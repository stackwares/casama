/** Memory backends (D-137): Supermemory and Honcho behind the MemoryStore interface. */
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { builtinTools, memoryStoreFor, PostgresMemoryStore } from "@kasama/agent";
import { unzipSync, strFromU8 } from "fflate";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { purgeDueAccounts } from "../src/services/privacy.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

type Doc = { id: string; content: string; containerTags: string[]; metadata: Record<string, unknown> };
const sm = { docs: [] as Doc[], auth: [] as string[], bulkDeleted: [] as string[][] };
type Msg = { id: string; content: string; peer_id: string; session: string; metadata: Record<string, unknown> };
const ho = { msgs: [] as Msg[], sessions: new Set<string>(), deletedSessions: [] as string[], workspaces: new Set<string>() };

let smServer: Server;
let hoServer: Server;
let smUrl = "";
let hoUrl = "";
let h: Harness;

async function body(req: import("node:http").IncomingMessage) {
  const chunks: Buffer[] = [];
  for await (const c of req) chunks.push(c as Buffer);
  const t = Buffer.concat(chunks).toString();
  return t ? JSON.parse(t) : {};
}

beforeAll(async () => {
  // A fake Supermemory (v3 documents and search).
  smServer = createServer(async (req, res) => {
    sm.auth.push(String(req.headers.authorization));
    const b = await body(req);
    const send = (x: unknown) => res.writeHead(200, { "content-type": "application/json" }).end(JSON.stringify(x));
    const url = req.url ?? "";
    if (req.method === "POST" && url === "/v3/documents") {
      const d = { id: `doc_${sm.docs.length + 1}`, content: b.content, containerTags: b.containerTags, metadata: b.metadata ?? {} };
      sm.docs.push(d);
      return send({ id: d.id, status: "queued" });
    }
    if (req.method === "POST" && url === "/v3/documents/list")
      return send({ memories: sm.docs.filter((d) => !b.containerTags || d.containerTags.some((t: string) => b.containerTags.includes(t))) });
    if (req.method === "POST" && url === "/v3/search") {
      const words = String(b.q).toLowerCase().split(/\s+/);
      const hits = sm.docs.filter((d) => d.containerTags.some((t) => b.containerTags.includes(t)) && words.some((w) => d.content.toLowerCase().includes(w)));
      return send({ results: hits.map((d) => ({ documentId: d.id, chunks: [{ content: d.content, score: 0.9 }], metadata: d.metadata })) });
    }
    if (req.method === "PATCH" && url.startsWith("/v3/documents/")) {
      const d = sm.docs.find((x) => x.id === decodeURIComponent(url.split("/").pop() as string));
      if (d) Object.assign(d, b.content !== undefined ? { content: b.content } : {}, { metadata: { ...d.metadata, ...b.metadata } });
      return send({ id: d?.id });
    }
    if (req.method === "DELETE" && url === "/v3/documents/bulk") {
      sm.bulkDeleted.push(b.containerTags);
      sm.docs = sm.docs.filter((d) => !d.containerTags.some((t) => b.containerTags.includes(t)));
      return send({ success: true });
    }
    if (req.method === "DELETE" && url.startsWith("/v3/documents/")) {
      sm.docs = sm.docs.filter((x) => x.id !== decodeURIComponent(url.split("/").pop() as string));
      return res.writeHead(204).end();
    }
    res.writeHead(404).end("{}");
  }).listen(0, "127.0.0.1");
  // A fake Honcho (v2 workspaces, peers, sessions, messages, search).
  hoServer = createServer(async (req, res) => {
    const b = await body(req);
    const send = (x: unknown) => res.writeHead(200, { "content-type": "application/json" }).end(JSON.stringify(x));
    const url = req.url ?? "";
    let m: RegExpMatchArray | null;
    if (req.method === "POST" && url === "/v2/workspaces") return ho.workspaces.add(b.id), send({ id: b.id });
    if ((m = url.match(/^\/v2\/workspaces\/([^/]+)\/peers$/))) return send({ id: b.id });
    if ((m = url.match(/^\/v2\/workspaces\/([^/]+)\/sessions$/))) return ho.sessions.add(b.id), send({ id: b.id });
    if ((m = url.match(/^\/v2\/workspaces\/[^/]+\/sessions\/([^/]+)\/messages$/)) && req.method === "POST") {
      const out = (b.messages as Array<{ peer_id: string; content: string; metadata: Record<string, unknown> }>).map((x) => {
        const msg = { id: `msg_${ho.msgs.length + 1}`, session: m![1] as string, ...x };
        ho.msgs.push(msg);
        return msg;
      });
      return send(out);
    }
    if ((m = url.match(/^\/v2\/workspaces\/[^/]+\/sessions\/([^/]+)\/messages\/list$/)))
      return send({ items: ho.msgs.filter((x) => x.session === m![1]), page: 1 });
    if ((m = url.match(/^\/v2\/workspaces\/[^/]+\/sessions\/([^/]+)\/messages\/([^/]+)$/)) && req.method === "PUT") {
      const msg = ho.msgs.find((x) => x.id === m![2]);
      if (msg) msg.metadata = { ...msg.metadata, ...b.metadata };
      return send(msg ?? {});
    }
    if ((m = url.match(/^\/v2\/workspaces\/[^/]+\/sessions\/([^/]+)$/)) && req.method === "DELETE") return ho.deletedSessions.push(m[1] as string), send({});
    if (url.match(/^\/v2\/workspaces\/[^/]+\/search$/)) {
      const q = String(b.query).toLowerCase();
      return send(ho.msgs.filter((x) => x.session === b.filters?.session_id && q.split(/\s+/).some((w) => x.content.toLowerCase().includes(w))));
    }
    res.writeHead(404).end("{}");
  }).listen(0, "127.0.0.1");
  await Promise.all([once(smServer, "listening"), once(hoServer, "listening")]);
  smUrl = `http://127.0.0.1:${(smServer.address() as AddressInfo).port}`;
  hoUrl = `http://127.0.0.1:${(hoServer.address() as AddressInfo).port}`;
  h = await startHarness();
}, 60_000);
afterAll(async () => {
  await h?.stop();
  smServer?.close();
  hoServer?.close();
});

