import { describe, expect, it } from "vitest";
import { registerDeviceTools } from "../src/device-data.ts";
import { registerKnowledgeTools } from "../src/knowledge.ts";
import { registerAutonomyTools } from "../src/tools/autonomy.ts";
import { builtinTools } from "../src/tools/builtin.ts";
import {
  CALL_PERSONA_CHARS,
  callPersona,
  geminiSchema,
  type RealtimeTool,
  SHOW_SCREEN_TOOL,
  START_TASK_TOOL,
  STOP_TASK_TOOL,
  VOICE_CALL_TOOL_SPECS,
  VOICE_CALL_TOOLS,
  voiceCallTools,
} from "../src/voice.ts";

/** Every built-in call tool declaration together may take this many characters of JSON. */
const MAX_DECLARATION_CHARS = 4_800;

// The real tools, as the worker registers them. Nothing here runs a tool, so no database is needed.
const db = {} as never;
const registry = builtinTools({ db, memory: async () => ({}) as never });
registerAutonomyTools(registry, { db } as never);
registerKnowledgeTools(registry, { db, embedderFor: async () => null });
registerDeviceTools(registry, { db });

type Schema = {
  type?: string;
  enum?: string[];
  properties?: Record<string, Schema>;
  required?: string[];
};

/** A real tool's arguments, in the form a call would have been sent before the short ones. */
const realSchema = (name: string): Schema => {
  const def = registry.get(name);
  if (!def) throw new Error(`${name} is not a registered tool`);
  return geminiSchema(registry.specs([def])[0]?.inputSchema) as Schema;
};

const declarations = (tools: RealtimeTool[]) =>
  tools.map((t) => ({
    name: t.name,
    description: t.description,
    parameters: geminiSchema(t.parameters),
  }));

describe("the tools a live call carries (docs/USAGE-PLAN.md step 6)", () => {
  it("stay within the size budget: every turn of a call is billed them again", () => {
    const sent = declarations([
      ...voiceCallTools([...VOICE_CALL_TOOLS]),
      START_TASK_TOOL,
      STOP_TASK_TOOL,
      SHOW_SCREEN_TOOL,
    ]);
    expect(sent).toHaveLength(VOICE_CALL_TOOLS.size + 3);
    expect(JSON.stringify(sent).length).toBeLessThanOrEqual(MAX_DECLARATION_CHARS);
  });

  it("are all real tools, sent under their wire names", () => {
    for (const name of VOICE_CALL_TOOLS) expect(registry.get(name), name).toBeTruthy();
    expect(voiceCallTools(["memory.search", "no.such_tool"]).map((t) => t.name)).toEqual([
      "memory__search",
    ]);
  });

  it("name only arguments the real tool takes, and every one it requires", () => {
    for (const [name, spec] of Object.entries(VOICE_CALL_TOOL_SPECS)) {
      const real = realSchema(name);
      const short = spec.parameters as Schema;
      // Already in Gemini's subset, so what's measured is what's sent.
      expect(geminiSchema(short), name).toEqual(short);
      for (const [arg, s] of Object.entries(short.properties ?? {})) {
        const r = real.properties?.[arg];
        expect(r, `${name}.${arg} is not an argument of the real tool`).toBeTruthy();
        expect(s.type, `${name}.${arg} type`).toBe(r?.type);
        // A short list of choices may leave some out, never add one.
        for (const v of s.enum ?? [])
          expect(r?.enum, `${name}.${arg} value ${v}`).toEqual(expect.arrayContaining([v]));
      }
      expect([...(short.required ?? [])].sort(), `${name} required`).toEqual(
        [...(real.required ?? [])].sort(),
      );
    }
  });

  it("produce calls the real tools accept", () => {
    const at = new Date(Date.now() + 86_400_000).toISOString();
    const spoken: Record<string, Record<string, unknown>> = {
      "memory.search": { query: "plants" },
      "memory.write": { content: "Prefers short replies.", about: "person" },
      "knowledge.search": { query: "refund policy" },
      "web.search": { query: "weather tomorrow" },
      "web.fetch": { url: "https://example.com/opening-hours" },
      "notify.user": { title: "Done", message: "The report is ready" },
      "routines.list": {},
      "routines.create": { name: "Call mum", instructions: "Remind me to call mum", run_at: at },
      "tasks.list": { status: "todo", mine: true },
      "tasks.create": { title: "Fix the invoice", details: "Wrong VAT", assignee: "Ava" },
      "usage.report": { period: "week" },
      "device.read": { kind: "calendar", from: new Date().toISOString(), to: at },
    };
    expect(Object.keys(spoken).sort()).toEqual([...VOICE_CALL_TOOLS].sort());
    for (const [name, args] of Object.entries(spoken)) {
      const short = VOICE_CALL_TOOL_SPECS[name]?.parameters as Schema | undefined;
      const known = Object.keys(short?.properties ?? {});
      expect(known, name).toEqual(expect.arrayContaining(Object.keys(args)));
      expect(() => registry.parse(name, args), name).not.toThrow();
    }
    // The three ways to say when, as a call would send them.
    for (const when of [{ in_minutes: 20 }, { run_at: at }, { schedule_cron: "0 8 * * 1-5" }])
      expect(() =>
        registry.parse("routines.create", { name: "Reminder", instructions: "Stand up", ...when }),
      ).not.toThrow();
  });

  it("leave routine changes and watching to start_task", () => {
    for (const name of ["routines.update", "routines.delete", "watchers.create", "watchers.list"])
      expect(VOICE_CALL_TOOLS.has(name), name).toBe(false);
    for (const name of ["routines.create", "routines.list", "device.read", "memory.search"])
      expect(VOICE_CALL_TOOLS.has(name), name).toBe(true);
  });
});

