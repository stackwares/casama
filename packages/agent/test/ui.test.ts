import { needsApproval } from "@casama/domain";
import { describe, expect, it } from "vitest";
import { failureMessage, partsText } from "../src/run.ts";
import { ToolError, ToolRegistry } from "../src/tools/registry.ts";
import {
  A2UI_BASIC_CATALOG,
  checkComponents,
  ensureSubmit,
  ensureWayOut,
  normalizeBindings,
  registerUiTools,
  surfaceMessages,
  UI_COMPONENTS,
} from "../src/tools/ui.ts";
import { uiCatalog, uiCatalogAll } from "../src/tools/ui-catalog.ts";

const plan = [
  { id: "root", component: "Column", children: ["title", "basic", "pro"] },
  { id: "title", component: "Text", text: "## Which plan?" },
  {
    id: "basic",
    component: "Button",
    child: "basicLabel",
    action: { event: { name: "choose", context: { plan: "basic" } } },
  },
  { id: "basicLabel", component: "Text", text: "Basic" },
  {
    id: "pro",
    component: "Button",
    variant: "primary",
    child: "proLabel",
    action: { event: { name: "choose", context: { plan: "pro" } } },
  },
  { id: "proLabel", component: "Text", text: "Pro" },
];

describe("ui.show (D-086)", () => {
  it("wraps components in A2UI v1.0 messages for one surface", () => {
    const msgs = surfaceMessages("ui_1", plan, { form: { note: "" } });
    expect(msgs[0]).toEqual({
      version: "1.0",
      createSurface: { surfaceId: "ui_1", catalogId: A2UI_BASIC_CATALOG },
    });
    expect(msgs[1]).toEqual({
      version: "1.0",
      updateDataModel: { surfaceId: "ui_1", path: "/", value: { form: { note: "" } } },
    });
    expect(msgs[2]).toEqual({
      version: "1.0",
      updateComponents: { surfaceId: "ui_1", components: plan },
    });
    expect(surfaceMessages("ui_2", plan)).toHaveLength(2);
  });

  it("turns v0.9 path bindings into v1.0 @path bindings", () => {
    expect(
      normalizeBindings([
        {
          id: "f",
          value: { path: "/form/x" },
          action: { event: { name: "go", context: { x: { path: "/form/x" } } } },
        },
      ]),
    ).toEqual([
      {
        id: "f",
        value: { "@path": "/form/x" },
        action: { event: { name: "go", context: { x: { "@path": "/form/x" } } } },
      },
    ]);
  });

  it("rejects trees without a root, with duplicate ids, or with missing children", () => {
    expect(() => checkComponents(plan)).not.toThrow();
    expect(() => checkComponents(plan.slice(1))).toThrow(/root/);
    expect(() => checkComponents([...plan, plan[1] as Record<string, unknown>])).toThrow(
      /Two components/,
    );
    expect(() => checkComponents([{ id: "root", component: "Card", child: "missing" }])).toThrow(
      /missing/,
    );
  });

  it("takes a Map with real coordinates and says what's wrong otherwise (D-310)", () => {
    const sf = { lat: 37.7749, lng: -122.4194 };
    const ok = [
      { id: "root", component: "Column", children: ["map"] },
      { id: "map", component: "Map", center: sf, zoom: 12, markers: [{ ...sf, label: "SF" }] },
    ];
    expect(() => checkComponents(ok)).not.toThrow();
    // A map is display only: no Send or Skip is added to it.
    expect(ensureWayOut(ensureSubmit(ok))).toEqual(ok);
    expect(() =>
      checkComponents([{ id: "root", component: "Map", markers: [sf, { lat: "37", lng: 1 }] }]),
    ).toThrow(/marker 2/);
    expect(() =>
      checkComponents([{ id: "root", component: "Map", center: { lat: 120, lng: 0 } }]),
    ).toThrow(/center/);
    expect(() => checkComponents([{ id: "root", component: "Map" }])).toThrow(
      /center, markers or a path/,
    );
  });

  it("never waits for approval, even when a bot asks before everything", () => {
    const registry = new ToolRegistry();
    registerUiTools(registry);
    const def = registry.parse("ui.show", { components: plan }).def;
    expect(def.readOnly).toBe(true);
    expect(
      needsApproval({
        autonomy: "ask_always",
        risk: def.risk,
        readOnly: def.readOnly === true,
        granted: false,
        untrustedSinceApproval: false,
      }),
    ).toBe(false);
  });

  it("emits ui.shown and tells the model to end its turn", async () => {
    const registry = new ToolRegistry();
    registerUiTools(registry);
    const events: Array<[string, Record<string, unknown>]> = [];
    const { def, args } = registry.parse("ui.show", { components: plan });
    const result = await def.execute(args, {
      runId: "r1",
      botId: "b1",
      orgId: "o1",
      output: () => {},
      emit: async (type: string, payload: Record<string, unknown>) => {
        events.push([type, payload]);
      },
    } as never);
    expect(events[0]?.[0]).toBe("ui.shown");
    const payload = events[0]?.[1] as { surface_id: string; messages: unknown[] };
    expect(payload.surface_id).toMatch(/^ui_/);
    expect(payload.messages).toHaveLength(2);
    expect(result.content).toContain("End your turn");
  });

  it("gives the model an accepted suggestion's action, which the person never sees as text", () => {
    const out = partsText([
      { type: "text", text: "Please do this now: Block travel time" },
      { type: "suggested_action", action: { tool: "calendar_create_event", args: { m: 45 } } },
    ]);
    expect(out).toContain("Please do this now: Block travel time");
    expect(out).toContain('"tool":"calendar_create_event"');
  });

  it("describes shown UIs and the person's action to the model", () => {
    expect(
      partsText([
        { type: "text", text: "Pick one:" },
        { type: "ui", surface_id: "ui_1", messages: [] },
      ]),
    ).toContain("(You showed an interactive UI, ui_1.)");
    const picker = [
      { id: "root", component: "Column", children: ["q"] },
      {
        id: "q",
        component: "ChoicePicker",
        label: "Want me to take one of these?",
        options: [
          { label: "Diagnose the failing CI", value: "ci" },
          { label: "Check PR #16", value: "pr" },
        ],
        value: { "@path": "/form/task" },
      },
    ];
    expect(
      partsText([{ type: "ui", surface_id: "ui_2", messages: surfaceMessages("ui_2", picker) }]),
    ).toContain(
      "(You showed an interactive UI, ui_2: Want me to take one of these? A) Diagnose the failing CI, B) Check PR #16.)",
    );
    const answer = partsText([
      { type: "text", text: "plan: pro" },
      { type: "ui_action", surface_id: "ui_1", name: "choose", context: { plan: "pro" } },
    ]);
    expect(answer).toContain('On your UI ui_1 I chose "choose" with: {"plan":"pro"}');
  });

  it("explains failures without leaking keys", () => {
    expect(failureMessage("model_auth_failed", "401 bad key sk-or-v1-abcdefghijklmnop")).toBe(
      "The model provider rejected the key. Check it in Settings → Model keys.",
    );
    const m = failureMessage(
      "run_error",
      "fetch failed: Bearer abc.def-123 for sk-live-1234567890abcd\nstack...",
    );
    expect(m).toContain("Something went wrong");
    expect(m).not.toContain("abc.def-123");
    expect(m).not.toContain("1234567890abcd");
    expect(m).not.toContain("stack");
  });
});

