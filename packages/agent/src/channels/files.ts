/**
 * Files in chat apps (D-342). Out: the images, videos, audio and files a reply carries go to the
 * chat app as attachments, or as a signed link when the app can't take them. In: photos, files and
 * voice notes people send are saved like attachments in the app, so the bot can see and use them.
 */
import { createHmac, timingSafeEqual } from "node:crypto";
import type { Database } from "@casama/db";
import type { ObjectStore } from "@casama/sandbox";
import { sql } from "drizzle-orm";
import { computerPathFromLink } from "../file-links.ts";
import { readMedia } from "../media-store.ts";

/** A file going out to a chat app. `url` is a signed link to the same bytes (2.2). */
export interface OutFile {
  name: string;
  mime: string;
  size: number;
  bytes: Uint8Array;
  url?: string;
}

/** A file someone sent in a chat app, before it's downloaded. `fetch` is what the adapter needs. */
export interface InFile {
  name?: string;
  mime?: string;
  size?: number;
  fetch: Record<string, unknown>;
}

/** Most files a reply sends; the rest go as links (Twilio and Discord take ten). */
export const MAX_FILES_OUT = 10;
/** Largest file read from a chat app, and most per message. */
export const MAX_FILE_IN = 25 * 1024 * 1024;
export const MAX_FILES_IN = 10;
/** Shared with the app's uploads (chat-media.ts): files a person may send in a day. */
const DAILY_FILES = 300;
const DAILY_BYTES = 1024 ** 3;
const ATTACHMENT_LOCK = 3230;

// ------------------------------------------------------------------ Signed links
export interface FileLinks {
  /** The server's public address, where /hooks/files/{token} is served. */
  base: string;
  /** The server's internal token; links are signed with a key derived from it. */
  key: string;
}

/** How long a link in a chat works. */
export const FILE_LINK_TTL_MS = 7 * 24 * 3600 * 1000;

const linkKey = (secret: string) =>
  createHmac("sha256", secret).update("casama-file-links").digest();

export type FileTarget =
  | { kind: "media"; id: string }
  | { kind: "creation"; id: string; version: number };

export function signFileLink(secret: string, target: FileTarget, expiresAt: number): string {
  const body = Buffer.from(
    JSON.stringify(
      target.kind === "media"
        ? { m: target.id, e: Math.floor(expiresAt / 1000) }
        : { c: target.id, v: target.version, e: Math.floor(expiresAt / 1000) },
    ),
  ).toString("base64url");
  const mac = createHmac("sha256", linkKey(secret)).update(body).digest("base64url");
  return `${body}.${mac}`;
}

/** The file a link names, or null when it's forged, malformed or expired. */
export function verifyFileLink(secret: string, token: string, now = Date.now()): FileTarget | null {
  const [body, mac] = token.split(".");
  if (!body || !mac) return null;
  const want = createHmac("sha256", linkKey(secret)).update(body).digest("base64url");
  if (want.length !== mac.length || !timingSafeEqual(Buffer.from(want), Buffer.from(mac)))
    return null;
  try {
    const p = JSON.parse(Buffer.from(body, "base64url").toString()) as Record<string, unknown>;
    if (typeof p.e !== "number" || p.e * 1000 < now) return null;
    const uuid = /^[0-9a-f-]{36}$/;
    if (typeof p.m === "string" && uuid.test(p.m)) return { kind: "media", id: p.m };
    if (typeof p.c === "string" && uuid.test(p.c) && typeof p.v === "number")
      return { kind: "creation", id: p.c, version: p.v };
  } catch {}
  return null;
}

export const fileLinkUrl = (links: FileLinks, target: FileTarget, now = Date.now()) =>
  `${links.base.replace(/\/$/, "")}/hooks/files/${signFileLink(links.key, target, now + FILE_LINK_TTL_MS)}`;

// ------------------------------------------------------------------ Out: what a reply carries
export interface ReplyFile {
  target: FileTarget;
  name: string;
  mime: string;
  size: number;
}

/** The files a reply carries, in the order the app shows them: generated media, then kept files. */
export async function replyFiles(
  db: Database,
  runId: string,
  kept: Array<{
    creation_id: string;
    name: string;
    mime_type: string;
    size: number;
    version: number;
  }> = [],
): Promise<ReplyFile[]> {
  const media = await db.execute<{
    id: string;
    name: string | null;
    content_type: string;
    size: number;
  }>(sql`
    select id, name, content_type, size from public.chat_media
    where run_id = ${runId}::uuid and uploaded_by is null order by created_at, id`);
  return [
    ...[...media].map((m) => ({
      target: { kind: "media" as const, id: m.id },
      name: m.name ?? defaultName(m.content_type),
      mime: m.content_type,
      size: Number(m.size),
    })),
    ...kept.map((k) => ({
      target: { kind: "creation" as const, id: k.creation_id, version: k.version },
      name: k.name,
      mime: k.mime_type,
      size: Number(k.size),
    })),
  ];
}

const EXT: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
  "image/gif": "gif",
  "video/mp4": "mp4",
  "audio/mpeg": "mp3",
  "audio/mp4": "m4a",
  "audio/ogg": "ogg",
  "audio/wav": "wav",
  "application/pdf": "pdf",
};

/** A file name for a file that has none, with the extension its type implies. */
export function defaultName(mime: string) {
  const kind = mime.split("/")[0];
  const base =
    kind === "image" ? "image" : kind === "video" ? "video" : kind === "audio" ? "audio" : "file";
  const ext = EXT[mime.split(";")[0]?.trim() ?? ""];
  return ext ? `${base}.${ext}` : base;
}

