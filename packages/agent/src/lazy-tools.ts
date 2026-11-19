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
  media:
    "make pictures, videos, sound and QR codes; crop, resize, rotate or convert a real picture without remaking it",
  documents:
    "make PDF and Word files; read PDFs, Word files and spreadsheets from the chat; combine, cut or rotate PDFs (photos into one PDF); with or without a computer",
  gallery:
    "ready-made skills, routines, bots, apps, plugins and looks to offer before building one yourself; turn good work into a skill draft",
  library: "find and change things you made before",
  device:
    "the person's own phone or computer: calendar, contacts, health (sleep, steps, heart rate), places, reminders; read them or ask for access",
  projects:
    "keep work that takes several files or sessions (a game, an app, a site) together: start one and what you make is filed under it",
};
const INTEGRATION_KINDS = new Set([
  "mcp",
  "openapi",
  "composio",
  "pipedream",
  "local_mcp",
  "computer_mcp",
  "a2a",
  "app",
]);

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

/**
 * A conversation starts each run with the groups its earlier runs used (docs/USAGE-PLAN.md step 2).
 * Loading a group mid-run changes the tool list, which comes first in the prompt, so the provider
 * bills the whole context again; and the load itself is an extra model call. Remembered groups cost
 * neither, and give the next message the same tool list as the last one.
 */
export const REMEMBERED_GROUPS = 6;
/** Remembered definitions stay under this many tokens, so an old habit can't bloat every call. */
export const REMEMBERED_TOOL_TOKENS = 6_000;
/** Mentioned `@App` tools preload before remembered groups under their own budget (D-434). */
export const MENTIONED_TOOL_TOKENS = 8_000;
/** Group names kept on the conversation; more than are loaded, so a skipped big group can return. */
const REMEMBERED_KEPT = 12;

export interface MentionedToolRequest {
  /** Integration tool group, e.g. `mcp.linear`, `composio.apps`, `computer_mcp.figma`. */
  group: string;
  /** Exact full tool names belonging to this mentioned app (filtered to one toolkit for hubs). */
  toolNames: string[];
}

/**
 * Selects tool definitions for `@App` mentions that fit within `MENTIONED_TOOL_TOKENS`.
 * Keeps each mentioned app atomic: if an app's tools exceed the remaining budget it is skipped
 * (the model still receives its name and group so it can call `tools.load` if needed).
 * Returned tools are sorted by name for prompt-cache stability.
 */
export function selectMentionedTools(
  available: ToolDefinition[],
  requests: MentionedToolRequest[],
  tokensOf: (defs: ToolDefinition[]) => number,
  budget = MENTIONED_TOOL_TOKENS,
): { loaded: ToolDefinition[]; loadedIndices: Set<number> } {
  const byName = new Map(available.map((t) => [t.name, t]));
  const seen = new Set<string>();
  const picked: ToolDefinition[] = [];
  const loadedIndices = new Set<number>();
  let tokens = 0;

  for (const [idx, req] of requests.entries()) {
    const defs = req.toolNames
      .map((n) => byName.get(n))
      .filter((d): d is ToolDefinition => !!d && !isCoreTool(d.name) && !seen.has(d.name))
      .sort((a, b) => a.name.localeCompare(b.name));
    if (!defs.length) continue;
    const size = tokensOf(defs);
    if (tokens + size > budget) continue;
    tokens += size;
    loadedIndices.add(idx);
    for (const d of defs) {
      seen.add(d.name);
      picked.push(d);
    }
  }

  picked.sort((a, b) => a.name.localeCompare(b.name));
  return { loaded: picked, loadedIndices };
}

/**
 * The tools to load at the start of a run: the conversation's groups, most recent first, while
 * they fit. Returned sorted by name, so the same groups always make the same tool list.
 */
export function rememberedTools(
  plan: LazyPlan,
  groups: string[],
  tokensOf: (defs: ToolDefinition[]) => number,
  alreadyLoaded?: Set<string>,
): ToolDefinition[] {
  const chosen: ToolDefinition[] = [];
  const chosenGroups = new Set<string>();
  let tokens = 0;
  for (const g of groups) {
    if (chosenGroups.size >= REMEMBERED_GROUPS) break;
    const raw = plan.groups.get(g);
    if (!raw || chosenGroups.has(g)) continue;
    const tools = alreadyLoaded ? raw.filter((t) => !alreadyLoaded.has(t.name)) : raw;
    if (!tools.length) continue;
    const size = tokensOf(tools);
    if (tokens + size > REMEMBERED_TOOL_TOKENS) continue;
    tokens += size;
    chosenGroups.add(g);
    chosen.push(...tools);
  }
  return chosen.sort((a, b) => a.name.localeCompare(b.name));
}

/** A conversation's groups after a run used `used`: those first, then the earlier ones. */
export function mergeToolGroups(previous: string[], used: string[]): string[] {
  const ok = (g: string) => /^[\w.-]{1,120}$/.test(g);
  return [...new Set([...used, ...previous].filter(ok))].slice(0, REMEMBERED_KEPT);
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
    // Models often give a connection tool's own name (t3_list_threads) without its prefix
    // (local_mcp.t3code_ab12cd.t3_list_threads): accept that when only one tool ends with it.
    const t =
      all.find((x) => x.name === n) ??
      ((m) => (m.length === 1 ? m[0] : undefined))(all.filter((x) => x.name.endsWith(`.${n}`)));
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
