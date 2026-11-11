import { readFile } from "node:fs/promises";
import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { resetGalleryCache } from "../src/services/gallery.ts";
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
    expect(list.items.map((i: { id: string }) => i.id)).toEqual(["lagoon", "nightshift", "orchard"]);
    // A list carries what each card draws, so the app needs no request per preview.
    expect(list.items[0].document.headingFont).toBe("Fraunces");
    const item = await j(await h.request("/v1/gallery/theme/lagoon", { token: owner.token }));
    expect(item.document.v).toBe(2);
    expect(item.author.name).toBe("Casama");
    expect(item.license).toBe("CC0-1.0");
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
