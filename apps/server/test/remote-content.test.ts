/**
 * Remote content (D-372): gallery lists and copies win over the built-in ones, and every built-in
 * copy stays the fallback. No database: the gallery comes from the repository's gallery/.
 */
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { focusCard, searchGallery, setWelcomeContentSource } from "@casama/agent";
import { BOT_TEMPLATES } from "@casama/domain";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { loadEnv } from "../src/env.ts";
import { accountEmailContent, defaultEmailCopy } from "../src/services/account-emails.ts";
import {
  findTemplate,
  galleryLists,
  resetGalleryCache,
  starterBots,
} from "../src/services/gallery.ts";
import { galleryForAgents } from "../src/services/gallery-agent.ts";

const root = fileURLToPath(new URL("../../../gallery/", import.meta.url));

const env = loadEnv({
  DATABASE_URL: "postgres://unused",
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "anon",
  SUPABASE_JWT_SECRET: "x".repeat(40),
  NODE_ENV: "test",
  GALLERY_URL: "https://gallery.test",
  GALLERY_SIGNATURE: "off",
});

/** The repository's gallery, with some files replaced. */
const galleryWith = (over: Record<string, unknown> = {}) =>
  (async (url: string | URL) => {
    const path = new URL(String(url)).pathname.slice(1);
    if (path in over)
      return over[path] === null
        ? new Response("gone", { status: 404 })
        : Response.json(over[path]);
    try {
      return new Response(await readFile(`${root}${path}`), {
        headers: { "content-type": "application/json" },
      });
    } catch {
      return new Response("not found", { status: 404 });
    }
  }) as typeof fetch;

async function botsFile() {
  return JSON.parse(await readFile(`${root}bots.json`, "utf8")) as {
    schema: number;
    items: { id: string; document: Record<string, unknown> }[];
  };
}

describe("starter bots: the gallery's copy wins (D-372)", () => {
  beforeEach(() => resetGalleryCache());

  it("uses an edited gallery copy of a built-in bot", async () => {
    const file = await botsFile();
    for (const i of file.items)
      if (i.id === "writer")
        i.document = { ...i.document, persona: "Edited in the gallery. ".repeat(3) };
    const fetchImpl = galleryWith({ "bots.json": file });
    const t = await findTemplate(env, "writer", fetchImpl);
    expect(t?.persona).toMatch(/^Edited in the gallery/);
    const all = await starterBots(env, fetchImpl);
    // Built-in order first, no id twice, the gallery's own after.
    expect(all.slice(0, BOT_TEMPLATES.length).map((b) => b.id)).toEqual(
      BOT_TEMPLATES.map((b) => b.id),
    );
    expect(new Set(all.map((b) => b.id)).size).toBe(all.length);
    expect(all.map((b) => b.id)).toContain("study-buddy");
  });

  it("falls back to the built-in copy when the gallery's fails its check or is gone", async () => {
    const file = await botsFile();
    for (const i of file.items)
      if (i.id === "writer") i.document = { ...i.document, autonomy: "autonomous" };
    const broken = await findTemplate(env, "writer", galleryWith({ "bots.json": file }));
    expect(broken?.persona).toBe(BOT_TEMPLATES.find((b) => b.id === "writer")?.persona);
    resetGalleryCache();
    const offline = await starterBots(env, galleryWith({ "bots.json": null }));
    expect(offline.map((b) => b.id)).toEqual(BOT_TEMPLATES.map((b) => b.id));
    const off = await findTemplate({ ...env, GALLERY_URL: "off" }, "coder");
    expect(off?.id).toBe("coder");
  });
});

