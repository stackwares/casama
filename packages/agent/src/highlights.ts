/**
 * Highlights (D-323, Casama for Chrome B7): text a person highlighted on web pages. A bot reads only
 * the highlights of the person it is acting for, in its own workspace; nobody else's, and nothing
 * on runs that no one person started (shared links, channels without a linked person).
 */
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "./acting.ts";
import type { ToolRegistry } from "./tools/registry.ts";

export function registerHighlightTools(registry: ToolRegistry, deps: { db: Database }) {
  const { db } = deps;
  registry.register({
    name: "highlights.search",
    description:
      "Search the text I highlighted on web pages with Casama for Chrome (newest first), with each page's address and title and my note. Use it when I ask about something I read or highlighted.",
    risk: "low",
    readOnly: true,
    schema: z.object({
      query: z.string().max(200).optional().describe("Words to look for; leave out for the newest"),
      url: z
        .string()
        .max(2000)
        .optional()
        .describe("Only highlights on pages whose address contains this"),
      limit: z.number().int().min(1).max(50).optional(),
    }),
    async execute(args, ctx) {
      const owner = await actingUserOf(db, ctx.runId);
      if (!owner) return { content: "No highlights: this run isn't acting for one person." };
      const like = (s: string) => `%${s.replace(/[\\%_]/g, (m) => `\\${m}`)}%`;
      const rows = await db.execute<{
        url: string;
        title: string;
        text: string;
        note: string;
        created_at: string;
      }>(sql`
        select h.url, h.title, h.text, h.note, h.created_at from public.highlights h
        where h.user_id = ${owner}::uuid and h.org_id = ${ctx.orgId}::uuid
          and exists (select 1 from public.memberships m where m.org_id = h.org_id and m.user_id = h.user_id)
          ${args.query ? sql`and (h.text ilike ${like(args.query)} or h.note ilike ${like(args.query)} or h.title ilike ${like(args.query)})` : sql``}
          ${args.url ? sql`and h.url ilike ${like(args.url)}` : sql``}
        order by h.created_at desc limit ${args.limit ?? 20}`);
      if (!rows.length) return { content: "No highlights found." };
      return {
        content: rows
          .map(
            (r) =>
              `- "${r.text}"${r.note ? ` (note: ${r.note})` : ""}\n  ${r.title || r.url} <${r.url}> · ${new Date(r.created_at).toISOString().slice(0, 10)}`,
          )
          .join("\n"),
      };
    },
  });
}
