/**
 * Casama Link's push relay, cloud side (D-296):
 *
 *   POST /link/v1/push   { tokens, message }, { tokens, call }, { tokens, voip }, { tokens, live }
 *                        or { tokens, widget }
 *
 * A linked self-hosted server hands over a notification and the device tokens it is for, and this
 * sends it with Casama's Firebase key, the only key that can address the store apps. It answers
 * which tokens are dead so the server forgets them (D-271). A call rings Android phones through
 * Firebase (`call`) and iPhones through Apple's call pushes (`voip`), with Casama's Apple key. A
 * followed run's state (`live`, D-324) updates iPhone Live Activities and Android's live
 * notification; with private notifications on, the server sends it without the words. A widget
 * refresh (`widget`, D-405) carries only the tokens: Apple's WidgetKit pushes with Casama's Apple
 * key, Android's data message with Firebase. An alert to an Apple Watch's own token (`watch`,
 * D-410) goes to Apple with Casama's key; a Wear OS watch's token is an ordinary data `message`.
 *
 * A server can only name tokens of devices that signed in to it, since that is the only place a
 * token is handed over. Nothing is stored here: not the tokens, not the text. Each key is held to
 * a number of pushes an hour, so a server gone wrong can't spend the project's quota.
 */
import type { PushSender, VoipSender, WatchAlertSender, WidgetPushSender } from "@casama/agent";
import type { Database } from "@casama/db";
import type { Hono } from "hono";
import { z } from "zod";
import { linkCaller, linkSuspended } from "./keys.ts";

const text = (max: number) => z.string().transform((s) => s.slice(0, max));
const Data = z.record(z.string().max(64), z.string().max(1024));

const Message = z.object({
  title: text(200),
  body: text(1000),
  link: z.string().max(500).optional(),
  data: Data.optional(),
  category: z.string().max(40).optional(),
  dataOnly: z.boolean().optional(),
  // D-312 and D-325; optional, so servers from before them still pass.
  tag: z.string().max(100).optional(),
  channel: z.string().max(40).optional(),
  priority: z.enum(["high", "normal"]).optional(),
  threadId: z.string().max(100).optional(),
  badge: z.number().int().min(0).max(9999).optional(),
  interruption: z.literal("time-sensitive").optional(),
});

const Body = z
  .object({
    tokens: z.array(z.string().min(8).max(4096)).min(1).max(500),
    message: Message.optional(),
    // An alert to Apple Watches' own tokens (D-410); `tokens` are then the targets' tokens.
    watch: z
      .object({
        targets: z
          .array(z.object({ token: z.string().min(8).max(4096), sandbox: z.boolean() }))
          .min(1)
          .max(50),
        message: Message,
      })
      .optional(),
    call: z.object({ data: Data, ttl_seconds: z.number().int().min(1).max(120) }).optional(),
    // An iPhone's call ring; `tokens` are then the phones' call-push tokens.
    voip: z
      .object({
        call: z.object({
          call_id: z.string().max(64),
          bot_id: z.string().max(64),
          bot_name: text(200),
          reason: text(500),
          conversation_id: z.string().max(64).nullable(),
        }),
      })
      .optional(),
    // A followed run's state (D-324); `tokens` are then the targets' tokens.
    live: z
      .object({
        targets: z
          .array(
            z.object({
              token: z.string().min(8).max(4096),
              platform: z.enum(["ios", "android"]),
              fcm_token: z.string().min(8).max(4096).nullable(),
            }),
          )
          .min(1)
          .max(50),
        update: z.object({
          run_id: z.string().max(64),
          bot_id: z.string().max(64),
          bot_name: text(200),
          // Older servers send none.
          bot_avatar: z.string().max(200).nullable().optional(),
          started_at: z.number(),
          link: z.string().max(500),
          state: z.object({
            phase: z.enum(["working", "needsOk", "takeOver", "finished", "problem"]),
            step: text(80),
            detail: text(80).nullable(),
            steps: z.number().int().min(0).max(100_000),
            approval_id: z.string().max(64).nullable(),
            risk: z.string().max(16).nullable(),
            updated_at: z.number(),
            ended_at: z.number().nullable(),
          }),
          event: z.enum(["update", "end", "start"]),
          priority: z.union([z.literal(5), z.literal(10)]),
          stale_at: z.number(),
          dismiss_at: z.number().nullable(),
        }),
      })
      .optional(),
    // Widget refresh pushes (D-405): tokens only, nothing to read; `tokens` are the targets'.
    widget: z
      .object({
        targets: z
          .array(
            z.object({
              token: z.string().min(8).max(4096),
              kind: z.enum(["apns_widgets", "fcm"]),
              sandbox: z.boolean(),
            }),
          )
          .min(1)
          .max(50),
        urgent: z.boolean().optional(),
      })
      .optional(),
  })
  .refine(
    (b) => [b.message, b.call, b.voip, b.live, b.widget, b.watch].filter(Boolean).length === 1,
    "Send a message or a call",
  )
  .refine(
    (b) =>
      !b.watch ||
      (b.watch.targets.length === b.tokens.length &&
        b.watch.targets.every((t, i) => t.token === b.tokens[i])),
    "The watch targets don't match the tokens",
  )
  .refine(
    (b) =>
      !b.live ||
      (b.live.targets.length === b.tokens.length &&
        b.live.targets.every((t, i) => t.token === b.tokens[i])),
    "The live targets don't match the tokens",
  )
  .refine(
    (b) =>
      !b.widget ||
      (b.widget.targets.length === b.tokens.length &&
        b.widget.targets.every((t, i) => t.token === b.tokens[i])),
    "The widget targets don't match the tokens",
  );

