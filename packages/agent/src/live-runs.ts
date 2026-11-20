/**
 * The island's server pushes (D-324, Phase 4; docs/ISLAND-AND-MENU-BAR-PLAN.md §6 F, §8.7).
 *
 * A phone that follows a run registers a live token for it (`run_live_tokens`): an iPhone Live
 * Activity's own push token, or an Android phone's push token. This watches run events and sends
 * the run's whole state to those tokens, so the Lock Screen keeps up while the app sleeps:
 *
 * - a new step at most every 5 seconds per run (Apple priority 5, free of the budget);
 * - needs your OK, back to work and ended at once (priority 10);
 * - every push carries the full state, when it was made and when it goes stale, so a late or lost
 *   push never leaves a wrong picture.
 *
 * What leaves the server: the bot's name, a step in general words ("Searching the web"), a phase
 * and times. Never tool arguments, approval details or message text (§10).
 */
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import type { PushSender } from "./notifications.ts";

/** island_feed.dart's IslandPhase names, which the widget and the Android receiver read. */
export type LivePhase = "working" | "needsOk" | "takeOver" | "finished" | "problem";

/** A Live Activity's content state (RunActivityAttributes.ContentState): snake_case, seconds. */
export interface LiveState {
  phase: LivePhase;
  step: string;
  detail: string | null;
  steps: number;
  approval_id: string | null;
  risk: string | null;
  updated_at: number;
  ended_at: number | null;
}

/** One push: the run, its state, and how the phone should treat it. */
export interface LiveUpdate {
  run_id: string;
  bot_id: string;
  bot_name: string;
  /** The bot's icon as it stores it (`mascot:<name>`), or null for its initials. Optional: older servers send none. */
  bot_avatar?: string | null;
  /** Seconds since 1970; timers count from here on the phone. */
  started_at: number;
  /** Where tapping it goes in the app. */
  link: string;
  state: LiveState;
  /**
   * `end` ends the activity (Finished stays for [dismiss_at]; a stop leaves at once). `start`
   * starts one on a phone that wasn't following the run (push-to-start, Phase 6).
   */
  event: "update" | "end" | "start";
  /** Apple's priority: 5 for steps (free of the budget), 10 for changes the person must see. */
  priority: 5 | 10;
  /** When the phone should dim it and say "Open Casama for the latest" (seconds). */
  stale_at: number;
  /** For `end`: when it leaves the Lock Screen (seconds); now for a stopped run. */
  dismiss_at: number | null;
}

/** Where a live push goes. */
export interface LiveTarget {
  /** The Live Activity's push token (iPhone) or the phone's push token (Android). */
  token: string;
  platform: "ios" | "android";
  /** iPhone: the phone's own Firebase token, which Firebase needs beside the activity's. */
  fcm_token: string | null;
}

/** A Live Activity's whole state must stay under 4 KB, so the words are cut short. */
const STEP_CHARS = 60;

