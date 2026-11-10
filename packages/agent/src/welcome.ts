/**
 * Welcome chat (SPEC: Post-v1 roadmap → Welcome chat; D-129). A new person's first chat with their
 * personal bot. The opening is scripted: ordinary bot messages with A2UI cards, answered without a
 * model call. Picks become memories and the bot's instructions; then come one main connection,
 * a first piece of value (a catch-up with consent, or a first task), the setup interview (D-105)
 * in the same chat, and a "What I learned" card.
 *
 * Card actions named "welcome.*" come back here. Actions named "app:*" are handled by the app
 * itself (open a connection, a screen, or an invite) and never reach the server.
 */
import { randomUUID } from "node:crypto";
import type { Database } from "@kasama/db";
import { defaultModelFor } from "@kasama/domain";
import { sql } from "drizzle-orm";
import { surfaceMessages } from "./tools/ui.ts";
import { contentKeys } from "@kasama/db";

export const WELCOME_FOCUS = [
  { id: "email_calendar", label: "Email and calendar" },
  { id: "work_projects", label: "Work projects" },
  { id: "coding", label: "Coding" },
  { id: "research", label: "Research" },
  { id: "sales", label: "Sales and customers" },
  { id: "errands", label: "Personal errands" },
  // Wave 4 (D-150): health and habits, from the phone's own data.
  { id: "health", label: "Health and habits" },
  { id: "other", label: "Something else" },
] as const;
export type Focus = (typeof WELCOME_FOCUS)[number]["id"];
export type Scope = "just_me" | "team" | "business";

export interface WelcomeState {
  step: "focus" | "scope" | "connect" | "first_value" | "offer_setup" | "interview" | "learned" | "done";
  focus: Focus[];
  other?: string;
  scope?: Scope;
  learned?: string[];
}

/** The main connection for each pick (apps from the catalog; "More apps" covers the rest). */
export const MAIN_CONNECTION: Record<Focus, string[]> = {
  email_calendar: ["google_calendar", "gmail"],
  work_projects: ["notion", "linear", "atlassian"],
  coding: ["github"],
  research: [],
  sales: ["hubspot", "google_calendar"],
  errands: ["google_calendar"],
  health: [],
  other: [],
};
const APP_NAMES: Record<string, string> = {
  google_calendar: "Google Calendar",
  gmail: "Gmail",
  notion: "Notion",
  linear: "Linear",
  atlassian: "Jira",
  github: "GitHub",
  hubspot: "HubSpot",
};
/** Starter bots worth suggesting for each pick (D-105 templates). */
export const STARTER_FOR: Record<Focus, string[]> = {
  email_calendar: ["executive-assistant"],
  work_projects: ["project-manager"],
  coding: ["software-engineer"],
  research: ["researcher"],
  sales: ["sales-assistant"],
  errands: ["personal-assistant"],
  health: ["personal-assistant"],
  other: [],
};

const INTRO: Record<Focus, string> = {
  email_calendar: "I can keep an eye on your calendar, draft replies, and tell you each morning what needs you.",
  work_projects: "I can turn projects into tasks, keep them moving, and tell you when something needs a decision.",
  coding: "I can work in your repositories on my computer: read code, fix issues and open pull requests for you to review.",
  research: "I can dig into a topic, compare sources, and write it up as a report or a page you can share.",
  sales: "I can research the people and companies you talk to, prepare for meetings, and keep your CRM tidy.",
  errands: "I can take small things off your plate: bookings, reminders, comparisons and forms.",
  health: "I can keep track of your sleep, activity and workouts from your phone, notice how they compare with your usual, and help you build habits. I'm not a doctor and won't give medical advice.",
  other: "Tell me a bit more about what you need and I'll suggest how to start.",
};