describe("gallery lists (D-372)", () => {
  beforeEach(() => resetGalleryCache());

  it("reads lists.json and ignores lists it doesn't know", async () => {
    const lists = await galleryLists(env, galleryWith());
    expect(lists.searchWords?.cal).toContain("calendar");
    expect(lists.starters?.support).toHaveLength(4);
    expect(lists.appCuration?.starter_apps).toContain("notion");
  });

  it("is empty, never an error, when the file is missing or broken", async () => {
    expect(await galleryLists(env, galleryWith({ "lists.json": null }))).toEqual({});
    resetGalleryCache();
    expect(await galleryLists(env, galleryWith({ "lists.json": { items: "no" } }))).toEqual({});
  });

  it("gives the bots' gallery search the gallery's words, and the built-in ones without", async () => {
    const withWords = galleryForAgents(
      env,
      galleryWith({
        "lists.json": {
          schema: 1,
          items: [
            { type: "list", id: "search-words", document: { words: { homework: ["school"] } } },
          ],
        },
      }),
    );
    const items = await withWords.items("org");
    const words = await withWords.searchWords?.();
    expect(words).toEqual({ homework: ["school"] });
    expect(searchGallery(items, "homework", { synonyms: words }).map((i) => i.id)).toContain(
      "study-buddy",
    );
    resetGalleryCache();
    const without = galleryForAgents(env, galleryWith({ "lists.json": null }));
    expect(await without.searchWords?.()).toBeUndefined();
  });
});

describe("welcome chat words from the gallery (D-372)", () => {
  afterEach(() => setWelcomeContentSource(null));

  it("relabels a focus the gallery names and keeps the ids", async () => {
    const { refreshWelcomeContent } = await import("@casama/agent");
    setWelcomeContentSource(async () => ({
      focus: [
        { id: "coding", label: "Code and repos" },
        { id: "brand_new", label: "Nope" },
      ],
    }));
    await refreshWelcomeContent();
    const options = JSON.stringify(focusCard());
    expect(options).toContain('"label":"Code and repos","value":"coding"');
    expect(options).toContain('"label":"Research","value":"research"');
    expect(options).not.toContain("brand_new");
  });

  it("keeps the built-in words when the gallery fails", async () => {
    const { refreshWelcomeContent } = await import("@casama/agent");
    setWelcomeContentSource(async () => {
      throw new Error("offline");
    });
    await refreshWelcomeContent();
    expect(JSON.stringify(focusCard())).toContain('"label":"Coding","value":"coding"');
  });
});

describe("email copy (D-372)", () => {
  it("puts the owner's words in the welcome series and keeps the greeting and links", () => {
    const c = accountEmailContent("welcome", { name: "Ana" }, "https://app.example", {
      welcome: { subject: "Hello", intro: ["Try one thing."], button: "Start" },
    });
    expect(c.subject).toBe("Hello");
    expect(c.email.intro).toEqual(["Hi Ana,", "Try one thing."]);
    expect(c.email.button).toEqual({ label: "Start", url: "https://app.example" });
    expect(c.email.title).toBe("Welcome to Casama");
  });

  it("keeps the digest's item lines and counts them", () => {
    const items = [{ type: "skill", id: "a", name: "A", description: "Does a" }];
    const c = accountEmailContent("gallery_digest", { items }, "https://app.example", {
      gallery_digest: { preheader: "{count} picks", intro: ["Fresh this month:"] },
    });
    expect(c.email.preheader).toBe("1 picks");
    expect(c.email.intro[1]).toBe("Fresh this month:");
    expect(c.email.intro[2]).toContain("A: Does a");
  });

  it("never changes billing emails, and the defaults are the code's text", () => {
    const copy = { welcome: { subject: "x" } };
    const billing = accountEmailContent("payment_failed", { plan: "Pro" }, "https://a", copy);
    expect(billing.subject).not.toBe("x");
    const defaults = defaultEmailCopy();
    expect(Object.keys(defaults).sort()).toEqual(
      ["come_back", "first_bot_nudge", "gallery_digest", "week_one_tips", "welcome"].sort(),
    );
    expect(defaults.welcome?.intro?.[0]).toMatch(/AI teammates/);
  });
});
