/**
 * Welcome chat (SPEC: Post-v1 roadmap → Welcome chat; D-129). A new person's first chat with their
 * personal bot. The opening is scripted: ordinary bot messages with A2UI cards, answered without a
 * model call. After the name comes Google (D-204): connecting it starts the catch-up at once, and
 * the picks are skipped. Otherwise, picks become memories and the bot's instructions; then come
 * one main connection, a first piece of value (a catch-up with consent, or a first task), the
 * setup interview (D-105) in the same chat, and a "What I learned" card.
 *
 * Card actions named "welcome.*" come back here. Actions named "app:*" are handled by the app
 * itself (open a connection, a screen, or an invite) and never reach the server.
 */
import { randomUUID } from "node:crypto";
import type { Database } from "@casama/db";
import { contentKeys } from "@casama/db";
import { defaultModelFor } from "@casama/domain";
import { sql } from "drizzle-orm";
import { PLATFORM_OPENROUTER_CREDENTIAL_ID } from "./credentials.ts";
import { composioDirectory, loadIntegration } from "./integrations.ts";
import { surfaceMessages } from "./tools/ui.ts";

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

/** How Google connects on this server (D-204); absent when it can't, so the Google card is skipped. */
export type GoogleRoute = "composio" | "direct";

export interface WelcomeState {
  step:
    | "name"
    | "google"
    | "focus"
    | "scope"
    | "model"
    | "connect"
    | "phone"
    | "invite"
    | "first_value"
    | "offer_setup"
    | "interview"
    | "learned"
    | "done";
  focus: Focus[];
  other?: string;
  scope?: Scope;
  learned?: string[];
  /** Offer Google right after the name (D-204), and how it connects. */
  google?: GoogleRoute;
  /** They said "Not now" to Google, so later cards don't ask again. */
  googleDeclined?: boolean;
  /** Google is connected (or its sign-in was started) from the welcome chat. */
  connected?: boolean;
}

/** The Google apps the welcome chat connects and the catch-up reads. */
const GOOGLE_APPS = ["google_calendar", "gmail"];

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
  email_calendar:
    "I can keep an eye on your calendar, draft replies, and tell you each morning what needs you.",
  work_projects:
    "I can turn projects into tasks, keep them moving, and tell you when something needs a decision.",
  coding:
    "I can work in your repositories on my computer: read code, fix issues and open pull requests for you to review.",
  research:
    "I can dig into a topic, compare sources, and write it up as a report or a page you can share.",
  sales:
    "I can research the people and companies you talk to, prepare for meetings, and keep your CRM tidy.",
  errands: "I can take small things off your plate: bookings, reminders, comparisons and forms.",
  health:
    "I can keep track of your sleep, activity and workouts from your phone, notice how they compare with your usual, and help you build habits. I'm not a doctor and won't give medical advice.",
  other: "Tell me a bit more about what you need and I'll suggest how to start.",
};

/** The first task for each pick when nothing is connected: a prompt and how the answer is phrased. */
const FIRST_TASK: Record<Focus, { label: string; placeholder: string; prefix: string }> = {
  email_calendar: {
    label: "What should I keep an eye on this week?",
    placeholder: "A deadline, a meeting, a reply you're waiting for",
    prefix: "Please keep an eye on this for me: ",
  },
  work_projects: {
    label: "Tell me a project you're working on.",
    placeholder: "Launch the new pricing page by Friday",
    prefix: "Let's set up this project: ",
  },
  coding: {
    label: "Point me at a repo.",
    placeholder: "https://github.com/you/your-repo",
    prefix: "Please take a look at this repository and tell me what you'd improve first: ",
  },
  research: {
    label: "Give me a topic to research.",
    placeholder: "The best CRM for a 5-person team",
    prefix: "Please research this and write it up as a short report: ",
  },
  sales: {
    label: "Who should I research first?",
    placeholder: "A company or a person",
    prefix: "Please research this for an upcoming conversation: ",
  },
  errands: {
    label: "What's one errand I can take off your plate?",
    placeholder: "Find a dentist near me who takes my insurance",
    prefix: "Please help me with this errand: ",
  },
  health: {
    label: "What habit would you like to build?",
    placeholder: "Sleep before 11 on weeknights",
    prefix: "Please help me build this habit, and check in on it: ",
  },
  other: {
    label: "What would you like me to do first?",
    placeholder: "Describe the task",
    prefix: "",
  },
};

export const CATCHUP_TEXT =
  "Yes, catch me up: look at my next 14 days of calendar and, if you can read my inbox, the last 14 days of email.";
/** The catch-up when only the calendar is connected (D-204). */
export const CATCHUP_CALENDAR_TEXT =
  "Yes, catch me up: look at my next 14 days of calendar and tell me what stands out.";

