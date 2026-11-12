/**
 * Encryption at rest (D-136): turning it on and off for a workspace, key rotation, and the sweep that
 * seals existing rows (and any row a write path missed) or opens them again when it's turned off.
 * Data key rotation (D-238): replacing a workspace's data key, and resealing rows onto the new key.
 */
import { contentKeys, type Database, isSealed } from "@casama/db";
import { sql } from "drizzle-orm";

/** Covered columns: table, column, json or text, and the row key. */
export const SEALED_COLUMNS = [
  { table: "messages", column: "content", json: true, key: ["id"] },
  { table: "run_events", column: "payload", json: true, key: ["run_id", "seq"] },
  { table: "memories", column: "content", json: false, key: ["id"] },
  { table: "conversations", column: "summary", json: false, key: ["id"] },
  { table: "tasks", column: "details_md", json: false, key: ["id"] },
  { table: "tasks", column: "result_md", json: false, key: ["id"] },
  { table: "task_comments", column: "body_md", json: false, key: ["id"] },
  { table: "pages", column: "html", json: false, key: ["id"] },
  { table: "pages", column: "data", json: true, key: ["id"] },
  { table: "page_versions", column: "html", json: false, key: ["page_id", "version"] },
  { table: "page_versions", column: "data", json: true, key: ["page_id", "version"] },
  { table: "knowledge_chunks", column: "text", json: false, key: ["id"] },
  // The default invite link's token, kept so the link can be shown again (D-167).
  { table: "invite_links", column: "share_token", json: false, key: ["id"] },
] as const;

export type EncryptionMode = "off" | "encrypting" | "on" | "decrypting";

export async function encryptionStatus(db: Database, orgId: string) {
  const [o] = await db.execute<{
    mode: EncryptionMode;
    wrapper: string | null;
    rotated_at: string | null;
    created_at: string | null;
    rekeying: boolean;
  }>(sql`
    select o.content_encryption as mode, k.wrapper, k.rotated_at, k.created_at,
           exists (select 1 from public.org_keys r where r.org_id = o.id and r.retired_at is not null) as rekeying
    from public.organizations o
    left join public.org_keys k on k.org_id = o.id and k.retired_at is null
    where o.id = ${orgId}::uuid`);
  return {
    mode: o?.mode ?? "off",
    available: contentKeys.configured,
    key: o?.wrapper
      ? o.wrapper.startsWith("kms:")
        ? ("aws_kms" as const)
        : ("server_key" as const)
      : null,
    rotated_at: o?.rotated_at ? new Date(o.rotated_at).toISOString() : null,
    since: o?.created_at ? new Date(o.created_at).toISOString() : null,
    // Rows are still being moved from a replaced data key to the current one (D-238).
    rekeying: (o?.mode === "on" || o?.mode === "encrypting") && !!o?.rekeying,
  };
}

/** Turns encryption on (a new data key, then the sweep seals existing rows) or off (the sweep opens them). */
export async function setEncryption(db: Database, orgId: string, enabled: boolean) {
  if (enabled) {
    if (!contentKeys.configured) throw new Error("not_configured");
    const [k] = await db.execute<{ id: string }>(
      sql`select id from public.org_keys where org_id = ${orgId}::uuid and retired_at is null`,
    );
    if (!k) {
      const nk = await contentKeys.newKey();
      await db.execute(sql`
        insert into public.org_keys (org_id, wrapped_key, wrapper) values (${orgId}::uuid, ${nk.wrapped}, ${nk.wrapper})`);
    }
    await db.execute(sql`
      update public.organizations set content_encryption = 'encrypting' where id = ${orgId}::uuid and content_encryption in ('off', 'decrypting')`);
  } else {
    await db.execute(sql`
      update public.organizations set content_encryption = 'decrypting' where id = ${orgId}::uuid and content_encryption in ('on', 'encrypting')`);
  }
  // This process seals (or stops sealing) right away; others hear the NOTIFY.
  await contentKeys.refresh();
  return encryptionStatus(db, orgId);
}

type KeyTable = "org_keys" | "user_keys";

async function rewrapRow(
  db: Database,
  table: KeyTable,
  k: { id: string; wrapped_key: string; wrapper: string },
) {
  const r = await contentKeys.rewrap(k.wrapped_key, k.wrapper);
  await db.execute(
    sql`update ${sql.raw(`public.${table}`)} set wrapped_key = ${r.wrapped}, wrapper = ${r.wrapper}, rotated_at = now() where id = ${k.id}::uuid`,
  );
}

