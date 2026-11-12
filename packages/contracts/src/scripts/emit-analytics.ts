import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dartCatalog } from "../analytics.ts";

const out = fileURLToPath(
  new URL("../../../../client/lib/core/analytics_events.g.dart", import.meta.url),
);
writeFileSync(out, dartCatalog());
console.log(`wrote ${out}`);
