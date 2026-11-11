import { describe, expect, it } from "vitest";
import {
  CLOUD_MODEL_DEFAULTS,
  cloudModelAssignment,
  cloudRunPolicy,
} from "../src/cloud-model-assignment.ts";
import { PLATFORM_OPENROUTER_CREDENTIAL_ID } from "../src/cloud-models.ts";

describe("cloud model assignment", () => {
  it("fills blanks from the built-in defaults and keeps a valid change", () => {
    expect(cloudModelAssignment(null)).toEqual(CLOUD_MODEL_DEFAULTS);
    expect(
      cloudModelAssignment({ chat: "  openai/gpt-6-luna  ", image_resolution: "4K" }),
    ).toMatchObject({
      chat: "openai/gpt-6-luna",
      image_resolution: "4K",
      live: CLOUD_MODEL_DEFAULTS.live,
    });
    expect(cloudModelAssignment({ image_resolution: "8K", chat: "" }).image_resolution).toBe("1K");
    expect(cloudModelAssignment({ chat: "" }).chat).toBe(CLOUD_MODEL_DEFAULTS.chat);
  });

  it("pins a Cloud bot to Casama's key and the assigned models", () => {
    const policy = cloudRunPolicy({ ...CLOUD_MODEL_DEFAULTS, chat: "a", background: "b" });
    expect(policy.primary).toEqual({
      credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID,
      model: "a",
    });
    expect(policy.cheap).toEqual({ credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID, model: "b" });
  });
});
