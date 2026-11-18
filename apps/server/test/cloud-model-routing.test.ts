/** Which OpenRouter providers serve the shared key, from the server's settings (D-354). */
import { describe, expect, it } from "vitest";
import { cloudModelChatRouting, cloudModelRouting } from "../src/env.ts";

describe("cloud model routing", () => {
  it("tries the cheapest provider first unless told otherwise", () => {
    expect(cloudModelRouting({ CLOUD_MODEL_PROVIDER_SORT: "price" })).toEqual({ sort: "price" });
  });

  it("puts named providers ahead of the rest, in order", () => {
    expect(
      cloudModelRouting({
        CLOUD_MODEL_PROVIDER_SORT: "price",
        CLOUD_MODEL_PROVIDERS: " wafer, deepinfra/fp8 ,",
      }),
    ).toEqual({ order: ["wafer", "deepinfra/fp8"], sort: "price" });
  });

  it("chats get their own sort only when one is set (D-355)", () => {
    expect(cloudModelChatRouting({})).toBeUndefined();
    expect(cloudModelChatRouting({ CLOUD_MODEL_CHAT_SORT: "throughput" })).toEqual({
      sort: "throughput",
    });
  });

  it("off leaves OpenRouter's own spread, and named providers still go first", () => {
    expect(cloudModelRouting({ CLOUD_MODEL_PROVIDER_SORT: "off" })).toBeUndefined();
    expect(
      cloudModelRouting({ CLOUD_MODEL_PROVIDER_SORT: "off", CLOUD_MODEL_PROVIDERS: "wafer" }),
    ).toEqual({ order: ["wafer"] });
  });
});
