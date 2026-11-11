/**
 * Plugins (D-121): Agent Plugins 1.0 packages from GitHub, pinned to a commit and installed for a
 * bot. Skills become the bot's skills, remote MCP servers become MCP connections, and stdio MCP
 * servers become computer_mcp connections that computerd runs inside the bot's computer. Every
 * piece points back at the plugin row, so uninstalling removes all of it.
 */

import {
  botComputerId,
  ComputerMcpAdapter,
  type ComputerMcpConfig,
  computerMcpFetch,
  forgetPluginSync,
  pluginRoot,
  syncPluginComputer,
} from "@casama/agent";
import { routes } from "@casama/contracts";
import { type JwtClaims, pgErrorCode, withUserSession } from "@casama/db";
import {
  type CheckedPlugin,
  checkPlugin,
  PLUGIN_MAX_BYTES,
  PLUGIN_MAX_FILES,
  PluginError,
  type PluginServer,
} from "@casama/domain";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import {
  bundleFrom,
  GitHubReader,
  type GitHubRef,
  isText,
  parseGitHubUrl,
} from "../../services/skills.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

const MAX_FILES = PLUGIN_MAX_FILES;
const MAX_BYTES = PLUGIN_MAX_BYTES;

type Loaded = {
  ref: GitHubRef;
  commit: string;
  checked: CheckedPlugin;
  files: Array<{ path: string; content: Buffer; executable: boolean }>;
  skills: ReturnType<typeof bundleFrom>[];
};

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

const serverInfo = (s: PluginServer) => ({
  key: s.key,
  type: s.type,
  command: s.type === "stdio" ? s.command : null,
  args: s.type === "stdio" ? s.args : [],
  url: s.type === "stdio" ? null : s.url,
});

/** A connection name for a server: unique per workspace, `^[a-z][a-z0-9_]{0,39}$`. */
export function integrationName(plugin: string, server: string, botId: string) {
  const base = `${plugin}_${server}`
    .toLowerCase()
    .replace(/[^a-z0-9_]+/g, "_")
    .replace(/^[^a-z]+/, "");
  return `${(base || "plugin").slice(0, 33)}_${botId.slice(0, 6)}`;
}

