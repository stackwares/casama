/**
 * "Your browser" in the service worker (D-323 Phase 3): messages from the panel, the options page
 * and the ask window, the reconnect alarm, and what ends a recording.
 *
 * Only the extension's own pages may send these (not content scripts, which run in web pages).
 */
import { getLocal } from "../../lib/store.ts";
import { type Answer, answer, onAskNotification } from "./ask.ts";
import * as cdp from "./cdp.ts";
import { connect, deviceInfo, ensureConnected, pair, unpair, updateDevice } from "./device.ts";
import { handBack, installRunner, stopByKey } from "./runner.ts";
import { onTeachTabGone, startTeach, stopTeach } from "./teach.ts";

export type ActMessage =
  | { type: "act:answer"; id: string; answer: Answer }
  | { type: "act:pair"; accountId: string; orgId: string; botIds: string[] }
  | { type: "act:unpair" }
  | { type: "act:stop"; key: string }
  | { type: "act:handback"; key: string }
  | { type: "act:teach-start"; tabId: number; botId: string }
  | { type: "act:teach-stop" }
  | { type: "act:device" }
  | { type: "act:update"; body: Record<string, unknown> }
  | { type: "act:connect" };

const fromOwnPage = (sender: chrome.runtime.MessageSender) =>
  sender.id === chrome.runtime.id && !!sender.url?.startsWith(chrome.runtime.getURL(""));

export function onActMessage(
  m: ActMessage,
  sender: chrome.runtime.MessageSender,
  reply: (r: unknown) => void,
): boolean {
  if (!m?.type?.startsWith("act:") || !fromOwnPage(sender)) return false;
  const done = (p: Promise<unknown>) => {
    p.then(
      (r) => reply({ ok: true, result: r ?? null }),
      (e: unknown) => reply({ ok: false, error: (e as Error).message ?? String(e) }),
    );
    return true;
  };
  switch (m.type) {
    case "act:answer":
      reply({ ok: answer(m.id, m.answer) });
      return false;
    case "act:pair":
      return done(
        (async () => {
          const account = (await getLocal()).accounts.find((a) => a.id === m.accountId);
          if (!account) throw new Error("Sign in first.");
          const d = await pair(account, m.orgId, m.botIds);
          return { deviceId: d.deviceId };
        })(),
      );
    case "act:unpair":
      return done(unpair());
    case "act:stop":
      return done(stopByKey(m.key, "panel"));
    case "act:handback":
      handBack(m.key);
      reply({ ok: true });
      return false;
    case "act:teach-start":
      return done(startTeach(m.tabId, m.botId));
    case "act:teach-stop":
      return done(stopTeach());
    case "act:device":
      return done(deviceInfo());
    case "act:update":
      return done(updateDevice(m.body as never));
    case "act:connect":
      return done(ensureConnected());
  }
  return false;
}

/** Wires Act into the service worker; returns whether a notification button was an Act one. */
export function installAct() {
  installRunner();
  cdp.onDetach((tabId) => onTeachTabGone(tabId));
  chrome.tabs.onRemoved.addListener((tabId) => onTeachTabGone(tabId));
  void chrome.alarms.create("act-reconnect", { periodInMinutes: 1 });
  chrome.alarms.onAlarm.addListener((a) => {
    if (a.name === "act-reconnect") void ensureConnected().catch(() => {});
  });
  void connect().catch(() => {});
}

export { onAskNotification };
