/** Generated media out of Postgres (D-290): moved, read from either place, deleted with its row. */
import { mkdtemp, readdir, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createDb, type DbHandle } from "@casama/db";
import { startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { FsObjectStore } from "@casama/sandbox";
import { afterAll, beforeAll, expect, it } from "vitest";
import { deleteQueuedBlobs, moveMediaToStore, readMedia } from "../src/media-store.ts";

let tdb: TestDatabase;
let h: DbHandle;
let dir = "";
let store: FsObjectStore;
beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 2 });
  dir = await mkdtemp(join(tmpdir(), "casama-media-"));
  store = new FsObjectStore(dir);
});
afterAll(async () => {
  await h?.close();
  await tdb?.stop();
  await rm(dir, { recursive: true, force: true });
});

it("moves old media to the store, reads it (and ranges) from either place, and deletes it with its row", async () => {
  const [org] = await tdb.admin<
    { id: string }[]
  >`insert into public.organizations (name, slug) values ('M', 'media-store') returning id`;
  const [m] = await tdb.admin<{ id: string }[]>`
    insert into public.chat_media (org_id, name, content_type, bytes, size)
    values (${org!.id}, 'pic.png', 'image/png', ${Buffer.from("0123456789")}, 10) returning id`;
  expect(new TextDecoder().decode((await readMedia(h.db, store, m!.id))!)).toBe("0123456789");
  expect(
    new TextDecoder().decode((await readMedia(h.db, store, m!.id, { start: 2, end: 4 }))!),
  ).toBe("234");
  expect(await moveMediaToStore(h.db, store)).toBe(1);
  const [row] = await tdb.admin<
    { bytes: Buffer | null; blob_key: string }[]
  >`select bytes, blob_key from public.chat_media where id = ${m!.id}`;
  expect(row!.bytes).toBeNull();
  expect(row!.blob_key).toBe(`media/${org!.id}/${m!.id}`);
  expect(
    new TextDecoder().decode((await readMedia(h.db, store, m!.id, { start: 7, end: 9 }))!),
  ).toBe("789");
  // The creation the trigger made goes with it; both keys are queued, the bytes deleted once.
  await tdb.admin`delete from public.chat_media where id = ${m!.id}`;
  expect(await deleteQueuedBlobs(h.db, store)).toBeGreaterThan(0);
  expect(await readdir(join(dir, "media", org!.id)).catch(() => [])).toEqual([]);
  expect(await readMedia(h.db, store, m!.id)).toBeNull();
});
