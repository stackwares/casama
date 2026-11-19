import { contentKeys, type Database as Db } from "@casama/db";
import { sql } from "drizzle-orm";

/**
 * The call card (docs/CALL-RECAP-PLAN.md): one message at the end of a call that holds the whole
 * call. Its `call` part carries how it ended, what was done on it (start_task jobs and quick
 * tools), the transcript's turn count, and the summary and next steps once they're written. The
 * text part is for older apps, the conversation list and the model's history.
 */

/** "3:12", or "1:02:05" past an hour. */
export function callLength(seconds: number) {
  const s = Math.max(0, Math.round(seconds));
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const ss = String(s % 60).padStart(2, "0");
  return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${ss}` : `${m}:${ss}`;
}

/** One job started on a call, for the card. */
export interface CallTask {
  run_id: string;
  task: string;
  status: string;
}

/** Something the bot did with a quick tool on the call, as one line. */
export interface CallAction {
  run_id: string;
  tool: string;
  label: string;
  ok: boolean;
  target: { kind: "memory" | "routine" | "task" | "run"; id: string | null };
}

/** A next step from the summary; the person starts it with a tap. */
export interface CallStep {
  id: string;
  label: string;
  task: string;
  doable: boolean;
  /** starting: claimed while its run is being made, so a second tap can't start it again. */
  state: "open" | "starting" | "started" | "dismissed";
  run_id: string | null;
}

export type CallSummaryState = "pending" | "ready" | "skipped" | "failed";

/**
 * How a call ended, for the card's header. The server's end reason, unless the app said more
 * about a hang-up: the bot hung up (D-423), it dropped, or it went quiet.
 */
export type CallEnded =
  | "hung_up"
  | "bot_hung_up"
  | "dropped"
  | "idle"
  | "silent"
  | "limit"
  | "missed"
  | "failed";

/** What the app says about how its call ended (VoiceTranscriptRequest.ended). */
export type AppCallEnd = "person" | "bot" | "dropped" | "idle" | "limit" | "replaced";

export interface CallPart {
  type: "call";
  live_call_id: string | null;
  seconds: number;
  kind: "app" | "phone";
  ended: CallEnded;
  started_at: string | null;
  ended_at: string | null;
  turns: number;
  tasks: CallTask[];
  actions: CallAction[];
  summary: { status: CallSummaryState; text?: string };
  next_steps: CallStep[];
  /** For a missed ring: why the bot called. */
  reason?: string;
}

/** Calls shorter than this, or with fewer turns, get no summary: there's nothing to sum up. */
export const SUMMARY_MIN_SECONDS = 30;
export const SUMMARY_MIN_TURNS = 3;

const LIMIT_REASONS = new Set(["max_length", "credits", "daily_cap", "quota", "bot_budget"]);

function endedFrom(reason: string | null, app?: AppCallEnd): CallEnded {
  if (reason && LIMIT_REASONS.has(reason)) return "limit";
  if (reason === "silent") return "silent";
  switch (app) {
    case "bot":
      return "bot_hung_up";
    case "dropped":
      return "dropped";
    case "idle":
      return "idle";
    case "limit":
      return "limit";
    default:
      return "hung_up";
  }
}

const str = (v: unknown) => (typeof v === "string" ? v.trim() : "");
const clip = (s: string, n: number) => (s.length > n ? `${s.slice(0, n - 1).trimEnd()}…` : s);

/**
 * A quick tool call as the line the card shows, or null for lookups that changed nothing (they'd
 * only be noise). Names arrive as wire names (`memory__write`).
 */
export function actionLine(
  runId: string,
  wireName: string,
  args: Record<string, unknown>,
  result: string,
  blocked: boolean,
): CallAction | null {
  const tool = wireName.replaceAll("__", ".");
  const ok = !blocked && !/^\s*(error|failed|couldn't|could not)\b/i.test(result);
  const firstId = (re: RegExp) => re.exec(result)?.[1] ?? null;
  const uuid = /([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/i;
  switch (tool) {
    case "memory.write": {
      const what = clip(str(args.content), 120);
      return {
        run_id: runId,
        tool,
        label: ok ? `Remembered: ${what}` : `Couldn't remember: ${what}`,
        ok,
        target: { kind: "memory", id: null },
      };
    }
    case "web.search":
      return {
        run_id: runId,
        tool,
        label: `Looked up “${clip(str(args.query), 80)}”`,
        ok,
        target: { kind: "run", id: runId },
      };
    case "web.fetch": {
      let host = str(args.url);
      try {
        host = new URL(host).hostname.replace(/^www\./, "");
      } catch {
        // Not a URL: show what was asked.
      }
      return {
        run_id: runId,
        tool,
        label: `Read ${clip(host, 60)}`,
        ok,
        target: { kind: "run", id: runId },
      };
    }
    case "routines.create": {
      const name = clip(str(args.name) || str(args.instructions), 80);
      return {
        run_id: runId,
        tool,
        label: ok ? `Set up: ${name}` : `Couldn't set up: ${name}`,
        ok,
        target: { kind: "routine", id: ok ? firstId(uuid) : null },
      };
    }
    case "tasks.create": {
      const title = clip(str(args.title), 80);
      return {
        run_id: runId,
        tool,
        label: ok ? `Added a ticket: ${title}` : `Couldn't add a ticket: ${title}`,
        ok,
        target: { kind: "task", id: ok ? firstId(uuid) : null },
      };
    }
    case "device.read": {
      const kind = str(args.kind).replaceAll("_", " ");
      return {
        run_id: runId,
        tool,
        label: ok ? `Checked your ${kind || "phone"}` : `Couldn't check your ${kind || "phone"}`,
        ok,
        target: { kind: "run", id: runId },
      };
    }
    default:
      // Searches, lists, usage, pushes: they changed nothing worth listing.
      return null;
  }
}

