/**
 * Casama on the wrist (D-410, docs/WATCH-PLAN.md §6.1, §8.3, §8.4): the words a watch shows, built
 * here so both watch apps show the same thing and never work out a risk, a step or a summary
 * themselves.
 *
 * - A request: what it wants in everyday words, up to three short detail lines for tools people
 *   know (an email, a message, a payment, a calendar event), and whether this watch may allow it.
 *   Never a secret, a token or raw arguments.
 * - A chat: the last few messages as plain text, cut to fit; cards, pages and files as one line.
 * - A run: its whole state now, in the island's words (live-runs.ts), so the watch, the Live
 *   Activity and the Android notification agree.
 *
 * Everything is read in the person's own session: row-level security decides what they see.
 * Private (Show details off) keeps counts, names, kinds and times and drops the person's words.
 */
import type {
  WatchApproval,
  WatchChat,
  WatchMessage,
  WatchPrefs,
  WatchRun,
} from "@casama/contracts";
import { contentKeys, type Database, withUserSession } from "@casama/db";
import {
  isPaymentTool,
  WATCH_QUICK_REPLIES,
  type WatchAllowLevel,
  watchAllowance,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import { LIVE_LABELS, liveStepWords } from "./live-runs.ts";
import { plainText } from "./notifications.ts";

/** The contract's limits (packages/contracts/src/watch.ts). */
export const WATCH_LIMITS = {
  messages: 12,
  latestChars: 1200,
  olderChars: 300,
  attachments: 3,
  titleChars: 140,
  detailChars: 120,
  details: 3,
  botChars: 80,
  stepChars: 80,
} as const;

/** The words for a run the person stopped (the island has none: its stopped activity leaves). */
export const WATCH_STOPPED = "Stopped";

const iso = (v: string | Date) => (v instanceof Date ? v : new Date(v)).toISOString();
const avatar = (a: string | null | undefined) => (a && a.length <= 64 ? a : "");

/** One line, cut to [max] with "…" at a word, never splitting a surrogate pair. */
export function watchLine(s: string | null | undefined, max: number): string {
  return watchText(s, max, false).text;
}

/**
 * Plain text cut to [max] characters with "…": at a word when one is near, never inside a
 * surrogate pair. Paragraphs stay when [multiline]; otherwise everything is one line.
 */
export function watchText(
  s: string | null | undefined,
  max: number,
  multiline = true,
): { text: string; cut: boolean } {
  let t = (s ?? "").replace(/\r/g, "");
  t = multiline
    ? t
        .split("\n")
        .map((l) => l.replace(/[ \t]+/g, " ").trim())
        .join("\n")
        .replace(/\n{3,}/g, "\n\n")
        .trim()
    : t.replace(/\s+/g, " ").trim();
  if (t.length <= max) return { text: t, cut: false };
  let end = max - 1;
  const code = t.charCodeAt(end - 1);
  if (code >= 0xd800 && code <= 0xdbff) end -= 1;
  let head = t.slice(0, end);
  const space = head.search(/\s\S*$/);
  if (space > max * 0.6) head = head.slice(0, space);
  return { text: `${head.replace(/[\s,;:–—-]+$/, "")}…`, cut: true };
}

// --- requests -------------------------------------------------------------------------------

/** Argument names that could hold something secret: never shown, whatever their value. */
const SECRET_NAME =
  /pass|secret|token|api[_-]?key|private|auth|cookie|session|otp|totp|cvv|cvc|pin$|card_?number|iban|ssn|credential/i;

/** A value that reads like a key or a token (long, no spaces), or one the redactor replaced. */
const looksSecret = (v: string) =>
  /^[A-Za-z0-9_\-+/=.:]{32,}$/.test(v) || /redacted|\*{3,}|•{3,}/i.test(v);

/** A short, safe string from an argument: strings and lists of strings only, never JSON. */
function arg(args: Record<string, unknown>, ...names: string[]): string | null {
  for (const n of names) {
    if (SECRET_NAME.test(n)) continue;
    const v = args[n];
    let s: string | null = null;
    if (typeof v === "string") s = v;
    else if (typeof v === "number" && Number.isFinite(v)) s = String(v);
    else if (Array.isArray(v)) {
      const parts = v.filter((x): x is string => typeof x === "string" && !looksSecret(x));
      if (parts.length) s = parts.join(", ");
    }
    if (s === null) continue;
    const t = plainText(s).replace(/\s+/g, " ").trim();
    if (t && !looksSecret(t)) return t;
  }
  return null;
}

/** "Dana Cruz <dana@example.com>" reads as Dana Cruz; a bare address stays as it is. */
function personName(to: string) {
  const first = to.split(/,\s*/)[0] ?? to;
  const m = /^\s*"?([^"<]+?)"?\s*<[^>]+>\s*$/.exec(first);
  const name = (m ? m[1] : first)?.trim() ?? to;
  return to.includes(",") ? `${name} and others` : name;
}

