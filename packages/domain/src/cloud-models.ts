import { DEFAULT_MODELS, FEATURED_MODELS } from "./models.ts";

/** OpenRouter keeps 5.5% when credits are bought. */
export const OPENROUTER_CREDIT_FEE = 1.055;

/** docs/COSTS.md: charge at least cost × 1.3. */
export const CLOUD_OPENROUTER_MARKUP = 1.3;

/** What a workspace is charged for one OpenRouter call on Casama's key. */
export function cloudOpenRouterCharge(providerCostUsd: number): number {
  return providerCostUsd * OPENROUTER_CREDIT_FEE * CLOUD_OPENROUTER_MARKUP;
}

/** Casama's shared OpenRouter key. Not a row in model_credentials (D-186). */
export const PLATFORM_OPENROUTER_CREDENTIAL_ID = "00000000-0000-4000-8000-0000000000c1";

/** The only model a Casama Cloud workspace runs on Casama's key. */
export const CLOUD_LOCKED_MODEL = DEFAULT_MODELS.openrouter ?? "meta/muse-ember";

/** Output cap on Casama's key. Reasoning models can write past a smaller cap. */
export const CLOUD_MAX_OUTPUT_TOKENS = 4096;

const PAID_DAILY_USD = 10;
const FREE_DAILY_USD = 0.25;

/** How much one workspace may be charged for Casama's key in a UTC day. */
export function cloudModelDailyCap(plan: string | null | undefined): number {
  if (!plan || plan === "free") return FREE_DAILY_USD;
  return PAID_DAILY_USD;
}

type CloudChoice = { credential_id: string; model: string };

/**
 * On Casama Cloud, every choice that uses Casama's key runs [model] (the deployment's model).
 * A workspace's own key is left as the user set it.
 */
export function lockCloudPolicy<
  T extends { primary?: CloudChoice; fallbacks?: CloudChoice[]; cheap?: CloudChoice },
>(policy: T, model = CLOUD_LOCKED_MODEL): T {
  const lock = <C extends CloudChoice>(c: C | undefined): C | undefined =>
    c?.credential_id === PLATFORM_OPENROUTER_CREDENTIAL_ID && c.model !== model
      ? { ...c, model }
      : c;
  return {
    ...policy,
    primary: lock(policy.primary),
    cheap: lock(policy.cheap),
    fallbacks: policy.fallbacks?.map((c) => lock(c)!),
  };
}

/**
 * Models a call on Casama's key may use. Casama Cloud (billing on) runs only the model Casama
 * assigns. A self-hosted server that set the key gets the short recommended list.
 */
export function cloudModelIds(opts: {
  billing: boolean;
  plan: string | null | undefined;
  /** The model this deployment assigns on Casama Cloud. */
  locked?: string;
}): readonly string[] {
  if (opts.billing) return [opts.locked || CLOUD_LOCKED_MODEL];
  return (FEATURED_MODELS.openrouter ?? []).map((m) => m.id);
}

export function cloudModelAllowed(
  opts: { billing: boolean; plan: string | null | undefined; locked?: string },
  model: string,
): boolean {
  return cloudModelIds(opts).includes(model);
}
