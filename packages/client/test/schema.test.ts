import { readFileSync } from "node:fs";
import { expect, it } from "vitest";
import { generateSchema, OUT } from "../scripts/schema.ts";

it("src/generated/schema.ts matches openapi.json (run `pnpm --filter @casama/client gen`)", async () => {
  const fresh = await generateSchema();
  expect(readFileSync(OUT, "utf8") === fresh).toBe(true);
}, 60_000);