/** What the bot is told in the welcome chat (appended to its instructions). */
export const WELCOME_GUIDE = `You are in this person's welcome chat. When they ask for a catch-up: look at the next 14 days of their calendar and, only if you have inbox access, the last 14 days of email. Reply with "Here's what I noticed" and 3-5 short items, then show up to three one-tap task cards with ui.show (one Button each whose action context holds the task), and offer a morning brief (check-ins). Don't send, change or delete anything during the catch-up. For a first task, do it well and briefly.`;

const sid = () => `ui_${randomUUID().replaceAll("-", "").slice(0, 16)}`;
const text = (id: string, t: string, variant?: "caption") => ({
  id,
  component: "Text",
  text: t,
  ...(variant ? { variant } : {}),
});
const button = (
  id: string,
  label: string,
  action: string,
  context: Record<string, unknown> = {},
  variant: "primary" | "default" | "borderless" = "default",
) => [
  {
    id,
    component: "Button",
    child: `${id}_t`,
    variant,
    action: { event: { name: action, context } },
  },
  text(`${id}_t`, label),
];
const card = (components: Array<Record<string, unknown>>, data?: Record<string, unknown>) => {
  const surface = sid();
  return { type: "ui", surface_id: surface, messages: surfaceMessages(surface, components, data) };
};
const column = (children: string[], rest: Array<Record<string, unknown>>) => [
  { id: "root", component: "Column", children },
  ...rest,
];

/** About you (D-169): what to call the person, the sign-in first name filled in. */
export function nameCard(firstName: string) {
  return card(
    column(
      ["q", "name", "row"],
      [
        text("q", "## What should I call you?"),
        {
          id: "name",
          component: "TextField",
          label: "Your name",
          value: { "@path": "/form/name" },
          variant: "shortText",
        },
        { id: "row", component: "Row", children: ["go", "skip"] },
        ...button("go", "Continue", "welcome.name", { name: { "@path": "/form/name" } }, "primary"),
        ...button("skip", "Skip", "welcome.name", { skip: true }, "borderless"),
      ],
    ),
    { form: { name: firstName.trim().slice(0, 60) } },
  );
}

export function focusCard() {
  return card(
    column(
      ["q", "pick", "other", "row"],
      [
        text("q", "## What should I help with first?\nPick up to three."),
        {
          id: "pick",
          component: "ChoicePicker",
          options: WELCOME_FOCUS.map((f) => ({ label: f.label, value: f.id })),
          value: { "@path": "/form/focus" },
          variant: "multipleSelection",
          displayStyle: "chips",
        },
        {
          id: "other",
          component: "TextField",
          label: "Something else? (optional)",
          value: { "@path": "/form/other" },
          variant: "shortText",
        },
        { id: "row", component: "Row", children: ["go", "skip"] },
        ...button(
          "go",
          "Continue",
          "welcome.focus",
          { focus: { "@path": "/form/focus" }, other: { "@path": "/form/other" } },
          "primary",
        ),
        ...button("skip", "Skip", "welcome.focus", { skip: true }, "borderless"),
      ],
    ),
    { form: { focus: [], other: "" } },
  );
}

export function scopeCard() {
  return card(
    column(
      ["q", "row"],
      [
        text("q", "## Just me, my team or my business?"),
        { id: "row", component: "Row", children: ["me", "team", "biz", "skip"] },
        ...button("me", "Just me", "welcome.scope", { scope: "just_me" }, "primary"),
        ...button("team", "My team", "welcome.scope", { scope: "team" }),
        ...button("biz", "My business", "welcome.scope", { scope: "business" }),
        ...button("skip", "Skip", "welcome.scope", { skip: true }, "borderless"),
      ],
    ),
  );
}

/**
 * Google first (D-204): one card, right after the name, for everyone. Connecting is also the
 * consent to the catch-up, so the card says what it reads and that nothing is sent or changed.
 * The app opens the connection itself ("app:connect") and, once it worked, sends
 * "welcome.connected" back ("after").
 */
export function googleCard(route: GoogleRoute) {
  const connect = (app: string) => ({ app, after: "welcome.connected" });
  return card(
    column(
      ["q", "t", ...(route === "composio" ? ["via"] : []), "row"],
      [
        text("q", "## Start with your Google account"),
        text(
          "t",
          "Connect Google Calendar and I'll catch you up on your next two weeks: what's coming, what clashes and what needs preparing. Add Gmail too and I'll tell you which emails need you. I only read; I won't send, change or delete anything.",
        ),
        ...(route === "composio"
          ? [
              text(
                "via",
                "Google's screen names Composio, the service that keeps your Google sign-in safe for Casama. You can disconnect any time in Settings → Connections.",
                "caption",
              ),
            ]
          : []),
        { id: "row", component: "Row", children: ["cal", "mail", "skip"] },
        ...button(
          "cal",
          "Connect Google Calendar",
          "app:connect",
          connect("google_calendar"),
          "primary",
        ),
        ...button("mail", "Gmail too", "app:connect", connect("gmail")),
        ...button("skip", "Not now", "welcome.nogoogle", {}, "borderless"),
      ],
    ),
  );
}

