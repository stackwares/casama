import { cloudMarkup, setCloudMarkup } from "@casama/domain";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

describe("pricing editor (D-244)", () => {
  let h: Harness;
  let owner: { id: string; token: string };
  let member: { id: string; token: string };
  let orgId: string;

  beforeAll(async () => {
    h = await startHarness();
    owner = await h.user("pricing-owner@example.com");
    member = await h.user("pricing-member@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: member.token,
          json: { name: "On Plus" },
        }),
      )
    ).id;
    // Put the workspace on Plus with an owner override, as billing would.
    await h.handle.db.execute(sql`
      update public.entitlements set plan_code = 'plus', overrides = '{"max_bots": 7}'::jsonb,
        limits = (select limits from public.plans where code = 'plus') || '{"max_bots": 7}'::jsonb
      where org_id = ${orgId}::uuid`);
    await h.handle.db.execute(
      sql`update public.organizations set plan = 'plus' where id = ${orgId}::uuid`,
    );
  }, 60_000);
  afterAll(async () => {
    setCloudMarkup(1.3);
    await h?.stop();
  });

  it("only the instance owner can read or change pricing", async () => {
    expect((await h.request("/v1/admin/pricing", { token: member.token })).status).toBe(403);
    const r = await j(await h.request("/v1/admin/pricing", { token: owner.token }));
    expect(r.plans.map((p: { code: string }) => p.code)).toEqual(
      expect.arrayContaining(["free", "plus", "pro", "max", "max_yearly"]),
    );
    const plus = r.plans.find((p: { code: string }) => p.code === "plus");
    expect(plus).toMatchObject({
      price_label: "$15 / month",
      credit_gate: true,
      workspaces: 1,
      limits: { computer_hours: 30, monthly_credits_usd: 5, cloud_daily_usd: 5 },
      store_product_ids: { app_store: "ai.casama.plus.monthly" },
    });
    expect(r.packs.map((p: { code: string }) => p.code)).toEqual(["credits_10", "credits_25"]);
    expect(r.settings.markup).toBe(1.3);
    const denied = await h.request("/v1/admin/plans/plus", {
      method: "PUT",
      token: member.token,
      json: { price_label: "free!" },
    });
    expect(denied.status).toBe(403);
  });

  it("a plan's new limits reach its workspaces right away, under their overrides", async () => {
    const limits = {
      monthly_credits_usd: 6,
      max_bots: 5,
      max_computers: 2,
      computer_hours: 40,
      seats: 3,
      cloud_daily_usd: 5,
    };
    const saved = await j(
      await h.request("/v1/admin/plans/plus", {
        method: "PUT",
        token: owner.token,
        json: { limits, price_label: "$16 / month" },
      }),
    );
    expect(saved).toMatchObject({ price_label: "$16 / month", credit_gate: true, limits });
    const [e] = await h.handle.db.execute<{ limits: Record<string, unknown> }>(
      sql`select limits from public.entitlements where org_id = ${orgId}::uuid`,
    );
    expect(e?.limits).toMatchObject({
      computer_hours: 40,
      seats: 3,
      max_bots: 7,
      credit_gate: true,
    });
    // Saving only the label keeps the limits.
    const again = await j(
      await h.request("/v1/admin/plans/plus", {
        method: "PUT",
        token: owner.token,
        json: { price_label: "$15 / month" },
      }),
    );
    expect(again.limits).toEqual(limits);
  });

  it("creates plans and packs, and protects the free and self-hosted plans", async () => {
    const incomplete = await h.request("/v1/admin/plans/team", {
      method: "PUT",
      token: owner.token,
      json: { price_label: "$99" },
    });
    expect(incomplete.status).toBe(400);
    const team = await j(
      await h.request("/v1/admin/plans/team", {
        method: "PUT",
        token: owner.token,
        json: {
          name: "Team",
          interval: "month",
          limits: { seats: 25 },
          credit_gate: true,
          sort: 7,
        },
      }),
    );
    expect(team).toMatchObject({ code: "team", active: true, credit_gate: true, workspaces: 0 });
    for (const [code, body] of [
      ["selfhost", { price_label: "x" }],
      ["free", { active: false }],
    ] as const)
      expect(
        (
          await h.request(`/v1/admin/plans/${code}`, {
            method: "PUT",
            token: owner.token,
            json: body,
          })
        ).status,
      ).toBe(400);
    const pack = await j(
      await h.request("/v1/admin/credit-packs/credits_50", {
        method: "PUT",
        token: owner.token,
        json: { name: "$50 of credits", credits_usd: 50, price_label: "$50" },
      }),
    );
    expect(pack).toMatchObject({ code: "credits_50", credits_usd: 50, active: true });
  });

  it("changes the markup live", async () => {
    const bad = await h.request("/v1/admin/billing-settings", {
      method: "PATCH",
      token: owner.token,
      json: { markup: 0.9 },
    });
    expect(bad.status).toBe(400);
    const r = await j(
      await h.request("/v1/admin/billing-settings", {
        method: "PATCH",
        token: owner.token,
        json: { markup: 1.5 },
      }),
    );
    expect(r.markup).toBe(1.5);
    expect(cloudMarkup()).toBe(1.5);
  });
});
