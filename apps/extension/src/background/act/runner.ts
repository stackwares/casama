/**
 * Runs a bot's browser calls in this browser (D-323 C2–C7, C13–C15, plan §9.5).
 *
 * - Each bot works in its own tab group, named after it; it only ever sees and acts on tabs in that
 *   group. The person can drag a tab in to share it and out to take it back.
 * - The debugger is attached to a tab while a run is using it and detached after a minute idle.
 * - Every page is checked before a step (sites.ts); risky steps ask or are handed to the person
 *   (risk.ts); text read on one site and typed on another asks.
 * - Stop from the banner, the panel, Chrome's own "Cancel" on the debugging bar, closing the group
 *   or unpairing end the run's browser work and cancel the run. A dropped connection only ends the
 *   calls in flight; the run carries on when the browser reconnects.
 * - Watchers only read sites the person set to "Always allow" (they run unattended, so they never
 *   ask).
 */
import type { BrowserCall, BrowserResult } from "../../../../../packages/contracts/src/browser.ts";
import { getManaged } from "../../lib/act/managed.ts";
import {
  clickVerdict,
  crossSite,
  fieldVerdict,
  keyVerdict,
  type Verdict,
} from "../../lib/act/risk.ts";
import { hostOf, type SitePolicy, siteDecision } from "../../lib/act/sites.ts";
import type { Ref } from "../../lib/act/snapshot.ts";
import { guardAdditions } from "../../lib/guard-sites.ts";
import { getSettings } from "../../lib/settings.ts";
import { getLocal } from "../../lib/store.ts";
import { ask, denyFor } from "./ask.ts";
import * as cdp from "./cdp.ts";
import { forgetOverlay, hideOverlay, type OverlayEvent, showOverlay } from "./overlay.ts";
import * as page from "./page.ts";

export type Call = BrowserCall & { policy: SitePolicy };

const IDLE_DETACH_MS = 60_000;
const FORGET_MS = 30 * 60_000;
const PAUSE_WAIT_MS = 8 * 60_000;
const FILE_MAX = 20 * 1024 * 1024;
const COLORS = ["purple", "blue", "cyan", "green", "orange", "pink", "red", "yellow"] as const;

export interface Step {
  at: number;
  text: string;
}

export interface Job {
  key: string;
  runId: string | null;
  botId: string;
  botName: string;
  watcher: boolean;
  groupId: number | null;
  current: number | null;
  refs: Record<string, Ref & { tabId: number }>;
  readBy: Map<string, string[]>;
  once: string[];
  state: "working" | "paused" | "asking" | "stopped";
  stoppedBy?: string;
  steps: Step[];
  lastInput: number;
  idle?: ReturnType<typeof setTimeout>;
  forget?: ReturnType<typeof setTimeout>;
  resume?: () => void;
  aborts: Set<AbortController>;
  attachedTabs: Set<number>;
}

/** What the runner needs from the device connection. */
export interface RunnerHost {
  /** Adds a host to this browser's allowed or blocked sites on the server. */
  rememberSite(
    list: "allowed_sites" | "blocked_sites",
    host: string,
    current: string[],
  ): Promise<void>;
  /** Cancels a run on the server. */
  cancelRun(runId: string): Promise<void>;
}

const JOBS = new Map<string, Job>();
let host: RunnerHost | null = null;

export function setRunnerHost(h: RunnerHost) {
  host = h;
}

export function jobs() {
  return [...JOBS.values()];
}

const fail = (code: string, message: string): BrowserResult => ({ ok: false, code, message });

/** Focus is where Casama can't see the field (a frame from another site, a closed shadow root). */
const OUT_OF_SIGHT: Verdict = {
  kind: "hand_off",
  reason:
    "The field is inside a box from another site (often a card or sign-in box) that Casama can't check",
};
const okText = (text: string, url?: string): BrowserResult => ({
  ok: true,
  text,
  ...(url ? { url } : {}),
});

// --- What the panel shows ---------------------------------------------------------------------

