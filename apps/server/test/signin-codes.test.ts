import { sql } from "drizzle-orm";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { reachableFromOutside } from "../src/api/routes/signin-codes.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

/**
 * Scan to sign in (D-296): a signed-in app shows a one-time code as a QR; the phone that scans it
 * trades the code for a one-time sign-in token from Auth. Auth's admin API is a stub that records
 * what it was asked.
 */
describe("scan to sign in", () => {
  let h: Harness;
  let user: { id: string; email: string; token: string };
  let other: { id: string; email: string; token: string };
  let auth: {
    calls: Array<{ url: string; headers: Headers; body: Record<string, unknown> }>;
    up: boolean;
  };

  const create = (token?: string) => h.request("/v1/auth/pairing-codes", { method: "POST", token });
  const redeem = (code: string, device_name?: string) =>
    h.request("/v1/auth/pairing-codes/redeem", { method: "POST", json: { code, device_name } });
  /** Past the per-minute limit, which counts by when a code was made. */
  const age = () =>
    h.handle.db.execute(
      sql`update public.signin_codes set created_at = created_at - interval '2 minutes'`,
    );

  beforeAll(async () => {
    h = await startHarness({ env: { PUBLIC_API_URL: "https://k7qm2xfd9abc.link.test" } });
    user = await h.user("scanner@example.com");
    other = await h.user("someone-else@example.com");
  }, 60_000);
  afterAll(() => h?.stop());
  beforeEach(async () => {
    auth = { calls: [], up: true };
    h.deps.authAdmin = {
      url: "http://auth.internal/auth/v1",
      serviceRoleKey: "service-key",
      fetch: async (input, init) => {
        auth.calls.push({
          url: String(input),
          headers: new Headers(init?.headers),
          body: JSON.parse(String(init?.body ?? "{}")),
        });
        if (!auth.up) return Response.json({ msg: "down" }, { status: 500 });
        return Response.json({
          action_link: "http://auth.internal/verify?token=x",
          hashed_token: `hash-${auth.calls.length}`,
          verification_type: "magiclink",
        });
      },
    };
    await age();
  });

  it("a server without Auth's service key has no codes, and says so", async () => {
    h.deps.authAdmin = undefined;
    expect((await j(await h.request("/v1/config"))).sign_in_codes).toBe(false);
    const res = await create(user.token);
    expect(res.status).toBe(409);
    expect((await j(res)).code).toBe("sign_in_codes_unavailable");
  });

  it("makes a code only for someone signed in", async () => {
    expect((await create()).status).toBe(401);
    expect((await j(await h.request("/v1/config"))).sign_in_codes).toBe(true);
    const res = await create(user.token);
    expect(res.status).toBe(201);
    const made = await j(res);
    expect(made.code).toMatch(/^ksc_[A-Za-z0-9_-]{43}$/);
    const left = Date.parse(made.expires_at) - Date.now();
    expect(left).toBeGreaterThan(4 * 60_000);
    expect(left).toBeLessThanOrEqual(5 * 60_000);
    expect(made.server_url).toBe("https://k7qm2xfd9abc.link.test");
    expect(made.reachable).toBe(true);
    // The QR holds a link that opens the app; the code rides after "#", so no web server sees it.
    const link = new URL(made.pair_url);
    expect(`${link.origin}${link.pathname}`).toBe("https://casama.ai/pair");
    expect(link.search).toBe("");
    const carried = new URLSearchParams(link.hash.slice(1));
    expect(carried.get("s")).toBe(made.server_url);
    expect(carried.get("c")).toBe(made.code);
    // Only its hash is kept.
    const rows = await h.handle.db.execute<{ code_hash: string }>(
      sql`select code_hash from public.signin_codes where user_id = ${user.id}::uuid`,
    );
    expect(rows.some((r) => r.code_hash === made.code)).toBe(false);
  });

  it("an instance owner needs a fresh sign-in to make one; others don't (admin security)", async () => {
    const stale = (u: { id: string; email: string }) =>
      h.tokenFor(u, {
        amr: [{ method: "password", timestamp: Math.floor(Date.now() / 1000) - 600 }],
      });
    // The first account is this server's owner.
    const owner = await create(await stale({ id: user.id, email: "scanner@example.com" }));
    expect(owner.status).toBe(403);
    expect((await j(owner)).code).toBe("admin_confirmation_required");
    const someone = await create(await stale({ id: other.id, email: "someone-else@example.com" }));
    expect(someone.status).toBe(201);
  });

  it("the phone trades the code for a sign-in token, once", async () => {
    const made = await j(await create(user.token));
    const res = await redeem(made.code, "Pixel 9");
    expect(res.status).toBe(200);
    expect(await j(res)).toEqual({ token_hash: "hash-1", email: user.email });
    // Auth was asked for a one-time link for that account, with the server's own key.
    expect(auth.calls).toHaveLength(1);
    expect(auth.calls[0]?.url).toBe("http://auth.internal/auth/v1/admin/generate_link");
    expect(auth.calls[0]?.body).toEqual({ type: "magiclink", email: user.email });
    expect(auth.calls[0]?.headers.get("authorization")).toBe("Bearer service-key");
    expect(auth.calls[0]?.headers.get("apikey")).toBe("service-key");

    // The account is told a new device signed in.
    const [note] = await h.handle.db.execute<{ kind: string; payload: { body: string } }>(sql`
      select kind, payload from public.notifications where user_id = ${user.id}::uuid
      order by created_at desc limit 1`);
    expect(note?.kind).toBe("sign_in");
    expect(note?.payload.body).toContain("Pixel 9");

    const again = await redeem(made.code, "Pixel 9");
    expect(again.status).toBe(404);
    expect((await j(again)).code).toBe("code_not_valid");
    expect(auth.calls).toHaveLength(1);
  });

  it("refuses a code that is wrong, expired, or replaced by a newer one", async () => {
    expect((await redeem("ksc_this-code-was-never-made-0123456789abcdefghij")).status).toBe(404);
    expect((await redeem("short")).status).toBe(400);

    const stale = await j(await create(user.token));
    await h.handle.db.execute(sql`
      update public.signin_codes set expires_at = now() - interval '1 second'
      where user_id = ${user.id}::uuid and used_at is null`);
    expect((await redeem(stale.code)).status).toBe(404);

    // Showing a new QR ends the one before it.
    await age();
    const first = await j(await create(user.token));
    const second = await j(await create(user.token));
    expect((await redeem(first.code)).status).toBe(404);
    expect((await redeem(second.code)).status).toBe(200);
    expect(auth.calls).toHaveLength(1);
  });

  it("one person's code signs in that person only", async () => {
    const mine = await j(await create(user.token));
    const theirs = await j(await create(other.token));
    expect((await j(await redeem(theirs.code))).email).toBe(other.email);
    expect((await j(await redeem(mine.code))).email).toBe(user.email);
  });

  it("limits how fast codes are made", async () => {
    for (let i = 0; i < 5; i++) expect((await create(user.token)).status).toBe(201);
    const sixth = await create(user.token);
    expect(sixth.status).toBe(429);
    expect(sixth.headers.get("retry-after")).toBe("60");
    // Someone else isn't held up by it.
    expect((await create(other.token)).status).toBe(201);
  });

  it("when Auth can't be reached the phone is told to try again, and the code is spent", async () => {
    const made = await j(await create(user.token));
    auth.up = false;
    const res = await redeem(made.code);
    expect(res.status).toBe(503);
    expect((await j(res)).code).toBe("auth_unavailable");
    auth.up = true;
    expect((await redeem(made.code)).status).toBe(404);
  });

  it("knows which addresses a phone elsewhere can reach", () => {
    expect(reachableFromOutside("https://k7qm2xfd9abc.link.test")).toBe(true);
    expect(reachableFromOutside("https://api.casama.ai")).toBe(true);
    for (const local of [
      "http://localhost:8080",
      "https://localhost",
      "http://casama.example.com",
      "https://127.0.0.1:8443",
      "https://192.168.1.20",
      "https://10.0.0.4",
      "https://172.20.1.1",
      "https://mac-mini.local",
      "https://[::1]:8443",
      "not a url",
    ])
      expect(reachableFromOutside(local), local).toBe(false);
  });
});
