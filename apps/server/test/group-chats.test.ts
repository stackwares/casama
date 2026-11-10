/** Group chats (D-118): @everyone gets a plan and each bot's work; @Name wakes only that bot. */
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/groups.json", import.meta.url));
let h: Harness;
let owner: { id: string; token: string };
let member: { id: string; token: string };
let orgId: string;
let cred: string;
const bot = async (name: string, extra: Record<string, unknown> = {}) =>
  (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name,
          persona_md: `You are ${name}.`,
          visibility: "team",
          model_policy: { primary: { credential_id: cred, model: "fixture-main" } },
          ...extra,
        },
      }),
    )
  ).id as string;
const settle = async () => {
  for (let i = 0; i < 300; i++) {
    const [r] = await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.runs where status in ('queued', 'running')`;
    if (!r?.n) {
      await new Promise((res) => setTimeout(res, 150));
      const [again] = await h.tdb.admin<
        { n: number }[]
      >`select count(*)::int as n from public.runs where status in ('queued', 'running')`;
      if (!again?.n) return;
    }
    await new Promise((res) => setTimeout(res, 100));
  }
  throw new Error("runs did not settle");
};
const replies = async (conv: string) =>
  (
    await h.tdb.admin<{ name: string; text: string }[]>`
      select b.name, m.content->0->>'text' as text from public.messages m join public.bots b on b.id = m.bot_id
      where m.conversation_id = ${conv} and m.role = 'assistant' order by m.created_at`
  ).map((r) => `${r.name}: ${r.text}`);

let lead: string;
let writer: string;
let designer: string;
let conv: string;

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  owner = await h.user("group-owner@example.com");
  member = await h.user("group-member@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "G" } }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
  await h.tdb
    .admin`update public.entitlements set limits = limits - 'max_bots' where org_id = ${orgId}`;
  cred = (
    await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          provider: "openrouter",
          label: "k",
          api_key: "sk-or-v1-abcdefabcdef",
        },
      }),
    )
  ).id;
  lead = await bot("Lead");
  writer = await bot("Writer");
  designer = await bot("Designer");
  const res = await h.request("/v1/conversations", {
    method: "POST",
    token: owner.token,
    json: { bot_id: lead, bot_ids: [writer, designer], title: "Launch" },
  });
  expect(res.status).toBe(201);
  const c = await j(res);
  expect(c).toMatchObject({ kind: "group", bot_ids: [lead, writer, designer] });
  conv = c.id;
}, 60_000);
afterAll(async () => h?.stop());

const send = async (text: string) =>
  j(
    await h.request(`/v1/conversations/${conv}/messages`, {
      method: "POST",
      token: owner.token,
      json: { text },
    }),
  );

describe("group chats", () => {
  it("@everyone gets a plan from the lead and work from each assigned bot", async () => {
    const sent = await send("@everyone let's ship the launch");
    expect(sent.run_ids).toHaveLength(1);
    await settle();
    const r = await replies(conv);
    expect(r[0]).toBe("Lead: Plan: @Writer write the launch copy. @Designer make the banner.");
    expect(r.slice(1).sort()).toEqual([
      "Designer: Banner done.",
      "Writer: Copy done: Meet Kasama.",
    ]);
    const [hops] = await h.tdb.admin<
      { max: number }[]
    >`select max(hop)::int as max from public.runs where conversation_id = ${conv}`;
    expect(hops?.max).toBe(1);
  });

  it("@Name wakes only that bot; no mention goes to whoever spoke last", async () => {
    const before = (await replies(conv)).length;
    const sent = await send("@Writer fix the typo");
    expect(sent.run_ids).toHaveLength(1);
    await settle();
    const after = await replies(conv);
    expect(after.slice(before)).toEqual(["Writer: Fixed it."]);
    await send("and the title too");
    await settle();
    expect((await replies(conv)).at(-1)).toBe("Writer: Fixed it.");
  });

  it("bot-to-bot mentions stop after 6 hops", async () => {
    const ping = await bot("Ping");
    const pong = await bot("Pong");
    const c = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: ping, bot_ids: [pong] },
      }),
    );
    if (!c.id) throw new Error(JSON.stringify(c));
    await h.request(`/v1/conversations/${c.id}/messages`, {
      method: "POST",
      token: owner.token,
      json: { text: "@Ping start" },
    });
    await settle();
    const [n] = await h.tdb.admin<
      { n: number; max: number }[]
    >`select count(*)::int as n, max(hop)::int as max from public.runs where conversation_id = ${c.id}`;
    expect(n).toEqual({ n: 7, max: 6 });
  });

  it("a member only sees a group chat if they can see every bot in it", async () => {
    const secret = await bot("Secret", { visibility: "private" });
    const hidden = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: lead, bot_ids: [secret] },
      }),
    );
    const visible = await j(
      await h.request(`/v1/group-chats?org_id=${orgId}`, { token: member.token }),
    );
    const ids = visible.items.map((g: { id: string }) => g.id);
    expect(ids).toContain(conv);
    expect(ids).not.toContain(hidden.id);
    expect(
      (
        await h.request(`/v1/conversations/${hidden.id}/messages`, {
          method: "POST",
          token: member.token,
          json: { text: "hi" },
        })
      ).status,
    ).toBe(404);
  });
  it("with the bot-to-bot switch off, a bot's @mention isn't delivered and the timeline says why", async () => {
    const off = await h.request(`/v1/orgs/${orgId}/settings`, {
      method: "PATCH",
      token: owner.token,
      json: { allow_bot_to_bot: false },
    });
    expect(off.status).toBe(200);
    expect((await j(off)).allow_bot_to_bot).toBe(false);
    const c = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: lead, bot_ids: [writer, designer], title: "Quiet" },
      }),
    );
    await h.request(`/v1/conversations/${c.id}/messages`, {
      method: "POST",
      token: owner.token,
      json: { text: "@everyone let's ship the launch" },
    });
    await settle();
    expect(await replies(c.id)).toEqual([
      "Lead: Plan: @Writer write the launch copy. @Designer make the banner.",
    ]);
    const [ev] = await h.tdb.admin<{ payload: { code: string; message: string } }[]>`
      select e.payload from public.run_events e join public.runs r on r.id = e.run_id where r.conversation_id = ${c.id} and e.type = 'notice'`;
    expect(ev?.payload).toEqual({
      code: "bot_to_bot_off",
      message: "@Writer, @Designer weren't told: bots can't message each other in this workspace.",
    });
    await h.request(`/v1/orgs/${orgId}/settings`, {
      method: "PATCH",
      token: owner.token,
      json: { allow_bot_to_bot: true },
    });
  });
});
