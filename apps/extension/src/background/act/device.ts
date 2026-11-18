/**
 * This browser as a device bots can use (D-323 C1, plan §9.5): pairing makes a browser-only local
 * device (platform "chrome", capability "browser"), and the service worker keeps the device
 * WebSocket open while paired, answering the API's tool requests with the runner.
 *
 * The socket sends a small message every 20 seconds, which also keeps the service worker alive
 * (Chrome 116+); an alarm reconnects after the worker was stopped anyway.
 */
import type { Schemas } from "@casama/client";
import { getManaged } from "../../lib/act/managed.ts";
import { hasConsent } from "../../lib/consent.ts";
import { clientFor } from "../../lib/session.ts";
import { type Account, getLocal } from "../../lib/store.ts";
import {
  abortInFlight,
  type Call,
  handleCall,
  installRunner,
  setRunnerHost,
  stopAll,
} from "./runner.ts";

export interface PairedDevice {
  accountId: string;
  server: string;
  orgId: string;
  deviceId: string;
  token: string;
  name: string;
}

export interface ActStatus {
  paired: boolean;
  online: boolean;
  error: string | null;
  deviceId: string | null;
  accountId: string | null;
}

const KEEPALIVE_MS = 20_000;
let ws: WebSocket | null = null;
let keepalive: ReturnType<typeof setInterval> | undefined;
let retry: ReturnType<typeof setTimeout> | undefined;
let backoff = 1000;
const inflight = new Map<string, AbortController>();

export async function pairedDevice(): Promise<PairedDevice | null> {
  return (
    ((await chrome.storage.local.get("actDevice")).actDevice as PairedDevice | undefined) ?? null
  );
}

async function status(patch: Partial<ActStatus>) {
  const d = await pairedDevice();
  const cur = ((await chrome.storage.session.get("actStatus")).actStatus as
    | ActStatus
    | undefined) ?? {
    paired: false,
    online: false,
    error: null,
    deviceId: null,
    accountId: null,
  };
  await chrome.storage.session.set({
    actStatus: {
      ...cur,
      paired: !!d,
      deviceId: d?.deviceId ?? null,
      accountId: d?.accountId ?? null,
      ...patch,
    },
  });
}

async function accountOf(d: PairedDevice): Promise<Account | null> {
  return (await getLocal()).accounts.find((a) => a.id === d.accountId) ?? null;
}

/** "Chrome on macOS" and the like. */
export function deviceName(): string {
  const p =
    (navigator as Navigator & { userAgentData?: { platform?: string } }).userAgentData?.platform ??
    navigator.platform ??
    "";
  const os = /mac/i.test(p)
    ? "macOS"
    : /win/i.test(p)
      ? "Windows"
      : /cros|chrome os/i.test(p)
        ? "ChromeOS"
        : /linux/i.test(p)
          ? "Linux"
          : "";
  const browser = /Edg\//.test(navigator.userAgent) ? "Edge" : "Chrome";
  return os ? `${browser} on ${os}` : browser;
}

/** Pairs this browser in [orgId] for [botIds]. */
export async function pair(
  account: Account,
  orgId: string,
  botIds: string[],
): Promise<PairedDevice> {
  if ((await getManaged()).ActDisabled)
    throw new Error("Your administrator turned off bots in this browser.");
  const api = clientFor(account);
  const name = deviceName();
  const created = await api.unwrap(
    api.POST("/v1/local-devices", { body: { org_id: orgId, name, platform: "chrome" } }),
  );
  await api.unwrap(
    api.PATCH("/v1/local-devices/{id}", {
      params: { path: { id: created.id } },
      body: { allowed_bot_ids: botIds, capabilities: { browser: true } },
    }),
  );
  const d: PairedDevice = {
    accountId: account.id,
    server: account.server,
    orgId,
    deviceId: created.id,
    token: created.token,
    name,
  };
  await chrome.storage.local.set({ actDevice: d });
  await status({ error: null });
  await connect();
  return d;
}

/** Unpairs: stops all bot work here, removes the device on the server and forgets the token. */
export async function unpair() {
  const d = await pairedDevice();
  await stopAll("unpaired");
  disconnect();
  await chrome.storage.local.remove("actDevice");
  await status({ online: false, error: null });
  if (!d) return;
  const account = await accountOf(d);
  if (account) {
    const api = clientFor(account);
    await api
      .DELETE("/v1/local-devices/{id}", { params: { path: { id: d.deviceId } } })
      .catch(() => {});
  }
}

/** The device as the server sees it (allowed bots, site lists). */
export async function deviceInfo(): Promise<Schemas["LocalDevice"] | null> {
  const d = await pairedDevice();
  const account = d && (await accountOf(d));
  if (!d || !account) return null;
  const api = clientFor(account);
  const r = await api.unwrap(
    api.GET("/v1/local-devices", { params: { query: { org_id: d.orgId } } }),
  );
  return r.items.find((x) => x.id === d.deviceId) ?? null;
}

export async function updateDevice(body: Schemas["UpdateLocalDeviceRequest"]) {
  const d = await pairedDevice();
  const account = d && (await accountOf(d));
  if (!d || !account) throw new Error("This browser isn't paired.");
  const api = clientFor(account);
  return api.unwrap(
    api.PATCH("/v1/local-devices/{id}", { params: { path: { id: d.deviceId } }, body }),
  );
}

