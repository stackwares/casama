import { describe, expect, it } from "vitest";
import { CLOUD_MODEL_DEFAULTS } from "../src/cloud-model-assignment.ts";
import { PLATFORM_OPENROUTER_CREDENTIAL_ID } from "../src/cloud-models.ts";
import type { ModelAccess } from "../src/model-access.ts";
import { resolveModelPolicy } from "../src/resolve-model-policy.ts";

const K_OR = "11111111-1111-4000-8000-111111111111";
const K_OAI = "22222222-2222-4000-8000-222222222222";
const K_CHATGPT_ALICE = "33333333-3333-4000-8000-333333333333";
const USER_ALICE = "aaaaaaaa-aaaa-4000-8000-aaaaaaaaaaaa";
const USER_BOB = "bbbbbbbb-bbbb-4000-8000-bbbbbbbbbbbb";

const ALL_ON: ModelAccess = {
  own_providers: true,
  casama_models: { default: "on", plans: {} },
  note: null,
};

const FREE_OFF: ModelAccess = {
  own_providers: true,
  casama_models: { default: "on", plans: { free: "off" } },
  note: null,
};

const ALL_OFF: ModelAccess = {
  own_providers: true,
  casama_models: { default: "off", plans: {} },
  note: "Casama's models are paused.",
};

