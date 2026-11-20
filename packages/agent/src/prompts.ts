/**
 * Check-in and setup prompts as versioned gallery content (D-374, docs/REMOTE-CONTENT-PLAN.md #8).
 * The text people's bots follow for briefs, scans and the setup interview comes from the signed
 * gallery's `prompts.json` (first-party only: the main catalog, never an extra source), so a
 * reviewed pull request changes it without a deploy. The words below are the fallback, used when
 * the gallery can't be reached or an entry fails its check.
 *
 * The parts code checks for are not in this text and can't be edited: the brief's opening
 * ("Write my morning brief for today."), the scan's ("Check-in scan."), the "Quiet day" and
 * NOTHING_NEW replies and the setup summary's "You're all set." (checkins.ts adds them).
 */

export const PROMPT_IDS = [
  "checkin.brief",
  "checkin.scan",
  "checkin.setup_scan",
  "checkin.reason.connection",
  "checkin.reason.event",
  "setup.guide",
] as const;
export type PromptId = (typeof PROMPT_IDS)[number];

/** The fallback text of each prompt (what the gallery's version 1 holds too). */
export const BUILT_IN_PROMPTS: Readonly<Record<PromptId, string>> = {
  "checkin.brief": [
    "Check what you can reach: calendar and email accounts you're connected to, tickets on the board assigned to you or me, active projects, and anything you're watching.",
    "Cover, briefly: today's meetings (time, title, who), what's coming up in the next couple of days, emails that need a reply from me, tickets due or blocked, and projects that need a decision. Skip sections with nothing in them, and say each thing once.",
    "Only today and what's ahead: leave out anything that has already happened (a trip that ended, a flight that left). An all-day event's end date is the day after its last day.",
    'If tickets labelled read-for-me are waiting (pages I sent from Chrome to read later), add a short "To read" part: for each, its title and two lines on what it says and why it might matter to me, then move the ticket to done.',
    "Leave out Casama's own emails about my plan, billing or account; the app tells me about those. Say only what you saw; don't guess at causes.",
    "Start with one plain sentence, no heading and no date, that says the most important thing; it's also the notification I get.",
    "When you can show live cards, open with one live.dashboard: today's weather for my city, plus any prices, rates or countdowns I've asked you to watch. Then don't repeat its numbers in the text.",
    "Keep it to one screen. Don't take any actions; suggest them instead with suggestions.add when something clearly needs doing, but not anything already suggested or dismissed (listed below).",
    "You have only a few steps. When your recent mail, calendar or tickets are already there as you start, use them; don't fetch them again, and make calls that don't depend on each other in the same step.",
  ].join("\n"),
  "checkin.scan": [
    "Look over what you can reach (connected accounts, calendar, email, tickets, projects, things you're watching) for anything new since your last scan that I'd want help with. Think ahead: what's coming up in the next couple of days, and what would make it go smoothly?",
    "Group things that belong together (a trip, an event, a deadline and its prep) into one suggestion instead of several. When a plan has parts spread across apps (tickets, rides, stays, flights), you can offer to pull them into one shareable Page (pages.publish).",
    "For each item, call suggestions.add with a short title, why it matters, the action you'd take (a tool and its arguments) when there is one, the sources, its urgency (urgent only if it can't wait for my next look), and push_text: one short first-person line, the way you'd text a friend, ending in a question when you're offering to do something (\"Want me to book a ride to the show at 7?\"). When an offer only makes sense close to a time (leaving for the airport, booking the ride an hour before the show), set notify_at to that time.",
    "Keep the look light: recent mail (about 10 messages, newest first, without full bodies) and the next two days of calendar. Open a message only when it matters.",
    "You have only a few steps. When your recent mail, calendar or tickets are already there as you start, use them; don't fetch them again. Make calls that don't depend on each other in the same step, and add all your suggestions in one step.",
    "Don't repeat anything already suggested or dismissed (listed below). Don't take actions yourself.",
  ].join("\n"),
  "checkin.setup_scan":
    "This is your first look since I set you up. Look across everything you can reach for the next few days and add up to 5 suggestions; their pushes are held, and I get one summary instead.",
  "checkin.reason.connection": "An app was just connected. Start with what it shows.",
  "checkin.reason.event":
    "Something just changed in a connected app (a new email or a calendar change). Look at what's new first.",
  "setup.guide": [
    "You are being set up by the person you'll work for. This conversation is your setup interview.",
    "1. Ask three to six short questions with ui.show, one card at a time (a card can hold one or two questions; choices where they fit, a text field otherwise), and wait for each answer before the next card. Cover: the work you'll do and what good looks like; how they like things written (length, tone, format); which tools and accounts you'll need; and any regular schedule (daily or weekly jobs).",
    "2. Then call setup.apply once with: your new standing instructions (second person, specific, a short bullet list), up to five memories worth keeping (facts about them and their work), routines for any schedule they gave, and connections they should add (service names only).",
    "3. Don't make changes any other way during setup. If they want to stop, say they can rerun setup from your settings.",
  ].join("\n"),
};