/** The quick tools run on a call, oldest first, as card lines. */
export async function callActions(
  db: Db,
  liveCallId: string,
  conversationId: string,
): Promise<CallAction[]> {
  const rows = await db.execute<{ id: string; voice_call: Record<string, unknown> | null }>(sql`
    select id, voice_call from public.runs
    where conversation_id = ${conversationId}::uuid and trigger = 'voice'
      and voice_call->>'live_call_id' = ${liveCallId}
    order by created_at limit 50`);
  return rows.flatMap((r) => {
    const v = r.voice_call ?? {};
    const args = (v.arguments && typeof v.arguments === "object" ? v.arguments : {}) as Record<
      string,
      unknown
    >;
    const line = actionLine(r.id, str(v.name), args, str(v.result), v.blocked === true);
    return line ? [line] : [];
  });
}

/** The start_task jobs of a call, in the order they were started. */
async function callTasks(db: Db, liveCallId: string): Promise<CallTask[]> {
  const rows = await db.execute<{ run_id: string; status: string; content: unknown }>(sql`
    select r.id as run_id, r.status, m.content
    from public.live_calls lc
    cross join lateral unnest(lc.task_run_ids) with ordinality as t(run_id, n)
    join public.runs r on r.id = t.run_id
    left join lateral (
      select content from public.messages
      where run_id = r.id and role = 'user' order by created_at limit 1
    ) m on true
    where lc.id = ${liveCallId}::uuid
    order by t.n`);
  return rows.map((r) => ({
    run_id: r.run_id,
    task: textOf(r.content).slice(0, 300),
    status: r.status,
  }));
}

/** The text parts of sealed message content, joined. */
export function textOf(content: unknown): string {
  const parts = content == null ? null : contentKeys.open(content);
  return Array.isArray(parts)
    ? parts
        .filter((p): p is { type: "text"; text: string } => p?.type === "text")
        .map((p) => p.text ?? "")
        .join(" ")
        .trim()
    : "";
}

/** The card's text part: what older apps, the conversation list and the model read. */
export function recapText(part: CallPart): string {
  const head =
    part.ended === "missed"
      ? "Missed call"
      : part.ended === "dropped"
        ? `Call dropped · ${callLength(part.seconds)}`
        : `${part.kind === "phone" ? "Phone call" : "Voice call"} · ${callLength(part.seconds)}`;
  const lines = [head];
  if (part.summary.status === "ready" && part.summary.text) lines.push(part.summary.text);
  if (part.reason) lines.push(part.reason);
  const open = part.next_steps.filter((s) => s.state === "open");
  if (open.length) lines.push(`Next: ${open.map((s) => s.label).join("; ")}`);
  if (part.tasks.length)
    lines.push(`Started on the call: ${part.tasks.map((t) => t.task).join("; ")}`);
  const done = part.actions.filter((a) => a.ok);
  if (done.length) lines.push(`Done on the call: ${done.map((a) => a.label).join("; ")}`);
  return lines.join("\n");
}

/** Sends "this message changed" to open chats of its conversation (best effort). */
export async function announceMessageChange(db: Db, conversationId: string, messageId: string) {
  try {
    await db.execute(
      sql`select public.announce_message_change(${conversationId}::uuid, ${messageId}::uuid)`,
    );
  } catch {
    // No Realtime (tests, some self-hosts): the chat sees it on its next load.
  }
}

/**
 * The card at the end of a call (D-327 §8, grown by the call card plan). Posted once, by whatever
 * ends the call. Nothing for a call that never connected and started nothing. A call worth summing
 * up is marked `pending`; the summary job fills it in (`summarizeCall`).
 */