let publishing = Promise.resolve();
/** Writes the runs for the panel, in order (each write waits for the one before). */
function publish() {
  const runs = [...JOBS.values()]
    .filter((j) => !j.watcher)
    .map((j) => ({
      key: j.key,
      runId: j.runId,
      bot: j.botName,
      state: j.state,
      stoppedBy: j.stoppedBy ?? null,
      steps: j.steps.slice(-15),
      tabId: j.current,
      groupId: j.groupId,
    }));
  publishing = publishing
    .then(() => chrome.storage.session.set({ actRuns: runs }))
    .catch(() => {})
    .then(() => badge());
}

async function badge() {
  const working = [...JOBS.values()].some((j) => !j.watcher && j.state !== "stopped");
  // D1: a colour while a bot works in this browser; alerts.ts owns the count.
  await chrome.action
    .setBadgeBackgroundColor({ color: working ? "#7c5cff" : "#d93025" })
    .catch(() => {});
}

function step(job: Job, text: string) {
  job.steps.push({ at: Date.now(), text });
  if (job.steps.length > 50) job.steps.splice(0, job.steps.length - 50);
  publish();
}

// --- Tabs and the bot's group -----------------------------------------------------------------

async function groups(): Promise<Record<string, number>> {
  return (
    ((await chrome.storage.session.get("actGroups")).actGroups as Record<string, number>) ?? {}
  );
}

async function groupTabs(groupId: number | null): Promise<chrome.tabs.Tab[]> {
  if (groupId === null) return [];
  return chrome.tabs.query({ groupId }).catch(() => []);
}

async function liveGroup(job: Job): Promise<number | null> {
  if (job.groupId !== null) {
    const ok = await chrome.tabGroups
      ?.get(job.groupId)
      .then(() => true)
      .catch(() => false);
    if (ok) return job.groupId;
  }
  const g = (await groups())[job.botId];
  if (
    g !== undefined &&
    (await chrome.tabGroups
      ?.get(g)
      .then(() => true)
      .catch(() => false))
  ) {
    job.groupId = g;
    return g;
  }
  job.groupId = null;
  return null;
}

function colorFor(botId: string) {
  let h = 0;
  for (const c of botId) h = (h * 31 + c.charCodeAt(0)) >>> 0;
  return COLORS[h % COLORS.length];
}

/** A new background tab in the bot's group (making the group when there's none). */
async function newTab(job: Job, url = "about:blank"): Promise<number> {
  const groupId = await liveGroup(job);
  let windowId: number | undefined;
  if (groupId !== null) windowId = (await chrome.tabGroups.get(groupId)).windowId;
  else
    windowId = (await chrome.windows.getLastFocused({ windowTypes: ["normal"] }).catch(() => null))
      ?.id;
  const tab = await chrome.tabs.create({
    url,
    active: false,
    ...(windowId !== undefined ? { windowId } : {}),
  });
  const tabId = tab.id as number;
  if (groupId !== null) await chrome.tabs.group({ tabIds: [tabId], groupId });
  else {
    const g = await chrome.tabs.group({
      tabIds: [tabId],
      ...(windowId !== undefined ? { createProperties: { windowId } } : {}),
    });
    job.groupId = g;
    await chrome.tabGroups
      ?.update(g, { title: job.botName.slice(0, 40), color: colorFor(job.botId), collapsed: true })
      .catch(() => {});
    await chrome.storage.session.set({ actGroups: { ...(await groups()), [job.botId]: g } });
  }
  return tabId;
}

/** The tab the bot works in: its current one if still in the group, else the group's first, else a new one. */
async function tabFor(job: Job): Promise<number> {
  const tabs = await groupTabs(await liveGroup(job));
  if (job.current !== null && tabs.some((t) => t.id === job.current)) return job.current;
  const first = tabs[0]?.id;
  job.current = first ?? (await newTab(job));
  return job.current;
}

async function attachTo(job: Job, tabId: number) {
  if (!cdp.attached(tabId)) await cdp.attach(tabId);
  job.attachedTabs.add(tabId);
  await showOverlay(
    tabId,
    job.botName,
    job.state === "asking" ? "asking" : job.state === "paused" ? "paused" : "working",
    (e) => onOverlay(job, tabId, e),
  ).catch(() => {});
}

