import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

export const Watcher = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    name: z.string(),
    kind: z.enum(["page_change", "reply", "query", "time"]),
    target: z.record(z.string(), z.unknown()),
    condition_md: z.string(),
    status: z.enum(["active", "paused", "done", "expired"]),
    check_every_seconds: z.number().int(),
    fired_count: z.number().int(),
    last_checked_at: ts.nullable(),
    last_error: z.string().nullable(),
    expires_at: ts.nullable(),
    conversation_id: Uuid.nullable(),
    created_at: ts,
  })
  .openapi("Watcher");

export const UpdateWatcherRequest = z
  .object({ status: z.enum(["active", "paused"]) })
  .openapi("UpdateWatcherRequest");
