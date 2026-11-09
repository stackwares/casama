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
import { type ToolContext, ToolError, type ToolRegistry } from "./registry.ts";

export interface AutonomyToolDeps {
  db: Database;
  /** Guarded fetch for outbound requests (private ranges blocked). */
  fetch: typeof fetch;
  notifications?: NotificationService;
  mediaFor?: (orgId: string) => Promise<MediaProvider | null>;
  searchFor?: (orgId: string) => Promise<SearchProvider | null>;
  /** Runs a child run to completion (a child DBOS workflow in the worker). Late-bound. */
  runChild?: (runId: string) => Promise<{ status: string }>;
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
  const [e] = await db.execute<{ text: string | null }>(sql`
    select (select string_agg(p ->> 'text', '') from jsonb_array_elements(payload -> 'content') p where p ->> 'type' = 'text') as text
    from public.run_events where run_id = ${runId}::uuid and type = 'message.completed' order by seq desc limit 1`);
  return e?.text ?? "";
}

async function emit(db: Database, runId: string, type: string, payload: Record<string, unknown>) {
  await db.execute(
    sql`select public.append_run_event(${runId}::uuid, ${type}, ${JSON.stringify(payload)}::jsonb)`,
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
      const [owner] = await db.execute<{ user_id: string | null }>(sql`
        select coalesce(r.created_by, b.created_by) as user_id from public.runs r join public.bots b on b.id = r.bot_id where r.id = ${ctx.runId}::uuid`);
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

  registry.register({
    name: "tasks.create",
    description: "Add a task to the shared task board, optionally assigned to a bot by name.",
    risk: "low",
    schema: z.object({
      title: z.string().min(1).max(300),
      details: z.string().max(10_000).optional(),
      assignee: z.string().max(100).optional(),
    }),
    async execute(args, ctx) {
      const assignee = args.assignee ? await botByRef(ctx.orgId, args.assignee) : undefined;
      if (args.assignee && !assignee)
        throw new ToolError("bot_not_found", `No bot named ${args.assignee}.`);
      const [t] = await db.execute<{ id: string }>(sql`
        insert into public.tasks (org_id, created_by_bot_id, assignee_bot_id, title, details_md, parent_run_id)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${assignee?.id ?? null}::uuid, ${args.title}, ${args.details ?? ""}, ${ctx.runId}::uuid)
        returning id`);
      return { content: `Created task ${t?.id}.`, preview: args.title };
    },
  });

  registry.register({
    name: "tasks.update",
    description:
      "Update a task on the board: status (todo, doing, done, blocked) and an optional result.",
    risk: "low",
    schema: z.object({
      task_id: z.uuid(),
      status: z.enum(["todo", "doing", "done", "blocked"]).optional(),
      result: z.string().max(20_000).optional(),
    }),
    async execute(args, ctx) {
      const rows = await db.execute<{ id: string }>(sql`
        update public.tasks set status = coalesce(${args.status ?? null}, status), result_md = coalesce(${args.result ?? null}, result_md), updated_at = now()
        where id = ${args.task_id}::uuid and org_id = ${ctx.orgId}::uuid returning id`);
      if (!rows.length) throw new ToolError("task_not_found", "No such task.");
      return { content: "Task updated.", preview: args.status ?? "updated" };
    },
  });

  // --- routines -----------------------------------------------------------------

  registry.register({
    name: "routines.create",
    description:
      "Schedule a recurring job for yourself (5-field cron in the user's timezone). Results arrive in a dedicated conversation.",
    risk: "medium",
    schema: z.object({
      name: z.string().min(1).max(120),
      instructions: z.string().min(1).max(10_000),
      schedule_cron: z.string().max(100),
      timezone: z.string().max(64).optional(),
      notify: z.boolean().optional(),
    }),
    async execute(args, ctx) {
      if (!isValidCron(args.schedule_cron))
        throw new ToolError("invalid_cron", "Use a 5-field cron expression like '0 8 * * *'.");
      const [owner] = await db.execute<{ user_id: string | null; timezone: string | null }>(sql`
        select coalesce(r.created_by, b.created_by) as user_id, p.timezone from public.runs r join public.bots b on b.id = r.bot_id
        left join public.profiles p on p.user_id = coalesce(r.created_by, b.created_by) where r.id = ${ctx.runId}::uuid`);
      const tz = args.timezone ?? owner?.timezone ?? "UTC";
      if (!isValidTimezone(tz)) throw new ToolError("invalid_timezone", `Unknown timezone ${tz}.`);
      const next = nextRunAt(args.schedule_cron, tz);
      const [r] = await db.execute<{ id: string }>(sql`
        insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, notify, next_run_at)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${owner?.user_id ?? null}::uuid, ${args.name}, ${args.instructions},
                ${args.schedule_cron}, ${tz}, ${args.notify ?? true}, ${next.toISOString()}::timestamptz) returning id`);
      return {
        content: `Scheduled routine ${r?.id}; next run ${next.toISOString()} (${tz}).`,
        preview: `${args.name} · ${args.schedule_cron}`,
      };
    },
  });

  registry.register({
    name: "routines.update",
    description: "Change or pause one of your routines.",
    risk: "medium",
    schema: z.object({
      routine_id: z.uuid(),
      enabled: z.boolean().optional(),
      schedule_cron: z.string().max(100).optional(),
      instructions: z.string().max(10_000).optional(),
    }),
    async execute(args, ctx) {
      const [r] = await db.execute<{ schedule_cron: string | null; timezone: string }>(sql`
        select schedule_cron, timezone from public.routines where id = ${args.routine_id}::uuid and bot_id = ${ctx.botId}::uuid`);
      if (!r) throw new ToolError("routine_not_found", "No such routine for this bot.");
      if (args.schedule_cron && !isValidCron(args.schedule_cron))
        throw new ToolError("invalid_cron", "Invalid cron expression.");
      const cron = args.schedule_cron ?? r.schedule_cron;
      const next = cron ? nextRunAt(cron, r.timezone).toISOString() : null;
      await db.execute(sql`
        update public.routines set enabled = coalesce(${args.enabled ?? null}, enabled), schedule_cron = ${cron},
          instructions_md = coalesce(${args.instructions ?? null}, instructions_md), next_run_at = ${next}::timestamptz
        where id = ${args.routine_id}::uuid`);
      return { content: "Routine updated.", preview: "updated" };
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
      insert into public.runs (org_id, bot_id, conversation_id, parent_run_id, created_by, trigger, budget)
      values (${ctx.orgId}::uuid, ${opts.botId}::uuid, ${conversationId}::uuid, ${ctx.runId}::uuid, ${parent.created_by}::uuid, ${opts.trigger},
              ${JSON.stringify({ per_run_usd: budget, task: opts.task, tools: opts.tools, timeout_s: opts.timeoutS ?? 600 })}::jsonb)
      returning id`);
    const childId = child?.id as string;
    if (conversationId) {
      await db.execute(sql`insert into public.messages (org_id, conversation_id, role, content, run_id)
        values (${ctx.orgId}::uuid, ${conversationId}::uuid, 'user', ${JSON.stringify([{ type: "text", text: opts.task }])}::jsonb, ${childId}::uuid)`);
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
