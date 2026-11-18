/**
 * Reading the open tab when the person asks (plan §9.3): its address, title, selection, readable
 * text, a PDF's text or a video's transcript, and screenshots. Runs from extension pages and the
 * service worker; Chrome allows it through activeTab or site access. The guard comes first.
 */
import { browserName } from "./browser.ts";
import { type PageContext, TEXT_CAP } from "./context.ts";
import { hasSecretField, pageMarkdown, pickRegion, snapshotPage, youtubeInfo } from "./extract.ts";
import { GUARD_REASON, guardUrl, scriptable } from "./guard.ts";
import { guardAdditions } from "./guard-sites.ts";
import { markdownToHtml } from "./md.ts";
import { fetchPdf, looksLikePdf, pdfText } from "./pdf.ts";
import { getSettings } from "./settings.ts";
import { getLocal } from "./store.ts";
import { isYouTubeVideo, transcriptText } from "./youtube.ts";

/** Chrome said no: the tab needs site access (or a click on the toolbar button) first. */
export class NoAccessError extends Error {
  readonly origin?: string;
  constructor(url?: string) {
    super("Casama needs your permission to read this tab.");
    try {
      this.origin = url ? `${new URL(url).origin}/*` : undefined;
    } catch {
      this.origin = undefined;
    }
  }
}

/**
 * The tab the person is looking at. When the panel itself is open as a tab (where the side panel
 * couldn't open), that's the one they used last before it.
 */
export async function activeTab(): Promise<chrome.tabs.Tab | undefined> {
  const own = chrome.runtime.getURL("");
  const [tab] = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
  if (tab && !tab.url?.startsWith(own)) return tab;
  const latest = (tabs: chrome.tabs.Tab[]) =>
    tabs
      .filter((t) => !t.url?.startsWith(own))
      .sort((a, b) => (b.lastAccessed ?? 0) - (a.lastAccessed ?? 0))[0];
  // The panel may be a window of its own; then the tab used last in any window.
  return (
    latest(await chrome.tabs.query({ lastFocusedWindow: true })) ??
    latest(await chrome.tabs.query({}))
  );
}

/** The signed-in servers' addresses (API and Auth), which count as Casama's own pages. */
async function ownHosts(): Promise<string[]> {
  const out: string[] = [];
  for (const a of (await getLocal()).accounts)
    for (const u of [a.server, a.authUrl])
      try {
        out.push(new URL(u).host);
      } catch {
        // Not an address; nothing to add.
      }
  return out;
}

/** Why the page at [url] can't be read or sent (G2), or null when it can. */
export async function blockedReason(url: string | undefined): Promise<string | null> {
  const s = await getSettings();
  const kind = guardUrl(url, {
    neverList: s.neverList,
    ownHosts: await ownHosts(),
    extraHosts: await guardAdditions(),
  });
  return kind ? GUARD_REASON[kind] : null;
}
const guarded = blockedReason;

const SECRET = "This page has a password or card field, so it isn't sent.";

/** Refuses a page showing a password or card field, before a screenshot or a save. */
async function refuseSecretFields(tab: chrome.tabs.Tab) {
  if (!tab.id || !scriptable(tab.url)) return;
  if (await run(tab.id, tab.url, hasSecretField)) throw new Error(SECRET);
}

async function run<T>(
  tabId: number,
  url: string | undefined,
  func: () => T | Promise<T>,
  world?: "MAIN",
): Promise<T>;
async function run<T, A extends unknown[]>(
  tabId: number,
  url: string | undefined,
  func: (...a: A) => T | Promise<T>,
  world: "MAIN" | undefined,
  args: A,
): Promise<T>;
async function run(
  tabId: number,
  url: string | undefined,
  func: (...a: unknown[]) => unknown,
  world?: "MAIN",
  args: unknown[] = [],
) {
  try {
    const [r] = await chrome.scripting.executeScript({
      target: { tabId },
      func,
      args,
      ...(world ? { world: "MAIN" as chrome.scripting.ExecutionWorld } : {}),
    });
    return r?.result;
  } catch (e) {
    const m = (e as Error).message ?? "";
    if (/permission|Cannot access|host/i.test(m)) throw new NoAccessError(url);
    throw e;
  }
}

