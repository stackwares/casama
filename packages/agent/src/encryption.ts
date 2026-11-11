/**
 * Encryption at rest (D-136): turning it on and off for a workspace, key rotation, and the sweep that
 * seals existing rows (and any row a write path missed) or opens them again when it's turned off.
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
] as const;

export type EncryptionMode = "off" | "encrypting" | "on" | "decrypting";

export async function encryptionStatus(db: Database, orgId: string) {
  const [o] = await db.execute<{
    mode: EncryptionMode;
    wrapper: string | null;
    rotated_at: string | null;
    created_at: string | null;
  }>(sql`
    select o.content_encryption as mode, k.wrapper, k.rotated_at, k.created_at
    from public.organizations o left join public.org_keys k on k.org_id = o.id where o.id = ${orgId}::uuid`);
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
  };
}

/** Turns encryption on (a new data key, then the sweep seals existing rows) or off (the sweep opens them). */
export async function setEncryption(db: Database, orgId: string, enabled: boolean) {
  if (enabled) {
    if (!contentKeys.configured) throw new Error("not_configured");
    const [k] = await db.execute<{ id: string }>(
      sql`select id from public.org_keys where org_id = ${orgId}::uuid`,
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

/** Rewraps the workspace's data key with the server's current key; rows are not rewritten. */
export async function rotateEncryptionKey(db: Database, orgId: string) {
  const [k] = await db.execute<{ id: string; wrapped_key: string; wrapper: string }>(sql`
    select id, wrapped_key, wrapper from public.org_keys where org_id = ${orgId}::uuid`);
  if (!k) throw new Error("no_key");
  const r = await contentKeys.rewrap(k.wrapped_key, k.wrapper);
  await db.execute(
    sql`update public.org_keys set wrapped_key = ${r.wrapped}, wrapper = ${r.wrapper}, rotated_at = now() where id = ${k.id}::uuid`,
  );
  return encryptionStatus(db, orgId);
}

/** Rewraps every workspace key still wrapped by an older server key (run after changing keys). */
export async function rewrapAllKeys(db: Database) {
  const id = contentKeys.wrapperId;
  if (!id) return 0;
  const old = await db.execute<{ org_id: string }>(
    sql`select org_id from public.org_keys where wrapper <> ${id}`,
  );
  for (const k of old) await rotateEncryptionKey(db, k.org_id);
  return old.length;
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
      await db.execute(sql`delete from public.org_keys where org_id = ${o.id}::uuid`);
    }
  }
  return changed + (await sweepUserProfiles(db, batch));
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
      and not exists (select 1 from public.user_keys k where k.user_id = u.user_id)
    limit 100`);
  for (const m of missing) {
    const nk = await contentKeys.newKey();
    await db.execute(sql`
      insert into public.user_keys (user_id, wrapped_key, wrapper) values (${m.user_id}::uuid, ${nk.wrapped}, ${nk.wrapper})
      on conflict (user_id) do nothing`);
  }
  if (missing.length) await contentKeys.refresh();
  const keyed = await db.execute<{ user_id: string; seal: boolean }>(
    sql`select user_id, public.user_seals_profile(user_id) as seal from public.user_keys`,
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
    if (!u.seal && left === 0)
      await db.execute(sql`delete from public.user_keys where user_id = ${u.user_id}::uuid`);
  }
  return changed;
}
