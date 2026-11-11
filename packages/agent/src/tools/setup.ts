/**
 * Setup interview (SPEC: Post-v1 roadmap → Setup and starter bots; D-105). In a setup
 * conversation the bot asks a few questions as cards, then calls `setup.apply` with everything it
 * proposes; the approval card shows it all and nothing changes until the person approves.
 */
import { contentKeys, type Database } from "@kasama/db";
import { isValidCron, isValidTimezone, nextRunAt } from "@kasama/domain";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { personForRun } from "../acting.ts";
import { ToolError, type ToolRegistry } from "./registry.ts";

export const SETUP_GUIDE = [
  "You are being set up by the person you'll work for. This conversation is your setup interview.",
  "1. Ask three to six short questions with ui.show, one card at a time (a card can hold one or two questions; choices where they fit, a text field otherwise), and wait for each answer before the next card. Cover: the work you'll do and what good looks like; how they like things written (length, tone, format); which tools and accounts you'll need; and any regular schedule (daily or weekly jobs).",
  "2. Then call setup.apply once with: your new standing instructions (second person, specific, a short bullet list), up to five memories worth keeping (facts about them and their work), routines for any schedule they gave, and connections they should add (service names only).",
  "3. Don't make changes any other way during setup. If they want to stop, say they can rerun setup from your settings.",
].join("\n");

const Routine = z.object({
  name: z.string().min(1).max(120),
  instructions: z.string().min(1).max(5000),
  schedule_cron: z.string().max(100).describe("5-field cron in the person's timezone"),
});

export function registerSetupTools(registry: ToolRegistry, deps: { db: Database }) {
  const { db } = deps;
  registry.register({
    name: "setup.apply",
    description:
      "At the end of a setup interview: propose your standing instructions, a few memories, routines and connections to add. The person approves it all in one card before anything changes.",
    risk: "high",
    schema: z.object({
      instructions: z.string().min(20).max(20_000),
      memories: z.array(z.string().min(1).max(500)).max(5).default([]),
      routines: z.array(Routine).max(5).default([]),
      connections: z
        .array(z.string().min(1).max(60))
        .max(10)
        .default([])
        .describe("Services the person should connect, e.g. Gmail, Google Calendar"),
    }),
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
        await tx.execute(sql`select set_config('kasama.actor_bot', ${ctx.botId}, true)`);
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
        ? ` Ask the person to connect ${args.connections.join(", ")} in Settings → Integrations; you can't add accounts yourself.`
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
