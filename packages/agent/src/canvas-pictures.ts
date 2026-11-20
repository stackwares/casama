/**
 * Canvas pictures (docs/BOT-WIDGET-PLAN.md §6.2): a bot names a picture (an https link, a chat
 * file as `media:<id>`, or a file on its computer); the server fetches it, checks it, drops its
 * metadata, shrinks it to fit 1200×1200 and re-encodes it as a JPEG under 400 KB, and records
 * whether it is light or dark. Widgets fetch it from our server with their key; a widget never
 * opens an address a bot gave.
 */
import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import type { Database } from "@casama/db";
import { CANVAS_LIMITS, CANVAS_PAINTINGS, type CanvasPainting, type Tone } from "@casama/domain";
import type { ObjectStore } from "@casama/sandbox";
import { sql } from "drizzle-orm";
import { readMedia } from "./media-store.ts";
import { safeFetch, withTimeout } from "./safe-fetch.ts";
import { type ToolContext, ToolError } from "./tools/registry.ts";

export interface CanvasPicture {
  hash: string;
  tone: Tone;
  bytes: Uint8Array;
}

const ACCEPTED = new Set(["jpeg", "png", "webp", "heif"]);

/** Reads what a bot pointed at: an https link, `media:<id>` or a path on its computer. */
export async function loadPictureSource(
  ref: string,
  ctx: ToolContext,
  deps: { db: Database; objects?: ObjectStore | null; fetch?: typeof fetch },
): Promise<Uint8Array> {
  const r = ref.trim();
  const tooBig = () =>
    new ToolError("picture_too_large", "That picture is over 10 MB. Use a smaller one.");
  if (/^https:\/\//i.test(r)) {
    const f = withTimeout(deps.fetch ?? safeFetch, 20_000);
    let res: Response;
    try {
      res = await f(r, { redirect: "follow" });
    } catch (e) {
      throw new ToolError(
        "picture_unreachable",
        `Couldn't fetch the picture: ${(e as Error).message}`,
      );
    }
    if (!res.ok)
      throw new ToolError("picture_unreachable", `The picture link answered ${res.status}.`);
    const len = Number(res.headers.get("content-length") ?? 0);
    if (len > CANVAS_LIMITS.pictureInBytes) throw tooBig();
    const buf = new Uint8Array(await res.arrayBuffer());
    if (buf.length > CANVAS_LIMITS.pictureInBytes) throw tooBig();
    return buf;
  }
  if (/^http:\/\//i.test(r))
    throw new ToolError("picture_not_https", "Picture links must be https.");
  const media = /^media:([0-9a-f-]{36})$/i.exec(r)?.[1];
  if (media) {
    const [row] = await deps.db.execute<{ id: string }>(sql`
      select id from public.chat_media where id = ${media}::uuid and org_id = ${ctx.orgId}::uuid`);
    const data = row ? await readMedia(deps.db, deps.objects, media) : null;
    if (!data) throw new ToolError("picture_not_found", `There's no chat file ${r}.`);
    if (data.length > CANVAS_LIMITS.pictureInBytes) throw tooBig();
    return data;
  }
  if (!ctx.computer)
    throw new ToolError(
      "picture_not_found",
      `${r} would be on your computer, and you don't have one here. Use an https link or media:<id>.`,
    );
  const path = r.startsWith("workspace/") ? `~/${r}` : r;
  const data = await (await ctx.computer()).readFile(path).catch(() => {
    throw new ToolError("picture_not_found", `There's no file at ${r} on your computer.`);
  });
  if (data.length > CANVAS_LIMITS.pictureInBytes) throw tooBig();
  return data;
}

/** Checks, cleans, shrinks and re-encodes a picture; works out its tone. */
export async function preparePicture(input: Uint8Array): Promise<CanvasPicture> {
  const sharp = (await import("sharp")).default;
  let meta: { format?: string; width?: number; height?: number };
  try {
    meta = await sharp(input, { limitInputPixels: 50_000_000 }).metadata();
  } catch {
    throw new ToolError("picture_unreadable", "That file isn't a picture we can read.");
  }
  if (!meta.format || !ACCEPTED.has(meta.format))
    throw new ToolError(
      "picture_type",
      `Pictures must be JPEG, PNG, WebP or HEIC (this is ${meta.format ?? "unknown"}).`,
    );
  const side = CANVAS_LIMITS.pictureSide;
  let out: Buffer | null = null;
  for (const [max, quality] of [
    [side, 82],
    [side, 70],
    [Math.round(side * 0.75), 70],
    [Math.round(side * 0.5), 65],
  ] as const) {
    // rotate() applies the camera's orientation; metadata isn't kept unless asked for.
    out = await sharp(input, { limitInputPixels: 50_000_000 })
      .rotate()
      .resize({ width: max, height: max, fit: "inside", withoutEnlargement: true })
      .flatten({ background: "#ffffff" })
      .jpeg({ quality, mozjpeg: true })
      .toBuffer();
    if (out.length <= CANVAS_LIMITS.pictureOutBytes) break;
  }
  if (!out || out.length > CANVAS_LIMITS.pictureOutBytes)
    throw new ToolError(
      "picture_too_large",
      "That picture won't shrink small enough for a widget.",
    );
  const tone = await toneOfPicture(out);
  const hash = createHash("sha256").update(out).digest("hex").slice(0, 32);
  return { hash, tone, bytes: new Uint8Array(out) };
}

/** Light or dark, from the picture's mean luminance. */
export async function toneOfPicture(bytes: Uint8Array): Promise<Tone> {
  const sharp = (await import("sharp")).default;
  const { channels } = await sharp(bytes).resize(32, 32, { fit: "fill" }).stats();
  const [r, g, b] = channels.map((c) => c.mean / 255) as [number, number, number];
  const l = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  return l > 0.55 ? "light" : "dark";
}

export const pictureKey = (orgId: string, canvasId: string, hash: string) =>
  `canvases/${orgId}/${canvasId}/${hash}.jpg`;

/** Keeps a prepared picture for a canvas (once; the hash names it). */
export async function storePicture(
  db: Database,
  objects: ObjectStore | null | undefined,
  o: { orgId: string; canvasId: string; picture: CanvasPicture },
) {
  const { hash, tone, bytes } = o.picture;
  const [had] = await db.execute<{ hash: string }>(sql`
    select hash from public.widget_canvas_pictures where canvas_id = ${o.canvasId}::uuid and hash = ${hash}`);
  if (had) return;
  if (objects) {
    const key = pictureKey(o.orgId, o.canvasId, hash);
    await objects.put(key, bytes);
    await db.execute(sql`
      insert into public.widget_canvas_pictures (canvas_id, hash, tone, size, blob_key)
      values (${o.canvasId}::uuid, ${hash}, ${tone}, ${bytes.length}, ${key}) on conflict do nothing`);
  } else
    await db.execute(sql`
      insert into public.widget_canvas_pictures (canvas_id, hash, tone, size, bytes)
      values (${o.canvasId}::uuid, ${hash}, ${tone}, ${bytes.length}, ${Buffer.from(bytes)}) on conflict do nothing`);
}

/** Removes a canvas's pictures that its content no longer names. */
export async function prunePictures(db: Database, canvasId: string, keep: string[]) {
  await db.execute(sql`
    delete from public.widget_canvas_pictures where canvas_id = ${canvasId}::uuid
    ${keep.length ? sql`and hash <> all(${`{${keep.join(",")}}`}::text[])` : sql``}`);
}

/** A stored picture's bytes; null when it's gone. */
export async function readPicture(
  db: Database,
  objects: ObjectStore | null | undefined,
  canvasId: string,
  hash: string,
): Promise<Uint8Array | null> {
  const [p] = await db.execute<{ blob_key: string | null; bytes: Buffer | null }>(sql`
    select blob_key, bytes from public.widget_canvas_pictures
    where canvas_id = ${canvasId}::uuid and hash = ${hash}`);
  if (!p) return null;
  if (p.bytes) return new Uint8Array(p.bytes);
  if (!p.blob_key || !objects) return null;
  const { readObject } = await import("@casama/sandbox");
  return readObject(objects, p.blob_key).catch(() => null);
}

/** The colours a painting falls back to when its file isn't there (a soft gradient). */
const PAINTING_FALLBACK: Record<CanvasPainting, [string, string]> = {
  sunrise: ["#3b1f4a", "#e0785a"],
  night_sky: ["#0b1026", "#2b3a6b"],
  ocean: ["#0b3a53", "#1f7a8c"],
  forest: ["#1b3a2a", "#3f6b45"],
  rain: ["#2c3e50", "#4a6072"],
  meadow: ["#e8f3d6", "#b7d98b"],
  desert: ["#f6e3c4", "#e2b97f"],
  paper: ["#faf6ee", "#efe6d4"],
};

const paintingCache = new Map<string, Uint8Array>();

/** A built-in painting's JPEG (§6.2): its file beside this module, or a gradient until it exists. */
export async function readPainting(name: string): Promise<Uint8Array | null> {
  if (!(name in CANVAS_PAINTINGS)) return null;
  const hit = paintingCache.get(name);
  if (hit) return hit;
  let bytes: Uint8Array;
  try {
    bytes = new Uint8Array(
      await readFile(new URL(`./canvas-paintings/${name}.jpg`, import.meta.url)),
    );
  } catch {
    const [from, to] = PAINTING_FALLBACK[name as CanvasPainting];
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="1200"><defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${from}"/><stop offset="1" stop-color="${to}"/></linearGradient></defs><rect width="1200" height="1200" fill="url(#g)"/></svg>`;
    const sharp = (await import("sharp")).default;
    bytes = new Uint8Array(await sharp(Buffer.from(svg)).jpeg({ quality: 80 }).toBuffer());
  }
  paintingCache.set(name, bytes);
  return bytes;
}
