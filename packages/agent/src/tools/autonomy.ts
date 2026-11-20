import type { Database } from "@casama/db";
import { contentKeys } from "@casama/db";
import {
  browserTriggerSite,
  cloudOpenRouterCharge,
  cloudOpenRouterCost,
  isValidCron,
  isValidTimezone,
  MAX_DELEGATION_DEPTH,
  nextRunAt,
  subagentBudget,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf, personForRun } from "../acting.ts";
import { makeBotPicture, makeOriginal, pictureAvatar } from "../bot-pictures.ts";
import { wrapUntrusted } from "../context.ts";
import { checkStorage, StorageFullError, titleFromText } from "../creations.ts";
import { imageRefs, makeDocument } from "../document-make.ts";
import { sealRunPayload } from "../events.ts";
import {
  combinePdf,
  editImage,
  FileOpError,
  imageInfo,
  makeQr,
  pickPdfPages,
  readDocument,
  readQr,
  rotatePdf,
  splitPdf,
} from "../file-ops.ts";
import {
  MediaChargedError,
  type MediaInput,
  type MediaPayer,
  type MediaProvider,
  type MediaResult,
  mediaPrices,
} from "../media.ts";
import {
  checkMediaRequest,
  type MediaClassifier,
  type MediaSafetyRequest,
} from "../media-safety.ts";
import type { NotificationService } from "../notifications.ts";
import { runSearch, type SearchProvider } from "../search.ts";
import { startTicketWork } from "../tickets.ts";
import { decodeBody, htmlToReadable, readCapped } from "../web-read.ts";
import { type ToolContext, ToolError, type ToolRegistry, toolImage } from "./registry.ts";

/** keepForChat's answer when the workspace's Library is full. */
const LIBRARY_FULL = Symbol("library_full");

/** The most a generated file kept for the chat can be (D-205); the table allows the same. */
export const CHAT_MEDIA_MAX_BYTES = 50 * 1024 * 1024;

export interface AutonomyToolDeps {
  db: Database;
  /** False when this server has no live data tools, so web.search doesn't point at them. */
  liveTools?: boolean;
  /** Where Noto Sans CJK lives, for Chinese, Japanese and Korean PDFs (D-351). */
  cjkFontDir?: string;
  /** Guarded fetch for outbound requests (private ranges blocked). */
  fetch: typeof fetch;
  notifications?: NotificationService;
  mediaFor?: (orgId: string) => Promise<MediaProvider | null>;
  /**
   * The small-model call that checks image and video prompts (D-419): the bot's background model,
   * its cost in the usage ledger. Unset or failing: minors fail closed, the rest open.
   */
  mediaSafetyFor?: (ctx: ToolContext) => MediaClassifier | undefined;
  /** Where the media check's outages and refusals are logged. */
  log?: (message: string, fields: Record<string, unknown>) => void;
  searchFor?: (orgId: string) => Promise<SearchProvider | null>;
  /** Where generated media's bytes go (D-290); unset: Postgres. */
  objects?: import("@casama/sandbox").ObjectStore;
  /**
   * The key for spoken audio (D-284): the workspace's own OpenRouter key, else the server's.
   * `billable` when the server's key pays and billing is on.
   */
  speechFor?: (orgId: string) => Promise<{
    key: string;
    billable: boolean;
    model?: string;
    bases?: { openrouter?: string };
  } | null>;
  /** Runs a child run to completion (a child DBOS workflow in the worker). Late-bound. */
  runChild?: (runId: string) => Promise<{ status: string }>;
  /** Starts a run without waiting (a bot assigning a ticket to another bot). Late-bound. */
  startRun?: (runId: string) => Promise<void>;
  /** Hands out the picture drawers, for the API's "Make one with AI" (through the worker). */
  exposeBotPictures?: (api: {
    draw: (a: BotPictureDrawRequest) => Promise<{ ids: string[] }>;
    drawWorkspace: (a: WorkspacePictureDrawRequest) => Promise<{ ids: string[] }>;
  }) => void;
}

/** The looks "Make one with AI" offers (docs/BOT-PICTURES-PLAN.md §8). */
export const BOT_PICTURE_STYLES = [
  "cloud",
  "soft3d",
  "watercolor",
  "flat",
  "pixel",
  "line",
  "photo",
] as const;
export type BotPictureStyle = (typeof BOT_PICTURE_STYLES)[number];

export interface BotPictureDrawRequest {
  orgId: string;
  botId: string;
  userId: string | null;
  runId?: string | null;
  style: BotPictureStyle;
  description?: string;
  count?: number;
}

export interface WorkspacePictureDrawRequest {
  orgId: string;
  userId: string | null;
  style: BotPictureStyle;
  description?: string;
  count?: number;
}

const STYLE_WORDS: Record<BotPictureStyle, string> = {
  cloud:
    "a cute cloud mascot character: a soft, puffy, rounded cloud body with a little tail, a simple friendly face (small dot eyes, a gentle smile, rosy cheeks), smooth soft gradient shading, glossy highlights, like a premium app mascot",
  soft3d:
    "a soft 3D render, smooth clay-like materials, gentle studio lighting, pastel colours, rounded friendly shapes",
  watercolor:
    "a delicate watercolour painting with soft bleeding edges, light paper texture and a warm palette",
  flat: "a flat vector icon with bold simple shapes, two or three harmonious colours, no gradients, clean edges",
  pixel: "crisp pixel art in a 32 by 32 pixel style with a limited palette and clear outlines",
  line: "minimal line art: one confident continuous line in a dark colour on a light plain background",
  photo: "a photorealistic portrait with natural light and a shallow depth of field",
};

/** The prompt for a bot's picture: the look, what it shows, and what makes a good small avatar. */
export function botPicturePrompt(
  style: BotPictureStyle,
  botName: string,
  description: string | undefined,
  persona: string,
): string {
  const what = description?.trim()
    ? description.trim()
    : `something that fits an assistant called "${botName.slice(0, 80)}"${persona.trim() ? `, whose job is: ${persona.trim().replace(/\s+/g, " ").slice(0, 300)}` : ""}`;
  return [
    `A square profile picture (avatar) for an AI assistant, in the style of ${STYLE_WORDS[style]}.`,
    `It shows ${what}.`,
    "One subject, centred, filling about two thirds of the frame with even space around it, facing the viewer, on a plain soft background that contrasts with it.",
    "Bold, simple and recognisable even when shown very small. No text, letters, numbers, logos or watermarks.",
  ].join(" ");
}

/** The prompt for a workspace's emblem/picture: centred, bold, readable at 30 px in the switcher. */
export function workspacePicturePrompt(
  style: BotPictureStyle,
  workspaceName: string,
  description: string | undefined,
): string {
  const what = description?.trim()
    ? description.trim()
    : `a clean visual emblem representing a team workspace called "${workspaceName.slice(0, 80)}"`;
  return [
    `A square workspace emblem icon in the style of ${STYLE_WORDS[style]}.`,
    `It shows ${what}.`,
    "One clear central motif, centred, filling about two thirds of the frame with balanced padding on a clean contrasting background.",
    "Bold, simple and recognisable even when shown at 30 pixels. No text, letters, numbers or watermarks.",
  ].join(" ");
}

interface RunRow {
  id: string;
  org_id: string;
  bot_id: string;
  parent_run_id: string | null;
  budget: Record<string, unknown>;
  cost_usd: string;
  created_by: string | null;
  [key: string]: unknown;
}

/** Ancestors of a run (nearest first), for depth limits and cycle checks. */
async function ancestry(db: Database, runId: string) {
  return db.execute<{ id: string; bot_id: string; depth: number }>(sql`
    with recursive chain as (
      select id, bot_id, parent_run_id, 0 as depth from public.runs where id = ${runId}::uuid
      union all
      select r.id, r.bot_id, r.parent_run_id, c.depth + 1 from public.runs r join chain c on r.id = c.parent_run_id where c.depth < 10
    ) select id, bot_id, depth from chain order by depth`);
}

/** Final text of a finished run (from its message.completed event). */
async function finalText(db: Database, runId: string) {
  // Read in the app, not in SQL: the payload may be sealed (D-136).
  const [e] = await db.execute<{
    payload: { content?: Array<{ type?: string; text?: string }> };
  }>(sql`
    select payload from public.run_events where run_id = ${runId}::uuid and type = 'message.completed' order by seq desc limit 1`);
  return (e?.payload.content ?? [])
    .filter((p) => p.type === "text")
    .map((p) => p.text ?? "")
    .join("");
}

async function emit(db: Database, runId: string, type: string, payload: Record<string, unknown>) {
  await db.execute(
    sql`select public.append_run_event(${runId}::uuid, ${type}, ${await sealRunPayload(db, runId, payload)}::jsonb)`,
  );
}

/** web.fetch's text limits (D-384): the default and the most one call returns. */
export const WEB_FETCH_DEFAULT_CHARS = 20_000;
export const WEB_FETCH_MAX_CHARS = 100_000;
/** The most of a page's body web.fetch reads. */
const WEB_FETCH_MAX_BYTES = 5 * 1024 * 1024;
const WEB_FETCH_REDIRECTS = 5;

export interface FetchedPage {
  url: string;
  status: number;
  contentType: string;
  title: string;
  description: string;
  text: string;
  truncatedBytes: boolean;
}

/**
 * GETs [url] through the guarded fetch http.request uses (private ranges, cloud metadata and DNS
 * rebinding refused at connect time) and turns the answer into readable text (D-384). Redirects
 * are followed by hand, at most five, so every hop goes through the same guard.
 */
export async function fetchPage(
  guardedFetch: typeof fetch,
  url: string,
  signal?: AbortSignal,
): Promise<FetchedPage> {
  const deadline = AbortSignal.timeout(30_000);
  const combined = signal ? AbortSignal.any([signal, deadline]) : deadline;
  let current = url;
  let res: Response | null = null;
  for (let hop = 0; hop <= WEB_FETCH_REDIRECTS; hop++) {
    const u = new URL(current);
    if (u.protocol !== "http:" && u.protocol !== "https:")
      throw new ToolError("unsupported_url", "web.fetch reads only http and https links.");
    try {
      res = await guardedFetch(current, {
        method: "GET",
        redirect: "manual",
        signal: combined,
        headers: {
          accept:
            "text/html,application/xhtml+xml,text/plain;q=0.9,application/json;q=0.8,*/*;q=0.5",
          "accept-language": "en,*;q=0.5",
          "user-agent": "Mozilla/5.0 (compatible; CasamaBot/1.0; +https://casama.ai)",
        },
      });
    } catch (err) {
      const e = err as { code?: string; cause?: { code?: string }; name?: string };
      if (e.code === "blocked_address" || e.cause?.code === "blocked_address")
        throw new ToolError(
          "blocked_address",
          "That address is private or internal, so it can't be read.",
        );
      if (e.name === "TimeoutError" || e.name === "AbortError")
        throw new ToolError("fetch_timeout", "The page took too long to answer.");
      throw new ToolError("fetch_failed", `Couldn't reach the page: ${(err as Error).message}`);
    }
    const location = res.headers.get("location");
    if (res.status >= 300 && res.status < 400 && location) {
      await res.body?.cancel().catch(() => {});
      if (hop === WEB_FETCH_REDIRECTS)
        throw new ToolError("too_many_redirects", "The page redirected too many times.");
      current = new URL(location, current).href;
      continue;
    }
    break;
  }
  const r = res as Response;
  const contentType = (r.headers.get("content-type") ?? "").toLowerCase();
  const base = { url: current, status: r.status, contentType, title: "", description: "" };
  const textual =
    !contentType || /text\/|json|xml|javascript|ecmascript|csv|markdown|yaml/.test(contentType);
  if (!textual) {
    await r.body?.cancel().catch(() => {});
    const size = r.headers.get("content-length");
    const what = contentType.includes("pdf")
      ? "a PDF"
      : contentType.startsWith("image/")
        ? "an image"
        : contentType.startsWith("audio/") || contentType.startsWith("video/")
          ? "audio or video"
          : `a ${contentType.split(";")[0]} file`;
    return {
      ...base,
      text: `This link is ${what}${size ? ` (${size} bytes)` : ""}, not a page web.fetch can read as text.${contentType.includes("pdf") ? " Open it in the browser, or download it on the computer and read it there." : ""}`,
      truncatedBytes: false,
    };
  }
  const { bytes, truncated } = await readCapped(r, WEB_FETCH_MAX_BYTES);
  const raw = decodeBody(bytes, contentType);
  const html =
    contentType.includes("html") ||
    (!contentType && /^\s*(?:<!doctype html|<html)/i.test(raw.slice(0, 500)));
  if (!html) return { ...base, text: raw.trim(), truncatedBytes: truncated };
  const page = htmlToReadable(raw, current);
  return { ...base, ...page, truncatedBytes: truncated };
}

