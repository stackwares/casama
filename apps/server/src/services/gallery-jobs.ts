/**
 * Gallery v2 background jobs (D-315), run by the worker process:
 * - hourly: roll up use counts and run success, refresh submission pull requests, grant
 *   contributor rewards;
 * - daily: the gallery health check (dead sign-in endpoints and links, much-reported items,
 *   items newer than this server), filed as reports in the owners' queue;
 * - on the 1st of the month: queue the opt-in "New for you" email.
 */
import type { Database } from "@casama/db";
import { galleryItemKey } from "@casama/domain";
import { sql } from "drizzle-orm";
import type { Env } from "../env.ts";
import { queueAccountEmail } from "./account-emails.ts";
import {
  galleryApps,
  galleryIndex,
  galleryRecords,
  galleryTooNew,
  splitGalleryId,
} from "./gallery.ts";
import { refreshSubmissionStatuses, type SubmitEnv } from "./gallery-community.ts";
import { rollupGalleryStats } from "./gallery-usage.ts";

type Log = (msg: string, extra?: Record<string, unknown>) => void;

// ---------------------------------------------------------------- contributor rewards

/** GALLERY_REWARDS as tiers, lowest first: `{"50":10,"250":25,"1000":75}` (active users → credits), or `off`. */
export function parseGalleryRewards(raw: string): { active: number; usd: number }[] {
  const v = raw.trim();
  if (!v || v === "off") return [];
  try {
    const obj = JSON.parse(v) as Record<string, unknown>;
    return Object.entries(obj)
      .map(([k, usd]) => ({ active: Number(k), usd: Number(usd) }))
      .filter(
        (t) =>
          Number.isInteger(t.active) &&
          t.active > 0 &&
          Number.isFinite(t.usd) &&
          t.usd > 0 &&
          t.usd <= 1000,
      )
      .sort((a, b) => a.active - b.active);
  } catch {
    return [];
  }
}

/** The most reward credits one contributor is paid in a calendar month (UTC), across all items. */
export const GALLERY_REWARD_MONTHLY_CAP_USD = 110;

/**
 * Records once per item and milestone a reward for whoever's merged submission made it, counting
 * only people who qualify (qualified_14d: confirmed email, account 7+ days old, not the author, a
 * run that succeeded; see gallery-usage.ts). Then pays recorded rewards oldest first while the
 * contributor is under GALLERY_REWARD_MONTHLY_CAP_USD this month; the rest stay recorded with
 * paid_at null, for next month or a review. Pays through the same credit_apply path as invite
 * rewards (reason `grant`, reference `gallery_reward:<item>:<n>`), so a repeat run can never pay
 * twice. Casama Cloud only (billing on). Returns how many rewards were paid.
 */
