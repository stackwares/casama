import { createServer, type IncomingMessage } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));

/** One local server standing in for OpenAI dictation and Gemini (their REST shapes). */
async function mockVoiceProviders() {
  const calls: Array<{ path: string; headers: IncomingMessage["headers"]; body: string }> = [];
  const server = createServer((req, res) => {
    const chunks: Buffer[] = [];
    req.on("data", (c) => chunks.push(c));
    req.on("end", () => {
      const body = Buffer.concat(chunks);
      const path = (req.url ?? "").split("?")[0] ?? "";
      calls.push({ path, headers: req.headers, body: body.toString("latin1") });
      const json = (o: unknown) => {
        res.writeHead(200, { "content-type": "application/json" });
        res.end(JSON.stringify(o));
      };
      if (path === "/v1/audio/transcriptions")
        return json({ text: "remind me to water the plants", duration: 3.2 });
      if (path === "/v1beta/auth_tokens") return json({ name: "auth_tokens/gemini-test-token" });
      res.writeHead(404);
      res.end();
    });
  });
  await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
  return {
    url: `http://127.0.0.1:${(server.address() as AddressInfo).port}`,
    calls,
    close: () => server.close(),
  };
}

/**
 * The server's own Google AI key (GOOGLE_AI_API_KEY): workspaces without a live-call key of their
 * own still get calls, and on Casama Cloud (billing on) those calls come out of credits.
 */
describe("live calls included on Casama Cloud", () => {
  let mock: Awaited<ReturnType<typeof mockVoiceProviders>>;
  const stacks: Harness[] = [];
  afterAll(async () => {
    for (const h of stacks) await h.stop();
    mock?.close();
  });
  beforeAll(async () => {
    mock = await mockVoiceProviders();
  });

  async function workspace(h: Harness, email: string) {
    const owner = await h.user(email);
    const orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Calls" },
        }),
      )
    ).id as string;
    const llm = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, provider: "openrouter", label: "llm", api_key: "sk-llm" },
      }),
    );
    const bot = await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Vox",
          model_policy: { primary: { credential_id: llm.id, model: "fixture-main" } },
        },
      }),
    );
    return { owner, orgId, botId: bot.id as string };
  }
  const start = (h: Harness, token: string, botId: string) =>
    h.request("/v1/voice/session", { method: "POST", token, json: { bot_id: botId } });

  it("Casama Cloud: calls on the server's key are paid from credits, and stop when they run out", async () => {
    const h = await startHarness({
      env: { GOOGLE_AI_API_KEY: "server-gemini-key", BILLING_ENABLED: "true" },
      worker: { fixtures: FIXTURES, providerBases: { gemini: mock.url, openai: mock.url } },
    });
    stacks.push(h);
    const w = await workspace(h, "cloud-calls@example.com");
    const drain = async () => {
      const [b] = await h.handle.db.execute<{ b: string | null }>(
        sql`select balance_after as b from public.credit_ledger where org_id = ${w.orgId}::uuid order by seq desc limit 1`,
      );
      const bal = Number(b?.b ?? 0);
      if (bal > 0)
        await h.handle.db.execute(
          sql`select public.credit_apply(${w.orgId}::uuid, ${-bal}, 'adjustment', 'test-drain')`,
        );
    };
    await drain();
    const none = await start(h, w.owner.token, w.botId);
    expect(none.status).toBe(402);
    expect((await j(none)).code).toBe("out_of_credits");

    await h.handle.db.execute(
      sql`select public.credit_apply(${w.orgId}::uuid, 5, 'adjustment', 'test-topup')`,
    );
    const res = await start(h, w.owner.token, w.botId);
    expect(res.status).toBe(200);
    const s = await j(res);
    const saved = await h.request("/v1/voice/transcript", {
      method: "POST",
      token: w.owner.token,
      json: {
        conversation_id: s.conversation_id,
        turns: [{ role: "user", text: "hi" }],
        seconds: 60,
        provider: "gemini",
        usage: {
          input_audio_tokens: 1500,
          input_text_tokens: 0,
          output_audio_tokens: 1500,
          output_text_tokens: 0,
        },
      },
    });
    expect(saved.status, await saved.clone().text()).toBe(200);
    const rows = await h.handle.db.execute<{
      billable: boolean;
      cost_usd: string;
      meta: { key?: string; provider_cost_usd?: number; hold?: boolean; settled?: boolean };
    }>(
      sql`select billable, cost_usd, meta from public.usage_ledger where org_id = ${w.orgId}::uuid and kind = 'voice_seconds' order by created_at`,
    );
    // A hold when the call started (D-248), settled by the saved call's real price.
    const [hold, row] = rows;
    expect(hold?.meta.hold).toBe(true);
    expect(hold?.meta.settled).toBe(true);
    expect(row?.billable).toBe(true);
    expect(row?.meta.key).toBe("server");
    // Google's price times the markup (D-244); Google's price is kept in meta.
    const google = 1500 * 3e-6 + 1500 * 12e-6;
    expect(row?.meta.provider_cost_usd).toBeCloseTo(google, 6);
    const total = rows.reduce((n, r) => n + Number(r.cost_usd), 0);
    expect(total).toBeCloseTo(google * 1.3, 6);

    // A call the app reports as nothing is still charged its time on the clock, at Gemini's
    // listening rate: here 10 minutes.
    const again = await j(await start(h, w.owner.token, w.botId));
    await h.handle.db.execute(sql`
      update public.usage_ledger set created_at = now() - interval '10 minutes'
      where org_id = ${w.orgId}::uuid and (meta->>'hold')::boolean and meta->>'conversation_id' = ${again.conversation_id}`);
    const fake = await h.request("/v1/voice/transcript", {
      method: "POST",
      token: w.owner.token,
      json: { conversation_id: again.conversation_id, turns: [], seconds: 1, provider: "gemini" },
    });
    expect(fake.status).toBe(200);
    const [sum] = await h.handle.db.execute<{ total: string }>(sql`
      select sum(cost_usd)::text as total from public.usage_ledger
      where org_id = ${w.orgId}::uuid and kind = 'voice_seconds' and created_at > now() - interval '11 minutes'
        and (meta->>'conversation_id' = ${again.conversation_id} or meta->>'clock_seconds' is not null)
        and not (meta->>'clock_seconds' is not null and (meta->>'clock_seconds')::int < 500)`);
    expect(Number(sum?.total)).toBeGreaterThanOrEqual(10 * 0.0045 * 1.3 - 1e-6);
  }, 120_000);
});
