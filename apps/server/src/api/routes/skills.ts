/** Skills library routes (D-104): catalog, GitHub preview and install, update checks with a diff. */
import type { OpenAPIHono } from "@hono/zod-openapi";
import { routes } from "@kasama/contracts";
import { type Database, type JwtClaims, pgErrorCode, withUserSession } from "@kasama/db";
import { lineDiff } from "@kasama/domain";
import { sql } from "drizzle-orm";
import {
  GitHubReader,
  isText,
  loadCatalog,
  parseGitHubUrl,
  type SkillBundle,
} from "../../services/skills.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

type Row = {
  id: string;
  org_id: string;
  bot_id: string | null;
  name: string;
  description: string;
  source: "manual";
  source_ref: Record<string, unknown>;
  category: string | null;
  file_count: number;
  updated_at: string;
};
const out = (r: Row) => ({ ...r, file_count: Number(r.file_count), updated_at: iso(r.updated_at) });

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

/** Writes the skill and its files as the caller, so RLS decides who may install where. */
async function saveSkill(
  db: Database,
  claims: JwtClaims,
  target: { orgId: string; botId: string | null; skillId?: string },
  bundle: SkillBundle,
  source: { kind: "catalog" | "github"; ref: Record<string, unknown>; category: string | null },
): Promise<Row> {
  try {
    return await withUserSession(db, claims, async (tx) => {
      let id = target.skillId;
      if (id) {
        await tx.execute(sql`
          update public.skills set name = ${bundle.name}, description = ${bundle.description}, body_md = ${bundle.body},
            source_ref = ${JSON.stringify(source.ref)}::jsonb, updated_at = now(), updated_by_bot = null
          where id = ${id}::uuid`);
        await tx.execute(sql`delete from public.skill_files where skill_id = ${id}::uuid`);
      } else {
        const [r] = await tx.execute<{ id: string }>(sql`
          insert into public.skills (org_id, bot_id, name, description, body_md, source, source_ref, category)
          values (${target.orgId}::uuid, ${target.botId}::uuid, ${bundle.name}, ${bundle.description}, ${bundle.body},
                  ${source.kind}, ${JSON.stringify(source.ref)}::jsonb, ${source.category})
          returning id`);
        id = r?.id;
      }
      for (const f of bundle.files)
        await tx.execute(sql`
          insert into public.skill_files (org_id, skill_id, path, content, executable)
          values (${target.orgId}::uuid, ${id}::uuid, ${f.path}, decode(${f.content.toString("base64")}, 'base64'), ${f.executable})`);
      const [row] = await tx.execute<Row>(sql`
        select s.id, s.org_id, s.bot_id, s.name, s.description, s.source, s.source_ref, s.category, s.updated_at,
               (select count(*) from public.skill_files f where f.skill_id = s.id) as file_count
        from public.skills s where s.id = ${id}::uuid`);
      if (!row) throw new ApiError(403, "forbidden", "You can't change this skill.");
      return row;
    });
  } catch (err) {
    const code = pgErrorCode(err);
    if (code === "23505")
      throw new ApiError(
        409,
        "skill_exists",
        `A skill named ${bundle.name} is already installed there.`,
      );
    if (code === "42501")
      throw new ApiError(
        403,
        "forbidden",
        "Only admins install workspace skills; bot skills need someone who manages the bot.",
      );
    throw err;
  }
}

