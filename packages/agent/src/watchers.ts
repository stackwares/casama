/**
 * Watchers (SPEC: Post-v1 roadmap → Watchers; D-116). "Tell me when…": the worker checks pages,
 * ticket replies, query results and times on a schedule without a model. The first check records a
 * baseline; a later change (or the time arriving) starts a run for the bot with the change.
 */

import { createHash } from "node:crypto";
import type { Database } from "@casama/db";
import { contentKeys } from "@casama/db";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "./acting.ts";
import { track } from "./analytics.ts";
import { createAdapter, loadIntegration } from "./integrations.ts";
import { loadSecrets } from "./secrets.ts";
import { ToolError, type ToolRegistry } from "./tools/registry.ts";
import { browserCaller, browserDevicesFor, firstOnline } from "./user-browser.ts";
import { WATCHER_NO_MATCH } from "./watcher-match.ts";

export { WATCHER_NO_MATCH };

type StartRun = (runId: string) => Promise<void>;

export type WatcherRow = {
  id: string;
  org_id: string;
  bot_id: string;
  created_by: string | null;
  name: string;
  kind: "page_change" | "reply" | "query" | "time";
  target: Record<string, unknown>;
  condition_md: string;
  on_match_md: string;
  check_every_seconds: number;
  expires_at: Date | string | null;
  last_value_hash: string | null;
  last_value: string | null;
  last_checked_at: Date | string | null;
  conversation_id: string | null;
  fired_count: number;
};

const sha = (s: string) => createHash("sha256").update(s).digest("hex");

/** Visible text of an HTML page, whitespace collapsed (scripts, styles and tags removed). */
export function pageText(html: string) {
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<noscript[\s\S]*?<\/noscript>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, " ")
    .trim();
}

/**
 * The part of a page to compare: from `anchor` on (`chars` characters, 2,000 by default), or the
 * whole page (20,000). Casama for Chrome sets `chars` to the length of the part a person pointed at.
 */
export function pagePart(text: string, anchor?: string, chars = 2000) {
  if (!anchor) return text.slice(0, 20_000);
  const i = text.toLowerCase().indexOf(anchor.toLowerCase());
  return i < 0 ? "" : text.slice(i, i + Math.max(20, Math.min(chars, 2000)));
}

/** A short, readable description of what changed. */
function describeChange(before: string | null, after: string) {
  if (!before) return after.slice(0, 1500);
  let start = 0;
  while (start < before.length && start < after.length && before[start] === after[start]) start++;
  const from = Math.max(0, start - 200);
  return `Before: …${before.slice(from, from + 600)}…\nNow: …${after.slice(from, from + 600)}…`;
}

export interface WatcherDeps {
  db: Database;
  fetch: typeof fetch;
  startRun: StartRun;
  /** Reads a page in the bot's browser (signed-in pages); only when its computer is awake. */
  browserText?: (botId: string, url: string) => Promise<string | null>;
  local?: { apiUrl: string; internalToken: string };
}

/** The current value a watcher compares, or null when it can't be read this time. */
async function currentValue(d: WatcherDeps, w: WatcherRow, now: Date): Promise<string | null> {
  const t = w.target;
  switch (w.kind) {
    case "time":
      return new Date(String(t.at)).getTime() <= now.getTime() ? "due" : "waiting";
    case "page_change": {
      const url = String(t.url);
      let text: string | null = null;
      // Signed-in pages read in the person's own browser (D-323 B10, C13): when it's online; else
      // the watcher waits (or, if its maker chose so, checks from the bot's computer).
      if (t.where === "mine" && d.local) {
        const ids = await browserDevicesFor(d.db, {
          orgId: w.org_id,
          botId: w.bot_id,
          userId: w.created_by,
        });
        const id = await firstOnline(d.local, ids);
        if (id) {
          const r = await browserCaller(d.local, id, { watcher_id: w.id }).call("page_text", {
            url,
          });
          if (!r.ok) throw new Error(r.message);
          text = r.text;
        } else if (t.offline !== "computer")
          throw new Error("Your browser is offline; this is checked again when it's back.");
      }
      if (text === null && t.browser && d.browserText) text = await d.browserText(w.bot_id, url);
      if (text === null) {
        const res = await d.fetch(url, {
          headers: { "user-agent": "CasamaWatcher/1.0" },
          signal: AbortSignal.timeout(15_000),
        });
        if (!res.ok) throw new Error(`The page answered ${res.status}.`);
        text = pageText(await res.text());
      }
      const anchor = typeof t.anchor === "string" && t.anchor ? t.anchor : undefined;
      const part = pagePart(text, anchor, typeof t.chars === "number" ? t.chars : undefined);
      // The anchor gone is not a change to report: the page moved things around, or the
      // check landed on a sign-in page. Say so on the watcher and keep the last value.
      if (anchor && !part) throw new Error(`"${anchor.slice(0, 80)}" is no longer on the page.`);
      return part;
    }
    case "reply": {
      // Ticket replies from people (email and chat sources come with their channels).
      const rows = await d.db.execute<{ body_md: string; created_at: string }>(sql`
        select body_md, created_at from public.task_comments
        where task_id = ${String(t.task_id)}::uuid and author_type = 'user' order by created_at desc limit 1`);
      return rows[0] ? `${rows[0].created_at}\n${rows[0].body_md}` : "";
    }
    case "query": {
      const rec = await loadIntegration(d.db, String(t.integration_id), d.fetch);
      if (!rec || rec.org_id !== w.org_id) throw new Error("The integration is gone.");
      const adapter = createAdapter(rec, {
        fetch: d.fetch,
        secrets: await loadSecrets(d.db, w.org_id, w.bot_id),
        local: d.local,
      });
      try {
        return (
          await adapter.callTool(String(t.tool), (t.args as Record<string, unknown>) ?? {})
        ).slice(0, 20_000);
      } finally {
        await adapter.close?.();
      }
    }
  }
}

