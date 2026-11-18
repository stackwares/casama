/**
 * Gallery use counts (D-315), aggregate only. Each person and item is one row keyed by an HMAC of
 * the user id and the item, so the table never holds a user id or a workspace id. The worker rolls
 * the rows (and the runs that used each item) into gallery_item_stats every hour; the public stats
 * leave out anything under 10 people, and run success under 20 runs.
 *
 * Contributor rewards read a stricter count than the public one (qualified_at, qualified_14d):
 * only people whose email is confirmed, whose account was at least 7 days old, who didn't submit
 * the item, and who had a run succeed with it. Kinds no run can point at (looks, plugins, sets)
 * count when a run of that person's succeeded after they first used the item.
 */
import { createHmac } from "node:crypto";
import type { Database } from "@casama/db";
import { galleryItemKey } from "@casama/domain";
import { sql } from "drizzle-orm";
import type { Env } from "../env.ts";

export const STATS_MIN_INSTALLERS = 10;
export const STATS_MIN_RUNS = 20;
/** How old an account must be before it counts toward contributor rewards. */
export const REWARD_MIN_ACCOUNT_DAYS = 7;
/** Item kinds a run can point at (rollup below); the rest count through any succeeded run. */
const RUN_LINKED_KINDS = ["skill", "routine", "bot", "app"];

type HashEnv = Pick<Env, "SUPABASE_JWT_SECRET" | "CONTENT_ENCRYPTION_KEY" | "DATABASE_URL">;

/** The server's key for usage hashes: derived from a secret every server already has. */
function hashSecret(env: HashEnv): string {
  return `gallery-installs:${env.SUPABASE_JWT_SECRET ?? env.CONTENT_ENCRYPTION_KEY ?? env.DATABASE_URL}`;
}

export function galleryUserHash(env: HashEnv, userId: string, itemKey: string): string {
  return createHmac("sha256", hashSecret(env)).update(`${userId}|${itemKey}`).digest("hex");
}

/** Counts someone as using an item: first time adds them, later times only refresh "last used". */
export async function recordGalleryUse(
  db: Database,
  env: HashEnv,
  userId: string,
  type: string,
  id: string,
  at: Date = new Date(),
): Promise<void> {
  const key = galleryItemKey(type, id);
  const hash = galleryUserHash(env, userId, key);
  await db.execute(sql`
    insert into public.gallery_installs (item_key, user_hash, first_at, last_used_at)
    values (${key}, ${hash}, ${at.toISOString()}::timestamptz, ${at.toISOString()}::timestamptz)
    on conflict (item_key, user_hash) do update
      set last_used_at = greatest(public.gallery_installs.last_used_at, excluded.last_used_at)`);
}

/** Marks a person's use of an item as counting toward rewards (see the header), as of `at`. */
async function markGalleryQualified(
  db: Database,
  pairs: { key: string; hash: string }[],
  at: Date,
  requireFirstBefore: boolean,
): Promise<number> {
  let n = 0;
  for (let i = 0; i < pairs.length; i += 500) {
    const chunk = pairs.slice(i, i + 500);
    const res = await db.execute<{ item_key: string }>(sql`
      update public.gallery_installs g
        set qualified_at = greatest(coalesce(g.qualified_at, '-infinity'::timestamptz), ${at.toISOString()}::timestamptz)
      from (values ${sql.join(
        chunk.map((p) => sql`(${p.key}, ${p.hash})`),
        sql`, `,
      )}) as x(item_key, user_hash)
      where g.item_key = x.item_key and g.user_hash = x.user_hash
        ${requireFirstBefore ? sql`and g.first_at <= ${at.toISOString()}::timestamptz` : sql``}
      returning g.item_key`);
    n += res.length;
  }
  return n;
}

type RewardPerson = { confirmed: boolean; createdAt: Date; submitted: Set<string> };