/** Starts the idle clock when a call ends (never during one: asks and downloads take time). */
function armIdle(job: Job) {
  clearTimeout(job.idle);
  job.idle = setTimeout(() => {
    // A paused or asking job keeps its banner (with Hand back) until it moves on.
    if (job.state === "paused" || job.state === "asking" || job.aborts.size) return armIdle(job);
    void release(job);
  }, IDLE_DETACH_MS);
  clearTimeout(job.forget);
  job.forget = setTimeout(() => {
    void release(job);
    JOBS.delete(job.key);
    publish();
  }, FORGET_MS);
}

/** Takes the banner off and detaches from the job's tabs. */
async function release(job: Job) {
  for (const t of job.attachedTabs) {
    await hideOverlay(t).catch(() => {});
    await cdp.detach(t);
  }
  job.attachedTabs.clear();
}

async function setOverlayState(job: Job, state: "working" | "paused" | "asking") {
  for (const t of job.attachedTabs)
    await showOverlay(t, job.botName, state, (e) => onOverlay(job, t, e)).catch(() => {});
}

function onOverlay(job: Job, _tabId: number, e: OverlayEvent) {
  if (e.type === "stop") return void stopJob(job, "banner");
  if (e.type === "takeover") {
    // The bot's own clicks and keys are real input too: ignore what comes right after them.
    if (e.at - job.lastInput < 500 || job.state !== "working") return;
    job.state = "paused";
    step(job, "You took over");
    void setOverlayState(job, "paused");
    return;
  }
  if (e.type === "handback" && job.state === "paused") {
    job.state = "working";
    step(job, "You handed back");
    void setOverlayState(job, "working");
    job.resume?.();
  }
}

/** Hand back from the panel. */
export function handBack(key: string) {
  const j = JOBS.get(key);
  if (j) onOverlay(j, j.current ?? -1, { type: "handback", at: Date.now() });
}

// --- Stopping ---------------------------------------------------------------------------------

export async function stopJob(job: Job, by: string) {
  if (job.state === "stopped") return;
  job.state = "stopped";
  job.stoppedBy = by;
  step(job, by === "banner" || by === "panel" ? "You stopped it" : `Stopped (${by})`);
  denyFor(job.key);
  for (const a of job.aborts) a.abort();
  job.resume?.();
  await release(job);
  if (job.runId && host) await host.cancelRun(job.runId).catch(() => {});
  publish();
}

export async function stopByKey(key: string, by: string) {
  const j = JOBS.get(key);
  if (j) await stopJob(j, by);
}

/** Unpairing: everything stops. */
export async function stopAll(by: string) {
  await Promise.all([...JOBS.values()].filter((j) => !j.watcher).map((j) => stopJob(j, by)));
}

/**
 * The connection dropped (a deploy, sleep, a network blip): the calls in flight end, since their
 * answers can't reach the server, but the runs aren't stopped and carry on after reconnecting.
 */
export function abortInFlight() {
  for (const j of JOBS.values()) for (const a of j.aborts) a.abort();
}

let wired = false;
export function installRunner() {
  if (wired) return;
  wired = true;
  cdp.installCdp();
  // Chrome's own "Cancel" on the debugging bar.
  cdp.onDetach((tabId, reason) => {
    forgetOverlay(tabId);
    for (const j of JOBS.values()) {
      if (!j.attachedTabs.delete(tabId)) continue;
      if (reason === "canceled_by_user") void stopJob(j, "Chrome's Cancel");
    }
  });
  // Closing the bot's group.
  chrome.tabGroups?.onRemoved.addListener((g) => {
    for (const j of JOBS.values())
      if (j.groupId === g.id && !j.watcher) void stopJob(j, "group closed");
  });
  chrome.tabs.onRemoved.addListener((tabId) => {
    for (const j of JOBS.values()) {
      j.attachedTabs.delete(tabId);
      if (j.current === tabId) j.current = null;
    }
  });
  // A tab dragged out of the group is the person's again: let go of it.
  chrome.tabs.onUpdated.addListener((tabId, info) => {
    if (info.groupId === undefined) return;
    for (const j of JOBS.values()) {
      if (j.groupId === null || info.groupId === j.groupId || !j.attachedTabs.has(tabId)) continue;
      j.attachedTabs.delete(tabId);
      if (j.current === tabId) j.current = null;
      void hideOverlay(tabId).then(() => cdp.detach(tabId));
      step(j, "You took a tab back");
    }
  });
}

// --- Checks -----------------------------------------------------------------------------------

