/**
 * The Library (docs/LIBRARY-PLAN.md; D-274): what bots made, indexed in `public.creations`.
 * Pages and generated media reach it through database triggers; this file holds what the agent
 * and the worker add on top: titles, the bot's own tools to find its work, and the purge.
 */
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { ToolError, type ToolRegistry } from "./tools/registry.ts";

/** Deleted creations are purged after this many days. */
export const CREATION_PURGE_DAYS = 30;

/** A Library title from a prompt or the bot's own name for it: one line, about 8 words, 80 characters. */
export function titleFromText(text: string): string {
  const line = text.replace(/\s+/g, " ").trim();
  if (!line) return "";
  const words = line.split(" ");
  let out = words.slice(0, 8).join(" ");
  if (out.length > 80) out = `${out.slice(0, 79).replace(/\s+\S*$/, "")}…`;
  else if (words.length > 8) out = `${out}…`;
  return out.replace(/^./, (c) => c.toUpperCase());
}

/**
 * Removes what was deleted over 30 days ago: the page or media row (whose foreign key removes the
 * creation), then any creation with nothing behind it. Returns how many creations went.
 */
export async function purgeDeletedCreations(
  db: Database,
  days = CREATION_PURGE_DAYS,
  store?: import("@casama/sandbox").ObjectStore,
) {
  const old = sql`deleted_at < now() - make_interval(days => ${days})`;
  // Kept files' bytes first: the rows that name them go below.
  if (store) {
    const blobs = await db.execute<{ blob_key: string }>(sql`
      select v.blob_key from public.creation_versions v
      join public.creations c on c.id = v.creation_id where c.${sql.raw("deleted_at")} < now() - make_interval(days => ${days})
      union select blob_key from public.creations where ${old} and blob_key is not null
      union select preview_key from public.creations where ${old} and preview_key is not null
      union select cover_key from public.creations where ${old} and cover_key is not null
      limit 2000`);
    for (const b of blobs) await store.delete(b.blob_key).catch(() => {});
  }
  const rows = await db.execute<{ n: number }>(sql`
    with gone as (select id, page_id, media_id from public.creations where ${old} limit 500),
    m as (delete from public.chat_media where id in (select media_id from gone where media_id is not null) returning 1),
    p as (delete from public.pages where id in (select page_id from gone where page_id is not null) returning 1),
    c as (delete from public.creations where id in (select id from gone) returning 1)
    select (select count(*) from gone)::int as n`);
  return rows[0]?.n ?? 0;
}

interface LibraryRow {
  id: string;
  kind: string;
  label: string | null;
  title: string;
  page_id: string | null;
  media_id: string | null;
  mime: string | null;
  size: string | number;
  created_at: Date;
  conversation_id: string | null;
  [k: string]: unknown;
}

const line = (r: LibraryRow) =>
  `- ${r.title} (${r.label ?? r.kind}; ${r.created_at.toISOString().slice(0, 10)}; id ${r.id}${
    r.page_id ? `; page ${r.page_id}` : r.media_id ? `; media:${r.media_id}` : ""
  })`;

/**
 * library.list and library.get: a bot finds its own earlier work and the handle to change it
 * (a page id for pages.publish, media:<id> for media tools). Only this bot's creations, and only
 * ones from chats the person it acts for could see.
 */
