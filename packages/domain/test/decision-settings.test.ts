import { describe, expect, it } from "vitest";
import {
  DECISION_USES,
  DEFAULT_SHADOW_MODELS,
  decisionModelIds,
  decisionModeOf,
  decisionSettings,
  shadowModelsOf,
} from "../src/decision-settings.ts";

describe("decision settings (D-454)", () => {
  it("start with every use off, no model and the plan's thresholds", () => {
    const s = decisionSettings(null);
    expect(s.model).toBe("");
    expect(s.shadow_models).toEqual([]);
    expect(s.timeout_ms).toBe(1500);
    for (const use of DECISION_USES) expect(s.uses[use].mode).toBe("off");
    expect(s.uses.scan_gate).toEqual({ mode: "off", skip_below: 0.1, max_skips_in_row: 3 });
    expect(s.uses.reply_check.flag_above).toBe(0.9);
    expect(decisionModelIds(s)).toEqual([]);
  });

  it("keep valid values and replace bad ones with defaults", () => {
    const s = decisionSettings({
      model: "  typesafe/jev-1.14 ",
      shadow_models: ["a/x", "a/x", "", 3, "b/y", "c/z", "d/w", "e/v", "f/u"],
      timeout_ms: 99,
      uses: {
        scan_gate: { mode: "on", skip_below: 0.05, max_skips_in_row: 0 },
        reply_check: { mode: "loud", flag_above: 2 },
        nonsense: { mode: "on" },
      },
    });
    expect(s.model).toBe("typesafe/jev-1.14");
    expect(s.shadow_models).toEqual(["a/x", "b/y", "c/z", "d/w", "e/v"]);
    expect(s.timeout_ms).toBe(1500);
    expect(s.uses.scan_gate).toEqual({ mode: "on", skip_below: 0.05, max_skips_in_row: 3 });
    expect(s.uses.reply_check.mode).toBe("off");
    expect(s.uses.reply_check.flag_above).toBe(0.9);
    expect("nonsense" in s.uses).toBe(false);
  });

  it("treat on without a model as off; shadow falls back to the plan's three", () => {
    const on = decisionSettings({ uses: { scan_gate: { mode: "on" } } });
    expect(decisionModeOf(on, "scan_gate")).toBe("off");
    const shadow = decisionSettings({ uses: { scan_gate: { mode: "shadow" } } });
    expect(decisionModeOf(shadow, "scan_gate")).toBe("shadow");
    expect(shadowModelsOf(shadow)).toEqual(DEFAULT_SHADOW_MODELS);
    expect(decisionModelIds(shadow)).toEqual(DEFAULT_SHADOW_MODELS);
    const chosen = decisionSettings({ model: "a/x", uses: { scan_gate: { mode: "shadow" } } });
    expect(shadowModelsOf(chosen)).toEqual(["a/x"]);
  });
});
