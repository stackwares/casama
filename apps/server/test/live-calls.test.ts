import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import { VOICE_PRICES } from "@casama/agent";
import { contentKeys } from "@casama/db";
import { setCallLimits } from "@casama/domain";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { endSilentCalls } from "../src/billing/live-calls.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));

/** Gemini Live tokens, keeping each minted setup so the locked instructions can be read. */
async function mockGemini() {
  const minted: Array<Record<string, unknown>> = [];
  const server = createServer((req, res) => {
    const chunks: Buffer[] = [];
    req.on("data", (c) => chunks.push(c));
    req.on("end", () => {
      const path = (req.url ?? "").split("?")[0] ?? "";
      if (path === "/v1beta/auth_tokens") {
        minted.push(JSON.parse(Buffer.concat(chunks).toString("utf8")));
        res.writeHead(200, { "content-type": "application/json" });
        return res.end(JSON.stringify({ name: "auth_tokens/live-call-test" }));
      }
      res.writeHead(404);
      res.end();
    });
  });
  await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
  return {
    url: `http://127.0.0.1:${(server.address() as AddressInfo).port}`,
    minted,
    close: () => server.close(),
  };
}

/** Live calls that keep going (D-327): the server's record of a call, turns as they happen, the sweep. */
describe("live calls (D-327)", () => {
  let mock: Awaited<ReturnType<typeof mockGemini>>;
  // One stack per file (the worker's workflow engine is process-wide), on Casama Cloud: calls on
  // the server's key are paid from credits.
  let h: Harness;
  beforeAll(async () => {
    mock = await mockGemini();
    h = await startHarness({
      env: { GOOGLE_AI_API_KEY: "server-gemini-key", BILLING_ENABLED: "true" },
      worker: { fixtures: FIXTURES, providerBases: { gemini: mock.url } },
    });
  }, 120_000);
  afterAll(async () => {
    await h?.stop();
    mock?.close();
  });

  async function workspace(email: string) {
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
          name: "Ava",
          model_policy: { primary: { credential_id: llm.id, model: "fixture-main" } },
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
    await h.handle.db.execute(
      sql`select public.credit_apply(${orgId}::uuid, 5, 'adjustment', 'test-topup')`,
    );
    return { owner, orgId, botId: bot.id as string, convId: conv.id as string };
  }

  const startCall = async (token: string, botId: string, conversationId?: string) => {
    const res = await h.request("/v1/voice/session", {
      method: "POST",
      token,
      json: { bot_id: botId, ...(conversationId ? { conversation_id: conversationId } : {}) },
    });
    expect(res.status, await res.clone().text()).toBe(200);
    return j(res);
  };

  it("a call gets a server record and hears the conversation's last turns", async () => {
    const w = await workspace("live-context@example.com");
    // Two earlier turns, typed in the chat.
    for (const [role, text] of [
      ["user", "Book the dentist for Tuesday"],
      ["assistant", "Booked for Tuesday at 10."],
    ] as const)
      await h.handle.db.execute(sql`
        insert into public.messages (org_id, conversation_id, role, author_user_id, content)
        values (${w.orgId}::uuid, ${w.convId}::uuid, ${role}, ${role === "user" ? w.owner.id : null}::uuid,
                ${JSON.stringify([{ type: "text", text }])}::jsonb)`);
    const before = mock.minted.length;
    const s = await startCall(w.owner.token, w.botId, w.convId);
    expect(s.live_call_id).toMatch(/^[0-9a-f-]{36}$/);
    const setup = mock.minted[before]?.bidiGenerateContentSetup as {
      systemInstruction: { parts: Array<{ text: string }> };
    };
    const said = setup.systemInstruction.parts[0]?.text ?? "";
    expect(said).toContain("Earlier in this conversation");
    expect(said).toContain("User: Book the dentist for Tuesday");
    expect(said).toContain("Ava: Booked for Tuesday at 10.");
    // The earlier turns come before the greeting.
    expect(said.indexOf("Earlier in this conversation")).toBeLessThan(said.lastIndexOf("Booked"));

    const [row] = await h.handle.db.execute<{
      user_id: string;
      ended_at: string | null;
      conversation_id: string;
    }>(
      sql`select user_id, ended_at, conversation_id from public.live_calls where id = ${s.live_call_id}::uuid`,
    );
    expect(row?.user_id).toBe(w.owner.id);
    expect(row?.conversation_id).toBe(w.convId);
    expect(row?.ended_at).toBeNull();

    // A brand-new call (no conversation yet) has nothing to carry over.
    const fresh = mock.minted.length;
    await startCall(w.owner.token, w.botId);
    const freshSetup = mock.minted[fresh]?.bidiGenerateContentSetup as typeof setup;
    expect(freshSetup.systemInstruction.parts[0]?.text).not.toContain(
      "Earlier in this conversation",
    );
  }, 120_000);

  it("turns are saved as they happen, each once; heartbeats keep the call open; hanging up ends it once", async () => {
    const w = await workspace("live-turns@example.com");
    const s = await startCall(w.owner.token, w.botId, w.convId);
    const turns = (body: unknown) =>
      h.request("/v1/voice/transcript/turns", { method: "POST", token: w.owner.token, json: body });
    const first = await turns({
      live_call_id: s.live_call_id,
      turns: [
        { id: "t0", role: "user", text: "Hi Ava" },
        { id: "t1", role: "assistant", text: "Hi! What can I do?" },
      ],
    });
    expect(first.status, await first.clone().text()).toBe(200);
    expect((await j(first)).saved).toBe(2);
    // A retry of the same turns, plus one new one.
    const retry = await j(
      await turns({
        live_call_id: s.live_call_id,
        turns: [
          { id: "t1", role: "assistant", text: "Hi! What can I do?" },
          { id: "t2", role: "user", text: "Nothing, bye" },
        ],
      }),
    );
    expect(retry.saved).toBe(1);
    const [count] = await h.handle.db.execute<{ n: number }>(
      sql`select count(*)::int as n from public.messages where conversation_id = ${w.convId}::uuid`,
    );
    expect(count?.n).toBe(3);

    // Someone else's call is out of reach.
    const other = await h.user("live-turns-other@example.com");
    expect(
      (
        await h.request("/v1/voice/transcript/turns", {
          method: "POST",
          token: other.token,
          json: { live_call_id: s.live_call_id, turns: [{ id: "x", role: "user", text: "hey" }] },
        })
      ).status,
    ).toBe(404);
    expect(
      (
        await h.request(`/v1/voice/live/${s.live_call_id}/heartbeat`, {
          method: "POST",
          token: other.token,
          json: {},
        })
      ).status,
    ).toBe(404);

    const usage = {
      input_audio_tokens: 900,
      input_text_tokens: 10,
      output_audio_tokens: 700,
      output_text_tokens: 0,
    };
    const beat = await h.request(`/v1/voice/live/${s.live_call_id}/heartbeat`, {
      method: "POST",
      token: w.owner.token,
      json: { usage },
    });
    expect(beat.status, await beat.clone().text()).toBe(200);
    expect((await j(beat)).ended).toBe(false);
    const [live] = await h.handle.db.execute<{ usage: typeof usage }>(
      sql`select usage from public.live_calls where id = ${s.live_call_id}::uuid`,
    );
    expect(live?.usage.output_audio_tokens).toBe(700);

    // Hanging up: the last turn not yet sent comes with it (by id, so nothing doubles).
    const end = (seconds: number) =>
      h.request("/v1/voice/transcript", {
        method: "POST",
        token: w.owner.token,
        json: {
          conversation_id: w.convId,
          live_call_id: s.live_call_id,
          turns: [
            { id: "t2", role: "user", text: "Nothing, bye" },
            { id: "t3", role: "assistant", text: "Bye!" },
          ],
          seconds,
          provider: "gemini",
          usage,
        },
      });
    expect((await end(42)).status).toBe(200);
    expect((await end(42)).status).toBe(200);
    // Four turns and the call's recap (posted once, at the first hang-up).
    const [after] = await h.handle.db.execute<{ n: number }>(
      sql`select count(*)::int as n from public.messages where conversation_id = ${w.convId}::uuid`,
    );
    expect(after?.n).toBe(5);
    const [ended] = await h.handle.db.execute<{ end_reason: string; seconds: number }>(
      sql`select end_reason, seconds from public.live_calls where id = ${s.live_call_id}::uuid`,
    );
    expect(ended).toEqual({ end_reason: "hung_up", seconds: 42 });
    const rows = await h.handle.db.execute<{ quantity: string }>(sql`
      select quantity::text from public.usage_ledger
      where org_id = ${w.orgId}::uuid and kind = 'voice_seconds' and meta->>'live_call_id' = ${s.live_call_id}
        and not coalesce((meta->>'hold')::boolean, false)`);
    expect(rows.length).toBe(1);
    // The heartbeat now says the call is over.
    expect(
      (
        await j(
          await h.request(`/v1/voice/live/${s.live_call_id}/heartbeat`, {
            method: "POST",
            token: w.owner.token,
            json: {},
          }),
        )
      ).ended,
    ).toBe(true);
  }, 120_000);

  it("Casama Cloud: a call whose app went quiet is ended by the sweep and billed its real length, once", async () => {
    const w = await workspace("live-sweep@example.com");
    const s = await startCall(w.owner.token, w.botId, w.convId);
    const usage = {
      input_audio_tokens: 3000,
      input_text_tokens: 0,
      output_audio_tokens: 3000,
      output_text_tokens: 0,
    };
    await h.request(`/v1/voice/live/${s.live_call_id}/heartbeat`, {
      method: "POST",
      token: w.owner.token,
      json: { usage },
    });
    // Six minutes of call, then the app vanished three minutes ago.
    await h.handle.db.execute(sql`
      update public.live_calls set started_at = now() - interval '9 minutes', last_seen_at = now() - interval '3 minutes'
      where id = ${s.live_call_id}::uuid`);
    // A call still beating is left alone.
    const live = await startCall(w.owner.token, w.botId, w.convId);

    expect(await endSilentCalls(h.handle.db)).toBe(1);
    expect(await endSilentCalls(h.handle.db)).toBe(0);
    const [ended] = await h.handle.db.execute<{ end_reason: string; seconds: number }>(
      sql`select end_reason, seconds from public.live_calls where id = ${s.live_call_id}::uuid`,
    );
    expect(ended).toEqual({ end_reason: "silent", seconds: 360 });
    const [still] = await h.handle.db.execute<{ ended_at: string | null }>(
      sql`select ended_at::text from public.live_calls where id = ${live.live_call_id}::uuid`,
    );
    expect(still?.ended_at).toBeNull();

    const rows = await h.handle.db.execute<{
      cost_usd: string;
      quantity: string;
      meta: {
        hold?: boolean;
        settled?: boolean;
        clock_seconds?: number;
        provider_cost_usd?: number;
      };
    }>(sql`
      select cost_usd::text, quantity::text, meta from public.usage_ledger
      where org_id = ${w.orgId}::uuid and kind = 'voice_seconds' and meta->>'live_call_id' = ${s.live_call_id}
      order by created_at`);
    const [hold, charge] = rows;
    expect(rows.length).toBe(2);
    expect(hold?.meta.hold).toBe(true);
    expect(hold?.meta.settled).toBe(true);
    expect(Number(charge?.quantity)).toBe(360);
    // The app talks to Google directly, so the quiet minutes may still be in use: the clock runs to
    // the sweep (nine minutes), billed at the listening rate (billing audit 2026-11-17).
    expect(charge?.meta.clock_seconds).toBeGreaterThanOrEqual(540);
    expect(charge?.meta.clock_seconds).toBeLessThan(560);
    const clock = (charge?.meta.clock_seconds ?? 540) / 60;
    // Nine minutes at the listening rate is more than these tokens, so the floor applies.
    const google = Math.max(3000 * 3e-6 + 3000 * 12e-6, clock * 0.0045);
    expect(charge?.meta.provider_cost_usd).toBeCloseTo(google, 6);
    const total = rows.reduce((n, r) => n + Number(r.cost_usd), 0);
    expect(total).toBeCloseTo(google * 1.3, 6);

    // The app comes back and hangs up late: the turns are kept, nothing is billed twice.
    const late = await h.request("/v1/voice/transcript", {
      method: "POST",
      token: w.owner.token,
      json: {
        conversation_id: w.convId,
        live_call_id: s.live_call_id,
        turns: [{ id: "t9", role: "user", text: "Are you there?" }],
        seconds: 600,
        provider: "gemini",
      },
    });
    expect(late.status).toBe(200);
    // The sweep posted the recap with the length it billed.
    const recaps = await h.handle.db.execute<{ content: unknown }>(sql`
      select content from public.messages where conversation_id = ${w.convId}::uuid and role = 'assistant'`);
    const recap = recaps
      .map((r) => contentKeys.open(r.content) as Array<{ type: string; seconds?: number }>)
      .find((p) => p.some((x) => x.type === "call"));
    expect(recap?.find((x) => x.type === "call")?.seconds).toBe(360);
    const [n] = await h.handle.db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.usage_ledger
      where org_id = ${w.orgId}::uuid and kind = 'voice_seconds' and meta->>'live_call_id' = ${s.live_call_id}`);
    expect(n?.n).toBe(2);
  }, 120_000);

  it("billing audit 2026-11-17: a call that never sent a heartbeat keeps its hold", async () => {
    const w = await workspace("live-silent-start@example.com");
    const s = await startCall(w.owner.token, w.botId, w.convId);
    // No heartbeat and no usage ever, and the app is gone.
    await h.handle.db.execute(sql`
      update public.live_calls set started_at = now() - interval '3 minutes', last_seen_at = now() - interval '3 minutes'
      where id = ${s.live_call_id}::uuid`);
    expect(await endSilentCalls(h.handle.db)).toBe(1);
    const rows = await h.handle.db.execute<{ cost_usd: string }>(sql`
      select cost_usd::text from public.usage_ledger
      where org_id = ${w.orgId}::uuid and kind = 'voice_seconds' and meta->>'live_call_id' = ${s.live_call_id}`);
    const total = rows.reduce((t, r) => t + Number(r.cost_usd), 0);
    // The two-minute hold at the per-minute estimate, times the markup: not refunded to zero.
    expect(total).toBeGreaterThan(0);
    expect(total).toBeCloseTo(2 * VOICE_PRICES.geminiLivePerMinute * 1.3, 6);
  }, 120_000);

  it("call limits (D-426): the sweep waits abandoned_seconds for a heartbeat and ends calls past their longest length", async () => {
    const w = await workspace("live-limits-sweep@example.com");
    const quiet = await startCall(w.owner.token, w.botId, w.convId);
    const recent = await startCall(w.owner.token, w.botId, w.convId);
    const long = await startCall(w.owner.token, w.botId, w.convId);
    // Default: a minute without a heartbeat. 70 seconds is over; 45 isn't.
    await h.handle.db.execute(sql`
      update public.live_calls set started_at = now() - interval '3 minutes', last_seen_at = now() - interval '70 seconds'
      where id = ${quiet.live_call_id}::uuid`);
    await h.handle.db.execute(sql`
      update public.live_calls set started_at = now() - interval '3 minutes', last_seen_at = now() - interval '45 seconds'
      where id = ${recent.live_call_id}::uuid`);
    // Still beating, but an hour and three minutes in: past the longest call and its goodbye.
    await h.handle.db.execute(sql`
      update public.live_calls set started_at = now() - interval '63 minutes', last_seen_at = now()
      where id = ${long.live_call_id}::uuid`);
    expect(await endSilentCalls(h.handle.db)).toBe(2);
    const rows = await h.handle.db.execute<{ id: string; end_reason: string | null }>(sql`
      select id, end_reason from public.live_calls
      where id in (${quiet.live_call_id}::uuid, ${recent.live_call_id}::uuid, ${long.live_call_id}::uuid)`);
    const reason = (id: string) => rows.find((r) => r.id === id)?.end_reason ?? null;
    expect(reason(quiet.live_call_id)).toBe("silent");
    expect(reason(recent.live_call_id)).toBeNull();
    expect(reason(long.live_call_id)).toBe("max_length");
    // The long call's app hears it's over on its next heartbeat.
    const beat = await j(
      await h.request(`/v1/voice/live/${long.live_call_id}/heartbeat`, {
        method: "POST",
        token: w.owner.token,
        json: {},
      }),
    );
    expect(beat.ended).toBe(true);
    // The window follows Admin → Call limits.
    setCallLimits({ abandoned_seconds: 120 });
    await h.handle.db.execute(sql`
      update public.live_calls set last_seen_at = now() - interval '90 seconds' where id = ${recent.live_call_id}::uuid`);
    expect(await endSilentCalls(h.handle.db)).toBe(0);
    setCallLimits(null);
    expect(await endSilentCalls(h.handle.db)).toBe(1);
  }, 120_000);

  it("jobs started on a call are the call's: stop_task stops only those, and the recap lists them", async () => {
    const w = await workspace("live-jobs@example.com");
    const s = await startCall(w.owner.token, w.botId, w.convId);
    const tool = (
      token: string,
      name: string,
      args: Record<string, unknown> = {},
      live = s.live_call_id,
    ) =>
      h.request("/v1/voice/tool", {
        method: "POST",
        token,
        json: {
          bot_id: w.botId,
          conversation_id: w.convId,
          call_id: `c-${name}-${Math.random()}`,
          name,
          arguments: args,
          live_call_id: live,
        },
      });

    // The tools a call gets: start_task, stop_task (and show_screen with a computer).
    const before = mock.minted.length;
    await startCall(w.owner.token, w.botId, w.convId);
    const setup = mock.minted[before]?.bidiGenerateContentSetup as {
      tools: Array<{ functionDeclarations: Array<{ name: string }> }>;
    };
    const names = setup.tools.flatMap((t) => t.functionDeclarations.map((f) => f.name));
    expect(names).toContain("start_task");
    expect(names).toContain("stop_task");

    const started = await tool(w.owner.token, "start_task", { task: "Book the flight to Cebu" });
    expect(started.status, await started.clone().text()).toBe(200);
    const job = (await j(started)).run_id as string;
    const [rec] = await h.handle.db.execute<{ task_run_ids: string[] }>(
      sql`select task_run_ids from public.live_calls where id = ${s.live_call_id}::uuid`,
    );
    expect(rec?.task_run_ids).toEqual([job]);

    // A job that is still going (made here so the worker can't finish it first), and a run in the
    // same chat that wasn't started on the call.
    const insertRun = async () => {
      const [r] = await h.handle.db.execute<{ id: string }>(sql`
        insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger, status)
        values (${w.orgId}::uuid, ${w.botId}::uuid, ${w.convId}::uuid, ${w.owner.id}::uuid, 'chat', 'running')
        returning id`);
      return (r as { id: string }).id;
    };
    const going = await insertRun();
    const other = await insertRun();
    await h.handle.db.execute(sql`
      update public.live_calls set task_run_ids = array_append(task_run_ids, ${going}::uuid)
      where id = ${s.live_call_id}::uuid`);

    // Someone else can't stop them through this call.
    const stranger = await h.user("live-jobs-stranger@example.com");
    expect((await tool(stranger.token, "stop_task")).status).not.toBe(200);

    const stop = await tool(w.owner.token, "stop_task");
    expect(stop.status, await stop.clone().text()).toBe(200);
    const stopped = await j(stop);
    expect(stopped.run_id).toBe(going);
    expect(stopped.output).toContain("Stopped");
    const cancel = await h.handle.db.execute<{ id: string; asked: boolean }>(sql`
      select id, cancel_requested_at is not null as asked from public.runs where id in (${going}::uuid, ${other}::uuid)`);
    expect(cancel.find((r) => r.id === going)?.asked).toBe(true);
    expect(cancel.find((r) => r.id === other)?.asked).toBe(false);

    // show_screen is the app's to answer; an older app gets a line to say instead.
    const shown = await j(await tool(w.owner.token, "show_screen"));
    expect(shown.status).toBe("completed");
    expect(shown.run_id).toBe("00000000-0000-0000-0000-000000000000");

    // Hanging up posts the recap: the length and the jobs, each with its run.
    await h.request("/v1/voice/transcript", {
      method: "POST",
      token: w.owner.token,
      json: { conversation_id: w.convId, live_call_id: s.live_call_id, turns: [], seconds: 75 },
    });
    const rows = await h.handle.db.execute<{ content: unknown }>(sql`
      select content from public.messages where conversation_id = ${w.convId}::uuid and role = 'assistant'
      order by created_at desc limit 1`);
    const parts = contentKeys.open(rows[0]?.content) as Array<Record<string, unknown>>;
    expect(parts[0]?.text).toContain("Call ended · 1:15");
    expect(parts[0]?.text).toContain("Book the flight to Cebu");
    const card = parts.find((p) => p.type === "call") as {
      seconds: number;
      tasks: Array<{ run_id: string; task: string }>;
    };
    expect(card.seconds).toBe(75);
    expect(card.tasks.map((t) => t.run_id)).toEqual([job, going]);
    expect(card.tasks[0]?.task).toBe("Book the flight to Cebu");

    // The next call doesn't hear the recap as something either side said.
    const next = mock.minted.length;
    await startCall(w.owner.token, w.botId, w.convId);
    const nextSetup = mock.minted[next]?.bidiGenerateContentSetup as {
      systemInstruction: { parts: Array<{ text: string }> };
    };
    expect(nextSetup.systemInstruction.parts[0]?.text).not.toContain("Call ended");
  }, 120_000);
});
