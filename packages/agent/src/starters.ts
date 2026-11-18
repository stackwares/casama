/**
 * Starter requests (D-338): the tappable requests in an empty chat, written for the person.
 *
 * A cheap model writes four from what Casama knows: the time of day where they are, the apps the bot
 * can use, what they shared about themselves (only where they share it in this space), the bot's role
 * and what they asked lately, so it doesn't repeat itself. They're kept per person and bot for a day.
 * Without a model, or when the bot's budget or credits refuse, rules pick four from the same signals.
 *
 * The bot's role leads: a coding bot gets coding requests, a fitness coach workouts. The time of
 * day, apps and what the person shared only shape requests that fit the role.
 */
import type { Database } from "@casama/db";
import { BOT_TEMPLATES, type BotTemplate } from "@casama/domain";
import { sql } from "drizzle-orm";
import { loadPerson, type PersonContext } from "./about-you.ts";

export interface Starter {
  /** Decoration only; tapping sends the text. */
  emoji: string;
  text: string;
}

export type StarterSource = "ai" | "rules";

export interface StarterSignals {
  botName: string;
  persona: string;
  person: PersonContext | null;
  /** Lower-case names of the apps the bot can use (integration names, labels, Composio toolkits). */
  apps: string[];
  /** What the person asked this bot lately, newest first. */
  recent: string[];
  timezone: string;
  now: Date;
}

export const STARTER_COUNT = 4;
/** How long a written list is kept. */
export const AI_STARTERS_TTL_MS = 20 * 60 * 60 * 1000;
/** Rules are a stand-in: try the model again sooner, in case a key or credits were added. */
export const RULE_STARTERS_TTL_MS = 3 * 60 * 60 * 1000;

/** The person's local hour, weekday (0 = Sunday) and the weekday's name. */
export function localTime(now: Date, timezone: string) {
  let tz = timezone;
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: tz });
  } catch {
    tz = "UTC";
  }
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: tz,
    hour: "numeric",
    hourCycle: "h23",
    weekday: "long",
  }).formatToParts(now);
  const hour = Number(parts.find((p) => p.type === "hour")?.value ?? 12) % 24;
  const dayName = parts.find((p) => p.type === "weekday")?.value ?? "Monday";
  const day = [
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ].indexOf(dayName);
  const part =
    hour < 5
      ? "night"
      : hour < 12
        ? "morning"
        : hour < 17
          ? "afternoon"
          : hour < 22
            ? "evening"
            : "night";
  return { hour, day: day < 0 ? 1 : day, dayName, part } as const;
}

/** Everything the starters are written from. Null when the bot is gone. */
export async function starterSignals(
  db: Database,
  ids: { userId: string; orgId: string; botId: string },
  now = new Date(),
): Promise<StarterSignals | null> {
  const [bot] = await db.execute<{
    name: string;
    persona_md: string | null;
    timezone: string | null;
  }>(sql`
    select b.name, b.persona_md, p.timezone
    from public.bots b left join public.profiles p on p.user_id = ${ids.userId}::uuid
    where b.id = ${ids.botId}::uuid and b.org_id = ${ids.orgId}::uuid and b.archived_at is null`);
  if (!bot) return null;
  const apps = await db.execute<{
    name: string;
    label: string | null;
    app_id: string | null;
    toolkits: string[] | null;
  }>(sql`
    select i.name, i.config ->> 'label' as label, i.config ->> 'app_id' as app_id,
           case when jsonb_typeof(i.config -> 'toolkits') = 'array'
             then array(select jsonb_array_elements_text(i.config -> 'toolkits')) end as toolkits
    from public.bot_integrations bi join public.integrations i on i.id = bi.integration_id
    where bi.bot_id = ${ids.botId}::uuid and i.status <> 'error'
      and (i.kind <> 'local_mcp' or coalesce(i.config ->> 'owner_user_id', '') in ('', ${ids.userId}))`);
  const names = new Set<string>();
  for (const a of apps)
    for (const n of [a.name, a.label, a.app_id, ...(a.toolkits ?? [])])
      if (n?.trim()) names.add(n.trim().toLowerCase());
  // Their own requests to this bot, not other people's (a shared bot serves several people).
  const recent = await db.execute<{ task: string }>(sql`
    select d.task from public.run_digests d join public.runs r on r.id = d.run_id
    where d.bot_id = ${ids.botId}::uuid and r.created_by = ${ids.userId}::uuid
    order by d.created_at desc limit 12`);
  return {
    botName: bot.name,
    persona: (bot.persona_md ?? "").slice(0, 1200),
    person: await loadPerson(db, ids.userId, ids.orgId, ids.botId).catch(() => null),
    apps: [...names].sort(),
    recent: recent.map((r) => r.task.replace(/\s+/g, " ").trim().slice(0, 140)).filter(Boolean),
    timezone: bot.timezone ?? "UTC",
    now,
  };
}

