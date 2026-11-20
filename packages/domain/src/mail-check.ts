/**
 * Hosted bot mail (BOT-EMAIL-PLAN §5.2, §5.3): is the sender real, and is the mail automatic.
 * A sender is who they say only when their domain confirms it; automatic mail (bounces,
 * out-of-office replies, mailing lists) is never answered.
 */
import { parse as parseDomain } from "tldts";

/** Whether the sender's domain confirmed the From line. */
export type SenderCheck = "pass" | "fail" | "none";

export interface AuthResults {
  spf?: string;
  /** The domain SPF was checked against (`smtp.mailfrom`). */
  spfDomain?: string;
  dkim?: string;
  /** The signing domain (`header.d`). */
  dkimDomain?: string;
  /** All signing domains with a passing DKIM clause (a message may carry several signatures). */
  dkimDomains?: string[];
  dmarc?: string;
  /** The From domain DMARC checked (`header.from`). */
  dmarcDomain?: string;
}

export interface MailHeader {
  key: string;
  value: string;
}

/**
 * The sender-check results Cloudflare's routers prepended. Only the first Authentication-Results
 * header counts, and only when its service id is Cloudflare's own: senders can add fake ones
 * below it.
 */
export function cloudflareAuthResults(headers: readonly MailHeader[]): AuthResults | null {
  const h = headers.find((x) => x.key.toLowerCase() === "authentication-results");
  if (!h) return null;
  if ((h.value.split(";")[0] ?? "").trim().toLowerCase() !== "mx.cloudflare.net") return null;
  return pickResults(h.value);
}

const pickDomain = (value: string, prop: string): string | undefined => {
  const m = value.match(new RegExp(`\\b${prop}=([^\\s;()]+)`, "i"))?.[1]?.toLowerCase();
  if (!m) return undefined;
  // `smtp.mailfrom` may carry the whole address; only its domain counts.
  const at = m.lastIndexOf("@");
  return (at >= 0 ? m.slice(at + 1) : m).replace(/\.$/, "") || undefined;
};

/**
 * Best-effort sender check from headers a receiving API returned (the self-hosted email chat
 * app): the first Authentication-Results header, whoever prepended it. Absent: null.
 */
export function apiAuthResults(headers: readonly MailHeader[]): AuthResults | null {
  const h = headers.find((x) => x.key.toLowerCase() === "authentication-results");
  return h ? pickResults(h.value) : null;
}

/**
 * Resend's receiving API reports SPF, DKIM and DMARC itself (`gray` is its word for "no
 * record"). Its DKIM verdict is From-aware (gray covers a signing domain that doesn't match
 * From), but its SPF verdict checks the envelope, not From — so only DMARC passing, or DKIM
 * passing with no DMARC policy, confirms.
 */
export function senderCheckFromResend(auth: {
  spf?: unknown;
  dkim?: unknown;
  dmarc?: unknown;
}): SenderCheck {
  if (auth.dmarc === "pass") return "pass";
  if (auth.dmarc === "gray" && auth.dkim === "pass") return "pass";
  return "fail";
}

/** Strip RFC 822 comments `(...)` iteratively so comments cannot smuggle fake results. */
function stripComments(s: string): string {
  let out = s;
  for (let i = 0; i < 8; i++) {
    const next = out.replace(/\([^()]*\)/g, " ");
    if (next === out) break;
    out = next;
  }
  return out;
}

