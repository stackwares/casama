/**
 * Git sync for routines and skills (D-124). Each sync compares three versions of every file: what
 * was synced last time, what Casama has now, and what the repo has now.
 * - Changed only in Casama: committed to the branch.
 * - Changed only in the repo: checked and applied to Casama (bad files are skipped and reported).
 * - Changed on both sides: Casama keeps its version and opens a pull request with it, so the repo
 *   owner decides; merging it makes both sides agree again.
 * Uses the workspace's GITHUB_TOKEN secret (allowed for api.github.com).
 */
import { createHash } from "node:crypto";
import type { Database } from "@casama/db";
import { INDEX_FILE } from "@casama/domain";
import { sql } from "drizzle-orm";
import { applyWorkspaceFiles, exportWorkspaceFiles } from "./workspace-files.ts";

type Synced = Record<string, { git: string; hash: string }>;

const sha256 = (b: Uint8Array) => createHash("sha256").update(b).digest("hex");
/** The id git gives a file's content. */
export const gitBlobSha = (b: Uint8Array) =>
  createHash("sha1").update(`blob ${b.byteLength}\0`).update(b).digest("hex");
const same = (a?: Uint8Array, b?: Uint8Array) =>
  !!a && !!b && Buffer.compare(Buffer.from(a), Buffer.from(b)) === 0;

export class GitSyncError extends Error {}

class GitHub {
  private readonly repo: string;
  private readonly token: string;
  private readonly api: string;
  private readonly fetchImpl: typeof fetch;
  constructor(repo: string, token: string, api: string, fetchImpl: typeof fetch) {
    this.repo = repo;
    this.token = token;
    this.api = api;
    this.fetchImpl = fetchImpl;
  }

