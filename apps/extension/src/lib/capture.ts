/**
 * Capture (plan §6 B1–B5): Save to Library, Remember this, Add to knowledge, Make a task. When the
 * server can't be reached, the capture waits in an offline queue and is sent later (B5); errors the
 * server gives (no permission, a full Library) are shown, not queued.
 */
import { CasamaError } from "@casama/client";
import { accessToken, clientFor, UnreachableError } from "./session.ts";
import { type Account, getLocal, withLock } from "./store.ts";

export type Capture =
  | {
      kind: "library";
      orgId: string;
      name: string;
      /** Base64 of the bytes. */
      data: string;
      type: string;
      convert?: "pdf";
      projectId?: string;
    }
  | { kind: "fact"; text: string }
  | {
      kind: "knowledge";
      orgId: string;
      botId?: string;
      url: string;
      name: string;
      site: boolean;
    }
  | { kind: "task"; orgId: string; title: string; details: string; botId?: string };

export interface Queued {
  id: string;
  accountId: string;
  capture: Capture;
  tries: number;
  nextAt: number;
  addedAt: number;
  lastError?: string;
}

/** The queue holds at most this many, and this many bytes, so it can't fill the disk. */
export const QUEUE_MAX = 25;
export const QUEUE_MAX_BYTES = 25 * 1024 * 1024;

export function toBase64(bytes: Uint8Array): string {
  let s = "";
  for (let i = 0; i < bytes.length; i += 0x8000)
    s += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return btoa(s);
}
export function fromBase64(b64: string): Uint8Array {
  const s = atob(b64);
  const out = new Uint8Array(s.length);
  for (let i = 0; i < s.length; i++) out[i] = s.charCodeAt(i);
  return out;
}

/** A network failure (worth retrying) rather than a refusal. */
export function isOffline(e: unknown): boolean {
  if (e instanceof UnreachableError) return true;
  if (e instanceof CasamaError) return e.status >= 500 || e.status === 429;
  return e instanceof TypeError || (e as Error)?.name === "TimeoutError";
}

export interface UploadResult {
  id: string;
  path: string;
  name: string;
  mime_type: string;
  size: number;
  creation_id: string | null;
}

/** POST /v1/media: an attachment (media:<id>) or a Library item. */
export async function uploadMedia(
  account: Account,
  q: {
    orgId: string;
    name: string;
    purpose: "attachment" | "library";
    convert?: "pdf";
    projectId?: string;
  },
  body: Blob | Uint8Array,
  type: string,
): Promise<UploadResult> {
  const token = await accessToken(account.id);
  if (!token) throw new Error("You're signed out. Sign in again in Settings.");
  const url = new URL(`${account.server}/v1/media`);
  url.searchParams.set("org_id", q.orgId);
  url.searchParams.set("name", q.name.slice(0, 200));
  url.searchParams.set("purpose", q.purpose);
  if (q.convert) url.searchParams.set("convert", q.convert);
  if (q.projectId) url.searchParams.set("project_id", q.projectId);
  let res: Response;
  try {
    res = await fetch(url, {
      method: "POST",
      headers: { authorization: `Bearer ${token}`, "content-type": type },
      body: body instanceof Blob ? body : new Blob([body as BlobPart], { type }),
      signal: AbortSignal.timeout(120_000),
    });
  } catch (e) {
    if ((e as Error).name === "AbortError") throw e;
    throw new UnreachableError(account.server);
  }
  if (!res.ok) throw await CasamaError.fromResponse(res, await res.json().catch(() => undefined));
  return (await res.json()) as UploadResult;
}

