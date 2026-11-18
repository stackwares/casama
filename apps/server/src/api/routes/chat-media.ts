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
import { checkStorage, readMedia, StorageFullError, track, verifyFileLink } from "@casama/agent";
import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { internalToken } from "./local.ts";

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

/** Largest upload: the chat_media size check (50 MB). */
export const MAX_MEDIA_UPLOAD = 52_428_800;
/** Attachments a person may send in a day (they don't count against the Library's storage). */
export const DAILY_ATTACHMENTS = 300;
const DAILY_ATTACHMENT_BYTES = 1024 ** 3;
/** The advisory lock's second key for the daily attachment check (the first is the person). */
const ATTACHMENT_LOCK = 3230;

/** Reads a request body, refusing it as soon as it passes [max] bytes (a chunked body has no length). */
export async function readCapped(
  body: ReadableStream<Uint8Array> | null,
  max: number,
  tooBig: () => Error,
): Promise<Uint8Array> {
  if (!body) return new Uint8Array(0);
  const reader = body.getReader();
  const chunks: Uint8Array[] = [];
  let size = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    size += value.length;
    if (size > max) {
      await reader.cancel().catch(() => {});
      throw tooBig();
    }
    chunks.push(value);
  }
  const out = new Uint8Array(size);
  let at = 0;
  for (const c of chunks) {
    out.set(c, at);
    at += c.length;
  }
  return out;
}

/** No scripts, no network, no files and no frames while a page saved from the browser is printed. */
const PRINT_CSP =
  "default-src 'none'; style-src 'unsafe-inline'; img-src data:; font-src data:; base-uri 'none'; form-action 'none'";

/**
 * HTML from the browser, made safe to print: a strict policy first in its head (any policy of its
 * own still applies too) and no meta refresh, which a policy can't stop.
 */
