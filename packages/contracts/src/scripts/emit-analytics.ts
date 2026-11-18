import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dartCatalog, ga4TwinsSource } from "../analytics.ts";

const out = fileURLToPath(
  new URL("../../../../client/lib/core/analytics_events.g.dart", import.meta.url),
);
writeFileSync(out, dartCatalog());
console.log(`wrote ${out}`);

const twinsOut = fileURLToPath(new URL("../ga4-twins.generated.ts", import.meta.url));
writeFileSync(twinsOut, ga4TwinsSource());
console.log(`wrote ${twinsOut}`);