export async function rewardGalleryContributors(
  db: Database,
  env: Pick<Env, "BILLING_ENABLED" | "GALLERY_REWARDS">,
  opts: { now?: Date } = {},
): Promise<number> {
  if (!env.BILLING_ENABLED) return 0;
  const tiers = parseGalleryRewards(env.GALLERY_REWARDS);
  if (!tiers.length) return 0;
  const now = opts.now ?? new Date();
  const lowest = tiers[0]?.active ?? 1;
  const rows = await db.execute<{ item_key: string; user_id: string; active: number }>(sql`
    select distinct on (s.item_key) s.item_key, s.user_id::text as user_id, st.qualified_14d as active
    from public.gallery_submissions s join public.gallery_item_stats st on st.item_key = s.item_key
    where s.status = 'merged' and s.user_id is not null and st.qualified_14d >= ${lowest}
    order by s.item_key, s.created_at`);
  for (const r of rows)
    for (const t of tiers) {
      if (Number(r.active) < t.active) continue;
      await db.execute(sql`
        insert into public.gallery_rewards (item_key, milestone, user_id, usd, granted_at)
        values (${r.item_key}, ${t.active}, ${r.user_id}::uuid, ${t.usd}, ${now.toISOString()}::timestamptz)
        on conflict do nothing`);
    }
  const monthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1)).toISOString();
  const due = await db.execute<{
    item_key: string;
    milestone: number;
    user_id: string;
    usd: string;
  }>(sql`
    select item_key, milestone, user_id::text as user_id, usd::text as usd from public.gallery_rewards
    where paid_at is null and user_id is not null
    order by granted_at, item_key, milestone`);
  let paid = 0;
  for (const r of due) {
    const usd = Number(r.usd);
    const [month] = await db.execute<{ total: string }>(sql`
      select coalesce(sum(usd), 0)::text as total from public.gallery_rewards
      where user_id = ${r.user_id}::uuid and paid_at >= ${monthStart}::timestamptz`);
    // Over the cap: stays recorded and unpaid until next month (or an owner's review).
    if (Number(month?.total ?? 0) + usd > GALLERY_REWARD_MONTHLY_CAP_USD) continue;
    const [org] = await db.execute<{ id: string | null }>(
      sql`select public.referral_credit_org(${r.user_id}::uuid) as id`,
    );
    if (!org?.id) continue;
    await db.execute(sql`
      select public.credit_apply(${org.id}::uuid, ${usd}, 'grant',
        ${`gallery_reward:${r.item_key}:${r.milestone}`},
        ${`Gallery reward: ${r.milestone} people use what you made`})`);
    const [marked] = await db.execute<{ item_key: string }>(sql`
      update public.gallery_rewards set paid_at = ${now.toISOString()}::timestamptz, org_id = ${org.id}::uuid
      where item_key = ${r.item_key} and milestone = ${r.milestone} and paid_at is null
      returning item_key`);
    if (!marked) continue;
    paid++;
    await db.execute(sql`
      insert into public.notifications (user_id, org_id, kind, payload, push_status, push_after)
      values (${r.user_id}::uuid, ${org.id}::uuid, 'gallery_reward',
              ${JSON.stringify({
                title: `$${usd} in credits: thank you`,
                body: `${r.milestone} people are using what you added to the gallery.`,
                link: "/settings/gallery/submissions",
              })}::jsonb, 'deferred', now())`);
  }
  return paid;
}

// ---------------------------------------------------------------- monthly "New for you"

type DigestItem = { type: string; id: string; name: string; description: string };

/**
 * Queues the monthly email for people who turned it on: up to 6 items added in the last 30 days
 * that need apps they connected or are kinds they added before. Nothing that matches: no email.
 */
export async function queueGalleryDigests(
  db: Database,
  env: Env,
  opts: { now?: Date; fetch?: typeof fetch } = {},
): Promise<number> {
  const now = opts.now ?? new Date();
  const month = now.toISOString().slice(0, 7);
  const since = new Date(now.getTime() - 30 * 86_400_000).toISOString().slice(0, 10);
  const people = await db.execute<{ id: string }>(sql`
    select p.user_id::text as id from public.profiles p join auth.users u on u.id = p.user_id
    where p.gallery_digest and u.email is not null and u.email_confirmed_at is not null`);
  if (!people.length) return 0;
  const records = await galleryRecords(env, ["app", "bot", "routine", "plugin"], opts.fetch).catch(
    () => [],
  );
  const looks = (await galleryIndex(env, opts.fetch).catch(() => ({ items: [] }))).items;
  const fresh = [
    ...records.map((r) => ({ ...r }) as Record<string, unknown>),
    ...looks.map((l) => ({ ...(l as unknown as Record<string, unknown>) })),
  ]
    .filter(
      (r) => typeof r.added === "string" && (r.added as string) >= since && r.retired !== true,
    )
    .sort((a, b) => String(b.added).localeCompare(String(a.added)));
  if (!fresh.length) return 0;
  let queued = 0;
  for (const p of people) {
    const apps = await db.execute<{ app: string }>(sql`
      select distinct coalesce(i.config ->> 'app', i.name) as app from public.integrations i
      join public.memberships m on m.org_id = i.org_id where m.user_id = ${p.id}::uuid`);
    const kinds = await db.execute<{ kind: string }>(sql`
      select distinct split_part(l.item_key, '/', 1) as kind from public.gallery_links l
      join public.memberships m on m.org_id = l.org_id where m.user_id = ${p.id}::uuid`);
    const connected = new Set(apps.map((a) => a.app).filter(Boolean));
    const kindSet = new Set(kinds.map((k) => k.kind));
    const picked: DigestItem[] = [];
    for (const r of fresh) {
      if (picked.length >= 6) break;
      const needs = ((r.needs as { apps?: string[] } | undefined)?.apps ?? []).map(
        (a) => splitGalleryId(a).id,
      );
      const matchesApps =
        needs.length > 0 &&
        needs.every((a) => connected.has(a) || connected.has(a.replaceAll("-", "_")));
      if (!matchesApps && !kindSet.has(String(r.type))) continue;
      const doc = (r.document ?? {}) as { description?: unknown };
      picked.push({
        type: String(r.type),
        id: String(r.id),
        name: String(r.name),
        description: String(r.description ?? doc.description ?? "").slice(0, 160),
      });
    }
    if (!picked.length) continue;
    await queueAccountEmail(db, {
      kind: "gallery_digest",
      userId: p.id,
      dedupeKey: `gallery_digest:${p.id}:${month}`,
      data: { items: picked } as never,
    });
    queued++;
  }
  return queued;
}

