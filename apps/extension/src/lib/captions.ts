/**
 * Meeting notes from captions (D-323 E7, decision 7): on a Google Meet call, the person starts it
 * from the panel, a banner shows on the page for as long as it runs, and Meet's own captions are
 * collected as a transcript. When they stop, the transcript goes to a bot for notes. No audio is
 * recorded and nothing is sent until they stop.
 *
 * Off by default, behind the server's `chrome_meeting_captions` flag and the person's own switch.
 * The page functions below are injected with chrome.scripting.executeScript and run in the
 * extension's isolated world, where their state lasts as long as the page.
 */

export interface CaptionLine {
  speaker: string;
  text: string;
  at: number;
}

export const MEET = /^https:\/\/meet\.google\.com\/[a-z]{3}-[a-z]{4}-[a-z]{3}(?:[/?#]|$)/;

/** Whether [url] is a Google Meet call. */
export const isMeetCall = (url: string | undefined) => !!url && MEET.test(url);

/** The words to tell the others, for the Meet chat. */
export const NOTICE =
  "Heads up: I'm taking notes of this call from the captions with Casama. Tell me if you'd rather I didn't.";

/** One transcript from the lines: a speaker's lines run together, with the time they started. */
export function transcript(lines: CaptionLine[], title?: string): string {
  const out: string[] = [];
  let last = "";
  for (const l of lines) {
    const text = l.text.trim();
    if (!text) continue;
    if (l.speaker === last && out.length) out[out.length - 1] += ` ${text}`;
    else {
      const t = new Date(l.at);
      const hh = String(t.getHours()).padStart(2, "0");
      const mm = String(t.getMinutes()).padStart(2, "0");
      out.push(`[${hh}:${mm}] ${l.speaker || "Someone"}: ${text}`);
      last = l.speaker;
    }
  }
  return `${title ? `Meeting: ${title}\n\n` : ""}${out.join("\n")}`;
}

export type CaptionsState = { running: boolean; lines: number; found: boolean };

/**
 * Injected: starts collecting captions and shows the banner. Returns whether Meet's caption area
 * was found (captions have to be on in Meet).
 */
export function startCaptions(bannerText: string): CaptionsState {
  type Line = { speaker: string; text: string; at: number };
  type W = typeof globalThis & {
    __casamaCaptions?: {
      lines: Line[];
      seen: WeakMap<Element, number>;
      obs: MutationObserver;
      banner: HTMLElement;
    };
  };
  const w = globalThis as W;
  const region = () =>
    document.querySelector('[role="region"][aria-label*="aption" i]') ??
    document.querySelector('[jsname="dsyhDe"]');
  if (w.__casamaCaptions)
    return { running: true, lines: w.__casamaCaptions.lines.length, found: !!region() };
  const lines: Line[] = [];
  const seen = new WeakMap<Element, number>();
  const read = () => {
    const r = region();
    if (!r) return;
    // Each block: the speaker's name, then the words Meet keeps rewriting as it hears more.
    for (const block of Array.from(r.children)) {
      const name =
        (
          block.querySelector(
            '[class*="name" i], img[alt] + div, [data-self-name]',
          ) as HTMLElement | null
        )?.innerText ?? "";
      const words = (block as HTMLElement).innerText.replace(name, "").trim();
      if (!words) continue;
      const i = seen.get(block);
      if (i === undefined) {
        seen.set(block, lines.length);
        lines.push({ speaker: name.trim(), text: words, at: Date.now() });
      } else if (lines[i]) lines[i].text = words;
    }
  };
  const obs = new MutationObserver(read);
  obs.observe(document.body, { childList: true, subtree: true, characterData: true });
  const host = document.createElement("div");
  host.setAttribute("data-casama-captions", "");
  const root = host.attachShadow({ mode: "closed" });
  root.innerHTML = `<style>
    div{position:fixed;left:50%;top:8px;transform:translateX(-50%);z-index:2147483647;background:#b3261e;color:#fff;font:600 13px system-ui,sans-serif;padding:8px 14px;border-radius:999px;box-shadow:0 2px 8px rgba(0,0,0,.3);pointer-events:none}
  </style><div role="status"></div>`;
  (root.querySelector("div") as HTMLElement).textContent = bannerText;
  document.documentElement.append(host);
  w.__casamaCaptions = { lines, seen, obs, banner: host };
  read();
  return { running: true, lines: lines.length, found: !!region() };
}

/** Injected: whether it's running, and how many lines so far. */
export function captionsState(): CaptionsState {
  const c = (globalThis as typeof globalThis & { __casamaCaptions?: { lines: unknown[] } })
    .__casamaCaptions;
  const found = !!(
    document.querySelector('[role="region"][aria-label*="aption" i]') ??
    document.querySelector('[jsname="dsyhDe"]')
  );
  return { running: !!c, lines: c?.lines.length ?? 0, found };
}

/** Injected: stops, removes the banner and hands back the lines and the call's title. */
export function stopCaptions(): { lines: CaptionLine[]; title: string } {
  type W = typeof globalThis & {
    __casamaCaptions?: { lines: CaptionLine[]; obs: MutationObserver; banner: HTMLElement };
  };
  const w = globalThis as W;
  const c = w.__casamaCaptions;
  delete w.__casamaCaptions;
  if (!c) return { lines: [], title: document.title };
  c.obs.disconnect();
  c.banner.remove();
  return { lines: c.lines, title: document.title.replace(/^Meet\s*[-–]\s*/, "") };
}
