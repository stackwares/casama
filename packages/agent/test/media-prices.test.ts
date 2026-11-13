/** Media providers and prices (D-185, D-189, D-261). */
import { describe, expect, it } from "vitest";
import { MediaRouter, OpenRouterMediaProvider } from "../src/media.ts";

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

  it("the router refuses a side it has no provider for", async () => {
    const images = new OpenRouterMediaProvider("k", {
      fetch: (async () => Response.json({ data: [{ b64_json: PNG }] })) as unknown as typeof fetch,
    });
    const onlyImages = new MediaRouter(images, null);
    expect((await onlyImages.generateImage({ prompt: "x" }))[0]?.model).toBe(
      "google/gemini-nano-banana-2.1",
    );
    expect(() => onlyImages.generateVideo({ prompt: "x" })).toThrow(
      "Video needs an OpenRouter key",
    );
    const onlyVideo = new MediaRouter(null, images);
    expect(() => onlyVideo.generateImage({ prompt: "x" })).toThrow("Images need an OpenRouter key");
  });

  /** A fake OpenRouter video API: submit, `polls` pending answers, then done; records requests. */
  function fakeVideoApi(opts: { polls?: number; cost?: number | null; status?: string } = {}) {
    const seen: Array<{ method: string; url: string; auth: string; body: unknown }> = [];
    let polls = opts.polls ?? 1;
    const fetchImpl = (async (url: string, init: RequestInit = {}) => {
      seen.push({
        method: init.method ?? "GET",
        url,
        auth: new Headers(init.headers).get("authorization") ?? "",
        body: init.body ? JSON.parse(String(init.body)) : null,
      });
      if (init.method === "POST")
        return Response.json({
          id: "gen-vid-1",
          polling_url: "/api/v1/videos/gen-vid-1",
          status: "pending",
        });
      if (url.endsWith("/content?index=0"))
        return new Response(Buffer.from("mp4"), { headers: { "content-type": "video/mp4" } });
      if (polls-- > 0) return Response.json({ id: "gen-vid-1", status: "in_progress" });
      return Response.json({
        id: "gen-vid-1",
        status: opts.status ?? "completed",
        ...(opts.status === "failed" ? { error: "content policy" } : {}),
        ...(opts.cost === null ? {} : { usage: { cost: opts.cost ?? 0.3475 } }),
      });
    }) as unknown as typeof fetch;
    return { seen, fetchImpl };
  }

  it("video is a job on OpenRouter: Omni Flash 1.2 at 720p, polled, downloaded, at its reported cost", async () => {
    const api = fakeVideoApi({ polls: 2 });
    const video = await new OpenRouterMediaProvider("sk-or", {
      base: "http://or.test/api/v1",
      fetch: api.fetchImpl,
      pollMs: 1,
    }).generateVideo({ prompt: "a lighthouse", durationS: 1, size: "portrait" });
    expect(api.seen[0]).toMatchObject({
      method: "POST",
      url: "http://or.test/api/v1/videos",
      auth: "Bearer sk-or",
      body: {
        model: "google/gemini-omni-1.2-flash",
        prompt: "a lighthouse",
        duration: 3,
        resolution: "720p",
        aspect_ratio: "9:16",
        generate_audio: true,
      },
    });
    expect(api.seen.filter((r) => r.url === "http://or.test/api/v1/videos/gen-vid-1")).toHaveLength(
      3,
    );
    expect(api.seen.at(-1)).toMatchObject({
      url: "http://or.test/api/v1/videos/gen-vid-1/content?index=0",
      auth: "Bearer sk-or",
    });
    expect(video).toMatchObject({
      url: "",
      contentType: "video/mp4",
      durationS: 3,
      model: "google/gemini-omni-1.2-flash",
      costUsd: 0.3475,
    });
    expect(Buffer.from(video.data ?? []).toString()).toBe("mp4");
  });

  it("without a reported cost a clip is priced at OpenRouter's 720p rate; a failed job says why", async () => {
    const priced = await new OpenRouterMediaProvider("k", {
      fetch: fakeVideoApi({ polls: 0, cost: null }).fetchImpl,
      pollMs: 1,
    }).generateVideo({ prompt: "x", durationS: 4 });
    expect(priced.costUsd).toBeCloseTo(4 * 0.069504, 6);
    await expect(
      new OpenRouterMediaProvider("k", {
        fetch: fakeVideoApi({ polls: 0, status: "failed" }).fetchImpl,
        pollMs: 1,
      }).generateVideo({ prompt: "x" }),
    ).rejects.toThrow("OpenRouter video failed: content policy");
  });

  it("animating a picture sends it as the first frame", async () => {
    const api = fakeVideoApi({ polls: 0 });
    const image = { data: new Uint8Array([137, 80, 78, 71]), contentType: "image/png" };
    await new OpenRouterMediaProvider("k", { fetch: api.fetchImpl, pollMs: 1 }).generateVideo({
      prompt: "make it wag",
      image,
    });
    expect((api.seen[0]?.body as { frame_images?: unknown } | undefined)?.frame_images).toEqual([
      {
        type: "image_url",
        image_url: { url: `data:image/png;base64,${PNG}` },
        frame_type: "first_frame",
      },
    ]);
  });
});