/** What the reward rules need to know about each person: confirmed, account age, own items. */
async function rewardPeople(db: Database, ids: string[]): Promise<Map<string, RewardPerson>> {
  const out = new Map<string, RewardPerson>();
  const uniq = [...new Set(ids)].filter(Boolean);
  for (let i = 0; i < uniq.length; i += 500) {
    const chunk = uniq.slice(i, i + 500);
    const list = sql.join(
      chunk.map((id) => sql`${id}::uuid`),
      sql`, `,
    );
    const users = await db.execute<{ id: string; confirmed: boolean; created_at: string }>(sql`
      select id::text, email_confirmed_at is not null as confirmed, created_at::text
      from auth.users where id in (${list})`);
    for (const u of users)
      out.set(u.id, {
        confirmed: u.confirmed,
        createdAt: new Date(u.created_at),
        submitted: new Set(),
      });
    const subs = await db.execute<{ user_id: string; item_key: string }>(sql`
      select distinct user_id::text, item_key from public.gallery_submissions where user_id in (${list})`);
    for (const s of subs) out.get(s.user_id)?.submitted.add(s.item_key);
  }
  return out;
}

/** The person rules: confirmed email, an account old enough at `at`, and not the item's author. */
function countsForRewards(p: RewardPerson | undefined, key: string, at: Date): boolean {
  if (!p?.confirmed || p.submitted.has(key)) return false;
  return p.createdAt.getTime() <= at.getTime() - REWARD_MIN_ACCOUNT_DAYS * 86_400_000;
}

/** Never lets counting break an install. */
export function recordGalleryUseQuietly(
  db: Database,
  env: HashEnv,
  userId: string,
  type: string,
  id: string,
) {
  void recordGalleryUse(db, env, userId, type, id).catch(() => {});
}

/**
 * Remembers what a workspace added from the gallery and at which version (the Installed list and
 * updates read it), and counts the person.
 */
export async function linkGalleryInstall(
  db: Database,
  env: HashEnv,
  l: {
    orgId: string;
    userId: string | null;
    type: string;
    id: string;
    targetKind: "skill" | "bot" | "routine" | "app" | "plugin";
    targetId: string;
    version?: number;
    access?: unknown;
    inputs?: Record<string, string>;
  },
): Promise<void> {
  const key = galleryItemKey(l.type, l.id);
  await db.execute(sql`
    insert into public.gallery_links (org_id, target_kind, target_id, item_key, version, access, inputs, installed_by)
    values (${l.orgId}::uuid, ${l.targetKind}, ${l.targetId}, ${key}, ${Math.max(1, l.version ?? 1)},
            ${JSON.stringify(l.access ?? {})}::jsonb, ${JSON.stringify(l.inputs ?? {})}::jsonb, ${l.userId}::uuid)
    on conflict (org_id, target_kind, target_id) do update
      set item_key = excluded.item_key, version = excluded.version, access = excluded.access,
          inputs = excluded.inputs, updated_at = now()`);
  if (l.userId) await recordGalleryUse(db, env, l.userId, l.type, l.id).catch(() => {});
}

/** The same, never failing the install it follows. */
export async function linkGalleryInstallQuietly(
  db: Database,
  env: HashEnv,
  l: Parameters<typeof linkGalleryInstall>[2],
  log?: (msg: string, extra?: Record<string, unknown>) => void,
) {
  await linkGalleryInstall(db, env, l).catch((e: Error) =>
    log?.("gallery link not recorded", { error: e.message }),
  );
}

export interface PublicStats {
  installers?: number;
  trending?: number;
  active?: number;
  success?: number;
}

type StatsRow = {
  item_key: string;
  installers: number;
  installers_7d: number;
  active_14d: number;
  runs_ok: number;
  runs_total: number;
};

