import { describe, expect, it } from "vitest";
import {
  cardResult,
  checkCardFile,
  checkPlugin,
  checkPluginCards,
  fillCard,
  UiCheckError,
} from "../src/index.ts";

const pr = {
  format: 1,
  card: "Details",
  title: "#{{result.number}} {{result.title}}",
  rows: [
    { label: "State", value: "{{result.state}}" },
    { label: "Author", value: "{{result.author.login}}" },
    { each: "result.labels", label: "Label", value: "{{item.name}}", max: 3 },
  ],
  footer: "{{result.url}}",
  when: "result.number",
};

const files = (extra: Record<string, string>) =>
  new Map<string, string>([
    [
      "plugin.json",
      JSON.stringify({
        $schema: "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
        name: "demo",
      }),
    ],
    [
      "mcp.json",
      JSON.stringify({
        $schema: "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json",
        mcpServers: { demo: { type: "stdio", command: "node", args: ["server.js"] } },
      }),
    ],
    ...Object.entries(extra),
  ]);

describe("card files", () => {
  it("reads the one-component shape and the components shape", () => {
    const c = checkCardFile(pr, "get_pr");
    expect(c).toMatchObject({ tool: "get_pr", card: "Details", when: "result.number" });
    expect(c.components).toHaveLength(1);
    expect(c.components[0]).toMatchObject({ id: "root", component: "Details" });

    const tree = checkCardFile(
      {
        format: 1,
        components: [
          { id: "root", component: "Column", children: ["t", "m"] },
          { id: "t", component: "Text", text: "## {{result.name}}" },
          {
            id: "m",
            component: "Map",
            markers: [{ each: "result.places", lat: "{{item.lat}}", lng: "{{item.lng}}" }],
          },
        ],
      },
      "places",
    );
    expect(tree.card).toBe("Column");
  });

  it("refuses unknown components, bad bindings and a missing format", () => {
    const bad = (raw: unknown, why: RegExp) =>
      expect(() => checkCardFile(raw, "t"), String(why)).toThrow(why);
    bad({ ...pr, format: undefined }, /format/);
    bad({ ...pr, format: 2 }, /card format 2/);
    bad({ ...pr, card: "Html" }, /isn't in Casama's catalog/);
    bad({ ...pr, title: "{{secrets.TOKEN}}" }, /isn't a binding/);
    bad({ ...pr, title: "{{result.title" }, /isn't closed/);
    bad({ ...pr, title: "{{item.title}}" }, /inside an "each"/);
    bad({ ...pr, when: "status" }, /"when"/);
    bad({ ...pr, rows: [] }, /needs rows/);
    bad({ ...pr, rows: [{ label: "x" }] }, /needs value/);
    bad({ ...pr, rows: [{ each: 3, label: "x", value: "y" }] }, /"each" names a list/);
    bad({ ...pr, rows: [{ each: "result.x", max: 100, label: "x", value: "y" }] }, /"max"/);
    bad({ format: 1, card: "Event", start: "{{result.start}}" }, /needs title/);
    bad({ format: 1, card: "Event", title: "x", start: "tomorrow" }, /ISO time/);
    bad(
      {
        format: 1,
        components: [
          { id: "root", component: "Button", child: "x", action: { event: { name: "event.add" } } },
          { id: "x", component: "Text", text: "Add" },
        ],
      },
      /belong to Event/,
    );
    bad({ format: 1, card: "Details", components: [] }, /not both/);
  });

  it("skips a bad card with a warning and keeps the plugin", () => {
    const r = checkPluginCards(
      files({
        "com.casama/cards/get_pr.json": JSON.stringify(pr),
        "com.casama/cards/broken.json": "{",
        "com.casama/cards/odd.json": JSON.stringify({ format: 1, card: "WebView" }),
        "com.casama/cards/nested/x.json": "{}",
      }),
      true,
    );
    expect(r.cards.map((c) => c.tool)).toEqual(["get_pr"]);
    expect(r.warnings).toEqual([
      "Skipped the card for broken: not valid JSON",
      "Ignored com.casama/cards/nested/x.json: a card is com.casama/cards/<tool>.json",
      expect.stringMatching(/^Skipped the card for odd: .*isn't in Casama's catalog/),
    ]);
    const p = checkPlugin(files({ "com.casama/cards/get_pr.json": JSON.stringify(pr) }));
    expect(p.cards.map((c) => c.card)).toEqual(["Details"]);
    expect(p.warnings).toEqual([]);
  });

  it("ignores cards in a plugin without servers", () => {
    const f = files({ "com.casama/cards/x.json": JSON.stringify(pr) });
    f.delete("mcp.json");
    const p = checkPlugin(f);
    expect(p.cards).toEqual([]);
    expect(p.warnings).toContain("Ignored com.casama/cards/: the plugin has no MCP servers");
  });
});

describe("filling a card", () => {
  const card = checkCardFile(pr, "get_pr");
  const result = {
    number: 42,
    title: "Fix login",
    state: "open",
    author: { login: "sam" },
    labels: [{ name: "bug" }, { name: "auth" }, { name: "p1" }, { name: "p2" }],
    url: "https://github.com/o/r/pull/42",
  };

  it("fills bindings, each rows (up to max) and drops missing optional fields", () => {
    const out = fillCard(card, result);
    expect(out).toEqual([
      {
        id: "root",
        component: "Details",
        title: "#42 Fix login",
        rows: [
          { label: "State", value: "open" },
          { label: "Author", value: "sam" },
          { label: "Label", value: "bug" },
          { label: "Label", value: "auth" },
          { label: "Label", value: "p1" },
        ],
        footer: "https://github.com/o/r/pull/42",
      },
    ]);
    const noUrl = fillCard(card, { ...result, url: undefined });
    expect(noUrl?.[0]).not.toHaveProperty("footer");
  });

  it("keeps a whole binding's type", () => {
    const stats = checkCardFile(
      {
        format: 1,
        card: "Stats",
        chart: {
          type: "bar",
          labels: "{{result.days}}",
          series: [{ values: "{{result.counts}}" }],
        },
      },
      "s",
    );
    const out = fillCard(stats, { days: ["Mon", "Tue"], counts: [3, 5] });
    expect(out?.[0]?.chart).toEqual({
      type: "bar",
      labels: ["Mon", "Tue"],
      series: [{ values: [3, 5] }],
    });
  });

  it("is null when `when` has no value, and refuses a fill that doesn't check", () => {
    expect(fillCard(card, { title: "x" })).toBeNull();
    expect(fillCard(card, "plain text")).toBeNull();
    const event = checkCardFile(
      { format: 1, card: "Event", title: "{{result.title}}", start: "{{result.start}}" },
      "e",
    );
    expect(() => fillCard(event, { title: "Lunch", start: "soon" })).toThrow(UiCheckError);
    expect(() => fillCard(event, { title: "Lunch" })).toThrow(/needs start/);
    expect(fillCard(event, { title: "Lunch", start: "2026-11-20T12:00" })?.[0]).toMatchObject({
      title: "Lunch",
      start: "2026-11-20T12:00",
    });
  });

  it("reads structured content, else the text as JSON, else the text", () => {
    expect(cardResult({ a: 1 }, "ignored")).toEqual({ a: 1 });
    expect(cardResult(undefined, ' {"a": 2} ')).toEqual({ a: 2 });
    expect(cardResult(undefined, "hello")).toBe("hello");
    expect(cardResult(undefined, "{not json")).toBe("{not json");
  });
});
