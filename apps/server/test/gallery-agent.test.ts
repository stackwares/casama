/** The gallery as bots see it (D-315): every kind in one list, from the repository's gallery/. */
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { searchGallery } from "@casama/agent";
import { beforeEach, describe, expect, it } from "vitest";
import { loadEnv } from "../src/env.ts";
import { resetGalleryCache } from "../src/services/gallery.ts";
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

describe("galleryForAgents", () => {
  beforeEach(() => resetGalleryCache());

  it("lists skills, looks, apps, bots, routines and plugins with their descriptions", async () => {
    const items = await galleryForAgents(env, fromRepo).items("org");
    const kinds = new Set(items.map((i) => i.type));
    for (const k of ["skill", "theme", "app", "bot", "routine", "plugin"])
      expect(kinds.has(k as never), k).toBe(true);
    const skill = items.find((i) => i.type === "skill" && i.id === "article-outline");
    expect(skill?.description).toMatch(/outline/i);
    expect(searchGallery(items, "outline an article").map((i) => i.id)).toContain(
      "article-outline",
    );
  });

  it("is empty, not an error, when the gallery is off", async () => {
    const off = { ...env, GALLERY_URL: "off" };
    expect(await galleryForAgents(off, fromRepo).items("org")).toEqual([]);
  });
});
