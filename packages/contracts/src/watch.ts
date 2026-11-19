import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

/**
 * Casama on the wrist (D-410, docs/WATCH-PLAN.md §8): watch keys, signing a watch in, and the few
 * routes a watch calls with `Authorization: Watch <key>`.
 *
 * A watch makes its own key (`cwt_` and 43 base64url characters, from 32 random bytes) and keeps
 * it. Its fingerprint is `sha256hex("casama-watch-key:" + key)`: that is all the phone, the link
 * between them and the sign-in code ever carry, and what the server stores. The server hands the
 * watch finished words: the watch apps never work out a risk, a step or a summary themselves.
 */

const ts = z.iso.datetime({ offset: true });

/** A bot's mark: `mascot:<name>` or empty for initials, as `bots.avatar_url` holds it. */
const Avatar = z.string().max(64);

/** sha256 of "casama-watch-key:" + the key, as 64 lowercase hex characters. */
export const WatchFingerprint = z
  .string()
  .regex(/^[0-9a-f]{64}$/)
  .openapi("WatchFingerprint", { description: 'sha256hex("casama-watch-key:" + key)' });

export const WatchPlatform = z.enum(["watchos", "wearos"]).openapi("WatchPlatform");

/** How much a person lets their watches allow (§6.10): medium (the default), low only, nothing. */
export const WatchAllowLevel = z.enum(["medium", "low", "none"]).openapi("WatchAllowLevel");

/** Where on the watch something was done, for counting (§15). */
export const WatchSurface = z
  .enum(["app", "notification", "complication", "smart_stack", "tile", "control", "siri"])
  .openapi("WatchSurface");

/** What a watch says about itself: shown on the phone's Settings → Watch. */
const WatchDevice = {
  platform: WatchPlatform,
  /** The watch's own name ("Oliver's Apple Watch"). */
  name: z.string().min(1).max(80),
  /** "Apple Watch Series 10, 46 mm", "Pixel Watch 3". */
  model: z.string().max(80).optional(),
  app_version: z.string().max(40).optional(),
  os_version: z.string().max(40).optional(),
};

// --- the phone's side (the person's session) -------------------------------------------------

/** The phone registers the fingerprint its watch sent it over the phone link (§8.2). */
export const WatchKeyRegister = z
  .object({ org_id: Uuid, fingerprint: WatchFingerprint, ...WatchDevice })
  .openapi("WatchKeyRegister");

/** A signed-in watch as the phone lists it (never the key or its fingerprint). */
export const WatchKey = z
  .object({
    id: Uuid,
    org_id: Uuid,
    platform: WatchPlatform,
    name: z.string(),
    model: z.string().nullable(),
    app_version: z.string().nullable(),
    os_version: z.string().nullable(),
    /** How it was signed in. */
    paired_by: z.enum(["phone", "code"]),
    /** Whether pushes can reach the watch directly (its own token). */
    has_push: z.boolean(),
    last_used_at: ts.nullable(),
    created_at: ts,
  })
  .openapi("WatchKey");

/** The person's watch settings (§6.10), the same for all their watches. */
export const WatchPrefs = z
  .object({
    /** What a watch may allow: up to medium risk (default), low risk only, or nothing. */
    allow: WatchAllowLevel,
    /** Off: watches show counts and general words only (with the app lock, §10). */
    show_details: z.boolean(),
    /** The short answers under a reply (§6.2), 1 to 6, each up to 40 characters. */
    quick_replies: z.array(z.string().min(1).max(40)).min(1).max(6),
  })
  .openapi("WatchPrefs");

export const WatchPrefsUpdate = z
  .object({
    allow: WatchAllowLevel.optional(),
    show_details: z.boolean().optional(),
    /** Empty or null: back to the built-in list. */
    quick_replies: z.array(z.string().min(1).max(40)).max(6).nullable().optional(),
  })
  .openapi("WatchPrefsUpdate");

/** A code a watch shows, as the phone sees it before allowing it (§8.2). */
export const WatchCodeInfo = z
  .object({
    platform: WatchPlatform,
    name: z.string(),
    model: z.string().nullable(),
    expires_at: ts,
  })
  .openapi("WatchCodeInfo");