export function printable(html: string): string {
  const meta = `<meta http-equiv="Content-Security-Policy" content="${PRINT_CSP}">`;
  let out = html.replace(/<meta[^>]+http-equiv\s*=\s*["']?refresh[^>]*>/gi, "");
  if (!/<html[\s>]/i.test(out))
    out = `<!doctype html><html><head></head><body>${out}</body></html>`;
  if (!/<head[\s>]/i.test(out)) out = out.replace(/<html[^>]*>/i, (m) => `${m}<head></head>`);
  return out.replace(/<head[^>]*>/i, (m) => `${m}${meta}`);
}

/** The type an upload is kept as: what it says it is, within reason. HTML only as a PDF. */
export function uploadType(header: string | undefined, name: string): string {
  const t = (header ?? "").split(";")[0]!.trim().toLowerCase();
  const byName: Record<string, string> = {
    md: "text/markdown",
    txt: "text/plain",
    csv: "text/csv",
    pdf: "application/pdf",
    png: "image/png",
    jpg: "image/jpeg",
    jpeg: "image/jpeg",
    webp: "image/webp",
    gif: "image/gif",
  };
  const ext = /\.([a-z0-9]+)$/i.exec(name)?.[1]?.toLowerCase() ?? "";
  if (t && t !== "application/octet-stream" && /^[a-z]+\/[a-z0-9.+-]+$/.test(t)) {
    if (t === "text/html" || t === "application/xhtml+xml" || t === "image/svg+xml")
      throw new ApiError(400, "unsupported_type", "Send HTML with convert=pdf");
    return t;
  }
  return byName[ext] ?? "application/octet-stream";
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

  // Casama for Chrome (D-323): a screenshot or file for a message, kept here so asking about it
  // doesn't wake the bot's computer; or a page saved to the Library (Save to Library).
  app.openapi(routes.uploadMedia, async (c) => {
    const claims = c.get("claims") as JwtClaims | undefined;
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    const q = c.req.valid("query");
    const tooBig = () => new ApiError(400, "file_too_large", "Files are limited to 50 MB");
    if (Number(c.req.header("content-length") ?? 0) > MAX_MEDIA_UPLOAD * 2) throw tooBig();
    const [m] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.is_member(${q.org_id}::uuid) as ok`),
    );
    if (!m?.ok) throw new ApiError(404, "org_not_found", "No such workspace");
    let bytes = await readCapped(c.req.raw.body, MAX_MEDIA_UPLOAD * 2, tooBig);
    let type: string;
    let name = q.name.trim();
    if (q.convert === "pdf") {
      if (!deps.pdf) throw new ApiError(409, "pdf_unavailable", "This server can't make PDFs");
      if (bytes.length > MAX_MEDIA_UPLOAD) throw tooBig();
      bytes = new Uint8Array(await deps.pdf.render(printable(new TextDecoder().decode(bytes))));
      type = "application/pdf";
      if (!/\.pdf$/i.test(name)) name = `${name.replace(/\.html?$/i, "")}.pdf`;
    } else {
      type = uploadType(c.req.header("content-type"), name);
    }
    if (bytes.length === 0) throw new ApiError(400, "empty_file", "The file is empty");
    if (bytes.length > MAX_MEDIA_UPLOAD) throw tooBig();
    const library = q.purpose === "library";
    // Attachments count toward storage as well (a trigger adds them), so both are checked.
    try {
      await checkStorage(db, q.org_id, bytes.length);
    } catch (e) {
      if (e instanceof StorageFullError) throw new ApiError(409, e.code, e.message);
      throw e;
    }
    let projectId: string | null = null;
    if (q.project_id) {
      const [p] = await withUserSession(db, claims, (tx) =>
        tx.execute<{ id: string }>(sql`
          select id from public.projects where id = ${q.project_id}::uuid and org_id = ${q.org_id}::uuid`),
      );
      if (!p) throw new ApiError(404, "project_not_found", "No such project");
      projectId = p.id;
    }
    // The daily attachment limit is checked and the row written under one lock per person, so
    // uploads sent side by side can't all pass the check.
    const row = await db.transaction(async (tx) => {
      if (!library) {
        await tx.execute(
          sql`select pg_advisory_xact_lock(hashtext(${claims.sub}), ${ATTACHMENT_LOCK})`,
        );
        const [day] = await tx.execute<{ n: number; total: string }>(sql`
          select count(*)::int as n, coalesce(sum(size), 0)::text as total from public.chat_media
          where uploaded_by = ${claims.sub}::uuid and not in_library
            and created_at > now() - interval '1 day'`);
        if (
          (day?.n ?? 0) >= DAILY_ATTACHMENTS ||
          Number(day?.total ?? 0) + bytes.length > DAILY_ATTACHMENT_BYTES
        )
          throw new ApiError(
            429,
            "rate_limited",
            "That's a lot of files today. Try again tomorrow.",
          );
      }
      const [r] = await tx.execute<{ id: string }>(sql`
        insert into public.chat_media (org_id, name, content_type, bytes, size, uploaded_by, in_library)
        values (${q.org_id}::uuid, ${name.slice(0, 200)}, ${type}, ${Buffer.from(bytes)}, ${bytes.length},
                ${claims.sub}::uuid, ${library})
        returning id`);
      return r;
    });
    const id = row!.id;
    let creationId: string | null = null;
    if (library) {
      const [cr] = await db.execute<{ id: string }>(sql`
        update public.creations set project_id = coalesce(${projectId}::uuid, project_id)
        where media_id = ${id}::uuid returning id`);
      creationId = cr?.id ?? null;
    }
    track(db, {
      event: "media_uploaded",
      userId: claims.sub,
      orgId: q.org_id,
      properties: {
        purpose: library ? "library" : "attachment",
        converted: q.convert === "pdf",
        size_bytes: bytes.length,
      },
    });
    return c.json(
      {
        id,
        path: `media:${id}`,
        name,
        mime_type: type,
        size: bytes.length,
        creation_id: creationId,
      },
      201,
    );
  });

  // Chat apps' file links (D-342): a file a chat app couldn't take as an attachment, opened by
  // whoever holds the signed link until it expires (7 days). Under /hooks so every install's
  // proxy already routes it. A deleted file's link stops working.
  app.get("/hooks/files/:token", async (c) => {
    const target = verifyFileLink(internalToken(deps.env), c.req.param("token"));
    const gone = () =>
      c.json({ code: "not_found", message: "This link has expired or the file is gone." }, 404);
    if (!target) return gone();
    let meta: { name: string; type: string; size: number } | null = null;
    let read: (range?: { start: number; end: number }) => Promise<Uint8Array | null>;
    if (target.kind === "media") {
      const [m] = await db.execute<{ name: string | null; content_type: string; size: number }>(sql`
        select name, content_type, size from public.chat_media where id = ${target.id}::uuid`);
      if (m) meta = { name: m.name ?? "file", type: m.content_type, size: Number(m.size) };
      read = (range) => readMedia(db, deps.objects, target.id, range);
    } else {
      const [k] = await db.execute<{
        name: string;
        mime: string | null;
        size: string;
        blob_key: string | null;
      }>(sql`
        select coalesce(nullif(regexp_replace(origin_path, '^.*/', ''), ''), title) as name, mime, size::text, blob_key
        from public.creations where id = ${target.id}::uuid`);
      if (k?.blob_key && deps.objects)
        meta = { name: k.name, type: k.mime ?? "application/octet-stream", size: Number(k.size) };
      read = async (range) => {
        const { readObject } = await import("@casama/sandbox");
        const all =
          deps.objects && k?.blob_key
            ? await readObject(deps.objects, k.blob_key).catch(() => null)
            : null;
        return all && range ? all.subarray(range.start, range.end + 1) : all;
      };
    }
    if (!meta) return gone();
    // Pictures, video, audio and PDFs open in the browser; anything else downloads.
    const inline = /^(image\/(png|jpeg|gif|webp)|video\/|audio\/|application\/pdf$)/.test(
      meta.type,
    );
    const headers: Record<string, string> = {
      "content-type": meta.type,
      "cache-control": "private, max-age=3600",
      "accept-ranges": "bytes",
      "content-security-policy":
        "default-src 'none'; img-src 'self'; media-src 'self'; style-src 'unsafe-inline'",
      "content-disposition": `${inline ? "inline" : "attachment"}; filename*=UTF-8''${encodeURIComponent(meta.name)}`,
    };
    const rangeHeader = c.req.header("range");
    if (rangeHeader) {
      const range = parseRange(rangeHeader, meta.size);
      if (!range) return c.body(null, 416, { ...headers, "content-range": `bytes */${meta.size}` });
      const part = await read(range);
      if (!part) return gone();
      return c.body(new Uint8Array(part), 206, {
        ...headers,
        "content-range": `bytes ${range.start}-${range.end}/${meta.size}`,
        "content-length": String(range.end - range.start + 1),
      });
    }
    const all = await read();
    if (!all) return gone();
    return c.body(new Uint8Array(all), 200, { ...headers, "content-length": String(all.length) });
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