// ---------------------------------------------------------------- nightly health

export type HealthCheck =
  | "app_unreachable"
  | "composio_missing"
  | "dead_link"
  | "reports"
  | "min_server";

/** Whether an address answers (3 tries; a 404 or 410 counts as gone, any other answer as there). */
async function alive(url: string, fetchImpl: typeof fetch): Promise<boolean> {
  for (let i = 0; i < 3; i++) {
    try {
      let res = await fetchImpl(url, { method: "HEAD", signal: AbortSignal.timeout(10_000) });
      if (res.status === 405 || res.status === 501)
        res = await fetchImpl(url, { method: "GET", signal: AbortSignal.timeout(10_000) });
      return res.status !== 404 && res.status !== 410;
    } catch {
      // try again
    }
  }
  return false;
}

/** Files one finding as an open report (target gallery_item, reason health:<check>), once. */
async function fileFinding(db: Database, key: string, check: HealthCheck, note: string) {
  const r = await db.execute<{ id: string }>(sql`
    insert into public.content_reports (reporter_id, target_kind, target_id, reason, note, snapshot)
    values (null, 'gallery_item', ${key}, ${`health:${check}`}, ${note.slice(0, 2000)}, ${`Gallery item ${key}`})
    on conflict do nothing returning id`);
  return r.length > 0;
}

