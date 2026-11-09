import { z } from "zod";
import type { ToolSpec } from "../gateway/types.ts";

export type Risk = "low" | "medium" | "high";

export interface ToolContext {
  runId: string;
  botId: string;
  orgId: string;
  /** Streams partial output (tool.output events). */
  output(chunk: string): Promise<void>;
  /** Emits an arbitrary run event (e.g. memory.written, skill.loaded). */
  emit(type: string, payload: Record<string, unknown>): Promise<void>;
  /** The bot's computer, started or restored on first use (tools that require a computer). */
  computer?: () => Promise<import("@kasama/sandbox").SandboxHandle>;
  /** Saves an undo point of the computer's home directory and records it on the timeline. */
  checkpoint?: (label: string) => Promise<{ checkpointId: string; label: string }>;
}

export interface ToolResult {
  /** Text the model sees. */
  content: string;
  /** Short preview for the timeline. */
  preview?: string;
  artifactPath?: string | null;
}

export interface ToolDefinition<S extends z.ZodType = z.ZodType> {
  name: string;
  description: string;
  schema: S;
  risk: Risk;
  requires?: { computer?: boolean; desktop?: boolean; vision?: boolean };
  /** Arguments that may carry {{secret:NAME}} placeholders (Phase 4). */
  acceptsSecrets?: boolean;
  execute(args: z.infer<S>, ctx: ToolContext): Promise<ToolResult>;
}

export class ToolError extends Error {
  readonly code: string;
  constructor(code: string, message: string) {
    super(message);
    this.code = code;
  }
}

/** One registry for every tool: schema, risk, capability needs and executor. */
export class ToolRegistry {
  private readonly tools = new Map<string, ToolDefinition>();

  register<S extends z.ZodType>(def: ToolDefinition<S>) {
    if (this.tools.has(def.name)) throw new Error(`tool ${def.name} already registered`);
    this.tools.set(def.name, def as unknown as ToolDefinition);
    return this;
  }

  get(name: string) {
    return this.tools.get(name);
  }

  /** Tools a bot may use given its capabilities. The model only ever sees these. */
  available(
    caps: { computer: boolean; desktop: boolean; vision: boolean },
    allow?: (name: string) => boolean,
  ) {
    return [...this.tools.values()].filter(
      (t) =>
        (!t.requires?.computer || caps.computer) &&
        (!t.requires?.desktop || caps.desktop) &&
        (!t.requires?.vision || caps.vision) &&
        (allow ? allow(t.name) : true),
    );
  }

  /** Provider tool names cannot contain dots; map memory.search <-> memory__search. */
  static wireName = (name: string) => name.replaceAll(".", "__");
  static fromWire = (name: string) => name.replaceAll("__", ".");

  specs(defs: ToolDefinition[]): ToolSpec[] {
    return defs.map((t) => ({
      name: ToolRegistry.wireName(t.name),
      description: t.description,
      inputSchema: z.toJSONSchema(t.schema, { target: "draft-7" }) as Record<string, unknown>,
    }));
  }

  /** Validates arguments; throws ToolError("invalid_arguments") with a readable message. */
  parse(name: string, args: unknown) {
    const def = this.tools.get(name);
    if (!def) throw new ToolError("unknown_tool", `Unknown tool ${name}`);
    const parsed = def.schema.safeParse(args);
    if (!parsed.success) {
      throw new ToolError(
        "invalid_arguments",
        parsed.error.issues.map((i) => `${i.path.join(".") || "(root)"}: ${i.message}`).join("; "),
      );
    }
    return { def, args: parsed.data };
  }
}