const has = (apps: string[], re: RegExp) => apps.some((a) => re.test(a));

/**
 * The starter bot a persona was made from, when its instructions still open the same way (people
 * may add to them). Null for a bot written from scratch or a general assistant.
 */
export function personaTemplate(persona: string): BotTemplate | null {
  const first = persona.trim().split("\n")[0]?.trim();
  if (!first) return null;
  return BOT_TEMPLATES.find((t) => t.persona.split("\n")[0]?.trim() === first) ?? null;
}

/** A role whose requests are naturally technical (code, data, testing): tech words are fine there. */
export function technicalRole(persona: string): boolean {
  const t = personaTemplate(persona);
  if (t) return t.category === "build" || t.id === "data-analyst";
  return /\b(software|engineer(ing)?|developer|coding|programm(er|ing)|devops|sql|code review|test suite)\b/i.test(
    persona,
  );
}

const CATEGORY_EMOJI: Record<BotTemplate["category"], string> = {
  work: "💼",
  research: "🔎",
  build: "🛠️",
  create: "🎨",
  life: "🌿",
};

/** Requests for what a connected app does, most useful first. */
function appStarters(apps: string[], evening: boolean): Starter[] {
  const out: Starter[] = [];
  if (has(apps, /gmail|outlook|mail/)) out.push({ emoji: "📬", text: "Sum up my unread emails" });
  if (has(apps, /calendar/))
    out.push({
      emoji: "📅",
      text: evening ? "What's on my calendar tomorrow?" : "What's on my calendar today?",
    });
  if (has(apps, /slack/)) out.push({ emoji: "💬", text: "Catch me up on Slack" });
  if (has(apps, /notion/)) out.push({ emoji: "🗒️", text: "Find my latest notes in Notion" });
  return out;
}

/**
 * Four starters without a model. A bot made from a starter bot leads with that role's requests and
 * adds one for a connected app. Otherwise: the apps they connected first, then something for the
 * time of day, then everyday help. The everyday ones rotate by day so the list doesn't stay the same.
 */
export function ruleStarters(
  s: Pick<StarterSignals, "apps" | "timezone" | "now"> & { persona?: string },
): Starter[] {
  const t = localTime(s.now, s.timezone);
  const evening = t.part === "evening" || t.part === "night";
  const apps = appStarters(s.apps, evening);
  const dayIndex = Math.floor(s.now.getTime() / 86_400_000);
  const template = personaTemplate(s.persona ?? "");
  if (template) {
    const out: Starter[] = template.starters
      .slice(0, STARTER_COUNT - 1)
      .map((text) => ({ emoji: CATEGORY_EMOJI[template.category], text }));
    const extra = [...apps, { emoji: "🔎", text: "Look something up and explain it simply" }];
    for (const e of extra) if (out.length < STARTER_COUNT) out.push(e);
    return out;
  }
  const out = apps.slice(0, 2);
  const weekend = t.day === 0 || t.day === 6;
  const timely: Starter =
    weekend && t.part !== "night"
      ? { emoji: "🗺️", text: "Find something fun to do this weekend" }
      : t.part === "morning"
        ? { emoji: "☀️", text: "Help me plan my day" }
        : t.part === "afternoon"
          ? { emoji: "✅", text: "Help me sort out my to-do list" }
          : t.part === "evening"
            ? { emoji: "🍝", text: "Give me an easy dinner idea for tonight" }
            : { emoji: "🌙", text: "Help me wind down before bed" };
  out.push(timely);
  const everyday: Starter[] = [
    { emoji: "✍️", text: "Help me write a message" },
    { emoji: "🔎", text: "Look something up and explain it simply" },
    { emoji: "⏰", text: "Remind me about something later" },
    { emoji: "🎁", text: "Help me pick a gift" },
    { emoji: "✈️", text: "Help me plan a trip" },
    { emoji: "💡", text: "Give me ideas for the weekend" },
    { emoji: "📖", text: "Recommend a good book for me" },
  ];
  for (let i = 0; out.length < STARTER_COUNT && i < everyday.length; i++) {
    const pick = everyday[(dayIndex + i) % everyday.length] as Starter;
    if (!out.some((o) => o.text === pick.text)) out.push(pick);
  }
  return out.slice(0, STARTER_COUNT);
}

