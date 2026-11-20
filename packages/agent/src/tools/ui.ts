import { randomUUID } from "node:crypto";
import {
  checkComponents as checkCatalog,
  ensureSubmit,
  ensureWayOut,
  normalizeBindings,
  surfaceMessages,
  UI_COMPONENTS,
  UiCheckError,
} from "@casama/domain";
import { z } from "zod";
import { leanSchema, ToolError, type ToolRegistry } from "./registry.ts";
import { catalogHint, uiCatalog } from "./ui-catalog.ts";

// The catalog and its checks live in @casama/domain (a2ui.ts), shared with plugin cards (D-345).
export {
  A2UI_BASIC_CATALOG,
  ensureSubmit,
  ensureWayOut,
  normalizeBindings,
  surfaceMessages,
  UI_COMPONENTS,
} from "@casama/domain";

/**
 * Checks the tree before it reaches the app (see @casama/domain); a bad one comes back to the bot
 * with where to read that component's properties, since ui.show's description names only a few.
 */
export function checkComponents(components: Array<Record<string, unknown>>) {
  try {
    checkCatalog(components, { fromBot: true });
  } catch (err) {
    if (err instanceof UiCheckError)
      throw new ToolError("invalid_arguments", `${err.message}${catalogHint(err.message)}`);
    throw err;
  }
}

const Component = z
  .object({
    id: z.string().min(1).max(60),
    component: z.enum(UI_COMPONENTS, {
      error: (issue) =>
        issue.input === undefined
          ? "Each component needs a component name."
          : `${JSON.stringify(issue.input)} isn't in the catalog. Its components are ${UI_COMPONENTS.join(", ")}; call ui.catalog for their properties.`,
    }),
  })
  .catchall(z.unknown());

export const UiShowArgs = z.object({
  components: z.array(Component).min(1).max(60),
  data: z
    .record(z.string(), z.unknown())
    .optional()
    .describe('Starting values for inputs: {"form": {"plan": ["pro"]}}'),
});

const UiShowWire = z.object({
  components: z
    .array(z.object({ id: z.string(), component: z.string() }).catchall(z.unknown()))
    .min(1)
    .max(60),
  data: z
    .record(z.string(), z.unknown())
    .optional()
    .describe('Starting values for inputs: {"form": {"plan": ["pro"]}}'),
});

export const UiCatalogArgs = z.object({
  component: z
    .string()
    .max(200)
    .optional()
    .describe(
      'Names, e.g. "Map" or "Event, Agenda"; "checks" for Button checks. Leave out for all.',
    ),
});

/**
 * Sent with every model call, so it holds only what most UIs need: the tree, the layout and form
 * components, and when to reach for a card. The rest is ui.catalog's (ui-catalog.ts); a test keeps
 * this under its token budget (core-tools-size.test.ts).
 */
const DESCRIPTION = `Show the person a small interactive UI in the chat when a few taps beat typing: picking options, confirming details, filling 2-5 fields. Not for plain answers.

components is a flat list of {id, component, ...its properties}. The one with id "root" is the top; containers name their children by id.
- Text: {text, variant?: "body"|"caption"}. Start text with "## " for a heading; simple Markdown works.
- Column, Row: {children: [ids], align?, justify?}. Card: {child: id}. List: {children: [ids]}. Divider: {}. Image: {url}.
- Button: {child: id of a Text, variant?: "primary"|"default"|"borderless", action: {event: {name, context?}}}
- ChoicePicker: {label?, options: [{label, value}], value: {"@path": "/form/plan"}, variant?: "multipleSelection", displayStyle?: "chips"}. The path holds a list of strings. One choice unless "multipleSelection"; a lettered list (A, B, C…) unless "chips".
- TextField: {label, value, placeholder?, variant?: "shortText"|"longText"|"number"}. CheckBox: {label, value}. Slider: {label?, min?, max, value}. DateTimeInput: {label?, value, enableDate?, enableTime?}.

Every input's value is a data path like the ChoicePicker's. A Button's action sends you an event; put the values you need in its context: {"event": {"name": "submit", "context": {"plan": {"@path": "/form/plan"}}}}. To have the person pick between options, use one ChoicePicker with the question as its label, not a Button per option: Buttons are for actions. Never ask for a password, API key or other secret here (it would stay in the chat): use secrets.request.

After calling this, end your turn: the answer arrives as the person's next message. A typed letter or number is that option of your last list (A or 1 is first).

Every other component (Map, MessageDraft, Event, Checklist, Stats, Results, Details, Tabs, Video…) is described by ui.catalog, with Button checks: call it for a component's properties before you first use one. Most are cards for what you read, found or set up: show one instead of a long list in your reply, and still say a line in text. To show a place, where things are or a route, use a Map: never open a browser or build a page for it. Show an email, message or post you write for the person as a MessageDraft before sending, unless they said to send it straight away. Recipe, Comparison, ProsCons, Steps, Timeline, Calculator, Translation, Contact, Quiz, Countdown and Dashboard are cards too. Weather, prices, rates and scores come from the live tools, which show their own cards.`;

