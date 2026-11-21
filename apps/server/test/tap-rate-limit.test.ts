import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { OWN_BUDGET_TAPS } from "../src/api/app.ts";
import { type Harness, startHarness } from "./helpers.ts";

const ID = "0b0e5c3a-1f2e-4c6d-9a8b-7c6d5e4f3a2b";

describe("request cards and Stop have their own rate budget", () => {
  let h: Harness;
  beforeAll(async () => {
    h = await startHarness({ rateLimit: 3 });
  });
  afterAll(async () => {
    await h.stop();
  });

  it("knows which taps count apart", () => {
    for (const p of [
      `/v1/approvals/${ID}/decision`,
      `/v1/gallery-approvals/${ID}/decision`,
      `/v1/runs/${ID}/cancel`,
    ])
      expect(OWN_BUDGET_TAPS.test(p), p).toBe(true);
    for (const p of ["/v1/approvals", `/v1/approvals/${ID}`, `/v1/runs/${ID}`, "/v1/glance"])
      expect(OWN_BUDGET_TAPS.test(p), p).toBe(false);
  });

  it("an Approve still gets through after background calls use up the general budget", async () => {
    for (let i = 0; i < 3; i++) await h.request("/v1/config");
    const over = await h.request("/v1/config");
    expect(over.status).toBe(429);
    expect(Number(over.headers.get("retry-after"))).toBeGreaterThan(0);
    const tap = await h.request(`/v1/approvals/${ID}/decision`, {
      method: "POST",
      body: JSON.stringify({ decision: "approve" }),
    });
    expect(tap.status).not.toBe(429);
  });
});
