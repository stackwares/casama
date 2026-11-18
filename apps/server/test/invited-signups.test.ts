/**
 * New accounts by invitation only (D-296): on a self-hosted server that the internet can reach,
 * its owner may let invited people sign up. Auth asks this hook before making an account.
 */
import { randomUUID } from "node:crypto";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { standardWebhookSignature } from "../src/billing/dodo.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const HOOK_SECRET = `whsec_${Buffer.from("invited-only-hook-secret-01").toString("base64")}`;

const hook = (h: Harness, email: string, signed = true) => {
  const body = JSON.stringify({ user: { email, app_metadata: { provider: "email" } } });
  const id = `msg_${randomUUID()}`;
  const ts = String(Math.floor(Date.now() / 1000));
  return h.request("/hooks/auth/before-user-created", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      ...(signed
        ? {
            "webhook-id": id,
            "webhook-timestamp": ts,
            "webhook-signature": `v1,${standardWebhookSignature(HOOK_SECRET, id, ts, body)}`,
          }
        : {}),
    },
    body,
  });
};

describe("sign-up by invitation only", () => {
  let h: Harness;
  let orgId: string;
  const invite = (email: string, extra = sql``) =>
    h.handle.db.execute(sql`
      insert into public.invites (org_id, email, role, token_hash)
      values (${orgId}::uuid, ${email}, 'member', ${randomUUID()})
      returning id ${extra}`);

  beforeAll(async () => {
    h = await startHarness({
      env: {
        SIGNUP_INVITED_ONLY: "true",
        SIGNUP_ALLOWED_EMAILS: "boss@example.com",
        AUTH_HOOK_SECRET: `v1,${HOOK_SECRET}`,
      },
    });
    const owner = await h.user("invites-owner@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Home" } }),
      )
    ).id;
  }, 60_000);
  afterAll(() => h?.stop());

  it("lets in an email with a standing invitation, however it is capitalized", async () => {
    await invite("Ana@Example.com");
    expect((await hook(h, "ana@example.com")).status).toBe(200);
    expect((await hook(h, "ANA@example.COM")).status).toBe(200);
  });

  it("refuses everyone else, and says why", async () => {
    const no = await hook(h, "stranger@example.com");
    expect(no.status).toBe(403);
    expect((await j(no)).error.message).toContain("by invitation only");
    // No email at all (a phone sign-up) has no invitation to match.
    expect((await hook(h, "")).status).toBe(403);
  });

  it("an invitation that ran out or was already used doesn't count", async () => {
    await invite("late@example.com");
    await h.handle.db.execute(
      sql`update public.invites set expires_at = now() - interval '1 minute' where email = 'late@example.com'`,
    );
    expect((await hook(h, "late@example.com")).status).toBe(403);
    await invite("used@example.com");
    await h.handle.db.execute(
      sql`update public.invites set accepted_at = now() where email = 'used@example.com'`,
    );
    expect((await hook(h, "used@example.com")).status).toBe(403);
  });

  it("the allowlist still lets its emails in", async () => {
    expect((await hook(h, "boss@example.com")).status).toBe(200);
  });

  it("a request that Auth didn't sign is refused", async () => {
    await invite("signed@example.com");
    expect((await hook(h, "signed@example.com", false)).status).toBe(401);
  });

  it("the apps are told accounts are by invitation", async () => {
    expect((await j(await h.request("/v1/config"))).signups_by_invitation).toBe(true);
  });
});

describe("sign-up by invitation, with the hook's secret missing", () => {
  let h: Harness;
  beforeAll(async () => {
    h = await startHarness({ env: { SIGNUP_INVITED_ONLY: "true" } });
  }, 60_000);
  afterAll(() => h?.stop());

  it("refuses rather than trusting whoever calls", async () => {
    const res = await hook(h, "anyone@example.com", false);
    expect(res.status).toBe(500);
  });
});
