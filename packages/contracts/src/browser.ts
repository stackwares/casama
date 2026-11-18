/** Casama for Chrome, Phase 2 (D-323): page commands, highlights and a page's history. */
import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });
const PageUrl = z.url().max(2000);

export const PageCommand = z
  .object({
    id: Uuid,
    name: z.string(),
    prompt: z.string(),
    position: z.number().int(),
    created_at: ts,
    updated_at: ts,
  })
  .openapi("PageCommand");

export const CreatePageCommandRequest = z
  .object({
    name: z.string().trim().min(1).max(60).openapi({ description: "What follows / in the panel" }),
    prompt: z.string().trim().min(1).max(4000),
    position: z.number().int().min(0).max(1000).optional(),
  })
  .openapi("CreatePageCommandRequest");

export const UpdatePageCommandRequest = CreatePageCommandRequest.partial().openapi(
  "UpdatePageCommandRequest",
);

export const Highlight = z
  .object({
    id: Uuid,
    org_id: Uuid,
    url: z.string(),
    url_key: z.string(),
    title: z.string(),
    text: z.string(),
    prefix: z.string(),
    suffix: z.string(),
    note: z.string(),
    created_at: ts,
  })
  .openapi("Highlight");

export const CreateHighlightRequest = z
  .object({
    org_id: Uuid,
    url: PageUrl,
    title: z.string().max(300).optional(),
    text: z.string().min(1).max(5000),
    prefix: z.string().max(64).optional(),
    suffix: z.string().max(64).optional(),
    note: z.string().max(2000).optional(),
  })
  .openapi("CreateHighlightRequest");

export const PageHistory = z
  .object({
    conversations: z.array(
      z.object({ id: Uuid, bot_id: Uuid, title: z.string().nullable(), created_at: ts }),
    ),
    highlights: z.array(Highlight),
  })
  .openapi("PageHistory");

export const CreatePageWatcherRequest = z
  .object({
    bot_id: Uuid.openapi({ description: "The bot woken when the page changes" }),
    name: z.string().trim().min(1).max(120),
    url: PageUrl.openapi({
      description: "The page; the server reads public pages, your browser signed-in ones",
    }),
    anchor: z.string().max(200).optional().openapi({
      description: "Compare from this text on (a label just before the part that matters)",
    }),
    chars: z.number().int().min(20).max(2000).optional().openapi({
      description: "How much after the anchor to compare (default 2,000 characters)",
    }),
    condition: z.string().max(2000).optional().openapi({
      description: 'What counts as a match, in words ("the price drops below $40")',
    }),
    check_every_minutes: z.number().int().min(15).max(10_080).optional(),
    where: z.enum(["server", "mine"]).optional().openapi({
      description:
        '"mine": a signed-in page, read in your own browser whenever it\'s online (Phase 3); default "server" (public pages)',
    }),
  })
  .openapi("CreatePageWatcherRequest");

/**
 * A page's address as a key: no fragment, no tracking parameters, no trailing slash, lower-case
 * host. Two visits to the same article find the same highlights.
 */
export function pageKey(url: string): string {
  try {
    const u = new URL(url);
    u.hash = "";
    for (const k of [...u.searchParams.keys()])
      if (/^(utm_|fbclid$|gclid$|mc_|ref$|ref_src$|igshid$|si$)/i.test(k)) u.searchParams.delete(k);
    u.hostname = u.hostname.toLowerCase();
    if (u.pathname.length > 1 && u.pathname.endsWith("/")) u.pathname = u.pathname.slice(0, -1);
    const s = u.toString();
    return s.endsWith("/") ? s.slice(0, -1) : s;
  } catch {
    return url;
  }
}

// ---------------------------------------------------------------------------------------------
// Phase 3 (D-323): bots in the person's own browser. The worker sends browser tool calls through the
// API's device tunnel to the extension (POST /browser/<action> over the device WebSocket); these are
// the actions and what comes back. Not a public route: the extension and the worker share it.

/** Everything the extension does for browser tools. */
export const BROWSER_ACTIONS = [
  "open",
  "snapshot",
  "read",
  "click",
  "fill",
  "type",
  "press",
  "scroll",
  "screenshot",
  "url",
  "tabs",
  "switch_tab",
  "wait",
  "upload",
  "download",
  "dialog",
  "console",
  "network",
  "extract",
  "page_text",
  "stop",
] as const;
export type BrowserAction = (typeof BROWSER_ACTIONS)[number];

/** One call from the worker. `run` names who is asking; `watcher` is set for page checks instead. */
export interface BrowserCall {
  action: BrowserAction;
  args: Record<string, unknown>;
  run?: { id: string; bot_id: string; bot_name: string; conversation_id?: string | null };
  watcher?: { id: string; bot_id: string; bot_name: string };
}

/** The extension's answer. `code` on failure: offline, refused, asked_denied, handed_off, … */
export type BrowserResult =
  | {
      ok: true;
      text: string;
      /** A screenshot or other picture, base64. */
      image?: { data: string; media_type: string };
      /** A downloaded file, base64 (at most 20 MB). */
      file?: { name: string; media_type: string; data: string };
      url?: string;
    }
  | { ok: false; code: string; message: string };

export const BrowserCallBody = z.object({
  action: z.enum(BROWSER_ACTIONS),
  args: z.record(z.string(), z.unknown()).default({}),
});