const ctx = (orgId: string, botId: string, runId: string) => ({ runId, botId, orgId, output: async () => {}, emit: async () => {} }) as never;

describe("memory backends", () => {
  it("Supermemory: copy existing memories, then tools, the memory screen, export and account deletion use it", async () => {
    const u = await h.user("sm@example.com");
    const orgId = (await j(await h.request("/v1/orgs", { method: "POST", token: u.token, json: { name: "SM" } }))).id;
    const botId = (await j(await h.request("/v1/bots", { method: "POST", token: u.token, json: { org_id: orgId, name: "Sam" } }))).id;
    await new PostgresMemoryStore(h.handle.db, null).write({ orgId, botId, kind: "preference", content: "Likes window seats", pinned: true });

    const bad = await h.request(`/v1/orgs/${orgId}/memory-backend`, { method: "PUT", token: u.token, json: { provider: "supermemory", api_key: "sm_secret_key", base_url: "http://127.0.0.1:1" } });
    expect(bad.status).toBe(400);
    const set = await h.request(`/v1/orgs/${orgId}/memory-backend`, {
      method: "PUT",
      token: u.token,
      json: { provider: "supermemory", api_key: "sm_secret_key", base_url: smUrl, copy_existing: true },
    });
    expect(set.status).toBe(200);
    expect(await j(set)).toMatchObject({ provider: "supermemory", base_url: smUrl });
    expect(sm.auth.at(-1)).toBe("Bearer sm_secret_key");
    expect(sm.docs.map((d) => [d.content, d.containerTags[0], d.metadata.pinned])).toEqual([["Likes window seats", `kasama_bot_${botId}`, true]]);

    // The bot's memory tools go to Supermemory.
    const tools = builtinTools({ db: h.handle.db, memory: (o) => memoryStoreFor(h.handle.db, o, null) });
    const [r] = await h.tdb.admin<{ id: string }[]>`insert into public.runs (org_id, bot_id, created_by) values (${orgId}, ${botId}, ${u.id}) returning id`;
    await tools.get("memory.write")!.execute({ kind: "fact", content: "Flies out of SFO" } as never, ctx(orgId, botId, r!.id));
    await tools.get("memory.write")!.execute({ kind: "fact", content: "flies out of SFO!" } as never, ctx(orgId, botId, r!.id));
    expect(sm.docs).toHaveLength(2);
    const found = await tools.get("memory.search")!.execute({ query: "which airport SFO" } as never, ctx(orgId, botId, r!.id));
    expect(found.content).toContain("Flies out of SFO");
    expect(found.content).toContain("Likes window seats"); // pinned
    expect(await h.tdb.admin`select 1 from public.memories where bot_id = ${botId} and content = 'Flies out of SFO'`).toHaveLength(0);

    // The memory screen: list, edit, unpin, delete.
    const list = (await j(await h.request(`/v1/bots/${botId}/memories`, { token: u.token }))).items as Array<{ id: string; content: string; pinned: boolean }>;
    expect(list.map((m) => m.content)).toEqual(["Likes window seats", "Flies out of SFO"]);
    const edited = await j(await h.request(`/v1/bots/${botId}/memories/doc_2`, { method: "PATCH", token: u.token, json: { content: "Flies out of OAK" } }));
    expect(edited.content).toBe("Flies out of OAK");
    expect(sm.docs.find((d) => d.id === "doc_2")?.content).toBe("Flies out of OAK");
    expect((await h.request(`/v1/bots/${botId}/memories/doc_1`, { method: "DELETE", token: u.token })).status).toBe(200);
    expect(sm.docs.map((d) => d.id)).toEqual(["doc_2"]);

    // The privacy export has the provider's memories.
    const zip = unzipSync(new Uint8Array(await (await h.request("/v1/me/export", { token: u.token })).arrayBuffer()));
    const memFile = Object.keys(zip).find((k) => k.endsWith("/memories.json"))!;
    expect(JSON.parse(strFromU8(zip[memFile]!)).map((m: { content: string }) => m.content)).toEqual(["Flies out of OAK"]);

    // Account deletion removes them from Supermemory.
    await h.tdb.admin`insert into public.account_deletions (user_id, purge_after) values (${u.id}, now() - interval '1 minute')`;
    await purgeDueAccounts(h.handle.db);
    expect(sm.bulkDeleted).toEqual([[`kasama_bot_${botId}`]]);
    expect(sm.docs).toHaveLength(0);
  });

  it("Honcho: memories are messages in the bot's session; deletes hide them; members can't change the backend", async () => {
    const u = await h.user("ho@example.com");
    const orgId = (await j(await h.request("/v1/orgs", { method: "POST", token: u.token, json: { name: "HO" } }))).id;
    const botId = (await j(await h.request("/v1/bots", { method: "POST", token: u.token, json: { org_id: orgId, name: "Hal" } }))).id;
    const member = await h.user("ho-member@example.com");
    await h.tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
    expect((await h.request(`/v1/orgs/${orgId}/memory-backend`, { method: "PUT", token: member.token, json: { provider: "honcho", api_key: "hch_key_123", base_url: hoUrl } })).status).toBe(403);
    expect((await h.request(`/v1/orgs/${orgId}/memory-backend`, { method: "PUT", token: u.token, json: { provider: "honcho", api_key: "hch_key_123", base_url: hoUrl, workspace: "acme" } })).status).toBe(200);
    expect(ho.workspaces.has("acme")).toBe(true);

    const store = await memoryStoreFor(h.handle.db, orgId, null);
    expect(store.provider).toBe("honcho");
    const w = await store.write({ orgId, botId, kind: "fact", content: "Deploys on Fridays are banned" });
    expect(ho.sessions.has(`kasama-${botId}`)).toBe(true);
    expect(ho.msgs.find((m) => m.id === w.id)).toMatchObject({ peer_id: `bot-${botId}`, metadata: { kind: "fact" } });
    expect((await store.recall(botId, "friday deploys")).map((m) => m.content)).toEqual(["Deploys on Fridays are banned"]);
    await store.update(botId, w.id, { pinned: true, content: "No deploys on Fridays" });
    expect((await store.list(botId))[0]).toMatchObject({ content: "No deploys on Fridays", pinned: true });
    await store.delete(botId, w.id);
    expect(await store.list(botId)).toEqual([]);
    await store.deleteAll([botId]);
    expect(ho.deletedSessions).toContain(`kasama-${botId}`);

    // Back to built-in memory.
    expect((await j(await h.request(`/v1/orgs/${orgId}/memory-backend`, { method: "DELETE", token: u.token }))).provider).toBe("postgres");
    expect((await memoryStoreFor(h.handle.db, orgId, null)).provider).toBe("postgres");
  });
});
