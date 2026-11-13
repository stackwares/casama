/** Media providers and prices (D-185, D-189, D-260). */
import { describe, expect, it } from "vitest";
import { GeminiVideoProvider, MediaRouter, OpenRouterMediaProvider } from "../src/media.ts";

const PNG = Buffer.from([137, 80, 78, 71]).toString("base64");

describe("media prices", () => {
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
    expect(() => onlyImages.generateVideo({ prompt: "x" })).toThrow("Video needs a Google AI key");
    const onlyVideo = new MediaRouter(null, new GeminiVideoProvider("g"));
    expect(() => onlyVideo.generateImage({ prompt: "x" })).toThrow("Images need an OpenRouter key");
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

  it("animating a picture: Gemini gets the picture with the prompt", async () => {
    const image = { data: new Uint8Array([137, 80, 78, 71]), contentType: "image/png" };
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