/** The first task for each pick when nothing is connected: a prompt and how the answer is phrased. */
const FIRST_TASK: Record<Focus, { label: string; placeholder: string; prefix: string }> = {
  email_calendar: { label: "What should I keep an eye on this week?", placeholder: "A deadline, a meeting, a reply you're waiting for", prefix: "Please keep an eye on this for me: " },
  work_projects: { label: "Tell me a project you're working on.", placeholder: "Launch the new pricing page by Friday", prefix: "Let's set up this project: " },
  coding: { label: "Point me at a repo.", placeholder: "https://github.com/you/your-repo", prefix: "Please take a look at this repository and tell me what you'd improve first: " },
  research: { label: "Give me a topic to research.", placeholder: "The best CRM for a 5-person team", prefix: "Please research this and write it up as a short report: " },
  sales: { label: "Who should I research first?", placeholder: "A company or a person", prefix: "Please research this for an upcoming conversation: " },
  errands: { label: "What's one errand I can take off your plate?", placeholder: "Find a dentist near me who takes my insurance", prefix: "Please help me with this errand: " },
  health: { label: "What habit would you like to build?", placeholder: "Sleep before 11 on weeknights", prefix: "Please help me build this habit, and check in on it: " },
  other: { label: "What would you like me to do first?", placeholder: "Describe the task", prefix: "" },
};

export const CATCHUP_TEXT =
  "Yes, catch me up: look at my next 14 days of calendar and, if you can read my inbox, the last 14 days of email.";

/** What the bot is told in the welcome chat (appended to its instructions). */
export const WELCOME_GUIDE = `You are in this person's welcome chat. When they ask for a catch-up: look at the next 14 days of their calendar and, only if you have inbox access, the last 14 days of email. Reply with "Here's what I noticed" and 3-5 short items, then show up to three one-tap task cards with ui.show (one Button each whose action context holds the task), and offer a morning brief (check-ins). Don't send, change or delete anything during the catch-up. For a first task, do it well and briefly.`;

const sid = () => `ui_${randomUUID().replaceAll("-", "").slice(0, 16)}`;
const text = (id: string, t: string, variant?: "caption") => ({ id, component: "Text", text: t, ...(variant ? { variant } : {}) });
const button = (id: string, label: string, action: string, context: Record<string, unknown> = {}, variant: "primary" | "default" | "borderless" = "default") => [
  { id, component: "Button", child: `${id}_t`, variant, action: { event: { name: action, context } } },
  text(`${id}_t`, label),
];
const card = (components: Array<Record<string, unknown>>, data?: Record<string, unknown>) => {
  const surface = sid();
  return { type: "ui", surface_id: surface, messages: surfaceMessages(surface, components, data) };
};
const column = (children: string[], rest: Array<Record<string, unknown>>) => [{ id: "root", component: "Column", children }, ...rest];

export function focusCard() {
  return card(
    column(["q", "pick", "other", "row"], [
      text("q", "## What should I help with first?\nPick up to three."),
      {
        id: "pick",
        component: "ChoicePicker",
        options: WELCOME_FOCUS.map((f) => ({ label: f.label, value: f.id })),
        value: { "@path": "/form/focus" },
        variant: "multipleSelection",
        displayStyle: "chips",
      },
      { id: "other", component: "TextField", label: "Something else? (optional)", value: { "@path": "/form/other" }, variant: "shortText" },
      { id: "row", component: "Row", children: ["go", "skip"] },
      ...button("go", "Continue", "welcome.focus", { focus: { "@path": "/form/focus" }, other: { "@path": "/form/other" } }, "primary"),
      ...button("skip", "Skip", "welcome.focus", { skip: true }, "borderless"),
    ]),
    { form: { focus: [], other: "" } },
  );
}

export function scopeCard() {
  return card(
    column(["q", "row"], [
      text("q", "## Just me, my team or my business?"),
      { id: "row", component: "Row", children: ["me", "team", "biz", "skip"] },
      ...button("me", "Just me", "welcome.scope", { scope: "just_me" }, "primary"),
      ...button("team", "My team", "welcome.scope", { scope: "team" }),
      ...button("biz", "My business", "welcome.scope", { scope: "business" }),
      ...button("skip", "Skip", "welcome.scope", { skip: true }, "borderless"),
    ]),
  );
}

export function openingMessage(botName: string) {
  return [
    { type: "text", text: `Hi! I'm ${botName}, your assistant. I can work on my own computer, use your apps when you connect them, and remember how you like things done. A couple of quick questions so I can start in the right place.` },
    focusCard(),
  ];
}