/**
 * Rewraps the workspace's data keys (the current one and any being replaced) with the server's
 * current key; rows are not rewritten.
 */
export async function rotateEncryptionKey(db: Database, orgId: string) {
  const keys = await db.execute<{ id: string; wrapped_key: string; wrapper: string }>(sql`
    select id, wrapped_key, wrapper from public.org_keys where org_id = ${orgId}::uuid`);
  if (!keys.length) throw new Error("no_key");
  for (const k of keys) await rewrapRow(db, "org_keys", k);
  return encryptionStatus(db, orgId);
}

/**
 * Rewraps every data key still wrapped by an older server key (run after changing keys): workspace
 * keys and each person's About you key (D-169), so dropping CONTENT_ENCRYPTION_KEY_PREVIOUS later
 * can't strand any of them.
 */
export async function rewrapAllKeys(db: Database) {
  const id = contentKeys.wrapperId;
  if (!id) return 0;
  let n = 0;
  for (const table of ["org_keys", "user_keys"] as const) {
    const old = await db.execute<{ id: string; wrapped_key: string; wrapper: string }>(
      sql`select id, wrapped_key, wrapper from ${sql.raw(`public.${table}`)} where wrapper <> ${id}`,
    );
    for (const k of old) await rewrapRow(db, table, k);
    n += old.length;
  }
  return n;
}

/**
 * Replaces the workspace's data key (D-238), for when the database may have leaked: the current key
 * is retired (it keeps opening older rows, seals nothing new) and a new one takes over. The sweep
 * then reseals every row onto the new key and deletes the old one. People's About you keys (D-169)
 * for the workspace's members are replaced too.
 */
export async function replaceDataKey(db: Database, orgId: string, opts: { people?: boolean } = {}) {
  if (!contentKeys.configured) throw new Error("not_configured");
  const [o] = await db.execute<{ mode: EncryptionMode }>(
    sql`select content_encryption as mode from public.organizations where id = ${orgId}::uuid`,
  );
  if (o?.mode !== "on" && o?.mode !== "encrypting") throw new Error("not_encrypted");
  const nk = await contentKeys.newKey();
  // One statement: two replacements at once can't leave two current keys (the second finds none to retire).
  await db.execute(sql`
    with old as (
      update public.org_keys set retired_at = now()
      where org_id = ${orgId}::uuid and retired_at is null
      returning org_id)
    insert into public.org_keys (org_id, wrapped_key, wrapper)
    select org_id, ${nk.wrapped}, ${nk.wrapper} from old`);
  if (opts.people !== false) {
    const members = await db.execute<{ user_id: string }>(sql`
      select k.user_id from public.user_keys k
      join public.memberships m on m.user_id = k.user_id and m.org_id = ${orgId}::uuid
      where k.retired_at is null`);
    for (const m of members) await replaceUserKey(db, m.user_id);
  }
  await contentKeys.refresh();
  return encryptionStatus(db, orgId);
}

/** Replaces a person's About you key (D-169, D-238); the sweep reseals their rows. */
export async function replaceUserKey(db: Database, userId: string) {
  const nk = await contentKeys.newKey();
  await db.execute(sql`
    with old as (
      update public.user_keys set retired_at = now()
      where user_id = ${userId}::uuid and retired_at is null
      returning user_id)
    insert into public.user_keys (user_id, wrapped_key, wrapper)
    select user_id, ${nk.wrapped}, ${nk.wrapper} from old`);
}

/** Replaces every data key on this server (D-238): after a leak, run once; the worker does the rest. */
export async function replaceAllDataKeys(db: Database) {
  if (!contentKeys.configured) throw new Error("not_configured");
  const orgs = await db.execute<{ id: string }>(sql`
    select o.id from public.organizations o
    where o.content_encryption in ('on', 'encrypting')
      and exists (select 1 from public.org_keys k where k.org_id = o.id and k.retired_at is null)`);
  const users = await db.execute<{ user_id: string }>(
    sql`select user_id from public.user_keys where retired_at is null`,
  );
  for (const o of orgs) await replaceDataKey(db, o.id, { people: false });
  for (const u of users) await replaceUserKey(db, u.user_id);
  await contentKeys.refresh();
  return { workspaces: orgs.length, people: users.length };
}

