import { readFile } from "node:fs/promises";
import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { resetEmailCopyCache } from "../src/services/account-emails.ts";
import { resetAppConfigCache } from "../src/services/app-config.ts";
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
      "casama",
      "lagoon",
      "nightshift",
      "orchard",
    ]);
    expect(list.items.find((i: { id: string }) => i.id === "lagoon").document.headingFont).toBe(
      "Quicksand",
    );
    const item = await j(await h.request("/v1/gallery/theme/lagoon", { token: owner.token }));
    expect(item.document.v).toBe(2);
    expect(item.author.name).toBe("Casama");
    expect(item.license).toBe("CC0-1.0");
  });

  it("carries what a look needs: a painted wallpaper's picture, a scheme's colors", async () => {
    // Every wallpaper is a painted picture since D-379, so none needs doodles or a mesh.
    const list = await j(await h.request("/v1/gallery?type=wallpaper", { token: owner.token }));
    const stargazer = list.items.find((i: { id: string }) => i.id === "stargazer");
    expect(stargazer.document.kind).toBe("image");
    expect(stargazer.requires ?? []).not.toContain("doodles");
    const item = await j(
      await h.request("/v1/gallery/wallpaper/stargazer", { token: owner.token }),
    );
    expect(item.document.file).toBe("stargazer.jpg");
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

  it("adds the gallery's starter bots to the templates and builds a bot from one", async () => {
    const templates = await j(await h.request("/v1/templates", { token: owner.token }));
    const buddy = templates.items.find((t: { id: string }) => t.id === "study-buddy");
    expect(buddy).toMatchObject({
      name: "Study buddy",
      category: "life",
      mascot: "thinker",
      autonomy: "ask_always",
      skills: ["flashcards"],
      author: { name: "Casama" },
    });
    // Built-in ones come first, as the gallery's copies when it has them (D-372), Casama's own
    // first of all (D-391).
    expect(templates.items[0]).toMatchObject({
      id: "casama",
      bot_name: "Casama",
      author: { name: "Casama" },
    });
    const ids = templates.items.map((t: { id: string }) => t.id);
    expect(new Set(ids).size).toBe(ids.length);
    const credId = (
      await j(
        await h.request("/v1/credentials", {
          method: "POST",
          token: owner.token,
          json: { org_id: orgId, provider: "openrouter", label: "m", api_key: "sk-or-gallery" },
        }),
      )
    ).id;
    const make = (template_id: string) =>
      h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Home",
          template_id,
          model_policy: { primary: { credential_id: credId, model: "fixture-main" } },
        },
      });
    const bot = await j(await make("home-organizer"));
    expect(bot.persona_md).toContain("household");
    expect(bot.autonomy).toBe("ask_risky");
    const routines = await j(
      await h.request(`/v1/bots/${bot.id}/routines`, { token: owner.token }),
    );
    expect(routines.items[0]).toMatchObject({
      name: "Sunday week ahead",
      schedule_cron: "0 18 * * 0",
    });
    expect((await make("no-such-bot")).status).toBe(404);
  });

  it("lists routine ideas and reviewed plugins", async () => {
    const ideas = await j(await h.request("/v1/routine-ideas", { token: owner.token }));
    expect(ideas.items[0].featured).toBe(true);
    expect(ideas.items.find((i: { id: string }) => i.id === "weekly-review")).toMatchObject({
      schedule_cron: "0 16 * * 5",
      category: "work",
      icon: "calendar-check",
    });
    const plugins = await j(await h.request("/v1/plugin-directory", { token: owner.token }));
    expect(plugins.items).toContainEqual(
      expect.objectContaining({
        id: "hello-casama",
        commit: "6efc18250f69b9c2938b689076384237324136e3",
        url: "https://github.com/stackwares/casama/tree/main/examples/hello-plugin",
      }),
    );
    // The first-party packs are directory plugins too (D-343).
    const ids = plugins.items.map((p: { id: string }) => p.id);
    expect(ids).toEqual(expect.arrayContaining(["dev-kit", "founder-kit", "meetings-handled"]));
  });

  it("serves the skill catalog from the gallery and installs its copy", async () => {
    const catalog = await j(await h.request("/v1/skills/catalog", { token: owner.token }));
    const ids = catalog.items.map((i: { id: string }) => i.id);
    expect(ids).toContain("meeting-notes");
    expect(ids).toContain("teach");
    expect(new Set(ids).size).toBe(ids.length);
    const res = await h.request("/v1/skills/install", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, catalog_id: "proofread" },
    });
    expect(res.status).toBe(201);
    const skill = await j(res);
    expect(skill.source).toBe("catalog");
    expect(skill.source_ref.id).toBe("proofread");
    expect(skill.source_ref.sha256).toMatch(/^[0-9a-f]{64}$/);
  });

  it("serves remote app settings without sign-in; only the owner changes them", async () => {
    resetAppConfigCache();
    const empty = await j(await h.request("/v1/app-config"));
    expect(empty).toMatchObject({
      min_versions: {},
      update_urls: {},
      maintenance: null,
      announcements: [],
      flags: {},
      // Served with every answer (D-372): the apps' copies are only fallbacks now.
      quick_reactions: ["👍", "❤️", "😂", "😮", "😢", "👎"],
    });
    expect(empty.names.apps.googlecalendar).toBe("Google Calendar");
    expect(empty.names.dns_providers.route53).toBe("Amazon Route 53");
    expect(empty.links).toBeUndefined();
    const bad = await h.request("/v1/admin/app-config", {
      method: "PUT",
      token: owner.token,
      json: { min_versions: { ios: "soon" } },
    });
    expect(bad.status).toBe(400);
    const set = await h.request("/v1/admin/app-config", {
      method: "PUT",
      token: owner.token,
      json: {
        min_versions: { ios: "0.8.0" },
        update_urls: { ios: "https://apps.apple.com/app/id1" },
        announcements: [{ id: "launch", title: "We're live", body: "Thanks for testing." }],
        flags: { new_home: true },
      },
    });
    expect(set.status).toBe(200);
    const live = await j(await h.request("/v1/app-config"));
    expect(live.min_versions).toEqual({ ios: "0.8.0" });
    expect(live.announcements[0]).toMatchObject({ id: "launch", level: "info" });
    // bot_email is on only where hosted mail is set up (D-449); not in tests.
    expect(live.flags).toEqual({ new_home: true, bot_email: false });
    const other = await h.user("gallery-other@example.com");
    const denied = await h.request("/v1/admin/app-config", {
      method: "PUT",
      token: other.token,
      json: {},
    });
    expect(denied.status).toBe(403);
    resetAppConfigCache();
  });

  it("stores and serves the crash reporter choice, and refuses a bad one (D-417)", async () => {
    resetAppConfigCache();
    const bad = await h.request("/v1/admin/app-config", {
      method: "PUT",
      token: owner.token,
      json: { crash_reporter: { ios: "bugsnag" } },
    });
    expect(bad.status).toBe(400);
    expect(JSON.stringify(await j(bad))).toContain("crash_reporter.ios must be one of");
    const set = await h.request("/v1/admin/app-config", {
      method: "PUT",
      token: owner.token,
      json: { crash_reporter: { default: "sentry", android: "crashlytics" } },
    });
    expect(set.status).toBe(200);
    const stored = await j(await h.request("/v1/admin/app-config", { token: owner.token }));
    expect(stored.crash_reporter).toEqual({ default: "sentry", android: "crashlytics" });
    // What the editor got back saves again unchanged.
    const again = await h.request("/v1/admin/app-config", {
      method: "PUT",
      token: owner.token,
      json: stored,
    });
    expect(again.status).toBe(200);
    const live = await j(await h.request("/v1/app-config"));
    expect(live.crash_reporter).toEqual({ default: "sentry", android: "crashlytics" });
    await h.request("/v1/admin/app-config", { method: "PUT", token: owner.token, json: {} });
    resetAppConfigCache();
  });

  it("serves links, prompts and the owner's quick reactions in the app settings (D-372)", async () => {
    resetAppConfigCache();
    const set = await h.request("/v1/admin/app-config", {
      method: "PUT",
      token: owner.token,
      json: {
        links: { status: "https://status.example.com", terms: "https://example.com/terms" },
        prompts: { "selection.explain": "Explain this simply." },
        quick_reactions: ["🔥", "👍"],
        // What the server fills in is dropped, not refused: an editor may send back what it got.
        names: { apps: { x: "X" } },
      },
    });
    expect(set.status).toBe(200);
    const stored = await j(await h.request("/v1/admin/app-config", { token: owner.token }));
    expect(stored.names).toBeUndefined();
    const live = await j(await h.request("/v1/app-config"));
    expect(live.links).toEqual({
      status: "https://status.example.com",
      terms: "https://example.com/terms",
    });
    expect(live.prompts).toEqual({ "selection.explain": "Explain this simply." });
    expect(live.quick_reactions).toEqual(["🔥", "👍"]);
    expect(live.names.apps.github).toBe("GitHub");
    await h.request("/v1/admin/app-config", { method: "PUT", token: owner.token, json: {} });
    resetAppConfigCache();
  });

  it("serves the gallery's search words and starters, and its curation of the app catalog (D-372)", async () => {
    const lists = await j(await h.request("/v1/gallery/lists", { token: owner.token }));
    expect(lists.search_words.mail).toContain("email");
    expect(lists.starters.library.map((s: { id: string }) => s.id)).toContain("video");
    expect(lists.starters.tasks).toHaveLength(3);
    expect(lists.starters.support).toHaveLength(4);
    expect((await h.request("/v1/gallery/lists")).status).toBe(401);
    const catalog = await j(await h.request("/v1/apps", { token: owner.token }));
    expect(catalog.starter_apps).toEqual([
      "gmail",
      "google_calendar",
      "google_drive",
      "notion",
      "github",
      "slack",
    ]);
  });

  it("lets the owner change the welcome emails' words, never billing emails' (D-372)", async () => {
    const got = await j(await h.request("/v1/admin/email-copy", { token: owner.token }));
    expect(got.copy).toEqual({});
    expect(got.defaults.welcome.subject).toBe("Welcome to Casama");
    expect(got.defaults.gallery_digest.preheader).toContain("{count}");
    const bad = await h.request("/v1/admin/email-copy", {
      method: "PUT",
      token: owner.token,
      json: { payment_failed: { subject: "Pay up" } },
    });
    expect(bad.status).toBe(400);
    const set = await h.request("/v1/admin/email-copy", {
      method: "PUT",
      token: owner.token,
      json: { welcome: { subject: "Hello from us", intro: ["One thing to try."] } },
    });
    expect(set.status).toBe(200);
    expect((await j(set)).copy.welcome.subject).toBe("Hello from us");
    const other = await h.user("gallery-copy-other@example.com");
    expect((await h.request("/v1/admin/email-copy", { token: other.token })).status).toBe(403);
    await h.request("/v1/admin/email-copy", { method: "PUT", token: owner.token, json: {} });
    resetEmailCopyCache();
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
