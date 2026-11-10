/**
 * Skills library (D-104): the bundled catalog (`skills/` in the repo), GitHub import pinned to a
 * commit, and installing a skill's SKILL.md plus files into a workspace or one bot.
 */
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { parseSkillMd, SkillFormatError } from "@kasama/domain";
import { ApiError } from "../api/errors.ts";

export const MAX_FILE_BYTES = 1024 * 1024;
export const MAX_SKILL_BYTES = 5 * 1024 * 1024;
export const MAX_FILES = 60;

export interface SkillBundle {
  name: string;
  description: string;
  body: string;
  /** Extra files (everything but SKILL.md), relative to the skill folder. */
  files: Array<{ path: string; content: Buffer; executable: boolean }>;
  /** The raw SKILL.md, for previews and diffs. */
  skillMd: string;
}

export interface CatalogSkill extends SkillBundle {
  id: string;
  category: string;
}

const SAFE_PATH = /^[A-Za-z0-9._-]+(\/[A-Za-z0-9._-]+)*$/;

/** Checks a set of files against the limits and the safe-path rule. */
export function checkBundle(files: SkillBundle["files"]) {
  if (files.length > MAX_FILES)
    throw new ApiError(400, "skill_too_large", `A skill can have up to ${MAX_FILES} files.`);
  let total = 0;
  for (const f of files) {
    if (!SAFE_PATH.test(f.path) || f.path.split("/").includes(".."))
      throw new ApiError(400, "skill_bad_path", `Unsupported file name: ${f.path}`);
    if (f.content.length > MAX_FILE_BYTES)
      throw new ApiError(400, "skill_too_large", `${f.path} is over 1 MB.`);
    total += f.content.length;
  }
  if (total > MAX_SKILL_BYTES)
    throw new ApiError(400, "skill_too_large", "A skill's files can total up to 5 MB.");
}

export function bundleFrom(skillMd: string, files: SkillBundle["files"]): SkillBundle {
  try {
    const parsed = parseSkillMd(skillMd);
    checkBundle(files);
    return {
      name: parsed.name,
      description: parsed.description,
      body: parsed.body,
      files,
      skillMd,
    };
  } catch (err) {
    if (err instanceof SkillFormatError) throw new ApiError(400, "skill_invalid", err.message);
    throw err;
  }
}

// ---------------------------------------------------------------------------
// Catalog
// ---------------------------------------------------------------------------

const DEFAULT_CATALOG = fileURLToPath(new URL("../../../../skills", import.meta.url));

function walk(dir: string, root = dir): string[] {
  return readdirSync(dir).flatMap((e) => {
    const p = join(dir, e);
    return statSync(p).isDirectory() ? walk(p, root) : [relative(root, p)];
  });
}

let cache: { dir: string; skills: CatalogSkill[]; categories: string[] } | undefined;

/** The bundled skills, read once per process. */
export function loadCatalog(dir = process.env.SKILLS_CATALOG_DIR ?? DEFAULT_CATALOG) {
  if (cache?.dir === dir) return cache;
  if (!existsSync(join(dir, "catalog.json"))) return { dir, skills: [], categories: [] };
  const index = JSON.parse(readFileSync(join(dir, "catalog.json"), "utf8")) as {
    categories: string[];
    skills: Record<string, string>;
  };
  const skills: CatalogSkill[] = [];
  for (const [id, category] of Object.entries(index.skills)) {
    const folder = join(dir, id);
    const files = walk(folder)
      .filter((p) => p !== "SKILL.md")
      .map((p) => ({
        path: p.split("\\").join("/"),
        content: readFileSync(join(folder, p)),
        executable: (statSync(join(folder, p)).mode & 0o111) !== 0,
      }));
    skills.push({
      id,
      category,
      ...bundleFrom(readFileSync(join(folder, "SKILL.md"), "utf8"), files),
    });
  }
  cache = { dir, skills, categories: index.categories };
  return cache;
}

// ---------------------------------------------------------------------------
// GitHub
// ---------------------------------------------------------------------------

export interface GitHubRef {
  owner: string;
  repo: string;
  ref: string | null;
  path: string;
}

/** github.com/owner/repo[/tree|blob/ref[/path]] → its parts. */
export function parseGitHubUrl(url: string): GitHubRef {
  let u: URL;
  try {
    u = new URL(url.trim());
  } catch {
    throw new ApiError(
      400,
      "github_url_invalid",
      "Paste a github.com link to a repository or folder.",
    );
  }
  if (u.hostname !== "github.com" && u.hostname !== "www.github.com")
    throw new ApiError(
      400,
      "github_url_invalid",
      "Paste a github.com link to a repository or folder.",
    );
  const parts = u.pathname.split("/").filter(Boolean);
  if (parts.length < 2)
    throw new ApiError(400, "github_url_invalid", "The link needs an owner and a repository.");
  const [owner, repoRaw, kind, ref, ...rest] = parts;
  const repo = (repoRaw as string).replace(/\.git$/, "");
  let path = kind === "tree" || kind === "blob" ? rest.join("/") : "";
  if (path.endsWith("SKILL.md")) path = path.slice(0, -"SKILL.md".length).replace(/\/$/, "");
  return {
    owner: owner as string,
    repo,
    ref: kind === "tree" || kind === "blob" ? (ref ?? null) : null,
    path,
  };
}