export async function checkGalleryHealth(
  db: Database,
  env: Env,
  opts: { fetch?: typeof fetch; log?: Log } = {},
): Promise<{ checked: number; filed: number }> {
  const fetchImpl = opts.fetch ?? fetch;
  let filed = 0;
  let checked = 0;
  const file = async (key: string, check: HealthCheck, note: string) => {
    if (await fileFinding(db, key, check, note)) filed++;
  };
  // Apps: the sign-in endpoint (the app's MCP address) still answers; Composio still has the toolkit.
  const apps = await galleryApps(env, fetchImpl).catch(() => []);
  for (const a of apps) {
    checked++;
    if (!(await alive(a.url, fetchImpl)))
      await file(galleryItemKey("app", a.id), "app_unreachable", `${a.url} doesn't answer`);
    if (a.composio && env.COMPOSIO_API_KEY) {
      const base = (env.COMPOSIO_API_URL ?? "https://backend.composio.dev/api/v3").replace(
        /\/$/,
        "",
      );
      try {
        const res = await fetchImpl(`${base}/toolkits/${encodeURIComponent(a.composio)}`, {
          headers: { "x-api-key": env.COMPOSIO_API_KEY },
          signal: AbortSignal.timeout(10_000),
        });
        if (res.status === 404)
          await file(
            galleryItemKey("app", a.id),
            "composio_missing",
            `Composio has no toolkit ${a.composio}`,
          );
      } catch {
        // Composio down: not this item's problem.
      }
    }
  }
  // Author links and plugin folders.
  const records = await galleryRecords(
    env,
    ["theme", "scheme", "wallpaper", "skill", "app", "bot", "routine", "plugin"],
    fetchImpl,
  ).catch(() => []);
  const urls = new Map<string, string[]>();
  for (const r of records) {
    if (r.retired === true) continue;
    const key = galleryItemKey(r.type, r.id);
    const add = (u: unknown) => {
      if (typeof u !== "string" || !u.startsWith("https://")) return;
      urls.set(u, [...(urls.get(u) ?? []), key]);
    };
    add((r.author as { url?: unknown } | undefined)?.url);
    if (r.type === "plugin") add((r.document as { url?: unknown } | undefined)?.url);
  }
  for (const [url, keys] of urls) {
    checked++;
    if (!(await alive(url, fetchImpl)))
      for (const key of keys) await file(key, "dead_link", `${url} is gone`);
  }
  // Items with 3 or more open reports from people.
  const reported = await db.execute<{ target_id: string; n: number }>(sql`
    select target_id, count(*)::int as n from public.content_reports
    where target_kind = 'gallery_item' and status = 'open' and reporter_id is not null
    group by target_id having count(*) >= 3`);
  for (const r of reported) await file(r.target_id, "reports", `${r.n} open reports`);
  // Items this server can't use yet.
  for (const t of await galleryTooNew(env, fetchImpl).catch(() => []))
    await file(
      galleryItemKey(t.type, t.id),
      "min_server",
      `Needs server ${t.min_server}; this one is older. Update the server to offer it.`,
    );
  opts.log?.("gallery health checked", { checked, filed });
  return { checked, filed };
}

// ---------------------------------------------------------------- the loop

/** The worker's gallery loop. Returns a stopper. */
export function startGalleryJobs(opts: {
  db: Database;
  env: Env;
  fetch?: typeof fetch;
  log?: Log;
}): () => Promise<void> {
  let hourlyAt = 0;
  let dailyAt = 0;
  let digestMonth = "";
  let busy = false;
  const step = async (name: string, fn: () => Promise<unknown>) => {
    try {
      await fn();
    } catch (err) {
      opts.log?.(`gallery ${name} failed`, { error: (err as Error).message });
    }
  };
  const tick = async () => {
    if (busy) return;
    busy = true;
    try {
      const now = Date.now();
      if (now - hourlyAt >= 3_600_000) {
        hourlyAt = now;
        await step("rollup", () => rollupGalleryStats(opts.db, opts.env));
        await step("submissions", () =>
          refreshSubmissionStatuses(
            opts.db,
            opts.env as SubmitEnv,
            { olderThanMinutes: 60 },
            opts.fetch,
          ),
        );
        await step("rewards", () => rewardGalleryContributors(opts.db, opts.env));
      }
      if (now - dailyAt >= 86_400_000) {
        dailyAt = now;
        await step("health", () => checkGalleryHealth(opts.db, opts.env, opts));
      }
      const d = new Date(now);
      const month = d.toISOString().slice(0, 7);
      if (d.getUTCDate() === 1 && digestMonth !== month) {
        digestMonth = month;
        await step("digest", () => queueGalleryDigests(opts.db, opts.env, { fetch: opts.fetch }));
      }
    } finally {
      busy = false;
    }
  };
  const timer = setInterval(tick, 10 * 60_000);
  timer.unref?.();
  // The first pass waits a little, so a restart doesn't hit the gallery hosts at once.
  const first = setTimeout(tick, 60_000);
  first.unref?.();
  return async () => {
    clearInterval(timer);
    clearTimeout(first);
  };
}
