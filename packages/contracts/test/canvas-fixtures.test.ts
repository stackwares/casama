import { readdirSync, readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { CanvasList } from "../src/index.ts";

/**
 * Sample canvases every renderer is tested against (docs/BOT-WIDGET-PLAN.md §7): the server's,
 * the app's, the iPhone and Mac widgets' and Android's. Made from the server's own code
 * (canvasOut), so they must keep matching the contract.
 */
const dir = new URL("../fixtures/canvases/", import.meta.url);

describe("canvas fixtures", () => {
  for (const file of readdirSync(dir).filter((f) => f.endsWith(".json"))) {
    it(`${file} matches the contract`, () => {
      const data = JSON.parse(readFileSync(new URL(file, dir), "utf8"));
      expect(() => CanvasList.parse(data)).not.toThrow();
    });
  }
  it("covers every template", () => {
    const data = CanvasList.parse(JSON.parse(readFileSync(new URL("canvases.json", dir), "utf8")));
    const templates = new Set(data.items.flatMap((c) => c.entries.map((e) => e.template)));
    expect([...templates].sort()).toEqual(["countdown", "list", "number", "picture", "text"]);
  });
});