/** What the tab offers as context. Text is read now; whether it's sent is up to the chips. */
export async function readTab(tab: chrome.tabs.Tab | undefined): Promise<PageContext> {
  if (!tab?.id) return {};
  const blocked = await guarded(tab.url);
  if (blocked) return { url: tab.url, title: tab.title, blocked };
  if (looksLikePdf(tab.url) && tab.url && !/^chrome-extension:/.test(tab.url)) {
    try {
      const data = await fetchPdf(tab.url);
      const pdf = await pdfText(data, TEXT_CAP);
      return { url: tab.url, title: pdf.title || tab.title, text: pdf.text, textKind: "pdf" };
    } catch (e) {
      if (/Failed to fetch|NetworkError/i.test((e as Error).message))
        throw new NoAccessError(tab.url);
      throw e;
    }
  }
  if (!scriptable(tab.url))
    return {
      url: tab.url,
      title: tab.title,
      blocked: `${browserName()} doesn't let extensions read this page.`,
    };
  const snap = await run(tab.id, tab.url, snapshotPage, undefined, [TEXT_CAP * 2]);
  if (!snap) return { url: tab.url, title: tab.title };
  // The address may have changed since Chrome told us (a redirect); check it again.
  const late = await guarded(snap.url);
  if (late) return { url: snap.url, title: snap.title, blocked: late };
  if (snap.secretField) return { url: snap.url, title: snap.title, blocked: SECRET };
  const ctx: PageContext = {
    url: snap.url,
    title: snap.title,
    selection: snap.selection,
    text: snap.text,
    textKind: "page",
  };
  if (isYouTubeVideo(snap.url)) {
    const yt = await run(tab.id, tab.url, youtubeInfo, "MAIN").catch(() => null);
    if (yt?.events?.length) {
      ctx.text = transcriptText(yt.events);
      ctx.textKind = "transcript";
      ctx.title = yt.title || ctx.title;
      ctx.videoTime = yt.time;
    }
  }
  return ctx;
}

/** The page's main content as Markdown, for saving. */
export async function tabMarkdown(tab: chrome.tabs.Tab) {
  const blocked = await guarded(tab.url);
  if (blocked) throw new Error(blocked);
  if (!tab.id || !scriptable(tab.url))
    throw new Error(`${browserName()} doesn't let extensions read this page.`);
  await refuseSecretFields(tab);
  return run(tab.id, tab.url, pageMarkdown, undefined, [500_000]);
}

/** The page as HTML with its styles inlined as far as the page allows, for Save as PDF. */
export async function tabHtml(tab: chrome.tabs.Tab): Promise<string> {
  const md = await tabMarkdown(tab);
  const esc = (s: string) =>
    s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]!);
  // A clean, readable copy rather than the live page: no scripts, no trackers, prints well.
  return `<!doctype html><html><head><meta charset="utf-8"><title>${esc(md.title)}</title><style>body{font:12pt/1.5 Georgia,serif;max-width:46em;margin:2em auto;color:#111}h1,h2,h3{font-family:system-ui,sans-serif}img{max-width:100%}pre{white-space:pre-wrap;background:#f4f4f4;padding:8px}a{color:#1a5fd0}.src{font:9pt system-ui;color:#555;margin-bottom:2em}</style></head><body><div class="src">${esc(md.url)}</div><h1>${esc(md.title)}</h1>${markdownToHtml(md.markdown)}</body></html>`;
}

/** What's visible in the tab as a PNG. */
export async function screenshot(tab: chrome.tabs.Tab): Promise<Blob> {
  const blocked = await guarded(tab.url);
  if (blocked) throw new Error(blocked);
  await refuseSecretFields(tab);
  let dataUrl: string;
  try {
    dataUrl = await chrome.tabs.captureVisibleTab(tab.windowId, { format: "png" });
  } catch (e) {
    if (/permission|activeTab|<all_urls>/i.test((e as Error).message ?? ""))
      throw new NoAccessError(tab.url);
    throw e;
  }
  return (await fetch(dataUrl)).blob();
}

/** A4: the person drags a box over the page; the screenshot is cut to it. Null when cancelled. */
export async function regionScreenshot(tab: chrome.tabs.Tab): Promise<Blob | null> {
  if (!tab.id) return null;
  const blocked = await guarded(tab.url);
  if (blocked) throw new Error(blocked);
  await chrome.tabs.update(tab.id, { active: true });
  const rect = await run(tab.id, tab.url, pickRegion);
  if (!rect) return null;
  // Let the page repaint without the picker before the screenshot.
  await new Promise((r) => setTimeout(r, 120));
  const full = await screenshot(tab);
  return crop(full, rect);
}

export async function crop(
  png: Blob,
  r: { x: number; y: number; w: number; h: number; dpr: number },
) {
  const bitmap = await createImageBitmap(png);
  const sx = Math.round(r.x * r.dpr);
  const sy = Math.round(r.y * r.dpr);
  const sw = Math.min(bitmap.width - sx, Math.round(r.w * r.dpr));
  const sh = Math.min(bitmap.height - sy, Math.round(r.h * r.dpr));
  const canvas = new OffscreenCanvas(Math.max(1, sw), Math.max(1, sh));
  canvas.getContext("2d")!.drawImage(bitmap, sx, sy, sw, sh, 0, 0, sw, sh);
  bitmap.close();
  return canvas.convertToBlob({ type: "image/png" });
}
