/** Image and video generation behind one interface; fal.ai is the first adapter. */
export interface MediaResult {
  url: string;
  contentType: string;
  width?: number;
  height?: number;
  durationS?: number;
  /** The model that made it and what it cost (D-182). */
  model?: string;
  costUsd?: number;
}

export interface MediaProvider {
  readonly id: string;
  generateImage(input: {
    prompt: string;
    size?: "square" | "portrait" | "landscape";
    model?: string;
  }): Promise<MediaResult[]>;
  generateVideo(input: {
    prompt: string;
    durationS?: number;
    model?: string;
  }): Promise<MediaResult>;
}

export interface FalOptions {
  apiKey: string;
  fetch?: typeof fetch;
  /** Overridable for tests. */
  syncBase?: string;
  queueBase?: string;
  imageModel?: string;
  videoModel?: string;
  pollMs?: number;
  timeoutMs?: number;
}

const FAL_SIZES = {
  square: "square_hd",
  portrait: "portrait_4_3",
  landscape: "landscape_16_9",
} as const;

export class FalMediaProvider implements MediaProvider {
  readonly id = "fal";
  private readonly o: Required<Omit<FalOptions, "fetch">> & { fetch: typeof fetch };

  constructor(opts: FalOptions) {
    this.o = {
      fetch: opts.fetch ?? fetch,
      apiKey: opts.apiKey,
      syncBase: (opts.syncBase ?? "https://fal.run").replace(/\/$/, ""),
      queueBase: (opts.queueBase ?? "https://queue.fal.run").replace(/\/$/, ""),
      // FLUX.2 klein 4B: about $0.005 an image, well ahead of FLUX.1 schnell for $0.002 more (D-182).
      imageModel: opts.imageModel ?? "fal-ai/flux-2/klein/4b",
      videoModel: opts.videoModel ?? "fal-ai/ltx-video",
      pollMs: opts.pollMs ?? 2000,
      timeoutMs: opts.timeoutMs ?? 10 * 60_000,
    };
  }

  private async json(url: string, init: RequestInit = {}) {
    const res = await this.o.fetch(url, {
      ...init,
      headers: { authorization: `Key ${this.o.apiKey}`, "content-type": "application/json" },
    });
    const body = (await res.json().catch(() => ({}))) as Record<string, unknown>;
    if (!res.ok)
      throw new Error(
        `fal.ai returned ${res.status}: ${JSON.stringify(body.detail ?? body.error ?? "").slice(0, 300)}`,
      );
    return body;
  }

  async generateImage(input: {
    prompt: string;
    size?: "square" | "portrait" | "landscape";
    model?: string;
  }) {
    const model = input.model ?? this.o.imageModel;
    const r = await this.json(`${this.o.syncBase}/${model}`, {
      method: "POST",
      body: JSON.stringify({
        prompt: input.prompt,
        image_size: FAL_SIZES[input.size ?? "square"],
        num_images: 1,
      }),
    });
    const images =
      (r.images as Array<{
        url: string;
        content_type?: string;
        width?: number;
        height?: number;
      }>) ?? [];
    if (!images.length) throw new Error("fal.ai returned no images");
    return images.map((i) => ({
      url: i.url,
      contentType: i.content_type ?? "image/jpeg",
      width: i.width,
      height: i.height,
      model,
      costUsd: falImageCost(model, i.width, i.height),
    }));
  }

  async generateVideo(input: { prompt: string; durationS?: number; model?: string }) {
    const model = input.model ?? this.o.videoModel;
    const queued = await this.json(`${this.o.queueBase}/${model}`, {
      method: "POST",
      body: JSON.stringify({
        prompt: input.prompt,
        ...(input.durationS ? { duration: input.durationS } : {}),
      }),
    });
    const statusUrl = String(
      queued.status_url ?? `${this.o.queueBase}/${model}/requests/${queued.request_id}/status`,
    );
    const responseUrl = String(
      queued.response_url ?? `${this.o.queueBase}/${model}/requests/${queued.request_id}`,
    );
    const until = Date.now() + this.o.timeoutMs;
    for (;;) {
      const s = await this.json(statusUrl);
      if (s.status === "COMPLETED") break;
      if (s.status === "FAILED" || s.status === "ERROR")
        throw new Error("fal.ai video generation failed");
      if (Date.now() > until) throw new Error("fal.ai video generation timed out");
      await new Promise((r) => setTimeout(r, this.o.pollMs));
    }
    const result = await this.json(responseUrl);
    const video = result.video as { url: string; content_type?: string } | undefined;
    if (!video?.url) throw new Error("fal.ai returned no video");
    const seconds = input.durationS ?? 5;
    return {
      url: video.url,
      contentType: video.content_type ?? "video/mp4",
      durationS: input.durationS,
      model,
      costUsd: seconds * (FAL_VIDEO_PER_SECOND[model] ?? MEDIA_PRICES.videoPerSecond),
    };
  }
}

/**
 * fal.ai list prices (USD, fal.ai/pricing and model pages, 2026-11-11; D-182). Most image models
 * bill per megapixel, rounded up; a few per image. OpenRouter sells the same models for more
 * (FLUX.2 klein 4B: $0.014 per megapixel there), so media stays on fal.
 */
export const FAL_IMAGE_PER_MEGAPIXEL: Record<string, number> = {
  "fal-ai/flux/schnell": 0.003,
  "fal-ai/flux-2/klein/4b": 0.005,
  "fal-ai/flux-2/klein/9b": 0.006,
  "fal-ai/flux-2/flash": 0.005,
  "fal-ai/z-image/turbo": 0.005,
  "fal-ai/flux-2": 0.012,
  "fal-ai/flux/dev": 0.025,
};
export const FAL_IMAGE_PER_IMAGE: Record<string, number> = {
  "fal-ai/bytedance/seedream/v4.5/text-to-image": 0.04,
};
export const FAL_VIDEO_PER_SECOND: Record<string, number> = {
  "fal-ai/pixverse/v6/text-to-video": 0.005,
  "minimax/h3-max-turbo/text-to-video": 0.025,
  "xai/grok-imagine-video/text-to-video": 0.05,
};

/**
 * Prices for models not in the tables: high on purpose, so an unknown model never costs us more
 * than we record (a premium image is about $0.04; fal's priciest common video about $0.10 a second).
 */
export const MEDIA_PRICES = { image: 0.04, videoPerSecond: 0.1 };

/** What one fal image cost: per megapixel (rounded up, 1024×1024 when the size is unknown). */
export function falImageCost(model: string, width?: number, height?: number): number {
  const perImage = FAL_IMAGE_PER_IMAGE[model];
  if (perImage !== undefined) return perImage;
  const perMp = FAL_IMAGE_PER_MEGAPIXEL[model];
  if (perMp === undefined) return MEDIA_PRICES.image;
  // fal's megapixel is 1024 × 1024 pixels.
  const mp = Math.max(1, Math.ceil(((width ?? 1024) * (height ?? 1024)) / (1024 * 1024)));
  return perMp * mp;
}
