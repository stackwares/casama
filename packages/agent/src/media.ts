/** Image and video generation behind one interface; fal.ai is the first adapter. */
export interface MediaResult {
  url: string;
  contentType: string;
  width?: number;
  height?: number;
  durationS?: number;
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
      imageModel: opts.imageModel ?? "fal-ai/flux/schnell",
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
    const r = await this.json(`${this.o.syncBase}/${input.model ?? this.o.imageModel}`, {
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
    return {
      url: video.url,
      contentType: video.content_type ?? "video/mp4",
      durationS: input.durationS,
    };
  }
}

/** Rough list prices (USD) for the ledger until provider pricing is pulled live. */
export const MEDIA_PRICES = { image: 0.003, videoPerSecond: 0.04 };
