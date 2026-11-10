/**
 * Action rules (SPEC: Post-v1 roadmap → Action rules; D-115). Which rule applies to a tool call:
 * the most specific one wins, ask or hand off wins ties, and nothing matching means the bot's
 * autonomy decides. Changing passwords or two-step settings is always handed off.
 */
export type ActionCategory = "send" | "pay" | "delete" | "publish" | "share" | "sign_in";
export type ActionRuleKind = "allow" | "allow_within_limits" | "ask" | "hand_off";

export type ActionRule = {
  id: string;
  bot_id: string | null;
  match_kind: "tool" | "group" | "category";
  match_value: string;
  target: { domains?: string[]; recipients?: string[]; max_amount?: number } | null;
  rule: ActionRuleKind;
};

export interface ActionTarget {
  recipients: string[];
  domains: string[];
  amount: number | null;
}

const CATEGORY_WORDS: Array<[ActionCategory, RegExp]> = [
  ["sign_in", /(sign_?in|log_?in|password|passkey|two_?factor|2fa|mfa|totp|credential)/],
  ["pay", /(pay|charge|transfer|refund|purchase|checkout|invoice_send|send_money|wire)/],
  ["delete", /(delete|remove|destroy|drop|purge|erase|archive_permanently)/],
  ["publish", /(publish|deploy|release|tweet|post_status|go_live)/],
  ["share", /(share|invite|grant|add_member|permission)/],
  ["send", /(send|email|mail|message|reply|forward|sms|text_message|post_message|chat_post)/],
];

/** A tool's category from its own declaration, or from words in its name. */
export function toolCategory(
  tool: string,
  declared?: ActionCategory | null,
): ActionCategory | null {
  if (declared) return declared;
  const name = tool.toLowerCase().replace(/[.-]/g, "_");
  for (const [cat, re] of CATEGORY_WORDS) if (re.test(name)) return cat;
  return null;
}

/** browser.open → browser; mcp.github.create_issue → mcp.github (same grouping as lazy tools). */
export function toolGroupOf(tool: string) {
  const parts = tool.split(".");
  const kinds = new Set(["mcp", "openapi", "composio", "pipedream", "local_mcp", "app"]);
  if (parts.length > 2 && kinds.has(parts[0] as string)) return `${parts[0]}.${parts[1]}`;
  return parts[0] as string;
}