/** Questions the live tools answer with real data and a card (docs/RICH-CARDS-PLAN.md §15). */
const LIVE_QUESTION =
  /\b(weather|forecast|temperature|rain(ing)?|humid|typhoon|bagyo|panahon|ulan|exchange rate|conversion rate|usd|php|eur|bitcoin|btc|eth|crypto|stock price|share price|time (is it )?in|earthquake|lindol|sunrise|sunset|air quality|aqi)\b/i;
const LIVE_HINT =
  "Tip: weather, prices, rates, time zones, earthquakes and air quality come from the live tools (tools.load live) as a card with named sources; use them for this next time unless the person asked for a web search.";

export function registerAutonomyTools(registry: ToolRegistry, deps: AutonomyToolDeps) {
  const { db } = deps;

  // --- outbound HTTP and search ---------------------------------------------

  registry.register({
    name: "http.request",
    description:
      "Make an HTTP request from the server. Use {{secret:NAME}} in headers or body for credentials; they are filled in only for the secret's allowed hosts. Private and internal addresses are blocked.",
    risk: "medium",
    acceptsSecrets: true,
    untrustedOutput: true,
    // Writing requests send data out; reads don't ask after untrusted content (D-213).
    sendsOutFor: (args) => args.method !== "GET" && args.method !== "HEAD",
    destinationHost: (args) => {
      try {
        return new URL(args.url).hostname;
      } catch {
        return null;
      }
    },
    schema: z.object({
      method: z.enum(["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD"]).default("GET"),
      url: z.url().max(4000),
      headers: z.record(z.string(), z.string()).optional(),
      body: z.string().max(1_000_000).optional(),
    }),
    async execute(args) {
      const res = await deps.fetch(args.url, {
        method: args.method,
        headers: args.headers,
        body: args.body,
        redirect: "manual",
      });
      const type = res.headers.get("content-type") ?? "";
      const text =
        /json|text|xml|html|javascript/.test(type) || !type
          ? await res.text()
          : `[${type} body, ${res.headers.get("content-length") ?? "?"} bytes]`;
      const head = `HTTP ${res.status} ${res.statusText}\ncontent-type: ${type}${res.headers.get("location") ? `\nlocation: ${res.headers.get("location")}` : ""}`;
      return {
        content: wrapUntrusted("http", `${head}\n\n${text.slice(0, 200_000)}`),
        preview: `HTTP ${res.status}`,
      };
    },
  });

  registry.register({
    name: "web.search",
    description:
      "Search the web. Returns titles, links and snippets; read a page's text with web.fetch (cheaper than http.request), or open it in the browser when it needs clicking or a sign-in. Weather, prices, exchange rates, time zones, scores, earthquakes and definitions come from the live tools instead (tools.load live): real data shown as cards.",
    risk: "low",
    readOnly: true,
    untrustedOutput: true,
    schema: z.object({
      query: z.string().min(1).max(400),
      count: z.number().int().min(1).max(20).optional(),
    }),
    async execute(args, ctx) {
      const provider = await deps.searchFor?.(ctx.orgId);
      if (!provider)
        throw new ToolError(
          "no_search_provider",
          "Web search isn't set up on this server. A workspace admin can add a Brave Search, Tavily, Parallel or Serper key in Model keys; a self-hosted server can run SearXNG instead (SEARXNG_URL, or ./install.sh --search).",
        );
      const found = await runSearch(provider, args.query, args.count ?? 8);
      // One row per query, also for a cached answer (cost 0), so query counts stay true (D-384).
      // The server's chain is paid by the server, not charged (D-400); a workspace key pays itself.
      await db.execute(sql`insert into public.usage_ledger (org_id, bot_id, run_id, kind, quantity, cost_usd, upstream_cost_usd, meta)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${ctx.runId}::uuid, 'search_queries', 1, ${found.costUsd},
                ${found.serverPaid ? found.costUsd : null},
                ${JSON.stringify({ provider: found.providerId, ...(found.cached ? { cached: true } : {}) })}::jsonb)`);
      const results = found.results;
      const text = results
        .map((r, i) => `${i + 1}. ${r.title}\n   ${r.url}\n   ${r.snippet}`)
        .join("\n");
      // A question the live tools answer better (RICH-CARDS-PLAN §15): say so, for this and next time.
      const live = LIVE_QUESTION.test(args.query) && deps.liveTools !== false;
      return {
        content: `${wrapUntrusted("search", text || "No results.")}${live ? `\n\n${LIVE_HINT}` : ""}`,
        preview: `${results.length} results`,
      };
    },
  });

  registry.register({
    name: "web.fetch",
    description:
      "Read a web page as text: its title and main content, without menus, scripts or ads. Use it after web.search to read a result, or for any public link. Plain text and JSON come back as they are. Use the browser for pages that need clicking, a sign-in or JavaScript, and http.request for APIs.",
    risk: "low",
    readOnly: true,
    untrustedOutput: true,
    schema: z.object({
      url: z.url().max(4000),
      max_chars: z
        .number()
        .int()
        .min(500)
        .max(WEB_FETCH_MAX_CHARS)
        .optional()
        .describe(`At most this many characters of text (default ${WEB_FETCH_DEFAULT_CHARS})`),
      start: z
        .number()
        .int()
        .min(0)
        .optional()
        .describe("Skip this many characters, to read on where a cut page stopped"),
    }),
    async execute(args, ctx) {
      const page = await fetchPage(deps.fetch, args.url, ctx.signal);
      const maxChars = Math.min(args.max_chars ?? WEB_FETCH_DEFAULT_CHARS, WEB_FETCH_MAX_CHARS);
      const start = args.start ?? 0;
      const slice = page.text.slice(start, start + maxChars);
      const end = start + slice.length;
      const notes = [
        page.truncatedBytes ? "The page was larger than 5 MB; only its start was read." : null,
        end < page.text.length
          ? `Cut at character ${end} of ${page.text.length}. Call web.fetch again with start=${end} to read on.`
          : null,
      ].filter(Boolean);
      const head = [
        `URL: ${page.url}`,
        page.title ? `Title: ${page.title}` : null,
        page.description ? `Description: ${page.description}` : null,
        `HTTP ${page.status}, ${page.contentType || "no content type"}`,
      ]
        .filter(Boolean)
        .join("\n");
      const body = slice || (start > 0 ? "(Nothing past that point.)" : "(No readable text.)");
      return {
        content: wrapUntrusted(
          "web",
          `${head}\n\n${body}${notes.length ? `\n\n[${notes.join(" ")}]` : ""}`,
        ),
        preview: page.title ? page.title.slice(0, 120) : `HTTP ${page.status}`,
      };
    },
  });

  // --- notifications ---------------------------------------------------------

  registry.register({
    name: "notify.user",
    description:
      "Send a push notification to the bot's owner (use sparingly: finished work, blockers, urgent findings).",
    risk: "low",
    // Only the bot's own state inside Casama: never asks (D-155).
    selfOnly: true,
    schema: z.object({ title: z.string().min(1).max(120), message: z.string().min(1).max(1000) }),
    async execute(args, ctx) {
      if (!deps.notifications)
        throw new ToolError("notifications_unavailable", "Notifications are not configured.");
      // The person the run acts for (a sub-run's starter), else the bot's creator.
      const p = await personForRun(db, ctx.runId);
      const owner = { user_id: p.userId };
      if (!owner?.user_id) throw new ToolError("no_owner", "This bot has no owner to notify.");
      // Opens the chat this run is in, not whichever chat with the bot was open or newest.
      const [run] = await db.execute<{ conversation_id: string | null }>(
        sql`select conversation_id from public.runs where id = ${ctx.runId}::uuid`,
      );
      const conversationId = run?.conversation_id ?? null;
      await deps.notifications.notify(owner.user_id, ctx.orgId, "bot_message", {
        title: args.title,
        body: args.message,
        link: `/bots/${ctx.botId}/chat${conversationId ? `?c=${conversationId}` : ""}`,
        ...(conversationId ? { conversation_id: conversationId } : {}),
        bot_id: ctx.botId,
        run_id: ctx.runId,
      });
      return { content: "Notification sent.", preview: "notified" };
    },
  });

  // --- task board --------------------------------------------------------------

  const botByRef = async (orgId: string, ref: string) => {
    const [b] = await db.execute<{ id: string; name: string }>(sql`
      select id, name from public.bots where org_id = ${orgId}::uuid and (id::text = ${ref} or lower(name) = lower(${ref})) limit 1`);
    return b;
  };

  const STATUSES = ["todo", "in_progress", "in_review", "blocked", "done"] as const;
  const PRIORITIES = ["urgent", "high", "medium", "low", "none"] as const;

  /** Assigning a ticket to another bot starts that bot's work (D-098). */
  const startAssignee = async (
    taskId: string,
    assigneeId: string | null | undefined,
    ctx: { botId: string },
  ) => {
    if (!assigneeId || assigneeId === ctx.botId || !deps.startRun) return;
    await startTicketWork(db, { ticketId: taskId, actorUserId: null }, deps.startRun);
  };

  registry.register({
    name: "tasks.create",
    description:
      "Add a ticket to the board, optionally assigned to a bot by name (that bot starts on it right away).",
    risk: "low",
    // Only the bot's own state inside Casama: never asks (D-155).
    selfOnly: true,
    schema: z.object({
      title: z.string().min(1).max(300),
      details: z.string().max(10_000).optional(),
      assignee: z.string().max(100).optional(),
      priority: z.enum(PRIORITIES).optional(),
      review_required: z.boolean().optional(),
    }),
    async execute(args, ctx) {
      const assignee = args.assignee ? await botByRef(ctx.orgId, args.assignee) : undefined;
      if (args.assignee && !assignee)
        throw new ToolError("bot_not_found", `No bot named ${args.assignee}.`);
      // A ticket made while working on a project is the project's (D-295).
      const [t] = await db.execute<{ id: string }>(sql`
        insert into public.tasks (org_id, created_by_bot_id, assignee_bot_id, title, details_md, parent_run_id, priority, review_required, project_id)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${assignee?.id ?? null}::uuid, ${args.title}, ${contentKeys.seal(ctx.orgId, args.details ?? "")}, ${ctx.runId}::uuid,
                ${args.priority ?? "none"}, ${args.review_required ?? false},
                (select project_id from public.runs where id = ${ctx.runId}::uuid))
        returning id`);
      if (t) await startAssignee(t.id, assignee?.id, ctx);
      return { content: `Created ticket ${t?.id}.`, preview: args.title };
    },
  });

  registry.register({
    name: "tasks.update",
    description:
      "Update a ticket: status (todo, in_progress, in_review, blocked, done), a result, priority or the bot it's assigned to.",
    risk: "low",
    // Only the bot's own state inside Casama: never asks (D-155).
    selfOnly: true,
    schema: z.object({
      task_id: z.uuid(),
      status: z.enum(STATUSES).optional(),
      result: z.string().max(20_000).optional(),
      priority: z.enum(PRIORITIES).optional(),
      assignee: z.string().max(100).optional().describe("A bot's name, to hand the ticket over"),
    }),
    async execute(args, ctx) {
      const assignee = args.assignee ? await botByRef(ctx.orgId, args.assignee) : undefined;
      if (args.assignee && !assignee)
        throw new ToolError("bot_not_found", `No bot named ${args.assignee}.`);
      const rows = await db.execute<{ id: string }>(sql`
        update public.tasks set status = coalesce(${args.status ?? null}, status), result_md = coalesce(${contentKeys.seal(ctx.orgId, args.result ?? null)}, result_md),
          priority = coalesce(${args.priority ?? null}, priority), assignee_bot_id = coalesce(${assignee?.id ?? null}::uuid, assignee_bot_id),
          updated_at = now()
        where id = ${args.task_id}::uuid and org_id = ${ctx.orgId}::uuid returning id`);
      if (!rows.length) throw new ToolError("task_not_found", "No such ticket.");
      if (assignee) await startAssignee(args.task_id, assignee.id, ctx);
      return { content: "Ticket updated.", preview: args.status ?? "updated" };
    },
  });

  registry.register({
    name: "tasks.comment",
    description: "Post a comment on a ticket (progress, questions, results).",
    risk: "low",
    // Only the bot's own state inside Casama: never asks (D-155).
    selfOnly: true,
    schema: z.object({ task_id: z.uuid(), body: z.string().min(1).max(20_000) }),
    async execute(args, ctx) {
      const rows = await db.execute<{ id: string }>(sql`
        insert into public.task_comments (org_id, task_id, author_type, author_bot_id, body_md)
        select t.org_id, t.id, 'bot', ${ctx.botId}::uuid, ${contentKeys.seal(ctx.orgId, args.body)} from public.tasks t
        where t.id = ${args.task_id}::uuid and t.org_id = ${ctx.orgId}::uuid returning id`);
      if (!rows.length) throw new ToolError("task_not_found", "No such ticket.");
      await db.execute(
        sql`update public.tasks set updated_at = now() where id = ${args.task_id}::uuid`,
      );
      return { content: "Comment posted.", preview: args.body.slice(0, 120) };
    },
  });

  registry.register({
    name: "tasks.list",
    readOnly: true,
    description: "List tickets on the board, newest first (optionally by status, or only yours).",
    risk: "low",
    schema: z.object({
      status: z.enum(STATUSES).optional(),
      mine: z.boolean().optional().describe("Only tickets assigned to you"),
      limit: z.number().int().min(1).max(100).optional(),
    }),
    async execute(args, ctx) {
      const rows = await db.execute<{
        id: string;
        title: string;
        status: string;
        priority: string;
        bot: string | null;
      }>(sql`
        select t.id, t.title, t.status, t.priority, b.name as bot from public.tasks t
        left join public.bots b on b.id = t.assignee_bot_id
        where t.org_id = ${ctx.orgId}::uuid
          and (${args.status ?? null}::text is null or t.status = ${args.status ?? null})
          and (${args.mine ?? false} = false or t.assignee_bot_id = ${ctx.botId}::uuid)
        order by t.updated_at desc limit ${args.limit ?? 30}`);
      const text = rows.length
        ? rows
            .map(
              (r) =>
                `- ${r.title} [${r.status}, ${r.priority}${r.bot ? `, ${r.bot}` : ""}] (id ${r.id})`,
            )
            .join("\n")
        : "No tickets.";
      return { content: text, preview: `${rows.length} tickets` };
    },
  });

  // A bot may manage another bot's routines in its workspace (D-100).
  const BOT_ARG = z
    .string()
    .max(100)
    .optional()
    .describe("Another bot's name, to manage its routines instead of yours");
  const routineBot = async (ref: string | undefined, ctx: { orgId: string; botId: string }) => {
    if (!ref) return ctx.botId;
    const b = await botByRef(ctx.orgId, ref);
    if (!b) throw new ToolError("bot_not_found", `No bot named ${ref}.`);
    return b.id;
  };

  // --- routines -----------------------------------------------------------------

  const DEVICE_EVENT = z
    .object({
      event: z.enum([
        "wake",
        "arrive",
        "leave",
        "leave_now",
        "workout_ended",
        "notification",
        "focus_on",
        "focus_off",
        "file_added",
        "site_opened",
        "download_done",
        "bookmark_added",
      ]),
      site: z
        .string()
        .max(253)
        .optional()
        .describe(
          "site_opened: a site the person opens in their browser with Casama for Chrome, like wiki.example.com",
        ),
      place: z.string().max(60).optional().describe("arrive/leave: a named place like Home"),
      app: z.string().max(200).optional().describe("notification: the app to watch"),
      minutes_before: z
        .number()
        .int()
        .min(0)
        .max(120)
        .optional()
        .describe("leave_now: buffer on top of travel time"),
      folder: z
        .string()
        .max(200)
        .optional()
        .describe("file_added: a folder the person's desktop app watches, like Downloads"),
      pattern: z
        .string()
        .max(100)
        .optional()
        .describe("file_added and download_done: a file name pattern like *.pdf"),
    })
    .describe(
      "Run each time this happens on the person's own phone, computer or browser (they must share that kind in Device connections; browser events need Casama for Chrome)",
    );
  const checkDeviceEvent = (d: z.infer<typeof DEVICE_EVENT>) => {
    if ((d.event === "arrive" || d.event === "leave") && !d.place)
      throw new ToolError("place_required", "Arrive and leave need a named place.");
    if (d.event === "notification" && !d.app)
      throw new ToolError("app_required", "Notification routines need the app to watch.");
    if (d.event === "file_added" && !d.folder)
      throw new ToolError("folder_required", "File routines need the watched folder.");
    if (d.event === "site_opened") {
      const r = browserTriggerSite(d.site ?? "");
      if ("error" in r) throw new ToolError("bad_site", r.error);
      d.site = r.site;
    }
  };
  /** A one-time run's time from run_at or in_minutes; refuses times already past. */
  const onceAt = (runAt: string | undefined, inMinutes: number | undefined) => {
    if (inMinutes != null) return new Date(Date.now() + inMinutes * 60_000);
    const at = new Date(runAt as string);
    if (Number.isNaN(at.getTime()))
      throw new ToolError("invalid_time", "run_at must be an ISO 8601 time.");
    if (at.getTime() < Date.now() - 60_000)
      throw new ToolError("invalid_time", "run_at is in the past.");
    return at;
  };
  /** An end time (D-262): ISO 8601, in the future. */
  const endAt = (v: string) => {
    const at = new Date(v);
    if (Number.isNaN(at.getTime()))
      throw new ToolError("invalid_time", "ends_at must be an ISO 8601 time.");
    if (at.getTime() <= Date.now()) throw new ToolError("invalid_time", "ends_at is in the past.");
    return at;
  };
  const ENDS_AT = z
    .string()
    .max(40)
    .describe("Stop for good at this ISO 8601 time (with offset); it switches itself off");
  const MAX_RUNS = z
    .number()
    .int()
    .min(1)
    .max(10_000)
    .describe("Stop for good after this many runs; it switches itself off");
  const IN_MINUTES = z
    .number()
    .int()
    .min(1)
    .max(60 * 24 * 365);
  /** How a routine ends, for tool replies. */
  const endsText = (endsAt: Date | string | null, maxRuns: number | null, runCount = 0) =>
    [
      endsAt ? `ends ${new Date(endsAt).toISOString()}` : null,
      maxRuns != null ? `${Math.max(0, maxRuns - runCount)} of ${maxRuns} runs left` : null,
    ]
      .filter(Boolean)
      .join(", ");

  /** A routine named like a brief (morning brief, daily briefing). */
  const BRIEF_NAME = /\bbrief(?:ing)?\b/i;
  /** A cron that runs every day (a weekly "Friday brief" isn't a second morning brief). */
  const everyDay = (cron: string) => /^\S+\s+\S+\s+\*\s+\*\s+\*$/.test(cron.trim());

  registry.register({
    name: "routines.create",
    description:
      "Schedule work for yourself later. For something that should happen once (a reminder, a follow-up), pass in_minutes or run_at; it runs a single time and switches itself off. Use schedule_cron (5-field cron in the user's timezone) only for work that repeats. A repeating or device routine can end on its own: ends_at (a date and time) and/or max_runs (after that many runs). Each run posts its reply in this chat and notifies the person, so a reminder or greeting needs no other way of sending.",
    risk: "medium",
    // Only the bot's own state inside Casama: never asks (D-155).
    selfOnly: true,
    schedulesWork: true,
    schema: z.object({
      bot: BOT_ARG,
      name: z.string().min(1).max(120),
      instructions: z
        .string()
        .min(1)
        .max(10_000)
        .describe("What to do when it runs, written as a message to yourself"),
      in_minutes: IN_MINUTES.optional().describe("Run once, this many minutes from now"),
      run_at: z
        .string()
        .max(40)
        .optional()
        .describe("Run once at this ISO 8601 time (with offset)"),
      schedule_cron: z.string().max(100).optional().describe("Repeat on this 5-field cron"),
      browser: z
        .enum(["computer", "mine", "mine_or_computer"])
        .optional()
        .describe(
          'Where its browser work happens: "mine" is the person\'s own Chrome (their sign-ins; waits for it to be online), "mine_or_computer" uses it when online, "computer" your own (default)',
        ),
      on_device_event: DEVICE_EVENT.optional(),
      ends_at: ENDS_AT.optional(),
      max_runs: MAX_RUNS.optional(),
      timezone: z.string().max(64).optional(),
      notify: z.boolean().optional(),
    }),
    async execute(args, ctx) {
      const target = await routineBot(args.bot, ctx);
      // Runs post in the chat the routine was asked for in (one thread per person, like a chat app),
      // when that chat is a direct one with the routine's bot.
      const [here] = await db.execute<{ id: string }>(sql`
        select c.id from public.runs r join public.conversations c on c.id = r.conversation_id
        where r.id = ${ctx.runId}::uuid and c.bot_id = ${target}::uuid and c.kind = 'direct'`);
      const conversationId = here?.id ?? null;
      const kinds = [
        args.in_minutes != null,
        !!args.run_at,
        !!args.schedule_cron,
        !!args.on_device_event,
      ].filter(Boolean).length;
      if (kinds !== 1)
        throw new ToolError(
          "invalid_schedule",
          "Pass exactly one of in_minutes, run_at (once), schedule_cron (repeating) or on_device_event.",
        );
      const once = args.in_minutes != null || !!args.run_at;
      if (once && (args.ends_at || args.max_runs != null))
        throw new ToolError(
          "invalid_schedule",
          "A one-time routine already ends after its run: ends_at and max_runs are for repeating or device routines.",
        );
      const ends = args.ends_at ? endAt(args.ends_at) : null;
      const maxRuns = args.max_runs ?? null;
      const endNote = endsText(ends, maxRuns);
      if (args.on_device_event) {
        // Device triggers (D-151) belong to the person this run acts for: their events, their routine.
        const d = args.on_device_event;
        checkDeviceEvent(d);
        const person = await actingUserOf(db, ctx.runId);
        if (!person)
          throw new ToolError(
            "no_person",
            "Device routines need a person: this run isn't acting for anyone.",
          );
        const [r] = await db.execute<{ id: string }>(sql`
          insert into public.routines (org_id, bot_id, created_by, name, instructions_md, timezone, trigger, notify, conversation_id, ends_at, max_runs, browser)
          values (${ctx.orgId}::uuid, ${target}::uuid, ${person}::uuid, ${args.name}, ${args.instructions}, ${args.timezone ?? "UTC"},
                  ${JSON.stringify({ type: "device", ...d })}::jsonb, ${args.notify ?? true}, ${conversationId}::uuid,
                  ${ends?.toISOString() ?? null}::timestamptz, ${maxRuns}::int, ${args.browser ?? "computer"}) returning id`);
        return {
          content: `Created routine ${r?.id}: it runs on ${d.event}${d.place ? ` (${d.place})` : ""}${d.app ? ` (${d.app})` : ""}${endNote ? `; ${endNote}` : ""}.`,
          preview: `${args.name} · on ${d.event}`,
        };
      }
      if (args.schedule_cron && !isValidCron(args.schedule_cron))
        throw new ToolError("invalid_cron", "Use a 5-field cron expression like '0 8 * * *'.");
      // One brief per bot (D-312): a second "Morning brief" routine beside the check-ins one sent
      // two briefs every morning that contradicted each other.
      if (args.schedule_cron && everyDay(args.schedule_cron) && BRIEF_NAME.test(args.name)) {
        const [brief] = await db.execute<{ id: string; schedule_cron: string | null }>(sql`
          select id, schedule_cron from public.routines where bot_id = ${target}::uuid and kind = 'brief' and enabled limit 1`);
        if (brief)
          throw new ToolError(
            "brief_exists",
            `This bot already has a morning brief from check-ins (routine ${brief.id}, ${brief.schedule_cron}). Don't add a second one: change what it covers with routines.update on that routine. Its time is set in the bot's Check-ins settings.`,
          );
      }
      const person = await personForRun(db, ctx.runId);
      const owner = { user_id: person.userId, timezone: person.timezone };
      const tz = args.timezone ?? owner?.timezone ?? "UTC";
      if (!isValidTimezone(tz)) throw new ToolError("invalid_timezone", `Unknown timezone ${tz}.`);
      const next = args.schedule_cron
        ? nextRunAt(args.schedule_cron, tz)
        : onceAt(args.run_at, args.in_minutes);
      if (ends && next.getTime() > ends.getTime())
        throw new ToolError(
          "invalid_time",
          `It would end before its first run (${next.toISOString()}). Pick a later ends_at.`,
        );
      const trigger = JSON.stringify({ type: once ? "once" : "schedule" });
      const [r] = await db.execute<{ id: string }>(sql`
        insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, trigger, notify, next_run_at, conversation_id, ends_at, max_runs, browser)
        values (${ctx.orgId}::uuid, ${target}::uuid, ${owner?.user_id ?? null}::uuid, ${args.name}, ${args.instructions},
                ${args.schedule_cron ?? null}, ${tz}, ${trigger}::jsonb, ${args.notify ?? true}, ${next.toISOString()}::timestamptz, ${conversationId}::uuid,
                ${ends?.toISOString() ?? null}::timestamptz, ${maxRuns}::int, ${args.browser ?? "computer"}) returning id`);
      return {
        content: once
          ? `Scheduled one-time routine ${r?.id} for ${next.toISOString()}. It runs once, then switches itself off.`
          : `Scheduled repeating routine ${r?.id}; next run ${next.toISOString()} (${tz})${endNote ? `; ${endNote}` : ""}.`,
        preview: once
          ? `${args.name} · once at ${next.toISOString()}`
          : `${args.name} · ${args.schedule_cron}`,
      };
    },
  });

  registry.register({
    name: "routines.list",
    description:
      "List your routines (id, name, schedule, whether it is on, next run, when it ends). Use it before changing or deleting one.",
    risk: "low",
    readOnly: true,
    schema: z.object({ bot: BOT_ARG }),
    async execute(args, ctx) {
      const target = await routineBot(args.bot, ctx);
      const rows = await db.execute<{
        id: string;
        name: string;
        schedule_cron: string | null;
        trigger: { type?: string; event?: string; place?: string };
        timezone: string;
        enabled: boolean;
        next_run_at: string | null;
        last_run_at: string | null;
        ends_at: string | null;
        max_runs: number | null;
        run_count: number;
      }>(sql`
        select id, name, schedule_cron, trigger, timezone, enabled, next_run_at, last_run_at, ends_at, max_runs, run_count
        from public.routines where bot_id = ${target}::uuid order by created_at`);
      if (!rows.length) return { content: "You have no routines.", preview: "none" };
      const lines = rows.map((r) => {
        const when =
          r.trigger?.type === "once"
            ? "once"
            : r.schedule_cron
              ? `cron ${r.schedule_cron} (${r.timezone})`
              : r.trigger?.type === "device"
                ? `on ${r.trigger.event}${r.trigger.place ? ` (${r.trigger.place})` : ""}`
                : (r.trigger?.type ?? "schedule");
        const next = r.next_run_at ? new Date(r.next_run_at).toISOString() : "none";
        const ends = endsText(r.ends_at, r.max_runs, r.run_count);
        return `- ${r.id} · ${r.name} · ${when} · ${r.enabled ? "on" : "off"} · next ${next}${ends ? ` · ${ends}` : ""}`;
      });
      return {
        content: lines.join("\n"),
        preview: `${rows.length} routine${rows.length === 1 ? "" : "s"}`,
      };
    },
  });

  registry.register({
    name: "routines.update",
    description:
      "Change, pause (enabled: false) or resume one of your routines: its name, instructions, timezone, schedule, device event or when it ends. schedule_cron makes it repeat; run_at or in_minutes makes it run once. ends_at and max_runs end it on their own (null removes them; max_runs counts from now). Find its id with routines.list.",
    risk: "medium",
    // Only the bot's own state inside Casama: never asks (D-155).
    selfOnly: true,
    schedulesWork: true,
    schema: z.object({
      bot: BOT_ARG,
      routine_id: z.uuid(),
      name: z.string().min(1).max(120).optional(),
      enabled: z.boolean().optional(),
      notify: z.boolean().optional(),
      instructions: z.string().min(1).max(10_000).optional(),
      timezone: z.string().max(64).optional(),
      schedule_cron: z.string().max(100).optional().describe("Repeat on this 5-field cron"),
      browser: z
        .enum(["computer", "mine", "mine_or_computer"])
        .optional()
        .describe(
          'Where its browser work happens: "mine" is the person\'s own Chrome (their sign-ins; waits for it to be online), "mine_or_computer" uses it when online, "computer" your own (default)',
        ),
      run_at: z
        .string()
        .max(40)
        .optional()
        .describe("Run once at this ISO 8601 time (with offset)"),
      in_minutes: IN_MINUTES.optional().describe("Run once, this many minutes from now"),
      on_device_event: DEVICE_EVENT.optional().describe("A device routine's new event"),
      ends_at: ENDS_AT.nullable().optional(),
      max_runs: MAX_RUNS.nullable().optional(),
    }),
    async execute(args, ctx) {
      const target = await routineBot(args.bot, ctx);
      const [r] = await db.execute<{
        schedule_cron: string | null;
        timezone: string;
        trigger: Record<string, unknown> & { type?: string };
        enabled: boolean;
        next_run_at: string | null;
        ends_at: string | null;
        max_runs: number | null;
        run_count: number;
      }>(sql`
        select schedule_cron, timezone, trigger, enabled, next_run_at, ends_at, max_runs, run_count
        from public.routines where id = ${args.routine_id}::uuid and bot_id = ${target}::uuid`);
      if (!r)
        throw new ToolError(
          "routine_not_found",
          "No such routine for this bot. Check routines.list.",
        );
      const wantsOnce = !!args.run_at || args.in_minutes != null;
      if ([wantsOnce, !!args.schedule_cron, !!args.on_device_event].filter(Boolean).length > 1)
        throw new ToolError(
          "invalid_schedule",
          "Pass at most one of schedule_cron, run_at/in_minutes or on_device_event.",
        );
      const was = r.trigger?.type ?? "schedule";
      // Only time-based routines switch between once and repeating; an event routine keeps its kind.
      if ((wantsOnce || args.schedule_cron) && was !== "once" && was !== "schedule")
        throw new ToolError(
          "invalid_schedule",
          `This routine runs on ${was === "device" ? "a device event" : `a ${was} trigger`}. Delete it and create a scheduled one instead.`,
        );
      if (args.on_device_event && was !== "device")
        throw new ToolError(
          "invalid_schedule",
          "Only a device routine takes on_device_event. Delete this one and create a device routine instead.",
        );
      if (args.on_device_event) checkDeviceEvent(args.on_device_event);
      if (args.schedule_cron && !isValidCron(args.schedule_cron))
        throw new ToolError("invalid_cron", "Use a 5-field cron expression like '0 8 * * *'.");
      const tz = args.timezone ?? r.timezone;
      if (!isValidTimezone(tz)) throw new ToolError("invalid_timezone", `Unknown timezone ${tz}.`);
      const type = wantsOnce ? "once" : args.schedule_cron ? "schedule" : was;
      const cron = type === "schedule" ? (args.schedule_cron ?? r.schedule_cron) : null;
      const trigger =
        type !== was
          ? { type }
          : args.on_device_event
            ? { type: "device", ...args.on_device_event }
            : r.trigger;
      if (type === "once" && (args.ends_at || args.max_runs))
        throw new ToolError(
          "invalid_schedule",
          "A one-time routine already ends after its run: ends_at and max_runs are for repeating or device routines.",
        );
      // A one-time routine keeps no end of its own.
      const ends =
        type === "once" || args.ends_at === null
          ? null
          : args.ends_at
            ? endAt(args.ends_at)
            : r.ends_at
              ? new Date(r.ends_at)
              : null;
      const maxRuns =
        type === "once" ? null : args.max_runs === undefined ? r.max_runs : args.max_runs;
      // A new max_runs counts from now.
      const runCount = args.max_runs === undefined ? r.run_count : 0;
      const enabled = args.enabled ?? r.enabled;
      let next: Date | null = null;
      if (enabled) {
        if (ends && ends.getTime() <= Date.now())
          throw new ToolError(
            "routine_ended",
            "This routine's end time has passed. Pass a later ends_at, or ends_at: null to keep it going.",
          );
        if (maxRuns != null && runCount >= maxRuns)
          throw new ToolError(
            "routine_ended",
            `This routine already ran its ${maxRuns} times. Pass max_runs (counted from now), or max_runs: null.`,
          );
        if (type === "once") {
          next = wantsOnce
            ? onceAt(args.run_at, args.in_minutes)
            : r.next_run_at && new Date(r.next_run_at).getTime() > Date.now() - 60_000
              ? new Date(r.next_run_at)
              : null;
          if (!next)
            throw new ToolError(
              "invalid_time",
              "This one-time routine has already run. Pass run_at or in_minutes for its new time.",
            );
        } else if (cron) {
          next = nextRunAt(cron, tz);
          if (ends && next.getTime() > ends.getTime())
            throw new ToolError(
              "invalid_time",
              `It would end before its next run (${next.toISOString()}). Pick a later ends_at.`,
            );
        }
      }
      // A routine runs for its creator: an edit for anyone else sends its browser work back to
      // the bot's computer, and only the creator can point it at their own browser (D-323).
      const editor = await actingUserOf(db, ctx.runId);
      const [owner] = await db.execute<{ created_by: string | null }>(
        sql`select created_by from public.routines where id = ${args.routine_id}::uuid`,
      );
      const byCreator = !!editor && editor === owner?.created_by;
      if (!byCreator && args.browser && args.browser !== "computer")
        throw new ToolError(
          "not_creator",
          "Only the person who made this routine can point it at their own browser.",
        );
      await db.execute(sql`
        update public.routines set
          name = coalesce(${args.name ?? null}, name),
          instructions_md = coalesce(${args.instructions ?? null}, instructions_md),
          notify = coalesce(${args.notify ?? null}, notify),
          browser = ${byCreator ? sql`coalesce(${args.browser ?? null}, browser)` : sql`'computer'`},
          edited_by_other = ${!byCreator},
          enabled = ${enabled}, timezone = ${tz}, schedule_cron = ${cron},
          trigger = ${JSON.stringify(trigger)}::jsonb,
          ends_at = ${ends?.toISOString() ?? null}::timestamptz, max_runs = ${maxRuns}::int, run_count = ${runCount}::int,
          next_run_at = ${next?.toISOString() ?? null}::timestamptz, retime_pending = false
        where id = ${args.routine_id}::uuid`);
      const parts = [
        enabled ? "on" : "paused",
        type === "once" && next ? `runs once at ${next.toISOString()}` : null,
        type === "schedule" && next ? `next run ${next.toISOString()} (${tz})` : null,
        endsText(ends, maxRuns, runCount) || null,
      ].filter(Boolean);
      return {
        content: `Routine updated: ${parts.join(", ")}.`,
        preview: enabled ? "updated" : "paused",
      };
    },
  });

  registry.register({
    name: "routines.delete",
    description:
      "Delete one of your routines for good (its past results stay). Find its id with routines.list.",
    risk: "medium",
    // Only the bot's own state inside Casama: never asks (D-155).
    selfOnly: true,
    schema: z.object({ routine_id: z.uuid(), bot: BOT_ARG }),
    async execute(args, ctx) {
      const target = await routineBot(args.bot, ctx);
      const rows = await db.execute<{ name: string }>(sql`
        delete from public.routines where id = ${args.routine_id}::uuid and bot_id = ${target}::uuid returning name`);
      if (!rows.length)
        throw new ToolError(
          "routine_not_found",
          "No such routine for this bot. Check routines.list.",
        );
      return {
        content: `Deleted routine "${rows[0]?.name}".`,
        preview: `deleted ${rows[0]?.name}`,
      };
    },
  });

  // --- delegation ------------------------------------------------------------------

  /** Creates a child run (subagent or peer bot) and runs it to completion. */
  async function runChildTask(
    ctx: ToolContext,
    opts: {
      botId: string;
      task: string;
      trigger: "subagent" | "delegation";
      budgetUsd?: number;
      tools?: string[];
      timeoutS?: number;
    },
  ) {
    if (!deps.runChild)
      throw new ToolError("delegation_unavailable", "Delegation is not available here.");
    const chain = await ancestry(db, ctx.runId);
    if (chain.length >= MAX_DELEGATION_DEPTH + 1)
      throw new ToolError(
        "delegation_too_deep",
        `Delegation is limited to ${MAX_DELEGATION_DEPTH} levels.`,
      );
    if (opts.trigger === "delegation" && chain.some((c) => c.bot_id === opts.botId)) {
      throw new ToolError(
        "delegation_cycle",
        "That bot is already working on this chain of tasks; delegating to it would create a cycle.",
      );
    }
    const [parent] = await db.execute<RunRow>(sql`
      select r.id, r.org_id, r.bot_id, r.parent_run_id, r.budget, r.cost_usd, r.created_by, b.budget as bot_budget
      from public.runs r join public.bots b on b.id = r.bot_id where r.id = ${ctx.runId}::uuid`);
    if (!parent) throw new ToolError("run_not_found", "Parent run not found.");
    const parentLimit = Number(
      (parent.budget as { per_run_usd?: number }).per_run_usd ??
        (parent.bot_budget as { per_run_usd?: number })?.per_run_usd ??
        Number.NaN,
    );
    const budget =
      opts.budgetUsd ??
      subagentBudget(Number.isFinite(parentLimit) ? parentLimit : null, Number(parent.cost_usd));

    let conversationId: string | null = null;
    if (opts.trigger === "delegation") {
      const [bot] = await db.execute<{ name: string }>(
        sql`select name from public.bots where id = ${ctx.botId}::uuid`,
      );
      const [conv] = await db.execute<{ id: string }>(sql`
        insert into public.conversations (org_id, bot_id, title) values (${ctx.orgId}::uuid, ${opts.botId}::uuid, ${`Task from ${bot?.name ?? "a bot"}`}) returning id`);
      conversationId = conv?.id ?? null;
    }
    const [child] = await db.execute<{ id: string }>(sql`
      insert into public.runs (org_id, bot_id, conversation_id, parent_run_id, created_by, trigger, budget, project_id)
      values (${ctx.orgId}::uuid, ${opts.botId}::uuid, ${conversationId}::uuid, ${ctx.runId}::uuid, ${parent.created_by}::uuid, ${opts.trigger},
              ${JSON.stringify({ per_run_usd: budget, task: opts.task, tools: opts.tools, timeout_s: opts.timeoutS ?? 600 })}::jsonb,
              (select project_id from public.runs where id = ${ctx.runId}::uuid))
      returning id`);
    const childId = child?.id as string;
    if (conversationId) {
      await db.execute(sql`insert into public.messages (org_id, conversation_id, role, content, run_id)
        values (${ctx.orgId}::uuid, ${conversationId}::uuid, 'user', ${contentKeys.sealJson(ctx.orgId, [{ type: "text", text: opts.task }])}::jsonb, ${childId}::uuid)`);
    }
    await emit(db, ctx.runId, "subrun.started", {
      child_run_id: childId,
      bot_id: opts.botId,
      task: opts.task.slice(0, 1000),
    });
    const { status } = await deps.runChild(childId);
    const summary = status === "completed" ? await finalText(db, childId) : "";
    const [failed] = await db.execute<{ error: { code?: string; message?: string } | null }>(
      sql`select error from public.runs where id = ${childId}::uuid`,
    );
    const outcome = (
      status === "completed" ? "completed" : status === "cancelled" ? "cancelled" : "failed"
    ) as "completed";
    const note =
      status === "completed"
        ? summary
        : `Stopped: ${failed?.error?.code ?? status}. ${failed?.error?.message ?? ""}`.trim();
    await emit(db, ctx.runId, "subrun.completed", {
      child_run_id: childId,
      status: outcome,
      summary: note.slice(0, 4000),
    });
    return { childId, status, note, budget };
  }

  registry.register({
    name: "subagent.spawn",
    description:
      "Start a short-lived helper (a copy of you with a fresh context) for a self-contained task. It has its own budget (default 20% of what you have left), a time limit and optionally fewer tools, and returns a summary.",
    risk: "low",
    schema: z.object({
      task: z.string().min(1).max(20_000),
      tools: z.array(z.string().max(120)).max(50).optional(),
      budget_usd: z.number().positive().max(100).optional(),
      timeout_s: z.number().int().min(10).max(3600).optional(),
    }),
    async execute(args, ctx) {
      const r = await runChildTask(ctx, {
        botId: ctx.botId,
        task: args.task,
        trigger: "subagent",
        budgetUsd: args.budget_usd,
        tools: args.tools,
        timeoutS: args.timeout_s,
      });
      return {
        content: `Subagent ${r.status} (budget $${r.budget}).\n${r.note}`,
        preview: `subagent ${r.status}`,
      };
    },
  });

  registry.register({
    name: "subagent.spawn_many",
    description:
      "Start up to 5 helpers at once, each a copy of you with a fresh context, and wait for all of them: for work that splits into independent parts (research several companies, check several sites, draft several sections). Each part gets an equal share of the budget (together 40% of what you have left, unless budget_usd is set). Returns every helper's summary in order. For research, ask each helper for the same fields with sources so you can merge them into one table.",
    risk: "low",
    schema: z.object({
      tasks: z.array(z.string().min(1).max(20_000)).min(2).max(5),
      tools: z.array(z.string().max(120)).max(50).optional(),
      budget_usd: z.number().positive().max(100).optional(),
      timeout_s: z.number().int().min(10).max(3600).optional(),
    }),
    async execute(args, ctx) {
      // One share each, decided before any helper spends, so the first can't starve the rest.
      let each = args.budget_usd
        ? Math.round((args.budget_usd / args.tasks.length) * 10_000) / 10_000
        : undefined;
      if (!each) {
        const [parent] = await db.execute<RunRow>(sql`
          select r.id, r.org_id, r.bot_id, r.parent_run_id, r.budget, r.cost_usd, r.created_by, b.budget as bot_budget
          from public.runs r join public.bots b on b.id = r.bot_id where r.id = ${ctx.runId}::uuid`);
        const limit = Number(
          (parent?.budget as { per_run_usd?: number } | undefined)?.per_run_usd ??
            (parent?.bot_budget as { per_run_usd?: number } | undefined)?.per_run_usd ??
            Number.NaN,
        );
        const pool =
          subagentBudget(Number.isFinite(limit) ? limit : null, Number(parent?.cost_usd ?? 0)) * 2;
        each = Math.max(0.01, Math.round((pool / args.tasks.length) * 100) / 100);
      }
      const results = await Promise.all(
        args.tasks.map((task) =>
          runChildTask(ctx, {
            botId: ctx.botId,
            task,
            trigger: "subagent",
            budgetUsd: each,
            tools: args.tools,
            timeoutS: args.timeout_s,
          }).catch((err: unknown) => ({
            childId: "",
            status: "failed",
            note: `Couldn't start: ${(err as Error).message}`,
            budget: each as number,
          })),
        ),
      );
      const done = results.filter((r) => r.status === "completed").length;
      return {
        content: results
          .map((r, n) => `## Helper ${n + 1} of ${results.length}: ${r.status}\n${r.note}`)
          .join("\n\n"),
        preview: `${done} of ${results.length} helpers finished`,
      };
    },
  });

  registry.register({
    name: "bots.delegate",
    description: "Hand a task to another bot in your workspace (by name). Waits for its result.",
    risk: "low",
    schema: z.object({
      bot: z.string().min(1).max(100),
      task: z.string().min(1).max(20_000),
      budget_usd: z.number().positive().max(100).optional(),
    }),
    async execute(args, ctx) {
      const peer = await botByRef(ctx.orgId, args.bot);
      if (!peer) throw new ToolError("bot_not_found", `No bot named ${args.bot}.`);
      if (peer.id === ctx.botId)
        throw new ToolError("delegation_cycle", "Use subagent.spawn to hand work to yourself.");
      // Bot-to-bot switch (D-133): handing work to peer bots can be turned off; subagents still work.
      const [org] = await deps.db.execute<{ allow: boolean }>(
        sql`select allow_bot_to_bot as allow from public.organizations where id = ${ctx.orgId}::uuid`,
      );
      if (org && !org.allow)
        throw new ToolError(
          "bot_to_bot_off",
          "Bots can't hand work to each other in this workspace (an admin turned it off). Use subagent.spawn instead.",
        );
      const r = await runChildTask(ctx, {
        botId: peer.id,
        task: args.task,
        trigger: "delegation",
        budgetUsd: args.budget_usd,
      });
      return {
        content: `${peer.name} ${r.status}.\n${r.note}`,
        preview: `${peer.name} ${r.status}`,
      };
    },
  });

  // --- media generation ---------------------------------------------------------

  // Generated media (D-205) is kept twice: in chat_media, so it shows under the reply whether or
  // not there is a computer, and in the computer's media/ folder when there is one.
  async function mediaBytes(media: { url: string; data?: Uint8Array }) {
    if (media.data) return media.data;
    if (!media.url) return null;
    const res = await deps.fetch(media.url);
    if (!res.ok) return null;
    return new Uint8Array(await res.arrayBuffer());
  }

  async function saveMedia(ctx: ToolContext, bytes: Uint8Array | null, ext: string) {
    if (!ctx.computer || !bytes) return null;
    const asked = `media/${new Date().toISOString().replace(/[:.]/g, "-")}.${ext}`;
    // On a team computer this is in the bot's own folder (D-148): report where it really is.
    const h = await ctx.computer();
    const path = h.resolvePath?.(asked) ?? asked;
    await h.writeFile(path, bytes);
    return path;
  }

  /**
   * A file the bot points at, for tools that take one as input: `media:<id>` for a file kept
   * in this workspace's chats, otherwise a path on the bot's computer (`workspace/uploads/…` as
   * attachments are listed, `~/…`, absolute, or relative to its working folder).
   */
  async function loadFile(ctx: ToolContext, ref: string): Promise<MediaInput & { name: string }> {
    const id = /^media:([0-9a-f-]{36})$/.exec(ref.trim())?.[1];
    if (id) {
      const [row] = await db.execute<{
        content_type: string;
        name: string | null;
      }>(sql`
        select content_type, name from public.chat_media
        where id = ${id}::uuid and org_id = ${ctx.orgId}::uuid`);
      if (!row) throw new ToolError("file_not_found", `There's no chat file ${ref}.`);
      const { readMedia } = await import("../media-store.ts");
      const data = await readMedia(db, deps.objects, id);
      if (!data) throw new ToolError("file_not_found", `The chat file ${ref} is gone.`);
      return {
        data,
        contentType: row.content_type,
        name: row.name ?? `${id}.${row.content_type.split("/")[1] ?? "bin"}`,
      };
    }
    if (!ctx.computer)
      throw new ToolError(
        "file_not_found",
        `${ref} would be on your computer, and you don't have one here. Pass a media: id instead.`,
      );
    const path = ref.trim().startsWith("workspace/") ? `~/${ref.trim()}` : ref.trim();
    const data = await (await ctx.computer()).readFile(path).catch(() => {
      throw new ToolError("file_not_found", `There's no file at ${ref} on your computer.`);
    });
    if (data.length > MAX_INPUT_BYTES)
      throw new ToolError("file_too_large", `${ref} is over 25 MB, too big to pass on.`);
    const name = path.split("/").pop() ?? path;
    return { data, contentType: contentTypeOf(name), name };
  }

  /** Whether this workspace has a key that makes this kind of media. */
  async function mediaReady(orgId: string, kind: "image" | "video") {
    const provider = await deps.mediaFor?.(orgId);
    return !!provider && provider.supports?.(kind) !== false;
  }

  /** The saved file's name (the chat copy shares it, so a link to it isn't shown twice). */
  const fileName = (path: string | null, fallback: string) => path?.split("/").pop() || fallback;

  /** Keeps the file for the chat; null when it couldn't be (too big, or the download failed). */
  /** What the tool says when a full Library didn't keep the new file (D-276). */
  const kept = (shown: string | null | typeof LIBRARY_FULL) =>
    shown === LIBRARY_FULL
      ? {
          id: null,
          note: `\nIt wasn't kept in the person's Library or shown in the chat. ${new StorageFullError().message} Tell the person this plainly.`,
        }
      : { id: shown, note: "" };

  async function keepForChat(
    ctx: ToolContext,
    bytes: Uint8Array | null,
    media: MediaResult,
    name: string,
    /** What the Library calls it (D-274): the bot's title, else the prompt's first words. */
    title?: string,
  ): Promise<string | null | typeof LIBRARY_FULL> {
    if (!bytes || bytes.length === 0 || bytes.length > CHAT_MEDIA_MAX_BYTES) return null;
    // A full Library keeps nothing new (D-276); the file is still on the computer, and the bot
    // is told so it can tell the person (like pages and kept files, which refuse outright).
    const full = await checkStorage(db, ctx.orgId, bytes.length).then(
      () => false,
      (err) => err instanceof StorageFullError,
    );
    if (full) return LIBRARY_FULL;
    // The bytes go to the object store when the server has one (D-290); Postgres otherwise.
    const { randomUUID } = await import("node:crypto");
    const { mediaKey } = await import("../media-store.ts");
    const id = randomUUID();
    const key = deps.objects ? mediaKey(ctx.orgId, id) : null;
    if (deps.objects && key) await deps.objects.put(key, bytes);
    const [row] = await db.execute<{ id: string }>(sql`
      insert into public.chat_media (id, org_id, bot_id, run_id, conversation_id, name, content_type, bytes, blob_key, size, width, height, duration_s)
      values (${id}::uuid, ${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${ctx.runId}::uuid,
              (select conversation_id from public.runs where id = ${ctx.runId}::uuid),
              ${name}, ${media.contentType}, ${key ? null : Buffer.from(bytes)}, ${key}, ${bytes.length},
              ${media.width ?? null}, ${media.height ?? null}, ${media.durationS ?? null})
      returning id`);
    const named = title ? titleFromText(title) : "";
    if (row?.id && named)
      await db.execute(
        sql`update public.creations set title = ${named} where media_id = ${row.id}::uuid`,
      );
    return row?.id ?? null;
  }

  /**
   * A generation that failed after the provider accepted it was still paid for: it's recorded
   * (marked failed) before the error goes on. Nothing is recorded when the provider refused it.
   */
  const recordFailed =
    (ctx: ToolContext, kind: "media_images" | "media_video_seconds", payer: MediaPayer | null) =>
    async (err: unknown): Promise<never> => {
      if (err instanceof MediaChargedError)
        await recordMedia(
          db,
          ctx,
          kind,
          err.charged.quantity,
          err.charged.costUsd,
          err.charged.model,
          payer,
          { failed: true, ...(err.charged.estimated ? { estimated: true } : {}) },
        ).catch(() => {});
      throw err;
    };

  /** Refuses a request Casama doesn't make (D-419), before any credits are checked or spent. */
  const mediaSafety = async (ctx: ToolContext, req: MediaSafetyRequest) => {
    const log = (message: string, fields: Record<string, unknown>) =>
      deps.log?.(message, { ...fields, run_id: ctx.runId, org_id: ctx.orgId });
    const verdict = await checkMediaRequest(req, deps.mediaSafetyFor?.(ctx), log);
    if (verdict.ok) return;
    log("media request refused", { category: verdict.category, kind: req.kind });
    throw new ToolError("content_refused", verdict.message);
  };

  registry.register({
    name: "media.image.generate",
    description:
      "Generate an image from a text prompt. The image is saved in your computer (media/) when you have one.",
    risk: "medium",
    // Runs without asking under the default autonomy; credit caps and budgets still apply (D-213).
    ready: (ctx) => mediaReady(ctx.orgId, "image"),
    schema: z.object({
      prompt: z.string().min(1).max(4000),
      title: z
        .string()
        .max(120)
        .optional()
        .describe(
          "A short name for it in the person's Library (otherwise the prompt's first words)",
        ),
      size: z.enum(["square", "portrait", "landscape"]).optional(),
    }),
    async execute(args, ctx) {
      const provider = await deps.mediaFor?.(ctx.orgId);
      if (!provider || provider.supports?.("image") === false)
        throw new ToolError(
          "no_media_provider",
          "No image generation key is configured. Add an OpenRouter key in Model keys.",
        );
      await mediaSafety(ctx, { kind: "image", prompt: args.prompt });
      const payer = provider.paidBy?.("image") ?? null;
      if (payer) await needCredits(db, ctx.orgId, mediaCharge(payer, mediaPrices().image));
      const [img] = await provider
        .generateImage({ prompt: args.prompt, size: args.size })
        .catch(recordFailed(ctx, "media_images", payer));
      if (!img) throw new ToolError("media_failed", "No image was returned.");
      await recordMedia(
        db,
        ctx,
        "media_images",
        1,
        img.costUsd ?? mediaPrices().image,
        img.model ?? provider.id,
        payer,
      );
      const ext = img.contentType.includes("png")
        ? "png"
        : img.contentType.includes("webp")
          ? "webp"
          : "jpg";
      const bytes = await mediaBytes(img).catch(() => null);
      const path = await saveMedia(ctx, bytes, ext).catch(() => null);
      const { id: shown, note } = kept(
        await keepForChat(
          ctx,
          bytes,
          img,
          fileName(path, `image.${ext}`),
          args.title ?? args.prompt,
        ).catch(() => null),
      );
      // Inline images (OpenRouter) have no link; never put their bytes in the conversation.
      const where = img.url ? `Generated image: ${img.url}` : "Generated image";
      return {
        content: `${where}${shown ? `\nThe person already sees it in the chat under your reply: don't link it or name the file. To use it again (animate it, convert it), pass media:${shown}.` : ""}${path ? `\nSaved to ~/workspace/${path}` : img.url || shown ? "" : " (no computer to save it to)"}${note}`,
        preview: path ?? "image generated",
        artifactPath: path,
      };
    },
  });

  // --- bot pictures (docs/BOT-PICTURES-PLAN.md §8) ----------------------------------------

  /** Whether [userId] may change the bot: its creator, or a workspace admin for a team bot. */
  async function canManageBot(botId: string, userId: string | null | undefined) {
    if (!userId) return false;
    const [r] = await db.execute<{ ok: boolean }>(sql`
      select (b.created_by = ${userId}::uuid
              or (b.visibility = 'team' and exists (
                select 1 from public.memberships m
                where m.org_id = b.org_id and m.user_id = ${userId}::uuid and m.role in ('owner', 'admin')))) as ok
      from public.bots b where b.id = ${botId}::uuid`);
    return !!r?.ok;
  }

  /** Stores a picture for a bot; with `use`, the bot switches to it. Returns its id and value. */
  async function storeBotPicture(a: {
    orgId: string;
    botId: string;
    userId: string | null;
    bytes: Uint8Array;
    botName: string;
    source: "generated" | "bot";
    candidate: boolean;
  }) {
    const pic = await makeBotPicture(a.bytes, { botName: a.botName }).catch((e) => {
      throw new ToolError("invalid_arguments", e instanceof Error ? e.message : String(e));
    });
    const original = await makeOriginal(a.bytes).catch(() => null);
    const [row] = await db.execute<{ id: string }>(sql`
      insert into public.bot_images (bot_id, org_id, created_by, source, large, small, original, original_type, colors, candidate)
      values (${a.botId}::uuid, ${a.orgId}::uuid, ${a.userId}::uuid, ${a.source}, ${pic.large}, ${pic.small},
              ${original?.bytes ?? null}, ${original?.type ?? null}, ${pic.colors}, ${a.candidate})
      returning id`);
    if (!row) throw new ToolError("media_failed", "The picture couldn't be saved.");
    return { id: row.id, avatar: pictureAvatar(row.id, pic.colors) };
  }

  /**
   * Draws picture candidates for a bot ("Make one with AI" in the app, and the bot's own tool).
   * Casama's safety check first, then credits, then the drawing; each picture is charged like any
   * other image and recorded with `purpose: bot_picture`. Candidates don't change the bot.
   */
  async function drawBotPictures(a: BotPictureDrawRequest): Promise<{ ids: string[] }> {
    const provider = await deps.mediaFor?.(a.orgId);
    if (!provider || provider.supports?.("image") === false)
      throw new ToolError(
        "no_media_provider",
        "Drawing pictures needs an OpenRouter key. Add one in Model keys.",
      );
    const [bot] = await db.execute<{ name: string; persona_md: string }>(sql`
      select name, persona_md from public.bots where id = ${a.botId}::uuid and org_id = ${a.orgId}::uuid`);
    if (!bot) throw new ToolError("bot_not_found", "Bot not found");
    const prompt = botPicturePrompt(a.style, bot.name, a.description, bot.persona_md);
    const ctx = {
      runId: a.runId ?? null,
      botId: a.botId,
      orgId: a.orgId,
      actingUserId: a.userId,
    } as unknown as ToolContext;
    await mediaSafety(ctx, { kind: "image", prompt });
    const count = Math.max(1, Math.min(2, a.count ?? 2));
    const payer = provider.paidBy?.("image") ?? null;
    if (payer) await needCredits(db, a.orgId, mediaCharge(payer, mediaPrices().image * count));
    const drawn = await Promise.all(
      Array.from({ length: count }, () =>
        provider
          .generateImage({ prompt, size: "square" })
          .then(async ([img]) => {
            if (!img) return null;
            await recordMedia(
              db,
              ctx,
              "media_images",
              1,
              img.costUsd ?? mediaPrices().image,
              img.model ?? provider.id,
              payer,
              {
                purpose: "bot_picture",
              },
            );
            return mediaBytes(img);
          })
          .catch(recordFailed(ctx, "media_images", payer))
          .catch((e) => (count > 1 ? null : Promise.reject(e))),
      ),
    );
    const ids: string[] = [];
    for (const bytes of drawn) {
      if (!bytes) continue;
      const p = await storeBotPicture({
        orgId: a.orgId,
        botId: a.botId,
        userId: a.userId,
        bytes,
        botName: bot.name,
        source: "generated",
        candidate: true,
      }).catch(() => null);
      if (p) ids.push(p.id);
    }
    if (ids.length === 0)
      throw new ToolError("media_failed", "No picture came back. Try again in a moment.");
    return { ids };
  }

  async function storeWorkspacePicture(a: {
    orgId: string;
    userId: string | null;
    bytes: Uint8Array;
    workspaceName: string;
    source: "generated";
    candidate: boolean;
  }) {
    const pic = await makeBotPicture(a.bytes, { botName: a.workspaceName }).catch((e) => {
      throw new ToolError("invalid_arguments", e instanceof Error ? e.message : String(e));
    });
    const original = await makeOriginal(a.bytes).catch(() => null);
    const [row] = await db.execute<{ id: string }>(sql`
      insert into public.workspace_images (org_id, created_by, source, large, small, original, original_type, colors, candidate)
      values (${a.orgId}::uuid, ${a.userId}::uuid, ${a.source}, ${pic.large}, ${pic.small},
              ${original?.bytes ?? null}, ${original?.type ?? null}, ${pic.colors}, ${a.candidate})
      returning id`);
    if (!row) throw new ToolError("media_failed", "The picture couldn't be saved.");
    return { id: row.id, avatar: pictureAvatar(row.id, pic.colors) };
  }

  async function drawWorkspacePictures(a: WorkspacePictureDrawRequest): Promise<{ ids: string[] }> {
    const provider = await deps.mediaFor?.(a.orgId);
    if (!provider || provider.supports?.("image") === false)
      throw new ToolError(
        "no_media_provider",
        "Drawing pictures needs an OpenRouter key. Add one in Model keys.",
      );
    const [org] = await db.execute<{ name: string }>(sql`
      select name from public.organizations where id = ${a.orgId}::uuid`);
    if (!org) throw new ToolError("org_not_found", "Workspace not found");
    const prompt = workspacePicturePrompt(a.style, org.name, a.description);
    const ctx = {
      runId: null,
      botId: null,
      orgId: a.orgId,
      actingUserId: a.userId,
    } as unknown as ToolContext;
    await mediaSafety(ctx, { kind: "image", prompt });
    const count = Math.max(1, Math.min(2, a.count ?? 2));
    const payer = provider.paidBy?.("image") ?? null;
    if (payer) await needCredits(db, a.orgId, mediaCharge(payer, mediaPrices().image * count));
    const drawn = await Promise.all(
      Array.from({ length: count }, () =>
        provider
          .generateImage({ prompt, size: "square" })
          .then(async ([img]) => {
            if (!img) return null;
            await recordMedia(
              db,
              ctx,
              "media_images",
              1,
              img.costUsd ?? mediaPrices().image,
              img.model ?? provider.id,
              payer,
              {
                purpose: "workspace_picture",
              },
            );
            return mediaBytes(img);
          })
          .catch(recordFailed(ctx, "media_images", payer))
          .catch((e) => (count > 1 ? null : Promise.reject(e))),
      ),
    );
    const ids: string[] = [];
    for (const bytes of drawn) {
      if (!bytes) continue;
      const p = await storeWorkspacePicture({
        orgId: a.orgId,
        userId: a.userId,
        bytes,
        workspaceName: org.name,
        source: "generated",
        candidate: true,
      }).catch(() => null);
      if (p) ids.push(p.id);
    }
    if (ids.length === 0)
      throw new ToolError("media_failed", "No picture came back. Try again in a moment.");
    return { ids };
  }
  deps.exposeBotPictures?.({ draw: drawBotPictures, drawWorkspace: drawWorkspacePictures });

  registry.register({
    name: "profile.set_picture",
    description:
      "Change your own picture (your avatar in Casama). Use it when the person asks: from a picture in the conversation (image: its media: id or a path on your computer), or draw a new one (draw: what it shows, with a style). undo: true goes back to the picture you had before. Only someone who manages you can ask for this. After changing it, tell the person in a few words; they can say 'undo' or pick an earlier one under your picture.",
    risk: "low",
    schema: z.object({
      image: z.string().min(1).max(1000).optional(),
      draw: z.string().min(1).max(400).optional(),
      style: z.enum(BOT_PICTURE_STYLES).optional(),
      undo: z.boolean().optional(),
    }),
    async execute(args, ctx) {
      if (!(await canManageBot(ctx.botId, ctx.actingUserId)))
        throw new ToolError(
          "forbidden",
          "Only someone who manages you can change your picture. Say so plainly.",
        );
      const given = [args.image, args.draw, args.undo ? "undo" : undefined].filter(Boolean).length;
      if (given !== 1)
        throw new ToolError("invalid_arguments", "Pass exactly one of image, draw or undo.");
      const [bot] = await db.execute<{ name: string; avatar_url: string | null }>(sql`
        select name, avatar_url from public.bots where id = ${ctx.botId}::uuid`);
      if (!bot) throw new ToolError("bot_not_found", "Bot not found");
      if (args.undo) {
        const [prev] = await db.execute<{ id: string; colors: string }>(sql`
          select id, colors from public.bot_images
          where bot_id = ${ctx.botId}::uuid and not candidate and used_at is not null
            and ${bot.avatar_url ?? ""} not like '%' || id::text || '%'
          order by used_at desc limit 1`);
        if (!prev) throw new ToolError("not_found", "There's no earlier picture to go back to.");
        await db.execute(
          sql`update public.bots set avatar_url = ${pictureAvatar(prev.id, prev.colors)} where id = ${ctx.botId}::uuid`,
        );
        await ctx.emit("bot.picture", { bot_id: ctx.botId, image_id: prev.id });
        return { content: "Back to your previous picture.", preview: "picture restored" };
      }
      let id: string;
      let avatar: string;
      if (args.draw) {
        const { ids } = await drawBotPictures({
          orgId: ctx.orgId,
          botId: ctx.botId,
          userId: ctx.actingUserId ?? null,
          runId: ctx.runId,
          style: args.style ?? "cloud",
          description: args.draw,
          count: 1,
        });
        const [row] = await db.execute<{ colors: string }>(
          sql`select colors from public.bot_images where id = ${ids[0]}::uuid`,
        );
        id = ids[0]!;
        avatar = pictureAvatar(id, row!.colors);
        await db.execute(sql`update public.bot_images set source = 'bot' where id = ${id}::uuid`);
      } else {
        const f = await loadFile(ctx, args.image!);
        if (!f.contentType.startsWith("image/"))
          throw new ToolError(
            "invalid_arguments",
            `${args.image} is ${f.contentType}, not a picture.`,
          );
        ({ id, avatar } = await storeBotPicture({
          orgId: ctx.orgId,
          botId: ctx.botId,
          userId: ctx.actingUserId ?? null,
          bytes: f.data,
          botName: bot.name,
          source: "bot",
          candidate: false,
        }));
      }
      await db.execute(
        sql`update public.bots set avatar_url = ${avatar} where id = ${ctx.botId}::uuid`,
      );
      await ctx.emit("bot.picture", { bot_id: ctx.botId, image_id: id });
      return {
        content:
          "Your picture is changed; the person sees it now. If they don't like it, profile.set_picture with undo: true goes back.",
        preview: "picture changed",
      };
    },
  });

  registry.register({
    name: "media.audio.generate",
    description:
      "Make spoken audio from text: a narration, a voiceover, a podcast intro, a message read in a voice. It shows under your reply and is kept in the person's Library. Up to 4,000 characters; for longer pieces make several and join them with ffmpeg.",
    risk: "low",
    confirm: true,
    ready: async ({ orgId }) => !!(await deps.speechFor?.(orgId).catch(() => null)),
    schema: z.object({
      text: z.string().min(1).max(4000),
      voice: z
        .string()
        .max(40)
        .optional()
        .describe("A Gemini voice name, such as Kore, Puck or Charon"),
      title: z.string().max(120).optional(),
    }),
    async execute(args, ctx) {
      const speech = await deps.speechFor?.(ctx.orgId);
      if (!speech)
        throw new ToolError(
          "no_speech_key",
          "Spoken audio needs an OpenRouter key. Add one in Settings → Model keys.",
        );
      const { synthesize, ttsCostUsd } = await import("../voice.ts");
      const estimate = ttsCostUsd("openrouter", args.text.length);
      if (speech.billable) await needCredits(db, ctx.orgId, cloudOpenRouterCharge(estimate));
      const r = await synthesize("openrouter", speech.key, args.text, args.voice, {
        fetch: deps.fetch,
        model: speech.model,
        bases: speech.bases,
      });
      const cost = ttsCostUsd("openrouter", args.text.length, r.audio);
      await db.execute(sql`insert into public.usage_ledger (org_id, bot_id, run_id, kind, quantity, cost_usd, upstream_cost_usd, billable, meta)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${ctx.runId}::uuid, 'tts_chars', ${args.text.length},
                ${speech.billable ? cloudOpenRouterCharge(cost) : cost},
                ${speech.billable ? cloudOpenRouterCost(cost) : null}, ${speech.billable},
                ${JSON.stringify(speech.billable ? { provider: "openrouter", provider_cost_usd: cost, key: "server", estimated: true } : {})}::jsonb)`);
      const { wavDurationS } = await import("../voice.ts");
      const path = await saveMedia(ctx, r.audio, "wav").catch(() => null);
      const { id: shown, note } = kept(
        await keepForChat(
          ctx,
          r.audio,
          {
            url: "",
            contentType: r.mime,
            durationS: wavDurationS(r.audio) ?? undefined,
          } as MediaResult,
          fileName(path, "audio.wav"),
          args.title ?? args.text,
        ).catch(() => null),
      );
      return {
        content: `Made ${Math.round(wavDurationS(r.audio) ?? 0)} s of audio.${shown ? ` The person already hears it under your reply: don't link it. To reuse it, pass media:${shown}.` : ""}${path ? `\nSaved to ~/workspace/${path}` : ""}${note}`,
        preview: path ?? "audio made",
        artifactPath: path,
      };
    },
  });

  registry.register({
    name: "media.video.generate",
    description:
      "Generate a short video clip from a text prompt (can take a few minutes). To animate a picture (one you made, or one the person sent), pass it as image: its media: id or its path on your computer; the clip then starts from that exact picture. Saved in your computer (media/) when you have one.",
    risk: "medium",
    // Runs without asking under the default autonomy; credit caps and budgets still apply (D-213).
    ready: (ctx) => mediaReady(ctx.orgId, "video"),
    schema: z.object({
      prompt: z.string().min(1).max(4000),
      title: z
        .string()
        .max(120)
        .optional()
        .describe(
          "A short name for it in the person's Library (otherwise the prompt's first words)",
        ),
      duration_s: z.number().int().min(1).max(20).optional(),
      image: z
        .string()
        .min(1)
        .max(1000)
        .optional()
        .describe("A picture to start from: a media: id or a path on your computer."),
    }),
    async execute(args, ctx) {
      const provider = await deps.mediaFor?.(ctx.orgId);
      if (!provider || provider.supports?.("video") === false)
        throw new ToolError(
          "no_media_provider",
          "No video generation key is configured. Add an OpenRouter key in Model keys.",
        );
      const image = args.image ? await loadFile(ctx, args.image) : undefined;
      if (image && !image.contentType.startsWith("image/"))
        throw new ToolError(
          "invalid_arguments",
          `${args.image} is ${image.contentType}, not a picture. Pass an image to animate.`,
        );
      await mediaSafety(ctx, { kind: "video", prompt: args.prompt, fromPhoto: !!image });
      const payer = provider.paidBy?.("video") ?? null;
      if (payer)
        await needCredits(
          db,
          ctx.orgId,
          mediaCharge(payer, (args.duration_s ?? 5) * mediaPrices().videoPerSecond),
        );
      const video = await provider
        .generateVideo({
          prompt: args.prompt,
          durationS: args.duration_s,
          ...(image ? { image } : {}),
        })
        .catch(recordFailed(ctx, "media_video_seconds", payer));
      const seconds = video.durationS ?? args.duration_s ?? 5;
      await recordMedia(
        db,
        ctx,
        "media_video_seconds",
        seconds,
        video.costUsd ?? seconds * mediaPrices().videoPerSecond,
        video.model ?? provider.id,
        payer,
      );
      const bytes = await mediaBytes(video).catch(() => null);
      const path = await saveMedia(ctx, bytes, "mp4").catch(() => null);
      const { id: shown, note } = kept(
        await keepForChat(
          ctx,
          bytes,
          { ...video, durationS: video.durationS ?? seconds },
          fileName(path, "video.mp4"),
          args.title ?? args.prompt,
        ).catch(() => null),
      );
      const where = video.url ? `Generated video: ${video.url}` : "Generated video";
      return {
        content: `${where}${shown ? `\nThe person already sees it in the chat under your reply: don't link it or name the file. To use it again, pass media:${shown}.` : ""}${path ? `\nSaved to ~/workspace/${path}` : video.url || shown ? "" : " (no computer to save it to)"}${note}`,
        preview: path ?? "video generated",
        artifactPath: path,
      };
    },
  });

  // --- file work without a computer (D-351) ---------------------------------
  // Crop, convert, read and combine files kept in the chat on the server, so a bot on the
  // person's Mac with no shared folders (or with no computer) works on the real file.

  /** A file-op failure is the model's to fix (a bad box, a page that isn't there). */
  const opError = (err: unknown): never => {
    if (err instanceof FileOpError) throw new ToolError("bad_input", err.message);
    throw err;
  };
  const kbOf = (n: number) =>
    n >= 1024 * 1024
      ? `${(n / 1024 / 1024).toFixed(1)} MB`
      : `${Math.max(1, Math.round(n / 1024))} KB`;
  const baseName = (name: string) => name.replace(/\.[^.]+$/, "") || "file";
  /** Keeps a made file in the chat (shown under the reply, sent on to chat apps) and says how. */
  const keepMade = async (
    ctx: ToolContext,
    bytes: Uint8Array,
    contentType: string,
    name: string,
    title: string,
    dims: { width?: number; height?: number } = {},
  ) => {
    const { id, note } = kept(
      await keepForChat(ctx, bytes, { url: "", contentType, ...dims }, name, title).catch(
        () => null,
      ),
    );
    return id
      ? `${name} is shown to the person under your reply: don't link it or name the file. To work on it again, pass media:${id}.${note}`
      : `It couldn't be kept in the chat (too big?).${note}`;
  };
  const fileRef = z
    .string()
    .min(1)
    .max(1000)
    .describe("A media: id from the chat (media:<id>), or a path on your computer");

  registry.register({
    name: "media.image.look",
    description:
      "Look at a picture from the chat or your computer: its size in pixels and the picture itself. Use it before cropping by a box.",
    risk: "low",
    readOnly: true,
    schema: z.object({ file: fileRef }),
    async execute(args, ctx) {
      const f = await loadFile(ctx, args.file);
      const info = await imageInfo(f.data);
      if (!info) throw new ToolError("bad_input", `${args.file} isn't a picture this can open.`);
      // What the model sees is a small copy; its pixel sizes still refer to the original.
      const small = await editImage(f.data, f.contentType, {
        resize: { width: 1024, height: 1024 },
        format: "jpeg",
        quality: 80,
      }).catch(() => null);
      return {
        content: `${f.name}: ${info.width}×${info.height} pixels, ${info.format}. Boxes for media.image.edit use these pixels, from the top left.`,
        preview: `${info.width}×${info.height}`,
        ...(small ? { image: toolImage(small.bytes, small.contentType) } : {}),
      };
    },
  });

  registry.register({
    name: "media.image.edit",
    description:
      "Change a real picture from the chat or your computer, without remaking it: crop to a box or a shape (1:1, 16:9, 4:5, 9:16), resize, rotate, flip, convert (PNG, JPEG, WebP) or shrink. Location and camera details are removed. The new copy shows under your reply. Needs no computer.",
    risk: "low",
    schema: z.object({
      file: fileRef,
      crop: z
        .object({
          left: z.number().min(0),
          top: z.number().min(0),
          width: z.number().min(1),
          height: z.number().min(1),
        })
        .optional()
        .describe("A box in pixels from the top left (see media.image.look for the size)"),
      aspect: z
        .string()
        .max(20)
        .optional()
        .describe('Cut to this shape, keeping as much as fits, like "1:1", "16:9", "4:5"'),
      focus: z
        .enum(["center", "top", "bottom", "left", "right", "auto"])
        .optional()
        .describe("What to keep when cutting to a shape; auto keeps the most interesting part"),
      resize: z
        .object({
          width: z.number().int().min(1).max(8000).optional(),
          height: z.number().int().min(1).max(8000).optional(),
          enlarge: z.boolean().optional(),
        })
        .optional()
        .describe("Fit inside this many pixels, keeping the shape"),
      rotate: z.number().optional().describe("Degrees clockwise, like 90"),
      flip: z.enum(["horizontal", "vertical"]).optional(),
      format: z.enum(["png", "jpeg", "webp"]).optional(),
      quality: z.number().int().min(1).max(100).optional().describe("Lower makes a smaller file"),
      title: z.string().max(120).optional().describe("A short name for it in the person's Library"),
    }),
    async execute(args, ctx) {
      const f = await loadFile(ctx, args.file);
      const out = await editImage(f.data, f.contentType, args).catch(opError);
      const name = `${baseName(f.name)}-edited.${out.ext}`;
      const said = await keepMade(ctx, out.bytes, out.contentType, name, args.title ?? name, out);
      return {
        content: `Made ${name}: ${out.width}×${out.height}, ${kbOf(out.bytes.length)}, from the original ${f.name}. ${said}`,
        preview: `${out.width}×${out.height}`,
        image: toolImage(out.bytes, out.contentType),
      };
    },
  });

  registry.register({
    name: "documents.read",
    description:
      "Read the text of a document from the chat or your computer: PDF, Word (.docx), CSV, Markdown, HTML or plain text. Long ones come a piece at a time (pass offset for the next). Scanned PDFs have no text. Needs no computer.",
    risk: "low",
    readOnly: true,
    untrustedOutput: true,
    schema: z.object({
      file: fileRef,
      offset: z.number().int().min(0).optional().describe("Where to continue, from the last read"),
    }),
    async execute(args, ctx) {
      const f = await loadFile(ctx, args.file);
      const r = await readDocument(f.name, f.data, f.contentType, args.offset ?? 0).catch(opError);
      const more =
        r.next !== null
          ? `\n\n(${r.next} of ${r.total} characters so far: call again with offset ${r.next} for more.)`
          : "";
      return {
        content: `${wrapUntrusted("document", r.text || "This document has no text (a scanned PDF?).")}${more}`,
        preview: `${r.title}: ${r.total} characters`,
      };
    },
  });

  registry.register({
    name: "documents.pdf",
    description:
      "Work on PDFs from the chat or your computer, without a computer: combine PDFs and pictures (photos of receipts, scans) into one PDF; keep, reorder or drop pages; rotate pages; split into pieces. The result shows under your reply.",
    risk: "low",
    schema: z.object({
      action: z.enum(["combine", "pages", "rotate", "split"]),
      files: z
        .array(fileRef)
        .min(1)
        .max(30)
        .describe("combine: PDFs and pictures in order. Other actions: the one PDF"),
      pages: z
        .string()
        .max(200)
        .optional()
        .describe(
          'pages: which to keep, in order, like "1-3, 5". rotate: which to turn (all if left out)',
        ),
      drop: z.string().max(200).optional().describe('pages: which to leave out, like "2, 7-9"'),
      degrees: z.number().optional().describe("rotate: 90, 180 or 270, clockwise"),
      every: z.number().int().min(1).optional().describe("split: pages per piece (1 = each page)"),
      name: z.string().max(120).optional().describe("The new file's name, without .pdf"),
    }),
    async execute(args, ctx) {
      const first = args.files[0] as string;
      const pdf = "application/pdf";
      const named = (fallback: string) => `${(args.name ?? fallback).replace(/\.pdf$/i, "")}.pdf`;
      if (args.action === "combine") {
        const inputs = [];
        for (const ref of args.files) {
          const f = await loadFile(ctx, ref);
          inputs.push({ bytes: f.data, contentType: f.contentType, name: f.name });
        }
        const r = await combinePdf(inputs).catch(opError);
        const name = named("combined");
        const said = await keepMade(ctx, r.bytes, pdf, name, name);
        return {
          content: `Made ${name}: ${r.pages} pages from ${inputs.length} files. ${said}`,
          preview: `${r.pages} pages`,
        };
      }
      const f = await loadFile(ctx, first);
      const base = baseName(f.name);
      if (args.action === "split") {
        const parts = await splitPdf(f.data, args.every ?? 1).catch(opError);
        const lines = [];
        for (const p of parts) {
          const name = named(
            `${args.name ?? base}-${p.from === p.to ? p.from : `${p.from}-${p.to}`}`,
          );
          lines.push(`- ${name}: ${await keepMade(ctx, p.bytes, pdf, name, name)}`);
        }
        return {
          content: `Split ${f.name} into ${parts.length} files:\n${lines.join("\n")}`,
          preview: `${parts.length} files`,
        };
      }
      const r =
        args.action === "rotate"
          ? await rotatePdf(f.data, args.degrees ?? 90, args.pages).catch(opError)
          : await pickPdfPages(f.data, args.pages, args.drop).catch(opError);
      const name = named(`${base}-${args.action === "rotate" ? "rotated" : "pages"}`);
      const said = await keepMade(ctx, r.bytes, pdf, name, name);
      return { content: `Made ${name}: ${r.pages} pages. ${said}`, preview: `${r.pages} pages` };
    },
  });

  registry.register({
    name: "documents.make",
    description:
      "Make a PDF or Word (.docx) file from Markdown: headings, paragraphs, bold, italic, links, lists, tables, quotes, code and pictures (![caption](media:<id>)). Chinese, Japanese and Korean work. Plain look with page numbers. The file shows under your reply and goes to chat apps. Needs no computer. Page size: letter for people in the US and Canada, A4 elsewhere.",
    risk: "low",
    schema: z.object({
      markdown: z.string().min(1).max(300_000),
      format: z.enum(["pdf", "docx"]),
      name: z.string().min(1).max(120).describe("The file's name, without the extension"),
      title: z.string().max(200).optional().describe("The document's title (its properties)"),
      page_size: z.enum(["a4", "letter"]).optional(),
    }),
    async execute(args, ctx) {
      const images = new Map<string, { bytes: Uint8Array; contentType: string }>();
      const missing: string[] = [];
      for (const ref of imageRefs(args.markdown).slice(0, 30)) {
        const f = await loadFile(ctx, ref).catch(() => null);
        if (f?.contentType.startsWith("image/"))
          images.set(ref, { bytes: f.data, contentType: f.contentType });
        else missing.push(ref);
      }
      const r = await makeDocument({
        markdown: args.markdown,
        format: args.format,
        title: args.title ?? args.name,
        pageSize: args.page_size,
        images,
        cjkFontDir: deps.cjkFontDir,
      }).catch(opError);
      const name = `${args.name.replace(/\.(pdf|docx)$/i, "")}.${r.ext}`;
      const said = await keepMade(ctx, r.bytes, r.contentType, name, args.title ?? name);
      return {
        content: `Made ${name}${r.pages ? `: ${r.pages} pages` : ""}, ${kbOf(r.bytes.length)}. ${said}${missing.length ? `\nThese pictures couldn't be found, so their captions are shown instead: ${missing.join(", ")}.` : ""}`,
        preview: name,
      };
    },
  });

  registry.register({
    name: "media.qr.make",
    description:
      "Make a QR code picture for a link, text, contact or Wi-Fi network (WIFI:T:WPA;S:<name>;P:<password>;;). It shows under your reply. Needs no computer.",
    risk: "low",
    schema: z.object({
      text: z.string().min(1).max(2000),
      size: z.number().int().min(128).max(2048).optional().describe("Pixels per side (512)"),
      name: z.string().max(80).optional().describe("The file's name, without .png"),
    }),
    async execute(args, ctx) {
      const r = await makeQr(args.text, args.size ?? 512).catch(opError);
      const name = `${(args.name ?? "qr-code").replace(/\.png$/i, "")}.png`;
      const said = await keepMade(ctx, r.bytes, "image/png", name, name, {
        width: r.width,
        height: r.width,
      });
      return { content: `Made the QR code. ${said}`, preview: "QR code" };
    },
  });

  registry.register({
    name: "media.qr.read",
    description: "Read the QR code in a picture from the chat or your computer.",
    risk: "low",
    readOnly: true,
    untrustedOutput: true,
    schema: z.object({ file: fileRef }),
    async execute(args, ctx) {
      const f = await loadFile(ctx, args.file);
      const text = await readQr(f.data).catch(opError);
      return {
        content: text ? wrapUntrusted("qr", text) : "No QR code could be read in that picture.",
        preview: text ? "read a QR code" : "no QR code",
      };
    },
  });

  registry.register({
    name: "files.from_chat",
    description:
      "Copy a file kept in the chat (a media: id: a picture or video you made) onto your computer, so you can convert or edit it there with your shell tools (for example ffmpeg, pandoc, LibreOffice). Returns its path.",
    risk: "low",
    requires: { computer: true },
    schema: z.object({
      file: z.string().regex(/^media:[0-9a-f-]{36}$/, "a media: id, like media:<id>"),
      path: z.string().min(1).max(1000).optional(),
    }),
    async execute(args, ctx) {
      if (!ctx.computer) throw new ToolError("no_computer", "This needs your computer.");
      const f = await loadFile(ctx, args.file);
      const h = await ctx.computer();
      const asked = args.path ?? `media/${f.name}`;
      const path = h.resolvePath?.(asked) ?? asked;
      await h.writeFile(path, f.data);
      const where = path.startsWith("/") || path.startsWith("~") ? path : `~/workspace/${path}`;
      return {
        content: `Copied ${f.name} (${f.contentType}) to ${where}.`,
        preview: `copied to ${path}`,
      };
    },
  });

  return registry;
}

