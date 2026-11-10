import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

export const ReplayParamInfo = z
  .object({ name: z.string(), description: z.string().optional(), default: z.string().optional(), secret: z.boolean().optional() })
  .openapi("ReplayParamInfo");

export const Replay = z
  .object({
    id: Uuid,
    bot_id: Uuid,
    name: z.string(),
    description: z.string(),
    params: z.array(ReplayParamInfo),
    steps: z.array(z.object({ tool: z.string(), note: z.string().optional() })),
    source: z.enum(["bot", "teach", "manual"]),
    runs: z.number().int(),
    failures: z.number().int(),
    last_failure: z.string().nullable(),
    last_run_at: ts.nullable(),
    updated_at: ts,
  })
  .openapi("Replay");

export const RunReplayRequest = z
  .object({ params: z.record(z.string(), z.string().max(2000)).optional() })
  .openapi("RunReplayRequest");
export const RunReplayResponse = z.object({ conversation_id: Uuid, run_id: Uuid }).openapi("RunReplayResponse");
export const ReplayFromTeachRequest = z
  .object({ name: z.string().regex(/^[a-z0-9][a-z0-9_-]{0,62}$/), description: z.string().max(300).optional() })
  .openapi("ReplayFromTeachRequest");
