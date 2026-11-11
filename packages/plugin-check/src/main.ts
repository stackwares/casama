#!/usr/bin/env node
/**
 * casama-plugin-check [folder] [--json] [--strict]
 *
 * Checks a plugin folder the way Casama checks it at install. Exits 1 when Casama would refuse
 * it; with --strict, also when anything would be skipped or ignored (for CI).
 */
import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { checkPluginFolder } from "./check.ts";

const args = process.argv.slice(2);
if (args.includes("--help") || args.includes("-h")) {
  console.log(`Usage: casama-plugin-check [folder] [--json] [--strict]

Checks an Agent Plugins 1.0 package (plugin.json, mcp.json, skills/) the way Casama checks it
when someone installs it from GitHub.

  --json    print the result as JSON
  --strict  also fail when Casama would skip or ignore something`);
  process.exit(0);
}
const dir = resolve(args.find((a) => !a.startsWith("--")) ?? ".");
if (!existsSync(dir)) {
  console.error(`No folder at ${dir}`);
  process.exit(2);
}
const r = checkPluginFolder(dir);
const strict = args.includes("--strict");
const failed = !r.ok || (strict && r.warnings.length > 0);

if (args.includes("--json")) {
  const { plugin, ...rest } = r;
  console.log(
    JSON.stringify(
      {
        ...rest,
        manifest: plugin?.manifest,
        servers: plugin?.servers,
        secrets: plugin?.secrets,
        hosts: plugin?.hosts,
      },
      null,
      2,
    ),
  );
  process.exit(failed ? 1 : 0);
}

const color = process.stdout.isTTY && !process.env.NO_COLOR;
const paint = (code: string, s: string) => (color ? `\x1b[${code}m${s}\x1b[0m` : s);
const red = (s: string) => paint("31", s);
const yellow = (s: string) => paint("33", s);
const green = (s: string) => paint("32", s);
const dim = (s: string) => paint("2", s);
const list = (title: string, items: string[], mark: string) => {
  if (!items.length) return;
  console.log(`\n${title}`);
  for (const i of items) console.log(`  ${mark} ${i}`);
};

const p = r.plugin;
if (p) {
  console.log(`${p.manifest.name}${p.manifest.version ? ` ${p.manifest.version}` : ""}`);
  if (p.manifest.description) console.log(dim(p.manifest.description));
}
console.log(
  dim(
    `${r.files} files, ${(r.bytes / 1024).toFixed(1)} KB${r.fromGit ? " (as committed in git)" : ""}`,
  ),
);
if (p) {
  list(
    "Skills",
    r.skills.map((s) => `${s.name}: ${s.description}`),
    "•",
  );
  list(
    "MCP servers",
    p.servers.map((s) =>
      s.type === "stdio"
        ? `${s.key} (runs on the bot's computer): ${[s.command, ...s.args].join(" ")}`
        : `${s.key} (${s.type}): ${s.url}`,
    ),
    "•",
  );
  list(
    "Secrets the person installing it is asked for",
    p.secrets.map(
      (s) =>
        `${s.name} → ${s.server} ${s.env ? `env ${s.env}` : `header ${s.header}`}${s.description ? dim(` (${s.description})`) : ""}`,
    ),
    "•",
  );
  list("Network hosts", p.hosts, "•");
}
list(red("Casama would refuse it"), r.errors, red("✗"));
list(yellow("Casama would skip or ignore"), r.warnings, yellow("!"));
list("Tips", r.tips, "→");
console.log(
  `\n${
    !r.ok
      ? red("✗ Not installable. Fix the errors above.")
      : r.warnings.length
        ? yellow(
            `! Installable, with ${r.warnings.length} warning${r.warnings.length === 1 ? "" : "s"}.`,
          )
        : green("✓ Ready to install.")
  }`,
);
process.exit(failed ? 1 : 0);
