import { runCompletedMilestones } from "@casama/agent";
import { createDb } from "@casama/db";
import { createAuthUser, startTestDatabase } from "@casama/db/testing";
import type { CaptureOptions, ProductAnalytics } from "@casama/observability";
import { expect, it } from "vitest";
import { sweepSignups } from "../src/services/analytics-signups.ts";

class Recorder implements ProductAnalytics {
  readonly enabled: boolean;
  constructor(enabled = true) {
    this.enabled = enabled;
  }
  events: CaptureOptions[] = [];
  capture(o: CaptureOptions) {
    this.events.push(o);
  }
  async flush() {}
  async close() {}
}

it("reports each new sign-up once, never old accounts, opt-outs, or anything when analytics is off", async () => {
  const tdb = await startTestDatabase();
  const h = createDb(tdb.url, { max: 2 });
  try {
    const a = await createAuthUser(tdb.admin, "new@example.com");
    const b = await createAuthUser(tdb.admin, "optout@example.com");
    await tdb.admin`update public.profiles set analytics_opt_out = true where user_id = ${b.id}`;

    // Analytics off: nothing sent, nobody marked.
    const off = new Recorder(false);
    expect(await sweepSignups(h.db, off)).toBe(0);
    expect(off.events).toHaveLength(0);

    const rec = new Recorder();
    expect(await sweepSignups(h.db, rec)).toBe(1);
    expect(rec.events).toHaveLength(1);
    expect(rec.events[0]).toMatchObject({ event: "signed_up", distinctId: a.id });
    expect(rec.events[0]?.properties).toEqual({ method: expect.any(String) });
    expect(JSON.stringify(rec.events[0] ?? {})).not.toContain("example.com");

    // Second pass: already reported.
    expect(await sweepSignups(h.db, new Recorder())).toBe(0);
  } finally {
    await h.close();
    await tdb.stop();
  }
});

it("first completed interactive run is first_value, once, and automation never counts", async () => {
  const tdb = await startTestDatabase();
  const h = createDb(tdb.url, { max: 2 });
  try {
    const a = await createAuthUser(tdb.admin, "a@example.com");
    const b = await createAuthUser(tdb.admin, "b@example.com");
    await tdb.admin`update public.profiles set analytics_opt_out = true where user_id = ${b.id}`;
    const orgId = "00000000-0000-0000-0000-000000000001";
    const rec = new Recorder();

    await runCompletedMilestones(h.db, { userId: a.id, orgId, trigger: "routine" }, rec);
    expect(rec.events).toHaveLength(0);

    await runCompletedMilestones(h.db, { userId: a.id, orgId, trigger: "chat" }, rec);
    expect(rec.events.map((e) => e.event)).toEqual(["milestone_reached", "first_value"]);
    expect(rec.events[1]?.properties).toMatchObject({ kind: "chat" });
    expect(rec.events[1]?.setOnce).toMatchObject({ first_value_kind: "chat" });

    await runCompletedMilestones(h.db, { userId: a.id, orgId, trigger: "chat" }, rec);
    expect(rec.events).toHaveLength(2); // once per person

    // Opted out: the milestone is recorded in our own database, nothing is sent.
    const rec2 = new Recorder();
    await runCompletedMilestones(h.db, { userId: b.id, orgId, trigger: "chat" }, rec2);
    expect(rec2.events).toHaveLength(0);
    const rows =
      await tdb.admin`select milestone from public.analytics_milestones where user_id = ${b.id}`;
    expect(rows.length).toBe(2);
  } finally {
    await h.close();
    await tdb.stop();
  }
});
