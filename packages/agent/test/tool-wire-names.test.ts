import { describe, expect, it } from "vitest";
import { z } from "zod";
import { toModelMessages } from "../src/gateway/ai-sdk.ts";
import { toResponsesInput } from "../src/gateway/chatgpt.ts";
import type { ChatMessage } from "../src/gateway/types.ts";
import { ToolRegistry } from "../src/tools/registry.ts";

// Tool definitions go out as wire names (media__image__generate). History must match, or providers
// that allow at most one dot in a name (Google behind OpenRouter) reject the next call with a 400.
const history: ChatMessage[] = [
  { role: "user", content: "draw a dog" },
  {
    role: "assistant",
    content: "",
    toolCalls: [{ callId: "c1", name: "media.image.generate", args: { prompt: "dog" } }],
  },
  { role: "tool", callId: "c1", name: "media.image.generate", content: "media/dog.jpg" },
];

describe("tool names in history", () => {
  it("uses wire names in AI SDK messages", () => {
    const [, call, result] = toModelMessages(history);
    expect(JSON.stringify(call)).toContain('"toolName":"media__image__generate"');
    expect(JSON.stringify(result)).toContain('"toolName":"media__image__generate"');
    expect(JSON.stringify([call, result])).not.toContain("media.image.generate");
  });

  it("uses wire names in ChatGPT Responses input", () => {
    const input = toResponsesInput(history);
    expect(input.find((i) => i.type === "function_call")?.name).toBe("media__image__generate");
  });
});

const reg = (...names: string[]) => {
  const r = new ToolRegistry();
  for (const name of names)
    r.register({
      name,
      description: name,
      risk: "low",
      schema: z.object({ count: z.number().int().optional(), deep: z.boolean().optional() }),
      async execute() {
        return { content: "ok" };
      },
    });
  return r;
};

describe("wire names", () => {
  const long = `composio.apps.${"salesforce_create_opportunity_with_line_items_and_".repeat(2)}x`;

  it("keeps provider names within 64 characters, stable and distinct", () => {
    const w = ToolRegistry.wireName(long);
    expect(w.length).toBe(64);
    expect(w).toMatch(/^[a-zA-Z0-9_-]+$/);
    expect(ToolRegistry.wireName(long)).toBe(w);
    expect(ToolRegistry.wireName(`${long}y`)).not.toBe(w);
    expect(ToolRegistry.wireName("memory.search")).toBe("memory__search");
  });

  it("maps provider names back to the registered tool", () => {
    const r = reg(long, "mcp.notion.get__page", "memory.search");
    expect(r.resolveWire(ToolRegistry.wireName(long))).toBe(long);
    expect(r.resolveWire("mcp__notion__get__page")).toBe("mcp.notion.get__page");
    expect(r.resolveWire("memory__search")).toBe("memory.search");
    expect(r.resolveWire("unknown__tool")).toBe("unknown.tool");
  });

  it("accepts numbers and booleans sent as strings", () => {
    const r = reg("web.search");
    expect(r.parse("web.search", { count: "10.0", deep: "true" }).args).toEqual({
      count: 10,
      deep: true,
    });
    expect(() => r.parse("web.search", { count: "ten" })).toThrow(/expected number/);
  });
});
