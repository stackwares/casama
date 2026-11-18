/**
 * Where generated media's bytes live (D-290): the object store when the server has one, Postgres
 * otherwise (and for rows not moved yet). Every reader goes through readMedia, so both work.
 */
import type { Database } from "@casama/db";
import type { ObjectStore } from "@casama/sandbox";
import { sql } from "drizzle-orm";

export const mediaKey = (orgId: string, id: string) => `media/${orgId}/${id}`;

/** A media file's bytes, or the asked-for byte range of them; null when it's gone. */
export async function readMedia(
  db: Database,
  store: ObjectStore | null | undefined,
  id: string,
  range?: { start: number; end: number },
): Promise<Uint8Array | null> {
  const [m] = await db.execute<{ blob_key: string | null; size: number }>(sql`
    select blob_key, size from public.chat_media where id = ${id}::uuid`);
  if (!m) return null;
  if (m.blob_key) {
    if (!store) return null;
    const { readObject } = await import("@casama/sandbox");
    const all = await readObject(store, m.blob_key).catch(() => null);
    if (!all) return null;
    return range ? all.subarray(range.start, range.end + 1) : all;
  }
  if (range) {
    // substring() on bytea is 1-based; only the slice leaves the database.
    const [s] = await db.execute<{ part: Buffer }>(sql`
      select substring(bytes from ${range.start + 1}::int for ${range.end - range.start + 1}::int) as part
      from public.chat_media where id = ${id}::uuid`);
    return s ? new Uint8Array(s.part) : null;
  }
  const [r] = await db.execute<{ bytes: Buffer }>(
    sql`select bytes from public.chat_media where id = ${id}::uuid`,
  );
  return r?.bytes ? new Uint8Array(r.bytes) : null;
}

/** Moves up to `batch` older media files from Postgres to the store. Returns how many moved. */
export async function moveMediaToStore(db: Database, store: ObjectStore, batch = 50) {
  const rows = await db.execute<{ id: string; org_id: string; bytes: Buffer }>(sql`
    select id, org_id, bytes from public.chat_media where blob_key is null and bytes is not null
    order by created_at limit ${batch}`);
  for (const r of rows) {
    const key = mediaKey(r.org_id, r.id);
    await store.put(key, new Uint8Array(r.bytes));
    await db.execute(sql`
      update public.chat_media set blob_key = ${key}, bytes = null where id = ${r.id}::uuid and blob_key is null`);
  }
  return rows.length;
}

/** Deletes bytes whose rows are gone (queued by database triggers). Returns how many. */
export async function deleteQueuedBlobs(db: Database, store: ObjectStore, batch = 500) {
  const rows = await db.execute<{ key: string }>(sql`
    select key from public.deleted_blobs order by deleted_at limit ${batch}`);
  for (const r of rows) {
    // Still in use somewhere (a version that became current again, a shared key): keep it.
    const [used] = await db.execute<{ n: number }>(sql`
      select (
        (select count(*) from public.chat_media where blob_key = ${r.key}) +
        (select count(*) from public.creations where ${r.key} in (blob_key, preview_key, cover_key)) +
        (select count(*) from public.creation_versions where blob_key = ${r.key}) +
        (select count(*) from public.page_assets where blob_key = ${r.key}))::int as n`);
    if (!used?.n) await store.delete(r.key).catch(() => {});
    await db.execute(sql`delete from public.deleted_blobs where key = ${r.key}`);
  }
  return rows.length;
}