/**
 * The lettered options of each list question on a shown UI ("Which plan? A) Basic, B) Pro"), so
 * that on a later turn a typed "B" means something to the model. Chip pickers have no letters.
 */
export function uiChoiceLines(messages: unknown): string[] {
  if (!Array.isArray(messages)) return [];
  const lines: string[] = [];
  for (const m of messages) {
    const comps = (m as { updateComponents?: { components?: unknown } })?.updateComponents
      ?.components;
    if (!Array.isArray(comps)) continue;
    for (const c of comps as Array<Record<string, unknown>>) {
      if (c?.component !== "ChoicePicker" || c.displayStyle === "chips" || c.filterable) continue;
      const opts = (Array.isArray(c.options) ? c.options : [])
        .map((o) => (o as { label?: unknown; value?: unknown }) ?? {})
        .map((o) => String(typeof o.label === "string" ? o.label : (o.value ?? "")))
        .filter(Boolean);
      if (!opts.length) continue;
      const list = opts.map((o, i) => `${String.fromCharCode(65 + (i % 26))}) ${o}`).join(", ");
      const label = typeof c.label === "string" && c.label.trim() ? `${c.label.trim()} ` : "";
      const many = c.variant === "multipleSelection" ? " (pick any)" : "";
      lines.push(`${label}${list}${many}`);
    }
  }
  return lines;
}

/** How a shown card's tool result starts; the run loop ends the turn after one (one card at a time). */
export const UI_SHOWN_RESULT = "Showing the UI (";

/**
 * ui.show: interactive UI in the chat. The app renders it and sends the person's action back.
 * ui.catalog: the reference for everything ui.show takes, read when a bot needs more than the
 * components ui.show's own description covers.
 */
export function registerUiTools(registry: ToolRegistry) {
  registry.register({
    name: "ui.show",
    description: DESCRIPTION,
    risk: "low",
    // Showing a card changes nothing; what the person picks comes back as their own message. So it
    // never waits for approval, even for bots set to ask before everything.
    readOnly: true,
    schema: UiShowArgs,
    // The model sees component as a name, not all 60-odd: the parse still checks it, and a wrong
    // one comes back with the list (that also keeps every call's prompt small).
    jsonSchema: leanSchema(UiShowWire),
    async execute(args, ctx) {
      const components = normalizeBindings(args.components) as Array<Record<string, unknown>>;
      checkComponents(components);
      const shown = ensureWayOut(ensureSubmit(components));
      const surfaceId = `ui_${randomUUID().replaceAll("-", "").slice(0, 16)}`;
      await ctx.emit("ui.shown", {
        surface_id: surfaceId,
        messages: surfaceMessages(surfaceId, shown, args.data),
      });
      return {
        content: `${UI_SHOWN_RESULT}${surfaceId}) to the person now. End your turn; their answer arrives as their next message.`,
        preview: "shown",
      };
    },
  });

  registry.register({
    name: "ui.catalog",
    description: "Read the properties of ui.show's components. Shows nothing to the person.",
    risk: "low",
    readOnly: true,
    schema: UiCatalogArgs,
    jsonSchema: leanSchema(UiCatalogArgs),
    async execute(args) {
      return uiCatalog(args.component);
    },
  });
}
