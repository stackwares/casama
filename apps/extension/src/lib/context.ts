/**
 * Context that goes with a message (plan §9.3): the D-152 block quick ask already sends
 * ("Browser tab: …", "Selected text: …"), extended with page text, a video's transcript and a
 * PDF's text. Each part is a chip the person can switch off; screenshots go as attachments.
 */

/** A selection is cut at 8,000 characters, as in quick ask. */
export const SELECTION_CAP = 8_000;
/** Page text, transcripts and PDFs have their own, larger cap; the chip shows the size. */
export const TEXT_CAP = 60_000;

export interface PageContext {
  url?: string;
  title?: string;
  selection?: string;
  /** Readable text of the page (or the PDF, or the transcript). */
  text?: string;
  textKind?: "page" | "pdf" | "transcript";
  /** Seconds into a video, for "ask at the current moment". */
  videoTime?: number;
  /** Why the page couldn't be read, when it couldn't. */
  blocked?: string;
}

export type ChipKey = "page" | "selection" | "text" | "screenshot";

const cut = (s: string, n: number) => (s.length > n ? `${s.slice(0, n)}…` : s);

export function clock(seconds: number): string {
  const s = Math.max(0, Math.floor(seconds));
  const hh = Math.floor(s / 3600);
  const mm = Math.floor((s % 3600) / 60);
  const ss = String(s % 60).padStart(2, "0");
  return hh ? `${hh}:${String(mm).padStart(2, "0")}:${ss}` : `${mm}:${ss}`;
}

const TEXT_LABEL = { page: "Page text", pdf: "PDF text", transcript: "Video transcript" } as const;

/** The block that goes after the person's text, with only the chips that are on. */
export function contextBlock(ctx: PageContext, on: Partial<Record<ChipKey, boolean>>): string {
  // A blocked page (G2) sends nothing at all, not even its address.
  if (ctx.blocked) return "";
  const parts: string[] = [];
  if (on.page && ctx.url)
    parts.push(`Browser tab: ${ctx.title ? `${ctx.title} ` : ""}(${ctx.url})`);
  if (on.page && ctx.videoTime !== undefined && ctx.textKind === "transcript")
    parts.push(`Video position: ${clock(ctx.videoTime)}`);
  if (on.selection && ctx.selection?.trim())
    parts.push(`Selected text:\n${cut(ctx.selection.trim(), SELECTION_CAP)}`);
  if (on.text && ctx.text?.trim())
    parts.push(`${TEXT_LABEL[ctx.textKind ?? "page"]}:\n${cut(ctx.text.trim(), TEXT_CAP)}`);
  return parts.join("\n\n");
}

/** The message text: what they typed, then the context. */
export function messageText(
  typed: string,
  ctx: PageContext,
  on: Partial<Record<ChipKey, boolean>>,
) {
  const block = contextBlock(ctx, on);
  return [typed.trim(), block].filter(Boolean).join("\n\n");
}

/** A short record of what went with a message, for "What was sent" (G4). */
export interface SentRecord {
  at: number;
  url?: string;
  title?: string;
  parts: string[];
  chars: number;
  runId?: string;
  botId?: string;
  /** How much of the message's text the person typed; the rest is the context block. */
  typedChars?: number;
}

export function sentRecord(
  ctx: PageContext,
  on: Partial<Record<ChipKey, boolean>>,
  text: string,
  attachments: string[],
): SentRecord {
  const parts: string[] = [];
  const page = !ctx.blocked;
  if (page && on.page && ctx.url) parts.push("Page address and title");
  if (page && on.selection && ctx.selection?.trim()) parts.push("Selected text");
  if (page && on.text && ctx.text?.trim()) parts.push(TEXT_LABEL[ctx.textKind ?? "page"]);
  for (const a of attachments) parts.push(a);
  return {
    at: Date.now(),
    url: page && on.page ? ctx.url : undefined,
    title: page && on.page ? ctx.title : undefined,
    parts,
    chars: text.length,
  };
}
