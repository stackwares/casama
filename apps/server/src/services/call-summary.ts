import { track } from "@casama/agent";
import { contentKeys, type Database as Db } from "@casama/db";
import { sql } from "drizzle-orm";
import { type CallStep, readCard, writeCard } from "./call-recap.ts";

/**
 * The call card's summary and next steps (docs/CALL-RECAP-PLAN.md §5): one call on the bot's
 * background model after the call, in the worker. Never blocks the card: on any failure the card
 * just has no summary.
 */

/** One background-model call (backgroundComplete), so tests can swap it. */
export type Complete = (input: {
  orgId: string;
  botId: string;
  userId: string | null;
  system: string;
  text: string;
  maxOutputTokens?: number;
  purpose: string;
}) => Promise<{ text: string; model: string } | null>;

/** About 6,000 tokens of the call's end plus its opening, which usually says why it happened. */
export const SUMMARY_TAIL_CHARS = 18_000;
export const SUMMARY_HEAD_CHARS = 1_500;
export const SUMMARY_MAX_STEPS = 3;

export const CALL_SUMMARY_SYSTEM = `You write the recap of a voice call between a person and their AI assistant, for the card shown in their chat afterwards.

Reply with JSON only, no code fence:
{"summary": string, "next_steps": [{"label": string, "task": string, "doable": boolean}]}

summary: 1 to 3 short sentences, past tense, plain words, what the call was about and what was decided or found out. Start with the substance ("Planned Friday's trip to Cebu: …"), never with "In this call" or "The user and the assistant". Say "you" for the person and the assistant's name for the assistant. Only facts said in the transcript; keep names, numbers and places as heard; no guesses at dates or times nobody said.

next_steps: at most 3 things someone said out loud would happen next and that haven't been done on the call yet. Leave it empty when nothing was promised or asked for; never invent follow-ups. label: under 50 characters, starting with a verb ("Text Ana the hotel address"). task: the complete request as the person would type it to the assistant, with every detail from the call it needs. doable: true when the assistant could do it itself (look things up, write or send messages, set reminders, make documents, book through connected apps); false when only the person can (go somewhere, decide, pay in person).

Write in the language the call was held in.`;

