import { describe, expect, it } from "vitest";
import { parseMentions } from "../src/mentions.ts";

const bots = [
  { id: "a", name: "Ada" },
  { id: "al", name: "Ada Lovelace" },
  { id: "w", name: "Writer" },
];

describe("parseMentions", () => {
  it("finds bots by name, longest first, in text order", () => {
    expect(parseMentions("@Writer draft it, @Ada Lovelace check it", bots)).toEqual({ everyone: false, botIds: ["w", "al"] });
    expect(parseMentions("ask @ada.", bots).botIds).toEqual(["a"]);
    expect(parseMentions("email me@ada.com or @Adam", bots).botIds).toEqual([]);
  });

  it("notices @everyone", () => {
    expect(parseMentions("@everyone let's plan the launch", bots)).toEqual({ everyone: true, botIds: [] });
    expect(parseMentions("hi team", bots).everyone).toBe(false);
  });
});
