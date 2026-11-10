/** Step replay (D-127): saved from a teach recording; a replay run hands over to the model when it can't run. */
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/replays.json", import.meta.url));
let h: Harness;
let owner: { id: string; token: string };
let member: { id: string; token: string };
let orgId: string;
let botId: string;
let teachId: string;

const settle = async () => {
  for (let i = 0; i < 200; i++) {
    const [r] = await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.runs where status in ('queued', 'running')`;
    if (!r?.n) return;
    await new Promise((res) => setTimeout(res, 100));
  }
};

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  owner = await h.user("replay@example.com");
  member = await h.user("replay-member@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "R" } }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
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
          name: "Clerk",
          model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
          autonomy: "autonomous",
        },
      }),
    )
  ).id;
  const [k] = await h.tdb.admin<
    { id: string }[]
  >`insert into public.computers (org_id, kind, owner_bot_id, name, provider) values (${orgId}, 'private', ${botId}, 'c', 'e2b') returning id`;
  const [t] = await h.tdb.admin<
    { id: string }[]
  >`insert into public.teach_sessions (org_id, bot_id, computer_id, user_id, status) values (${orgId}, ${botId}, ${k!.id}, ${owner.id}, 'saved') returning id`;
  teachId = t!.id;
  await h.tdb
    .admin`insert into public.teach_steps (session_id, seq, org_id, kind, x, y, button, url) values (${teachId}, 1, ${orgId}, 'click', 100, 200, 1, 'https://portal.example.com/new')`;
  await h.tdb
    .admin`insert into public.teach_steps (session_id, seq, org_id, kind, text) values (${teachId}, 2, ${orgId}, 'type', '42.50')`;
  await h.tdb
    .admin`insert into public.teach_steps (session_id, seq, org_id, kind, secret_name, password, url) values (${teachId}, 3, ${orgId}, 'type', 'PASSWORD', true, 'https://portal.example.com/login')`;
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

describe("step replay", () => {
  let replayId: string;

  it("saves a teach recording as a replay with a parameter and a secret", async () => {
    expect(
      (
        await h.request(`/v1/teach/${teachId}/replay`, {
          method: "POST",
          token: member.token,
          json: { name: "file-expense" },
        })
      ).status,
    ).toBe(404); // recordings are private to who made them
    const r = await j(
      await h.request(`/v1/teach/${teachId}/replay`, {
        method: "POST",
        token: owner.token,
        json: { name: "file-expense", description: "File an expense" },
      }),
    );
    replayId = r.id;
    expect(r).toMatchObject({
      name: "file-expense",
      source: "teach",
      params: [{ name: "text_1", default: "42.50" }],
    });
    expect(r.steps.map((s: { tool: string }) => s.tool)).toEqual([
      "desktop.click",
      "desktop.type",
      "desktop.type",
    ]);
    const [stored] = await h.tdb.admin<
      { steps: unknown }[]
    >`select steps from public.replays where id = ${replayId}`;
    expect(JSON.stringify(stored?.steps)).toContain("{{secret:PASSWORD}}");
    expect(
      (
        await h.request(`/v1/teach/${teachId}/replay`, {
          method: "POST",
          token: owner.token,
          json: { name: "file-expense" },
        })
      ).status,
    ).toBe(409);
    const list = await j(await h.request(`/v1/replays?bot_id=${botId}`, { token: member.token }));
    expect(list.items).toHaveLength(1);
  });

  it("a replay run hands over to the model when the replay can't run (here: the bot has no desktop tools)", async () => {
    const started = await j(
      await h.request(`/v1/replays/${replayId}/run`, {
        method: "POST",
        token: owner.token,
        json: { params: { text_1: "99" } },
      }),
    );
    await settle();
    const [run] = await h.tdb.admin<
      { status: string; trigger: string; error: unknown }[]
    >`select status, trigger, error from public.runs where id = ${started.run_id}`;
    expect(run).toMatchObject({ status: "completed", trigger: "replay" });
    const msgs = await h.tdb.admin<{ role: string; content: Array<{ text: string }> }[]>`
      select role, content from public.messages where conversation_id = ${started.conversation_id} order by created_at`;
    expect(msgs[0]?.content[0]?.text).toBe('Run the replay "file-expense" with text_1 = 99.');
    expect(msgs.at(-1)?.content[0]?.text).toBe(
      "The replay couldn't run, so I'll do the steps myself.",
    );
  });

  it("only managers delete replays", async () => {
    expect(
      (await h.request(`/v1/replays/${replayId}`, { method: "DELETE", token: member.token }))
        .status,
    ).toBe(403);
    expect(
      (await h.request(`/v1/replays/${replayId}`, { method: "DELETE", token: owner.token })).status,
    ).toBe(200);
  });
});
