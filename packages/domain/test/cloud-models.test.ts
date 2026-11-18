import { describe, expect, it } from "vitest";
import {
  CLOUD_LOCKED_MODEL,
  cloudModelAllowed,
  cloudModelDailyCap,
  cloudOpenRouterCharge,
  lockCloudPolicy,
  PLATFORM_OPENROUTER_CREDENTIAL_ID,
  useSharedKeyForMissing,
} from "../src/index.ts";

describe("Casama Cloud models", () => {
  it("charges OpenRouter's cost times the 5.5% fee times 1.3", () => {
    expect(cloudOpenRouterCharge(1)).toBeCloseTo(1.055 * 1.3, 8);
    expect(cloudOpenRouterCharge(0)).toBe(0);
  });

  it("lets a Casama Cloud workspace run only the model Casama assigns", () => {
    expect(cloudModelAllowed({ billing: true, plan: "free" }, CLOUD_LOCKED_MODEL)).toBe(true);
    expect(cloudModelAllowed({ billing: true, plan: "pro" }, CLOUD_LOCKED_MODEL)).toBe(true);
    expect(cloudModelAllowed({ billing: true, plan: "free" }, "openai/gpt-6-luna")).toBe(false);
    expect(cloudModelAllowed({ billing: true, plan: "pro" }, "anthropic/claude-sonnet-5.5")).toBe(
      false,
    );
    // A self-hosted server that set the shared key is locked the same way.
    expect(cloudModelAllowed({ billing: false, plan: "selfhost" }, CLOUD_LOCKED_MODEL)).toBe(true);
    expect(cloudModelAllowed({ billing: false, plan: "selfhost" }, "openai/gpt-6-luna")).toBe(
      false,
    );
    expect(cloudModelAllowed({ billing: false, plan: "selfhost" }, "some/unknown-model")).toBe(
      false,
    );
  });

  it("moves a deleted key onto Casama's shared key and leaves a live key alone", () => {
    const own = "11111111-1111-4111-8111-111111111111";
    const gone = "22222222-2222-4222-8222-222222222222";
    const shared = { credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID, model: CLOUD_LOCKED_MODEL };
    const repaired = useSharedKeyForMissing(
      {
        primary: { credential_id: gone, model: "openai/gpt-6-luna" },
        cheap: { credential_id: own, model: "claude-haiku-5-5" },
      },
      new Set([own]),
      shared,
    );
    expect(repaired.changed).toBe(true);
    expect(repaired.policy.primary).toEqual(shared);
    expect(repaired.policy.cheap?.credential_id).toBe(own);
    const kept = useSharedKeyForMissing(
      { primary: { credential_id: own, model: "openai/gpt-6-luna" } },
      new Set([own]),
      shared,
    );
    expect(kept.changed).toBe(false);
    expect(kept.policy.primary?.model).toBe("openai/gpt-6-luna");
  });

  it("rewrites Casama's key to that model and leaves a workspace key alone", () => {
    const own = "11111111-1111-4111-8111-111111111111";
    const policy = lockCloudPolicy({
      primary: {
        credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID,
        model: "anthropic/claude-opus-5.5",
      },
      cheap: { credential_id: own, model: "claude-haiku-5-5" },
    });
    expect(policy.primary?.model).toBe(CLOUD_LOCKED_MODEL);
    expect(policy.cheap?.model).toBe("claude-haiku-5-5");
  });

  it("drops a bot's own thinking level on the shared key", () => {
    const policy = lockCloudPolicy({
      primary: {
        credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID,
        model: CLOUD_LOCKED_MODEL,
        reasoning_effort: "max",
      } as { credential_id: string; model: string; reasoning_effort?: string },
    });
    expect((policy.primary as { reasoning_effort?: string }).reasoning_effort).toBeUndefined();
  });

  it("caps a free workspace at $0.25 a day and a paid one at $10", () => {
    expect(cloudModelDailyCap("free")).toBe(0.25);
    expect(cloudModelDailyCap(null)).toBe(0.25);
    expect(cloudModelDailyCap("pro")).toBe(10);
    expect(cloudModelDailyCap("pro_yearly")).toBe(10);
  });
});