/** What comes after the name: the Google card when this server can connect Google, else the focus question. */
function afterName(s: WelcomeState) {
  s.step = s.google ? "google" : "focus";
  return s.google ? googleCard(s.google) : focusCard();
}

/**
 * The scripted opening. When the person already said what to call them (the app's name step,
 * About you D-169), it greets them by name and goes straight to the next question.
 */
export function openingMessage(
  botName: string,
  firstName = "",
  nameKnown = false,
  google?: GoogleRoute,
) {
  const hi = nameKnown && firstName.trim() ? `Hi ${firstName.trim()}!` : "Hi!";
  return [
    {
      type: "text",
      text: `${hi} I'm ${botName}, your assistant. I can work on my own computer, use your apps when you connect them, and remember how you like things done. ${google ? "Let's get you something useful in a minute." : "A couple of quick questions so I can start in the right place."}`,
    },
    nameKnown ? afterName({ step: "name", focus: [], google }) : nameCard(firstName),
  ];
}

const listLabels = (focus: Focus[], other?: string) =>
  focus
    .map((f) =>
      f === "other" && other ? other : (WELCOME_FOCUS.find((x) => x.id === f)?.label ?? f),
    )
    .join(", ");

/** One setup question at a time. A model, a connection, the phone, and an invite never share a message. */
type SetupPrompt = "model" | "connect" | "phone" | "invite";

const focusIntro = (s: WelcomeState) =>
  s.focus.length
    ? `Great. ${s.focus.map((f) => INTRO[f]).join(" ")}`
    : "No problem. I can help with email and calendar, projects, code, research and errands. Here's how to get the most out of me.";

const laterBots = (s: WelcomeState) => {
  const names = [...new Set(s.focus.flatMap((f) => STARTER_FOR[f]))].map((t) =>
    t.replaceAll("-", " "),
  );
  if (!names.length) return "";
  const phrase = (name: string) => `${/^[aeiou]/i.test(name) ? "an" : "a"} ${name}`;
  return `Later you might add ${names.map(phrase).join(" or ")} bot; I can set one up when you're ready.`;
};

/** The next single question after "just me / team / business", if one is still waiting. */
function setupPrompts(s: WelcomeState, hasModel: boolean): SetupPrompt[] {
  const prompts: SetupPrompt[] = [];
  if (!hasModel) prompts.push("model");
  if (mainApps(s).length > 0) prompts.push("connect");
  if (s.focus.some((f) => f === "health" || f === "errands")) prompts.push("phone");
  if (s.scope === "team" || s.scope === "business") prompts.push("invite");
  return prompts;
}

/** The picks' main connections, without Google once it was connected or turned down at the start. */
function mainApps(s: WelcomeState) {
  const skipGoogle = s.googleDeclined || s.connected;
  return [...new Set(s.focus.flatMap((f) => MAIN_CONNECTION[f]))]
    .filter((a) => !(skipGoogle && GOOGLE_APPS.includes(a)))
    .slice(0, 3);
}

function connectCard(s: WelcomeState) {
  const apps = mainApps(s);
  const names = apps.map((a) => APP_NAMES[a] ?? a);
  return card(
    column(
      ["t", "apps", "row"],
      [
        text(
          "t",
          `Connect ${names.join(" or ")} so I can ${s.focus.includes("coding") ? "work on your code" : "see what you're working with"}. You choose what I can do, and I ask before anything risky.`,
        ),
        { id: "apps", component: "Row", children: apps.map((a) => `c_${a}`) },
        ...apps.flatMap((a, i) =>
          button(
            `c_${a}`,
            `Connect ${APP_NAMES[a] ?? a}`,
            "app:connect",
            { app: a },
            i === 0 ? "primary" : "default",
          ),
        ),
        { id: "row", component: "Row", children: ["more", "next"] },
        ...button(
          "more",
          "More apps",
          "app:route",
          { path: "/settings/integrations" },
          "borderless",
        ),
        ...button("next", "Done, next", "welcome.next"),
      ],
    ),
  );
}

function phoneCard(s: WelcomeState) {
  return card(
    column(
      ["t", "row"],
      [
        text(
          "t",
          s.focus.includes("health")
            ? "Share your sleep, activity and workouts from your phone (Apple Health or Health Connect). You choose each kind, and only I can read it, only in your chats."
            : "Share your phone's calendar and places with me, so I can plan around your day. You choose each kind.",
        ),
        { id: "row", component: "Row", children: ["phone", "next"] },
        ...button(
          "phone",
          "Choose what to share",
          "app:route",
          { path: "/settings/devices" },
          "primary",
        ),
        ...button("next", "Done, next", "welcome.next"),
      ],
    ),
  );
}

