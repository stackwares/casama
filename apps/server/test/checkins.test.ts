/** Check-ins (D-114): brief, scans that suggest or stay silent, the For you feed, accept and dismiss. */
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { claimDueRoutines } from "../src/worker/routines.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/checkins.json", import.meta.url));
let h: Harness;
let owner: { id: string; token: string };
let orgId: string;
let botId: string;

const settle = async () => {
  for (let i = 0; i < 200; i++) {
    const [r] = await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.runs where status in ('queued', 'running')`;
    if (!r?.n) return;
    await new Promise((res) => setTimeout(res, 100));
  }
  throw new Error("runs did not settle");
};
const fire = async (kind: "brief" | "scan") => {
  await h.tdb
    .admin`update public.routines set next_run_at = now() - interval '1 minute' where bot_id = ${botId} and kind = ${kind}`;
  const ids = await claimDueRoutines(h.handle.db);
  for (const id of ids) await h.deps.workflows.startRun(id);
  await settle();
  return ids;
};

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  owner = await h.user("checkins@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "C" } }),
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
          name: "Aide",
          model_policy: {
            primary: { credential_id: cred.id, model: "fixture-main" },
            cheap: { credential_id: cred.id, model: "fixture-cheap" },
          },
        },
      }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.devices (user_id, fcm_token, platform) values (${owner.id}, 'tok-c', 'ios')`;
}, 60_000);
afterAll(async () => h?.stop());

describe("check-ins", () => {
  it("are off by default and create a brief and a scan routine when turned on", async () => {
    expect(
      (await j(await h.request(`/v1/bots/${botId}/checkins`, { token: owner.token }))).enabled,
    ).toBe(false);
    const res = await j(
      await h.request(`/v1/bots/${botId}/checkins`, {
        method: "PUT",
        token: owner.token,
        json: { enabled: true, brief_time: "08:00", scan_every_hours: 3, daily_cap_usd: 1 },
      }),
    );
    expect(res.enabled).toBe(true);
    const rows = await h.tdb.admin<{ kind: string; schedule_cron: string; notify: boolean }[]>`
      select kind, schedule_cron, notify from public.routines where bot_id = ${botId} order by kind`;
    expect(rows).toEqual([
      { kind: "brief", schedule_cron: "0 8 * * *", notify: true },
      { kind: "scan", schedule_cron: "0 */3 * * *", notify: false },
    ]);
  });

  it("the brief runs on the cheaper model and shows in For you", async () => {
    await fire("brief");
    const feed = await j(await h.request(`/v1/for-you?org_id=${orgId}`, { token: owner.token }));
    expect(feed.briefs[0].text).toContain("10:00 Standup");
    const [u] = await h.tdb.admin<{ model: string }[]>`
      select u.model from public.usage_ledger u join public.runs r on r.id = u.run_id join public.routines rt on rt.id = r.routine_id
      where rt.kind = 'brief' limit 1`;
    expect(u?.model).toBe("fixture-cheap");
  });

  it("a scan leaves suggestions (urgent ones notify); a quiet scan writes and sends nothing", async () => {
    await fire("scan");
    const feed = await j(await h.request(`/v1/for-you?org_id=${orgId}`, { token: owner.token }));
    expect(feed.suggestions).toHaveLength(1);
    expect(feed.suggestions[0]).toMatchObject({
      title: "Reply to Ana about the invoice",
      urgency: "urgent",
      proposed_action: { tool: "http.request" },
    });
    const count = async () =>
      (
        await h.tdb.admin<{ s: number; n: number; c: number }[]>`
        select (select count(*)::int from public.suggestions) as s,
               (select count(*)::int from public.notifications where user_id = ${owner.id}) as n,
               (select count(*)::int from public.conversations where bot_id = ${botId}) as c`
      )[0];
    const before = await count();
    expect(before?.n).toBeGreaterThanOrEqual(1);
    await fire("scan"); // nothing new
    expect(await count()).toEqual(before);
  });

  it("accepting runs it through a normal chat; dismissing can remember not to suggest it", async () => {
    const feed = await j(await h.request(`/v1/for-you?org_id=${orgId}`, { token: owner.token }));
    const res = await h.request(`/v1/suggestions/${feed.suggestions[0].id}/accept`, {
      method: "POST",
      token: owner.token,
    });
    expect(res.status).toBe(202);
    await settle();
    const [s] = await h.tdb.admin<{ id: string }[]>`
      insert into public.suggestions (org_id, bot_id, user_id, title) values (${orgId}, ${botId}, ${owner.id}, 'Unsubscribe from newsletters') returning id`;
    await h.request(`/v1/suggestions/${s!.id}/dismiss`, {
      method: "POST",
      token: owner.token,
      json: { dont_suggest_again: true },
    });
    const [m] = await h.tdb.admin<
      { content: string }[]
    >`select content from public.memories where bot_id = ${botId} and content like 'Don''t suggest%'`;
    expect(m?.content).toContain("Unsubscribe from newsletters");
    expect(
      (await j(await h.request(`/v1/for-you?org_id=${orgId}`, { token: owner.token }))).suggestions,
    ).toEqual([]);
  });

  it("skip once today's cap is used", async () => {
    await h.tdb.admin`update public.bot_checkins set daily_cap_usd = 0.01 where bot_id = ${botId}`;
    await h.tdb
      .admin`update public.runs set cost_usd = 1 where routine_id in (select id from public.routines where bot_id = ${botId})`;
    expect(await fire("scan")).toEqual([]);
  });
});
