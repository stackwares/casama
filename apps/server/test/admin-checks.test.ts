import { createSign, generateKeyPairSync, randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { pinProblem } from "../src/api/admin-security.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

/** D-452: a passkey or the admin PIN, recorded on the sign-in session, instead of a new sign-in. */
describe("admin checks: passkey and PIN", () => {
  let h: Harness;
  let owner: { id: string; email: string; token: string };
  let member: { id: string; email: string; token: string };
  const nowS = () => Math.floor(Date.now() / 1000);
  const old = () => [{ method: "password", timestamp: nowS() - 3600 }];

  /** A token for a sign-in session whose last real sign-in was an hour ago. */
  const staleSession = async (who = owner, extra: Record<string, unknown> = {}) => {
    const session = randomUUID();
    return {
      session,
      token: await h.tokenFor(who, { session_id: session, amr: old(), aal: "aal1", ...extra }),
    };
  };
  const passkeyProof = (who = owner, at = nowS(), session = randomUUID()) =>
    h.tokenFor(who, {
      session_id: session,
      aal: "aal1",
      amr: [{ method: "passkey", timestamp: at }],
    });
  const users = (token: string) => h.request("/v1/admin/users", { token });
  const pinCheck = (token: string, pin: string) =>
    h.request("/v1/admin/checks/pin", { method: "POST", token, json: { pin } });

  beforeAll(async () => {
    h = await startHarness();
    owner = { ...(await h.user("checks-owner@example.com")), email: "checks-owner@example.com" };
    member = { ...(await h.user("checks-member@example.com")), email: "checks-member@example.com" };
  }, 60_000);
  afterAll(async () => h?.stop());

  it("refuses obvious PINs", () => {
    for (const pin of [
      "000000",
      "123456",
      "654321",
      "901234",
      "121212",
      "123123",
      "12345",
      "abcdef",
    ])
      expect(pinProblem(pin), pin).not.toBeNull();
    for (const pin of ["482913", "730316", "112358"]) expect(pinProblem(pin), pin).toBeNull();
  });

  it("a passkey check opens the console and confirms changes on that session only", async () => {
    const s = await staleSession();
    expect((await users(s.token)).status).toBe(403);
    const res = await h.request("/v1/admin/checks/passkey", {
      method: "POST",
      token: s.token,
      json: { token: await passkeyProof() },
    });
    expect(res.status).toBe(200);
    expect(await j(res)).toMatchObject({ verified_at: expect.any(String) });
    expect((await users(s.token)).status).toBe(200);
    // Another sign-in session of the same account isn't checked by it.
    expect((await users((await staleSession()).token)).status).toBe(403);
  });

  it("a passkey is enough on an account with an authenticator", async () => {
    const [factor] = await h.tdb.admin<{ id: string }[]>`
      insert into auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at)
      values (gen_random_uuid(), ${owner.id}::uuid, 'checks', 'totp', 'verified', now(), now())
      returning id`;
    try {
      const s = await staleSession();
      await h.request("/v1/admin/checks/passkey", {
        method: "POST",
        token: s.token,
        json: { token: await passkeyProof() },
      });
      expect((await users(s.token)).status).toBe(200);
      // A passkey sign-in itself (aal1 in Supabase) counts too.
      const passkeySession = await passkeyProof();
      expect((await users(passkeySession)).status).toBe(200);
      // A password alone still owes the code.
      const password = await h.tokenFor(owner, { aal: "aal1", session_id: randomUUID() });
      expect((await users(password)).status).toBe(403);
    } finally {
      await h.tdb.admin`delete from auth.mfa_factors where id = ${factor!.id}::uuid`;
    }
  });

  it("refuses another account's, an old, a forged or a reused passkey proof", async () => {
    const s = await staleSession();
    const check = (token: string, on = s.token) =>
      h.request("/v1/admin/checks/passkey", { method: "POST", token: on, json: { token } });
    const codes = async (r: Response) => [r.status, (await j(r)).code];
    expect(await codes(await check(await passkeyProof(member)))).toEqual([
      403,
      "admin_check_failed",
    ]);
    expect(await codes(await check(await passkeyProof(owner, nowS() - 120)))).toEqual([
      403,
      "admin_check_failed",
    ]);
    // A password sign-in isn't a passkey check.
    const password = await h.tokenFor(owner, { session_id: randomUUID() });
    expect(await codes(await check(password))).toEqual([403, "admin_check_failed"]);
    expect(await codes(await check(`${await passkeyProof()}x`))).toEqual([
      403,
      "admin_check_failed",
    ]);
    expect((await users(s.token)).status).toBe(403);
    // One proof counts for one session.
    const proof = await passkeyProof();
    expect((await check(proof)).status).toBe(200);
    const other = await staleSession();
    expect((await check(proof, other.token)).status).toBe(403);
    expect((await users(other.token)).status).toBe(403);
    // Only the owner records checks.
    const m = await staleSession(member);
    expect((await check(await passkeyProof(member), m.token)).status).toBe(403);
  });

  it("the PIN: set with a fresh sign-in, checks a session, five wrong ones turn it off", async () => {
    const s = await staleSession();
    expect(await j(await h.request("/v1/admin/pin", { token: s.token }))).toEqual({
      set: false,
      disabled: false,
      tries_left: 0,
    });
    expect((await pinCheck(s.token, "482913")).status).toBe(409);
    // Setting it needs a fresh sign-in.
    const put = (token: string, pin: string) =>
      h.request("/v1/admin/pin", { method: "PUT", token, json: { pin } });
    expect((await put(s.token, "482913")).status).toBe(403);
    expect((await put(owner.token, "123456")).status).toBe(400);
    expect(await j(await put(owner.token, "482913"))).toMatchObject({ set: true, tries_left: 5 });
    const stored = await h.tdb.admin<{ pin_hash: string }[]>`
      select pin_hash from public.admin_pins where user_id = ${owner.id}::uuid`;
    expect(stored[0]!.pin_hash).toMatch(/^scrypt\$/);
    expect(stored[0]!.pin_hash).not.toContain("482913");

    expect((await pinCheck(s.token, "482913")).status).toBe(200);
    expect((await users(s.token)).status).toBe(200);
    // The PIN can't change the PIN.
    expect(await j(await put(s.token, "730316"))).toMatchObject({
      code: "admin_pin_needs_sign_in",
    });

    const t = await staleSession();
    for (let left = 4; left >= 1; left--) {
      const r = await pinCheck(t.token, "111111");
      expect(await j(r)).toMatchObject({ code: "admin_pin_wrong" });
    }
    // A right one resets the count.
    expect((await pinCheck(t.token, "482913")).status).toBe(200);
    const u = await staleSession();
    for (let i = 0; i < 4; i++) await pinCheck(u.token, "111111");
    expect(await j(await pinCheck(u.token, "111111"))).toMatchObject({
      code: "admin_pin_disabled",
    });
    expect(await j(await h.request("/v1/admin/pin", { token: u.token }))).toEqual({
      set: false,
      disabled: true,
      tries_left: 0,
    });
    // Turned off: even the right PIN doesn't work until a new one is set.
    expect((await pinCheck(u.token, "482913")).status).toBe(409);
    expect((await users(u.token)).status).toBe(403);
    expect(await j(await put(owner.token, "730316"))).toMatchObject({ set: true, disabled: false });
    const del = await h.request("/v1/admin/pin", { method: "DELETE", token: owner.token });
    expect(await j(del)).toMatchObject({ set: false });
  });

  it("a check approves admin bot actions in the database too", async () => {
    const s = await staleSession();
    await h.request("/v1/admin/checks/passkey", {
      method: "POST",
      token: s.token,
      json: { token: await passkeyProof() },
    });
    const claims = (session: string) =>
      JSON.stringify({ sub: owner.id, role: "authenticated", session_id: session, amr: old() });
    const fresh = async (session: string) => {
      const [row] = await h.tdb.admin<{ ok: boolean }[]>`
        select set_config('request.jwt.claims', ${claims(session)}, true) is not null
           and public.fresh_admin_sign_in() as ok`;
      return row!.ok;
    };
    expect(await fresh(s.session)).toBe(true);
    expect(await fresh(randomUUID())).toBe(false);
  });

  describe("device keys: the screen lock as the whole check (D-453)", () => {
    const device = () => {
      const { publicKey, privateKey } = generateKeyPairSync("ec", { namedCurve: "prime256v1" });
      return {
        spki: publicKey.export({ format: "der", type: "spki" }).toString("base64"),
        sign: (challenge: string) => {
          const s = createSign("SHA256");
          s.update(`casama-admin-check:${challenge}`);
          return s.sign(privateKey).toString("base64");
        },
      };
    };
    const add = (token: string, spki: string, name = "iPhone") =>
      h.request("/v1/admin/devices", { method: "POST", token, json: { name, public_key: spki } });
    const challenge = (token: string, key_id: string) =>
      h.request("/v1/admin/checks/device/challenge", { method: "POST", token, json: { key_id } });
    const check = (token: string, challenge_id: string, signature: string) =>
      h.request("/v1/admin/checks/device", {
        method: "POST",
        token,
        json: { challenge_id, signature },
      });

    it("a signed challenge opens the console on that session, as both steps", async () => {
      const d = device();
      const key = await j(await add(owner.token, d.spki));
      expect(key).toMatchObject({ id: expect.any(String), name: "iPhone", last_used_at: null });
      const [factor] = await h.tdb.admin<{ id: string }[]>`
        insert into auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at)
        values (gen_random_uuid(), ${owner.id}::uuid, 'dev', 'totp', 'verified', now(), now())
        returning id`;
      try {
        const s = await staleSession();
        expect((await users(s.token)).status).toBe(403);
        const c = await j(await challenge(s.token, key.id));
        expect((await check(s.token, c.challenge_id, d.sign(c.challenge))).status).toBe(200);
        expect((await users(s.token)).status).toBe(200);
        // The check also lets the owner add another device (not the PIN's power).
        expect((await add(s.token, device().spki, "iPad")).status).toBe(200);
        // A challenge works once.
        expect((await check(s.token, c.challenge_id, d.sign(c.challenge))).status).toBe(403);
      } finally {
        await h.tdb.admin`delete from auth.mfa_factors where id = ${factor!.id}::uuid`;
      }
    });

    it("refuses another key's signature, another session's challenge and a bad key", async () => {
      const d = device();
      const key = await j(await add(owner.token, d.spki));
      const s = await staleSession();
      const c = await j(await challenge(s.token, key.id));
      expect((await check(s.token, c.challenge_id, device().sign(c.challenge))).status).toBe(403);
      const c2 = await j(await challenge(s.token, key.id));
      const other = await staleSession();
      expect((await check(other.token, c2.challenge_id, d.sign(c2.challenge))).status).toBe(403);
      expect((await users(s.token)).status).toBe(403);
      expect((await users(other.token)).status).toBe(403);
      // Not a P-256 key; adding needs a fresh check; another account's key isn't found.
      expect((await add(owner.token, Buffer.alloc(91, 1).toString("base64"))).status).toBe(400);
      expect((await add(s.token, device().spki)).status).toBe(403);
      const m = await staleSession(member);
      expect((await challenge(m.token, key.id)).status).toBe(403);
    });

    it("a PIN check can't add a device; removing one ends its challenges", async () => {
      await h.request("/v1/admin/pin", {
        method: "PUT",
        token: owner.token,
        json: { pin: "482913" },
      });
      const s = await staleSession();
      expect((await pinCheck(s.token, "482913")).status).toBe(200);
      expect(await j(await add(s.token, device().spki))).toMatchObject({
        code: "admin_pin_needs_sign_in",
      });
      const d = device();
      const key = await j(await add(owner.token, d.spki));
      const list = await j(
        await h.request(`/v1/admin/devices/${key.id}`, { method: "DELETE", token: owner.token }),
      );
      expect(list.items.map((k: { id: string }) => k.id)).not.toContain(key.id);
      expect((await challenge(s.token, key.id)).status).toBe(404);
      await h.request("/v1/admin/pin", { method: "DELETE", token: owner.token });
    });
  });
});
