/**
 * Server-side `@App` mention loading and resolution (D-434).
 *
 * Shared by the API send/edit routes (`apps/server/src/api/routes/bots.ts`) and external chat
 * channels (`packages/agent/src/channels/service.ts`) so `@Gmail` works identically everywhere.
 */
import type { Database } from "@casama/db";
import {
  APP_CATALOG,
  type AppMentionRefInput,
  appByIdOrNull,
  appMentionKey,
  type MentionableApp,
  parseAppMentions,
  resolveAppMentions,
} from "@casama/domain";
import { sql } from "drizzle-orm";

export interface AppMentionPart {
  type: "app";
  integration_id: string;
  toolkit?: string;
  label: string;
  app_id?: string;
  source?: "picker" | "typed";
}

type IntegrationAppRow = {
  id: string;
  kind: string;
  name: string;
  status: string;
  config: Record<string, unknown> | null;
};

const titleCaseSlug = (slug: string) =>
  slug
    .split(/[_\-\s]+/)
    .filter(Boolean)
    .map((w) => `${w[0]?.toUpperCase() ?? ""}${w.slice(1)}`)
    .join(" ");

/** Normalizes a hub toolkit/app slug into the prefix used by Composio and Pipedream tool names. */
export const hubToolkitPrefix = (toolkit: string) =>
  toolkit
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, "_");

/** Whether an integration tool's raw name belongs to a given hub toolkit/app slug. */
export function toolMatchesToolkit(toolName: string, toolkit: string): boolean {
  const norm = toolName.toLowerCase().replace(/[^a-z0-9_]/g, "_");
  const prefix = hubToolkitPrefix(toolkit);
  if (!prefix) return false;
  return norm === prefix || norm.startsWith(`${prefix}_`);
}

/** Expands DB integration rows into mentionable apps (splitting Composio/Pipedream hubs per app). */
export function mentionableAppsFromRows(rows: IntegrationAppRow[]): MentionableApp[] {
  const out: MentionableApp[] = [];
  const seen = new Set<string>();

  for (const row of rows) {
    const config = (row.config ?? {}) as Record<string, unknown>;
    if (row.kind === "composio" || row.kind === "pipedream") {
      const rawSlugs = row.kind === "composio" ? config.toolkits : config.apps;
      const slugs = Array.isArray(rawSlugs)
        ? rawSlugs.filter((s): s is string => typeof s === "string" && s.trim().length > 0)
        : [];
      for (const slug of slugs) {
        const key = appMentionKey(row.id, slug);
        if (seen.has(key)) continue;
        seen.add(key);
        const norm = slug.trim().toLowerCase();
        const catalog = APP_CATALOG.find(
          (a) => a.composio?.toLowerCase() === norm || a.id.toLowerCase() === norm,
        );
        const label = catalog?.name ?? titleCaseSlug(slug);
        const aliases = [
          ...new Set([slug, ...(catalog ? [catalog.name, catalog.id] : [])].filter(Boolean)),
        ];
        out.push({
          integrationId: row.id,
          toolkit: slug,
          label,
          aliases,
          ...(catalog ? { appId: catalog.id } : {}),
          kind: row.kind,
        });
      }
      continue;
    }

    const key = appMentionKey(row.id);
    if (seen.has(key)) continue;
    seen.add(key);

    const appId =
      typeof config.app === "string" && config.app.trim() ? config.app.trim() : undefined;
    const catalog = appId ? appByIdOrNull(appId) : null;
    const rawLabel = typeof config.label === "string" ? config.label.trim() : "";

    let label = row.name;
    if (row.kind === "local_mcp" && rawLabel) {
      label = rawLabel;
    } else if (catalog) {
      const lowerName = row.name.toLowerCase();
      const normName = lowerName.replace(/-/g, "_");
      if (
        lowerName === catalog.id.toLowerCase() ||
        normName === catalog.id.toLowerCase() ||
        lowerName === catalog.name.toLowerCase()
      ) {
        label = catalog.name;
      }
    }

    const aliases = [
      ...new Set(
        [row.name, rawLabel, ...(catalog ? [catalog.name, catalog.id] : [])].filter(Boolean),
      ),
    ];

    out.push({
      integrationId: row.id,
      label,
      aliases,
      ...(appId ? { appId } : {}),
      kind: row.kind,
    });
  }

  return out;
}

type DbExecutor = Pick<Database, "execute">;