export const STARTERS_SYSTEM = `You write the tappable starter requests shown in an empty chat with an AI assistant. The person taps one and it's sent as their message.

The assistant's role comes first. When it has one (a coder, a fitness coach, a translator, a writer…), every request must be something a person would ask that kind of assistant: a coding assistant gets coding requests, a fitness coach gets workout and health requests. Never suggest unrelated everyday chores, meal plans or birthday reminders to a specialist. Only a general personal assistant gets general everyday requests.

Write exactly ${STARTER_COUNT}. Each one:
- is something this person would actually type, in the first person ("Plan my week", "Help me write…", "Review my pull request");
- is short and plain, 3 to 9 words, no ending period;
- matches the role's own vocabulary: technical words are right for a technical role (code, tests, bugs, pull request) and wrong for an everyday one;
- is something the assistant can do now: talk, write, explain, research the web, plan, remind them or do something on a schedule, use its computer if its role works in one, and use the connected apps listed (only those);
- is different from what they asked recently, and different from the others.

Within the role, vary them: one can use a connected app if it suits the role, one can fit their local time or day if that makes sense for the role, and one can fit who they are. Never invent personal details they didn't share. Keep any name out of the text.

Reply with only a JSON array, no other text: [{"emoji":"🔎","text":"…"}]`;

/** The model's input: the signals as short labeled lines. */
export function starterPrompt(s: StarterSignals): string {
  const t = localTime(s.now, s.timezone);
  const lines = [
    `Local time: ${t.dayName} ${t.part} (${String(t.hour).padStart(2, "0")}:00, ${s.timezone})`,
    `Assistant: ${s.botName}`,
  ];
  if (s.persona.trim()) lines.push(`Its role (write for this role):\n${s.persona.trim()}`);
  else lines.push("Its role: a general personal assistant.");
  const template = personaTemplate(s.persona);
  if (template)
    lines.push(
      `Requests that fit this role, for the kind of thing to write (don't copy them):\n${template.starters
        .map((t) => `- ${t}`)
        .join("\n")}`,
    );
  lines.push(`Connected apps: ${s.apps.length ? s.apps.join(", ") : "none"}`);
  const p = s.person;
  if (p?.about) lines.push(`What they shared about themselves:\n${p.about.slice(0, 800)}`);
  if (p?.facts.length)
    lines.push(
      `What bots learned about them:\n${p.facts
        .slice(0, 15)
        .map((f) => `- ${f.slice(0, 160)}`)
        .join("\n")}`,
    );
  if (!p?.about && !p?.facts.length)
    lines.push("About them: nothing yet. Keep it broadly useful for anyone.");
  lines.push(
    s.recent.length
      ? `Asked lately (don't repeat):\n${s.recent.map((r) => `- ${r}`).join("\n")}`
      : "Asked lately: nothing yet (a new chat).",
  );
  return lines.join("\n\n");
}

const EMOJI = /\p{Extended_Pictographic}/u;
const TECHY = /\b(api|repo|cli|sdk|json|endpoint|terminal)\b/i;

/**
 * Reads the model's reply. Fewer than four usable starters is a failed reply ([]). Tech words are
 * dropped unless the bot's role is technical.
 */
