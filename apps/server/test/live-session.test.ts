/**
 * Credentials minted only from a sign-in session that still stands (D-474): after Sign Out
 * Everywhere deletes the sessions, a token that hasn't expired yet can't make sign-in codes,
 * watch keys or widget keys.
 */
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { hashWatchKey } from "../src/api/routes/watch.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let me: { id: string; email: string; token: string };
let orgId = "";

beforeAll(async () => {
  h = await startHarness();
  me = await h.user("live-session@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: me.token, json: { name: "Home" } }),
    )
  ).id;
  h.deps.authAdmin = {
    url: "http://auth.internal/auth/v1",
    serviceRoleKey: "service-key",
    fetch: async () =>
      Response.json({
        action_link: "http://auth.internal/verify?token=x",
        hashed_token: "hash",
        verification_type: "magiclink",
      }),
  };
}, 600_000);
afterAll(() => h?.stop());

const mint = (token: string) => ({
  signIn: () => h.request("/v1/auth/pairing-codes", { method: "POST", token }),
  widget: () =>
    h.request("/v1/widget-keys", {
      method: "POST",
      token,
      json: { org_id: orgId, platform: "ios" },
    }),
  watch: () =>
    h.request("/v1/watch-keys", {
      method: "POST",
      token,
      json: {
        org_id: orgId,
        fingerprint: hashWatchKey(`ckw_${randomUUID()}`),
        platform: "watchos",
        name: "Wrist",
      },
    }),
});

describe("minting from a revoked session", () => {
  it("works while the session stands, and is refused once it's gone", async () => {
    const session = randomUUID();
    await h.tdb.admin`insert into auth.sessions (id, user_id) values (${session}, ${me.id})`;
    const token = await h.tokenFor(me, { session_id: session });
    const live = mint(token);
    expect((await live.signIn()).status).toBe(201);
    expect((await live.widget()).status).toBe(201);
    expect((await live.watch()).status).toBe(201);
    // Sign Out Everywhere: the sessions go, the access token lives on until it expires.
    await h.tdb.admin`delete from auth.sessions where user_id = ${me.id}`;
    for (const res of [await live.signIn(), await live.widget(), await live.watch()]) {
      expect(res.status).toBe(401);
      expect((await j(res)).code).toBe("session_ended");
    }
  });

  it("refuses a session that ran out", async () => {
    const session = randomUUID();
    await h.tdb.admin`
      insert into auth.sessions (id, user_id, not_after)
      values (${session}, ${me.id}, now() - interval '1 minute')`;
    const res = await mint(await h.tokenFor(me, { session_id: session })).widget();
    expect(res.status).toBe(401);
  });
});
