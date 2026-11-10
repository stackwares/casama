/** Attention rules (D-153): busy people get non-urgent messages in their next brief, with a "why". */
import {
  NotificationService,
  RecordingPushSender,
  registerSuggestionTools,
  ToolRegistry,
} from "@kasama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { claimDueRoutines } from "../src/worker/routines.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const KEY = "attention-phone-1";
let h: Harness;
let owner: { id: string; token: string };
let other: { id: string; token: string };
let orgId: string;
let botId: string;
let push: RecordingPushSender;
let svc: NotificationService;

const meetingNow = (on: boolean) => {
  const now = Date.now();
  const date = new Date(now).toISOString().slice(0, 10);
  return h.request(`/v1/device-sources/${KEY}/readings`, {
    method: "POST",
    token: owner.token,
    json: {
      readings: [
        {
          kind: "calendar",
          period_start: `${date}T00:00:00Z`,
          period_end: `${date}T23:59:59Z`,
          external_id: `cal-${date}`,
          summary: {
            events: on
              ? [
                  {
                    title: "Design review",
                    start: new Date(now - 10 * 60_000).toISOString(),
                    end: new Date(now + 20 * 60_000).toISOString(),
                  },
                ]
              : [],
          },
        },
      ],
    },
  });
};
const notify = (title: string, urgency: "low" | "normal" | "urgent", bot = botId) =>
  svc.notify(
    owner.id,
    orgId,
    "routine_result",
    { title, body: "b", link: "/inbox", bot_id: bot },
    { urgency, why: { rule: `Routine "${title}"`, data: ["calendar"] } },
  );
const row = async (id: string | undefined) =>
  (
    await h.tdb.admin<
      {
        push_status: string;
        held_reason: string | null;
        urgency: string;
        payload: { why?: unknown };
      }[]
    >`select push_status, held_reason, urgency, payload from public.notifications where id = ${id!}`
  )[0]!;

beforeAll(async () => {
  h = await startHarness({});
  owner = await h.user("attn-owner@example.com");
  other = await h.user("attn-other@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", {
        method: "POST",
        token: owner.token,
        json: { name: "Attention" },
      }),
    )
  ).id;
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Nudge" },
      }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.devices (user_id, platform, fcm_token) values (${owner.id}, 'ios', 'tok-1')`;
  await h.request(`/v1/device-sources/${KEY}`, {
    method: "PUT",
    token: owner.token,
    json: { name: "Phone", platform: "ios", kinds: { calendar: {} } },
  });
  push = new RecordingPushSender();
  svc = new NotificationService(h.deps.db, push);
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

describe("attention rules", () => {
  it("during a calendar meeting a non-urgent message waits; an urgent one still pushes; each says why", async () => {
    await meetingNow(true);
    const held = await notify("Weekly numbers", "normal");
    expect(await row(held)).toMatchObject({
      push_status: "held",
      held_reason: "meeting",
      urgency: "normal",
      payload: { why: { rule: 'Routine "Weekly numbers"', data: ["calendar"] } },
    });
    expect(push.sent).toHaveLength(0);
    const urgent = await notify("Server down", "urgent");
    expect((await row(urgent)).push_status).toBe("sent");
    expect(push.sent).toHaveLength(1);
    // Low urgency never pushes.
    expect((await row(await notify("Nice to know", "low"))).held_reason).toBe("low_urgency");
    await meetingNow(false);
  });

  it("Focus mode holds them until it's turned off", async () => {
    const ev = (id: string, type: string) =>
      h.request(`/v1/device-sources/${KEY}/events`, {
        method: "POST",
        token: owner.token,
        json: { events: [{ id, type, at: new Date().toISOString() }] },
      });
    await ev("f-on", "focus_on");
    expect((await row(await notify("During focus", "normal"))).held_reason).toBe("focus");
    await ev("f-off", "focus_off");
    expect((await row(await notify("After focus", "normal"))).push_status).toBe("sent");
  });

  it("five non-urgent pushes per bot per day, then the brief", async () => {
    const other = (
      await j(
        await h.request("/v1/bots", {
          method: "POST",
          token: owner.token,
          json: { org_id: orgId, name: "Chatty" },
        }),
      )
    ).id;
    for (let i = 0; i < 5; i++)
      expect((await row(await notify(`Update ${i}`, "normal", other))).push_status).toBe("sent");
    expect((await row(await notify("Update 6", "normal", other))).held_reason).toBe("daily_cap");
    // Another bot has its own count.
    expect((await row(await notify("From Nudge", "normal"))).push_status).toBe("sent");
  });

  it("a non-urgent suggestion during a meeting arrives in the next brief instead of as a push", async () => {
    await meetingNow(true);
    const registry = new ToolRegistry();
    registerSuggestionTools(registry, { db: h.deps.db, notifications: svc });
    const [run] = await h.tdb.admin<
      { id: string }[]
    >`insert into public.runs (org_id, bot_id, created_by, trigger) values (${orgId}, ${botId}, ${owner.id}, 'routine') returning id`;
    const before = push.sent.length;
    await registry
      .get("suggestions.add")!
      .execute(
        { title: "Book the dentist", urgency: "normal" },
        { runId: run!.id, botId, orgId, output: async () => {}, emit: async () => {} },
      );
    expect(push.sent.length).toBe(before);
    const [n] = await h.tdb.admin<
      { push_status: string; payload: { why: { rule: string } } }[]
    >`select push_status, payload from public.notifications where kind = 'suggestion' order by created_at desc limit 1`;
    expect(n?.push_status).toBe("held");
    expect(n?.payload.why.rule).toContain("suggestion from Nudge");
    await meetingNow(false);

    await h.request(`/v1/bots/${botId}/checkins`, {
      method: "PUT",
      token: owner.token,
      json: { enabled: true, brief_time: "08:00", scan_every_hours: 24, daily_cap_usd: 1 },
    });
    const [brief] = await h.tdb.admin<
      { id: string; next_run_at: Date }[]
    >`select id, next_run_at from public.routines where bot_id = ${botId} and kind = 'brief'`;
    await claimDueRoutines(h.deps.db, new Date(new Date(brief!.next_run_at).getTime() + 1000));
    const [{ id: runId } = { id: "" }] = await h.tdb.admin<
      { id: string }[]
    >`select id from public.runs where routine_id = ${brief!.id}`;
    const [m] = await h.tdb.admin<
      { c: string }[]
    >`select content::text as c from public.messages where run_id = ${runId} and role = 'user'`;
    expect(m?.c).toContain("Book the dentist");
    expect(m?.c).toContain("you were in a meeting");
    expect(m?.c).toContain("Weekly numbers");
    expect(
      await h.tdb
        .admin`select 1 from public.notifications where user_id = ${owner.id} and push_status = 'held'`,
    ).toHaveLength(0);
  });

  it('"Less like this" becomes a memory for that bot; only the person can say it', async () => {
    const id = await notify("Daily trivia", "normal");
    expect(
      (
        await h.request(`/v1/notifications/${id}/less-like-this`, {
          method: "POST",
          token: other.token,
        })
      ).status,
    ).toBe(404);
    expect(
      await j(
        await h.request(`/v1/notifications/${id}/less-like-this`, {
          method: "POST",
          token: owner.token,
        }),
      ),
    ).toEqual({ ok: true });
    const mems = await h.tdb.admin<
      { kind: string; pinned: boolean }[]
    >`select kind, pinned from public.memories where bot_id = ${botId}`;
    expect(mems).toMatchObject([{ kind: "preference", pinned: false }]);
  });
});
