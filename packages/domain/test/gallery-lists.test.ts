import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { checkAppConfig } from "../src/app-config.ts";
import { APP_CATALOG } from "../src/apps.ts";
import { checkEmailCopy } from "../src/email-copy.ts";
import {
  checkGalleryList,
  curateCatalog,
  GALLERY_LIST_IDS,
  parseAppCuration,
  parseEmptyStarters,
  parseGalleryLists,
  parseSearchWords,
  parseWelcomeContent,
} from "../src/gallery-lists.ts";
import { BOT_TEMPLATES } from "../src/templates.ts";

const gallery = fileURLToPath(new URL("../../../gallery", import.meta.url));
const WELCOME_IDS = [
  "email_calendar",
  "work_projects",
  "coding",
  "research",
  "sales",
  "errands",
  "health",
  "other",
];

describe("gallery content lists (D-372)", () => {
  it("passes every list in the gallery strictly", () => {
    const files = readdirSync(join(gallery, "lists")).filter((f) => f.endsWith(".json"));
    expect(files.map((f) => f.replace(/\.json$/, "")).sort()).toEqual([...GALLERY_LIST_IDS].sort());
    for (const f of files) {
      const {
        name: _n,
        version: _v,
        updated: _u,
        ...doc
      } = JSON.parse(readFileSync(join(gallery, "lists", f), "utf8"));
      expect(checkGalleryList(f.replace(/\.json$/, ""), doc, { welcomeIds: WELCOME_IDS })).toEqual(
        [],
      );
    }
  });

  it("reads lists.json and skips what it doesn't know", () => {
    const { items } = JSON.parse(readFileSync(join(gallery, "lists.json"), "utf8"));
    const lists = parseGalleryLists([
      ...items,
      { type: "list", id: "from-the-future", document: { x: 1 } },
      { type: "bot", id: "search-words", document: {} },
      "nonsense",
    ]);
    expect(lists.searchWords?.mail).toContain("email");
    expect(lists.starters?.library?.length).toBe(6);
    expect(lists.starters?.library?.find((s) => s.id === "video")?.prompt).toBe(
      "Make a short video of ",
    );
    expect(lists.appCuration?.starter_apps?.[0]).toBe("gmail");
    expect(parseWelcomeContent(lists.welcome, WELCOME_IDS)).toHaveLength(8);
  });

  it("keeps good search words and drops bad ones", () => {
    expect(
      parseSearchWords({
        words: { Mail: ["Email", "email", 3, "<b>"], "": ["x"], dark: "night", ok: ["fine"] },
      }),
    ).toEqual({ mail: ["email"], ok: ["fine"] });
    expect(parseSearchWords({ words: {} })).toBeUndefined();
    expect(parseSearchWords(null)).toBeUndefined();
  });

  it("only takes welcome entries for focus ids the code knows, and only valid fields", () => {
    const got = parseWelcomeContent(
      {
        focus: [
          { id: "coding", label: "Code", first_task: { label: "x" }, apps: ["github", "BAD ID"] },
          { id: "brand_new", label: "Not yet" },
          { id: "coding", label: "Twice" },
        ],
      },
      WELCOME_IDS,
    );
    expect(got).toEqual([{ id: "coding", label: "Code", apps: ["github"] }]);
  });

  it("skips starters with missing fields and falls back on icon and hue", () => {
    const s = parseEmptyStarters({
      library: [
        { id: "a", label: "A", prompt: "Make A", icon: "Not An Icon", hue: 999 },
        { id: "b" },
      ],
      tasks: [{ id: "t", text: "" }],
      support: "nope",
    });
    expect(s).toEqual({
      library: [{ id: "a", label: "A", prompt: "Make A", icon: "sparkles", hue: 265 }],
    });
  });

  it("curates display fields and order of built-in apps only", () => {
    const curation = parseAppCuration({
      apps: [
        { id: "notion", name: "Notion (notes)", color: "112233", featured: true, url: "https://x" },
        { id: "gallery-app", name: "Not mine" },
      ],
      order: ["notion"],
      starter_apps: ["notion", "slack"],
    });
    const gallery = { ...(APP_CATALOG[0] as (typeof APP_CATALOG)[number]), id: "gallery-app" };
    const builtIn = new Set(APP_CATALOG.map((a) => a.id));
    const out = curateCatalog([...APP_CATALOG, gallery], curation, builtIn);
    const notion = out[0];
    const original = APP_CATALOG.find((a) => a.id === "notion");
    expect(notion?.id).toBe("notion");
    expect(notion?.name).toBe("Notion (notes)");
    expect(notion?.color).toBe("112233");
    expect(notion?.popular).toBe(true);
    // What connects never changes.
    expect(notion?.url).toBe(original?.url);
    expect(out.find((a) => a.id === "gallery-app")?.name).toBe(gallery.name);
    expect(out).toHaveLength(APP_CATALOG.length + 1);
    expect(curateCatalog(APP_CATALOG, undefined, builtIn)).toBe(APP_CATALOG);
  });

  it("refuses sign-in fields in the gallery's curation file", () => {
    expect(
      checkGalleryList("app-curation", { apps: [{ id: "notion", scopes: ["x"] }] }).join(),
    ).toMatch(/only display fields/);
  });

  it("has a gallery copy of every built-in starter bot", () => {
    const { items } = JSON.parse(readFileSync(join(gallery, "bots.json"), "utf8"));
    const ids = new Set(items.map((i: { id: string }) => i.id));
    for (const t of BOT_TEMPLATES) expect(ids.has(t.id), t.id).toBe(true);
  });
});

