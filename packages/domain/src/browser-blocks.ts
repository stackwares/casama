/**
 * Notices a page that kept the bot's computer out: a "prove you're human" challenge or a flat
 * refusal (docs/PHONE-BROWSER-PLAN.md §5, T2). It reads the text a snapshot or a page read already
 * returned, so it costs no extra call.
 *
 * Careful on purpose: a normal page that mentions a CAPTCHA, or a sign-in form with one on it, is
 * not a block. A block page is short and says little else.
 */

export type BrowserBlockKind = "challenge" | "denied";

export interface BrowserBlock {
  kind: BrowserBlockKind;
  /** The phrase that gave it away, for the audit row. */
  sign: string;
}

/** A block page says little. Longer pages need a stronger sign. */
const SHORT = 1200;

/** A person can get past these by solving something. */
const CHALLENGE: RegExp[] = [
  /just a moment\.\.\./i,
  /verify(ing)? (that )?you are (a )?human/i,
  /checking (if the site connection is secure|your browser before accessing)/i,
  /press (and|&) hold to confirm/i,
  /are you a (robot|human)\??/i,
  /confirm (that )?you('re| are) (not a robot|a human)/i,
  /complete the (captcha|security check)/i,
  /unusual traffic from your computer network/i,
  /pardon our interruption/i,
  /let's confirm you are human/i,
  /additional verification required/i,
  /enable javascript and cookies to continue/i,
];

/** Nothing to solve: the site refused. */
const DENIED: RegExp[] = [
  /access denied/i,
  /sorry, you have been blocked/i,
  /attention required!? \| cloudflare/i,
  /error 1020/i,
  /you don't have permission to access/i,
  /your (ip|access) (address )?(has been|is) (blocked|banned|restricted)/i,
  /request (was )?blocked/i,
  /403 forbidden/i,
  /automated (access|queries|requests) (to this (site|page) )?(is|are|has been) (not allowed|blocked|detected)/i,
  /too many requests/i,
];

/** Only on long pages: phrases that don't turn up in ordinary copy. */
const STRONG: RegExp[] = [
  /unusual traffic from your computer network/i,
  /sorry, you have been blocked/i,
  /attention required!? \| cloudflare/i,
  /press (and|&) hold to confirm/i,
];

/** What kind of block [text] (a snapshot or page text) looks like, or null. */
export function detectBrowserBlock(text: string): BrowserBlock | null {
  const t = text.replace(/\s+/g, " ").trim();
  if (!t) return null;
  const short = t.length <= SHORT;
  const find = (list: RegExp[]) => {
    for (const re of list) {
      const m = re.exec(t);
      if (m) return m[0];
    }
    return null;
  };
  if (!short) {
    const s = find(STRONG);
    if (!s) return null;
    return { kind: CHALLENGE.some((re) => re.test(s)) ? "challenge" : "denied", sign: s };
  }
  const c = find(CHALLENGE);
  if (c) return { kind: "challenge", sign: c };
  const d = find(DENIED);
  if (d) return { kind: "denied", sign: d };
  return null;
}
