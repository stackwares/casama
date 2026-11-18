/**
 * Plugins (D-121): Agent Plugins 1.0 packages from GitHub, pinned to a commit and installed for a
 * bot. Skills become the bot's skills, remote MCP servers become MCP connections, and stdio MCP
 * servers become computer_mcp connections that computerd runs inside the bot's computer. Every
 * piece points back at the plugin row, so uninstalling removes all of it.
 */

import { forgetPluginSync } from "@casama/agent";
import { routes } from "@casama/contracts";
import type { JwtClaims } from "@casama/db";
import { withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { galleryPlugins } from "../../services/gallery.ts";
import { enforceGalleryPolicy, enforceLinkPolicy } from "../../services/gallery-install.ts";
import { linkGalleryInstallQuietly } from "../../services/gallery-usage.ts";
import { pluginInstaller } from "../../services/plugin-install.ts";
import { parseGitHubUrl } from "../../services/skills.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

export { integrationName } from "../../services/plugin-install.ts";

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

export function registerPluginRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const {
    load,
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
  } = pluginInstaller(deps);

  app.openapi(routes.previewPlugin, async (c) => {
    claimsOf(c);
    // A commit from the plugin directory previews exactly what was reviewed (D-241).
    const { url, commit } = c.req.valid("json");
    return c.json(preview(await load(parseGitHubUrl(url), commit ?? null)), 200);
  });

  app.openapi(routes.installPlugin, async (c) => {
    const claims = claimsOf(c);
    const b = c.req.valid("json");
    const bot = await manageable(claims, b.bot_id);
    if (bot.org_id !== b.org_id) throw new ApiError(404, "bot_not_found", "Bot not found");
    // From the reviewed directory (D-241): the same folder and commit (D-315 counts and updates).
    const listed = (await galleryPlugins(deps.env).catch(() => [])).find(
      (p) => p.url.replace(/\/$/, "") === b.url.replace(/\/$/, "") && p.commit === b.commit,
    );
    const ref = parseGitHubUrl(b.url);
    if (listed) await enforceGalleryPolicy(deps, claims, b.org_id, "plugin", listed.id);
    else await enforceLinkPolicy(deps, claims, b.org_id, ref, "plugin");
    const l = await load(ref, b.commit, b.org_id);
    const id = await apply(claims, { orgId: b.org_id, botId: b.bot_id }, l, b.secrets ?? {}, {
      settings: b.settings ?? {},
      deviceId: b.device_id ?? null,
    });
    await listTools(id, b.bot_id);
    if (listed)
      await linkGalleryInstallQuietly(db, deps.env, {
        orgId: b.org_id,
        userId: claims.sub,
        type: "plugin",
        id: listed.id,
        targetKind: "plugin",
        targetId: id,
        version: listed.version,
        access: listed.access,
      });
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

  app.openapi(routes.getPluginUpdate, async (c) => {
    const claims = claimsOf(c);
    const p = await stored(claims, c.req.valid("param").id);
    if (!p.source.owner)
      throw new ApiError(
        400,
        "plugin_no_source",
        "This plugin came from a file, so it has no updates",
      );
    const l = await load({ ...p.source, ref: p.source.ref ?? null }, null, p.org_id);
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
        to_commit: l.commit as string,
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
    if (!p.source.owner)
      throw new ApiError(
        400,
        "plugin_no_source",
        "This plugin came from a file, so it has no updates",
      );
    const l = await load({ ...p.source, ref: p.source.ref ?? null }, b.commit, p.org_id);
    if (l.checked.manifest.name !== p.name)
      throw new ApiError(400, "plugin_renamed", "The new version has a different plugin name");
    // Secrets and settings carry over unless replaced.
    const kept = await currentSecrets(p.id, l.checked);
    const keptSettings = await currentSettings(claims, p.id);
    const known = new Set(l.checked.settings.map((s) => s.name));
    await apply(
      claims,
      { orgId: p.org_id, botId: p.bot_id, pluginId: p.id },
      l,
      { ...kept, ...(b.secrets ?? {}) },
      {
        settings: Object.fromEntries(
          Object.entries({ ...keptSettings, ...(b.settings ?? {}) }).filter(([k]) => known.has(k)),
        ),
        packId: p.pack_id,
        skipSkills: !!p.pack_id,
      },
    );
    forgetPluginSync();
    await listTools(p.id, p.bot_id);
    return c.json(await out(claims, p.id), 200);
  });

  app.openapi(routes.uninstallPlugin, async (c) => {
    const claims = claimsOf(c);
    const p = await stored(claims, c.req.valid("param").id);
    await manageable(claims, p.bot_id);
    await remove(claims, p);
    return c.json({ deleted: p.id }, 200);
  });

  app.openapi(routes.updatePluginSettings, async (c) => {
    const claims = claimsOf(c);
    const p = await stored(claims, c.req.valid("param").id);
    await manageable(claims, p.bot_id);
    await updateSettings(claims, p, c.req.valid("json").settings);
    forgetPluginSync();
    return c.json(await out(claims, p.id), 200);
  });
}
