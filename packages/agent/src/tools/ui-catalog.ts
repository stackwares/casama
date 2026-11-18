/**
 * The full reference for what `ui.show` takes, read on demand through `ui.catalog`
 * (docs/USAGE-PLAN.md, step 4). `ui.show` goes out with every model call, so its description
 * holds only the components bots use most; everything else a bot needs to build a UI is here.
 * What the catalog accepts is decided by the checks in @casama/domain (a2ui.ts), not by this text.
 */
import { UI_COMPONENTS } from "@casama/domain";

export type UiComponent = (typeof UI_COMPONENTS)[number];

const LAYOUT =
  '{children: [ids], align?: "start"|"center"|"end"|"stretch", justify?: "start"|"center"|"end"|"spaceBetween"}';
const MEDIA =
  "It plays in the chat with a play button. The url must be an https link to the media file itself (.mp4, .mp3, .m4a…), not a page like YouTube or Spotify: for those, send the link in your reply.";

/** Each component's properties, in the words a bot builds it from. Every catalog component has one. */
export const UI_REFERENCE: Record<UiComponent, string> = {
  Text: '{text, variant?: "body"|"caption"}. Start text with "## " for a heading; simple Markdown works.',
  Row: `${LAYOUT}. Its children sit side by side.`,
  Column: `${LAYOUT}. Its children go top to bottom.`,
  List: '{children: [ids], direction?: "vertical"|"horizontal"}',
  Card: "{child: id}",
  Tabs: "{tabs: [{title, child: id}]}",
  Divider: "{}",
  Button:
    '{child: id of a Text, variant?: "primary"|"default"|"borderless", action: {event: {name, context?}}, checks?: [{condition, message}]}',
  TextField:
    '{label, value: {"@path": "/form/x"}, placeholder?, variant?: "shortText"|"longText"|"number", checks?: [{condition, message}]}',
  CheckBox: '{label, value: {"@path": "/form/agree"}}',
  ChoicePicker:
    '{label?, options: [{label, value}], value: {"@path": "/form/plan"}, variant?: "mutuallyExclusive"|"multipleSelection", displayStyle?: "chips"|"checkbox"}. Its value is a list of strings. The default allows one choice; when the person may pick several ("pick any", "all that apply"), set variant "multipleSelection". Without displayStyle "chips" it shows as a lettered list: A, B, C… in the order you give.',
  Slider: '{label?, min?, max, value: {"@path": "/form/n"}}',
  DateTimeInput: '{value: {"@path": "/form/when"}, enableDate?: true, enableTime?: true, label?}',
  Image: "{url, description?}",
  Icon: '{name}, e.g. "check", "info", "event", "mail".',
  Video: `{url, posterUrl?}. ${MEDIA}`,
  AudioPlayer: `{url, description?}. ${MEDIA}`,
  Map: "{center?: {lat, lng}, zoom?: 1-18 (12 is a city, 15 a neighbourhood, 17 a street), markers?: [{lat, lng, label?}], path?: [{lat, lng}] (a route line), height?: 140-420}. Give coordinates in decimal degrees from what you know or look up; without a center it fits the markers and path. A map with nothing to answer needs no Button: show it and say a line about it. When the person asks to see a place, a map, where things are or a route, show a Map: never open a browser or build a page for it.",
  MessageDraft:
    '{kind?: "email"|"message"|"post", app?: "gmail"|"outlook"|"slack"|"whatsapp"|"telegram"|"sms"|"x"|"linkedin"…, from?, to?: [addresses or names], cc?, bcc?, subject?, body, title?, status?}. An email, chat message or post you wrote, shown for the person to check, edit and send. It has its own Send, Discard and Edit buttons: don\'t add Buttons for it, and make it the root or put it in a Column with at most a Text above it. When the person asks you to write, draft, reply to or send an email or message for them, show it here before sending, unless they said to send it straight away. Tapping Send reaches you as "draft.send" with the final fields (they may have edited them): then send exactly that with your tools, without asking again. "draft.discard" means don\'t send it. Put the whole message in body as plain text, and every recipient in to, cc or bcc.',
  Event:
    '{title, start, end?, allDay?, location?, attendees?: [emails or names], description?, app?: "google_calendar"…, actions?: true}. One event to add: buttons Add to calendar ("event.add" with the final fields: then add exactly that with your tools, without asking again), Change ("event.change": ask what to change) and Skip ("event.skip"). Set actions false to show an event that already exists.',
  Agenda:
    "{title?, date?, events: [{title, start, end?, allDay?, location?}]}. A day or week of events, display only. Up to 40 events.",
  MessageList:
    '{title?, app?, messages: [{id, from, subject?, preview?, time?, unread?}], reply?: true}. Emails or chat messages you read, up to 25. Reply on a row sends "message.reply" {id, from, subject}: answer with a MessageDraft.',
  Checklist:
    '{title?, items: [{id, text, done?, due?, detail?}]}. Tasks or steps, up to 40; the person ticks and taps Save ("checklist.save" {done: [ids], undone: [ids]}): update them with your tools.',
  Stats:
    '{title?, stats?: [{label, value, unit?, change?: "+12%", trend?: "up"|"down"|"flat", good?: "up"|"down"}], chart?: {type: "line"|"bar", labels: [...], series: [{name?, values: [numbers]}], unit?}}. Numbers: health, spending, usage, results over time. Display only. It needs stats, a chart or both: up to 8 stats; a chart has 2 to 60 labels and 1 to 4 series, each with one number per label.',
  Results:
    '{title?, layout?: "carousel"|"list", items: [{id?, title, subtitle?, imageUrl?, rating?: 0-5, reviews?, price?, url?, badge?}], choose?: false}. Places, products, search results, up to 20; tapping one opens its url. With choose true each has Choose ("result.choose" {id, title}).',
  PersonPicker:
    '{label?, people: [{id?, name, detail?: email or phone, avatarUrl?}], multiple?}. When a name matches several contacts (up to 12), ask which one: "person.pick" {people: [...]} or "person.none".',
  Schedule:
    '{kind?: "reminder"|"routine"|"watcher", title, when: "Mondays at 9:00", next?, detail?, ref?: its id}. After you set up a reminder, routine or watcher: Change ("schedule.change") and Cancel it ("schedule.cancel" {ref}).',
  Details:
    "{title?, rows: [{label, value}], footer?}. Label and value rows, up to 30: a booking, an order, a receipt, a summary. Display only.",
};

