import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import {
  capacityReport,
  dueAlerts,
  forecastWeeks,
  recordCapacityFull,
  recordSample,
  sampleHost,
} from "../src/services/capacity.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

describe("forecastWeeks", () => {
  it("projects daily peaks to the budget", () => {
    // +100 MB a day from 1,000: at day 13 the trend is 2,300; 9,000 is 67 days away.
    const peaks = Array.from({ length: 14 }, (_, i) => 1000 + i * 100);
    expect(forecastWeeks(peaks, 9000)).toBeCloseTo(67 / 7, 1);
  });
  it("is null without a budget, enough days or growth, and 0 when already full", () => {
    expect(forecastWeeks([1, 2, 3, 4, 5, 6, 7], 0)).toBeNull();
    expect(forecastWeeks([1, 2, 3], 9000)).toBeNull();
    expect(forecastWeeks(Array(10).fill(4000), 9000)).toBeNull();
    expect(forecastWeeks(Array(10).fill(9500), 9000)).toBe(0);
  });
});

describe("server capacity (D-252)", () => {
  let h: Harness;
  let owner: { id: string; token: string };
  let member: { id: string; token: string };
  const host = (avail: number, disk = 40) => ({
    mem_total_mb: 11960,
    mem_available_mb: avail,
    load1: 0.5,
    cpus: 6,
    disk_used_pct: disk,
  });
  /** A sample `minutesAgo` in the past with this much computer memory in use. */
  const sampleAt = (minutesAgo: number, computersMb: number, avail = 6000, disk = 40) =>
    h.handle.db.execute(sql`
      insert into public.capacity_samples (at, mem_total_mb, mem_available_mb, load1, cpus, disk_used_pct,
        computers_running, computers_mem_mb, budget_mb)
      values (now() - (${minutesAgo} * interval '1 minute'), 11960, ${avail}, 0.4, 6, ${disk},
        ${Math.ceil(computersMb / 4096)}, ${computersMb}, 9216)`);

  beforeAll(async () => {
    h = await startHarness();
    owner = await h.user("capacity-owner@example.com");
    member = await h.user("capacity-member@example.com");
  }, 60_000);
  afterAll(async () => h?.stop());

  it("reads the host", async () => {
    const s = await sampleHost();
    expect(s.mem_total_mb).toBeGreaterThan(0);
    expect(s.mem_available_mb).toBeGreaterThan(0);
    expect(s.cpus).toBeGreaterThan(0);
  });

  it("records hosted computers' memory with each sample", async () => {
    const orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Cap" } }),
      )
    ).id;
    // A workspace starts with its team computer: make it a running 4 GB one.
    const [team] = await h.handle.db.execute<{ id: string }>(
      sql`select id from public.computers where org_id = ${orgId}::uuid and kind = 'team'`,
    );
    if (team)
      await h.handle.db.execute(sql`
        update public.computers set state = 'running', size = '{"cpus": 4, "memory_mb": 4096}'
        where id = ${team.id}::uuid`);
    else
      await h.handle.db.execute(sql`
        insert into public.computers (org_id, kind, name, state, size)
        values (${orgId}::uuid, 'team', 'A', 'running', '{"cpus": 4, "memory_mb": 4096}')`);
    const r = await recordSample(h.handle.db, 9216, host(5000));
    expect(r).toMatchObject({ computers_running: 1, computers_mem_mb: 4096 });
    await h.handle.db.execute(sql`delete from public.capacity_samples`);
  });

  it("alerts once a day per kind: early warning, refusals, low memory, disk", async () => {
    // Over 60% of 9 GB at the daily peak on 3 of the last 7 days.
    for (const d of [0, 1, 2]) await sampleAt(d * 1440 + 30, 6000);
    expect((await dueAlerts(h.handle.db, 9216)).map((a) => a.kind)).toEqual(["early_warning"]);
    // Claimed for today: not again.
    expect(await dueAlerts(h.handle.db, 9216)).toEqual([]);

    await recordCapacityFull(h.handle.db, { detail: { mem_mb: 4096 } });
    for (const m of [0, 5, 10]) await sampleAt(m, 1000, 1200, 85);
    expect((await dueAlerts(h.handle.db, 9216)).map((a) => a.kind).sort()).toEqual([
      "capacity_full",
      "disk",
      "low_memory",
    ]);
    expect(await dueAlerts(h.handle.db, 9216)).toEqual([]);
  });

  it("shows the owner 30-day peaks, refusals, alerts and a forecast", async () => {
    expect((await h.request("/v1/admin/capacity", { token: member.token })).status).toBe(403);
    const r = await j(await h.request("/v1/admin/capacity", { token: owner.token }));
    expect(r.latest).toMatchObject({ mem_available_mb: 1200, computers_mem_mb: 1000 });
    expect(r.days.length).toBeGreaterThanOrEqual(3);
    expect(r.refusals_30d).toBe(1);
    expect(r.alerts.map((a: { kind: string }) => a.kind)).toEqual(
      expect.arrayContaining(["early_warning", "capacity_full", "low_memory", "disk"]),
    );
    expect(r).toHaveProperty("full_in_weeks");
    const report = await capacityReport(h.handle.db, 9216);
    expect(report.budget_mb).toBe(9216);
  });
});