describe("remote app settings additions (D-372)", () => {
  const base = { min_versions: {}, update_urls: {}, announcements: [], flags: {} };

  it("checks links, prompts and quick reactions, and drops served names", () => {
    const { config, errors } = checkAppConfig({
      ...base,
      links: { status: "https://status.example.com", docs: "" },
      prompts: { "selection.explain": " Explain this, simply. " },
      quick_reactions: ["👍", "❤"],
      names: { apps: { github: "GitHub" } },
    });
    expect(errors).toEqual([]);
    expect(config?.links).toEqual({ status: "https://status.example.com" });
    expect(config?.prompts).toEqual({ "selection.explain": "Explain this, simply." });
    expect(config?.quick_reactions).toEqual(["👍", "❤️"]);
    expect(config && "names" in config).toBe(false);
  });

  it("explains bad links, prompts and reactions", () => {
    const { errors } = checkAppConfig({
      ...base,
      links: { status: "http://insecure.example.com", "Bad Name": "https://x.example.com" },
      prompts: { long: "x".repeat(1001) },
      quick_reactions: ["👍", "hello"],
    });
    expect(errors.join("\n")).toMatch(/links.status must be an https link/);
    expect(errors.join("\n")).toMatch(/links.Bad Name/);
    expect(errors.join("\n")).toMatch(/prompts.long/);
    expect(errors.join("\n")).toMatch(/quick_reactions/);
  });

  it("leaves the old settings shape as it was", () => {
    const { config } = checkAppConfig(base);
    expect(config).toEqual({ ...base, maintenance: null });
  });
});

describe("email copy (D-372)", () => {
  it("keeps editable emails and explains the rest", () => {
    expect(
      checkEmailCopy({ welcome: { subject: "Hello", intro: ["One", "Two"], button: "Go" } }),
    ).toEqual({
      errors: [],
      copy: { welcome: { subject: "Hello", intro: ["One", "Two"], button: "Go" } },
    });
    const bad = checkEmailCopy({ payment_failed: { subject: "x" }, welcome: { color: "red" } });
    expect(bad.copy).toBeUndefined();
    expect(bad.errors.join("\n")).toMatch(/payment_failed isn't an email/);
    expect(bad.errors.join("\n")).toMatch(/welcome.color isn't a field/);
  });
});
