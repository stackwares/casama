/**
 * Where a run's model comes from (docs/OWN-KEYS-PLAN.md §3.1, §3.2, §6).
 *
 * Three levels, first match wins:
 * 1. The bot's own choice (`model_policy.source`: `"own"` or `"casama"`, or an explicit own key).
 * 2. The workspace default (`organizations.model_default`: `"own"` or `"casama"`).
 * 3. Casama's models (if `casamaModelsAllowed(planCode)` and the server has its shared key), else
 *    the automatic pick (first usable chat key in the workspace with that provider's default model
 *    from the catalog).
 *
 * A personal ChatGPT plan (`provider === "chatgpt"`) only runs for its owner (`owner_user_id ===
 * actingUserId`). When someone else starts the run, resolution moves to the next level down; if no
 * other level has a usable model, `chatgpt_plan_not_yours` is returned so the caller sees why.
 */

import {
  CLOUD_MODEL_DEFAULTS,
  type CloudModelAssignment,
  cloudRunPolicy,
} from "./cloud-model-assignment.ts";
import {
  CLOUD_LOCKED_MODEL,
  lockCloudPolicy,
  PLATFORM_OPENROUTER_CREDENTIAL_ID,
  useSharedKeyForMissing,
} from "./cloud-models.ts";
import { KEY_PROVIDERS } from "./key-providers.ts";
import {
  casamaModelsAllowed,
  type ModelAccess,
  modelAccess,
  type OwnProviderRequiredDetails,
  ownProviderRequiredError,
  ownProvidersAllowed,
} from "./model-access.ts";
import { defaultModelFor, featuredModelsFor, smallModelFor } from "./model-catalog.ts";
import type { ReasoningEffort } from "./models.ts";

export type BotModelSource = "workspace" | "casama" | "own";

export interface PolicyModelChoice {
  credential_id: string;
  model: string;
  temperature?: number;
  max_tokens?: number;
  reasoning_effort?: ReasoningEffort;
}

export interface BotModelPolicy {
  source?: BotModelSource;
  primary?: PolicyModelChoice;
  cheap?: PolicyModelChoice;
  fallbacks?: PolicyModelChoice[];
}

export interface WorkspaceModelDefault {
  source: "casama" | "own";
  credential_id?: string | null;
  model?: string | null;
  cheap_model?: string | null;
}

export interface ResolveCredentialRow {
  id: string;
  provider: string;
  owner_user_id?: string | null;
  status?: string | null;
  fallback_on_limit?: boolean;
}

export interface ResolveModelPolicyInput {
  /** True on Casama Cloud (`BILLING_ENABLED`). */
  billingEnabled: boolean;
  /** True when the server has `CLOUD_MODEL_UPSTREAM_KEY` configured. */
  hasPlatformKey: boolean;
  /** The workspace's current billing plan code (`"free"`, `"starter"`, `"pro"`, `"max"`). */
  planCode?: string | null;
  /** Casama Cloud's assigned models (Admin → Cloud models). */
  assigned?: CloudModelAssignment | null;
  /** Self-hosted locked model for the shared key (`DEFAULT_MODEL_OPENROUTER`). */
  cloudLockedModel?: string;
  /** The bot's stored `model_policy`. */
  botPolicy?: BotModelPolicy | null;
  /** The workspace's stored `organizations.model_default`. */
  workspaceDefault?: WorkspaceModelDefault | null;
  /** The workspace's live credentials from `public.model_credentials`. */
  credentials?: readonly ResolveCredentialRow[];
  /** The user starting the run or routine (for the personal ChatGPT plan owner rule). */
  actingUserId?: string | null;
  /** Optional environment overrides for default models (`DEFAULT_MODEL_OPENROUTER`, etc.). */
  modelOverrides?: Partial<Record<string, string | undefined>>;
  /** Optional explicit `ModelAccess` for testing; defaults to the process-wide `modelAccess()`. */
  access?: ModelAccess;
}

