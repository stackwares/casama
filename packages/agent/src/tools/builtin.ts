import type { Database } from "@casama/db";
import { collectExec } from "@casama/sandbox";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { savePersonFact } from "../about-you.ts";
import { mirrorReactionToChannel } from "../channels/service.ts";
import type { MemoryStore } from "../memory-store.ts";
import { ReactionError, setBotReaction } from "../reactions.ts";
import { shq } from "./computer.ts";
import { ToolError, ToolRegistry } from "./registry.ts";
import { registerUiTools } from "./ui.ts";

/** Phase 1 tools: memory and skills. Computer, browser and integration tools register in later phases. */
export function builtinTools(deps: {
  db: Database;
  memory: (orgId: string) => Promise<MemoryStore>;
  /** For a bot's reaction to reach the chat app a conversation came from (D-331). */
  fetch?: typeof fetch;
}) {
  const registry = new ToolRegistry();

  registry.register({
    name: "memory.search",
    // Outside content (audit 2026-11): later risky calls ask first.
    untrustedOutput: true,
    readOnly: true,
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
    name: "usage.report",
    readOnly: true,
    description:
      "The workspace's usage and estimated cost: totals, by bot, by model, by day, and everything metered (tokens, computer time, live view, read aloud). Use it to answer questions about spending or usage.",
    risk: "low",
    schema: z.object({
      period: z.enum(["day", "week", "month", "year"]).optional().describe("Defaults to month"),
    }),
    async execute(args, ctx) {
      const period = args.period ?? "month";
      const since = sql`date_trunc(${period}, now() at time zone 'utc') at time zone 'utc'`;
      const scope = sql`u.org_id = ${ctx.orgId}::uuid and u.created_at >= ${since}`;
      const usd = (n: unknown) => `$${Number(n ?? 0).toFixed(4)}`;
      const [total] = await deps.db.execute<{ cost: string; runs: string }>(sql`
        select coalesce(sum(u.cost_usd), 0) as cost, count(distinct u.run_id) as runs
        from public.usage_ledger u where ${scope}`);
      const bots = await deps.db.execute<{
        name: string | null;
        cost: string;
        tin: string;
        tout: string;
      }>(sql`
        select b.name, sum(u.cost_usd) as cost,
          sum(case when u.kind = 'tokens_in' then u.quantity else 0 end) as tin,
          sum(case when u.kind = 'tokens_out' then u.quantity else 0 end) as tout
        from public.usage_ledger u left join public.bots b on b.id = u.bot_id
        where ${scope} group by b.name order by cost desc limit 20`);
      const models = await deps.db.execute<{ model: string | null; cost: string }>(sql`
        select u.model, sum(u.cost_usd) as cost from public.usage_ledger u where ${scope}
        group by u.model order by cost desc limit 10`);
      const kinds = await deps.db.execute<{ kind: string; quantity: string; cost: string }>(sql`
        select u.kind, sum(u.quantity) as quantity, sum(u.cost_usd) as cost from public.usage_ledger u
        where ${scope} group by u.kind order by cost desc`);
      const days = await deps.db.execute<{ day: string; cost: string }>(sql`
        select to_char(date_trunc('day', u.created_at at time zone 'utc'), 'YYYY-MM-DD') as day, sum(u.cost_usd) as cost
        from public.usage_ledger u where ${scope} group by 1 order by 1 desc limit 31`);
      const lines = [
        `Usage this ${period} (UTC): ${usd(total?.cost)} across ${total?.runs ?? 0} runs. Costs are estimates from published prices.`,
        "By bot:",
        ...bots.map(
          (b) =>
            `- ${b.name ?? "not tied to a bot (computers, etc.)"}: ${usd(b.cost)}, ${b.tin} tokens in, ${b.tout} out`,
        ),
        "By model:",
        ...models.map((m) => `- ${m.model ?? "no model (computers, voice)"}: ${usd(m.cost)}`),
        "Everything metered:",
        ...kinds.map((k) => `- ${k.kind}: ${Number(k.quantity)} (${usd(k.cost)})`),
        "By day (newest first):",
        ...days.map((d) => `- ${d.day}: ${usd(d.cost)}`),
      ];
      return { content: lines.join("\n"), preview: `${usd(total?.cost)} this ${period}` };
    },
  });

  registry.register({
    name: "memory.write",
    description:
      'Save a lasting fact or preference to long-term memory. Near-duplicates are updated instead of added. Use one standalone sentence. about: "person" saves a fact about the person you\'re helping (their job, family, places, tastes, how they like replies) to their private profile, which every bot they use reads; "work" (default) saves it to your own memory. Never save health, religion, politics, sexuality or money troubles unless they ask you to remember it.',
    risk: "low",
    // Only the bot's own state inside Casama: never asks (D-155).
    selfOnly: true,
    schema: z.object({
      content: z.string().min(1).max(1000),
      kind: z.enum(["fact", "preference"]).optional(),
      importance: z.number().min(0).max(1).optional(),
      about: z.enum(["person", "work"]).optional(),
    }),
    async execute(args, ctx) {
      const kind = args.kind ?? "fact";
      if (args.about === "person") {
        const userId = ctx.actingUserId;
        if (!userId)
          throw new ToolError(
            "no_person",
            "This run isn't for a person, so there's no profile to save to.",
          );
        const [about] = await deps.db.execute<{ learn: boolean }>(
          sql`select learn from public.user_about where user_id = ${userId}::uuid`,
        );
        if (about && !about.learn)
          return {
            content: "Not saved: this person turned off learning about them.",
            preview: "not saved",
          };
        const { id, created } = await savePersonFact(deps.db, {
          userId,
          orgId: ctx.orgId,
          botId: ctx.botId,
          runId: ctx.runId,
          kind,
          content: args.content,
        });
        if (created) await ctx.emit("memory.written", { memory_id: id, kind, scope: "profile" });
        return {
          content: created ? "Saved to their profile." : "Already in their profile.",
          preview: created ? "saved to profile" : "already saved",
        };
      }
      const memory = await deps.memory(ctx.orgId);
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
    readOnly: true,
    description: "Load the full instructions of one skill from the skills index by name.",
    risk: "low",
    // Only the bot's own state inside Casama: never asks (D-155).
    selfOnly: true,
    schema: z.object({ name: z.string().min(1).max(63) }),
    async execute(args, ctx) {
      const [skill] = await deps.db.execute<{ id: string; name: string; body_md: string }>(sql`
        select id, name, body_md from public.skills
        where org_id = ${ctx.orgId}::uuid and name = ${args.name} and enabled
          and (bot_id is null or bot_id = ${ctx.botId}::uuid)
        order by bot_id nulls last limit 1`);
      if (!skill) throw new ToolError("skill_not_found", `No enabled skill named "${args.name}".`);
      await ctx.emit("skill.loaded", { skill_id: skill.id, name: skill.name });
      // A skill's files go to ~/skills/<name>/ on the computer (D-104); scripts run only there.
      const files = await deps.db.execute<{
        path: string;
        content: string;
        executable: boolean;
      }>(sql`
        select path, encode(content, 'base64') as content, executable from public.skill_files where skill_id = ${skill.id}::uuid`);
      let note = "";
      if (files.length && ctx.computer) {
        try {
          const handle = await ctx.computer();
          // ~/skills/<name>/ (D-104), as an absolute path: a relative one would land in
          // ~/workspace (or the bot's own folder on a team computer).
          const dir = `/home/casama/skills/${skill.name}`;
          for (const f of files) {
            await handle.writeFile(`${dir}/${f.path}`, Buffer.from(f.content, "base64"));
            if (f.executable) await collectExec(handle.exec(`chmod +x ${shq(`${dir}/${f.path}`)}`));
          }
          note = `\n\n[This skill's files are in ~/skills/${skill.name}/: ${files.map((f) => f.path).join(", ")}]`;
        } catch {
          note = `\n\n[This skill has files (${files.map((f) => f.path).join(", ")}) but they could not be copied to your computer.]`;
        }
      } else if (files.length) {
        note = `\n\n[This skill has files (${files.map((f) => f.path).join(", ")}) that need a computer.]`;
      }
      return { content: skill.body_md + note, preview: `loaded ${skill.name}` };
    },
  });

  registry.register({
    name: "chat.react",
    description:
      'React to a message in this chat with one emoji, the way a person would (👍 ❤️ 😂 😮 😢 👎 or any other). Without message_id it reacts to the message you\'re answering. Use it instead of a reply when the message needs no answer ("thanks", "ok", "got it"): react, then end your turn without writing anything. In a group chat, react to agree without posting. Don\'t react to every message, and never instead of answering a question or doing what was asked. One reaction per message: another emoji replaces yours, remove takes it back.',
    risk: "low",
    // Only a mark on a message in this chat (and on the same message in the chat app it came
    // from, where replies already go without asking): never asks (D-155).
    selfOnly: true,
    schema: z.object({
      emoji: z.string().min(1).max(64).describe("Exactly one emoji, e.g. 👍"),
      message_id: z
        .string()
        .uuid()
        .optional()
        .describe("A message in this chat; defaults to the one you're answering"),
      remove: z.boolean().optional().describe("Take your reaction back instead"),
    }),
    async execute(args, ctx) {
      const [run] = await deps.db.execute<{
        conversation_id: string | null;
        target: string | null;
      }>(sql`
        select r.conversation_id, coalesce(
          (select m.id from public.messages m where m.run_id = r.id and m.role = 'user' order by m.created_at limit 1),
          r.trigger_message_id) as target
        from public.runs r where r.id = ${ctx.runId}::uuid`);
      if (!run?.conversation_id)
        throw new ToolError(
          "no_chat",
          "You're not working in a chat, so there's nothing to react to.",
        );
      const messageId = args.message_id ?? run.target;
      if (!messageId)
        throw new ToolError("no_message", "There's no message to react to. Pass message_id.");
      let out: Awaited<ReturnType<typeof setBotReaction>>;
      try {
        out = await setBotReaction(deps.db, {
          botId: ctx.botId,
          conversationId: run.conversation_id,
          messageId,
          emoji: args.remove ? null : args.emoji,
        });
      } catch (e) {
        if (e instanceof ReactionError) throw new ToolError(e.code, e.message);
        throw e;
      }
      if (deps.fetch && out.emoji !== out.previous)
        await mirrorReactionToChannel(
          deps.db,
          {
            conversationId: run.conversation_id,
            messageId,
            emoji: out.emoji,
            previous: out.previous,
          },
          deps.fetch,
        ).catch(() => false);
      return out.emoji
        ? { content: `Reacted ${out.emoji}.`, preview: out.emoji }
        : { content: "Reaction removed.", preview: "removed" };
    },
  });

  registerUiTools(registry);

  return registry;
}