/** The first line of a body that has words in it. */
function firstLine(s: string | null) {
  if (!s) return null;
  const line = plainText(s)
    .split(/\n+/)
    .map((l) => l.trim())
    .find((l) => /[\p{L}\p{N}]/u.test(l));
  return line ?? null;
}

function money(amount: string | null, currency: string | null) {
  if (!amount) return null;
  const n = Number(amount);
  if (!Number.isFinite(n)) return amount;
  const c = (currency ?? "USD").toUpperCase();
  try {
    return new Intl.NumberFormat("en-US", { style: "currency", currency: c }).format(n);
  } catch {
    return `${n.toFixed(2)} ${c}`;
  }
}

type Kind = "email" | "message" | "payment" | "calendar" | null;

/** Which well-known kind of action a tool call is, from its name (and channel for channel.send). */
function toolKind(tool: string, args: Record<string, unknown>): Kind {
  const t = tool.toLowerCase();
  if (isPaymentTool(t)) return "payment";
  if (t === "channel.send")
    return /mail/i.test(String(args.channel ?? "")) || typeof args.subject === "string"
      ? "email"
      : "message";
  if (/(gmail|outlook|mail).*(send|reply|draft|forward)|(send|reply|forward).*(e?mail)/.test(t))
    return "email";
  if (/calendar|event/.test(t) && /(create|add|insert|quick|update|schedule|book)/.test(t))
    return "calendar";
  if (
    /(slack|telegram|whatsapp|discord|teams|sms|imessage|signal|messenger).*(send|post|reply)|(send|post).*message/.test(
      t,
    )
  )
    return "message";
  return null;
}

/**
 * What a request wants, in everyday words, for tools people know; null for the rest (the
 * approval's own summary is used then).
 */
export function approvalTitle(tool: string, args: Record<string, unknown>): string | null {
  const a = args ?? {};
  switch (toolKind(tool, a)) {
    case "email": {
      const to = arg(a, "to", "recipient_email", "recipient", "to_email", "recipients", "email");
      return to ? `Send an email to ${personName(to)}` : "Send an email";
    }
    case "message": {
      const to = arg(a, "to", "recipient", "channel_name", "chat", "user", "channel");
      return to ? `Send a message to ${personName(to)}` : "Send a message";
    }
    case "payment": {
      const amount = money(arg(a, "amount"), arg(a, "currency"));
      const payee = arg(a, "merchant", "payee", "to");
      if (amount && payee) return `Pay ${amount} to ${payee}`;
      return amount ? `Pay ${amount}` : "Make a payment";
    }
    case "calendar": {
      const title = arg(a, "summary", "title", "event_name", "name");
      return title ? `Add an event: ${title}` : "Add a calendar event";
    }
    default:
      return null;
  }
}

/** Up to three short lines about a request for tools people know; none for the rest. */
export function approvalDetails(tool: string, args: Record<string, unknown>): string[] {
  const a = args ?? {};
  const out: Array<string | null> = [];
  switch (toolKind(tool, a)) {
    case "email": {
      const to = arg(a, "to", "recipient_email", "recipient", "to_email", "recipients", "email");
      const subject = arg(a, "subject");
      out.push(
        to ? `To: ${to}` : null,
        subject ? `Subject: ${subject}` : null,
        firstLine(typeof a.body === "string" ? a.body : arg(a, "text", "message", "content")),
      );
      break;
    }
    case "message": {
      const to = arg(a, "to", "recipient", "channel_name", "chat", "user");
      const via = tool === "channel.send" ? arg(a, "channel") : null;
      out.push(
        to ? `To: ${to}` : null,
        via ? `Via: ${via}` : null,
        firstLine(typeof a.text === "string" ? a.text : arg(a, "message", "content", "body")),
      );
      break;
    }
    case "payment":
      out.push(arg(a, "reason", "description", "memo"));
      break;
    case "calendar": {
      const when = arg(a, "start", "start_time", "start_datetime", "when", "date", "time");
      const who = arg(a, "attendees", "guests", "invitees");
      const where = arg(a, "location", "where");
      out.push(
        when ? `When: ${when}` : null,
        who ? `With: ${who}` : null,
        where ? `Where: ${where}` : null,
      );
      break;
    }
  }
  return out
    .filter((l): l is string => !!l)
    .slice(0, WATCH_LIMITS.details)
    .map((l) => watchLine(l, WATCH_LIMITS.detailChars));
}

