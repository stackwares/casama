import type { Database } from "@kasama/db";
import {
  isValidCron,
  isValidTimezone,
  MAX_DELEGATION_DEPTH,
  nextRunAt,
  subagentBudget,
} from "@kasama/domain";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { wrapUntrusted } from "../context.ts";
import { MEDIA_PRICES, type MediaProvider } from "../media.ts";
import type { NotificationService } from "../notifications.ts";
import type { SearchProvider } from "../search.ts";
import { startTicketWork } from "../tickets.ts";
import { type ToolContext, ToolError, type ToolRegistry } from "./registry.ts";
import { contentKeys } from "@kasama/db";
import { sealRunPayload } from "../events.ts";
import { actingUserOf, personForRun } from "../acting.ts";

export interface AutonomyToolDeps {
  db: Database;
  /** Guarded fetch for outbound requests (private ranges blocked). */
  fetch: typeof fetch;
  notifications?: NotificationService;
  mediaFor?: (orgId: string) => Promise<MediaProvider | null>;
  searchFor?: (orgId: string) => Promise<SearchProvider | null>;
  /** Runs a child run to completion (a child DBOS workflow in the worker). Late-bound. */
  runChild?: (runId: string) => Promise<{ status: string }>;
  /** Starts a run without waiting (a bot assigning a ticket to another bot). Late-bound. */
  startRun?: (runId: string) => Promise<void>;
}

interface RunRow {
  id: string;
  org_id: string;
  bot_id: string;
  parent_run_id: string | null;
  budget: Record<string, unknown>;
  cost_usd: string;
  created_by: string | null;
  [key: string]: unknown;
}

/** Ancestors of a run (nearest first), for depth limits and cycle checks. */
async function ancestry(db: Database, runId: string) {
  return db.execute<{ id: string; bot_id: string; depth: number }>(sql`
    with recursive chain as (
      select id, bot_id, parent_run_id, 0 as depth from public.runs where id = ${runId}::uuid
      union all
      select r.id, r.bot_id, r.parent_run_id, c.depth + 1 from public.runs r join chain c on r.id = c.parent_run_id where c.depth < 10
    ) select id, bot_id, depth from chain order by depth`);
}

/** Final text of a finished run (from its message.completed event). */
async function finalText(db: Database, runId: string) {
  // Read in the app, not in SQL: the payload may be sealed (D-136).
  const [e] = await db.execute<{ payload: { content?: Array<{ type?: string; text?: string }> } }>(sql`
    select payload from public.run_events where run_id = ${runId}::uuid and type = 'message.completed' order by seq desc limit 1`);
  return (e?.payload.content ?? []).filter((p) => p.type === "text").map((p) => p.text ?? "").join("");
}

async function emit(db: Database, runId: string, type: string, payload: Record<string, unknown>) {
  await db.execute(
    sql`select public.append_run_event(${runId}::uuid, ${type}, ${await sealRunPayload(db, runId, payload)}::jsonb)`,
  );
}