/** A file reference's type, from its name. */
function contentTypeOf(name: string) {
  const ext = name.split(".").pop()?.toLowerCase() ?? "";
  const types: Record<string, string> = {
    png: "image/png",
    jpg: "image/jpeg",
    jpeg: "image/jpeg",
    webp: "image/webp",
    gif: "image/gif",
    mp4: "video/mp4",
    mov: "video/quicktime",
    webm: "video/webm",
    pdf: "application/pdf",
  };
  return types[ext] ?? "application/octet-stream";
}

/** Largest file a tool reads into memory as input. */
const MAX_INPUT_BYTES = 25 * 1024 * 1024;

/** What a workspace is charged for media Casama paid for: cost with markup (and OpenRouter's fee). */
/** Media on the server's key is OpenRouter's price with its fee and Casama's markup (D-261). */
function mediaCharge(_payer: MediaPayer, providerCostUsd: number) {
  return cloudOpenRouterCharge(providerCostUsd);
}

/**
 * Refuses media (and other paid calls, such as paid data) on the server's key when a credit-gated
 * workspace can't cover it (D-246).
 */
export async function needCredits(db: Database, orgId: string, chargeUsd: number) {
  const [r] = await db.execute<{
    credits: string | null;
    unbilled: string;
    gate: boolean | null;
  }>(sql`
    select
      (select balance_after from public.credit_ledger where org_id = ${orgId}::uuid order by seq desc limit 1) as credits,
      (select coalesce(sum(cost_usd), 0) from public.usage_ledger
        where org_id = ${orgId}::uuid and billable and billed_at is null) as unbilled,
      (select (limits->>'credit_gate')::boolean from public.entitlements
        where org_id = ${orgId}::uuid order by created_at desc limit 1) as gate`);
  if (!r?.gate) return;
  if (Number(r.credits ?? 0) - Number(r.unbilled) < chargeUsd)
    throw new ToolError(
      "out_of_credits",
      "The workspace doesn't have enough credits for this. Add credits or change plans in Billing.",
    );
}

/** A usage row for generated media; billable with markup when Casama's key paid for it. */
async function recordMedia(
  db: Database,
  ctx: ToolContext,
  kind: "media_images" | "media_video_seconds",
  quantity: number,
  providerCostUsd: number,
  model: string,
  payer: MediaPayer | null,
  extra: Record<string, unknown> = {},
) {
  await db.execute(sql`insert into public.usage_ledger (org_id, bot_id, run_id, kind, quantity, cost_usd, upstream_cost_usd, model, billable, meta)
    values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${ctx.runId}::uuid, ${kind}, ${quantity},
            ${payer ? mediaCharge(payer, providerCostUsd) : providerCostUsd},
            ${payer ? cloudOpenRouterCost(providerCostUsd) : null}, ${model}, ${payer != null},
            ${JSON.stringify({ ...(payer ? { provider: payer, provider_cost_usd: providerCostUsd, key: "server" } : {}), ...extra })}::jsonb)`);
}
