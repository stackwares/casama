/**
 * Privacy (D-072): data export, account deletion with a grace period, and run event retention.
 * Exports run under the user's session, so they contain exactly what RLS lets the user see.
 */
import type { ComputerService } from "@casama/agent";
import { memoryBackendConfig, storeFromConfig } from "@casama/agent";
import { type Database, type JwtClaims, withUserSession } from "@casama/db";
import { captureError } from "@casama/observability";
import { sql } from "drizzle-orm";
import { strToU8, zipSync } from "fflate";
import { erasePostHogPerson } from "./posthog-erase.ts";

/** Per-workspace tables in the export, in a readable order. */
const ORG_TABLES = [
  "bots",
  "conversations",
  "messages",
  "attachments",
  "runs",
  "run_events",
  "approvals",
  "memories",
  "skills",
  "routines",
  "tasks",
  "computers",
  "checkpoints",
  "integrations",
  "bot_integrations",
  "tool_grants",
  "secrets",
  "model_credentials",
  "local_devices",
  "usage_ledger",
  "subscriptions",
  "credit_ledger",
  "audit_log",
] as const;

/** Never exported: secret references, token hashes and vectors. */
const DROP = new Set([
  "vault_secret_id",
  "token_hash",
  "key_hash",
  "embedding",
  "fcm_token",
  "audio",
]);

const clean = (rows: Array<Record<string, unknown>>) =>
  rows.map((r) => Object.fromEntries(Object.entries(r).filter(([k]) => !DROP.has(k))));

export async function exportUserData(db: Database, claims: JwtClaims) {
  return withUserSession(db, claims, async (tx) => {
    const files: Record<string, Uint8Array> = {};
    const put = (name: string, value: unknown) => {
      files[name] = strToU8(`${JSON.stringify(value, null, 2)}\n`);
    };
    const q = async (query: ReturnType<typeof sql>) =>
      clean((await tx.execute<Record<string, unknown>>(query)) as Array<Record<string, unknown>>);
    put("account.json", {
      user_id: claims.sub,
      email: claims.email ?? null,
      exported_at: new Date().toISOString(),
      profile:
        (await q(sql`select * from public.profiles where user_id = ${claims.sub}::uuid`))[0] ??
        null,
      // About you (D-169): what bots know about the person, across workspaces.
      about_you: {
        about:
          (await q(sql`select * from public.user_about where user_id = ${claims.sub}::uuid`))[0] ??
          null,
        facts: await q(
          sql`select id, kind, content, pinned, source_org_id, source_bot_id, created_at, updated_at from public.user_facts where user_id = ${claims.sub}::uuid order by created_at`,
        ),
        spaces: await q(
          sql`select org_id, share_about, updated_at from public.profile_spaces where user_id = ${claims.sub}::uuid`,
        ),
      },
      push_devices: await q(sql`select * from public.devices where user_id = ${claims.sub}::uuid`),
      // Device connections (D-149): the person's own shared device data.
      device_sources: await q(
        sql`select id, name, platform, kinds, last_seen_at, created_at from public.device_sources where user_id = ${claims.sub}::uuid`,
      ),
      device_readings: await q(
        sql`select source_id, kind, period_start, period_end, external_id, summary, collected_at from public.device_readings where user_id = ${claims.sub}::uuid`,
      ),
      device_grants: await q(
        sql`select bot_id, kind, created_at from public.device_grants where user_id = ${claims.sub}::uuid`,
      ),
      notifications: await q(
        sql`select * from public.notifications where user_id = ${claims.sub}::uuid`,
      ),
    });
    const orgs = await q(sql`
      select o.*, m.role from public.organizations o
      join public.memberships m on m.org_id = o.id and m.user_id = ${claims.sub}::uuid order by o.created_at`);
    put("workspaces.json", orgs);
    for (const org of orgs) {
      const dir = `workspaces/${org.slug as string}`;
      put(`${dir}/workspace.json`, org);
      put(
        `${dir}/members.json`,
        await q(sql`select * from public.memberships where org_id = ${org.id as string}::uuid`),
      );
      for (const t of ORG_TABLES)
        put(
          `${dir}/${t}.json`,
          await q(sql`select * from ${sql.identifier(t)} where org_id = ${org.id as string}::uuid`),
        );
      // Memory kept in Honcho or Supermemory (D-137) is exported from there.
      const backend = await memoryBackendConfig(db, org.id as string);
      if (backend) {
        const store = storeFromConfig(backend, org.id as string);
        const bots = await q(
          sql`select id from public.bots where org_id = ${org.id as string}::uuid`,
        );
        const all = [];
        for (const b of bots) all.push(...(await store.list(b.id as string).catch(() => [])));
        put(`${dir}/memories.json`, all);
      }
    }
    files["README.txt"] = strToU8(
      "Your Casama data export. Each workspace you belong to has a folder of JSON files, limited to what your role can see.\nSecrets, model keys and device tokens are never exported (only their names).\n",
    );
    return zipSync(files, { level: 6 });
  });
}