const listLabels = (focus: Focus[], other?: string) =>
  focus.map((f) => (f === "other" && other ? other : (WELCOME_FOCUS.find((x) => x.id === f)?.label ?? f))).join(", ");

/** The intro for the picks, the main connection card, and the model / invite cards when needed. */
export function introMessage(s: WelcomeState, o: { hasModel: boolean }) {
  const focus = s.focus.length ? s.focus : [];
  const intro = focus.length
    ? `Great. ${focus.map((f) => INTRO[f]).join(" ")}`
    : "No problem. I can help with email and calendar, projects, code, research and errands. Here's how to get the most out of me.";
  const apps = [...new Set(focus.flatMap((f) => MAIN_CONNECTION[f]))].slice(0, 3);
  const parts: Array<Record<string, unknown>> = [{ type: "text", text: intro }];
  if (!o.hasModel)
    parts.push(
      card(
        column(["t", "row"], [
          text("t", "First, I need a model to think with. Pick one way:"),
          { id: "row", component: "Row", children: ["chatgpt", "key", "local"] },
          ...button("chatgpt", "Continue with ChatGPT", "app:route", { path: "/settings/keys", provider: "chatgpt" }, "primary"),
          ...button("key", "Add a model key", "app:route", { path: "/settings/keys" }),
          ...button("local", "Use a local model", "app:route", { path: "/settings/keys", provider: "openai_compatible" }),
        ]),
      ),
    );
  if (apps.length) {
    const names = apps.map((a) => APP_NAMES[a] ?? a);
    parts.push(
      card(
        column(["t", "apps", "row"], [
          text("t", `Connect ${names.join(" or ")} so I can ${focus.includes("coding") ? "work on your code" : "see what you're working with"}. You choose what I can do, and I ask before anything risky.`),
          { id: "apps", component: "Row", children: apps.map((a) => `c_${a}`) },
          ...apps.flatMap((a, i) => button(`c_${a}`, `Connect ${APP_NAMES[a] ?? a}`, "app:connect", { app: a }, i === 0 ? "primary" : "default")),
          { id: "row", component: "Row", children: ["more", "next"] },
          ...button("more", "More apps", "app:route", { path: "/settings/integrations" }, "borderless"),
          ...button("next", "Done, next", "welcome.next"),
        ]),
      ),
    );
  } else parts.push(...firstTaskMessage(s));
  // Phone connections (Wave 4, D-149/D-150): health, places and the phone's calendar live on the phone.
  const phone = focus.filter((f) => f === "health" || f === "errands");
  if (phone.length)
    parts.push(
      card(
        column(["t", "row"], [
          text(
            "t",
            focus.includes("health")
              ? "Share your sleep, activity and workouts from your phone (Apple Health or Health Connect). You choose each kind, and only I can read it, only in your chats."
              : "Share your phone's calendar and places with me, so I can plan around your day. You choose each kind.",
          ),
          { id: "row", component: "Row", children: ["phone"] },
          ...button("phone", "Choose what to share", "app:route", { path: "/settings/devices" }, apps.length ? "default" : "primary"),
        ]),
      ),
    );
  if (s.scope === "team" || s.scope === "business")
    parts.push(
      card(
        column(["t", "inv"], [
          text("t", s.scope === "team" ? "Want your team in here? Invite them; they get their own chats with shared bots." : "Bring in the people you work with; shared bots can help everyone."),
          ...button("inv", "Invite people", "app:invite"),
        ]),
      ),
    );
  return parts;
}

/** The first task card for the first pick. */
export function firstTaskMessage(s: WelcomeState) {
  const t = FIRST_TASK[s.focus[0] ?? "other"];
  return [
    card(
      column(["q", "in", "go"], [
        text("q", `## ${t.label}`),
        { id: "in", component: "TextField", label: t.placeholder, value: { "@path": "/form/text" }, variant: "longText" },
        ...button("go", "Go", "welcome.task", { text: { "@path": "/form/text" }, prefix: t.prefix }, "primary"),
      ]),
      { form: { text: "" } },
    ),
  ];
}

