/**
 * Image and video generation behind one interface (D-185, D-189): images on OpenRouter (Gemini
 * Nano Banana 2.1 at 1K) when the workspace has an OpenRouter key, else fal. Video is Gemini Omni
 * Flash 1.2 when a Google AI key exists, else fal.
 */
export interface MediaResult {
  /** Where to download it; empty when the bytes come inline (`data`). */
  url: string;
  /** The file itself, for providers that return it inline (OpenRouter returns base64). */
  data?: Uint8Array;
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
      // Seedream 4.5: arena rank 38 for $0.04 an image, the fal fallback when there is no
      // OpenRouter key. Workspaces with an OpenRouter key get Nano Banana 2.1 instead (D-185).
      imageModel: opts.imageModel ?? "fal-ai/bytedance/seedream/v4.5/text-to-image",
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

// ---------------------------------------------------------------------------
// OpenRouter images (D-185): POST /api/v1/images, base64 results, exact cost in `usage.cost`.

/** Default image model on OpenRouter: Gemini Nano Banana 2.1, pinned to 1K (D-185). */
export const OPENROUTER_IMAGE_MODEL = "google/gemini-nano-banana-2.1";
/** 1K is $0.0336; 2K is $0.0504 and 4K is $0.113, so the request names the tier. */
export const OPENROUTER_IMAGE_RESOLUTION = "1K";

/** OpenRouter list prices per image at 1K (2026-11-11), for when a response has no cost. */
export const OPENROUTER_IMAGE_PRICES: Record<string, number> = {
  "google/gemini-nano-banana-2.1": 0.0336,
  "qwen/qwen-image-3-pro": 0.04,
  "qwen/qwen-image-3": 0.03,
  "bytedance-seed/seedream-5-0-pro": 0.045,
  "bytedance-seed/seedream-5-0-lite": 0.035,
  "bytedance-seed/seedream-5-0-flash": 0.018,
};

const ASPECT = { square: "1:1", portrait: "3:4", landscape: "16:9" } as const;

export class OpenRouterMediaProvider implements MediaProvider {
  readonly id = "openrouter";
  private readonly key: string;
  private readonly base: string;
  private readonly fetchImpl: typeof fetch;
  private readonly imageModel: string;
  private readonly resolution: string;
  constructor(
    key: string,
    opts: { base?: string; fetch?: typeof fetch; imageModel?: string; resolution?: string } = {},
  ) {
    this.key = key;
    this.base = (opts.base ?? "https://openrouter.ai/api/v1").replace(/\/$/, "");
    this.fetchImpl = opts.fetch ?? fetch;
    // Nano Banana 2.1: LM Arena rank 7 and Artificial Analysis rank 6, about $0.034 at 1K.
    this.imageModel = opts.imageModel ?? OPENROUTER_IMAGE_MODEL;
    this.resolution = opts.resolution ?? OPENROUTER_IMAGE_RESOLUTION;
  }

  async generateImage(input: {
    prompt: string;
    size?: "square" | "portrait" | "landscape";
    model?: string;
  }) {
    const model = input.model ?? this.imageModel;
    const res = await this.fetchImpl(`${this.base}/images`, {
      method: "POST",
      headers: { authorization: `Bearer ${this.key}`, "content-type": "application/json" },
      body: JSON.stringify({
        model,
        prompt: input.prompt,
        aspect_ratio: ASPECT[input.size ?? "square"],
        resolution: this.resolution,
        n: 1,
      }),
      signal: AbortSignal.timeout(180_000),
    });
    const body = (await res.json().catch(() => ({}))) as {
      data?: Array<{ b64_json?: string; media_type?: string }>;
      usage?: { cost?: number | null };
      error?: { message?: string };
    };
    if (!res.ok)
      throw new Error(
        `OpenRouter returned ${res.status}: ${String(body.error?.message ?? "").slice(0, 300)}`,
      );
    const images = (body.data ?? []).filter((d) => d.b64_json);
    if (!images.length) throw new Error("OpenRouter returned no images");
    const total =
      typeof body.usage?.cost === "number"
        ? body.usage.cost
        : (OPENROUTER_IMAGE_PRICES[model] ?? MEDIA_PRICES.image) * images.length;
    return images.map((d) => ({
      url: "",
      data: Uint8Array.from(Buffer.from(d.b64_json as string, "base64")),
      contentType: d.media_type ?? "image/png",
      model,
      costUsd: total / images.length,
    }));
  }

