/**
 * The words of the welcome series and the gallery digest (D-372), editable by a server's owner in
 * Admin (instance_settings key "email_copy"). Copy only: who gets which email and when stays in
 * code, and billing and domain emails aren't editable at all. Any field left out uses the text in
 * code.
 */

export const EDITABLE_EMAIL_KINDS = [
  "welcome",
  "first_bot_nudge",
  "week_one_tips",
  "come_back",
  "gallery_digest",
] as const;
export type EditableEmailKind = (typeof EDITABLE_EMAIL_KINDS)[number];

export interface EmailCopy {
  subject?: string;
  /** The inbox preview line. `{count}` is the number of items in a gallery digest. */
  preheader?: string;
  title?: string;
  /** Paragraphs after the greeting ("Hi Ana,"), which stays in code. */
  intro?: string[];
  /** The button's label; where it goes stays in code. */
  button?: string;
}

export type EmailCopySettings = Partial<Record<EditableEmailKind, EmailCopy>>;

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

const LIMITS = { subject: 120, preheader: 160, title: 120, button: 40 } as const;

/** Checks an owner's email copy. Returns it cleaned when there are no errors. */
export function checkEmailCopy(raw: unknown): { copy?: EmailCopySettings; errors: string[] } {
  const errors: string[] = [];
  if (!isRecord(raw)) return { errors: ["email copy must be an object"] };
  const copy: EmailCopySettings = {};
  for (const [kind, v] of Object.entries(raw)) {
    if (!(EDITABLE_EMAIL_KINDS as readonly string[]).includes(kind)) {
      errors.push(
        `${kind} isn't an email whose words can change (${EDITABLE_EMAIL_KINDS.join(", ")})`,
      );
      continue;
    }
    if (v === null) continue;
    if (!isRecord(v)) {
      errors.push(`${kind} must be an object`);
      continue;
    }
    const out: EmailCopy = {};
    for (const [k, value] of Object.entries(v)) {
      if (k === "intro") {
        if (
          !Array.isArray(value) ||
          value.length < 1 ||
          value.length > 8 ||
          value.some((p) => typeof p !== "string" || !p.trim() || p.length > 1000)
        )
          errors.push(`${kind}.intro must be 1 to 8 paragraphs of at most 1,000 characters`);
        else out.intro = value.map((p: string) => p.trim());
      } else if (k in LIMITS) {
        const max = LIMITS[k as keyof typeof LIMITS];
        const t = typeof value === "string" ? value.trim() : "";
        if (value === null || value === "") continue;
        if (t.length < 1 || t.length > max)
          errors.push(`${kind}.${k} must be 1 to ${max} characters`);
        else out[k as keyof typeof LIMITS] = t;
      } else errors.push(`${kind}.${k} isn't a field (subject, preheader, title, intro, button)`);
    }
    if (Object.keys(out).length) copy[kind as EditableEmailKind] = out;
  }
  if (errors.length) return { errors };
  return { errors, copy };
}
