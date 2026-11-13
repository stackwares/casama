/**
 * Proactive bots (D-247): plan limits on check-ins, the setup scan's one summary push, pushes in the
 * bot's own words with buttons, timed suggestions, new connections and Composio events starting
 * scans, and the welcome bot checking in by default.
 */
import { createHmac } from "node:crypto";
import { fileURLToPath } from "node:url";
import {
  applyCheckins,
  NotificationService,
  RecordingPushSender,
  sendDueSuggestions,
  startWelcome,
  syncComposioTriggers,
  verifyComposioSignature,
} from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { claimDueRoutines, retimeRoutines } from "../src/worker/routines.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/proactive.json", import.meta.url));
const SECRET = "whsec_test_secret";
const push = new RecordingPushSender();
let h: Harness;
let owner: { id: string; token: string };
let orgId: string;
let botId: string;
let bot2: string;

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
const fireScan = async (bot: string) => {
  await h.tdb
    .admin`update public.routines set next_run_at = now() - interval '1 minute' where bot_id = ${bot} and kind = 'scan'`;
  const ids = await claimDueRoutines(h.handle.db);
  for (const id of ids) await h.deps.workflows.startRun(id);
  await settle();
  return ids;
};
const checkins = (bot: string, scan: number) =>
  h.request(`/v1/bots/${bot}/checkins`, {
    method: "PUT",
    token: owner.token,
    json: { enabled: true, brief_time: "08:00", scan_every_hours: scan, daily_cap_usd: 1 },
  });
const sign = (id: string, ts: string, body: string, secret = SECRET) =>
  `v1,${createHmac("sha256", secret).update(`${id}.${ts}.${body}`).digest("base64")}`;
const hook = (body: string, signature?: string) => {
  const id = "msg_1";
  const ts = String(Math.floor(Date.now() / 1000));
  return h.request("/hooks/composio", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "webhook-id": id,
      "webhook-timestamp": ts,
      "webhook-signature": signature ?? sign(id, ts, body),
    },
    body,
  });
};

beforeAll(async () => {
  h = await startHarness({
    worker: { fixtures: FIXTURES, push },
    env: { COMPOSIO_WEBHOOK_SECRET: SECRET },
  });
  owner = await h.user("proactive@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "P" } }),
    )
  ).id;
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
    }),
  );
  const mk = async (name: string) =>
    (
      await j(
        await h.request("/v1/bots", {
          method: "POST",
          token: owner.token,
          json: {
            org_id: orgId,
            name,
            model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
          },
        }),
      )
    ).id as string;
  botId = await mk("Aide");
  bot2 = await mk("Second");
  // A plan with one bot that checks in, scans every 3 hours at most, and app events allowed.
  await h.tdb.admin`
    update public.entitlements set limits = limits || '{"max_proactive_bots": 1, "min_scan_hours": 3, "event_scans": 1}'::jsonb
    where org_id = ${orgId}`;
  await h.tdb.admin`
    insert into public.devices (user_id, fcm_token, platform) values (${owner.id}, 'tok-ios', 'ios')`;
  await h.tdb.admin`
    insert into public.devices (user_id, fcm_token, platform, data_pushes) values (${owner.id}, 'tok-android', 'android', true)`;
}, 60_000);
afterAll(async () => h?.stop());