  async call<T>(method: string, path: string, body?: unknown): Promise<T> {
    const res = await this.fetchImpl(`${this.api}/repos/${this.repo}${path}`, {
      method,
      headers: {
        accept: "application/vnd.github+json",
        authorization: `Bearer ${this.token}`,
        "user-agent": "casama-git-sync",
        ...(body ? { "content-type": "application/json" } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    if (res.status === 404)
      throw new GitSyncError(
        `GitHub: ${path.split("?")[0]} not found (check the repository, branch and token access)`,
      );
    if (!res.ok)
      throw new GitSyncError(`GitHub answered ${res.status} for ${method} ${path.split("?")[0]}`);
    return (await res.json()) as T;
  }
}

export interface GitSyncDeps {
  db: Database;
  fetch: typeof fetch;
  /** GitHub's API (a fake in tests). */
  apiUrl?: string;
}

export interface GitSyncReport {
  pushed: string[];
  pulled: string[];
  conflicts: string[];
  errors: string[];
  pullRequest: string | null;
}

/** Syncs one workspace; records the outcome on org_git_sync. */
export async function syncWorkspaceRepo(
  d: GitSyncDeps,
  orgId: string,
  now = new Date(),
): Promise<GitSyncReport> {
  const { db } = d;
  const [cfg] = await db.execute<{
    repo: string;
    branch: string;
    path: string;
    synced: Synced;
    open_pr_url: string | null;
  }>(
    sql`select repo, branch, path, synced, open_pr_url from public.org_git_sync where org_id = ${orgId}::uuid and enabled`,
  );
  if (!cfg) throw new GitSyncError("Git sync isn't set up for this workspace");
  const report: GitSyncReport = {
    pushed: [],
    pulled: [],
    conflicts: [],
    errors: [],
    pullRequest: cfg.open_pr_url,
  };
  try {
    const [tok] = await db.execute<{ token: string | null }>(sql`
      select v.decrypted_secret as token from public.secrets s join vault.decrypted_secrets v on v.id = s.vault_secret_id
      where s.org_id = ${orgId}::uuid and s.name = 'GITHUB_TOKEN' and 'api.github.com' = any(s.allowed_hosts)`);
    if (!tok?.token) throw new GitSyncError("Add a GITHUB_TOKEN secret allowed for api.github.com");
    const gh = new GitHub(cfg.repo, tok.token, d.apiUrl ?? "https://api.github.com", d.fetch);
    const prefix = cfg.path ? `${cfg.path.replace(/^\/+|\/+$/g, "")}/` : "";

    // The repo now.
    const ref = await gh.call<{ object: { sha: string } }>("GET", `/git/ref/heads/${cfg.branch}`);
    const head = ref.object.sha;
    const commit = await gh.call<{ tree: { sha: string } }>("GET", `/git/commits/${head}`);
    const tree = await gh.call<{ tree: Array<{ path: string; type: string; sha: string }> }>(
      "GET",
      `/git/trees/${commit.tree.sha}?recursive=1`,
    );
    const remoteSha = new Map(
      tree.tree
        .filter((e) => e.type === "blob" && e.path.startsWith(prefix))
        .map((e) => [e.path.slice(prefix.length), e.sha]),
    );
    const remote = new Map<string, Uint8Array>();
    const remoteBlob = async (p: string) => {
      if (remote.has(p)) return remote.get(p) as Uint8Array;
      const b = await gh.call<{ content: string; encoding: string }>(
        "GET",
        `/git/blobs/${remoteSha.get(p)}`,
      );
      const bytes = new Uint8Array(
        Buffer.from(b.content, b.encoding === "base64" ? "base64" : "utf8"),
      );
      remote.set(p, bytes);
      return bytes;
    };

    // Casama now.
    const local = await exportWorkspaceFiles(db, orgId);
    const synced = cfg.synced ?? {};
    const paths = new Set([...local.keys(), ...remoteSha.keys(), ...Object.keys(synced)]);
    const push = new Map<string, Uint8Array | null>();
    const pull = new Map<string, Uint8Array>();
    const pullDeleted: string[] = [];
    const conflicts = new Map<string, Uint8Array | null>();
    for (const p of paths) {
      const s = synced[p];
      const l = local.get(p);
      const rSha = remoteSha.get(p);
      const localChanged = s ? (l ? sha256(l) !== s.hash : true) : !!l;
      const remoteChanged = s ? rSha !== s.git : !!rSha;
      if (!localChanged && !remoteChanged) continue;
      if (localChanged && !remoteChanged) push.set(p, l ?? null);
      else if (remoteChanged && !localChanged) {
        if (rSha) pull.set(p, await remoteBlob(p));
        else pullDeleted.push(p);
      } else {
        const r = rSha ? await remoteBlob(p) : undefined;
        if ((l && r && same(l, r)) || (!l && !r)) continue;
        // casama.json changes on both sides are routine (a new bot); Casama's index wins quietly.
        if (p === INDEX_FILE) push.set(p, l ?? null);
        else conflicts.set(p, l ?? null);
      }
    }

    // Repo → Casama.
    if (pull.size || pullDeleted.length) {
      const incoming = new Map(local);
      for (const [p, b] of pull) incoming.set(p, b);
      // Only the changed files are applied; casama.json comes along so folders map to bots.
      const subset = new Map([...pull]);
      const idx = pull.get(INDEX_FILE) ?? local.get(INDEX_FILE);
      if (idx) subset.set(INDEX_FILE, idx);
      const r = await applyWorkspaceFiles(db, orgId, subset, {
        deletedPaths: pullDeleted,
        previous: local,
      });
      report.pulled.push(...r.created, ...r.updated, ...r.deleted);
      report.errors.push(...r.errors);
    }

    // Casama → repo.
    let newHead = head;
    const pushable = [...push].filter(
      ([p]) => p !== INDEX_FILE || push.size > 1 || !remoteSha.has(p),
    );
    if (pushable.length) {
      const t = await gh.call<{ sha: string }>("POST", "/git/trees", {
        base_tree: commit.tree.sha,
        tree: pushable.map(([p, b]) =>
          b
            ? {
                path: prefix + p,
                mode: "100644",
                type: "blob",
                content: Buffer.from(b).toString("utf8"),
              }
            : { path: prefix + p, mode: "100644", type: "blob", sha: null },
        ),
      });
      const c = await gh.call<{ sha: string }>("POST", "/git/commits", {
        message: `Update routines and skills from Casama\n\n${pushable.map(([p, b]) => `${b ? "update" : "delete"} ${p}`).join("\n")}`,
        tree: t.sha,
        parents: [head],
      });
      await gh.call("PATCH", `/git/refs/heads/${cfg.branch}`, { sha: c.sha, force: false });
      newHead = c.sha;
      report.pushed.push(...pushable.map(([p]) => p));
    }

    // Both changed: a pull request with Casama's version.
    if (conflicts.size) {
      const branch = `casama/sync-${now.toISOString().replace(/[-:]/g, "").slice(0, 15)}`;
      const base = await gh.call<{ tree: { sha: string } }>("GET", `/git/commits/${newHead}`);
      const t = await gh.call<{ sha: string }>("POST", "/git/trees", {
        base_tree: base.tree.sha,
        tree: [...conflicts].map(([p, b]) =>
          b
            ? {
                path: prefix + p,
                mode: "100644",
                type: "blob",
                content: Buffer.from(b).toString("utf8"),
              }
            : { path: prefix + p, mode: "100644", type: "blob", sha: null },
        ),
      });
      const c = await gh.call<{ sha: string }>("POST", "/git/commits", {
        message: "Casama's version of files changed on both sides",
        tree: t.sha,
        parents: [newHead],
      });
      await gh.call("POST", "/git/refs", { ref: `refs/heads/${branch}`, sha: c.sha });
      const pr = await gh.call<{ html_url: string }>("POST", "/pulls", {
        title: "Casama: files changed in both places",
        head: branch,
        base: cfg.branch,
        body: `These files changed in Casama and in this repository since the last sync. Casama kept its version; this pull request has it.\n\n${[...conflicts.keys()].map((p) => `- \`${p}\``).join("\n")}\n\nMerge it to use Casama's version, or close it and edit the files here again.`,
      });
      report.conflicts.push(...conflicts.keys());
      report.pullRequest = pr.html_url;
    }

    // What both sides agree on now becomes the new baseline.
    const after = await exportWorkspaceFiles(db, orgId);
    const next: Synced = {};
    const remoteAfter = new Map(remoteSha);
    for (const [p, b] of push) b ? remoteAfter.set(p, gitBlobSha(b)) : remoteAfter.delete(p);
    const touched = new Set([...push.keys(), ...pull.keys(), ...pullDeleted, ...conflicts.keys()]);
    for (const [p, b] of after) {
      const rs = remoteAfter.get(p);
      // Nothing happened to it this time: its baseline stays (an open conflict stays open).
      if (!touched.has(p) && synced[p] && sha256(b) === synced[p]?.hash && rs === synced[p]?.git)
        next[p] = synced[p] as Synced[string];
      else if (conflicts.has(p)) next[p] = { git: rs ?? "", hash: sha256(b) };
      else if (rs === gitBlobSha(b)) next[p] = { git: rs, hash: sha256(b) };
      else if (synced[p] && report.errors.some((e) => e.startsWith(`${p}:`)))
        next[p] = synced[p] as Synced[string];
    }
    // A repo file Casama refused stays "unsynced", so it's retried after it's fixed.
    await db.execute(sql`
      update public.org_git_sync set synced = ${JSON.stringify(next)}::jsonb, last_commit = ${newHead}, checked_at = ${now.toISOString()}::timestamptz,
        last_synced_at = ${now.toISOString()}::timestamptz, last_error = ${report.errors.length ? report.errors.join("\n").slice(0, 2000) : null},
        open_pr_url = ${report.pullRequest}
      where org_id = ${orgId}::uuid`);
    return report;
  } catch (err) {
    const msg =
      err instanceof GitSyncError ? err.message : `Sync failed: ${(err as Error).message}`;
    await db.execute(sql`
      update public.org_git_sync set last_error = ${msg.slice(0, 2000)}, checked_at = ${now.toISOString()}::timestamptz where org_id = ${orgId}::uuid`);
    throw err instanceof GitSyncError ? err : new GitSyncError(msg);
  }
}

/** The worker's minute tick: workspaces changed since their last sync, or not checked in 10 minutes. */
export async function gitSyncTick(d: GitSyncDeps, now = new Date()) {
  const due = await d.db.execute<{ org_id: string }>(sql`
    select org_id from public.org_git_sync
    where enabled and (last_synced_at is null or dirty_at > last_synced_at or checked_at is null or checked_at < ${now.toISOString()}::timestamptz - interval '10 minutes')
    order by checked_at nulls first limit 20`);
  const out: string[] = [];
  for (const r of due) {
    try {
      await syncWorkspaceRepo(d, r.org_id, now);
      out.push(r.org_id);
    } catch {}
  }
  return out;
}
