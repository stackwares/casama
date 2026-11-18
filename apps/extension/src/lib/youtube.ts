/** YouTube transcripts (A6): caption events into "[m:ss] text" lines. */
import { clock } from "./context.ts";
import type { YouTubeInfo } from "./extract.ts";

export function isYouTubeVideo(url: string | undefined): boolean {
  if (!url) return false;
  try {
    const u = new URL(url);
    return (
      /(^|\.)youtube\.com$/.test(u.hostname) &&
      (u.pathname === "/watch" ||
        u.pathname.startsWith("/shorts/") ||
        u.pathname.startsWith("/live/"))
    );
  } catch {
    return false;
  }
}

/** One line per caption event, merged into lines of roughly a sentence or 15 seconds. */
export function transcriptText(events: NonNullable<YouTubeInfo["events"]>): string {
  const lines: string[] = [];
  let current = "";
  let at = -1;
  const flush = () => {
    if (current.trim()) lines.push(`[${clock(at / 1000)}] ${current.trim()}`);
    current = "";
    at = -1;
  };
  for (const e of events) {
    const text = (e.segs ?? [])
      .map((s) => s.utf8 ?? "")
      .join("")
      .replace(/\s+/g, " ");
    if (!text.trim()) continue;
    const start = e.tStartMs ?? 0;
    if (at < 0) at = start;
    current += `${current ? " " : ""}${text.trim()}`;
    if (/[.!?]$/.test(current.trim()) || start - at > 15_000) flush();
  }
  flush();
  return lines.join("\n");
}
