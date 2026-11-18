/** Casama Cloud abuse controls (D-094): sign-up gate, egress abuse reports, suspension. */
import { createHash, randomUUID } from "node:crypto";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { ComputerService } from "@casama/agent";
import { unavailableProvider } from "@casama/sandbox";
import { exportJWK, generateKeyPair, SignJWT } from "jose";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { internalToken } from "../src/api/routes/local.ts";
import { standardWebhookSignature } from "../src/billing/dodo.ts";
import { leadingZeroBits } from "../src/services/abuse.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const HOOK_SECRET = `whsec_${Buffer.from("hook-secret-0123456789abcdef").toString("base64")}`;
let h: Harness;
let jwks: Server;
let jwksBase: string;
let signAppCheck: (aud: string) => Promise<string>;
let owner: { id: string; email: string; token: string };
let stranger: { id: string; email: string; token: string };
let orgId: string;

function hook(payload: unknown, sign = true) {
  const body = JSON.stringify(payload);
  const id = `msg_${randomUUID()}`;
  const ts = String(Math.floor(Date.now() / 1000));
  const headers: Record<string, string> = { "content-type": "application/json" };
  if (sign) {
    headers["webhook-id"] = id;
    headers["webhook-timestamp"] = ts;
    headers["webhook-signature"] = `v1,${standardWebhookSignature(HOOK_SECRET, id, ts, body)}`;
  }
  return h.request("/hooks/auth/before-user-created", { method: "POST", headers, body });
}

const emailUser = (proof?: unknown) => ({
  user: {
    email: `new-${randomUUID()}@example.com`,
    app_metadata: { provider: "email" },
    user_metadata: proof ? { signup_proof: proof } : {},
  },
});

function solve(challenge: string, difficulty: number) {
  for (let n = 0; ; n++) {
    const digest = createHash("sha256").update(`${challenge}:${n}`).digest();
    if (leadingZeroBits(digest) >= difficulty) return String(n);
  }
}

beforeAll(async () => {
  const { privateKey, publicKey } = await generateKeyPair("RS256");
  const jwk = { ...(await exportJWK(publicKey)), kid: "ac1", alg: "RS256", use: "sig" };
  jwks = createServer((_req, res) => res.end(JSON.stringify({ keys: [jwk] }))).listen(
    0,
    "127.0.0.1",
  );
  await new Promise((r) => jwks.once("listening", r));
  jwksBase = `http://127.0.0.1:${(jwks.address() as AddressInfo).port}`;
  signAppCheck = (aud) =>
    new SignJWT({})
      .setProtectedHeader({ alg: "RS256", kid: "ac1" })
      .setIssuer(`${jwksBase}/123456`)
      .setAudience([aud])
      .setSubject("1:123456:ios:abc")
      .setIssuedAt()
      .setExpirationTime("1h")
      .sign(privateKey);
  h = await startHarness({
    env: {
      ABUSE_CONTROLS: "on",
      AUTH_HOOK_SECRET: `v1,${HOOK_SECRET}`,
      SIGNUP_POW_DIFFICULTY: "8",
      APP_CHECK_PROJECT_NUMBER: "123456",
      APP_CHECK_JWKS_URL: `${jwksBase}/jwks`,
      APP_CHECK_ISSUER_BASE: jwksBase,
    },
  });
  owner = await h.user("abuse-owner@example.com"); // first user: the instance owner
  stranger = await h.user("abuse-stranger@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", {
        method: "POST",
        token: stranger.token,
        json: { name: "Busy" },
      }),
    )
  ).id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
  jwks?.close();
});

