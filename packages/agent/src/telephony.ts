/**
 * Calls for you (SPEC: Calls for you; D-141). `voice.call(number, purpose, notes)` (high risk)
 * places an outbound call through the workspace's Twilio account. Twilio streams the call's audio
 * (Media Streams) to the API, which bridges it to a realtime voice session: the bot says it's an
 * AI assistant calling for the person, works toward the purpose, and hangs up when done. The tool
 * waits for the call to end and returns the transcript.
 *
 * Limits: E.164 numbers only, never emergency or short numbers, the deny list, a daily cap per
 * workspace, and business numbers by default (Twilio Lookup's caller type). Recording stays off.
 * Twilio request shapes follow its public REST docs; tested against a local fake.
 */
import { createHash, randomBytes } from "node:crypto";
import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "./acting.ts";
import type { NotificationService } from "./notifications.ts";
import { ToolError, type ToolRegistry } from "./tools/registry.ts";

export interface TwilioConfig {
  accountSid: string;
  authToken: string;
  fromNumber: string;
  allowPersonal: boolean;
  dailyCap: number;
}

/** Twilio REST: calls and Lookup. */
export class TwilioClient {
  private readonly o: {
    sid: string;
    token: string;
    api: string;
    lookups: string;
    fetch: typeof fetch;
  };
  constructor(o: {
    accountSid: string;
    authToken: string;
    apiUrl?: string;
    lookupsUrl?: string;
    fetch?: typeof fetch;
  }) {
    this.o = {
      sid: o.accountSid,
      token: o.authToken,
      api: (o.apiUrl ?? "https://api.twilio.com").replace(/\/$/, ""),
      lookups: (o.lookupsUrl ?? "https://lookups.twilio.com").replace(/\/$/, ""),
      fetch: o.fetch ?? fetch,
    };
  }
  private auth() {
    return `Basic ${Buffer.from(`${this.o.sid}:${this.o.token}`).toString("base64")}`;
  }
  private async form<T>(path: string, params: Record<string, string>) {
    const res = await this.o.fetch(`${this.o.api}/2010-04-01/Accounts/${this.o.sid}${path}`, {
      method: "POST",
      headers: { authorization: this.auth(), "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams(params).toString(),
    });
    const text = await res.text();
    if (!res.ok) throw new Error(`Twilio answered ${res.status}: ${text.slice(0, 200)}`);
    return JSON.parse(text) as T;
  }
  createCall(p: { to: string; from: string; twiml: string; statusCallback: string }) {
    return this.form<{ sid: string; status: string }>("/Calls.json", {
      To: p.to,
      From: p.from,
      Twiml: p.twiml,
      StatusCallback: p.statusCallback,
      StatusCallbackMethod: "POST",
      StatusCallbackEvent: "initiated ringing answered completed",
      Record: "false",
      Timeout: "30",
    });
  }
  /** Hangs up (completed) or redirects a live call to new TwiML. */
  updateCall(callSid: string, p: { status?: "completed"; twiml?: string }) {
    return this.form<{ sid: string; status: string }>(`/Calls/${callSid}.json`, {
      ...(p.status ? { Status: p.status } : {}),
      ...(p.twiml ? { Twiml: p.twiml } : {}),
    });
  }
  /** BUSINESS, CONSUMER or null (unknown), from Lookup v2's caller name. */
  async callerType(number: string): Promise<string | null> {
    const res = await this.o.fetch(
      `${this.o.lookups}/v2/PhoneNumbers/${encodeURIComponent(number)}?Fields=caller_name`,
      { headers: { authorization: this.auth() } },
    );
    if (!res.ok) return null;
    const b = (await res.json()) as { caller_name?: { caller_type?: string | null } | null };
    return b.caller_name?.caller_type ?? null;
  }
}

const EMERGENCY = new Set([
  "911",
  "112",
  "999",
  "000",
  "110",
  "119",
  "118",
  "113",
  "100",
  "101",
  "102",
  "108",
  "120",
  "122",
  "15",
  "17",
  "18",
  "190",
  "192",
  "193",
  "197",
  "198",
  "995",
  "997",
  "1122",
]);

/** Why a number can't be called, or null. */
export function numberProblem(raw: string): string | null {
  const n = raw.replace(/[\s().-]/g, "");
  if (EMERGENCY.has(n.replace(/^\+/, ""))) return "Emergency numbers can never be called by a bot.";
  if (!/^\+[1-9][0-9]{7,14}$/.test(n))
    return "Use a full international number, like +14155550123 (short numbers can't be called).";
  // Emergency numbers dialed with a country code (+1 911…, +44 999…).
  if (
    [...EMERGENCY].some(
      (e) =>
        e.length >= 3 && (n.slice(2).startsWith(e) || n.slice(3).startsWith(e)) && n.length <= 8,
    )
  )
    return "Emergency numbers can never be called by a bot.";
  return null;
}
export const normalizeNumber = (raw: string) => raw.replace(/[\s().-]/g, "");

export function callInstructions(o: {
  personName: string;
  botName: string;
  purpose: string;
  notes?: string | null;
  number: string;
}) {
  return [
    `You are ${o.botName}, an AI assistant, on a phone call you placed to ${o.number} for ${o.personName}.`,
    `Start by saying you're an AI assistant calling on behalf of ${o.personName}. Never pretend to be a person.`,
    `Purpose of the call: ${o.purpose}`,
    o.notes ? `Notes from ${o.personName}: ${o.notes}` : "",
    "Speak naturally and briefly. Stay on the purpose; don't agree to payments, contracts or sharing personal details beyond the notes.",
    "If you reach voicemail, leave a short message with the purpose and that you'll follow up, then end the call.",
    "When the purpose is done, or the other person wants to stop, say goodbye and call end_call.",
  ]
    .filter(Boolean)
    .join("\n");
}

export const hashStreamToken = (t: string) => createHash("sha256").update(t).digest("hex");

export interface CallToolDeps {
  db: Database;
  notifications?: NotificationService;
  /** The API's public https and wss addresses (Twilio must reach them). */
  publicApiUrl?: string;
  /** The workspace's Twilio account (from Vault), or null when not set up. */
  twilioFor: (orgId: string) => Promise<(TwilioConfig & { client: TwilioClient }) | null>;
  /** How long the tool waits for the call to finish. */
  maxWaitMs?: number;
}

const TERMINAL = ["completed", "failed", "busy", "no_answer", "ended_by_user", "taken_over"];

export function registerCallTools(registry: ToolRegistry, deps: CallToolDeps) {
  const { db } = deps;
  registry.register({
    name: "voice.call",
    description:
      "Phone a business for the person (book, reschedule, ask a question): you speak live on the call as their AI assistant, then get the transcript back. Give the number in international form, the purpose, and any notes the call needs (name, booking reference, times that work). Business numbers only unless the workspace allows personal ones; never emergency numbers.",
    risk: "high",
    category: "send",
    schema: z.object({
      number: z.string().min(3).max(32),
      purpose: z.string().min(1).max(500),
      notes: z.string().max(4000).optional(),
    }),
    async execute(args, ctx) {
      const number = normalizeNumber(args.number);
      const problem = numberProblem(number);
      if (problem) throw new ToolError("number_not_allowed", problem);
      const tw = await deps.twilioFor(ctx.orgId);
      if (!tw)
        throw new ToolError(
          "no_telephony",
          "Phone calls aren't set up. An admin connects Twilio in workspace settings → Phone calls.",
        );
      if (!deps.publicApiUrl)
        throw new ToolError(
          "no_public_url",
          "Phone calls need this server to have a public https address (PUBLIC_API_URL).",
        );
      const [denied] = await db.execute<{ prefix: string }>(sql`
        select prefix from public.call_deny_list where ${number} like prefix || '%' order by length(prefix) desc limit 1`);
      if (denied)
        throw new ToolError(
          "number_not_allowed",
          "This number is on the list of numbers bots may not call.",
        );
      const [today] = await db.execute<{ n: number }>(sql`
        select count(*)::int as n from public.outbound_calls where org_id = ${ctx.orgId}::uuid and created_at > now() - interval '1 day'`);
      if ((today?.n ?? 0) >= tw.dailyCap)
        throw new ToolError(
          "call_cap_reached",
          `The workspace's daily limit of ${tw.dailyCap} calls is reached.`,
        );
      if (
        !tw.allowPersonal &&
        (await tw.client.callerType(number).catch(() => null)) === "CONSUMER"
      )
        throw new ToolError(
          "personal_number",
          "That looks like a personal number. Bots call businesses unless an admin allows personal numbers.",
        );
      const user = await actingUserOf(db, ctx.runId);
      if (!user) throw new ToolError("no_person", "There's nobody to call for.");

      const token = randomBytes(24).toString("base64url");
      const [row] = await db.execute<{ id: string }>(sql`
        insert into public.outbound_calls (org_id, bot_id, user_id, run_id, number, purpose, notes, stream_token_hash)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${user}::uuid, ${ctx.runId}::uuid, ${number}, ${args.purpose}, ${args.notes ?? null}, ${hashStreamToken(token)})
        returning id`);
      const id = row?.id as string;
      const base = deps.publicApiUrl.replace(/\/$/, "");
      const wss = base.replace(/^http/, "ws");
      const twiml = `<Response><Connect><Stream url="${wss}/telephony/stream/${id}"><Parameter name="token" value="${token}"/></Stream></Connect></Response>`;
      try {
        const call = await tw.client.createCall({
          to: number,
          from: tw.fromNumber,
          twiml,
          statusCallback: `${base}/hooks/telephony/${id}`,
        });
        await db.execute(
          sql`update public.outbound_calls set provider_call_id = ${call.sid}, status = 'ringing' where id = ${id}::uuid`,
        );
      } catch (e) {
        await db.execute(
          sql`update public.outbound_calls set status = 'failed', error = ${(e as Error).message.slice(0, 500)}, ended_at = now() where id = ${id}::uuid`,
        );
        throw new ToolError("call_failed", `The call couldn't be placed: ${(e as Error).message}`);
      }
      await deps.notifications
        ?.notify(user, ctx.orgId, "outbound_call", {
          title: `Calling ${number}`,
          body: args.purpose,
          link: `/calls/${id}`,
          bot_id: ctx.botId,
          call_id: id,
        })
        .catch(() => {});
      // Wait for the call to end, streaming the transcript as it grows.
      let shown = 0;
      const until = Date.now() + (deps.maxWaitMs ?? 20 * 60_000);
      for (;;) {
        const [c] = await db.execute<{
          status: string;
          transcript: Array<{ role: string; text: string }>;
          seconds: number | null;
          error: string | null;
        }>(sql`
          select status, transcript, seconds, error from public.outbound_calls where id = ${id}::uuid`);
        const lines = c?.transcript ?? [];
        for (const l of lines.slice(shown))
          await ctx.output(`${l.role === "bot" ? "Bot" : "Them"}: ${l.text}\n`).catch(() => {});
        shown = lines.length;
        if (c && TERMINAL.includes(c.status)) {
          const text = lines
            .map((l) => `${l.role === "bot" ? "You" : "Them"}: ${l.text}`)
            .join("\n");
          const how =
            c.status === "completed"
              ? `The call ended after ${c.seconds ?? 0} seconds.`
              : c.status === "taken_over"
                ? "The person took over the call."
                : c.status === "ended_by_user"
                  ? "The person ended the call."
                  : `The call didn't go through (${c.status.replace("_", " ")}${c.error ? `: ${c.error}` : ""}).`;
          return {
            content: `${how}\n\nTranscript:\n${text || "(nothing was said)"}`,
            preview: `${c.status} · ${lines.length} lines`,
          };
        }
        if (Date.now() > until)
          return {
            content: `The call is still going (call ${id}); check it in the app.`,
            preview: "still on the call",
          };
        await new Promise((r) => setTimeout(r, 1000));
      }
    },
  });
}