export type ResolveModelPolicyResult =
  | {
      ok: true;
      policy: BotModelPolicy & { primary: PolicyModelChoice };
      /** Whether the primary model runs on Casama's shared OpenRouter key. */
      onCasamaKey: boolean;
      /** Which level won. */
      resolvedFrom: "bot" | "workspace" | "casama" | "auto";
    }
  | ({
      ok: false;
    } & (
      | OwnProviderRequiredDetails
      | {
          code: "chatgpt_plan_not_yours";
          message: string;
          note: null;
          actions: Array<"connect">;
        }
    ));

const CHAT_SET = new Set<string>([...KEY_PROVIDERS.runs_chat, "chatgpt"]);

/** Default model for a credential when none was specified. */
export function defaultModelForProvider(
  provider: string,
  overrides: Partial<Record<string, string | undefined>> = {},
): string {
  return (
    defaultModelFor(provider, overrides) ??
    smallModelFor(provider) ??
    featuredModelsFor(provider)[0]?.id ??
    DEFAULT_MODEL_FALLBACK
  );
}

const DEFAULT_MODEL_FALLBACK = "deepseek/deepseek-v4.1-flash-1017";

/**
 * Checks whether a workspace credential can run chat for `actingUserId`.
 */
function checkCredential(
  cred: ResolveCredentialRow | undefined,
  actingUserId: string | null | undefined,
): { ok: true; cred: ResolveCredentialRow } | { ok: false; reason: "missing" | "not_yours" } {
  if (!cred || !CHAT_SET.has(cred.provider)) return { ok: false, reason: "missing" };
  if (cred.status && cred.status !== "ok") return { ok: false, reason: "missing" };
  if (cred.provider === "chatgpt") {
    // When actingUserId is known (run time), enforce the personal owner rule.
    // When actingUserId is undefined (saving a bot or workspace default), allow it if status is ok.
    if (actingUserId !== undefined && (!actingUserId || cred.owner_user_id !== actingUserId)) {
      return { ok: false, reason: "not_yours" };
    }
  }
  return { ok: true, cred };
}

/**
 * Resolves the effective `ModelPolicy` for a run, background completion, check-in verdict, or bot
 * creation/update.
 */
