/**
 * Checks an Agent Plugins 1.0 package before it's published, with the same code Kasama runs when
 * someone installs it (`checkPlugin` and the skill rules from @kasama/domain), plus a few tips for
 * things that install fine but would fail at run time on the bot's computer.
 *
 * The domain files are imported by relative path, so this runs with plain Node 24 and nothing
 * installed (the GitHub Action relies on that).
 */
import { execFileSync } from "node:child_process";
import { existsSync, lstatSync, readdirSync, readFileSync } from "node:fs";
import { join, relative, sep } from "node:path";
import {
  type CheckedPlugin,
  checkPlugin,
  PLUGIN_MAX_BYTES,
  PLUGIN_MAX_FILES,
  PluginError,
} from "../../domain/src/agent-plugins.ts";
import {
  parseSkillMd,
  SKILL_MAX_FILE_BYTES,
  SKILL_MAX_FILES,
  SKILL_MAX_TOTAL_BYTES,
  SKILL_SAFE_PATH,
} from "../../domain/src/skill-format.ts";

export interface PluginFile {
  /** Relative to the plugin root, with forward slashes and no leading "./". */
  path: string;
  content: Buffer;
  executable: boolean;
}

export interface CheckResult {
  /** False when Kasama would refuse to install the plugin. */
  ok: boolean;
  /** Why Kasama would refuse it. */
  errors: string[];
  /** What Kasama would skip or ignore (it still installs). */
  warnings: string[];
  /** Installs fine, but likely to fail or surprise on the bot's computer. */
  tips: string[];
  plugin?: CheckedPlugin;
  skills: Array<{ name: string; description: string }>;
  files: number;
  bytes: number;
}

/** Programs the default computer image has (infra/images/computer/Dockerfile.headless). */
export const IMAGE_PROGRAMS = new Set([
  "node",
  "npm",
  "npx",
  "python3",
  "pip3",
  "bash",
  "sh",
  "git",
  "curl",
  "wget",
  "jq",
  "rg",
  "chrome",
  "agent-browser",
  "playwright",
]);

const isText = (b: Buffer) => !b.subarray(0, 8000).includes(0);

/**
 * Reads a plugin folder the way Kasama sees it on GitHub: in a git checkout, only the files git
 * tracks (with their executable bit); otherwise every file except .git. Symlinks are left out,
 * as Kasama leaves them out.
 */
export function readPluginFolder(dir: string): {
  files: PluginFile[];
  symlinks: string[];
  fromGit: boolean;
  /** In a git checkout: files not committed yet, which GitHub (and so Kasama) won't see. */
  untracked: string[];
} {
  const symlinks: string[] = [];
  try {
    const out = execFileSync("git", ["-C", dir, "ls-files", "-s", "-z", "--", "."], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    });
    const entries = out.split("\0").filter(Boolean);
    if (entries.length) {
      const files: PluginFile[] = [];
      for (const e of entries) {
        const m = /^(\d+) [0-9a-f]+ \d+\t(.*)$/.exec(e);
        if (!m) continue;
        const [, mode, path] = m as unknown as [string, string, string];
        if (mode === "120000") {
          symlinks.push(path);
          continue;
        }
        if (mode === "160000") continue; // a submodule: not part of the package on GitHub
        const full = join(dir, path);
        if (!existsSync(full)) continue; // deleted in the working tree
        files.push({ path, content: readFileSync(full), executable: mode === "100755" });
      }
      let untracked: string[] = [];
      try {
        untracked = execFileSync(
          "git",
          ["-C", dir, "ls-files", "-o", "--exclude-standard", "-z", "--", "."],
          {
            encoding: "utf8",
            stdio: ["ignore", "pipe", "ignore"],
          },
        )
          .split("\0")
          .filter(Boolean);
      } catch {}
      return { files, symlinks, fromGit: true, untracked };
    }
  } catch {
    // Not a git checkout (or no git): read the folder.
  }
  const files: PluginFile[] = [];
  const walk = (d: string) => {
    for (const name of readdirSync(d)) {
      if (name === ".git") continue;
      const full = join(d, name);
      const st = lstatSync(full);
      const rel = relative(dir, full).split(sep).join("/");
      if (st.isSymbolicLink()) symlinks.push(rel);
      else if (st.isDirectory()) walk(full);
      else if (st.isFile())
        files.push({ path: rel, content: readFileSync(full), executable: (st.mode & 0o111) !== 0 });
    }
  };
  walk(dir);
  return { files, symlinks, fromGit: false, untracked: [] };
}

