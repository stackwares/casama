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
export async function purgeDeletedCreations(db: Database, days = CREATION_PURGE_DAYS) {
  const old = sql`deleted_at < now() - make_interval(days => ${days})`;
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
export function registerLibraryTools(registry: ToolRegistry, deps: { db: Database }) {
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
}