/** Signs the user out everywhere and schedules the purge. */
export async function requestAccountDeletion(db: Database, userId: string, graceDays: number) {
  const purgeAfter = new Date(Date.now() + graceDays * 86_400_000);
  const solo = await soleOwnedOrgs(db, userId);
  await db.transaction(async (tx) => {
    await tx.execute(sql`
      insert into public.account_deletions (user_id, purge_after) values (${userId}::uuid, ${purgeAfter.toISOString()}::timestamptz)
      on conflict (user_id) do update set purge_after = least(public.account_deletions.purge_after, excluded.purge_after)`);
    await tx.execute(
      sql`update auth.users set banned_until = 'infinity'::timestamptz where id = ${userId}::uuid`,
    );
    await tx.execute(sql`delete from public.devices where user_id = ${userId}::uuid`);
    // Shared device data goes right away too (D-149); the rest goes with the account.
    await tx.execute(sql`delete from public.device_sources where user_id = ${userId}::uuid`);
  });
  // End every session (Supabase Auth tables; absent in the test shim, so outside the transaction).
  await db.execute(sql`delete from auth.sessions where user_id = ${userId}::uuid`).catch(() => {});
  await db
    .execute(sql`delete from auth.refresh_tokens where user_id = ${userId}::text`)
    .catch(() => {});
  return { purgeAfter, solo };
}

async function soleOwnedOrgs(db: Database, userId: string) {
  return db.execute<{ id: string; name: string }>(sql`
    select o.id, o.name from public.organizations o
    join public.memberships m on m.org_id = o.id and m.user_id = ${userId}::uuid and m.role = 'owner'
    where not exists (select 1 from public.memberships m2 where m2.org_id = o.id and m2.role = 'owner' and m2.user_id <> ${userId}::uuid)`);
}

/** Daily: purge accounts past their grace period (workspaces, snapshots, then the user). */
export async function purgeDueAccounts(
  db: Database,
  computers?: ComputerService,
  opts: { erase?: (userId: string) => Promise<unknown> } = {},
) {
  const due = await db.execute<{ user_id: string }>(sql`
    select user_id from public.account_deletions where completed_at is null and purge_after <= now() limit 50`);
  for (const { user_id } of due) {
    const orgs = await soleOwnedOrgs(db, user_id);
    for (const org of orgs) {
      // Computer archives live outside Postgres; remove them before the rows cascade away.
      const comps = await db.execute<{ id: string }>(
        sql`select id from public.computers where org_id = ${org.id}::uuid`,
      );
      for (const c of comps) {
        await computers?.remove(c.id).catch((e) => {
          captureError(e, {
            service: "casama-worker",
            step: "purge-computer",
            computer_id: c.id,
            org_id: org.id,
          });
        });
      }
      // So is memory kept in Honcho or Supermemory (D-137).
      const backend = await memoryBackendConfig(db, org.id);
      if (backend) {
        const bots = await db.execute<{ id: string }>(
          sql`select id from public.bots where org_id = ${org.id}::uuid`,
        );
        await storeFromConfig(backend, org.id)
          .deleteAll(bots.map((b) => b.id))
          .catch((e) => {
            captureError(e, { service: "casama-worker", step: "purge-memories", org_id: org.id });
          });
      }
      await db.execute(sql`delete from public.organizations where id = ${org.id}::uuid`);
    }
    // Product analytics for this person (PostHog). A failure is reported with the id so it can be erased by
    // hand; it never blocks erasing the account itself.
    await (opts.erase ?? erasePostHogPerson)(user_id).catch((e) => {
      captureError(e, { service: "casama-worker", step: "purge-analytics", user_id });
    });
    await db.execute(sql`select public.worker_purge_user(${user_id}::uuid)`);
    await db.execute(sql`
      update public.account_deletions set completed_at = now(), orgs_deleted = ${orgs.length} where user_id = ${user_id}::uuid`);
  }
  return due.length;
}

/** Daily: drop run events older than each workspace's retention. */
export async function applyRetention(db: Database) {
  const rows = await db.execute<{ n: number }>(sql`
    with d as (
      delete from public.run_events e using public.organizations o
      where e.org_id = o.id and e.created_at < now() - make_interval(days => o.run_event_retention_days)
      returning 1)
    select count(*)::int as n from d`);
  return rows[0]?.n ?? 0;
}
