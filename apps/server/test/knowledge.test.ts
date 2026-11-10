/** Knowledge sources (D-125): uploads, a website crawl within robots.txt, GitHub, and cited search. */
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { hashEmbedder, knowledgeTick, registerKnowledgeTools, syncKnowledgeSource, ToolRegistry } from "@kasama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let site: Server;
let base = "";
let owner: { id: string; token: string };
let member: { id: string; token: string };
let orgId: string;
let botId: string;
const fetched: string[] = [];

const pages: Record<string, string> = {
  "/robots.txt": "User-agent: *\nDisallow: /private\n",
  "/": `<html><head><title>Acme help</title></head><body><h1>Welcome</h1><p>Start here.</p><a href="/shipping">Shipping</a> <a href="/private/notes">Notes</a> <a href="https://elsewhere.example/x">Out</a></body></html>`,
  "/shipping": `<html><head><title>Shipping</title></head><body><h2>Times</h2><p>Orders to Cebu arrive in 3 business days.</p></body></html>`,
  "/private/notes": `<html><body><p>Secret plans</p></body></html>`,
};
const gh: Record<string, unknown> = {
  "/repos/acme/handbook": { default_branch: "main" },
  "/repos/acme/handbook/git/trees/main": { tree: [{ path: "docs/leave.md", type: "blob", sha: "b1", size: 50 }, { path: "logo.png", type: "blob", sha: "b2", size: 50 }] },
  "/repos/acme/handbook/git/blobs/b1": { content: Buffer.from("# Leave\n\nEveryone gets twenty vacation days a year.").toString("base64"), encoding: "base64" },
};

const deps = (embed = true) => ({ db: h.handle.db, fetch, embedderFor: async () => (embed ? hashEmbedder() : null), githubApiUrl: base });

beforeAll(async () => {
  site = createServer((req, res) => {
    const path = new URL(req.url ?? "/", "http://x").pathname;
    fetched.push(path);
    if (path in gh) return res.writeHead(200, { "content-type": "application/json" }).end(JSON.stringify(gh[path]));
    const body = pages[path];
    if (body === undefined) return res.writeHead(404).end();
    res.writeHead(200, { "content-type": path.endsWith(".txt") ? "text/plain" : "text/html" }).end(body);
  }).listen(0, "127.0.0.1");
  await once(site, "listening");
  base = `http://127.0.0.1:${(site.address() as AddressInfo).port}`;
  h = await startHarness();
  owner = await h.user("knowledge@example.com");
  member = await h.user("knowledge-member@example.com");
  orgId = (await j(await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "K" } }))).id;
  await h.tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
    }),
  );
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Helper", model_policy: { primary: { credential_id: cred.id, model: "m" } } },
      }),
    )
  ).id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
  site?.close();
});

const reg = new ToolRegistry();
const search = (query: string) =>
  reg.get("knowledge.search")!.execute({ query } as never, { runId: "r", botId, orgId, output: async () => {}, emit: async () => {} } as never);
const b64 = (s: string) => Buffer.from(s).toString("base64");

describe("knowledge sources", () => {
  it("indexes uploads (Markdown, CSV) and cites them in search", async () => {
    const res = await h.request("/v1/knowledge-sources", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: orgId,
        bot_id: botId,
        kind: "upload",
        name: "Policies",
        files: [
          { name: "returns.md", content_base64: b64("# Returns\n\nRefunds are accepted within 30 days with a receipt.") },
          { name: "stores.csv", content_base64: b64("city,hours\nCebu,9-6\nManila,10-8\n") },
          { name: "virus.exe", content_base64: b64("MZ") },
        ],
      },
    });
    expect(res.status).toBe(201);
    const src = await j(res);
    expect(src.status).toBe("pending");
    // The worker's tick picks new sources up.
    expect(await knowledgeTick(deps())).toEqual([src.id]);
    const list = await j(await h.request(`/v1/knowledge-sources?org_id=${orgId}&bot_id=${botId}`, { token: owner.token }));
    expect(list.items[0]).toMatchObject({ status: "ready", documents: 2 });
    expect(list.items[0].error).toMatch(/virus\.exe: Unsupported/);
    registerKnowledgeTools(reg, { db: h.handle.db, embedderFor: async () => hashEmbedder() });
    const r = await search("how many days for refunds");
    expect(r.content).toMatch(/^\[1\] Returns \(Returns\)\nRefunds are accepted within 30 days/);
    expect(r.preview).toContain("Returns");
    expect((await search("Manila hours")).content).toContain("city: Manila; hours: 10-8");
  });

  it("crawls a website within its domain and robots.txt", async () => {
    const src = await j(
      await h.request("/v1/knowledge-sources", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, bot_id: botId, kind: "website", name: "Help site", url: `${base}/` },
      }),
    );
    const r = await syncKnowledgeSource(deps(), src.id);
    expect(r.documents).toBe(2);
    expect(fetched).not.toContain("/private/notes");
    const found = await search("when do orders to Cebu arrive");
    expect(found.content).toContain(`Shipping (Times) ${base}/shipping`);
    expect(found.content).toContain("3 business days");
  });

  it("reads a GitHub repository's documents, shared with the whole workspace, and searches without embeddings too", async () => {
    expect(
      (
        await h.request("/v1/knowledge-sources", {
          method: "POST",
          token: member.token,
          json: { org_id: orgId, kind: "github", name: "Handbook", repo_url: "https://github.com/acme/handbook" },
        })
      ).status,
    ).toBe(403);
    const src = await j(
      await h.request("/v1/knowledge-sources", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, kind: "github", name: "Handbook", repo_url: "https://github.com/acme/handbook" },
      }),
    );
    const r = await syncKnowledgeSource(deps(false), src.id);
    expect(r.documents).toBe(1);
    const [c] = await h.tdb.admin<{ embedding: unknown; url: string }[]>`select embedding, url from public.knowledge_chunks where source_id = ${src.id}`;
    expect(c?.embedding).toBeNull();
    expect(c?.url).toBe("https://github.com/acme/handbook/blob/main/docs/leave.md");
    const plain = new ToolRegistry();
    registerKnowledgeTools(plain, { db: h.handle.db, embedderFor: async () => null });
    const out = await plain.get("knowledge.search")!.execute({ query: "vacation days" } as never, { runId: "r", botId, orgId } as never);
    expect(out.content).toContain("twenty vacation days");
  });

  it("only the bot's managers resync or delete; deleting removes its chunks", async () => {
    const list = await j(await h.request(`/v1/knowledge-sources?org_id=${orgId}&bot_id=${botId}`, { token: member.token }));
    expect(list.items.length).toBe(3);
    const id = list.items[0].id;
    expect((await h.request(`/v1/knowledge-sources/${id}`, { method: "DELETE", token: member.token })).status).toBe(403);
    expect((await j(await h.request(`/v1/knowledge-sources/${id}/sync`, { method: "POST", token: owner.token }))).status).toBe("pending");
    expect((await h.request(`/v1/knowledge-sources/${id}`, { method: "DELETE", token: owner.token })).status).toBe(200);
    const [n] = await h.tdb.admin<{ n: number }[]>`select count(*)::int as n from public.knowledge_chunks where source_id = ${id}`;
    expect(n?.n).toBe(0);
  });
});