describe("ui.show cards always have a way to answer", () => {
  const picker = {
    id: "pick",
    component: "ChoicePicker",
    options: [{ label: "Web research", value: "web" }],
    value: { "@path": "/form/tools" },
    variant: "multipleSelection",
  };

  it("adds a Send button carrying the inputs when a card has none", () => {
    const shown = ensureSubmit([
      { id: "root", component: "Column", children: ["q", "pick"] },
      { id: "q", component: "Text", text: "## Which tools?" },
      picker,
    ]);
    expect(() => checkComponents(shown)).not.toThrow();
    const root = shown.find((c) => c.id === "root") as { children: string[] };
    const send = shown.find((c) => c.component === "Button") as { id: string; action: unknown };
    expect(root.children.at(-1)).toBe(send.id);
    expect(send.action).toEqual({
      event: { name: "submit", context: { tools: { "@path": "/form/tools" } } },
    });
  });

  it("puts any other root under a column with the button", () => {
    const shown = ensureSubmit([{ id: "root", component: "Card", child: "pick" }, picker]);
    expect(() => checkComponents(shown)).not.toThrow();
    expect(shown.find((c) => c.id === "root")).toMatchObject({ component: "Column" });
    expect(shown.some((c) => c.component === "Card" && c.child === "pick")).toBe(true);
  });

  it("leaves cards alone that can already be answered, or have nothing to send", () => {
    const withButton = [
      { id: "root", component: "Column", children: ["pick", "go"] },
      picker,
      {
        id: "go",
        component: "Button",
        child: "go_t",
        action: { event: { name: "save", context: { tools: { "@path": "/form/tools" } } } },
      },
      { id: "go_t", component: "Text", text: "Save" },
    ];
    expect(ensureSubmit(withButton)).toBe(withButton);
    const plain = [{ id: "root", component: "Text", text: "Done." }];
    expect(ensureSubmit(plain)).toBe(plain);
  });
});