/** The rule for public numbers: nothing under 10 installers, no success rate under 20 runs. */
export function publicStatsOf(r: StatsRow): PublicStats | null {
  if (r.installers < STATS_MIN_INSTALLERS) return null;
  return {
    installers: r.installers,
    trending: r.installers_7d,
    active: r.active_14d,
    ...(r.runs_total >= STATS_MIN_RUNS
      ? { success: Math.round((r.runs_ok / r.runs_total) * 1000) / 1000 }
      : {}),
  };
}

let ownCache: { at: number; items: Record<string, PublicStats> } | null = null;
let remoteCache: { at: number; url: string; items: Record<string, PublicStats> } | null = null;

export function resetGalleryStatsCache() {
  ownCache = null;
  remoteCache = null;
}

/** This server's own stats, thresholded (cached a minute). */
export async function ownGalleryStats(db: Database): Promise<Record<string, PublicStats>> {
  if (ownCache && Date.now() - ownCache.at < 60_000) return ownCache.items;
  const rows = await db.execute<StatsRow>(sql`
    select item_key, installers, installers_7d, active_14d, runs_ok, runs_total
    from public.gallery_item_stats where installers >= ${STATS_MIN_INSTALLERS}`);
  const items: Record<string, PublicStats> = {};
  for (const r of rows) {
    const s = publicStatsOf({
      ...r,
      installers: Number(r.installers),
      installers_7d: Number(r.installers_7d),
      active_14d: Number(r.active_14d),
      runs_ok: Number(r.runs_ok),
      runs_total: Number(r.runs_total),
    });
    if (s) items[r.item_key] = s;
  }
  ownCache = { at: Date.now(), items };
  return items;
}

/**
 * The stats this server shows: Casama Cloud (billing on) counts its own; a self-hosted server
 * shows Casama's public numbers from GALLERY_STATS_URL (cached 10 minutes), or none when `off`.
 */
export async function galleryStats(
  db: Database,
  env: Pick<Env, "BILLING_ENABLED" | "GALLERY_STATS_URL">,
  fetchImpl: typeof fetch = fetch,
): Promise<Record<string, PublicStats>> {
  if (env.BILLING_ENABLED) return ownGalleryStats(db);
  const url = env.GALLERY_STATS_URL.trim();
  if (!url || url === "off") return {};
  if (remoteCache && remoteCache.url === url && Date.now() - remoteCache.at < 600_000)
    return remoteCache.items;
  const keep = (items: Record<string, PublicStats>, ttlShort = false) => {
    // A failure is kept a minute so a down host isn't asked on every list.
    remoteCache = { at: ttlShort ? Date.now() - 540_000 : Date.now(), url, items };
    return items;
  };
  try {
    const res = await fetchImpl(url, { signal: AbortSignal.timeout(5_000) });
    if (!res.ok) return keep(remoteCache?.items ?? {}, true);
    const body = (await res.json()) as { items?: unknown };
    const items: Record<string, PublicStats> = {};
    if (body && typeof body.items === "object" && body.items !== null)
      for (const [k, v] of Object.entries(body.items as Record<string, unknown>)) {
        if (typeof v !== "object" || v === null || k.length > 140) continue;
        const s = v as Record<string, unknown>;
        const n = (x: unknown) => (typeof x === "number" && Number.isFinite(x) ? x : undefined);
        const out: PublicStats = {};
        for (const f of ["installers", "trending", "active", "success"] as const) {
          const val = n(s[f]);
          if (val !== undefined) out[f] = val;
        }
        items[k] = out;
      }
    return keep(items);
  } catch {
    return keep(remoteCache?.items ?? {}, true);
  }
}

/** Adds `stats` to each item that has some. */
export function withStats<T extends { id: string }>(
  type: string | ((item: T) => string),
  items: T[],
  stats: Record<string, PublicStats>,
): (T & { stats?: PublicStats })[] {
  return items.map((i) => {
    const s = stats[galleryItemKey(typeof type === "string" ? type : type(i), i.id)];
    return s ? { ...i, stats: s } : i;
  });
}