/** The words a phone shows for a tool's step, from app_en.arb's `toolDoing` (D-324). */
export const LIVE_STEP_WORDS: Record<string, string> = {
  profile_set_picture: "Changing its picture",
  memory_search: "Searching your memories",
  memory_write: "Saving that to memory",
  memory: "Updating its memory",
  knowledge_search: "Looking through your knowledge",
  web_search: "Searching the web",
  web: "Reading a web page",
  browser_open: "Opening a website",
  browser_click: "Clicking on the page",
  browser_type: "Typing on the page",
  browser_press: "Pressing a key",
  browser_scroll: "Scrolling the page",
  browser_look: "Looking at the page",
  desktop_click: "Clicking on the screen",
  desktop_type: "Typing",
  desktop_press: "Pressing keys",
  desktop_launch: "Opening an app",
  desktop_look: "Looking at the screen",
  shell: "Working on its computer",
  files_read: "Reading a file",
  files_write: "Writing a file",
  files_list: "Looking through files",
  files_search: "Searching files",
  files_from_chat: "Getting a file from the chat",
  http: "Contacting a service",
  data_search: "Looking for data",
  data_call: "Getting data",
  skills_load: "Getting a skill ready",
  skills_create: "Learning a new skill",
  skills_update: "Improving a skill",
  checkpoint: "Saving a restore point",
  computer_restart: "Restarting its computer",
  takeover: "Asking you to take over",
  delegate: "Asking a helper",
  routines_list: "Checking your routines",
  routines_create: "Setting up a routine",
  routines_update: "Updating a routine",
  routines_delete: "Removing a routine",
  watchers_create: "Setting up a watcher",
  watchers_list: "Checking your watchers",
  watchers_delete: "Removing a watcher",
  tasks_list: "Checking your tasks",
  tasks_create: "Adding a task",
  tasks: "Updating your tasks",
  notify_user: "Sending you a note",
  usage_report: "Checking usage",
  device_read: "Reading your device data",
  device_access: "Asking for device access",
  pages_publish: "Publishing a page",
  pages: "Updating a page",
  media: "Making an image",
  media_video: "Making a video",
  bots_create: "Making a new bot",
  bots_update: "Updating a bot",
  bots_list: "Checking your bots",
  bots_archive: "Archiving a bot",
  channel_send: "Sending a message",
  links_ask: "Asking a contact's assistant",
  logins_list: "Checking saved logins",
  replay_run: "Repeating saved steps",
  replay_save: "Saving these steps",
  setup_apply: "Suggesting a setup",
  sidebar_organize: "Organizing your sidebar",
  suggestions_add: "Adding a suggestion",
  teach_save_draft: "Saving a draft skill",
  welcome_name: "Picking a name",
  secrets_request: "Asking you for a secret",
  pages_list: "Checking your pages",
  pages_share: "Changing who can see a page",
  projects_create: "Starting a project",
  projects_status: "Checking a project",
  projects_update: "Updating a project",
  projects: "Planning a project",
  payments: "Asking to make a payment",
  voice_call: "Calling a business",
  voice_call_user: "Calling you",
  tools_load: "Getting ready",
  ui_show: "Showing you something",
  start_task: "Starting this in the chat",
  other: "Working on it",
};

export const LIVE_LABELS = {
  thinking: "Thinking…",
  writing: "Writing a reply",
  needsOk: "Needs your OK",
  takeOver: "Wants you to take over",
  finished: "Finished",
  problem: "Stopped with a problem",
} as const;

/** Which words a tool uses (tool_words.dart, toolWordsId); "other" for a connected app's tool. */
export function liveStepId(tool: string): string {
  const t = tool.replaceAll("__", ".");
  const flat = t.replaceAll(".", "_");
  if (flat in LIVE_STEP_WORDS && flat !== "other") return flat;
  // Looking up a card's properties before showing it (D-355) reads like loading tools.
  if (t === "ui.catalog") return "tools_load";
  if (t === "browser.fill") return "browser_type";
  if (t.startsWith("browser.")) return "browser_look";
  if (t === "desktop.files.search") return "files_search";
  if (t.startsWith("desktop.")) return "desktop_look";
  if (t.startsWith("computer.request_takeover")) return "takeover";
  if (t.startsWith("computer.")) return "desktop_look";
  if (t.startsWith("shell")) return "shell";
  if (t.startsWith("checkpoint")) return "checkpoint";
  if (t.startsWith("http")) return "http";
  if (t === "device.request_access") return "device_access";
  if (t.startsWith("memory")) return "memory";
  if (t.startsWith("web")) return "web";
  if (t.startsWith("tasks") || t.startsWith("tickets")) return "tasks";
  if (t.startsWith("pages")) return "pages";
  if (t === "documents.read" || t === "media.image.look" || t === "media.qr.read")
    return "files_read";
  if (t === "documents.pdf" || t === "documents.make" || t === "media.image.edit")
    return "files_write";
  if (t.startsWith("media.video")) return "media_video";
  if (t.startsWith("media")) return "media";
  if (t.startsWith("projects")) return "projects";
  if (t.startsWith("payments")) return "payments";
  if (t.includes("delegate") || t.includes("subagent")) return "delegate";
  if (t.startsWith("skills")) return "skills_load";
  if (t.startsWith("files")) return "files_list";
  if (t.startsWith("routines")) return "routines_list";
  if (t.startsWith("watchers")) return "watchers_list";
  return "other";
}

