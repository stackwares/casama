import { writeFileSync } from "node:fs";
import { generateSchema, OUT } from "./schema.ts";

writeFileSync(OUT, await generateSchema());
console.log(`Wrote ${OUT}`);