export function registerAutonomyTools(registry: ToolRegistry, deps: AutonomyToolDeps) {
  const { db } = deps;

  // --- outbound HTTP and search ---------------------------------------------

  registry.register({
    name: "http.request",
    description:
      "Make an HTTP request from the server. Use {{secret:NAME}} in headers or body for credentials; they are filled in only for the secret's allowed hosts. Private and internal addresses are blocked.",
    risk: "medium",
    acceptsSecrets: true,
    untrustedOutput: true,
    destinationHost: (args) => {
      try {
        return new URL(args.url).hostname;
      } catch {
        return null;
      }
    },
    schema: z.object({
      method: z.enum(["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD"]).default("GET"),
      url: z.url().max(4000),
      headers: z.record(z.string(), z.string()).optional(),
      body: z.string().max(1_000_000).optional(),
    }),
    async execute(args) {
      const res = await deps.fetch(args.url, {
        method: args.method,
        headers: args.headers,
        body: args.body,
        redirect: "manual",
      });
      const type = res.headers.get("content-type") ?? "";
      const text =
        /json|text|xml|html|javascript/.test(type) || !type
          ? await res.text()
          : `[${type} body, ${res.headers.get("content-length") ?? "?"} bytes]`;
      const head = `HTTP ${res.status} ${res.statusText}\ncontent-type: ${type}${res.headers.get("location") ? `\nlocation: ${res.headers.get("location")}` : ""}`;
      return {
        content: wrapUntrusted("http", `${head}\n\n${text.slice(0, 200_000)}`),
        preview: `HTTP ${res.status}`,
      };
    },
  });

  registry.register({
    name: "web.search",
    description:
      "Search the web. Returns titles, links and snippets; open pages with the browser or http.request to read them.",
    risk: "low",
    readOnly: true,
    untrustedOutput: true,
    schema: z.object({
      query: z.string().min(1).max(400),
      count: z.number().int().min(1).max(20).optional(),
    }),
    async execute(args, ctx) {
      const provider = await deps.searchFor?.(ctx.orgId);
      if (!provider)
        throw new ToolError(
          "no_search_provider",
          "No web search key is configured. Add a Brave Search or Tavily key in Model keys.",
        );
      const results = await provider.search(args.query, args.count ?? 8);
      await db.execute(sql`insert into public.usage_ledger (org_id, bot_id, run_id, kind, quantity, cost_usd)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${ctx.runId}::uuid, 'search_queries', 1, 0.005)`);
      const text = results
        .map((r, i) => `${i + 1}. ${r.title}\n   ${r.url}\n   ${r.snippet}`)
        .join("\n");
      return {
        content: wrapUntrusted("search", text || "No results."),
        preview: `${results.length} results`,
      };
    },
  });

  // --- notifications ---------------------------------------------------------

  registry.register({
    name: "notify.user",
    description:
      "Send a push notification to the bot's owner (use sparingly: finished work, blockers, urgent findings).",
    risk: "low",
    schema: z.object({ title: z.string().min(1).max(120), message: z.string().min(1).max(1000) }),
    async execute(args, ctx) {
      if (!deps.notifications)
        throw new ToolError("notifications_unavailable", "Notifications are not configured.");
      // The person the run acts for (a sub-run's starter), else the bot's creator.
      const p = await personForRun(db, ctx.runId);
      const owner = { user_id: p.userId };
      if (!owner?.user_id) throw new ToolError("no_owner", "This bot has no owner to notify.");
      await deps.notifications.notify(owner.user_id, ctx.orgId, "bot_message", {
        title: args.title,
        body: args.message,
        link: `/bots/${ctx.botId}/chat`,
        bot_id: ctx.botId,
        run_id: ctx.runId,
      });
      return { content: "Notification sent.", preview: "notified" };
    },
  });

  // --- task board --------------------------------------------------------------

  const botByRef = async (orgId: string, ref: string) => {
    const [b] = await db.execute<{ id: string; name: string }>(sql`
      select id, name from public.bots where org_id = ${orgId}::uuid and (id::text = ${ref} or lower(name) = lower(${ref})) limit 1`);
    return b;
  };

  const STATUSES = ["todo", "in_progress", "in_review", "blocked", "done"] as const;
  const PRIORITIES = ["urgent", "high", "medium", "low", "none"] as const;

  /** Assigning a ticket to another bot starts that bot's work (D-098). */
  const startAssignee = async (
    taskId: string,
    assigneeId: string | null | undefined,
    ctx: { botId: string },
  ) => {
    if (!assigneeId || assigneeId === ctx.botId || !deps.startRun) return;
    await startTicketWork(db, { ticketId: taskId, actorUserId: null }, deps.startRun);
  };

  registry.register({
    name: "tasks.create",
    description:
      "Add a ticket to the board, optionally assigned to a bot by name (that bot starts on it right away).",
    risk: "low",
    schema: z.object({
      title: z.string().min(1).max(300),
      details: z.string().max(10_000).optional(),
      assignee: z.string().max(100).optional(),
      priority: z.enum(PRIORITIES).optional(),
      review_required: z.boolean().optional(),
    }),
    async execute(args, ctx) {
      const assignee = args.assignee ? await botByRef(ctx.orgId, args.assignee) : undefined;
      if (args.assignee && !assignee)
        throw new ToolError("bot_not_found", `No bot named ${args.assignee}.`);
      const [t] = await db.execute<{ id: string }>(sql`
        insert into public.tasks (org_id, created_by_bot_id, assignee_bot_id, title, details_md, parent_run_id, priority, review_required)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${assignee?.id ?? null}::uuid, ${args.title}, ${contentKeys.seal(ctx.orgId, args.details ?? "")}, ${ctx.runId}::uuid,
                ${args.priority ?? "none"}, ${args.review_required ?? false})
        returning id`);
      if (t) await startAssignee(t.id, assignee?.id, ctx);
      return { content: `Created ticket ${t?.id}.`, preview: args.title };
    },
  });

  registry.register({
    name: "tasks.update",
    description:
      "Update a ticket: status (todo, in_progress, in_review, blocked, done), a result, priority or the bot it's assigned to.",
    risk: "low",
    schema: z.object({
      task_id: z.uuid(),
      status: z.enum(STATUSES).optional(),
      result: z.string().max(20_000).optional(),
      priority: z.enum(PRIORITIES).optional(),
      assignee: z.string().max(100).optional().describe("A bot's name, to hand the ticket over"),
    }),
    async execute(args, ctx) {
      const assignee = args.assignee ? await botByRef(ctx.orgId, args.assignee) : undefined;
      if (args.assignee && !assignee)
        throw new ToolError("bot_not_found", `No bot named ${args.assignee}.`);
      const rows = await db.execute<{ id: string }>(sql`
        update public.tasks set status = coalesce(${args.status ?? null}, status), result_md = coalesce(${contentKeys.seal(ctx.orgId, args.result ?? null)}, result_md),
          priority = coalesce(${args.priority ?? null}, priority), assignee_bot_id = coalesce(${assignee?.id ?? null}::uuid, assignee_bot_id),
          updated_at = now()
        where id = ${args.task_id}::uuid and org_id = ${ctx.orgId}::uuid returning id`);
      if (!rows.length) throw new ToolError("task_not_found", "No such ticket.");
      if (assignee) await startAssignee(args.task_id, assignee.id, ctx);
      return { content: "Ticket updated.", preview: args.status ?? "updated" };
    },
  });

  registry.register({
    name: "tasks.comment",
    description: "Post a comment on a ticket (progress, questions, results).",
    risk: "low",
    schema: z.object({ task_id: z.uuid(), body: z.string().min(1).max(20_000) }),
    async execute(args, ctx) {
      const rows = await db.execute<{ id: string }>(sql`
        insert into public.task_comments (org_id, task_id, author_type, author_bot_id, body_md)
        select t.org_id, t.id, 'bot', ${ctx.botId}::uuid, ${contentKeys.seal(ctx.orgId, args.body)} from public.tasks t
        where t.id = ${args.task_id}::uuid and t.org_id = ${ctx.orgId}::uuid returning id`);
      if (!rows.length) throw new ToolError("task_not_found", "No such ticket.");
      await db.execute(
        sql`update public.tasks set updated_at = now() where id = ${args.task_id}::uuid`,
      );
      return { content: "Comment posted.", preview: args.body.slice(0, 120) };
    },
  });

  registry.register({
    name: "tasks.list",
    readOnly: true,
    description: "List tickets on the board, newest first (optionally by status, or only yours).",
    risk: "low",
    schema: z.object({
      status: z.enum(STATUSES).optional(),
      mine: z.boolean().optional().describe("Only tickets assigned to you"),
      limit: z.number().int().min(1).max(100).optional(),
    }),
    async execute(args, ctx) {
      const rows = await db.execute<{
        id: string;
        title: string;
        status: string;
        priority: string;
        bot: string | null;
      }>(sql`
        select t.id, t.title, t.status, t.priority, b.name as bot from public.tasks t
        left join public.bots b on b.id = t.assignee_bot_id
        where t.org_id = ${ctx.orgId}::uuid
          and (${args.status ?? null}::text is null or t.status = ${args.status ?? null})
          and (${args.mine ?? false} = false or t.assignee_bot_id = ${ctx.botId}::uuid)
        order by t.updated_at desc limit ${args.limit ?? 30}`);
      const text = rows.length
        ? rows
            .map(
              (r) =>
                `- ${r.title} [${r.status}, ${r.priority}${r.bot ? `, ${r.bot}` : ""}] (id ${r.id})`,
            )
            .join("\n")
        : "No tickets.";
      return { content: text, preview: `${rows.length} tickets` };
    },
  });

  // A bot may manage another bot's routines in its workspace (D-100).
  const BOT_ARG = z
    .string()
    .max(100)
    .optional()
    .describe("Another bot's name, to manage its routines instead of yours");
  const routineBot = async (ref: string | undefined, ctx: { orgId: string; botId: string }) => {
    if (!ref) return ctx.botId;
    const b = await botByRef(ctx.orgId, ref);
    if (!b) throw new ToolError("bot_not_found", `No bot named ${ref}.`);
    return b.id;
  };

  // --- routines -----------------------------------------------------------------

  registry.register({
    name: "routines.create",
    description:
      "Schedule work for yourself later. For something that should happen once (a reminder, a follow-up), pass in_minutes or run_at; it runs a single time and switches itself off. Use schedule_cron (5-field cron in the user's timezone) only for work that repeats. Results arrive in a dedicated conversation.",
    risk: "medium",
    schema: z.object({
      bot: BOT_ARG,
      name: z.string().min(1).max(120),
      instructions: z
        .string()
        .min(1)
        .max(10_000)
        .describe("What to do when it runs, written as a message to yourself"),
      in_minutes: z
        .number()
        .int()
        .min(1)
        .max(60 * 24 * 365)
        .optional()
        .describe("Run once, this many minutes from now"),
      run_at: z
        .string()
        .max(40)
        .optional()
        .describe("Run once at this ISO 8601 time (with offset)"),
      schedule_cron: z.string().max(100).optional().describe("Repeat on this 5-field cron"),
      on_device_event: z
        .object({
          event: z.enum(["wake", "arrive", "leave", "leave_now", "workout_ended", "notification", "focus_on", "focus_off", "file_added"]),
          place: z.string().max(60).optional().describe("arrive/leave: a named place like Home"),
          app: z.string().max(200).optional().describe("notification: the app to watch"),
          minutes_before: z.number().int().min(0).max(120).optional().describe("leave_now: buffer on top of travel time"),
          folder: z.string().max(200).optional().describe("file_added: a folder the person's desktop app watches, like Downloads"),
          pattern: z.string().max(100).optional().describe("file_added: a file name pattern like *.pdf"),
        })
        .optional()
        .describe("Run each time this happens on the person's own phone (they must share that kind in Device connections)"),
      timezone: z.string().max(64).optional(),
      notify: z.boolean().optional(),
    }),
    async execute(args, ctx) {
      const target = await routineBot(args.bot, ctx);
      const kinds = [args.in_minutes != null, !!args.run_at, !!args.schedule_cron, !!args.on_device_event].filter(
        Boolean,
      ).length;
      if (kinds !== 1)
        throw new ToolError(
          "invalid_schedule",
          "Pass exactly one of in_minutes, run_at (once), schedule_cron (repeating) or on_device_event.",
        );
      if (args.on_device_event) {
        // Device triggers (D-151) belong to the person this run acts for: their events, their routine.
        const d = args.on_device_event;
        if ((d.event === "arrive" || d.event === "leave") && !d.place) throw new ToolError("place_required", "Arrive and leave need a named place.");
        if (d.event === "notification" && !d.app) throw new ToolError("app_required", "Notification routines need the app to watch.");
        if (d.event === "file_added" && !d.folder) throw new ToolError("folder_required", "File routines need the watched folder.");
        const person = await actingUserOf(db, ctx.runId);
        if (!person) throw new ToolError("no_person", "Device routines need a person: this run isn't acting for anyone.");
        const [r] = await db.execute<{ id: string }>(sql`
          insert into public.routines (org_id, bot_id, created_by, name, instructions_md, timezone, trigger, notify)
          values (${ctx.orgId}::uuid, ${target}::uuid, ${person}::uuid, ${args.name}, ${args.instructions}, ${args.timezone ?? "UTC"},
                  ${JSON.stringify({ type: "device", ...d })}::jsonb, ${args.notify ?? true}) returning id`);
        return { content: `Created routine ${r?.id}: it runs on ${d.event}${d.place ? ` (${d.place})` : ""}${d.app ? ` (${d.app})` : ""}.`, preview: `${args.name} · on ${d.event}` };
      }
      if (args.schedule_cron && !isValidCron(args.schedule_cron))
        throw new ToolError("invalid_cron", "Use a 5-field cron expression like '0 8 * * *'.");
      const person = await personForRun(db, ctx.runId);
      const owner = { user_id: person.userId, timezone: person.timezone };
      const tz = args.timezone ?? owner?.timezone ?? "UTC";
      if (!isValidTimezone(tz)) throw new ToolError("invalid_timezone", `Unknown timezone ${tz}.`);
      let next: Date;
      if (args.schedule_cron) {
        next = nextRunAt(args.schedule_cron, tz);
      } else if (args.in_minutes != null) {
        next = new Date(Date.now() + args.in_minutes * 60_000);
      } else {
        next = new Date(args.run_at as string);
        if (Number.isNaN(next.getTime()))
          throw new ToolError("invalid_time", "run_at must be an ISO 8601 time.");
        if (next.getTime() < Date.now() - 60_000)
          throw new ToolError("invalid_time", "run_at is in the past.");
      }
      const once = !args.schedule_cron;
      const trigger = JSON.stringify({ type: once ? "once" : "schedule" });
      const [r] = await db.execute<{ id: string }>(sql`
        insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, trigger, notify, next_run_at)
        values (${ctx.orgId}::uuid, ${target}::uuid, ${owner?.user_id ?? null}::uuid, ${args.name}, ${args.instructions},
                ${args.schedule_cron ?? null}, ${tz}, ${trigger}::jsonb, ${args.notify ?? true}, ${next.toISOString()}::timestamptz) returning id`);
      return {
        content: once
          ? `Scheduled one-time routine ${r?.id} for ${next.toISOString()}. It runs once, then switches itself off.`
          : `Scheduled repeating routine ${r?.id}; next run ${next.toISOString()} (${tz}).`,
        preview: once
          ? `${args.name} · once at ${next.toISOString()}`
          : `${args.name} · ${args.schedule_cron}`,
      };
    },
  });

  registry.register({
    name: "routines.list",
    description:
      "List your routines (id, name, schedule, whether it is on, next run). Use it before changing or deleting one.",
    risk: "low",
    readOnly: true,
    schema: z.object({ bot: BOT_ARG }),
    async execute(args, ctx) {
      const target = await routineBot(args.bot, ctx);
      const rows = await db.execute<{
        id: string;
        name: string;
        schedule_cron: string | null;
        trigger: { type?: string };
        timezone: string;
        enabled: boolean;
        next_run_at: string | null;
        last_run_at: string | null;
      }>(sql`
        select id, name, schedule_cron, trigger, timezone, enabled, next_run_at, last_run_at from public.routines
        where bot_id = ${target}::uuid order by created_at`);
      if (!rows.length) return { content: "You have no routines.", preview: "none" };
      const lines = rows.map((r) => {
        const when =
          r.trigger?.type === "once"
            ? "once"
            : r.schedule_cron
              ? `cron ${r.schedule_cron} (${r.timezone})`
              : (r.trigger?.type ?? "schedule");
        const next = r.next_run_at ? new Date(r.next_run_at).toISOString() : "none";
        return `- ${r.id} · ${r.name} · ${when} · ${r.enabled ? "on" : "off"} · next ${next}`;
      });
      return {
        content: lines.join("\n"),
        preview: `${rows.length} routine${rows.length === 1 ? "" : "s"}`,
      };
    },
  });

  registry.register({
    name: "routines.update",
    description:
      "Change, pause (enabled: false) or resume one of your routines. Find its id with routines.list.",
    risk: "medium",
    schema: z.object({
      bot: BOT_ARG,
      routine_id: z.uuid(),
      enabled: z.boolean().optional(),
      schedule_cron: z.string().max(100).optional(),
      run_at: z.string().max(40).optional(),
      instructions: z.string().max(10_000).optional(),
    }),
    async execute(args, ctx) {
      const target = await routineBot(args.bot, ctx);
      const [r] = await db.execute<{
        schedule_cron: string | null;
        timezone: string;
        trigger: { type?: string };
        next_run_at: string | null;
      }>(sql`
        select schedule_cron, timezone, trigger, next_run_at from public.routines where id = ${args.routine_id}::uuid and bot_id = ${target}::uuid`);
      if (!r)
        throw new ToolError(
          "routine_not_found",
          "No such routine for this bot. Check routines.list.",
        );
      const once = r.trigger?.type === "once";
      if (args.schedule_cron && !isValidCron(args.schedule_cron))
        throw new ToolError("invalid_cron", "Invalid cron expression.");
      const cron = once ? null : (args.schedule_cron ?? r.schedule_cron);
      let next: string | null = null;
      if (once) {
        const at = args.run_at
          ? new Date(args.run_at)
          : r.next_run_at
            ? new Date(r.next_run_at)
            : null;
        if (args.run_at && (!at || Number.isNaN(at.getTime())))
          throw new ToolError("invalid_time", "run_at must be an ISO 8601 time.");
        next = at ? at.toISOString() : null;
      } else if (cron) {
        next = nextRunAt(cron, r.timezone).toISOString();
      }
      await db.execute(sql`
        update public.routines set enabled = coalesce(${args.enabled ?? null}, enabled), schedule_cron = ${cron},
          instructions_md = coalesce(${args.instructions ?? null}, instructions_md),
          next_run_at = case when coalesce(${args.enabled ?? null}, enabled) then ${next}::timestamptz else null end
        where id = ${args.routine_id}::uuid`);
      return {
        content: "Routine updated.",
        preview: args.enabled === false ? "paused" : "updated",
      };
    },
  });

  registry.register({
    name: "routines.delete",
    description:
      "Delete one of your routines for good (its past results stay). Find its id with routines.list.",
    risk: "medium",
    schema: z.object({ routine_id: z.uuid(), bot: BOT_ARG }),
    async execute(args, ctx) {
      const target = await routineBot(args.bot, ctx);
      const rows = await db.execute<{ name: string }>(sql`
        delete from public.routines where id = ${args.routine_id}::uuid and bot_id = ${target}::uuid returning name`);
      if (!rows.length)
        throw new ToolError(
          "routine_not_found",
          "No such routine for this bot. Check routines.list.",
        );
      return {
        content: `Deleted routine "${rows[0]?.name}".`,
        preview: `deleted ${rows[0]?.name}`,
      };
    },
  });

  // --- delegation ------------------------------------------------------------------

  /** Creates a child run (subagent or peer bot) and runs it to completion. */
  async function runChildTask(
    ctx: ToolContext,
    opts: {
      botId: string;
      task: string;
      trigger: "subagent" | "delegation";
      budgetUsd?: number;
      tools?: string[];
      timeoutS?: number;
    },
  ) {
    if (!deps.runChild)
      throw new ToolError("delegation_unavailable", "Delegation is not available here.");
    const chain = await ancestry(db, ctx.runId);
    if (chain.length >= MAX_DELEGATION_DEPTH + 1)
      throw new ToolError(
        "delegation_too_deep",
        `Delegation is limited to ${MAX_DELEGATION_DEPTH} levels.`,
      );
    if (opts.trigger === "delegation" && chain.some((c) => c.bot_id === opts.botId)) {
      throw new ToolError(
        "delegation_cycle",
        "That bot is already working on this chain of tasks; delegating to it would create a cycle.",
      );
    }
    const [parent] = await db.execute<RunRow>(sql`
      select r.id, r.org_id, r.bot_id, r.parent_run_id, r.budget, r.cost_usd, r.created_by, b.budget as bot_budget
      from public.runs r join public.bots b on b.id = r.bot_id where r.id = ${ctx.runId}::uuid`);
    if (!parent) throw new ToolError("run_not_found", "Parent run not found.");
    const parentLimit = Number(
      (parent.budget as { per_run_usd?: number }).per_run_usd ??
        (parent.bot_budget as { per_run_usd?: number })?.per_run_usd ??
        Number.NaN,
    );
    const budget =
      opts.budgetUsd ??
      subagentBudget(Number.isFinite(parentLimit) ? parentLimit : null, Number(parent.cost_usd));

    let conversationId: string | null = null;
    if (opts.trigger === "delegation") {
      const [bot] = await db.execute<{ name: string }>(
        sql`select name from public.bots where id = ${ctx.botId}::uuid`,
      );
      const [conv] = await db.execute<{ id: string }>(sql`
        insert into public.conversations (org_id, bot_id, title) values (${ctx.orgId}::uuid, ${opts.botId}::uuid, ${`Task from ${bot?.name ?? "a bot"}`}) returning id`);
      conversationId = conv?.id ?? null;
    }
    const [child] = await db.execute<{ id: string }>(sql`
      insert into public.runs (org_id, bot_id, conversation_id, parent_run_id, created_by, trigger, budget, project_id)
      values (${ctx.orgId}::uuid, ${opts.botId}::uuid, ${conversationId}::uuid, ${ctx.runId}::uuid, ${parent.created_by}::uuid, ${opts.trigger},
              ${JSON.stringify({ per_run_usd: budget, task: opts.task, tools: opts.tools, timeout_s: opts.timeoutS ?? 600 })}::jsonb,
              (select project_id from public.runs where id = ${ctx.runId}::uuid))
      returning id`);
    const childId = child?.id as string;
    if (conversationId) {
      await db.execute(sql`insert into public.messages (org_id, conversation_id, role, content, run_id)
        values (${ctx.orgId}::uuid, ${conversationId}::uuid, 'user', ${contentKeys.sealJson(ctx.orgId, [{ type: "text", text: opts.task }])}::jsonb, ${childId}::uuid)`);
    }
    await emit(db, ctx.runId, "subrun.started", {
      child_run_id: childId,
      bot_id: opts.botId,
      task: opts.task.slice(0, 1000),
    });
    const { status } = await deps.runChild(childId);
    const summary = status === "completed" ? await finalText(db, childId) : "";
    const [failed] = await db.execute<{ error: { code?: string; message?: string } | null }>(
      sql`select error from public.runs where id = ${childId}::uuid`,
    );
    const outcome = (
      status === "completed" ? "completed" : status === "cancelled" ? "cancelled" : "failed"
    ) as "completed";
    const note =
      status === "completed"
        ? summary
        : `Stopped: ${failed?.error?.code ?? status}. ${failed?.error?.message ?? ""}`.trim();
    await emit(db, ctx.runId, "subrun.completed", {
      child_run_id: childId,
      status: outcome,
      summary: note.slice(0, 4000),
    });
    return { childId, status, note, budget };
  }

  registry.register({
    name: "subagent.spawn",
    description:
      "Start a short-lived helper (a copy of you with a fresh context) for a self-contained task. It has its own budget (default 20% of what you have left), a time limit and optionally fewer tools, and returns a summary.",
    risk: "low",
    schema: z.object({
      task: z.string().min(1).max(20_000),
      tools: z.array(z.string().max(120)).max(50).optional(),
      budget_usd: z.number().positive().max(100).optional(),
      timeout_s: z.number().int().min(10).max(3600).optional(),
    }),
    async execute(args, ctx) {
      const r = await runChildTask(ctx, {
        botId: ctx.botId,
        task: args.task,
        trigger: "subagent",
        budgetUsd: args.budget_usd,
        tools: args.tools,
        timeoutS: args.timeout_s,
      });
      return {
        content: `Subagent ${r.status} (budget $${r.budget}).\n${r.note}`,
        preview: `subagent ${r.status}`,
      };
    },
  });

  registry.register({
    name: "bots.delegate",
    description: "Hand a task to another bot in your workspace (by name). Waits for its result.",
    risk: "low",
    schema: z.object({
      bot: z.string().min(1).max(100),
      task: z.string().min(1).max(20_000),
      budget_usd: z.number().positive().max(100).optional(),
    }),
    async execute(args, ctx) {
      const peer = await botByRef(ctx.orgId, args.bot);
      if (!peer) throw new ToolError("bot_not_found", `No bot named ${args.bot}.`);
      if (peer.id === ctx.botId)
        throw new ToolError("delegation_cycle", "Use subagent.spawn to hand work to yourself.");
      // Bot-to-bot switch (D-133): handing work to peer bots can be turned off; subagents still work.
      const [org] = await deps.db.execute<{ allow: boolean }>(sql`select allow_bot_to_bot as allow from public.organizations where id = ${ctx.orgId}::uuid`);
      if (org && !org.allow)
        throw new ToolError("bot_to_bot_off", "Bots can't hand work to each other in this workspace (an admin turned it off). Use subagent.spawn instead.");
      const r = await runChildTask(ctx, {
        botId: peer.id,
        task: args.task,
        trigger: "delegation",
        budgetUsd: args.budget_usd,
      });
      return {
        content: `${peer.name} ${r.status}.\n${r.note}`,
        preview: `${peer.name} ${r.status}`,
      };
    },
  });

  // --- media generation ---------------------------------------------------------

  async function saveMedia(ctx: ToolContext, url: string, ext: string) {
    if (!ctx.computer) return null;
    const res = await deps.fetch(url);
    if (!res.ok) return null;
    const path = `media/${new Date().toISOString().replace(/[:.]/g, "-")}.${ext}`;
    await (await ctx.computer()).writeFile(path, new Uint8Array(await res.arrayBuffer()));
    return path;
  }

  registry.register({
    name: "media.image.generate",
    description:
      "Generate an image from a text prompt. The image is saved in your computer (media/) when you have one.",
    risk: "medium",
    confirm: true,
    schema: z.object({
      prompt: z.string().min(1).max(4000),
      size: z.enum(["square", "portrait", "landscape"]).optional(),
    }),
    async execute(args, ctx) {
      const provider = await deps.mediaFor?.(ctx.orgId);
      if (!provider)
        throw new ToolError(
          "no_media_provider",
          "No media generation key is configured. Add a fal.ai key in Model keys.",
        );
      const [img] = await provider.generateImage({ prompt: args.prompt, size: args.size });
      if (!img) throw new ToolError("media_failed", "No image was returned.");
      await db.execute(sql`insert into public.usage_ledger (org_id, bot_id, run_id, kind, quantity, cost_usd, model)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${ctx.runId}::uuid, 'media_images', 1, ${MEDIA_PRICES.image}, ${provider.id})`);
      const path = await saveMedia(
        ctx,
        img.url,
        img.contentType.includes("png") ? "png" : "jpg",
      ).catch(() => null);
      return {
        content: `Generated image: ${img.url}${path ? `\nSaved to ~/workspace/${path}` : ""}`,
        preview: path ?? "image generated",
        artifactPath: path,
      };
    },
  });

  registry.register({
    name: "media.video.generate",
    description:
      "Generate a short video clip from a text prompt (can take a few minutes). Saved in your computer (media/) when you have one.",
    risk: "medium",
    confirm: true,
    schema: z.object({
      prompt: z.string().min(1).max(4000),
      duration_s: z.number().int().min(1).max(20).optional(),
    }),
    async execute(args, ctx) {
      const provider = await deps.mediaFor?.(ctx.orgId);
      if (!provider)
        throw new ToolError(
          "no_media_provider",
          "No media generation key is configured. Add a fal.ai key in Model keys.",
        );
      const video = await provider.generateVideo({
        prompt: args.prompt,
        durationS: args.duration_s,
      });
      const seconds = video.durationS ?? args.duration_s ?? 5;
      await db.execute(sql`insert into public.usage_ledger (org_id, bot_id, run_id, kind, quantity, cost_usd, model)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${ctx.runId}::uuid, 'media_video_seconds', ${seconds}, ${seconds * MEDIA_PRICES.videoPerSecond}, ${provider.id})`);
      const path = await saveMedia(ctx, video.url, "mp4").catch(() => null);
      return {
        content: `Generated video: ${video.url}${path ? `\nSaved to ~/workspace/${path}` : ""}`,
        preview: path ?? "video generated",
        artifactPath: path,
      };
    },
  });

  return registry;
}
