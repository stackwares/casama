import { readdirSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { BOT_NAMES, BOT_TEMPLATES, personalBotPersona, starterBotName } from "../src/index.ts";

describe("starter bot names", () => {
  const galleryIds = readdirSync(new URL("../../../gallery/bots", import.meta.url));
  const ids = [...new Set([...BOT_TEMPLATES.map((t) => t.id), ...galleryIds])];

  it("gives every Casama starter bot its own name from the list", () => {
    const names = ids.filter((id) => id !== "casama").map(starterBotName);
    for (const n of names) expect(BOT_NAMES).toContain(n);
    expect(new Set(names).size).toBe(names.length);
  });

  it("names Casama's own starter bot Casama, first in the list (D-391)", () => {
    expect(BOT_TEMPLATES[0]?.id).toBe("casama");
    expect(galleryIds).toContain("casama");
    expect(starterBotName("casama")).toBe("Casama");
    expect(BOT_NAMES).not.toContain("Casama");
  });

  it("gives a community starter bot a steady name none of Casama's own has", () => {
    const n = starterBotName("someone-elses-bot");
    expect(BOT_NAMES).toContain(n);
    expect(starterBotName("someone-elses-bot")).toBe(n);
    expect(ids.map(starterBotName)).not.toContain(n);
  });

  it("names them people, not jobs", () => {
    expect(starterBotName("travel-planner")).toBe("Rome");
    expect(starterBotName("executive-assistant")).toBe("Anna");
  });

  it("starts the personal bot as Casama's own starter bot", () => {
    expect(personalBotPersona()).toBe(BOT_TEMPLATES[0]?.persona);
  });
});