/** Casama's own additions to the basic catalog: apps from before a card skip it. */
const CARDS = new Set<UiComponent>([
  "Map",
  "MessageDraft",
  "Event",
  "Agenda",
  "MessageList",
  "Checklist",
  "Stats",
  "Results",
  "PersonPicker",
  "Schedule",
  "Details",
]);
const INPUTS = new Set<UiComponent>([
  "TextField",
  "CheckBox",
  "ChoicePicker",
  "Slider",
  "DateTimeInput",
]);

const INTRO =
  "ui.show shows the person a small interactive UI in the chat (A2UI v1.0, basic catalog, plus Casama's own cards): choice buttons, a short form, a card with options, a map, a message draft, events, messages, tasks, numbers, results. Use it when a few taps beat typing: picking between options, confirming details, filling 2-5 fields. Don't use it for plain answers.";
const TREE =
  'Give a flat list of components; the one with id "root" is the top. Containers name their children by id. Each component is {id, component, ...its properties}; a ? marks a property you may leave out.';
const CARDS_NOTE =
  "Casama's own cards. Show what you read or found in one of these instead of a long list in your reply, and still say a line in text (older apps skip cards they don't know). Those with their own buttons need no Button from you, and their events reach you as the person's answer. Times are ISO 8601 in the person's time zone (\"2026-11-20T14:00\").";
const BINDING =
  'Inputs keep their values at their data path; bind with {"@path": "/form/x"} (note the @). A Button\'s action sends an event to you; put the values you need in its context with paths, e.g. {"event": {"name": "submit", "context": {"plan": {"@path": "/form/plan"}, "note": {"@path": "/form/note"}}}}. To ask the person to pick between options (which plan, which task to take on, "want me to do one of these?"), use one ChoicePicker with the question as its label, not a Button per option: they tap a letter, or just type it ("B", "A and C", "2"). Keep Buttons for actions (Connect, Confirm, Open), not answers. Inputs alone send nothing: every UI with inputs needs a Button that sends them (one is added if you leave it out). Always leave the person a way out: next to a single Go/Send/Confirm button, add a borderless "Skip" or "Not now" (a Skip is added if a UI has only one button). ui.show\'s data argument gives inputs their starting values by path, e.g. {"form": {"plan": ["pro"], "note": ""}}.';
