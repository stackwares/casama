import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

/**
 * The glance (D-405): one small summary of what a person's widgets show, built by the server
 * (`GET /v1/glance`) and read the same way on iPhone, Android and the Mac. See docs/WIDGETS-PLAN.md
 * §8.1. Every list is short and every string is cut; it never carries tool arguments, full messages
 * or anything a secret could be in. Links are app routes ("/bots/<id>/chat?c=…").
 */

const ts = z.iso.datetime({ offset: true });

/** A bot's mark: `mascot:<name>` or empty for initials, as `bots.avatar_url` holds it. */
const Avatar = z.string().max(64);

export const GlanceNeed = z
  .object({
    kind: z.enum(["approval", "takeover", "suggestion"]),
    id: Uuid,
    bot_id: Uuid,
    bot: z.string().max(80),
    bot_avatar: Avatar,
    /** One line: the approval's summary, the takeover's reason, the suggestion's title. */
    text: z.string().max(140),
    /** Approvals only. */
    risk: z.enum(["low", "medium", "high"]).nullable(),
    /** Suggestions only: urgent ones sort first among suggestions. */
    urgent: z.boolean(),
    created_at: ts,
    link: z.string().max(300),
  })
  .openapi("GlanceNeed");

export const GlanceBot = z
  .object({
    id: Uuid,
    name: z.string().max(80),
    avatar: Avatar,
    status: z.enum(["idle", "working", "waiting", "disabled"]),
    /** While it works: what it is doing in general words ("Searching the web"); else null. */
    step: z.string().max(80).nullable(),
    /** Its last message in plain text, two lines' worth; null when hidden (hide_reply_text). */
    last_text: z.string().max(160).nullable(),
    last_at: ts.nullable(),
    /** When it last finished a run (for "Idle · replied 9:20"). */
    busy_at: ts.nullable(),
    link: z.string().max(300),
  })
  .openapi("GlanceBot");

export const GlanceRoutine = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    name: z.string().max(80),
    bot: z.string().max(80),
    bot_avatar: Avatar,
    next_at: ts.nullable(),
    /** How often, in words the server made from the cron ("Every day", "Weekdays at 9:00"). */
    every: z.string().max(60),
    enabled: z.boolean(),
    link: z.string().max(300),
  })
  .openapi("GlanceRoutine");

/** A routine for widget pickers (choose which routine a widget shows or runs). */
export const GlanceRoutineChoice = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    /** "" when private. */
    name: z.string().max(80),
    bot: z.string().max(80),
    enabled: z.boolean(),
  })
  .openapi("GlanceRoutineChoice");

export const GlanceBrief = z
  .object({
    bot_id: Uuid,
    bot: z.string().max(80),
    bot_avatar: Avatar,
    /** Plain text, cut to about 600 characters; null before today's arrives. */
    text: z.string().max(640).nullable(),
    at: ts.nullable(),
    /** When the next one is due (local brief time), for "Brief at 7:00". */
    next_at: ts.nullable(),
    link: z.string().max(300),
  })
  .openapi("GlanceBrief");

export const GlanceDone = z
  .object({
    bot_id: Uuid,
    bot: z.string().max(80),
    bot_avatar: Avatar,
    /** What it made or did: a creation's title, a routine's name, or "Replied". */
    title: z.string().max(100),
    at: ts,
    link: z.string().max(300),
  })
  .openapi("GlanceDone");

export const GlanceCreation = z
  .object({
    id: Uuid,
    kind: z.enum(["page", "image", "video", "audio", "document", "file"]),
    title: z.string().max(100),
    bot: z.string().max(80).nullable(),
    has_cover: z.boolean(),
    /** Bumps when the cover changes; widgets cache covers by id and version. */
    version: z.number().int(),
    at: ts,
    link: z.string().max(300),
  })
  .openapi("GlanceCreation");

