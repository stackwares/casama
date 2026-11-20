/** Live data and composed cards (docs/RICH-CARDS-PLAN.md): what the checks accept and refuse. */
import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { checkComponents, UiCheckError } from "../src/a2ui.ts";
import { DATA_CARDS } from "../src/live-cards.ts";

const load = (name: string) =>
  JSON.parse(
    readFileSync(new URL(`../../contracts/fixtures/${name}`, import.meta.url), "utf8"),
  ) as Record<string, Record<string, unknown>>;
const one = (c: Record<string, unknown>, opts = {}) =>
  checkComponents([{ id: "root", ...c }], opts);

describe("composed cards", () => {
  for (const [name, card] of Object.entries(load("composed-cards.json")))
    it(`accepts the ${name} sample from a bot`, () =>
      expect(() => one(card, { fromBot: true })).not.toThrow());

  it("refuses what doesn't add up", () => {
    expect(() =>
      one({ component: "Comparison", items: ["A", "B"], rows: [{ label: "x", values: ["1"] }] }),
    ).toThrow(/one per item/);
    expect(() =>
      one({
        component: "Comparison",
        items: ["A", "B"],
        rows: [{ label: "x", values: ["1", "2"], best: 2 }],
      }),
    ).toThrow(/best/);
    expect(() => one({ component: "Quiz", question: "?", options: ["a", "b"], answer: 3 })).toThrow(
      /answer/,
    );
    expect(() =>
      one({ component: "WorldClock", places: [{ name: "X", tz: "Manila time" }] }),
    ).toThrow(/time zone/);
    expect(() => one({ component: "Calculator", kind: "mortgage" })).toThrow(/kind is one of/);
    expect(() => one({ component: "Recipe", title: "x", ingredients: [], steps: ["a"] })).toThrow(
      /ingredients/,
    );
    expect(() =>
      one({ component: "Summary", title: "x", text: "y", imageUrl: "http://insecure" }),
    ).toThrow(/https/);
    expect(() => one({ component: "Media", kind: "movie", title: "x", rating: 11 })).toThrow(
      /rating/,
    );
    expect(() => one({ component: "Countdown", title: "x", target: "next week" })).toThrow(/ISO/);
  });

  it("never lets a bot set a live block", () => {
    expect(() =>
      one(
        { component: "Summary", title: "x", text: "y", live: { source: { name: "Reuters" } } },
        { fromBot: true },
      ),
    ).toThrow(/live is set by Casama/);
  });
});

describe("data cards", () => {
  const live = load("live-cards.json");
  for (const [name, card] of Object.entries(live))
    it(`the server's ${name} card passes the checks`, () => expect(() => one(card)).not.toThrow());

  it("are refused from ui.show, so no number in them is typed by a model", () => {
    for (const c of DATA_CARDS) {
      expect(() => one({ component: c }, { fromBot: true })).toThrow(UiCheckError);
      expect(() => one({ component: c }, { fromBot: true })).toThrow(/live\.\*/);
    }
  });

  it("can be named in a plugin's card file", () => {
    expect(() =>
      checkComponents(
        [{ id: "root", component: "Quote", symbol: "{{result.s}}", price: "{{result.p}}" }],
        { template: true },
      ),
    ).not.toThrow();
  });
});

describe("containers", () => {
  it("hold other cards by id", () => {
    expect(() =>
      checkComponents(
        [
          { id: "root", component: "Dashboard", title: "Brief", children: ["a", "b"] },
          { id: "a", component: "Countdown", title: "x", target: "2026-12-25" },
          { id: "b", component: "ProsCons", pros: ["a"], cons: ["b"] },
        ],
        { fromBot: true },
      ),
    ).not.toThrow();
    expect(() =>
      checkComponents([{ id: "root", component: "Carousel", children: ["zzz"] }]),
    ).toThrow(/isn't in the list/);
    expect(() => checkComponents([{ id: "root", component: "Carousel", children: [] }])).toThrow(
      /children/,
    );
  });
});
