/** The glance (D-405): what a person's widgets show, built from their own data. */
import { Glance } from "@casama/contracts";
import { createDb, type DbHandle } from "@casama/db";
import { startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { cronWords } from "@casama/domain";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { buildGlance, GLANCE_LIMITS, glanceCut } from "../src/glance.ts";

let tdb: TestDatabase;
let h: DbHandle;
const ids = {
  me: "",
  other: "",
  org: "",
  ada: "",
  bo: "",
  conv: "",
  approvalNew: "",
  approvalOld: "",
  takeover: "",
  computer: "",
  urgentSuggestion: "",
  briefConv: "",
  tripCreation: "",
};
const NOW = new Date();
const ago = (minutes: number) => new Date(NOW.getTime() - minutes * 60_000).toISOString();
const ahead = (minutes: number) => new Date(NOW.getTime() + minutes * 60_000).toISOString();
const one = async <T>(q: Promise<unknown>) => ((await q) as unknown as T[])[0] as T;

beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 2 });
  const a = tdb.admin;
  ids.me = (
    await one<{ id: string }>(a`insert into auth.users (id, email, aud, role)
      values (gen_random_uuid(), 'glance-me@example.com', 'authenticated', 'authenticated') returning id`)
  ).id;
  ids.other = (
    await one<{ id: string }>(a`insert into auth.users (id, email, aud, role)
      values (gen_random_uuid(), 'glance-other@example.com', 'authenticated', 'authenticated') returning id`)
  ).id;
  ids.org = (
    await one<{ id: string }>(
      a`insert into public.organizations (name, slug) values ('Glance', 'glance-test') returning id`,
    )
  ).id;
  await a`insert into public.memberships (org_id, user_id, role) values
    (${ids.org}, ${ids.me}, 'owner'), (${ids.org}, ${ids.other}, 'member')`;

  // Ten bots: the glance carries the first eight in the person's order.
  ids.ada = (
    await one<{
      id: string;
    }>(a`insert into public.bots (org_id, created_by, name, avatar_url, status, sort_key)
      values (${ids.org}, ${ids.me}, 'Ada', 'mascot:winky', 'working', 0) returning id`)
  ).id;
  ids.bo = (
    await one<{ id: string }>(a`insert into public.bots (org_id, created_by, name, status, sort_key)
      values (${ids.org}, ${ids.me}, 'Bo', 'idle', 1) returning id`)
  ).id;
  for (let i = 2; i < 10; i++)
    await a`insert into public.bots (org_id, created_by, name, sort_key) values (${ids.org}, ${ids.me}, ${`Bot ${i}`}, ${i})`;

  // Ada's chat: its last message, a finished run, and a run working on a web search now.
  ids.conv = (
    await one<{
      id: string;
    }>(a`insert into public.conversations (org_id, bot_id, created_by, last_message_at)
      values (${ids.org}, ${ids.ada}, ${ids.me}, now()) returning id`)
  ).id;
  await a`insert into public.messages (org_id, conversation_id, role, content, created_at) values
    (${ids.org}, ${ids.conv}, 'assistant', ${a.json([{ type: "text", text: "**Found** three flights\nunder $400." }])}, ${ago(5)}),
    (${ids.org}, ${ids.conv}, 'assistant', ${a.json([{ type: "tool_call", name: "web.search" }])}, ${ago(4)})`;
  const running = await one<{ id: string }>(a`
    insert into public.runs (org_id, bot_id, conversation_id, created_by, status, started_at)
    values (${ids.org}, ${ids.ada}, ${ids.conv}, ${ids.me}, 'running', now()) returning id`);
  await a`insert into public.run_events (run_id, seq, org_id, bot_id, type, payload) values
    (${running.id}, 1, ${ids.org}, ${ids.ada}, 'run.started', '{}'),
    (${running.id}, 2, ${ids.org}, ${ids.ada}, 'tool.started', ${a.json({ call_id: "c1", tool: "web.search", args_redacted: {} })})`;

  // What bots last finished for me: a creation, a routine, a reply; an older one falls off.
  const routine = await one<{ id: string }>(a`
    insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, enabled, kind)
    values (${ids.org}, ${ids.bo}, ${ids.me}, 'Morning digest', 'x', '0 7 * * *', false, 'task') returning id`);
  const done = async (bot: string, endedMin: number, routineId: string | null = null) =>
    (
      await one<{ id: string }>(a`
        insert into public.runs (org_id, bot_id, conversation_id, created_by, status, started_at, ended_at, routine_id, created_at)
        values (${ids.org}, ${bot}, ${ids.conv}, ${ids.me}, 'completed', ${ago(endedMin + 1)}, ${ago(endedMin)}, ${routineId}, ${ago(endedMin + 1)})
        returning id`)
    ).id;
  const tripRun = await done(ids.ada, 2);
  await done(ids.bo, 3, routine.id);
  await done(ids.bo, 4);
  await done(ids.bo, 60);
  ids.tripCreation = (
    await one<{ id: string }>(a`
      insert into public.creations (org_id, bot_id, run_id, kind, title, created_at)
      values (${ids.org}, ${ids.ada}, ${tripRun}, 'document', 'Trip plan', ${ago(2)}) returning id`)
  ).id;

  // Needs you: two approvals, a takeover, my three suggestions (one urgent), someone else's, a
  // skill idea.
  ids.approvalOld = (
    await one<{ id: string }>(a`
      insert into public.approvals (org_id, bot_id, run_id, call_id, tool_name, summary, risk, created_at)
      values (${ids.org}, ${ids.ada}, ${running.id}, 'a1', 'gmail.send', 'Send the itinerary to Sam', 'medium', ${ago(30)}) returning id`)
  ).id;
  ids.approvalNew = (
    await one<{ id: string }>(a`
      insert into public.approvals (org_id, bot_id, run_id, call_id, tool_name, summary, risk, created_at)
      values (${ids.org}, ${ids.ada}, ${running.id}, 'a2', 'web.fetch', ${`Read ${"a very long page title ".repeat(10)}`}, 'low', ${ago(1)}) returning id`)
  ).id;
  await a`insert into public.approvals (org_id, bot_id, run_id, call_id, tool_name, summary, risk, status)
    values (${ids.org}, ${ids.ada}, ${running.id}, 'a3', 'x', 'Already answered', 'low', 'approved')`;
  ids.computer = (
    await one<{ id: string }>(a`
      insert into public.computers (org_id, kind, name, provider) values (${ids.org}, 'local', 'Mac', 'local') returning id`)
  ).id;
  ids.takeover = (
    await one<{ id: string }>(a`
      insert into public.takeover_requests (org_id, bot_id, run_id, computer_id, reason, created_at)
      values (${ids.org}, ${ids.bo}, ${running.id}, ${ids.computer}, 'Solve the captcha', ${ago(10)}) returning id`)
  ).id;
  await a`insert into public.suggestions (org_id, bot_id, user_id, title, urgency, created_at) values
    (${ids.org}, ${ids.ada}, ${ids.me}, 'Book the window seat', 'normal', ${ago(3)}),
    (${ids.org}, ${ids.ada}, ${ids.me}, 'Renew the passport', 'normal', ${ago(2)}),
    (${ids.org}, ${ids.ada}, ${ids.other}, 'Not mine', 'urgent', ${ago(1)})`;
  ids.urgentSuggestion = (
    await one<{ id: string }>(a`
      insert into public.suggestions (org_id, bot_id, user_id, title, urgency, created_at)
      values (${ids.org}, ${ids.bo}, ${ids.me}, 'Leave now for the airport', 'urgent', ${ago(20)}) returning id`)
  ).id;
  await a`insert into public.skill_proposals (org_id, bot_id, kind, name, description, body_md)
    values (${ids.org}, ${ids.ada}, 'new', 'flights', 'Find flights', 'x')`;

  // Up next: seven scheduled routines (the soonest six show), one off, a check-in.
  for (let i = 0; i < 7; i++)
    await a`insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, next_run_at, enabled, kind)
      values (${ids.org}, ${ids.bo}, ${ids.me}, ${`Routine ${i}`}, 'x', '0 9 * * 1-5', ${ahead(60 * (7 - i))}, true, 'task')`;
  await a`insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, next_run_at, enabled, kind)
    values (${ids.org}, ${ids.bo}, ${ids.me}, 'Paused', 'x', '0 9 * * *', ${ahead(1)}, false, 'task')`;

  // The brief: Ada checks in for me at 7:00 and wrote this morning's an hour ago.
  await a`insert into public.bot_checkins (bot_id, org_id, user_id, enabled, brief_time)
    values (${ids.ada}, ${ids.org}, ${ids.me}, true, '07:00')`;
  const briefRoutine = await one<{ id: string }>(a`
    insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, next_run_at, enabled, kind)
    values (${ids.org}, ${ids.ada}, ${ids.me}, 'Brief', 'x', '0 7 * * *', ${ahead(5)}, true, 'brief') returning id`);
  ids.briefConv = (
    await one<{
      id: string;
    }>(a`insert into public.conversations (org_id, bot_id, created_by, last_message_at)
      values (${ids.org}, ${ids.ada}, ${ids.me}, ${ago(70)}) returning id`)
  ).id;
  const briefRun = await one<{ id: string }>(a`
    insert into public.runs (org_id, bot_id, conversation_id, created_by, status, routine_id, ended_at, created_at)
    values (${ids.org}, ${ids.ada}, ${ids.briefConv}, ${ids.me}, 'completed', ${briefRoutine.id}, ${ago(70)}, ${ago(70)}) returning id`);
  await a`insert into public.messages (org_id, conversation_id, role, content, run_id, created_at) values
    (${ids.org}, ${ids.briefConv}, 'assistant', ${a.json([{ type: "text", text: `# Morning brief\nYou have **3** meetings. ${"More words. ".repeat(80)}` }])}, ${briefRun.id}, ${ago(60)})`;

  // Seven creations: the newest six show.
  for (let i = 0; i < 6; i++)
    await a`insert into public.creations (org_id, bot_id, kind, title, cover_key, created_at)
      values (${ids.org}, ${ids.bo}, ${i % 2 ? "image" : "page"}, ${`Made ${i}`}, ${i === 0 ? "covers/x.png" : null}, ${ago(10 + i)})`;

  // The board.
  for (const [title, status] of [
    ["Write copy", "todo"],
    ["Plan launch", "todo"],
    ["Build page", "in_progress"],
    ["Check copy", "in_review"],
    ["Check numbers", "in_review"],
    ["Waiting on legal", "blocked"],
    ["Shipped", "done"],
  ] as const)
    await a`insert into public.tasks (org_id, title, status, assignee_bot_id) values (${ids.org}, ${title}, ${status}, ${ids.ada})`;

  // The default bot's starters (five saved; four show).
  await a`insert into public.chat_starters (user_id, bot_id, org_id, items, source) values
    (${ids.me}, ${ids.ada}, ${ids.org}, ${a.json([1, 2, 3, 4, 5].map((n) => ({ emoji: "✈️", text: `Idea ${n}` })))}, 'ai')`;

  // Spend: today and earlier this month (and one not billable).
  const monthStart = new Date(Date.UTC(NOW.getUTCFullYear(), NOW.getUTCMonth(), 1, 0, 1));
  await a`insert into public.usage_ledger (org_id, kind, quantity, cost_usd, billable, created_at) values
    (${ids.org}, 'tokens_in', 1, 0.5, true, now()),
    (${ids.org}, 'tokens_in', 1, 1.0, true, ${monthStart.toISOString()}),
    (${ids.org}, 'tokens_in', 1, 2.0, false, now())`;
}, 600_000);