export const GlanceTask = z
  .object({
    id: Uuid,
    title: z.string().max(100),
    status: z.enum(["todo", "in_progress", "in_review", "blocked", "done"]),
    bot: z.string().max(80).nullable(),
    link: z.string().max(300),
  })
  .openapi("GlanceTask");

export const GlanceCredits = z
  .object({
    /** False on a server with billing off: only the spends below are meaningful. */
    billing: z.boolean(),
    unlimited: z.boolean(),
    plan: z.string().max(40).nullable(),
    /** Share of this period's credits used, 0–1; null when unknown. */
    used_share: z.number().min(0).max(1).nullable(),
    left_usd: z.number().nullable(),
    today_usd: z.number(),
    month_usd: z.number(),
    /** A daily cap (the Free plan): its use and when it resets. */
    daily_cap_usd: z.number().nullable(),
    daily_used_usd: z.number().nullable(),
    resets_at: ts.nullable(),
  })
  .openapi("GlanceCredits");

export const GlanceStarter = z
  .object({ emoji: z.string().max(16), text: z.string().max(120) })
  .openapi("GlanceStarter");

export const Glance = z
  .object({
    /** Bumps when anything in it changes; `If-None-Match` with it answers 304. */
    version: z.string(),
    made_at: ts,
    org_id: Uuid,
    needs: z.object({ count: z.number().int().min(0), items: z.array(GlanceNeed).max(4) }),
    bots: z.array(GlanceBot).max(8),
    next: z.array(GlanceRoutine).max(6),
    /** Every routine on the workspace's bots, the person's own first, for pickers (max 20). */
    routines: z.array(GlanceRoutineChoice).max(20),
    brief: GlanceBrief.nullable(),
    lately: z.array(GlanceDone).max(3),
    recent: z.array(GlanceCreation).max(6),
    tasks: z.object({
      counts: z.object({
        todo: z.number().int(),
        in_progress: z.number().int(),
        in_review: z.number().int(),
        blocked: z.number().int(),
      }),
      items: z.array(GlanceTask).max(3),
    }),
    credits: GlanceCredits,
    /** For the Ask widget: the default bot's starters (D-338). */
    starters: z.array(GlanceStarter).max(4),
    flags: z.object({
      /** Widgets show counts and general words only (Lock Screen, app lock, D-405 §10). */
      private: z.boolean(),
      hide_reply_text: z.boolean(),
    }),
  })
  .openapi("Glance");

export type Glance = z.infer<typeof Glance>;

/** A widget key (D-405 §8.3): reads the glance and creation covers, nothing else. */
export const WidgetKeyCreate = z
  .object({
    org_id: Uuid,
    platform: z.enum(["ios", "android", "macos"]),
    label: z.string().max(80).optional(),
  })
  .openapi("WidgetKeyCreate");

export const WidgetKeyCreated = z
  .object({ id: Uuid, key: z.string().openapi({ description: "Shown once" }), created_at: ts })
  .openapi("WidgetKeyCreated");

/** A widget key as the app sees it (never the key itself). */
export const WidgetKey = z
  .object({
    id: Uuid,
    org_id: Uuid,
    platform: z.enum(["ios", "android", "macos"]),
    label: z.string().nullable(),
    /** The glance it reads is private (D-405 §10): counts and general words only. */
    private: z.boolean(),
    /** Whether refresh pushes have somewhere to go. */
    has_push: z.boolean(),
    last_used_at: ts.nullable(),
    created_at: ts,
  })
  .openapi("WidgetKey");

export const WidgetKeyUpdate = z
  .object({ private: z.boolean().optional() })
  .openapi("WidgetKeyUpdate");

/** Sent by a widget extension or the app: where to send refresh pushes for this key's widgets. */
export const WidgetPushToken = z
  .object({
    /** Apple's WidgetKit push token (hex) or an Android phone's Firebase token. */
    token: z.string().min(8).max(4096),
    kind: z.enum(["apns_widgets", "fcm"]),
    /** APNs environment for Apple tokens. */
    sandbox: z.boolean().optional(),
  })
  .openapi("WidgetPushToken");
