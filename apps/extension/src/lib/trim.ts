/**
 * Send less (F2): a long page is cut down on this computer to the parts that matter to the question
 * before it's sent, which saves credits. Plain word overlap, no model: paragraphs that share words
 * with the question (and the page's opening) are kept, in page order, up to a budget.
 */

/** Pages shorter than this go whole. */
export const TRIM_FROM = 12_000;
/** What a trimmed page is cut to. */
export const TRIM_TO = 8_000;

const STOP = new Set(
  "a an and are as at be but by can do for from has have how i in is it its me my not of on or so that the this to was what when where which who why will with you your about does did".split(
    " ",
  ),
);
const words = (s: string) =>
  (s.toLowerCase().match(/[\p{L}\p{N}]{3,}/gu) ?? []).filter((w) => !STOP.has(w));

export interface Trimmed {
  text: string;
  /** Characters before trimming. */
  from: number;
  trimmed: boolean;
}

export function sendLess(text: string, question: string, budget = TRIM_TO): Trimmed {
  if (text.length <= Math.max(budget, TRIM_FROM))
    return { text, from: text.length, trimmed: false };
  const paras = text
    .split(/\n{2,}|\n(?=[-*#\d])/)
    .map((p) => p.trim())
    .filter(Boolean);
  const q = new Set(words(question));
  const scored = paras.map((p, i) => {
    const ws = words(p);
    let hits = 0;
    for (const w of ws) if (q.has(w)) hits++;
    // The opening says what the page is; headings help find the way.
    const bonus = (i < 3 ? 2 : 0) + (/^#|^[A-Z][^.!?]{0,80}$/.test(p) ? 0.5 : 0);
    return { i, p, score: (ws.length ? hits / Math.sqrt(ws.length) : 0) * 4 + bonus };
  });
  const keep = new Set<number>();
  let used = 0;
  for (const s of [...scored].sort((a, b) => b.score - a.score || a.i - b.i)) {
    if (used + s.p.length + 2 > budget) continue;
    keep.add(s.i);
    used += s.p.length + 2;
  }
  const out: string[] = [];
  let last = -1;
  for (const s of scored) {
    if (!keep.has(s.i)) continue;
    if (last >= 0 && s.i !== last + 1) out.push("[…]");
    out.push(s.p);
    last = s.i;
  }
  return { text: out.join("\n\n"), from: text.length, trimmed: true };
}