/** A request as the database holds it, with what the watch needs to decide. */
export type WatchApprovalRow = {
  id: string;
  run_id: string;
  bot_id: string;
  org_id: string;
  bot: string;
  bot_avatar: string | null;
  status: string;
  summary: string;
  tool_name: string;
  args_redacted: unknown;
  risk: string;
  created_at: string | Date;
  expires_at: string | Date;
  /** The person started the run or is an owner or admin of its workspace. */
  is_yours: boolean;
};

export interface WatchViewOptions {
  /** Show details off: the person's words go; bot, risk, kind and times stay. */
  private: boolean;
  level: WatchAllowLevel;
  workspaceOff?: boolean;
}

const RISKS = new Set(["low", "medium", "high"]);
const APPROVAL_STATUSES = new Set(["pending", "approved", "denied", "expired"]);

/** A request as a watch shows it. */
export function watchApprovalView(row: WatchApprovalRow, o: WatchViewOptions): WatchApproval {
  const risk = (RISKS.has(row.risk) ? row.risk : "high") as WatchApproval["risk"];
  const payment = isPaymentTool(row.tool_name);
  const args =
    row.args_redacted && typeof row.args_redacted === "object" && !Array.isArray(row.args_redacted)
      ? (row.args_redacted as Record<string, unknown>)
      : {};
  const expired =
    row.status === "pending" && new Date(row.expires_at).getTime() <= Date.now() ? "expired" : null;
  const allowance = watchAllowance({
    risk,
    payment,
    level: o.level,
    workspaceOff: o.workspaceOff,
    isYours: row.is_yours,
    tool: row.tool_name,
  });
  const summary = row.summary.replace(new RegExp(`^${escapeRe(row.bot)} wants to run `), "");
  return {
    id: row.id,
    run_id: row.run_id,
    bot_id: row.bot_id,
    bot: watchLine(row.bot, WATCH_LIMITS.botChars),
    bot_avatar: avatar(row.bot_avatar),
    status: (expired ??
      (APPROVAL_STATUSES.has(row.status) ? row.status : "expired")) as WatchApproval["status"],
    title: o.private
      ? ""
      : watchLine(approvalTitle(row.tool_name, args) ?? summary, WATCH_LIMITS.titleChars),
    details: o.private ? [] : approvalDetails(row.tool_name, args),
    risk,
    payment,
    can_allow: allowance.can_allow,
    why_phone: allowance.why_phone,
    created_at: iso(row.created_at),
    expires_at: iso(row.expires_at),
    link: `/approvals/${row.id}`,
  };
}

const escapeRe = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

/** The person's watch settings; the defaults when they never changed them. */
export async function watchPrefsFor(db: Database, userId: string): Promise<WatchPrefs> {
  const [p] = await db.execute<{
    allow: string;
    show_details: boolean;
    quick_replies: string[] | null;
  }>(
    sql`select allow, show_details, quick_replies from public.watch_prefs where user_id = ${userId}::uuid`,
  );
  return {
    allow: (p?.allow === "low" || p?.allow === "none" ? p.allow : "medium") as WatchAllowLevel,
    show_details: p?.show_details ?? true,
    quick_replies: p?.quick_replies?.length ? p.quick_replies : [...WATCH_QUICK_REPLIES],
  };
}

type Tx = Parameters<Parameters<typeof withUserSession>[2]>[0];

const APPROVAL_COLUMNS = sql`a.id, a.run_id, a.bot_id, a.org_id, b.name as bot, b.avatar_url as bot_avatar,
  a.status, a.summary, a.tool_name, a.args_redacted, a.risk, a.created_at, a.expires_at,
  (r.created_by = (select auth.uid()) or public.has_role(a.org_id, 'admin')) as is_yours`;

