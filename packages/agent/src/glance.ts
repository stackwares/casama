/**
 * The glance (D-405, docs/WIDGETS-PLAN.md §8.1, §8.2): one small document of what a person's
 * widgets show, built here from the data behind `/v1/for-you`, the Needs you row, routines,
 * creations, tasks and billing. `GET /v1/glance` serves it to the app and, with a widget key, to
 * the widgets themselves, up to about 70 times a day per widget, so it stays at a handful of
 * queries, all in the person's own session (row-level security decides what they see).
 *
 * It never carries tool arguments, full messages or anything a secret could be in: one line per
 * request, two lines of a bot's last message, a cut brief. When the widget key is private (a Lock
 * Screen, the app lock), the person's own words go too and only counts, names, times and kinds
 * stay (§10).
 */
import { createHash } from "node:crypto";
import type { Glance } from "@casama/contracts";
import { contentKeys, type Database, withUserSession } from "@casama/db";
import { cronWords, nextRunAt } from "@casama/domain";
import { sql } from "drizzle-orm";
import { LIVE_LABELS, liveStepWords } from "./live-runs.ts";
import { plainText } from "./notifications.ts";
import { storedStarters } from "./starters.ts";

/** What billing knows, from the server's billing summary; null or billing off on self-hosted. */
export interface GlanceCreditsSource {
  billing: boolean;
  unlimited: boolean;
  plan: string | null;
  /** The credit balance left. */
  left_usd: number | null;
  daily: { used_usd: number; cap_usd: number; resets_at: string } | null;
}

export interface BuildGlanceOptions {
  userId: string;
  orgId: string;
  /** The widget key's private switch (D-405 §10): counts and general words only. */
  private?: boolean;
  /** Billing's view; unset or null: billing is off on this server. */
  credits?: () => Promise<GlanceCreditsSource | null>;
  now?: Date;
}

/** The contract's limits (packages/contracts/src/glance.ts). */
export const GLANCE_LIMITS = {
  needs: 4,
  bots: 8,
  next: 6,
  routines: 20,
  lately: 3,
  recent: 6,
  tasks: 3,
  starters: 4,
  runs: 3,
  briefChars: 600,
} as const;

/** A string cut to [max] characters with "…", never splitting a surrogate pair. */
export function glanceCut(s: string | null | undefined, max: number): string {
  const t = (s ?? "").replace(/\s+/g, " ").trim();
  if (t.length <= max) return t;
  let end = max - 1;
  const code = t.charCodeAt(end - 1);
  if (code >= 0xd800 && code <= 0xdbff) end -= 1;
  return `${t.slice(0, end).trimEnd()}…`;
}

/** The text parts of a message's content (opened if sealed), as plain text on one line. */
function messageText(content: unknown): string {
  const opened = contentKeys.open(content);
  if (!Array.isArray(opened)) return "";
  const text = opened
    .filter((p): p is { type: string; text: string } => {
      const part = p as { type?: unknown; text?: unknown } | null;
      return !!part && part.type === "text" && typeof part.text === "string";
    })
    .map((p) => p.text)
    .join(" ");
  return plainText(text).replace(/\s+/g, " ").trim();
}

const iso = (v: string | Date) => (v instanceof Date ? v : new Date(v)).toISOString();
const isoOrNull = (v: string | Date | null | undefined) => (v ? iso(v) : null);
const money = (n: number) => Math.round(n * 10_000) / 10_000;
const avatar = (a: string | null | undefined) => (a && a.length <= 64 ? a : "");

const CREATION_KINDS = new Set(["page", "image", "video", "audio", "document", "file"]);
const TASK_STATUSES = new Set(["todo", "in_progress", "in_review", "blocked", "done"]);
const BOT_STATUSES = new Set(["idle", "working", "waiting", "disabled"]);

/** The glance's version: a hash of everything in it but when it was made. */
export function glanceVersion(g: Omit<Glance, "version" | "made_at">): string {
  return createHash("sha256").update(JSON.stringify(g)).digest("base64url").slice(0, 22);
}

