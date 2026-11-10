/** Device triggers (D-151): routines start from the person's own device events; no GPS trail. */
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { checkLeaveNow } from "../src/worker/device-triggers.ts";
import { claimDueRoutines } from "../src/worker/routines.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/device-triggers.json", import.meta.url));
const KEY = "trigger-phone-01";
let h: Harness;
let owner: { id: string; token: string };
let mate: { id: string; token: string };
let orgId: string;
let botId: string;

const waitFor = async <T>(
  fn: () => Promise<T | undefined | null | false>,
  what: string,
  ms = 30_000,
): Promise<T> => {
  const until = Date.now() + ms;
  for (;;) {
    const v = await fn();
    if (v) return v;
    if (Date.now() > until) throw new Error(`timed out waiting for ${what}`);
    await new Promise((r) => setTimeout(r, 100));
  }
};
const routine = async (user: { token: string }, name: string, device: Record<string, unknown>) =>
  j(
    await h.request("/v1/routines", {
      method: "POST",
      token: user.token,
      json: { bot_id: botId, name, instructions: `Run ${name}.`, trigger: "device", device },
    }),
  );
const runsOf = (routineId: string) =>
  h.tdb.admin<
    { id: string; trigger: string; status: string }[]
  >`select id, trigger, status from public.runs where routine_id = ${routineId} order by created_at`;
const firstMessage = async (runId: string) =>
  (
    await h.tdb.admin<
      { c: string }[]
    >`select content::text as c from public.messages where run_id = ${runId} and role = 'user' order by created_at limit 1`
  )[0]?.c ?? "";
