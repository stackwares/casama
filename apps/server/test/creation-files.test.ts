/**
 * The Library keeps files off the computer (D-276): versions, the 50 MB and storage caps, serving
 * the bytes, and the purge removing them.
 */
import { mkdtemp, readdir, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { keepFile, purgeDeletedCreations, StorageFullError } from "@casama/agent";
import { FsObjectStore } from "@casama/sandbox";
import { afterAll, beforeAll, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let dir = "";
let store: FsObjectStore;
let owner: { id: string; token: string };
let orgId = "";
let botId = "";
let computerId = "";
let runId = "";

beforeAll(async () => {
  dir = await mkdtemp(join(tmpdir(), "casama-library-"));
  store = new FsObjectStore(dir);
  h = await startHarness({ objects: store });
  owner = await h.user("files-owner@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Files" } }),
    )
  ).id;
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Writer" },
      }),
    )
  ).id;
  const [c] = await h.tdb.admin<{ id: string }[]>`
    select id from public.computers where org_id = ${orgId} order by created_at limit 1`;
  computerId =
    c?.id ??
    (
      await h.tdb.admin<{ id: string }[]>`
        insert into public.computers (org_id, kind, name) values (${orgId}, 'team', 'Box') returning id`
    )[0]!.id;
  const [r] = await h.tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, created_by) values (${orgId}, ${botId}, ${owner.id}) returning id`;
  runId = r!.id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
  await rm(dir, { recursive: true, force: true });
});

const keep = (path: string, text: string) =>
  keepFile(h.handle.db, store, {
    orgId,
    botId,
    computerId,
    runId,
    conversationId: null,
    madeFor: owner.id,
    path,
    bytes: new TextEncoder().encode(text),
  });

it("keeps a file, makes a new version when it changes, and serves the newest", async () => {
  const first = await keep("reports/q3.md", "# Q3\nfirst draft");
  expect(first).toMatchObject({
    kind: "document",
    version: 1,
    name: "q3.md",
    mime_type: "text/markdown",
  });
  // The same bytes again: nothing new.
  expect((await keep("reports/q3.md", "# Q3\nfirst draft"))?.version).toBe(1);
  const second = await keep("reports/q3.md", "# Q3\nfinal");
  expect(second).toMatchObject({ creation_id: first?.creation_id, version: 2 });
  const res = await h.request(`/v1/creations/${first?.creation_id}/content`, {
    token: owner.token,
  });
  expect(res.status).toBe(200);
  expect(await res.text()).toBe("# Q3\nfinal");
  const list = await j(await h.request(`/v1/creations?org_id=${orgId}`, { token: owner.token }));
  expect(list.items).toHaveLength(1);
  expect(list.items[0]).toMatchObject({ title: "Q3", kind: "document", version: 2 });
});

it("keeps the last five versions only", async () => {
  for (let v = 0; v < 6; v++) await keep("notes.txt", `version ${v}`);
  const [c] = await h.tdb.admin<
    { id: string }[]
  >`select id from public.creations where origin_path = 'notes.txt'`;
  const versions = await h.tdb.admin<{ version: number }[]>`
    select version from public.creation_versions where creation_id = ${c!.id} order by version`;
  expect(versions.map((v) => v.version)).toEqual([2, 3, 4, 5, 6]);
});

it("a full Library keeps nothing new", async () => {
  await h.tdb.admin`insert into public.entitlements (org_id, plan_code, limits)
    values (${orgId}, 'free', ${h.tdb.admin.json({ storage_gb: 0.000001 })})`;
  await expect(keep("big.txt", "x".repeat(5000))).rejects.toBeInstanceOf(StorageFullError);
  await h.tdb.admin`delete from public.entitlements where org_id = ${orgId}`;
});

it("the purge removes a deleted file's bytes", async () => {
  const k = await keep("old/draft.txt", "throw me away");
  await h.request(`/v1/creations/${k?.creation_id}`, { method: "DELETE", token: owner.token });
  await h.tdb
    .admin`update public.creations set deleted_at = now() - interval '31 days' where id = ${k?.creation_id as string}`;
  const before = (await readdir(join(dir, "creations", orgId), { recursive: true })).length;
  expect(await purgeDeletedCreations(h.handle.db, undefined, store)).toBe(1);
  const after = (await readdir(join(dir, "creations", orgId), { recursive: true })).length;
  expect(after).toBeLessThan(before);
  expect(
    await h.tdb.admin`select 1 from public.creations where id = ${k?.creation_id as string}`,
  ).toHaveLength(0);
});

it("a kept document gets a PDF preview and its first page as the cover (D-280)", async () => {
  const { keepDocumentPreview } = await import("@casama/agent");
  const k = await keep("decks/pitch.pptx", "PK fake pptx bytes");
  expect(k).toBeTruthy();
  // A computer whose LibreOffice and pdftoppm answer with a PDF and a 640×360 PNG.
  const png = Buffer.alloc(32);
  png.set([0x89, 0x50, 0x4e, 0x47]);
  png.writeUInt32BE(640, 16);
  png.writeUInt32BE(360, 20);
  const files: Record<string, Uint8Array> = {
    "/tmp/x/pitch.pdf": new TextEncoder().encode("%PDF-1.7 deck"),
    "/tmp/x/cover.png": png,
  };
  const handle = {
    exec: async function* (script: string) {
      expect(script).toContain("/home/casama/workspace/decks/pitch.pptx");
      yield { type: "stdout", data: "/tmp/x/pitch.pdf\n/tmp/x/cover.png\n" };
      yield { type: "exit", code: 0 };
    },
    readFile: async (p: string) => files[p] as Uint8Array,
  };
  expect(await keepDocumentPreview(h.handle.db, store, handle as never, k!)).toBe(true);
  const c = await j(await h.request(`/v1/creations/${k!.creation_id}`, { token: owner.token }));
  expect(c).toMatchObject({ has_preview: true, has_cover: true });
  const pdf = await h.request(`/v1/creations/${k!.creation_id}/preview`, { token: owner.token });
  expect(pdf.headers.get("content-type")).toBe("application/pdf");
  expect(await pdf.text()).toBe("%PDF-1.7 deck");
  const cover = await h.request(`/v1/creations/${k!.creation_id}/cover`, { token: owner.token });
  expect(cover.headers.get("content-type")).toBe("image/png");
  const [row] = await h.tdb.admin<{ cover_w: number; cover_h: number }[]>`
    select cover_w, cover_h from public.creations where id = ${k!.creation_id}`;
  expect(row).toEqual({ cover_w: 640, cover_h: 360 });
});
