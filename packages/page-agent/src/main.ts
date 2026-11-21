/**
 * The page agent's entry point (docs/PHONE-BROWSER-PLAN.md §8.3). Built to one IIFE,
 * `client/assets/app_browser/page_agent.js`, that the phone app runs in an isolated script world of
 * every frame at document start. It defines one global, `__casamaPageAgent`, and when native gave
 * it a `casamaNative` port (Android's web message listener) it answers commands there too.
 */
import { clearRefs, handle, plain, setDownloadCap } from "./agent.ts";
import { CONNECT, getSecret, setSecret } from "./frames.ts";
import {
  addListener,
  defineProp,
  freeze,
  getOwnDesc,
  IS_TOP,
  jsonParse,
  jsonStringify,
  LOCATION,
  locHref,
  messageData,
  messagePorts,
  messageSource,
  PARENT,
  portPostMessage,
  portStart,
  stopImmediate,
  WIN,
} from "./prims.ts";

const VERSION = "1";
const reflectApply = Reflect.apply;

/** Reads (and removes) a global native set up before this script, so page scripts can't reach it. */
function takeGlobal(name: string): unknown {
  const d = getOwnDesc(WIN, name);
  if (!d) return undefined;
  const v = "value" in d ? d.value : undefined;
  try {
    delete (WIN as unknown as Record<string, unknown>)[name];
  } catch {}
  return v;
}

function install(): void {
  if (getOwnDesc(WIN, "__casamaPageAgent")) return;

  const config = takeGlobal("__casamaPageAgentConfig") as Record<string, unknown> | undefined;
  if (config && typeof config === "object") {
    const s = getOwnDesc(config, "secret")?.value;
    if (typeof s === "string") setSecret(s);
    const cap = getOwnDesc(config, "downloadCap")?.value;
    if (typeof cap === "number" && cap > 0) setDownloadCap(cap);
  }

  const run = async (command: unknown) => plain(await handle(command));
  defineProp(WIN, "__casamaPageAgent", {
    value: freeze({ handle: run, version: VERSION }),
    writable: false,
    configurable: false,
    enumerable: false,
  });

  // Refs die with the page (and with a back-forward cache restore).
  addListener(WIN, "pagehide", () => clearRefs(), true);

  // The parent frame's agent asking for this frame's part. Registered before any page script, so
  // it runs first and the page's own listeners never see these messages.
  addListener(
    WIN,
    "message",
    (e) => {
      const d = messageData(e);
      if (!d || typeof d !== "object") return;
      const marker = getOwnDesc(d, CONNECT)?.value;
      if (marker !== "connect") return;
      stopImmediate(e);
      if (IS_TOP || messageSource(e) !== PARENT) return;
      const secret = getSecret();
      if (secret && getOwnDesc(d, "secret")?.value !== secret) return;
      const port = messagePorts(e)[0];
      if (!port) return;
      addListener(port, "message", (m) => {
        const data = messageData(m);
        if (typeof data !== "string") return;
        void (async () => {
          const answer = await handle(data);
          try {
            portPostMessage(port, jsonStringify(answer));
          } catch {}
        })();
      });
      portStart(port);
    },
    true,
  );

  // Android: the native web message listener's object, in this world.
  const native = takeGlobal("casamaNative") as Record<string, unknown> | undefined;
  if (native && typeof native === "object") {
    const post = native.postMessage;
    if (typeof post !== "function") return;
    const send = (v: unknown) => {
      try {
        reflectApply(post, native, [jsonStringify(v)]);
      } catch {}
    };
    const onCommand = (e: unknown) => {
      const data = e && typeof e === "object" ? (e as { data?: unknown }).data : undefined;
      if (typeof data !== "string") return;
      let parsed: unknown;
      try {
        parsed = jsonParse(data);
      } catch {
        send({ id: null, ok: false, code: "error", message: "The command isn't valid JSON." });
        return;
      }
      void (async () => send(await handle(parsed)))();
    };
    const add = native.addEventListener;
    if (typeof add === "function") reflectApply(add, native, ["message", onCommand]);
    else native.onmessage = onCommand;
    send({ hello: true, frame: IS_TOP ? "top" : "child", href: locHref(LOCATION) });
  }
}

try {
  install();
} catch {
  // A page the script can't start in is left alone; native sees no agent and says so.
}