describe("sign-up gate", () => {
  it("advertises the proofs it accepts", async () => {
    const cfg = await j(await h.request("/v1/config"));
    expect(cfg.signup_proofs).toEqual(["app_check", "pow"]);
  });

  it("rejects unsigned hook calls and sign-ups without a proof", async () => {
    expect((await hook(emailUser(), false)).status).toBe(401);
    const res = await hook(emailUser());
    expect(res.status).toBe(403);
    expect((await j(res)).error.http_code).toBe(403);
    const [ev] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.abuse_events where kind = 'signup_blocked'`;
    expect(ev?.n).toBeGreaterThan(0);
  });

  it("lets Google, Apple and SSO sign-ups through", async () => {
    expect((await hook({ user: { app_metadata: { provider: "google" } } })).status).toBe(200);
  });

  it("accepts a solved puzzle once", async () => {
    const ch = await j(await h.request("/v1/signup/challenge"));
    expect(ch.difficulty).toBe(8);
    const nonce = solve(ch.challenge, ch.difficulty);
    const proof = { kind: "pow", challenge: ch.challenge, nonce };
    expect((await hook(emailUser(proof))).status).toBe(200);
    expect((await hook(emailUser(proof))).status).toBe(403);
    const bad = await j(await h.request("/v1/signup/challenge"));
    expect(
      (await hook(emailUser({ kind: "pow", challenge: bad.challenge, nonce: "x" }))).status,
    ).toBe(403);
    const forged = `${ch.challenge.slice(0, -3)}abc`;
    expect((await hook(emailUser({ kind: "pow", challenge: forged, nonce }))).status).toBe(403);
  });

  it("accepts a valid App Check token for this project only", async () => {
    const good = await signAppCheck("projects/123456");
    expect((await hook(emailUser({ kind: "app_check", token: good }))).status).toBe(200);
    const other = await signAppCheck("projects/999");
    expect((await hook(emailUser({ kind: "app_check", token: other }))).status).toBe(403);
  });
});

describe("egress abuse and suspension", () => {
  let computerId: string;
  const report = (kind: string) =>
    h.request("/internal/abuse", {
      method: "POST",
      headers: { "x-casama-internal": internalToken(h.deps.env) },
      json: { computer: computerId, kind, target: "pool.example:3333" },
    });

  it("records blocked ports without suspending", async () => {
    const [c] = await h.tdb.admin<{ id: string }[]>`
      select id from public.computers where org_id = ${orgId} and kind = 'team'`;
    computerId = c!.id;
    expect((await h.request("/internal/abuse", { method: "POST", json: {} })).status).toBe(401);
    const res = await j(await report("blocked_port"));
    expect(res.action).toBe("recorded");
    const orgs = await j(await h.request("/v1/orgs", { token: stranger.token }));
    expect(orgs.items[0].suspended).toBe(false);
  });

  it("suspends the workspace on mining, and suspended workspaces don't chat", async () => {
    const res = await j(await report("mining_pool"));
    expect(res.action).toBe("workspace_suspended");
    const orgs = await j(await h.request("/v1/orgs", { token: stranger.token }));
    expect(orgs.items[0].suspended).toBe(true);
    const cred = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: stranger.token,
        json: {
          org_id: orgId,
          provider: "openrouter",
          label: "k",
          api_key: "sk-or-v1-abcdefabcdef",
        },
      }),
    );
    const bot = await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: stranger.token,
        json: {
          org_id: orgId,
          name: "B",
          model_policy: { primary: { credential_id: cred.id, model: "m" } },
        },
      }),
    );
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: stranger.token,
        json: { bot_id: bot.id },
      }),
    );
    const sent = await h.request(`/v1/conversations/${conv.id}/messages`, {
      method: "POST",
      token: stranger.token,
      json: { text: "hi" },
    });
    expect(sent.status).toBe(403);
    expect((await j(sent)).code).toBe("workspace_suspended");
  });

  it("lets the instance owner see abuse, lift and reapply a suspension", async () => {
    expect((await h.request("/v1/admin/abuse", { token: stranger.token })).status).toBe(403);
    const events = await j(await h.request("/v1/admin/abuse", { token: owner.token }));
    expect(events.items.map((e: { kind: string }) => e.kind)).toContain("mining_pool");
    const lifted = await j(
      await h.request(`/v1/admin/orgs/${orgId}/suspend`, { method: "DELETE", token: owner.token }),
    );
    expect(lifted.suspended_at).toBeNull();
    const again = await j(
      await h.request(`/v1/admin/orgs/${orgId}/suspend`, {
        method: "POST",
        token: owner.token,
        json: { reason: "Spam reports" },
      }),
    );
    expect(again.suspended_reason).toBe("Spam reports");
    await h.request(`/v1/admin/orgs/${orgId}/suspend`, { method: "DELETE", token: owner.token });
  });
});

describe("computers", () => {
  it("need a verified owner email on free workspaces, and never start when suspended", async () => {
    const computers = new ComputerService(h.handle.db, unavailableProvider());
    computers.requireVerifiedEmail = true;
    await h.tdb.admin`update public.entitlements set plan_code = 'free' where org_id = ${orgId}`;
    await h.tdb.admin`update auth.users set email_confirmed_at = null where id = ${stranger.id}`;
    await expect(computers.checkCanStart(orgId)).rejects.toThrow("email_unverified");
    await h.tdb.admin`update auth.users set email_confirmed_at = now() where id = ${stranger.id}`;
    await expect(computers.checkCanStart(orgId)).resolves.toBeUndefined();
    await h.tdb.admin`update public.organizations set suspended_at = now() where id = ${orgId}`;
    await expect(computers.checkCanStart(orgId)).rejects.toThrow("workspace_suspended");
  });
});