const keyCols = (key: readonly string[]) => sql.raw(key.map((k) => `"${k}"`).join(", "));

/**
 * One pass of the sweep (the worker runs it every minute): seals up to `batch` plaintext rows per
 * column for workspaces that encrypt, and opens sealed rows for workspaces turning it off. A
 * workspace whose pass finds nothing left moves to `on` (or `off`, and its key is deleted).
 */
export async function sweepEncryption(
  db: Database,
  batch = 500,
  opts: { recheckOn?: boolean } = {},
) {
  // Fully sealed workspaces are only re-checked when asked (the worker does it every 15 minutes):
  // a scan per sealed column per workspace every minute costs more than it catches (audit 2026-11).
  const recheck = opts.recheckOn ?? new Date().getMinutes() % 15 === 0;
  const orgs = await db.execute<{ id: string; mode: EncryptionMode }>(sql`
    select id, content_encryption as mode from public.organizations
    where content_encryption in ('encrypting', 'decrypting') ${recheck ? sql`or content_encryption = 'on'` : sql``}`);
  let changed = 0;
  for (const o of orgs) {
    if (o.mode !== "decrypting" && !contentKeys.seals(o.id)) await contentKeys.refresh();
    let left = 0;
    for (const c of SEALED_COLUMNS) {
      const col = sql.raw(`"${c.column}"`);
      const t = sql.raw(`public.${c.table}`);
      const sealedCond = c.json
        ? sql`(jsonb_typeof(${col}) = 'object' and ${col} ? '$enc')`
        : sql`${col} like 'enc:v1:%'`;
      const want = o.mode === "decrypting" ? sealedCond : sql`not ${sealedCond}`;
      const nonEmpty = c.json ? sql`true` : sql`${col} is not null and ${col} <> ''`;
      // Once a workspace is fully sealed, only recent rows are checked (catching any missed write path).
      const recent = o.mode === "on" ? sql`and created_at > now() - interval '1 hour'` : sql``;
      const rows = await db.execute<Record<string, unknown>>(sql`
        select ${keyCols(c.key)}, ${col} as value from ${t} where org_id = ${o.id}::uuid and ${nonEmpty} and ${want} ${recent} limit ${batch}`);
      for (const r of rows) {
        // Rows read through this client are already opened (D-136), so the value is plaintext.
        // A value this process couldn't open (or one already sealed) is left alone.
        if (isSealed(r.value)) continue;
        const value =
          o.mode === "decrypting"
            ? c.json
              ? JSON.stringify(r.value)
              : (r.value as string)
            : c.json
              ? contentKeys.sealJson(o.id, r.value)
              : contentKeys.seal(o.id, r.value as string);
        const where = sql.join(
          c.key.map(
            (k) =>
              sql`${sql.raw(`"${k}"`)} = ${String(r[k])}${sql.raw(k === "seq" || k === "version" ? "::int" : "::uuid")}`,
          ),
          sql` and `,
        );
        await db.execute(
          sql`update ${t} set ${col} = ${value}${c.json ? sql`::jsonb` : sql``} where ${where}`,
        );
        changed++;
      }
      left += rows.length;
    }
    if (left === 0 && o.mode === "encrypting")
      await db.execute(
        sql`update public.organizations set content_encryption = 'on' where id = ${o.id}::uuid and content_encryption = 'encrypting'`,
      );
    if (left === 0 && o.mode === "decrypting") {
      await db.execute(
        sql`update public.organizations set content_encryption = 'off' where id = ${o.id}::uuid and content_encryption = 'decrypting'`,
      );
      await dropKeys(db, "org_keys", o.id);
    }
  }
  return changed + (await sweepUserProfiles(db, batch)) + (await sweepReplacedKeys(db, batch));
}

/** The first table still holding a value sealed with this key (any column, nested too), or null. */
async function keyInUse(db: Database, keyId: string) {
  const [r] = await db.execute<{ t: string | null }>(
    sql`select public.content_key_in_use(${keyId}::uuid) as t`,
  );
  return r?.t ?? null;
}

/**
 * Deletes a workspace's or person's keys once they no longer seal. A key something still needs
 * (device data sealed with a workspace's key, say) is kept, retired, so that data stays readable.
 */
