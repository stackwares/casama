import { describe, expect, it } from "vitest";
import { z } from "zod";
import { argumentsHint, ToolError, ToolRegistry } from "../src/tools/registry.ts";

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
