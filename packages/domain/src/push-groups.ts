/**
 * Which settings row and Android channel a notification kind belongs to (D-325). Every push goes
 * through one of five groups; a person can turn each one off in Notifications settings.
 */
export type PushGroup = "replies" | "needs_you" | "routines" | "suggestions" | "account";

export const PUSH_GROUPS: readonly PushGroup[] = [
  "replies",
  "needs_you",
  "routines",
  "suggestions",
  "account",
];

const BY_KIND: Record<string, PushGroup> = {
  reply: "replies",
  approval_request: "needs_you",
  secret: "needs_you",
  mcp_question: "needs_you",
  takeover: "needs_you",
  call_missed: "needs_you",
  permission: "needs_you",
  routine_result: "routines",
  bot_message: "routines",
  suggestion: "suggestions",
  mail_unknown_sender: "needs_you",
  mail_new_sender: "routines",
  mail_mailbox_full: "account",
  mail_auto_paused: "account",
  fare_drop: "routines",
};

export function pushGroup(kind: string): PushGroup {
  return BY_KIND[kind] ?? "account";
}

/** Groups whose pushes go at high priority (someone is waiting, or asked for it). */
export function pushIsHighPriority(group: PushGroup): boolean {
  return group === "replies" || group === "needs_you" || group === "suggestions";
}

export interface PushPrefs {
  replies?: boolean;
  needs_you?: boolean;
  routines?: boolean;
  suggestions?: boolean;
  account?: boolean;
  /** Lock screen shows "<bot> replied" instead of the reply's words. */
  hide_reply_text?: boolean;
}

/** Whether a group pushes under these settings (missing = on). */
export function pushGroupOn(prefs: PushPrefs | null | undefined, group: PushGroup): boolean {
  return prefs?.[group] !== false;
}
