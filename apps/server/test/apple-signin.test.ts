/**
 * Sign in with Apple token revocation (D-420, App Store 5.1.1(v)): the app hands over Apple's code
 * or refresh token, the server keeps a refresh token in Vault, and deleting the account revokes it.
 */
import { generateKeyPairSync } from "node:crypto";
import { sql } from "drizzle-orm";
import { decodeProtectedHeader, importSPKI, jwtVerify } from "jose";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { appleSignInConfig, revokeAppleTokens } from "../src/services/apple-signin.ts";
import { purgeDueAccounts } from "../src/services/privacy.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const { privateKey, publicKey } = generateKeyPairSync("ec", { namedCurve: "P-256" });
const P8 = privateKey.export({ type: "pkcs8", format: "pem" }).toString();
const SPKI = publicKey.export({ type: "spki", format: "pem" }).toString();
const APPLE_ENV = {
  // One line with \n, the way Compose's .env carries it.
  APPLE_SIGNIN_KEY_P8: P8.replace(/\n/g, "\\n"),
  APPLE_SIGNIN_KEY_ID: "KEY1234567",
  APPLE_SIGNIN_TEAM_ID: "TEAM123456",
  APPLE_SIGNIN_URL: "https://apple.test",
};

/** An unsigned id_token: the server only reads `sub` from Apple's own answer. */
const idToken = (sub: string) =>
  `${Buffer.from(JSON.stringify({ alg: "none" })).toString("base64url")}.${Buffer.from(
    JSON.stringify({ iss: "https://appleid.apple.com", sub }),
  ).toString("base64url")}.`;

interface Call {
  path: string;
  form: Record<string, string>;
}

function fakeApple() {
  const calls: Call[] = [];
  const state = {
    sub: "001234.apple-sub.0001",
    codeStatus: 200,
    revokeStatus: 200,
  };
  const f = (async (input: string | URL | Request, init?: RequestInit) => {
    const url = new URL(String(input));
    const form = Object.fromEntries(new URLSearchParams(String(init?.body ?? "")));
    calls.push({ path: url.pathname, form });
    const json = (status: number, body: unknown) =>
      new Response(JSON.stringify(body), {
        status,
        headers: { "content-type": "application/json" },
      });
    if (url.pathname === "/auth/token") {
      if (state.codeStatus !== 200) return json(state.codeStatus, { error: "invalid_grant" });
      if (form.grant_type === "authorization_code")
        return json(200, {
          access_token: "at",
          token_type: "Bearer",
          expires_in: 3600,
          refresh_token: `rt-for-${form.code}`,
          id_token: idToken(state.sub),
        });
      return json(200, {
        access_token: "at",
        token_type: "Bearer",
        expires_in: 3600,
        id_token: idToken(state.sub),
      });
    }
    if (url.pathname === "/auth/revoke") {
      if (state.revokeStatus !== 200) return json(state.revokeStatus, { error: "server_error" });
      return new Response("", { status: 200 });
    }
    return json(404, {});
  }) as typeof fetch;
  return { calls, state, fetch: f };
}

