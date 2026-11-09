import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";
import { z } from "zod";
import type { MemoryService } from "../memory.ts";
import { ToolError, ToolRegistry } from "./registry.ts";

/** Phase 1 tools: memory and skills. Computer, browser and integration tools register in later phases. */
export function builtinTools(deps: {
  db: Database;
  memory: (orgId: string) => Promise<MemoryService>;
}) {
  const registry = new ToolRegistry();

  registry.register({
    name: "memory.search",
    description:
      "Search your long-term memory about the user and past work. Returns the most relevant memories.",
    risk: "low",
    schema: z.object({
      query: z.string().min(1).max(500),
      limit: z.number().int().min(1).max(20).optional(),
    }),
    async execute(args, ctx) {
      const memory = await deps.memory(ctx.orgId);
      const rows = await memory.recall(ctx.botId, args.query, args.limit ?? 8);
      if (!rows.length) return { content: "No matching memories.", preview: "0 memories" };
      return {
        content: rows
          .map((m) => `- [${m.id}] (${m.kind}${m.pinned ? ", pinned" : ""}) ${m.content}`)
          .join("\n"),
        preview: `${rows.length} memories`,
      };
    },
  });

  registry.register({
    name: "memory.write",
    description:
      "Save a lasting fact or preference to long-term memory. Near-duplicates are updated instead of added. Use one standalone sentence.",
    risk: "low",
    schema: z.object({
      content: z.string().min(1).max(1000),
      kind: z.enum(["fact", "preference"]).optional(),
      importance: z.number().min(0).max(1).optional(),
    }),
    async execute(args, ctx) {
      const memory = await deps.memory(ctx.orgId);
      const kind = args.kind ?? "fact";
      const { id, created } = await memory.write({
        orgId: ctx.orgId,
        botId: ctx.botId,
        kind,
        content: args.content,
        importance: args.importance,
        sourceRunId: ctx.runId,
      });
      await ctx.emit("memory.written", { memory_id: id, kind });
      return {
        content: created ? `Saved memory ${id}.` : `Updated existing memory ${id}.`,
        preview: created ? "saved" : "updated",
      };
    },
  });

  registry.register({
    name: "skills.load",
    description: "Load the full instructions of one skill from the skills index by name.",
    risk: "low",
    schema: z.object({ name: z.string().min(1).max(63) }),
    async execute(args, ctx) {
      const [skill] = await deps.db.execute<{ id: string; name: string; body_md: string }>(sql`
        select id, name, body_md from public.skills
        where org_id = ${ctx.orgId}::uuid and name = ${args.name} and enabled
          and (bot_id is null or bot_id = ${ctx.botId}::uuid)
        order by bot_id nulls last limit 1`);
      if (!skill) throw new ToolError("skill_not_found", `No enabled skill named "${args.name}".`);
      await ctx.emit("skill.loaded", { skill_id: skill.id, name: skill.name });
      return { content: skill.body_md, preview: `loaded ${skill.name}` };
    },
  });

  return registry;
}