async function dropKeys(db: Database, table: KeyTable, owner: string) {
  const col = sql.raw(table === "org_keys" ? "org_id" : "user_id");
  const t = sql.raw(`public.${table}`);
  const keys = await db.execute<{ id: string }>(
    sql`select id from ${t} where ${col} = ${owner}::uuid`,
  );
  for (const k of keys) {
    if (await keyInUse(db, k.id))
      await db.execute(
        sql`update ${t} set retired_at = coalesce(retired_at, now()) where id = ${k.id}::uuid`,
      );
    else await db.execute(sql`delete from ${t} where id = ${k.id}::uuid`);
  }
}

/** About you text sealed with the person's own key (D-169). */
export const USER_SEALED_COLUMNS = [
  { table: "user_about", column: "about", key: "user_id" },
  { table: "user_about", column: "reply_style", key: "user_id" },
  { table: "user_facts", column: "content", key: "id" },
] as const;

/**
 * About you (D-169): a person's profile text is sealed with their own key while they belong to a
 * workspace that encrypts. This pass makes keys for people who now need one and seals their rows,
 * and for people who no longer do, opens their rows and then drops the key.
 */
export async function sweepUserProfiles(db: Database, batch = 500) {
  if (!contentKeys.configured) return 0;
  const missing = await db.execute<{ user_id: string }>(sql`
    select u.user_id from (
      select user_id from public.user_about where about <> '' or reply_style <> ''
      union select user_id from public.user_facts
    ) u
    where public.user_seals_profile(u.user_id)
      and not exists (select 1 from public.user_keys k where k.user_id = u.user_id and k.retired_at is null)
    limit 100`);
  for (const m of missing) {
    const nk = await contentKeys.newKey();
    await db.execute(sql`
      insert into public.user_keys (user_id, wrapped_key, wrapper) values (${m.user_id}::uuid, ${nk.wrapped}, ${nk.wrapper})
      on conflict (user_id) where retired_at is null do nothing`);
  }
  if (missing.length) await contentKeys.refresh();
  const keyed = await db.execute<{ user_id: string; seal: boolean }>(
    sql`select distinct user_id, public.user_seals_profile(user_id) as seal from public.user_keys`,
  );
  let changed = 0;
  for (const u of keyed) {
    if (u.seal && !contentKeys.sealsUser(u.user_id)) await contentKeys.refresh();
    let left = 0;
    for (const c of USER_SEALED_COLUMNS) {
      const col = sql.raw(`"${c.column}"`);
      const t = sql.raw(`public.${c.table}`);
      const sealed = sql`${col} like 'enc:v1:%'`;
      const rows = await db.execute<{ k: string; value: string }>(sql`
        select ${sql.raw(`"${c.key}"`)} as k, ${col} as value from ${t}
        where user_id = ${u.user_id}::uuid and ${col} <> '' and ${u.seal ? sql`not ${sealed}` : sealed} limit ${batch}`);
      for (const r of rows) {
        // Values read through this client are already opened; one this process can't open stays.
        if (isSealed(r.value)) continue;
        const value = u.seal ? contentKeys.sealForUser(u.user_id, r.value) : r.value;
        await db.execute(
          sql`update ${t} set ${col} = ${value} where ${sql.raw(`"${c.key}"`)} = ${r.k}::uuid`,
        );
        changed++;
      }
      left += rows.length;
    }
    if (!u.seal && left === 0) await dropKeys(db, "user_keys", u.user_id);
  }
  return changed;
}

/**
 * Every column that can hold a value sealed with a workspace key or a person's key, for resealing
 * onto a replacement key (D-238). `owner` narrows the scan to the key's workspace or person.
 */
const RESEAL_COLUMNS: ReadonlyArray<{
  table: string;
  column: string;
  json: boolean;
  kind: "org" | "user";
  owner: "org_id" | "user_id" | null;
}> = [
  ...SEALED_COLUMNS.map((c) => ({
    table: c.table,
    column: c.column,
    json: c.json,
    kind: "org" as const,
    owner: "org_id" as const,
  })),
  // Device data is sealed with a workspace key of its owner's (D-149, D-150) and has no org_id.
  { table: "device_readings", column: "summary", json: true, kind: "org", owner: null },
  { table: "device_requests", column: "result", json: true, kind: "org", owner: null },
  ...USER_SEALED_COLUMNS.map((c) => ({
    table: c.table,
    column: c.column,
    json: false,
    kind: "user" as const,
    owner: "user_id" as const,
  })),
];