describe("Sign in with Apple revocation (D-420)", () => {
  let h: Harness;
  let off: Harness;
  const apple = fakeApple();

  const addAppleIdentity = (userId: string, sub: string) =>
    h.handle.db.execute(sql`
      insert into auth.identities (user_id, provider, provider_id) values (${userId}::uuid, 'apple', ${sub})`);
  const tokens = (userId: string) =>
    h.handle.db.execute<{ client_id: string; apple_sub: string; token: string | null }>(sql`
      select t.client_id, t.apple_sub, v.decrypted_secret as token
      from public.apple_sign_in_tokens t left join vault.decrypted_secrets v on v.id = t.vault_secret_id
      where t.user_id = ${userId}::uuid order by t.client_id`);
  const secretsNamed = async (token: string) =>
    (
      await h.handle.db.execute<{ n: number }>(
        sql`select count(*)::int as n from vault.secrets where secret = ${token}`,
      )
    )[0]?.n;

  beforeAll(async () => {
    h = await startHarness({
      env: { ...APPLE_ENV, ACCOUNT_DELETION_GRACE_DAYS: "0" },
      appleFetch: apple.fetch,
    });
    off = await startHarness({});
  });
  afterAll(async () => {
    await h?.stop();
    await off?.stop();
  });
  let n = 0;
  beforeEach(() => {
    apple.calls.length = 0;
    // Apple ids are unique across people, so each test signs in as a new one.
    apple.state.sub = `001234.apple-sub.${++n}`;
    apple.state.codeStatus = 200;
    apple.state.revokeStatus = 200;
  });

  it("does nothing on a server without the Sign in with Apple key", async () => {
    const u = await off.user("apple-off@example.com");
    const r = await off.request("/v1/me/apple-sign-in", {
      method: "POST",
      token: u.token,
      json: { authorization_code: "c-off" },
    });
    expect(r.status).toBe(200);
    expect(await j(r)).toEqual({ stored: false });
  });

  it("asks for exactly one of a code or a refresh token", async () => {
    const u = await h.user("apple-both@example.com");
    for (const json of [{}, { authorization_code: "a", refresh_token: "b" }]) {
      const r = await h.request("/v1/me/apple-sign-in", { method: "POST", token: u.token, json });
      expect(r.status).toBe(400);
    }
  });

  it("swaps the sheet's code for a refresh token kept in Vault, with a signed client secret", async () => {
    const u = await h.user("apple-native@example.com");
    await addAppleIdentity(u.id, apple.state.sub);
    const r = await h.request("/v1/me/apple-sign-in", {
      method: "POST",
      token: u.token,
      json: { authorization_code: "code-1" },
    });
    expect(r.status).toBe(200);
    expect(await j(r)).toEqual({ stored: true });

    const call = apple.calls.find((c) => c.path === "/auth/token");
    expect(call?.form).toMatchObject({
      client_id: "ai.casama.app",
      code: "code-1",
      grant_type: "authorization_code",
    });
    const secret = call?.form.client_secret as string;
    expect(decodeProtectedHeader(secret)).toMatchObject({ alg: "ES256", kid: "KEY1234567" });
    const { payload } = await jwtVerify(secret, await importSPKI(SPKI, "ES256"), {
      issuer: "TEAM123456",
      audience: "https://appleid.apple.com",
      subject: "ai.casama.app",
    });
    expect((payload.exp as number) - (payload.iat as number)).toBeLessThanOrEqual(300);

    expect(await tokens(u.id)).toEqual([
      { client_id: "ai.casama.app", apple_sub: apple.state.sub, token: "rt-for-code-1" },
    ]);
    // A newer sign-in replaces the token, and the old one leaves Vault.
    await h.request("/v1/me/apple-sign-in", {
      method: "POST",
      token: u.token,
      json: { authorization_code: "code-2" },
    });
    expect((await tokens(u.id)).map((t) => t.token)).toEqual(["rt-for-code-2"]);
    expect(await secretsNamed("rt-for-code-1")).toBe(0);
  });

  it("checks the browser sign-in's refresh token under the Services ID", async () => {
    const u = await h.user("apple-web@example.com");
    apple.state.sub = "001234.apple-sub.web";
    await addAppleIdentity(u.id, apple.state.sub);
    const r = await h.request("/v1/me/apple-sign-in", {
      method: "POST",
      token: u.token,
      json: { refresh_token: "rt-web" },
    });
    expect(await j(r)).toEqual({ stored: true });
    expect(apple.calls[0]?.form).toMatchObject({
      client_id: "ai.casama.app.signin",
      refresh_token: "rt-web",
      grant_type: "refresh_token",
    });
    expect(await tokens(u.id)).toEqual([
      { client_id: "ai.casama.app.signin", apple_sub: apple.state.sub, token: "rt-web" },
    ]);
  });

  it("refuses another Apple account's token, and a code Apple refuses", async () => {
    const u = await h.user("apple-mismatch@example.com");
    await addAppleIdentity(u.id, "001234.someone-else");
    let r = await h.request("/v1/me/apple-sign-in", {
      method: "POST",
      token: u.token,
      json: { authorization_code: "code-x" },
    });
    expect(r.status).toBe(400);
    expect((await j(r)).code).toBe("apple_identity_mismatch");
    expect(await tokens(u.id)).toEqual([]);

    apple.state.codeStatus = 400;
    r = await h.request("/v1/me/apple-sign-in", {
      method: "POST",
      token: u.token,
      json: { authorization_code: "code-y" },
    });
    expect(r.status).toBe(400);
    expect((await j(r)).code).toBe("apple_token_refused");
  });

  it("deleting the account revokes the token with Apple and forgets it", async () => {
    const u = await h.user("apple-delete@example.com");
    await addAppleIdentity(u.id, apple.state.sub);
    await h.request("/v1/me/apple-sign-in", {
      method: "POST",
      token: u.token,
      json: { authorization_code: "code-del" },
    });
    apple.calls.length = 0;
    const r = await h.request("/v1/me", {
      method: "DELETE",
      token: u.token,
      json: { confirm_email: "apple-delete@example.com" },
    });
    expect(r.status).toBe(200);
    const revoke = apple.calls.find((c) => c.path === "/auth/revoke");
    expect(revoke?.form).toMatchObject({
      client_id: "ai.casama.app",
      token: "rt-for-code-del",
      token_type_hint: "refresh_token",
    });
    expect(revoke?.form.client_secret).toBeTruthy();
    expect(await tokens(u.id)).toEqual([]);
    expect(await secretsNamed("rt-for-code-del")).toBe(0);
  });

  it("a failed revoke never blocks the deletion; the purge tries again and drops it either way", async () => {
    const u = await h.user("apple-down@example.com");
    await addAppleIdentity(u.id, apple.state.sub);
    await h.request("/v1/me/apple-sign-in", {
      method: "POST",
      token: u.token,
      json: { authorization_code: "code-down" },
    });
    apple.state.revokeStatus = 503;
    const r = await h.request("/v1/me", {
      method: "DELETE",
      token: u.token,
      json: { confirm_email: "apple-down@example.com" },
    });
    expect(r.status).toBe(200);
    expect((await tokens(u.id)).map((t) => t.token)).toEqual(["rt-for-code-down"]);

    // Apple is still down at the purge: the account and its token go anyway.
    apple.calls.length = 0;
    await h.handle.db.execute(
      sql`update public.account_deletions set purge_after = now() - interval '1 minute' where user_id = ${u.id}::uuid`,
    );
    await purgeDueAccounts(h.handle.db, undefined, {
      erase: async () => {},
      forgetNewsletter: async () => true,
      apple: appleSignInConfig(APPLE_ENV, apple.fetch),
    });
    expect(apple.calls.filter((c) => c.path === "/auth/revoke")).toHaveLength(1);
    expect(await tokens(u.id)).toEqual([]);
    expect(await secretsNamed("rt-for-code-down")).toBe(0);
    const [gone] = await h.handle.db.execute<{ n: number }>(
      sql`select count(*)::int as n from auth.users where id = ${u.id}::uuid`,
    );
    expect(gone?.n).toBe(0);
  });

  it("an already revoked token (invalid_grant) counts as revoked", async () => {
    const u = await h.user("apple-gone@example.com");
    await addAppleIdentity(u.id, apple.state.sub);
    await h.request("/v1/me/apple-sign-in", {
      method: "POST",
      token: u.token,
      json: { authorization_code: "code-gone" },
    });
    const cfg = appleSignInConfig(
      APPLE_ENV,
      (async () =>
        new Response(JSON.stringify({ error: "invalid_grant" }), { status: 400 })) as typeof fetch,
    );
    expect(await revokeAppleTokens(h.handle.db, cfg, u.id)).toBe(0);
    expect(await tokens(u.id)).toEqual([]);
  });
});