async function localRules(job: Job) {
  const [m, s, extraHosts, local] = await Promise.all([
    getManaged(),
    getSettings(),
    guardAdditions(),
    getLocal(),
  ]);
  return {
    managedBlocked: m.BlockedSites,
    managedAllowed: m.AllowedSites,
    neverList: s.neverList,
    once: job.once,
    extraHosts,
    ownUrls: local.accounts.flatMap((a) => [a.server, a.authUrl]),
  };
}

/** Whether the bot may work on [url]; asks the person when the site needs it. */
async function siteGate(job: Job, url: string, policy: SitePolicy): Promise<BrowserResult | null> {
  const rules = await localRules(job);
  const d = siteDecision(
    url,
    { ...policy, own_urls: [...policy.own_urls, ...rules.ownUrls] },
    rules,
  );
  if (d.kind === "allowed") return null;
  if (d.kind === "refused") return fail("refused", `${d.host}: ${d.reason}`);
  if (job.watcher)
    return fail(
      "refused",
      d.kindOfSite
        ? `${d.host}: ${d.reason}`
        : `${d.host} isn't on this browser's always-allowed sites. Watchers here run unattended, so they only read sites the person set to "Always allow".`,
    );
  const a = await asking(job, () =>
    ask({
      kind: "site",
      bot: job.botName,
      owner: job.key,
      host: d.host,
      title: `Let ${job.botName} work on ${d.host}?`,
      detail: d.kindOfSite
        ? `${d.reason} You switched this kind back on, so Casama asks every time.`
        : `${job.botName} wants to open and use ${d.host} in its tab group, signed in as you.`,
    }),
  );
  if (a === "once") job.once.push(d.host);
  else if (a === "always" && !d.kindOfSite) {
    job.once.push(d.host);
    await host?.rememberSite("allowed_sites", d.host, policy.allowed_sites).catch(() => {});
  } else if (a === "always") job.once.push(d.host);
  else {
    if (a === "never")
      await host?.rememberSite("blocked_sites", d.host, policy.blocked_sites).catch(() => {});
    return fail("asked_denied", `The person didn't let you use ${d.host}.`);
  }
  step(job, `Allowed on ${d.host}`);
  return null;
}

async function asking<T>(job: Job, fn: () => Promise<T>): Promise<T> {
  const before = job.state;
  job.state = "asking";
  await setOverlayState(job, "asking");
  publish();
  try {
    return await fn();
  } finally {
    if (job.state === "asking") {
      job.state = before === "asking" ? "working" : before;
      await setOverlayState(job, job.state === "paused" ? "paused" : "working");
      publish();
    }
  }
}

/** Applies a risk verdict: null to go ahead, or the answer to give the bot. */
async function verdictGate(job: Job, v: Verdict, what: string): Promise<BrowserResult | null> {
  if (v.kind === "ok") return null;
  if (v.kind === "hand_off") {
    step(job, `Handed to you: ${v.reason}`);
    void chrome.notifications
      ?.create(`act-handoff:${job.key}:${Date.now()}`, {
        type: "basic",
        iconUrl: chrome.runtime.getURL("icons/icon-128.png"),
        title: `${job.botName} needs you`,
        message: `${v.reason}. Finish this step yourself in the "${job.botName}" tab group.`,
      })
      .catch?.(() => {});
    return fail(
      "handed_off",
      `${v.reason}. This step is the person's to do: tell them what's left, and don't try another way.`,
    );
  }
  const a = await asking(job, () =>
    ask({
      kind: "step",
      bot: job.botName,
      owner: job.key,
      title: `Let ${job.botName} ${what}?`,
      detail: v.reason,
    }),
  );
  if (a === "allow") return null;
  return fail("asked_denied", `The person said no: ${v.reason}.`);
}

function remember(job: Job, url: string | undefined, text: string) {
  const h = url ? hostOf(url) : null;
  if (!h || !text) return;
  const list = job.readBy.get(h) ?? [];
  list.push(text.slice(0, 100_000));
  if (list.length > 5) list.shift();
  job.readBy.set(h, list);
}

async function crossSiteGate(job: Job, text: string, url: string | undefined) {
  const h = url ? hostOf(url) : null;
  if (!h) return null;
  const from = crossSite(text, h, job.readBy);
  if (!from) return null;
  return verdictGate(
    job,
    { kind: "ask", reason: `It types text read on ${from.from} into ${h}` },
    `type on ${h} what it read on ${from.from}`,
  );
}

