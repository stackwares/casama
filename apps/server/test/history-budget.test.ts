/**
 * History budget (D-253): a long chat sends a fixed amount of recent history, folds the rest into the
 * conversation's summary, and the turns it kept are still there on the next message.
 */
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/history-budget.json", import.meta.url));
let h: Harness;
let owner: { id: string; token: string };
let orgId: string;
let convId: string;

const done = async (runId: string) => {
  for (let i = 0; i < 150; i++) {
    const r = await j(await h.request(`/v1/runs/${runId}`, { token: owner.token }));
    if (["completed", "failed"].includes(r.status)) return r;
    await new Promise((res) => setTimeout(res, 100));
  }
  throw new Error("run did not finish");
};
const send = async (text: string) => {
  const sent = await j(
    await h.request(`/v1/conversations/${convId}/messages`, {
      method: "POST",
      token: owner.token,
      json: { text },
    }),
  );
  return done(sent.run_id);
};
const lastReply = async () => {
  const [m] = await h.tdb.admin<{ content: Array<{ text?: string }> }[]>`
    select content from public.messages where conversation_id = ${convId} and role = 'assistant'
    order by created_at desc limit 1`;
  return m?.content[0]?.text;
};

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  owner = await h.user("history-budget@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "H" } }),
    )
  ).id;
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
    }),
  );
  const bot = await j(
    await h.request("/v1/bots", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: orgId,
        name: "Planner",
        model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
      },
    }),
  );
  convId = (
    await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: bot.id },
      }),
    )
  ).id;
  // About 24k tokens of earlier chat: over the 16k budget.
  for (let i = 0; i < 60; i++) {
    const role = i % 2 ? "assistant" : "user";
    const text = `turn-${i}-marker ${"trip planning detail ".repeat(80)}`;
    await h.tdb.admin`
      insert into public.messages (org_id, conversation_id, role, author_user_id, content)
      values (${orgId}, ${convId}, ${role}, ${role === "user" ? owner.id : null},
              ${h.tdb.admin.json([{ type: "text", text }])})`;
  }
}, 60_000);
afterAll(async () => h?.stop());

describe("history budget", () => {
  it("folds older turns into the summary and marks only those as summarized", async () => {
    const run = await send("budget check one");
    expect(run.status).toBe("completed");
    const [c] = await h.tdb.admin<{ summary: string | null; through: string | null }[]>`
      select summary, summary_through::text as through from public.conversations where id = ${convId}`;
    expect(c?.summary).toContain("long trip");
    // The cut-off is one of the seeded turns, not the newest message: later turns stay word for word.
    const [cut] = await h.tdb.admin<{ text: string }[]>`
      select content -> 0 ->> 'text' as text from public.messages
      where conversation_id = ${convId} and created_at = ${c?.through}::timestamptz`;
    expect(cut?.text).toMatch(/^turn-\d+-marker/);
    const n = Number(cut?.text.match(/^turn-(\d+)/)?.[1]);
    expect(n).toBeGreaterThan(20);
    expect(n).toBeLessThan(59);
  });

  it("still sends the kept recent turns on the next message", async () => {
    const run = await send("budget check two");
    expect(run.status).toBe("completed");
    expect(await lastReply()).toBe("Recent turns kept.");
  });
});