const events = (evs: unknown[]) =>
  h.request(`/v1/device-sources/${KEY}/events`, {
    method: "POST",
    token: owner.token,
    json: { events: evs },
  });

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES, deviceWaitMs: { read: 200 } } });
  owner = await h.user("trig-owner@example.com");
  mate = await h.user("trig-mate@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", {
        method: "POST",
        token: owner.token,
        json: { name: "Triggers" },
      }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${mate.id}, 'member')`;
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-triggers" },
    }),
  );
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Buddy",
          model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
        },
      }),
    )
  ).id;
  await h.request(`/v1/device-sources/${KEY}`, {
    method: "PUT",
    token: owner.token,
    json: {
      name: "Phone",
      platform: "ios",
      kinds: {
        places: {},
        notifications: { apps: ["com.mybank.app", "com.chat.app"] },
        health: {},
        calendar: {},
      },
    },
  });
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

describe("device triggers", () => {
  it("named places: owner only, up to 20", async () => {
    const home = await j(
      await h.request("/v1/device-places", {
        method: "POST",
        token: owner.token,
        json: { name: "Home", latitude: 40.7, longitude: -74.0 },
      }),
    );
    expect(home).toMatchObject({ name: "Home", radius_m: 150 });
    // Same name updates it.
    expect(
      (
        await j(
          await h.request("/v1/device-places", {
            method: "POST",
            token: owner.token,
            json: { name: "home", latitude: 40.71, longitude: -74.01, radius_m: 200 },
          }),
        )
      ).id,
    ).toBe(home.id);
    expect(
      (await j(await h.request("/v1/device-places", { token: mate.token }))).items,
    ).toHaveLength(0);
    expect(
      (await h.request(`/v1/device-places/${home.id}`, { method: "DELETE", token: mate.token }))
        .status,
    ).toBe(404);
    for (let i = 0; i < 19; i++)
      await h.request("/v1/device-places", {
        method: "POST",
        token: owner.token,
        json: { name: `P${i}`, latitude: 1, longitude: 1 },
      });
    expect(
      (
        await h.request("/v1/device-places", {
          method: "POST",
          token: owner.token,
          json: { name: "One too many", latitude: 1, longitude: 1 },
        })
      ).status,
    ).toBe(400);
  });

  it("arriving at Home starts the routine at once, once; the visit is kept as times only", async () => {
    const mine = await routine(owner, "Home lights", { event: "arrive", place: "Home" });
    const work = await routine(owner, "At work", { event: "arrive", place: "Work" });
    // A teammate's routine never fires on the owner's events.
    const theirs = await routine(mate, "Their home", { event: "arrive", place: "Home" });
    expect(mine.device).toEqual({ event: "arrive", place: "Home" });
    expect(
      (
        await h.request("/v1/routines", {
          method: "POST",
          token: owner.token,
          json: {
            bot_id: botId,
            name: "x",
            instructions: "x",
            trigger: "device",
            device: { event: "arrive" },
          },
        })
      ).status,
    ).toBe(400);

    const at = new Date().toISOString();
    const res = await j(await events([{ id: "e1", type: "arrive", at, place: "Home" }]));
    expect(res).toEqual({ accepted: 1, runs: 1 });
    const [run] = await runsOf(mine.id);
    expect(run?.trigger).toBe("device");
    expect(await firstMessage(run!.id)).toContain("arrived at Home");
    await waitFor(async () => (await runsOf(mine.id))[0]?.status === "completed", "run");
    expect(await runsOf(work.id)).toHaveLength(0);
    expect(await runsOf(theirs.id)).toHaveLength(0);
    // A retried upload doesn't start it again.
    expect((await j(await events([{ id: "e1", type: "arrive", at, place: "Home" }]))).runs).toBe(0);

    await events([
      { id: "e2", type: "leave", at: new Date(Date.now() + 60_000).toISOString(), place: "Home" },
    ]);
    const visits = await j(
      await h.request("/v1/device-readings?kind=places", { token: owner.token }),
    );
    expect(visits.items).toHaveLength(1);
    expect(visits.items[0].summary).toMatchObject({
      place: "Home",
      arrived_at: expect.any(String),
      left_at: expect.any(String),
    });
    expect(JSON.stringify(visits.items[0].summary)).not.toMatch(/lat|lng|longitude|latitude/);
  });

  it("notifications from a watched app, with one-time codes masked", async () => {
    const r = await routine(owner, "Bank alerts", { event: "notification", app: "bank" });
    await events([
      {
        id: "n1",
        type: "notification",
        at: new Date().toISOString(),
        app: "com.mybank.app",
        title: "Sign-in code",
        text: "Your code is 482913. Don't share it.",
      },
      {
        id: "n2",
        type: "notification",
        at: new Date().toISOString(),
        app: "com.chat.app",
        title: "Hi",
        text: "lunch?",
      },
    ]);
    const runs = await runsOf(r.id);
    expect(runs).toHaveLength(1);
    const text = await firstMessage(runs[0]!.id);
    expect(text).toContain("Sign-in code");
    expect(text).not.toContain("482913");
    const stored = await j(
      await h.request("/v1/device-readings?kind=notifications", { token: owner.token }),
    );
    expect(JSON.stringify(stored.items)).not.toContain("482913");
    // Apps the person didn't pick are dropped entirely.
    await events([
      {
        id: "n3",
        type: "notification",
        at: new Date().toISOString(),
        app: "com.mybank.other",
        title: "Bank promo",
        text: "x",
      },
    ]);
    expect(
      (await j(await h.request("/v1/device-readings?kind=notifications", { token: owner.token })))
        .items,
    ).toHaveLength(2);
  });

  it("waking up (last night's sleep ending today) brings the morning brief forward, which cites the sleep", async () => {
    await h.request(`/v1/bots/${botId}/checkins`, {
      method: "PUT",
      token: owner.token,
      json: { enabled: true, brief_time: "08:00", scan_every_hours: 24, daily_cap_usd: 1 },
    });
    const [brief] = await h.tdb.admin<
      { id: string; next_run_at: Date }[]
    >`select id, next_run_at from public.routines where bot_id = ${botId} and kind = 'brief'`;
    const wake = await routine(owner, "Morning stretch", { event: "wake" });
    await h.request("/v1/device-grants", {
      method: "PUT",
      token: owner.token,
      json: { bot_id: botId, kind: "health", allowed: true },
    });
    const today = new Date();
    const date = `${today.getUTCFullYear()}-${String(today.getUTCMonth() + 1).padStart(2, "0")}-${String(today.getUTCDate()).padStart(2, "0")}`;
    const up = (sleepEnd: string) =>
      h.request(`/v1/device-sources/${KEY}/readings`, {
        method: "POST",
        token: owner.token,
        json: {
          readings: [
            {
              kind: "health",
              period_start: `${date}T00:00:00Z`,
              period_end: `${date}T23:59:59Z`,
              external_id: `health-${date}`,
              summary: { type: "day", date, sleep: { minutes: 300, end: sleepEnd } },
            },
          ],
        },
      });
    expect((await up("06:40")).status).toBe(200);
    const briefRuns = await waitFor(async () => {
      const r = await runsOf(brief!.id);
      return r.length ? r : null;
    }, "brief run");
    expect(await firstMessage(briefRuns[0]!.id)).toContain("woke up");
    expect(await runsOf(wake.id)).toHaveLength(1);
    await waitFor(async () => (await runsOf(brief!.id))[0]?.status === "completed", "brief");
    const [reply] = await h.tdb.admin<
      { c: string }[]
    >`select content::text as c from public.messages where run_id = ${briefRuns[0]!.id} and role = 'assistant' order by created_at desc limit 1`;
    expect(reply?.c).toContain("slept 5 hours");
    // Another upload the same morning: no second brief or wake routine.
    await up("06:45");
    expect(await runsOf(brief!.id)).toHaveLength(1);
    expect(await runsOf(wake.id)).toHaveLength(1);
    // And the scheduled 08:00 brief skips today.
    await claimDueRoutines(h.deps.db, new Date(new Date(brief!.next_run_at).getTime() + 1000));
    expect(await runsOf(brief!.id)).toHaveLength(1);
  });

  it("leave now: where the person is now (cleared after use) plus travel time on the workspace's maps key", async () => {
    const r = await routine(owner, "Leave reminder", { event: "leave_now", minutes_before: 5 });
    const start = new Date(Date.now() + 40 * 60_000);
    const date = start.toISOString().slice(0, 10);
    await h.request(`/v1/device-sources/${KEY}/readings`, {
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
              events: [{ title: "Dentist", start: start.toISOString(), location: "12 Main St" }],
            },
          },
        ],
      },
    });
    const calls: string[] = [];
    const fakeMaps = (async (u: URL | string) => {
      calls.push(String(u));
      return new Response(
        JSON.stringify({
          rows: [
            {
              elements: [
                { status: "OK", duration: { value: 1500 }, duration_in_traffic: { value: 1800 } },
              ],
            },
          ],
        }),
        { status: 200 },
      );
    }) as typeof fetch;
    const deps = (now: Date) => ({
      fetch: fakeMaps,
      mapsKey: async () => ({ provider: "google_maps" as const, key: "maps-key" }),
      now: () => now,
    });
    // First pass asks the phone where it is.
    expect(await checkLeaveNow(h.deps.db, deps(new Date()))).toEqual([]);
    const req = (
      await j(await h.request(`/v1/device-sources/${KEY}/requests`, { token: owner.token }))
    ).items.find((x: { action: string }) => x.action === "locate");
    expect(req).toBeTruthy();
    await h.request(`/v1/device-requests/${req.id}/result`, {
      method: "POST",
      token: owner.token,
      json: { ok: true, result: { lat: 40.7, lng: -74 } },
    });
    // 30 min travel (with traffic) + 5 min buffer: not yet at 40 min before, yes at 34.
    expect(await checkLeaveNow(h.deps.db, deps(new Date(start.getTime() - 40 * 60_000)))).toEqual(
      [],
    );
    const fired = await checkLeaveNow(h.deps.db, deps(new Date(start.getTime() - 34 * 60_000)));
    expect(fired).toHaveLength(1);
    expect(calls[0]).toContain("origins=40.7%2C-74");
    expect(calls[0]).toContain("destinations=12+Main+St");
    expect(await firstMessage(fired[0]!)).toContain("Travel takes about 30 minutes");
    expect((await runsOf(r.id))[0]?.id).toBe(fired[0]);
    // The location is gone, and the same event doesn't fire twice.
    const [loc] = await h.tdb.admin<
      { result: unknown }[]
    >`select result from public.device_requests where id = ${req.id}`;
    expect(loc?.result).toBeNull();
    expect(await checkLeaveNow(h.deps.db, deps(new Date(start.getTime() - 30 * 60_000)))).toEqual(
      [],
    );
  });
});