describe("proactive bots", () => {
  it("the plan sets how often and how many bots check in", async () => {
    const tooOften = await checkins(botId, 1);
    expect(tooOften.status).toBe(402);
    expect((await j(tooOften)).detail).toContain("every 3 hours");
    expect((await checkins(botId, 3)).status).toBe(200);
    const second = await checkins(bot2, 6);
    expect(second.status).toBe(402);
    expect((await j(second)).code).toBe("plan_limit");
  });

  it("a bot past the plan's number skips its scans (a downgrade keeps the oldest bot)", async () => {
    await applyCheckins(h.handle.db, {
      orgId,
      botId: bot2,
      userId: owner.id,
      enabled: true,
      briefTime: "08:00",
      scanEveryHours: 6,
      dailyCapUsd: 1,
    });
    const ids = await fireScan(bot2);
    expect(ids).toEqual([]);
    await applyCheckins(h.handle.db, {
      orgId,
      botId: bot2,
      userId: owner.id,
      enabled: false,
      briefTime: "08:00",
      scanEveryHours: 6,
      dailyCapUsd: 1,
    });
  });

  it("the first scan after setup sends one summary push instead of one per suggestion", async () => {
    const [r] = await h.tdb.admin<{ ok: boolean }[]>`
      select public.request_checkin_scan(${botId}::uuid, 'setup', interval '0 seconds') as ok`;
    expect(r?.ok).toBe(true);
    push.sent.length = 0;
    expect(await fireScan(botId)).toHaveLength(1);
    const [run] = await h.tdb.admin<{ reason: string; task: string }[]>`
      select budget ->> 'scan_reason' as reason, budget ->> 'task' as task from public.runs
      where routine_id in (select id from public.routines where bot_id = ${botId} and kind = 'scan')
      order by created_at desc limit 1`;
    expect(run?.reason).toBe("setup");
    expect(run?.task).toContain("You're all set.");
    // The summary goes out just after the run finishes, so wait for it rather than racing it.
    let notes: { kind: string; payload: { title: string; body: string } }[] = [];
    for (let i = 0; i < 100 && !notes.length; i++) {
      notes = await h.tdb.admin<{ kind: string; payload: { title: string; body: string } }[]>`
        select kind, payload from public.notifications where user_id = ${owner.id} order by created_at`;
      if (!notes.length) await new Promise((res) => setTimeout(res, 100));
    }
    expect(notes.map((n) => n.kind)).toEqual(["checkin_summary"]);
    expect(notes[0]?.payload).toMatchObject({
      title: "Aide",
      body: "You're all set. Found 1 thing to start on, like booking a ride to the concert tomorrow night.",
    });
    for (let i = 0; i < 50 && !push.sent.length; i++)
      await new Promise((res) => setTimeout(res, 100));
    expect(push.sent.map((p) => p.message.title)).toEqual(["Aide"]);
    const [s] = await h.tdb.admin<{ push_text: string }[]>`
      select push_text from public.suggestions where bot_id = ${botId}`;
    expect(s?.push_text).toBe("Want me to book a ride to the concert tomorrow at 7?");
    // Once per bot.
    const [again] = await h.tdb.admin<{ ok: boolean }[]>`
      select public.request_checkin_scan(${botId}::uuid, 'setup', interval '0 seconds') as ok`;
    expect(again?.ok).toBe(false);
  });

  it("a new connection asks for a scan", async () => {
    await h.tdb.admin`
      insert into public.integrations (org_id, kind, name, config, status)
      values (${orgId}, 'composio', 'apps', '{"managed": true, "toolkits": ["gmail"], "triggers": {"GMAIL_NEW_GMAIL_MESSAGE": "ti_mail"}}'::jsonb, 'ok')`;
    const [ck] = await h.tdb.admin<{ reason: string | null }[]>`
      select scan_reason as reason from public.bot_checkins where bot_id = ${botId}`;
    expect(ck?.reason).toBe("connection");
    await h.tdb
      .admin`update public.bot_checkins set scan_requested_at = null, scan_reason = null where bot_id = ${botId}`;
  });

  it("Composio events are verified and start a scan, at most every 2 hours", async () => {
    const body = JSON.stringify({
      id: "msg_1",
      type: "composio.trigger.message",
      metadata: { trigger_slug: "GMAIL_NEW_GMAIL_MESSAGE", trigger_id: "ti_mail", user_id: orgId },
      data: { subject: "Your flight on Sunday" },
    });
    expect((await hook(body, sign("msg_1", "1", body, "wrong"))).status).toBe(401);
    await h.tdb
      .admin`update public.routines set next_run_at = now() + interval '3 hours' where bot_id = ${botId} and kind = 'scan'`;
    const res = await hook(body);
    expect(res.status).toBe(200);
    expect((await j(res)).scans).toBe(1);
    const [rt] = await h.tdb.admin<{ soon: boolean }[]>`
      select next_run_at between now() + interval '110 minutes' and now() + interval '121 minutes' as soon from public.routines where bot_id = ${botId} and kind = 'scan'`;
    expect(rt?.soon).toBe(true); // the setup scan just ran
    const [ck] = await h.tdb.admin<{ note: string | null }[]>`
      select scan_note as note from public.bot_checkins where bot_id = ${botId}`;
    expect(ck?.note).toBe("New email: Your flight on Sunday"); // handed to the scan
    expect(
      verifyComposioSignature(
        SECRET,
        { id: "a", timestamp: "1", signature: sign("a", "1", "x") },
        "x",
      ),
    ).toBe(false); // too old
  });

  it("suggestion pushes come from the bot, in its words, with buttons; timed ones wait", async () => {
    push.sent.length = 0;
    expect(await fireScan(botId)).toHaveLength(1);
    const now = push.sent.filter((p) => p.message.data?.kind === "suggestion");
    expect(now).toHaveLength(2); // one suggestion, to the iOS and the Android device
    const ios = now.find((p) => p.tokens.includes("tok-ios"));
    const android = now.find((p) => p.tokens.includes("tok-android"));
    expect(ios?.message).toMatchObject({
      title: "Aide",
      body: "Want me to make a shareable Page for your weekend with the show time, ride plan, lodging and Sunday flight?",
      category: "SUGGESTION",
    });
    expect(ios?.message.dataOnly).toBeUndefined();
    expect(ios?.message.data?.suggestion_id).toBeTruthy();
    expect(android?.message.dataOnly).toBe(true);

    const [timed] = await h.tdb.admin<{ id: string; notified: boolean }[]>`
      select id, notified_at is not null as notified from public.suggestions where title = 'Leave for the airport'`;
    expect(timed?.notified).toBe(false);
    await h.tdb
      .admin`update public.suggestions set notify_at = now() - interval '1 minute' where id = ${timed!.id}`;
    push.sent.length = 0;
    expect(await sendDueSuggestions(h.handle.db, new NotificationService(h.handle.db, push))).toBe(
      1,
    );
    expect(push.sent[0]?.message.body).toBe(
      "Your flight's in 3 hours. Want me to book a ride now?",
    );
    expect(await sendDueSuggestions(h.handle.db, new NotificationService(h.handle.db, push))).toBe(
      0,
    );
  });

  it("a new event on the phone's calendar asks for a scan", async () => {
    await h.tdb
      .admin`update public.routines set last_run_at = now() - interval '2 hours' where bot_id = ${botId} and kind = 'scan'`;
    await h.tdb
      .admin`update public.bot_checkins set scan_requested_at = null, scan_reason = null where bot_id = ${botId}`;
    await h.request("/v1/device-sources/phone-key-0001", {
      method: "PUT",
      token: owner.token,
      json: { name: "Phone", platform: "ios", kinds: { calendar: {} } },
    });
    const t = new Date(Date.now() + 86_400_000);
    const up = await h.request("/v1/device-sources/phone-key-0001/readings", {
      method: "POST",
      token: owner.token,
      json: {
        readings: [
          {
            kind: "calendar",
            period_start: t.toISOString(),
            period_end: new Date(t.getTime() + 3600_000).toISOString(),
            external_id: "evt-1",
            summary: { events: [{ title: "Concert", start: t.toISOString() }] },
          },
        ],
      },
    });
    expect(up.status).toBe(200);
    const [ck] = await h.tdb.admin<{ reason: string | null; note: string | null }[]>`
      select scan_reason as reason, scan_note as note from public.bot_checkins where bot_id = ${botId}`;
    expect(ck?.reason).toBe("event");
    expect(ck?.note).toContain("Phone calendar: Concert at ");
    await h.tdb
      .admin`update public.bot_checkins set scan_requested_at = null, scan_reason = null, scan_note = null where bot_id = ${botId}`;
  });

  it("saves cost: newsletters, no-reply mail and far-off calendar changes don't scan; a few a day", async () => {
    await h.tdb
      .admin`update public.routines set last_run_at = now() - interval '3 hours' where bot_id = ${botId} and kind = 'scan'`;
    const event = (slug: string, data: Record<string, unknown>) =>
      JSON.stringify({
        id: "msg_1",
        type: "composio.trigger.message",
        metadata: { trigger_slug: slug, trigger_id: "ti_mail", user_id: orgId },
        data,
      });
    const scans = async (body: string) => (await j(await hook(body))).scans;
    const mail = "GMAIL_NEW_GMAIL_MESSAGE";
    expect(
      await scans(
        event(mail, {
          sender: "Shop <deals@shop.example>",
          label_ids: ["INBOX", "CATEGORY_PROMOTIONS"],
        }),
      ),
    ).toBe(0);
    expect(
      await scans(
        event(mail, { sender: "GitHub <notifications@github.com>", subject: "CI passed" }),
      ),
    ).toBe(0);
    expect(
      await scans(event(mail, { sender: "no-reply@bank.example", subject: "Statement" })),
    ).toBe(0);
    const far = new Date(Date.now() + 5 * 86_400_000).toISOString();
    expect(
      await scans(
        event("GOOGLECALENDAR_GOOGLE_CALENDAR_EVENT_CREATED_TRIGGER", {
          summary: "Dentist",
          start: { dateTime: far },
        }),
      ),
    ).toBe(0);
    let [ck] = await h.tdb.admin<{ reason: string | null }[]>`
      select scan_reason as reason from public.bot_checkins where bot_id = ${botId}`;
    expect(ck?.reason).toBeNull();
    // Six event scans in the last day: the seventh waits for the schedule.
    const [rt] = await h.tdb.admin<{ id: string }[]>`
      select id from public.routines where bot_id = ${botId} and kind = 'scan'`;
    for (let i = 0; i < 6; i++)
      await h.tdb.admin`
        insert into public.runs (org_id, bot_id, trigger, routine_id, status, budget)
        values (${orgId}, ${botId}, 'schedule', ${rt!.id}, 'completed', '{"scan_reason": "event"}'::jsonb)`;
    expect(
      await scans(event(mail, { sender: "Ana Ruiz <ana@example.com>", subject: "Q3 invoice" })),
    ).toBe(0);
    await h.tdb.admin`
      delete from public.runs where bot_id = ${botId} and budget ->> 'scan_reason' = 'event' and budget ->> 'task' is null`;
    expect(
      await scans(event(mail, { sender: "Ana Ruiz <ana@example.com>", subject: "Q3 invoice" })),
    ).toBe(1);
    [ck] = await h.tdb.admin<{ reason: string | null }[]>`
      select scan_reason as reason from public.bot_checkins where bot_id = ${botId}`;
    expect(ck?.reason).toBe("event");
    await h.tdb
      .admin`update public.bot_checkins set scan_requested_at = null, scan_reason = null, scan_note = null where bot_id = ${botId}`;
  });

  it("saves cost: no scans in quiet hours, slower when idle, none after 30 days away", async () => {
    const ids = async () => {
      await h.tdb
        .admin`update public.routines set last_run_at = now() - interval '5 hours' where bot_id = ${botId} and kind = 'scan'`;
      return fireScan(botId);
    };
    // Quiet all day (00:00 to 23:59).
    await h.tdb.admin`
      update public.profiles set timezone = 'UTC', quiet_hours = '{"enabled": true, "start": "00:00", "end": "23:59"}'::jsonb
      where user_id = ${owner.id}`;
    expect(await ids()).toEqual([]);
    await h.tdb.admin`update public.profiles set quiet_hours = null where user_id = ${owner.id}`;
    // Idle 10 days: one scan a day, so 5 hours after the last is too soon.
    await h.tdb
      .admin`update public.devices set last_seen_at = now() - interval '10 days' where user_id = ${owner.id}`;
    await h.tdb.admin`update public.notifications set read_at = null where user_id = ${owner.id}`;
    expect(await ids()).toEqual([]);
    // Away 40 days: nothing at all.
    await h.tdb
      .admin`update public.devices set last_seen_at = now() - interval '40 days' where user_id = ${owner.id}`;
    await h.tdb
      .admin`update public.routines set last_run_at = now() - interval '2 days' where bot_id = ${botId} and kind = 'scan'`;
    expect(await fireScan(botId)).toEqual([]);
    // Back again: scans resume.
    await h.tdb.admin`update public.devices set last_seen_at = now() where user_id = ${owner.id}`;
    expect(await ids()).toHaveLength(1);
  });

  it("removes Composio triggers once nobody in the workspace checks in", async () => {
    const calls: string[] = [];
    const fake = (async (url: string, init?: RequestInit) => {
      calls.push(`${init?.method ?? "GET"} ${url}`);
      return new Response("{}", { status: 200 });
    }) as unknown as typeof fetch;
    const [i] = await h.tdb.admin<{ id: string }[]>`
      select id from public.integrations where org_id = ${orgId} and kind = 'composio'`;
    await h.tdb.admin`
      update public.integrations set vault_secret_id = vault.create_secret('ck_test', ${`composio ${i!.id}`}) where id = ${i!.id}`;
    await h.tdb.admin`update public.bot_checkins set enabled = false where org_id = ${orgId}`;
    await syncComposioTriggers(h.handle.db, fake);
    expect(calls).toEqual([
      "DELETE https://backend.composio.dev/api/v3/trigger_instances/manage/ti_mail",
    ]);
    const [cfg] = await h.tdb.admin<{ triggers: Record<string, string> }[]>`
      select config -> 'triggers' as triggers from public.integrations where id = ${i!.id}`;
    expect(cfg?.triggers).toEqual({});
    await h.tdb.admin`update public.bot_checkins set enabled = true where bot_id = ${botId}`;
  });

  it("routines follow the person's timezone (D-250)", async () => {
    await h.tdb
      .admin`update public.profiles set timezone = 'Asia/Manila' where user_id = ${owner.id}`;
    expect(await retimeRoutines(h.handle.db)).toBeGreaterThanOrEqual(2);
    const rows = await h.tdb.admin<
      { kind: string; timezone: string; local: string; pending: boolean }[]
    >`
      select kind, timezone, to_char(next_run_at at time zone 'Asia/Manila', 'HH24:MI') as local, retime_pending as pending
      from public.routines where bot_id = ${botId} and kind in ('brief', 'scan') order by kind`;
    expect(rows[0]).toMatchObject({
      kind: "brief",
      timezone: "Asia/Manila",
      local: "08:00",
      pending: false,
    });
    expect(rows[1]).toMatchObject({ kind: "scan", timezone: "Asia/Manila", pending: false });
    await expect(
      h.tdb.admin`update public.profiles set timezone = 'Mars/Olympus' where user_id = ${owner.id}`,
    ).rejects.toThrow(/Unknown timezone/);
  });

  it("the welcome bot checks in by default", async () => {
    const other = await h.user("proactive-welcome@example.com");
    const org = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: other.token, json: { name: "W" } }),
      )
    ).id;
    const w = await startWelcome(h.handle.db, {
      orgId: org,
      userId: other.id,
      firstName: "Sam",
      botName: "Pip",
    });
    const [ck] = await h.tdb.admin<{ enabled: boolean; scan_every_hours: number }[]>`
      select enabled, scan_every_hours from public.bot_checkins where bot_id = ${w.botId}`;
    expect(ck).toEqual({ enabled: true, scan_every_hours: 3 });
  });
});