/** Loads integrations attached to any of `botIds` that are usable for `actingUserId`. */
export async function loadMentionableApps(
  db: DbExecutor,
  opts: { botIds: string[]; actingUserId?: string | null },
): Promise<MentionableApp[]> {
  if (!opts.botIds.length) return [];
  const rows = await db.execute<IntegrationAppRow>(sql`
    select distinct on (i.id) i.id, i.kind, i.name, i.status, i.config
    from public.bot_integrations bi
    join public.integrations i on i.id = bi.integration_id
    where bi.bot_id in (select jsonb_array_elements_text(${JSON.stringify(opts.botIds)}::jsonb)::uuid)
      and (i.status <> 'error' or i.kind = 'local_mcp')
      and (i.kind <> 'local_mcp' or coalesce(i.config ->> 'owner_user_id', '') = ''
        or i.config ->> 'owner_user_id' = ${opts.actingUserId ?? ""})
    order by i.id`);
  return mentionableAppsFromRows(rows);
}

/**
 * Resolves `@App` mentions for a message into stored `{ type: "app", ... }` content parts.
 *
 * In group chats, pass `allBotIds` (all group members) and `orgId` so apps the user picked or
 * typed that belong to another bot/the workspace — but none of the woken `botIds` — are returned
 * in `unavailableLabels` for a `notice` event.
 */
export async function resolveMessageAppParts(
  db: DbExecutor,
  opts: {
    botIds: string[];
    actingUserId?: string | null;
    text: string;
    picked?: AppMentionRefInput[];
    reservedNames?: string[];
    allBotIds?: string[];
    orgId?: string;
  },
): Promise<{ parts: AppMentionPart[]; unavailableLabels: string[] }> {
  const usable = await loadMentionableApps(db, {
    botIds: opts.botIds,
    actingUserId: opts.actingUserId,
  });
  const { resolved, unresolvedPicked } = resolveAppMentions(opts.text, usable, opts.picked, {
    reservedNames: opts.reservedNames,
  });

  const parts: AppMentionPart[] = resolved.map((m) => ({
    type: "app",
    integration_id: m.integrationId,
    ...(m.toolkit ? { toolkit: m.toolkit } : {}),
    label: m.label,
    ...(m.appId ? { app_id: m.appId } : {}),
    source: m.source,
  }));

  const unavailableLabels: string[] = [];
  if (opts.allBotIds && opts.allBotIds.length > 0) {
    const resolvedKeys = new Set(resolved.map((m) => appMentionKey(m.integrationId, m.toolkit)));
    const otherBotIds = opts.allBotIds.filter((id) => !opts.botIds.includes(id));

    // Any picked app not usable by the woken bots: resolve its label from the org's integrations.
    if (unresolvedPicked.length > 0 && opts.orgId) {
      const ids = [...new Set(unresolvedPicked.map((p) => p.integration_id))];
      const rows = await db.execute<IntegrationAppRow>(sql`
        select id, kind, name, status, config from public.integrations
        where org_id = ${opts.orgId}::uuid
          and id in (select jsonb_array_elements_text(${JSON.stringify(ids)}::jsonb)::uuid)`);
      const expanded = mentionableAppsFromRows(rows);
      const byKey = new Map(expanded.map((a) => [appMentionKey(a.integrationId, a.toolkit), a]));
      for (const ref of unresolvedPicked) {
        const hit = byKey.get(appMentionKey(ref.integration_id, ref.toolkit));
        if (hit && !unavailableLabels.includes(hit.label)) unavailableLabels.push(hit.label);
      }
    }

    // Any plain-text @App matching another bot's integration in the group that none of the woken
    // bots has attached.
    if (otherBotIds.length > 0) {
      const otherApps = await loadMentionableApps(db, {
        botIds: otherBotIds,
        actingUserId: opts.actingUserId,
      });
      const textMatches = parseAppMentions(opts.text, otherApps, {
        reservedNames: opts.reservedNames,
      });
      for (const m of textMatches) {
        const key = appMentionKey(m.integrationId, m.toolkit);
        if (!resolvedKeys.has(key) && !unavailableLabels.includes(m.label)) {
          unavailableLabels.push(m.label);
        }
      }
    }
  }

  return { parts, unavailableLabels };
}

/** Extracts validated `{ type: "app" }` parts from a stored message's content array. */
export function partsApps(content: unknown): AppMentionPart[] {
  if (!Array.isArray(content)) return [];
  const out: AppMentionPart[] = [];
  for (const p of content) {
    if (!p || typeof p !== "object") continue;
    const obj = p as Record<string, unknown>;
    if (
      obj.type !== "app" ||
      typeof obj.integration_id !== "string" ||
      typeof obj.label !== "string"
    )
      continue;
    out.push({
      type: "app",
      integration_id: obj.integration_id,
      ...(typeof obj.toolkit === "string" && obj.toolkit ? { toolkit: obj.toolkit } : {}),
      label: obj.label,
      ...(typeof obj.app_id === "string" && obj.app_id ? { app_id: obj.app_id } : {}),
      ...(obj.source === "picker" || obj.source === "typed" ? { source: obj.source } : {}),
    });
  }
  return out.slice(0, 3);
}
