/**
 * Cost tables as an admin setting (D-373, docs/REMOTE-CONTENT-PLAN.md #12): what voice, Gemini
 * Live, computers and media cost Casama, used for the ledger and for what billing charges. Edited
 * in Admin → Pricing (`billing_settings.cost_tables`), loaded by every process every minute. Each
 * value is optional: a value left out, or one that fails its check, uses the price in code
 * (`VOICE_PRICES`, `GEMINI_LIVE_PRICES`, `COMPUTER_RATES`, `MEDIA_PRICES` in @casama/agent), so an
 * empty setting bills exactly as before.
 */

export interface CostTables {
  voice?: {
    /** USD a minute of dictation when the response carries no cost. */
    stt_per_minute?: number;
    /** USD per thousand characters read aloud when the audio's length is unknown. */
    gemini_tts_per_thousand_chars?: number;
    /** USD a minute of a call when its token counts are missing (and the hold before a call). */
    gemini_live_per_minute?: number;
  };
  /** Gemini Live list prices, USD per million tokens. */
  gemini_live?: {
    input_audio?: number;
    input_text?: number;
    input_image?: number;
    output_audio?: number;
    output_text?: number;
  };
  /** Computer prices by provider, USD per vCPU-hour and per GiB-hour. */
  computers?: Record<string, { cpu_hour: number; gb_hour: number }>;
  media?: {
    /** USD per image for a model with no price of its own. */
    image?: number;
    /** USD per second of video for a model with no price of its own. */
    video_per_second?: number;
    /** OpenRouter's video price per second, when a finished job reports no cost. */
    openrouter_video_per_second?: number;
  };
}

const SECTIONS: Record<keyof CostTables, readonly string[] | null> = {
  voice: ["stt_per_minute", "gemini_tts_per_thousand_chars", "gemini_live_per_minute"],
  gemini_live: ["input_audio", "input_text", "input_image", "output_audio", "output_text"],
  computers: null,
  media: ["image", "video_per_second", "openrouter_video_per_second"],
};
/** The highest value each kind of price may take; a typo a thousand times too big is refused. */
const LIMITS: Record<string, number> = {
  stt_per_minute: 10,
  gemini_tts_per_thousand_chars: 10,
  gemini_live_per_minute: 10,
  input_audio: 1000,
  input_text: 1000,
  input_image: 1000,
  output_audio: 1000,
  output_text: 1000,
  image: 5,
  video_per_second: 10,
  openrouter_video_per_second: 10,
};
const COMPUTER_PROVIDER = /^[a-z][a-z0-9-]{0,39}$/;
const MAX_COMPUTER_RATE = 100;

const isRecord = (v: unknown): v is Record<string, unknown> =>
  typeof v === "object" && v !== null && !Array.isArray(v);
const okPrice = (v: unknown, max: number) =>
  typeof v === "number" && Number.isFinite(v) && v >= 0 && v <= max;

/** Checks cost tables; `tables` keeps what passed, a save is refused when `errors` isn't empty. */
export function checkCostTables(raw: unknown): { tables: CostTables; errors: string[] } {
  const errors: string[] = [];
  const tables: CostTables = {};
  if (raw === undefined || raw === null) return { tables, errors };
  if (!isRecord(raw)) return { tables, errors: ["the cost tables must be an object"] };
  for (const [section, value] of Object.entries(raw)) {
    if (!(section in SECTIONS)) {
      errors.push(`unknown table ${section} (expected ${Object.keys(SECTIONS).join(", ")})`);
      continue;
    }
    if (!isRecord(value)) {
      errors.push(`${section} must be an object`);
      continue;
    }
    if (section === "computers") {
      const out: Record<string, { cpu_hour: number; gb_hour: number }> = {};
      for (const [id, rate] of Object.entries(value)) {
        if (!COMPUTER_PROVIDER.test(id)) {
          errors.push(`computers: ${id} isn't a provider id`);
          continue;
        }
        if (
          !isRecord(rate) ||
          Object.keys(rate).some((k) => k !== "cpu_hour" && k !== "gb_hour") ||
          !okPrice(rate.cpu_hour, MAX_COMPUTER_RATE) ||
          !okPrice(rate.gb_hour, MAX_COMPUTER_RATE)
        ) {
          errors.push(
            `computers.${id} must be { cpu_hour, gb_hour } in USD, 0 to ${MAX_COMPUTER_RATE}`,
          );
          continue;
        }
        out[id] = { cpu_hour: rate.cpu_hour as number, gb_hour: rate.gb_hour as number };
      }
      tables.computers = out;
      continue;
    }
    const keys = SECTIONS[section as keyof CostTables] as readonly string[];
    const out: Record<string, number> = {};
    for (const [k, v] of Object.entries(value)) {
      if (!keys.includes(k)) errors.push(`${section}: unknown price ${k}`);
      else if (!okPrice(v, LIMITS[k] as number))
        errors.push(`${section}.${k} must be a number from 0 to ${LIMITS[k]}`);
      else out[k] = v as number;
    }
    (tables as Record<string, unknown>)[section] = out;
  }
  return { tables, errors };
}

let current: CostTables = {};

/** Replaces the loaded tables (the server calls it every minute); bad values are left out. */
export function setCostTables(raw: unknown) {
  current = checkCostTables(raw).tables;
}

/** The loaded overrides; each consumer merges them over its own prices in code. */
export function costTables(): CostTables {
  return current;
}
