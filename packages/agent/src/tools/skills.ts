/**
 * Bots writing skills (SPEC: Post-v1 roadmap → Skills library; D-104). `skills.create` saves the
 * method used in a conversation as a skill for this bot; `skills.update` changes one of its own
 * skills. Both are medium risk: the approval card shows the text or the diff.
 */
import type { Database } from "@casama/db";
import { lineDiff, SKILL_NAME } from "@casama/domain";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { ToolError, type ToolRegistry } from "./registry.ts";

const NAME = z
  .string()
  .regex(SKILL_NAME, "lowercase letters, digits, - or _")
  .describe("e.g. weekly-invoice-check");

export function registerSkillTools(registry: ToolRegistry, deps: { db: Database }) {
  const { db } = deps;
  const own = async (orgId: string, botId: string, name: string) => {
    const [s] = await db.execute<{
      id: string;
      description: string;
      body_md: string;
      bot_id: string | null;
    }>(sql`
      select id, description, body_md, bot_id from public.skills
      where org_id = ${orgId}::uuid and name = ${name} and (bot_id is null or bot_id = ${botId}::uuid)
      order by bot_id nulls last limit 1`);
    return s;
  };

  registry.register({
    name: "skills.create",
    description:
      'Save a method as a skill for yourself (for example when the user says "save that as a skill"): a name, a one-line description of when to use it, and step-by-step instructions in Markdown. It joins your skills index.',
    risk: "medium",
    keepsPlaceholders: true,
    schema: z.object({
      name: NAME,
      description: z.string().min(1).max(300),
      instructions: z.string().min(1).max(50_000),
    }),
    async approvalDetails(args) {
      return {
        preview:
          `---\nname: ${args.name}\ndescription: ${args.description}\n---\n\n${args.instructions}`.slice(
            0,
            20_000,
          ),
      };
    },
    async execute(args, ctx) {
      if (await own(ctx.orgId, ctx.botId, args.name))
        throw new ToolError(
          "skill_exists",
          `A skill named ${args.name} already exists; use skills.update to change it.`,
        );
      await db.execute(sql`
        insert into public.skills (org_id, bot_id, name, description, body_md, source, updated_by_bot)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${args.name}, ${args.description}, ${args.instructions}, 'bot', ${ctx.botId}::uuid)`);
      return {
        content: `Saved the skill ${args.name}. Load it with skills.load next time.`,
        preview: `saved ${args.name}`,
      };
    },
  });

  registry.register({
    name: "skills.update",
    description:
      "Change one of your own skills: its description and/or instructions. Workspace-wide skills are changed by admins in the app.",
    risk: "medium",
    keepsPlaceholders: true,
    schema: z.object({
      name: NAME,
      description: z.string().min(1).max(300).optional(),
      instructions: z.string().min(1).max(50_000).optional(),
    }),
    async approvalDetails(args, ctx) {
      const s = await own(ctx.orgId, ctx.botId, args.name);
      if (!s) return {};
      const before = `${s.description}\n\n${s.body_md}`;
      const after = `${args.description ?? s.description}\n\n${args.instructions ?? s.body_md}`;
      return { diff: lineDiff(before, after).join("\n").slice(0, 20_000) };
    },
    async execute(args, ctx) {
      const s = await own(ctx.orgId, ctx.botId, args.name);
      if (!s) throw new ToolError("skill_not_found", `No skill named ${args.name}.`);
      if (s.bot_id !== ctx.botId)
        throw new ToolError(
          "workspace_skill",
          `${args.name} is a workspace skill; ask an admin to change it in the app.`,
        );
      if (!args.description && !args.instructions)
        throw new ToolError("nothing_to_change", "Give a new description or instructions.");
      await db.execute(sql`
        update public.skills set description = ${args.description ?? s.description}, body_md = ${args.instructions ?? s.body_md},
          updated_at = now(), updated_by_bot = ${ctx.botId}::uuid
        where id = ${s.id}::uuid`);
      return { content: `Updated the skill ${args.name}.`, preview: `updated ${args.name}` };
    },
  });
}