export function liveStepWords(tool: string): string {
  return LIVE_STEP_WORDS[liveStepId(tool)] ?? (LIVE_STEP_WORDS.other as string);
}

const cut = (s: string, max: number) => (s.length <= max ? s : `${s.slice(0, max - 1).trimEnd()}…`);

/** Events that change a run's state rather than its step: sent at once, priority 10. */
const CHANGE_EVENTS = new Set([
  "approval.requested",
  "approval.resolved",
  "takeover.requested",
  "takeover.resolved",
  "run.completed",
  "run.failed",
  "run.cancelled",
]);

/** Triggers that mean a person started the run (run_tracker.dart reads them the same way). */
export const PERSON_TRIGGERS = new Set(["chat", "mention", "voice", "replay", "teach"]);
export const UNFINISHED_RUN_STATUSES = new Set([
  "queued",
  "running",
  "waiting_approval",
  "waiting_takeover",
]);

/** The events that change what a phone shows. */
const LIVE_EVENTS = new Set([
  "run.started",
  "tool.started",
  "message.delta",
  "approval.requested",
  "approval.resolved",
  "takeover.requested",
  "takeover.resolved",
  "run.completed",
  "run.failed",
  "run.cancelled",
]);

interface RunLive {
  orgId: string;
  botId: string;
  botName: string;
  botAvatar: string | null;
  startedAt: number;
  link: string;
  phase: LivePhase;
  step: string;
  steps: number;
  approvalId: string | null;
  risk: string | null;
  endedAt: number | null;
  /** When the last push went out (ms), for the step throttle. */
  sentAt: number;
  /** The last push's timestamp (s): each one is later than the one before, or Apple drops it. */
  stamp: number;
  /** A step that waits for the throttle. */
  timer?: ReturnType<typeof setTimeout>;
}

export interface LiveRunPusherOptions {
  /** At most one step push per run this often (ms). Default 5 s. */
  stepEveryMs?: number;
  /** How long a run's token list is kept before it is read again (ms). Default 10 s. */
  tokensForMs?: number;
  /** A pushed state goes stale this long after it was made (s). Default 120. */
  staleAfterS?: number;
  /** Finished stays on the Lock Screen this long (s), decision 9. Default 15 minutes. */
  finishedForS?: number;
  /**
   * Push-to-start (decision 11): this long after a person's run starts (ms), their phones that
   * aren't following it yet get a start. The wait lets the phone that started it register first,
   * so it doesn't get a second one. Default 6 s; negative turns it off.
   */
  startAfterMs?: number;
  now?: () => number;
  onError?: (error: Error) => void;
}

/**
 * Sends a followed run's state to the phones that follow it. Feed it every run event
 * ([observe], wired to EventBus.observe); it reads a run's tokens only for events that change
 * what a phone shows, and keeps the list a few seconds.
 */
export class LiveRunPusher {
  private readonly db: Database;
  private readonly push: PushSender;
  private readonly o: Required<Omit<LiveRunPusherOptions, "onError">> & {
    onError?: (e: Error) => void;
  };
  private readonly runs = new Map<string, RunLive>();
  private readonly tokens = new Map<string, { at: number; list: LiveTarget[] }>();
  /** Each run's events in order: one at a time. */
  private readonly chains = new Map<string, Promise<void>>();

  constructor(db: Database, push: PushSender, o: LiveRunPusherOptions = {}) {
    this.db = db;
    this.push = push;
    this.o = {
      stepEveryMs: o.stepEveryMs ?? 5_000,
      tokensForMs: o.tokensForMs ?? 10_000,
      staleAfterS: o.staleAfterS ?? 120,
      finishedForS: o.finishedForS ?? 15 * 60,
      startAfterMs: o.startAfterMs ?? 6_000,
      now: o.now ?? Date.now,
      onError: o.onError,
    };
  }

  /** Whether this server can send live pushes at all. */
  get enabled() {
    return typeof this.push.sendLive === "function";
  }