export function resolveModelPolicy(input: ResolveModelPolicyInput): ResolveModelPolicyResult {
  const access = input.access ?? modelAccess();
  const assigned = input.assigned ?? CLOUD_MODEL_DEFAULTS;
  const lockedModel = input.billingEnabled
    ? assigned.chat
    : (input.cloudLockedModel ?? CLOUD_LOCKED_MODEL);
  const creds = input.credentials ?? [];
  const byId = new Map(creds.map((c) => [c.id, c]));
  const casamaAllowed =
    input.hasPlatformKey && casamaModelsAllowed(input.planCode, input.billingEnabled, access);
  const ownAllowed = ownProvidersAllowed(input.billingEnabled, access);
  const rawBot: BotModelPolicy = input.botPolicy ?? {};

  const casamaPolicy = (): BotModelPolicy & { primary: PolicyModelChoice } => {
    if (input.billingEnabled) {
      return {
        ...(rawBot.source ? { source: rawBot.source } : {}),
        ...cloudRunPolicy(assigned),
      };
    }
    return {
      ...(rawBot.source ? { source: rawBot.source } : {}),
      primary: { credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID, model: lockedModel },
    };
  };

  // Build an own-key policy, appending Casama's model as fallback only when fallback_on_limit is on
  // and Casama's models are allowed for this workspace's plan (§3.2).
  const buildOwnPolicy = (
    cred: ResolveCredentialRow,
    primaryChoice: PolicyModelChoice,
    cheapChoice: PolicyModelChoice | undefined,
    extraFallbacks: PolicyModelChoice[] | undefined,
    source?: BotModelSource,
  ): BotModelPolicy & { primary: PolicyModelChoice } => {
    const keptFallbacks = (extraFallbacks ?? []).filter((f) => {
      if (f.credential_id === PLATFORM_OPENROUTER_CREDENTIAL_ID) {
        return Boolean(cred.fallback_on_limit && casamaAllowed);
      }
      const fc = checkCredential(byId.get(f.credential_id), input.actingUserId);
      return fc.ok;
    });
    const fallbacks = [...keptFallbacks];
    if (
      cred.fallback_on_limit &&
      casamaAllowed &&
      !fallbacks.some((f) => f.credential_id === PLATFORM_OPENROUTER_CREDENTIAL_ID)
    ) {
      fallbacks.push({
        credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID,
        model: lockedModel,
      });
    }
    const cheap =
      cheapChoice &&
      (cheapChoice.credential_id === cred.id ||
        checkCredential(byId.get(cheapChoice.credential_id), input.actingUserId).ok)
        ? cheapChoice
        : undefined;
    return lockCloudPolicy(
      {
        ...(source ? { source } : {}),
        primary: primaryChoice,
        ...(cheap ? { cheap } : {}),
        ...(fallbacks.length ? { fallbacks } : {}),
      },
      lockedModel,
    ) as BotModelPolicy & { primary: PolicyModelChoice };
  };

  // --- Self-hosted (`!billingEnabled`) -----------------------------------------------------------
  if (!input.billingEnabled) {
    // If the bot explicitly follows the workspace default and one is set, honor it.
    if (
      (rawBot.source === "workspace" || !rawBot.primary) &&
      input.workspaceDefault?.source === "own" &&
      input.workspaceDefault.credential_id
    ) {
      const check = checkCredential(
        byId.get(input.workspaceDefault.credential_id),
        input.actingUserId,
      );
      if (check.ok) {
        const model =
          input.workspaceDefault.model?.trim() ||
          defaultModelForProvider(check.cred.provider, input.modelOverrides);
        const cheap = input.workspaceDefault.cheap_model?.trim()
          ? { credential_id: check.cred.id, model: input.workspaceDefault.cheap_model.trim() }
          : undefined;
        return {
          ok: true,
          policy: buildOwnPolicy(
            check.cred,
            { credential_id: check.cred.id, model },
            cheap,
            undefined,
            rawBot.source,
          ),
          onCasamaKey: false,
          resolvedFrom: "workspace",
        };
      }
    }
    const liveIds = new Set(creds.map((c) => c.id));
    const shared = input.hasPlatformKey
      ? { credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID, model: lockedModel }
      : null;
    const { policy: healed } = useSharedKeyForMissing(rawBot, liveIds, shared);
    const locked = lockCloudPolicy(healed, lockedModel);
    if (locked.primary) {
      // Check personal ChatGPT owner rule if primary is a ChatGPT plan
      const primaryCred = byId.get(locked.primary.credential_id);
      if (primaryCred?.provider === "chatgpt") {
        const check = checkCredential(primaryCred, input.actingUserId);
        if (!check.ok && check.reason === "not_yours") {
          if (shared) {
            return {
              ok: true,
              policy: casamaPolicy(),
              onCasamaKey: true,
              resolvedFrom: "casama",
            };
          }
          return {
            ok: false,
            code: "chatgpt_plan_not_yours",
            message:
              "This bot uses a teammate's personal ChatGPT plan. Connect your own ChatGPT plan or add an API key in Settings.",
            note: null,
            actions: ["connect"],
          };
        }
      }
      const onCasama = locked.primary.credential_id === PLATFORM_OPENROUTER_CREDENTIAL_ID;
      return {
        ok: true,
        policy: locked as BotModelPolicy & { primary: PolicyModelChoice },
        onCasamaKey: onCasama,
        resolvedFrom: onCasama ? "casama" : "bot",
      };
    }
    if (shared) {
      return {
        ok: true,
        policy: casamaPolicy(),
        onCasamaKey: true,
        resolvedFrom: "casama",
      };
    }
    return {
      ok: false,
      ...ownProviderRequiredError({ planCode: input.planCode, access }),
    };
  }

  // --- Casama Cloud (`billingEnabled`) -----------------------------------------------------------

  // When `own_providers` is off, only Casama's models can run.
  if (!ownAllowed) {
    if (casamaAllowed) {
      return {
        ok: true,
        policy: casamaPolicy(),
        onCasamaKey: true,
        resolvedFrom: "casama",
      };
    }
    return {
      ok: false,
      ...ownProviderRequiredError({ planCode: input.planCode, access }),
    };
  }

  let sawChatGptNotYours = false;

  // Level 1: The bot's own choice (§3.1).
  // Existing Cloud bots have Casama's key saved and no `source`, so they follow the workspace.
  // A bot with `source: "own"` (or no `source` and a non-Casama `primary.credential_id`, e.g. from
  // a shipped app or API call) uses that key; a bot with `source: "casama"` explicitly asks for
  // Casama's models.
  const botEffectiveSource: BotModelSource =
    rawBot.source ??
    (rawBot.primary?.credential_id &&
    rawBot.primary.credential_id !== PLATFORM_OPENROUTER_CREDENTIAL_ID
      ? "own"
      : "workspace");

  if (botEffectiveSource === "casama") {
    if (casamaAllowed) {
      return {
        ok: true,
        policy: { ...casamaPolicy(), source: "casama" },
        onCasamaKey: true,
        resolvedFrom: "bot",
      };
    }
    // If Casama's models are turned off, fall through to workspace default / automatic pick so a
    // workspace that connected a key keeps running (§2 Principle 4).
  } else if (botEffectiveSource === "own" && rawBot.primary?.credential_id) {
    const check = checkCredential(byId.get(rawBot.primary.credential_id), input.actingUserId);
    if (check.ok) {
      const model =
        rawBot.primary.model?.trim() ||
        defaultModelForProvider(check.cred.provider, input.modelOverrides);
      return {
        ok: true,
        policy: buildOwnPolicy(
          check.cred,
          { ...rawBot.primary, credential_id: check.cred.id, model },
          rawBot.cheap,
          rawBot.fallbacks,
          rawBot.source ?? "own",
        ),
        onCasamaKey: false,
        resolvedFrom: "bot",
      };
    }
    if (check.reason === "not_yours") sawChatGptNotYours = true;
    // Key was deleted or belongs to another user's ChatGPT plan: move to level 2.
  }

  // Level 2: The workspace default (§3.1).
  const ws = input.workspaceDefault;
  if (ws?.source === "casama") {
    if (casamaAllowed) {
      return {
        ok: true,
        policy: casamaPolicy(),
        onCasamaKey: true,
        resolvedFrom: "workspace",
      };
    }
  } else if (ws?.source === "own" && ws.credential_id) {
    const check = checkCredential(byId.get(ws.credential_id), input.actingUserId);
    if (check.ok) {
      const model =
        ws.model?.trim() || defaultModelForProvider(check.cred.provider, input.modelOverrides);
      const cheap = ws.cheap_model?.trim()
        ? { credential_id: check.cred.id, model: ws.cheap_model.trim() }
        : undefined;
      return {
        ok: true,
        policy: buildOwnPolicy(
          check.cred,
          { credential_id: check.cred.id, model },
          cheap,
          undefined,
          rawBot.source,
        ),
        onCasamaKey: false,
        resolvedFrom: "workspace",
      };
    }
    if (check.reason === "not_yours") sawChatGptNotYours = true;
  }

  // Level 3: Casama's models, if allowed for the plan (§3.1, §3.3).
  if (casamaAllowed) {
    return {
      ok: true,
      policy: casamaPolicy(),
      onCasamaKey: true,
      resolvedFrom: "casama",
    };
  }

  // Automatic pick (§3.1): when Casama's models are off for the workspace and nobody chose a
  // usable default, pick the workspace's first usable chat key with that provider's default model.
  for (const cred of creds) {
    const check = checkCredential(cred, input.actingUserId);
    if (check.ok) {
      const model = defaultModelForProvider(check.cred.provider, input.modelOverrides);
      return {
        ok: true,
        policy: buildOwnPolicy(
          check.cred,
          { credential_id: check.cred.id, model },
          undefined,
          undefined,
          rawBot.source,
        ),
        onCasamaKey: false,
        resolvedFrom: "auto",
      };
    }
    if (check.reason === "not_yours") sawChatGptNotYours = true;
  }

  if (sawChatGptNotYours) {
    return {
      ok: false,
      code: "chatgpt_plan_not_yours",
      message:
        "This workspace's ChatGPT plan belongs to a teammate. Connect your own ChatGPT plan or add an API key in Settings.",
      note: null,
      actions: ["connect"],
    };
  }

  return {
    ok: false,
    ...ownProviderRequiredError({ planCode: input.planCode, access }),
  };
}
