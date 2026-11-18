/** F1: quick answers use Chrome's built-in models when they're downloaded, and hide otherwise. */
import { afterEach, describe, expect, it } from "vitest";
import { quickAnswer, quickKinds } from "../src/lib/ondevice.ts";

const g = globalThis as Record<string, unknown>;
afterEach(() => {
  delete g.LanguageModel;
  delete g.Summarizer;
  delete g.Translator;
});

describe("on-device quick answers", () => {
  it("offers nothing without a model", async () => {
    expect(await quickKinds()).toEqual([]);
  });

  it("offers nothing while the model still has to download", async () => {
    g.LanguageModel = { availability: async () => "downloadable", create: async () => ({}) };
    expect(await quickKinds()).toEqual([]);
  });

  it("answers with the Prompt API when it's there", async () => {
    const prompts: string[] = [];
    g.LanguageModel = {
      availability: async () => "available",
      create: async () => ({
        prompt: async (t: string) => {
          prompts.push(t);
          return "- one\n- two";
        },
        destroy() {},
      }),
    };
    expect(await quickKinds()).toEqual(["summarize", "explain", "translate"]);
    expect(await quickAnswer("explain", "Photosynthesis turns light into sugar.")).toBe(
      "- one\n- two",
    );
    expect(prompts[0]).toMatch(/^Explain this simply/);
    expect(prompts[0]).toContain("Photosynthesis");
  });

  it("prefers the Summarizer for summaries", async () => {
    g.Summarizer = {
      availability: async () => "available",
      create: async () => ({ summarize: async () => "Short.", destroy() {} }),
    };
    expect(await quickKinds()).toEqual(["summarize"]);
    expect(await quickAnswer("summarize", "Long text")).toBe("Short.");
  });
});
