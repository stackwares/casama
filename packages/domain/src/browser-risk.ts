/**
 * Which steps a bot may take in the person's browser on its own (D-323 C7, plan §11). Pure, so it's
 * tested without a browser. One copy for both of a person's browsers: Casama for Chrome runs it in
 * the extension, and for the phone app's browser the server runs it before it forwards a step
 * (docs/PHONE-BROWSER-PLAN.md §8.5).
 *
 * - Clicks that send, pay, delete, publish, share or sign in ask the person first, always (the
 *   workspace's action rules apply on top, on the server).
 * - Purchases and password changes are handed to the person: the bot stops and says so.
 * - A password field is never filled by a bot: signing in is handed to the person too.
 * - Text read on one site and typed into another asks (the cross-site check), so a page can't get a
 *   bot to carry what it read somewhere else unseen.
 */

export type Verdict =
  | { kind: "ok" }
  | { kind: "ask"; reason: string }
  | { kind: "hand_off"; reason: string };

const OK: Verdict = { kind: "ok" };

/** Words on buttons and links that hand the step to the person. */
const HAND_OFF: Array<[RegExp, string]> = [
  [
    /\b(buy|purchase|place (your )?order|pay( now)?|checkout|check out|complete (purchase|order|payment)|confirm (purchase|order|payment)|subscribe|upgrade|donate|book now|reserve now)\b/i,
    "a purchase",
  ],
  [/\b(change|reset|update|set) (your |my )?(password|passcode|pin)\b/i, "a password change"],
];

/** Words that make a click ask first. */
const ASK: Array<[RegExp, string]> = [
  [/\b(send|reply|reply all|forward|post|submit|comment|tweet|message)\b/i, "sends something"],
  [/\b(delete|remove|discard|trash|erase|destroy|archive all|empty)\b/i, "deletes something"],
  [/\b(publish|go live|release|deploy|merge)\b/i, "publishes something"],
  [/\b(share|invite|grant access|make public|add (people|member))\b/i, "shares something"],
  [
    /\b(sign ?in|log ?in|sign ?up|register|authori[sz]e|allow access|connect account|accept invit\w*)\b/i,
    "signs in or grants access",
  ],
  [/\b(transfer|withdraw|send money|confirm)\b/i, "confirms a transaction"],
];

export interface ClickTarget {
  role: string;
  name: string;
  /** The page's address, for the person's sake. */
  url?: string;
  /** A submit button of a form whose fields include a password. */
  passwordForm?: boolean;
  /** An input of type "submit" or a button inside a form. */
  submits?: boolean;
}

/** What a click on [t] needs. */
export function clickVerdict(t: ClickTarget): Verdict {
  const name = t.name.trim();
  for (const [re, what] of HAND_OFF)
    if (re.test(name)) return { kind: "hand_off", reason: `"${short(name)}" looks like ${what}` };
  if (t.passwordForm && t.submits)
    return { kind: "hand_off", reason: "This form signs in with a password" };
  if (
    !["button", "link", "menuitem", "option", "switch", "checkbox", "radio", "tab"].includes(t.role)
  )
    return OK;
  for (const [re, what] of ASK)
    if (re.test(name)) return { kind: "ask", reason: `"${short(name)}" ${what}` };
  // A form's submit button with no telling name still sends the form.
  if (t.submits && !name) return { kind: "ask", reason: "This submits a form" };
  return OK;
}

export interface FieldTarget {
  role: string;
  name: string;
  /** The input's type attribute. */
  inputType?: string;
  autocomplete?: string;
}

/** Filling or typing into a field. */
export function fieldVerdict(f: FieldTarget): Verdict {
  const type = (f.inputType ?? "").toLowerCase();
  const ac = (f.autocomplete ?? "").toLowerCase();
  if (type === "password" || /(current|new)-password/.test(ac))
    return { kind: "hand_off", reason: "Passwords are typed by you, never by a bot" };
  if (/^cc-|one-time-code/.test(ac) || /\b(card number|cvc|cvv|security code)\b/i.test(f.name))
    return { kind: "hand_off", reason: "Card details and one-time codes are typed by you" };
  return OK;
}

/**
 * Pressing a key. Enter (or Ctrl/Cmd+Enter) in a form sends it, so it follows the form's submit
 * button; in any other text field or editable area it often sends what's typed (chat boxes,
 * comment boxes), so it asks, except in search boxes.
 */
export function keyVerdict(
  key: string,
  field?: {
    inForm?: boolean;
    submitName?: string;
    passwordForm?: boolean;
    editable?: boolean;
    inputType?: string;
    role?: string;
  },
): Verdict {
  const last = key.split("+").pop() ?? key;
  if (!/^(Enter|NumpadEnter)$/i.test(last) || !field) return OK;
  if (field.inForm)
    return clickVerdict({
      role: "button",
      name: field.submitName ?? "",
      submits: true,
      passwordForm: field.passwordForm,
    });
  if (!field.editable) return OK;
  if (field.inputType === "search" || /^(searchbox|combobox)$/.test(field.role ?? "")) return OK;
  return { kind: "ask", reason: "Pressing Enter here may send what's typed" };
}

/**
 * The cross-site check: whether [text] (to be typed on [host]) carries something the run read on
 * another site. Short or common text doesn't count; 24 characters in a row of something read
 * elsewhere does.
 */
export function crossSite(
  text: string,
  host: string,
  readBy: Map<string, string[]>,
): { from: string } | null {
  const t = norm(text);
  if (t.length < 24) return null;
  for (const [other, pages] of readBy) {
    if (other === host || sameSite(other, host)) continue;
    for (const page of pages) {
      const p = norm(page);
      // Any 24-character piece of the text appearing in what was read there.
      for (let i = 0; i + 24 <= t.length; i += 12)
        if (p.includes(t.slice(i, i + 24))) return { from: other };
    }
  }
  return null;
}

/** Same registrable-ish site: the last two labels (three for co.uk-style names). */
export function sameSite(a: string, b: string): boolean {
  const site = (h: string) => {
    const parts = h.split(".");
    const n =
      parts.length >= 3 &&
      parts[parts.length - 2]!.length <= 3 &&
      parts[parts.length - 1]!.length === 2
        ? 3
        : 2;
    return parts.slice(-n).join(".");
  };
  return site(a) === site(b);
}

const norm = (s: string) => s.replace(/\s+/g, " ").trim().toLowerCase();
const short = (s: string) => (s.length > 60 ? `${s.slice(0, 59)}…` : s);