/** Sends one capture now. */
export async function send(account: Account, c: Capture): Promise<string> {
  const api = clientFor(account);
  const T = () => AbortSignal.timeout(30_000);
  switch (c.kind) {
    case "library": {
      const r = await uploadMedia(
        account,
        {
          orgId: c.orgId,
          name: c.name,
          purpose: "library",
          convert: c.convert,
          projectId: c.projectId,
        },
        fromBase64(c.data),
        c.type,
      );
      return r.creation_id ?? r.id;
    }
    case "fact": {
      const r = await api.unwrap(
        api.POST("/v1/me/facts", {
          body: { items: [{ kind: "fact", content: c.text.slice(0, 500) }] },
          signal: T(),
        }),
      );
      return (r.items[0] as { id?: string } | undefined)?.id ?? "";
    }
    case "knowledge": {
      const r = await api.unwrap(
        api.POST("/v1/knowledge-sources", {
          body: {
            org_id: c.orgId,
            ...(c.botId ? { bot_id: c.botId } : {}),
            kind: "website",
            name: c.name.slice(0, 120),
            url: c.url,
            max_pages: c.site ? 50 : 1,
          } as never,
          signal: T(),
        }),
      );
      return r.id;
    }
    case "task": {
      const r = await api.unwrap(
        api.POST("/v1/tasks", {
          body: {
            org_id: c.orgId,
            title: c.title.slice(0, 200),
            details_md: c.details,
            ...(c.botId ? { assignee_bot_id: c.botId } : {}),
          } as never,
          signal: T(),
        }),
      );
      return r.id;
    }
  }
}

async function readQueue(): Promise<Queued[]> {
  return ((await chrome.storage.local.get("queue")).queue as Queued[] | undefined) ?? [];
}
function writeQueue(q: Queued[]) {
  return chrome.storage.local.set({ queue: q });
}
const sizeOf = (q: Queued) => (q.capture.kind === "library" ? q.capture.data.length : 200);

export async function queued(): Promise<Queued[]> {
  return readQueue();
}

/** Keeps a capture for later. Throws when the queue is full. */
export async function enqueue(accountId: string, capture: Capture): Promise<Queued> {
  return withLock("queue", async () => {
    const q = await readQueue();
    const item: Queued = {
      id: crypto.randomUUID(),
      accountId,
      capture,
      tries: 0,
      nextAt: Date.now() + 30_000,
      addedAt: Date.now(),
    };
    if (
      q.length >= QUEUE_MAX ||
      q.reduce((n, x) => n + sizeOf(x), 0) + sizeOf(item) > QUEUE_MAX_BYTES
    )
      throw new Error("Too many captures are waiting to be sent. Connect to the internet first.");
    q.push(item);
    await writeQueue(q);
    return item;
  });
}

/**
 * Sends a capture now, or queues it when offline. Returns "sent" with the new id, or "queued".
 */
export async function capture(
  account: Account,
  c: Capture,
): Promise<{ state: "sent"; id: string } | { state: "queued" }> {
  try {
    return { state: "sent", id: await send(account, c) };
  } catch (e) {
    if (!isOffline(e)) throw e;
    await enqueue(account.id, c);
    return { state: "queued" };
  }
}

/** Tries what's due in the queue (an alarm calls it every few minutes, and when back online). */
export async function flushQueue(now = Date.now()): Promise<{ sent: number; left: number }> {
  return withLock("queue-flush", async () => {
    const q = await readQueue();
    const accounts = (await getLocal()).accounts;
    let sent = 0;
    const keep: Queued[] = [];
    for (const item of q) {
      const account = accounts.find((a) => a.id === item.accountId);
      // Signed out of that account: nothing can be sent for it any more.
      if (!account) continue;
      if (item.nextAt > now) {
        keep.push(item);
        continue;
      }
      try {
        await send(account, item.capture);
        sent++;
      } catch (e) {
        // Refused for good (a deleted bot, a full Library) after a few tries: drop it.
        if (!isOffline(e) && item.tries >= 2) continue;
        keep.push({
          ...item,
          tries: item.tries + 1,
          nextAt: now + Math.min(60 * 60_000, 60_000 * 2 ** item.tries),
          lastError: (e as Error).message,
        });
      }
    }
    await withLock("queue", async () => {
      // Keep anything added while this ran.
      const latest = await readQueue();
      const before = new Set(q.map((x) => x.id));
      await writeQueue([...keep, ...latest.filter((x) => !before.has(x.id))]);
    });
    return { sent, left: keep.length };
  });
}