/**
 * Starts the bot on a match, in the watcher's own conversation. That conversation is a topic under
 * the person's General (D-413): its result is posted there as a line that opens the topic, as a
 * routine's is (D-253). Before, the answer only ever sat in a "Watching: …" chat that nothing
 * pointed to, so a watcher that fired looked like it had done nothing.
 */
async function fire(d: WatcherDeps, w: WatcherRow, change: string) {
  return d.db.transaction(async (tx) => {
    let conv = w.conversation_id;
    if (!conv) {
      // General first: the first personal chat of a person with a bot would become General itself.
      if (w.created_by)
        await tx.execute(
          sql`select public.main_conversation(${w.org_id}::uuid, ${w.bot_id}::uuid, ${w.created_by}::uuid)`,
        );
      const [c] = await tx.execute<{ id: string }>(sql`
        insert into public.conversations (org_id, bot_id, title, created_by, personal, posts_result)
        values (${w.org_id}::uuid, ${w.bot_id}::uuid, ${`Watching: ${w.name}`.slice(0, 200)}, ${w.created_by}::uuid,
                ${w.created_by !== null}, ${w.created_by !== null}) returning id`);
      conv = c?.id ?? null;
      await tx.execute(
        sql`update public.watchers set conversation_id = ${conv}::uuid where id = ${w.id}::uuid`,
      );
    }
    const [run] = await tx.execute<{ id: string }>(sql`
      insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger)
      values (${w.org_id}::uuid, ${w.bot_id}::uuid, ${conv}::uuid, ${w.created_by}::uuid, 'watcher') returning id`);
    const text = [
      `Your watcher "${w.name}" fired.`,
      w.condition_md ? `You were watching for: ${w.condition_md}` : "",
      w.kind === "time" ? "The time you were waiting for has come." : `What changed:\n${change}`,
      w.on_match_md ? `What to do: ${w.on_match_md}` : "Tell the person what happened, briefly.",
      `If the change doesn't actually meet what you were watching for, reply with exactly ${WATCHER_NO_MATCH} and nothing else: the person is then not told.`,
    ]
      .filter(Boolean)
      .join("\n\n");
    await tx.execute(sql`
      insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
      values (${w.org_id}::uuid, ${conv}::uuid, 'user', ${w.created_by}::uuid, ${contentKeys.sealJson(w.org_id, [{ type: "text", text }])}::jsonb, ${run?.id}::uuid)`);
    return run?.id as string;
  });
}

/** The chat-app conversation a watcher was asked for in, if any: its news goes back there. */
export async function watcherAskedIn(db: Database, watcherConversationId: string) {
  const [w] = await db.execute<{ asked_in: string | null }>(sql`
    select target ->> 'asked_in' as asked_in from public.watchers
    where conversation_id = ${watcherConversationId}::uuid limit 1`);
  return w?.asked_in ?? null;
}

/**
 * Checks every watcher that is due (FOR UPDATE SKIP LOCKED, so workers never double-check). No
 * model is involved unless something changed. Returns the runs it started.
 */