export function parseStarters(text: string, opts: { technical?: boolean } = {}): Starter[] {
  const start = text.indexOf("[");
  const end = text.lastIndexOf("]");
  if (start < 0 || end <= start) return [];
  let raw: unknown;
  try {
    raw = JSON.parse(text.slice(start, end + 1));
  } catch {
    return [];
  }
  if (!Array.isArray(raw)) return [];
  const out: Starter[] = [];
  for (const item of raw) {
    if (!item || typeof item !== "object") continue;
    const r = item as Record<string, unknown>;
    const body =
      typeof r.text === "string"
        ? r.text
            .replace(/\s+/g, " ")
            .trim()
            .replace(/[."]+$/u, "")
            .replace(/^"/, "")
        : "";
    if (body.length < 6 || body.length > 80) continue;
    if (/https?:|www\.|[<>{}`]/.test(body) || (!opts.technical && TECHY.test(body))) continue;
    if (out.some((o) => o.text.toLowerCase() === body.toLowerCase())) continue;
    const emoji =
      typeof r.emoji === "string" && EMOJI.test(r.emoji)
        ? [...r.emoji.trim()].slice(0, 2).join("")
        : "✨";
    out.push({ emoji, text: body });
    if (out.length === STARTER_COUNT) break;
  }
  return out.length === STARTER_COUNT ? out : [];
}

export interface StoredStarters {
  items: Starter[];
  source: StarterSource;
  generatedAt: Date;
}

/** The saved list for a person and bot, if any. */
export async function storedStarters(
  db: Database,
  userId: string,
  botId: string,
): Promise<StoredStarters | null> {
  const [row] = await db.execute<{
    items: Starter[];
    source: StarterSource;
    generated_at: Date | string;
  }>(sql`
    select items, source, generated_at from public.chat_starters
    where user_id = ${userId}::uuid and bot_id = ${botId}::uuid`);
  return row
    ? { items: row.items, source: row.source, generatedAt: new Date(row.generated_at) }
    : null;
}

/**
 * Lists written before starters followed the bot's role can be off-role (a coding bot offered meal
 * plans), so anything older is written again.
 */
export const STARTERS_REVISED_AT = new Date("2026-11-17T09:00:00Z");

/**
 * Whether a saved list should be written again: old, or a stand-in, or written before the current
 * rules, or the bot got an app since.
 */
export function startersStale(
  saved: StoredStarters | null,
  appAddedAt: Date | null,
  now = new Date(),
) {
  if (!saved || saved.items.length === 0) return true;
  if (saved.generatedAt < STARTERS_REVISED_AT) return true;
  const age = now.getTime() - saved.generatedAt.getTime();
  if (age > (saved.source === "ai" ? AI_STARTERS_TTL_MS : RULE_STARTERS_TTL_MS)) return true;
  // A newly connected app is worth a new list, but not more than once every 10 minutes.
  return !!appAddedAt && appAddedAt > saved.generatedAt && age > 10 * 60 * 1000;
}

/** When the bot last got an app. */
export async function lastAppAdded(db: Database, botId: string): Promise<Date | null> {
  const [row] = await db.execute<{ at: Date | string | null }>(
    sql`select max(created_at) as at from public.bot_integrations where bot_id = ${botId}::uuid`,
  );
  return row?.at ? new Date(row.at) : null;
}

export type StarterComplete = (input: {
  orgId: string;
  botId: string;
  userId: string;
  system: string;
  text: string;
  maxOutputTokens?: number;
  purpose: string;
}) => Promise<{ text: string; model: string } | null>;

/**
 * Writes a new list for a person and bot when theirs is stale (the worker's job, D-338). The model
 * writes it when it can; rules otherwise. Returns what was saved, or null when the bot is gone or
 * the person can't see it.
 */
export async function refreshStarters(
  deps: { db: Database; complete?: StarterComplete },
  ids: { userId: string; orgId: string; botId: string },
  now = new Date(),
): Promise<StoredStarters | null> {
  const { db } = deps;
  // Only a member of the bot's workspace gets starters written with its model and budget.
  const [member] = await db.execute<{ ok: boolean }>(sql`
    select exists (select 1 from public.memberships m where m.user_id = ${ids.userId}::uuid
      and m.org_id = ${ids.orgId}::uuid) as ok`);
  if (!member?.ok) return null;
  const saved = await storedStarters(db, ids.userId, ids.botId);
  if (!startersStale(saved, await lastAppAdded(db, ids.botId), now)) return saved;
  const signals = await starterSignals(db, ids, now);
  if (!signals) return null;
  let items: Starter[] = [];
  let model: string | null = null;
  if (deps.complete) {
    const r = await deps
      .complete({
        ...ids,
        system: STARTERS_SYSTEM,
        text: starterPrompt(signals),
        maxOutputTokens: 600,
        purpose: "starters",
      })
      .catch(() => null);
    if (r) {
      items = parseStarters(r.text, { technical: technicalRole(signals.persona) });
      model = r.model;
    }
  }
  const source: StarterSource = items.length ? "ai" : "rules";
  if (!items.length) items = ruleStarters(signals);
  await db.execute(sql`
    insert into public.chat_starters (user_id, bot_id, org_id, items, source, model, generated_at)
    values (${ids.userId}::uuid, ${ids.botId}::uuid, ${ids.orgId}::uuid, ${JSON.stringify(items)}::jsonb,
            ${source}, ${source === "ai" ? model : null}, ${now.toISOString()}::timestamptz)
    on conflict (user_id, bot_id) do update set items = excluded.items, source = excluded.source,
      model = excluded.model, org_id = excluded.org_id, generated_at = excluded.generated_at`);
  return { items, source, generatedAt: now };
}
