/** The checks behind Admin's model catalog, cost tables and guard sites (D-373, D-374). */
import { afterEach, describe, expect, it } from "vitest";
import {
  builtInModelCatalog,
  checkCostTables,
  checkGuardAdditions,
  checkModelCatalog,
  KEY_PROVIDERS,
  SENSITIVE_SITE_HOSTS,
  sensitiveSiteKind,
  setSensitiveSiteAdditions,
} from "../src/index.ts";

afterEach(() => setSensitiveSiteAdditions(undefined));

describe("model catalog check", () => {
  it("accepts every part in its shape", () => {
    const { catalog, errors } = checkModelCatalog({
      default_models: { openrouter: "z-ai/glm-5.3" },
      small_models: { anthropic: "claude-haiku-5-5" },
      test_models: { xai: "grok-4.7" },
      featured_models: { openrouter: [{ id: "z-ai/glm-5.3", name: "GLM" }, { id: "a/b" }] },
      models: [
        { id: "Z-AI/GLM-5.3", input_price: 0.3, output_price: 1.2, context_window: 200_000 },
        { pattern: "^qwen/", input_price: 0.2, output_price: 0.6, vision: true },
      ],
      image_prices: { "google/gemini-nano-banana-2.1": 0.04 },
    });
    expect(errors).toEqual([]);
    expect(catalog.models?.[0]?.id).toBe("z-ai/glm-5.3");
    expect(catalog.featured_models?.openrouter?.[1]).toEqual({ id: "a/b", name: "a/b" });
  });

  it("refuses typos, wrong shapes and prices out of range", () => {
    const { errors } = checkModelCatalog({
      defaults: {},
      default_models: { OpenRouter: "x" },
      models: [
        { id: "a", pattern: "b", input_price: 1, output_price: 1 },
        { id: "c", input_price: 15000, output_price: 1 },
        { pattern: "(", input_price: 1, output_price: 1 },
        { id: "d", input_price: 1, output_price: 1, colour: "red" },
      ],
      image_prices: { x: 50 },
    });
    expect(errors.join("\n")).toMatch(/unknown part defaults/);
    expect(errors.join("\n")).toMatch(/OpenRouter isn't a provider id/);
    expect(errors.join("\n")).toMatch(/needs either id or pattern/);
    expect(errors.join("\n")).toMatch(/models\[1\]\.input_price/);
    expect(errors.join("\n")).toMatch(/models\[2\]\.pattern/);
    expect(errors.join("\n")).toMatch(/unknown colour/);
    expect(errors.join("\n")).toMatch(/image_prices\.x/);
  });

  it("an empty setting is valid and the defaults cover the code", () => {
    expect(checkModelCatalog({})).toEqual({ catalog: {}, errors: [] });
    expect(checkModelCatalog(null)).toEqual({ catalog: {}, errors: [] });
    const built = builtInModelCatalog();
    expect(checkModelCatalog(built).errors).toEqual([]);
    expect(built.test_models?.google).toBe("gemini-3.5-flash-lite");
  });
});

describe("cost tables check", () => {
  it("accepts known prices and computer rates", () => {
    const { tables, errors } = checkCostTables({
      voice: { stt_per_minute: 0.0003 },
      gemini_live: { input_audio: 3 },
      computers: {
        docker: { cpu_hour: 0.003, gb_hour: 0.005 },
        "casama-cloud": { cpu_hour: 0.05, gb_hour: 0 },
      },
      media: { image: 0.04 },
    });
    expect(errors).toEqual([]);
    expect(tables.computers?.["casama-cloud"]).toEqual({ cpu_hour: 0.05, gb_hour: 0 });
  });

  it("refuses unknown tables, unknown prices and values out of range", () => {
    const { tables, errors } = checkCostTables({
      phones: {},
      voice: { stt_per_minute: 50, tts: 1 },
      computers: { docker: { cpu_hour: -1, gb_hour: 0 }, Bad: { cpu_hour: 1, gb_hour: 1 } },
      media: { image: Number.NaN },
    });
    expect(errors).toHaveLength(6);
    expect(tables).toEqual({ voice: {}, computers: {}, media: {} });
  });
});

describe("browser guard additions (D-374)", () => {
  it("only adds: a built-in host stays guarded whatever the additions hold", () => {
    setSensitiveSiteAdditions({ banking: ["mybank.example"] });
    expect(sensitiveSiteKind("mybank.example")).toBe("banking");
    expect(sensitiveSiteKind("login.mybank.example")).toBe("banking");
    expect(sensitiveSiteKind("paypal.com")).toBe("banking");
    // An empty list, or one naming built-in hosts, can't take anything off.
    setSensitiveSiteAdditions({ banking: [] });
    expect(sensitiveSiteKind("paypal.com")).toBe("banking");
    expect(sensitiveSiteKind("mybank.example")).toBeNull();
  });

  it("passes additions explicitly (the extension) and leaves the person's choices alone", () => {
    const extra = { health: ["clinic-portal.example"] };
    expect(sensitiveSiteKind("clinic-portal.example", [], extra)).toBe("health");
    expect(sensitiveSiteKind("clinic-portal.example", ["health"], extra)).toBeNull();
  });

  it("checks hosts and kinds; unknown kinds are skipped on load", () => {
    const { hosts, errors } = checkGuardAdditions({
      banking: ["https://www.MyBank.example/login", "not a host", "mybank.example"],
      crypto: ["coin.example"],
    });
    expect(hosts.banking).toEqual(["mybank.example"]);
    expect(errors).toHaveLength(2);
    expect(Object.keys(hosts).sort()).toEqual(Object.keys(SENSITIVE_SITE_HOSTS).sort());
  });
});

describe("key providers (D-374)", () => {
  it("puts every chat provider in the form and nothing twice", () => {
    for (const p of KEY_PROVIDERS.runs_chat)
      expect([...KEY_PROVIDERS.chat, ...KEY_PROVIDERS.more]).toContain(p);
    const all = [...KEY_PROVIDERS.chat, ...KEY_PROVIDERS.more];
    expect(new Set(all).size).toBe(all.length);
    for (const p of KEY_PROVIDERS.cloud) expect(KEY_PROVIDERS.more).toContain(p);
  });
});
