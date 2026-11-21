/**
 * Model access setting (`instance_settings` key `model_access`, docs/OWN-KEYS-PLAN.md §3.3):
 * whether Casama Cloud workspaces may bring their own model keys or ChatGPT plans, and whether
 * Casama's own model keys (the shared OpenRouter key and the server's Google key) are on or off
 * per plan. Self-hosted servers ignore this setting.
 */

export type CasamaModelsSwitch = "on" | "off";

export interface ModelAccess {
  /** Whether Cloud workspaces may use their own keys and ChatGPT plans. */
  own_providers: boolean;
  /** Whether Casama's model keys are available, by default and per plan code. */
  casama_models: {
    default: CasamaModelsSwitch;
    plans: Record<string, CasamaModelsSwitch>;
  };
  /** Optional text shown on the blocked card when Casama's models are off. */
  note: string | null;
}

export const DEFAULT_MODEL_ACCESS: ModelAccess = {
  own_providers: false,
  casama_models: {
    default: "on",
    plans: {},
  },
  note: null,
};

const ACCESS_KEYS = ["own_providers", "casama_models", "note"] as const;
const CASAMA_KEYS = ["default", "plans"] as const;
const PLAN_CODE = /^[a-z0-9_]{1,40}$/;
const MAX_NOTE_LENGTH = 500;
/** The paid tiers in `public.plans` (each also sold as `<tier>_yearly` and `<tier>_weekly`). */
const KNOWN_PAID_PLANS = ["plus", "pro", "max"] as const;
/** Billing-period suffixes on plan codes (`plus_yearly`, `pro_weekly`, …). */
const PERIOD_SUFFIX = /_(?:weekly|monthly|yearly|annual|annually|week|month|year)$/;

/** Lower-cased plan code, `free` when empty. */
function normalizePlanCode(planCode: string | null | undefined): string {
  return (planCode?.trim() ? planCode.trim() : "free").toLowerCase();
}

/** The base tier of a plan code: `plus_yearly` → `plus`, `max_weekly` → `max`, `pro` → `pro`. */
export function basePlanTier(planCode: string | null | undefined): string {
  const code = normalizePlanCode(planCode);
  const base = code.replace(PERIOD_SUFFIX, "");
  return base || code;
}

const isRecord = (v: unknown): v is Record<string, unknown> =>
  typeof v === "object" && v !== null && !Array.isArray(v);

const isSwitch = (v: unknown): v is CasamaModelsSwitch => v === "on" || v === "off";

/**
 * Validates a `model_access` setting. Lenient on load (keeps every valid field, falls back to
 * `DEFAULT_MODEL_ACCESS` for bad or missing ones); strict on save (`errors` is non-empty when any
 * field is invalid).
 */
export function checkModelAccess(raw: unknown): { access: ModelAccess; errors: string[] } {
  const errors: string[] = [];
  const access: ModelAccess = {
    own_providers: DEFAULT_MODEL_ACCESS.own_providers,
    casama_models: {
      default: DEFAULT_MODEL_ACCESS.casama_models.default,
      plans: {},
    },
    note: DEFAULT_MODEL_ACCESS.note,
  };
  if (raw === undefined || raw === null) return { access, errors };
  if (!isRecord(raw)) return { access, errors: ["model_access must be an object"] };

  for (const key of Object.keys(raw)) {
    if (!(ACCESS_KEYS as readonly string[]).includes(key)) {
      errors.push(`unknown field ${key} (expected ${ACCESS_KEYS.join(", ")})`);
    }
  }

  if (raw.own_providers !== undefined) {
    if (typeof raw.own_providers !== "boolean") {
      errors.push("own_providers must be true or false");
    } else {
      access.own_providers = raw.own_providers;
    }
  }

  if (raw.casama_models !== undefined) {
    if (!isRecord(raw.casama_models)) {
      errors.push("casama_models must be an object");
    } else {
      for (const k of Object.keys(raw.casama_models)) {
        if (!(CASAMA_KEYS as readonly string[]).includes(k)) {
          errors.push(`casama_models: unknown field ${k}`);
        }
      }
      if (raw.casama_models.default !== undefined) {
        if (!isSwitch(raw.casama_models.default)) {
          errors.push('casama_models.default must be "on" or "off"');
        } else {
          access.casama_models.default = raw.casama_models.default;
        }
      }
      if (raw.casama_models.plans !== undefined) {
        if (!isRecord(raw.casama_models.plans)) {
          errors.push("casama_models.plans must map plan codes to on or off");
        } else {
          const plans: Record<string, CasamaModelsSwitch> = {};
          for (const [code, val] of Object.entries(raw.casama_models.plans)) {
            if (!PLAN_CODE.test(code)) {
              errors.push(`casama_models.plans: ${code} isn't a valid plan code`);
            } else if (!isSwitch(val)) {
              errors.push(`casama_models.plans.${code} must be "on" or "off"`);
            } else {
              plans[code] = val;
            }
          }
          access.casama_models.plans = plans;
        }
      }
    }
  }

  if (raw.note !== undefined && raw.note !== null) {
    if (typeof raw.note !== "string") {
      errors.push("note must be a string or null");
    } else {
      const trimmed = raw.note.trim();
      if (trimmed.length > MAX_NOTE_LENGTH) {
        errors.push(`note must be at most ${MAX_NOTE_LENGTH} characters`);
      } else {
        access.note = trimmed || null;
      }
    }
  }

  return { access, errors };
}