  /** A run event happened. Never throws; pushes go out in the background, in order per run. */
  observe = (runId: string, type: string, payload: Record<string, unknown>) => {
    if (!this.enabled || !LIVE_EVENTS.has(type)) return;
    // A reply streaming in is only news when it starts (Writing a reply).
    if (type === "message.delta" && this.runs.get(runId)?.step === LIVE_LABELS.writing) return;
    this.enqueue(runId, () => this.handle(runId, type, payload));
    if (type === "run.started" && this.o.startAfterMs >= 0) {
      const timer = setTimeout(
        () => this.enqueue(runId, () => this.startElsewhere(runId)),
        this.o.startAfterMs,
      );
      timer.unref?.();
    }
  };

  /** Runs [work] after the run's earlier events, one at a time. */
  private enqueue(runId: string, work: () => Promise<void>) {
    const next = (this.chains.get(runId) ?? Promise.resolve())
      .then(work)
      .catch((e: Error) => this.o.onError?.(e));
    this.chains.set(runId, next);
    void next.finally(() => {
      if (this.chains.get(runId) === next) this.chains.delete(runId);
    });
  }

  /**
   * Push-to-start (decision 11): a run a person started (in a chat, by voice, a replay; not a
   * routine) appears on their phones that aren't following it already, such as a run started on
   * their Mac. An iPhone gets a Live Activity start; an Android phone the usual live message, and
   * from then on follows the run like the phone that started it.
   */
  async startElsewhere(runId: string) {
    const [r] = await this.db.execute<{
      created_by: string | null;
      trigger: string | null;
      status: string;
    }>(sql`select created_by, trigger, status from public.runs where id = ${runId}::uuid`);
    if (
      !r?.created_by ||
      !PERSON_TRIGGERS.has(r.trigger ?? "") ||
      !UNFINISHED_RUN_STATUSES.has(r.status)
    ) {
      return;
    }
    const starts = await this.db.execute<LiveTarget & Record<string, unknown>>(sql`
      select t.platform, t.token, t.fcm_token from public.live_start_tokens t
      where t.user_id = ${r.created_by}::uuid and t.enabled
        -- A shared phone follows whoever signed in on it last (switched off or not), never an
        -- earlier account.
        and not exists (
          select 1 from public.live_start_tokens o
          where o.token = t.token and o.user_id <> t.user_id and o.updated_at > t.updated_at)`);
    if (!starts.length) return;
    const following = await this.targets(runId, true);
    const targets = starts.filter(
      (s) =>
        !following.some(
          (f) => f.token === s.token || (s.fcm_token != null && f.fcm_token === s.fcm_token),
        ),
    );
    if (!targets.length || !this.push.sendLive) return;
    const loaded = await this.load(runId);
    if (!loaded || loaded.run.endedAt != null) return;
    const { run } = loaded;
    run.sentAt = this.o.now();
    const { invalidTokens } = await this.push.sendLive(
      targets,
      this.update(runId, run, { event: "start", priority: 10 }),
    );
    for (const t of targets) {
      if (t.platform !== "android" || invalidTokens.includes(t.token)) continue;
      await this.db.execute(sql`
        insert into public.run_live_tokens (run_id, user_id, platform, token)
        values (${runId}::uuid, ${r.created_by}::uuid, 'android', ${t.token})
        on conflict (run_id, token) do nothing`);
    }
    for (const token of invalidTokens)
      await this.db.execute(sql`delete from public.live_start_tokens where token = ${token}`);
    this.tokens.delete(runId);
  }

  /** Waits for every push in flight (tests and shutdown). */
  async idle() {
    while (this.chains.size) await Promise.all([...this.chains.values()]);
  }

  /**
   * A run's tokens. A list with tokens is kept [tokensForMs]; an empty one only a second, since a
   * phone registers its token a moment after the run starts and a short run's end mustn't be
   * missed. `fresh` reads it anew (state changes and the end).
   */
  private async targets(runId: string, fresh = false): Promise<LiveTarget[]> {
    const now = this.o.now();
    const cached = this.tokens.get(runId);
    const keep = cached?.list.length ? this.o.tokensForMs : 1_000;
    if (!fresh && cached && now - cached.at < keep) return cached.list;
    const list = await this.db.execute<LiveTarget & Record<string, unknown>>(sql`
      select token, platform, fcm_token from public.run_live_tokens where run_id = ${runId}::uuid`);
    if (this.tokens.size > 5000) this.tokens.clear();
    this.tokens.set(runId, { at: now, list: [...list] });
    return list;
  }

