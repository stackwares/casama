/**
 * Settings for decision models (docs/DECISION-MODEL-PLAN.md §5.4, D-454): which model answers,
 * which models are compared in shadow, and per use whether it is off, in shadow (asked and logged,
 * never acted on) or on, with its thresholds. Stored in instance_settings under "decisions" and
 * editable by the instance owner without a deploy. Everything starts off.
 */

export const DECISION_USES = [
  "scan_gate",
  "reply_check",
  "push_score",
  "tool_gate",
  "long_run",
  "effort",
  "watcher_gate",
] as const;
export type DecisionUse = (typeof DECISION_USES)[number];
export type DecisionMode = "off" | "shadow" | "on";

/** Thresholds per use, with the plan's starting values. All are probabilities except the steps. */
export const DECISION_THRESHOLDS = {
  // Skip a scan only when every question is at or under this.
  scan_gate: { skip_below: 0.1, max_skips_in_row: 3 },
  // Over flag_above: run today's checker. Under memory_skip_below: skip the memory call.
  reply_check: { flag_above: 0.9, memory_skip_below: 0.1, correction_above: 0.9 },
  // A non-urgent suggestion under hold_below waits for the next brief.
  push_score: { hold_below: 0.2 },
  // An outgoing call the person likely didn't ask for (asked_for at or under ask_below) asks first.
  tool_gate: { ask_below: 0.1 },
  // At first_step and every `every` steps after; repeating at or over repeating_above sends the
  // "deliver what you have" note early.
  long_run: { repeating_above: 0.9, first_step: 10, every: 8 },
  // quick at or over quick_above runs the message at low effort.
  effort: { quick_above: 0.9 },
  // The change clearly doesn't match the watcher's condition: no run.
  watcher_gate: { skip_below: 0.1 },
} as const satisfies Record<DecisionUse, Record<string, number>>;

export type DecisionThresholds<U extends DecisionUse> = {
  -readonly [K in keyof (typeof DECISION_THRESHOLDS)[U]]: number;
};

export type DecisionUseSettings<U extends DecisionUse = DecisionUse> = {
  mode: DecisionMode;
} & DecisionThresholds<U>;

export interface DecisionSettings {
  /** The model that answers for uses that are on. Empty: every use behaves as off. Pinned version. */
  model: string;
  /** Models asked side by side for uses in shadow (at most 5). */
  shadow_models: string[];
  /** Per call time limit. */
  timeout_ms: number;
  uses: { [U in DecisionUse]: DecisionUseSettings<U> };
}

/** The plan's three shadow candidates (§12, decision 2), used when shadow is on and none are set. */
export const DEFAULT_SHADOW_MODELS = [
  "typesafe/jev-1.14",
  "openai/gpt-6-luna-decisions",
  "perplexity/pplx-decider-flash-v1.2",
];

const MODES = new Set<DecisionMode>(["off", "shadow", "on"]);
const STEP_KEYS = new Set(["max_skips_in_row", "first_step", "every"]);

function modelId(v: unknown): string {
  return typeof v === "string" ? v.trim().slice(0, 200) : "";
}

/** Fills anything missing or out of range from the defaults; unknown keys are dropped. */
export function decisionSettings(raw: unknown): DecisionSettings {
  const row = raw && typeof raw === "object" ? (raw as Record<string, unknown>) : {};
  const usesRaw =
    row.uses && typeof row.uses === "object" ? (row.uses as Record<string, unknown>) : {};
  const uses = {} as Record<DecisionUse, Record<string, unknown>>;
  for (const use of DECISION_USES) {
    const given =
      usesRaw[use] && typeof usesRaw[use] === "object"
        ? (usesRaw[use] as Record<string, unknown>)
        : {};
    const mode =
      typeof given.mode === "string" && MODES.has(given.mode as DecisionMode)
        ? (given.mode as DecisionMode)
        : "off";
    const out: Record<string, unknown> = { mode };
    for (const [key, fallback] of Object.entries(DECISION_THRESHOLDS[use])) {
      const v = given[key];
      const ok = STEP_KEYS.has(key)
        ? typeof v === "number" && Number.isInteger(v) && v >= 1 && v <= 100
        : typeof v === "number" && Number.isFinite(v) && v >= 0 && v <= 1;
      out[key] = ok ? v : fallback;
    }
    uses[use] = out;
  }
  const shadow = Array.isArray(row.shadow_models)
    ? [...new Set(row.shadow_models.map(modelId).filter(Boolean))].slice(0, 5)
    : [];
  const timeout = row.timeout_ms;
  return {
    model: modelId(row.model),
    shadow_models: shadow,
    timeout_ms:
      typeof timeout === "number" && Number.isInteger(timeout) && timeout >= 200 && timeout <= 5000
        ? timeout
        : 1500,
    uses: uses as unknown as DecisionSettings["uses"],
  };
}

/** What a use does right now: `on` needs a model, `shadow` needs at least one model to compare. */
export function decisionModeOf(settings: DecisionSettings, use: DecisionUse): DecisionMode {
  const mode = settings.uses[use].mode;
  if (mode === "on" && !settings.model) return "off";
  if (mode === "shadow" && !shadowModelsOf(settings).length) return "off";
  return mode;
}

/** The models compared in shadow: the list, or the chosen model alone, or the plan's three. */
export function shadowModelsOf(settings: DecisionSettings): string[] {
  if (settings.shadow_models.length) return settings.shadow_models;
  if (settings.model) return [settings.model];
  return DEFAULT_SHADOW_MODELS;
}

/** Every model the decision path may call on Casama's key: the guardrail must allow each (D-364). */
export function decisionModelIds(settings: DecisionSettings): string[] {
  const any = DECISION_USES.some((u) => settings.uses[u].mode !== "off");
  if (!any) return settings.model ? [settings.model] : [];
  return [...new Set([settings.model, ...shadowModelsOf(settings)].filter(Boolean))];
}