/** How long a replaced key is kept after its last row moves, for servers still sealing with it. */
const RETIRED_GRACE = "15 minutes";
/** When each replaced key was last checked against the whole database (that check scans every table). */
const lastInUseCheck = new Map<string, number>();

/**
 * Data key rotation (D-238): moves rows sealed with a replaced key onto the workspace's (or
 * person's) current key, `batch` per column per pass. Rows are opened and sealed again in this
 * process, never in Postgres. Once none are left, the grace period has passed and nothing anywhere
 * in the database still holds a value sealed with it, the old key is deleted.
 */
export async function sweepReplacedKeys(
  db: Database,
  batch = 500,
  opts: { inUseCheckEveryMs?: number } = {},
) {
  if (!contentKeys.configured) return 0;
  const retired = await db.execute<{
    id: string;
    owner: string;
    kind: "org" | "user";
    settled: boolean;
  }>(sql`
    select k.id, k.org_id as owner, 'org' as kind,
           k.retired_at < now() - ${RETIRED_GRACE}::interval as settled
    from public.org_keys k join public.organizations o on o.id = k.org_id
    where k.retired_at is not null and o.content_encryption in ('on', 'encrypting')
      and exists (select 1 from public.org_keys n where n.org_id = k.org_id and n.retired_at is null)
    union all
    select k.id, k.user_id, 'user', k.retired_at < now() - ${RETIRED_GRACE}::interval
    from public.user_keys k
    where k.retired_at is not null
      and exists (select 1 from public.user_keys n where n.user_id = k.user_id and n.retired_at is null)`);
  let changed = 0;
  for (const k of retired) {
    const current = () =>
      k.kind === "org" ? contentKeys.orgKeyId(k.owner) : contentKeys.userKeyId(k.owner);
    let now = current();
    if (!now || now === k.id) {
      await contentKeys.refresh();
      now = current();
      // This process doesn't know the new key yet; try again next pass.
      if (!now || now === k.id) continue;
    }
    const pattern = `enc:v1:${k.id}:%`;
    let left = 0;
    for (const c of RESEAL_COLUMNS) {
      if (c.kind !== k.kind) continue;
      const col = sql.raw(`"${c.column}"`);
      const t = sql.raw(`public.${c.table}`);
      const cond = c.json
        ? sql`jsonb_typeof(${col}) = 'object' and ${col}->>'$enc' like ${pattern}`
        : sql`${col} like ${pattern}`;
      const owner = c.owner ? sql`and ${sql.raw(c.owner)} = ${k.owner}::uuid` : sql``;
      // tableoid and ctid find the row in any table (partitions too); the hash makes sure it hasn't
      // changed since it was read, so a concurrent edit is never overwritten with older content.
      const rows = await db.execute<{ rel: string; tid: string; h: string; value: unknown }>(sql`
        select tableoid::regclass::text as rel, ctid::text as tid, md5(${col}::text) as h, ${col} as value
        from ${t} where ${cond} ${owner} limit ${batch}`);
      for (const r of rows) {
        // Rows read through this client are already opened; one this process couldn't open stays.
        if (isSealed(r.value)) continue;
        const value =
          k.kind === "user"
            ? contentKeys.sealForUser(k.owner, r.value as string)
            : c.json
              ? contentKeys.sealJson(k.owner, JSON.stringify(r.value))
              : contentKeys.seal(k.owner, r.value as string);
        await db.execute(sql`
          update ${t} set ${col} = ${value}${c.json ? sql`::jsonb` : sql``}
          where tableoid = ${r.rel}::regclass and ctid = ${r.tid}::tid and md5(${col}::text) = ${r.h}`);
        changed++;
      }
      left += rows.length;
    }
    if (left > 0 || !k.settled) continue;
    // A key still in use somewhere else is checked again every 15 minutes, not every pass.
    const last = lastInUseCheck.get(k.id);
    if (last && Date.now() - last < (opts.inUseCheckEveryMs ?? 15 * 60_000)) continue;
    if (await keyInUse(db, k.id)) {
      lastInUseCheck.set(k.id, Date.now());
      continue;
    }
    const t = sql.raw(k.kind === "org" ? "public.org_keys" : "public.user_keys");
    await db.execute(sql`delete from ${t} where id = ${k.id}::uuid and retired_at is not null`);
    lastInUseCheck.delete(k.id);
  }
  return changed;
}
