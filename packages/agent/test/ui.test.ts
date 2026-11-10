import { describe, expect, it } from "vitest";
import { failureMessage, partsText } from "../src/run.ts";
import { ToolRegistry } from "../src/tools/registry.ts";
import {
  A2UI_BASIC_CATALOG,
  checkComponents,
  normalizeBindings,
  registerUiTools,
  surfaceMessages,
} from "../src/tools/ui.ts";

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

  it("describes shown UIs and the person's action to the model", () => {
    expect(
      partsText([
        { type: "text", text: "Pick one:" },
        { type: "ui", surface_id: "ui_1", messages: [] },
      ]),
    ).toContain("(You showed an interactive UI, ui_1.)");
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
