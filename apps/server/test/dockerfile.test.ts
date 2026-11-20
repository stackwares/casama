/**
 * The server image runs the sources straight from the repo layout, so every folder the server reads at
 * runtime must be copied into it. A missing one fails silently in production: without `skills/` the
 * skill catalog came back empty (categories live in skills/catalog.json).
 */
import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";

const dockerfile = readFileSync(new URL("../Dockerfile", import.meta.url), "utf8");
const copied = dockerfile
  .split("\n")
  .filter((l) => l.startsWith("COPY ") && !l.includes("--from="))
  .flatMap((l) => l.slice(5).trim().split(/\s+/).slice(0, -1));

describe("server Dockerfile", () => {
  it.each([
    "skills", // loadCatalog(), D-104
    "packages/contracts/support", // loadSupportPlaces(), D-431
    "client/assets/apps", // app-logos.ts
  ])("copies %s, which the server reads at runtime", (dir) => {
    expect(copied).toContain(dir);
  });
});
