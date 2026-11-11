/** Regressions for the November 2026 audit fixes (docs/AUDIT-2026-11.md). */
import { actingUserOf, messageMatches, personForRun, takeHeldForBrief } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { claimDueRoutines } from "../src/worker/routines.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let orgA: string;
let orgB: string;
let botA: string;

beforeAll(async () => {
  h = await startHarness({});
  owner = await h.user("audit-owner@example.com");
  orgA = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "A" } }),
    )
  ).id;
  orgB = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "B" } }),
    )
  ).id;
  botA = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgA, name: "Ada" },
      }),
    )
  ).id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

describe("audit fixes", () => {
  it("a linked bot's request (and its sub-runs) acts for nobody, though recorded under the owner", async () => {
    const [link] = await h.tdb.admin<
      { id: string }[]
    >`insert into public.runs (org_id, bot_id, created_by, trigger) values (${orgA}, ${botA}, ${owner.id}, 'link') returning id`;
    const [sub] = await h.tdb.admin<
      { id: string }[]
    >`insert into public.runs (org_id, bot_id, parent_run_id, trigger) values (${orgA}, ${botA}, ${link!.id}, 'subrun') returning id`;
    const [chat] = await h.tdb.admin<
      { id: string }[]
    >`insert into public.runs (org_id, bot_id, created_by, trigger) values (${orgA}, ${botA}, ${owner.id}, 'chat') returning id`;
    expect(await actingUserOf(h.deps.db, link!.id)).toBeNull();
    expect(await actingUserOf(h.deps.db, sub!.id)).toBeNull();
    expect(await actingUserOf(h.deps.db, chat!.id)).toBe(owner.id);
  });

  it("a sub-run's messages go to the person who started the work, not the bot's creator", async () => {
    const mate = await h.user("audit-mate@example.com");
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${orgA}, ${mate.id}, 'member')`;
    const [parent] = await h.tdb.admin<
      { id: string }[]
    >`insert into public.runs (org_id, bot_id, created_by, trigger) values (${orgA}, ${botA}, ${mate.id}, 'chat') returning id`;
    const [sub] = await h.tdb.admin<
      { id: string }[]
    >`insert into public.runs (org_id, bot_id, parent_run_id, trigger) values (${orgA}, ${botA}, ${parent!.id}, 'subrun') returning id`;
    expect((await personForRun(h.deps.db, sub!.id)).userId).toBe(mate.id);
  });

  it("message routines without their own sender filter only hear the channel's allowed senders", () => {
    const c = { id: "c1", kind: "email" as const, allowed_senders: ["ana@acme.com"] };
    const msg = (sender: string) => ({
      sender,
      text: "invoice attached",
      threadKey: "t",
      subject: "Invoice",
      reply: {},
    });
    expect(
      messageMatches({ type: "message", subject_match: "invoice" }, c, msg("ana@acme.com")),
    ).toBe(true);
    expect(
      messageMatches({ type: "message", subject_match: "invoice" }, c, msg("stranger@evil.test")),
    ).toBe(false);
    expect(
      messageMatches(
        { type: "message", sender: "*", subject_match: "invoice" },
        c,
        msg("stranger@evil.test"),
      ),
    ).toBe(true);
    expect(
      messageMatches({ type: "message", sender: "*@vendor.test" }, c, msg("bills@vendor.test")),
    ).toBe(true);
  });

  it("a brief only carries its own workspace's held messages", async () => {
    for (const org of [orgA, orgB])
      await h.tdb
        .admin`insert into public.notifications (user_id, org_id, kind, payload, push_status, urgency, held_reason)
        values (${owner.id}, ${org}, 'routine_result', jsonb_build_object('title', ${`From ${org === orgA ? "A" : "B"}`}::text), 'held', 'normal', 'meeting')`;
    const text = await takeHeldForBrief(h.deps.db, owner.id, orgA);
    expect(text).toContain("From A");
    expect(text).not.toContain("From B");
    expect(
      await h.tdb
        .admin`select 1 from public.notifications where org_id = ${orgB} and push_status = 'held'`,
    ).toHaveLength(1);
  });

  it("one broken routine doesn't stop the others from running", async () => {
    const past = new Date(Date.now() - 60_000).toISOString();
    const [bad] = await h.tdb.admin<
      { id: string }[]
    >`insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, next_run_at)
      values (${orgA}, ${botA}, ${owner.id}, 'Broken', 'x', '0 8 * * *', 'Not/AZone', ${past}) returning id`;
    const [good] = await h.tdb.admin<
      { id: string }[]
    >`insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, next_run_at)
      values (${orgA}, ${botA}, ${owner.id}, 'Fine', 'y', '0 8 * * *', 'UTC', ${past}) returning id`;
    const ids = await claimDueRoutines(h.deps.db);
    const [run] = await h.tdb.admin<
      { id: string }[]
    >`select id from public.runs where routine_id = ${good!.id}`;
    expect(ids).toContain(run!.id);
    // The broken one doesn't leave a half-made run behind, and it won't be retried every minute.
    expect(await h.tdb.admin`select 1 from public.runs where routine_id = ${bad!.id}`).toHaveLength(
      0,
    );
    const [b] = await h.tdb.admin<
      { enabled: boolean; next_run_at: Date | null }[]
    >`select enabled, next_run_at from public.routines where id = ${bad!.id}`;
    expect(
      b!.enabled === false || (b!.next_run_at && new Date(b!.next_run_at) > new Date()),
    ).toBeTruthy();
  });
});

describe("routines post in the person's chat (D-155)", () => {
  it("a routine with no chat recorded runs in the person's latest chat with the bot, marked as a routine", async () => {
    const [chat] = await h.tdb.admin<{ id: string }[]>`
      insert into public.conversations (org_id, bot_id, created_by, last_message_at) values (${orgA}, ${botA}, ${owner.id}, now()) returning id`;
    const past = new Date(Date.now() - 60_000).toISOString();
    const [r] = await h.tdb.admin<{ id: string }[]>`
      insert into public.routines (org_id, bot_id, created_by, name, instructions_md, trigger, timezone, next_run_at)
      values (${orgA}, ${botA}, ${owner.id}, 'Say hi', 'Say hi', '{"type":"once"}', 'UTC', ${past}) returning id`;
    await claimDueRoutines(h.deps.db);
    const [run] = await h.tdb.admin<{ conversation_id: string }[]>`
      select conversation_id from public.runs where routine_id = ${r!.id}`;
    expect(run!.conversation_id).toBe(chat!.id);
    const [m] = await h.tdb.admin<{ content: Array<{ routine?: { name: string } }> }[]>`
      select content from public.messages where run_id in (select id from public.runs where routine_id = ${r!.id}) and role = 'user'`;
    expect(m!.content[0]!.routine?.name).toBe("Say hi");
  });
});

describe("the API role can enqueue runs (audit 2026-11)", () => {
  it("the worker grants the API's database role access to DBOS's tables", async () => {
    const h2 = await startHarness({
      worker: { fixtures: undefined as never, apiDatabaseRole: "casama_api_probe" },
    });
    try {
      const [r] = await h2.tdb.admin<{ ok: boolean; usage: boolean }[]>`
        select has_table_privilege('casama_api_probe', 'dbos.workflow_status', 'insert') as ok,
               has_schema_privilege('casama_api_probe', 'dbos', 'usage') as usage`;
      expect(r).toEqual({ ok: true, usage: true });
    } finally {
      await h2.stop();
    }
  }, 60_000);
});