describe("resolveModelPolicy", () => {
  it("forces Casama's models when own_providers is false on Cloud", () => {
    const res = resolveModelPolicy({
      billingEnabled: true,
      hasPlatformKey: true,
      planCode: "pro",
      botPolicy: {
        source: "own",
        primary: { credential_id: K_OR, model: "anthropic/claude-sonnet-5.5" },
      },
      credentials: [{ id: K_OR, provider: "openrouter", status: "ok" }],
      access: {
        own_providers: false,
        casama_models: { default: "on", plans: {} },
        note: null,
      },
    });
    expect(res.ok).toBe(true);
    if (!res.ok) return;
    expect(res.onCasamaKey).toBe(true);
    expect(res.policy.primary.credential_id).toBe(PLATFORM_OPENROUTER_CREDENTIAL_ID);
    expect(res.policy.primary.model).toBe(CLOUD_MODEL_DEFAULTS.chat);
  });

  it("follows the three levels: bot choice > workspace default > Casama's models", () => {
    const creds = [
      { id: K_OR, provider: "openrouter", status: "ok" },
      { id: K_OAI, provider: "openai", status: "ok" },
    ];

    // 1. Existing Cloud bot (no source, saved with Casama's key) follows workspace default
    const fromWorkspace = resolveModelPolicy({
      billingEnabled: true,
      hasPlatformKey: true,
      planCode: "pro",
      botPolicy: {
        primary: {
          credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID,
          model: CLOUD_MODEL_DEFAULTS.chat,
        },
      },
      workspaceDefault: {
        source: "own",
        credential_id: K_OR,
        model: "anthropic/claude-sonnet-5.5",
      },
      credentials: creds,
      access: ALL_ON,
    });
    expect(fromWorkspace.ok).toBe(true);
    if (fromWorkspace.ok) {
      expect(fromWorkspace.resolvedFrom).toBe("workspace");
      expect(fromWorkspace.onCasamaKey).toBe(false);
      expect(fromWorkspace.policy.primary).toEqual({
        credential_id: K_OR,
        model: "anthropic/claude-sonnet-5.5",
      });
    }

    // 2. Bot with its own choice overrides workspace default
    const fromBotOwn = resolveModelPolicy({
      billingEnabled: true,
      hasPlatformKey: true,
      planCode: "pro",
      botPolicy: {
        source: "own",
        primary: { credential_id: K_OAI, model: "gpt-6.1-sol" },
      },
      workspaceDefault: {
        source: "own",
        credential_id: K_OR,
        model: "anthropic/claude-sonnet-5.5",
      },
      credentials: creds,
      access: ALL_ON,
    });
    expect(fromBotOwn.ok).toBe(true);
    if (fromBotOwn.ok) {
      expect(fromBotOwn.resolvedFrom).toBe("bot");
      expect(fromBotOwn.onCasamaKey).toBe(false);
      expect(fromBotOwn.policy.primary).toEqual({
        credential_id: K_OAI,
        model: "gpt-6.1-sol",
      });
    }

    // 3. Bot explicitly set to "casama" overrides an own-key workspace default
    const fromBotCasama = resolveModelPolicy({
      billingEnabled: true,
      hasPlatformKey: true,
      planCode: "pro",
      botPolicy: {
        source: "casama",
        primary: {
          credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID,
          model: "openai/gpt-6.1-terra",
        },
      },
      workspaceDefault: {
        source: "own",
        credential_id: K_OR,
        model: "anthropic/claude-sonnet-5.5",
      },
      credentials: creds,
      access: ALL_ON,
    });
    expect(fromBotCasama.ok).toBe(true);
    if (fromBotCasama.ok) {
      expect(fromBotCasama.resolvedFrom).toBe("bot");
      expect(fromBotCasama.onCasamaKey).toBe(true);
      // Still locked to Casama's assigned chat model on Casama's key (D-188)
      expect(fromBotCasama.policy.primary.model).toBe(CLOUD_MODEL_DEFAULTS.chat);
    }

    // 4. Neither bot nor workspace set: falls back to Casama's models
    const fromCasama = resolveModelPolicy({
      billingEnabled: true,
      hasPlatformKey: true,
      planCode: "pro",
      botPolicy: {},
      workspaceDefault: null,
      credentials: creds,
      access: ALL_ON,
    });
    expect(fromCasama.ok).toBe(true);
    if (fromCasama.ok) {
      expect(fromCasama.resolvedFrom).toBe("casama");
      expect(fromCasama.onCasamaKey).toBe(true);
    }
  });

  it("uses automatic pick when Casama's models are off and no default was chosen", () => {
    const res = resolveModelPolicy({
      billingEnabled: true,
      hasPlatformKey: true,
      planCode: "free",
      botPolicy: {
        primary: {
          credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID,
          model: CLOUD_MODEL_DEFAULTS.chat,
        },
      },
      workspaceDefault: null,
      credentials: [
        { id: "99999999-9999-4000-8000-999999999999", provider: "google_maps", status: "ok" },
        { id: K_OAI, provider: "openai", status: "ok" },
      ],
      access: FREE_OFF,
    });
    expect(res.ok).toBe(true);
    if (!res.ok) return;
    expect(res.resolvedFrom).toBe("auto");
    expect(res.onCasamaKey).toBe(false);
    expect(res.policy.primary).toEqual({
      credential_id: K_OAI,
      model: "gpt-6-luna",
    });
  });

  it("refuses with own_provider_required when Casama's models are off and workspace has no chat key", () => {
    const res = resolveModelPolicy({
      billingEnabled: true,
      hasPlatformKey: true,
      planCode: "free",
      botPolicy: {},
      workspaceDefault: null,
      credentials: [],
      access: FREE_OFF,
    });
    expect(res.ok).toBe(false);
    if (res.ok) return;
    expect(res.code).toBe("own_provider_required");
    expect(res.actions).toEqual(["connect", "upgrade"]);
  });

  it("enforces the ChatGPT plan personal owner rule and falls down to the next level", () => {
    const creds = [
      {
        id: K_CHATGPT_ALICE,
        provider: "chatgpt",
        owner_user_id: USER_ALICE,
        status: "ok",
      },
      { id: K_OR, provider: "openrouter", status: "ok" },
    ];

    // Alice runs a bot using Alice's ChatGPT plan -> succeeds on ChatGPT plan
    const aliceRun = resolveModelPolicy({
      billingEnabled: true,
      hasPlatformKey: true,
      planCode: "pro",
      botPolicy: {
        source: "own",
        primary: { credential_id: K_CHATGPT_ALICE, model: "gpt-6.1-sol" },
      },
      workspaceDefault: {
        source: "own",
        credential_id: K_OR,
        model: "deepseek/deepseek-v4.1-flash-1017",
      },
      credentials: creds,
      actingUserId: USER_ALICE,
      access: ALL_ON,
    });
    expect(aliceRun.ok).toBe(true);
    if (aliceRun.ok) {
      expect(aliceRun.policy.primary.credential_id).toBe(K_CHATGPT_ALICE);
    }

    // Bob runs the same bot -> moves down to workspace default (OpenRouter key)
    const bobRun = resolveModelPolicy({
      billingEnabled: true,
      hasPlatformKey: true,
      planCode: "pro",
      botPolicy: {
        source: "own",
        primary: { credential_id: K_CHATGPT_ALICE, model: "gpt-6.1-sol" },
      },
      workspaceDefault: {
        source: "own",
        credential_id: K_OR,
        model: "deepseek/deepseek-v4.1-flash-1017",
      },
      credentials: creds,
      actingUserId: USER_BOB,
      access: ALL_ON,
    });
    expect(bobRun.ok).toBe(true);
    if (bobRun.ok) {
      expect(bobRun.resolvedFrom).toBe("workspace");
      expect(bobRun.policy.primary.credential_id).toBe(K_OR);
    }

    // Bob runs when Casama's models are off and only Alice's ChatGPT plan exists -> chatgpt_plan_not_yours
    const bobOnlyAlicePlan = resolveModelPolicy({
      billingEnabled: true,
      hasPlatformKey: true,
      planCode: "pro",
      botPolicy: {},
      workspaceDefault: {
        source: "own",
        credential_id: K_CHATGPT_ALICE,
        model: "gpt-6.1-sol",
      },
      credentials: [
        {
          id: K_CHATGPT_ALICE,
          provider: "chatgpt",
          owner_user_id: USER_ALICE,
          status: "ok",
        },
      ],
      actingUserId: USER_BOB,
      access: ALL_OFF,
    });
    expect(bobOnlyAlicePlan.ok).toBe(false);
    if (!bobOnlyAlicePlan.ok) {
      expect(bobOnlyAlicePlan.code).toBe("chatgpt_plan_not_yours");
    }
  });

  it("only adds Casama's model as fallback when fallback_on_limit is true and Casama's models are allowed", () => {
    // fallback_on_limit is false -> no fallback to Casama
    const withoutFallback = resolveModelPolicy({
      billingEnabled: true,
      hasPlatformKey: true,
      planCode: "pro",
      botPolicy: {
        source: "own",
        primary: { credential_id: K_OR, model: "anthropic/claude-sonnet-5.5" },
      },
      credentials: [{ id: K_OR, provider: "openrouter", status: "ok", fallback_on_limit: false }],
      access: ALL_ON,
    });
    expect(withoutFallback.ok).toBe(true);
    if (withoutFallback.ok) {
      expect(withoutFallback.policy.fallbacks).toBeUndefined();
    }

    // fallback_on_limit is true and Casama's models are on -> appends Casama's model
    const withFallback = resolveModelPolicy({
      billingEnabled: true,
      hasPlatformKey: true,
      planCode: "pro",
      botPolicy: {
        source: "own",
        primary: { credential_id: K_OR, model: "anthropic/claude-sonnet-5.5" },
      },
      credentials: [{ id: K_OR, provider: "openrouter", status: "ok", fallback_on_limit: true }],
      access: ALL_ON,
    });
    expect(withFallback.ok).toBe(true);
    if (withFallback.ok) {
      expect(withFallback.policy.fallbacks).toEqual([
        {
          credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID,
          model: CLOUD_MODEL_DEFAULTS.chat,
        },
      ]);
    }

    // fallback_on_limit is true but Casama's models are off -> no fallback to Casama
    const withFallbackWhenOff = resolveModelPolicy({
      billingEnabled: true,
      hasPlatformKey: true,
      planCode: "pro",
      botPolicy: {
        source: "own",
        primary: { credential_id: K_OR, model: "anthropic/claude-sonnet-5.5" },
      },
      credentials: [{ id: K_OR, provider: "openrouter", status: "ok", fallback_on_limit: true }],
      access: ALL_OFF,
    });
    expect(withFallbackWhenOff.ok).toBe(true);
    if (withFallbackWhenOff.ok) {
      expect(withFallbackWhenOff.policy.fallbacks).toBeUndefined();
    }
  });
});
