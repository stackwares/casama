import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import { contentKeys } from "@casama/db";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { endSilentCalls } from "../src/billing/live-calls.ts";
import { actionLine, type CallPart, recapText } from "../src/services/call-recap.ts";
import {
  type Complete,
  parseSummary,
  pendingSummaries,
  SUMMARY_HEAD_CHARS,
  SUMMARY_TAIL_CHARS,
  summarizeCall,
  transcriptFor,
} from "../src/services/call-summary.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));

describe("call card pieces", () => {
  it("quick tools become one line each; lookups that changed nothing are left out", () => {
    expect(
      actionLine("r1", "memory__write", { content: "Likes aisle seats" }, "Saved.", false),
    ).toMatchObject({
      label: "Remembered: Likes aisle seats",
      ok: true,
      target: { kind: "memory" },
    });
    expect(
      actionLine("r2", "web__search", { query: "flights to Cebu" }, "1. …", false)?.label,
    ).toBe("Looked up “flights to Cebu”");
    expect(
      actionLine("r3", "web__fetch", { url: "https://www.example.com/a" }, "Title", false)?.label,
    ).toBe("Read example.com");
    const routine = actionLine(
      "r4",
      "routines__create",
      { name: "Morning news" },
      "Created routine 0a1b2c3d-1111-2222-3333-444455556666.",
      false,
    );
    expect(routine).toMatchObject({
      label: "Set up: Morning news",
      target: { kind: "routine", id: "0a1b2c3d-1111-2222-3333-444455556666" },
    });
    expect(actionLine("r5", "routines__create", { name: "X" }, "", true)).toMatchObject({
      ok: false,
      label: "Couldn't set up: X",
    });
    expect(actionLine("r6", "device__read", { kind: "browser_history" }, "…", false)?.label).toBe(
      "Checked your browser history",
    );
    for (const name of ["memory__search", "routines__list", "notify__user", "usage__report"])
      expect(actionLine("r", name, {}, "", false)).toBeNull();
  });

  it("the text part leads with the call and carries the summary, steps and work", () => {
    const part: CallPart = {
      type: "call",
      live_call_id: "x",
      seconds: 252,
      kind: "app",
      ended: "hung_up",
      started_at: null,
      ended_at: null,
      turns: 18,
      tasks: [{ run_id: "r", task: "Book dinner", status: "running" }],
      actions: [
        {
          run_id: "a",
          tool: "memory.write",
          label: "Remembered: aisle seats",
          ok: true,
          target: { kind: "memory", id: null },
        },
      ],
      summary: { status: "ready", text: "Planned the Cebu trip." },
      next_steps: [
        {
          id: "s1",
          label: "Text Ana",
          task: "Text Ana",
          doable: true,
          state: "open",
          run_id: null,
        },
        { id: "s2", label: "Gone", task: "Gone", doable: true, state: "dismissed", run_id: null },
      ],
    };
    expect(recapText(part)).toBe(
      [
        "Voice call · 4:12",
        "Planned the Cebu trip.",
        "Next: Text Ana",
        "Started on the call: Book dinner",
        "Done on the call: Remembered: aisle seats",
      ].join("\n"),
    );
    expect(
      recapText({ ...part, ended: "dropped", summary: { status: "pending" } }).split("\n")[0],
    ).toBe("Call dropped · 4:12");
    expect(recapText({ ...part, kind: "phone" }).startsWith("Phone call · 4:12")).toBe(true);
  });

  it("reads the model's JSON, fenced or not, and refuses anything without a summary", () => {
    expect(
      parseSummary(
        '```json\n{"summary":"Planned the trip.","next_steps":[{"label":"Text Ana","task":"Text Ana the hotel address","doable":true},{"label":"Pack"}]}\n```',
      ),
    ).toEqual({
      summary: "Planned the trip.",
      steps: [
        { label: "Text Ana", task: "Text Ana the hotel address", doable: true },
        { label: "Pack", task: "Pack", doable: false },
      ],
    });
    const many = JSON.stringify({
      summary: "S",
      next_steps: Array.from({ length: 6 }, (_, i) => ({
        label: `L${i}`,
        task: "t",
        doable: true,
      })),
    });
    expect(parseSummary(many)?.steps).toHaveLength(3);
    expect(parseSummary("not json")).toBeNull();
    expect(parseSummary('{"summary":""}')).toBeNull();
  });

  it("a long transcript keeps its opening and as much of its end as fits", () => {
    const lines = Array.from({ length: 2_000 }, (_, i) => `Person: line ${i}`);
    const t = transcriptFor(lines);
    expect(t.length).toBeLessThanOrEqual(SUMMARY_HEAD_CHARS + SUMMARY_TAIL_CHARS + 10);
    expect(t.startsWith("Person: line 0")).toBe(true);
    expect(t).toContain("[…]");
    expect(t.endsWith("Person: line 1999")).toBe(true);
    expect(transcriptFor(["A: hi", "B: hey"])).toBe("A: hi\nB: hey");
  });
});

