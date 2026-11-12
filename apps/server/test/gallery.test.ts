import { readFile } from "node:fs/promises";
import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { galleryApps, resetGalleryCache } from "../src/services/gallery.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const galleryRoot = fileURLToPath(new URL("../../../gallery", import.meta.url));

function serveGallery() {
  return new Promise<{ url: string; close: () => Promise<void> }>((resolve) => {
    const server = createServer(async (req, res) => {
      const path = decodeURIComponent(new URL(req.url ?? "/", "http://127.0.0.1").pathname);
      if (path.includes("..")) {
        res.statusCode = 400;
        res.end();
        return;
      }
      try {
        const bytes = await readFile(join(galleryRoot, path));
        res.setHeader("content-type", path.endsWith(".json") ? "application/json" : "text/plain");
        res.end(bytes);
      } catch {
        res.statusCode = 404;
        res.end();
      }
    });
    server.listen(0, "127.0.0.1", () => {
      const address = server.address() as AddressInfo;
      resolve({
        url: `http://127.0.0.1:${address.port}`,
        close: () => new Promise((done) => server.close(() => done())),
      });
    });
  });
}

describe("gallery", () => {
  let h: Harness;
  let site: { url: string; close: () => Promise<void> };
  let owner: { token: string };
  let orgId: string;

  beforeAll(async () => {
    resetGalleryCache();
    site = await serveGallery();
    h = await startHarness({ env: { GALLERY_URL: site.url } });
    owner = await h.user("gallery-owner@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Gallery" },
        }),
      )
    ).id;
  }, 60_000);

  afterAll(async () => {
    await h?.stop();
    await site?.close();
    resetGalleryCache();
  });

  it("lists featured looks and returns a theme document", async () => {
    const list = await j(
      await h.request("/v1/gallery?type=theme&featured=true", { token: owner.token }),
    );
    expect(list.available).toBe(true);
    expect(list.items.map((i: { id: string }) => i.id)).toEqual([
      "lagoon",
      "nightshift",
      "orchard",
    ]);
    // A list carries what each card draws, so the app needs no request per preview.
    expect(list.items[0].document.headingFont).toBe("Fraunces");
    const item = await j(await h.request("/v1/gallery/theme/lagoon", { token: owner.token }));
    expect(item.document.v).toBe(2);
    expect(item.author.name).toBe("Casama");
    expect(item.license).toBe("CC0-1.0");
  });

  it("carries what a look needs, with glyphs turned into doodles", async () => {
    const list = await j(await h.request("/v1/gallery?type=wallpaper", { token: owner.token }));
    const stargazer = list.items.find((i: { id: string }) => i.id === "stargazer");
    expect(stargazer.requires).toEqual(["doodles"]);
    expect(stargazer.document.doodles).toHaveLength(stargazer.document.glyphs.length);
    const scribbles = list.items.find((i: { id: string }) => i.id === "scribbles");
    expect(scribbles.requires).toEqual(["doodles", "mesh"]);
    const item = await j(
      await h.request("/v1/gallery/wallpaper/stargazer", { token: owner.token }),
    );
    expect(item.document.doodles[0][0][0]).toBe("path");
    const schemes = await j(await h.request("/v1/gallery?type=scheme", { token: owner.token }));
    expect(schemes.items.find((i: { id: string }) => i.id === "orchid").requires).toEqual([
      "scheme-colors",
    ]);
  });

  it("lists skills with their description and icon", async () => {
    const list = await j(await h.request("/v1/gallery?type=skill", { token: owner.token }));
    const brief = list.items.find((i: { id: string }) => i.id === "research-brief");
    expect(brief.icon).toBe("file-search");
    expect(brief.description).toMatch(/sourced brief/);
    expect(brief.document).toBeUndefined();
  });

  it("installs a gallery skill when the files match the index", async () => {
    const res = await h.request("/v1/skills/install", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, gallery_id: "meeting-notes" },
    });
    expect(res.status).toBe(201);
    expect(await j(res)).toMatchObject({
      name: "meeting-notes",
      source: "gallery",
      category: "work",
    });
  });

  it("adds the gallery's apps to the catalog, with their marks, and keeps them out of looks", async () => {
    const catalog = await j(await h.request("/v1/apps", { token: owner.token }));
    const canva = catalog.apps.find((a: { id: string }) => a.id === "canva");
    expect(canva).toMatchObject({
      name: "Canva",
      category: "design",
      url: "https://mcp.canva.com/mcp",
      auth: ["oauth"],
      popular: false,
      logo_url: `${site.url}/apps/canva/logo.svg`,
    });
    const deepwiki = catalog.apps.find((a: { id: string }) => a.id === "deepwiki");
    expect(deepwiki.auth).toEqual(["none"]);
    expect(deepwiki.logo_url).toBeUndefined();
    // Built-in apps still come first.
    expect(catalog.apps[0].id).not.toBe("canva");
    const all = await j(await h.request("/v1/gallery", { token: owner.token }));
    expect(all.items.some((i: { type: string }) => i.type === "app")).toBe(false);
  });

  it("checks gallery apps again and refuses what only the built-in catalog may do", async () => {
    const good = {
      description: "Fine.",
      category: "design",
      color: "112233",
      homepage: "https://vendor.example.org",
      url: "https://mcp.vendor.example.org/mcp",
      auth: ["oauth"],
      oauthClient: "dcr",
      capabilities: ["Do things"],
    };
    const item = (id: string, document: unknown, extra: Record<string, unknown> = {}) => ({
      id,
      type: "app",
      name: id,
      retired: false,
      files: [`apps/${id}/app.json`, `apps/${id}/item.json`],
      document,
      ...extra,
    });
    const items = [
      item("good", good),
      item("google-ish", { ...good, category: "google" }),
      item("borrowed-client", { ...good, oauthClient: "preregistered" }),
      item("via-composio", { ...good, composio: "x" }),
      item("inward", { ...good, url: "https://10.0.0.5/mcp" }),
      item("plain-http", { ...good, url: "http://mcp.vendor.example.org/mcp" }),
      item("retired", good, { retired: true }),
      item("github", good),
      item("google-drive", good),
      item("Bad_Id", good),
      { ...item("theme-like", good), type: "theme" },
    ];
    const fakeFetch = (async () =>
      new Response(JSON.stringify({ schema: 1, items }), {
        headers: { "content-type": "application/json" },
      })) as typeof fetch;
    resetGalleryCache();
    const apps = await galleryApps(
      { GALLERY_URL: "https://gallery.example.org" } as never,
      fakeFetch,
    );
    resetGalleryCache();
    expect(apps.map((a) => a.id)).toEqual(["good"]);
    expect(apps[0]).not.toHaveProperty("logoUrl");
  });

  it("is off when the URL is empty", async () => {
    resetGalleryCache();
    const off = await startHarness({ env: { GALLERY_URL: "off" } });
    const user = await off.user("off@example.com");
    const res = await off.request("/v1/gallery", { token: user.token });
    expect(res.status).toBe(404);
    await off.stop();
    resetGalleryCache();
  });
});
