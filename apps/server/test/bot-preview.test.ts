import { describe, expect, it } from "vitest";
import { previewText } from "../src/api/routes/bots.js";

describe("previewText", () => {
  it("reads a markdown table as its cells, without the rule row or pipes", () => {
    const text =
      "Here you go:\n\n| Planet | Diameter (km) |\n|---|---|\n| Jupiter | 142,984 |\n| :--- | ---: |\n| Earth | 12,756 |";
    expect(previewText(text)).toBe(
      "Here you go: Planet · Diameter (km) Jupiter · 142,984 Earth · 12,756",
    );
  });

  it("leaves a lone pipe in prose alone", () => {
    expect(previewText("Use a | b in the shell")).toBe("Use a | b in the shell");
  });
});
