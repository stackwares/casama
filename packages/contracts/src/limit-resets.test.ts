import { describe, expect, it } from "vitest";
import { LimitResetCampaignInput, LimitResetSettings } from "./limit-resets.ts";

const campaign = {
  name: "Outage recovery",
  message: "Here's a reset after Tuesday's outage.",
  audience: {},
  starts_at: "2026-11-20T00:00:00Z",
  expires_at: "2026-12-04T00:00:00Z",
};
describe("saved reset contracts", () => {
  it("defaults to a full refill with daily cap relief and no computer reset", () => {
    expect(LimitResetCampaignInput.parse(campaign)).toMatchObject({
      refill_percent: 100,
      reset_daily: true,
      reset_computer: false,
      audience: {
        plan_codes: [],
        workspace_ids: [],
        created_before: null,
        limited_within_days: null,
      },
      budget_usd: null,
    });
  });
  it("rejects multiline notices and invalid refill or cost settings", () => {
    for (const change of [
      { message: "hello\nworld" },
      { message: "x".repeat(121) },
      { expires_at: campaign.starts_at },
      { refill_percent: 9 },
      { refill_percent: 101 },
      { budget_usd: -1 },
      { max_per_use_usd: -1 },
      { audience: { workspace_ids: ["not-an-id"] } },
    ])
      expect(LimitResetCampaignInput.safeParse({ ...campaign, ...change }).success).toBe(false);
  });
  it("requires positive whole-number usage and holding limits", () => {
    const settings = { enabled: false, per_period: 1, max_held: 3, notify_owners: true };
    expect(LimitResetSettings.parse(settings)).toEqual(settings);
    expect(LimitResetSettings.safeParse({ ...settings, per_period: 0 }).success).toBe(false);
    expect(LimitResetSettings.safeParse({ ...settings, max_held: 1.5 }).success).toBe(false);
  });
});
