import { z } from "zod";
import type { ToolSpec } from "../gateway/types.ts";

export type Risk = "low" | "medium" | "high";

export interface ToolContext {
  runId: string;
  botId: string;
  orgId: string;
  /** The person this run acts for, when there is one (About you, D-169). */
  actingUserId?: string | null;
  /** Streams partial output (tool.output events). */
  output(chunk: string): Promise<void>;
  /** Emits an arbitrary run event (e.g. memory.written, skill.loaded). */
  emit(type: string, payload: Record<string, unknown>): Promise<void>;
  /** The bot's computer, started or restored on first use (tools that require a computer). */
  computer?: () => Promise<import("@casama/sandbox").SandboxHandle>;
  /** Saves an undo point of the computer's home directory and records it on the timeline. */
  checkpoint?: (label: string) => Promise<{ checkpointId: string; label: string }>;
  /** Sleeps and wakes the bot's computer: a fresh system with the same files (D-240). */
  restartComputer?: () => Promise<void>;
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
  /** Arguments may carry {{secret:NAME}} placeholders, swapped in only for allowed hosts. */
  acceptsSecrets?: boolean;
  /** Stores {{secret:NAME}} placeholders as written (skill text); they're never filled in here. */
  keepsPlaceholders?: boolean;
  /** Where the call sends data, for secret host allowlists (may ask the computer, e.g. the browser's page). */
  destinationHost?: (args: z.infer<S>, ctx: ToolContext) => Promise<string | null> | string | null;
  /** No side effects: never needs approval. */
  readOnly?: boolean;
  /**
   * Only changes the bot's own state inside Casama (notes, schedule, board tasks, messages and cards
   * for the person): never asks, even for bots that ask before everything (D-155). Anything that
   * reaches outside Casama or costs money must not set this.
   */
  selfOnly?: boolean;
  /** Asks for approval under the default autonomy whatever its risk (for example media generation). */
  confirm?: boolean;
  /** Always asks, whatever the autonomy, grants or action rules (payments, D-142). */
  alwaysAsk?: boolean;
  /** Always asks for these arguments (for example loosening a rule but not tightening it, D-242). */
  alwaysAskFor?: (args: z.infer<S>) => boolean;
  /** Risk that depends on the arguments (overrides `risk`). */
  riskFor?: (args: z.infer<S>) => Risk;
  /**
   * The output is untrusted (web pages, outside services): under the default autonomy, later
   * medium-risk calls that send data out need approval.
   */
  untrustedOutput?: boolean;
  /**
   * Sends data out of Casama (D-213): after untrusted content, a medium-risk call asks first under the
   * default autonomy. `sendsOutFor` decides from the arguments (for example only writing requests).
   */
  sendsOut?: boolean;
  sendsOutFor?: (args: z.infer<S>) => boolean;
  /**
   * Acts on the screen (browser or desktop). Waits while a person has control of the computer;
   * shell and file tools wait too unless the person allowed them.
   */
  screen?: boolean;
  /**
   * Extra fields shown on the approval card (for example a diff of what will change). Merged into
   * the redacted arguments only for approvals; never passed to the tool.
   */
  approvalDetails?: (
    args: z.infer<S>,
    ctx: { orgId: string; botId: string },
  ) => Promise<Record<string, unknown>>;
  /** Its action category for action rules (D-115); otherwise guessed from the name. */
  category?: "send" | "pay" | "delete" | "publish" | "share" | "sign_in";
  /**
   * Whether the tool can run at all for this workspace (a key it needs is set up). When false,
   * nobody is asked to approve it: it runs straight away and reports what's missing.
   */
  ready?: (ctx: { orgId: string; botId: string }) => Promise<boolean>;
  /** Raw JSON Schema for tools defined outside Zod (integration tools). */
  jsonSchema?: Record<string, unknown>;
  execute(args: z.infer<S>, ctx: ToolContext): Promise<ToolResult>;
}

export class ToolError extends Error {
  readonly code: string;
  constructor(code: string, message: string) {
    super(message);
    this.code = code;
  }
}

const WIRE_MAX = 64;

/** 8 hex characters of FNV-1a: short, stable across processes, no crypto import. */
function fnv1a(text: string) {
  let h = 0x811c9dc5;
  for (let i = 0; i < text.length; i++) h = Math.imul(h ^ text.charCodeAt(i), 0x01000193);
  return (h >>> 0).toString(16).padStart(8, "0");
}

/** One registry for every tool: schema, risk, capability needs and executor. */
export class ToolRegistry {
  private readonly tools = new Map<string, ToolDefinition>();

