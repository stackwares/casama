/**
 * Shared set-up for the sites and domains tests (docs/SITES-AND-DOMAINS-PLAN.md §10): a harness
 * with a sites zone, a workspace with a bot, a three-page site published from a folder, and the
 * pages port's dispatcher exactly as main.ts builds it.
 */
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { registerPageTools, registerSiteTools, ToolRegistry } from "@casama/agent";
import { FsObjectStore } from "@casama/sandbox";
import { createPagesApp } from "../src/pages/app.ts";
import { clearHostCache, createHostDispatcher } from "../src/pages/hosts.ts";
import { createSitesApp } from "../src/pages/sites.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

export const ZONE = "sites.example.com";
export const PAGES_HOST = "pages.example.com";

const enc = (t: string) => new TextEncoder().encode(t);
export const SITE_FILES: Record<string, Uint8Array> = {
  "/home/casama/workspace/site/index.html": enc(
    '<!doctype html><html><head><title>Crumb</title><meta name="description" content="Bread"></head><body><h1>Crumb</h1><a href="about.html">About</a><img src="img/logo.png"></body></html>',
  ),
  "/home/casama/workspace/site/about.html": enc(
    "<!doctype html><html><head><title>About</title></head><body><h1>About us</h1></body></html>",
  ),
  "/home/casama/workspace/site/contact/index.html": enc(
    '<!doctype html><html><head><title>Contact</title></head><body><form data-casama-form><input name="email"><button type="submit">Send</button></form></body></html>',
  ),
  "/home/casama/workspace/site/404.html": enc(
    "<!doctype html><html><head><title>Lost</title></head><body><h1>Nothing here</h1></body></html>",
  ),
  "/home/casama/workspace/site/img/logo.png": new Uint8Array([0x89, 0x50, 0x4e, 0x47, 9, 9]),
};

const computer = (files: Record<string, Uint8Array>) => ({
  listDir: async (p: string) => {
    const abs = p.startsWith("/") ? p : `/home/casama/workspace/${p}`;
    const names = new Map<string, "file" | "dir">();
    for (const f of Object.keys(files)) {
      if (!f.startsWith(`${abs}/`)) continue;
      const [first, ...more] = f.slice(abs.length + 1).split("/");
      names.set(first as string, more.length ? "dir" : "file");
    }
    return [...names].map(([name, type]) => ({
      name,
      path: `${abs}/${name}`,
      type,
      size: files[`${abs}/${name}`]?.length ?? 0,
      modified: "",
    }));
  },
  readFile: async (p: string) =>
    files[p.startsWith("/") ? p : `/home/casama/workspace/${p}`] as Uint8Array,
});

export interface SitesWorld {
  h: Harness;
  dir: string;
  store: FsObjectStore;
  reg: ToolRegistry;
  owner: { id: string; email: string; token: string };
  orgId: string;
  botId: string;
  runId: string;
  /** The pages port: a request to any host. */
  get(url: string, init?: RequestInit): Promise<Response>;
  tool(name: string, args: unknown): Promise<{ content: string; preview?: string }>;
  /** Publishes the three-page site from a folder and returns its page id. */
  publishFolder(title?: string): Promise<string>;
  stop(): Promise<void>;
}

export async function startSitesWorld(
  opts: { env?: Record<string, string>; harness?: Parameters<typeof startHarness>[0] } = {},
): Promise<SitesWorld> {
  clearHostCache();
  const dir = await mkdtemp(join(tmpdir(), "casama-sites-"));
  const store = new FsObjectStore(dir);
  const h = await startHarness({
    ...opts.harness,
    objects: store,
    env: { PAGES_URL: `https://${PAGES_HOST}`, CASAMA_SITES_ZONE: ZONE, ...opts.env },
  });
  const owner = await h.user(`sites-${Math.random().toString(36).slice(2)}@example.com`);
  const orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Crumb" } }),
    )
  ).id as string;
  const botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Builder" },
      }),
    )
  ).id as string;
  const [run] = await h.tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, trigger, status, created_by) values (${orgId}, ${botId}, 'chat', 'completed', ${owner.id}) returning id`;
  const runId = run!.id;
  const reg = new ToolRegistry();
  registerPageTools(reg, { db: h.handle.db, pagesUrl: `https://${PAGES_HOST}`, objects: store });
  registerSiteTools(reg, { db: h.handle.db, zone: ZONE });
  const dispatch = createHostDispatcher({
    db: h.handle.db,
    zone: ZONE,
    pagesHost: PAGES_HOST,
    pages: createPagesApp({ db: h.handle.db, objects: store }),
    sites: createSitesApp({ db: h.handle.db, objects: store, instanceId: "instance-test-1" }),
  });
  const files = { ...SITE_FILES };
  const ctx = () =>
    ({
      runId,
      botId,
      orgId,
      output: async () => {},
      emit: async () => {},
      computer: async () => computer(files),
    }) as never;
  const tool = (name: string, args: unknown) => {
    const t = reg.get(name);
    if (!t) throw new Error(`no tool ${name}`);
    return t.execute(args as never, ctx()) as Promise<{ content: string; preview?: string }>;
  };
  return {
    h,
    dir,
    store,
    reg,
    owner,
    orgId,
    botId,
    runId,
    get: (url, init) => Promise.resolve(dispatch(new Request(url, init))),
    tool,
    async publishFolder(title = "Crumb") {
      const r = await tool("pages.publish", {
        title,
        folder: "site",
        label: "Site",
        collect: true,
      });
      return /page ([0-9a-f-]{36})/.exec(r.content)?.[1] as string;
    },
    async stop() {
      await h.stop();
      await rm(dir, { recursive: true, force: true });
    },
  };
}