function inviteCard(s: WelcomeState) {
  return card(
    column(
      ["t", "row"],
      [
        text(
          "t",
          s.scope === "team"
            ? "Want your team in here? Invite them; they get their own chats with shared bots."
            : "Bring in the people you work with; shared bots can help everyone.",
        ),
        { id: "row", component: "Row", children: ["inv", "next"] },
        ...button("inv", "Invite people", "app:invite", {}, "primary"),
        ...button("next", "Done, next", "welcome.next"),
      ],
    ),
  );
}

function onePrompt(kind: SetupPrompt, s: WelcomeState) {
  if (kind === "model") return [modelCard()];
  if (kind === "connect") return [connectCard(s)];
  if (kind === "phone") return [phoneCard(s)];
  return [inviteCard(s)];
}

/**
 * How the bot gets a model, when the workspace has no usable key yet. With [again], it's shown after
 * someone tried to go on without one, with a button to carry on once a key is added.
 */
export function modelCard(again = false) {
  return card(
    column(
      ["t", "row", "row2"],
      [
        text(
          "t",
          again
            ? "I need a model before I can do that. Pick one way, then tap Continue:"
            : "First, I need a model to think with. Pick one way:",
        ),
        { id: "row", component: "Row", children: ["chatgpt", "key", "local"] },
        // The app starts ChatGPT sign-in itself where it can (desktop) and explains elsewhere.
        ...button(
          "chatgpt",
          "Continue with ChatGPT",
          "app:route",
          { path: "/settings/keys", provider: "chatgpt" },
          "primary",
        ),
        ...button("key", "Add a model key", "app:route", { path: "/settings/keys" }),
        ...button("local", "Use a local model", "app:route", {
          path: "/settings/keys",
          provider: "openai_compatible",
        }),
        { id: "row2", component: "Row", children: ["next"] },
        ...button("next", "Continue", "welcome.next"),
      ],
    ),
  );
}

/** The first task card for the first pick. */
export function firstTaskMessage(s: WelcomeState) {
  const t = FIRST_TASK[s.focus[0] ?? "other"];
  return [
    card(
      column(
        ["q", "in", "row"],
        [
          text("q", `## ${t.label}`),
          {
            id: "in",
            component: "TextField",
            label: t.placeholder,
            value: { "@path": "/form/text" },
            variant: "longText",
          },
          { id: "row", component: "Row", children: ["go", "skip"] },
          ...button("go", "Go", "welcome.task", { text: { "@path": "/form/text" } }, "primary"),
          ...button("skip", "Skip", "welcome.task", { skip: true }, "borderless"),
        ],
      ),
      { form: { text: "" } },
    ),
  ];
}

export function catchupMessage(inbox: boolean) {
  return [
    card(
      column(
        ["t", "row"],
        [
          text(
            "t",
            `Want a quick catch-up? I'll read your next 14 days of calendar${inbox ? " and the last 14 days of email" : ""} and tell you what stands out. I won't send or change anything.`,
          ),
          { id: "row", component: "Row", children: ["yes", "no"] },
          ...button("yes", "Catch me up", "welcome.catchup", {}, "primary"),
          ...button("no", "Not now", "welcome.nocatchup", {}, "borderless"),
        ],
      ),
    ),
  ];
}

export function setupOfferMessage() {
  return [
    {
      type: "text",
      text: "Next: a few quick questions so I work the way you like. It takes a minute.",
    },
    card(
      column(
        ["row"],
        [
          { id: "row", component: "Row", children: ["yes", "later"] },
          ...button("yes", "Let's do it", "welcome.setup", {}, "primary"),
          ...button("later", "Later", "welcome.later", {}, "borderless"),
        ],
      ),
    ),
  ];
}

