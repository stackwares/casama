/**
 * Builds the page agent to one IIFE (dist/page-agent.js) and copies it to the app's assets.
 * `--check` builds in memory and fails when the app's copy differs. The output is deterministic.
 */
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { build, type Plugin, type Rollup } from "vite";
import { EXTRACT_TABLES_JS } from "../../contracts/src/browser-scripts.ts";

const here = dirname(fileURLToPath(import.meta.url));
const pkg = join(here, "..");
const dist = join(pkg, "dist", "page-agent.js");
const asset = join(pkg, "..", "..", "client", "assets", "app_browser", "page_agent.js");

const HEADER =
  "// Casama page agent (packages/page-agent). Generated: edit the source and run\n" +
  "// `pnpm --filter @casama/page-agent build`. See packages/page-agent/README.md.\n";

/** `EXTRACT_TABLES_JS` as a function, so the agent never evaluates a string at run time. */
const extractTables: Plugin = {
  name: "extract-tables",
  resolveId: (id) => (id === "virtual:extract-tables" ? "\0virtual:extract-tables" : null),
  load: (id) =>
    id === "\0virtual:extract-tables"
      ? `export default function extractTables() {\n  return ${EXTRACT_TABLES_JS};\n}\n`
      : null,
};

export async function bundle(): Promise<string> {
  const out = (await build({
    configFile: false,
    root: pkg,
    logLevel: "warn",
    plugins: [extractTables],
    build: {
      write: false,
      minify: false,
      sourcemap: false,
      target: "es2020",
      reportCompressedSize: false,
      lib: {
        entry: join(pkg, "src", "main.ts"),
        formats: ["iife"],
        name: "casamaPageAgentBundle",
        fileName: () => "page-agent.js",
      },
    },
  })) as Rollup.RollupOutput[] | Rollup.RollupOutput;
  const outputs = Array.isArray(out) ? out : [out];
  const chunk = outputs.flatMap((o) => o.output).find((o) => o.type === "chunk");
  if (chunk?.type !== "chunk") throw new Error("The build gave no script.");
  return HEADER + chunk.code;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  const code = await bundle();
  if (process.argv.includes("--check")) {
    let current = "";
    try {
      current = readFileSync(asset, "utf8");
    } catch {}
    if (current !== code) {
      console.error(
        "client/assets/app_browser/page_agent.js is stale. Run `pnpm --filter @casama/page-agent build`.",
      );
      process.exit(1);
    }
    console.log("page_agent.js is up to date.");
  } else {
    mkdirSync(dirname(dist), { recursive: true });
    mkdirSync(dirname(asset), { recursive: true });
    writeFileSync(dist, code);
    writeFileSync(asset, code);
    console.log(`Wrote ${dist} and the app asset (${code.length} bytes).`);
  }
}
