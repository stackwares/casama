import { describe, expect, it } from "vitest";
import { mailBaseName, mailNameIssue, splitMailTag, suggestMailNames } from "../src/index.ts";

describe("hosted mail names", () => {
  it("accepts plain names", () => {
    for (const n of ["ada", "ada.oliver", "front-desk_2", "a1b", "x".repeat(40)])
      expect(mailNameIssue(n)).toBeNull();
  });

  it("rejects bad shapes with the app's words", () => {
    expect(mailNameIssue("")).toBe("Give the address a name.");
    expect(mailNameIssue("ab")).toContain("3 to 40");
    expect(mailNameIssue("x".repeat(41))).toContain("3 to 40");
    expect(mailNameIssue(".ada")).toContain("lowercase letters");
    expect(mailNameIssue("ada.")).toContain("lowercase letters");
    expect(mailNameIssue("ad..a")).toContain("lowercase letters");
    expect(mailNameIssue("Ad a!")).toContain("lowercase letters");
  });

  it("reserves roles, Casama's names and brands", () => {
    for (const n of ["admin", "support", "postmaster", "noreply", "casama", "paypal", "gmail"])
      expect(mailNameIssue(n)).toBe("That name is reserved. Pick another.");
    expect(mailNameIssue("custom", ["custom"])).toBe("That name is reserved. Pick another.");
  });

  it("builds a base from the bot's name", () => {
    expect(mailBaseName("Ada")).toBe("ada");
    expect(mailBaseName("Front Desk!")).toBe("front.desk");
    expect(mailBaseName("Café")).toBe("cafe");
    expect(mailBaseName("Al")).toBe("al.bot");
    expect(mailBaseName("!!!")).toBe("assistant");
  });

  it("suggests the bot's name, then owner variants, then numbered", () => {
    expect(suggestMailNames("Ada", "Oliver Martinez", () => false)).toEqual([
      "ada",
      "ada.oliver",
      "ada.martinez",
    ]);
    const taken = new Set(["ada", "ada.oliver", "ada.martinez", "ada.bot"]);
    expect(suggestMailNames("Ada", "Oliver Martinez", (n) => taken.has(n))).toEqual([
      "ada2",
      "ada3",
      "ada4",
    ]);
  });

  it("splits plus tags", () => {
    expect(splitMailTag("ada+shop@x.com")).toEqual({ name: "ada", tag: "shop" });
    expect(splitMailTag("Ada@x.com")).toEqual({ name: "ada", tag: "" });
  });
});
