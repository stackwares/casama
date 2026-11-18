import { describe, expect, it } from "vitest";
import { z } from "zod";
import { argumentsHint, leanSchema, ToolError, ToolRegistry } from "../src/tools/registry.ts";

describe("tool argument errors say what the call needs", () => {
  const registry = new ToolRegistry();
  registry.register({
    name: "shell.exec",
    description: "Run a command.",
    risk: "low",
    schema: z.object({
      command: z.string().min(1),
      timeout_s: z.number().int().optional(),
      mode: z.enum(["a", "b"]).optional(),
    }),
    async execute() {
      return { content: "ok" };
    },
  });

  it("lists the arguments, marking the required ones", () => {
    expect(argumentsHint(registry.get("shell.exec")!)).toBe(
      '{"command": string (required), "timeout_s": integer, "mode": "a"|"b"}',
    );
  });

  it("an empty call is told to try again with them filled in", () => {
    try {
      registry.parse("shell.exec", {});
      expect.unreachable();
    } catch (e) {
      expect(e).toBeInstanceOf(ToolError);
      expect((e as Error).message).toContain("command: Invalid input");
      expect((e as Error).message).toContain('shell.exec takes {"command": string (required)');
      expect((e as Error).message).toContain("call it again with them filled in");
    }
  });
});

describe("the schema a model is sent", () => {
  const Args = z.object({
    title: z.string().min(1).max(80).describe("Short"),
    // An argument that happens to be called like a schema keyword stays.
    maxLength: z.number().int().optional(),
    tags: z.array(z.string().max(20)).min(1).max(5),
    extra: z.record(z.string(), z.unknown()).optional(),
  });
  const registry = new ToolRegistry();
  const tool = { description: "A tool.", risk: "low" as const, schema: Args };
  const execute = async () => ({ content: "ok" });
  registry.register({ ...tool, name: "plain.tool", execute });
  registry.register({ ...tool, name: "lean.tool", jsonSchema: leanSchema(Args), execute });
  const sent = (name: string) => registry.specs([registry.get(name)!])[0]?.inputSchema;

  it("never carries the $schema line", () => {
    expect(sent("plain.tool")).not.toHaveProperty("$schema");
    expect(sent("plain.tool")).toMatchObject({
      type: "object",
      properties: { title: { type: "string", minLength: 1, maxLength: 80, description: "Short" } },
      required: ["title", "tags"],
    });
  });

  it("leaves string lengths out of a lean one, and keeps the rest", () => {
    expect(sent("lean.tool")).toEqual({
      type: "object",
      properties: {
        title: { type: "string", description: "Short" },
        maxLength: { type: "integer", minimum: -9007199254740991, maximum: 9007199254740991 },
        tags: { type: "array", minItems: 1, maxItems: 5, items: { type: "string" } },
        extra: { type: "object", additionalProperties: {} },
      },
      required: ["title", "tags"],
      additionalProperties: false,
    });
  });

  it("still checks what a lean schema doesn't say", () => {
    expect(() => registry.parse("lean.tool", { title: "x".repeat(81), tags: ["a"] })).toThrow(
      /title: Too big/,
    );
    expect(argumentsHint(registry.get("lean.tool")!)).toBe(
      '{"title": string (required), "maxLength": integer, "tags": array (required), "extra": object}',
    );
  });
});
