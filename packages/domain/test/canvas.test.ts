import { describe, expect, it } from "vitest";
import {
  CANVAS_LIMITS,
  type CanvasContent,
  CanvasError,
  checkEntry,
  checkSchedule,
  currentEntries,
  cutAtWord,
  dealRotation,
  inkFor,
  lapOrder,
  parseItemsFile,
  rotationAt,
  toneOf,
} from "../src/canvas.ts";

const item = (text: string) => checkEntry({ text }).entry;
const rotation = (
  n: number,
  r: Partial<NonNullable<CanvasContent["rotation"]>> = {},
): NonNullable<CanvasContent["rotation"]> => ({
  every: "day",
  at: "06:00",
  order: "in_order",
  at_end: "loop",
  tz: "UTC",
  started_at: "2027-03-01T06:00:00.000Z",
  items: Array.from({ length: n }, (_, i) => item(`Item ${i}`)),
  ...r,
});

describe("canvas entries", () => {
  it("cuts at a word with an ellipsis", () => {
    expect(cutAtWord("Be still, and know that I am God", 14)).toBe("Be still, and…");
    expect(cutAtWord("short", 10)).toBe("short");
    expect(cutAtWord("Supercalifragilistic", 8)).toBe("Superca…");
  });

  it("makes short and tiny forms, keeping the footer", () => {
    const { entry } = checkEntry({
      text: "Be still, and know that I am God; I will be exalted among the nations, I will be exalted in the earth.",
      footer: "Ps 46:10",
    });
    expect(entry.short.length).toBeLessThanOrEqual(CANVAS_LIMITS.short);
    expect(entry.short.endsWith(" · Ps 46:10")).toBe(true);
    expect(entry.tiny.length).toBeLessThanOrEqual(CANVAS_LIMITS.tiny);
    expect(entry.tiny.startsWith("Be still")).toBe(true);
    // The bot's own short forms win, cut to fit.
    const own = checkEntry({ text: "x", short: "Mine", tiny: "a".repeat(40) });
    expect(own.entry.short).toBe("Mine");
    expect(own.entry.tiny.length).toBe(CANVAS_LIMITS.tiny);
    expect(own.cut.join()).toContain("tiny");
  });

  it("needs each template's fields", () => {
    expect(() => checkEntry({ template: "countdown", title: "Trip" })).toThrow(CanvasError);
    expect(() => checkEntry({ template: "number", title: "Streak" })).toThrow(/value/);
    expect(() => checkEntry({ template: "list", items: [] })).toThrow(/items/);
    expect(() => checkEntry({ template: "picture" })).toThrow(/picture/);
    expect(() => checkEntry({ template: "bogus" })).toThrow(/template/);
    const c = checkEntry({
      template: "countdown",
      title: "Trip",
      target: "2027-06-01T09:00:00+08:00",
    });
    expect(c.entry.target).toBe("2027-06-01T01:00:00.000Z");
    expect(c.entry.tiny).toBe("Trip");
    const n = checkEntry({
      template: "number",
      title: "Reading streak",
      value: 12,
      of: 30,
      unit: "days",
    });
    expect(n.entry.short).toBe("12/30 days Reading streak");
  });

  it("keeps five list rows and says so", () => {
    const { entry, cut } = checkEntry({
      template: "list",
      title: "Today",
      items: ["a", "b", { text: "c", done: true }, "d", "e", "f"],
    });
    expect(entry.items).toHaveLength(5);
    expect(entry.short).toBe("a, b, d, e");
    expect(cut.join()).toContain("first 5");
  });

  it("cuts long text and reports it", () => {
    const { entry, cut } = checkEntry({ title: "t".repeat(100), text: "word ".repeat(100) });
    expect(entry.title?.length).toBeLessThanOrEqual(CANVAS_LIMITS.title);
    expect(entry.text?.length).toBeLessThanOrEqual(CANVAS_LIMITS.text);
    expect(cut).toHaveLength(2);
  });
});

describe("canvas colours", () => {
  it("chooses the text colour for contrast", () => {
    expect(toneOf("#000000")).toBe("dark");
    expect(toneOf("#ffffff")).toBe("light");
    expect(inkFor({ kind: "color", color: "#1a237e" })).toBe("light");
    expect(inkFor({ kind: "color", color: "#fff59d" })).toBe("dark");
    expect(inkFor({ kind: "gradient", from: "#000000", to: "#333333" })).toBe("light");
    expect(inkFor({ kind: "picture", picture: "h", tone: "light" })).toBe("dark");
    expect(inkFor({ kind: "painting", name: "night_sky" })).toBe("light");
    expect(inkFor({ kind: "auto" })).toBe("auto");
  });
});

describe("canvas schedules", () => {
  const now = new Date("2027-03-01T00:00:00Z");
  const at = (min: number) => new Date(now.getTime() + min * 60_000).toISOString();
  it("needs entries 5 minutes apart and in order", () => {
    const e = (a: string | null) => ({ ...item("x"), at: a });
    expect(() => checkSchedule([e(null), e(at(10)), e(at(20))], now)).not.toThrow();
    expect(() => checkSchedule([e(null), e(at(3))], now)).toThrow(/5 minutes/);
    expect(() => checkSchedule([e(null), e(at(20)), e(at(10))], now)).toThrow(/order/);
    expect(() => checkSchedule([e(null), e(null)], now)).toThrow(/at/);
    expect(() =>
      checkSchedule(
        Array.from({ length: 15 }, (_, i) => e(at(i * 10))),
        now,
      ),
    ).toThrow(/14/);
  });
  it("shows the latest entry that has started", () => {
    const c: CanvasContent = {
      look: {
        background: { kind: "auto" },
        font: "plain",
        align: "start",
        icon: null,
        accent: null,
      },
      entries: [
        { ...item("a"), at: null },
        { ...item("b"), at: at(10) },
        { ...item("c"), at: at(20) },
      ],
    };
    const later = currentEntries(c, "s", now.getTime() + 15 * 60_000);
    expect(later.map((e) => e.text)).toEqual(["b", "c"]);
    expect(later[0]?.at).toBeNull();
  });
});

