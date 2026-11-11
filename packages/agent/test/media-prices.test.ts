/** Media priced per model (D-182). */
import { describe, expect, it } from "vitest";
import { FalMediaProvider, falImageCost, MEDIA_PRICES } from "../src/media.ts";

describe("media prices", () => {
  it("bills fal images per megapixel, rounded up, or per image", () => {
    expect(falImageCost("fal-ai/flux-2/klein/4b", 1024, 1024)).toBeCloseTo(0.005, 6);
    expect(falImageCost("fal-ai/flux-2/klein/4b", 1024, 576)).toBeCloseTo(0.005, 6);
    expect(falImageCost("fal-ai/flux-2/klein/4b", 2048, 2048)).toBeCloseTo(0.02, 6);
    expect(falImageCost("fal-ai/flux/schnell")).toBeCloseTo(0.003, 6);
    expect(falImageCost("fal-ai/bytedance/seedream/v4.5/text-to-image", 4096, 4096)).toBe(0.04);
    // Unknown models are priced high, never low.
    expect(falImageCost("fal-ai/something-new", 1024, 1024)).toBe(MEDIA_PRICES.image);
  });

  it("the default image model is FLUX.2 klein 4B and results carry their price", async () => {
    let path = "";
    const fake = (async (url: string) => {
      path = new URL(url).pathname;
      return Response.json({ images: [{ url: "https://x/i.png", width: 1024, height: 1024 }] });
    }) as unknown as typeof fetch;
    const [img] = await new FalMediaProvider({ apiKey: "k", fetch: fake }).generateImage({
      prompt: "a cloud",
    });
    expect(path).toBe("/fal-ai/flux-2/klein/4b");
    expect(img).toMatchObject({ model: "fal-ai/flux-2/klein/4b" });
    expect(img?.costUsd).toBeCloseTo(0.005, 6);
  });
});
