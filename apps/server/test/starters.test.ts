/** Starter requests for an empty chat (D-338): the route, the worker's refresh and the model call. */
import {
  backgroundComplete,
  type CredentialResolver,
  type GatewayEvent,
  type ModelRequest,
  refreshStarters,
} from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let other: { id: string; token: string };
let orgId: string;
let botId: string;
const enqueued: string[][] = [];
const CRED = "11111111-2222-4333-8444-555555555555";

const AI_REPLY = JSON.stringify([
  { emoji: "🌱", text: "Plan a calm Sunday for me" },
  { emoji: "📬", text: "Sum up my unread emails" },
  { emoji: "🧁", text: "Find a quick cupcake recipe" },
  { emoji: "🎁", text: "Help me pick a birthday gift" },
]);

/** A model that answers with [reply] and counts the calls. */
const scripted = (reply: string) => {
  const calls: ModelRequest[] = [];
  return {
    calls,
    gateway: {
      async *stream(req: ModelRequest): AsyncIterable<GatewayEvent> {
        calls.push(req);
        yield { type: "text", text: reply };
        yield {
          type: "finish",
          usage: { inputTokens: 900, outputTokens: 120 },
          finishReason: "stop",
          model: req.model.model,
        };
      },
    },
  };
};
const credentials = {
  platformChoice: () => null,
  resolve: async (_org: string, c: { credential_id: string; model: string }) => ({
    provider: "openai" as const,
    model: c.model,
    apiKey: "sk-test",
    credentialId: c.credential_id,
  }),
} as unknown as CredentialResolver;

const getStarters = async (token = owner.token, bot = botId) =>
  h.request(`/v1/bots/${bot}/starters`, { token });

beforeAll(async () => {
  h = await startHarness({});
  h.deps.workflows.refreshStarters = async (...args) => {
    enqueued.push(args);
  };
  owner = await h.user("starters-owner@example.com");
  other = await h.user("starters-other@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Home" } }),
    )
  ).id;
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Casama" },
      }),
    )
  ).id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

describe("starter requests", () => {
  it("a first open gets everyday starters from rules and asks the worker for a personal list", async () => {
    const res = await getStarters();
    expect(res.status).toBe(200);
    const body = await j(res);
    expect(body.source).toBe("rules");
    expect(body.refreshing).toBe(true);
    expect(body.items).toHaveLength(4);
    for (const s of body.items) {
      expect(s.text.length).toBeGreaterThan(5);
      expect(s.text).not.toMatch(/workspace|computer|folder/i);
    }
    expect(enqueued.at(-1)).toEqual([owner.id, orgId, botId]);
  });

  it("someone outside the workspace can't read them", async () => {
    expect((await getStarters(other.token)).status).toBe(404);
  });

  it("without a model the worker saves rules, and the route serves them without asking again", async () => {
    const saved = await refreshStarters({ db: h.deps.db }, { userId: owner.id, orgId, botId });
    expect(saved?.source).toBe("rules");
    enqueued.length = 0;
    const body = await j(await getStarters());
    expect(body).toMatchObject({ source: "rules", refreshing: false });
    expect(body.items).toEqual(saved?.items);
    expect(enqueued).toHaveLength(0);
  });

  it("with a model it writes them from the person's signals, records the cost and serves them", async () => {
    await h.tdb.admin`
      update public.bots set model_policy = jsonb_build_object('primary', jsonb_build_object('credential_id', ${CRED}::text, 'model', 'gpt-test'))
      where id = ${botId}`;
    await h.tdb
      .admin`update public.profiles set timezone = 'Asia/Manila' where user_id = ${owner.id}`;
    // The rules list is new; an old one is what gets written again.
    await h.tdb
      .admin`update public.chat_starters set generated_at = now() - interval '4 hours' where bot_id = ${botId}`;
    const model = scripted(AI_REPLY);
    const saved = await refreshStarters(
      {
        db: h.deps.db,
        complete: (input) =>
          backgroundComplete({ db: h.deps.db, gateway: model.gateway, credentials }, input),
      },
      { userId: owner.id, orgId, botId },
    );
    expect(saved?.source).toBe("ai");
    expect(model.calls).toHaveLength(1);
    const prompt = String(model.calls[0]?.messages[0]?.content);
    expect(prompt).toContain("Asia/Manila");
    expect(prompt).toContain("Connected apps: none");
    expect(model.calls[0]?.system[0]).toContain("JSON array");
    const ledger = await h.tdb.admin<
      { kind: string; run_id: string | null; meta: { purpose?: string } }[]
    >`
      select kind, run_id, meta from public.usage_ledger where bot_id = ${botId} order by kind`;
    expect(ledger.map((l) => l.kind)).toEqual(["tokens_in", "tokens_out"]);
    expect(ledger.every((l) => l.run_id === null && l.meta.purpose === "starters")).toBe(true);
    const body = await j(await getStarters());
    expect(body).toMatchObject({ source: "ai", refreshing: false });
    expect(body.items[0]).toEqual({ emoji: "🌱", text: "Plan a calm Sunday for me" });
    // Fresh: a second refresh doesn't call the model.
    await refreshStarters(
      {
        db: h.deps.db,
        complete: (input) =>
          backgroundComplete({ db: h.deps.db, gateway: model.gateway, credentials }, input),
      },
      { userId: owner.id, orgId, botId },
    );
    expect(model.calls).toHaveLength(1);
  });

  it("an unusable reply falls back to rules; a bot over its daily budget never calls the model", async () => {
    await h.tdb
      .admin`update public.chat_starters set generated_at = now() - interval '1 day' where bot_id = ${botId}`;
    const bad = scripted("Sure! Here are some ideas: plan your day.");
    const deps = {
      db: h.deps.db,
      complete: (input: Parameters<typeof backgroundComplete>[1]) =>
        backgroundComplete({ db: h.deps.db, gateway: bad.gateway, credentials }, input),
    };
    expect((await refreshStarters(deps, { userId: owner.id, orgId, botId }))?.source).toBe("rules");
    expect(bad.calls).toHaveLength(1);
    await h.tdb
      .admin`update public.bots set budget = '{"daily_usd": 0.0000001}'::jsonb where id = ${botId}`;
    await h.tdb
      .admin`update public.chat_starters set generated_at = now() - interval '1 day' where bot_id = ${botId}`;
    expect((await refreshStarters(deps, { userId: owner.id, orgId, botId }))?.source).toBe("rules");
    expect(bad.calls).toHaveLength(1);
  });

  it("people who leave the workspace lose its lists, and the worker writes none for them", async () => {
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${other.id}, 'member')`;
    await h.tdb
      .admin`update public.bots set budget = '{}'::jsonb, model_policy = '{}'::jsonb where id = ${botId}`;
    expect(
      (await refreshStarters({ db: h.deps.db }, { userId: other.id, orgId, botId }))?.source,
    ).toBe("rules");
    await h.tdb
      .admin`delete from public.memberships where user_id = ${other.id} and org_id = ${orgId}`;
    const left = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.chat_starters where user_id = ${other.id}`;
    expect(left[0]?.n).toBe(0);
    expect(await refreshStarters({ db: h.deps.db }, { userId: other.id, orgId, botId })).toBeNull();
    // The owner's own list stays.
    expect((await getStarters()).status).toBe(200);
  });
});
