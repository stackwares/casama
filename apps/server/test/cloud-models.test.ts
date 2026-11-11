/** Casama Cloud's model assignment can be changed by the instance owner without a restart (D-188). */
import { CLOUD_MODEL_DEFAULTS } from "@casama/domain";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { resetCloudModelsCache } from "../src/services/cloud-models.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

describe("cloud models", () => {
  let h: Harness;
  let token: string;
  beforeAll(async () => {
    resetCloudModelsCache();
    h = await startHarness();
    token = (await h.user("cloud-models@example.com")).token;
  }, 60_000);
  afterAll(async () => {
    resetCloudModelsCache();
    await h?.stop();
  });

  it("starts from the built-in defaults and keeps an owner's change", async () => {
    const first = await j(await h.request("/v1/admin/models", { token }));
    expect(first).toMatchObject(CLOUD_MODEL_DEFAULTS);
    const saved = await j(
      await h.request("/v1/admin/models", {
        method: "PUT",
        token,
        json: { ...first, chat: "openai/gpt-6-luna", image_resolution: "2K" },
      }),
    );
    expect(saved.chat).toBe("openai/gpt-6-luna");
    expect(saved.image_resolution).toBe("2K");
    const again = await j(await h.request("/v1/admin/models", { token }));
    expect(again.chat).toBe("openai/gpt-6-luna");
    const stranger = await h.user("cloud-models-stranger@example.com");
    expect((await h.request("/v1/admin/models", { token: stranger.token })).status).toBe(403);
  });
});