  async generateVideo(): Promise<MediaResult> {
    throw new Error("Video needs a Google AI or fal.ai key in Model keys.");
  }
}

/** Gemini Omni Flash 1.2 video (D-189): Interactions API, MP4 inline, 720p, 3–15 seconds. */
export const GEMINI_VIDEO_MODEL = "gemini-omni-1.2-flash";
/** 720p: 5,792 video tokens a second at $12 per million (Google, 2026-11-10). */
export const GEMINI_VIDEO_PER_SECOND = 0.0695;

export class GeminiVideoProvider implements MediaProvider {
  readonly id = "gemini";
  private readonly key: string;
  private readonly base: string;
  private readonly fetchImpl: typeof fetch;
  private readonly model: string;
  constructor(key: string, opts: { base?: string; fetch?: typeof fetch; model?: string } = {}) {
    this.key = key;
    this.base = (opts.base ?? "https://generativelanguage.googleapis.com").replace(/\/$/, "");
    this.fetchImpl = opts.fetch ?? fetch;
    this.model = opts.model ?? GEMINI_VIDEO_MODEL;
  }

  async generateImage(): Promise<MediaResult[]> {
    throw new Error("Images need an OpenRouter or fal.ai key in Model keys.");
  }

  async generateVideo(input: {
    prompt: string;
    durationS?: number;
    model?: string;
    size?: "square" | "portrait" | "landscape";
  }) {
    const model = input.model ?? this.model;
    const seconds = Math.min(15, Math.max(3, input.durationS ?? 5));
    const res = await this.fetchImpl(`${this.base}/v1beta/interactions`, {
      method: "POST",
      headers: { "x-goog-api-key": this.key, "content-type": "application/json" },
      body: JSON.stringify({
        model,
        input: input.prompt,
        response_format: {
          type: "video",
          duration: `${seconds}s`,
          aspect_ratio: input.size === "portrait" ? "9:16" : "16:9",
          resolution: "720p",
        },
      }),
      signal: AbortSignal.timeout(300_000),
    });
    const body = (await res.json().catch(() => ({}))) as {
      error?: { message?: string };
      usage?: { cost?: number };
      output_video?: { data?: string; mime_type?: string; mimeType?: string };
      steps?: Array<{
        type?: string;
        content?: Array<{ type?: string; data?: string; mime_type?: string; mimeType?: string }>;
      }>;
    };
    if (!res.ok)
      throw new Error(
        `Gemini returned ${res.status}: ${String(body.error?.message ?? "").slice(0, 300)}`,
      );
    let data = body.output_video?.data;
    let mime = body.output_video?.mime_type ?? body.output_video?.mimeType;
    for (const step of [...(body.steps ?? [])].reverse()) {
      if (data) break;
      if (step.type !== "model_output") continue;
      for (const part of [...(step.content ?? [])].reverse()) {
        if (part.type === "video" && part.data) {
          data = part.data;
          mime = part.mime_type ?? part.mimeType;
          break;
        }
      }
    }
    if (!data) throw new Error("Gemini returned no video");
    const cost =
      typeof body.usage?.cost === "number" ? body.usage.cost : seconds * GEMINI_VIDEO_PER_SECOND;
    return {
      url: "",
      data: Uint8Array.from(Buffer.from(data, "base64")),
      contentType: mime ?? "video/mp4",
      durationS: seconds,
      model,
      costUsd: cost,
    };
  }
}

/** Images from one provider, video from another (either may be missing). */
export class MediaRouter implements MediaProvider {
  readonly id: string;
  private readonly images: MediaProvider | null;
  private readonly video: MediaProvider | null;
  constructor(images: MediaProvider | null, video: MediaProvider | null) {
    this.images = images;
    this.video = video;
    this.id = images?.id ?? video?.id ?? "none";
  }
  generateImage(input: Parameters<MediaProvider["generateImage"]>[0]) {
    if (!this.images) throw new Error("Images need an OpenRouter or fal.ai key in Model keys.");
    return this.images.generateImage(input);
  }
  generateVideo(input: Parameters<MediaProvider["generateVideo"]>[0]) {
    if (!this.video) throw new Error("Video needs a Google AI or fal.ai key in Model keys.");
    return this.video.generateVideo(input);
  }
}
