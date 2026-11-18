/**
 * Plugins (D-121) as a service: fetching and checking a package at a commit, writing a bot's
 * skills, files and connections, listing tools and tidying up. The plugin routes and packs use
 * the same code, so a pack's tools are ordinary per-bot plugin rows.
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
import { type JwtClaims, pgErrorCode, withUserSession } from "@casama/db";
import {
  APP_CATALOG,
  type CheckedPlugin,
  checkPlugin,
  checkPluginSettingValue,
  type KnownApp,
  PLUGIN_MAX_BYTES,
  PLUGIN_MAX_FILES,
  PluginError,
  type PluginServer,
  packTitle,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import { ApiError } from "../api/errors.ts";
import type { AppDeps } from "../api/types.ts";
import { iso } from "../api/util.ts";
import { syncCompanionPlugins, syncCompanionPluginsQuietly } from "./companion-plugins.ts";
import { galleryApps } from "./gallery.ts";
import { bundleFrom, GitHubReader, type GitHubRef, isText } from "./skills.ts";

export type PluginFileRow = { path: string; content: Buffer; executable: boolean };

export type LoadedPlugin = {
  /** Where it came from: a GitHub folder, or files someone gave (a share or an upload). */
  ref: GitHubRef | null;
  commit: string | null;
  checked: CheckedPlugin;
  files: PluginFileRow[];
  skills: ReturnType<typeof bundleFrom>[];
};

