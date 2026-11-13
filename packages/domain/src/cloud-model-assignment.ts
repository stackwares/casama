import { PLATFORM_OPENROUTER_CREDENTIAL_ID } from "./cloud-models.ts";

/**
 * The models Casama Cloud runs. People on Cloud cannot change them. The instance owner can,
 * from the admin console, and every server picks the change up within a few seconds (D-188).
 * Self-hosted servers ignore this and keep each workspace's own choices.
 */
export interface CloudModelAssignment {
  chat: string;
  background: string;
  image: string;
  image_resolution: "1K" | "2K" | "4K";
  live: string;
  realtime: string;
  tts: string;
  stt: string;
  embedding: string;
  video: string;
}

export const CLOUD_MODEL_DEFAULTS: CloudModelAssignment = {
  chat: "deepseek/deepseek-v4.1-flash-1017",
  background: "deepseek/deepseek-v4.1-flash-1017",
  image: "google/gemini-nano-banana-2.1",
  image_resolution: "1K",
  live: "gemini-3.8-live",
  realtime: "gpt-realtime-2.1",
  tts: "gemini-3.8-flash-lite-tts",
  stt: "gpt-4o-mini-transcribe",
  embedding: "text-embedding-3-small",
  video: "gemini-omni-1.2-flash",
};

const RESOLUTIONS = new Set(["1K", "2K", "4K"]);

function text(value: unknown, fallback: string): string {
  return typeof value === "string" && value.trim() ? value.trim().slice(0, 200) : fallback;
}

/** Fills any missing or blank field from the built-in defaults. */
export function cloudModelAssignment(raw: unknown): CloudModelAssignment {
  const row = raw && typeof raw === "object" ? (raw as Record<string, unknown>) : {};
  const resolution = row.image_resolution;
  return {
    chat: text(row.chat, CLOUD_MODEL_DEFAULTS.chat),
    background: text(row.background, CLOUD_MODEL_DEFAULTS.background),
    image: text(row.image, CLOUD_MODEL_DEFAULTS.image),
    image_resolution:
      typeof resolution === "string" && RESOLUTIONS.has(resolution)
        ? (resolution as CloudModelAssignment["image_resolution"])
        : CLOUD_MODEL_DEFAULTS.image_resolution,
    live: text(row.live, CLOUD_MODEL_DEFAULTS.live),
    realtime: text(row.realtime, CLOUD_MODEL_DEFAULTS.realtime),
    tts: text(row.tts, CLOUD_MODEL_DEFAULTS.tts),
    stt: text(row.stt, CLOUD_MODEL_DEFAULTS.stt),
    embedding: text(row.embedding, CLOUD_MODEL_DEFAULTS.embedding),
    video: text(row.video, CLOUD_MODEL_DEFAULTS.video),
  };
}

/** What a Casama Cloud bot runs: Casama's key, Casama's chat model, Casama's background model. */
export function cloudRunPolicy(assignment: CloudModelAssignment) {
  return {
    primary: { credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID, model: assignment.chat },
    cheap: { credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID, model: assignment.background },
  };
}
