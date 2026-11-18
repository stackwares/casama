import { eq, sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { createDb, type DbHandle, pgErrorCode, schema, withUserSession } from "../src/index.ts";
import { createAuthUser, startTestDatabase, type TestDatabase } from "../src/testing.ts";

let tdb: TestDatabase;
let h: DbHandle;
let alice: { id: string; email: string };
let bob: { id: string; email: string };
const claims = (u: { id: string; email: string }) => ({ sub: u.id, email: u.email });

beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 4 });
  alice = await createAuthUser(tdb.admin, "alice@example.com");
  bob = await createAuthUser(tdb.admin, "bob@example.com");
});
afterAll(async () => {
  await h?.close();
  await tdb?.stop();
});

describe("withUserSession", () => {
  it("runs as authenticated with the caller's uid", async () => {
    const [row] = await withUserSession(h.db, claims(alice), (tx) =>
      tx.execute<{ uid: string; role: string }>(
        sql`select auth.uid() as uid, current_user as role`,
      ),
    );
    expect(row).toEqual({ uid: alice.id, role: "authenticated" });
  });

  it("isolates organizations between users", async () => {
    await withUserSession(h.db, claims(alice), (tx) =>
      tx.execute(sql`select public.create_organization('A', 'a-org')`),
    );
    await withUserSession(h.db, claims(bob), (tx) =>
      tx.execute(sql`select public.create_organization('B', 'b-org')`),
    );

    const aliceOrgs = await withUserSession(h.db, claims(alice), (tx) =>
      tx.select().from(schema.organizations),
    );
    expect(aliceOrgs.map((o) => o.slug)).toEqual(["a-org"]);

    const bobSeesA = await withUserSession(h.db, claims(bob), (tx) =>
      tx.select().from(schema.organizations).where(eq(schema.organizations.slug, "a-org")),
    );
    expect(bobSeesA).toHaveLength(0);
  });

  it("rejects direct inserts that skip create_organization", async () => {
    const err = await withUserSession(h.db, claims(alice), (tx) =>
      tx.insert(schema.organizations).values({ name: "X", slug: "x-org" }),
    ).catch((e) => e);
    expect(pgErrorCode(err)).toBe("42501");
  });

  it("does not leak settings across transactions on the same connection", async () => {
    await withUserSession(h.db, claims(alice), async () => {});
    const [row] = await h.db.execute<{ role: string }>(sql`select current_user as role`);
    expect(row?.role).toBe("postgres");
  });
});