export const serverInfo = (s: PluginServer) => ({
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

/** Folders already fetched, by repository, folder and commit (a commit never changes). */
const folderCache = new Map<string, PluginFileRow[]>();
const FOLDER_CACHE_MAX = 50;

/** Apps a pack's app may not pretend to be: built-in ones and the gallery's. */
export async function knownApps(deps: Pick<AppDeps, "env">): Promise<KnownApp[]> {
  const gallery = await galleryApps(deps.env).catch(() => []);
  return [...APP_CATALOG, ...gallery].map((a) => ({ id: a.id, name: a.name, url: a.url }));
}

export function pluginInstaller(deps: AppDeps) {
  const { db } = deps;

  /** A reader with the server's token, or the workspace's GITHUB_TOKEN for private repositories. */
  const reader = async (orgId?: string) => {
    let token: string | null = deps.env.GITHUB_API_TOKEN ?? null;
    if (orgId) {
      const [tok] = await db.execute<{ value: string | null }>(sql`
        select v.decrypted_secret as value from public.secrets s
        join vault.decrypted_secrets v on v.id = s.vault_secret_id
        where s.org_id = ${orgId}::uuid and s.name = 'GITHUB_TOKEN' and s.kind = 'value'
          and 'api.github.com' = any(s.allowed_hosts) and s.allowed_bot_ids is null
        limit 1`);
      if (tok?.value) token = tok.value;
    }
    return new GitHubReader({ apiUrl: deps.env.GITHUB_API_URL, token });
  };

  /** Checks a package's files (from GitHub, a share or an upload). */
  const check = async (
    ref: GitHubRef | null,
    commit: string | null,
    files: PluginFileRow[],
  ): Promise<LoadedPlugin> => {
    const texts = new Map(
      files.filter((f) => isText(f.content)).map((f) => [f.path, f.content.toString("utf8")]),
    );
    let checked: CheckedPlugin;
    try {
      checked = checkPlugin(texts, { knownApps: await knownApps(deps) });
    } catch (err) {
      if (err instanceof PluginError) throw new ApiError(400, "plugin_invalid", err.message);
      throw err;
    }
    const skills: LoadedPlugin["skills"] = [];
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
    return { ref, commit, checked, files, skills };
  };

  /** Fetches and checks a package at a commit (the latest one when commit is null). */
  const load = async (
    ref: GitHubRef,
    commit: string | null,
    orgId?: string,
  ): Promise<LoadedPlugin> => {
    const r = await reader(orgId);
    const sha = commit ?? (await r.resolveCommit(ref));
    const key = `${ref.owner}/${ref.repo}/${ref.path}@${sha}`;
    let files = folderCache.get(key);
    if (!files) {
      files = await r.fetchFolder(ref, sha, {
        maxFiles: PLUGIN_MAX_FILES,
        maxBytes: PLUGIN_MAX_BYTES,
      });
      folderCache.set(key, files);
      if (folderCache.size > FOLDER_CACHE_MAX)
        folderCache.delete(folderCache.keys().next().value as string);
    }
    return check(ref, sha, files);
  };

  /** Files someone gave (a pack file or a shared pack), with the same limits as GitHub. */
  const loadFiles = async (
    given: Array<{ path: string; base64: string; executable?: boolean }>,
  ): Promise<LoadedPlugin> => {
    if (given.length > PLUGIN_MAX_FILES)
      throw new ApiError(
        400,
        "plugin_too_large",
        `A plugin holds at most ${PLUGIN_MAX_FILES} files`,
      );
    const files: PluginFileRow[] = [];
    let total = 0;
    for (const f of given) {
      const path = f.path.replace(/^\.\//, "");
      if (!/^[A-Za-z0-9._-]+(\/[A-Za-z0-9._-]+)*$/.test(path) || path.split("/").includes(".."))
        throw new ApiError(400, "plugin_invalid", `${f.path} isn't a safe file name`);
      const content = Buffer.from(f.base64, "base64");
      total += content.length;
      files.push({ path, content, executable: f.executable === true });
    }
    if (total > PLUGIN_MAX_BYTES)
      throw new ApiError(400, "plugin_too_large", "A plugin holds at most 10 MB");
    return check(null, null, files);
  };

  const preview = (l: LoadedPlugin) => {
    const p = l.checked.pack;
    return {
      name: l.checked.manifest.name,
      version: l.checked.manifest.version ?? null,
      description: l.checked.manifest.description ?? "",
      repo: l.ref ? `${l.ref.owner}/${l.ref.repo}` : "",
      path: l.ref?.path ?? "",
      commit: l.commit ?? "",
      skills: l.skills.map((s) => ({ name: s.name, description: s.description })),
      servers: l.checked.servers.map(serverInfo),
      secrets: l.checked.secrets.map(({ name, description, server }) => ({
        name,
        description,
        server,
      })),
      hosts: l.checked.hosts,
      warnings: l.checked.warnings,
      settings: l.checked.settings.map((s) => ({
        name: s.name,
        label: s.label,
        description: s.description,
        server: s.server,
        default: s.default ?? null,
      })),
      ...(p
        ? {
            pack: {
              summary: p.document.summary,
              bots: p.bots.length,
              routines: p.routines.length,
              apps: p.apps.length,
              looks: p.looks.length,
            },
          }
        : {}),
    };
  };

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

  /**
   * Where a plugin's stdio servers run (D-344): the bot's computer (null) or one of the
   * installer's own paired computers, with local tools (MCP) turned on.
   */
  const ownDevice = async (claims: JwtClaims, orgId: string, deviceId: string) => {
    const [d] = await db.execute<{
      id: string;
      org_id: string;
      user_id: string;
      computer_id: string | null;
      name: string;
      enabled: boolean;
      capabilities: { mcp?: boolean } | null;
    }>(sql`
      select id, org_id, user_id, computer_id, name, enabled, capabilities
      from public.local_devices where id = ${deviceId}::uuid`);
    if (!d || d.org_id !== orgId || d.user_id !== claims.sub)
      throw new ApiError(
        403,
        "device_not_yours",
        "A plugin's tools can run only on your own computer, not someone else's",
      );
    if (!d.computer_id || !d.enabled)
      throw new ApiError(
        400,
        "device_off",
        `${d.name} isn't set up for bots. Turn on "Use this computer for bots" in the Casama app there.`,
      );
    if (!d.capabilities?.mcp)
      throw new ApiError(
        400,
        "device_no_mcp",
        `Turn on "Local tools (MCP)" on ${d.name} first, in the Casama app there.`,
      );
    return { ...d, computer_id: d.computer_id };
  };

  /** The computer a plugin's tools run on now (null: the bot's computer). */
  const placement = async (pluginId: string) => {
    const [r] = await db.execute<{ device_id: string; owner: string; computer_id: string }>(sql`
      select config ->> 'device_id' as device_id, config ->> 'owner_user_id' as owner, config ->> 'computer_id' as computer_id
      from public.integrations where plugin_id = ${pluginId}::uuid and kind = 'local_mcp' limit 1`);
    return r ?? null;
  };

  /** Only the person whose computer runs a plugin's tools changes what runs there (D-131). */
  const checkPlacementOwner = async (claims: JwtClaims, pluginId: string) => {
    const at = await placement(pluginId);
    if (at && at.owner !== claims.sub)
      throw new ApiError(
        403,
        "plugin_on_others_computer",
        "This plugin's tools run on someone else's own computer, so only they can change it. You can still remove it.",
      );
    return at;
  };

  /** Settings with their defaults, checked; unknown names are refused. */
  const settingValues = (l: LoadedPlugin, given: Record<string, string>) => {
    const out: Record<string, string> = {};
    for (const k of Object.keys(given))
      if (!l.checked.settings.some((s) => s.name === k))
        throw new ApiError(400, "plugin_setting_unknown", `This plugin has no setting ${k}`);
    for (const s of l.checked.settings) {
      const v = given[s.name] ?? s.default ?? "";
      const why = checkPluginSettingValue(v);
      if (why) throw new ApiError(400, "plugin_setting_invalid", `${s.label} ${why}`);
      out[s.name] = v;
    }
    return out;
  };

  /**
   * Writes the plugin's skills, files and connections (replacing an older version's). A pack
   * writes its skills itself (`skipSkills`) and marks its tool rows with `packId`.
   */
  const apply = async (
    claims: JwtClaims,
    target: { orgId: string; botId: string; pluginId?: string },
    l: LoadedPlugin,
    secrets: Record<string, string>,
    opts: {
      packId?: string | null;
      skipSkills?: boolean;
      settings?: Record<string, string>;
      source?: Record<string, unknown>;
      /**
       * Where its stdio servers run (D-344): one of the installer's own computers, or null for
       * the bot's computer. Left out, an update keeps where they run now.
       */
      deviceId?: string | null;
    } = {},
  ) => {
    const missing = l.checked.secrets.filter((s) => !secrets[s.name]?.trim()).map((s) => s.name);
    if (missing.length)
      throw new ApiError(400, "plugin_secrets_missing", `This plugin needs: ${missing.join(", ")}`);
    const settings = settingValues(l, opts.settings ?? {});
    const m = l.checked.manifest;
    const now = target.pluginId ? await checkPlacementOwner(claims, target.pluginId) : null;
    const deviceId = opts.deviceId === undefined ? (now?.device_id ?? null) : opts.deviceId;
    const hasStdio = l.checked.servers.some((s) => s.type === "stdio");
    const device = deviceId && hasStdio ? await ownDevice(claims, target.orgId, deviceId) : null;
    // A new place needs the computer online, so the package and the tools can be checked now.
    if (device && device.id !== now?.device_id && !deps.devices?.online(device.computer_id))
      throw new ApiError(
        409,
        "device_offline",
        `${device.name} is offline. Open the Casama app there, then try again.`,
      );
    const skills = opts.skipSkills ? [] : l.skills;
    const summary = {
      skills: skills.map((s) => ({ name: s.name, md: s.skillMd })),
      servers: l.checked.servers,
      secrets: l.checked.secrets,
      settings: l.checked.settings,
      hosts: l.checked.hosts,
      warnings: l.checked.warnings,
      // Cards for its tools (D-345): the run reads them from here after each call.
      cards: l.checked.cards,
    };
    const source =
      opts.source ??
      (l.ref
        ? { owner: l.ref.owner, repo: l.ref.repo, path: l.ref.path, ref: l.ref.ref }
        : { owner: "", repo: "", path: "", ref: null });
    // Pack files without a commit (a share or an upload) are pinned by their content.
    const commit =
      l.commit ??
      (await import("node:crypto"))
        .createHash("sha1")
        .update(l.files.map((f) => `${f.path}\0${f.content.toString("base64")}`).join("\n"))
        .digest("hex");
    try {
      const pluginRowId = await db.transaction(async (tx) => {
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
            update public.plugins set version = ${m.version ?? null}, description = ${m.description ?? ""}, commit_sha = ${commit},
              summary = ${JSON.stringify(summary)}::jsonb, updated_at = now() where id = ${id}::uuid`);
        } else {
          const [p] = await tx.execute<{ id: string }>(sql`
            insert into public.plugins (org_id, bot_id, name, version, description, source, commit_sha, summary, installed_by, pack_id)
            values (${target.orgId}::uuid, ${target.botId}::uuid, ${m.name}, ${m.version ?? null}, ${(m.description ?? "").slice(0, 2000)},
                    ${JSON.stringify(source)}::jsonb,
                    ${commit}, ${JSON.stringify(summary)}::jsonb, ${claims.sub}::uuid, ${opts.packId ?? null}::uuid)
            returning id`);
          id = p?.id as string;
        }
        for (const s of skills) {
          const [row] = await tx.execute<{ id: string }>(sql`
            insert into public.skills (org_id, bot_id, name, description, body_md, source, source_ref, plugin_id)
            values (${target.orgId}::uuid, ${target.botId}::uuid, ${s.name}, ${s.description}, ${s.body}, 'plugin',
                    ${JSON.stringify({ plugin: m.name, commit })}::jsonb, ${id}::uuid)
            returning id`);
          for (const f of s.files)
            await tx.execute(sql`
              insert into public.skill_files (org_id, skill_id, path, content, executable)
              values (${target.orgId}::uuid, ${row?.id}::uuid, ${f.path}, decode(${f.content.toString("base64")}, 'base64'), ${f.executable})`);
        }
        for (const f of l.files.filter(
          (f) => !f.path.startsWith("skills/") && !f.path.startsWith("com.casama/"),
        ))
          await tx.execute(sql`
            insert into public.plugin_files (plugin_id, org_id, path, content, executable)
            values (${id}::uuid, ${target.orgId}::uuid, ${f.path}, decode(${f.content.toString("base64")}, 'base64'), ${f.executable})`);
        for (const s of l.checked.servers) {
          const mine = l.checked.secrets.filter((x) => x.server === s.key);
          const plain = l.checked.settings.filter((x) => x.server === s.key);
          let config: Record<string, unknown>;
          let secret: string | null = null;
          if (s.type === "stdio") {
            // Plain settings are ordinary env values (they're not secret); secrets stay in Vault.
            const env = { ...s.env };
            for (const p of plain) if (p.env) env[p.env] = settings[p.name] ?? "";
            config = {
              plugin_id: id,
              plugin: m.name,
              server: s.key,
              command: s.command,
              args: s.args,
              env,
              cwd: s.cwd,
              secret_env: mine.map((x) => x.env),
              ...(plain.length ? { settings: plain.map((p) => p.name) } : {}),
            } satisfies ComputerMcpConfig & Record<string, unknown>;
            if (mine.length)
              secret = JSON.stringify(
                Object.fromEntries(mine.map((x) => [x.env, secrets[x.name]])),
              );
          } else {
            const h = mine[0];
            const headers = { ...s.headers };
            for (const p of plain)
              if (p.header) {
                const v = settings[p.name] ?? "";
                headers[p.header] = p.format ? p.format.replace("{{value}}", v) : v;
              }
            config = {
              url: s.url,
              headers,
              ...(h ? { auth_header: h.header } : {}),
              plugin: m.name,
              server: s.key,
              ...(plain.length ? { settings: plain.map((p) => p.name) } : {}),
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
          const name = integrationName(m.name, s.key, target.botId);
          // On the installer's own computer (D-344): a local server their companion runs.
          const local = s.type === "stdio" && device;
          if (local)
            config = {
              ...config,
              device_id: device.id,
              computer_id: device.computer_id,
              owner_user_id: claims.sub,
              bridge_key: name,
              label: `${m.name}: ${s.key}`,
              summary: [s.command, ...s.args].join(" ").slice(0, 200),
              timeout_s: 1800,
            };
          const [i] = await tx.execute<{ id: string }>(sql`
            insert into public.integrations (org_id, kind, name, config, vault_secret_id, created_by, plugin_id)
            values (${target.orgId}::uuid, ${local ? "local_mcp" : s.type === "stdio" ? "computer_mcp" : "mcp"}, ${name},
                    ${JSON.stringify(config)}::jsonb, ${vault ?? null}::uuid, ${claims.sub}::uuid, ${id}::uuid)
            returning id`);
          await tx.execute(sql`
            insert into public.bot_integrations (org_id, bot_id, integration_id)
            values (${target.orgId}::uuid, ${target.botId}::uuid, ${i?.id}::uuid)`);
        }
        await tx.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
          values (${target.orgId}::uuid, 'user', ${claims.sub}::uuid, ${target.pluginId ? "plugin.updated" : "plugin.installed"}, 'plugin', ${id}::uuid,
                  ${JSON.stringify({ name: m.name, commit, bot_id: target.botId, ...(opts.packId ? { pack_id: opts.packId } : {}), ...(device ? { device_id: device.id } : {}) })}::jsonb)`);
        return id as string;
      });
      // Tell the computers involved: the new one gets the package, an old one drops it.
      for (const c of new Set([now?.computer_id, device?.computer_id].filter(Boolean) as string[]))
        await syncCompanionPluginsQuietly(deps, c);
      return pluginRowId;
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
        if (r.kind === "local_mcp") {
          // On the person's own computer (D-344): pushed there, then listed through the tunnel.
          const at = await placement(pluginId);
          if (at && !(await syncCompanionPlugins(deps, at.computer_id)))
            throw new Error("The computer these tools run on is offline");
          const t = await deps.workflows.testIntegration(r.id);
          if (!t.ok) throw new Error(t.error ?? "The tools couldn't be listed");
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

  /** The person's own computer a plugin's tools run on (D-344), or null for the bot's computer. */
  const runsOn = async (pluginId: string) => {
    const [r] = await db.execute<{
      device_id: string;
      computer_id: string;
      owner_user_id: string;
      name: string | null;
    }>(sql`
      select i.config ->> 'device_id' as device_id, i.config ->> 'computer_id' as computer_id,
             i.config ->> 'owner_user_id' as owner_user_id, d.name
      from public.integrations i
      left join public.local_devices d on d.id::text = i.config ->> 'device_id'
      where i.plugin_id = ${pluginId}::uuid and i.kind = 'local_mcp' limit 1`);
    if (!r) return null;
    return {
      device_id: r.device_id,
      device_name: r.name ?? "a computer that was removed",
      owner_user_id: r.owner_user_id,
      online: !!deps.devices?.online(r.computer_id),
    };
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
        pack_id: string | null;
        pack_name: string | null;
        pack_title: string | null;
        installed_at: string;
        updated_at: string;
      }>(sql`select p.*, k.name as pack_name, k.content->'document'->>'title' as pack_title from public.plugins p
             left join public.packs k on k.id = p.pack_id where p.id = ${id}::uuid`),
    );
    if (!p) throw new ApiError(404, "plugin_not_found", "Plugin not found");
    const skills = await db.execute<{ id: string; name: string }>(
      sql`select id, name from public.skills where plugin_id = ${id}::uuid order by name`,
    );
    const ints = await db.execute<{
      id: string;
      status: "ok";
      error: string | null;
      config: {
        server: string;
        env?: Record<string, string>;
        headers?: Record<string, string>;
      };
      tools_cache: Array<{ name: string; risk?: "low" | "medium" | "high" }>;
      risk_overrides: Record<string, "low" | "medium" | "high">;
    }>(
      sql`select id, status, error, config, tools_cache, risk_overrides from public.integrations where plugin_id = ${id}::uuid`,
    );
    const settingValue = (s: CheckedPlugin["settings"][number]) => {
      const i = ints.find((x) => x.config.server === s.server);
      const raw = s.env ? i?.config.env?.[s.env] : s.header ? i?.config.headers?.[s.header] : "";
      if (raw === undefined) return s.default ?? "";
      if (!s.format) return raw;
      const [pre, post] = s.format.split("{{value}}") as [string, string];
      return raw.startsWith(pre) && raw.endsWith(post)
        ? raw.slice(pre.length, raw.length - post.length)
        : raw;
    };
    return {
      id: p.id,
      bot_id: p.bot_id,
      name: p.name,
      version: p.version,
      description: p.description,
      repo: p.source.owner ? `${p.source.owner}/${p.source.repo}` : "",
      path: p.source.path ?? "",
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
      settings: (p.summary.settings ?? []).map((s) => ({
        name: s.name,
        label: s.label,
        description: s.description,
        server: s.server,
        default: s.default ?? null,
        value: settingValue(s),
      })),
      pack_id: p.pack_id,
      pack_name: p.pack_name ? packTitle({ title: p.pack_title }, p.pack_name) : null,
      runs_on: await runsOn(id),
      installed_at: iso(p.installed_at),
      updated_at: iso(p.updated_at),
    };
  };

  type StoredPlugin = {
    id: string;
    org_id: string;
    bot_id: string;
    name: string;
    version: string | null;
    commit_sha: string;
    source: GitHubRef;
    pack_id: string | null;
    summary: {
      skills?: Array<{ name: string; md: string }>;
      servers?: PluginServer[];
      hosts?: string[];
      secrets?: Array<{ name: string }>;
      settings?: CheckedPlugin["settings"];
    };
  };

  const stored = async (claims: JwtClaims, id: string): Promise<StoredPlugin> => {
    const [p] = await withUserSession(db, claims, (tx) =>
      tx.execute<StoredPlugin>(
        sql`select id, org_id, bot_id, name, version, commit_sha, source, summary, pack_id from public.plugins where id = ${id}::uuid`,
      ),
    );
    if (!p) throw new ApiError(404, "plugin_not_found", "Plugin not found");
    return p;
  };

  /** The secrets a plugin row holds now, by name, so an update keeps them. */
  const currentSecrets = async (pluginId: string, checked: CheckedPlugin) => {
    const current = await db.execute<{
      config: { server: string; secret_env?: string[]; auth_header?: string };
      secret: string | null;
    }>(sql`
      select i.config, v.decrypted_secret as secret from public.integrations i
      left join vault.decrypted_secrets v on v.id = i.vault_secret_id where i.plugin_id = ${pluginId}::uuid`);
    const kept: Record<string, string> = {};
    for (const s of checked.secrets) {
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
    return kept;
  };

  /** The settings a plugin row holds now, by name. */
  const currentSettings = async (claims: JwtClaims, pluginId: string) => {
    const o = await out(claims, pluginId);
    return Object.fromEntries((o.settings ?? []).map((s) => [s.name, s.value]));
  };

  /** Deletes a plugin row with its Vault secrets, and tidies the computer when it's awake. */
  const remove = async (
    claims: JwtClaims,
    p: Pick<StoredPlugin, "id" | "org_id" | "bot_id" | "name">,
  ) => {
    const secrets = await db.execute<{ vault_secret_id: string | null }>(
      sql`select vault_secret_id from public.integrations where plugin_id = ${p.id}::uuid`,
    );
    const at = await placement(p.id);
    await db.transaction(async (tx) => {
      for (const s of secrets)
        if (s.vault_secret_id)
          await tx.execute(sql`delete from vault.secrets where id = ${s.vault_secret_id}::uuid`);
      await tx.execute(sql`delete from public.plugins where id = ${p.id}::uuid`);
      await tx.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
        values (${p.org_id}::uuid, 'user', ${claims.sub}::uuid, 'plugin.uninstalled', 'plugin', ${p.id}::uuid, ${JSON.stringify({ name: p.name })}::jsonb)`);
    });
    // On a person's own computer (D-344): its servers stop and its package goes.
    if (at) await syncCompanionPluginsQuietly(deps, at.computer_id);
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
  };

  /** Rewrites a plugin's plain settings in its connections' config. */
  const updateSettings = async (
    claims: JwtClaims,
    p: StoredPlugin,
    given: Record<string, string>,
  ) => {
    const defs = p.summary.settings ?? [];
    const at = await checkPlacementOwner(claims, p.id);
    for (const k of Object.keys(given))
      if (!defs.some((s) => s.name === k))
        throw new ApiError(400, "plugin_setting_unknown", `This plugin has no setting ${k}`);
    for (const [k, v] of Object.entries(given)) {
      const why = checkPluginSettingValue(v);
      if (why) throw new ApiError(400, "plugin_setting_invalid", `${k} ${why}`);
    }
    const ints = await db.execute<{ id: string; config: Record<string, unknown> }>(
      sql`select id, config from public.integrations where plugin_id = ${p.id}::uuid`,
    );
    for (const i of ints) {
      const config = { ...i.config } as {
        server: string;
        env?: Record<string, string>;
        headers?: Record<string, string>;
      };
      for (const s of defs.filter((d) => d.server === config.server)) {
        const v = given[s.name];
        if (v === undefined) continue;
        if (s.env) config.env = { ...(config.env ?? {}), [s.env]: v };
        if (s.header)
          config.headers = {
            ...(config.headers ?? {}),
            [s.header]: s.format ? s.format.replace("{{value}}", v) : v,
          };
      }
      await db.execute(
        sql`update public.integrations set config = ${JSON.stringify(config)}::jsonb where id = ${i.id}::uuid`,
      );
    }
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${p.org_id}::uuid, 'user', ${claims.sub}::uuid, 'plugin.settings_changed', 'plugin', ${p.id}::uuid,
              ${JSON.stringify({ name: p.name, settings: Object.keys(given) })}::jsonb)`);
    forgetPluginSync();
    if (at) await syncCompanionPluginsQuietly(deps, at.computer_id);
  };

  return {
    reader,
    load,
    loadFiles,
    check,
    preview,
    manageable,
    apply,
    listTools,
    out,
    stored,
    currentSecrets,
    currentSettings,
    remove,
    updateSettings,
  };
}

export type PluginInstaller = ReturnType<typeof pluginInstaller>;