export async function postCallRecap(
  db: Db,
  call: { id: string; org_id: string; conversation_id: string },
  seconds: number,
  opts: { ended?: AppCallEnd; summarize?: boolean } = {},
): Promise<string | null> {
  const [lc] = await db.execute<{
    end_reason: string | null;
    phone_call_id: string | null;
    started_at: string;
    ended_at: string | null;
    bot_id: string;
  }>(sql`
    select end_reason, phone_call_id, started_at::text, ended_at::text, bot_id
    from public.live_calls where id = ${call.id}::uuid`);
  const tasks = await callTasks(db, call.id);
  const actions = await callActions(db, call.id, call.conversation_id);
  if (Math.round(seconds) <= 0 && tasks.length === 0 && actions.length === 0) return null;
  const [t] = await db.execute<{ total: number; worded: number }>(sql`
    select count(*)::int as total, count(m.id)::int as worded
    from public.live_call_turns t left join public.messages m on m.id = t.message_id
    where t.live_call_id = ${call.id}::uuid`);
  const turns = t?.worded ?? 0;
  const wanted =
    opts.summarize !== false &&
    Math.round(seconds) >= SUMMARY_MIN_SECONDS &&
    turns >= SUMMARY_MIN_TURNS &&
    (lc ? await summariesOn(db, lc.bot_id) : true);
  const part: CallPart = {
    type: "call",
    live_call_id: call.id,
    seconds: Math.round(seconds),
    kind: lc?.phone_call_id ? "phone" : "app",
    ended: endedFrom(lc?.end_reason ?? null, opts.ended),
    started_at: lc ? new Date(lc.started_at).toISOString() : null,
    ended_at: lc?.ended_at ? new Date(lc.ended_at).toISOString() : new Date().toISOString(),
    turns,
    tasks,
    actions,
    summary: { status: wanted ? "pending" : "skipped" },
    next_steps: [],
  };
  const content = [{ type: "text", text: recapText(part) }, part];
  const [m] = await db.execute<{ id: string }>(sql`
    insert into public.messages (org_id, conversation_id, role, content)
    values (${call.org_id}::uuid, ${call.conversation_id}::uuid, 'assistant',
            ${contentKeys.sealJson(call.org_id, content)}::jsonb)
    returning id`);
  await db.execute(sql`
    update public.live_calls set recap_message_id = ${m?.id ?? null}::uuid,
      summary_state = ${wanted ? "pending" : "skipped"}
    where id = ${call.id}::uuid`);
  await db.execute(
    sql`update public.conversations set last_message_at = now() where id = ${call.conversation_id}::uuid`,
  );
  if (m) await announceMessageChange(db, call.conversation_id, m.id);
  return m?.id ?? null;
}

/** A bot's "Summarize calls" switch (bots.voice.summarize_calls), on unless turned off. */
export async function summariesOn(db: Db, botId: string) {
  const [b] = await db.execute<{ on: boolean | null }>(sql`
    select (voice->>'summarize_calls')::boolean as on from public.bots where id = ${botId}::uuid`);
  return b?.on !== false;
}

/** Reads a card's `call` part and the rest of its content, for an update. */
export async function readCard(db: Db, messageId: string, opts: { lock?: boolean } = {}) {
  const [row] = await db.execute<{ org_id: string; conversation_id: string; content: unknown }>(
    opts.lock
      ? sql`select org_id, conversation_id, content from public.messages where id = ${messageId}::uuid for update`
      : sql`select org_id, conversation_id, content from public.messages where id = ${messageId}::uuid`,
  );
  if (!row) return null;
  const parts = contentKeys.open(row.content);
  if (!Array.isArray(parts)) return null;
  const part = parts.find((p) => p?.type === "call") as CallPart | undefined;
  if (!part) return null;
  return { orgId: row.org_id, conversationId: row.conversation_id, part };
}

/** Writes a card's `call` part back, with its text part rebuilt from it, and tells open chats. */
export async function writeCard(
  db: Db,
  messageId: string,
  card: { orgId: string; conversationId: string; part: CallPart },
) {
  const content = [{ type: "text", text: recapText(card.part) }, card.part];
  await db.execute(sql`
    update public.messages set content = ${contentKeys.sealJson(card.orgId, content)}::jsonb
    where id = ${messageId}::uuid`);
  await announceMessageChange(db, card.conversationId, messageId);
}

/**
 * Changes a card under a row lock, so two changes at once (two taps, two devices) never undo each
 * other: [change] gets the card as it is now and may throw to refuse. Open chats hear of it after.
 */
export async function updateCard<T>(
  db: Db,
  messageId: string,
  change: (part: CallPart) => T,
): Promise<T | null> {
  const done = await db.transaction(async (tx) => {
    const t = tx as unknown as Db;
    const card = await readCard(t, messageId, { lock: true });
    if (!card) return null;
    const out = change(card.part);
    const content = [{ type: "text", text: recapText(card.part) }, card.part];
    await t.execute(sql`
      update public.messages set content = ${contentKeys.sealJson(card.orgId, content)}::jsonb
      where id = ${messageId}::uuid`);
    return { out, conversationId: card.conversationId };
  });
  if (!done) return null;
  await announceMessageChange(db, done.conversationId, messageId);
  return done.out;
}
