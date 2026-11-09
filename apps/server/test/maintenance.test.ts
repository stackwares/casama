import { createDb } from "@kasama/db";
import { createAuthUser, startTestDatabase } from "@kasama/db/testing";
import { expect, it } from "vitest";
import { cleanupIdempotencyKeys } from "../src/worker/workflows.ts";

it("deletes idempotency keys older than 24 hours", async () => {
  const tdb = await startTestDatabase();
  const h = createDb(tdb.url, { max: 2 });
  try {
    const u = await createAuthUser(tdb.admin, "m@example.com");
    await tdb.admin`insert into public.idempotency_keys (user_id, key, method, path, status, response, created_at) values
      (${u.id}, 'old', 'POST', '/v1/orgs', 201, '{}', now() - interval '25 hours'),
      (${u.id}, 'new', 'POST', '/v1/orgs', 201, '{}', now())`;
    expect(await cleanupIdempotencyKeys(h.db)).toBe(1);
    const rest = await tdb.admin<{ key: string }[]>`select key from public.idempotency_keys`;
    expect(rest.map((r) => r.key)).toEqual(["new"]);
  } finally {
    await h.close();
    await tdb.stop();
  }
});