/** A file's bytes: media from chat_media, a kept file from the Library's store. */
export async function readReplyFile(
  db: Database,
  store: ObjectStore | null | undefined,
  f: ReplyFile,
): Promise<Uint8Array | null> {
  if (f.target.kind === "media") return readMedia(db, store, f.target.id);
  const [c] = await db.execute<{ blob_key: string | null }>(sql`
    select blob_key from public.creations where id = ${f.target.id}::uuid`);
  if (!c?.blob_key || !store) return null;
  const { readObject } = await import("@casama/sandbox");
  return readObject(store, c.blob_key).catch(() => null);
}

/**
 * Links to files on the bot's computer can't open in a chat app: the files go as attachments, and
 * the link keeps only its words (an image link keeps its alt text, or goes).
 */
export function unlinkComputerFiles(text: string): string {
  // Code is left alone: a link written as code is an example, not a link.
  return text.replace(
    /(```[\s\S]*?```|`[^`\n]*`)|(!?)\[([^\]\n]*)\]\(\s*<?([^)\s>]+)>?(?:\s+"[^"]*")?\s*\)/g,
    (all, code, bang, label, target) => {
      if (code) return code;
      if (!computerPathFromLink(target)) return all;
      if (bang) return label.trim();
      return label.trim() || target.split("/").pop() || target;
    },
  );
}

export const sizeText = (n: number) =>
  n >= 1024 * 1024
    ? `${(n / 1024 / 1024).toFixed(1)} MB`
    : `${Math.max(1, Math.round(n / 1024))} KB`;

/** A file as a line of text with its link, for apps (or files) that can't take it as an attachment. */
export const fileLinkLine = (f: { name: string; size: number }, url: string | undefined) =>
  url
    ? `📎 ${f.name} (${sizeText(f.size)}): ${url}`
    : `📎 ${f.name} (${sizeText(f.size)}) is in the Casama app.`;

// ------------------------------------------------------------------ In: saving what people send
/**
 * Saves a downloaded file like an attachment sent in the app (D-323): in chat_media, uploaded by
 * the person who connected the chat app, counted against their daily allowance. Returns the id,
 * or null when the allowance is used up.
 */
export async function saveInboundFile(
  db: Database,
  c: { org_id: string; bot_id: string; created_by: string },
  conversationId: string,
  file: { name: string; mime: string; bytes: Uint8Array },
): Promise<string | null> {
  return db.transaction(async (tx) => {
    await tx.execute(
      sql`select pg_advisory_xact_lock(hashtext(${c.created_by}), ${ATTACHMENT_LOCK})`,
    );
    const [day] = await tx.execute<{ n: number; total: string }>(sql`
      select count(*)::int as n, coalesce(sum(size), 0)::text as total from public.chat_media
      where uploaded_by = ${c.created_by}::uuid and not in_library and created_at > now() - interval '1 day'`);
    if ((day?.n ?? 0) >= DAILY_FILES || Number(day?.total ?? 0) + file.bytes.length > DAILY_BYTES)
      return null;
    const [r] = await tx.execute<{ id: string }>(sql`
      insert into public.chat_media (org_id, bot_id, conversation_id, name, content_type, bytes, size, uploaded_by, in_library)
      values (${c.org_id}::uuid, ${c.bot_id}::uuid, ${conversationId}::uuid, ${file.name.slice(0, 200)}, ${file.mime},
              ${Buffer.from(file.bytes)}, ${file.bytes.length}, ${c.created_by}::uuid, false)
      returning id`);
    return r?.id ?? null;
  });
}

/** What a file's first bytes say it is, when the app didn't say (or said octet-stream). */
export function sniffMime(bytes: Uint8Array, said?: string, name?: string): string {
  const s = said?.split(";")[0]?.trim().toLowerCase();
  if (s && s !== "application/octet-stream" && /^[a-z]+\/[\w.+-]+$/.test(s)) return s;
  const b = bytes;
  const at = (i: number, ...v: number[]) => v.every((x, k) => b[i + k] === x);
  if (at(0, 0xff, 0xd8, 0xff)) return "image/jpeg";
  if (at(0, 0x89, 0x50, 0x4e, 0x47)) return "image/png";
  if (at(0, 0x47, 0x49, 0x46, 0x38)) return "image/gif";
  if (at(0, 0x52, 0x49, 0x46, 0x46) && at(8, 0x57, 0x45, 0x42, 0x50)) return "image/webp";
  if (at(0, 0x25, 0x50, 0x44, 0x46)) return "application/pdf";
  if (at(0, 0x4f, 0x67, 0x67, 0x53)) return "audio/ogg";
  if (at(4, 0x66, 0x74, 0x79, 0x70)) return name?.match(/\.m4a$/i) ? "audio/mp4" : "video/mp4";
  if (at(0, 0x49, 0x44, 0x33) || at(0, 0xff, 0xfb)) return "audio/mpeg";
  const ext = name?.split(".").pop()?.toLowerCase();
  const byExt: Record<string, string> = {
    txt: "text/plain",
    csv: "text/csv",
    md: "text/markdown",
    json: "application/json",
    docx: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    xlsx: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    pptx: "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    zip: "application/zip",
  };
  return (ext && byExt[ext]) || "application/octet-stream";
}