let current: ModelAccess = {
  own_providers: DEFAULT_MODEL_ACCESS.own_providers,
  casama_models: { default: DEFAULT_MODEL_ACCESS.casama_models.default, plans: {} },
  note: DEFAULT_MODEL_ACCESS.note,
};

/** Replaces the in-memory `model_access` setting (reloaded every minute by `startRemoteSettings`). */
export function setModelAccess(raw: unknown): ModelAccess {
  current = checkModelAccess(raw).access;
  return current;
}

export function modelAccess(): ModelAccess {
  return current;
}

/**
 * Whether workspaces may bring and run their own chat model keys or ChatGPT plans. Always true on
 * self-hosted servers (`!billingEnabled`).
 */
export function ownProvidersAllowed(billingEnabled = true, access: ModelAccess = current): boolean {
  if (!billingEnabled) return true;
  return access.own_providers;
}

/**
 * Whether a workspace on `planCode` may use Casama's own model keys (the shared OpenRouter key
 * and the server's Google key). Always true on self-hosted servers (`!billingEnabled`).
 */
export function casamaModelsAllowed(
  planCode: string | null | undefined,
  billingEnabled = true,
  access: ModelAccess = current,
): boolean {
  if (!billingEnabled) return true;
  const code = normalizePlanCode(planCode);
  // An exact code (`pro_weekly`) wins over its base tier (`pro`), which wins over the default.
  const specific =
    access.casama_models.plans[code] ?? access.casama_models.plans[basePlanTier(code)];
  const state = specific ?? access.casama_models.default;
  return state === "on";
}

/**
 * Whether upgrading to another plan would give this workspace access to Casama's models.
 */
export function upgradeGivesCasamaModels(
  planCode: string | null | undefined,
  access: ModelAccess = current,
): boolean {
  const code = normalizePlanCode(planCode);
  if (casamaModelsAllowed(code, true, access)) return false;
  const tier = basePlanTier(code);
  for (const paid of KNOWN_PAID_PLANS) {
    if (paid !== tier && casamaModelsAllowed(paid, true, access)) return true;
  }
  for (const [other, state] of Object.entries(access.casama_models.plans)) {
    if (state !== "on" || other === code || basePlanTier(other) === tier) continue;
    // Free is never an upgrade.
    if (basePlanTier(other) === "free") continue;
    return true;
  }
  return false;
}

export interface OwnProviderRequiredDetails {
  code: "own_provider_required";
  message: string;
  note: string | null;
  actions: Array<"connect" | "upgrade">;
}

/**
 * The refusal returned when Casama's models are off for the workspace's plan and no usable own
 * model provider is connected (§3.4). `message` works as plain text in a shipped app.
 */
export function ownProviderRequiredError(opts?: {
  planCode?: string | null;
  access?: ModelAccess;
}): OwnProviderRequiredDetails {
  const access = opts?.access ?? current;
  const canUpgrade = upgradeGivesCasamaModels(opts?.planCode, access);
  const actions: Array<"connect" | "upgrade"> = canUpgrade ? ["connect", "upgrade"] : ["connect"];
  const base =
    "Casama's models aren't available on this plan right now. Add your own model key in Settings to keep chatting.";
  const note = access.note?.trim() || null;
  const message = note ? `${note} Add your own model key in Settings to keep chatting.` : base;
  return {
    code: "own_provider_required",
    message,
    note,
    actions,
  };
}
