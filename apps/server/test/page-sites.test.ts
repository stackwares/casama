/** Sites and games with their own files (D-289), published from a folder on the computer. */
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { registerPageTools, ToolRegistry } from "@casama/agent";
import { PAGE_CSP_ASSETS } from "@casama/domain";
import { FsObjectStore } from "@casama/sandbox";
import { afterAll, beforeAll, expect, it } from "vitest";
import { createPagesApp } from "../src/pages/app.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let dir = "";
let store: FsObjectStore;
let pages: ReturnType<typeof createPagesApp>;
let orgId = "";
let botId = "";
let runId = "";
const reg = new ToolRegistry();
const enc = (t: string) => new TextEncoder().encode(t);
const site: Record<string, Uint8Array> = {
  "/home/casama/workspace/game/index.html": enc(
    '<!doctype html><html><head><title>Snake</title><link rel="stylesheet" href="css/game.css"></head><body><canvas id="c"></canvas><script src="js/game.js"></script></body></html>',
  ),
  "/home/casama/workspace/game/js/game.js": enc("document.title='Snake ready';"),
  "/home/casama/workspace/game/css/game.css": enc("body{margin:0}"),
  "/home/casama/workspace/game/img/apple.png": new Uint8Array([0x89, 0x50, 0x4e, 0x47, 1, 2]),
};
const computer = {
  listDir: async (p: string) => {
    const abs = p.startsWith("/") ? p : `/home/casama/workspace/${p}`;
    const names = new Map<string, "file" | "dir">();
    for (const f of Object.keys(site)) {
      if (!f.startsWith(`${abs}/`)) continue;
      const rest = f.slice(abs.length + 1);
      const [first, ...more] = rest.split("/");
      names.set(first as string, more.length ? "dir" : "file");
    }
    return [...names].map(([name, type]) => ({
      name,
      path: `${abs}/${name}`,
      type,
      size: site[`${abs}/${name}`]?.length ?? 0,
      modified: "",
    }));
  },
  readFile: async (p: string) =>
    site[p.startsWith("/") ? p : `/home/casama/workspace/${p}`] as Uint8Array,
};
const ctx = () =>
  ({
    runId,
    botId,
    orgId,
    output: async () => {},
    emit: async () => {},
    computer: async () => computer,
  }) as never;
const tool = (name: string, args: unknown) => reg.get(name)!.execute(args as never, ctx());

beforeAll(async () => {
  dir = await mkdtemp(join(tmpdir(), "casama-sites-"));
  store = new FsObjectStore(dir);
  h = await startHarness({ env: { PAGES_URL: "https://pages.example.com" } });
  pages = createPagesApp({ db: h.handle.db, objects: store });
  const owner = await h.user("sites@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Sites" } }),
    )
  ).id;
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Dev" },
      }),
    )
  ).id;
  const [run] = await h.tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, trigger, status, created_by) values (${orgId}, ${botId}, 'chat', 'completed', ${owner.id}) returning id`;
  runId = run!.id;
  registerPageTools(reg, {
    db: h.handle.db,
    pagesUrl: "https://pages.example.com",
    objects: store,
  });
}, 60_000);
afterAll(async () => {
  await h?.stop();
  await rm(dir, { recursive: true, force: true });
});

it("publishes a folder: the page loads its own scripts, styles and images from its own origin only", async () => {
  const r = await tool("pages.publish", { title: "Snake", folder: "game", label: "Game" });
  const pageId = /page ([0-9a-f-]{36})/.exec(r.content)![1]!;
  const share = await tool("pages.share", { page_id: pageId, visibility: "public" });
  const url = /https:\/\/pages\.example\.com(\/s\/[^\s)."]+)/.exec(share.content)![1]!;
  const page = await pages.request(url);
  expect(page.headers.get("content-security-policy")).toBe(PAGE_CSP_ASSETS);
  expect(PAGE_CSP_ASSETS).toContain("script-src 'self' 'unsafe-inline'");
  expect(PAGE_CSP_ASSETS).not.toMatch(/https?:/);
  const html = await page.text();
  expect(html).toContain(`<base href="${url}/a/">`);
  const js = await pages.request(`${url}/a/js/game.js`);
  expect(js.headers.get("content-type")).toBe("text/javascript; charset=utf-8");
  expect(await js.text()).toBe("document.title='Snake ready';");
  expect((await pages.request(`${url}/a/img/apple.png`)).headers.get("content-type")).toBe(
    "image/png",
  );
  expect((await pages.request(`${url}/a/../index.html`)).status).toBe(404);
  expect((await pages.request(`${url}/a/%2e%2e/x`)).status).toBe(404);
  const [c] = await h.tdb.admin<
    { label: string; size: string }[]
  >`select label, size::text from public.creations where page_id = ${pageId}`;
  expect(c!.label).toBe("Game");
  expect(Number(c!.size)).toBeGreaterThan(30);
});

it("republishing as one HTML file drops the files", async () => {
  const r = await tool("pages.publish", { title: "Plain", folder: "game" });
  const pageId = /page ([0-9a-f-]{36})/.exec(r.content)![1]!;
  await tool("pages.publish", { title: "Plain", page_id: pageId, html: "<p>just text</p>" });
  const share = await tool("pages.share", { page_id: pageId, visibility: "public" });
  const url = /https:\/\/pages\.example\.com(\/s\/[^\s)."]+)/.exec(share.content)![1]!;
  expect(await (await pages.request(url)).text()).not.toContain("<base");
  expect((await pages.request(`${url}/a/js/game.js`)).status).toBe(404);
});
