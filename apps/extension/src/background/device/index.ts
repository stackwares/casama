/**
 * This browser as a device (D-323 E2–E6, F3; plan §9.6). All opt-in, per kind, in the options page:
 *
 * - "The tab in front" (kind browser_tab): a bot the person allowed in Device connections, on any
 *   surface, asks; this browser answers with the address, title, selection and readable text. The
 *   desktop app's quick ask on Windows and Linux asks the same way (E3).
 * - "History search" (browser_history): pages from history and bookmarks matching a bot's search.
 * - "Start routines" (E4): opening a site one of the person's routines names, a finished download,
 *   a new bookmark. Only those events go, and only when a routine starts on them.
 * - "Activity recap" (activity, E5): minutes per site per hour, site names only. Off by default.
 *
 * Requests arrive on the person's Realtime topic, like the phone's (D-149), and are answered within
 * the server's 10-second window. A request is answered from the device source this browser
 * registered (platform web); the guard (Casama's own pages, the never-list, the off-by-default
 * kinds of site, password and card fields) applies to every read.
 */
import type { Schemas } from "@casama/client";
import { hasConsent } from "../../lib/consent.ts";
import {
  type ActivityBuckets,
  addMinute,
  type BrowserTrigger,
  finishedHours,
  historyItems,
  hourKey,
  tabSummary,
  wanted,
} from "../../lib/device/pure.ts";
import { Realtime } from "../../lib/device/realtime.ts";
import { guardUrl } from "../../lib/guard.ts";
import { guardAdditions } from "../../lib/guard-sites.ts";
import { activeTab, NoAccessError, readTab } from "../../lib/page.ts";
import { accessToken, clientFor } from "../../lib/session.ts";
import { getSettings } from "../../lib/settings.ts";
import { type Account, activeAccount, getLocal } from "../../lib/store.ts";

export interface BrowserDevice {
  accountId: string;
  key: string;
  sourceId: string | null;
  name: string;
  /** E2: answer "what's on my screen". */
  tab: boolean;
  /** E6: search history and bookmarks on request. */
  history: boolean;
  /** E4: report the events the person's routines start on. */
  triggers: boolean;
  /** E5: minutes per site per hour. */
  activity: boolean;
  /** F3: page content from this browser goes only to bots on private models. */
  privateModel: boolean;
}

export type BrowserDevicePatch = Partial<
  Pick<BrowserDevice, "tab" | "history" | "triggers" | "activity" | "privateModel">
>;

const KEY = "browserDevice";
const TRIGGERS_FRESH_MS = 10 * 60_000;

export async function getBrowserDevice(): Promise<BrowserDevice | null> {
  return ((await chrome.storage.local.get(KEY))[KEY] as BrowserDevice | undefined) ?? null;
}

async function accountOf(d: BrowserDevice): Promise<Account | null> {
  return (await getLocal()).accounts.find((a) => a.id === d.accountId) ?? null;
}

function deviceName() {
  const ua = navigator.userAgent;
  const os = /Mac OS X/.test(ua)
    ? "Mac"
    : /Windows/.test(ua)
      ? "Windows"
      : /CrOS/.test(ua)
        ? "ChromeOS"
        : /Linux/.test(ua)
          ? "Linux"
          : "";
  const browser = /Edg\//.test(ua) ? "Edge" : "Chrome";
  return os ? `${browser} on ${os}` : browser;
}

/** The kinds this browser shares, as the server stores them. */
function kindsOf(d: BrowserDevice) {
  const pm = d.privateModel ? { private_model: true } : {};
  return {
    ...(d.tab ? { browser_tab: { retention_days: 0, ...pm } } : {}),
    ...(d.history ? { browser_history: { retention_days: 0, ...pm } } : {}),
    ...(d.activity ? { activity: { retention_days: 30, ...pm } } : {}),
  };
}

const anyOn = (d: BrowserDevice) => d.tab || d.history || d.triggers || d.activity;

/**
 * Turns kinds on or off for [account] and tells the server. With everything off the device source
 * is deleted (and with it whatever it stored, which for a browser is only the activity recap).
 */
