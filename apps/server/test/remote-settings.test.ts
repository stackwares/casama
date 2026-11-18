/**
 * Models, prices and guard sites from Admin (D-373, D-374): saved, checked on save, loaded by every
 * process, and the code's values whenever nothing is saved.
 */
import { capabilitiesOf, voicePrices } from "@casama/agent";
import {
  defaultModelFor,
  sensitiveSiteKind,
  setCostTables,
  setModelCatalog,
  setSensitiveSiteAdditions,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { loadRemoteSettings } from "../src/services/remote-settings.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

describe("remote settings in Admin", () => {
  let h: Harness;
  let token: string;
  const reset = () => {
    setModelCatalog(undefined);
    setCostTables(undefined);
    setSensitiveSiteAdditions(undefined);
  };
  beforeAll(async () => {
    reset();
    h = await startHarness();
    token = (await h.user("remote-settings-owner@example.com")).token;
  }, 60_000);
  afterAll(async () => {
    reset();
    await h?.stop();
  });

  it("model catalog: starts empty with the code's values, refuses a bad save, applies a good one", async () => {
    const first = await j(await h.request("/v1/admin/model-catalog", { token }));
    expect(first.catalog).toEqual({});
    expect(first.built_in.default_models.openrouter).toBe("deepseek/deepseek-v4.1-flash-1017");
    expect(first.built_in.image_prices["google/gemini-nano-banana-2.1"]).toBe(0.0336);

    const bad = await h.request("/v1/admin/model-catalog", {
      method: "PUT",
      token,
      json: { catalog: { models: [{ id: "x/y", input_price: 20000, output_price: 1 }] } },
    });
    expect(bad.status).toBe(400);
    expect((await j(bad)).detail).toMatch(/input_price/);

    const saved = await j(
      await h.request("/v1/admin/model-catalog", {
        method: "PUT",
        token,
        json: {
          catalog: {
            default_models: { openrouter: "z-ai/glm-5.3" },
            models: [{ id: "z-ai/glm-5.3", input_price: 0.3, output_price: 1.2 }],
          },
        },
      }),
    );
    expect(saved.catalog.default_models).toEqual({ openrouter: "z-ai/glm-5.3" });
    // This process applied it at once; another one picks it up on its next load.
    expect(defaultModelFor("openrouter")).toBe("z-ai/glm-5.3");
    setModelCatalog(undefined);
    expect(capabilitiesOf("z-ai/glm-5.3").inputPrice).toBe(1);
    await loadRemoteSettings(h.handle.db);
    expect(capabilitiesOf("z-ai/glm-5.3").inputPrice).toBe(0.3);
    // The apps get the new default model.
    const config = await j(await h.request("/v1/config"));
    expect(config.default_models.openrouter).toBe("z-ai/glm-5.3");
    expect(config.key_providers.chat).toContain("openrouter");

    const stranger = await h.user("remote-settings-stranger@example.com");
    expect((await h.request("/v1/admin/model-catalog", { token: stranger.token })).status).toBe(
      403,
    );
    // Back to the code's values.
    await h.request("/v1/admin/model-catalog", { method: "PUT", token, json: { catalog: {} } });
    expect(defaultModelFor("openrouter")).toBe("deepseek/deepseek-v4.1-flash-1017");
  });

  it("price tables: cost overrides and domain sale settings, env var as the fallback", async () => {
    const first = await j(await h.request("/v1/admin/price-tables", { token }));
    expect(first.cost_tables).toEqual({});
    expect(first.built_in.voice.stt_per_minute).toBe(0.0002);
    expect(first.domain_tlds_saved).toBe(false);
    expect(first.domain_tlds).toContain("com");
    expect([first.domain_cap_first_month, first.domain_cap_per_month]).toEqual([3, 10]);

    const bad = await h.request("/v1/admin/price-tables", {
      method: "PUT",
      token,
      json: { cost_tables: { voice: { stt_per_minute: 99 } }, domain_tlds: ["c om"] },
    });
    expect(bad.status).toBe(400);
    expect((await j(bad)).detail).toMatch(/stt_per_minute.*c om|c om.*stt_per_minute/);

    const saved = await j(
      await h.request("/v1/admin/price-tables", {
        method: "PUT",
        token,
        json: {
          cost_tables: { voice: { stt_per_minute: 0.0004 } },
          domain_tlds: [".COM", "co.uk"],
          domain_cap_first_month: 2,
        },
      }),
    );
    expect(saved.cost_tables).toEqual({ voice: { stt_per_minute: 0.0004 } });
    expect(saved.domain_tlds).toEqual(["com", "co.uk"]);
    expect(saved.domain_tlds_saved).toBe(true);
    expect([saved.domain_cap_first_month, saved.domain_cap_per_month]).toEqual([2, 10]);
    expect(voicePrices().sttPerMinute).toBe(0.0004);

    // null goes back to the env var or the code's list; caps left out keep their value.
    const back = await j(
      await h.request("/v1/admin/price-tables", {
        method: "PUT",
        token,
        json: { domain_tlds: null, cost_tables: {} },
      }),
    );
    expect(back.domain_tlds_saved).toBe(false);
    expect(back.domain_cap_first_month).toBe(2);
    expect(voicePrices().sttPerMinute).toBe(0.0002);
    await h.handle.db.execute(
      sql`update public.billing_settings set domain_cap_first_month = 3 where id`,
    );
  });

  it("browser guard: public added sites, add-only, checked on save", async () => {
    expect(await j(await h.request("/v1/browser-guard"))).toEqual({
      hosts: { passwords: [], banking: [], health: [], government: [] },
    });
    const bad = await h.request("/v1/admin/browser-guard", {
      method: "PUT",
      token,
      json: { hosts: { banking: ["not a host"], crypto: ["x.example"] } },
    });
    expect(bad.status).toBe(400);
    const saved = await j(
      await h.request("/v1/admin/browser-guard", {
        method: "PUT",
        token,
        json: { hosts: { banking: ["MyBank.example"] } },
      }),
    );
    expect(saved.hosts.banking).toEqual(["mybank.example"]);
    expect(saved.built_in.banking).toContain("paypal.com");
    expect((await j(await h.request("/v1/browser-guard"))).hosts.banking).toEqual([
      "mybank.example",
    ]);
    expect(sensitiveSiteKind("mybank.example")).toBe("banking");
    // Saving an empty list removes only what was added.
    await h.request("/v1/admin/browser-guard", { method: "PUT", token, json: { hosts: {} } });
    expect(sensitiveSiteKind("mybank.example")).toBeNull();
    expect(sensitiveSiteKind("paypal.com")).toBe("banking");
  });
});
