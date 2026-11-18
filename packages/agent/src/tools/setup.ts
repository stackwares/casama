/**
 * Setup interview (SPEC: Post-v1 roadmap → Setup and starter bots; D-105). In a setup
 * conversation the bot asks a few questions as cards, then calls `setup.apply` with everything it
 * proposes; the approval card shows it all and nothing changes until the person approves.
 */
import { contentKeys, type Database } from "@casama/db";
import { isValidCron, isValidTimezone, nextRunAt } from "@casama/domain";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { personForRun } from "../acting.ts";
import { BUILT_IN_PROMPTS, promptText } from "../prompts.ts";
import { leanSchema, ToolError, type ToolRegistry } from "./registry.ts";

/** The setup interview's guide: from the gallery when it has a good one (D-374), else built in. */
export const SETUP_GUIDE = BUILT_IN_PROMPTS["setup.guide"];
export const setupGuide = () => promptText("setup.guide");

const Routine = z.object({
  name: z.string().min(1).max(120),
  instructions: z.string().min(1).max(5000),
  schedule_cron: z.string().max(100).describe("5 fields, in the person's timezone"),
});

const SetupArgs = z.object({
  instructions: z.string().min(20).max(20_000),
  memories: z.array(z.string().min(1).max(500)).max(5).default([]),
  routines: z.array(Routine).max(5).default([]),
  connections: z
    .array(z.string().min(1).max(60))
    .max(10)
    .default([])
    .describe("Services to connect, e.g. Gmail"),
});

export function registerSetupTools(registry: ToolRegistry, deps: { db: Database }) {
  const { db } = deps;
  registry.register({
    name: "setup.apply",
    description:
      "End a setup interview: propose your standing instructions, memories to keep, routines and services to connect. The person approves it all in one card before anything changes.",
    risk: "high",
    schema: SetupArgs,
    // Sent with every model call (a core tool), so without the string length limits.
    jsonSchema: leanSchema(SetupArgs),
    async execute(args, ctx) {
      for (const r of args.routines)
        if (!isValidCron(r.schedule_cron))
          throw new ToolError(
            "invalid_cron",
            `Routine "${r.name}" needs a 5-field cron like '0 8 * * 1-5'.`,
          );
      const person = await personForRun(db, ctx.runId);
      const owner = { user_id: person.userId, timezone: person.timezone };
      const tz = owner?.timezone && isValidTimezone(owner.timezone) ? owner.timezone : "UTC";
      await db.transaction(async (tx) => {
        await tx.execute(sql`select set_config('casama.actor_bot', ${ctx.botId}, true)`);
        await tx.execute(
          sql`update public.bots set persona_md = ${args.instructions}, setup_status = 'done' where id = ${ctx.botId}::uuid`,
        );
        for (const m of args.memories)
          await tx.execute(sql`
            insert into public.memories (org_id, bot_id, kind, content, importance, source_run_id)
            values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, 'preference', ${contentKeys.seal(ctx.orgId, m)}, 0.8, ${ctx.runId}::uuid)`);
        for (const r of args.routines)
          await tx.execute(sql`
            insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, trigger, notify, next_run_at)
            values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${owner?.user_id ?? null}::uuid, ${r.name}, ${r.instructions},
                    ${r.schedule_cron}, ${tz}, '{"type":"schedule"}'::jsonb, true, ${nextRunAt(r.schedule_cron, tz).toISOString()}::timestamptz)`);
      });
      const parts = [
        "Setup is done: your new instructions are saved",
        args.memories.length ? `${args.memories.length} memories kept` : null,
        args.routines.length ? `${args.routines.length} routines scheduled (${tz})` : null,
      ].filter(Boolean);
      const connect = args.connections.length
        ? ` Now offer ${args.connections.join(", ")} with connections.offer so the person can sign in with one tap; you can't sign in for them.`
        : "";
      return {
        content: `${parts.join(", ")}. They take effect from the next message.${connect}`,
        preview: args.connections.length
          ? `setup applied; connect ${args.connections.join(", ")}`
          : "setup applied",
      };
    },
  });
}