export async function setBrowserDevice(
  account: Account,
  patch: BrowserDevicePatch,
): Promise<BrowserDevice | null> {
  const before = await getBrowserDevice();
  // Another account's device: take it off that account's server first, so nothing is left there.
  if (before && before.accountId !== account.id) {
    const prev = await accountOf(before);
    if (prev && before.sourceId)
      await clientFor(prev)
        .DELETE("/v1/device-sources/{key}", { params: { path: { key: before.key } } })
        .catch(() => {});
  }
  const d: BrowserDevice =
    before && before.accountId === account.id
      ? { ...before, ...patch }
      : {
          accountId: account.id,
          key: `browser-${crypto.randomUUID()}`,
          sourceId: null,
          name: deviceName(),
          tab: false,
          history: false,
          triggers: false,
          activity: false,
          privateModel: false,
          ...patch,
        };
  const api = clientFor(account);
  if (!anyOn(d)) {
    if (d.sourceId)
      await api
        .DELETE("/v1/device-sources/{key}", { params: { path: { key: d.key } } })
        .catch(() => {});
    await chrome.storage.local.remove("activityBuckets");
    // "Private models only" also covers the panel, so it outlives the kinds.
    if (d.privateModel) await chrome.storage.local.set({ [KEY]: { ...d, sourceId: null } });
    else await chrome.storage.local.remove(KEY);
    await syncDevice();
    return d.privateModel ? { ...d, sourceId: null } : null;
  }
  const saved = await api.unwrap(
    api.PUT("/v1/device-sources/{key}", {
      params: { path: { key: d.key } },
      body: { name: d.name, platform: "web", kinds: kindsOf(d) },
    }),
  );
  d.sourceId = saved.id;
  await chrome.storage.local.set({ [KEY]: d });
  if (!d.activity) await chrome.storage.local.remove("activityBuckets");
  await syncDevice();
  return d;
}

// --- Requests --------------------------------------------------------------------------------

let realtime: Realtime | null = null;
let realtimeFor: string | null = null;
let draining: Promise<void> | null = null;
/** A request was announced while a drain was under way: list again before stopping. */
let drainAgain = false;

/** Starts or stops listening, after a settings, sign-in or consent change. */
export async function syncDevice() {
  const d = await getBrowserDevice();
  const account = d ? await accountOf(d) : null;
  const listen = !!d && !!account && (d.tab || d.history) && (await hasConsent());
  if (!listen || realtimeFor !== account?.id) {
    realtime?.stop();
    realtime = null;
    realtimeFor = null;
  }
  if (!listen || realtime || !account) return;
  realtimeFor = account.id;
  realtime = new Realtime({
    authUrl: account.authUrl,
    anonKey: account.anonKey,
    topic: `user:${account.userId}`,
    token: () => accessToken(account.id),
    onBroadcast: (event, payload) => {
      if (event === "device_request" && payload.source_id === d?.sourceId) void drain();
    },
    // Anything asked while the channel was down is picked up on joining.
    onStatus: (joined) => {
      void chrome.storage.session.set({ deviceListening: joined });
      if (joined) void drain();
    },
  });
  await realtime.start();
}

/** Answers every pending request for this browser, one at a time. */
export function drain(): Promise<void> {
  if (draining) {
    drainAgain = true;
    return draining;
  }
  draining = (async () => {
    try {
      do {
        drainAgain = false;
        const d = await getBrowserDevice();
        const account = d ? await accountOf(d) : null;
        if (!d?.sourceId || !account) return;
        const api = clientFor(account);
        // Listing also tells the server this browser is around (its last_seen).
        const { items } = await api.unwrap(
          api.GET("/v1/device-sources/{key}/requests", { params: { path: { key: d.key } } }),
        );
        for (const r of items) await answer(api, d, r);
      } while (drainAgain);
    } finally {
      draining = null;
    }
  })().catch(() => {});
  return draining;
}

type Api = ReturnType<typeof clientFor>;

async function fail(api: Api, id: string, error: string) {
  await api
    .POST("/v1/device-requests/{id}/result", {
      params: { path: { id } },
      body: { ok: false, error: error.slice(0, 1000) },
    })
    .catch(() => {});
}

async function upload(
  api: Api,
  d: BrowserDevice,
  r: Schemas["DeviceRequest"],
  summary: Record<string, unknown>,
) {
  const now = new Date().toISOString();
  await api.unwrap(
    api.POST("/v1/device-sources/{key}/readings", {
      params: { path: { key: d.key } },
      body: {
        request_id: r.id,
        readings: [
          {
            kind: r.kind as "browser_tab",
            period_start: now,
            period_end: now,
            external_id: `${r.kind}-${r.id}`,
            summary,
          },
        ],
      },
    }),
  );
}

async function blocker() {
  const s = await getSettings();
  const own: string[] = [];
  for (const a of (await getLocal()).accounts)
    for (const u of [a.server, a.authUrl])
      try {
        own.push(new URL(u).host);
      } catch {
        // Not an address.
      }
  const extraHosts = await guardAdditions();
  return (url: string) =>
    guardUrl(url, { neverList: s.neverList, ownHosts: own, extraHosts }) !== null;
}