export function catchupMessage(inbox: boolean) {
  return [
    card(
      column(["t", "row"], [
        text("t", `Want a quick catch-up? I'll read your next 14 days of calendar${inbox ? " and the last 14 days of email" : ""} and tell you what stands out. I won't send or change anything.`),
        { id: "row", component: "Row", children: ["yes", "no"] },
        ...button("yes", "Catch me up", "welcome.catchup", {}, "primary"),
        ...button("no", "Not now", "welcome.nocatchup", {}, "borderless"),
      ]),
    ),
  ];
}

export function setupOfferMessage() {
  return [
    { type: "text", text: "Next: a few quick questions so I work the way you like. It takes a minute." },
    card(
      column(["row"], [
        { id: "row", component: "Row", children: ["yes", "later"] },
        ...button("yes", "Let's do it", "welcome.setup", {}, "primary"),
        ...button("later", "Later", "welcome.later", {}, "borderless"),
      ]),
    ),
  ];
}

export function learnedMessage(memories: Array<{ id: string; content: string }>, botId: string) {
  return [
    { type: "text", text: memories.length ? "Here's what I learned. Untick anything that's wrong." : "All set. Ask me anything." },
    ...(memories.length
      ? [
          card(
            column(["pick", "row"], [
              {
                id: "pick",
                component: "ChoicePicker",
                options: memories.map((m) => ({ label: m.content, value: m.id })),
                value: { "@path": "/form/keep" },
                variant: "multipleSelection",
                displayStyle: "checkbox",
              },
              { id: "row", component: "Row", children: ["keep", "edit"] },
              ...button("keep", "Looks right", "welcome.learned", { keep: { "@path": "/form/keep" } }, "primary"),
              ...button("edit", "Edit in Memory", "app:route", { path: `/bots/${botId}/memory` }, "borderless"),
            ]),
            { form: { keep: memories.map((m) => m.id) } },
          ),
        ]
      : []),
  ];
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

const CHAT_PROVIDERS = ["openai", "anthropic", "google", "xai", "openrouter", "openai_compatible", "chatgpt"];

/** Whether the bot can think yet; gives it the workspace's first usable key when it has none. */
export async function ensureBotModel(db: Database, botId: string, orgId: string, overrides: Record<string, string | undefined> = {}) {
  const [b] = await db.execute<{ primary: unknown }>(sql`select model_policy -> 'primary' as primary from public.bots where id = ${botId}::uuid`);
  if (b?.primary) return true;
  const creds = await db.execute<{ id: string; provider: string }>(sql`
    select id, provider from public.model_credentials where org_id = ${orgId}::uuid
      and provider = any(array(select jsonb_array_elements_text(${JSON.stringify(CHAT_PROVIDERS)}::jsonb))) order by created_at`);
  for (const c of creds) {
    const model = defaultModelFor(c.provider, overrides);
    if (!model) continue;
    await db.execute(sql`update public.bots set model_policy = jsonb_set(model_policy, '{primary}', ${JSON.stringify({ credential_id: c.id, model })}::jsonb) where id = ${botId}::uuid`);
    return true;
  }
  return false;
}

/** A bot message with no model behind it: a completed run, its events, and the message. */
export async function postScripted(
  db: Database,
  c: { orgId: string; botId: string; conversationId: string; userId: string },
  parts: Array<Record<string, unknown>>,
  user?: { text: string; uiAction?: Record<string, unknown> },
) {
  const [run] = await db.execute<{ id: string }>(sql`
    insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger, status, started_at, ended_at)
    values (${c.orgId}::uuid, ${c.botId}::uuid, ${c.conversationId}::uuid, ${c.userId}::uuid, 'welcome', 'completed', now(), now()) returning id`);
  const runId = run?.id as string;
  let userMessageId: string | null = null;
  if (user) {
    const [m] = await db.execute<{ id: string }>(sql`
      insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
      values (${c.orgId}::uuid, ${c.conversationId}::uuid, 'user', ${c.userId}::uuid,
              ${contentKeys.sealJson(c.orgId, [{ type: "text", text: user.text }, ...(user.uiAction ? [{ type: "ui_action", ...user.uiAction }] : [])])}::jsonb, ${runId}::uuid)
      returning id`);
    userMessageId = m?.id ?? null;
  }
  const messageId = randomUUID();
  await db.execute(sql`
    insert into public.messages (id, org_id, conversation_id, role, content, run_id, bot_id, created_at)
    values (${messageId}::uuid, ${c.orgId}::uuid, ${c.conversationId}::uuid, 'assistant', ${contentKeys.sealJson(c.orgId, parts)}::jsonb, ${runId}::uuid, ${c.botId}::uuid,
            clock_timestamp())`);
  let seq = 1;
  for (const [type, payload] of [
    ["run.started", { model: "scripted", trigger: "welcome", computer_id: null }],
    ["message.completed", { message_id: messageId, content: parts }],
    ["run.completed", { final_message_id: messageId }],
  ] as const)
    await db.execute(sql`
      insert into public.run_events (run_id, seq, org_id, bot_id, type, payload)
      values (${runId}::uuid, ${seq++}, ${c.orgId}::uuid, ${c.botId}::uuid, ${type}, ${contentKeys.sealJson(c.orgId, payload)}::jsonb)`);
  await db.execute(sql`update public.conversations set last_message_at = now() where id = ${c.conversationId}::uuid`);
  return { runId, messageId, userMessageId };
}

async function saveState(db: Database, conversationId: string, s: WelcomeState, purpose?: string) {
  await db.execute(sql`
    update public.conversations set welcome = ${JSON.stringify(s)}::jsonb, purpose = coalesce(${purpose ?? null}, purpose) where id = ${conversationId}::uuid`);
}

async function hasConnection(db: Database, orgId: string, apps: string[]) {
  const [r] = await db.execute<{ n: number }>(sql`
    select count(*)::int as n from public.integrations
    where org_id = ${orgId}::uuid and status <> 'error' and (config ->> 'app' = any(array(select jsonb_array_elements_text(${JSON.stringify(apps)}::jsonb)))
      or (kind = 'composio' and config ->> 'managed' = 'true'))`);
  return (r?.n ?? 0) > 0;
}

export interface WelcomeAction {
  name: string;
  surface_id: string;
  context?: Record<string, unknown>;
}

export interface WelcomeDeps {
  db: Database;
  modelOverrides?: Record<string, string | undefined>;
}

/**
 * Handles a "welcome.*" card action. Scripted steps answer at once (no run is queued); steps that
 * need the model return a run to start, created like a normal chat run.
 */
export async function handleWelcomeAction(
  d: WelcomeDeps,
  c: { orgId: string; botId: string; conversationId: string; userId: string },
  action: WelcomeAction,
  summary: string,
): Promise<{ runId: string; messageId: string; queue: boolean }> {
  const { db } = d;
  const [conv] = await db.execute<{ welcome: WelcomeState | null }>(sql`select welcome from public.conversations where id = ${c.conversationId}::uuid`);
  const s: WelcomeState = conv?.welcome ?? { step: "focus", focus: [] };
  const ctx = action.context ?? {};
  const uiAction = { surface_id: action.surface_id, name: action.name, context: ctx };
  const scripted = async (parts: Array<Record<string, unknown>>) => {
    const r = await postScripted(db, c, parts, { text: summary, uiAction });
    await saveState(db, c.conversationId, s);
    return { runId: r.runId, messageId: r.userMessageId as string, queue: false };
  };
  const memory = async (content: string) =>
    db.execute(sql`insert into public.memories (org_id, bot_id, kind, content, importance, pinned)
      values (${c.orgId}::uuid, ${c.botId}::uuid, 'preference', ${contentKeys.seal(c.orgId, content.slice(0, 8000))}, 0.8, true)`);
  /** A user message and a queued normal run (the model's turn). */
  const modelTurn = async (text: string, purpose?: string) => {
    await ensureBotModel(db, c.botId, c.orgId, d.modelOverrides);
    const [run] = await db.execute<{ id: string }>(sql`
      insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger)
      values (${c.orgId}::uuid, ${c.botId}::uuid, ${c.conversationId}::uuid, ${c.userId}::uuid, 'chat') returning id`);
    const [m] = await db.execute<{ id: string }>(sql`
      insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
      values (${c.orgId}::uuid, ${c.conversationId}::uuid, 'user', ${c.userId}::uuid,
              ${contentKeys.sealJson(c.orgId, [{ type: "text", text }, { type: "ui_action", ...uiAction }])}::jsonb, ${run?.id}::uuid) returning id`);
    await saveState(db, c.conversationId, s, purpose);
    return { runId: run?.id as string, messageId: m?.id as string, queue: true };
  };

  switch (action.name) {
    case "welcome.focus": {
      const picked = Array.isArray(ctx.focus) ? (ctx.focus as string[]) : [];
      s.focus = ctx.skip ? [] : (picked.filter((f) => WELCOME_FOCUS.some((x) => x.id === f)) as Focus[]).slice(0, 3);
      s.other = typeof ctx.other === "string" && ctx.other.trim() ? ctx.other.trim().slice(0, 300) : undefined;
      if (s.other && !s.focus.includes("other")) s.focus = [...s.focus, "other" as const].slice(0, 3);
      if (s.focus.length) {
        await memory(`Wants help first with: ${listLabels(s.focus, s.other)}.`);
        await db.execute(sql`update public.bots set persona_md = trim(persona_md || ${`\n\n## What they want help with\n${listLabels(s.focus, s.other)}`}) where id = ${c.botId}::uuid`);
      }
      s.step = "scope";
      return scripted([scopeCard()]);
    }
    case "welcome.scope": {
      s.scope = ctx.skip ? undefined : (["just_me", "team", "business"].includes(String(ctx.scope)) ? (ctx.scope as Scope) : undefined);
      if (s.scope) await memory(s.scope === "just_me" ? "Uses Kasama just for themselves." : s.scope === "team" ? "Uses Kasama with their team." : "Uses Kasama for their business.");
      const hasModel = await ensureBotModel(db, c.botId, c.orgId, d.modelOverrides);
      const apps = s.focus.flatMap((f) => MAIN_CONNECTION[f]);
      s.step = apps.length ? "connect" : "first_value";
      const starters = [...new Set(s.focus.flatMap((f) => STARTER_FOR[f]))];
      const parts = introMessage(s, { hasModel });
      if (starters.length)
        parts.push({ type: "text", text: `Later you might add a ${starters.map((t) => t.replaceAll("-", " ")).join(" or a ")} bot; I can set one up when you're ready.` });
      return scripted(parts);
    }
    case "welcome.next": {
      const calendarOrMail = await hasConnection(db, c.orgId, ["google_calendar", "gmail", "gmail_inbox"]);
      s.step = "first_value";
      if (calendarOrMail) return scripted(catchupMessage(await hasConnection(db, c.orgId, ["gmail_inbox"])));
      return scripted(firstTaskMessage(s));
    }
    case "welcome.nocatchup":
      s.step = "first_value";
      return scripted(firstTaskMessage(s));
    case "welcome.catchup":
      s.step = "first_value";
      return modelTurn(CATCHUP_TEXT);
    case "welcome.task": {
      const t = typeof ctx.text === "string" ? ctx.text.trim() : "";
      if (!t) return scripted([{ type: "text", text: "Type what you'd like first, then tap Go." }, ...firstTaskMessage(s)]);
      s.step = "first_value";
      return modelTurn(`${typeof ctx.prefix === "string" ? ctx.prefix : ""}${t}`.slice(0, 4000));
    }
    case "welcome.setup":
      s.step = "interview";
      await db.execute(sql`update public.bots set setup_status = 'pending' where id = ${c.botId}::uuid`);
      return modelTurn("Let's get you set up.", "setup");
    case "welcome.later":
      s.step = "done";
      await saveState(db, c.conversationId, s, "chat");
      return scripted([{ type: "text", text: "Sure. When you want, say \"set me up\". Ask me anything." }]);
    case "welcome.learned": {
      const keep = new Set(Array.isArray(ctx.keep) ? (ctx.keep as string[]) : []);
      const drop = (s.learned ?? []).filter((id) => !keep.has(id));
      if (drop.length)
        await db.execute(sql`delete from public.memories where bot_id = ${c.botId}::uuid and id = any(array(select jsonb_array_elements_text(${JSON.stringify(drop)}::jsonb))::uuid[])`);
      s.step = "done";
      await saveState(db, c.conversationId, s, "chat");
      return scripted([{ type: "text", text: drop.length ? `Forgot ${drop.length === 1 ? "that one" : `those ${drop.length}`}. You're all set; ask me anything.` : "You're all set. Ask me anything." }]);
    }
    default:
      return scripted([{ type: "text", text: "Let's keep going." }]);
  }
}

/**
 * After a model run in the welcome chat: offer the setup interview once the first value is done,
 * and show "What I learned" once the interview saved its answers.
 */
export async function afterWelcomeRun(db: Database, run: { runId: string; orgId: string; botId: string; conversationId: string | null; userId: string | null }) {
  if (!run.conversationId || !run.userId) return;
  const [conv] = await db.execute<{ welcome: WelcomeState | null; created_at: string }>(
    sql`select welcome, created_at from public.conversations where id = ${run.conversationId}::uuid`,
  );
  const s = conv?.welcome;
  if (!s) return;
  const c = { orgId: run.orgId, botId: run.botId, conversationId: run.conversationId, userId: run.userId };
  if (s.step === "first_value") {
    s.step = "offer_setup";
    await postScripted(db, c, setupOfferMessage());
    await saveState(db, run.conversationId, s);
  } else if (s.step === "interview") {
    const [b] = await db.execute<{ setup_status: string }>(sql`select setup_status from public.bots where id = ${run.botId}::uuid`);
    if (b?.setup_status !== "done") return;
    const mems = await db.execute<{ id: string; content: string }>(sql`
      select id, content from public.memories where bot_id = ${run.botId}::uuid and created_at >= ${conv?.created_at}::timestamptz
      order by created_at limit 10`);
    s.step = "learned";
    s.learned = mems.map((m) => m.id);
    await postScripted(db, c, learnedMessage(mems, run.botId));
    await saveState(db, run.conversationId, s);
  }
}

/** The welcome chat this person already has, if any. */
export async function existingWelcome(db: Database, userId: string) {
  const [w] = await db.execute<{ org_id: string; bot_id: string; id: string }>(sql`
    select c.org_id, c.bot_id, c.id from public.conversations c
    where c.created_by = ${userId}::uuid and c.welcome is not null order by c.created_at limit 1`);
  return w ? { orgId: w.org_id, botId: w.bot_id, conversationId: w.id } : null;
}

/** In a new personal workspace: the personal bot and its welcome chat, with the scripted opening. */
export async function startWelcome(
  db: Database,
  a: { orgId: string; userId: string; firstName: string; botName: string; mascot?: string },
): Promise<{ orgId: string; botId: string; conversationId: string }> {
  return db.transaction(async (tx) => {
    const [bot] = await tx.execute<{ id: string }>(sql`
      insert into public.bots (org_id, created_by, name, persona_md, avatar_url, visibility)
      values (${a.orgId}::uuid, ${a.userId}::uuid, ${a.botName}, ${`You are ${a.botName}, ${a.firstName || "this person"}'s personal assistant. Be warm, brief and practical.`},
              ${`mascot:${a.mascot ?? "winky"}`}, 'private')
      returning id`);
    const [conv] = await tx.execute<{ id: string }>(sql`
      insert into public.conversations (org_id, bot_id, title, created_by, last_message_at, purpose, welcome)
      values (${a.orgId}::uuid, ${bot?.id}::uuid, 'Welcome', ${a.userId}::uuid, now(), 'welcome', ${JSON.stringify({ step: "focus", focus: [] })}::jsonb)
      returning id`);
    await tx.execute(sql`
      insert into public.messages (org_id, conversation_id, role, content, bot_id)
      values (${a.orgId}::uuid, ${conv?.id}::uuid, 'assistant', ${contentKeys.sealJson(a.orgId, openingMessage(a.botName))}::jsonb, ${bot?.id}::uuid)`);
    return { orgId: a.orgId, botId: bot?.id as string, conversationId: conv?.id as string };
  });
}
