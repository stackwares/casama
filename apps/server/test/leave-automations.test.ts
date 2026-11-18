/**
 * Leaving a workspace stops that person's automations there (D-334): removing a membership pauses
 * their routines and watchers in that workspace (a trigger), and the worker skips any routine or
 * watcher whose creator is no longer a member when it would fire.
 */
import { checkWatchers } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { claimDueRoutines, startRoutineForMessage } from "../src/worker/routines.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let member: { id: string; token: string };
let orgId: string;
let otherOrgId: string;
let botId: string;
let otherBotId: string;

const routine = async (org: string, bot: string, by: string | null, name: string) =>
  (
    await h.tdb.admin<{ id: string }[]>`
      insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, next_run_at)
      values (${org}, ${bot}, ${by}, ${name}, 'Do the thing', '0 9 * * *', 'UTC', now() - interval '1 minute')
      returning id`
  )[0]!.id;
const watcher = async (org: string, bot: string, by: string | null, name: string) =>
  (
    await h.tdb.admin<{ id: string }[]>`
      insert into public.watchers (org_id, bot_id, created_by, name, kind, target, next_check_at)
      values (${org}, ${bot}, ${by}, ${name}, 'time', ${JSON.stringify({ at: new Date(Date.now() + 86_400_000).toISOString() })}::jsonb, now() - interval '1 minute')
      returning id`
  )[0]!.id;
const enabled = async (id: string) =>
  (
    await h.tdb.admin<{ enabled: boolean }[]>`select enabled from public.routines where id = ${id}`
  )[0]!.enabled;
const status = async (id: string) =>
  (await h.tdb.admin<{ status: string }[]>`select status from public.watchers where id = ${id}`)[0]!
    .status;
const runsOf = async (id: string) =>
  (
    await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.runs where routine_id = ${id}`
  )[0]!.n;

const makeBot = async (org: string, name: string) => {
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: org, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
    }),
  );
  return (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: org,
          name,
          model_policy: { primary: { credential_id: cred.id, model: "m" } },
        },
      }),
    )
  ).id as string;
};

beforeAll(async () => {
  h = await startHarness();
  owner = await h.user("leave-owner@example.com");
  member = await h.user("leave-member@example.com");
  const org = async (name: string) =>
    (await j(await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name } })))
      .id as string;
  orgId = await org("Leavers");
  otherOrgId = await org("Stayers");
  for (const o of [orgId, otherOrgId])
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${o}, ${member.id}, 'member')`;
  botId = await makeBot(orgId, "Helper");
  otherBotId = await makeBot(otherOrgId, "Other");
});
afterAll(async () => {
  await h?.stop();
});

describe("leaving a workspace (D-334)", () => {
  it("pauses the person's routines and watchers there, and nothing else", async () => {
    const theirs = await routine(orgId, botId, member.id, "Member's routine");
    const theirWatcher = await watcher(orgId, botId, member.id, "Member's watcher");
    const ownersRoutine = await routine(orgId, botId, owner.id, "Owner's routine");
    const ownersWatcher = await watcher(orgId, botId, owner.id, "Owner's watcher");
    const elsewhere = await routine(otherOrgId, otherBotId, member.id, "Elsewhere");
    const elsewhereWatcher = await watcher(otherOrgId, otherBotId, member.id, "Elsewhere watcher");

    await h.tdb
      .admin`delete from public.memberships where org_id = ${orgId} and user_id = ${member.id}`;

    expect(await enabled(theirs)).toBe(false);
    expect(await status(theirWatcher)).toBe("paused");
    // Still there to turn back on after rejoining.
    expect((await h.tdb.admin`select 1 from public.routines where id = ${theirs}`).length).toBe(1);
    // The creator who stayed, and the workspace they're still in, are untouched.
    expect(await enabled(ownersRoutine)).toBe(true);
    expect(await status(ownersWatcher)).toBe("active");
    expect(await enabled(elsewhere)).toBe(true);
    expect(await status(elsewhereWatcher)).toBe("active");
  });

  it("the worker skips a routine or watcher whose creator left, even if it's still on", async () => {
    // As if the trigger had missed it: switched back on directly while its creator is gone.
    const orphan = await routine(orgId, botId, member.id, "Orphan routine");
    const orphanWatcher = await watcher(orgId, botId, member.id, "Orphan watcher");
    const kept = await routine(orgId, botId, owner.id, "Kept routine");
    const nobody = await routine(orgId, botId, null, "Nobody's routine");

    await claimDueRoutines(h.handle.db);
    expect(await runsOf(orphan)).toBe(0);
    expect(await runsOf(kept)).toBe(1);
    expect(await runsOf(nobody)).toBe(1);
    expect(await startRoutineForMessage(h.handle.db, orphan, "hello")).toBeNull();

    const before = await h.tdb.admin<
      { last_checked_at: Date | null }[]
    >`select last_checked_at from public.watchers where id = ${orphanWatcher}`;
    expect(before[0]!.last_checked_at).toBeNull();
    await checkWatchers({ db: h.handle.db, fetch, startRun: async () => {} });
    const [after] = await h.tdb.admin<
      { last_checked_at: Date | null; next_check_at: Date }[]
    >`select last_checked_at, next_check_at from public.watchers where id = ${orphanWatcher}`;
    expect(after!.last_checked_at).toBeNull();
    expect(new Date(after!.next_check_at).getTime()).toBeLessThan(Date.now());
  });

  it("deleting the workspace still works", async () => {
    const [o] = await h.tdb.admin<{ id: string }[]>`
      insert into public.organizations (name, slug) values ('Gone', 'gone-d334') returning id`;
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${o!.id}, ${member.id}, 'owner')`;
    await h.tdb.admin`delete from public.organizations where id = ${o!.id}`;
    expect(
      (await h.tdb.admin`select 1 from public.memberships where org_id = ${o!.id}`).length,
    ).toBe(0);
  });
});
