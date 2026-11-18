import { describe, expect, it } from "vitest";
import { loadEnv, voiceContext } from "../src/env.ts";

/** When a live call's context is trimmed is a server setting (docs/USAGE-PLAN.md step 6). */
describe("VOICE_CONTEXT_TRIGGER_TOKENS and VOICE_CONTEXT_TARGET_TOKENS", () => {
  const base = {
    DATABASE_URL: "postgres://x",
    SUPABASE_URL: "https://sb.example.com",
    SUPABASE_ANON_KEY: "anon",
  };

  it("default to 8,000 and 3,000", () => {
    expect(voiceContext(loadEnv(base))).toEqual({ triggerTokens: 8000, targetTokens: 3000 });
    // Compose writes KEY= for unset settings.
    expect(
      voiceContext(
        loadEnv({ ...base, VOICE_CONTEXT_TRIGGER_TOKENS: "", VOICE_CONTEXT_TARGET_TOKENS: "" }),
      ),
    ).toEqual({ triggerTokens: 8000, targetTokens: 3000 });
  });

  it("take a server's own numbers", () => {
    const env = loadEnv({
      ...base,
      VOICE_CONTEXT_TRIGGER_TOKENS: "32000",
      VOICE_CONTEXT_TARGET_TOKENS: "16000",
    });
    expect(voiceContext(env)).toEqual({ triggerTokens: 32000, targetTokens: 16000 });
    // One alone is fine while the pair still makes sense.
    expect(voiceContext(loadEnv({ ...base, VOICE_CONTEXT_TARGET_TOKENS: "1000" }))).toEqual({
      triggerTokens: 8000,
      targetTokens: 1000,
    });
  });

  it("refuse a target that isn't below the trigger", () => {
    for (const [trigger, target] of [
      ["8000", "8000"],
      ["4000", "6000"],
    ])
      expect(() =>
        loadEnv({
          ...base,
          VOICE_CONTEXT_TRIGGER_TOKENS: trigger,
          VOICE_CONTEXT_TARGET_TOKENS: target,
        }),
      ).toThrow(/VOICE_CONTEXT_TARGET_TOKENS: must be below VOICE_CONTEXT_TRIGGER_TOKENS/);
    // The default target (3,000) against a lower trigger, and the default trigger against a
    // higher target.
    expect(() => loadEnv({ ...base, VOICE_CONTEXT_TRIGGER_TOKENS: "2000" })).toThrow(
      /VOICE_CONTEXT_TARGET_TOKENS/,
    );
    expect(() => loadEnv({ ...base, VOICE_CONTEXT_TARGET_TOKENS: "9000" })).toThrow(
      /VOICE_CONTEXT_TARGET_TOKENS/,
    );
  });

  it("refuse numbers under 1,000 and things that aren't whole numbers", () => {
    expect(() => loadEnv({ ...base, VOICE_CONTEXT_TARGET_TOKENS: "999" })).toThrow(
      /VOICE_CONTEXT_TARGET_TOKENS/,
    );
    expect(() =>
      loadEnv({
        ...base,
        VOICE_CONTEXT_TRIGGER_TOKENS: "500",
        VOICE_CONTEXT_TARGET_TOKENS: "1000",
      }),
    ).toThrow(/VOICE_CONTEXT_TRIGGER_TOKENS/);
    expect(() => loadEnv({ ...base, VOICE_CONTEXT_TRIGGER_TOKENS: "8k" })).toThrow(
      /VOICE_CONTEXT_TRIGGER_TOKENS/,
    );
    expect(() => loadEnv({ ...base, VOICE_CONTEXT_TRIGGER_TOKENS: "8000.5" })).toThrow(
      /VOICE_CONTEXT_TRIGGER_TOKENS/,
    );
  });
});
