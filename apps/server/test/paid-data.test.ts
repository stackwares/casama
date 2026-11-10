/** Paid data services (D-138): Treg catalog and calls, the price on the approval card, the ledger. */
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import { registerDataTools, ToolRegistry, TregProvider } from "@kasama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/data.json", import.meta.url));
const seen: Array<{
  method: string;
  url: string;
  token: string;
  maxCost: string | undefined;
  body: string;
}> = [];
let treg: Server;
let tregUrl = "";
let h: Harness;
let owner: { id: string; token: string };
let orgId = "";
let credId = "";

const CATALOG = [
  {
    id: "places.search",
    name: "Places search",
    description: "Find places near a spot",
    method: "GET",
    cost: { type: "per_call", usd_per_call: 0.004 },
  },
  {
    id: "hunter.email-finder",
    name: "Email finder",
    description: "Find a work email",
    method: "GET",
    cost: { type: "per_call", usd_per_call: 0.02 },
  },
];

beforeAll(async () => {
  treg = createServer(async (req, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    const url = new URL(req.url ?? "/", "http://x");
    seen.push({
      method: req.method ?? "",
      url: req.url ?? "",
      token: String(req.headers["x-treg-token"]),
      maxCost: req.headers["x-treg-route-max-cost"] as string | undefined,
      body: Buffer.concat(chunks).toString(),
    });
    if (req.headers["x-treg-token"] === "broke" && url.pathname.startsWith("/call/"))
      return res
        .writeHead(402, { "x-treg-error": "1", "content-type": "application/json" })
        .end(JSON.stringify({ code: "insufficient_balance", balance_micro: 0 }));
    if (url.pathname === "/catalog/search") {
      const q = (url.searchParams.get("q") ?? "").toLowerCase();
      return res.writeHead(200, { "content-type": "application/json" }).end(
        JSON.stringify({
          results: CATALOG.filter((c) =>
            `${c.name} ${c.description}`.toLowerCase().includes(q.split(" ")[0] ?? ""),
          ),
        }),
      );
    }
    if (url.pathname.startsWith("/catalog/endpoints/")) {
      const e = CATALOG.find(
        (c) => c.id === decodeURIComponent(url.pathname.split("/").pop() as string),
      );
      return e
        ? res.writeHead(200, { "content-type": "application/json" }).end(JSON.stringify(e))
        : res.writeHead(404).end();
    }
    if (url.pathname === "/call/places.search")
      return res
        .writeHead(200, {
          "content-type": "application/json",
          "x-treg-cost-micro": "4000",
          "x-treg-call-id": "call_123",
        })
        .end(JSON.stringify({ places: [{ name: "Blue Bottle" }, { name: "Sightglass" }] }));
    res.writeHead(404).end();
  }).listen(0, "127.0.0.1");
  await once(treg, "listening");
  tregUrl = `http://127.0.0.1:${(treg.address() as AddressInfo).port}`;
  h = await startHarness({
    worker: {
      fixtures: FIXTURES,
      egressExemptCidrs: ["127.0.0.1/32"],
      providerBases: { treg: tregUrl },
    },
  });
  owner = await h.user("data@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Data" } }),
    )
  ).id;
  credId = (
    await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, provider: "openrouter", label: "m", api_key: "sk-or-data-key" },
      }),
    )
  ).id;
}, 90_000);
afterAll(async () => {
  treg?.close();
  await h?.stop();
});

const waitFor = async <T>(
  fn: () => Promise<T | undefined | null | false>,
  what: string,
  ms = 30_000,
): Promise<T> => {
  const until = Date.now() + ms;
  for (;;) {
    const v = await fn();
    if (v) return v;
    if (Date.now() > until) throw new Error(`timed out waiting for ${what}`);
    await new Promise((r) => setTimeout(r, 100));
  }
};

