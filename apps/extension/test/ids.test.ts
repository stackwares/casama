import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { DEV_EXTENSION_ID, EDGE_EXTENSION_ID } from "../src/manifest.ts";

const read = (path: string) => readFileSync(new URL(`../../../${path}`, import.meta.url), "utf8");

describe("Casama for Chrome's id", () => {
  it("is the one the server, the compose file and the web app allow", () => {
    // Whitespace-blind: the formatter may wrap the zod chain over several lines.
    expect(read("apps/server/src/env.ts").replace(/\s+/g, "")).toContain(
      `CHROME_EXTENSION_IDS:z.string().default("${DEV_EXTENSION_ID},${EDGE_EXTENSION_ID}")`,
    );
    expect(read("infra/compose/docker-compose.yml")).toContain(
      `CHROME_EXTENSION_IDS: \${CHROME_EXTENSION_IDS:-${DEV_EXTENSION_ID},${EDGE_EXTENSION_ID}}`,
    );
    expect(read("client/lib/core/chrome_extension.dart")).toContain(
      `const chromeExtensionIds = ['${DEV_EXTENSION_ID}', '${EDGE_EXTENSION_ID}'];`,
    );
  });
});
