/**
 * Lazy tool loading (SPEC: Post-v1 roadmap → Lazy tool loading; D-106). A bot with many tools
 * starts with the core ones, `tools.load` and a byte-stable index of the other groups; tools.load
 * adds full definitions for the rest of the run, appended after the core tools so the cached
 * prompt prefix (system, core tools) doesn't change.
 */
import { z } from "zod";
import { type ToolDefinition, ToolError, type ToolRegistry } from "./tools/registry.ts";

export const TOOLS_LOAD = "tools.load";
export const DEFAULT_LAZY_THRESHOLD = 30;

const CORE_PREFIXES = [
  "memory.",
  "skills.",
  "tasks.",
  "notify",
  "ui.",
  "setup.",
  "secrets.request",
  // Always there, so "connect my Google" gets a button, not a made-up answer (D-259).
  "connections.offer",
  TOOLS_LOAD,
];
/**
 * What a group is for, for groups people ask for by outcome rather than by tool: without it a bot
 * asked for "a game I can play" writes an HTML file and links that, since nothing in "pages (5):
 * publish, share…" says that's how sites and games reach the person.
 */
const GROUP_PURPOSE: Record<string, string> = {
  pages:
    "how sites, games, reports and dashboards reach the person: publish one and they open or play it",
  media: "make pictures, videos and sound",
  library: "find and change things you made before",
};
const INTEGRATION_KINDS = new Set(["mcp", "openapi", "composio", "pipedream", "local_mcp", "app"]);

export const isCoreTool = (name: string) =>
  CORE_PREFIXES.some((p) => name === p || name.startsWith(p));

/** browser.open → browser; mcp.github.create_issue → mcp.github. */
export function toolGroup(name: string) {
  const parts = name.split(".");
  if (parts.length > 2 && INTEGRATION_KINDS.has(parts[0] as string))
    return `${parts[0]}.${parts[1]}`;
  return parts[0] as string;
}

export interface LazyPlan {
  core: ToolDefinition[];
  /** Group → its tools, sorted. */
  groups: Map<string, ToolDefinition[]>;
  /** One line per group, sorted; identical for identical tool sets. */
  index: string;
}

/** Null when the bot has few enough tools to send them all. */
export function planLazyTools(
  available: ToolDefinition[],
  threshold = DEFAULT_LAZY_THRESHOLD,
): LazyPlan | null {
  if (threshold <= 0 || available.length <= threshold) return null;
  const core = available
    .filter((t) => isCoreTool(t.name))
    .sort((a, b) => a.name.localeCompare(b.name));
  const groups = new Map<string, ToolDefinition[]>();
  for (const t of available) {
    if (isCoreTool(t.name)) continue;
    const g = toolGroup(t.name);
    groups.set(g, [...(groups.get(g) ?? []), t]);
  }
  const lines = [...groups.keys()].sort().map((g) => {
    const tools = (groups.get(g) as ToolDefinition[]).sort((a, b) => a.name.localeCompare(b.name));
    const names = tools.map((t) => t.name.slice(g.length + 1) || t.name);
    const shown =
      names.length > 8
        ? `${names.slice(0, 8).join(", ")}, +${names.length - 8} more`
        : names.join(", ");
    const purpose = GROUP_PURPOSE[g];
    return `- ${g} (${tools.length}): ${shown}${purpose ? ` (${purpose})` : ""}`;
  });
  const index = [
    "More tools are available. Call tools.load with the groups (or tool names) you need before using them; they stay loaded for this run.",
    ...lines,
  ].join("\n");
  return { core, groups, index };
}

/** Resolves a tools.load request to tool definitions (groups or exact names). */
export function resolveToolsLoad(plan: LazyPlan, args: { groups?: string[]; names?: string[] }) {
  const out: ToolDefinition[] = [];
  const unknown: string[] = [];
  for (const g of args.groups ?? []) {
    const tools = plan.groups.get(g);
    if (tools) out.push(...tools);
    else unknown.push(g);
  }
  const all = [...plan.groups.values()].flat();
  for (const n of args.names ?? []) {
    const t = all.find((x) => x.name === n);
    if (t) out.push(t);
    else unknown.push(n);
  }
  return { tools: [...new Map(out.map((t) => [t.name, t])).values()], unknown };
}

export const ToolsLoadArgs = z.object({
  groups: z
    .array(z.string().max(120))
    .max(20)
    .optional()
    .describe("Groups from the index, e.g. browser, mcp.github"),
  names: z.array(z.string().max(120)).max(40).optional().describe("Exact tool names"),
});

export function registerToolsLoad(registry: ToolRegistry) {
  registry.register({
    name: TOOLS_LOAD,
    readOnly: true,
    description:
      "Load more tools by group or name from the index in your instructions. They stay available for the rest of this run.",
    risk: "low",
    schema: ToolsLoadArgs,
    async execute() {
      throw new ToolError("internal", "tools.load runs in the run loop");
    },
  });
}
