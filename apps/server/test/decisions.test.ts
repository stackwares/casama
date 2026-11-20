/** Decision models (D-454): the owner's settings and the results table. */
import { decisionSettings } from "@casama/domain";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import {
  type DecisionLogRow,
  decisionResults,
  resetDecisionSettingsCache,
} from "../src/services/decisions.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

describe("decision settings", () => {
  let h: Harness;
  let token: string;
  beforeAll(async () => {
    resetDecisionSettingsCache();
    h = await startHarness();
    token = (await h.user("decisions@example.com")).token;
  }, 60_000);
  afterAll(async () => {
    resetDecisionSettingsCache();
    await h?.stop();
  });

  it("start with everything off; only the owner reads and changes them", async () => {
    const first = await j(await h.request("/v1/admin/decisions", { token }));
    expect(first).toEqual(decisionSettings(null));
    const next = {
      ...first,
      shadow_models: ["typesafe/jev-1.14"],
      uses: { ...first.uses, scan_gate: { ...first.uses.scan_gate, mode: "shadow" } },
    };
    const saved = await j(
      await h.request("/v1/admin/decisions", { method: "PUT", token, json: next }),
    );
    expect(saved.uses.scan_gate.mode).toBe("shadow");
    expect((await j(await h.request("/v1/admin/decisions", { token }))).shadow_models).toEqual([
      "typesafe/jev-1.14",
    ]);
    const bad = await h.request("/v1/admin/decisions", {
      method: "PUT",
      token,
      json: {
        ...next,
        uses: { ...next.uses, scan_gate: { ...next.uses.scan_gate, skip_below: 3 } },
      },
    });
    expect(bad.status).toBe(400);
    const results = await j(await h.request("/v1/admin/decisions/results?days=7", { token }));
    expect(results).toEqual({ days: 7, items: [] });
    const stranger = await h.user("decisions-stranger@example.com");
    expect((await h.request("/v1/admin/decisions", { token: stranger.token })).status).toBe(403);
    expect((await h.request("/v1/admin/decisions/results", { token: stranger.token })).status).toBe(
      403,
    );
    expect(
      (
        await h.request("/v1/admin/decisions", {
          method: "PUT",
          token: stranger.token,
          json: next,
        })
      ).status,
    ).toBe(403);
  });
});

describe("decision results", () => {
  const row = (
    v: number,
    outcome: Record<string, unknown> | null,
    model = "a/one",
  ): DecisionLogRow => ({
    use: "scan_gate",
    model,
    answers: { needs_attention: v, from_person: v / 2, time_bound: 0 },
    outcome,
    error: null,
    latency_ms: 100,
    cost_usd: 0.00002,
  });

  it("count, per threshold, what the code would have done and how often that was wrong", () => {
    const items = decisionResults([
      row(0.02, { suggested: false, accepted: false }),
      row(0.04, { suggested: true, accepted: true }),
      row(0.3, { suggested: true, accepted: false }),
      row(0.5, { suggested: false, accepted: false, pending: true }),
      { ...row(0, null), answers: {}, error: "timeout" },
      row(0.01, { suggested: false }, "b/two"),
    ]);
    const a = items.find((i) => i.model === "a/one" && i.signal === "scan_gate");
    expect(a).toMatchObject({ rows: 5, answered: 4, errors: 1, labelled: 3, positives: 2 });
    const at = (th: number) => a?.thresholds.find((t) => t.threshold === th);
    expect(at(0.05)).toEqual({
      threshold: 0.05,
      acted: 2,
      acted_positive: 1,
      acted_negative: 1,
      acted_severe: 1,
    });
    expect(at(0.95)?.acted).toBe(4);
    expect(items.find((i) => i.model === "b/two")?.rows).toBe(1);
  });
});
