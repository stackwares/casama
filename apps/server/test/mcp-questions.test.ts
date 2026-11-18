/**
 * A connected MCP server's question to the person mid-call (MCP elicitation, D-363): the call
 * waits on a card, the person answers through the API, and the answer goes back to the server.
 */
import { askMcpQuestion } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

describe("MCP questions", () => {
  let h: Harness;
  let owner: { id: string; token: string };
  let member: { id: string; token: string };
  let outsider: { id: string; token: string };
  let orgId: string;
  let botId: string;
  let integrationId: string;

  beforeAll(async () => {
    h = await startHarness();
    owner = await h.user("questions-owner@example.com");
    member = await h.user("questions-member@example.com");
    outsider = await h.user("questions-outsider@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Q" } }),
      )
    ).id;
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
    const [bot] = await h.tdb.admin<{ id: string }[]>`
      insert into public.bots (org_id, name, created_by, visibility) values (${orgId}, 'Asker', ${owner.id}, 'team') returning id`;
    botId = bot!.id;
    const [integ] = await h.tdb.admin<{ id: string }[]>`
      insert into public.integrations (org_id, kind, name, config) values (${orgId}, 'mcp', 'deploys', '{"url":"https://x.example/mcp"}') returning id`;
    integrationId = integ!.id;
  }, 120_000);
  afterAll(async () => h?.stop());

  const newRun = async () => {
    const [run] = await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, trigger, status, created_by) values (${orgId}, ${botId}, 'chat', 'running', ${owner.id}) returning id`;
    return run!.id;
  };
  const schema = {
    type: "object",
    properties: {
      env: { type: "string", enum: ["staging", "production"] },
      notes: { type: "string" },
    },
    required: ["env"],
  };

  /** Starts a question and returns its id from the card event, plus the pending answer. */
  const ask = async (runId: string, signal?: AbortSignal) => {
    const events: Array<{ type: string; payload: Record<string, unknown> }> = [];
    const answer = askMcpQuestion(
      h.deps.db,
      {
        runId,
        orgId,
        botId,
        integrationId,
        connection: "Deploys",
        emit: async (type, payload) => {
          events.push({ type, payload });
        },
        signal,
        pollMs: 50,
      },
      { message: "Where to deploy?", schema },
    );
    for (let i = 0; !events.length && i < 100; i++) await sleep(20);
    const card = events[0];
    expect(card?.type).toBe("mcp.question");
    expect(card?.payload).toMatchObject({
      connection: "Deploys",
      message: "Where to deploy?",
      schema,
    });
    return { id: card?.payload.question_id as string, answer, events };
  };
  const answer = (token: string, id: string, json: unknown) =>
    h.request(`/v1/mcp-questions/${id}/answer`, { method: "POST", token, json });

  it("waits for the person's answer and gives it to the server", async () => {
    const q = await ask(await newRun());
    // Checked against the form first.
    const bad = await answer(owner.token, q.id, { action: "accept", content: { env: "moon" } });
    expect(bad.status).toBe(400);
    expect((await j(bad)).detail).toBe("env must be one of the choices");
    // Only the person who started the chat or an admin answers; outsiders don't even see it.
    expect(
      (await answer(member.token, q.id, { action: "accept", content: { env: "staging" } })).status,
    ).toBe(403);
    expect((await answer(outsider.token, q.id, { action: "decline" })).status).toBe(404);

    const ok = await answer(owner.token, q.id, {
      action: "accept",
      content: { env: "staging", notes: "fast" },
    });
    expect(ok.status).toBe(200);
    expect(await j(ok)).toMatchObject({ status: "accepted", connection: "Deploys" });
    expect(await q.answer).toEqual({
      action: "accept",
      content: { env: "staging", notes: "fast" },
    });
    expect(q.events.at(-1)).toEqual({
      type: "mcp.question_resolved",
      payload: { question_id: q.id, outcome: "accepted" },
    });
    // The answer isn't kept once the server has it, and can't be given twice.
    const [row] = await h.tdb.admin<
      { answer: unknown }[]
    >`select answer from public.mcp_questions where id = ${q.id}`;
    expect(row?.answer).toBeNull();
    expect((await answer(owner.token, q.id, { action: "decline" })).status).toBe(409);
  });

  it("passes a decline on", async () => {
    const q = await ask(await newRun());
    expect((await answer(owner.token, q.id, { action: "decline" })).status).toBe(200);
    expect(await q.answer).toEqual({ action: "decline" });
  });

  it("cancels the question when nobody answers in time, or the run stops", async () => {
    const late = await ask(await newRun());
    await h.tdb
      .admin`update public.mcp_questions set expires_at = now() - interval '1 second' where id = ${late.id}`;
    expect(await late.answer).toEqual({ action: "cancel" });
    expect(late.events.at(-1)?.payload.outcome).toBe("expired");
    expect((await answer(owner.token, late.id, { action: "decline" })).status).toBe(409);

    const ctrl = new AbortController();
    const stopped = await ask(await newRun(), ctrl.signal);
    ctrl.abort();
    expect(await stopped.answer).toEqual({ action: "cancel" });
    expect(stopped.events.at(-1)?.payload.outcome).toBe("cancelled");
  });

  it("declines forms it can't show without asking", async () => {
    const events: string[] = [];
    const a = await askMcpQuestion(
      h.deps.db,
      {
        runId: await newRun(),
        orgId,
        botId,
        integrationId,
        connection: "Deploys",
        emit: async (type) => {
          events.push(type);
        },
      },
      { message: "Nested", schema: { type: "object", properties: { a: { type: "object" } } } },
    );
    expect(a).toEqual({ action: "decline" });
    expect(events).toEqual([]);
  });

  it("writes the outcome itself when the run already ended", async () => {
    const runId = await newRun();
    const q = await ask(runId);
    await h.tdb.admin`update public.runs set status = 'cancelled' where id = ${runId}`;
    expect((await answer(owner.token, q.id, { action: "decline" })).status).toBe(200);
    const evs = await h.tdb.admin<{ type: string }[]>`
      select type from public.run_events where run_id = ${runId} and type = 'mcp.question_resolved'`;
    expect(evs.length).toBeGreaterThan(0);
    await q.answer;
  });
});
