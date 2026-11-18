/**
 * Live view of a computer that won't start for billing reasons (D-248): the answer is the same
 * 402 the app's other computer routes give, so the app opens its paywall and Casama for Chrome
 * offers Billing, instead of a 503 "try again shortly".
 */
import { ComputerService } from "@casama/agent";
import { unavailableProvider } from "@casama/sandbox";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

describe("stream session refusals", () => {
  let h: Harness;
  let owner: { id: string; token: string };
  let orgId: string;
  let computerId: string;

  beforeAll(async () => {
    h = await startHarness();
    // Live view configured, on a computer service with no real computers behind it.
    (h.deps as { computers?: ComputerService }).computers = new ComputerService(
      h.handle.db,
      unavailableProvider(),
    );
    (h.deps as { live?: unknown }).live = {
      turnSecret: "turn-secret",
      turnHost: "turn.example.test",
      turnPort: 3478,
      tokenSecret: "test-stream-token-secret-0123456789",
    };
    owner = await h.user("stream-refusals@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "S" } }),
      )
    ).id as string;
    // The workspace's team computer, on the desktop profile live view needs.
    const [c] = await h.handle.db.execute<{ id: string }>(sql`
      update public.computers set profile = 'desktop', state = 'stopped'
      where org_id = ${orgId}::uuid and kind = 'team' returning id`);
    computerId = c!.id;
  }, 120_000);

  afterAll(async () => {
    await h?.stop();
  });

  const session = () =>
    h.request(`/v1/computers/${computerId}/stream-session`, {
      method: "POST",
      token: owner.token,
      json: { mode: "view" },
    });

  it("answers out of credits with 402 out_of_credits", async () => {
    await h.handle.db.execute(sql`
      update public.entitlements set limits = limits || '{"credit_gate": true}'::jsonb
      where org_id = ${orgId}::uuid`);
    const res = await session();
    expect(res.status).toBe(402);
    expect((await j(res)).code).toBe("out_of_credits");
  });

  it("answers a downgraded plan's extra computer with 402 plan_limit", async () => {
    await h.handle.db.execute(sql`
      update public.entitlements set limits = (limits - 'credit_gate') || '{"max_computers": 0}'::jsonb
      where org_id = ${orgId}::uuid`);
    const res = await session();
    expect(res.status).toBe(402);
    expect((await j(res)).code).toBe("plan_limit");
  });
});
