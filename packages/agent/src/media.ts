/**
 * Image and video generation behind one interface (D-185, D-189, D-260): images on OpenRouter
 * (Gemini Nano Banana 2.1 at 1K), video on Gemini Omni Flash 1.2 with a Google AI key. There is no
 * other provider.
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
  /** Whether it can make this kind of media (a router may have only one side). */
  supports?(kind: "image" | "video"): boolean;
  /**
   * Whose account pays when this kind runs on the server's own key with billing on: the usage is
   * then billable with markup and needs credits (D-246). Null on the workspace's own key.
   */
  paidBy?(kind: "image" | "video"): MediaPayer | null;
  generateImage(input: {
    prompt: string;
    size?: "square" | "portrait" | "landscape";
    model?: string;
  }): Promise<MediaResult[]>;
  generateVideo(input: {
    prompt: string;
    durationS?: number;
    model?: string;
    /** A picture to start from: the clip animates it instead of drawing something new. */
    image?: MediaInput;
  }): Promise<MediaResult>;
}

/** A file handed to a model as input. */
export interface MediaInput {
  data: Uint8Array;
  contentType: string;
}

/**
 * Prices for models not in the tables: high on purpose, so an unknown model never costs us more
 * than we record (a premium image is about $0.04; video about $0.10 a second).
 */
export const MEDIA_PRICES = { image: 0.04, videoPerSecond: 0.1 };

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
  supports(kind: "image" | "video") {
    return kind === "image";
  }
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
    throw new Error("Video needs a Google AI key in Model keys.");
  }
}

/** Gemini Omni Flash 1.2 video (D-189): Interactions API, MP4 inline, 720p, 3–15 seconds. */
export const GEMINI_VIDEO_MODEL = "gemini-omni-1.2-flash";
/** 720p: 5,792 video tokens a second at $12 per million (Google, 2026-11-10). */
export const GEMINI_VIDEO_PER_SECOND = 0.0695;

export class GeminiVideoProvider implements MediaProvider {
  readonly id = "gemini";
  supports(kind: "image" | "video") {
    return kind === "video";
  }
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
    throw new Error("Images need an OpenRouter key in Model keys.");
  }

  async generateVideo(input: {
    prompt: string;
    durationS?: number;
    model?: string;
    size?: "square" | "portrait" | "landscape";
    image?: MediaInput;
  }) {
    const model = input.model ?? this.model;
    const seconds = Math.min(15, Math.max(3, input.durationS ?? 5));
    const res = await this.fetchImpl(`${this.base}/v1beta/interactions`, {
      method: "POST",
      headers: { "x-goog-api-key": this.key, "content-type": "application/json" },
      body: JSON.stringify({
        model,
        // A starting picture goes in with the prompt, as an image part.
        input: input.image
          ? [
              { type: "text", text: input.prompt },
              {
                type: "image",
                data: Buffer.from(input.image.data).toString("base64"),
                mime_type: input.image.contentType,
              },
            ]
          : input.prompt,
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
/** The server account that pays for media made on its key. */
export type MediaPayer = "openrouter" | "google";

export class MediaRouter implements MediaProvider {
  readonly id: string;
  private readonly images: MediaProvider | null;
  private readonly video: MediaProvider | null;
  private readonly payers: { image?: MediaPayer | null; video?: MediaPayer | null };
  constructor(
    images: MediaProvider | null,
    video: MediaProvider | null,
    payers: { image?: MediaPayer | null; video?: MediaPayer | null } = {},
  ) {
    this.images = images;
    this.video = video;
    this.payers = payers;
    this.id = images?.id ?? video?.id ?? "none";
  }
  paidBy(kind: "image" | "video") {
    return this.payers[kind] ?? null;
  }
  supports(kind: "image" | "video") {
    const side = kind === "image" ? this.images : this.video;
    return !!side && side.supports?.(kind) !== false;
  }
  generateImage(input: Parameters<MediaProvider["generateImage"]>[0]) {
    if (!this.images) throw new Error("Images need an OpenRouter key in Model keys.");
    return this.images.generateImage(input);
  }
  generateVideo(input: Parameters<MediaProvider["generateVideo"]>[0]) {
    if (!this.video) throw new Error("Video needs a Google AI key in Model keys.");
    return this.video.generateVideo(input);
  }
}
