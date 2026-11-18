import { describe, expect, it } from "vitest";
import { compareReports } from "../src/compare.ts";
import type { EvalReport } from "../src/types.ts";

const report = (tokens: number, passes: boolean[]): EvalReport => ({
  mode: "fixtures",
  model: "m",
  subset: "quick",
  started_at: "",
  tasks: passes.map((pass, i) => ({
    id: `t${i}`,
    category: "files",
    pass,
    status: "completed",
    cost_usd: 0,
    steps: 1,
    seconds: 1,
  })),
  success_rate: passes.filter(Boolean).length / passes.length,
  cost_usd: 0,
  tokens_in: tokens,
  avg_steps: 1,
  avg_seconds: 1,
});

describe("compareReports", () => {
  it("reports the token saving and newly failing tasks", () => {
    const c = compareReports(report(10_000, [true, true]), report(6_000, [true, false]));
    expect(c.saving).toBeCloseTo(0.4);
    expect(c.success_delta).toBe(-0.5);
    expect(c.regressions).toEqual(["t1"]);
  });
});