export class GitHubReader {
  private readonly opts: { apiUrl?: string; token?: string | null; fetch?: typeof fetch };
  constructor(opts: { apiUrl?: string; token?: string | null; fetch?: typeof fetch } = {}) {
    this.opts = opts;
  }

  private async get<T>(path: string): Promise<T> {
    const res = await (this.opts.fetch ?? fetch)(
      `${this.opts.apiUrl ?? "https://api.github.com"}${path}`,
      {
        headers: {
          accept: "application/vnd.github+json",
          "user-agent": "kasama-skills",
          ...(this.opts.token ? { authorization: `Bearer ${this.opts.token}` } : {}),
        },
      },
    );
    if (res.status === 404)
      throw new ApiError(
        404,
        "github_not_found",
        "Not found on GitHub. For a private repository, add a GITHUB_TOKEN secret allowed for api.github.com.",
      );
    if (!res.ok) throw new ApiError(502, "github_error", `GitHub answered ${res.status}.`);
    return (await res.json()) as T;
  }

  /** The commit a ref points at (default branch when none). */
  async resolveCommit(r: GitHubRef): Promise<string> {
    const ref =
      r.ref ??
      (await this.get<{ default_branch: string }>(`/repos/${r.owner}/${r.repo}`)).default_branch;
    return (
      await this.get<{ sha: string }>(
        `/repos/${r.owner}/${r.repo}/commits/${encodeURIComponent(ref)}`,
      )
    ).sha;
  }

  /** All files under r.path at a commit, paths relative to it. */
  async fetchFolder(r: GitHubRef, commit: string, limits: { maxFiles: number; maxBytes: number }) {
    if (!/^[0-9a-f]{40}$/.test(commit))
      throw new ApiError(400, "github_commit_invalid", "Not a commit id.");
    const tree = await this.get<{
      tree: Array<{ path: string; type: string; sha: string; size?: number; mode: string }>;
    }>(`/repos/${r.owner}/${r.repo}/git/trees/${commit}?recursive=1`);
    const prefix = r.path ? `${r.path}/` : "";
    const blobs = tree.tree.filter(
      (e) => e.type === "blob" && e.path.startsWith(prefix) && e.mode !== "120000",
    );
    if (blobs.length > limits.maxFiles)
      throw new ApiError(
        400,
        "plugin_too_large",
        `A plugin can have up to ${limits.maxFiles} files.`,
      );
    if (blobs.reduce((n, e) => n + (e.size ?? 0), 0) > limits.maxBytes)
      throw new ApiError(
        400,
        "plugin_too_large",
        `A plugin's files can total up to ${limits.maxBytes / 1024 / 1024} MB.`,
      );
    return Promise.all(
      blobs.map(async (e) => {
        const b = await this.get<{ content: string; encoding: string }>(
          `/repos/${r.owner}/${r.repo}/git/blobs/${e.sha}`,
        );
        return {
          path: e.path.slice(prefix.length),
          content: Buffer.from(b.content, b.encoding === "base64" ? "base64" : "utf8"),
          executable: e.mode === "100755",
        };
      }),
    );
  }

  /** The skill folder at a commit: SKILL.md plus its files, within the limits. */
  async fetchSkill(r: GitHubRef, commit: string): Promise<SkillBundle> {
    if (!/^[0-9a-f]{40}$/.test(commit))
      throw new ApiError(400, "github_commit_invalid", "Not a commit id.");
    const tree = await this.get<{
      tree: Array<{ path: string; type: string; sha: string; size?: number; mode: string }>;
      truncated: boolean;
    }>(`/repos/${r.owner}/${r.repo}/git/trees/${commit}?recursive=1`);
    const prefix = r.path ? `${r.path}/` : "";
    const blobs = tree.tree.filter((e) => e.type === "blob" && e.path.startsWith(prefix));
    const md = blobs.find((e) => e.path === `${prefix}SKILL.md`);
    if (!md)
      throw new ApiError(
        400,
        "skill_invalid",
        `No SKILL.md in ${r.path || "the repository root"}.`,
      );
    const others = blobs.filter((e) => e !== md);
    if (others.length > MAX_FILES)
      throw new ApiError(400, "skill_too_large", `A skill can have up to ${MAX_FILES} files.`);
    const total = others.reduce((n, e) => n + (e.size ?? 0), 0);
    if (total > MAX_SKILL_BYTES)
      throw new ApiError(400, "skill_too_large", "A skill's files can total up to 5 MB.");
    const blob = async (sha: string) => {
      const b = await this.get<{ content: string; encoding: string }>(
        `/repos/${r.owner}/${r.repo}/git/blobs/${sha}`,
      );
      return Buffer.from(b.content, b.encoding === "base64" ? "base64" : "utf8");
    };
    const files = await Promise.all(
      others.map(async (e) => ({
        path: e.path.slice(prefix.length),
        content: await blob(e.sha),
        executable: e.mode === "100755",
      })),
    );
    return bundleFrom((await blob(md.sha)).toString("utf8"), files);
  }
}

/** Every file under a folder at a commit (plugins, D-121), within the limits. */
export async function fetchGitHubFolder(
  reader: GitHubReader,
  r: GitHubRef,
  commit: string,
  limits: { maxFiles: number; maxBytes: number },
) {
  return reader.fetchFolder(r, commit, limits);
}

/** Text files are shown in previews; binaries just by size. */
export const isText = (b: Buffer) => !b.subarray(0, 8000).includes(0);