export async function checkWatchers(d: WatcherDeps, now = new Date(), limit = 50) {
  const due = await d.db.transaction(async (tx) => {
    const rows = await tx.execute<WatcherRow>(sql`
      select * from public.watchers w where status = 'active' and next_check_at <= ${now.toISOString()}::timestamptz
        -- Only watchers whose creator is still in the workspace (D-334): leaving pauses them (a
        -- trigger on memberships), and this checks again when one would run.
        and (w.created_by is null or exists (select 1 from public.memberships m
          where m.org_id = w.org_id and m.user_id = w.created_by))
      order by next_check_at limit ${limit} for update skip locked`);
    for (const w of rows)
      await tx.execute(sql`
        update public.watchers set next_check_at = ${new Date(now.getTime() + w.check_every_seconds * 1000).toISOString()}::timestamptz
        where id = ${w.id}::uuid`);
    return rows;
  });
  const started: string[] = [];
  for (const w of due) {
    if (w.expires_at && new Date(w.expires_at).getTime() <= now.getTime()) {
      await d.db.execute(
        sql`update public.watchers set status = 'expired' where id = ${w.id}::uuid`,
      );
      continue;
    }
    let value: string | null;
    try {
      value = await currentValue(d, w, now);
    } catch (err) {
      await d.db.execute(sql`
        update public.watchers set last_checked_at = now(), last_error = ${(err as Error).message.slice(0, 500)} where id = ${w.id}::uuid`);
      continue;
    }
    if (value === null) continue;
    const hash = sha(value);
    const first = w.last_value_hash === null;
    const changed = !first && hash !== w.last_value_hash;
    const timeUp = w.kind === "time" && value === "due";
    await d.db.execute(sql`
      update public.watchers set last_value_hash = ${hash}, last_value = ${value.slice(0, 20_000)}, last_checked_at = now(), last_error = null,
        fired_count = fired_count + ${changed || timeUp ? 1 : 0},
        status = case when ${timeUp} then 'done' else status end
      where id = ${w.id}::uuid`);
    if (timeUp || changed) {
      const runId = await fire(d, w, timeUp ? "" : describeChange(w.last_value, value));
      await d.startRun(runId).catch(() => {});
      started.push(runId);
    }
  }
  return started;
}

// ---------------------------------------------------------------------------
// Tools
// ---------------------------------------------------------------------------

