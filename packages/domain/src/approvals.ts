export type Risk = "low" | "medium" | "high";
export type Autonomy = "ask_always" | "ask_risky" | "autonomous";

export interface ApprovalInput {
  autonomy: Autonomy;
  risk: Risk;
  /** Read-only tools never need approval (search, read, list, snapshot). */
  readOnly: boolean;
  /**
   * Tools that only change the bot's own state inside Casama, visibly and reversibly (its notes,
   * schedule, board tasks, messages to the person): never asked for, whatever the autonomy (D-155).
   */
  selfOnly?: boolean;
  /** The tool asks for approval under ask_risky whatever its risk (for example media generation). */
  confirmUnderDefault?: boolean;
  /**
   * High-risk on the person's own Mac (the desktop companion, D-066): asks under ask_risky and
   * ask_always even when "Always allow" was ticked before (D-394 lets autonomous bots and grants
   * through).
   */
  forceHighRisk?: boolean;
  /** The workspace's Full access switch is on (D-394): nothing in here asks. */
  fullAccess?: boolean;
  /** The run read untrusted content (web, email, tool output) since the last approval. */
  untrustedSinceApproval: boolean;
  /**
   * The call sends data out of Casama (a web request that writes, a connected app's write tool, a
   * message to someone else's assistant). Under ask_risky, only these medium-risk calls ask after
   * untrusted content, so an injected instruction can't quietly send things out (D-213).
   */
  sendsOut?: boolean;
  /** "Always allow this tool for this bot" was ticked before. */
  granted: boolean;
  /**
   * The call sets up work that runs later on its own (a routine). Under ask_risky it asks after
   * untrusted content even though it only changes the bot's own setup, so a web page can't plant a
   * standing instruction (D-269).
   */
  schedulesWork?: boolean;
}

/**
 * Whether a tool call needs a human's approval.
 * ask_always: every tool with side effects. ask_risky (default): high risk, tools that always confirm,
 * and medium-risk calls that send data out after untrusted input (D-213). autonomous: never. Full access
 * (D-394) never asks either; the gate still asks for tools marked askEvenWithFullAccess (payments).
 */
export function needsApproval(i: ApprovalInput): boolean {
  if (i.readOnly || i.fullAccess) return false;
  if (
    i.schedulesWork &&
    i.untrustedSinceApproval &&
    !i.granted &&
    (i.autonomy === "ask_risky" || i.autonomy === "ask_always")
  )
    return true;
  if (i.selfOnly) return false;
  if (i.granted) return false;
  // "Act on its own" and "Always allow" now cover the person's own Mac too (D-394, revisiting D-066).
  if (i.forceHighRisk && i.risk === "high" && i.autonomy !== "autonomous") return true;
  switch (i.autonomy) {
    case "ask_always":
      return true;
    case "autonomous":
      return false;
    default:
      return (
        i.risk === "high" ||
        i.confirmUnderDefault === true ||
        (i.risk === "medium" && i.untrustedSinceApproval && i.sendsOut === true)
      );
  }
}

export const APPROVAL_TTL_MS = 24 * 60 * 60 * 1000;

/** Delegation limits. */
export const MAX_DELEGATION_DEPTH = 3;
export const SUBAGENT_BUDGET_SHARE = 0.2;

/** Default budget for a subagent: 20% of what the parent has left (at least one cent). */
export function subagentBudget(parentLimit: number | null, parentSpent: number) {
  if (parentLimit == null) return 0.5;
  return Math.max(
    0.01,
    Math.round((parentLimit - parentSpent) * SUBAGENT_BUDGET_SHARE * 10_000) / 10_000,
  );
}
