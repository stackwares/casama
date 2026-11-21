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

// --- The stage rules (docs/PHONE-BROWSER-PLAN.md §6) ------------------------------------------

/** The numbers the rules read, over the last 14 days. */
export interface AppBrowserCounts {
  blocked_runs: number;
  blocked_people: number;
  watched_browser_runs: number;
  phone_runs: number;
  phones_paired: number;
  phones_with_sites: number;
  refused_steps: number;
}

export interface AppBrowserStep {
  /** What switching it on would change. */
  change: string;
  /** Whether the numbers a machine can read are there. */
  numbers_met: boolean;
  /** What the numbers say. */
  numbers: string;
  /** What only the owner can confirm. */
  still_needs: string[];
}

/**
 * The next switches and whether their bars are met. It only reads numbers: a safety miss, a store
 * approval and days spent in a stage are the owner's to confirm, and are listed, never assumed.
 */
export function appBrowserNextSteps(s: AppBrowserSettings, n: AppBrowserCounts): AppBrowserStep[] {
  const steps: AppBrowserStep[] = [];
  const pct = (a: number, b: number) => (b > 0 ? Math.round((a / b) * 1000) / 10 : 0);
  if (s.stage === "off")
    steps.push({
      change: "Stage 1: testers (the people you name, on internal test builds)",
      numbers_met: true,
      numbers: "No numbers needed.",
      still_needs: [
        "Phases 1 to 3 built and deployed",
        "You used it on an iPhone and an Android phone",
        "The names of the testers",
      ],
    });
  if (s.stage === "testers")
    steps.push({
      change: "Stage 2: on for everyone when they ask for it, Android first",
      numbers_met: n.phone_runs >= 100,
      numbers: `${n.phone_runs} runs used a phone's browser in 14 days (bar: 100).`,
      still_needs: [
        "14 days as testers",
        "No safety miss (a step that should have asked, been handed over or refused, and wasn't) and no crash from it",
        "Version 1.0 approved on both stores",
        "A store release whose review notes, listing, privacy answers and privacy page describe it",
      ],
    });
  if (s.stage === "on" && !s.systems.includes("ios"))
    steps.push({
      change: "iPhone and iPad",
      numbers_met: true,
      numbers: "No numbers needed.",
      still_needs: ["Apple approved a release that describes it"],
    });
  if (s.stage === "on" && !s.reasons.blocked) {
    const share = pct(n.blocked_runs, n.watched_browser_runs);
    steps.push({
      change: "Stage 3: also when a site blocks the bot's computer",
      numbers_met: share >= 5 || n.blocked_people >= 20,
      numbers: `${n.blocked_runs} of ${n.watched_browser_runs} watched browser runs on the computer met a block (${share}%; bar: 5%), for ${n.blocked_people} people (bar: 20). Under 2% for 60 days after launch means it stays off.`,
      still_needs: ["14 days in Stage 2 with no safety miss"],
    });
  }
  if (s.stage === "on" && !s.reasons.signed_in) {
    const share = pct(n.phones_with_sites, n.phones_paired);
    steps.push({
      change: "Stage 4: also for sites the person signed in to on the phone",
      numbers_met: share >= 25,
      numbers: `${n.phones_with_sites} of ${n.phones_paired} phones have a site added (${share}%; bar: 25%).`,
      still_needs: ["30 days in Stage 2 with no safety miss"],
    });
  }
  return steps;
}