export function registerWatcherTools(registry: ToolRegistry, deps: { db: Database }) {
  const { db } = deps;
  registry.register({
    name: "watchers.create",
    description:
      'Watch for something and get woken when it happens ("tell me when…"): a web page changing (optionally from an anchor text on), a person replying on a ticket, a connected tool\'s result changing, or a time arriving. Checks cost nothing until something changes.',
    risk: "low",
    schema: z.object({
      name: z.string().min(1).max(120),
      kind: z.enum(["page_change", "reply", "query", "time"]),
      url: z.string().url().max(2000).optional().describe("page_change: the page"),
      anchor: z.string().max(200).optional().describe("page_change: compare from this text on"),
      browser: z
        .boolean()
        .optional()
        .describe("page_change: read it in your computer's browser (signed-in pages)"),
      where: z
        .enum(["mine", "computer"])
        .optional()
        .describe(
          "page_change: \"mine\" reads the page in the person's own Chrome, signed in as them, whenever it's online",
        ),
      when_offline: z
        .enum(["wait", "computer"])
        .optional()
        .describe(
          'where "mine": while their browser is offline, wait (default) or check from your computer',
        ),
      task_id: z.uuid().optional().describe("reply: the ticket"),
      integration: z.string().max(200).optional().describe("query: the integration's name"),
      tool: z
        .string()
        .max(200)
        .optional()
        .describe("query: the tool inside the integration (read-only tools only)"),
      args: z.record(z.string(), z.unknown()).optional(),
      at: z.string().max(40).optional().describe("time: ISO date-time"),
      condition: z.string().max(2000).optional().describe("What counts as a match, in words"),
      on_match: z.string().max(4000).optional().describe("What to do when it fires"),
      check_every_minutes: z.number().int().min(1).max(10_080).optional(),
      expires_in_days: z.number().int().min(1).max(365).optional(),
    }),
    async execute(args, ctx) {
      let target: Record<string, unknown>;
      if (args.kind === "page_change") {
        if (!args.url) throw new ToolError("missing_url", "A page watcher needs url.");
        target = {
          url: args.url,
          anchor: args.anchor,
          browser: args.browser ?? false,
          ...(args.where === "mine" ? { where: "mine", offline: args.when_offline ?? "wait" } : {}),
        };
      } else if (args.kind === "reply") {
        if (!args.task_id) throw new ToolError("missing_task", "A reply watcher needs task_id.");
        target = { source: "ticket", task_id: args.task_id };
      } else if (args.kind === "query") {
        if (!args.integration || !args.tool)
          throw new ToolError("missing_query", "A query watcher needs integration and tool.");
        const [i] = await db.execute<{
          id: string;
          tools_cache: Array<{ name: string; risk?: string }> | null;
        }>(sql`
          select i.id, i.tools_cache from public.integrations i join public.bot_integrations bi on bi.integration_id = i.id
          where i.org_id = ${ctx.orgId}::uuid and bi.bot_id = ${ctx.botId}::uuid and lower(i.name) = lower(${args.integration}) limit 1`);
        if (!i)
          throw new ToolError(
            "integration_not_found",
            `You aren't connected to ${args.integration}.`,
          );
        const tool = (i.tools_cache ?? []).find((t) => t.name === args.tool);
        if (!tool)
          throw new ToolError("tool_not_found", `${args.integration} has no tool ${args.tool}.`);
        if (tool.risk && tool.risk !== "low")
          throw new ToolError("not_read_only", "Watchers only rerun read-only tools.");
        target = { integration_id: i.id, tool: args.tool, args: args.args ?? {} };
      } else {
        const at = args.at ? new Date(args.at) : null;
        if (!at || Number.isNaN(at.getTime()))
          throw new ToolError("missing_time", "A time watcher needs at (ISO date-time).");
        target = { at: at.toISOString() };
      }
      const owner = await actingUserOf(db, ctx.runId);
      const every = (args.check_every_minutes ?? (args.kind === "time" ? 1 : 15)) * 60;
      // Asked for from a chat app (D-413): the news goes back there too. Kept with the target;
      // only a direct chat with this bot counts, as for routines.
      const [here] = await db.execute<{ id: string }>(sql`
        select c.id from public.runs r join public.conversations c on c.id = r.conversation_id
        where r.id = ${ctx.runId}::uuid and c.bot_id = ${ctx.botId}::uuid and c.kind = 'direct'
          and exists (select 1 from public.channel_threads t where t.conversation_id = c.id)`);
      if (here) target = { ...target, asked_in: here.id };
      const [w] = await db.execute<{ id: string }>(sql`
        insert into public.watchers (org_id, bot_id, created_by, name, kind, target, condition_md, on_match_md, check_every_seconds, expires_at)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${owner}::uuid, ${args.name}, ${args.kind}, ${JSON.stringify(target)}::jsonb,
                ${args.condition ?? ""}, ${args.on_match ?? ""}, ${Math.max(60, every)},
                ${args.expires_in_days ? new Date(Date.now() + args.expires_in_days * 86_400_000).toISOString() : null}::timestamptz)
        returning id`);
      track(db, {
        event: "watcher_created",
        userId: owner,
        orgId: ctx.orgId,
        properties: { kind: args.kind },
      });
      return {
        content: `Watching "${args.name}" (${w?.id}). I'll be woken when it changes.`,
        preview: `watching ${args.name}`,
      };
    },
  });

  registry.register({
    name: "watchers.list",
    readOnly: true,
    description: "Your active and paused watchers.",
    risk: "low",
    schema: z.object({}),
    async execute(_args, ctx) {
      const rows = await db.execute<{
        id: string;
        name: string;
        kind: string;
        status: string;
        fired_count: number;
      }>(sql`
        select id, name, kind, status, fired_count from public.watchers
        where bot_id = ${ctx.botId}::uuid and status in ('active', 'paused') order by created_at`);
      return {
        content:
          rows
            .map((r) => `- ${r.name} (${r.kind}, ${r.status}, fired ${r.fired_count}×) ${r.id}`)
            .join("\n") || "No watchers.",
        preview: `${rows.length} watchers`,
      };
    },
  });

  registry.register({
    name: "watchers.delete",
    description: "Stop a watcher.",
    risk: "low",
    schema: z.object({ watcher: z.string().min(1).max(120).describe("Its id or name") }),
    async execute(args, ctx) {
      const rows = await db.execute<{ id: string }>(sql`
        delete from public.watchers where bot_id = ${ctx.botId}::uuid and (id::text = ${args.watcher} or lower(name) = lower(${args.watcher}))
        returning id`);
      if (!rows.length) throw new ToolError("watcher_not_found", `No watcher ${args.watcher}.`);
      return { content: `Stopped watching ${args.watcher}.`, preview: "stopped" };
    },
  });
}
