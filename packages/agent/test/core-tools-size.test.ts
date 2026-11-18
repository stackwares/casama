import { describe, expect, it } from "vitest";
import * as agent from "../src/index.ts";
import { planLazyTools, type ToolDefinition, type ToolRegistry } from "../src/index.ts";

/**
 * The core tools go out with every model call a bot makes (lazy-tools.ts), about ten times a
 * message, so their size is a running cost (docs/USAGE-PLAN.md, step 4). This fails when a
 * description grows past the budget: move the detail to a tool the bot reads on demand, the way
 * ui.catalog holds what ui.show doesn't say.
 */
const CORE_BUDGET = 3000;
const UI_SHOW_BUDGET = 800;

/** Stands in for the database and every other dependency: registering a tool never calls them. */
const stub: never = new Proxy(function stub() {}, {
  get: (_t, key) => (key === "then" ? undefined : key === Symbol.toPrimitive ? () => "stub" : stub),
  apply: () => stub,
  construct: () => stub,
}) as never;

/** The registry as the worker builds it (apps/server/src/worker/index.ts), without a database. */
function workerRegistry(): ToolRegistry {
  const tools = agent.builtinTools({ db: stub, memory: stub, fetch: stub });
  for (const [name, register] of Object.entries(agent)) {
    if (!/^register[A-Z]\w*Tools?$/.test(name) || typeof register !== "function") continue;
    try {
      (register as (registry: ToolRegistry, deps: unknown) => void)(tools, stub);
    } catch (err) {
      throw new Error(`${name} needs more than a stub to register its tools: ${String(err)}`);
    }
  }
  agent.registerToolsLoad(tools);
  return tools;
}

const tokens = (registry: ToolRegistry, defs: ToolDefinition[]) =>
  Math.ceil(JSON.stringify(registry.specs(defs)).length / 4);

describe("core tools stay small (USAGE-PLAN step 4)", () => {
  const tools = workerRegistry();
  const available = tools.available({ computer: true, desktop: false, vision: true });
  const plan = planLazyTools(available);
  const core = plan?.core ?? [];
  const sizes = core
    .map((t) => ({ name: t.name, tokens: tokens(tools, [t]) }))
    .sort((a, b) => b.tokens - a.tokens);
  const total = tokens(tools, core);
  const report = `core tools: ${total} tokens (budget ${CORE_BUDGET})\n${sizes
    .map((s) => `  ${String(s.tokens).padStart(5)}  ${s.name}`)
    .join("\n")}`;

  it("builds the worker's registry and splits it into core tools and groups", () => {
    expect(available.length).toBeGreaterThan(100);
    expect(plan).not.toBeNull();
    const names = core.map((t) => t.name);
    for (const name of [
      "connections.offer",
      "memory.search",
      "secrets.request",
      "setup.apply",
      "tools.load",
      "ui.catalog",
      "ui.show",
    ])
      expect(names).toContain(name);
  });

  it(`sends at most ${CORE_BUDGET} tokens of core tools with every model call`, () => {
    expect(total, report).toBeLessThanOrEqual(CORE_BUDGET);
  });

  it(`keeps ui.show at most ${UI_SHOW_BUDGET} tokens`, () => {
    const uiShow = sizes.find((s) => s.name === "ui.show")?.tokens ?? Number.POSITIVE_INFINITY;
    expect(uiShow, report).toBeLessThanOrEqual(UI_SHOW_BUDGET);
  });
});
