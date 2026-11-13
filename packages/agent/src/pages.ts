/**
 * Pages (SPEC: Post-v1 roadmap → Pages; D-092, D-119). A bot publishes one self-contained HTML
 * document with its data in a separate JSON block; later updates change only the data. Pages are
 * private to the person the bot was working for until shared. Sharing publicly is high risk.
 */

import { createHash, randomBytes } from "node:crypto";
import type { Database } from "@casama/db";
import { contentKeys } from "@casama/db";
import {
  isValidCron,
  isValidTimezone,
  nextRunAt,
  PAGE_AUTHORING_NOTE,
  PAGE_COLLECT_NOTE,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "./acting.ts";
import { track } from "./analytics.ts";
import { wrapUntrusted } from "./context.ts";
import { checkStorage, StorageFullError } from "./creations.ts";
import { ToolError, type ToolRegistry } from "./tools/registry.ts";

export const PAGE_HTML_MAX = 2_000_000;
export const PAGE_DATA_MAX = 1_000_000;

export const hashPageToken = (t: string) => createHash("sha256").update(t).digest("hex");
export const newPageToken = () => randomBytes(24).toString("base64url");

/** Saves a new version of a page's layout and/or data and keeps the version history. */
export async function savePageVersion(
  db: Database,
  pageId: string,
  change: { html?: string; data?: unknown; title?: string },
) {
  const [o] = await db.execute<{ org_id: string }>(
    sql`select org_id from public.pages where id = ${pageId}::uuid`,
  );
  const [p] = await db.execute<{ version: number; org_id: string }>(sql`
    update public.pages set
      html = coalesce(${contentKeys.seal(o?.org_id, change.html ?? null)}, html),
      data = coalesce(${change.data === undefined ? null : contentKeys.sealJson(o?.org_id, change.data)}::jsonb, data),
      title = coalesce(${change.title ?? null}, title),
      version = version + 1, updated_at = now()
    where id = ${pageId}::uuid returning version, org_id`);
  if (!p) throw new ToolError("page_not_found", "No such page.");
  await db.execute(sql`
    insert into public.page_versions (page_id, version, org_id, html, data)
    select id, version, org_id, html, data from public.pages where id = ${pageId}::uuid`);
  return p.version;
}

/** Makes a page public with a fresh link (old links stop working), or takes it back. */
export async function setPageVisibility(
  db: Database,
  pageId: string,
  visibility: "private" | "workspace" | "public",
  opts: { expiresInDays?: number; pagesUrl: string },
) {
  const token = visibility === "public" ? newPageToken() : null;
  const expires = opts.expiresInDays
    ? new Date(Date.now() + opts.expiresInDays * 86_400_000).toISOString()
    : null;
  await db.execute(sql`
    update public.pages set visibility = ${visibility}, public_token_hash = ${token ? hashPageToken(token) : null},
      expires_at = ${visibility === "public" ? expires : null}::timestamptz
    where id = ${pageId}::uuid`);
  return token ? `${opts.pagesUrl.replace(/\/$/, "")}/s/${token}` : null;
}

const parseJson = (s: string | undefined) => {
  if (s === undefined) return undefined;
  try {
    return JSON.parse(s) as unknown;
  } catch {
    throw new ToolError("bad_data", "data must be valid JSON.");
  }
};

export function registerPageTools(
  registry: ToolRegistry,
  deps: { db: Database; pagesUrl: string },
) {
  const { db } = deps;
  const ownPage = async (botId: string, id: string) => {
    const [p] = await db.execute<{ id: string; title: string; visibility: string }>(sql`
      select id, title, visibility from public.pages where id = ${id}::uuid and bot_id = ${botId}::uuid`);
    if (!p) throw new ToolError("page_not_found", "You have no page with that id.");
    return p;
  };

  registry.register({
    name: "pages.publish",
    description: `Publish a web page (a report, dashboard, plan or tracker) the person opens from Casama, or replace an existing page's layout with page_id. ${PAGE_AUTHORING_NOTE} Pass the HTML, or path to an HTML file on your computer. New pages are private to the person you're working for; pages.share changes that. refresh_cron (with refresh_instructions) has you refresh its data on a schedule. ${PAGE_COLLECT_NOTE}`,
    risk: "low",
    riskFor: (a) => (a.visibility === "workspace" ? "medium" : "low"),
    category: "publish",
    schema: z.object({
      title: z.string().min(1).max(200),
      html: z.string().max(PAGE_HTML_MAX).optional(),
      path: z
        .string()
        .max(1000)
        .optional()
        .describe("An HTML file on your computer instead of html"),
      data: z.string().max(PAGE_DATA_MAX).optional().describe("JSON for the data block"),
      page_id: z.uuid().optional().describe("Replace this page's layout (and data, if given)"),
      visibility: z.enum(["private", "workspace"]).optional(),
      refresh_cron: z.string().max(100).optional().describe("Refresh schedule, five-field cron"),
      refresh_instructions: z.string().max(4000).optional(),
      collect: z
        .boolean()
        .optional()
        .describe("The page takes input: forms and casama.submit send responses you can read"),
      on_submit: z
        .string()
        .max(4000)
        .optional()
        .describe(
          "With collect: what to do each time someone answers (starts a run with the response)",
        ),
      label: z
        .string()
        .max(24)
        .optional()
        .describe(
          "A word for what it is, shown in the person's Library: Site, Game, Report, Dashboard, Tracker",
        ),
    }),
    async execute(args, ctx) {
      let html = args.html;
      if (!html && args.path) {
        if (!ctx.computer)
          throw new ToolError("no_computer", "This bot has no computer available.");
        html = new TextDecoder().decode(await (await ctx.computer()).readFile(args.path));
      }
      if (!html) throw new ToolError("missing_html", "Give the page's html or a path to it.");
      // A full Library takes no new pages (D-276).
      try {
        await checkStorage(db, ctx.orgId, Buffer.byteLength(html));
      } catch (err) {
        if (err instanceof StorageFullError) throw new ToolError("storage_full", err.message);
        throw err;
      }
      if (Buffer.byteLength(html) > PAGE_HTML_MAX)
        throw new ToolError("too_large", "Pages are limited to 2 MB of HTML.");
      const data = parseJson(args.data);
      let id = args.page_id;
      let version = 1;
      if (id) {
        await ownPage(ctx.botId, id);
        version = await savePageVersion(db, id, { html, data, title: args.title });
        if (args.visibility)
          await db.execute(
            sql`update public.pages set visibility = ${args.visibility} where id = ${id}::uuid and visibility <> 'public'`,
          );
      } else {
        const user = await actingUserOf(db, ctx.runId);
        const [run] = await db.execute<{ conversation_id: string | null }>(
          sql`select conversation_id from public.runs where id = ${ctx.runId}::uuid`,
        );
        const [p] = await db.execute<{ id: string }>(sql`
          insert into public.pages (org_id, bot_id, created_by, conversation_id, title, html, data, visibility)
          values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${user ?? null}::uuid, ${run?.conversation_id ?? null}::uuid,
                  ${args.title}, ${contentKeys.seal(ctx.orgId, html)}, ${contentKeys.sealJson(ctx.orgId, data ?? {})}::jsonb, ${args.visibility ?? "private"})
          returning id`);
        id = p?.id as string;
        track(db, {
          event: "page_published",
          userId: user,
          orgId: ctx.orgId,
          properties: { visibility: args.visibility ?? "private" },
        });
        await db.execute(sql`
          insert into public.page_versions (page_id, version, org_id, html, data)
          select id, version, org_id, html, data from public.pages where id = ${id}::uuid`);
      }
      // Pages that take input (D-279).
      if (args.collect !== undefined)
        await db.execute(
          sql`update public.pages set collects = ${args.collect} where id = ${id}::uuid`,
        );
      if (args.collect && args.on_submit?.trim())
        await linkSubmitRoutine(db, ctx, id, args.title, args.on_submit.trim());
      // The Library's copy (D-274) is made by a trigger; this adds what only the tool knows.
      await db.execute(sql`
        update public.creations set run_id = coalesce(run_id, ${ctx.runId}::uuid)
          ${args.label?.trim() ? sql`, label = ${args.label.trim().slice(0, 24)}` : sql``}
        where page_id = ${id}::uuid`);
      if (args.refresh_cron)
        await linkRefresh(db, ctx, id, args.title, args.refresh_cron, args.refresh_instructions);
      return {
        content: `Published "${args.title}" (page ${id}, version ${version}). A card that opens it shows under your reply: don't tell the person where to find it or link it.`,
        preview: args.title,
      };
    },
  });

  registry.register({
    name: "pages.submissions",
    // Responses come from whoever had the page: outside content (later risky calls ask first).
    untrustedOutput: true,
    readOnly: true,
    description:
      "Read the responses to a page that takes input (published with collect), newest first.",
    risk: "low",
    schema: z.object({
      page_id: z.uuid(),
      limit: z.number().int().min(1).max(200).optional(),
      since: z.string().max(40).optional().describe("Only responses after this ISO time"),
    }),
    async execute(args, ctx) {
      const p = await ownPage(ctx.botId, args.page_id);
      const rows = await db.execute<{ data: unknown; created_at: Date; signed_in: boolean }>(sql`
        select data, created_at, submitted_by is not null as signed_in from public.page_submissions
        where page_id = ${p.id}::uuid
          ${args.since && !Number.isNaN(Date.parse(args.since)) ? sql`and created_at > ${new Date(args.since).toISOString()}::timestamptz` : sql``}
        order by created_at desc limit ${args.limit ?? 50}`);
      const [n] = await db.execute<{ n: number }>(
        sql`select count(*)::int as n from public.page_submissions where page_id = ${p.id}::uuid`,
      );
      if (!rows.length)
        return { content: `No responses to "${p.title}" yet.`, preview: "no responses" };
      return {
        content: wrapUntrusted(
          `page "${p.title}" responses`,
          `${n?.n ?? rows.length} responses in all; newest ${rows.length}:\n${rows
            .map(
              (r) =>
                `- ${new Date(r.created_at).toISOString()}${r.signed_in ? " (signed in)" : ""}: ${JSON.stringify(r.data).slice(0, 2000)}`,
            )
            .join("\n")}`,
        ),
        preview: `${rows.length} responses`,
      };
    },
  });

  registry.register({
    name: "pages.update_data",
    description:
      "Replace a page's data block (JSON) without touching its layout. Use it to refresh numbers on a page you published.",
    risk: "low",
    schema: z.object({ page_id: z.uuid(), data: z.string().max(PAGE_DATA_MAX) }),
    async execute(args, ctx) {
      const p = await ownPage(ctx.botId, args.page_id);
      const version = await savePageVersion(db, p.id, { data: parseJson(args.data) });
      return {
        content: `Updated the data on "${p.title}" (version ${version}).`,
        preview: p.title,
      };
    },
  });

  registry.register({
    name: "pages.share",
    description:
      "Change who can open a page: private (the person you work for), workspace (everyone who can see you), or public (anyone with the link; it can expose the page's data, so it always asks first). Making it public again gives a new link and the old one stops working.",
    risk: "high",
    riskFor: (a) => (a.visibility === "public" ? "high" : "medium"),
    category: "share",
    schema: z.object({
      page_id: z.uuid(),
      visibility: z.enum(["private", "workspace", "public"]),
      expires_in_days: z.number().int().min(1).max(365).optional(),
    }),
    async execute(args, ctx) {
      const p = await ownPage(ctx.botId, args.page_id);
      const url = await setPageVisibility(db, p.id, args.visibility, {
        expiresInDays: args.expires_in_days,
        pagesUrl: deps.pagesUrl,
      });
      return {
        content: url
          ? `"${p.title}" is public at ${url}`
          : `"${p.title}" is now ${args.visibility}.`,
        preview: `${p.title}: ${args.visibility}`,
      };
    },
  });

  registry.register({
    name: "pages.list",
    readOnly: true,
    description: "Your published pages.",
    risk: "low",
    schema: z.object({}),
    async execute(_args, ctx) {
      const rows = await db.execute<{
        id: string;
        title: string;
        visibility: string;
        version: number;
        updated_at: string;
      }>(sql`
        select id, title, visibility, version, updated_at from public.pages where bot_id = ${ctx.botId}::uuid order by updated_at desc limit 50`);
      return {
        content: rows.length
          ? rows
              .map(
                (r) =>
                  `- ${r.title} (${r.id}, ${r.visibility}, v${r.version}, updated ${new Date(r.updated_at).toISOString()})`,
              )
              .join("\n")
          : "No pages yet.",
      };
    },
  });
}

/** A routine that refreshes the page's data on schedule, linked to the page. */
/**
 * The routine a page's responses start (D-279). It uses the existing "webhook" trigger, which
 * shipped apps already know, and is started by the pages origin, never on a schedule.
 */
async function linkSubmitRoutine(
  db: Database,
  ctx: { runId: string; orgId: string; botId: string },
  pageId: string,
  title: string,
  instructions: string,
) {
  const user = await actingUserOf(db, ctx.runId);
  const text = `Someone answered the page "${title}" (page_id ${pageId}); their response is below. ${instructions}`;
  const [existing] = await db.execute<{ submit_routine_id: string | null }>(
    sql`select submit_routine_id from public.pages where id = ${pageId}::uuid`,
  );
  if (existing?.submit_routine_id) {
    await db.execute(sql`
      update public.routines set instructions_md = ${text}, enabled = true
      where id = ${existing.submit_routine_id}::uuid`);
    return;
  }
  const [r] = await db.execute<{ id: string }>(sql`
    insert into public.routines (org_id, bot_id, created_by, name, instructions_md, trigger, notify)
    values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${user ?? null}::uuid, ${`When someone answers: ${title}`.slice(0, 120)}, ${text},
            ${JSON.stringify({ type: "webhook", source: "page", page_id: pageId })}::jsonb, true)
    returning id`);
  await db.execute(
    sql`update public.pages set submit_routine_id = ${r?.id}::uuid where id = ${pageId}::uuid`,
  );
}

async function linkRefresh(
  db: Database,
  ctx: { runId: string; orgId: string; botId: string },
  pageId: string,
  title: string,
  cron: string,
  instructions?: string,
) {
  if (!isValidCron(cron))
    throw new ToolError("bad_cron", "refresh_cron must be a five-field cron expression.");
  const user = await actingUserOf(db, ctx.runId);
  const [tz] = user
    ? await db.execute<{ timezone: string | null }>(
        sql`select timezone from public.profiles where user_id = ${user}::uuid`,
      )
    : [];
  const zone = tz?.timezone && isValidTimezone(tz.timezone) ? tz.timezone : "UTC";
  const text = `Refresh the page "${title}" (page_id ${pageId}). ${instructions ?? "Gather fresh data for it."} Then call pages.update_data with the new JSON. Don't change the layout.`;
  const [existing] = await db.execute<{ refresh_routine_id: string | null }>(
    sql`select refresh_routine_id from public.pages where id = ${pageId}::uuid`,
  );
  const next = nextRunAt(cron, zone).toISOString();
  if (existing?.refresh_routine_id) {
    await db.execute(sql`
      update public.routines set schedule_cron = ${cron}, timezone = ${zone}, instructions_md = ${text}, enabled = true,
        next_run_at = ${next}::timestamptz where id = ${existing.refresh_routine_id}::uuid`);
    return;
  }
  const [r] = await db.execute<{ id: string }>(sql`
    insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, trigger, notify, next_run_at)
    values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${user ?? null}::uuid, ${`Refresh: ${title}`.slice(0, 120)}, ${text}, ${cron}, ${zone},
            '{"type":"schedule"}'::jsonb, false, ${next}::timestamptz)
    returning id`);
  await db.execute(
    sql`update public.pages set refresh_routine_id = ${r?.id}::uuid where id = ${pageId}::uuid`,
  );
}
