import { DEFAULT_MODELS } from "./models.ts";

/** OpenRouter keeps 5.5% when credits are bought. */
export const OPENROUTER_CREDIT_FEE = 1.055;

/** docs/COSTS.md: charge at least cost × 1.3. The default until billing_settings is loaded. */
export const CLOUD_OPENROUTER_MARKUP = 1.3;

let markup = CLOUD_OPENROUTER_MARKUP;

/**
 * The markup on usage paid with Casama's own keys (D-244). The server loads it from
 * billing_settings and refreshes it every minute, so the Admin screen can change it live.
 */
export function setCloudMarkup(value: number) {
  if (Number.isFinite(value) && value >= 1) markup = value;
}
export function cloudMarkup(): number {
  return markup;
}

/** What a workspace is charged for one OpenRouter call on Casama's key. */
export function cloudOpenRouterCharge(providerCostUsd: number): number {
  return providerCostUsd * OPENROUTER_CREDIT_FEE * markup;
}

/** What a workspace is charged for usage on another of Casama's keys (Google, OpenAI). */
export function cloudCharge(providerCostUsd: number): number {
  return providerCostUsd * markup;
}

/** Casama's shared OpenRouter key. Not a row in model_credentials (D-186). */
export const PLATFORM_OPENROUTER_CREDENTIAL_ID = "00000000-0000-4000-8000-0000000000c1";

/** The only model a Casama Cloud workspace runs on Casama's key. */
export const CLOUD_LOCKED_MODEL = DEFAULT_MODELS.openrouter ?? "deepseek/deepseek-v4.1-flash-1017";

/**
 * Output cap on Casama's key. It was 4,096, which cut long answers and file writes mid-way
 * (D-268); spending is held by the run and day budgets, not by this.
 */
export const CLOUD_MAX_OUTPUT_TOKENS = 16_384;

const PAID_DAILY_USD = 10;
const FREE_DAILY_USD = 0.25;

/**
 * How much one workspace may be charged for Casama's key in a UTC day: the plan's
 * `cloud_daily_usd` limit when it has one (D-244), else $0.25 free and $10 paid.
 */
export function cloudModelDailyCap(plan: string | null | undefined, limit?: unknown): number {
  if (typeof limit === "number" && limit >= 0) return limit;
  if (!plan || plan === "free") return FREE_DAILY_USD;
  return PAID_DAILY_USD;
}

type CloudChoice = { credential_id: string; model: string };

/**
 * A bot whose key was deleted still has that id stored. When the server has its shared key,
 * those choices move onto it so chat keeps working. A key that still exists is left alone.
 */
export function useSharedKeyForMissing<
  T extends { primary?: CloudChoice; fallbacks?: CloudChoice[]; cheap?: CloudChoice },
>(
  policy: T,
  liveCredentialIds: ReadonlySet<string>,
  shared: CloudChoice | null,
): {
  policy: T;
  changed: boolean;
} {
  if (!shared) return { policy, changed: false };
  const live = (c: CloudChoice | undefined) =>
    !c || c.credential_id === shared.credential_id || liveCredentialIds.has(c.credential_id);
  let changed = false;
  const keep = (c: CloudChoice | undefined): CloudChoice | undefined => {
    if (!c || live(c)) return c;
    changed = true;
    return { credential_id: shared.credential_id, model: shared.model };
  };
  const primary = policy.primary ? keep(policy.primary) : undefined;
  const hadNoPrimary = !policy.primary;
  const nextPrimary = primary ?? shared;
  if (hadNoPrimary) changed = true;
  const fallbacks = policy.fallbacks?.flatMap((c) => {
    const kept = keep(c);
    return kept ? [kept] : [];
  });
  return {
    policy: { ...policy, primary: nextPrimary, cheap: keep(policy.cheap), fallbacks },
    changed,
  };
}

/**
 * Every choice that uses the server's shared key runs [model] (the deployment's model) at the
 * server's reasoning level, on Casama Cloud and on self-hosted servers alike. A workspace's own
 * key is left as the user set it.
 */
export function lockCloudPolicy<
  T extends { primary?: CloudChoice; fallbacks?: CloudChoice[]; cheap?: CloudChoice },
>(policy: T, model = CLOUD_LOCKED_MODEL): T {
  const lock = <C extends CloudChoice>(c: C | undefined): C | undefined => {
    if (c?.credential_id !== PLATFORM_OPENROUTER_CREDENTIAL_ID) return c;
    const { reasoning_effort: _ignored, ...rest } = c as C & { reasoning_effort?: unknown };
    return { ...rest, model } as C;
  };
  return {
    ...policy,
    primary: lock(policy.primary),
    cheap: lock(policy.cheap),
    fallbacks: policy.fallbacks?.map((c) => lock(c)!),
  };
}

/**
 * Models a call on the server's shared key may use: only the model the server assigns, on Casama
 * Cloud and self-hosted alike, so nobody can run up the server owner's bill with a pricier model.
 * People who want another model add their own key.
 */
export function cloudModelIds(opts: {
  billing: boolean;
  plan: string | null | undefined;
  /** The model this deployment assigns. */
  locked?: string;
}): readonly string[] {
  return [opts.locked || CLOUD_LOCKED_MODEL];
}

export function cloudModelAllowed(
  opts: { billing: boolean; plan: string | null | undefined; locked?: string },
  model: string,
): boolean {
  return cloudModelIds(opts).includes(model);
}