/** Checks a plugin's files (no I/O). */
export function checkFiles(
  files: PluginFile[],
  opts: { symlinks?: string[]; untracked?: string[] } = {},
): CheckResult {
  const errors: string[] = [];
  const warnings: string[] = [];
  const tips: string[] = [];
  const bytes = files.reduce((n, f) => n + f.content.length, 0);
  const result = (plugin?: CheckedPlugin, skills: CheckResult["skills"] = []): CheckResult => ({
    ok: errors.length === 0,
    errors,
    warnings,
    tips,
    plugin,
    skills,
    files: files.length,
    bytes,
  });

  const untracked = opts.untracked ?? [];
  if (untracked.length)
    tips.push(
      `${untracked.length} file${untracked.length === 1 ? " isn't" : "s aren't"} committed (${untracked.slice(0, 3).join(", ")}${untracked.length > 3 ? ", …" : ""}); Kasama installs what's on GitHub, so commit and push them`,
    );
  for (const s of opts.symlinks ?? [])
    warnings.push(`Left out ${s}: Kasama doesn't install symlinks`);
  if (files.length > PLUGIN_MAX_FILES)
    errors.push(`The plugin has ${files.length} files; Kasama installs up to ${PLUGIN_MAX_FILES}`);
  if (bytes > PLUGIN_MAX_BYTES)
    errors.push(
      `The plugin is ${(bytes / 1024 / 1024).toFixed(1)} MB; Kasama installs up to ${PLUGIN_MAX_BYTES / 1024 / 1024} MB`,
    );

  const byPath = new Map(files.map((f) => [f.path, f]));
  const texts = new Map(
    files.filter((f) => isText(f.content)).map((f) => [f.path, f.content.toString("utf8")]),
  );
  let plugin: CheckedPlugin;
  try {
    plugin = checkPlugin(texts);
  } catch (err) {
    if (err instanceof PluginError) {
      errors.push(err.message);
      return result();
    }
    throw err;
  }
  warnings.push(...plugin.warnings);

  // Skills: a broken one is skipped at install, like Kasama does.
  const skills: CheckResult["skills"] = [];
  for (const s of plugin.skills) {
    const prefix = `${s.path}/`;
    const skip = (why: string) => warnings.push(`Skipped skill ${s.name}: ${why}`);
    let parsed: ReturnType<typeof parseSkillMd>;
    try {
      parsed = parseSkillMd(texts.get(`${prefix}SKILL.md`) ?? "");
    } catch (err) {
      skip((err as Error).message);
      continue;
    }
    const extra = files.filter((f) => f.path.startsWith(prefix) && f.path !== `${prefix}SKILL.md`);
    const rel = (f: PluginFile) => f.path.slice(prefix.length);
    const badPath = extra.find(
      (f) => !SKILL_SAFE_PATH.test(rel(f)) || rel(f).split("/").includes(".."),
    );
    const big = extra.find((f) => f.content.length > SKILL_MAX_FILE_BYTES);
    const total = extra.reduce((n, f) => n + f.content.length, 0);
    if (extra.length > SKILL_MAX_FILES)
      skip(`a skill can have up to ${SKILL_MAX_FILES} files besides SKILL.md`);
    else if (badPath) skip(`unsupported file name ${rel(badPath)} (letters, digits, . _ - and /)`);
    else if (big) skip(`${rel(big)} is over 1 MB`);
    else if (total > SKILL_MAX_TOTAL_BYTES) skip("a skill's files can total up to 5 MB");
    else {
      if (parsed.name !== s.name)
        tips.push(
          `Skill folder ${s.name} is named "${parsed.name}" in its SKILL.md; Kasama uses the SKILL.md name`,
        );
      skills.push({ name: parsed.name, description: parsed.description });
    }
  }

  // Run-time tips for servers that run on the bot's computer.
  for (const srv of plugin.servers) {
    if (srv.type !== "stdio") continue;
    if (srv.command.startsWith("./")) {
      const f = byPath.get(srv.command.slice(2).replace(/^\.\//, ""));
      if (!f) tips.push(`Server ${srv.key}: ${srv.command} isn't in the plugin, so it won't start`);
      else if (!f.executable)
        tips.push(
          `Server ${srv.key}: ${srv.command} isn't executable; run git update-index --chmod=+x on it, or start it with node or python3`,
        );
    } else if (!IMAGE_PROGRAMS.has(srv.command)) {
      tips.push(
        `Server ${srv.key}: "${srv.command}" isn't in Kasama's default computer image (Node.js 24, Python 3, bash). Ship it inside the plugin and point at it with ./`,
      );
    }
    for (const a of srv.args) {
      const m = /^\$\{PLUGIN_ROOT\}\/(.+)$/.exec(a);
      if (m && !byPath.has(m[1] as string) && !files.some((f) => f.path.startsWith(`${m[1]}/`)))
        tips.push(`Server ${srv.key}: ${a} isn't in the plugin`);
    }
    if (srv.command === "npx" || srv.command === "npm")
      tips.push(
        `Server ${srv.key}: ${srv.command} downloads packages the first time it starts, and the server has 30 seconds to answer initialize. Bundling the server into the plugin starts faster and pins what runs`,
      );
  }
  if (!plugin.servers.length && !skills.length)
    warnings.push("The plugin has no working skills or MCP servers, so it adds nothing");
  return result(plugin, skills);
}

/** Reads and checks a plugin folder. */
export function checkPluginFolder(dir: string) {
  const { files, symlinks, fromGit, untracked } = readPluginFolder(dir);
  return { ...checkFiles(files, { symlinks, untracked }), fromGit };
}
