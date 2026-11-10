import { randomUUID } from "node:crypto";
import { z } from "zod";
import { ToolError, type ToolRegistry } from "./registry.ts";

/** The A2UI v1.0 basic catalog the apps render (D-086). */
export const A2UI_BASIC_CATALOG = "https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json";

export const UI_COMPONENTS = [
  "Text",
  "Row",
  "Column",
  "List",
  "Card",
  "Tabs",
  "Divider",
  "Button",
  "TextField",
  "CheckBox",
  "ChoicePicker",
  "Slider",
  "DateTimeInput",
  "Image",
  "Icon",
] as const;

const Component = z
  .object({
    id: z
      .string()
      .min(1)
      .max(60)
      .describe('Unique within this UI. The top component\'s id must be "root".'),
    component: z.enum(UI_COMPONENTS),
  })
  .catchall(z.unknown())
  .describe("One component: id, component name, and that component's properties.");

export const UiShowArgs = z.object({
  components: z.array(Component).min(1).max(60),
  data: z
    .record(z.string(), z.unknown())
    .optional()
    .describe(
      'Starting values for inputs, bound by path, e.g. {"form": {"plan": ["pro"], "note": ""}}.',
    ),
});

const DESCRIPTION = `Show the person a small interactive UI in the chat (A2UI v1.0, basic catalog): choice buttons, a short form, a card with options. Use it when a few taps beat typing: picking between options, confirming details, filling 2-5 fields. Don't use it for plain answers.

Give a flat list of components; the one with id "root" is the top. Containers name their children by id.
- Text: {text, variant?: "body"|"caption"}. Start text with "## " for a heading; simple Markdown works.
- Column / Row: {children: [ids], align?: "start"|"center"|"end"|"stretch", justify?: "start"|"center"|"end"|"spaceBetween"}
- Card: {child: id}. List: {children: [ids], direction?: "vertical"|"horizontal"}. Divider: {}.
- Tabs: {tabs: [{title, child: id}]}
- Button: {child: id of a Text, variant?: "primary"|"default"|"borderless", action: {event: {name, context?}}}
- TextField: {label, value: {"@path": "/form/x"}, placeholder?, variant?: "shortText"|"longText"|"number"}
- CheckBox: {label, value: {"@path": "/form/agree"}}
- ChoicePicker: {label?, options: [{label, value}], value: {"@path": "/form/plan"}, variant?: "mutuallyExclusive"|"multipleSelection", displayStyle?: "chips"|"checkbox"}. Its value is a list of strings.
- Slider: {label?, min?, max, value: {"@path": "/form/n"}}
- DateTimeInput: {value: {"@path": "/form/when"}, enableDate?: true, enableTime?: true, label?}
- Image: {url, description?}. Icon: {name}, e.g. "check", "info", "event", "mail".

Inputs keep their values at their data path; bind with {"@path": "/form/x"} (note the @). A Button's action sends an event to you; put the values you need in its context with paths, e.g. {"event": {"name": "submit", "context": {"plan": {"@path": "/form/plan"}, "note": {"@path": "/form/note"}}}}. For simple choices make one Button per option with a literal context, e.g. {"event": {"name": "choose", "context": {"plan": "pro"}}}.

After calling this, end your turn: the person's choice arrives as their next message.`;

/** A2UI v1.0 binds data with "@path"; models often write "path" (the v0.9 form). Fix it up. */
export function normalizeBindings(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(normalizeBindings);
  if (!value || typeof value !== "object") return value;
  const obj = value as Record<string, unknown>;
  const keys = Object.keys(obj);
  if (keys.length === 1 && keys[0] === "path" && typeof obj.path === "string")
    return { "@path": obj.path };
  return Object.fromEntries(Object.entries(obj).map(([k, v]) => [k, normalizeBindings(v)]));
}

/** Wraps a flat component list in the A2UI messages for one new surface. */
export function surfaceMessages(
  surfaceId: string,
  components: Array<Record<string, unknown>>,
  data?: Record<string, unknown>,
) {
  return [
    { version: "1.0", createSurface: { surfaceId, catalogId: A2UI_BASIC_CATALOG } },
    ...(data ? [{ version: "1.0", updateDataModel: { surfaceId, path: "/", value: data } }] : []),
    { version: "1.0", updateComponents: { surfaceId, components } },
  ];
}

/** Checks the tree before it reaches the app: a root, unique ids, and child references that exist. */
export function checkComponents(components: Array<Record<string, unknown>>) {
  const ids = new Set<string>();
  for (const c of components) {
    const id = String(c.id);
    if (ids.has(id))
      throw new ToolError("invalid_arguments", `Two components have the id "${id}".`);
    ids.add(id);
  }
  if (!ids.has("root"))
    throw new ToolError("invalid_arguments", 'One component must have the id "root".');
  for (const c of components) {
    const refs = [
      ...(typeof c.child === "string" ? [c.child] : []),
      ...(Array.isArray(c.children)
        ? c.children.filter((x): x is string => typeof x === "string")
        : []),
      ...(Array.isArray(c.tabs)
        ? c.tabs
            .map((t) => (t as { child?: unknown })?.child)
            .filter((x): x is string => typeof x === "string")
        : []),
    ];
    for (const r of refs) {
      if (!ids.has(r))
        throw new ToolError(
          "invalid_arguments",
          `Component "${c.id}" refers to "${r}", which isn't in the list.`,
        );
    }
  }
}

/** ui.show: interactive UI in the chat. The app renders it and sends the person's action back. */
export function registerUiTools(registry: ToolRegistry) {
  registry.register({
    name: "ui.show",
    description: DESCRIPTION,
    risk: "low",
    schema: UiShowArgs,
    async execute(args, ctx) {
      const components = normalizeBindings(args.components) as Array<Record<string, unknown>>;
      checkComponents(components);
      const surfaceId = `ui_${randomUUID().replaceAll("-", "").slice(0, 16)}`;
      await ctx.emit("ui.shown", {
        surface_id: surfaceId,
        messages: surfaceMessages(surfaceId, components, args.data),
      });
      return {
        content: `Showing the UI (${surfaceId}) to the person now. End your turn; their answer arrives as their next message.`,
        preview: "shown",
      };
    },
  });
}