  /**
   * The run as phones see it. `fresh`: just read, with its steps counted from the database, the
   * event being handled already among them (a run that resumes in another worker keeps its count).
   */
  private async load(runId: string): Promise<{ run: RunLive; fresh: boolean } | null> {
    const known = this.runs.get(runId);
    if (known) return { run: known, fresh: false };
    const [r] = await this.db.execute<{
      org_id: string;
      bot_id: string;
      bot_name: string;
      bot_avatar: string | null;
      conversation_id: string | null;
      kind: string | null;
      started_at: string | null;
      created_at: string;
      steps: number;
    }>(sql`
      select r.org_id, r.bot_id, b.name as bot_name, b.avatar_url as bot_avatar, r.conversation_id, c.kind, r.started_at, r.created_at,
        (select count(*)::int from public.run_events e where e.run_id = r.id and e.type = 'tool.started') as steps
      from public.runs r
      join public.bots b on b.id = r.bot_id
      left join public.conversations c on c.id = r.conversation_id
      where r.id = ${runId}::uuid`);
    if (!r) return null;
    const link = !r.conversation_id
      ? `/bots/${r.bot_id}/chat`
      : r.kind === "group"
        ? `/groups/${r.conversation_id}`
        : `/bots/${r.bot_id}/chat?c=${r.conversation_id}`;
    const run: RunLive = {
      orgId: r.org_id,
      botId: r.bot_id,
      botName: r.bot_name,
      botAvatar: r.bot_avatar,
      startedAt: Math.round(new Date(r.started_at ?? r.created_at).getTime() / 1000),
      link,
      phase: "working",
      step: LIVE_LABELS.thinking,
      steps: r.steps,
      approvalId: null,
      risk: null,
      endedAt: null,
      sentAt: 0,
      stamp: 0,
    };
    if (this.runs.size > 5000) this.runs.clear();
    this.runs.set(runId, run);
    return { run, fresh: true };
  }