async function mockGemini() {
  const server = createServer((req, res) => {
    req.resume();
    req.on("end", () => {
      if ((req.url ?? "").startsWith("/v1beta/auth_tokens")) {
        res.writeHead(200, { "content-type": "application/json" });
        return res.end(JSON.stringify({ name: "auth_tokens/call-card-test" }));
      }
      res.writeHead(404);
      res.end();
    });
  });
  await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
  return {
    url: `http://127.0.0.1:${(server.address() as AddressInfo).port}`,
    close: () => server.close(),
  };
}

describe("the call card (call card plan)", () => {
  let mock: Awaited<ReturnType<typeof mockGemini>>;
  let h: Harness;
  beforeAll(async () => {
    mock = await mockGemini();
    h = await startHarness({
      env: { GOOGLE_AI_API_KEY: "server-gemini-key" },
      worker: { fixtures: FIXTURES, providerBases: { gemini: mock.url } },
    });
  }, 120_000);
  afterAll(async () => {
    await h?.stop();
    mock?.close();
  });

  async function call(email: string) {
    const owner = await h.user(email);
    const orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Card" } }),
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
          name: "Nova",
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
    const s = await j(
      await h.request("/v1/voice/session", {
        method: "POST",
        token: owner.token,
        json: { bot_id: bot.id, conversation_id: conv.id },
      }),
    );
    return {
      owner,
      orgId,
      botId: bot.id as string,
      convId: conv.id as string,
      liveCallId: s.live_call_id as string,
    };
  }

  const turns = (
    c: Awaited<ReturnType<typeof call>>,
    list: Array<[string, "user" | "assistant", string]>,
  ) =>
    h.request("/v1/voice/transcript/turns", {
      method: "POST",
      token: c.owner.token,
      json: {
        live_call_id: c.liveCallId,
        turns: list.map(([id, role, text]) => ({ id, role, text })),
      },
    });

  const hangUp = (c: Awaited<ReturnType<typeof call>>, seconds: number, ended?: string) =>
    h.request("/v1/voice/transcript", {
      method: "POST",
      token: c.owner.token,
      json: {
        conversation_id: c.convId,
        live_call_id: c.liveCallId,
        turns: [],
        seconds,
        ...(ended ? { ended } : {}),
      },
    });

  const card = async (convId: string) => {
    const rows = await h.handle.db.execute<{ id: string; content: unknown }>(sql`
      select id, content from public.messages where conversation_id = ${convId}::uuid and role = 'assistant'
      order by created_at desc limit 1`);
    const parts = contentKeys.open(rows[0]?.content) as Array<Record<string, unknown>>;
    return {
      id: rows[0]?.id as string,
      text: String(parts[0]?.text ?? ""),
      part: parts.find((p) => p.type === "call") as unknown as CallPart,
    };
  };

  it("turns carry their call; the card counts them, lists quick tools and waits for its summary", async () => {
    const c = await call("card-full@example.com");
    expect(
      (
        await turns(c, [
          ["t0", "assistant", "Hi, it's Nova."],
          ["t1", "user", "Plan Friday's Cebu trip with me"],
          ["t2", "assistant", "Sure: the 7 AM flight works, and dinner at Abaca."],
          ["t3", "user", "Great. Remember I like aisle seats."],
        ])
      ).status,
    ).toBe(200);
    const saved = await h.handle.db.execute<{ content: unknown }>(sql`
      select m.content from public.live_call_turns t join public.messages m on m.id = t.message_id
      where t.live_call_id = ${c.liveCallId}::uuid`);
    for (const r of saved)
      expect((contentKeys.open(r.content) as Array<Record<string, unknown>>)[0]).toMatchObject({
        voice: true,
        call: c.liveCallId,
      });

    // A quick tool on the call is tied to it (as the app sends it).
    await h.handle.db.execute(sql`
      insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger, status, voice_call)
      values (${c.orgId}::uuid, ${c.botId}::uuid, ${c.convId}::uuid, ${c.owner.id}::uuid, 'voice', 'completed',
        ${JSON.stringify({ name: "memory__write", arguments: { content: "Likes aisle seats" }, result: "Saved.", live_call_id: c.liveCallId })}::jsonb)`);

    expect((await hangUp(c, 95, "bot")).status).toBe(200);
    const k = await card(c.convId);
    expect(k.part).toMatchObject({
      live_call_id: c.liveCallId,
      seconds: 95,
      kind: "app",
      ended: "bot_hung_up",
      turns: 4,
      summary: { status: "pending" },
      next_steps: [],
    });
    expect(k.part.actions.map((a) => a.label)).toEqual(["Remembered: Likes aisle seats"]);
    expect(k.text.split("\n")[0]).toBe("Voice call · 1:35");
    const [lc] = await h.handle.db.execute<{ recap_message_id: string; summary_state: string }>(sql`
      select recap_message_id, summary_state from public.live_calls where id = ${c.liveCallId}::uuid`);
    expect(lc).toEqual({ recap_message_id: k.id, summary_state: "pending" });

    // The summary job: the call's turns go to the bot's background model; the card fills in once.
    const asked: Array<Parameters<Complete>[0]> = [];
    const complete: Complete = async (input) => {
      asked.push(input);
      return {
        model: "fixture-small",
        text: JSON.stringify({
          summary: "Planned Friday's Cebu trip: the 7 AM flight and dinner at Abaca.",
          next_steps: [
            {
              label: "Book dinner at Abaca",
              task: "Book dinner at Abaca for Friday",
              doable: true,
            },
            { label: "Pack for Cebu", task: "Pack for Cebu", doable: false },
          ],
        }),
      };
    };
    expect(await summarizeCall({ db: h.handle.db, complete }, c.liveCallId)).toBe("ready");
    expect(await summarizeCall({ db: h.handle.db, complete }, c.liveCallId)).toBe("not_pending");
    expect(asked).toHaveLength(1);
    expect(asked[0]?.purpose).toBe("call_summary");
    expect(asked[0]?.text).toContain("Person: Plan Friday's Cebu trip with me");
    expect(asked[0]?.text).toContain("Nova: Sure: the 7 AM flight works");
    expect(asked[0]?.text).toContain("Remembered: Likes aisle seats");
    const done = await card(c.convId);
    expect(done.id).toBe(k.id);
    expect(done.part.summary).toEqual({
      status: "ready",
      text: "Planned Friday's Cebu trip: the 7 AM flight and dinner at Abaca.",
    });
    expect(done.part.next_steps.map((s) => [s.id, s.doable, s.state])).toEqual([
      ["s1", true, "open"],
      ["s2", false, "open"],
    ]);
    expect(done.text).toContain("Planned Friday's Cebu trip");
    expect(done.text).toContain("Next: Book dinner at Abaca; Pack for Cebu");

    // Next steps: someone else can't touch them; only-you steps can't start; a step is used once.
    const step = (token: string, id: string, action: string) =>
      h.request(`/v1/voice/live/${c.liveCallId}/steps/${id}`, {
        method: "POST",
        token,
        json: { action },
      });
    const stranger = await h.user("card-stranger@example.com");
    expect((await step(stranger.token, "s1", "start")).status).toBe(404);
    expect((await step(c.owner.token, "s2", "start")).status).toBe(409);
    expect((await step(c.owner.token, "s2", "dismiss")).status).toBe(200);
    // Two taps at once (two devices): one starts it, the other finds it taken.
    const both = await Promise.all([
      step(c.owner.token, "s1", "start"),
      step(c.owner.token, "s1", "start"),
    ]);
    expect(both.map((r) => r.status).sort()).toEqual([200, 409]);
    const started = both.find((r) => r.status === 200) as Response;
    const runId = (await j(started)).run_id as string;
    expect(runId).toMatch(/^[0-9a-f-]{36}$/);
    expect((await step(c.owner.token, "s1", "start")).status).toBe(409);
    const after = await h.handle.db.execute<{ content: unknown }>(sql`
      select content from public.messages where run_id = ${runId}::uuid and role = 'user'`);
    expect((contentKeys.open(after[0]?.content) as Array<{ text: string }>)[0]?.text).toBe(
      "Book dinner at Abaca for Friday",
    );
    const used = (
      await h.handle.db.execute<{ content: unknown }>(
        sql`select content from public.messages where id = ${k.id}::uuid`,
      )
    )[0];
    const usedPart = (contentKeys.open(used?.content) as Array<Record<string, unknown>>).find(
      (p) => p.type === "call",
    ) as unknown as CallPart;
    expect(usedPart.next_steps.map((s) => [s.state, s.run_id])).toEqual([
      ["started", runId],
      ["dismissed", null],
    ]);
  }, 120_000);

  it("short calls get no summary; a bot can turn summaries off; the sweep leaves pending ones for the tick", async () => {
    const short = await call("card-short@example.com");
    await turns(short, [["t0", "assistant", "Hi!"]]);
    await hangUp(short, 12);
    expect((await card(short.convId)).part.summary.status).toBe("skipped");

    const off = await call("card-off@example.com");
    await h.handle.db.execute(sql`
      update public.bots set voice = coalesce(voice, '{}'::jsonb) || '{"summarize_calls": false}'::jsonb
      where id = ${off.botId}::uuid`);
    await turns(off, [
      ["t0", "assistant", "Hi"],
      ["t1", "user", "Hello there"],
      ["t2", "assistant", "What's up?"],
    ]);
    await hangUp(off, 60);
    expect((await card(off.convId)).part.summary.status).toBe("skipped");

    // The app went quiet: the sweep ends the call and its card waits for the minute tick.
    const quiet = await call("card-quiet@example.com");
    await turns(quiet, [
      ["t0", "assistant", "Hi"],
      ["t1", "user", "Let's plan the week"],
      ["t2", "assistant", "Monday first?"],
    ]);
    await h.handle.db.execute(sql`
      update public.live_calls set started_at = now() - interval '10 minutes',
        last_seen_at = now() - interval '5 minutes' where id = ${quiet.liveCallId}::uuid`);
    await endSilentCalls(h.handle.db);
    expect((await card(quiet.convId)).part).toMatchObject({
      ended: "silent",
      summary: { status: "pending" },
    });
    await h.handle.db.execute(sql`
      update public.live_calls set ended_at = now() - interval '1 minute' where id = ${quiet.liveCallId}::uuid`);
    expect(await pendingSummaries(h.handle.db)).toContain(quiet.liveCallId);

    // No model or no credits: the card goes without, quietly.
    expect(
      await summarizeCall({ db: h.handle.db, complete: async () => null }, quiet.liveCallId),
    ).toBe("skipped");
    expect((await card(quiet.convId)).part.summary.status).toBe("skipped");
    expect(await pendingSummaries(h.handle.db)).not.toContain(quiet.liveCallId);
  }, 120_000);

  it("deleting a call removes its card and every turn, and nothing else", async () => {
    const c = await call("card-delete@example.com");
    await h.handle.db.execute(sql`
      insert into public.messages (org_id, conversation_id, role, author_user_id, content)
      values (${c.orgId}::uuid, ${c.convId}::uuid, 'user', ${c.owner.id}::uuid,
              ${JSON.stringify([{ type: "text", text: "Typed before the call" }])}::jsonb)`);
    await turns(c, [
      ["t0", "assistant", "Hi"],
      ["t1", "user", "Bye"],
    ]);
    // A turn sent at hang-up without an id is recorded with the call too.
    const noId = await h.request("/v1/voice/transcript", {
      method: "POST",
      token: c.owner.token,
      json: {
        conversation_id: c.convId,
        live_call_id: c.liveCallId,
        turns: [{ role: "assistant", text: "Talk soon" }],
        seconds: 0,
      },
    });
    expect(noId.status).toBe(200);
    // That post ended the call (too short for a card); reopened so the hang-up below posts one.
    await h.handle.db.execute(
      sql`update public.live_calls set ended_at = null where id = ${c.liveCallId}::uuid`,
    );
    const del = () =>
      h.request(`/v1/voice/live/${c.liveCallId}`, { method: "DELETE", token: c.owner.token });
    expect((await del()).status).toBe(409);
    await hangUp(c, 20);
    const other = await h.user("card-delete-other@example.com");
    expect(
      (await h.request(`/v1/voice/live/${c.liveCallId}`, { method: "DELETE", token: other.token }))
        .status,
    ).toBe(404);
    const res = await del();
    expect(res.status, await res.clone().text()).toBe(200);
    expect((await j(res)).deleted).toBe(4);
    const left = await h.handle.db.execute<{ n: number }>(
      sql`select count(*)::int as n from public.messages where conversation_id = ${c.convId}::uuid`,
    );
    expect(left[0]?.n).toBe(1);
  }, 120_000);
});