const CHECKS =
  'Checks: a Button takes checks: [{condition, message}] and stays off until they all pass, with the first failing message as its tooltip. Put a form\'s checks on its Send button. Inputs take checks too, but an input shows a failing one in red at once, before the person has typed, so leave them off inputs unless the field starts filled in. A condition calls one of: required {value}, email {value}, length {value, min?, max?}, numeric {value, min?, max?}, regex {value, pattern}, or combines them with and {values: [...]}, or {values: [...]}, not {value}. Write it as {"@call": "required", "args": {"value": {"@path": "/form/name"}}}. Use checks when a field must be filled or have a form (an email, 1-10 guests), not for every field. Don\'t use a form to ask for passwords, API keys or other secrets: what is sent here stays in the chat. Ask for those with secrets.request.';
const AFTER =
  "After calling ui.show, end your turn: the person's choice arrives as their next message. If they type letters or numbers instead of tapping, read them as those options of your last list (A or 1 is the first).";

const line = (name: UiComponent) => `- ${name}: ${UI_REFERENCE[name]}`;

/** Everything `ui.show` takes: every component, then how inputs, buttons and checks work. */
export function uiCatalogAll(): string {
  const basic = UI_COMPONENTS.filter((c) => !CARDS.has(c));
  const cards = UI_COMPONENTS.filter((c) => CARDS.has(c));
  return [
    INTRO,
    [TREE, ...basic.map(line)].join("\n"),
    [CARDS_NOTE, ...cards.map(line)].join("\n"),
    BINDING,
    CHECKS,
    AFTER,
  ].join("\n\n");
}

/** Words a bot may put around a name ("the Map card"); they aren't names it got wrong. */
const FILLER = /^(the|a|an|and|or|for|of|component|components|card|cards|properties)$/i;

/**
 * What `ui.catalog` answers. Without a name: everything. With one or more names ("Map", "event,
 * agenda", "checks"): those components and the notes that apply to them. When no name is one the
 * catalog has, everything again, so the bot never needs a second call to find the right one.
 */
export function uiCatalog(component?: string): { content: string; preview: string } {
  const asked = (component ?? "").split(/[\s,;/|]+/).filter((w) => w && !FILLER.test(w));
  const found: UiComponent[] = [];
  const unknown: string[] = [];
  let checks = false;
  for (const word of asked) {
    const name = UI_COMPONENTS.find((c) => c.toLowerCase() === word.toLowerCase());
    if (name) found.push(name);
    else if (/^checks?$/i.test(word)) checks = true;
    else unknown.push(word);
  }
  const missing = unknown.length
    ? `The catalog has no ${unknown.map((u) => `"${u}"`).join(" or ")}; its components are ${UI_COMPONENTS.join(", ")}.`
    : null;
  const names = [...new Set(found)];
  if (!names.length && !checks)
    return {
      content: [missing, uiCatalogAll()].filter(Boolean).join(" All of it:\n\n"),
      preview: "all components",
    };
  const forms = names.some((c) => INPUTS.has(c) || c === "Button");
  return {
    content: [
      missing,
      names.map(line).join("\n"),
      names.some((c) => CARDS.has(c)) ? CARDS_NOTE : null,
      forms ? BINDING : null,
      checks || forms ? CHECKS : null,
      names.length
        ? `A component goes in ui.show's flat components list as {"id": …, "component": "${names[0]}", …its properties}; the top one's id is "root".`
        : null,
    ]
      .filter(Boolean)
      .join("\n\n"),
    preview: [...names, ...(checks ? ["checks"] : [])].join(", "),
  };
}

/**
 * Added to a refused `ui.show`: where to read the properties of the component the refusal is
 * about. `message` is the check's own wording (`Map "m": …`, `Component "go", check 1: …`).
 * Nothing for a refusal about the tree itself (no root, a missing child, two of one id).
 */
export function catalogHint(message: string): string {
  if (/^Component "[^"]*"(, check \d|: checks must be)/.test(message))
    return ' ui.catalog with component "checks" describes checks.';
  // A card's own event on a Button ("draft." events belong to MessageDraft), else `Name "id" …`.
  const name = (/events belong to ([A-Za-z]+)\./.exec(message) ??
    /^([A-Za-z]+) "/.exec(message))?.[1];
  return name && (UI_COMPONENTS as readonly string[]).includes(name)
    ? ` Call ui.catalog with component "${name}" for its properties.`
    : "";
}