describe("paid data", () => {
  it("asks first with the price, then buys through the workspace's Treg key (no markup)", async () => {
    const add = await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "treg", label: "Treg", api_key: "treg_own_key" },
    });
    expect(add.status).toBe(201);
    const bot = await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Scout",
          autonomy: "ask_risky",
          model_policy: { primary: { credential_id: credId, model: "fixture-main" } },
        },
      }),
    );
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: bot.id },
      }),
    );
    const runId = (
      await j(
        await h.request(`/v1/conversations/${conv.id}/messages`, {
          method: "POST",
          token: owner.token,
          json: { text: "Find coffee shops near the Ferry Building" },
        }),
      )
    ).run_id;

    // Under the default autonomy a purchase always asks first, and the card shows the price.
    const approval = await waitFor(async () => {
      const st = await j(await h.request(`/v1/runs/${runId}`, { token: owner.token }));
      if (st.status === "failed" || st.status === "completed") {
        const ev = await j(
          await h.request(`/v1/runs/${runId}/events?limit=100`, { token: owner.token }),
        );
        throw new Error(
          `run ${st.status}: ${JSON.stringify(ev.items.map((e: { type: string; payload: unknown }) => [e.type, e.payload])).slice(0, 2000)}`,
        );
      }
      const p = await j(
        await h.request(`/v1/approvals?org_id=${orgId}&status=pending`, { token: owner.token }),
      );
      return p.items.find((a: { run_id: string }) => a.run_id === runId);
    }, "approval");
    expect(approval.summary).toContain(
      "Scout wants to run data.call: places.search for $0.0040 per call",
    );
    expect(approval.args_redacted).toMatchObject({
      service: "data.places.search",
      price: "$0.0040 per call",
    });
    expect(seen.some((s) => s.url.startsWith("/call/"))).toBe(false);

    await h.request(`/v1/approvals/${approval.id}/decision`, {
      method: "POST",
      token: owner.token,
      json: { decision: "approved" },
    });
    await waitFor(
      async () =>
        (await j(await h.request(`/v1/runs/${runId}`, { token: owner.token }))).status ===
        "completed",
      "run",
    );
    const call = seen.find((s) => s.url.startsWith("/call/places.search"))!;
    expect(call).toMatchObject({ method: "GET", token: "treg_own_key", maxCost: "0.0100" });
    expect(call.url).toContain("q=coffee+near+Ferry+Building");
    const [u] = await h.tdb.admin<
      {
        cost_usd: string;
        billable: boolean;
        meta: { call_id: string; provider_cost_usd: number };
      }[]
    >`
      select cost_usd, billable, meta from public.usage_ledger where org_id = ${orgId} and kind = 'data_calls'`;
    expect(Number(u!.cost_usd)).toBeCloseTo(0.004, 6);
    expect(u!.billable).toBe(false);
    expect(u!.meta).toMatchObject({ call_id: "call_123", provider_cost_usd: 0.004 });
  }, 60_000);

  it("resale on Kasama Cloud charges credits cost plus 20%; Treg refusals are explained", async () => {
    const reg = new ToolRegistry();
    registerDataTools(reg, {
      db: h.handle.db,
      dataFor: async () => ({
        provider: new TregProvider({ key: "kasama_resale", base: tregUrl }),
        resale: true,
      }),
    });
    const [bot] = await h.tdb.admin<
      { id: string }[]
    >`select id from public.bots where org_id = ${orgId} limit 1`;
    const [run] = await h.tdb.admin<
      { id: string }[]
    >`insert into public.runs (org_id, bot_id, created_by) values (${orgId}, ${bot!.id}, ${owner.id}) returning id`;
    const ctx = {
      runId: run!.id,
      botId: bot!.id,
      orgId,
      output: async () => {},
      emit: async () => {},
    } as never;
    const found = await reg.get("data.search")!.execute({ query: "email" } as never, ctx);
    expect(found.content).toContain(
      "hunter.email-finder (data.hunter.email-finder): Email finder. $0.0240 per call (includes Kasama's 20%)",
    );
    await reg
      .get("data.call")!
      .execute({ endpoint: "places.search", params: { q: "tea" } } as never, ctx);
    const [u] = await h.tdb.admin<
      { cost_usd: string; billable: boolean }[]
    >`select cost_usd, billable from public.usage_ledger where run_id = ${run!.id}`;
    expect(Number(u!.cost_usd)).toBeCloseTo(0.0048, 6);
    expect(u!.billable).toBe(true);

    const broke = new ToolRegistry();
    registerDataTools(broke, {
      db: h.handle.db,
      dataFor: async () => ({
        provider: new TregProvider({ key: "broke", base: tregUrl }),
        resale: false,
      }),
    });
    await expect(
      broke.get("data.call")!.execute({ endpoint: "places.search" } as never, ctx),
    ).rejects.toThrow(/doesn't have enough balance/);
    const none = new ToolRegistry();
    registerDataTools(none, { db: h.handle.db, dataFor: async () => null });
    await expect(none.get("data.search")!.execute({ query: "x" } as never, ctx)).rejects.toThrow(
      /Add a Treg key/,
    );
  });
});