export function registerPluginRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const reader = () => new GitHubReader({ apiUrl: deps.env.GITHUB_API_URL });

  /** Fetches and checks a package at a commit (the latest one when commit is null). */
  const load = async (ref: GitHubRef, commit: string | null): Promise<Loaded> => {
    const r = reader();
    const sha = commit ?? (await r.resolveCommit(ref));
    const files = await r.fetchFolder(ref, sha, { maxFiles: MAX_FILES, maxBytes: MAX_BYTES });
    const texts = new Map(
      files.filter((f) => isText(f.content)).map((f) => [f.path, f.content.toString("utf8")]),
    );
    let checked: CheckedPlugin;
    try {
      checked = checkPlugin(texts);
    } catch (err) {
      if (err instanceof PluginError) throw new ApiError(400, "plugin_invalid", err.message);
      throw err;
    }
    const skills: Loaded["skills"] = [];
    for (const s of checked.skills) {
      const prefix = `${s.path}/`;
      try {
        skills.push(
          bundleFrom(
            texts.get(`${prefix}SKILL.md`) as string,
            files
              .filter((f) => f.path.startsWith(prefix) && f.path !== `${prefix}SKILL.md`)
              .map((f) => ({ ...f, path: f.path.slice(prefix.length) })),
          ),
        );
      } catch (err) {
        // A broken skill is skipped, not fatal (the specification's rule).
        checked.warnings.push(`Skipped skill ${s.name}: ${(err as Error).message}`);
      }
    }
    return { ref, commit: sha, checked, files, skills };
  };

  const preview = (l: Loaded) => ({
    name: l.checked.manifest.name,
    version: l.checked.manifest.version ?? null,
    description: l.checked.manifest.description ?? "",
    repo: `${l.ref.owner}/${l.ref.repo}`,
    path: l.ref.path,
    commit: l.commit,
    skills: l.skills.map((s) => ({ name: s.name, description: s.description })),
    servers: l.checked.servers.map(serverInfo),
    secrets: l.checked.secrets.map(({ name, description, server }) => ({
      name,
      description,
      server,
    })),
    hosts: l.checked.hosts,
    warnings: l.checked.warnings,
  });

  const manageable = async (claims: JwtClaims, botId: string) => {
    const [b] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ org_id: string; manage: boolean }>(sql`
        select org_id, public.can_manage_bot(id) as manage from public.bots where id = ${botId}::uuid and archived_at is null`),
    );
    if (!b) throw new ApiError(404, "bot_not_found", "Bot not found");
    if (!b.manage)
      throw new ApiError(
        403,
        "forbidden",
        "Only people who manage this bot can change its plugins",
      );
    return b;
  };

  /** Writes the plugin's skills, files and connections (replacing an older version's). */
  const apply = async (
    claims: JwtClaims,
    target: { orgId: string; botId: string; pluginId?: string },
    l: Loaded,
    secrets: Record<string, string>,
  ) => {
    const missing = l.checked.secrets.filter((s) => !secrets[s.name]?.trim()).map((s) => s.name);
    if (missing.length)
      throw new ApiError(400, "plugin_secrets_missing", `This plugin needs: ${missing.join(", ")}`);
    const m = l.checked.manifest;
    const summary = {
      skills: l.skills.map((s) => ({ name: s.name, md: s.skillMd })),
      servers: l.checked.servers,
      secrets: l.checked.secrets,
      hosts: l.checked.hosts,
      warnings: l.checked.warnings,
    };
    try {
      return await db.transaction(async (tx) => {
        let id = target.pluginId;
        if (id) {
          const old = await tx.execute<{ vault_secret_id: string | null }>(
            sql`select vault_secret_id from public.integrations where plugin_id = ${id}::uuid`,
          );
          for (const o of old)
            if (o.vault_secret_id)
              await tx.execute(
                sql`delete from vault.secrets where id = ${o.vault_secret_id}::uuid`,
              );
          await tx.execute(sql`delete from public.integrations where plugin_id = ${id}::uuid`);
          await tx.execute(sql`delete from public.skills where plugin_id = ${id}::uuid`);
          await tx.execute(sql`delete from public.plugin_files where plugin_id = ${id}::uuid`);
          await tx.execute(sql`
            update public.plugins set version = ${m.version ?? null}, description = ${m.description ?? ""}, commit_sha = ${l.commit},
              summary = ${JSON.stringify(summary)}::jsonb, updated_at = now() where id = ${id}::uuid`);
        } else {
          const [p] = await tx.execute<{ id: string }>(sql`
            insert into public.plugins (org_id, bot_id, name, version, description, source, commit_sha, summary, installed_by)
            values (${target.orgId}::uuid, ${target.botId}::uuid, ${m.name}, ${m.version ?? null}, ${(m.description ?? "").slice(0, 2000)},
                    ${JSON.stringify({ owner: l.ref.owner, repo: l.ref.repo, path: l.ref.path, ref: l.ref.ref })}::jsonb,
                    ${l.commit}, ${JSON.stringify(summary)}::jsonb, ${claims.sub}::uuid)
            returning id`);
          id = p?.id as string;
        }
        for (const s of l.skills) {
          const [row] = await tx.execute<{ id: string }>(sql`
            insert into public.skills (org_id, bot_id, name, description, body_md, source, source_ref, plugin_id)
            values (${target.orgId}::uuid, ${target.botId}::uuid, ${s.name}, ${s.description}, ${s.body}, 'plugin',
                    ${JSON.stringify({ plugin: m.name, commit: l.commit })}::jsonb, ${id}::uuid)
            returning id`);
          for (const f of s.files)
            await tx.execute(sql`
              insert into public.skill_files (org_id, skill_id, path, content, executable)
              values (${target.orgId}::uuid, ${row?.id}::uuid, ${f.path}, decode(${f.content.toString("base64")}, 'base64'), ${f.executable})`);
        }
        for (const f of l.files.filter((f) => !f.path.startsWith("skills/")))
          await tx.execute(sql`
            insert into public.plugin_files (plugin_id, org_id, path, content, executable)
            values (${id}::uuid, ${target.orgId}::uuid, ${f.path}, decode(${f.content.toString("base64")}, 'base64'), ${f.executable})`);
        for (const s of l.checked.servers) {
          const mine = l.checked.secrets.filter((x) => x.server === s.key);
          let config: Record<string, unknown>;
          let secret: string | null = null;
          if (s.type === "stdio") {
            config = {
              plugin_id: id,
              plugin: m.name,
              server: s.key,
              command: s.command,
              args: s.args,
              env: s.env,
              cwd: s.cwd,
              secret_env: mine.map((x) => x.env),
            } satisfies ComputerMcpConfig & Record<string, unknown>;
            if (mine.length)
              secret = JSON.stringify(
                Object.fromEntries(mine.map((x) => [x.env, secrets[x.name]])),
              );
          } else {
            const h = mine[0];
            config = {
              url: s.url,
              headers: s.headers,
              ...(h ? { auth_header: h.header } : {}),
              plugin: m.name,
              server: s.key,
            };
            if (h)
              secret = h.format
                ? h.format.replace("{{value}}", secrets[h.name] as string)
                : (secrets[h.name] as string);
          }
          const vault = secret
            ? (
                await tx.execute<{ id: string }>(
                  sql`select vault.create_secret(${secret}, null, ${`plugin ${m.name} ${s.key}`}) as id`,
                )
              )[0]?.id
            : null;
          const [i] = await tx.execute<{ id: string }>(sql`
            insert into public.integrations (org_id, kind, name, config, vault_secret_id, created_by, plugin_id)
            values (${target.orgId}::uuid, ${s.type === "stdio" ? "computer_mcp" : "mcp"}, ${integrationName(m.name, s.key, target.botId)},
                    ${JSON.stringify(config)}::jsonb, ${vault ?? null}::uuid, ${claims.sub}::uuid, ${id}::uuid)
            returning id`);
          await tx.execute(sql`
            insert into public.bot_integrations (org_id, bot_id, integration_id)
            values (${target.orgId}::uuid, ${target.botId}::uuid, ${i?.id}::uuid)`);
        }
        await tx.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
          values (${target.orgId}::uuid, 'user', ${claims.sub}::uuid, ${target.pluginId ? "plugin.updated" : "plugin.installed"}, 'plugin', ${id}::uuid,
                  ${JSON.stringify({ name: m.name, commit: l.commit, bot_id: target.botId })}::jsonb)`);
        return id as string;
      });
    } catch (err) {
      const code = pgErrorCode(err);
      if (code === "23505")
        throw new ApiError(
          409,
          "plugin_conflict",
          "This bot already has a plugin, skill or connection with one of these names",
        );
      throw err;
    }
  };

  /** Lists each server's tools: remote ones through the worker, stdio ones on the bot's computer. */
  const listTools = async (pluginId: string, botId: string) => {
    const rows = await db.execute<{ id: string; kind: string; name: string }>(
      sql`select id, kind, name from public.integrations where plugin_id = ${pluginId}::uuid`,
    );
    for (const r of rows) {
      try {
        if (r.kind === "mcp") {
          await deps.workflows.testIntegration(r.id);
          continue;
        }
        const svc = deps.computers;
        const computerId = await botComputerId(db, botId);
        if (!svc || !computerId)
          throw new Error("The bot needs a computer to run this plugin's server");
        const h = await svc.ensureRunning(computerId);
        await syncPluginComputer(db, h, computerId);
        const adapter = new ComputerMcpAdapter(
          { id: r.id, org_id: "", kind: "computer_mcp", name: r.name, config: {}, secret: null },
          {
            fetch,
            secrets: [],
            computerMcp: async () => computerMcpFetch(h, r.name),
          },
        );
        try {
          const tools = await adapter.listTools();
          await db.execute(sql`
            update public.integrations set tools_cache = ${JSON.stringify(tools)}::jsonb, tools_cached_at = now(), status = 'ok', error = null
            where id = ${r.id}::uuid`);
        } finally {
          await adapter.close();
        }
      } catch (err) {
        await db.execute(sql`
          update public.integrations set status = 'error', error = ${(err as Error).message.slice(0, 500)} where id = ${r.id}::uuid`);
      }
    }
  };

  const out = async (claims: JwtClaims, id: string) => {
    const [p] = await withUserSession(db, claims, (tx) =>
      tx.execute<{
        id: string;
        bot_id: string;
        name: string;
        version: string | null;
        description: string;
        source: { owner: string; repo: string; path: string };
        commit_sha: string;
        summary: CheckedPlugin & { secrets: CheckedPlugin["secrets"] };
        installed_at: string;
        updated_at: string;
      }>(sql`select * from public.plugins where id = ${id}::uuid`),
    );
    if (!p) throw new ApiError(404, "plugin_not_found", "Plugin not found");
    const skills = await db.execute<{ id: string; name: string }>(
      sql`select id, name from public.skills where plugin_id = ${id}::uuid order by name`,
    );
    const ints = await db.execute<{
      id: string;
      status: "ok";
      error: string | null;
      config: { server: string };
      tools_cache: Array<{ name: string; risk?: "low" | "medium" | "high" }>;
      risk_overrides: Record<string, "low" | "medium" | "high">;
    }>(
      sql`select id, status, error, config, tools_cache, risk_overrides from public.integrations where plugin_id = ${id}::uuid`,
    );
    return {
      id: p.id,
      bot_id: p.bot_id,
      name: p.name,
      version: p.version,
      description: p.description,
      repo: `${p.source.owner}/${p.source.repo}`,
      path: p.source.path,
      commit: p.commit_sha,
      skills,
      servers: (p.summary.servers ?? []).map((s) => {
        const i = ints.find((x) => x.config.server === s.key);
        return {
          ...serverInfo(s),
          integration_id: i?.id as string,
          status: (i?.status ?? "error") as "ok" | "error" | "pending",
          error: i?.error ?? null,
          tools: (i?.tools_cache ?? []).map((t) => ({
            name: t.name,
            risk: i?.risk_overrides?.[t.name] ?? t.risk ?? "medium",
          })),
        };
      }),
      hosts: p.summary.hosts ?? [],
      secrets: (p.summary.secrets ?? []).map(({ name, description, server }) => ({
        name,
        description,
        server,
      })),
      installed_at: iso(p.installed_at),
      updated_at: iso(p.updated_at),
    };
  };

  app.openapi(routes.previewPlugin, async (c) => {
    claimsOf(c);
    const { url } = c.req.valid("json");
    return c.json(preview(await load(parseGitHubUrl(url), null)), 200);
  });

  app.openapi(routes.installPlugin, async (c) => {
    const claims = claimsOf(c);
    const b = c.req.valid("json");
    const bot = await manageable(claims, b.bot_id);
    if (bot.org_id !== b.org_id) throw new ApiError(404, "bot_not_found", "Bot not found");
    const l = await load(parseGitHubUrl(b.url), b.commit);
    const id = await apply(claims, { orgId: b.org_id, botId: b.bot_id }, l, b.secrets ?? {});
    await listTools(id, b.bot_id);
    return c.json(await out(claims, id), 201);
  });

  app.openapi(routes.listPlugins, async (c) => {
    const claims = claimsOf(c);
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string }>(
        sql`select id from public.plugins where bot_id = ${c.req.valid("query").bot_id}::uuid order by name`,
      ),
    );
    return c.json({ items: await Promise.all(rows.map((r) => out(claims, r.id))) }, 200);
  });

  const stored = async (claims: JwtClaims, id: string) => {
    const [p] = await withUserSession(db, claims, (tx) =>
      tx.execute<{
        id: string;
        org_id: string;
        bot_id: string;
        name: string;
        version: string | null;
        commit_sha: string;
        source: GitHubRef;
        summary: {
          skills?: Array<{ name: string; md: string }>;
          servers?: PluginServer[];
          hosts?: string[];
          secrets?: Array<{ name: string }>;
        };
      }>(
        sql`select id, org_id, bot_id, name, version, commit_sha, source, summary from public.plugins where id = ${id}::uuid`,
      ),
    );
    if (!p) throw new ApiError(404, "plugin_not_found", "Plugin not found");
    return p;
  };

  app.openapi(routes.getPluginUpdate, async (c) => {
    const claims = claimsOf(c);
    const p = await stored(claims, c.req.valid("param").id);
    const l = await load({ ...p.source, ref: p.source.ref ?? null }, null);
    const oldSkills = new Map((p.summary.skills ?? []).map((s) => [s.name, s.md]));
    const newSkills = new Map(l.skills.map((s) => [s.name, s.skillMd]));
    const oldServers = new Map((p.summary.servers ?? []).map((s) => [s.key, JSON.stringify(s)]));
    const newServers = new Map(l.checked.servers.map((s) => [s.key, JSON.stringify(s)]));
    const diff = (a: Map<string, string>, b: Map<string, string>) => ({
      added: [...b.keys()].filter((k) => !a.has(k)),
      removed: [...a.keys()].filter((k) => !b.has(k)),
      changed: [...b.keys()].filter((k) => a.has(k) && a.get(k) !== b.get(k)),
    });
    const sk = diff(oldSkills, newSkills);
    const sv = diff(oldServers, newServers);
    const oldSecrets = new Set((p.summary.secrets ?? []).map((s) => s.name));
    return c.json(
      {
        up_to_date: l.commit === p.commit_sha,
        from_commit: p.commit_sha,
        to_commit: l.commit,
        from_version: p.version,
        to_version: l.checked.manifest.version ?? null,
        skills_added: sk.added,
        skills_removed: sk.removed,
        skills_changed: sk.changed,
        servers_added: sv.added,
        servers_removed: sv.removed,
        servers_changed: sv.changed,
        hosts_added: l.checked.hosts.filter((h) => !(p.summary.hosts ?? []).includes(h)),
        secrets_added: l.checked.secrets.map((s) => s.name).filter((n) => !oldSecrets.has(n)),
        preview: preview(l),
      },
      200,
    );
  });

  app.openapi(routes.updatePlugin, async (c) => {
    const claims = claimsOf(c);
    const p = await stored(claims, c.req.valid("param").id);
    await manageable(claims, p.bot_id);
    const b = c.req.valid("json");
    const l = await load({ ...p.source, ref: p.source.ref ?? null }, b.commit);
    if (l.checked.manifest.name !== p.name)
      throw new ApiError(400, "plugin_renamed", "The new version has a different plugin name");
    // Secrets carry over unless replaced: read the current ones from Vault.
    const current = await db.execute<{
      config: { server: string; secret_env?: string[]; auth_header?: string };
      secret: string | null;
    }>(sql`
      select i.config, v.decrypted_secret as secret from public.integrations i
      left join vault.decrypted_secrets v on v.id = i.vault_secret_id where i.plugin_id = ${p.id}::uuid`);
    const kept: Record<string, string> = {};
    for (const s of l.checked.secrets) {
      const row = current.find((r) => r.config.server === s.server);
      if (!row?.secret) continue;
      if (s.env) {
        try {
          const v = (JSON.parse(row.secret) as Record<string, string>)[s.env];
          if (v) kept[s.name] = v;
        } catch {}
      } else if (s.header) {
        // Undo the format ("Bearer {{value}}") to get the value back.
        const [pre, post] = (s.format ?? "{{value}}").split("{{value}}") as [string, string];
        if (row.secret.startsWith(pre) && row.secret.endsWith(post))
          kept[s.name] = row.secret.slice(pre.length, row.secret.length - post.length);
      }
    }
    await apply(claims, { orgId: p.org_id, botId: p.bot_id, pluginId: p.id }, l, {
      ...kept,
      ...(b.secrets ?? {}),
    });
    forgetPluginSync();
    await listTools(p.id, p.bot_id);
    return c.json(await out(claims, p.id), 200);
  });

  app.openapi(routes.uninstallPlugin, async (c) => {
    const claims = claimsOf(c);
    const p = await stored(claims, c.req.valid("param").id);
    await manageable(claims, p.bot_id);
    const secrets = await db.execute<{ vault_secret_id: string | null }>(
      sql`select vault_secret_id from public.integrations where plugin_id = ${p.id}::uuid`,
    );
    await db.transaction(async (tx) => {
      for (const s of secrets)
        if (s.vault_secret_id)
          await tx.execute(sql`delete from vault.secrets where id = ${s.vault_secret_id}::uuid`);
      await tx.execute(sql`delete from public.plugins where id = ${p.id}::uuid`);
      await tx.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
        values (${p.org_id}::uuid, 'user', ${claims.sub}::uuid, 'plugin.uninstalled', 'plugin', ${p.id}::uuid, ${JSON.stringify({ name: p.name })}::jsonb)`);
    });
    // Tidy the computer when it's awake: stop the servers and remove the files.
    const computerId = await botComputerId(db, p.bot_id);
    const svc = deps.computers;
    if (svc && computerId) {
      const k = await svc.byId(computerId).catch(() => null);
      if (k?.state === "running") {
        try {
          const h = await svc.ensureRunning(computerId);
          forgetPluginSync(h.ref);
          await syncPluginComputer(db, h, computerId);
          const home = pluginRoot("$HOME", p.name);
          for await (const _ of h.exec(`rm -rf "${home}"`, { timeoutMs: 30_000 }));
        } catch {}
      }
    }
    return c.json({ deleted: p.id }, 200);
  });
}
