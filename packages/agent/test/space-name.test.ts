/** A new workspace's name from its owner's first name (welcome.ts spaceName). */
import { describe, expect, it } from "vitest";
import { spaceName } from "../src/welcome.ts";

describe("spaceName", () => {
  it("names it after the person, capitalised", () => {
    expect(spaceName("oliver")).toBe("Oliver's space");
    expect(spaceName("  Ana  ")).toBe("Ana's space");
    expect(spaceName("mary   jane")).toBe("Mary jane's space");
    expect(spaceName("élodie")).toBe("Élodie's space");
    expect(spaceName("James")).toBe("James's space");
  });

  it("with no usable name it is just My space", () => {
    expect(spaceName("")).toBe("My space");
    expect(spaceName("   ")).toBe("My space");
    expect(spaceName("...")).toBe("My space");
    expect(spaceName("'")).toBe("My space");
  });

  it("doesn't double an apostrophe", () => {
    expect(spaceName("Chris'")).toBe("Chris's space");
    expect(spaceName("Chris’")).toBe("Chris's space");
  });

  it("fits 80 characters by cutting the name, never the suffix or a character", () => {
    const long = spaceName("a".repeat(200));
    expect(long).toHaveLength(80);
    expect(long.endsWith("'s space")).toBe(true);
    const emoji = spaceName("a😀".repeat(60));
    expect(emoji.endsWith("'s space")).toBe(true);
    expect(emoji).not.toMatch(/[\uD800-\uDBFF](?![\uDC00-\uDFFF])/);
  });
});