const pickResults = (value: string): AuthResults => {
  // RFC 8601: `authserv-id ; method=result props... ; method=result props...`.
  // Strip RFC 822 comments BEFORE splitting on `;` so a `;` inside a comment can't open a fake
  // clause, then parse each clause by its leading method token so a sender can't plant
  // `dmarc=pass` inside another clause (e.g. a DKIM field).
  const out: AuthResults = {};
  const dkimPassDomains: string[] = [];
  const clauses = stripComments(value).split(";").slice(1);
  for (const rawClause of clauses) {
    const clause = rawClause.trim();
    if (!clause) continue;
    const m = clause.match(/^(spf|dkim|dmarc)\s*=\s*([a-z0-9_-]+)/i);
    if (!m) continue;
    const method = m[1]!.toLowerCase();
    const verdict = m[2]!.toLowerCase();
    const rest = clause.slice(m[0].length);
    if (method === "spf" && !out.spf) {
      out.spf = verdict;
      out.spfDomain = pickDomain(rest, "smtp\\.mailfrom");
    } else if (method === "dkim") {
      const d = pickDomain(rest, "header\\.d");
      if (verdict === "pass") {
        out.dkim = "pass";
        if (d) {
          dkimPassDomains.push(d);
          out.dkimDomain ??= d;
        }
      } else if (!out.dkim) {
        out.dkim = verdict;
        out.dkimDomain ??= d;
      }
    } else if (method === "dmarc" && !out.dmarc) {
      out.dmarc = verdict;
      out.dmarcDomain = pickDomain(rest, "header\\.from");
    }
  }
  if (dkimPassDomains.length) out.dkimDomains = dkimPassDomains;
  return out;
};

/** Organizational domains equal (DMARC-style relaxed alignment): subdomains count. */
function sameOrg(a: string | undefined, b: string): boolean {
  if (!a || !b) return false;
  if (a === b) return true;
  const pa = parseDomain(a, { allowPrivateDomains: false });
  const pb = parseDomain(b, { allowPrivateDomains: false });
  return !!pa.domain && pa.domain === pb.domain;
}

/**
 * A sender counts as confirmed when DMARC passes (and, if `header.from` is present, matches the
 * From line's organizational domain), or, for a domain with no DMARC record (dmarc=none), when
 * SPF or DKIM passes *for the From line's organizational domain* (bounce and signing subdomains
 * count, other domains don't). A bare pass with no domain to check it against fails: without that,
 * anyone could spoof an allowed address on a DMARC-less domain from their own passing
 * infrastructure. Anything else is fail; no results at all is none.
 */
export function senderCheckFrom(r: AuthResults | null, fromDomain?: string): SenderCheck {
  if (!r) return "none";
  const from = (fromDomain ?? "").trim().toLowerCase().replace(/\.$/, "");
  if (r.dmarc === "pass") {
    if (r.dmarcDomain) return from && sameOrg(r.dmarcDomain, from) ? "pass" : "fail";
    return fromDomain !== undefined && !from ? "fail" : "pass";
  }
  if ((r.dmarc === "none" || r.dmarc === undefined) && from) {
    if (r.dkim === "pass") {
      const domains = r.dkimDomains?.length ? r.dkimDomains : r.dkimDomain ? [r.dkimDomain] : [];
      if (domains.some((d) => sameOrg(d, from))) return "pass";
    }
    if (r.spf === "pass" && sameOrg(r.spfDomain, from)) return "pass";
  }
  return "fail";
}

/**
 * Bounces, out-of-office replies and mailing lists: never answered, and (unless a routine asks
 * for them) never starting a run. This is what stops two auto-responders writing to each other
 * all night.
 */
export function isAutomaticMail(
  headers: readonly MailHeader[],
  from: string,
  envelopeFrom?: string,
): boolean {
  const f = from.trim();
  if (!f || f === "<>") return true;
  if (envelopeFrom !== undefined) {
    const env = envelopeFrom.trim();
    if (!env || env === "<>") return true;
  }
  const values = (name: string) =>
    headers
      .filter((x) => x.key.toLowerCase() === name)
      .map((x) => x.value)
      .join(" ");
  const auto = values("auto-submitted").trim().toLowerCase();
  if (auto && auto !== "no") return true;
  const xAutoReply = values("x-autoreply").trim().toLowerCase();
  if (xAutoReply && xAutoReply !== "no" && xAutoReply !== "0" && xAutoReply !== "false")
    return true;
  if (values("x-auto-response-suppress").trim()) return true;
  if (/\b(bulk|list|junk)\b/i.test(values("precedence"))) return true;
  if (values("list-id").trim()) return true;
  return /^(mailer-daemon|postmaster)@/i.test(f);
}
