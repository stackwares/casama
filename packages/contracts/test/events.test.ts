import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import {
  buildOpenApiDocument,
  eventComponentName,
  parseRunEvent,
  RUN_EVENT_TYPES,
} from "../src/index.ts";

const base = {
  v: 1,
  run_id: "11111111-1111-4111-8111-111111111111",
  seq: 1,
  ts: "2026-11-09T09:30:00.000Z",
  bot_id: "22222222-2222-4222-8222-222222222222",
};

describe("run events", () => {
  it("covers every event type in the spec", () => {
    expect(RUN_EVENT_TYPES).toEqual([
      "run.started",
      "message.delta",
      "message.completed",
      "tool.started",
      "tool.output",
      "tool.completed",
      "tool.failed",
      "approval.requested",
      "approval.resolved",
      "takeover.requested",
      "takeover.resolved",
      "lease.changed",
      "computer.state",
      "checkpoint.created",
      "subrun.started",
      "subrun.completed",
      "memory.written",
      "skill.loaded",
      "usage",
      "model.fallback",
      "run.completed",
      "run.failed",
      "run.cancelled",
      "ui.shown",
    ]);
  });

  it("parses known types and validates payloads", () => {
    const ev = parseRunEvent({
      ...base,
      type: "usage",
      payload: { tokens_in: 10, tokens_out: 5, cost_usd: 0.01 },
    });
    expect(ev?.type).toBe("usage");
    expect(() => parseRunEvent({ ...base, type: "usage", payload: { tokens_in: -1 } })).toThrow();
  });

  it("returns null for unknown types instead of throwing", () => {
    expect(
      parseRunEvent({ ...base, type: "future.event", payload: { anything: true } }),
    ).toBeNull();
  });

  it("names components predictably", () => {
    expect(eventComponentName("tool.completed")).toBe("ToolCompletedEvent");
    expect(eventComponentName("usage")).toBe("UsageEvent");
  });
});

describe("openapi", () => {
  it("matches the committed openapi.json (run `pnpm gen` after changing contracts)", () => {
    const committed = JSON.parse(readFileSync(new URL("../openapi.json", import.meta.url), "utf8"));
    expect(buildOpenApiDocument()).toEqual(committed);
  });

  it("documents every operation with an operationId and problem responses", () => {
    const doc = buildOpenApiDocument();
    for (const [path, ops] of Object.entries(doc.paths ?? {})) {
      for (const [method, op] of Object.entries(
        ops as Record<string, { operationId?: string; responses: object }>,
      )) {
        expect(op.operationId, `${method} ${path}`).toBeTruthy();
        if (path.startsWith("/v1/") && !["/v1/config", "/v1/signup/challenge"].includes(path))
          expect(Object.keys(op.responses)).toContain("401");
      }
    }
  });
});
