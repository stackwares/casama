/** Health data (D-150): summaries only, extras off by default, trends without a model, encryption on Cloud. */
import { randomBytes } from "node:crypto";
import { fileURLToPath } from "node:url";
import { contentKeys } from "@casama/db";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/health.json", import.meta.url));
const KEY = "watch-phone-0001";
let h: Harness;
let owner: { id: string; token: string };
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
const dayOf = (offset: number) =>
  new Date(Date.now() + offset * 86_400_000).toISOString().slice(0, 10);
const reading = (date: string, summary: Record<string, unknown>) => ({
  kind: "health",
  period_start: `${date}T00:00:00Z`,
  period_end: `${date}T23:59:59Z`,
  external_id: `health-${date}`,
  summary: { type: "day", date, ...summary },
});
const upload = (readings: unknown[]) =>
  h.request(`/v1/device-sources/${KEY}/readings`, {
    method: "POST",
    token: owner.token,
    json: { readings },
  });

beforeAll(async () => {
  h = await startHarness({
    contentKey: randomBytes(32).toString("base64"),
    env: { HEALTH_REQUIRES_ENCRYPTION: "on" },
    worker: { fixtures: FIXTURES, deviceWaitMs: { read: 300 } },
  });
  owner = await h.user("health-owner@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Health" } }),
    )
  ).id;
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-health" },
    }),
  );
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Coach",
          model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
        },
      }),
    )
  ).id;
  await h.request(`/v1/device-sources/${KEY}`, {
    method: "PUT",
    token: owner.token,
    json: { name: "Phone", platform: "android", kinds: { health: {} } },
  });
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

describe("health data", () => {
  it("isn't stored without encryption at rest where that's required, and is sealed once it's on", async () => {
    const res = await upload([reading(dayOf(0), { steps: 4000 })]);
    expect(res.status).toBe(409);
    expect((await j(res)).code).toBe("health_needs_encryption");
    await h.request(`/v1/orgs/${orgId}/encryption`, {
      method: "PUT",
      token: owner.token,
      json: { enabled: true },
    });
    expect((await upload([reading(dayOf(0), { steps: 4000 })])).status).toBe(200);
    // Sealed in the table; readable through the API.
    const [raw] = await h.tdb.admin<
      { s: string }[]
    >`select summary::text as s from public.device_readings where external_id = ${`health-${dayOf(0)}`}`;
    expect(raw?.s).toContain('"$enc"');
    expect(raw?.s).not.toContain("4000");
    const mine = await j(
      await h.request("/v1/device-readings?kind=health", { token: owner.token }),
    );
    expect(mine.items[0].summary).toMatchObject({ type: "day", steps: 4000 });
  });

  it("takes summaries only, and drops extras that weren't turned on", async () => {
    const samples = await upload([
      reading(dayOf(0), { steps: 1, samples: [{ hr: 70, at: "2027-01-01T00:00:00Z" }] }),
    ]);
    expect(samples.status).toBe(400);
    expect((await j(samples)).code).toBe("bad_health_summary");
    expect(
      (
        await upload([
          { ...reading(dayOf(0), {}), summary: { type: "heart_rate_series", values: [70, 71] } },
        ])
      ).status,
    ).toBe(400);
    await upload([reading(dayOf(-1), { steps: 9000, glucose: { avg_mg_dl: 101 } })]);
    let r = (
      await j(await h.request("/v1/device-readings?kind=health", { token: owner.token }))
    ).items.find((x: { external_id: string }) => x.external_id === `health-${dayOf(-1)}`);
    expect(r.summary.glucose).toBeUndefined();
    await h.request(`/v1/device-sources/${KEY}`, {
      method: "PUT",
      token: owner.token,
      json: { name: "Phone", platform: "android", kinds: { health: { extras: ["glucose"] } } },
    });
    await upload([reading(dayOf(-1), { steps: 9000, glucose: { avg_mg_dl: 101 } })]);
    r = (
      await j(await h.request("/v1/device-readings?kind=health", { token: owner.token }))
    ).items.find((x: { external_id: string }) => x.external_id === `health-${dayOf(-1)}`);
    expect(r.summary.glucose).toEqual({ avg_mg_dl: 101 });
  });

  it("a bot compares last night's sleep with the person's usual, from summaries alone", async () => {
    await upload([
      ...Array.from({ length: 10 }, (_, i) =>
        reading(dayOf(-(i + 2)), { sleep: { minutes: 420 + (i % 3) * 10 }, steps: 8000 }),
      ),
      reading(dayOf(0), { sleep: { minutes: 300, start: "23:40", end: "04:40" }, steps: 8100 }),
    ]);
    await h.request("/v1/device-grants", {
      method: "PUT",
      token: owner.token,
      json: { bot_id: botId, kind: "health", allowed: true },
    });
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: botId },
      }),
    );
    const runId = (
      await j(
        await h.request(`/v1/conversations/${conv.id}/messages`, {
          method: "POST",
          token: owner.token,
          json: { text: "How did I sleep?" },
        }),
      )
    ).run_id;
    await waitFor(
      async () =>
        ["completed", "failed"].includes(
          (await j(await h.request(`/v1/runs/${runId}`, { token: owner.token }))).status,
        ),
      "run",
    );
    // Messages are sealed too (encryption is on here).
    const [msg] = await h.tdb.admin<
      { content: unknown }[]
    >`select content from public.messages where run_id = ${runId} and role = 'assistant' order by created_at desc limit 1`;
    expect(JSON.stringify(contentKeys.open(msg?.content))).toContain("lower than your usual");
  });
});