describe("ensureWayOut", () => {
  const field = {
    id: "in",
    component: "TextField",
    label: "Task",
    value: { "@path": "/form/text" },
  };
  const go = {
    id: "go",
    component: "Button",
    child: "go_t",
    variant: "primary",
    action: { event: { name: "go", context: { text: { "@path": "/form/text" } } } },
  };
  const goText = { id: "go_t", component: "Text", text: "Go" };

  it("puts a Skip beside a lone button in a column", () => {
    const shown = ensureWayOut([
      { id: "root", component: "Column", children: ["in", "go"] },
      field,
      go,
      goText,
    ]);
    expect(() => checkComponents(shown)).not.toThrow();
    const root = shown.find((c) => c.id === "root") as { children: string[] };
    const row = shown.find((c) => c.id === root.children[1]) as {
      component: string;
      children: string[];
    };
    expect(row.component).toBe("Row");
    expect(row.children[0]).toBe("go");
    const skip = shown.find((c) => c.id === row.children[1]);
    expect(skip).toMatchObject({ component: "Button", action: { event: { name: "skip" } } });
  });

  it("adds Skip after a lone button already in a row", () => {
    const shown = ensureWayOut([
      { id: "root", component: "Column", children: ["in", "row"] },
      { id: "row", component: "Row", children: ["go"] },
      field,
      go,
      goText,
      { id: "skip", component: "Text", text: "taken" },
    ]);
    expect(() => checkComponents(shown)).not.toThrow();
    expect(shown.find((c) => c.id === "row")).toMatchObject({ children: ["go", "skip_2"] });
  });

  it("leaves cards with two or more buttons, or none, alone", () => {
    const two = [
      { id: "root", component: "Row", children: ["go", "no"] },
      go,
      goText,
      { ...go, id: "no", child: "no_t" },
      { id: "no_t", component: "Text", text: "No" },
    ];
    expect(ensureWayOut(two)).toBe(two);
    const none = [{ id: "root", component: "Text", text: "Done." }];
    expect(ensureWayOut(none)).toBe(none);
  });

  it("gives the Send that ensureSubmit adds a Skip too", () => {
    const shown = ensureWayOut(
      ensureSubmit([{ id: "root", component: "Column", children: ["in"] }, field]),
    );
    expect(() => checkComponents(shown)).not.toThrow();
    expect(shown.filter((c) => c.component === "Button")).toHaveLength(2);
  });
});