export function learnedMessage(memories: Array<{ id: string; content: string }>, botId: string) {
  return [
    {
      type: "text",
      text: memories.length
        ? "Here's what I learned. Untick anything that's wrong."
        : "All set. Ask me anything.",
    },
    ...(memories.length
      ? [
          card(
            column(
              ["pick", "row"],
              [
                {
                  id: "pick",
                  component: "ChoicePicker",
                  options: memories.map((m) => ({ label: m.content, value: m.id })),
                  value: { "@path": "/form/keep" },
                  variant: "multipleSelection",
                  displayStyle: "checkbox",
                },
                { id: "row", component: "Row", children: ["keep", "edit"] },
                ...button(
                  "keep",
                  "Looks right",
                  "welcome.learned",
                  { keep: { "@path": "/form/keep" } },
                  "primary",
                ),
                ...button(
                  "edit",
                  "Edit in Memory",
                  "app:route",
                  { path: `/bots/${botId}/memory` },
                  "borderless",
                ),
              ],
            ),
            { form: { keep: memories.map((m) => m.id) } },
          ),
        ]
      : []),
  ];
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

const CHAT_PROVIDERS = [
  "openai",
  "anthropic",
  "google",
  "xai",
  "openrouter",
  "openai_compatible",
  "chatgpt",
];

/** Whether the bot can think yet; gives it the workspace's first usable key when it has none. */
export async function ensureBotModel(
  db: Database,
  botId: string,
  orgId: string,
  overrides: Record<string, string | undefined> = {},
  platformModel = false,
) {
  const [b] = await db.execute<{ primary: unknown }>(
    sql`select model_policy -> 'primary' as primary from public.bots where id = ${botId}::uuid`,
  );
  if (b?.primary) return true;
  const creds = await db.execute<{ id: string; provider: string }>(sql`
    select id, provider from public.model_credentials where org_id = ${orgId}::uuid
      and provider = any(array(select jsonb_array_elements_text(${JSON.stringify(CHAT_PROVIDERS)}::jsonb))) order by created_at`);
  for (const c of creds) {
    const model = defaultModelFor(c.provider, overrides);
    if (!model) continue;
    await db.execute(
      sql`update public.bots set model_policy = jsonb_set(model_policy, '{primary}', ${JSON.stringify({ credential_id: c.id, model })}::jsonb) where id = ${botId}::uuid`,
    );
    return true;
  }
  // Casama Cloud's shared OpenRouter key: a workspace with no key of its own still has a model.
  if (!platformModel) return false;
  const model = defaultModelFor("openrouter", overrides);
  if (!model) return false;
  await db.execute(
    sql`update public.bots set model_policy = jsonb_set(coalesce(model_policy, '{}'::jsonb), '{primary}', ${JSON.stringify({ credential_id: PLATFORM_OPENROUTER_CREDENTIAL_ID, model })}::jsonb) where id = ${botId}::uuid`,
  );
  return true;
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
  await db.execute(
    sql`update public.conversations set last_message_at = now() where id = ${c.conversationId}::uuid`,
  );
  return { runId, messageId, userMessageId };
}

async function saveState(db: Database, conversationId: string, s: WelcomeState, purpose?: string) {
  await db.execute(sql`
    update public.conversations set welcome = ${JSON.stringify(s)}::jsonb, purpose = coalesce(${purpose ?? null}, purpose) where id = ${conversationId}::uuid`);
}

export type ConnectionState = "connected" | "pending" | "none";

/** Composio's names for the Google apps (the catalog's `composio` slugs). */
const COMPOSIO_SLUGS: Record<string, string> = {
  google_calendar: "googlecalendar",
  gmail: "gmail",
};

/**
 * Whether Google is really connected (D-204). A direct connection exists only once its sign-in
 * finished. A Composio one is added as soon as the sign-in page opens, so Composio is asked
 * whether that account is active yet: "pending" while the person is still signing in, or when
 * Composio can't be reached.
 */
export async function googleConnection(
  db: Database,
  orgId: string,
  fetchImpl: typeof fetch = fetch,
): Promise<{ state: ConnectionState; inbox: boolean }> {
  const direct = await db.execute<{ app: string }>(sql`
    select distinct case when config ->> 'app' = 'gmail_inbox' then 'gmail' else config ->> 'app' end as app
    from public.integrations
    where org_id = ${orgId}::uuid and kind <> 'composio' and status <> 'error'
      and config ->> 'app' = any(array['google_calendar', 'gmail', 'gmail_inbox'])`);
  const connected = new Set(direct.map((r) => r.app));
  let pending = false;
  const [managed] = await db.execute<{ id: string; toolkits: string[] | null }>(sql`
    select id, config -> 'toolkits' as toolkits from public.integrations
    where org_id = ${orgId}::uuid and kind = 'composio' and config ->> 'managed' = 'true' limit 1`);
  const wanted = GOOGLE_APPS.filter(
    (a) => !connected.has(a) && (managed?.toolkits ?? []).includes(COMPOSIO_SLUGS[a] as string),
  );
  if (managed && wanted.length) {
    try {
      const rec = await loadIntegration(db, managed.id, fetchImpl);
      const accounts = rec ? await composioDirectory(rec, fetchImpl).accounts() : [];
      for (const a of wanted) {
        const mine = accounts.filter((x) => x.app === COMPOSIO_SLUGS[a]);
        if (mine.some((x) => x.status === "connected")) connected.add(a);
        else if (mine.some((x) => x.status === "pending") || !mine.length) pending = true;
      }
    } catch {
      pending = true;
    }
  }
  return {
    state: connected.size ? "connected" : pending ? "pending" : "none",
    inbox: connected.has("gmail"),
  };
}

export interface WelcomeAction {
  name: string;
  surface_id: string;
  context?: Record<string, unknown>;
}

export interface WelcomeDeps {
  db: Database;
  modelOverrides?: Record<string, string | undefined>;
  /** This server has Casama Cloud's shared model key, so the model card is skipped. */
  platformModel?: boolean;
  /** For asking Composio whether a Google sign-in finished (tests pass a fake). */
  fetch?: typeof fetch;
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
  const [conv] = await db.execute<{ welcome: WelcomeState | null }>(
    sql`select welcome from public.conversations where id = ${c.conversationId}::uuid`,
  );
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
    await ensureBotModel(db, c.botId, c.orgId, d.modelOverrides, d.platformModel);
    const [run] = await db.execute<{ id: string }>(sql`
      insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger)
      values (${c.orgId}::uuid, ${c.botId}::uuid, ${c.conversationId}::uuid, ${c.userId}::uuid, 'chat') returning id`);
    const [m] = await db.execute<{ id: string }>(sql`
      insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
      values (${c.orgId}::uuid, ${c.conversationId}::uuid, 'user', ${c.userId}::uuid,
              ${contentKeys.sealJson(c.orgId, [
                { type: "text", text },
                { type: "ui_action", ...uiAction },
              ])}::jsonb, ${run?.id}::uuid) returning id`);
    await saveState(db, c.conversationId, s, purpose);
    return { runId: run?.id as string, messageId: m?.id as string, queue: true };
  };

  switch (action.name) {
    case "welcome.name": {
      const name =
        !ctx.skip && typeof ctx.name === "string"
          ? ctx.name.trim().replace(/\s+/g, " ").slice(0, 60)
          : "";
      if (name)
        await db.execute(
          sql`update public.profiles set preferred_name = ${name} where user_id = ${c.userId}::uuid`,
        );
      // An older copy of the card, answered after the chat moved on (welcomeNameAnswered): take
      // the name, but don't ask the focus question again.
      if (s.step !== "name")
        return scripted([
          { type: "text", text: name ? `Got it, I'll call you ${name}.` : "Let's keep going." },
        ]);
      // Answered or skipped, the one-time name card elsewhere never asks again.
      await db.execute(sql`
        insert into public.user_about (user_id, name_asked_at) values (${c.userId}::uuid, now())
        on conflict (user_id) do update set name_asked_at = coalesce(public.user_about.name_asked_at, now())`);
      const next = afterName(s);
      return scripted([
        ...(name ? [{ type: "text", text: `Nice to meet you, ${name}!` }] : []),
        next,
      ]);
    }
    // The app connected a Google app from the Google card (D-204): the catch-up starts right away,
    // since connecting under that card's wording was the consent to it.
    case "welcome.connected": {
      const g = await googleConnection(db, c.orgId, d.fetch);
      if (g.state === "none")
        return scripted([
          {
            type: "text",
            text: "I don't see Google connected yet. Try again, or tap Not now and we'll carry on.",
          },
          googleCard(s.google ?? "direct"),
        ]);
      s.connected = true;
      if (s.step === "google" || s.step === "name") {
        await memory(
          `Connected Google ${g.inbox ? "Calendar and Gmail" : "Calendar"} in the welcome chat.`,
        );
      }
      s.step = "first_value";
      if (g.state === "pending")
        return scripted([
          {
            type: "text",
            text: "Finish signing in to Google in your browser, then tap Catch me up.",
          },
          ...catchupMessage(g.inbox),
        ]);
      if (!(await ensureBotModel(db, c.botId, c.orgId, d.modelOverrides, d.platformModel))) {
        s.step = "model";
        return scripted([modelCard(true)]);
      }
      return modelTurn(g.inbox ? CATCHUP_TEXT : CATCHUP_CALENDAR_TEXT);
    }
    case "welcome.nogoogle":
      s.googleDeclined = true;
      s.step = "focus";
      return scripted([
        { type: "text", text: "No problem, you can connect it any time." },
        focusCard(),
      ]);
    case "welcome.focus": {
      const picked = Array.isArray(ctx.focus) ? (ctx.focus as string[]) : [];
      s.focus = ctx.skip
        ? []
        : (picked.filter((f) => WELCOME_FOCUS.some((x) => x.id === f)) as Focus[]).slice(0, 3);
      s.other =
        typeof ctx.other === "string" && ctx.other.trim()
          ? ctx.other.trim().slice(0, 300)
          : undefined;
      if (s.other && !s.focus.includes("other"))
        s.focus = [...s.focus, "other" as const].slice(0, 3);
      if (s.focus.length) {
        await memory(`Wants help first with: ${listLabels(s.focus, s.other)}.`);
        await db.execute(
          sql`update public.bots set persona_md = trim(persona_md || ${`\n\n## What they want help with\n${listLabels(s.focus, s.other)}`}) where id = ${c.botId}::uuid`,
        );
      }
      s.step = "scope";
      return scripted([scopeCard()]);
    }
    case "welcome.scope": {
      s.scope = ctx.skip
        ? undefined
        : ["just_me", "team", "business"].includes(String(ctx.scope))
          ? (ctx.scope as Scope)
          : undefined;
      if (s.scope)
        await memory(
          s.scope === "just_me"
            ? "Uses Casama just for themselves."
            : s.scope === "team"
              ? "Uses Casama with their team."
              : "Uses Casama for their business.",
        );
      const hasModel = await ensureBotModel(
        db,
        c.botId,
        c.orgId,
        d.modelOverrides,
        d.platformModel,
      );
      const prompts = setupPrompts(s, hasModel);
      const lead = [focusIntro(s), laterBots(s)].filter(Boolean).join("\n\n");
      const first = prompts[0];
      if (!first) {
        s.step = "first_value";
        return scripted([{ type: "text", text: lead }, ...firstTaskMessage(s)]);
      }
      s.step = first;
      return scripted([{ type: "text", text: lead }, ...onePrompt(first, s)]);
    }
    case "welcome.next": {
      const hasModel = await ensureBotModel(
        db,
        c.botId,
        c.orgId,
        d.modelOverrides,
        d.platformModel,
      );
      if (!hasModel) {
        s.step = "model";
        return scripted([modelCard(true)]);
      }
      const prompts = setupPrompts(s, true);
      const at = prompts.indexOf(s.step as SetupPrompt);
      const next = at === -1 ? prompts[0] : prompts[at + 1];
      if (next) {
        s.step = next;
        return scripted(onePrompt(next, s));
      }
      const g = await googleConnection(db, c.orgId, d.fetch);
      s.step = "first_value";
      if (g.state !== "none") return scripted(catchupMessage(g.inbox));
      return scripted(firstTaskMessage(s));
    }
    case "welcome.nocatchup":
      s.step = "first_value";
      return scripted(firstTaskMessage(s));
    case "welcome.catchup": {
      if (!(await ensureBotModel(db, c.botId, c.orgId, d.modelOverrides, d.platformModel)))
        return scripted([modelCard(true)]);
      // A Composio sign-in still open in the browser: a catch-up now would find nothing to read.
      const g = await googleConnection(db, c.orgId, d.fetch);
      if (g.state !== "connected")
        return scripted([
          {
            type: "text",
            text:
              g.state === "pending"
                ? "Google isn't connected yet. Finish signing in in your browser, then tap Catch me up again."
                : "I can't see your Google account anymore. Connect it in Settings → Connections, then try again.",
          },
          ...catchupMessage(g.inbox),
        ]);
      s.step = "first_value";
      return modelTurn(g.inbox ? CATCHUP_TEXT : CATCHUP_CALENDAR_TEXT);
    }
    case "welcome.task": {
      // Skipped: no first task, straight on to the setup offer (what a finished first task leads to).
      if (ctx.skip) {
        s.step = "offer_setup";
        return scripted(setupOfferMessage());
      }
      const t = typeof ctx.text === "string" ? ctx.text.trim() : "";
      if (!t)
        return scripted([
          { type: "text", text: "Type what you'd like first and tap Go, or tap Skip." },
          ...firstTaskMessage(s),
        ]);
      // Nothing would answer without a model; keep the task card for after one is added.
      if (!(await ensureBotModel(db, c.botId, c.orgId, d.modelOverrides, d.platformModel)))
        return scripted([modelCard(true)]);
      s.step = "first_value";
      const prefix =
        FIRST_TASK[s.focus[0] ?? "other"]?.prefix ??
        (typeof ctx.prefix === "string" ? ctx.prefix : "");
      return modelTurn(`${prefix}${t}`.slice(0, 4000));
    }
    case "welcome.setup":
      if (!(await ensureBotModel(db, c.botId, c.orgId, d.modelOverrides, d.platformModel)))
        return scripted([modelCard(true)]);
      s.step = "interview";
      await db.execute(
        sql`update public.bots set setup_status = 'pending' where id = ${c.botId}::uuid`,
      );
      return modelTurn("Let's get you set up.", "setup");
    case "welcome.later":
      s.step = "done";
      await saveState(db, c.conversationId, s, "chat");
      return scripted([
        { type: "text", text: 'Sure. When you want, say "set me up". Ask me anything.' },
      ]);
    case "welcome.learned": {
      const keep = new Set(Array.isArray(ctx.keep) ? (ctx.keep as string[]) : []);
      const drop = (s.learned ?? []).filter((id) => !keep.has(id));
      if (drop.length)
        await db.execute(
          sql`delete from public.memories where bot_id = ${c.botId}::uuid and id = any(array(select jsonb_array_elements_text(${JSON.stringify(drop)}::jsonb))::uuid[])`,
        );
      s.step = "done";
      await saveState(db, c.conversationId, s, "chat");
      return scripted([
        {
          type: "text",
          text: drop.length
            ? `Forgot ${drop.length === 1 ? "that one" : `those ${drop.length}`}. You're all set; ask me anything.`
            : "You're all set. Ask me anything.",
        },
      ]);
    }
    default:
      return scripted([{ type: "text", text: "Let's keep going." }]);
  }
}

