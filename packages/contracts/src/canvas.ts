import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

/**
 * Bot widgets (docs/BOT-WIDGET-PLAN.md): what a bot keeps on a person's Canvas widget, as the
 * widgets, the app and the watches read it (`GET /v1/canvases`). The server has already checked
 * and cut everything and chosen the text colour (`ink`), so renderers only draw. Every entry has a
 * plain `short` and `tiny` form for the Lock Screen and watches. Pictures (and the built-in
 * paintings) are fetched from `/v1/canvases/{id}/pictures/{hash}` with the same key.
 */

const ts = z.iso.datetime({ offset: true });

export const CanvasBackground = z
  .object({
    /** auto: the app's own surface in light and dark mode. A painting arrives as a picture. */
    kind: z.enum(["auto", "color", "gradient", "picture"]),
    /** color: #rrggbb. */
    color: z.string().max(7).nullable(),
    /** gradient: top-leading to bottom-trailing, #rrggbb. */
    from: z.string().max(7).nullable(),
    to: z.string().max(7).nullable(),
    /** picture: its hash in the picture route. */
    picture: z.string().max(80).nullable(),
  })
  .openapi("CanvasBackground");

export const CanvasLookOut = z
  .object({
    background: CanvasBackground,
    font: z.enum(["plain", "serif", "rounded", "mono"]),
    align: z.enum(["start", "center"]),
    /** One emoji, or an icon name from the app's set; null for none. */
    icon: z.string().max(32).nullable(),
    /** #rrggbb for rings and bars; null for the app's accent. */
    accent: z.string().max(7).nullable(),
    /** The text colour the server chose for contrast; auto follows light and dark mode. */
    ink: z.enum(["light", "dark", "auto"]),
  })
  .openapi("CanvasLook");

export const CanvasEntry = z
  .object({
    /** When it shows from; null for the one showing now. */
    at: ts.nullable(),
    template: z.enum(["text", "countdown", "number", "list", "picture"]),
    title: z.string().max(60).nullable(),
    text: z.string().max(280).nullable(),
    footer: z.string().max(40).nullable(),
    /** countdown */
    target: ts.nullable(),
    count: z.enum(["down", "up"]).nullable(),
    /** number */
    value: z.number().nullable(),
    of: z.number().nullable(),
    unit: z.string().max(16).nullable(),
    /** list */
    items: z.array(z.object({ text: z.string().max(60), done: z.boolean() })).max(5),
    /** picture: its hash in the picture route. */
    picture: z.string().max(80).nullable(),
    /** For the Lock Screen rectangle and watches (80), and the line above the clock (24). */
    short: z.string().max(80),
    tiny: z.string().max(24),
    look: CanvasLookOut,
  })
  .openapi("CanvasEntry");

export const Canvas = z
  .object({
    id: Uuid,
    org_id: Uuid,
    /** The bot's name for it ("Daily verse"). */
    name: z.string().max(40),
    bot_id: Uuid,
    bot: z.string().max(80),
    /** `mascot:<name>` or empty for initials. */
    bot_avatar: z.string().max(64),
    status: z.enum(["waiting", "shown", "paused"]),
    hide_when_locked: z.boolean(),
    version: z.number().int(),
    set_at: ts,
    until: ts.nullable(),
    /** The app route a tap opens: the bot's chat. */
    link: z.string().max(300),
    /** A rotation's place: how many items, which shows, how many are left before it loops or stops. */
    rotation: z
      .object({
        count: z.number().int(),
        showing: z.number().int(),
        left: z.number().int(),
        every: z.string().max(120),
      })
      .nullable(),
    /** Up to 14: the one showing now, then the ones planned, with their times. Empty for a private key. */
    entries: z.array(CanvasEntry).max(14),
  })
  .openapi("Canvas");

export const CanvasPlacement = z
  .object({
    platform: z.enum(["ios", "android", "macos"]),
    label: z.string().nullable(),
    /** The sizes it drew last: home_small, home_medium, home_large, home_xl, lock_rect, lock_inline, lock_circle, keyguard. */
    sizes: z.array(z.string().max(20)).max(12),
    seen_at: ts,
  })
  .openapi("CanvasPlacement");

export const CanvasGrant = z
  .object({ bot_id: Uuid, bot: z.string().max(80), created_at: ts })
  .openapi("CanvasGrant");

export const CanvasList = z
  .object({
    /** Changes whenever anything in it does; `If-None-Match` with it answers 304. */
    version: z.string(),
    made_at: ts,
    /** Content hidden (a private widget key, D-405): names and bots only. */
    private: z.boolean(),
    items: z.array(Canvas).max(12),
    /** Session only: the bots this person lets write, and where a Canvas widget is placed. */
    grants: z.array(CanvasGrant).max(200),
    placed: z.array(CanvasPlacement).max(20),
  })
  .openapi("CanvasList");
export type CanvasList = z.infer<typeof CanvasList>;
export type Canvas = z.infer<typeof Canvas>;
export type CanvasEntry = z.infer<typeof CanvasEntry>;

export const CanvasUpdate = z
  .object({
    /** Pause or show again. */
    status: z.enum(["shown", "paused"]).optional(),
    hide_when_locked: z.boolean().optional(),
  })
  .openapi("CanvasUpdate");

export const SetCanvasGrant = z
  .object({ bot_id: Uuid, allowed: z.boolean() })
  .openapi("SetCanvasGrant");