describe("the persona a call carries", () => {
  it("is the whole persona when it's short", () => {
    expect(callPersona("You love plants.")).toBe("You love plants.");
    expect(callPersona("")).toBe("");
    const exact = "x".repeat(CALL_PERSONA_CHARS);
    expect(callPersona(exact)).toBe(exact);
  });

  it("is cut at the last sentence end near the limit", () => {
    const start = `${"a".repeat(1_390)}. Second sentence here. Third one`;
    const cut = callPersona(`${start}${" and it goes on".repeat(40)}`);
    expect(cut).toBe(`${"a".repeat(1_390)}. Second sentence here.`);
    expect(cut.length).toBeLessThanOrEqual(CALL_PERSONA_CHARS);
  });

  it("is cut at a line end when that is the last break", () => {
    const cut = callPersona(`${"a".repeat(1_400)}\n${"b".repeat(600)}`);
    expect(cut).toBe("a".repeat(1_400));
    // Also when the line ends right where the last 200 characters begin.
    expect(callPersona(`${"a".repeat(1_300)}\n${"b".repeat(600)}`)).toBe("a".repeat(1_300));
  });

  it("keeps a sentence that ends exactly at the limit", () => {
    const full = `${"a".repeat(CALL_PERSONA_CHARS - 1)}. More after it.`;
    expect(callPersona(full)).toBe(`${"a".repeat(CALL_PERSONA_CHARS - 1)}.`);
  });

  it("is cut hard when there's no break in the last 200 characters", () => {
    // A sentence end earlier than that doesn't count: too much would be lost.
    const cut = callPersona(`Short. ${"a".repeat(3_000)}`);
    expect(cut.length).toBe(CALL_PERSONA_CHARS);
    // Never half of an emoji.
    const emoji = callPersona(`${"a".repeat(CALL_PERSONA_CHARS - 1)}😀${"a".repeat(50)}`);
    expect(emoji).toBe("a".repeat(CALL_PERSONA_CHARS - 1));
  });
});