export function registerSkillRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  /** A reader using the workspace's GITHUB_TOKEN secret when it is allowed for api.github.com. */
  const github = async (claims: JwtClaims, orgId: string) => {
    const [member] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.is_member(${orgId}::uuid) as ok`),
    );
    if (!member?.ok) throw new ApiError(404, "org_not_found", "Workspace not found");
    const [tok] = await db.execute<{ value: string | null }>(sql`
      select v.decrypted_secret as value from public.secrets s
      join vault.decrypted_secrets v on v.id = s.vault_secret_id
      where s.org_id = ${orgId}::uuid and s.name = 'GITHUB_TOKEN' and s.kind = 'value'
        and 'api.github.com' = any(s.allowed_hosts) and s.allowed_bot_ids is null
      limit 1`);
    return new GitHubReader({ apiUrl: deps.env.GITHUB_API_URL, token: tok?.value ?? null });
  };

  app.openapi(routes.getSkillCatalog, async (c) => {
    claimsOf(c);
    const cat = loadCatalog();
    return c.json(
      {
        categories: cat.categories,
        items: cat.skills.map((s) => ({
          id: s.id,
          name: s.name,
          description: s.description,
          category: s.category,
          files: s.files.map((f) => f.path),
        })),
      },
      200,
    );
  });

  app.openapi(routes.installCatalogSkill, async (c) => {
    const claims = claimsOf(c);
    const body = c.req.valid("json");
    const skill = loadCatalog().skills.find((s) => s.id === body.catalog_id);
    if (!skill) throw new ApiError(404, "catalog_skill_not_found", "No such skill in the catalog");
    const row = await saveSkill(
      db,
      claims,
      { orgId: body.org_id, botId: body.bot_id ?? null },
      skill,
      {
        kind: "catalog",
        ref: { id: skill.id },
        category: skill.category,
      },
    );
    return c.json(out(row), 201);
  });

  app.openapi(routes.previewGitHubSkill, async (c) => {
    const claims = claimsOf(c);
    const body = c.req.valid("json");
    const ref = parseGitHubUrl(body.url);
    const reader = await github(claims, body.org_id);
    const commit = await reader.resolveCommit(ref);
    const bundle = await reader.fetchSkill(ref, commit);
    return c.json(
      {
        repo: `${ref.owner}/${ref.repo}`,
        path: ref.path,
        ref: ref.ref,
        commit,
        name: bundle.name,
        description: bundle.description,
        skill_md: bundle.skillMd,
        files: bundle.files.map((f) => ({
          path: f.path,
          size: f.content.length,
          executable: f.executable,
          text:
            isText(f.content) && f.content.length <= 100_000 ? f.content.toString("utf8") : null,
        })),
      },
      200,
    );
  });

  app.openapi(routes.installGitHubSkill, async (c) => {
    const claims = claimsOf(c);
    const body = c.req.valid("json");
    const ref = parseGitHubUrl(body.url);
    const reader = await github(claims, body.org_id);
    const bundle = await reader.fetchSkill(ref, body.commit);
    const row = await saveSkill(
      db,
      claims,
      { orgId: body.org_id, botId: body.bot_id ?? null },
      bundle,
      {
        kind: "github",
        ref: {
          repo: `${ref.owner}/${ref.repo}`,
          path: ref.path,
          ref: ref.ref,
          commit: body.commit,
        },
        category: null,
      },
    );
    return c.json(out(row), 201);
  });

  /** A GitHub skill the caller can see, with what's needed to compare it. */
  const githubSkill = async (claims: JwtClaims, id: string) => {
    const [s] = await withUserSession(db, claims, (tx) =>
      tx.execute<{
        org_id: string;
        bot_id: string | null;
        name: string;
        description: string;
        body_md: string;
        source: string;
        source_ref: { repo?: string; path?: string; ref?: string | null; commit?: string };
      }>(sql`
        select org_id, bot_id, name, description, body_md, source, source_ref from public.skills where id = ${id}::uuid`),
    );
    if (!s) throw new ApiError(404, "skill_not_found", "Skill not found");
    if (s.source !== "github" || !s.source_ref.repo || !s.source_ref.commit)
      throw new ApiError(
        400,
        "skill_not_from_github",
        "Only skills imported from GitHub can be updated from their source.",
      );
    const [owner, repo] = s.source_ref.repo.split("/") as [string, string];
    return {
      s,
      ref: { owner, repo, path: s.source_ref.path ?? "", ref: s.source_ref.ref ?? null },
    };
  };

  app.openapi(routes.checkSkillUpdate, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const { s, ref } = await githubSkill(claims, id);
    const reader = await github(claims, s.org_id);
    const latest = await reader.resolveCommit(ref);
    const current = s.source_ref.commit as string;
    if (latest === current)
      return c.json(
        {
          current_commit: current,
          latest_commit: latest,
          has_update: false,
          diff: [],
          files_added: [],
          files_removed: [],
          files_changed: [],
        },
        200,
      );
    const next = await reader.fetchSkill(ref, latest);
    const files = await withUserSession(db, claims, (tx) =>
      tx.execute<{ path: string; content: Buffer | string }>(
        sql`select path, encode(content, 'base64') as content from public.skill_files where skill_id = ${id}::uuid`,
      ),
    );
    const have = new Map(files.map((f) => [f.path, Buffer.from(String(f.content), "base64")]));
    const want = new Map(next.files.map((f) => [f.path, f.content]));
    const before = `---\nname: ${s.name}\ndescription: ${s.description}\n---\n\n${s.body_md}`;
    const after = `---\nname: ${next.name}\ndescription: ${next.description}\n---\n\n${next.body}`;
    return c.json(
      {
        current_commit: current,
        latest_commit: latest,
        has_update: true,
        diff: lineDiff(before, after),
        files_added: [...want.keys()].filter((p) => !have.has(p)),
        files_removed: [...have.keys()].filter((p) => !want.has(p)),
        files_changed: [...want.keys()].filter(
          (p) => have.has(p) && !have.get(p)?.equals(want.get(p) as Buffer),
        ),
      },
      200,
    );
  });

  app.openapi(routes.applySkillUpdate, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const { commit } = c.req.valid("json");
    const { s, ref } = await githubSkill(claims, id);
    const reader = await github(claims, s.org_id);
    const bundle = await reader.fetchSkill(ref, commit);
    const row = await saveSkill(
      db,
      claims,
      { orgId: s.org_id, botId: s.bot_id, skillId: id },
      bundle,
      {
        kind: "github",
        ref: { repo: `${ref.owner}/${ref.repo}`, path: ref.path, ref: ref.ref, commit },
        category: null,
      },
    );
    return c.json(out(row), 200);
  });
}
