/**
 * The usage line under a reply (D-307): GET /v1/runs/{id}/usage adds up the run and its subruns
 * from the ledger, splits off what came out of credits, and is only for people who can see the run.
 */
import { fileURLToPath } from "node:url";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));

describe("run usage (D-307)", () => {
  let h: Harness;
  let owner: { id: string; token: string };
  let stranger: { id: string; token: string };
  let org: string;
  let bot: string;
  let run: string;

  beforeAll(async () => {
    h = await startHarness({ worker: { fixtures: FIXTURES } });
    owner = await h.user("usage-owner@example.com");
    stranger = await h.user("usage-stranger@example.com");
    const post = async (token: string, path: string, json: unknown) => {
      const r = await h.request(path, { method: "POST", token, json });
      if (r.status >= 300) throw new Error(`${path}: ${r.status} ${await r.text()}`);
      return j(r);
    };
    org = (await post(owner.token, "/v1/orgs", { name: "Usage" })).id;
    await post(stranger.token, "/v1/orgs", { name: "Elsewhere" });
    const credential = (
      await post(owner.token, "/v1/credentials", {
        org_id: org,
        provider: "openrouter",
        label: "k",
        api_key: "sk-usage",
      })
    ).id;
    bot = (
      await post(owner.token, "/v1/bots", {
        org_id: org,
        name: "Counter",
        model_policy: { primary: { credential_id: credential, model: "fixture-main" } },
      })
    ).id;
    const conversation = (await post(owner.token, "/v1/conversations", { bot_id: bot })).id;
    run = (await post(owner.token, `/v1/conversations/${conversation}/messages`, { text: "hello" }))
      .run_id;
    for (let i = 0; i < 100; i++) {
      const r = await j(await h.request(`/v1/runs/${run}`, { token: owner.token }));
      if (r.status === "completed") break;
      await new Promise((res) => setTimeout(res, 200));
    }
  }, 60_000);

  afterAll(async () => {
    await h?.stop();
  });

  it("adds up the run and its subruns and splits off what came out of credits", async () => {
    const db = h.handle.db;
    // Start from a known ledger: whatever the fixture recorded goes, then a run and a subrun spend.
    await db.execute(sql`delete from public.usage_ledger where run_id = ${run}::uuid`);
    const [child] = await db.execute<{ id: string }>(sql`
      insert into public.runs (org_id, bot_id, parent_run_id, trigger, status, tokens_in, tokens_out)
      values (${org}::uuid, ${bot}::uuid, ${run}::uuid, 'subrun', 'completed', 100, 50) returning id`);
    await db.execute(sql`
      insert into public.usage_ledger (org_id, bot_id, run_id, kind, quantity, cost_usd, model, source, billable) values
        (${org}::uuid, ${bot}::uuid, ${run}::uuid, 'tokens_in', 1000, 0.01, 'm', 'key', true),
        (${org}::uuid, ${bot}::uuid, ${run}::uuid, 'tokens_out', 200, 0.02, 'm', 'key', true),
        (${org}::uuid, ${bot}::uuid, ${child?.id}::uuid, 'tokens_in', 500, 0.005, 'm', 'key', true),
        (${org}::uuid, ${bot}::uuid, ${child?.id}::uuid, 'computer_seconds', 30, 0.03, null, 'key', false)`);

    const r = await h.request(`/v1/runs/${run}/usage`, { token: owner.token });
    expect(r.status).toBe(200);
    const u = await j(r);
    expect(u.run_id).toBe(run);
    expect(u.subruns).toBe(1);
    expect(u.cost_usd).toBeCloseTo(0.065, 6);
    expect(u.charged_usd).toBeCloseTo(0.035, 6);
    expect(u.tokens_in).toBeGreaterThanOrEqual(100);
    expect(u.duration_ms).not.toBeNull();
    const tokensIn = u.items.find((i: { kind: string }) => i.kind === "tokens_in");
    expect(tokensIn.quantity).toBe(1500);
    expect(tokensIn.cost_usd).toBeCloseTo(0.015, 6);
    const computer = u.items.find((i: { kind: string }) => i.kind === "computer_seconds");
    expect(computer).toMatchObject({ billable: false, model: null, quantity: 30 });
    // Largest cost first.
    expect(u.items[0].cost_usd).toBeGreaterThanOrEqual(u.items.at(-1).cost_usd);
  });

  it("adds what the server paid for the instance owner only (D-395)", async () => {
    const db = h.handle.db;
    await db.execute(sql`delete from public.usage_ledger where org_id = ${org}::uuid`);
    await db.execute(sql`
      insert into public.usage_ledger (org_id, bot_id, run_id, kind, quantity, cost_usd, upstream_cost_usd, model, source, billable) values
        (${org}::uuid, ${bot}::uuid, ${run}::uuid, 'tokens_in', 1000, 0.014, 0.01, 'm', 'key', true),
        (${org}::uuid, ${bot}::uuid, ${run}::uuid, 'tokens_out', 200, 0.028, 0.02, 'm', 'key', true),
        (${org}::uuid, ${bot}::uuid, ${run}::uuid, 'search_queries', 1, 0.001, null, null, 'key', false)`);
    // The owner made the first account, so they run this instance.
    const mine = await j(await h.request(`/v1/runs/${run}/usage`, { token: owner.token }));
    expect(mine.upstream_cost_usd).toBeCloseTo(0.03, 6);
    const out = mine.items.find((i: { kind: string }) => i.kind === "tokens_out");
    expect(out.upstream_cost_usd).toBeCloseTo(0.02, 6);
    const search = mine.items.find((i: { kind: string }) => i.kind === "search_queries");
    expect(search.upstream_cost_usd).toBeNull();

    // A member of the workspace sees the run and its price, never the cost behind it.
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${org}, ${stranger.id}, 'member')`;
    try {
      const theirs = await j(await h.request(`/v1/runs/${run}/usage`, { token: stranger.token }));
      expect(theirs.charged_usd).toBeCloseTo(0.042, 6);
      expect(theirs).not.toHaveProperty("upstream_cost_usd");
      for (const i of theirs.items) expect(i).not.toHaveProperty("upstream_cost_usd");
    } finally {
      await h.tdb
        .admin`delete from public.memberships where org_id = ${org} and user_id = ${stranger.id}`;
    }
  });

  it("is not found for someone outside the workspace", async () => {
    const r = await h.request(`/v1/runs/${run}/usage`, { token: stranger.token });
    expect(r.status).toBe(404);
  });
});