export const WatchCodeClaim = z.object({ org_id: Uuid }).openapi("WatchCodeClaim");

// --- signing in with a code (signed out) -----------------------------------------------------

/** A watch with no phone app at hand asks for a code (§8.2). */
export const WatchCodeRequest = z
  .object({ fingerprint: WatchFingerprint, ...WatchDevice })
  .openapi("WatchCodeRequest");

export const WatchCode = z
  .object({
    /** Eight characters from an alphabet without look-alikes; shown as "KQ7M 2XAB". */
    code: z.string().regex(/^[0-9A-Z]{8}$/),
    expires_at: ts,
    /** How often the watch tries `GET /v1/watch/me` with its key until it works. */
    poll_every_s: z.number().int().min(1),
  })
  .openapi("WatchCode");

// --- the watch's side (`Authorization: Watch <key>`) ------------------------------------------

export const WatchSelf = z
  .object({
    key_id: Uuid,
    org_id: Uuid,
    org_name: z.string().max(80),
    /** The person, for "Signed in as Oliver". */
    person: z.object({ name: z.string().max(80) }),
    prefs: WatchPrefs,
    /** Hide reply text (D-325): replies show no words in notifications and complications. */
    hide_reply_text: z.boolean(),
    /** The bot Ask goes to unless the person picks one: the first in their order. */
    ask_bot_id: Uuid.nullable(),
    /** What this server can do for a watch. */
    features: z.object({
      /** The server transcribes recordings (POST /v1/watch/ask with audio). */
      dictation: z.boolean(),
      /** Replies can be read aloud in the bot's voice (GET /v1/messages/{id}/speech). */
      speech: z.boolean(),
      /** Billing is on and the workspace is out of credits: Ask is off, answers still work. */
      out_of_credits: z.boolean(),
    }),
  })
  .openapi("WatchSelf");

/** The watch describes itself and where its pushes go. Every field is optional. */
export const WatchSelfUpdate = z
  .object({
    /** Apple's push token for the watch app (hex), or a Wear OS watch's Firebase token. */
    push_token: z.string().min(8).max(4096).nullable().optional(),
    push_kind: z.enum(["apns", "fcm"]).optional(),
    /** Apple's environment for Apple tokens. */
    sandbox: z.boolean().optional(),
    app_version: z.string().max(40).optional(),
    os_version: z.string().max(40).optional(),
    name: z.string().min(1).max(80).optional(),
  })
  .openapi("WatchSelfUpdate");

/** A card, page, file or picture in a reply, as one line (§6.1 E). */
export const WatchAttachment = z
  .object({
    kind: z.enum(["page", "image", "video", "audio", "document", "file", "card", "link"]),
    title: z.string().max(100),
  })
  .openapi("WatchAttachment");

export const WatchMessage = z
  .object({
    id: Uuid,
    role: z.enum(["user", "assistant"]),
    /** Plain text, no markdown. The latest reply up to 1,200 characters; older ones up to 300. */
    text: z.string().max(1300),
    /** The text was cut: "Continues on iPhone". */
    cut: z.boolean(),
    attachments: z.array(WatchAttachment).max(3),
    at: ts,
    /** Read aloud is offered (an assistant message with text, on a server with a voice). */
    can_speak: z.boolean(),
  })
  .openapi("WatchMessage");

export const WatchBotHeader = z
  .object({
    id: Uuid,
    name: z.string().max(80),
    avatar: Avatar,
    status: z.enum(["idle", "working", "waiting", "disabled"]),
  })
  .openapi("WatchBotHeader");

/** A bot's latest chat, to check what was said (§6.1 E), oldest first. */
export const WatchChat = z
  .object({
    bot: WatchBotHeader,
    conversation_id: Uuid.nullable(),
    messages: z.array(WatchMessage).max(12),
    /** The run that is live in this chat, if any: follow it with GET /v1/watch/runs/{id}. */
    run_id: Uuid.nullable(),
    link: z.string().max(300),
  })
  .openapi("WatchChat");

