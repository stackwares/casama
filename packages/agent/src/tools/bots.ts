/**
 * Bots that manage bots (SPEC: Post-v1 roadmap → Bots that manage bots; D-100): a bot can list,
 * create, change and archive bots, organize the sidebar and change its own settings. It can never
 * give any bot (itself included) more autonomy or budget than it has.
 */
import type { Database } from "@kasama/db";
import { templateById } from "@kasama/domain";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "../acting.ts";
import { type ToolContext, ToolError, type ToolRegistry } from "./registry.ts";

const RANK = { ask_always: 0, ask_risky: 1, autonomous: 2 } as const;
type Autonomy = keyof typeof RANK;
const AUTONOMY = z.enum(["ask_always", "ask_risky", "autonomous"]);
const BUDGET = z.object({
  per_run_usd: z.number().min(0).max(100).optional(),
  daily_usd: z.number().min(0).max(1000).optional(),
});

type BotRow = {
  id: string;
  org_id: string;
  name: string;
  persona_md: string;
  autonomy: Autonomy;
  budget: { per_run_usd?: number; daily_usd?: number } | null;
  model_policy: Record<string, unknown>;
  archived_at: Date | null;
};

export function registerBotTools(registry: ToolRegistry, deps: { db: Database }) {
  const { db } = deps;

  const load = async (orgId: string, ref: string) => {
    const [b] = await db.execute<BotRow>(sql`
      select id, org_id, name, persona_md, autonomy, budget, model_policy, archived_at from public.bots
      where org_id = ${orgId}::uuid and (id::text = ${ref} or lower(name) = lower(${ref})) limit 1`);
    return b;
  };
  const self = async (ctx: ToolContext) => {
    const [b] = await db.execute<BotRow>(sql`
      select id, org_id, name, persona_md, autonomy, budget, model_policy, archived_at from public.bots where id = ${ctx.botId}::uuid`);
    if (!b) throw new ToolError("bot_not_found", "This bot no longer exists.");
    return b;
  };
  /** Autonomy and budget may never exceed the acting bot's. */
  const cap = (me: BotRow, autonomy?: Autonomy, budget?: z.infer<typeof BUDGET>) => {
    if (autonomy && RANK[autonomy] > RANK[me.autonomy])
      throw new ToolError(
        "over_limit",
        `You can't give a bot more autonomy than you have (${me.autonomy}).`,
      );
    for (const k of ["per_run_usd", "daily_usd"] as const) {
      const mine = me.budget?.[k];
      const want = budget?.[k];
      if (want !== undefined && mine !== undefined && mine !== null && want > mine)
        throw new ToolError(
          "over_limit",
          `You can't give a bot a larger ${k} than yours ($${mine}).`,
        );
    }
  };
  /** Changes made in this transaction are recorded as made by this bot (bot_revisions). */
  const asBot = <T>(botId: string, fn: (tx: Database) => Promise<T>) =>
    db.transaction(async (tx) => {
      await tx.execute(sql`select set_config('kasama.actor_bot', ${botId}, true)`);
      return fn(tx as unknown as Database);
    });
  const audit = (ctx: ToolContext, action: string, target: string, meta: object) =>
    db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${ctx.orgId}::uuid, 'bot', ${ctx.botId}::uuid, ${action}, 'bot', ${target}::uuid, ${JSON.stringify(meta)}::jsonb)`);

  registry.register({
    name: "bots.list",
    readOnly: true,
    description: "List the bots in your workspace with their autonomy, model and folder.",
    risk: "low",
    schema: z.object({}),
    async execute(_args, ctx) {
      const rows = await db.execute<{
        name: string;
        autonomy: string;
        model: string | null;
        folder: string | null;
        id: string;
      }>(sql`
        select b.id, b.name, b.autonomy, b.model_policy #>> '{primary,model}' as model, f.name as folder
        from public.bots b left join public.bot_folders f on f.id = b.folder_id
        where b.org_id = ${ctx.orgId}::uuid and b.archived_at is null order by f.sort_key nulls first, b.sort_key, b.name`);
      return {
        content:
          rows
            .map(
              (r) =>
                `- ${r.name}${r.id === ctx.botId ? " (you)" : ""}: ${r.autonomy}, ${r.model ?? "no model"}${r.folder ? `, in ${r.folder}` : ""}`,
            )
            .join("\n") || "No bots.",
        preview: `${rows.length} bots`,
      };
    },
  });

  registry.register({
    name: "bots.create",
    description:
      "Create a new bot in your workspace: its name and standing instructions, optionally a persona template, autonomy, model, budget, and your tools. It can't have more autonomy or budget than you. Give it routines with routines.create (bot: its name).",
    risk: "high",
    schema: z.object({
      name: z.string().min(1).max(80),
      instructions: z.string().max(20_000).optional(),
      template: z.string().max(60).optional().describe("A persona template id to start from"),
      autonomy: AUTONOMY.optional(),
      model: z
        .string()
        .max(200)
        .optional()
        .describe("A model id on your own model key (default: your model)"),
      budget: BUDGET.optional(),
      copy_tools: z.boolean().optional().describe("Give it the same integrations you have"),
    }),
    async execute(args, ctx) {
      const me = await self(ctx);
      const tpl = args.template ? templateById(args.template) : undefined;
      if (args.template && !tpl)
        throw new ToolError("template_not_found", `No template ${args.template}.`);
      const autonomy = (args.autonomy ??
        (tpl?.autonomy as Autonomy | undefined) ??
        "ask_risky") as Autonomy;
      cap(me, autonomy, args.budget);
      if (await load(ctx.orgId, args.name))
        throw new ToolError("name_taken", `There is already a bot named ${args.name}.`);
      const [{ n, max } = { n: 0, max: null }] = await db.execute<{
        n: number;
        max: string | null;
      }>(sql`
        select (select count(*)::int from public.bots where org_id = ${ctx.orgId}::uuid and archived_at is null) as n,
               (select limits->>'max_bots' from public.entitlements where org_id = ${ctx.orgId}::uuid order by created_at desc limit 1) as max`);
      if (max !== null && Number(max) > 0 && n >= Number(max))
        throw new ToolError("bot_limit", `This workspace's plan allows ${max} bots.`);
      const policy = structuredClone(me.model_policy ?? {}) as { primary?: { model?: string } };
      if (args.model && policy.primary) policy.primary.model = args.model;
      const budget = {
        per_run_usd: args.budget?.per_run_usd ?? Math.min(1, me.budget?.per_run_usd ?? 1),
        daily_usd: args.budget?.daily_usd ?? Math.min(10, me.budget?.daily_usd ?? 10),
      };
      const owner = await actingUserOf(db, ctx.runId);
      const [created] = await db.execute<{ id: string }>(sql`
        insert into public.bots (org_id, created_by, name, persona_md, model_policy, autonomy, budget)
        values (${ctx.orgId}::uuid, ${owner}::uuid, ${args.name}, ${args.instructions ?? tpl?.persona ?? ""},
                ${JSON.stringify(policy)}::jsonb, ${autonomy}, ${JSON.stringify(budget)}::jsonb)
        returning id`);
      if (!created) throw new Error("bot insert returned nothing");
      if (args.copy_tools)
        await db.execute(sql`
          insert into public.bot_integrations (org_id, bot_id, integration_id, tool_allowlist)
          select org_id, ${created.id}::uuid, integration_id, tool_allowlist from public.bot_integrations
          where bot_id = ${ctx.botId}::uuid on conflict do nothing`);
      await audit(ctx, "bot.created_by_bot", created.id, { name: args.name, autonomy });
      return {
        content: `Created the bot ${args.name} (${autonomy}).`,
        preview: `created ${args.name}`,
      };
    },
  });

  registry.register({
    name: "bots.update",
    description:
      "Change a bot's settings (name, standing instructions, autonomy, model, budget). Leave `bot` out to change your own. Never more autonomy or budget than you have.",
    risk: "medium",
    riskFor: (a: { autonomy?: string; budget?: unknown }) =>
      a.autonomy || a.budget ? "high" : "medium",
    schema: z.object({
      bot: z.string().max(100).optional(),
      name: z.string().min(1).max(80).optional(),
      instructions: z.string().max(20_000).optional(),
      autonomy: AUTONOMY.optional(),
      model: z.string().max(200).optional(),
      budget: BUDGET.optional(),
    }),
    async execute(args, ctx) {
      const me = await self(ctx);
      const target = args.bot ? await load(ctx.orgId, args.bot) : me;
      if (!target || target.archived_at)
        throw new ToolError("bot_not_found", `No bot named ${args.bot}.`);
      // Raising your own autonomy is the same as giving yourself more than you have.
      cap(me, args.autonomy, args.budget);
      const policy = structuredClone(target.model_policy ?? {}) as { primary?: { model?: string } };
      if (args.model) {
        if (!policy.primary)
          throw new ToolError("no_model", `${target.name} has no model key to switch models on.`);
        policy.primary.model = args.model;
      }
      const budget = args.budget ? { ...(target.budget ?? {}), ...args.budget } : target.budget;
      await asBot(ctx.botId, (tx) =>
        tx.execute(sql`
          update public.bots set name = ${args.name ?? target.name}, persona_md = ${args.instructions ?? target.persona_md},
            autonomy = ${args.autonomy ?? target.autonomy}, model_policy = ${JSON.stringify(policy)}::jsonb,
            budget = ${JSON.stringify(budget ?? {})}::jsonb
          where id = ${target.id}::uuid`),
      );
      const changed = Object.keys(args).filter((k) => k !== "bot");
      await audit(ctx, "bot.updated_by_bot", target.id, { fields: changed });
      return {
        content: `Updated ${target.id === ctx.botId ? "your settings" : target.name}: ${changed.join(", ") || "nothing"}. The previous settings are in the bot's history.`,
        preview: `${target.name}: ${changed.join(", ")}`,
      };
    },
  });

  registry.register({
    name: "bots.archive",
    description:
      "Archive a bot: it leaves the sidebar and stops running; its chats and history are kept.",
    risk: "high",
    schema: z.object({ bot: z.string().min(1).max(100) }),
    async execute(args, ctx) {
      const target = await load(ctx.orgId, args.bot);
      if (!target || target.archived_at)
        throw new ToolError("bot_not_found", `No bot named ${args.bot}.`);
      if (target.id === ctx.botId)
        throw new ToolError("not_yourself", "You can't archive yourself.");
      await asBot(ctx.botId, (tx) =>
        tx.execute(sql`update public.bots set archived_at = now() where id = ${target.id}::uuid`),
      );
      await audit(ctx, "bot.archived_by_bot", target.id, {});
      return { content: `Archived ${target.name}.`, preview: `archived ${target.name}` };
    },
  });

  registry.register({
    name: "sidebar.organize",
    description:
      "Organize the bots in the sidebar into folders, in order. Bots you don't mention keep their place; an empty folder list leaves folders alone.",
    risk: "low",
    // Only the bot's own state inside Kasama: never asks (D-155).
    selfOnly: true,
    schema: z.object({
      folders: z
        .array(
          z.object({
            name: z.string().min(1).max(60),
            bots: z.array(z.string().max(100)).max(100),
          }),
        )
        .max(30),
      unfiled: z
        .array(z.string().max(100))
        .max(100)
        .optional()
        .describe("Bots to take out of folders, in order"),
    }),
    async execute(args, ctx) {
      let moved = 0;
      for (const [fi, f] of args.folders.entries()) {
        const [folder] = await db.execute<{ id: string }>(sql`
          insert into public.bot_folders (org_id, name, sort_key) values (${ctx.orgId}::uuid, ${f.name}, ${fi})
          on conflict (org_id, name) do update set sort_key = excluded.sort_key returning id`);
        for (const [bi, ref] of f.bots.entries()) {
          const b = await load(ctx.orgId, ref);
          if (!b) continue;
          await db.execute(
            sql`update public.bots set folder_id = ${folder?.id}::uuid, sort_key = ${bi} where id = ${b.id}::uuid`,
          );
          moved++;
        }
      }
      for (const [bi, ref] of (args.unfiled ?? []).entries()) {
        const b = await load(ctx.orgId, ref);
        if (!b) continue;
        await db.execute(
          sql`update public.bots set folder_id = null, sort_key = ${bi} where id = ${b.id}::uuid`,
        );
        moved++;
      }
      await db.execute(sql`
        delete from public.bot_folders f where f.org_id = ${ctx.orgId}::uuid
          and not exists (select 1 from public.bots b where b.folder_id = f.id)`);
      return {
        content: `Organized the sidebar (${moved} bots placed).`,
        preview: `${args.folders.length} folders`,
      };
    },
  });
}