  /** A copy of this registry plus extra tools (per-run integration tools). */
  with(defs: ToolDefinition[]) {
    const r = new ToolRegistry();
    for (const d of this.tools.values()) r.tools.set(d.name, d);
    for (const d of defs) r.tools.set(d.name, d);
    return r;
  }

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

  /**
   * Provider tool names cannot contain dots and are capped at 64 characters (OpenAI, Gemini):
   * memory.search -> memory__search, and a longer name is cut with a stable hash on the end.
   */
  static wireName = (name: string) => {
    const base = name.replaceAll(".", "__");
    return base.length <= WIRE_MAX ? base : `${base.slice(0, WIRE_MAX - 9)}_${fnv1a(name)}`;
  };
  /** The plain reverse of wireName; prefer resolveWire, which also undoes cut names. */
  static fromWire = (name: string) => name.replaceAll("__", ".");

  /** The registered tool a provider's tool name means (cut names, names with `__`), else fromWire. */
  resolveWire(name: string) {
    if (this.tools.has(name)) return name;
    for (const n of this.tools.keys()) if (ToolRegistry.wireName(n) === name) return n;
    return ToolRegistry.fromWire(name);
  }

  specs(defs: ToolDefinition[]): ToolSpec[] {
    return defs.map((t) => ({
      name: ToolRegistry.wireName(t.name),
      description: t.description,
      inputSchema:
        t.jsonSchema ??
        (z.toJSONSchema(t.schema, { target: "draft-7" }) as Record<string, unknown>),
    }));
  }

  /** Validates arguments; throws ToolError("invalid_arguments") with a readable message. */
  parse(name: string, args: unknown) {
    const def = this.tools.get(name);
    if (!def) throw new ToolError("unknown_tool", `Unknown tool ${name}`);
    let parsed = def.schema.safeParse(args);
    // Some models send numbers and booleans as strings ("count": "10.0"): accept those once.
    if (!parsed.success) {
      const fixed = coerceScalars(args, parsed.error.issues);
      if (fixed !== undefined) parsed = def.schema.safeParse(fixed);
    }
    if (!parsed.success) {
      // Say what the call needs, so a model that sent empty or wrong arguments can fix them.
      const problems = parsed.error.issues
        .map((i) => `${i.path.join(".") || "(root)"}: ${i.message}`)
        .join("; ");
      throw new ToolError(
        "invalid_arguments",
        `${problems}. ${name} takes ${argumentsHint(def)}; call it again with them filled in.`,
      );
    }
    return { def, args: parsed.data };
  }
}

/**
 * A copy of the arguments with strings turned into the numbers or booleans the schema expected,
 * or undefined when no issue is that kind of mix-up.
 */
export function coerceScalars(
  args: unknown,
  issues: ReadonlyArray<{ code: string; path: PropertyKey[]; expected?: unknown }>,
): unknown {
  if (!args || typeof args !== "object") return undefined;
  const copy = structuredClone(args) as Record<PropertyKey, unknown>;
  let changed = false;
  for (const issue of issues) {
    if (issue.code !== "invalid_type" || !issue.path.length) continue;
    const parent = issue.path
      .slice(0, -1)
      .reduce<unknown>((o, k) => (o as Record<PropertyKey, unknown> | undefined)?.[k], copy) as
      | Record<PropertyKey, unknown>
      | undefined;
    const key = issue.path[issue.path.length - 1] as PropertyKey;
    const value = parent?.[key];
    if (!parent || typeof value !== "string") continue;
    const text = value.trim();
    if (issue.expected === "number" && text !== "" && Number.isFinite(Number(text))) {
      parent[key] = Number(text);
      changed = true;
    } else if (issue.expected === "boolean" && (text === "true" || text === "false")) {
      parent[key] = text === "true";
      changed = true;
    }
  }
  return changed ? copy : undefined;
}

/** A tool's arguments in one line: {"command": string (required), "timeout_s": integer}. */
export function argumentsHint(def: ToolDefinition): string {
  const schema = (def.jsonSchema ?? z.toJSONSchema(def.schema, { target: "draft-7" })) as {
    properties?: Record<string, { type?: unknown; enum?: unknown[] }>;
    required?: string[];
  };
  const props = Object.entries(schema.properties ?? {});
  if (!props.length) return "no arguments";
  const required = new Set(schema.required ?? []);
  const parts = props.map(([key, p]) => {
    const type = Array.isArray(p.enum)
      ? p.enum.map((v) => JSON.stringify(v)).join("|")
      : Array.isArray(p.type)
        ? p.type.join("|")
        : String(p.type ?? "value");
    return `${JSON.stringify(key)}: ${type}${required.has(key) ? " (required)" : ""}`;
  });
  return `{${parts.join(", ")}}`;
}