function disconnect() {
  clearInterval(keepalive);
  clearTimeout(retry);
  const s = ws;
  ws = null;
  if (s && s.readyState <= WebSocket.OPEN) s.close(1000, "bye");
  for (const a of inflight.values()) a.abort();
  inflight.clear();
}

const b64 = (s: string) => {
  const bytes = new TextEncoder().encode(s);
  let bin = "";
  for (let i = 0; i < bytes.length; i += 0x8000)
    bin += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return btoa(bin);
};
const unb64 = (s: string) =>
  new TextDecoder().decode(Uint8Array.from(atob(s), (c) => c.charCodeAt(0)));

/** Opens the device socket when paired, signed in and allowed; safe to call again. */
export async function connect(): Promise<void> {
  installRunner();
  const d = await pairedDevice();
  if (!d || !(await hasConsent())) return;
  if ((await getManaged()).ActDisabled) {
    await status({ online: false, error: "Your administrator turned off bots in this browser." });
    return;
  }
  if (!(await accountOf(d))) {
    await status({ online: false, error: "Sign in to the account this browser was paired with." });
    return;
  }
  if (ws && ws.readyState <= WebSocket.OPEN) return;
  setRunnerHost({
    async rememberSite(list, host, current) {
      await updateDevice({ [list]: [...new Set([...current, host])] });
    },
    async cancelRun(runId) {
      const account = await accountOf(d);
      if (!account) return;
      const api = clientFor(account);
      await api.POST("/v1/runs/{id}/cancel", { params: { path: { id: runId } } });
    },
  });
  const url = `${d.server.replace(/^http/, "ws").replace(/\/+$/, "")}/v1/local-computer/connect?token=${encodeURIComponent(d.token)}`;
  const s = new WebSocket(url);
  ws = s;
  s.onopen = () => {
    backoff = 1000;
    s.send(
      JSON.stringify({
        type: "hello",
        platform: "chrome",
        version: chrome.runtime.getManifest().version,
      }),
    );
    clearInterval(keepalive);
    keepalive = setInterval(() => {
      if (s.readyState === WebSocket.OPEN)
        s.send(JSON.stringify({ type: "hello", platform: "chrome" }));
    }, KEEPALIVE_MS);
  };
  s.onmessage = (ev) => void onFrame(s, String(ev.data));
  s.onclose = (ev) => {
    if (ws !== s) return;
    ws = null;
    clearInterval(keepalive);
    void status({ online: false });
    // The calls in flight can't answer now; the runs carry on once the browser reconnects (a
    // deploy restarts the server, laptops sleep). Calls fail fast on the server while offline.
    abortInFlight();
    if (ev.code === 4000) return; // Replaced by a newer connection of this device.
    void pairedDevice().then((still) => {
      if (!still) return;
      retry = setTimeout(() => void connect(), backoff);
      backoff = Math.min(backoff * 2, 30_000);
    });
  };
  s.onerror = () => {
    void status({ error: "Can't reach the server for bots right now." });
  };
}

async function onFrame(s: WebSocket, raw: string) {
  let m: { type: string; id?: string; method?: string; path?: string; body?: string };
  try {
    m = JSON.parse(raw);
  } catch {
    return;
  }
  if (m.type === "ready") {
    await status({ online: true, error: null });
    return;
  }
  if (m.type === "cancel" && m.id) {
    inflight.get(m.id)?.abort();
    return;
  }
  if (m.type !== "request" || !m.id) return;
  const id = m.id;
  const reply = (status: number, body: unknown) => {
    if (s.readyState !== WebSocket.OPEN) return;
    s.send(
      JSON.stringify({
        type: "response",
        id,
        status,
        headers: { "content-type": "application/json" },
      }),
    );
    s.send(JSON.stringify({ type: "chunk", id, data: b64(JSON.stringify(body)) }));
    s.send(JSON.stringify({ type: "end", id }));
  };
  if (m.path === "/health") return reply(200, { ok: true });
  const action = /^\/browser\/([a-z_]+)$/.exec(m.path ?? "")?.[1];
  if (!action || m.method !== "POST")
    return reply(404, { ok: false, code: "not_found", message: "Unknown request" });
  let call: Call;
  try {
    call = JSON.parse(m.body ? unb64(m.body) : "{}") as Call;
  } catch {
    return reply(400, { ok: false, code: "bad_call", message: "Unreadable call" });
  }
  const ac = new AbortController();
  inflight.set(id, ac);
  try {
    reply(200, await handleCall(call, ac.signal));
  } finally {
    inflight.delete(id);
  }
}

/** On start-up and every minute: reconnect when the socket is gone. */
export async function ensureConnected() {
  const d = await pairedDevice();
  // Signed out of the paired account, consent withdrawn or turned off by policy: let go.
  if (
    ws &&
    (!d || !(await accountOf(d)) || !(await hasConsent()) || (await getManaged()).ActDisabled)
  ) {
    await stopAll("signed out");
    disconnect();
    await status({ online: false });
  }
  if (!ws || ws.readyState > WebSocket.OPEN) await connect();
}