// --- Calls --------------------------------------------------------------------------------------

function jobFor(call: Call): Job {
  const key = call.run ? call.run.id : `w:${call.watcher?.id}`;
  let j = JOBS.get(key);
  if (!j) {
    const who = call.run ?? call.watcher;
    j = {
      key,
      runId: call.run?.id ?? null,
      botId: who?.bot_id ?? "",
      botName: who?.bot_name ?? "Bot",
      watcher: !call.run,
      groupId: null,
      current: null,
      refs: {},
      readBy: new Map(),
      once: [],
      state: "working",
      steps: [],
      lastInput: 0,
      aborts: new Set(),
      attachedTabs: new Set(),
    };
    JOBS.set(key, j);
  }
  return j;
}

/** One call from a run or a watcher. [signal] aborts it (the server cancelled the request). */
export async function handleCall(call: Call, signal?: AbortSignal): Promise<BrowserResult> {
  if ((await getManaged()).ActDisabled)
    return fail("act_off", "Your administrator turned off bots in this browser.");
  if (!call.run && !call.watcher) return fail("bad_call", "No run or watcher");
  const job = jobFor(call);
  if (job.state === "stopped")
    return fail("stopped", "The person stopped this. Don't use their browser again in this task.");
  const ac = new AbortController();
  job.aborts.add(ac);
  clearTimeout(job.idle);
  const onAbort = () => ac.abort();
  signal?.addEventListener("abort", onAbort);
  // A cancelled call's open asks are answered no, so a late Allow can't run its step.
  ac.signal.addEventListener("abort", () => denyFor(job.key));
  try {
    if (job.state === "paused") {
      const back = await new Promise<boolean>((resolve) => {
        const t = setTimeout(() => resolve(false), PAUSE_WAIT_MS);
        job.resume = () => {
          clearTimeout(t);
          resolve(true);
        };
        ac.signal.addEventListener("abort", () => resolve(false));
      });
      job.resume = undefined;
      const now = job.state as Job["state"];
      if (!back || now !== "working")
        return now === "stopped"
          ? fail("stopped", "The person stopped this.")
          : fail("handed_off", "The person took over the tab and hasn't handed it back yet.");
    }
    const out = await Promise.race([
      run(job, call, ac.signal),
      new Promise<BrowserResult>((resolve) =>
        ac.signal.addEventListener("abort", () =>
          resolve(
            job.state === "stopped"
              ? fail("stopped", "The person stopped this.")
              : fail("cancelled", "Cancelled"),
          ),
        ),
      ),
    ]);
    return out;
  } catch (e) {
    if (e instanceof page.ActError) return fail(e.code, e.message);
    return fail(
      "browser_error",
      (e as Error).message?.slice(0, 500) || "Something went wrong in the browser",
    );
  } finally {
    job.aborts.delete(ac);
    signal?.removeEventListener("abort", onAbort);
    if ((job.state as Job["state"]) !== "stopped") armIdle(job);
  }
}

const pointer = (job: Job): page.Pointer => ({
  beforeInput: () => {
    job.lastInput = Date.now();
  },
});

async function tabUrl(tabId: number) {
  return (await cdp.targetInfo(tabId)).url;
}

/** Throws when the call was cancelled, so nothing happens after an ask the run no longer waits for. */
function alive(signal: AbortSignal) {
  if (signal.aborted) throw new page.ActError("cancelled", "Cancelled");
}

/** A read is thrown away when the page went to another site meanwhile (that site wasn't checked). */
async function sameSiteAfter(tabId: number, url: string): Promise<BrowserResult | null> {
  const now = await tabUrl(tabId);
  if (hostOf(now) === hostOf(url)) return null;
  return fail(
    "page_changed",
    `The page went to ${hostOf(now) ?? "another address"} while it was being read. Look again.`,
  );
}