/**
 * The fixed parts (code checks for them, so they stay out of the editable text): a brief starts with
 * BRIEF_OPENING and a scan with SCAN_OPENING (that's how a stored brief or scan is known to use the
 * built-in wording), "Quiet day" marks a brief with nothing to tell and NOTHING_NEW a scan with
 * nothing new, and the setup scan's summary starts "You're all set.".
 */
export const BRIEF_OPENING = "Write my morning brief for today.";
const BRIEF_QUIET =
  'If there\'s nothing at all, reply with just one short line starting with "Quiet day".';
export const SCAN_OPENING = "Check-in scan.";
const SCAN_NOTHING = "If there's nothing new, reply with just NOTHING_NEW.";
const SETUP_SCAN_SUMMARY =
  'Then reply with only that summary: one sentence that starts with "You\'re all set.", says how many things you found and names the best one, for example "You\'re all set. Found 3 things to start on, like booking a ride to the concert tomorrow night." If you found nothing, reply with just NOTHING_NEW.';

/** A brief's whole instructions: the opening, the editable text, the quiet-day rule. */
export const composeBrief = (text: string) => `${BRIEF_OPENING} ${text}\n${BRIEF_QUIET}`;
/** A scan's whole instructions: the opening, the editable text, the NOTHING_NEW rule. */
export const composeScan = (text: string) => `${SCAN_OPENING} ${text} ${SCAN_NOTHING}`;
/** The first scan after setup: the editable text, then the summary rule. */
export const composeSetupScan = (text: string) => `${text}\n${SETUP_SCAN_SUMMARY}`;

/** Words only code may say: a prompt that contains them would fight the code that checks for them. */
const RESERVED: Array<[RegExp, string]> = [
  [/NOTHING_NEW/, "NOTHING_NEW"],
  [/quiet day/i, '"Quiet day"'],
  [/write my morning brief for today/i, "the brief's opening line"],
  [/check-in scan\./i, "the scan's opening line"],
  [/you(?:'|’)re all set/i, '"You\'re all set"'],
];
export const PROMPT_MAX_CHARS = 8000;

/** What's wrong with a prompt's text, if anything. */
export function checkPromptText(id: string, text: unknown): string[] {
  if (!(PROMPT_IDS as readonly string[]).includes(id)) return [`${id} isn't a prompt id`];
  if (typeof text !== "string") return [`${id}: the text must be a string`];
  const t = text.trim();
  const errors: string[] = [];
  if (t.length < 20) errors.push(`${id}: the text is too short`);
  if (t.length > PROMPT_MAX_CHARS)
    errors.push(`${id}: the text is over ${PROMPT_MAX_CHARS} characters`);
  for (const [re, what] of RESERVED)
    if (re.test(t)) errors.push(`${id}: ${what} is added by code; leave it out of the text`);
  return errors;
}

let loaded: Partial<Record<PromptId, { text: string; version: number }>> = {};

/**
 * Takes the gallery's prompt entries ({ id, version, text }); entries that fail their check, or
 * ids this version doesn't know, are skipped and keep the fallback. Returns what was taken.
 */
export function setPrompts(items: unknown): Partial<Record<PromptId, number>> {
  const next: typeof loaded = {};
  for (const item of Array.isArray(items) ? items : []) {
    if (typeof item !== "object" || item === null) continue;
    const { id, version, text } = item as { id?: unknown; version?: unknown; text?: unknown };
    if (typeof id !== "string" || checkPromptText(id, text).length) continue;
    if (!Number.isInteger(version) || (version as number) < 1) continue;
    next[id as PromptId] = { text: (text as string).trim(), version: version as number };
  }
  loaded = next;
  return Object.fromEntries(Object.entries(next).map(([k, v]) => [k, v.version]));
}

/** A prompt's text now: the gallery's when it has a good one, else the fallback. */
export function promptText(id: PromptId): string {
  return loaded[id]?.text ?? BUILT_IN_PROMPTS[id];
}

/** The gallery version in use, or 0 for the fallback. */
export function promptVersion(id: PromptId): number {
  return loaded[id]?.version ?? 0;
}