const EMAIL = /[^\s<>@,;"']+@([a-z0-9-]+(?:\.[a-z0-9-]+)+)/gi;
const RECIPIENT_KEYS =
  /^(to|cc|bcc|recipient|recipients|email|emails|address|addresses|attendees|invitees)$/i;
const AMOUNT_KEYS = /^(amount|value|price|total|sum)$/i;

/** Recipients, their domains and an amount from a call's arguments (looked for by field name). */
export function extractTarget(args: unknown): ActionTarget {
  const recipients = new Set<string>();
  let amount: number | null = null;
  const walk = (v: unknown, key: string | null, depth: number) => {
    if (depth > 4 || v === null || v === undefined) return;
    if (Array.isArray(v)) {
      for (const x of v) walk(x, key, depth + 1);
      return;
    }
    if (typeof v === "object") {
      for (const [k, x] of Object.entries(v as Record<string, unknown>)) walk(x, k, depth + 1);
      return;
    }
    if (key && RECIPIENT_KEYS.test(key) && typeof v === "string")
      for (const m of v.matchAll(EMAIL)) recipients.add(m[0].toLowerCase());
    if (key && AMOUNT_KEYS.test(key)) {
      const n = typeof v === "number" ? v : Number(String(v).replace(/[^0-9.]/g, ""));
      if (Number.isFinite(n)) amount = Math.max(amount ?? 0, n);
    }
  };
  walk(args, null, 0);
  const list = [...recipients];
  return {
    recipients: list,
    domains: [...new Set(list.map((r) => r.split("@")[1] as string))],
    amount,
  };
}

/** Password and two-step changes always go to the person. */
export function isCredentialChange(tool: string, args: unknown) {
  const text = `${tool} ${JSON.stringify(args ?? {})}`.toLowerCase();
  return /(change|reset|update|set|disable|enable|remove)[_ -]?(the[_ -])?(password|two[_ -]?factor|2fa|mfa|totp|passkey)/.test(
    text,
  );
}

const domainOk = (d: string, allowed: string[]) =>
  allowed.some((a) => d === a.toLowerCase() || d.endsWith(`.${a.toLowerCase()}`));

/** Whether a call's target satisfies a rule's limits (no limits = always). */
export function targetMatches(rule: ActionRule, t: ActionTarget) {
  const lim = rule.target;
  if (!lim) return true;
  if (
    lim.domains?.length &&
    (!t.domains.length || !t.domains.every((d) => domainOk(d, lim.domains as string[])))
  )
    return false;
  if (lim.recipients?.length) {
    const ok = new Set(lim.recipients.map((r) => r.toLowerCase()));
    if (!t.recipients.length || !t.recipients.every((r) => ok.has(r))) return false;
  }
  if (
    lim.max_amount !== undefined &&
    lim.max_amount !== null &&
    (t.amount === null || t.amount > lim.max_amount)
  )
    return false;
  return true;
}

/**
 * The rule for a call, or null when none applies. A rule with limits only applies when the call is
 * within them. Specificity: the bot's own rule over a workspace rule, then tool over group over
 * category, then a rule with limits over one without.
 */
export function resolveActionRule(
  rules: ActionRule[],
  call: { botId: string; tool: string; category: ActionCategory | null; target: ActionTarget },
): ActionRule | null {
  const group = toolGroupOf(call.tool);
  let best: { r: ActionRule; score: number } | null = null;
  for (const r of rules) {
    if (r.bot_id && r.bot_id !== call.botId) continue;
    const matches =
      (r.match_kind === "tool" && r.match_value === call.tool) ||
      (r.match_kind === "group" && r.match_value === group) ||
      (r.match_kind === "category" && r.match_value === call.category);
    if (!matches || !targetMatches(r, call.target)) continue;
    const score =
      (r.bot_id ? 100 : 0) +
      (r.match_kind === "tool" ? 30 : r.match_kind === "group" ? 20 : 10) +
      (r.target ? 5 : 0);
    const cautious = r.rule === "ask" || r.rule === "hand_off";
    if (
      !best ||
      score > best.score ||
      (score === best.score && cautious && !(best.r.rule === "ask" || best.r.rule === "hand_off"))
    )
      best = { r, score };
  }
  return best?.r ?? null;
}

const CATEGORY_TEXT: Record<ActionCategory, string> = {
  send: "Sends messages",
  pay: "Makes payments",
  delete: "Deletes things",
  publish: "Publishes",
  share: "Shares or invites",
  sign_in: "Signs in",
};

/** A plain-language preview: "Sends messages to anyone at acme.com without asking". */
export function describeActionRule(
  r: Pick<ActionRule, "match_kind" | "match_value" | "target" | "rule">,
) {
  const what =
    r.match_kind === "category"
      ? (CATEGORY_TEXT[r.match_value as ActionCategory] ?? r.match_value)
      : r.match_kind === "group"
        ? `Uses ${r.match_value}`
        : `Runs ${r.match_value}`;
  const limits: string[] = [];
  if (r.target?.domains?.length) limits.push(`to anyone at ${r.target.domains.join(" or ")}`);
  if (r.target?.recipients?.length) limits.push(`to ${r.target.recipients.join(", ")}`);
  if (r.target?.max_amount !== undefined && r.target?.max_amount !== null)
    limits.push(`up to ${r.target.max_amount}`);
  const how =
    r.rule === "allow" || r.rule === "allow_within_limits"
      ? "without asking"
      : r.rule === "ask"
        ? "only after you approve"
        : "only by handing it to you to finish";
  return [what, ...limits, how].join(" ");
}