export function registerLibraryTools(
  registry: ToolRegistry,
  deps: { db: Database; objects?: import("@casama/sandbox").ObjectStore },
) {
  const { db } = deps;
  // A bot acting for someone sees only what that person could (bot sharing, D-131; D-091).
  const visibleTo = (runId: string) => sql`exists (
    select 1 from public.runs r where r.id = ${runId}::uuid and (
      c.conversation_id = r.conversation_id
      or (c.conversation_id is not null and exists (
            select 1 from public.conversations cv
            where cv.id = c.conversation_id and (not cv.private or cv.created_by = r.created_by)))
      or (c.conversation_id is null and (c.made_for is null or c.made_for = r.created_by)))
    and (c.page_id is null or exists (
          select 1 from public.pages p
          where p.id = c.page_id and (p.visibility <> 'private' or p.created_by = r.created_by))))`;

  registry.register({
    name: "library.list",
    description:
      "List things you made earlier that are in the person's Library (pages, pictures, videos, files), newest first, to find one to show, reuse or change. Filter by kind or words in the title.",
    risk: "low",
    readOnly: true,
    schema: z.object({
      kind: z.enum(["page", "image", "video", "audio", "document", "file"]).optional(),
      query: z.string().max(200).optional(),
      limit: z.number().int().min(1).max(50).optional(),
    }),
    async execute(args, ctx) {
      const rows = await db.execute<LibraryRow>(sql`
        select c.id, c.kind, c.label, c.title, c.page_id, c.media_id, c.mime, c.size, c.created_at, c.conversation_id
        from public.creations c
        where c.bot_id = ${ctx.botId}::uuid and c.deleted_at is null and ${visibleTo(ctx.runId)}
          ${args.kind ? sql`and c.kind = ${args.kind}` : sql``}
          ${args.query ? sql`and c.title ilike ${`%${args.query.replace(/[\\%_]/g, (x) => `\\${x}`)}%`}` : sql``}
        order by c.created_at desc limit ${args.limit ?? 20}`);
      if (!rows.length) return { content: "Nothing in the Library matches.", preview: "none" };
      return {
        content: `${rows.length} found:\n${rows.map(line).join("\n")}\nChange a page with pages.publish and its page id; use media with media:<id>.`,
        preview: `${rows.length} found`,
      };
    },
  });

  registry.register({
    name: "library.get",
    description:
      "Details of one thing in the Library by its id, with the handle to change or reuse it.",
    risk: "low",
    readOnly: true,
    schema: z.object({ id: z.uuid() }),
    async execute(args, ctx) {
      const [r] = await db.execute<
        LibraryRow & { version: number; width: number | null; height: number | null }
      >(sql`
        select c.id, c.kind, c.label, c.title, c.page_id, c.media_id, c.mime, c.size, c.created_at,
               c.conversation_id, c.version, c.width, c.height
        from public.creations c
        where c.id = ${args.id}::uuid and c.bot_id = ${ctx.botId}::uuid and c.deleted_at is null
          and ${visibleTo(ctx.runId)}`);
      if (!r)
        throw new ToolError("not_found", "Nothing in the Library with that id that you made.");
      return {
        content: [
          line(r),
          `Version ${r.version}, ${Number(r.size)} bytes${r.mime ? `, ${r.mime}` : ""}${r.width ? `, ${r.width}×${r.height}` : ""}.`,
          r.page_id
            ? `To change it, call pages.publish with page_id ${r.page_id}.`
            : r.media_id
              ? `To reuse it, pass media:${r.media_id} to a media tool, or files.from_chat to put it on your computer.`
              : "",
        ]
          .filter(Boolean)
          .join("\n"),
        preview: r.title,
      };
    },
  });

  registry.register({
    name: "library.save",
    description:
      "Keep a file from your computer in the person's Library (a report, a site's zip, a song) even if you don't link it in your reply. Files you link in a reply are kept on their own. Saving the same path again keeps a new version.",
    risk: "low",
    selfOnly: true,
    requires: { computer: true },
    ready: async () => !!deps.objects,
    schema: z.object({
      path: z.string().min(1).max(1000),
      title: z.string().max(200).optional(),
      label: z.string().max(24).optional().describe("Site, Game, Report, Slides, Sheet…"),
    }),
    async execute(args, ctx) {
      if (!deps.objects)
        throw new ToolError(
          "library_unavailable",
          "This server doesn't keep files in the Library.",
        );
      if (!ctx.computer) throw new ToolError("no_computer", "This bot has no computer available.");
      const h = await ctx.computer();
      const bytes = await h.readFile(args.path);
      const [run] = await db.execute<{ conversation_id: string | null; created_by: string | null }>(
        sql`select conversation_id, created_by from public.runs where id = ${ctx.runId}::uuid`,
      );
      const [computer] = await db.execute<{ id: string }>(sql`
        select coalesce(b.default_computer_id, c.id) as id from public.bots b
        left join public.computers c on c.org_id = b.org_id and c.kind <> 'local'
        where b.id = ${ctx.botId}::uuid order by c.created_at limit 1`);
      if (!computer?.id) throw new ToolError("no_computer", "This bot has no computer available.");
      try {
        const k = await keepFile(db, deps.objects, {
          orgId: ctx.orgId,
          botId: ctx.botId,
          computerId: computer.id,
          runId: ctx.runId,
          conversationId: run?.conversation_id ?? null,
          madeFor: ctx.actingUserId ?? run?.created_by ?? null,
          path: args.path.replace(/\/+$/, ""),
          bytes,
          title: args.title,
          label: args.label,
        });
        if (!k)
          throw new ToolError("not_kept", "That file is empty or over 50 MB, so it can't be kept.");
        return {
          content: `Kept "${k.title}" in the Library (version ${k.version}, id ${k.creation_id}).`,
          preview: k.title,
        };
      } catch (err) {
        if (err instanceof StorageFullError) throw new ToolError("storage_full", err.message);
        throw err;
      }
    },
  });
}

