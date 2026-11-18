/**
 * This page before (A20) and highlights (B7): a small index in this browser of the pages the person
 * chatted about or highlighted, by page key. The panel shows "This page before" from it without
 * asking the server; the server is asked only when the person opens the list. Highlights are
 * painted only on pages in it.
 */
import { withLock } from "./store.ts";

/** Same rule as the server's pageKey (packages/contracts/src/browser.ts). */
export function pageKey(url: string): string {
  try {
    const u = new URL(url);
    u.hash = "";
    for (const k of [...u.searchParams.keys()])
      if (/^(utm_|fbclid$|gclid$|mc_|ref$|ref_src$|igshid$|si$)/i.test(k)) u.searchParams.delete(k);
    u.hostname = u.hostname.toLowerCase();
    if (u.pathname.length > 1 && u.pathname.endsWith("/")) u.pathname = u.pathname.slice(0, -1);
    const s = u.toString();
    return s.endsWith("/") ? s.slice(0, -1) : s;
  } catch {
    return url;
  }
}

export interface IndexedHighlight {
  id: string;
  text: string;
  prefix: string;
  suffix: string;
  at: number;
}

export interface PageEntry {
  /** Conversations started from this page, newest first. */
  convs: { id: string; botId: string; title: string; at: number }[];
  highlights: IndexedHighlight[];
  /** Which account and workspace the entry belongs to. */
  owner: string;
  at: number;
}

const KEEP = 500;
type Index = Record<string, PageEntry>;

async function read(): Promise<Index> {
  return ((await chrome.storage.local.get("pageIndex")).pageIndex as Index | undefined) ?? {};
}

export async function pageEntry(url: string | undefined, owner: string): Promise<PageEntry | null> {
  if (!url || !/^https?:/.test(url)) return null;
  const e = (await read())[pageKey(url)];
  return e && e.owner === owner ? e : null;
}

function update(url: string, owner: string, fn: (e: PageEntry) => void) {
  return withLock("pageIndex", async () => {
    const all = await read();
    const key = pageKey(url);
    const e: PageEntry =
      all[key]?.owner === owner ? all[key] : { convs: [], highlights: [], owner, at: 0 };
    fn(e);
    e.at = Date.now();
    if (!e.convs.length && !e.highlights.length) delete all[key];
    else all[key] = e;
    const kept = Object.entries(all)
      .sort((a, b) => b[1].at - a[1].at)
      .slice(0, KEEP);
    await chrome.storage.local.set({ pageIndex: Object.fromEntries(kept) });
  });
}

export const noteConversation = (
  url: string,
  owner: string,
  c: { id: string; botId: string; title: string },
) =>
  update(url, owner, (e) => {
    e.convs = [{ ...c, at: Date.now() }, ...e.convs.filter((x) => x.id !== c.id)].slice(0, 20);
  });

export const noteHighlight = (url: string, owner: string, hl: Omit<IndexedHighlight, "at">) =>
  update(url, owner, (e) => {
    e.highlights = [...e.highlights.filter((x) => x.id !== hl.id), { ...hl, at: Date.now() }].slice(
      -200,
    );
  });

export const forgetHighlight = (url: string, owner: string, id: string) =>
  update(url, owner, (e) => {
    e.highlights = e.highlights.filter((x) => x.id !== id);
  });