export const WatchAudio = z
  .object({
    /** The recording, base64; at most about 1 MB once decoded (a minute of AAC). */
    data: z.string().min(16).max(1_500_000),
    mime: z.enum([
      "audio/aac",
      "audio/mp4",
      "audio/m4a",
      "audio/x-m4a",
      "audio/ogg",
      "audio/webm",
      "audio/3gpp",
      "audio/wav",
    ]),
  })
  .openapi("WatchAudio");

/** Ask or reply: text, or the recording itself (transcribed and sent in one step). */
export const WatchAsk = z
  .object({
    /** Ask: which bot. Reply: the chat's bot. */
    bot_id: Uuid,
    /** Reply: the chat it continues. Absent: a new chat, as quick ask does (decision 9). */
    conversation_id: Uuid.optional(),
    text: z.string().min(1).max(4000).optional(),
    audio: WatchAudio.optional(),
    /** A BCP 47 hint for transcription ("en", "fil"). */
    language: z.string().max(20).optional(),
    /** When it was first asked, for an ask kept while offline (§6.1 C). */
    asked_at: ts.optional(),
    surface: WatchSurface.optional(),
  })
  .openapi("WatchAsk");

export const WatchAsked = z
  .object({
    conversation_id: Uuid,
    message_id: Uuid,
    run_id: Uuid.nullable(),
    /** What was sent: the text, or what was heard. */
    heard: z.string().max(4000),
  })
  .openapi("WatchAsked");

export const WatchRisk = z.enum(["low", "medium", "high"]).openapi("WatchRisk");

/**
 * A request, in everyday words, and what this watch may do with it (§6.1 B):
 * `tap` allows in one tap, `hold` needs a hold, `phone` only on the phone. Deny always works.
 */
export const WatchApproval = z
  .object({
    id: Uuid,
    run_id: Uuid,
    bot_id: Uuid,
    bot: z.string().max(80),
    bot_avatar: Avatar,
    status: z.enum(["pending", "approved", "denied", "expired"]),
    /** What it wants to do ("Send an email to Dana"). Empty when private. */
    title: z.string().max(140),
    /** Up to three short lines: who it goes to, the subject, the first line. Empty when private. */
    details: z.array(z.string().max(120)).max(3),
    risk: WatchRisk,
    payment: z.boolean(),
    can_allow: z.enum(["tap", "hold", "phone"]),
    /** Why only the phone: the risk, a payment, the person's setting, the workspace's. */
    why_phone: z.enum(["high_risk", "payment", "setting", "workspace", "not_yours"]).nullable(),
    created_at: ts,
    expires_at: ts,
    link: z.string().max(300),
  })
  .openapi("WatchApproval");

/** A run's whole state now (§6.1 D); a stream sends one of these each time it changes. */
export const WatchRun = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    bot: z.string().max(80),
    bot_avatar: Avatar,
    conversation_id: Uuid.nullable(),
    phase: z.enum(["working", "needs_ok", "take_over", "finished", "problem", "stopped"]),
    /** What it is doing in general words ("Searching the web"). */
    step: z.string().max(80),
    steps: z.number().int().min(0),
    started_at: ts,
    ended_at: ts.nullable(),
    /** The request, while it waits on one. */
    approval: WatchApproval.nullable(),
    /** The reply, once it finished. */
    reply: WatchMessage.nullable(),
    link: z.string().max(300),
  })
  .openapi("WatchRun");

/** "Open on iPhone" / "Open on phone": the phone gets a notification that opens [link]. */
export const WatchHandoff = z
  .object({
    /** An app route ("/bots/<id>/chat?c=…", "/approvals/<id>"). */
    link: z
      .string()
      .min(1)
      .max(300)
      // An app route: "/x", never "//host" or "/\host" (another site).
      .regex(/^\/(?![/\\])/),
    /** What the notification says ("Continue with Milo"). */
    title: z.string().min(1).max(100),
  })
  .openapi("WatchHandoff");

export type WatchRun = z.infer<typeof WatchRun>;
export type WatchApproval = z.infer<typeof WatchApproval>;
export type WatchMessage = z.infer<typeof WatchMessage>;
export type WatchChat = z.infer<typeof WatchChat>;
export type WatchSelf = z.infer<typeof WatchSelf>;
export type WatchPrefs = z.infer<typeof WatchPrefs>;
