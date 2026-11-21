/**
 * Talking to the agent in a child frame. The parent hands the child one end of a MessageChannel
 * (`iframe.contentWindow.postMessage`); the child takes it only from its direct parent, with the
 * secret native gave this page when there is one, and hides the message from the page's own
 * listeners. Requests and answers are JSON strings on that port.
 */
import {
  addListener,
  channelPort1,
  channelPort2,
  frameContentWindow,
  iframeContentWindow,
  jsonParse,
  jsonStringify,
  localName,
  MessageChannelCtor,
  messageData,
  PromiseCtor,
  portClose,
  portPostMessage,
  portStart,
  record,
  setTimeoutFn,
  WeakMapCtor,
  weakMapGet,
  weakMapSet,
  winPostMessage,
} from "./prims.ts";

export type Answer = Record<string, unknown> & { ok: boolean };

export interface FrameLink {
  port: MessagePort;
  pending: Record<string, (a: Answer | null) => void>;
  seq: number;
}

/** The marker on connect messages. */
export const CONNECT = "__casamaPageAgent";

let secret = "";
export function setSecret(s: string): void {
  secret = s;
}
export function getSecret(): string {
  return secret;
}

const links = new WeakMapCtor<Element, FrameLink>();

function contentWindowOf(el: Element): Window | null {
  try {
    return localName(el) === "frame" ? frameContentWindow(el) : iframeContentWindow(el);
  } catch {
    return null;
  }
}

/** Sends one request to a child frame; null when it doesn't answer in [timeout] ms. */
export function request(
  link: FrameLink,
  cmd: string,
  args: Record<string, unknown>,
  timeout: number,
): Promise<Answer | null> {
  link.seq += 1;
  const id = `f${link.seq}`;
  return new PromiseCtor<Answer | null>((resolve) => {
    link.pending[id] = resolve;
    setTimeoutFn(() => {
      if (link.pending[id]) {
        delete link.pending[id];
        resolve(null);
      }
    }, timeout);
    try {
      portPostMessage(link.port, jsonStringify({ id, cmd, args }));
    } catch {
      delete link.pending[id];
      resolve(null);
    }
  });
}

/** A fresh link to the agent in [frameEl]; null when nothing answers within [timeout] ms. */
export async function connect(frameEl: Element, timeout: number): Promise<FrameLink | null> {
  const win = contentWindowOf(frameEl);
  if (!win || !MessageChannelCtor) return null;
  const ch = new MessageChannelCtor();
  const port = channelPort1(ch);
  const link: FrameLink = { port, pending: record(), seq: 0 };
  addListener(port, "message", (e) => {
    let a: Answer | null = null;
    try {
      const d = messageData(e);
      a = typeof d === "string" ? (jsonParse(d) as Answer) : null;
    } catch {}
    if (!a || typeof a.id !== "string") return;
    const done = link.pending[a.id];
    if (!done) return;
    delete link.pending[a.id];
    done(a);
  });
  portStart(port);
  try {
    winPostMessage(win, { [CONNECT]: "connect", secret }, "*", [channelPort2(ch)]);
  } catch {
    return null;
  }
  const hello = await request(link, "ping", {}, timeout);
  if (!hello?.ok) {
    portClose(port);
    return null;
  }
  weakMapSet(links, frameEl, link);
  return link;
}

/** The last link to [frameEl], or a new one. */
export async function linkFor(frameEl: Element, timeout: number): Promise<FrameLink | null> {
  const known = weakMapGet<FrameLink | undefined>(links, frameEl);
  if (known) {
    const ok = await request(known, "ping", {}, timeout);
    if (ok?.ok) return known;
  }
  return connect(frameEl, timeout);
}
