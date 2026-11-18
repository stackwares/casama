/** Ticket board (D-098): assigning a bot starts its work; the run moves the ticket on. */
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/tickets.json", import.meta.url));
let h: Harness;
let owner: { id: string; token: string };
let orgId: string;
let botId: string;

async function waitFor<T>(fn: () => Promise<T>, ok: (v: T) => boolean, ms = 20_000) {
  const until = Date.now() + ms;
  for (;;) {
    const v = await fn();
    if (ok(v)) return v;
    if (Date.now() > until) throw new Error(`timed out: ${JSON.stringify(v)}`);
    await new Promise((r) => setTimeout(r, 150));
  }
}
const ticket = async (id: string) => {
  const list = await j(await h.request(`/v1/tasks?org_id=${orgId}`, { token: owner.token }));
  return list.items.find((t: { id: string }) => t.id === id);
};
const comments = async (id: string) =>
  (await j(await h.request(`/v1/tasks/${id}/comments`, { token: owner.token }))).items as Array<{
    author_type: string;
    body_md: string;
  }>;

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  owner = await h.user("board-owner@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Board" } }),
    )
  ).id;
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
        json: {
          org_id: orgId,
          name: "Fixer",
          model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
        },
      }),
    )
  ).id;
}, 60_000);
afterAll(() => h?.stop());

describe("ticket board", () => {
  it("creates and moves tickets by hand without waking bots", async () => {
    const t = await j(
      await h.request("/v1/tasks", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, title: "Plan Q1", priority: "high", labels: ["planning"] },
      }),
    );
    expect(t).toMatchObject({
      status: "todo",
      priority: "high",
      labels: ["planning"],
      created_by_user_id: owner.id,
    });
    const moved = await j(
      await h.request(`/v1/tasks/${t.id}`, {
        method: "PATCH",
        token: owner.token,
        json: { status: "in_review", position: 2 },
      }),
    );
    expect(moved).toMatchObject({ status: "in_review", position: 2, conversation_id: null });
  });

  it("assigning a bot starts its work; the finished run marks the ticket done with a comment", async () => {
    const t = await j(
      await h.request("/v1/tasks", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          title: "Fix login",
          details_md: "Users get a redirect loop.",
          assignee_bot_id: botId,
        },
      }),
    );
    expect(t.conversation_id).toBeTruthy();
    const done = await waitFor(
      () => ticket(t.id),
      (x) => x.status === "done",
    );
    expect(done.result_md).toContain("Fixed the login redirect");
    const cs = await comments(t.id);
    expect(cs.at(-1)).toMatchObject({ author_type: "bot" });
    expect(cs.at(-1)?.body_md).toContain("Fixed the login redirect");
  });

  it("finishes in review when review is required, and a comment wakes the bot", async () => {
    const t = await j(
      await h.request("/v1/tasks", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, title: "Write docs", review_required: true },
      }),
    );
    expect(t.conversation_id).toBeNull();
    await h.request(`/v1/tasks/${t.id}`, {
      method: "PATCH",
      token: owner.token,
      json: { assignee_bot_id: botId },
    });
    await waitFor(
      () => ticket(t.id),
      (x) => x.status === "in_review",
    );
    const res = await h.request(`/v1/tasks/${t.id}/comments`, {
      method: "POST",
      token: owner.token,
      json: { body_md: "Please mention the Windows steps too." },
    });
    expect(res.status).toBe(201);
    const conv = (await ticket(t.id)).conversation_id as string;
    const runs = await waitFor(
      () =>
        h.tdb.admin<
          { status: string }[]
        >`select status from public.runs where trigger = 'task' and conversation_id = ${conv} order by created_at`,
      (r) => r.length === 2 && r[1]?.status === "completed",
    );
    expect(runs).toHaveLength(2);
  });

  it("a run that fails blocks the ticket and tells its owner", async () => {
    const t = await j(
      await h.request("/v1/tasks", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, title: "Something with no recorded answer", assignee_bot_id: botId },
      }),
    );
    await waitFor(
      () => ticket(t.id),
      (x) => x.status === "blocked",
    );
    expect((await comments(t.id)).at(-1)?.body_md).toMatch(/^Blocked:/);
    const [n] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.notifications where user_id = ${owner.id} and kind = 'ticket'`;
    expect(n?.n).toBe(1);
  });
});
