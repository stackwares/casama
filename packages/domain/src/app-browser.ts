/**
 * The browser inside the phone app (docs/PHONE-BROWSER-PLAN.md): who may use it and for which
 * reasons. One instance setting, changed by the owner without a deploy. It starts off, and each
 * stage adds people or reasons (plan §6).
 */

/** "off": nobody. "testers": the people listed. "on": everyone whose build has it. */
export type AppBrowserStage = "off" | "testers" | "on";

export const APP_BROWSER_STAGES: AppBrowserStage[] = ["off", "testers", "on"];
export const APP_BROWSER_SYSTEMS = ["ios", "android"] as const;
export type AppBrowserSystem = (typeof APP_BROWSER_SYSTEMS)[number];

/** Why a run may move to the phone's browser (plan §5). */
export interface AppBrowserReasons {
  /** T1: the person asks for it. */
  asked: boolean;
  /** T2: the site blocks the bot's computer. */
  blocked: boolean;
  /** T3: the person signed in to the site on the phone (its "always" list). */
  signed_in: boolean;
}

export interface AppBrowserSettings {
  stage: AppBrowserStage;
  /** User ids that have it in the "testers" stage. */
  testers: string[];
  reasons: AppBrowserReasons;
  /** Systems it is on for. Android goes first (plan decision 4). */
  systems: AppBrowserSystem[];
}

export const APP_BROWSER_OFF: AppBrowserSettings = {
  stage: "off",
  testers: [],
  reasons: { asked: true, blocked: false, signed_in: false },
  systems: [],
};

export const APP_BROWSER_MAX_TESTERS = 200;

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const isRecord = (v: unknown): v is Record<string, unknown> =>
  typeof v === "object" && v !== null && !Array.isArray(v);

/** Checks a stored or submitted setting. Unknown keys are refused, so a typo can't switch it on. */
export function checkAppBrowserSettings(raw: unknown): {
  settings?: AppBrowserSettings;
  errors: string[];
} {
  if (!isRecord(raw)) return { errors: ["settings must be an object"] };
  const errors: string[] = [];
  for (const k of Object.keys(raw))
    if (!["stage", "testers", "reasons", "systems"].includes(k)) errors.push(`unknown key: ${k}`);

  const stage = raw.stage;
  if (typeof stage !== "string" || !APP_BROWSER_STAGES.includes(stage as AppBrowserStage))
    errors.push(`stage must be one of ${APP_BROWSER_STAGES.join(", ")}`);

  const testers: string[] = [];
  if (raw.testers !== undefined) {
    if (!Array.isArray(raw.testers) || raw.testers.length > APP_BROWSER_MAX_TESTERS)
      errors.push(`testers must be a list of up to ${APP_BROWSER_MAX_TESTERS} user ids`);
    else
      for (const t of raw.testers) {
        if (typeof t !== "string" || !UUID.test(t)) errors.push(`testers: not a user id: ${t}`);
        else if (!testers.includes(t.toLowerCase())) testers.push(t.toLowerCase());
      }
  }

  const reasons: AppBrowserReasons = { ...APP_BROWSER_OFF.reasons };
  if (raw.reasons !== undefined) {
    if (!isRecord(raw.reasons)) errors.push("reasons must be an object");
    else
      for (const [k, v] of Object.entries(raw.reasons)) {
        if (!["asked", "blocked", "signed_in"].includes(k)) errors.push(`reasons.${k}: unknown`);
        else if (typeof v !== "boolean") errors.push(`reasons.${k} must be true or false`);
        else reasons[k as keyof AppBrowserReasons] = v;
      }
  }

  const systems: AppBrowserSystem[] = [];
  if (raw.systems !== undefined) {
    if (!Array.isArray(raw.systems)) errors.push("systems must be a list");
    else
      for (const s of raw.systems) {
        if (!APP_BROWSER_SYSTEMS.includes(s as AppBrowserSystem))
          errors.push(`systems: ${String(s)} is not ios or android`);
        else if (!systems.includes(s as AppBrowserSystem)) systems.push(s as AppBrowserSystem);
      }
  }

  if (errors.length) return { errors };
  return { settings: { stage: stage as AppBrowserStage, testers, reasons, systems }, errors };
}

/** Why a person can't use the phone's browser, in words for the app. */
export type AppBrowserDenied = "off" | "not_a_tester" | "system_off" | "workspace_off";

/**
 * Whether [userId] on [system] may use the phone's browser. The workspace switch is checked by the
 * caller's query and passed in.
 */
export function appBrowserFor(
  s: AppBrowserSettings,
  who: { userId: string; system: AppBrowserSystem | null; workspaceOn: boolean },
): { available: true } | { available: false; reason: AppBrowserDenied } {
  if (s.stage === "off") return { available: false, reason: "off" };
  if (s.stage === "testers" && !s.testers.includes(who.userId.toLowerCase()))
    return { available: false, reason: "not_a_tester" };
  // Testers get both systems, so the first one can be tried before the public has either.
  if (s.stage === "on" && (!who.system || !s.systems.includes(who.system)))
    return { available: false, reason: "system_off" };
  if (!who.workspaceOn) return { available: false, reason: "workspace_off" };
  return { available: true };
}

/** Actions the phone's browser doesn't do (plan §8.4); the answer points at the bot's computer. */
export const APP_BROWSER_UNSUPPORTED = ["console", "network", "page_text"] as const;

/** Steps the server checks against the step rules before a phone carries them out. */
export const APP_BROWSER_CHECKED = ["click", "fill", "type", "press", "upload"] as const;

/** How long the page asks the person about a step before it counts as no. */
export const APP_BROWSER_ASK_MS = 5 * 60 * 1000;
/** How fresh the chat-on-screen report must be (the app repeats it every 30 seconds). */
export const APP_BROWSER_FOCUS_S = 45;
