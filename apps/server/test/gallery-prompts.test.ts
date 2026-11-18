/** Check-in and setup prompts from the gallery (D-374): main catalog only, bad entries fall back. */
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { BUILT_IN_PROMPTS, promptText, promptVersion, setPrompts } from "@casama/agent";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { loadEnv } from "../src/env.ts";
import { resetGalleryCache } from "../src/services/gallery.ts";
import { loadGalleryPrompts } from "../src/services/remote-settings.ts";

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

const fromRepo = (async (url: string | URL) => {
  const path = new URL(String(url)).pathname.slice(1);
  try {
    return new Response(await readFile(`${root}${path}`), {
      headers: { "content-type": "application/json" },
    });
  } catch {
    return new Response("not found", { status: 404 });
  }
}) as typeof fetch;

describe("gallery prompts", () => {
  beforeEach(() => resetGalleryCache());
  afterEach(() => setPrompts([]));

  it("loads the repository's prompts.json, the same text as the built-in fallback", async () => {
    const versions = await loadGalleryPrompts(env, fromRepo);
    expect(Object.keys(versions ?? {}).sort()).toEqual(Object.keys(BUILT_IN_PROMPTS).sort());
    expect(promptVersion("checkin.brief")).toBeGreaterThanOrEqual(1);
    for (const id of Object.keys(BUILT_IN_PROMPTS) as (keyof typeof BUILT_IN_PROMPTS)[])
      expect(promptText(id)).toBe(BUILT_IN_PROMPTS[id]);
  });

  it("skips entries that fail their check, and keeps the last good set when offline", async () => {
    const items = [
      { id: "checkin.scan", version: 4, text: "A new scan text that is long enough to pass." },
      { id: "checkin.brief", version: 2, text: "Say NOTHING_NEW when there's nothing." },
      { id: "made.up", version: 1, text: "Some text for an id nobody knows about." },
    ];
    let up = true;
    const fake = (async (url: string | URL) => {
      if (!up) throw new TypeError("offline");
      if (String(url).endsWith("/prompts.json")) return Response.json({ schema: 1, items });
      return new Response("not found", { status: 404 });
    }) as typeof fetch;
    expect(await loadGalleryPrompts(env, fake)).toEqual({ "checkin.scan": 4 });
    expect(promptText("checkin.scan")).toMatch(/^A new scan text/);
    expect(promptText("checkin.brief")).toBe(BUILT_IN_PROMPTS["checkin.brief"]);
    resetGalleryCache();
    up = false;
    expect(await loadGalleryPrompts(env, fake)).toBeNull();
    expect(promptVersion("checkin.scan")).toBe(4);
  });

  it("never reads prompts from an extra source", async () => {
    const extraOnly = { ...env, GALLERY_URL: "off", GALLERY_SOURCES: "acme=https://acme.test" };
    expect(await loadGalleryPrompts(extraOnly, fromRepo)).toBeNull();
  });
});