/** Files bigger than this aren't kept (they stay on the computer). */
export const KEEP_FILE_MAX_BYTES = 50 * 1024 * 1024;
/** At most this many files are kept per reply. */
export const KEEP_FILES_PER_REPLY = 8;
/** Older versions of a kept file beyond this are dropped. */
export const KEEP_VERSIONS = 5;

/** A workspace's storage cap in bytes, or null for none (self-hosted, or no plan says one). */
export async function storageCap(db: Database, orgId: string): Promise<number | null> {
  const [e] = await db.execute<{ gb: string | null; unlimited: boolean | null }>(sql`
    select limits ->> 'storage_gb' as gb, (limits ->> 'unlimited')::boolean as unlimited
    from public.entitlements where org_id = ${orgId}::uuid order by created_at desc limit 1`);
  if (!e || e.unlimited || e.gb == null) return null;
  return Number(e.gb) * 1024 ** 3;
}

/** Thrown when a workspace's Library is full (LIBRARY-PLAN §9): nothing is deleted for them. */
export class StorageFullError extends Error {
  readonly code = "storage_full";
  constructor() {
    super(
      "The workspace's Library is full, so nothing new can be kept. Delete things you don't need from the Library, or move to a bigger plan in Billing.",
    );
  }
}

/** Throws StorageFullError when adding `bytes` would pass the workspace's cap. */
export async function checkStorage(db: Database, orgId: string, bytes: number) {
  const cap = await storageCap(db, orgId);
  if (cap == null) return;
  const [o] = await db.execute<{ used: string }>(sql`
    select storage_bytes::text as used from public.organizations where id = ${orgId}::uuid`);
  if (Number(o?.used ?? 0) + bytes > cap) throw new StorageFullError();
}

const MIME: Record<string, string> = {
  pdf: "application/pdf",
  md: "text/markdown",
  txt: "text/plain",
  csv: "text/csv",
  html: "text/html",
  htm: "text/html",
  json: "application/json",
  png: "image/png",
  jpg: "image/jpeg",
  jpeg: "image/jpeg",
  webp: "image/webp",
  gif: "image/gif",
  svg: "image/svg+xml",
  mp4: "video/mp4",
  mov: "video/quicktime",
  webm: "video/webm",
  mp3: "audio/mpeg",
  wav: "audio/wav",
  m4a: "audio/mp4",
  ogg: "audio/ogg",
  zip: "application/zip",
  docx: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  xlsx: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  pptx: "application/vnd.openxmlformats-officedocument.presentationml.presentation",
};
export const mimeOf = (name: string) =>
  MIME[name.toLowerCase().split(".").pop() ?? ""] ?? "application/octet-stream";

export interface KeptFile {
  creation_id: string;
  kind: string;
  title: string;
  name: string;
  mime_type: string;
  size: number;
  path: string;
  version: number;
}

