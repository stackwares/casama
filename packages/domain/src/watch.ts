/**
 * What a watch may do with a request (D-410, docs/WATCH-PLAN.md §6.1 B, §8.4, decision 5): low
 * risk in one tap, medium risk with a hold, high risk and payments only on the phone. Deny always
 * works and isn't decided here. The server answers every watch with this and refuses an allow it
 * says is phone-only, so the watch apps never work it out themselves.
 */
import type { Risk } from "./approvals.ts";

/** How much a person lets their watches allow (§6.10). */
export type WatchAllowLevel = "medium" | "low" | "none";

export type WatchCanAllow = "tap" | "hold" | "phone";
export type WatchWhyPhone = "high_risk" | "payment" | "setting" | "workspace" | "not_yours";

export interface WatchAllowanceInput {
  risk: Risk;
  /** It spends money (spendsMoney: a payment, a paid data call): always the phone, whatever its risk. */
  payment: boolean;
  /** The person's watch setting; medium by default. */
  level: WatchAllowLevel;
  /** The workspace turned watch approvals off. */
  workspaceOff?: boolean;
  /**
   * The person started the run, or is an owner or admin of its workspace. Anyone who can see the
   * bot may still answer on the phone (decide_approval); the wrist allows only for one's own runs,
   * as secret requests do (D-101).
   */
  isYours: boolean;
  /**
   * The tool's full name (`composio.stripe.STRIPE_CREATE_REFUND`). A tool from a connected app or
   * MCP server rates itself (an MCP readOnlyHint makes it low), so on a watch it gets one tap only
   * when it is low risk and doesn't look like money by name; anything else from outside is
   * phone-only.
   */
  tool?: string;
}

export interface WatchAllowance {
  can_allow: WatchCanAllow;
  why_phone: WatchWhyPhone | null;
}

const phone = (why: WatchWhyPhone): WatchAllowance => ({ can_allow: "phone", why_phone: why });

/** Whether this watch may allow a request, and why not when it may only be answered on the phone. */
export function watchAllowance(i: WatchAllowanceInput): WatchAllowance {
  if (i.workspaceOff) return phone("workspace");
  if (!i.isYours) return phone("not_yours");
  if (i.payment || (i.tool && spendsMoney(i.tool))) return phone("payment");
  if (i.risk === "high") return phone("high_risk");
  if (i.tool && isOutsideTool(i.tool) && (i.risk !== "low" || isMoneyLike(i.tool)))
    return phone("high_risk");
  if (i.level === "none") return phone("setting");
  if (i.risk === "medium")
    return i.level === "medium" ? { can_allow: "hold", why_phone: null } : phone("setting");
  return { can_allow: "tap", why_phone: null };
}

/** A payment (payments.request): never allowed from a watch (§7). */
export function isPaymentTool(tool: string): boolean {
  return tool === "payments.request" || tool.startsWith("payments.");
}

/**
 * Built-in tools that buy something without being a payment by name. `data.call` buys one call to
 * a paid data service at medium risk, up to 1.5 times its quote. (Publishing a site and connecting
 * a domain are high risk, so they are phone-only already.)
 */
const SPENDING_TOOLS = new Set(["data.call"]);

/**
 * Whether allowing this tool spends money: a payment, or a built-in tool that buys something. The
 * one rule for "never allowed from a watch"; a watch is told `payment` for these.
 */
export function spendsMoney(tool: string): boolean {
  return isPaymentTool(tool) || SPENDING_TOOLS.has(tool);
}

/** Where tools from outside Casama come from: connected apps, MCP servers, other agents. */
const OUTSIDE_KINDS = [
  "mcp",
  "openapi",
  "composio",
  "pipedream",
  "local_mcp",
  "computer_mcp",
  "a2a",
];

/** A tool from a connected app or MCP server (`<kind>.<connection>.<tool>`), not a built-in one. */
export function isOutsideTool(tool: string): boolean {
  const kind = tool.split(".", 1)[0] ?? "";
  return tool.includes(".") && OUTSIDE_KINDS.includes(kind);
}

/** Words in a tool's name that mean money may move. */
const MONEY_WORDS =
  /pay|charge|refund|transfer|invoice|checkout|purchase|order|payout|subscri|billing|wallet/;

/** Whether an outside tool's name looks like it moves money (Stripe, PayPal, Shopify…). */
export function isMoneyLike(tool: string): boolean {
  return MONEY_WORDS.test(tool.toLowerCase());
}

/** The short answers under a reply when the person hasn't set their own (§6.2). */
export const WATCH_QUICK_REPLIES = ["Yes", "No", "Tell me more", "Not now"] as const;