async function approvalRow(tx: Tx, where: ReturnType<typeof sql>) {
  const [row] = await tx.execute<WatchApprovalRow>(sql`
    select ${APPROVAL_COLUMNS}
    from public.approvals a
    join public.bots b on b.id = a.bot_id
    join public.runs r on r.id = a.run_id
    where ${where}
    order by a.created_at desc limit 1`);
  return row ?? null;
}

export interface WatchReadOptions {
  userId: string;
  /** A watch reads only its own workspace; unset for the person's session. */
  orgId?: string | null;
  private: boolean;
  level: WatchAllowLevel;
  workspaceOff?: boolean;
}

/** A request as this watch shows it, or null when the person can't see it (or it's elsewhere). */
export async function loadWatchApproval(
  db: Database,
  id: string,
  o: WatchReadOptions,
): Promise<(WatchApproval & { org_id: string }) | null> {
  const row = await withUserSession(db, { sub: o.userId, role: "authenticated" }, (tx) =>
    approvalRow(tx, sql`a.id = ${id}::uuid`),
  );
  if (!row || (o.orgId && row.org_id !== o.orgId)) return null;
  return { ...watchApprovalView(row, o), org_id: row.org_id };
}

// --- chats ----------------------------------------------------------------------------------

const CREATION_KINDS = new Set(["page", "image", "video", "audio", "document", "file"]);

/** Cards, pages, files and pictures in a message, each as one line (§6.1 E). */
export function messageAttachments(content: unknown, priv = false): WatchMessage["attachments"] {
  if (!Array.isArray(content)) return [];
  const out: WatchMessage["attachments"] = [];
  for (const p of content) {
    if (!p || typeof p !== "object") continue;
    const part = p as Record<string, unknown>;
    const title = (v: unknown) => (priv || typeof v !== "string" ? "" : watchLine(v, 100));
    switch (part.type) {
      case "page":
        out.push({ kind: "page", title: title(part.title) });
        break;
      case "creation":
        out.push({
          kind: (CREATION_KINDS.has(String(part.kind))
            ? part.kind
            : "file") as WatchMessage["attachments"][0]["kind"],
          title: title(part.title ?? part.name),
        });
        break;
      case "file": {
        const mime = String(part.mime_type ?? "");
        out.push({
          kind: mime.startsWith("image/")
            ? "image"
            : mime.startsWith("video/")
              ? "video"
              : mime.startsWith("audio/")
                ? "audio"
                : "file",
          title: title(part.name),
        });
        break;
      }
      case "ui":
      case "gallery_suggestion":
      case "gallery_draft":
        out.push({ kind: "card", title: title(part.title) });
        break;
      case "link":
        out.push({ kind: "link", title: title(part.title ?? part.url) });
        break;
    }
    if (out.length >= WATCH_LIMITS.attachments) break;
  }
  return out;
}

/** The text parts of a message's content (already opened), as plain text with its paragraphs. */
export function watchMessageText(content: unknown): string {
  if (!Array.isArray(content)) return "";
  return plainText(
    content
      .filter((p): p is { type: string; text: string } => {
        const part = p as { type?: unknown; text?: unknown } | null;
        return !!part && part.type === "text" && typeof part.text === "string";
      })
      .map((p) => p.text)
      .join("\n\n"),
  );
}

export interface WatchMessageOptions {
  /** The latest reply gets up to 1,200 characters; others 300. */
  latest: boolean;
  private: boolean;
  /** Hide reply text (D-325): a reply is listed with no words. */
  hideReplyText: boolean;
  /** The server can read replies aloud. */
  speech: boolean;
}

/** A message as a watch shows it. [content] may be sealed. */
export function watchMessageView(
  m: { id: string; role: string; content: unknown; created_at: string | Date },
  o: WatchMessageOptions,
): WatchMessage {
  const opened = contentKeys.open(m.content);
  const role = m.role === "assistant" ? "assistant" : "user";
  const raw = watchMessageText(opened);
  const hidden = o.private || (role === "assistant" && o.hideReplyText);
  const { text, cut } = hidden
    ? { text: "", cut: false }
    : watchText(
        raw,
        o.latest && role === "assistant" ? WATCH_LIMITS.latestChars : WATCH_LIMITS.olderChars,
      );
  return {
    id: m.id,
    role,
    text,
    cut,
    attachments: messageAttachments(opened, o.private),
    at: iso(m.created_at),
    can_speak: role === "assistant" && raw.trim().length > 0 && o.speech && !o.private,
  };
}