/**
 * Keeps a copy of a file from the bot's computer in the Library (D-276): the bytes go to the
 * object store, and the creation for (bot, computer, path) is made or gets a new version.
 * Returns null when the file is too big, empty or unchanged since the last version.
 */
export async function keepFile(
  db: Database,
  store: import("@casama/sandbox").ObjectStore,
  input: {
    orgId: string;
    botId: string;
    computerId: string;
    runId: string;
    conversationId: string | null;
    madeFor: string | null;
    path: string;
    bytes: Uint8Array;
    title?: string;
    label?: string;
  },
): Promise<KeptFile | null> {
  const size = input.bytes.length;
  if (size === 0 || size > KEEP_FILE_MAX_BYTES) return null;
  const name = input.path.split("/").filter(Boolean).pop() ?? "file";
  const mime = mimeOf(name);
  const [prev] = await db.execute<{
    id: string;
    version: number;
    size: string;
    blob_key: string;
  }>(sql`
    select id, version, size::text, blob_key from public.creations
    where bot_id = ${input.botId}::uuid and computer_id = ${input.computerId}::uuid
      and origin_path = ${input.path} and blob_key is not null`);
  const { createHash, randomUUID } = await import("node:crypto");
  const digest = createHash("sha256").update(input.bytes).digest("hex").slice(0, 16);
  // The same bytes as last time: nothing new to keep.
  if (prev?.blob_key.includes(digest))
    return {
      creation_id: prev.id,
      kind:
        (
          await db.execute<{ kind: string }>(
            sql`select kind from public.creations where id = ${prev.id}::uuid`,
          )
        )[0]?.kind ?? "file",
      title: name,
      name,
      mime_type: mime,
      size,
      path: input.path,
      version: prev.version,
    };
  await checkStorage(db, input.orgId, size);
  const id = prev?.id ?? randomUUID();
  const version = (prev?.version ?? 0) + 1;
  const key = `creations/${input.orgId}/${id}/${version}-${digest}/${name.replace(/[^\w.-]/g, "_")}`;
  await store.put(key, input.bytes);
  const title = titleFromText(input.title ?? name.replace(/\.[^.]+$/, "")) || name;
  const [row] = await db.execute<{ id: string; kind: string; title: string }>(sql`
    insert into public.creations (id, org_id, bot_id, made_for, conversation_id, run_id, kind, label,
      title, blob_key, computer_id, origin_path, mime, size, version)
    values (${id}::uuid, ${input.orgId}::uuid, ${input.botId}::uuid, ${input.madeFor}::uuid,
      ${input.conversationId}::uuid, ${input.runId}::uuid, public.creation_kind(${mime}),
      ${input.label?.trim().slice(0, 24) || null}, ${title.slice(0, 200)}, ${key},
      ${input.computerId}::uuid, ${input.path}, ${mime}, ${size}, ${version})
    on conflict (bot_id, computer_id, origin_path) where blob_key is not null do update set
      blob_key = excluded.blob_key, size = excluded.size, version = excluded.version,
      run_id = excluded.run_id, mime = excluded.mime, deleted_at = null, updated_at = now(),
      label = coalesce(excluded.label, creations.label)
    returning id, kind, title`);
  await db.execute(sql`
    insert into public.creation_versions (creation_id, version, org_id, blob_key, size)
    values (${row?.id}::uuid, ${version}, ${input.orgId}::uuid, ${key}, ${size})
    on conflict do nothing`);
  // Older versions beyond five go, bytes and all.
  const old = await db.execute<{ version: number; blob_key: string }>(sql`
    delete from public.creation_versions where creation_id = ${row?.id}::uuid
      and version <= ${version - KEEP_VERSIONS} returning version, blob_key`);
  for (const o of old) await store.delete(o.blob_key).catch(() => {});
  return {
    creation_id: row?.id as string,
    kind: row?.kind ?? "file",
    title: row?.title ?? title,
    name,
    mime_type: mime,
    size,
    path: input.path,
    version,
  };
}

