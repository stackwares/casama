/**
 * Image and video generation behind one interface, both on OpenRouter (D-185, D-189, D-261):
 * images are Gemini Nano Banana 2.1 at 1K, video is Gemini Omni Flash 1.2 at 720p.
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

/** Default video model on OpenRouter: Gemini Omni Flash 1.2 at 720p, 3–15 seconds (D-189, D-261). */
export const OPENROUTER_VIDEO_MODEL = "google/gemini-omni-1.2-flash";
/** OpenRouter's 720p-with-audio price (2026-11-13), for when a finished job reports no cost. */
export const OPENROUTER_VIDEO_PER_SECOND = 0.069504;

export interface OpenRouterMediaOptions {
  base?: string;
  fetch?: typeof fetch;
  imageModel?: string;
  resolution?: string;
  videoModel?: string;
  /** How often to poll a video job, and how long to wait for it (tests shorten both). */
  pollMs?: number;
  videoTimeoutMs?: number;
}

export class OpenRouterMediaProvider implements MediaProvider {
  readonly id = "openrouter";
  supports(_kind: "image" | "video") {
    return true;
  }
  private readonly key: string;
  private readonly base: string;
  private readonly fetchImpl: typeof fetch;
  private readonly imageModel: string;
  private readonly resolution: string;
  private readonly videoModel: string;
  private readonly pollMs: number;
  private readonly videoTimeoutMs: number;
  constructor(key: string, opts: OpenRouterMediaOptions = {}) {
    this.key = key;
    this.base = (opts.base ?? "https://openrouter.ai/api/v1").replace(/\/$/, "");
    this.fetchImpl = opts.fetch ?? fetch;
    // Nano Banana 2.1: LM Arena rank 7 and Artificial Analysis rank 6, about $0.034 at 1K.
    this.imageModel = opts.imageModel ?? OPENROUTER_IMAGE_MODEL;
    this.resolution = opts.resolution ?? OPENROUTER_IMAGE_RESOLUTION;
    this.videoModel = opts.videoModel ?? OPENROUTER_VIDEO_MODEL;
    this.pollMs = opts.pollMs ?? 5000;
    this.videoTimeoutMs = opts.videoTimeoutMs ?? 10 * 60_000;
  }

  private async call(path: string, init: RequestInit = {}) {
    const res = await this.fetchImpl(`${this.base}${path}`, {
      ...init,
      headers: { authorization: `Bearer ${this.key}`, "content-type": "application/json" },
      signal: AbortSignal.timeout(60_000),
    });
    const body = (await res.json().catch(() => ({}))) as Record<string, unknown> & {
      error?: { message?: string } | string;
    };
    if (!res.ok) {
      const said = typeof body.error === "string" ? body.error : body.error?.message;
      throw new Error(`OpenRouter returned ${res.status}: ${String(said ?? "").slice(0, 300)}`);
    }
    return body;
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

  /**
   * A video job (D-261): submit, poll until it finishes, then download the clip. A starting
   * picture goes in as the first frame.
   */
  async generateVideo(input: {
    prompt: string;
    durationS?: number;
    model?: string;
    size?: "square" | "portrait" | "landscape";
    image?: MediaInput;
  }): Promise<MediaResult> {
    const model = input.model ?? this.videoModel;
    const seconds = Math.min(15, Math.max(3, input.durationS ?? 5));
    const job = (await this.call("/videos", {
      method: "POST",
      body: JSON.stringify({
        model,
        prompt: input.prompt,
        duration: seconds,
        resolution: "720p",
        aspect_ratio: input.size === "portrait" ? "9:16" : "16:9",
        generate_audio: true,
        ...(input.image
          ? {
              frame_images: [
                {
                  type: "image_url",
                  image_url: {
                    url: `data:${input.image.contentType};base64,${Buffer.from(input.image.data).toString("base64")}`,
                  },
                  frame_type: "first_frame",
                },
              ],
            }
          : {}),
      }),
    })) as VideoJob;
    if (!job.id) throw new Error("OpenRouter returned no video job");
    const until = Date.now() + this.videoTimeoutMs;
    let done = job;
    let misses = 0;
    while (done.status !== "completed") {
      if (done.status === "failed" || done.status === "cancelled" || done.status === "expired")
        throw new Error(`OpenRouter video ${done.status}${done.error ? `: ${done.error}` : ""}`);
      if (Date.now() > until) throw new Error("OpenRouter video timed out");
      await new Promise((r) => setTimeout(r, this.pollMs));
      try {
        done = (await this.call(`/videos/${encodeURIComponent(job.id)}`)) as VideoJob;
        misses = 0;
      } catch (e) {
        // A few failed polls in a row (a network blip) are tolerated; the job keeps running.
        if (++misses >= 3) throw e;
      }
    }
    const res = await this.fetchImpl(
      `${this.base}/videos/${encodeURIComponent(job.id)}/content?index=0`,
      {
        headers: { authorization: `Bearer ${this.key}` },
        signal: AbortSignal.timeout(120_000),
      },
    );
    if (!res.ok) throw new Error(`OpenRouter returned ${res.status} for the video file`);
    const data = new Uint8Array(await res.arrayBuffer());
    if (!data.length) throw new Error("OpenRouter returned an empty video");
    const cost =
      typeof done.usage?.cost === "number"
        ? done.usage.cost
        : seconds * OPENROUTER_VIDEO_PER_SECOND;
    return {
      url: "",
      data,
      contentType: res.headers.get("content-type")?.split(";")[0] || "video/mp4",
      durationS: seconds,
      model,
      costUsd: cost,
    };
  }
}

type VideoJob = {
  id?: string;
  status?: "pending" | "in_progress" | "completed" | "failed" | "cancelled" | "expired";
  error?: string;
  usage?: { cost?: number | null };
};

/** The server account that pays for media made on its key. */
export type MediaPayer = "openrouter";

/** Images and video, each from its provider (either may be missing). */

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
    if (!this.video) throw new Error("Video needs an OpenRouter key in Model keys.");
    return this.video.generateVideo(input);
  }
}