const chatLink = (botId: string, conversationId: string | null, kind?: string | null) =>
  !conversationId
    ? `/bots/${botId}/chat`
    : kind === "group"
      ? `/groups/${conversationId}`
      : `/bots/${botId}/chat?c=${conversationId}`;

const BOT_STATUSES = new Set(["idle", "working", "waiting", "disabled"]);

export interface WatchChatOptions {
  userId: string;
  botId: string;
  /** A given chat; default the bot's latest direct chat. */
  conversationId?: string | null;
  orgId?: string | null;
  private: boolean;
  hideReplyText: boolean;
  speech: boolean;
}

/** A bot's latest chat for a watch (§6.1 E), or null when the bot or chat can't be seen. */
export async function buildWatchChat(db: Database, o: WatchChatOptions): Promise<WatchChat | null> {
  const q = await withUserSession(db, { sub: o.userId, role: "authenticated" }, async (tx) => {
    const [bot] = await tx.execute<{
      id: string;
      org_id: string;
      name: string;
      avatar_url: string | null;
      status: string;
    }>(sql`select id, org_id, name, avatar_url, status from public.bots
           where id = ${o.botId}::uuid and archived_at is null`);
    if (!bot || (o.orgId && bot.org_id !== o.orgId)) return null;
    const [conv] = o.conversationId
      ? await tx.execute<{ id: string; kind: string }>(sql`
          select c.id, c.kind from public.conversations c
          where c.id = ${o.conversationId}::uuid and c.bot_id = ${bot.id}::uuid`)
      : await tx.execute<{ id: string; kind: string }>(sql`
          select c.id, c.kind from public.conversations c
          where c.bot_id = ${bot.id}::uuid and c.kind = 'direct' and c.last_message_at is not null
          order by c.last_message_at desc limit 1`);
    if (o.conversationId && !conv) return null;
    if (!conv) return { bot, conv: null, messages: [], runId: null };
    const messages = await tx.execute<{
      id: string;
      role: string;
      content: unknown;
      created_at: string;
    }>(sql`select id, role, content, created_at
           from public.conversation_thread(${conv.id}::uuid, ${WATCH_LIMITS.messages}::int, null, null)
           where role in ('user', 'assistant')`);
    const [run] = await tx.execute<{ id: string }>(sql`
      select r.id from public.runs r
      where r.conversation_id = ${conv.id}::uuid and r.parent_run_id is null
        and r.status in ('queued', 'running', 'waiting_approval', 'waiting_takeover')
      order by r.created_at desc limit 1`);
    return { bot, conv, messages: [...messages], runId: run?.id ?? null };
  });
  if (!q) return null;
  const list = q.messages.slice(-WATCH_LIMITS.messages);
  let latestReply = -1;
  for (let i = list.length - 1; i >= 0; i--)
    if (list[i]?.role === "assistant") {
      latestReply = i;
      break;
    }
  return {
    bot: {
      id: q.bot.id,
      name: watchLine(q.bot.name, WATCH_LIMITS.botChars),
      avatar: avatar(q.bot.avatar_url),
      status: (BOT_STATUSES.has(q.bot.status)
        ? q.bot.status
        : "idle") as WatchChat["bot"]["status"],
    },
    conversation_id: q.conv?.id ?? null,
    messages: list.map((m, i) =>
      watchMessageView(m, {
        latest: i === latestReply,
        private: o.private,
        hideReplyText: o.hideReplyText,
        speech: o.speech,
      }),
    ),
    run_id: q.runId,
    link: chatLink(q.bot.id, q.conv?.id ?? null, q.conv?.kind),
  };
}

// --- runs -----------------------------------------------------------------------------------

export interface WatchRunOptions extends WatchReadOptions {
  hideReplyText: boolean;
  speech: boolean;
}

/** The step words for a run's latest event, as the island words it. */
export function watchStepWords(type: string | null, payload: unknown): string {
  if (type === "tool.started") {
    const p = contentKeys.open(payload) as { tool?: unknown } | null;
    return liveStepWords(String(p?.tool ?? ""));
  }
  if (type === "message.delta") return LIVE_LABELS.writing;
  return LIVE_LABELS.thinking;
}