/**
 * After a model run in the welcome chat: offer the setup interview once the first value is done,
 * and show "What I learned" once the interview saved its answers.
 */
export async function afterWelcomeRun(
  db: Database,
  run: {
    runId: string;
    orgId: string;
    botId: string;
    conversationId: string | null;
    userId: string | null;
  },
) {
  if (!run.conversationId || !run.userId) return;
  const [conv] = await db.execute<{ welcome: WelcomeState | null; created_at: string }>(
    sql`select welcome, created_at from public.conversations where id = ${run.conversationId}::uuid`,
  );
  const s = conv?.welcome;
  if (!s) return;
  const c = {
    orgId: run.orgId,
    botId: run.botId,
    conversationId: run.conversationId,
    userId: run.userId,
  };
  if (s.step === "first_value") {
    s.step = "offer_setup";
    await postScripted(db, c, setupOfferMessage());
    await saveState(db, run.conversationId, s);
  } else if (s.step === "interview") {
    const [b] = await db.execute<{ setup_status: string }>(
      sql`select setup_status from public.bots where id = ${run.botId}::uuid`,
    );
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

/**
 * About you (D-169): the person answered (or skipped) "What should bots call you?" somewhere else,
 * like the app's name step. A welcome chat still on its name question moves on, so it never asks
 * twice: the name card shows as answered, then the focus question.
 */
export async function welcomeNameAnswered(db: Database, userId: string) {
  // Claims the step first, so two saves at once can't both post.
  const [conv] = await db.execute<{
    id: string;
    org_id: string;
    bot_id: string;
    welcome: WelcomeState;
  }>(sql`
    update public.conversations
    set welcome = jsonb_set(welcome, '{step}', case when welcome ? 'google' then '"google"'::jsonb else '"focus"'::jsonb end)
    where id = (select id from public.conversations
                where created_by = ${userId}::uuid and welcome is not null order by created_at limit 1)
      and welcome ->> 'step' = 'name'
    returning id, org_id, bot_id, welcome`);
  if (!conv) return false;
  const [opening] = await db.execute<{ content: unknown }>(sql`
    select content from public.messages where conversation_id = ${conv.id}::uuid and role = 'assistant'
    order by created_at limit 1`);
  const parts = contentKeys.open(opening?.content) as Array<{
    type?: string;
    surface_id?: string;
  }> | null;
  const surface = Array.isArray(parts) ? parts.find((p) => p.type === "ui")?.surface_id : undefined;
  const [p] = await db.execute<{ name: string | null }>(sql`
    select nullif(btrim(preferred_name), '') as name from public.profiles where user_id = ${userId}::uuid`);
  const name = p?.name ?? "";
  await postScripted(
    db,
    { orgId: conv.org_id, botId: conv.bot_id, conversationId: conv.id, userId },
    [
      ...(name ? [{ type: "text", text: `Nice to meet you, ${name}!` }] : []),
      afterName({ ...conv.welcome }),
    ],
    {
      text: name || "Skip",
      ...(surface
        ? {
            uiAction: {
              surface_id: surface,
              name: "welcome.name",
              context: name ? { name } : { skip: true },
            },
          }
        : {}),
    },
  );
  return true;
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
  a: {
    orgId: string;
    userId: string;
    firstName: string;
    botName: string;
    mascot?: string;
    /** They already answered "What should bots call you?" (About you, D-169). */
    nameKnown?: boolean;
    /** How Google connects here; the Google card comes right after the name (D-204). */
    google?: GoogleRoute | null;
  },
): Promise<{ orgId: string; botId: string; conversationId: string }> {
  return db.transaction(async (tx) => {
    const [bot] = await tx.execute<{ id: string }>(sql`
      insert into public.bots (org_id, created_by, name, persona_md, avatar_url, visibility)
      values (${a.orgId}::uuid, ${a.userId}::uuid, ${a.botName}, ${`You are ${a.botName}, this person's personal assistant. Be warm, brief and practical.`},
              ${`mascot:${a.mascot ?? "winky"}`}, 'private')
      returning id`);
    const [conv] = await tx.execute<{ id: string }>(sql`
      insert into public.conversations (org_id, bot_id, title, created_by, last_message_at, purpose, welcome)
      values (${a.orgId}::uuid, ${bot?.id}::uuid, 'Welcome', ${a.userId}::uuid, now(), 'welcome', ${JSON.stringify({ step: a.nameKnown ? (a.google ? "google" : "focus") : "name", focus: [], ...(a.google ? { google: a.google } : {}) })}::jsonb)
      returning id`);
    await tx.execute(sql`
      insert into public.messages (org_id, conversation_id, role, content, bot_id)
      values (${a.orgId}::uuid, ${conv?.id}::uuid, 'assistant', ${contentKeys.sealJson(a.orgId, openingMessage(a.botName, a.firstName, a.nameKnown, a.google ?? undefined))}::jsonb, ${bot?.id}::uuid)`);
    return { orgId: a.orgId, botId: bot?.id as string, conversationId: conv?.id as string };
  });
}
