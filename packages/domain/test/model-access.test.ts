import { afterEach, describe, expect, it } from "vitest";
import {
  casamaModelsAllowed,
  checkModelAccess,
  DEFAULT_MODEL_ACCESS,
  modelAccess,
  ownProviderRequiredError,
  ownProvidersAllowed,
  setModelAccess,
  upgradeGivesCasamaModels,
} from "../src/model-access.ts";

describe("model-access", () => {
  afterEach(() => {
    setModelAccess(DEFAULT_MODEL_ACCESS);
  });

  it("returns safe defaults for null, undefined or invalid input", () => {
    expect(checkModelAccess(null)).toEqual({ access: DEFAULT_MODEL_ACCESS, errors: [] });
    expect(checkModelAccess(undefined)).toEqual({ access: DEFAULT_MODEL_ACCESS, errors: [] });

    const bad = checkModelAccess("not an object");
    expect(bad.access).toEqual(DEFAULT_MODEL_ACCESS);
    expect(bad.errors).toEqual(["model_access must be an object"]);
  });

  it("validates fields and keeps good ones when loading a partial/bad row", () => {
    const res = checkModelAccess({
      own_providers: true,
      casama_models: {
        default: "on",
        plans: {
          free: "off",
          pro: "on",
          "BAD-CODE": "off",
          starter: "maybe",
        },
      },
      note: "  Casama's models are paused.  ",
      extra: 123,
    });
    expect(res.access).toEqual({
      own_providers: true,
      casama_models: {
        default: "on",
        plans: {
          free: "off",
          pro: "on",
        },
      },
      note: "Casama's models are paused.",
    });
    expect(res.errors).toContain(
      "unknown field extra (expected own_providers, casama_models, note)",
    );
    expect(res.errors).toContain("casama_models.plans: BAD-CODE isn't a valid plan code");
    expect(res.errors).toContain('casama_models.plans.starter must be "on" or "off"');
  });

  it("checks casamaModelsAllowed per plan and default", () => {
    // Everything on by default
    expect(casamaModelsAllowed("free", true)).toBe(true);
    expect(casamaModelsAllowed("pro", true)).toBe(true);
    expect(casamaModelsAllowed(null, true)).toBe(true);
    expect(ownProvidersAllowed(true)).toBe(false);
    expect(ownProvidersAllowed(false)).toBe(true);

    // Free off, paid on
    setModelAccess({
      own_providers: true,
      casama_models: { default: "on", plans: { free: "off" } },
      note: null,
    });
    expect(modelAccess().own_providers).toBe(true);
    expect(ownProvidersAllowed(true)).toBe(true);
    expect(casamaModelsAllowed("free", true)).toBe(false);
    expect(casamaModelsAllowed(null, true)).toBe(false);
    expect(casamaModelsAllowed("starter", true)).toBe(true);
    expect(casamaModelsAllowed("pro", true)).toBe(true);
    // Self-hosted ignores the setting
    expect(casamaModelsAllowed("free", false)).toBe(true);
    expect(upgradeGivesCasamaModels("free")).toBe(true);
    expect(upgradeGivesCasamaModels("pro")).toBe(false);

    // Everything off (emergency switch)
    setModelAccess({
      own_providers: true,
      casama_models: { default: "off", plans: {} },
      note: "Casama's models are paused.",
    });
    expect(casamaModelsAllowed("free", true)).toBe(false);
    expect(casamaModelsAllowed("pro", true)).toBe(false);
    expect(upgradeGivesCasamaModels("free")).toBe(false);
  });

  it("builds own_provider_required error with plain-text message and actions", () => {
    setModelAccess({
      own_providers: true,
      casama_models: { default: "on", plans: { free: "off" } },
      note: null,
    });
    const freeErr = ownProviderRequiredError({ planCode: "free" });
    expect(freeErr.code).toBe("own_provider_required");
    expect(freeErr.actions).toEqual(["connect", "upgrade"]);
    expect(freeErr.message).toBe(
      "Casama's models aren't available on this plan right now. Add your own model key in Settings to keep chatting.",
    );

    setModelAccess({
      own_providers: true,
      casama_models: { default: "off", plans: {} },
      note: "Casama's models are paused.",
    });
    const emergencyErr = ownProviderRequiredError({ planCode: "pro" });
    expect(emergencyErr.actions).toEqual(["connect"]);
    expect(emergencyErr.note).toBe("Casama's models are paused.");
    expect(emergencyErr.message).toBe(
      "Casama's models are paused. Add your own model key in Settings to keep chatting.",
    );
  });
});
