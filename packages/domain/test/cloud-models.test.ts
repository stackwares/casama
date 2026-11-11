import { describe, expect, it } from "vitest";
import {
  CLOUD_LOCKED_MODEL,
  cloudModelAllowed,
  cloudModelDailyCap,
  cloudOpenRouterCharge,
  lockCloudPolicy,
  PLATFORM_OPENROUTER_CREDENTIAL_ID,
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
    // A self-hosted server that set the key still offers the short list.
    expect(cloudModelAllowed({ billing: false, plan: "selfhost" }, "openai/gpt-6-luna")).toBe(true);
    expect(cloudModelAllowed({ billing: false, plan: "selfhost" }, "some/unknown-model")).toBe(
      false,
    );
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

  it("caps a free workspace at $0.25 a day and a paid one at $10", () => {
    expect(cloudModelDailyCap("free")).toBe(0.25);
    expect(cloudModelDailyCap(null)).toBe(0.25);
    expect(cloudModelDailyCap("pro")).toBe(10);
    expect(cloudModelDailyCap("pro_yearly")).toBe(10);
  });
});
