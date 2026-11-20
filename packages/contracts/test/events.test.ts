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
      "device.access_requested",
      "device.browser_access_requested",
      "local_mcp.sign_in_needed",
      "mcp.question",
      "mcp.question_resolved",
      "device.permission_needed",
      "device.data_used",
      "secret.requested",
      "secret.resolved",
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
      "notice",
      "run.completed",
      "run.failed",
      "run.cancelled",
      "ui.shown",
      "canvas.preview",
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
        if (
          path.startsWith("/v1/") &&
          ![
            "/v1/config",
            "/v1/signup/challenge",
            "/v1/join/preview",
            "/v1/referral/preview",
            // Remote app settings: apps read them before signing in (D-241).
            "/v1/app-config",
            // The browser guard's added sites: the extension reads them before signing in (D-374).
            "/v1/browser-guard",
            // Gallery use counts: aggregate, public, and read by the web gallery (D-315).
            "/v1/gallery/stats",
            // A scanned sign-in code is how a phone signs in, so it has no session yet (D-296).
            "/v1/auth/pairing-codes/redeem",
            // Profile photos load in image views without a token; the random id is the secret (D-202).
            "/v1/photos/{id}",
            // Bot pictures load the same way, and native widgets fetch them without a session (D-456).
            "/v1/bot-images/{id}",
            // Reports from the sites zone's own page come from visitors, who have no account.
            "/v1/site-reports",
            // Casama Help on the websites answers signed-out visitors (D-401).
            "/v1/support/web/config",
            "/v1/support/web/session",
            // A watch with no phone app at hand asks for a sign-in code before it has a key (D-410).
            "/v1/watch/codes",
            // The waitlist is for people who have no account yet: joining it, claiming an invite
            // code, looking a code up and leaving the list (docs/WAITLIST-PLAN.md).
            "/v1/waitlist",
            "/v1/waitlist/redeem",
            "/v1/waitlist/leave",
            "/v1/invites/preview",
          ].includes(path)
        )
          expect(Object.keys(op.responses)).toContain("401");
      }
    }
  });
});
