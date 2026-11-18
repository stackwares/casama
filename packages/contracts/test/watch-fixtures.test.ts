import { readdirSync, readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import {
  Glance,
  WatchApproval,
  WatchAsked,
  WatchChat,
  WatchCode,
  WatchRun,
  WatchSelf,
} from "../src/index.ts";

/**
 * The sample answers both watch apps decode in their own tests (D-410, docs/WATCH-PLAN.md §14:
 * "both apps decode the same sample answers"). They must match the contract, so a change here
 * fails the server's tests before it reaches a watch.
 */
const dir = new URL("../fixtures/watch/", import.meta.url);
const schemas: Record<string, { parse: (v: unknown) => unknown }> = {
  "me.json": WatchSelf,
  "code.json": WatchCode,
  "asked.json": WatchAsked,
  "approval_medium.json": WatchApproval,
  "approval_high.json": WatchApproval,
  "run_working.json": WatchRun,
  "run_needs_ok.json": WatchRun,
  "run_finished.json": WatchRun,
  "chat.json": WatchChat,
  "glance.json": Glance,
};

describe("watch fixtures", () => {
  it("has a schema for every fixture", () => {
    const files = readdirSync(dir).filter((f) => f.endsWith(".json"));
    expect(files.sort()).toEqual(Object.keys(schemas).sort());
  });

  for (const [file, schema] of Object.entries(schemas)) {
    it(`${file} matches the contract`, () => {
      const data = JSON.parse(readFileSync(new URL(file, dir), "utf8"));
      expect(() => schema.parse(data)).not.toThrow();
    });
  }
});