/** Builds the glance for one person in one workspace. */
export async function buildGlance(db: Database, o: BuildGlanceOptions): Promise<Glance> {
  const now = o.now ?? new Date();
  const me = o.userId;
  const org = o.orgId;
  const dayStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const monthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
  const credits = (await o.credits?.().catch(() => null)) ?? null;
  const billing = credits?.billing === true;
  const claims = { sub: me, role: "authenticated" };

  const q = await withUserSession(db, claims, async (tx) => {
    // The person, their check-ins, the board's counts, today's and this month's spend.
    const [misc] = await tx.execute<{
      timezone: string | null;
      push_prefs: { hide_reply_text?: boolean } | null;
      skills: number;
      task_counts: Record<string, number> | null;
      checkins: Array<{
        bot_id: string;
        brief_time: string;
        name: string;
        avatar: string | null;
      }> | null;
      today: number;
      month: number;
    }>(sql`
      select
        (select p.timezone from public.profiles p where p.user_id = ${me}::uuid) as timezone,
        (select p.push_prefs from public.profiles p where p.user_id = ${me}::uuid) as push_prefs,
        (select count(*)::int from public.skill_proposals sp
           where sp.org_id = ${org}::uuid and sp.status = 'pending') as skills,
        (select json_object_agg(s.status, s.n) from (
           select t.status, count(*)::int as n from public.tasks t
           where t.org_id = ${org}::uuid and t.status <> 'done' group by t.status) s) as task_counts,
        (select json_agg(json_build_object('bot_id', ck.bot_id, 'brief_time', ck.brief_time,
                  'name', b.name, 'avatar', b.avatar_url) order by b.sort_key, b.created_at)
           from public.bot_checkins ck join public.bots b on b.id = ck.bot_id
           where b.org_id = ${org}::uuid and b.archived_at is null
             and ck.user_id = ${me}::uuid and ck.enabled) as checkins,
        u.today, u.month
      from (
        select
          coalesce(sum(cost_usd) filter (where created_at >= ${dayStart.toISOString()}::timestamptz), 0)::float8 as today,
          coalesce(sum(cost_usd), 0)::float8 as month
        from public.usage_ledger
        where org_id = ${org}::uuid and created_at >= ${monthStart.toISOString()}::timestamptz
          ${billing ? sql`and billable` : sql``}
      ) u`);

    // Needs you: what the Chats tab's row lists (approvals, takeovers, suggestions), blocked
    // bots first, newest first; then suggestions, urgent first.
    const needs = await tx.execute<{
      kind: "approval" | "takeover" | "suggestion";
      id: string;
      bot_id: string;
      text: string | null;
      risk: string | null;
      urgent: boolean;
      created_at: string;
      computer_id: string | null;
      bot: string;
      bot_avatar: string | null;
      total: number;
    }>(sql`
      with n as (
        select 'approval'::text as kind, a.id, a.bot_id, a.summary as text, a.risk, false as urgent,
               a.created_at, 0 as grp, null::uuid as computer_id
        from public.approvals a
        where a.org_id = ${org}::uuid and a.status = 'pending' and a.expires_at > now()
        union all
        select 'takeover', t.id, t.bot_id, t.reason, null, false, t.created_at, 0, t.computer_id
        from public.takeover_requests t
        where t.org_id = ${org}::uuid and t.status in ('pending', 'taken') and t.expires_at > now()
          and exists (select 1 from public.runs r where r.id = t.run_id
                      and r.status not in ('completed', 'failed', 'cancelled'))
        union all
        select 'suggestion', s.id, s.bot_id, s.title, null, s.urgency = 'urgent', s.created_at, 1, null
        from public.suggestions s
        where s.org_id = ${org}::uuid and s.user_id = ${me}::uuid and s.status = 'pending'
          and s.expires_at > now()
      )
      select n.kind, n.id, n.bot_id, n.text, n.risk, n.urgent, n.created_at, n.computer_id,
             b.name as bot, b.avatar_url as bot_avatar, (count(*) over ())::int as total
      from n join public.bots b on b.id = n.bot_id
      order by n.grp, n.urgent desc, n.created_at desc
      limit ${GLANCE_LIMITS.needs}`);

    // The person's bots in their order, each with when it last finished, its last message and,
    // while it works, its latest step.
    const bots = await tx.execute<{
      id: string;
      name: string;
      avatar_url: string | null;
      status: string;
      busy_at: string | null;
      last_items: Array<{ content: unknown; at: string }> | null;
      step_type: string | null;
      step_payload: unknown;
    }>(sql`
      select b.id, b.name, b.avatar_url, b.status, fin.ended_at as busy_at, last.items as last_items,
             step.type as step_type, step.payload as step_payload
      from public.bots b
      left join lateral (
        select r.ended_at from public.runs r
        where r.bot_id = b.id and r.ended_at is not null and r.parent_run_id is null
        order by r.created_at desc limit 1) fin on true
      left join lateral (
        select c.id from public.conversations c
        where c.bot_id = b.id and c.kind = 'direct' and c.last_message_at is not null
        order by c.last_message_at desc limit 1) lc on true
      left join lateral (
        select json_agg(json_build_object('content', m.content, 'at', m.created_at)
                        order by m.created_at desc) as items
        from (select content, created_at from public.messages
              where conversation_id = lc.id and role = 'assistant'
              order by created_at desc limit 3) m) last on true
      left join lateral (
        select e.type, e.payload from public.runs r
        cross join lateral (
          select type, payload from public.run_events
          where run_id = r.id and type in ('tool.started', 'message.delta')
          order by seq desc limit 1) e
        where b.status = 'working' and r.bot_id = b.id and r.status = 'running'
        order by r.created_at desc limit 1) step on true
      where b.org_id = ${org}::uuid and b.archived_at is null
      order by b.sort_key, b.created_at
      limit ${GLANCE_LIMITS.bots}`);

    // Up next: scheduled routines in the order they will run (check-ins have their own place).
    const next = await tx.execute<{
      id: string;
      bot_id: string;
      name: string;
      schedule_cron: string | null;
      next_run_at: string;
      enabled: boolean;
      bot: string;
      bot_avatar: string | null;
    }>(sql`
      select rt.id, rt.bot_id, rt.name, rt.schedule_cron, rt.next_run_at, rt.enabled,
             b.name as bot, b.avatar_url as bot_avatar
      from public.routines rt join public.bots b on b.id = rt.bot_id and b.archived_at is null
      where rt.org_id = ${org}::uuid and rt.enabled and rt.kind = 'task' and rt.next_run_at is not null
      order by rt.next_run_at limit ${GLANCE_LIMITS.next}`);

    // Every routine, for widget pickers: the person's own first, then on, then by name.
    const routines = await tx.execute<{
      id: string;
      bot_id: string;
      name: string;
      enabled: boolean;
      bot: string;
    }>(sql`
      select rt.id, rt.bot_id, rt.name, rt.enabled, b.name as bot
      from public.routines rt join public.bots b on b.id = rt.bot_id and b.archived_at is null
      where rt.org_id = ${org}::uuid and rt.kind = 'task'
      order by (rt.created_by = ${me}::uuid) desc, rt.enabled desc, lower(rt.name), rt.id
      limit ${GLANCE_LIMITS.routines}`);

    // The latest brief from the last 36 hours, for this person's check-ins (as /v1/for-you).
    const [brief] = await tx.execute<{
      bot_id: string;
      conversation_id: string;
      content: unknown;
      created_at: string;
    }>(sql`
      select rt.bot_id, m.conversation_id, m.content, m.created_at
      from public.routines rt
      join public.bot_checkins ck on ck.bot_id = rt.bot_id and ck.enabled and ck.user_id = ${me}::uuid
      join public.runs r on r.routine_id = rt.id
      join public.messages m on m.run_id = r.id and m.role = 'assistant'
      where rt.org_id = ${org}::uuid and rt.kind = 'brief' and m.created_at > now() - interval '36 hours'
      order by m.created_at desc limit 1`);

    // What bots last finished for this person: its creation, its routine, or a reply.
    const lately = await tx.execute<{
      bot_id: string;
      conversation_id: string | null;
      conv_kind: string | null;
      ended_at: string;
      bot: string;
      bot_avatar: string | null;
      routine: string | null;
      creation_id: string | null;
      creation_title: string | null;
    }>(sql`
      select r.bot_id, r.conversation_id, c.kind as conv_kind, r.ended_at, b.name as bot,
             b.avatar_url as bot_avatar, rt.name as routine, cr.id as creation_id,
             cr.title as creation_title
      from public.runs r
      join public.bots b on b.id = r.bot_id
      left join public.routines rt on rt.id = r.routine_id
      left join public.conversations c on c.id = r.conversation_id
      left join lateral (
        select x.id, x.title from public.creations x
        where x.run_id = r.id and x.deleted_at is null order by x.created_at desc limit 1) cr on true
      where r.org_id = ${org}::uuid and r.status = 'completed' and r.parent_run_id is null
        and r.ended_at is not null and r.created_at > now() - interval '14 days'
        and (r.created_by = ${me}::uuid or rt.created_by = ${me}::uuid)
        and (rt.id is null or rt.kind <> 'scan')
      order by r.ended_at desc limit ${GLANCE_LIMITS.lately}`);

    const recent = await tx.execute<{
      id: string;
      kind: string;
      title: string;
      cover_key: string | null;
      media_id: string | null;
      blob_key: string | null;
      version: number;
      created_at: string;
      bot: string | null;
    }>(sql`
      select c.id, c.kind, c.title, c.cover_key, c.media_id, c.blob_key, c.version, c.created_at,
             b.name as bot
      from public.creations c left join public.bots b on b.id = c.bot_id
      where c.org_id = ${org}::uuid and c.deleted_at is null
      order by c.created_at desc limit ${GLANCE_LIMITS.recent}`);

    // The board's top rows: In review first, since those wait on a person.
    const tasks = await tx.execute<{
      id: string;
      title: string;
      status: string;
      bot: string | null;
    }>(sql`
      select t.id, t.title, t.status, b.name as bot
      from public.tasks t left join public.bots b on b.id = t.assignee_bot_id
      where t.org_id = ${org}::uuid and t.status in ('in_review', 'blocked', 'in_progress', 'todo')
      order by case t.status when 'in_review' then 0 when 'blocked' then 1
                             when 'in_progress' then 2 else 3 end, t.updated_at desc
      limit ${GLANCE_LIMITS.tasks}`);

    // Live runs the person started by hand (D-410): the island's own (live-runs.ts PERSON_TRIGGERS),
    // top-level only, newest first. A run left unfinished for half a day is not live any more.
    const runs = await tx.execute<{
      id: string;
      bot_id: string;
      bot: string;
      bot_avatar: string | null;
      status: string;
      conversation_id: string | null;
      conv_kind: string | null;
      started_at: string | null;
      created_at: string;
      steps: number;
      step_type: string | null;
      step_payload: unknown;
      takeover: boolean;
      approval_id: string | null;
      approval_risk: string | null;
      approval_tool: string | null;
    }>(sql`
      select r.id, r.bot_id, b.name as bot, b.avatar_url as bot_avatar, r.status, r.conversation_id,
             c.kind as conv_kind, r.started_at, r.created_at,
             (select count(*)::int from public.run_events e
               where e.run_id = r.id and e.type = 'tool.started') as steps,
             ev.type as step_type, ev.payload as step_payload,
             exists (select 1 from public.takeover_requests t where t.run_id = r.id
                     and t.status in ('pending', 'taken') and t.expires_at > now()) as takeover,
             ap.id as approval_id, ap.risk as approval_risk, ap.tool_name as approval_tool
      from public.runs r
      join public.bots b on b.id = r.bot_id
      left join public.conversations c on c.id = r.conversation_id
      left join lateral (
        select e.type, e.payload from public.run_events e
        where e.run_id = r.id and e.type in ('tool.started', 'message.delta')
        order by e.seq desc limit 1) ev on true
      left join lateral (
        select a.id, a.risk, a.tool_name from public.approvals a
        where a.run_id = r.id and a.status = 'pending' and a.expires_at > now()
        order by a.created_at desc limit 1) ap on true
      where r.org_id = ${org}::uuid and r.created_by = ${me}::uuid and r.parent_run_id is null
        and r.trigger in ('chat', 'mention', 'voice', 'replay', 'teach')
        and r.status in ('queued', 'running', 'waiting_approval', 'waiting_takeover')
        and r.created_at > now() - interval '12 hours'
      order by r.created_at desc limit ${GLANCE_LIMITS.runs}`);

    return { misc, needs, bots, next, routines, brief, lately, recent, tasks, runs };
  });

  const priv = o.private === true;
  const hideReplies = q.misc?.push_prefs?.hide_reply_text === true;
  const timezone = q.misc?.timezone || "UTC";
  const words = (s: string | null | undefined, max: number) => (priv ? "" : glanceCut(s, max));

  const needsItems: Glance["needs"]["items"] = q.needs.map((n) => ({
    kind: n.kind,
    id: n.id,
    bot_id: n.bot_id,
    bot: glanceCut(n.bot, 80),
    bot_avatar: avatar(n.bot_avatar),
    text: words(n.text, 140),
    risk:
      n.kind === "approval" && (n.risk === "low" || n.risk === "medium" || n.risk === "high")
        ? n.risk
        : null,
    urgent: n.kind === "suggestion" && n.urgent === true,
    created_at: iso(n.created_at),
    link:
      n.kind === "approval"
        ? `/approvals/${n.id}`
        : n.kind === "takeover"
          ? `/computer/live?c=${n.computer_id}&takeover=${n.id}`
          : // Do it is an action; the row opens where suggestions are shown.
            "/inbox?tab=0",
  }));
  // Skill ideas count in the Chats tab's Needs you row too (D-253), so the two numbers agree.
  const needsCount = (q.needs[0]?.total ?? 0) + (q.misc?.skills ?? 0);

  const bots: Glance["bots"] = q.bots.map((b) => {
    const status = (BOT_STATUSES.has(b.status) ? b.status : "idle") as Glance["bots"][0]["status"];
    let last: { text: string; at: string } | null = null;
    for (const m of b.last_items ?? []) {
      const text = messageText(m.content);
      if (text) {
        last = { text, at: m.at };
        break;
      }
    }
    let step: string | null = null;
    if (status === "working") {
      const payload = contentKeys.open(b.step_payload) as { tool?: unknown } | null;
      step =
        b.step_type === "tool.started"
          ? liveStepWords(String(payload?.tool ?? ""))
          : b.step_type === "message.delta"
            ? LIVE_LABELS.writing
            : LIVE_LABELS.thinking;
    }
    return {
      id: b.id,
      name: glanceCut(b.name, 80),
      avatar: avatar(b.avatar_url),
      status,
      step: priv || !step ? null : glanceCut(step, 80),
      last_text: priv || hideReplies || !last ? null : glanceCut(last.text, 160),
      last_at: last ? iso(last.at) : null,
      busy_at: isoOrNull(b.busy_at),
      link: `/bots/${b.id}/chat`,
    };
  });

  // The person's live runs (D-410) in the island's words, so the watch and the Lock Screen agree.
  const runs: Glance["runs"] = q.runs.map((r) => {
    const phase: Glance["runs"][0]["phase"] =
      r.approval_id || r.status === "waiting_approval"
        ? "needs_ok"
        : r.takeover || r.status === "waiting_takeover"
          ? "take_over"
          : "working";
    const step =
      phase === "needs_ok"
        ? r.approval_tool
          ? liveStepWords(r.approval_tool)
          : LIVE_LABELS.needsOk
        : phase === "take_over"
          ? LIVE_LABELS.takeOver
          : r.step_type === "tool.started"
            ? liveStepWords(
                String((contentKeys.open(r.step_payload) as { tool?: unknown } | null)?.tool ?? ""),
              )
            : r.step_type === "message.delta"
              ? LIVE_LABELS.writing
              : LIVE_LABELS.thinking;
    const risk = r.approval_risk;
    return {
      id: r.id,
      bot_id: r.bot_id,
      bot: glanceCut(r.bot, 80),
      bot_avatar: avatar(r.bot_avatar),
      phase,
      step: priv ? "" : glanceCut(step, 80),
      steps: r.steps,
      started_at: iso(r.started_at ?? r.created_at),
      approval_id: r.approval_id,
      risk: risk === "low" || risk === "medium" || risk === "high" ? risk : null,
      link: r.approval_id
        ? `/approvals/${r.approval_id}`
        : !r.conversation_id
          ? `/bots/${r.bot_id}/chat`
          : r.conv_kind === "group"
            ? `/groups/${r.conversation_id}`
            : `/bots/${r.bot_id}/chat?c=${r.conversation_id}`,
    };
  });

  const next: Glance["next"] = q.next.map((r) => ({
    id: r.id,
    bot_id: r.bot_id,
    name: words(r.name, 80),
    bot: glanceCut(r.bot, 80),
    bot_avatar: avatar(r.bot_avatar),
    next_at: isoOrNull(r.next_run_at),
    every: r.schedule_cron ? glanceCut(cronWords(r.schedule_cron), 60) : "",
    enabled: r.enabled,
    link: `/bots/${r.bot_id}/routines`,
  }));

  const routines: Glance["routines"] = q.routines.map((r) => ({
    id: r.id,
    bot_id: r.bot_id,
    name: words(r.name, 80),
    bot: glanceCut(r.bot, 80),
    enabled: r.enabled,
  }));

  // The brief: today's if it came, and when the next one is due either way.
  const checkins = q.misc?.checkins ?? [];
  const briefBot = q.brief
    ? checkins.find((c) => c.bot_id === q.brief?.bot_id)
    : (checkins[0] ?? null);
  let brief: Glance["brief"] = null;
  if (briefBot || q.brief) {
    const botId = q.brief?.bot_id ?? (briefBot?.bot_id as string);
    let nextAt: string | null = null;
    const time = /^(\d{2}):(\d{2})$/.exec(briefBot?.brief_time ?? "");
    if (time) {
      try {
        nextAt = nextRunAt(
          `${Number(time[2])} ${Number(time[1])} * * *`,
          timezone,
          now,
        ).toISOString();
      } catch {
        nextAt = null;
      }
    }
    const text = q.brief ? glanceCut(messageText(q.brief.content), GLANCE_LIMITS.briefChars) : "";
    const botRow = briefBot ?? q.bots.find((b) => b.id === botId);
    brief = {
      bot_id: botId,
      bot: glanceCut(briefBot?.name ?? (botRow as { name?: string } | undefined)?.name ?? "", 80),
      bot_avatar: avatar(
        briefBot?.avatar ?? (botRow as { avatar_url?: string | null } | undefined)?.avatar_url,
      ),
      text: priv || !q.brief ? null : text,
      at: q.brief ? iso(q.brief.created_at) : null,
      next_at: nextAt,
      link: q.brief ? `/bots/${botId}/chat?c=${q.brief.conversation_id}` : `/bots/${botId}/chat`,
    };
  }

  const lately: Glance["lately"] = q.lately.map((r) => ({
    bot_id: r.bot_id,
    bot: glanceCut(r.bot, 80),
    bot_avatar: avatar(r.bot_avatar),
    title: priv ? "" : glanceCut(r.creation_title ?? r.routine ?? "Replied", 100),
    at: iso(r.ended_at),
    link: r.creation_id
      ? `/library/${r.creation_id}`
      : !r.conversation_id
        ? `/bots/${r.bot_id}/chat`
        : r.conv_kind === "group"
          ? `/groups/${r.conversation_id}`
          : `/bots/${r.bot_id}/chat?c=${r.conversation_id}`,
  }));

  const recent: Glance["recent"] = q.recent.map((c) => ({
    id: c.id,
    kind: (CREATION_KINDS.has(c.kind) ? c.kind : "file") as Glance["recent"][0]["kind"],
    title: words(c.title, 100),
    bot: c.bot ? glanceCut(c.bot, 80) : null,
    // As the Library decides it (creations.ts): pictures are their own cover, videos get a frame.
    has_cover:
      !!c.cover_key ||
      (!!c.media_id && (c.kind === "image" || c.kind === "video")) ||
      (!!c.blob_key && c.kind === "image"),
    version: c.version,
    at: iso(c.created_at),
    link: `/library/${c.id}`,
  }));

  const counts = q.misc?.task_counts ?? {};
  const tasks: Glance["tasks"] = {
    counts: {
      todo: counts.todo ?? 0,
      in_progress: counts.in_progress ?? 0,
      in_review: counts.in_review ?? 0,
      blocked: counts.blocked ?? 0,
    },
    items: q.tasks.map((t) => ({
      id: t.id,
      title: words(t.title, 100),
      status: (TASK_STATUSES.has(t.status)
        ? t.status
        : "todo") as Glance["tasks"]["items"][0]["status"],
      bot: t.bot ? glanceCut(t.bot, 80) : null,
      link: "/tasks",
    })),
  };

  const today = money(q.misc?.today ?? 0);
  const month = money(q.misc?.month ?? 0);
  const left = credits?.left_usd ?? null;
  const unlimited = !billing || credits?.unlimited === true;
  const creditsOut: Glance["credits"] = {
    billing,
    unlimited,
    plan: billing && credits?.plan ? glanceCut(credits.plan, 40) : null,
    used_share:
      billing && !unlimited && left !== null && month + Math.max(0, left) > 0
        ? Math.min(1, Math.max(0, money(month / (month + Math.max(0, left)))))
        : null,
    left_usd: billing && left !== null ? money(left) : null,
    today_usd: today,
    month_usd: month,
    daily_cap_usd: billing && credits?.daily ? money(credits.daily.cap_usd) : null,
    daily_used_usd: billing && credits?.daily ? money(credits.daily.used_usd) : null,
    resets_at: billing && credits?.daily ? iso(credits.daily.resets_at) : null,
  };

  // The Ask widget's starters: the default bot's (the first in the person's order, as the app's
  // quick ask picks it). They are written from the person's own words, so private hides them.
  let starters: Glance["starters"] = [];
  const firstBot = q.bots[0];
  if (firstBot && !priv) {
    const saved = await storedStarters(db, me, firstBot.id).catch(() => null);
    starters = (saved?.items ?? [])
      .filter((s) => s && typeof s.text === "string" && s.text.trim())
      .slice(0, GLANCE_LIMITS.starters)
      .map((s) => ({ emoji: glanceCut(s.emoji ?? "", 16), text: glanceCut(s.text, 120) }));
  }

  const body: Omit<Glance, "version" | "made_at"> = {
    org_id: org,
    needs: { count: needsCount, items: needsItems },
    bots,
    runs,
    next,
    routines,
    brief,
    lately,
    recent,
    tasks,
    credits: creditsOut,
    starters,
    flags: { private: priv, hide_reply_text: hideReplies },
  };
  return { version: glanceVersion(body), made_at: now.toISOString(), ...body };
}