/**
 * The hourly rollup: who used linked items lately (skills a run loaded, routines that ran, bots
 * that replied, apps whose tools were called), run success for skills and routines over 30 days,
 * then the per-item counts. Best effort and cheap: only runs of workspaces with gallery links.
 */
export async function rollupGalleryStats(
  db: Database,
  env: HashEnv,
  opts: { now?: Date; lookbackHours?: number } = {},
): Promise<{ items: number; touched: number }> {
  const now = opts.now ?? new Date();
  const since = new Date(now.getTime() - (opts.lookbackHours ?? 2) * 3_600_000).toISOString();
  const nowIso = now.toISOString();
  const used = await db.execute<{
    item_key: string;
    user_id: string;
    at: string;
    ok_at: string | null;
  }>(sql`
    with links as (
      select l.org_id, l.target_kind, l.target_id, l.item_key, l.installed_by from public.gallery_links l
    ),
    recent as (
      select r.id, r.org_id, r.bot_id, r.routine_id, r.created_by, r.created_at, r.status
      from public.runs r join public.bots b on b.id = r.bot_id
      where b.org_id in (select org_id from links)
        and r.created_at > ${since}::timestamptz
    ),
    events as (
      select e.run_id, e.type, e.payload from public.run_events e
      where e.run_id in (select id from recent) and e.type in ('skill.loaded', 'tool.started')
    )
    select l.item_key, coalesce(r.created_by, l.installed_by)::text as user_id, max(r.created_at)::text as at,
      max(r.created_at) filter (where r.status = 'completed')::text as ok_at
    from events e join recent r on r.id = e.run_id
    join links l on l.target_kind = 'skill' and l.org_id = r.org_id and l.target_id = e.payload ->> 'skill_id'
    where e.type = 'skill.loaded'
    group by 1, 2
    union all
    select l.item_key, coalesce(r.created_by, l.installed_by)::text, max(r.created_at)::text,
      max(r.created_at) filter (where r.status = 'completed')::text
    from recent r join links l on l.target_kind = 'routine' and l.target_id = r.routine_id::text
    group by 1, 2
    union all
    select l.item_key, coalesce(r.created_by, l.installed_by)::text, max(r.created_at)::text,
      max(r.created_at) filter (where r.status = 'completed')::text
    from recent r join links l on l.target_kind = 'bot' and l.target_id = r.bot_id::text
    where r.status = 'completed'
    group by 1, 2
    union all
    select l.item_key, coalesce(r.created_by, l.installed_by)::text, max(r.created_at)::text,
      max(r.created_at) filter (where r.status = 'completed')::text
    from events e join recent r on r.id = e.run_id
    join links l on l.target_kind = 'app' and l.org_id = r.org_id
    join public.integrations i on i.id::text = l.target_id
    where e.type = 'tool.started' and (e.payload ->> 'tool') like ('mcp.' || i.name || '.%')
    group by 1, 2`);
  let touched = 0;
  const people = await rewardPeople(
    db,
    used.filter((u) => u.ok_at).map((u) => u.user_id),
  );
  for (const u of used) {
    if (!u.user_id) continue;
    const [type, ...rest] = u.item_key.split("/");
    await recordGalleryUse(db, env, u.user_id, type as string, rest.join("/"), new Date(u.at));
    touched++;
    // A run succeeded with the item: counts toward rewards if the person does.
    if (u.ok_at && countsForRewards(people.get(u.user_id), u.item_key, new Date(u.ok_at)))
      await markGalleryQualified(
        db,
        [{ key: u.item_key, hash: galleryUserHash(env, u.user_id, u.item_key) }],
        new Date(u.ok_at),
        false,
      );
  }
  // Kinds no run points at (looks, plugins, sets): a person counts when a run they started
  // succeeded after they first used the item. Only hashes are matched, never stored ids.
  const otherKeys = (
    await db.execute<{ item_key: string }>(sql`
      select distinct item_key from public.gallery_installs
      where split_part(item_key, '/', 1) not in (${sql.join(
        RUN_LINKED_KINDS.map((k) => sql`${k}`),
        sql`, `,
      )})`)
  ).map((r) => r.item_key);
  if (otherKeys.length) {
    const runners = await db.execute<{ user_id: string; at: string }>(sql`
      select r.created_by::text as user_id, max(r.created_at)::text as at from public.runs r
      where r.created_at > ${since}::timestamptz and r.status = 'completed' and r.created_by is not null
      group by 1`);
    const runnerPeople = await rewardPeople(
      db,
      runners.map((r) => r.user_id),
    );
    for (const r of runners) {
      const at = new Date(r.at);
      const pairs = otherKeys
        .filter((key) => countsForRewards(runnerPeople.get(r.user_id), key, at))
        .map((key) => ({ key, hash: galleryUserHash(env, r.user_id, key) }));
      if (pairs.length) await markGalleryQualified(db, pairs, at, true);
    }
  }
  // Run success over 30 days: runs that loaded a linked skill, and runs of linked routines.
  const month = new Date(now.getTime() - 30 * 86_400_000).toISOString();
  const runs = await db.execute<{ item_key: string; ok: number; total: number }>(sql`
    with links as (select org_id, target_kind, target_id, item_key from public.gallery_links),
    recent as (
      select r.id, r.org_id, r.routine_id, r.status from public.runs r join public.bots b on b.id = r.bot_id
      where b.org_id in (select org_id from links)
        and r.created_at > ${month}::timestamptz and r.status in ('completed', 'failed')
    ),
    used as (
      select distinct l.item_key, r.id, r.status
      from recent r join public.run_events e on e.run_id = r.id and e.type = 'skill.loaded'
      join links l on l.target_kind = 'skill' and l.org_id = r.org_id and l.target_id = e.payload ->> 'skill_id'
      union
      select distinct l.item_key, r.id, r.status
      from recent r join links l on l.target_kind = 'routine' and l.target_id = r.routine_id::text
    )
    select item_key, count(*) filter (where status = 'completed')::int as ok, count(*)::int as total
    from used group by item_key`);
  const runsBy = new Map(runs.map((r) => [r.item_key, r]));
  const rows = await db.execute<{
    item_key: string;
    installers: number;
    installers_7d: number;
    active_14d: number;
    qualified_14d: number;
  }>(sql`
    select item_key, count(*)::int as installers,
      count(*) filter (where first_at > ${nowIso}::timestamptz - interval '7 days')::int as installers_7d,
      count(*) filter (where last_used_at > ${nowIso}::timestamptz - interval '14 days')::int as active_14d,
      count(*) filter (where qualified_at > ${nowIso}::timestamptz - interval '14 days')::int as qualified_14d
    from public.gallery_installs group by item_key`);
  const keys = new Set([...rows.map((r) => r.item_key), ...runsBy.keys()]);
  const byKey = new Map(rows.map((r) => [r.item_key, r]));
  for (const key of keys) {
    const r = byKey.get(key);
    const x = runsBy.get(key);
    await db.execute(sql`
      insert into public.gallery_item_stats (item_key, installers, installers_7d, active_14d, qualified_14d, runs_ok, runs_total, updated_at)
      values (${key}, ${r?.installers ?? 0}, ${r?.installers_7d ?? 0}, ${r?.active_14d ?? 0},
              ${r?.qualified_14d ?? 0}, ${x?.ok ?? 0}, ${x?.total ?? 0}, now())
      on conflict (item_key) do update set installers = excluded.installers,
        installers_7d = excluded.installers_7d, active_14d = excluded.active_14d,
        qualified_14d = excluded.qualified_14d,
        runs_ok = excluded.runs_ok, runs_total = excluded.runs_total, updated_at = now()`);
  }
  resetGalleryStatsCache();
  return { items: keys.size, touched };
}