/** File endings that get a PDF preview and a cover when kept (D-280). */
const PREVIEWABLE = new Set([
  "pdf",
  "docx",
  "doc",
  "odt",
  "rtf",
  "pptx",
  "ppt",
  "odp",
  "xlsx",
  "xls",
  "ods",
]);
export const previewable = (name: string) =>
  PREVIEWABLE.has(name.toLowerCase().split(".").pop() ?? "");

const shellQuote = (s: string) => `'${s.replace(/'/g, "'\\''")}'`;

/**
 * Prints a PDF of the document and a PNG of its first page (about 640 px wide), one path per line.
 * Office files go through LibreOffice; a PDF is used as it is. Exit 44: no file; 45: no tools.
 */
export function documentPreviewScript(file: string) {
  return [
    `f=${shellQuote(file)}`,
    `[ -f "$f" ] || exit 44`,
    "command -v pdftoppm >/dev/null 2>&1 || exit 45",
    "t=$(mktemp -d)",
    `case "$f" in`,
    `  *.pdf|*.PDF) pdf="$f" ;;`,
    `  *) command -v soffice >/dev/null 2>&1 || exit 45`,
    `     timeout 90 soffice --headless --norestore "-env:UserInstallation=file:///tmp/casama-lo-profile" --convert-to pdf --outdir "$t" "$f" >/dev/null 2>&1 || exit 46`,
    `     pdf=$(ls "$t"/*.pdf 2>/dev/null | head -n 1); [ -n "$pdf" ] || exit 46 ;;`,
    "esac",
    `timeout 30 pdftoppm -png -singlefile -scale-to 640 -f 1 -l 1 "$pdf" "$t/cover" >/dev/null 2>&1 || exit 47`,
    `echo "$pdf"`,
    `echo "$t/cover.png"`,
  ].join("\n");
}

/**
 * Makes a kept document's PDF preview and cover on its computer and stores both (D-280). Best
 * effort: a document without them still opens, as the original file.
 */
export async function keepDocumentPreview(
  db: Database,
  store: import("@casama/sandbox").ObjectStore,
  h: import("@casama/sandbox").SandboxHandle,
  kept: { creation_id: string; version: number; path: string; name: string },
) {
  if (!previewable(kept.name)) return false;
  const { collectExec } = await import("@casama/sandbox");
  const abs = kept.path.startsWith("/")
    ? kept.path
    : kept.path.startsWith("~/")
      ? `/home/casama/${kept.path.slice(2)}`
      : `/home/casama/workspace/${kept.path.replace(/^\.\//, "")}`;
  const r = await collectExec(h.exec(documentPreviewScript(abs), { timeoutMs: 150_000 }));
  if (r.code !== 0) return false;
  const [pdfPath, coverPath] = r.stdout
    .trim()
    .split("\n")
    .map((l: string) => l.trim());
  if (!pdfPath || !coverPath) return false;
  const pdf = await h.readFile(pdfPath);
  const cover = await h.readFile(coverPath);
  const [org] = await db.execute<{ org_id: string }>(
    sql`select org_id from public.creations where id = ${kept.creation_id}::uuid`,
  );
  if (!org) return false;
  const previewKey = `previews/${org.org_id}/${kept.creation_id}/${kept.version}.pdf`;
  const coverKey = `covers/${org.org_id}/${kept.creation_id}/${kept.version}.png`;
  if (pdf.length <= KEEP_FILE_MAX_BYTES) await store.put(previewKey, pdf);
  await store.put(coverKey, cover);
  const size = pngSize(cover);
  await db.execute(sql`
    update public.creations set
      preview_key = ${pdf.length <= KEEP_FILE_MAX_BYTES ? previewKey : null},
      cover_key = ${coverKey}, cover_w = ${size?.w ?? null}, cover_h = ${size?.h ?? null}
    where id = ${kept.creation_id}::uuid and version = ${kept.version}`);
  return true;
}

/** A PNG's width and height from its header. */
export function pngSize(b: Uint8Array): { w: number; h: number } | null {
  if (b.length < 24 || b[0] !== 0x89 || b[1] !== 0x50) return null;
  const v = new DataView(b.buffer, b.byteOffset, b.byteLength);
  return { w: v.getUint32(16), h: v.getUint32(20) };
}