afterAll(async () => {
  await h?.close();
  await tdb?.stop();
});

const build = (o: Partial<Parameters<typeof buildGlance>[1]> = {}) =>
  buildGlance(h.db, { userId: ids.me, orgId: ids.org, now: NOW, ...o });

describe("the glance", () => {
  it("fits the contract and its limits", async () => {
    const g = await build();
    expect(() => Glance.parse(g)).not.toThrow();
    expect(g.org_id).toBe(ids.org);
    expect(g.bots).toHaveLength(GLANCE_LIMITS.bots);
    expect(g.next).toHaveLength(GLANCE_LIMITS.next);
    expect(g.recent).toHaveLength(GLANCE_LIMITS.recent);
    expect(g.lately).toHaveLength(GLANCE_LIMITS.lately);
    expect(g.needs.items).toHaveLength(GLANCE_LIMITS.needs);
    expect(g.starters).toHaveLength(GLANCE_LIMITS.starters);
    // A few kilobytes at most, even full.
    expect(JSON.stringify(g).length).toBeLessThan(16_000);
  });

  it("counts every Needs you row, blocked bots first then urgent suggestions", async () => {
    const g = await build();
    // Two approvals, a takeover, my three suggestions and a skill idea.
    expect(g.needs.count).toBe(7);
    expect(g.needs.items.map((n) => n.id)).toEqual([
      ids.approvalNew,
      ids.takeover,
      ids.approvalOld,
      ids.urgentSuggestion,
    ]);
    const [approval, takeover, , suggestion] = g.needs.items;
    expect(approval).toMatchObject({
      kind: "approval",
      risk: "low",
      bot: "Ada",
      bot_avatar: "mascot:winky",
      link: `/approvals/${ids.approvalNew}`,
    });
    expect(approval?.text.length).toBeLessThanOrEqual(140);
    expect(approval?.text.endsWith("…")).toBe(true);
    expect(takeover).toMatchObject({
      kind: "takeover",
      text: "Solve the captcha",
      risk: null,
      link: `/computer/live?c=${ids.computer}&takeover=${ids.takeover}`,
    });
    // Do it is an action: the row opens where suggestions are listed.
    expect(suggestion).toMatchObject({ kind: "suggestion", urgent: true, link: "/inbox?tab=0" });
  });

  it("shows each bot's state, step in general words and last message as plain text", async () => {
    const g = await build();
    expect(g.bots.map((b) => b.name).slice(0, 3)).toEqual(["Ada", "Bo", "Bot 2"]);
    const ada = g.bots[0];
    expect(ada).toMatchObject({
      id: ids.ada,
      status: "working",
      step: "Searching the web",
      last_text: "Found three flights under $400.",
      link: `/bots/${ids.ada}/chat`,
    });
    expect(ada?.busy_at).toBeTruthy();
    expect(g.bots[1]).toMatchObject({ status: "idle", step: null });
  });

  it("lists the person's live runs in the island's words (D-410)", async () => {
    const g = await build();
    // Ada's chat run waits on two requests: the newest one is shown, with its risk.
    expect(g.runs).toHaveLength(1);
    expect(g.runs[0]).toMatchObject({
      bot_id: ids.ada,
      bot: "Ada",
      bot_avatar: "mascot:winky",
      phase: "needs_ok",
      step: "Reading a web page",
      steps: 1,
      approval_id: ids.approvalNew,
      risk: "low",
      link: `/approvals/${ids.approvalNew}`,
    });
    // Someone else's runs, routines' runs and sub-runs are not the person's live runs.
    const theirs = await build({ userId: ids.other });
    expect(theirs.runs).toEqual([]);
    const priv = await build({ private: true });
    expect(priv.runs[0]).toMatchObject({ phase: "needs_ok", step: "", steps: 1 });
  });

  it("lists what runs next with how often in words", async () => {
    const g = await build();
    expect(g.next.map((r) => r.name)).toEqual([
      "Routine 6",
      "Routine 5",
      "Routine 4",
      "Routine 3",
      "Routine 2",
      "Routine 1",
    ]);
    expect(g.next[0]).toMatchObject({
      every: "Weekdays at 9:00",
      bot: "Bo",
      enabled: true,
      link: `/bots/${ids.bo}/routines`,
    });
  });

  it("lists every routine for pickers, on ones first, without check-ins", async () => {
    const g = await build();
    expect(g.routines.map((r) => r.name)).toEqual([
      ...[0, 1, 2, 3, 4, 5, 6].map((i) => `Routine ${i}`),
      "Morning digest",
      "Paused",
    ]);
    expect(g.routines.at(-1)).toMatchObject({ bot: "Bo", bot_id: ids.bo, enabled: false });
    const priv = await build({ private: true });
    expect(priv.routines).toHaveLength(9);
    expect(priv.routines.every((r) => r.name === "" && r.bot === "Bo")).toBe(true);
  });

  it("carries the latest brief cut short, with when the next one is due", async () => {
    const g = await build();
    expect(g.brief?.bot_id).toBe(ids.ada);
    expect(g.brief?.text?.startsWith("Morning brief You have 3 meetings.")).toBe(true);
    expect(g.brief?.text?.length).toBeLessThanOrEqual(GLANCE_LIMITS.briefChars);
    expect(g.brief?.link).toBe(`/bots/${ids.ada}/chat?c=${ids.briefConv}`);
    const next = new Date(g.brief?.next_at as string);
    expect(next.getTime()).toBeGreaterThan(NOW.getTime());
    expect(next.getUTCHours()).toBe(7);
    expect(next.getUTCMinutes()).toBe(0);
  });

  it("says what bots finished, the newest creations and the board", async () => {
    const g = await build();
    expect(g.lately.map((l) => l.title)).toEqual(["Trip plan", "Morning digest", "Replied"]);
    expect(g.lately[0]?.link).toBe(`/library/${ids.tripCreation}`);
    expect(g.lately[2]?.link).toBe(`/bots/${ids.bo}/chat?c=${ids.conv}`);
    expect(g.recent[0]).toMatchObject({ title: "Trip plan", kind: "document", has_cover: false });
    expect(g.recent.find((c) => c.title === "Made 0")?.has_cover).toBe(true);
    expect(g.recent.find((c) => c.title === "Made 1")?.has_cover).toBe(false);
    expect(g.tasks.counts).toEqual({ todo: 2, in_progress: 1, in_review: 2, blocked: 1 });
    expect(g.tasks.items.map((t) => t.status)).toEqual(["in_review", "in_review", "blocked"]);
    expect(g.tasks.items[0]).toMatchObject({ bot: "Ada", link: "/tasks" });
    expect(g.starters[0]).toEqual({ emoji: "✈️", text: "Idea 1" });
  });

  it("keeps a stable version that moves when the content does", async () => {
    const a = await build();
    const b = await build({ now: new Date(NOW.getTime() + 1000) });
    expect(b.made_at).not.toBe(a.made_at);
    expect(b.version).toBe(a.version);
    await tdb.admin`update public.bots set name = 'Ada Lovelace' where id = ${ids.ada}`;
    const c = await build();
    expect(c.version).not.toBe(a.version);
    await tdb.admin`update public.bots set name = 'Ada' where id = ${ids.ada}`;
  });

  it("when private, keeps counts, names, times and kinds and drops the person's words", async () => {
    const g = await build({ private: true });
    expect(() => Glance.parse(g)).not.toThrow();
    expect(g.flags.private).toBe(true);
    expect(g.needs.count).toBe(7);
    expect(g.needs.items.every((n) => n.text === "")).toBe(true);
    expect(g.needs.items[0]?.kind).toBe("approval");
    expect(g.bots[0]).toMatchObject({
      name: "Ada",
      status: "working",
      step: null,
      last_text: null,
    });
    expect(g.bots[0]?.last_at).toBeTruthy();
    expect(g.next.every((r) => r.name === "" && r.next_at)).toBe(true);
    expect(g.next[0]?.every).toBe("Weekdays at 9:00");
    expect(g.brief).toMatchObject({ text: null, bot: "Ada" });
    expect(g.brief?.at).toBeTruthy();
    expect(g.lately.every((l) => l.title === "")).toBe(true);
    expect(g.recent.every((c) => c.title === "")).toBe(true);
    expect(g.tasks.items.every((t) => t.title === "")).toBe(true);
    expect(g.tasks.counts.in_review).toBe(2);
    expect(g.starters).toEqual([]);
  });

  it("hides the bots' last messages when the person hides reply text", async () => {
    await tdb.admin`update public.profiles set push_prefs = '{"hide_reply_text": true}' where user_id = ${ids.me}`;
    try {
      const g = await build();
      expect(g.flags.hide_reply_text).toBe(true);
      expect(g.bots[0]?.last_text).toBeNull();
      expect(g.bots[0]?.last_at).toBeTruthy();
      // Only the bots' replies: the rest still reads.
      expect(g.needs.items[1]?.text).toBe("Solve the captcha");
    } finally {
      await tdb.admin`update public.profiles set push_prefs = '{}' where user_id = ${ids.me}`;
    }
  });

  it("shows spend with billing off, and the plan's credits with it on", async () => {
    const off = await build();
    expect(off.credits).toMatchObject({
      billing: false,
      unlimited: true,
      plan: null,
      used_share: null,
      left_usd: null,
      daily_cap_usd: null,
    });
    // Billing off counts every row (self-hosted spend on the server's keys).
    expect(off.credits.today_usd).toBe(2.5);
    expect(off.credits.month_usd).toBe(3.5);
    const on = await build({
      credits: async () => ({
        billing: true,
        unlimited: false,
        plan: "Plus",
        left_usd: 4.5,
        daily: { used_usd: 0.5, cap_usd: 5, resets_at: ahead(600) },
      }),
    });
    expect(on.credits).toMatchObject({
      billing: true,
      unlimited: false,
      plan: "Plus",
      left_usd: 4.5,
      today_usd: 0.5,
      month_usd: 1.5,
      daily_cap_usd: 5,
      daily_used_usd: 0.5,
    });
    expect(on.credits.used_share).toBe(0.25);
    expect(on.credits.resets_at).toBeTruthy();
  });

  it("is only the person's: someone else sees their own suggestions, not mine", async () => {
    const g = await build({ userId: ids.other });
    expect(g.needs.items.some((n) => n.text === "Not mine")).toBe(true);
    expect(g.needs.items.some((n) => n.id === ids.urgentSuggestion)).toBe(false);
    // No check-ins of theirs: no brief.
    expect(g.brief).toBeNull();
    expect(g.lately).toEqual([]);
  });
});

