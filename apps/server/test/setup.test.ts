/** Setup interview (D-105): a setup conversation proposes everything through one approval. */
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/setup.json", import.meta.url));
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
let h: Harness;
let owner: { id: string; token: string };
let member: { id: string; token: string };
let orgId: string;
let botId: string;

const waitStatus = async (runId: string, status: string) => {
  for (let i = 0; i < 150; i++) {
    const r = await j(await h.request(`/v1/runs/${runId}`, { token: owner.token }));
    if (r.status === status) return r;
    await sleep(100);
  }
  throw new Error(`run never reached ${status}`);
};

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  owner = await h.user("setup-owner@example.com");
  member = await h.user("setup-member@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Bakery" } }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
  await h.tdb
    .admin`insert into public.profiles (user_id, timezone) values (${owner.id}, 'America/Chicago')
    on conflict (user_id) do update set timezone = excluded.timezone`;
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
        name: "Baker",
        model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
      },
    }),
  );
  botId = bot.id;
  expect(bot.setup_status).toBe("pending");
}, 60_000);
afterAll(async () => h?.stop());

describe("setup interview", () => {
  it("only the bot's managers start it", async () => {
    expect(
      (await h.request(`/v1/bots/${botId}/setup`, { method: "POST", token: member.token })).status,
    ).toBe(403);
  });

  it("proposes instructions, memories and routines for one approval, then applies them", async () => {
    const res = await h.request(`/v1/bots/${botId}/setup`, { method: "POST", token: owner.token });
    expect(res.status).toBe(201);
    const { run_id, conversation_id } = await j(res);
    await waitStatus(run_id, "waiting_approval");
    const approvals = await j(
      await h.request(`/v1/approvals?org_id=${orgId}`, { token: owner.token }),
    );
    const a = approvals.items.find((x: { tool_name: string }) => x.tool_name === "setup.apply");
    expect(a.risk).toBe("high");
    expect(a.args_redacted.memories).toContain("Ada owns a bakery in Portland");
    expect(a.args_redacted.connections).toEqual(["Gmail"]);
    await h.request(`/v1/approvals/${a.id}/decision`, {
      method: "POST",
      token: owner.token,
      json: { decision: "approved" },
    });
    await waitStatus(run_id, "completed");

    const [bot] = await h.tdb.admin<
      { persona_md: string; setup_status: string }[]
    >`select persona_md, setup_status from public.bots where id = ${botId}`;
    expect(bot).toMatchObject({
      setup_status: "done",
      persona_md: expect.stringContaining("small bakery"),
    });
    const mems = await h.tdb.admin<
      { content: string }[]
    >`select content from public.memories where bot_id = ${botId} order by content`;
    expect(mems.map((m) => m.content)).toEqual([
      "Ada owns a bakery in Portland",
      "Ada prefers bullet points",
    ]);
    const [routine] = await h.tdb.admin<
      { name: string; timezone: string }[]
    >`select name, timezone from public.routines where bot_id = ${botId}`;
    expect(routine).toEqual({ name: "Morning orders", timezone: "America/Chicago" });
    const [rev] = await h.tdb.admin<
      { changed_by_bot: string }[]
    >`select changed_by_bot from public.bot_revisions where bot_id = ${botId} and 'persona_md' = any(changed_fields)`;
    expect(rev?.changed_by_bot).toBe(botId);
    const evs = (
      await j(await h.request(`/v1/runs/${run_id}/events?limit=1000`, { token: owner.token }))
    ).items as Array<{ type: string; payload: Record<string, unknown> }>;
    expect(JSON.stringify(evs.find((e) => e.type === "tool.completed")?.payload)).toContain(
      "connect Gmail",
    );
    const [conv] = await h.tdb.admin<
      { purpose: string }[]
    >`select purpose from public.conversations where id = ${conversation_id}`;
    expect(conv?.purpose).toBe("setup");
  });

  it("normal chats don't get the setup guide", async () => {
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: botId },
      }),
    );
    const sent = await j(
      await h.request(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token: owner.token,
        json: { text: "hello" },
      }),
    );
    await waitStatus(sent.run_id, "completed");
    const [m] = await h.tdb.admin<
      { content: unknown }[]
    >`select content from public.messages where conversation_id = ${conv.id} and role = 'assistant'`;
    expect(JSON.stringify(m?.content)).toContain("Plain chat.");
  });
});