async function answer(api: Api, d: BrowserDevice, r: Schemas["DeviceRequest"]) {
  try {
    if (r.action !== "read") return fail(api, r.id, "This browser only answers reads.");
    if (r.kind === "browser_tab") {
      if (!d.tab) return fail(api, r.id, "Sharing the tab in front is off in this browser.");
      const tab = await activeTab();
      if (tab?.incognito) return fail(api, r.id, "The tab in front is in a private window.");
      let ctx: Awaited<ReturnType<typeof readTab>>;
      // The desktop app's quick ask needs only the address and title (E3).
      if (r.params.brief === true) {
        if (tab?.url && (await blocker())(tab.url))
          return fail(api, r.id, "The tab in front can't be shared.");
        ctx = { url: tab?.url, title: tab?.title };
      } else
        try {
          ctx = await readTab(tab);
        } catch (e) {
          // No site access: the address and title still go, without the page's text.
          if (!(e instanceof NoAccessError)) throw e;
          ctx = { url: tab?.url, title: tab?.title };
        }
      if (ctx.blocked) return fail(api, r.id, `The tab in front can't be shared: ${ctx.blocked}`);
      if (!ctx.url)
        return fail(
          api,
          r.id,
          "Casama can't see the tab in front. Allow tab access in Casama's settings.",
        );
      return upload(api, d, r, { ...tabSummary(ctx) });
    }
    if (r.kind === "browser_history") {
      if (!d.history) return fail(api, r.id, "History search is off in this browser.");
      const query = String(r.params.query ?? "").slice(0, 200);
      if (!query) return fail(api, r.id, "A history search needs words to look for.");
      const from = Date.parse(String(r.params.from ?? "")) || Date.now() - 90 * 86_400_000;
      const history = chrome.history
        ? await chrome.history.search({ text: query, startTime: from, maxResults: 100 })
        : [];
      const marks = chrome.bookmarks ? await chrome.bookmarks.search(query).catch(() => []) : [];
      const blocked = await blocker();
      return upload(api, d, r, {
        type: "history",
        query,
        items: historyItems(history, marks, blocked),
      });
    }
    return fail(api, r.id, `This browser doesn't share ${r.kind}.`);
  } catch (e) {
    return fail(api, r.id, (e as Error).message || "The browser couldn't answer.");
  }
}

// --- Browser triggers (E4) ---------------------------------------------------------------------

async function triggers(d: BrowserDevice, account: Account): Promise<BrowserTrigger[]> {
  const cached = (await chrome.storage.session.get("browserTriggers")).browserTriggers as
    | { at: number; accountId: string; items: BrowserTrigger[] }
    | undefined;
  if (cached && cached.accountId === d.accountId && Date.now() - cached.at < TRIGGERS_FRESH_MS)
    return cached.items;
  const api = clientFor(account);
  const { items } = await api.unwrap(api.GET("/v1/device-triggers/browser", {}));
  await chrome.storage.session.set({
    browserTriggers: { at: Date.now(), accountId: d.accountId, items },
  });
  return items;
}

const recent = new Map<string, number>();

async function report(
  e: { event: BrowserTrigger["event"]; url?: string; name?: string; title?: string },
  dedupeKey: string,
) {
  const d = await getBrowserDevice();
  const account = d ? await accountOf(d) : null;
  if (!d?.triggers || !account || !(await hasConsent())) return;
  let host: string | null = null;
  try {
    host = e.url ? new URL(e.url).hostname.toLowerCase().replace(/^www\./, "") : null;
  } catch {
    host = null;
  }
  if (e.url && (await blocker())(e.url)) return;
  if (!wanted(await triggers(d, account), { event: e.event, host, name: e.name })) return;
  const last = recent.get(dedupeKey) ?? 0;
  if (Date.now() - last < 10 * 60_000) return;
  recent.set(dedupeKey, Date.now());
  const api = clientFor(account);
  await api
    .POST("/v1/device-sources/{key}/events", {
      params: { path: { key: d.key } },
      body: {
        events: [
          {
            id: `${e.event}-${dedupeKey}-${Math.floor(Date.now() / 60_000)}`.slice(0, 200),
            type: e.event,
            at: new Date().toISOString(),
            ...(host ? { site: host } : {}),
            ...(e.name ? { name: e.name.slice(0, 300) } : {}),
            ...(e.title ? { title: e.title.slice(0, 300) } : {}),
          },
        ],
      },
    })
    .catch(() => {});
}

const attached = new Set<string>();
/** Listeners for optional permissions, attached once they're granted (now or later). */
function attachOptional() {
  if (chrome.downloads && !attached.has("downloads")) {
    attached.add("downloads");
    chrome.downloads.onChanged.addListener((delta) => {
      if (delta.state?.current !== "complete") return;
      void chrome.downloads.search({ id: delta.id }).then(([item]) => {
        if (!item) return;
        const name = item.filename.split(/[\\/]/).pop() ?? "";
        void report(
          { event: "download_done", url: item.finalUrl || item.url, name },
          `dl-${item.id}`,
        );
      });
    });
  }
  if (chrome.bookmarks && !attached.has("bookmarks")) {
    attached.add("bookmarks");
    chrome.bookmarks.onCreated.addListener((id, node) => {
      if (node.url)
        void report({ event: "bookmark_added", url: node.url, title: node.title }, `bm-${id}`);
    });
  }
}

