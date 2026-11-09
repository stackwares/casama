import { describe, expect, it } from "vitest";
import { assignableRoles, roleAtLeast, SLUG_PATTERN, slugify } from "../src/index.ts";

describe("slugify", () => {
  it.each([
    ["Acme Team", "acme-team"],
    ["  Kape't Kasama!! ", "kape-t-kasama"],
    ["Pañuelo Café", "panuelo-cafe"],
    ["???", "org"],
    ["a".repeat(60), "a".repeat(40)],
  ])("%s -> %s", (input, out) => {
    expect(slugify(input)).toBe(out);
    expect(SLUG_PATTERN.test(slugify(input))).toBe(true);
  });
});

describe("roles", () => {
  it("orders owner > admin > member", () => {
    expect(roleAtLeast("owner", "admin")).toBe(true);
    expect(roleAtLeast("admin", "admin")).toBe(true);
    expect(roleAtLeast("member", "admin")).toBe(false);
  });
  it("only owners assign owner", () => {
    expect(assignableRoles("admin")).not.toContain("owner");
    expect(assignableRoles("member")).toEqual([]);
  });
});