  private async handle(runId: string, type: string, payload: Record<string, unknown>) {
    // Nobody follows this run on a phone: nothing to read or send.
    // A state change or the end reads the list afresh; steps make do with the cached one.
    const change = CHANGE_EVENTS.has(type);
    if (!(await this.targets(runId, change)).length) {
      if (type.startsWith("run.") && type !== "run.started") this.forget(runId);
      return;
    }
    const loaded = await this.load(runId);
    if (!loaded) return;
    const { run, fresh } = loaded;
    const before = run.phase;
    let end: "finished" | "problem" | "stopped" | null = null;
    switch (type) {
      case "run.started":
        run.phase = "working";
        run.step = LIVE_LABELS.thinking;
        break;
      case "tool.started":
        run.phase = "working";
        run.step = cut(liveStepWords(String(payload.tool ?? "")), STEP_CHARS);
        if (!fresh) run.steps += 1;
        break;
      case "message.delta":
        run.phase = "working";
        run.step = LIVE_LABELS.writing;
        break;
      case "approval.requested":
        run.phase = "needsOk";
        // General words for the tool, never the approval's own summary or arguments (§10).
        run.step = cut(liveStepWords(String(payload.tool ?? "")), STEP_CHARS);
        run.approvalId = typeof payload.approval_id === "string" ? payload.approval_id : null;
        run.risk = typeof payload.risk === "string" ? payload.risk : null;
        break;
      case "approval.resolved":
      case "takeover.resolved":
        run.phase = "working";
        run.step = LIVE_LABELS.thinking;
        run.approvalId = null;
        run.risk = null;
        break;
      case "takeover.requested":
        run.phase = "takeOver";
        run.step = LIVE_LABELS.takeOver;
        break;
      case "run.completed":
        end = "finished";
        break;
      case "run.failed":
        end = "problem";
        break;
      case "run.cancelled":
        end = "stopped";
        break;
    }
    if (end) {
      run.phase = end === "finished" ? "finished" : "problem";
      run.step = end === "finished" ? LIVE_LABELS.finished : LIVE_LABELS.problem;
      run.approvalId = null;
      run.risk = null;
      run.endedAt = Math.round(this.o.now() / 1000);
      if (run.timer) clearTimeout(run.timer);
      // Read the list afresh: a phone that started following a moment ago still hears the end.
      await this.send(runId, run, { event: "end", stopped: end === "stopped" }, true);
      await this.db.execute(sql`delete from public.run_live_tokens where run_id = ${runId}::uuid`);
      this.forget(runId);
      return;
    }
    // Needs your OK, takeover and back to work go at once; steps wait for the throttle. A request
    // or its answer counts even when this process didn't see the phase before (a restarted worker).
    if (run.phase !== before || change) {
      if (run.timer) clearTimeout(run.timer);
      run.timer = undefined;
      await this.send(runId, run, { event: "update", priority: 10 });
      return;
    }
    const wait = run.sentAt + this.o.stepEveryMs - this.o.now();
    if (wait <= 0) {
      await this.send(runId, run, { event: "update", priority: 5 });
    } else if (!run.timer) {
      run.timer = setTimeout(() => {
        run.timer = undefined;
        if (!this.runs.has(runId)) return;
        const next = (this.chains.get(runId) ?? Promise.resolve())
          .then(() => this.send(runId, run, { event: "update", priority: 5 }))
          .catch((e: Error) => this.o.onError?.(e));
        this.chains.set(runId, next);
        void next.finally(() => {
          if (this.chains.get(runId) === next) this.chains.delete(runId);
        });
      }, wait);
      run.timer.unref?.();
    }
  }

  /** The update a run's state makes now. */
  update(
    runId: string,
    run: RunLive,
    o: { event: "update" | "end" | "start"; priority?: 5 | 10; stopped?: boolean },
  ): LiveUpdate {
    const now = Math.max(Math.round(this.o.now() / 1000), run.stamp + 1);
    run.stamp = now;
    return {
      run_id: runId,
      bot_id: run.botId,
      bot_name: run.botName,
      bot_avatar: run.botAvatar,
      started_at: run.startedAt,
      link: run.approvalId ? `/approvals/${run.approvalId}` : run.link,
      state: {
        phase: run.phase,
        step: run.step,
        detail: null,
        steps: run.steps,
        approval_id: run.approvalId,
        risk: run.risk,
        updated_at: now,
        ended_at: run.endedAt,
      },
      event: o.event,
      priority: o.event === "end" ? 10 : (o.priority ?? 5),
      stale_at: now + this.o.staleAfterS,
      dismiss_at: o.event === "end" ? (o.stopped ? now : now + this.o.finishedForS) : null,
    };
  }

  private async send(
    runId: string,
    run: RunLive,
    o: { event: "update" | "end" | "start"; priority?: 5 | 10; stopped?: boolean },
    fresh = false,
  ) {
    const targets = await this.targets(runId, fresh);
    run.sentAt = this.o.now();
    if (!targets.length || !this.push.sendLive) return;
    const { invalidTokens } = await this.push.sendLive(targets, this.update(runId, run, o));
    for (const token of invalidTokens)
      await this.db.execute(sql`delete from public.run_live_tokens where token = ${token}`);
    if (invalidTokens.length) this.tokens.delete(runId);
  }

  private forget(runId: string) {
    const run = this.runs.get(runId);
    if (run?.timer) clearTimeout(run.timer);
    this.runs.delete(runId);
    this.tokens.delete(runId);
  }
}

/** Deletes live tokens once they are 12 hours old (iOS ends an activity after 8). */
export async function sweepLiveTokens(db: Database, hours = 12) {
  const rows = await db.execute<{ id: string }>(sql`
    delete from public.run_live_tokens where created_at < now() - make_interval(hours => ${hours})
    returning id`);
  return rows.length;
}
