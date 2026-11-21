import { createHash } from "node:crypto";

/**
 * Pictures of computer screens for the screen card (SCREEN-CARD-PLAN §8). A computer is captured
 * at most once per `ttlMs`, however many people watch it: everyone asking within that window gets
 * the same picture, and asks that arrive while a capture runs wait for it rather than starting
 * another. Small copies are made once per picture and size.
 */
export class ScreenCaptures {
  private readonly shots = new Map<string, Shot>();
  private readonly ttlMs: number;
  private readonly now: () => number;
  private readonly maxEntries: number;

  constructor(ttlMs = 1000, now: () => number = Date.now, maxEntries = 500) {
    this.ttlMs = ttlMs;
    this.now = now;
    this.maxEntries = maxEntries;
  }

  /** The latest picture for `key`, capturing a new one when the last is older than the window. */
  async get(key: string, capture: () => Promise<Uint8Array>): Promise<Shot> {
    const t = this.now();
    const have = this.shots.get(key);
    if (have && t - have.at < this.ttlMs) return have;
    const running = this.pending.get(key);
    if (running) return running;
    const p = capture()
      .then((png) => {
        const shot: Shot = { at: this.now(), png, etag: etagOf(png), small: new Map() };
        this.shots.set(key, shot);
        this.prune();
        return shot;
      })
      .finally(() => this.pending.delete(key));
    this.pending.set(key, p);
    return p;
  }

  private readonly pending = new Map<string, Promise<Shot>>();

  /** Old pictures go after a minute; the map never grows past `maxEntries`. */
  private prune() {
    const t = this.now();
    for (const [k, s] of this.shots) {
      if (t - s.at > 60_000 || this.shots.size > this.maxEntries) this.shots.delete(k);
    }
  }
}

export type Shot = {
  at: number;
  png: Uint8Array;
  /** A strong ETag for this exact picture, the same for every size and format made from it. */
  etag: string;
  small: Map<string, Uint8Array>;
};

/** Quoted, as HTTP wants it. Unchanged screens give byte-identical PNGs, so the hash is stable. */
export const etagOf = (png: Uint8Array) =>
  `"s-${createHash("sha1").update(png).digest("hex").slice(0, 20)}"`;

/** Whether an If-None-Match header names this picture (a list, or `*`). */
export const matchesEtag = (header: string | undefined, etag: string) =>
  !!header &&
  header.split(",").some((v) => v.trim().replace(/^W\//, "") === etag || v.trim() === "*");

/**
 * A copy of `shot` at most `width` pixels wide (never enlarged), as JPEG at quality 60 or PNG.
 * 480 wide at quality 60 is 14–20 KB for a typical screen (measured 2026-11-21).
 */
export async function shrink(
  shot: Shot,
  width: number,
  format: "jpeg" | "png",
): Promise<Uint8Array> {
  const key = `${format}:${width}`;
  const have = shot.small.get(key);
  if (have) return have;
  const sharp = (await import("sharp")).default;
  const img = sharp(shot.png).resize({ width, withoutEnlargement: true });
  const out = new Uint8Array(
    format === "jpeg"
      ? await img.jpeg({ quality: 60, mozjpeg: true }).toBuffer()
      : await img.png().toBuffer(),
  );
  shot.small.set(key, out);
  return out;
}