describe("ui.show media and checks (D-322)", () => {
  const name = { "@call": "required", args: { value: { "@path": "/form/name" } } };
  const form = (extra: Record<string, unknown>) => [
    { id: "root", component: "Column", children: ["name", "go"] },
    { id: "name", component: "TextField", label: "Name", value: { "@path": "/form/name" } },
    {
      id: "go",
      component: "Button",
      child: "go_t",
      action: { event: { name: "submit", context: { name: { "@path": "/form/name" } } } },
      ...extra,
    },
    { id: "go_t", component: "Text", text: "Send" },
  ];

  it("takes Video and AudioPlayer with an http(s) media url", () => {
    const ok = [
      { id: "root", component: "Column", children: ["v", "a"] },
      {
        id: "v",
        component: "Video",
        url: "https://example.com/clip.mp4",
        posterUrl: "https://example.com/p.jpg",
      },
      {
        id: "a",
        component: "AudioPlayer",
        url: "https://example.com/song.mp3",
        description: "Demo",
      },
    ];
    expect(() => checkComponents(ok)).not.toThrow();
    // Media is display only: no Send or Skip is added.
    expect(ensureWayOut(ensureSubmit(ok))).toEqual(ok);
    expect(() =>
      checkComponents([{ id: "root", component: "Video", url: "file:///etc/hosts" }]),
    ).toThrow(/https link to the media file/);
    expect(() => checkComponents([{ id: "root", component: "AudioPlayer" }])).toThrow(
      /needs a url/,
    );
  });

  it("accepts checks built from the basic catalog's functions", () => {
    const value = { "@path": "/form/name" };
    const checks = [
      { condition: name, message: "Add your name" },
      {
        condition: {
          "@call": "and",
          args: {
            values: [
              { "@call": "length", args: { value, max: 40 } },
              {
                "@call": "not",
                args: { value: { "@call": "regex", args: { value, pattern: "^\\d+$" } } },
              },
            ],
          },
        },
        message: "A name, not a number",
      },
      { condition: { "@path": "/form/agree" } },
    ];
    expect(() => checkComponents(form({ checks }))).not.toThrow();
  });

  it("says what to fix in a check it can't use", () => {
    const one = (condition: unknown) => form({ checks: [{ condition, message: "x" }] });
    expect(() => checkComponents(form({ checks: { condition: name } }))).toThrow(/must be a list/);
    expect(() => checkComponents(one({ "@call": "isFilled", args: {} }))).toThrow(
      /required, email, length/,
    );
    expect(() => checkComponents(one({ "@call": "regex", args: { value: "a" } }))).toThrow(
      /regex needs args.pattern/,
    );
    expect(() => checkComponents(one({ "@call": "length", args: { value: "a" } }))).toThrow(
      /needs args.min or args.max/,
    );
    expect(() => checkComponents(one({ "@call": "or", args: { values: [name] } }))).toThrow(
      /2 or more/,
    );
    expect(() =>
      checkComponents(one({ "@call": "not", args: { value: { "@call": "nope" } } })),
    ).toThrow(/not: the condition/);
  });

  it("turns v0.9 call into v1.0 @call", () => {
    expect(
      normalizeBindings({
        condition: { call: "required", args: { value: { path: "/form/name" } } },
      }),
    ).toEqual({ condition: name });
  });

  it("puts the inputs' checks on the Send button it adds", () => {
    const check = { condition: name, message: "Add your name" };
    const shown = ensureSubmit([
      { id: "root", component: "Column", children: ["name"] },
      {
        id: "name",
        component: "TextField",
        label: "Name",
        value: { "@path": "/form/name" },
        checks: [check],
      },
    ]);
    expect(shown.find((c) => c.id === "send")).toMatchObject({ checks: [check] });
    expect(() => checkComponents(shown)).not.toThrow();
  });

  it("tells the bot about secrets, and where media and checks are described", () => {
    const registry = new ToolRegistry();
    registerUiTools(registry);
    const { description } = registry.parse("ui.show", { components: plan }).def;
    expect(description).toContain("secrets.request");
    expect(description).toContain("ui.catalog");
    const all = uiCatalogAll();
    expect(all).toContain("Video: {url, posterUrl?}");
    expect(all).toContain('"@call": "required"');
    expect(all).toContain("secrets.request");
  });
});