/** Strips a code fence and reads the model's JSON, or null when it isn't usable. */
export function parseSummary(
  raw: string,
): { summary: string; steps: Array<Omit<CallStep, "id" | "state" | "run_id">> } | null {
  const text = raw
    .trim()
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/\s*```$/, "");
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end <= start) return null;
  let v: unknown;
  try {
    v = JSON.parse(text.slice(start, end + 1));
  } catch {
    return null;
  }
  if (!v || typeof v !== "object") return null;
  const o = v as { summary?: unknown; next_steps?: unknown };
  const summary = typeof o.summary === "string" ? o.summary.trim().slice(0, 600) : "";
  if (!summary) return null;
  const steps = (Array.isArray(o.next_steps) ? o.next_steps : [])
    .flatMap((s) => {
      if (!s || typeof s !== "object") return [];
      const x = s as { label?: unknown; task?: unknown; doable?: unknown };
      const label = typeof x.label === "string" ? x.label.trim().slice(0, 80) : "";
      const task = typeof x.task === "string" ? x.task.trim().slice(0, 2_000) : "";
      if (!label) return [];
      return [{ label, task: task || label, doable: x.doable === true }];
    })
    .slice(0, SUMMARY_MAX_STEPS);
  return { summary, steps };
}

/** The transcript as the model reads it: the opening, then as much of the end as fits. */
export function transcriptFor(lines: string[]): string {
  const all = lines.join("\n");
  if (all.length <= SUMMARY_HEAD_CHARS + SUMMARY_TAIL_CHARS) return all;
  return `${all.slice(0, SUMMARY_HEAD_CHARS)}\n[…]\n${all.slice(-SUMMARY_TAIL_CHARS)}`;
}

/**
 * Writes the summary for a call whose card is pending. Safe to run twice: only a pending call is
 * claimed (it moves to a state only this run sets).
 */
export async function summarizeCall(
  deps: { db: Db; complete: Complete },
  liveCallId: string,
): Promise<"ready" | "skipped" | "failed" | "not_pending"> {
  const { db } = deps;
  const [call] = await db.execute<{
    org_id: string;
    bot_id: string;
    user_id: string;
    recap_message_id: string | null;
    bot_name: string;
  }>(sql`
    update public.live_calls lc set summary_state = 'failed'
    from public.bots b
    where lc.id = ${liveCallId}::uuid and lc.summary_state = 'pending' and b.id = lc.bot_id
    returning lc.org_id, lc.bot_id, lc.user_id, lc.recap_message_id, b.name as bot_name`);
  // Claimed as failed first: a crash mid-way leaves it failed, never summarized twice.
  if (!call) return "not_pending";
  if (!call.recap_message_id) return "failed";
  const card = await readCard(db, call.recap_message_id);
  if (!card) return "failed";

  const settle = async (status: "ready" | "skipped" | "failed") => {
    await db.execute(
      sql`update public.live_calls set summary_state = ${status} where id = ${liveCallId}::uuid`,
    );
    track(db, {
      event: "call_summary_written",
      userId: call.user_id,
      orgId: call.org_id,
      properties: { status, next_steps: card.part.next_steps.length },
    });
    return status;
  };

  try {
    const rows = await db.execute<{ role: string; content: unknown }>(sql`
      select m.role, m.content from public.live_call_turns t
      join public.messages m on m.id = t.message_id
      where t.live_call_id = ${liveCallId}::uuid
      order by m.created_at, t.created_at`);
    const lines = rows.flatMap((r) => {
      const parts = contentKeys.open(r.content);
      const text = Array.isArray(parts)
        ? parts
            .filter((p) => p?.type === "text")
            .map((p) => String(p.text ?? ""))
            .join(" ")
            .trim()
        : "";
      return text ? [`${r.role === "user" ? "Person" : call.bot_name}: ${text}`] : [];
    });
    if (lines.length === 0) {
      card.part.summary = { status: "skipped" };
      await writeCard(db, call.recap_message_id, card);
      return settle("skipped");
    }
    const done = [
      ...card.part.tasks.map((t) => `Started a job: ${t.task}`),
      ...card.part.actions.filter((a) => a.ok).map((a) => a.label),
    ];
    const text = [
      `Assistant's name: ${call.bot_name}`,
      `Call ended: ${card.part.ended_at ?? new Date().toISOString()}`,
      done.length ? `Already done on the call:\n- ${done.join("\n- ")}` : "",
      `Transcript:\n${transcriptFor(lines)}`,
    ]
      .filter(Boolean)
      .join("\n\n");
    const out = await deps.complete({
      orgId: call.org_id,
      botId: call.bot_id,
      userId: call.user_id,
      system: CALL_SUMMARY_SYSTEM,
      text,
      maxOutputTokens: 400,
      purpose: "call_summary",
    });
    // No model, no credits or over budget: the card goes without.
    if (!out) {
      card.part.summary = { status: "skipped" };
      await writeCard(db, call.recap_message_id, card);
      return settle("skipped");
    }
    const parsed = parseSummary(out.text);
    if (!parsed) {
      card.part.summary = { status: "failed" };
      await writeCard(db, call.recap_message_id, card);
      return settle("failed");
    }
    card.part.summary = { status: "ready", text: parsed.summary };
    card.part.next_steps = parsed.steps.map((s, i) => ({
      id: `s${i + 1}`,
      ...s,
      state: "open",
      run_id: null,
    }));
    await writeCard(db, call.recap_message_id, card);
    return settle("ready");
  } catch (e) {
    try {
      card.part.summary = { status: "failed" };
      await writeCard(db, call.recap_message_id, card);
    } catch {
      // The card stays pending on screen until it times out in the app.
    }
    await settle("failed");
    throw e;
  }
}

/** Calls whose summary is still pending a little after they ended (picked up by the minute tick). */
export async function pendingSummaries(db: Db, olderThanSeconds = 20) {
  const rows = await db.execute<{ id: string }>(sql`
    select id from public.live_calls
    where summary_state = 'pending'
      and ended_at < now() - make_interval(secs => ${olderThanSeconds})
      and ended_at > now() - interval '1 day'
    order by ended_at limit 20`);
  return rows.map((r) => r.id);
}
