/**
 * Chat apps (D-134): what happens to an inbound message, and how replies go out.
 * - Senders not on the channel's allowlist get no reply; the message is logged.
 * - Each external thread maps to one conversation, so replies stay in context.
 * - A routine with a `message` trigger whose filters match starts on the message.
 * - When a run in such a conversation finishes, its reply goes back to the thread.
 * - `channel.send` (high risk) starts a new message to an allowed sender.
 */
import { contentKeys, type Database } from "@kasama/db";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { ToolError, type ToolRegistry } from "../tools/registry.ts";
import { ADAPTERS, type ChannelKind, type Config, type InboundMessage, previewOf, type Secrets, senderAllowed } from "./adapters.ts";

export interface ChannelRow {
  id: string;
  org_id: string;
  bot_id: string;
  kind: ChannelKind;
  name: string;
  config: Config;
  secrets: Secrets;
  allowed_senders: string[];
  enabled: boolean;
  created_by: string | null;
}

const KIND_NAMES: Record<ChannelKind, string> = {
  telegram: "Telegram",
  email: "Email",
  sms: "SMS",
  slack: "Slack",
  whatsapp: "WhatsApp",
  messenger: "Messenger",
  feishu: "Feishu",
  imessage: "iMessage",
};

export async function loadChannel(db: Database, id: string): Promise<ChannelRow | null> {
  const [r] = await db.execute<Omit<ChannelRow, "secrets"> & { secret: string | null }>(sql`
    select c.id, c.org_id, c.bot_id, c.kind, c.name, c.config, c.allowed_senders, c.enabled, c.created_by, v.decrypted_secret as secret
    from public.channels c left join vault.decrypted_secrets v on v.id = c.vault_secret_id where c.id = ${id}::uuid`);
  if (!r) return null;
  let secrets: Secrets = {};
  try {
    secrets = r.secret ? (JSON.parse(r.secret) as Secrets) : {};
  } catch {}
  const { secret: _s, ...rest } = r;
  return { ...rest, secrets };
}

async function log(db: Database, c: ChannelRow, e: { direction: "in" | "out"; status: string; sender?: string; threadKey?: string; text?: string; detail?: string }) {
  await db.execute(sql`
    insert into public.channel_events (channel_id, org_id, direction, status, sender, thread_key, preview, detail)
    values (${c.id}::uuid, ${c.org_id}::uuid, ${e.direction}, ${e.status}, ${e.sender ?? null}, ${e.threadKey ?? null},
            ${e.text ? previewOf(e.text) : null}, ${e.detail?.slice(0, 1000) ?? null})`);
}

/** Routine message filters (D-134): channel, sender, subject and text, all optional; words match case-insensitively. */
export interface MessageTrigger {
  type: "message";
  channel_id?: string;
  channel_kind?: ChannelKind;
  sender?: string;
  subject_match?: string;
  text_match?: string;
}
export function messageMatches(t: MessageTrigger, c: Pick<ChannelRow, "id" | "kind"> & { allowed_senders?: string[] }, m: InboundMessage) {
  if (t.channel_id && t.channel_id !== c.id) return false;
  if (t.channel_kind && t.channel_kind !== c.kind) return false;
  // A routine without its own sender filter only hears the channel's allowed senders (audit 2026-11:
  // a subject-only filter let any stranger start tool-using runs). sender "*" accepts anyone.
  if (t.sender) {
    if (t.sender !== "*" && !senderAllowed([t.sender], m.sender)) return false;
  } else if (!senderAllowed(c.allowed_senders ?? [], m.sender)) return false;
  if (t.subject_match && !(m.subject ?? "").toLowerCase().includes(t.subject_match.toLowerCase())) return false;
  if (t.text_match && !m.text.toLowerCase().includes(t.text_match.toLowerCase())) return false;
  return true;
}

export function describeInbound(c: Pick<ChannelRow, "kind" | "name">, m: InboundMessage) {
  return [`${KIND_NAMES[c.kind]} (${c.name}) from ${m.senderName ? `${m.senderName} <${m.sender}>` : m.sender}`, m.subject ? `Subject: ${m.subject}` : "", "", m.text]
    .filter((l, i) => l !== "" || i === 2)
    .join("\n");
}

/**
 * Handles messages from a verified webhook (or the iMessage poll). Returns the runs to start:
 * replies for allowed senders, and routine runs for matching message triggers.
 */