// --- Activity recap (E5) -----------------------------------------------------------------------

async function sampleActivity(d: BrowserDevice, account: Account) {
  const win = await chrome.windows.getLastFocused({ windowTypes: ["normal"] }).catch(() => null);
  if (!win?.focused) return;
  if (chrome.idle && (await chrome.idle.queryState(60)) !== "active") return;
  const [tab] = await chrome.tabs.query({ active: true, windowId: win.id });
  if (tab?.incognito) return;
  let host: string | null = null;
  try {
    host =
      tab?.url && /^https?:/.test(tab.url) ? new URL(tab.url).hostname.replace(/^www\./, "") : null;
  } catch {
    host = null;
  }
  // Pages the guard keeps out aren't named.
  if (!host || (tab?.url && (await blocker())(tab.url))) return;
  const now = new Date();
  let buckets = ((await chrome.storage.local.get("activityBuckets")).activityBuckets ??
    {}) as ActivityBuckets;
  buckets = addMinute(buckets, hourKey(now), host);
  const done = finishedHours(buckets, hourKey(now));
  if (done.length) {
    const api = clientFor(account);
    const sent = await api
      .POST("/v1/device-sources/{key}/readings", {
        params: { path: { key: d.key } },
        body: {
          readings: done.map((h) => ({
            kind: "activity" as const,
            period_start: `${h.hour}:00:00Z`,
            period_end: `${h.hour}:59:59Z`,
            external_id: `web-${h.hour}`,
            summary: { ...h },
          })),
        },
      })
      .then((r) => !r.error)
      .catch(() => false);
    if (sent) for (const h of done) delete buckets[h.hour];
  }
  await chrome.storage.local.set({ activityBuckets: buckets });
}

/** The minute tick: keeps the browser seen, picks up missed requests, samples activity. */
export async function deviceTick() {
  const d = await getBrowserDevice();
  const account = d ? await accountOf(d) : null;
  if (!d || !account || !(await hasConsent())) return;
  if (d.tab || d.history) await drain();
  if (d.activity) await sampleActivity(d, account).catch(() => {});
  // Not joined after a minute (a dead socket, a laptop that woke offline): start over.
  if ((d.tab || d.history) && !realtime?.joined) {
    realtime?.stop();
    realtime = null;
    realtimeFor = null;
    await syncDevice();
  }
}

let installed = false;
export function installDevice() {
  if (installed) return;
  installed = true;
  attachOptional();
  chrome.permissions.onAdded.addListener(() => attachOptional());
  // Sites opened, for routines that start on them (needs the tabs permission to see addresses).
  chrome.tabs.onUpdated.addListener((tabId, info, tab) => {
    if (info.status !== "complete" || tab.incognito || !tab.url || !/^https?:/.test(tab.url))
      return;
    let host = "";
    try {
      host = new URL(tab.url).hostname;
    } catch {
      return;
    }
    void report({ event: "site_opened", url: tab.url }, `site-${tabId}-${host}`);
  });
  chrome.storage.onChanged.addListener((changes, area) => {
    if (area === "local" && (changes.accounts || changes.consent)) void syncDevice();
  });
  void syncDevice();
}

export type DeviceMessage =
  | { type: "device:get" }
  | { type: "device:set"; patch: BrowserDevicePatch };

const fromOwnPage = (sender: chrome.runtime.MessageSender) =>
  sender.id === chrome.runtime.id && !!sender.url?.startsWith(chrome.runtime.getURL(""));

/** From the options page: read or change what this browser shares. */
export function onDeviceMessage(
  m: DeviceMessage,
  sender: chrome.runtime.MessageSender,
  reply: (r: unknown) => void,
): boolean {
  if (!m?.type?.startsWith("device:") || !fromOwnPage(sender)) return false;
  const run = async () => {
    if (m.type === "device:get") {
      const d = await getBrowserDevice();
      const account = await activeAccount();
      return {
        device: d && account && d.accountId === account.id ? d : null,
        listening: !!(await chrome.storage.session.get("deviceListening")).deviceListening,
      };
    }
    const account = await activeAccount();
    if (!account) throw new Error("Sign in first.");
    return { device: await setBrowserDevice(account, m.patch) };
  };
  run().then(
    (result) => reply({ ok: true, result }),
    (e: unknown) => reply({ ok: false, error: (e as Error).message ?? String(e) }),
  );
  return true;
}
