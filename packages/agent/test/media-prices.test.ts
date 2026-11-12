/** Media providers and prices (D-185). */
import { describe, expect, it } from "vitest";
import {
  FalMediaProvider,
  falImageCost,
  falImageToVideoModel,
  GeminiVideoProvider,
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

  it("OpenRouter images: Nano Banana 2.1 at 1K, inline bytes, the cost OpenRouter reports", async () => {
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
    expect(sent).toMatchObject({
      model: "google/gemini-nano-banana-2.1",
      aspect_ratio: "16:9",
      resolution: "1K",
      n: 1,
    });
    expect(img).toMatchObject({ url: "", contentType: "image/png", costUsd: 0.0412 });
    expect([...(img?.data ?? [])]).toEqual([137, 80, 78, 71]);
  });

  it("OpenRouter without a reported cost uses its list price; errors say why", async () => {
    const noCost = (async () =>
      Response.json({ data: [{ b64_json: PNG }] })) as unknown as typeof fetch;
    const [img] = await new OpenRouterMediaProvider("k", { fetch: noCost }).generateImage({
      prompt: "x",
    });
    expect(img?.costUsd).toBeCloseTo(0.0336, 6);
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
      "google/gemini-nano-banana-2.1",
    );
    expect(() => onlyImages.generateVideo({ prompt: "x" })).toThrow("Google AI or fal.ai key");
  });

  it("Gemini video is Omni Flash 1.2 at 720p, saved inline, priced per second", async () => {
    let sent: Record<string, unknown> = {};
    let auth = "";
    const mp4 = Buffer.from("mp4").toString("base64");
    const fake = (async (url: string, init: RequestInit) => {
      expect(url).toBe("http://gemini.test/v1beta/interactions");
      auth = new Headers(init.headers).get("x-goog-api-key") ?? "";
      sent = JSON.parse(String(init.body));
      return Response.json({
        steps: [
          { type: "model_output", content: [{ type: "video", data: mp4, mime_type: "video/mp4" }] },
        ],
      });
    }) as unknown as typeof fetch;
    const video = await new GeminiVideoProvider("gem-key", {
      base: "http://gemini.test",
      fetch: fake,
    }).generateVideo({ prompt: "a lighthouse", durationS: 1, size: "portrait" });
    expect(auth).toBe("gem-key");
    expect(sent).toMatchObject({
      model: "gemini-omni-1.2-flash",
      input: "a lighthouse",
      response_format: { type: "video", duration: "3s", aspect_ratio: "9:16", resolution: "720p" },
    });
    expect(video).toMatchObject({
      contentType: "video/mp4",
      durationS: 3,
      model: "gemini-omni-1.2-flash",
    });
    expect(video.costUsd).toBeCloseTo(3 * 0.0695, 6);
    expect(Buffer.from(video.data ?? []).toString()).toBe("mp4");
  });

  it("animating a picture: fal uses the image-to-video model, Gemini gets the picture with the prompt", async () => {
    expect(falImageToVideoModel("fal-ai/ltx-video")).toBe("fal-ai/ltx-video/image-to-video");
    expect(falImageToVideoModel("fal-ai/pixverse/v6/text-to-video")).toBe(
      "fal-ai/pixverse/v6/image-to-video",
    );
    const image = { data: new Uint8Array([137, 80, 78, 71]), contentType: "image/png" };
    const posted: Array<{ path: string; body: Record<string, unknown> }> = [];
    const fal = (async (url: string, init?: RequestInit) => {
      const path = new URL(url).pathname;
      if (init?.method === "POST") {
        posted.push({ path, body: JSON.parse(String(init.body)) });
        return Response.json({ request_id: "q1" });
      }
      if (path.endsWith("/status")) return Response.json({ status: "COMPLETED" });
      return Response.json({ video: { url: "https://x/v.mp4" } });
    }) as unknown as typeof fetch;
    const clip = await new FalMediaProvider({
      apiKey: "k",
      fetch: fal,
      queueBase: "http://fal.test",
      videoModel: "fal-ai/pixverse/v6/text-to-video",
      pollMs: 1,
    }).generateVideo({ prompt: "make it wag", durationS: 4, image });
    expect(posted[0]).toEqual({
      path: "/fal-ai/pixverse/v6/image-to-video",
      body: { prompt: "make it wag", duration: 4, image_url: `data:image/png;base64,${PNG}` },
    });
    // An image-to-video endpoint without its own price is recorded high, never low.
    expect(clip.costUsd).toBeCloseTo(4 * 0.1, 6);

    let sent: Record<string, unknown> = {};
    const gemini = (async (_url: string, init: RequestInit) => {
      sent = JSON.parse(String(init.body));
      return Response.json({ output_video: { data: PNG, mime_type: "video/mp4" } });
    }) as unknown as typeof fetch;
    await new GeminiVideoProvider("g", { base: "http://gemini.test", fetch: gemini }).generateVideo(
      { prompt: "make it wag", image },
    );
    expect(sent.input).toEqual([
      { type: "text", text: "make it wag" },
      { type: "image", data: PNG, mime_type: "image/png" },
    ]);
  });
});