export async function handleInbound(
  db: Database,
  c: ChannelRow,
  messages: InboundMessage[],
  deps: { startRoutine: (routineId: string, eventText: string) => Promise<string | null> },
): Promise<string[]> {
  const runIds: string[] = [];
  if (!c.enabled) return runIds;
  await db.execute(sql`update public.channels set last_inbound_at = now() where id = ${c.id}::uuid`);
  const routines = await db.execute<{ id: string; trigger: MessageTrigger }>(sql`
    select id, trigger from public.routines where bot_id = ${c.bot_id}::uuid and enabled and trigger ->> 'type' = 'message'`);
  for (const m of messages) {
    // Routines with matching filters start on the message, whoever sent it.
    let routed = false;
    for (const r of routines)
      if (messageMatches(r.trigger, c, m)) {
        const id = await deps.startRoutine(r.id, describeInbound(c, m));
        if (id) {
          runIds.push(id);
          routed = true;
        }
      }
    if (routed) await log(db, c, { direction: "in", status: "routine", sender: m.sender, threadKey: m.threadKey, text: m.text });
    if (!senderAllowed(c.allowed_senders, m.sender)) {
      if (!routed) await log(db, c, { direction: "in", status: "ignored", sender: m.sender, threadKey: m.threadKey, text: m.text, detail: "Sender isn't on the allowed list" });
      continue;
    }
    if (routed) continue;
    // One conversation per external thread.
    let [t] = await db.execute<{ conversation_id: string }>(sql`
      select conversation_id from public.channel_threads where channel_id = ${c.id}::uuid and thread_key = ${m.threadKey}`);
    if (!t) {
      const [conv] = await db.execute<{ id: string }>(sql`
        insert into public.conversations (org_id, bot_id, title, created_by, last_message_at)
        values (${c.org_id}::uuid, ${c.bot_id}::uuid, ${`${KIND_NAMES[c.kind]}: ${m.subject ?? m.senderName ?? m.sender}`.slice(0, 200)}, ${c.created_by}::uuid, now())
        returning id`);
      [t] = await db.execute<{ conversation_id: string }>(sql`
        insert into public.channel_threads (channel_id, org_id, thread_key, conversation_id, reply)
        values (${c.id}::uuid, ${c.org_id}::uuid, ${m.threadKey}, ${conv?.id}::uuid, ${JSON.stringify(m.reply)}::jsonb)
        on conflict (channel_id, thread_key) do update set reply = excluded.reply
        returning conversation_id`);
    } else
      await db.execute(sql`update public.channel_threads set reply = ${JSON.stringify(m.reply)}::jsonb where channel_id = ${c.id}::uuid and thread_key = ${m.threadKey}`);
    const conversationId = t?.conversation_id as string;
    const [run] = await db.execute<{ id: string }>(sql`
      insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger)
      values (${c.org_id}::uuid, ${c.bot_id}::uuid, ${conversationId}::uuid, ${c.created_by}::uuid, 'channel') returning id`);
    await db.execute(sql`
      insert into public.messages (org_id, conversation_id, role, content, run_id)
      values (${c.org_id}::uuid, ${conversationId}::uuid, 'user',
              ${contentKeys.sealJson(c.org_id, [{ type: "text", text: `(${KIND_NAMES[c.kind]}, from ${m.senderName ?? m.sender}${m.subject ? `, subject "${m.subject}"` : ""})\n${m.text}` }, { type: "channel", kind: c.kind, channel_id: c.id, sender: m.sender, sender_name: m.senderName ?? null }])}::jsonb,
              ${run?.id}::uuid)`);
    await db.execute(sql`update public.conversations set last_message_at = now() where id = ${conversationId}::uuid`);
    await log(db, c, { direction: "in", status: "accepted", sender: m.sender, threadKey: m.threadKey, text: m.text });
    runIds.push(run?.id as string);
  }
  return runIds;
}

export interface LocalTunnel {
  apiUrl: string;
  internalToken: string;
}

/** Sends text through a channel; failures are logged and returned. iMessage goes through the Mac's tunnel. */
export async function sendThrough(db: Database, c: ChannelRow, reply: Record<string, unknown>, text: string, f: typeof fetch, threadKey?: string, local?: LocalTunnel) {
  try {
    const cfg = c.kind === "imessage" && local ? { ...c.config, tunnel_url: `${local.apiUrl.replace(/\/$/, "")}/internal/local/${c.config.computer_id}/http` } : c.config;
    const secrets = c.kind === "imessage" && local ? { ...c.secrets, internal_token: local.internalToken } : c.secrets;
    if (c.kind === "imessage" && !local) throw new Error("iMessage needs the desktop app on your Mac");
    await ADAPTERS[c.kind].send(cfg, secrets, reply, text, f);
    await log(db, c, { direction: "out", status: "sent", sender: String(reply.to ?? reply.chat_id ?? reply.channel ?? reply.recipient ?? ""), threadKey, text });
    return null;
  } catch (err) {
    const msg = (err as Error).message;
    await log(db, c, { direction: "out", status: "failed", threadKey, text, detail: msg });
    await db.execute(sql`update public.channels set last_error = ${msg.slice(0, 500)} where id = ${c.id}::uuid`);
    return msg;
  }
}

