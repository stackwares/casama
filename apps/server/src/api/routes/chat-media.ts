/**
 * Chat media (D-205): images and videos a bot generated, kept in Postgres and shown under the
 * reply. Members of the workspace read them here with their token; a single byte range is
 * honoured (video players ask for ranges and AVPlayer won't play without them), and only the
 * asked-for slice is read from the database.
 */
import { execFile } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { readMedia } from "@casama/agent";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

/** A single `bytes=` range against a file of `size` bytes: inclusive start and end, or null when unsatisfiable. */
export function parseRange(header: string, size: number): { start: number; end: number } | null {
  const m = /^bytes=(\d*)-(\d*)$/.exec(header.trim());
  if (!m || (m[1] === "" && m[2] === "")) return null;
  let start: number;
  let end: number;
  if (m[1] === "") {
    // Suffix: the last n bytes.
    const n = Number(m[2]);
    if (n <= 0) return null;
    start = Math.max(0, size - n);
    end = size - 1;
  } else {
    start = Number(m[1]);
    end = m[2] === "" ? size - 1 : Math.min(Number(m[2]), size - 1);
  }
  if (!Number.isSafeInteger(start) || !Number.isSafeInteger(end)) return null;
  if (start >= size || start > end) return null;
  return { start, end };
}

/** Pixels on a poster's longest side: sharp on a 320-point chat card at 1.5x. */
export const POSTER_SIZE = 480;
const POSTER_TIMEOUT_MS = 15_000;
const POSTERS_KEPT = 300;

/**
 * One still of a video as a JPEG, or null when ffmpeg can't make one (not installed, not a
 * video it reads). Taken a little in, past the fade from black most generated clips open with.
 */
export async function videoPoster(
  bytes: Uint8Array,
  durationS: number | null,
  ffmpeg = process.env.FFMPEG_PATH || "ffmpeg",
): Promise<Buffer | null> {
  const dir = await mkdtemp(join(tmpdir(), "casama-poster-"));
  // A file, not a pipe: MP4s with their index at the end need to seek.
  const input = join(dir, "in");
  try {
    await writeFile(input, bytes);
    const grab = (at: number) =>
      new Promise<Buffer | null>((resolve) => {
        execFile(
          ffmpeg,
          [
            "-hide_banner",
            "-loglevel",
            "error",
            ...(at > 0 ? ["-ss", at.toFixed(2)] : []),
            "-i",
            input,
            "-frames:v",
            "1",
            "-vf",
            `scale='if(gt(iw,ih),min(${POSTER_SIZE},iw),-2)':'if(gt(iw,ih),-2,min(${POSTER_SIZE},ih))'`,
            "-q:v",
            "4",
            "-f",
            "image2",
            "-c:v",
            "mjpeg",
            "pipe:1",
          ],
          { encoding: "buffer", timeout: POSTER_TIMEOUT_MS, maxBuffer: 8 * 1024 * 1024 },
          (err, stdout) => resolve(err || stdout.length === 0 ? null : stdout),
        );
      });
    const at = Math.min(1, Math.max(0, (durationS ?? 0) * 0.1));
    return (await grab(at)) ?? (at > 0 ? await grab(0) : null);
  } finally {
    await rm(dir, { recursive: true, force: true }).catch(() => {});
  }
}

export function registerChatMediaRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  // Posters made since the server started (chat media never changes under its id), and the
  // ones being made, so a chat full of clips opened on two devices runs ffmpeg once per clip.
  const posters = new Map<string, Buffer | null>();
  const making = new Map<string, Promise<Buffer | null>>();

  /** The file's details when the caller is a member of its workspace, else a 401 or 404. */
  async function readable(claims: JwtClaims | undefined, id: string) {
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    const missing = () => new ApiError(404, "media_not_found", "No such file");
    if (!/^[0-9a-f-]{36}$/i.test(id)) throw missing();
    const [meta] = await db.execute<{
      org_id: string;
      content_type: string;
      size: number;
      duration_s: number | null;
    }>(sql`
      select org_id, content_type, size, duration_s from public.chat_media where id = ${id}::uuid`);
    if (!meta) throw missing();
    const [m] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.is_member(${meta.org_id}::uuid) as ok`),
    );
    if (!m?.ok) throw missing();
    return { meta, missing };
  }

  // A video's poster (a JPEG still), so a chat card shows a picture at once instead of opening
  // a player to draw the first frame. Clients keep it on disk; it never changes.
  app.get("/v1/media/:id/poster", async (c) => {
    const id = c.req.param("id");
    const { meta, missing } = await readable(c.get("claims") as JwtClaims | undefined, id);
    if (!meta.content_type.startsWith("video/")) throw missing();
    let poster = posters.get(id);
    if (poster === undefined) {
      let pending = making.get(id);
      if (!pending) {
        pending = (async () => {
          const bytes = await readMedia(db, deps.objects, id);
          return bytes ? videoPoster(bytes, meta.duration_s) : null;
        })().finally(() => making.delete(id));
        making.set(id, pending);
      }
      poster = await pending;
      posters.set(id, poster);
      while (posters.size > POSTERS_KEPT) posters.delete(posters.keys().next().value!);
    }
    if (!poster) throw new ApiError(404, "poster_unavailable", "No poster for this file");
    return c.body(new Uint8Array(poster), 200, {
      "content-type": "image/jpeg",
      "content-length": String(poster.length),
      "cache-control": "private, max-age=31536000, immutable",
      "content-security-policy": "default-src 'none'",
    });
  });

  app.get("/v1/media/:id", async (c) => {
    const id = c.req.param("id");
    const { meta, missing } = await readable(c.get("claims") as JwtClaims | undefined, id);

    const size = Number(meta.size);
    const headers: Record<string, string> = {
      "content-type": meta.content_type,
      "cache-control": "private, max-age=31536000, immutable",
      "accept-ranges": "bytes",
      "content-security-policy": "default-src 'none'",
    };
    const rangeHeader = c.req.header("range");
    if (rangeHeader) {
      const range = parseRange(rangeHeader, size);
      if (!range) return c.body(null, 416, { ...headers, "content-range": `bytes */${size}` });
      const length = range.end - range.start + 1;
      const part = await readMedia(db, deps.objects, id, range);
      if (!part) throw missing();
      return c.body(new Uint8Array(part), 206, {
        ...headers,
        "content-range": `bytes ${range.start}-${range.end}/${size}`,
        "content-length": String(length),
      });
    }
    const all = await readMedia(db, deps.objects, id);
    if (!all) throw missing();
    return c.body(new Uint8Array(all), 200, {
      ...headers,
      "content-length": String(size),
    });
  });
}