/** Runs [fn] and reports a page dialog that opened meanwhile instead of hanging on it. */
async function withDialogWatch(tabId: number, fn: () => Promise<void>): Promise<string | null> {
  let opened: (v: string) => void = () => {};
  const dialog = new Promise<string>((r) => {
    opened = r;
  });
  const off = cdp.listen(tabId, (method, p) => {
    if (method === "Page.javascriptDialogOpening")
      opened(`${p.type}: ${String(p.message ?? "").slice(0, 300)}`);
  });
  try {
    const r = await Promise.race([fn().then(() => null), dialog]);
    return r;
  } finally {
    off();
  }
}

function refOf(job: Job, raw: unknown) {
  const id = String(raw ?? "").replace(/^@/, "");
  const r = job.refs[id];
  if (!r)
    throw new page.ActError("stale_ref", `There's no ${id} on the page now. Take a new snapshot.`);
  if (r.tabId !== job.current)
    throw new page.ActError("stale_ref", `${id} was on another tab. Take a new snapshot.`);
  return r;
}

async function run(job: Job, call: Call, signal: AbortSignal): Promise<BrowserResult> {
  const a = call.args ?? {};
  const p = pointer(job);
  if (call.action === "stop") {
    await release(job);
    step(job, "Done");
    return okText("Stopped using the browser.");
  }
  if (call.action === "page_text") return pageText(job, String(a.url ?? ""), call.policy);
  if (call.action === "tabs") {
    const tabs = await groupTabs(await liveGroup(job));
    if (!tabs.length) return okText("No tabs yet. Open a page with browser.open.");
    const lines = await Promise.all(
      tabs.map(async (t) => {
        const i = await cdp.targetInfo(t.id as number);
        return `${t.id === job.current ? "* " : "  "}${t.id} ${i.title} (${i.url})`;
      }),
    );
    return okText(lines.join("\n"));
  }
  if (call.action === "switch_tab") {
    if (typeof a.url === "string" && a.url) {
      const gate = await siteGate(job, a.url, call.policy);
      if (gate) return gate;
      alive(signal);
      job.current = await newTab(job, a.url);
      await attachTo(job, job.current);
      await page.settle(job.current);
      step(job, `Opened ${hostOf(a.url) ?? a.url} in a new tab`);
      return okText(`Opened ${a.url} in a new tab.`, await tabUrl(job.current));
    }
    const id = Number(a.tab);
    const tabs = await groupTabs(await liveGroup(job));
    if (!tabs.some((t) => t.id === id))
      return fail("not_found", "That tab isn't in your group. List them with browser.tabs.");
    job.current = id;
    await attachTo(job, id);
    return okText(`Switched to tab ${id}.`, await tabUrl(id));
  }

  const tabId = await tabFor(job);
  await attachTo(job, tabId);

  if (call.action === "open") {
    const url = String(a.url ?? "");
    const gate = await siteGate(job, url, call.policy);
    if (gate) return gate;
    alive(signal);
    await page.navigate(tabId, url);
    job.refs = {};
    const landed = await tabUrl(tabId);
    // Redirects are checked too.
    const after = await siteGate(job, landed, call.policy);
    if (after) {
      await page.navigate(tabId, "about:blank").catch(() => {});
      return after;
    }
    const { title } = await cdp.targetInfo(tabId);
    step(job, `Opened ${hostOf(landed) ?? landed}`);
    return okText(`Opened ${title ? `"${title}" ` : ""}${landed}`, landed);
  }

  // Every other step: the page the bot is on must be one it may use.
  const url = await tabUrl(tabId);
  if (call.action !== "url") {
    const gate = await siteGate(job, url, call.policy);
    if (gate) return gate;
  }

  switch (call.action) {
    case "url":
      return okText(url, url);
    case "snapshot": {
      const s = await page.snapshot(tabId, a.interactive_only !== false);
      const moved = await sameSiteAfter(tabId, url);
      if (moved) return moved;
      job.refs = Object.fromEntries(Object.entries(s.refs).map(([k, v]) => [k, { ...v, tabId }]));
      remember(job, url, s.text);
      step(job, `Looked at ${hostOf(url) ?? "the page"}`);
      return okText(s.text, url);
    }
    case "read": {
      const text = await page.read(tabId);
      const moved = await sameSiteAfter(tabId, url);
      if (moved) return moved;
      remember(job, url, text);
      step(job, `Read ${hostOf(url) ?? "the page"}`);
      return okText(text || "(no text on the page)", url);
    }
    case "extract": {
      const text = await page.extractTables(tabId);
      const moved = await sameSiteAfter(tabId, url);
      if (moved) return moved;
      remember(job, url, text);
      step(job, "Copied tables from the page");
      return okText(text, url);
    }
    case "click": {
      const r = refOf(job, a.ref);
      const info = await page.nodeInfo(tabId, r.backendNodeId);
      const gate = await verdictGate(
        job,
        clickVerdict({
          role: r.role,
          name: r.name,
          url,
          submits: info.submits,
          passwordForm: info.passwordForm,
        }),
        `click "${r.name || r.role}"`,
      );
      if (gate) return gate;
      alive(signal);
      const dialog = await withDialogWatch(tabId, () => page.click(tabId, r.backendNodeId, p));
      p.beforeInput();
      if (dialog)
        return okText(
          `Clicked. A page dialog opened (${dialog}); answer it with browser.dialog.`,
          url,
        );
      await page.settle(tabId);
      step(job, `Clicked "${r.name || r.role}"`);
      const now = await tabUrl(tabId);
      return okText(`Clicked "${r.name || r.role}".${now !== url ? ` Now on ${now}` : ""}`, now);
    }
    case "fill": {
      const r = refOf(job, a.ref);
      const info = await page.nodeInfo(tabId, r.backendNodeId);
      const text = String(a.text ?? "");
      const gate =
        (await verdictGate(
          job,
          fieldVerdict({
            role: r.role,
            name: r.name,
            inputType: info.inputType,
            autocomplete: info.autocomplete,
          }),
          `fill "${r.name}"`,
        )) ?? (await crossSiteGate(job, text, url));
      if (gate) return gate;
      alive(signal);
      await page.fill(tabId, r.backendNodeId, text, p);
      step(job, `Filled "${r.name || r.role}"`);
      return okText(`Filled "${r.name || r.role}".`, url);
    }
    case "type": {
      const text = String(a.text ?? "");
      const focused = await page.focusedNode(tabId);
      if (focused === "unknown") {
        const gate = await verdictGate(job, OUT_OF_SIGHT, "type here");
        if (gate) return gate;
      } else if (focused !== null) {
        const info = await page.nodeInfo(tabId, focused);
        const gate = await verdictGate(
          job,
          fieldVerdict({
            role: "textbox",
            name: "",
            inputType: info.inputType,
            autocomplete: info.autocomplete,
          }),
          "type here",
        );
        if (gate) return gate;
      }
      const gate = await crossSiteGate(job, text, url);
      if (gate) return gate;
      alive(signal);
      await page.type(tabId, text, p);
      step(job, "Typed");
      return okText("Typed.", url);
    }
    case "press": {
      const key = String(a.key ?? "");
      const focused = await page.focusedNode(tabId);
      if (focused === "unknown") {
        const gate = await verdictGate(job, OUT_OF_SIGHT, `press ${key} here`);
        if (gate) return gate;
      } else if (focused !== null) {
        const info = await page.nodeInfo(tabId, focused);
        const gate = await verdictGate(
          job,
          keyVerdict(key, {
            inForm: info.inForm,
            submitName: info.formSubmitName,
            passwordForm: info.passwordForm,
            editable: info.editable,
            inputType: info.inputType,
            role: info.role,
          }),
          info.inForm ? `press ${key} to send the form` : `press ${key} here`,
        );
        if (gate) return gate;
      }
      alive(signal);
      const dialog = await withDialogWatch(tabId, () => page.key(tabId, key, p));
      if (dialog)
        return okText(
          `Pressed ${key}. A page dialog opened (${dialog}); answer it with browser.dialog.`,
          url,
        );
      await page.settle(tabId, 300);
      step(job, `Pressed ${key}`);
      return okText(`Pressed ${key}.`, await tabUrl(tabId));
    }
    case "scroll": {
      await page.scroll(tabId, a.direction === "up" ? "up" : "down", Number(a.amount ?? 600), p);
      return okText(`Scrolled ${a.direction === "up" ? "up" : "down"}.`, url);
    }
    case "screenshot": {
      const image = await page.screenshot(tabId);
      step(job, "Took a screenshot");
      return { ok: true, text: "Screenshot of the tab.", image, url };
    }
    case "wait": {
      if (typeof a.text === "string" && a.text) {
        const until = Date.now() + 30_000;
        while (Date.now() < until) {
          if ((await page.read(tabId)).includes(a.text))
            return okText(`"${a.text}" is on the page.`, await tabUrl(tabId));
          await new Promise((r) => setTimeout(r, 700));
        }
        return fail("timeout", `"${a.text}" didn't show up within 30 seconds.`);
      }
      await new Promise((r) => setTimeout(r, Math.min(Number(a.ms ?? 1000), 30_000)));
      return okText("Done waiting.", await tabUrl(tabId));
    }
    case "dialog": {
      const d = cdp.dialogOf(tabId);
      if (!d) return fail("no_dialog", "No dialog is open on the page.");
      await cdp.send(tabId, "Page.handleJavaScriptDialog", {
        accept: a.accept !== false,
        ...(typeof a.text === "string" ? { promptText: a.text } : {}),
      });
      step(job, a.accept === false ? "Dismissed a dialog" : "Accepted a dialog");
      return okText(
        `${a.accept === false ? "Dismissed" : "Accepted"} the ${d.type} ("${d.message.slice(0, 200)}").`,
        url,
      );
    }
    case "console": {
      const lines = cdp.consoleOf(tabId);
      return okText(
        lines.length
          ? lines.map((l) => `[${l.level}] ${l.text}`).join("\n")
          : "(nothing in the console since the bot started using this tab)",
        url,
      );
    }
    case "network": {
      const f = typeof a.filter === "string" ? a.filter.toLowerCase() : "";
      const lines = cdp
        .networkOf(tabId)
        .filter((n) => !f || n.url.toLowerCase().includes(f))
        .slice(-100)
        .map(
          (n) => `${n.method} ${n.status ?? (n.failed ? `failed (${n.failed})` : "…")} ${n.url}`,
        );
      return okText(
        lines.length
          ? lines.join("\n")
          : "No requests recorded since the bot started using this tab.",
        url,
      );
    }
    case "upload": {
      const r = refOf(job, a.ref);
      const file = a.file as { name: string; media_type: string; data: string } | undefined;
      if (!file?.data) return fail("bad_call", "No file to upload.");
      const info = await page.nodeInfo(tabId, r.backendNodeId);
      if (!info.isFile) return fail("not_upload", "That element isn't an upload field.");
      const gate = await verdictGate(
        job,
        { kind: "ask", reason: `It puts ${file.name} into a page on ${hostOf(url)}` },
        `upload ${file.name}`,
      );
      if (gate) return gate;
      alive(signal);
      await page.upload(tabId, r.backendNodeId, file);
      step(job, `Put ${file.name} in an upload field`);
      return okText(`Put ${file.name} in the upload field.`, url);
    }
    case "download": {
      let target = typeof a.url === "string" ? a.url : "";
      if (!target && a.ref) {
        const r = refOf(job, a.ref);
        target = (await page.nodeInfo(tabId, r.backendNodeId)).href ?? "";
      }
      if (!target) return fail("bad_call", "That isn't a link to a file.");
      const abs = new URL(target, url).toString();
      const gate = await siteGate(job, abs, call.policy);
      if (gate) return gate;
      alive(signal);
      const got = await page.download(tabId, abs, FILE_MAX);
      if ("error" in got) return fail("download_failed", got.error);
      step(job, `Downloaded ${got.name}`);
      return { ok: true, text: `Downloaded ${got.name}.`, file: got, url };
    }
  }
  return fail("bad_call", `Unknown action ${call.action}`);
}

/** A watcher's check: the page's visible text, read in a background tab of the bot's group. */
async function pageText(job: Job, url: string, policy: SitePolicy): Promise<BrowserResult> {
  const gate = await siteGate(job, url, policy);
  if (gate) return gate;
  const tabId = await newTab(job, "about:blank");
  try {
    await cdp.attach(tabId);
    await page.navigate(tabId, url);
    const landed = await tabUrl(tabId);
    const after = await siteGate(job, landed, policy);
    if (after) return after;
    const text = await page.read(tabId);
    return (await sameSiteAfter(tabId, landed)) ?? okText(text, landed);
  } finally {
    await cdp.detach(tabId);
    await chrome.tabs.remove(tabId).catch(() => {});
  }
}