describe("canvas rotations", () => {
  const day = 86_400_000;
  const t0 = Date.parse("2027-03-01T06:00:00Z");

  it("moves one item a day at the set time, in order, looping", () => {
    const r = rotation(3);
    expect(rotationAt(r, "c", t0).item).toBe(0);
    expect(rotationAt(r, "c", t0 + day - 60_000).item).toBe(0);
    expect(rotationAt(r, "c", t0 + day).item).toBe(1);
    expect(rotationAt(r, "c", t0 + 2 * day).item).toBe(2);
    const lap = rotationAt(r, "c", t0 + 3 * day);
    expect(lap).toMatchObject({ item: 0, lap: 1, left: 2 });
  });

  it("stops on the last item when asked", () => {
    const r = rotation(3, { at_end: "stop" });
    expect(rotationAt(r, "c", t0 + 10 * day)).toMatchObject({ item: 2, ended: true, left: 0 });
    const dealt = dealRotation(r, "c", t0 + day);
    expect(dealt.map((e) => e.text)).toEqual(["Item 1", "Item 2"]);
  });

  it("shuffles the same way for the same canvas and lap", () => {
    expect(lapOrder(20, "shuffle", "canvas-a", 0)).toEqual(lapOrder(20, "shuffle", "canvas-a", 0));
    expect(lapOrder(20, "shuffle", "canvas-a", 0)).not.toEqual(
      lapOrder(20, "shuffle", "canvas-a", 1),
    );
    expect([...lapOrder(20, "shuffle", "canvas-b", 3)].sort((a, b) => a - b)).toEqual(
      lapOrder(20, "in_order", "x", 0),
    );
    const r = rotation(20, { order: "shuffle" });
    const seen = new Set<number>();
    for (let i = 0; i < 20; i++) seen.add(rotationAt(r, "seed", t0 + i * day).item);
    expect(seen.size).toBe(20);
  });

  it("deals the next 14 as dated entries", () => {
    const r = rotation(30);
    const dealt = dealRotation(r, "c", t0 + 3 * 3_600_000);
    expect(dealt).toHaveLength(14);
    expect(dealt[0]).toMatchObject({ text: "Item 0", at: null });
    expect(dealt[1]?.at).toBe("2027-03-02T06:00:00.000Z");
    expect(dealt[13]?.at).toBe("2027-03-14T06:00:00.000Z");
  });

  it("keeps the local time across a clock change and in another zone", () => {
    // New York moves its clocks forward on 2027-03-14.
    const r = rotation(30, { tz: "America/New_York", started_at: "2027-03-10T11:00:00.000Z" });
    const dealt = dealRotation(r, "c", Date.parse("2027-03-10T12:00:00Z"));
    expect(dealt[1]?.at).toBe("2027-03-11T11:00:00.000Z"); // 06:00 EST
    expect(dealt[4]?.at).toBe("2027-03-14T10:00:00.000Z"); // 06:00 EDT
    const manila = rotation(5, { tz: "Asia/Manila", started_at: "2027-02-28T22:00:00.000Z" });
    expect(dealRotation(manila, "c", Date.parse("2027-02-28T23:00:00Z"))[1]?.at).toBe(
      "2027-03-01T22:00:00.000Z",
    );
  });

  it("weekly and hourly rhythms", () => {
    // 2027-03-01 is a Monday.
    const weekly = rotation(4, { every: "week", weekday: 1 });
    expect(dealRotation(weekly, "c", t0)[1]?.at).toBe("2027-03-08T06:00:00.000Z");
    const hourly = rotation(4, { every: 3, started_at: "2027-03-01T00:00:00.000Z" });
    expect(rotationAt(hourly, "c", Date.parse("2027-03-01T07:00:00Z")).item).toBe(2);
    expect(dealRotation(hourly, "c", Date.parse("2027-03-01T07:00:00Z"))[1]?.at).toBe(
      "2027-03-01T09:00:00.000Z",
    );
  });
});

describe("rotation files", () => {
  it("reads lines, JSON and CSV", () => {
    expect(parseItemsFile("one\n\ntwo\n")).toEqual([{ text: "one" }, { text: "two" }]);
    expect(parseItemsFile('["a", {"text": "b", "footer": "c"}]')).toEqual([
      { text: "a" },
      { text: "b", footer: "c" },
    ]);
    expect(
      parseItemsFile(
        'text,footer\n"Be still, and know",Ps 46:10\nRejoice always,1 Thess 5:16',
        "v.csv",
      ),
    ).toEqual([
      { text: "Be still, and know", footer: "Ps 46:10" },
      { text: "Rejoice always", footer: "1 Thess 5:16" },
    ]);
    expect(() => parseItemsFile("[oops")).toThrow(CanvasError);
  });
});