describe("words and cuts", () => {
  it("cuts at the limit with an ellipsis, never inside an emoji", () => {
    expect(glanceCut("short", 10)).toBe("short");
    expect(glanceCut("a  b\n c", 10)).toBe("a b c");
    const cut = glanceCut(`${"x".repeat(8)}😀😀`, 10);
    expect(cut.length).toBeLessThanOrEqual(10);
    expect(cut.endsWith("…")).toBe(true);
    expect(/[\ud800-\udbff]…$/.test(cut)).toBe(false);
  });

  it("says schedules the way the app does", () => {
    expect(cronWords("0 9 * * 1-5")).toBe("Weekdays at 9:00");
    expect(cronWords("30 17 * * *")).toBe("Every day at 17:30");
    expect(cronWords("0 */2 * * *")).toBe("Every 2 hours");
    expect(cronWords("15 * * * *")).toBe("Every hour at :15");
    expect(cronWords("*/15 * * * *")).toBe("Every 15 minutes");
    expect(cronWords("0 10 * * 0,6")).toBe("Weekends at 10:00");
    expect(cronWords("0 8 * * 1,4")).toBe("Mondays and Thursdays at 8:00");
    expect(cronWords("0 8 * * sun,mon,wed")).toBe("Mondays, Wednesdays and Sundays at 8:00");
    expect(cronWords("0 6 1 * *")).toBe("Day 1 of every month at 6:00");
    expect(cronWords("@daily")).toBe("Every day at 0:00");
    expect(cronWords("0 9 1 1 *")).toBe("0 9 1 1 *");
  });
});
