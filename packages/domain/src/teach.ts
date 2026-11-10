/**
 * Teach a task by showing it (D-120): what a recorded step looks like and how a recording becomes
 * the model's instructions for a draft skill.
 */

export interface TeachStepView {
  seq: number;
  kind: "click" | "type" | "key" | "scroll";
  x?: number | null;
  y?: number | null;
  button?: number | null;
  text?: string | null;
  key?: string | null;
  dx?: number | null;
  dy?: number | null;
  secretName?: string | null;
  password?: boolean;
  url?: string | null;
  snapshot?: string | null;
}

/**
 * Whether the focused element in an accessibility snapshot is a password field. Both snapshot
 * tools mark focus and name the role (`password`, `secure text field`, `protected`).
 */
export function focusedIsPassword(snapshot: string | null | undefined) {
  if (!snapshot) return false;
  return snapshot
    .split("\n")
    .some((l) => /\bfocused\b/i.test(l) && /(password|secure ?text|protected)/i.test(l));
}

/** A free name for a secret input: PASSWORD, PASSWORD_2, … */
export function nextSecretName(taken: Iterable<string | null | undefined>, base = "PASSWORD") {
  const used = new Set([...taken].filter(Boolean));
  if (!used.has(base)) return base;
  for (let i = 2; ; i++) if (!used.has(`${base}_${i}`)) return `${base}_${i}`;
}

const BUTTONS: Record<number, string> = { 1: "click", 2: "middle-click", 3: "right-click" };

/** One line per step, for the model. Secrets are placeholders; text is quoted as typed. */
export function describeStep(s: TeachStepView) {
  switch (s.kind) {
    case "click":
      return `${BUTTONS[s.button ?? 1] ?? "click"} at (${s.x ?? "?"}, ${s.y ?? "?"})`;
    case "type":
      return s.secretName
        ? `type {{secret:${s.secretName}}}${s.password ? " (a password field; not recorded)" : " (marked secret; not recorded)"}`
        : `type ${JSON.stringify(s.text ?? "")}`;
    case "key":
      return `press ${s.key ?? "?"}`;
    default:
      return `scroll (${s.dx ?? 0}, ${s.dy ?? 0})`;
  }
}

export const TEACH_INSTRUCTIONS = [
  "Turn this recording into a skill. I just showed you a task on your computer while I had control; the steps are below, each with the page address and what the screen's accessibility tree looked like right after it.",
  "Call teach.save_draft once with: a short name (lowercase, dashes), a one-line description of when to use it, and step-by-step instructions that work on any day, not just today. Describe what to click by its label or role, not by coordinates. Values I typed that would change next time become inputs (parameters); {{secret:NAME}} values stay as secret inputs, never as text. Add success checks: what the screen shows when it worked.",
  "Don't do the task now and don't use any other tools.",
].join("\n");

/** The drafting run's message: instructions plus the recording, trimmed to fit. */
export function teachTranscript(
  steps: TeachStepView[],
  opts: { snapshotChars?: number; maxChars?: number } = {},
) {
  const per = opts.snapshotChars ?? 1500;
  const max = opts.maxChars ?? 60_000;
  const lines = [TEACH_INSTRUCTIONS, "", `Recording (${steps.length} steps):`];
  let lastUrl: string | null | undefined;
  for (const s of steps) {
    if (s.url && s.url !== lastUrl) lines.push(`\nOn ${s.url}`);
    lastUrl = s.url ?? lastUrl;
    lines.push(`${s.seq}. ${describeStep(s)}`);
    if (s.snapshot)
      lines.push(`   Screen after: ${s.snapshot.slice(0, per).replaceAll("\n", "\n   ")}`);
  }
  const text = lines.join("\n");
  return text.length > max ? `${text.slice(0, max)}\n…(recording trimmed)` : text;
}