/** After a run in a channel thread's conversation: its reply goes back to the thread. */
export async function replyToChannel(db: Database, run: { conversationId: string | null }, text: string, f: typeof fetch, local?: LocalTunnel) {
  if (!run.conversationId || !text.trim()) return;
  const [t] = await db.execute<{ channel_id: string; thread_key: string; reply: Record<string, unknown> }>(sql`
    select channel_id, thread_key, reply from public.channel_threads where conversation_id = ${run.conversationId}::uuid limit 1`);
  if (!t) return;
  const c = await loadChannel(db, t.channel_id);
  if (!c?.enabled) return;
  await sendThrough(db, c, t.reply, text, f, t.thread_key, local);
}

export function registerChannelTools(registry: ToolRegistry, deps: { db: Database; fetch: typeof fetch; local?: LocalTunnel }) {
  registry.register({
    name: "channel.send",
    description:
      "Send a new message through one of your chat apps (Telegram, email, SMS, Slack, WhatsApp, Messenger, Feishu, iMessage) to someone on its allowed list. Replies in a conversation that came from a chat app go back automatically; use this to start a new message.",
    risk: "high",
    category: "send",
    schema: z.object({
      channel: z.string().min(1).max(100).describe("The chat app's name, or its kind (telegram, email, …)"),
      to: z.string().min(1).max(300).describe("Chat id, address, phone number or user id"),
      text: z.string().min(1).max(20_000),
      subject: z.string().max(300).optional().describe("Email only"),
    }),
    async execute(args, ctx) {
      const [row] = await deps.db.execute<{ id: string }>(sql`
        select id from public.channels where bot_id = ${ctx.botId}::uuid and enabled and (lower(name) = lower(${args.channel}) or kind = ${args.channel.toLowerCase()})
        order by (lower(name) = lower(${args.channel})) desc limit 1`);
      if (!row) throw new ToolError("channel_not_found", `You have no chat app called ${args.channel}.`);
      const c = await loadChannel(deps.db, row.id);
      if (!c) throw new ToolError("channel_not_found", "The chat app was removed.");
      if (!senderAllowed(c.allowed_senders, args.to)) throw new ToolError("recipient_not_allowed", `${args.to} isn't on ${c.name}'s allowed list.`);
      const reply: Record<string, unknown> =
        c.kind === "telegram" ? { chat_id: args.to }
        : c.kind === "email" ? { to: args.to, subject: args.subject ?? "A message from your assistant" }
        : c.kind === "slack" ? { channel: args.to }
        : c.kind === "messenger" ? { recipient: args.to }
        : c.kind === "feishu" ? { chat_id: args.to }
        : { to: args.to };
      const err = await sendThrough(deps.db, c, reply, args.text, deps.fetch, undefined, deps.local);
      if (err) throw new ToolError("send_failed", err);
      return { content: `Sent to ${args.to} on ${c.name}.`, preview: `${c.name} → ${args.to}` };
    },
  });
}

/**
 * iMessage: new messages are read from the user's Mac through the device tunnel, every minute.
 * `cfg.computer_id` names the Mac; `cfg.since` is the last message row seen.
 */
export async function pollIMessage(db: Database, local: { apiUrl: string; internalToken: string }, f: typeof fetch, startRoutine: (routineId: string, eventText: string) => Promise<string | null>) {
  const rows = await db.execute<{ id: string }>(sql`select id from public.channels where kind = 'imessage' and enabled`);
  const runIds: string[] = [];
  for (const r of rows) {
    const c = await loadChannel(db, r.id);
    if (!c?.config.computer_id) continue;
    const since = Number(c.config.since ?? 0);
    try {
      const res = await f(`${local.apiUrl.replace(/\/$/, "")}/internal/local/${c.config.computer_id}/http/imessage/new?since=${since}`, {
        headers: { "x-kasama-internal": local.internalToken },
      });
      if (!res.ok) continue;
      const list = (await res.json()) as { messages: Array<{ rowid: number; handle: string; text: string; name?: string }>; latest?: number };
      const msgs = list.messages.filter((m) => m.rowid > since && m.text);
      // The first poll only takes a baseline, so old messages never get answered.
      if (!msgs.length) {
        if (!since && list.latest) await db.execute(sql`update public.channels set config = config || ${JSON.stringify({ since: list.latest })}::jsonb where id = ${c.id}::uuid`);
        continue;
      }
      runIds.push(
        ...(await handleInbound(db, c, msgs.map((m) => ({ threadKey: `im:${m.handle}`, sender: m.handle, senderName: m.name, text: m.text, reply: { to: m.handle } })), { startRoutine })),
      );
      await db.execute(sql`update public.channels set config = config || ${JSON.stringify({ since: Math.max(...msgs.map((m) => m.rowid)) })}::jsonb where id = ${c.id}::uuid`);
    } catch {}
  }
  return runIds;
}