export function registerPushRelay(
  app: Hono,
  o: {
    push: PushSender;
    /** To refuse a suspended workspace or server. */
    db?: Database;
    /** Apple's call pushes, which ring iPhones; unset: this cloud rings none. */
    voip?: VoipSender;
    /** Widget refresh pushes (D-405); unset: this cloud refreshes no widgets. */
    widgets?: WidgetPushSender;
    /** Alerts to Apple Watches' own tokens (D-410); unset: this cloud reaches no watches. */
    watch?: WatchAlertSender;
    perHour?: number;
    now?: () => number;
  },
) {
  const perHour = o.perHour ?? 2000;
  const now = o.now ?? Date.now;
  const windows = new Map<string, { start: number; count: number }>();

  app.post("/link/v1/push", async (c) => {
    const k = linkCaller(c);
    if (!k.scopes.includes("push"))
      return c.json(
        { code: "push_unavailable", message: "This key can't send notifications" },
        403,
      );
    if (o.db && (await linkSuspended(o.db, k)))
      return c.json(
        { code: "suspended", message: "Notifications are turned off for this server" },
        403,
      );
    const parsed = Body.safeParse(await c.req.json().catch(() => null));
    if (!parsed.success)
      return c.json({ code: "bad_request", message: "The request isn't valid" }, 400);
    const { tokens, message, call, voip, live, widget, watch } = parsed.data;
    if (watch && !o.watch)
      return c.json({ code: "watch_unavailable", message: "This cloud reaches no watches" }, 404);
    // Said before anything is counted, so a server stops asking a cloud that rings no iPhones.
    if (voip && !o.voip)
      return c.json({ code: "voip_unavailable", message: "This cloud rings no iPhones" }, 404);
    if (widget && !o.widgets)
      return c.json(
        { code: "widget_unavailable", message: "This cloud refreshes no widgets" },
        404,
      );
    // The data a notification carries is small; anything bigger isn't one.
    const size = JSON.stringify(message?.data ?? watch?.message.data ?? call?.data ?? {}).length;
    if (size > 3500)
      return c.json({ code: "bad_request", message: "The notification's data is too large" }, 400);

    const t = now();
    let w = windows.get(k.keyId);
    if (!w || t - w.start >= 3_600_000) {
      w = { start: t, count: 0 };
      windows.set(k.keyId, w);
    }
    if (w.count + tokens.length > perHour) {
      const retry = Math.max(1, Math.ceil((w.start + 3_600_000 - t) / 1000));
      c.header("retry-after", String(retry));
      return c.json({ code: "rate_limited", message: "Too many notifications this hour" }, 429);
    }
    w.count += tokens.length;

    const result = watch
      ? await (o.watch as WatchAlertSender).sendWatch(watch.targets, watch.message)
      : widget
        ? await (o.widgets as WidgetPushSender).sendWidgets(widget.targets, {
            urgent: widget.urgent === true,
          })
        : live
          ? await (o.push.sendLive?.(live.targets, live.update) ??
              Promise.resolve({ invalidTokens: [] }))
          : voip
            ? await (o.voip as VoipSender).send(tokens, voip.call)
            : call
              ? await (o.push.sendCall?.(tokens, call.data, call.ttl_seconds) ??
                  Promise.resolve({ invalidTokens: [] }))
              : await o.push.send(tokens, message as NonNullable<typeof message>);
    return c.json({ sent: tokens.length, invalid_tokens: result.invalidTokens });
  });
}