describe("ui.catalog (USAGE-PLAN step 4)", () => {
  const registry = new ToolRegistry();
  registerUiTools(registry);
  const read = async (args: Record<string, unknown>) => {
    const parsed = registry.parse("ui.catalog", args);
    return (await parsed.def.execute(parsed.args, {} as never)).content;
  };

  // ui.show's own description is all a bot has read before its first card: a UI built from every
  // component it describes, with its two JSON examples as written, must go through.
  it("shows a UI built from ui.show's short description alone", async () => {
    const { def, args } = registry.parse("ui.show", {
      components: [
        { id: "root", component: "Card", child: "col" },
        { id: "col", component: "Column", children: ["h", "pic", "line", "plan", "list", "go"] },
        { id: "h", component: "Text", text: "## Pick a plan", variant: "body" },
        { id: "pic", component: "Image", url: "https://example.com/plans.png" },
        { id: "line", component: "Divider" },
        {
          id: "plan",
          component: "ChoicePicker",
          label: "Which plan?",
          options: [
            { label: "Basic", value: "basic" },
            { label: "Pro", value: "pro" },
          ],
          value: { "@path": "/form/plan" },
          variant: "multipleSelection",
          displayStyle: "chips",
        },
        { id: "list", component: "List", children: ["note", "agree", "seats", "when"] },
        {
          id: "note",
          component: "TextField",
          label: "Note",
          value: { "@path": "/form/note" },
          placeholder: "Anything else?",
          variant: "longText",
        },
        { id: "agree", component: "CheckBox", label: "I agree", value: { "@path": "/form/agree" } },
        {
          id: "seats",
          component: "Slider",
          label: "Seats",
          min: 1,
          max: 10,
          value: { "@path": "/form/seats" },
        },
        {
          id: "when",
          component: "DateTimeInput",
          label: "Start",
          value: { "@path": "/form/when" },
          enableDate: true,
        },
        { id: "go", component: "Row", children: ["send"], justify: "end" },
        {
          id: "send",
          component: "Button",
          child: "send_t",
          variant: "primary",
          action: { event: { name: "submit", context: { plan: { "@path": "/form/plan" } } } },
        },
        { id: "send_t", component: "Text", text: "Continue" },
      ],
      data: { form: { plan: ["pro"] } },
    });
    const events: Array<[string, Record<string, unknown>]> = [];
    const result = await def.execute(args, {
      emit: async (type: string, payload: Record<string, unknown>) => {
        events.push([type, payload]);
      },
    } as never);
    expect(result.content).toContain("End your turn");
    expect(events.map(([type]) => type)).toEqual(["ui.shown"]);
    // Its description still carries both examples and names every component used above.
    for (const said of [
      '{"@path": "/form/plan"}',
      '{"event": {"name": "submit", "context": {"plan": {"@path": "/form/plan"}}}}',
      'The one with id "root" is the top',
      ...["Text", "Column", "Row", "Card", "List", "Divider", "Image", "Button"],
      ...["ChoicePicker", "TextField", "CheckBox", "Slider", "DateTimeInput"],
    ])
      expect(def.description, said).toContain(said);
  });

  it("is a read that never waits for approval", () => {
    const def = registry.parse("ui.catalog", {}).def;
    expect(def.readOnly).toBe(true);
    expect(def.risk).toBe("low");
  });

  it("describes every component of the catalog when asked for all", async () => {
    const all = await read({});
    for (const name of UI_COMPONENTS) expect(all, name).toContain(`- ${name}: `);
    expect(all).toBe(uiCatalogAll());
  });

  // What ui.show's own description said before it was cut down: the catalog must still say it.
  it("keeps what the long ui.show description said", () => {
    const all = uiCatalogAll();
    for (const said of [
      'the one with id "root" is the top',
      'Start text with "## " for a heading',
      'justify?: "start"|"center"|"end"|"spaceBetween"',
      'direction?: "vertical"|"horizontal"',
      "{tabs: [{title, child: id}]}",
      'variant?: "shortText"|"longText"|"number"',
      'displayStyle?: "chips"|"checkbox"',
      "enableDate?: true, enableTime?: true",
      '"check", "info", "event", "mail"',
      "not a page like YouTube or Spotify",
      "zoom?: 1-18 (12 is a city, 15 a neighbourhood, 17 a street)",
      "never open a browser or build a page for it",
      'Tapping Send reaches you as "draft.send"',
      "unless they said to send it straight away",
      "older apps skip cards they don't know",
      'Add to calendar ("event.add"',
      "A day or week of events, display only",
      'sends "message.reply" {id, from, subject}',
      '"checklist.save" {done: [ids], undone: [ids]}',
      'chart?: {type: "line"|"bar"',
      '"result.choose" {id, title}',
      '"person.pick" {people: [...]} or "person.none"',
      'Cancel it ("schedule.cancel" {ref})',
      "a booking, an order, a receipt, a summary",
      'bind with {"@path": "/form/x"} (note the @)',
      "not a Button per option",
      'add a borderless "Skip" or "Not now"',
      "required {value}, email {value}, length {value, min?, max?}",
      "end your turn: the person's choice arrives as their next message",
      "(A or 1 is the first)",
    ])
      expect(all, said).toContain(said);
  });

  it("answers for one component with the notes that apply to it", async () => {
    const map = await read({ component: "Map" });
    expect(map).toContain("- Map: {center?: {lat, lng}");
    expect(map).toContain("older apps skip cards");
    expect(map).not.toContain("- Event:");
    expect(map).not.toContain("Checks:");
    expect(map.length).toBeLessThan(uiCatalogAll().length / 4);
    const field = await read({ component: "TextField" });
    expect(field).toContain('bind with {"@path": "/form/x"}');
    expect(field).toContain('"@call": "required"');
  });

  it("takes several names in any case, and checks", async () => {
    const two = await read({ component: "event, AGENDA" });
    expect(two).toContain("- Event: ");
    expect(two).toContain("- Agenda: ");
    expect(two).not.toContain("- Map: ");
    expect(uiCatalog("Event, Agenda").preview).toBe("Event, Agenda");
    const checks = await read({ component: "checks" });
    expect(checks).toMatch(/^Checks: a Button takes checks/);
    expect(checks).not.toContain("- Text: ");
  });

  it("gives the whole catalog when no name is one it has", async () => {
    const table = await read({ component: "Table" });
    expect(table).toMatch(/^The catalog has no "Table"; its components are Text, Row, /);
    expect(table).toContain(uiCatalogAll());
    // One name right and one wrong: the right one, and what the names are.
    const mixed = await read({ component: "the Map card, Agnda" });
    expect(mixed).toMatch(/^The catalog has no "Agnda"; its components are Text, Row, /);
    expect(mixed).toContain("- Map: ");
    expect(mixed).not.toContain("- Text: ");
  });

  it("tells a refused ui.show where to read that component's properties", async () => {
    const refused = (components: Array<Record<string, unknown>>) => {
      try {
        checkComponents(components);
      } catch (err) {
        expect(err).toBeInstanceOf(ToolError);
        return (err as ToolError).message;
      }
      throw new Error("not refused");
    };
    // The check's own words stay, and the hint comes after them.
    expect(refused([{ id: "root", component: "Map" }])).toBe(
      'Map "root" needs a center, markers or a path. Call ui.catalog with component "Map" for its properties.',
    );
    expect(refused([{ id: "root", component: "Event", title: "Review" }])).toMatch(
      /needs start\. Call ui\.catalog with component "Event"/,
    );
    expect(
      refused([
        { id: "root", component: "Button", child: "t", action: { event: { name: "draft.send" } } },
        { id: "t", component: "Text", text: "Send" },
      ]),
    ).toMatch(/Show it as a MessageDraft instead\. Call ui\.catalog with component "MessageDraft"/);
    expect(
      refused([
        { id: "root", component: "Button", child: "t", checks: [{ condition: { "@call": "x" } }] },
        { id: "t", component: "Text", text: "Send" },
      ]),
    ).toMatch(/ui\.catalog with component "checks" describes checks\.$/);
    // Nothing to look up when the tree itself is wrong.
    expect(refused(plan.slice(1))).toBe('One component must have the id "root".');
    expect(refused([{ id: "root", component: "Card", child: "missing" }])).not.toContain(
      "ui.catalog",
    );
  });

  it("names the catalog and ui.catalog when a component isn't one", () => {
    expect(() =>
      registry.parse("ui.show", { components: [{ id: "root", component: "Table" }] }),
    ).toThrow(
      /components\.0\.component: "Table" isn't in the catalog\. Its components are Text, Row, .*Details; call ui\.catalog for their properties\./,
    );
    expect(() => registry.parse("ui.show", { components: [{ id: "root" }] })).toThrow(
      /Each component needs a component name/,
    );
  });

  it("sends the model its arguments without the draft line or string lengths", () => {
    const [show] = registry.specs([registry.parse("ui.show", { components: plan }).def]);
    const schema = JSON.stringify(show?.inputSchema);
    expect(schema).not.toContain("$schema");
    expect(schema).not.toContain("maxLength");
    // What shapes a call stays: the list's size, the component names, and free-form properties.
    expect(schema).toContain('"maxItems":60');
    expect(schema).toContain('"enum":["Text","Row"');
    expect(schema).toContain('"required":["id","component"],"additionalProperties":{}');
    // The server still checks what the model isn't told.
    expect(() =>
      registry.parse("ui.show", { components: [{ id: "x".repeat(61), component: "Text" }] }),
    ).toThrow(/components\.0\.id/);
  });
});
