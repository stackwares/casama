/** Media providers and prices (D-182, D-183). */
import { describe, expect, it } from "vitest";
import {
  FalMediaProvider,
  falImageCost,
  MEDIA_PRICES,
  MediaRouter,
  OpenRouterMediaProvider,
} from "../src/media.ts";

const PNG = Buffer.from([137, 80, 78, 71]).toString("base64");

describe("media prices", () => {
  it("bills fal images per megapixel (1024×1024, rounded up) or per image", () => {
    expect(falImageCost("fal-ai/flux-2/klein/4b", 1024, 1024)).toBeCloseTo(0.005, 6);
    expect(falImageCost("fal-ai/flux-2/klein/4b", 1024, 576)).toBeCloseTo(0.005, 6);
    expect(falImageCost("fal-ai/flux-2/klein/4b", 2048, 2048)).toBeCloseTo(0.02, 6);
    expect(falImageCost("fal-ai/flux/schnell")).toBeCloseTo(0.003, 6);
    expect(falImageCost("fal-ai/bytedance/seedream/v4.5/text-to-image", 4096, 4096)).toBe(0.04);
    // Unknown models are priced high, never low.
    expect(falImageCost("fal-ai/something-new", 1024, 1024)).toBe(MEDIA_PRICES.image);
  });

  it("fal's default image model is Seedream 4.5 and results carry their price", async () => {
    let path = "";
    const fake = (async (url: string) => {
      path = new URL(url).pathname;
      return Response.json({ images: [{ url: "https://x/i.png", width: 2048, height: 2048 }] });
    }) as unknown as typeof fetch;
    const [img] = await new FalMediaProvider({ apiKey: "k", fetch: fake }).generateImage({
      prompt: "a cloud",
    });
    expect(path).toBe("/fal-ai/bytedance/seedream/v4.5/text-to-image");
    expect(img).toMatchObject({ model: "fal-ai/bytedance/seedream/v4.5/text-to-image" });
    expect(img?.costUsd).toBeCloseTo(0.04, 6);
  });

  it("OpenRouter images: Qwen Image 3.0 Pro, inline bytes, the cost OpenRouter reports", async () => {
    let sent: Record<string, unknown> = {};
    let auth = "";
    const fake = (async (url: string, init: RequestInit) => {
      expect(url).toBe("https://openrouter.ai/api/v1/images");
      auth = new Headers(init.headers).get("authorization") ?? "";
      sent = JSON.parse(String(init.body));
      return Response.json({
        data: [{ b64_json: PNG, media_type: "image/png" }],
        usage: { cost: 0.0412 },
      });
    }) as unknown as typeof fetch;
    const [img] = await new OpenRouterMediaProvider("sk-or", { fetch: fake }).generateImage({
      prompt: "a cloud",
      size: "landscape",
    });
    expect(auth).toBe("Bearer sk-or");
    expect(sent).toMatchObject({ model: "qwen/qwen-image-3-pro", aspect_ratio: "16:9", n: 1 });
    expect(img).toMatchObject({ url: "", contentType: "image/png", costUsd: 0.0412 });
    expect([...(img?.data ?? [])]).toEqual([137, 80, 78, 71]);
  });

  it("OpenRouter without a reported cost uses its list price; errors say why", async () => {
    const noCost = (async () =>
      Response.json({ data: [{ b64_json: PNG }] })) as unknown as typeof fetch;
    const [img] = await new OpenRouterMediaProvider("k", { fetch: noCost }).generateImage({
      prompt: "x",
    });
    expect(img?.costUsd).toBe(0.04);
    const broke = (async () =>
      Response.json(
        { error: { message: "Insufficient credits" } },
        { status: 402 },
      )) as unknown as typeof fetch;
    await expect(
      new OpenRouterMediaProvider("k", { fetch: broke }).generateImage({ prompt: "x" }),
    ).rejects.toThrow("OpenRouter returned 402: Insufficient credits");
  });

  it("the router sends images and video to their own providers", async () => {
    const images = new OpenRouterMediaProvider("k", {
      fetch: (async () => Response.json({ data: [{ b64_json: PNG }] })) as unknown as typeof fetch,
    });
    const onlyImages = new MediaRouter(images, null);
    expect((await onlyImages.generateImage({ prompt: "x" }))[0]?.model).toBe(
      "qwen/qwen-image-3-pro",
    );
    expect(() => onlyImages.generateVideo({ prompt: "x" })).toThrow("fal.ai key");
  });
});