/** A run's whole state now (§6.1 D), or null when the person can't see it (or it's elsewhere). */
export async function buildWatchRun(
  db: Database,
  runId: string,
  o: WatchRunOptions,
): Promise<WatchRun | null> {
  const q = await withUserSession(db, { sub: o.userId, role: "authenticated" }, async (tx) => {
    const [run] = await tx.execute<{
      id: string;
      org_id: string;
      bot_id: string;
      bot: string;
      bot_avatar: string | null;
      status: string;
      conversation_id: string | null;
      conv_kind: string | null;
      started_at: string | null;
      created_at: string;
      ended_at: string | null;
      steps: number;
      step_type: string | null;
      step_payload: unknown;
      takeover: boolean;
    }>(sql`
      select r.id, r.org_id, r.bot_id, b.name as bot, b.avatar_url as bot_avatar, r.status,
             r.conversation_id, c.kind as conv_kind, r.started_at, r.created_at, r.ended_at,
             (select count(*)::int from public.run_events e
               where e.run_id = r.id and e.type = 'tool.started') as steps,
             ev.type as step_type, ev.payload as step_payload,
             exists (select 1 from public.takeover_requests t where t.run_id = r.id
                     and t.status in ('pending', 'taken') and t.expires_at > now()) as takeover
      from public.runs r
      join public.bots b on b.id = r.bot_id
      left join public.conversations c on c.id = r.conversation_id
      left join lateral (
        select e.type, e.payload from public.run_events e
        where e.run_id = r.id and e.type in ('tool.started', 'message.delta')
        order by e.seq desc limit 1) ev on true
      where r.id = ${runId}::uuid`);
    if (!run || (o.orgId && run.org_id !== o.orgId)) return null;
    const approval = await approvalRow(
      tx,
      sql`a.run_id = ${runId}::uuid and a.status = 'pending' and a.expires_at > now()`,
    );
    const [reply] =
      run.status === "completed"
        ? await tx.execute<{ id: string; role: string; content: unknown; created_at: string }>(sql`
            select id, role, content, created_at from public.messages
            where run_id = ${runId}::uuid and role = 'assistant' order by created_at desc limit 1`)
        : [];
    return { run, approval, reply: reply ?? null };
  });
  if (!q) return null;
  const { run, approval, reply } = q;
  const phase: WatchRun["phase"] =
    run.status === "completed"
      ? "finished"
      : run.status === "failed"
        ? "problem"
        : run.status === "cancelled"
          ? "stopped"
          : approval || run.status === "waiting_approval"
            ? "needs_ok"
            : run.takeover || run.status === "waiting_takeover"
              ? "take_over"
              : "working";
  const step =
    phase === "finished"
      ? LIVE_LABELS.finished
      : phase === "problem"
        ? LIVE_LABELS.problem
        : phase === "stopped"
          ? WATCH_STOPPED
          : phase === "needs_ok"
            ? approval
              ? liveStepWords(approval.tool_name)
              : LIVE_LABELS.needsOk
            : phase === "take_over"
              ? LIVE_LABELS.takeOver
              : watchStepWords(run.step_type, run.step_payload);
  const approvalView = approval ? watchApprovalView(approval, o) : null;
  return {
    id: run.id,
    bot_id: run.bot_id,
    bot: watchLine(run.bot, WATCH_LIMITS.botChars),
    bot_avatar: avatar(run.bot_avatar),
    conversation_id: run.conversation_id,
    phase,
    step: o.private ? "" : watchLine(step, WATCH_LIMITS.stepChars),
    steps: run.steps,
    started_at: iso(run.started_at ?? run.created_at),
    ended_at: run.ended_at ? iso(run.ended_at) : null,
    approval: approvalView,
    reply: reply
      ? watchMessageView(reply, {
          latest: true,
          private: o.private,
          hideReplyText: o.hideReplyText,
          speech: o.speech,
        })
      : null,
    link: approvalView
      ? approvalView.link
      : chatLink(run.bot_id, run.conversation_id, run.conv_kind),
  };
}

/** Deletes watch sign-in codes a day after they expired (they are good for ten minutes). */
export async function sweepWatchCodes(db: Database, hours = 24) {
  const rows = await db.execute<{ id: string }>(sql`
    delete from public.watch_key_requests
    where expires_at < now() - make_interval(hours => ${hours}) returning id`);
  return rows.length;
}

/** Whether a run has ended: a stream stops then. */
export const watchRunEnded = (r: Pick<WatchRun, "phase">) =>
  r.phase === "finished" || r.phase === "problem" || r.phase === "stopped";
