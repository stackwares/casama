/**
 * The waitlist and invite gate for Casama Cloud (docs/WAITLIST-PLAN.md): the rule in Auth's hook,
 * joining the list, claiming invite codes, letting people in, and what happens after sign-up.
 */
import { createHash, randomUUID } from "node:crypto";
import type { JwtClaims } from "@casama/db";
import {
  type CaptureOptions,
  type ProductAnalytics,
  setProductAnalytics,
} from "@casama/observability";
import { sql } from "drizzle-orm";
import { strFromU8, unzipSync } from "fflate";
import { exportJWK, generateKeyPair, type JWK, SignJWT } from "jose";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { internalToken } from "../src/api/routes/local.ts";
import { supportLookups } from "../src/api/routes/support-tools.ts";
import { standardWebhookSignature } from "../src/billing/dodo.ts";
import { leadingZeroBits } from "../src/services/abuse.ts";
import { sweepSignups } from "../src/services/analytics-signups.ts";
import { IdTokenVerifier, JWKS_URLS } from "../src/services/id-token.ts";
import {
  admittedVia,
  campaignCodeForm,
  checkSignupGate,
  claimInvite,
  claimVia,
  cleanEmail,
  gateClosed,
  isDisposableEmail,
  joinWaitlist,
  linkWaitlistSignups,
  newOneTimeCode,
  oneTimeCodeForm,
  resetSignupGateCache,
  runDailyBatch,
  sendWaitlistInvites,
} from "../src/services/waitlist.ts";
import { type Harness, hookVerdict, j, startHarness } from "./helpers.ts";

const HOOK_SECRET = `whsec_${Buffer.from("waitlist-hook-secret-0123456").toString("base64")}`;
type U = { id: string; email: string; token: string };

let ipCount = 0;
/** A caller's address nobody else in this file uses, so the per-address limits don't mix tests. */
const ip = () => {
  ipCount++;
  return `10.${(ipCount >> 16) & 255}.${(ipCount >> 8) & 255}.${ipCount & 255}`;
};

function solve(challenge: string, difficulty: number) {
  for (let n = 0; ; n++) {
    const digest = createHash("sha256").update(`${challenge}:${n}`).digest();
    if (leadingZeroBits(digest) >= difficulty) return String(n);
  }
}

const kit = (get: () => Harness) => {
  const h = () => get();
  const hook = (
    email: string,
    opts: { provider?: string; signed?: boolean; proof?: unknown; inviteCode?: unknown } = {},
  ) => {
    const body = JSON.stringify({
      user: {
        email,
        app_metadata: { provider: opts.provider ?? "email" },
        user_metadata: {
          ...(opts.proof ? { signup_proof: opts.proof } : {}),
          ...(opts.inviteCode !== undefined ? { invite_code: opts.inviteCode } : {}),
        },
      },
    });
    const id = `msg_${randomUUID()}`;
    const ts = String(Math.floor(Date.now() / 1000));
    return h().request("/hooks/auth/before-user-created", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        ...(opts.signed === false
          ? {}
          : {
              "webhook-id": id,
              "webhook-timestamp": ts,
              "webhook-signature": `v1,${standardWebhookSignature(HOOK_SECRET, id, ts, body)}`,
            }),
      },
      body,
    });
  };
  const proof = async () => {
    const ch = await j(await h().request("/v1/signup/challenge"));
    return { challenge: ch.challenge, nonce: solve(ch.challenge, ch.difficulty) };
  };
  const join = async (email: string, extra: Record<string, unknown> = {}, from = ip()) =>
    h().request("/v1/waitlist", {
      method: "POST",
      headers: { "x-forwarded-for": from },
      json: { email, proof: await proof(), ...extra },
    });
  const redeem = async (
    email: string,
    code: string,
    extra: Record<string, unknown> = {},
    from = ip(),
  ) =>
    h().request("/v1/waitlist/redeem", {
      method: "POST",
      headers: { "x-forwarded-for": from },
      json: { email, code, proof: await proof(), ...extra },
    });
  /** The entry for an address; undefined at run time when there is none. */
  const entry = async (email: string) =>
    (
      await h().tdb.admin<Record<string, any>[]>`
        select * from public.waitlist_entries where email_key = public.email_key(${email})`
    )[0] as Record<string, any>;
  const setGate = (owner: U, gate: Record<string, unknown>) =>
    h().request("/v1/admin/signup-gate", { method: "PUT", token: owner.token, json: gate });
  return { hook, proof, join, redeem, entry, setGate };
};

const ENV = {
  SIGNUP_WAITLIST: "on",
  AUTH_HOOK_SECRET: `v1,${HOOK_SECRET}`,
  SIGNUP_POW_DIFFICULTY: "8",
  REFERRALS: "on",
  WAITLIST_URL: "https://casama.ai/waitlist",
};

describe("small pieces", () => {
  it("reads the gate setting, with defaults for what it leaves out", () => {
    expect(checkSignupGate({}).gate).toEqual({
      mode: "open",
      opens_at: null,
      invites_per_person: 3,
      daily_admit: 0,
      daily_emails_max: 25,
      batch_hour_utc: 15,
    });
    expect(checkSignupGate({ batch_hour_utc: 0 }).gate?.batch_hour_utc).toBe(0);
    expect(checkSignupGate({ batch_hour_utc: 24 }).gate).toBeNull();
    expect(checkSignupGate({ batch_hour_utc: 1.5 }).gate).toBeNull();
    expect(checkSignupGate({ mode: "invite_only", invites_per_person: 5 }).gate).toMatchObject({
      mode: "invite_only",
      invites_per_person: 5,
    });
    expect(checkSignupGate({ mode: "closed" }).gate).toBeNull();
    expect(checkSignupGate({ invites_per_person: -1 }).gate).toBeNull();
    expect(checkSignupGate({ opens_at: "soon" }).gate).toBeNull();
    expect(checkSignupGate("on").gate).toBeNull();
  });

  it("opens by itself at its opening time", () => {
    const base = checkSignupGate({ mode: "invite_only" }).gate!;
    const at = Date.parse("2027-01-12T08:01:00Z");
    const timed = { ...base, opens_at: "2027-01-12T08:01:00.000Z" };
    expect(gateClosed(base, at)).toBe(true);
    expect(gateClosed(timed, at - 1)).toBe(true);
    expect(gateClosed(timed, at)).toBe(false);
    expect(gateClosed({ ...timed, mode: "open" }, at - 1)).toBe(false);
  });

  it("tells email addresses and throwaway ones apart", () => {
    expect(cleanEmail("  Ana@Example.COM ")).toBe("ana@example.com");
    for (const bad of ["ana", "ana@", "@example.com", "ana@example", "a b@example.com", "a@b..com"])
      expect(cleanEmail(bad), bad).toBeNull();
    expect(isDisposableEmail("x@mailinator.com")).toBe(true);
    expect(isDisposableEmail("x@inbox.mailinator.com")).toBe(true);
    expect(isDisposableEmail("x@gmail.com")).toBe(false);
    expect(isDisposableEmail("x@casama.ai")).toBe(false);
  });

  it("knows what a one-time code looks like, and keeps it apart from the other codes", () => {
    const code = newOneTimeCode();
    expect(code).toMatch(/^[0-9A-Z]{4}-[0-9A-Z]{4}$/);
    expect(oneTimeCodeForm(code)).toBe(code);
    expect(oneTimeCodeForm(code.toLowerCase().replace("-", " "))).toBe(code);
    expect(oneTimeCodeForm("abcd-efgo")).toBe("ABCD-EFG0");
    expect(oneTimeCodeForm("https://casama.ai/invite/K7M2-QXAB")).toBe("K7M2-QXAB");
    // A member's 6-character code and a campaign code aren't one.
    expect(oneTimeCodeForm("K7M2QX")).toBeNull();
    expect(oneTimeCodeForm("SHOWHN-DEC8")).toBeNull();
  });

  it("names how a claim came in and how someone got in, never anything personal", () => {
    expect(claimVia("app_ios", false)).toBe("app");
    expect(claimVia("waitlist", false)).toBe("web");
    expect(claimVia(undefined, false)).toBe("web");
    expect(claimVia("app_ios", true)).toBe("id_token");
    expect(admittedVia("auto")).toBe("batch");
    expect(admittedVia("batch")).toBe("hand");
    expect(admittedVia("admin")).toBe("hand");
    expect(admittedVia("campaign:SHOWHN")).toBe("code");
    expect(admittedVia("one_time:x")).toBe("code");
  });

  it("knows what a campaign code looks like", () => {
    expect(campaignCodeForm("showhn-dec8")).toBe("SHOWHN-DEC8");
    expect(campaignCodeForm("https://casama.ai/invite/HackerNews?x=1")).toBe("HACKERNEWS");
    // A member's code is 6 characters and a workspace code 8: neither can be a campaign code.
    expect(campaignCodeForm("K7M2QX")).toBeNull();
    expect(campaignCodeForm("AB12CD34")).toBeNull();
    expect(campaignCodeForm("-ABCDEFGHI")).toBeNull();
  });
});

describe("a server without the waitlist (every self-hosted one)", () => {
  let h: Harness;
  const k = kit(() => h);
  let before: Record<string, unknown>;
  beforeAll(async () => {
    resetSignupGateCache();
    // No SIGNUP_WAITLIST and no billing: the default for a self-hosted server.
    h = await startHarness({ env: { AUTH_HOOK_SECRET: `v1,${HOOK_SECRET}` } });
    before = await j(await h.request("/v1/config"));
  }, 60_000);
  afterAll(() => h?.stop());

  it("has no waitlist routes", async () => {
    const owner = await h.user("selfhost-owner@example.dev");
    expect((await k.join("someone@example.dev")).status).toBe(404);
    expect((await j(await k.join("someone@example.dev"))).code).toBe("waitlist_off");
    expect((await k.redeem("someone@example.dev", "SHOWHN-DEC8")).status).toBe(404);
    expect((await h.request("/v1/invites/preview?code=SHOWHN-DEC8")).status).toBe(404);
    for (const path of [
      "/v1/admin/waitlist",
      "/v1/admin/signup-gate",
      "/v1/admin/invite-campaigns",
    ])
      expect((await h.request(path, { token: owner.token })).status, path).toBe(404);
  });

  it("ignores a gate setting, lets strangers sign up and says nothing new to the apps", async () => {
    await h.tdb.admin`
      insert into public.instance_settings (key, value)
      values ('signup_gate', '{"mode":"invite_only"}'::jsonb)`;
    resetSignupGateCache();
    expect(await hookVerdict(await k.hook("stranger@example.dev"))).toBe(200);
    const cfg = await j(await h.request("/v1/config"));
    expect(cfg).toEqual(before);
    expect(cfg.signup_gate).toBeUndefined();
    expect(cfg.signups_by_invitation).toBeUndefined();
  });
});

describe("the gate in the sign-up hook", () => {
  let h: Harness;
  const k = kit(() => h);
  let owner: U;
  beforeAll(async () => {
    resetSignupGateCache();
    h = await startHarness({ env: ENV });
    owner = await h.user("gate-owner@example.dev"); // first user: the instance owner
  }, 60_000);
  afterAll(() => h?.stop());

  it("is open until an owner turns it on", async () => {
    expect(await hookVerdict(await k.hook("early@example.dev"))).toBe(200);
    const cfg = await j(await h.request("/v1/config"));
    expect(cfg.signup_gate).toBeUndefined();
    expect(cfg.signups_by_invitation).toBeUndefined();
    const state = await j(await h.request("/v1/admin/signup-gate", { token: owner.token }));
    expect(state).toMatchObject({ closed: false, gate: { mode: "open", invites_per_person: 3 } });
  });

  it("turns on from the admin route, and the apps are told", async () => {
    const res = await k.setGate(owner, { mode: "invite_only" });
    expect(res.status).toBe(200);
    expect(await j(res)).toMatchObject({ closed: true, gate: { mode: "invite_only" } });
    const cfg = await j(await h.request("/v1/config"));
    expect(cfg.signups_by_invitation).toBe(true);
    expect(cfg.signup_gate).toEqual({
      mode: "invite_only",
      waitlist_url: "https://casama.ai/waitlist",
    });
    expect((await k.setGate(owner, { mode: "sometimes" })).status).toBe(400);
  });

  it("refuses a stranger in the way Auth passes on: HTTP 200 with the reason in the body", async () => {
    const res = await k.hook("stranger@example.dev");
    // Auth shows the message only when the hook answers 200; a 403 from the hook itself reaches
    // the app as "Unexpected status code returned from hook" (checked against Auth v2.197.0).
    expect(res.status).toBe(200);
    const body = await j(res);
    expect(body.error.http_code).toBe(403);
    expect(body.error.message).toBe(
      "Casama Cloud is invite-only for now. Join the waitlist or enter an invite code at casama.ai/waitlist.",
    );
    // Whatever the sign-in method.
    for (const provider of ["google", "apple"])
      expect(await hookVerdict(await k.hook("stranger@example.dev", { provider }))).toBe(403);
    expect(await hookVerdict(await k.hook(""))).toBe(403);
  });

  it("tells a hidden Apple address what to do instead", async () => {
    const res = await k.hook("abc123@privaterelay.appleid.com", { provider: "apple" });
    expect((await j(res)).error.message).toContain("Share My Email");
  });

  it("lets in an address that was let in, however it is written", async () => {
    const add = await h.request("/v1/admin/waitlist/entries", {
      method: "POST",
      token: owner.token,
      json: { emails: ["Dana.Lee@gmail.com", "pat@example.dev", "not an email"] },
    });
    expect(await j(add)).toEqual({ count: 2, skipped: ["not an email"] });
    expect(await hookVerdict(await k.hook("pat@example.dev"))).toBe(200);
    expect(await hookVerdict(await k.hook("PAT+casama@Example.dev", { provider: "google" }))).toBe(
      200,
    );
    // Gmail ignores dots and "+tags": the same inbox.
    expect(await hookVerdict(await k.hook("danalee+x@googlemail.com"))).toBe(200);
    expect(await hookVerdict(await k.hook("pat@example.com"))).toBe(403);
    // Nobody was emailed: the owner let them in by hand.
    expect((await k.entry("pat@example.dev")).status).toBe("admitted");
    expect((await k.entry("pat@example.dev")).notified_at).toBeNull();
  });

  it("someone only waiting on the list is still refused", async () => {
    expect((await k.join("waiting@example.dev")).status).toBe(200);
    expect(await hookVerdict(await k.hook("waiting@example.dev"))).toBe(403);
  });

  it("a workspace invite counts only while the workspace has a seat for it", async () => {
    const org = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Team" } }),
      )
    ).id;
    const invite = (email: string) => h.tdb.admin`
      insert into public.invites (org_id, email, role, token_hash)
      values (${org}::uuid, ${email}, 'member', ${randomUUID()})`;
    // No seat limit on this workspace: an invite lets its address in.
    await h.tdb.admin`delete from public.entitlements where org_id = ${org}::uuid`;
    await invite("first@example.dev");
    expect(await hookVerdict(await k.hook("First@Example.dev"))).toBe(200);
    // Two seats, one taken by the owner: the first invite has a seat, the second doesn't.
    await h.tdb.admin`
      insert into public.entitlements (org_id, plan_code, limits)
      values (${org}::uuid, (select code from public.plans order by code limit 1), '{"seats": 2}'::jsonb)`;
    await invite("second@example.dev");
    expect(await hookVerdict(await k.hook("first@example.dev"))).toBe(200);
    expect(await hookVerdict(await k.hook("second@example.dev"))).toBe(403);
    // One seat (a Free workspace): nobody gets in through an invite.
    await h.tdb
      .admin`update public.entitlements set limits = '{"seats": 1}'::jsonb where org_id = ${org}::uuid`;
    expect(await hookVerdict(await k.hook("first@example.dev"))).toBe(403);
    // An invite that ran out doesn't count either.
    await h.tdb
      .admin`update public.entitlements set limits = '{"seats": 5}'::jsonb where org_id = ${org}::uuid`;
    await h.tdb
      .admin`update public.invites set expires_at = now() - interval '1 minute' where email = 'second@example.dev'`;
    expect(await hookVerdict(await k.hook("second@example.dev"))).toBe(403);
    expect(await hookVerdict(await k.hook("first@example.dev"))).toBe(200);
  });

  it("refuses calls Auth didn't sign", async () => {
    expect(await hookVerdict(await k.hook("pat@example.dev", { signed: false }))).toBe(401);
  });

  it("refuses everyone when the setting can't be read, and asks Auth to try again", async () => {
    await h.tdb
      .admin`update public.instance_settings set value = '{"mode":"maybe"}'::jsonb where key = 'signup_gate'`;
    resetSignupGateCache();
    const res = await k.hook("pat@example.dev");
    expect(res.status).toBe(503);
    expect(res.headers.get("retry-after")).toBe("1");
    // The apps are told accounts are by invitation rather than offered a sign-up that fails.
    expect((await j(await h.request("/v1/config"))).signups_by_invitation).toBe(true);
    await h.tdb
      .admin`update public.instance_settings set value = '{"mode":"invite_only"}'::jsonb where key = 'signup_gate'`;
    resetSignupGateCache();
    expect(await hookVerdict(await k.hook("pat@example.dev"))).toBe(200);
  });

  it("opens again with one setting, and at a time set ahead", async () => {
    await k.setGate(owner, { opens_at: new Date(Date.now() - 1000).toISOString() });
    expect(await hookVerdict(await k.hook("anyone@example.dev"))).toBe(200);
    expect((await j(await h.request("/v1/config"))).signup_gate).toBeUndefined();
    await k.setGate(owner, { opens_at: new Date(Date.now() + 3_600_000).toISOString() });
    expect(await hookVerdict(await k.hook("anyone@example.dev"))).toBe(403);
    await k.setGate(owner, { mode: "open", opens_at: null });
    expect(await hookVerdict(await k.hook("anyone@example.dev"))).toBe(200);
  });
});

describe("the gate on a server that also has an email allowlist (D-145)", () => {
  let h: Harness;
  const k = kit(() => h);
  beforeAll(async () => {
    resetSignupGateCache();
    h = await startHarness({ env: { ...ENV, SIGNUP_ALLOWED_EMAILS: "boss@example.dev" } });
    const owner = await h.user("allow-owner@example.dev");
    await k.setGate(owner, { mode: "invite_only" });
    await h.request("/v1/admin/waitlist/entries", {
      method: "POST",
      token: owner.token,
      json: { emails: ["in@example.dev"] },
    });
  }, 60_000);
  afterAll(() => h?.stop());

  it("the allowlist keeps deciding alone: its addresses get in, nobody else does", async () => {
    expect(await hookVerdict(await k.hook("boss@example.dev"))).toBe(200);
    const res = await k.hook("in@example.dev");
    expect(await hookVerdict(res)).toBe(403);
    expect((await j(res)).error.message).toContain("approved email addresses");
  });
});

describe("the gate with the sign-up proof on (Casama Cloud)", () => {
  let h: Harness;
  const k = kit(() => h);
  beforeAll(async () => {
    resetSignupGateCache();
    h = await startHarness({ env: { ...ENV, ABUSE_CONTROLS: "on" } });
    const owner = await h.user("proof-owner@example.dev");
    await k.setGate(owner, { mode: "invite_only" });
    await h.request("/v1/admin/waitlist/entries", {
      method: "POST",
      token: owner.token,
      json: { emails: ["in@example.dev"] },
    });
  }, 60_000);
  afterAll(() => h?.stop());

  it("being let in doesn't replace the proof, and a proof doesn't replace being let in", async () => {
    expect(await hookVerdict(await k.hook("in@example.dev"))).toBe(403);
    const p = await k.proof();
    expect(
      await hookVerdict(await k.hook("out@example.dev", { proof: { kind: "pow", ...p } })),
    ).toBe(403);
    const q = await k.proof();
    expect(
      await hookVerdict(await k.hook("in@example.dev", { proof: { kind: "pow", ...q } })),
    ).toBe(200);
    // Google and Apple need no proof, but still need to have been let in.
    expect(await hookVerdict(await k.hook("in@example.dev", { provider: "google" }))).toBe(200);
    expect(await hookVerdict(await k.hook("out@example.dev", { provider: "google" }))).toBe(403);
  });

  it("the invite-only refusal doesn't fill the abuse log", async () => {
    const [n] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.abuse_events
      where kind = 'signup_blocked' and detail ->> 'email_domain' = 'example.dev'
        and detail ->> 'reason' = 'not_invited'`;
    expect(n?.n).toBe(0);
  });
});

describe("the waitlist", () => {
  let h: Harness;
  const k = kit(() => h);
  let owner: U;
  let stranger: U;
  beforeAll(async () => {
    resetSignupGateCache();
    h = await startHarness({ env: ENV, email: true });
    owner = await h.user("list-owner@example.dev");
    stranger = await h.user("list-stranger@example.dev");
    await k.setGate(owner, { mode: "invite_only" });
  }, 60_000);
  afterAll(() => h?.stop());

  describe("joining", () => {
    it("takes an address, sends no email and answers the same every time", async () => {
      const first = await k.join("Rae+news@gmail.com", {
        source: "home",
        ref: "hn",
        note: "Sort my inbox",
        self_hosting: true,
      });
      expect(first.status).toBe(200);
      expect(await j(first)).toEqual({ ok: true });
      // The same inbox again, written differently, with a yes to the monthly email this time.
      const again = await k.join("r.a.e@googlemail.com", { newsletter: true, note: "Another" });
      expect(await j(again)).toEqual({ ok: true });
      // An address that already has an account gets the same answer too.
      expect(await j(await k.join(stranger.email))).toEqual({ ok: true });
      const rows = await h.tdb.admin<Record<string, any>[]>`
        select * from public.waitlist_entries where email_key = public.email_key('rae@gmail.com')`;
      expect(rows).toHaveLength(1);
      expect(rows[0]).toMatchObject({
        email: "rae+news@gmail.com",
        status: "waiting",
        source: "home",
        ref: "hn",
        note: "Sort my inbox",
        self_hosting: true,
        newsletter_opt_in: true,
        newsletter_wording: "waitlist-2026-11",
      });
      expect(rows[0]?.newsletter_consent_at).not.toBeNull();
      expect(rows[0]?.ip_hash).toMatch(/^[0-9a-f]{32}$/);
      expect(h.outbox).toHaveLength(0);
    });

    it("a later join never takes the monthly-email yes back", async () => {
      await k.join("rae@gmail.com", { newsletter: false });
      expect((await k.entry("rae@gmail.com")).newsletter_opt_in).toBe(true);
    });

    it("needs a solved puzzle, good once", async () => {
      const post = (json: unknown) =>
        h.request("/v1/waitlist", { method: "POST", headers: { "x-forwarded-for": ip() }, json });
      const p = await k.proof();
      expect(
        (await post({ email: "puzzle@example.dev", proof: { ...p, nonce: "nope" } })).status,
      ).toBe(403);
      expect((await post({ email: "puzzle@example.dev", proof: p })).status).toBe(200);
      const reused = await post({ email: "puzzle2@example.dev", proof: p });
      expect(reused.status).toBe(403);
      expect((await j(reused)).code).toBe("proof_required");
      expect(await k.entry("puzzle2@example.dev")).toBeUndefined();
      expect((await post({ email: "puzzle3@example.dev" })).status).toBe(400);
    });

    it("turns away what isn't an address, and throwaway addresses", async () => {
      const bad = await k.join("not-an-address");
      expect(bad.status).toBe(400);
      expect((await j(bad)).code).toBe("bad_email");
      const throwaway = await k.join("me@mailinator.com");
      expect(throwaway.status).toBe(400);
      expect((await j(throwaway)).code).toBe("disposable_email");
    });

    it("holds one address to a few tries in ten minutes", async () => {
      const from = ip();
      for (let i = 0; i < 5; i++)
        expect((await k.join(`burst-${i}@example.dev`, {}, from)).status).toBe(200);
      const over = await k.join("burst-6@example.dev", {}, from);
      expect(over.status).toBe(429);
      expect((await j(over)).code).toBe("too_many_attempts");
      expect(over.headers.get("retry-after")).toBeTruthy();
      // Someone else is not held up.
      expect((await k.join("calm@example.dev")).status).toBe(200);
    });
  });

  describe("letting people in", () => {
    const outFor = (email: string) => h.outbox.filter((m) => m.to === email);
    const send = (perTick = 5) =>
      sendWaitlistInvites({
        db: h.handle.db,
        email: h.deps.email,
        env: h.deps.env,
        secret: internalToken(h.deps.env),
        perTick,
      });

    it("is the owner's to do", async () => {
      const calls: Array<[string, string, unknown?]> = [
        ["GET", "/v1/admin/waitlist"],
        ["POST", "/v1/admin/waitlist/admit", { count: 1 }],
        ["POST", "/v1/admin/waitlist/entries", { emails: ["x@example.dev"] }],
        ["DELETE", `/v1/admin/waitlist/entries/${randomUUID()}`],
        ["GET", "/v1/admin/signup-gate"],
        ["PUT", "/v1/admin/signup-gate", { mode: "open" }],
        ["GET", "/v1/admin/invite-campaigns"],
        ["POST", "/v1/admin/invite-campaigns", { code: "SNEAKY-CODE", label: "x", max_uses: 9 }],
        ["PATCH", "/v1/admin/invite-campaigns/SNEAKY-CODE", { max_uses: 99 }],
      ];
      for (const [method, path, json] of calls) {
        expect((await h.request(path, { method, json })).status, `${method} ${path}`).toBe(401);
        expect(
          (await h.request(path, { method, json, token: stranger.token })).status,
          `${method} ${path}`,
        ).toBe(403);
      }
      expect(
        (await j(await h.request("/v1/admin/signup-gate", { token: owner.token }))).closed,
      ).toBe(true);
    });

    it("takes the next people in order: a used-up code, self-hosters, a note, then oldest", async () => {
      await h.tdb.admin`delete from public.waitlist_entries`;
      const add = async (email: string, minutesAgo: number, e: Record<string, unknown> = {}) => {
        await joinWaitlist(h.handle.db, { email, source: "order", ...e });
        await h.tdb.admin`
          update public.waitlist_entries set created_at = now() - make_interval(mins => ${minutesAgo})
          where email = ${email}`;
      };
      await add("oldest@example.dev", 50);
      await add("noted@example.dev", 40, { note: "Plan my trips" });
      await add("hoster@example.dev", 30, { selfHosting: true });
      await add("newest@example.dev", 10);
      await add("coded@example.dev", 5);
      await h.tdb
        .admin`update public.waitlist_entries set priority = 10 where email = 'coded@example.dev'`;
      const list = await j(
        await h.request("/v1/admin/waitlist?status=waiting", { token: owner.token }),
      );
      expect(list.items.map((i: { email: string }) => i.email)).toEqual([
        "coded@example.dev",
        "hoster@example.dev",
        "noted@example.dev",
        "oldest@example.dev",
        "newest@example.dev",
      ]);
      expect(list.stats).toMatchObject({ waiting: 5, queued: 0, admitted: 0 });
      const res = await h.request("/v1/admin/waitlist/admit", {
        method: "POST",
        token: owner.token,
        json: { count: 3 },
      });
      expect(await j(res)).toEqual({ count: 3 });
      // Chosen, but not in until their email goes out.
      expect((await k.entry("coded@example.dev")).status).toBe("waiting");
      expect(await hookVerdict(await k.hook("coded@example.dev"))).toBe(403);
      expect(await send()).toBe(3);
      for (const email of ["coded@example.dev", "hoster@example.dev", "noted@example.dev"]) {
        expect((await k.entry(email)).status, email).toBe("admitted");
        expect((await k.entry(email)).admitted_via).toBe("batch");
        expect(outFor(email)).toHaveLength(1);
        expect(await hookVerdict(await k.hook(email))).toBe(200);
      }
      expect((await k.entry("oldest@example.dev")).status).toBe("waiting");
      expect(outFor("oldest@example.dev")).toHaveLength(0);
      // Nothing is sent twice.
      expect(await send()).toBe(0);
      expect(h.outbox.filter((m) => m.subject.startsWith("You're in"))).toHaveLength(3);
    });

    it("the email says which address to use and how to be taken off the list", async () => {
      const [mail] = outFor("hoster@example.dev");
      expect(mail?.subject).toBe("You're in: Casama is ready for you");
      expect(mail?.text).toContain("Sign in with hoster@example.dev");
      const token = /waitlist\/leave\?t=(\S+)/.exec(mail?.text ?? "")?.[1];
      expect(token).toBeTruthy();
      const leave = (t: string) =>
        h.request("/v1/waitlist/leave", {
          method: "POST",
          headers: { "x-forwarded-for": ip() },
          json: { token: t },
        });
      expect((await leave(`${token?.slice(0, -2)}xx`)).status).toBe(400);
      expect((await leave(`${randomUUID()}.${"a".repeat(32)}`)).status).toBe(400);
      expect(await k.entry("hoster@example.dev")).toBeDefined();
      expect((await leave(token ?? "")).status).toBe(200);
      expect(await k.entry("hoster@example.dev")).toBeUndefined();
      // Off the list means out again.
      expect(await hookVerdict(await k.hook("hoster@example.dev"))).toBe(403);
    });

    it("never sends more than the day's number, and a few at a time", async () => {
      const sentSoFar = (await j(await h.request("/v1/admin/waitlist", { token: owner.token })))
        .stats.emails_today;
      await k.setGate(owner, { daily_emails_max: sentSoFar + 2 });
      for (let i = 0; i < 6; i++)
        await joinWaitlist(h.handle.db, { email: `cap-${i}@example.dev` });
      await h.request("/v1/admin/waitlist/admit", {
        method: "POST",
        token: owner.token,
        json: { count: 20 },
      });
      expect(await send(1)).toBe(1);
      expect(await send(50)).toBe(1);
      expect(await send(50)).toBe(0);
      const stats = (await j(await h.request("/v1/admin/waitlist", { token: owner.token }))).stats;
      expect(stats.emails_today).toBe(sentSoFar + 2);
      expect(stats.queued).toBeGreaterThan(0);
      // Tomorrow the rest go out.
      await h.tdb
        .admin`update public.waitlist_entries set notified_at = notified_at - interval '1 day' where notified_at is not null`;
      expect(await send(2)).toBe(2);
      await k.setGate(owner, { daily_emails_max: 1000 });
    });

    it("a failed send puts the person back in line", async () => {
      await joinWaitlist(h.handle.db, { email: "flaky@example.dev" });
      const id = (await k.entry("flaky@example.dev")).id;
      await h.request("/v1/admin/waitlist/admit", {
        method: "POST",
        token: owner.token,
        json: { ids: [id] },
      });
      await h.tdb
        .admin`update public.waitlist_entries set queued_at = now() - interval '1 day' where id = ${id}::uuid`;
      const broken = {
        enabled: true,
        send: async () => {
          throw new Error("mail is down");
        },
      };
      const n = await sendWaitlistInvites({
        db: h.handle.db,
        email: broken,
        env: h.deps.env,
        secret: "s",
        perTick: 1,
      });
      expect(n).toBe(0);
      expect(await k.entry("flaky@example.dev")).toMatchObject({
        status: "waiting",
        notify_attempts: 1,
        notify_error: "mail is down",
        notified_at: null,
        admitted_at: null,
      });
      expect(await hookVerdict(await k.hook("flaky@example.dev"))).toBe(403);
      expect(await send(1)).toBe(1);
      expect((await k.entry("flaky@example.dev")).status).toBe("admitted");
    });

    it("an entry can be removed, which shuts its address out again", async () => {
      await h.request("/v1/admin/waitlist/entries", {
        method: "POST",
        token: owner.token,
        json: { emails: ["oops@example.dev"] },
      });
      expect(await hookVerdict(await k.hook("oops@example.dev"))).toBe(200);
      const id = (await k.entry("oops@example.dev")).id;
      const del = (entryId: string) =>
        h.request(`/v1/admin/waitlist/entries/${entryId}`, {
          method: "DELETE",
          token: owner.token,
        });
      expect((await del(id)).status).toBe(204);
      expect((await del(id)).status).toBe(404);
      expect(await hookVerdict(await k.hook("oops@example.dev"))).toBe(403);
    });

    it("hand-added addresses can get the email too", async () => {
      const before = h.outbox.length;
      const res = await h.request("/v1/admin/waitlist/entries", {
        method: "POST",
        token: owner.token,
        json: { emails: ["told-by-mail@example.dev"], notify: true },
      });
      expect(await j(res)).toEqual({ count: 1 });
      expect((await k.entry("told-by-mail@example.dev")).status).toBe("waiting");
      await send(50);
      expect((await k.entry("told-by-mail@example.dev")).status).toBe("admitted");
      expect(h.outbox.length).toBeGreaterThan(before);
    });
  });

  describe("campaign codes", () => {
    const campaign = (json: Record<string, unknown>) =>
      h.request("/v1/admin/invite-campaigns", { method: "POST", token: owner.token, json });
    const patch = (code: string, json: Record<string, unknown>) =>
      h.request(`/v1/admin/invite-campaigns/${code}`, {
        method: "PATCH",
        token: owner.token,
        json,
      });
    const preview = (code: string, from = ip()) =>
      h.request(`/v1/invites/preview?code=${encodeURIComponent(code)}`, {
        headers: { "x-forwarded-for": from },
      });

    it("are made by the owner, with a link to share", async () => {
      const res = await campaign({ code: "showhn-test", label: "Show HN", max_uses: 2 });
      expect(res.status).toBe(200);
      expect(await j(res)).toMatchObject({
        code: "SHOWHN-TEST",
        label: "Show HN",
        max_uses: 2,
        used: 0,
        disabled: false,
        link: "https://casama.ai/invite/SHOWHN-TEST",
      });
      expect((await campaign({ code: "SHOWHN-TEST", label: "Again", max_uses: 1 })).status).toBe(
        409,
      );
      // Could be mistaken for a member's code or a workspace code.
      for (const code of ["ABC123", "AB12CD34", "no spaces!"])
        expect((await campaign({ code, label: "Bad", max_uses: 1 })).status, code).toBe(400);
      const list = await j(await h.request("/v1/admin/invite-campaigns", { token: owner.token }));
      expect(list.items.map((i: { code: string }) => i.code)).toContain("SHOWHN-TEST");
    });

    it("let in exactly their total, and then put people near the front of the list", async () => {
      expect(await j(await preview("showhn-test"))).toEqual({
        kind: "campaign",
        label: "Show HN",
        inviter_name: null,
        available: true,
        welcome_usd: 0,
      });
      const before = h.outbox.length;
      const a = await k.redeem("camp-a@example.dev", "https://casama.ai/invite/showhn-test");
      expect(await j(a)).toEqual({ outcome: "admitted", kind: "campaign" });
      expect(await hookVerdict(await k.hook("camp-a@example.dev", { provider: "google" }))).toBe(
        200,
      );
      // The same person again uses up nothing.
      expect((await j(await k.redeem("Camp-A+x@example.dev", "SHOWHN-TEST"))).outcome).toBe(
        "admitted",
      );
      // Nor does someone who already has an account.
      expect((await j(await k.redeem(stranger.email, "SHOWHN-TEST"))).outcome).toBe("admitted");
      expect((await j(await k.redeem("camp-b@example.dev", "SHOWHN-TEST"))).outcome).toBe(
        "admitted",
      );
      const c = await j(await k.redeem("camp-c@example.dev", "SHOWHN-TEST", { newsletter: true }));
      expect(c).toEqual({ outcome: "waitlisted", kind: "campaign" });
      expect(await k.entry("camp-c@example.dev")).toMatchObject({
        status: "waiting",
        priority: 10,
        invite_code: "SHOWHN-TEST",
        newsletter_opt_in: true,
      });
      expect(await hookVerdict(await k.hook("camp-c@example.dev"))).toBe(403);
      expect((await j(await preview("SHOWHN-TEST"))).available).toBe(false);
      const [row] = (
        await j(await h.request("/v1/admin/invite-campaigns", { token: owner.token }))
      ).items.filter((i: { code: string }) => i.code === "SHOWHN-TEST");
      expect(row.used).toBe(2);
      expect(await k.entry("camp-a@example.dev")).toMatchObject({
        status: "admitted",
        admitted_via: "campaign:SHOWHN-TEST",
      });
      // Told on the page: no email.
      expect(h.outbox.length).toBe(before);
      // A bigger total lets the person who was waiting claim again.
      await patch("SHOWHN-TEST", { max_uses: 3 });
      expect((await j(await k.redeem("camp-c@example.dev", "SHOWHN-TEST"))).outcome).toBe(
        "admitted",
      );
      expect((await k.entry("camp-c@example.dev")).status).toBe("admitted");
    });

    it("can't give the last place twice", async () => {
      await campaign({ code: "RACE-CODE", label: "Race", max_uses: 3 });
      const results = await Promise.all(
        Array.from({ length: 20 }, (_, i) =>
          claimInvite(h.handle.db, {
            email: `racer-${i}@example.dev`,
            code: "RACE-CODE",
            perPerson: 3,
          }),
        ),
      );
      expect(results.filter((r) => r?.outcome === "admitted")).toHaveLength(3);
      expect(results.filter((r) => r?.outcome === "waitlisted")).toHaveLength(17);
      const [n] = await h.tdb.admin<{ used: number; admitted: number }[]>`
        select (select used from public.invite_campaigns where code = 'RACE-CODE') as used,
          (select count(*)::int from public.waitlist_entries where admitted_via = 'campaign:RACE-CODE') as admitted`;
      expect(n).toEqual({ used: 3, admitted: 3 });
    });

    it("hold to a number per day, a start, an end and an off switch", async () => {
      await campaign({ code: "DAILY-CODE", label: "Daily", max_uses: 100, per_day: 1 });
      expect((await j(await k.redeem("day-1@example.dev", "DAILY-CODE"))).outcome).toBe("admitted");
      expect((await j(await k.redeem("day-2@example.dev", "DAILY-CODE"))).outcome).toBe(
        "waitlisted",
      );
      await h.tdb
        .admin`update public.waitlist_entries set admitted_at = admitted_at - interval '1 day' where email = 'day-1@example.dev'`;
      expect((await j(await k.redeem("day-2@example.dev", "DAILY-CODE"))).outcome).toBe("admitted");

      const soon = new Date(Date.now() + 3_600_000).toISOString();
      const past = new Date(Date.now() - 3_600_000).toISOString();
      await campaign({ code: "LATER-CODE", label: "Later", max_uses: 9, starts_at: soon });
      expect((await j(await k.redeem("early@example.dev", "LATER-CODE"))).outcome).toBe(
        "waitlisted",
      );
      await patch("LATER-CODE", { starts_at: null, expires_at: past });
      expect((await j(await k.redeem("late@example.dev", "LATER-CODE"))).outcome).toBe(
        "waitlisted",
      );
      await patch("LATER-CODE", { expires_at: null, disabled: true });
      expect((await j(await preview("LATER-CODE"))).available).toBe(false);
      expect((await j(await k.redeem("off@example.dev", "LATER-CODE"))).outcome).toBe("waitlisted");
      const on = await j(await patch("LATER-CODE", { disabled: false }));
      expect(on.disabled).toBe(false);
      expect((await j(await k.redeem("off@example.dev", "LATER-CODE"))).outcome).toBe("admitted");
      expect((await patch("NO-SUCH-CODE", { max_uses: 1 })).status).toBe(404);
    });

    it("wrong codes are counted, and a guesser is stopped", async () => {
      const from = ip();
      const miss = await preview("NOPE-NOT-REAL", from);
      expect(miss.status).toBe(404);
      expect((await j(miss)).code).toBe("invite_not_found");
      for (let i = 0; i < 9; i++) await preview(`GUESS-${i}-CODE`, from);
      expect((await preview("SHOWHN-TEST", from)).status).toBe(429);
      // Claims need the puzzle too, and a wrong code there counts the same way.
      const other = ip();
      const bad = await k.redeem("guesser@example.dev", "ZZZZZZ", {}, other);
      expect(bad.status).toBe(404);
      const noProof = await h.request("/v1/waitlist/redeem", {
        method: "POST",
        headers: { "x-forwarded-for": ip() },
        json: {
          email: "guesser@example.dev",
          code: "SHOWHN-TEST",
          proof: { challenge: "v1.8.1.x.y", nonce: "1" },
        },
      });
      expect(noProof.status).toBe(403);
    });
  });

  describe("members' invites", () => {
    let ana: U;
    let friend: U;
    let code: string;
    const referral = async (u: U) => j(await h.request("/v1/me/referral", { token: u.token }));
    const firstChat = (u: U) => h.tdb.admin`
      insert into public.analytics_milestones (user_id, milestone) values (${u.id}::uuid, 'first_value')
      on conflict do nothing`;

    beforeAll(async () => {
      ana = await h.user("ana-invites@example.dev");
      await h.tdb
        .admin`update public.profiles set display_name = 'Ana Reyes' where user_id = ${ana.id}::uuid`;
      await k.setGate(owner, { invites_per_person: 2 });
      code = (await referral(ana)).code;
    });

    it("are the member's own code, locked until their first finished chat", async () => {
      expect(code).toMatch(/^[0-9A-Z]{6}$/);
      expect((await referral(ana)).invites).toEqual({
        total: 2,
        used: 0,
        left: 2,
        unlocked: false,
      });
      const pv = await j(await h.request(`/v1/invites/preview?code=${code}`));
      expect(pv).toMatchObject({ kind: "personal", inviter_name: "Ana", available: false });
      const early = await j(await k.redeem("friend-0@example.dev", code));
      expect(early).toEqual({ outcome: "waitlisted", kind: "personal" });
      expect(await k.entry("friend-0@example.dev")).toMatchObject({
        status: "waiting",
        priority: 10,
      });
    });

    it("let in as many friends as the member has invites", async () => {
      await firstChat(ana);
      expect((await j(await h.request(`/v1/invites/preview?code=${code}`))).available).toBe(true);
      // The friend who came early claims again now that the invites are unlocked.
      expect((await j(await k.redeem("friend-0@example.dev", code.toLowerCase()))).outcome).toBe(
        "admitted",
      );
      expect(
        (await j(await k.redeem("friend-1@example.dev", `https://casama.ai/invite/${code}`)))
          .outcome,
      ).toBe("admitted");
      expect((await j(await k.redeem("friend-2@example.dev", code))).outcome).toBe("waitlisted");
      expect((await referral(ana)).invites).toEqual({ total: 2, used: 2, left: 0, unlocked: true });
      expect(await hookVerdict(await k.hook("friend-1@example.dev"))).toBe(200);
      expect(await hookVerdict(await k.hook("friend-2@example.dev"))).toBe(403);
      expect(await k.entry("friend-1@example.dev")).toMatchObject({
        status: "admitted",
        admitted_via: `invite:${ana.id}`,
        inviter_id: ana.id,
      });
      // One more for this member only.
      await h.tdb
        .admin`update public.referral_codes set invite_bonus = 1 where user_id = ${ana.id}::uuid`;
      expect((await referral(ana)).invites).toMatchObject({ total: 3, left: 1 });
      expect((await j(await k.redeem("friend-2@example.dev", code))).outcome).toBe("admitted");
    });

    it("can't be taken twice at the same moment", async () => {
      const ben = await h.user("ben-invites@example.dev");
      await firstChat(ben);
      const benCode = (await referral(ben)).code;
      const results = await Promise.all(
        Array.from({ length: 12 }, (_, i) =>
          claimInvite(h.handle.db, {
            email: `ben-friend-${i}@example.dev`,
            code: benCode,
            perPerson: 2,
          }),
        ),
      );
      expect(results.filter((r) => r?.outcome === "admitted")).toHaveLength(2);
    });

    it("the friend's referral follows them into their account, and the list knows they joined", async () => {
      friend = await h.user("friend-1@example.dev");
      const plain = await h.user("camp-b@example.dev");
      const n = await linkWaitlistSignups({ db: h.handle.db, referrals: true });
      expect(n).toBeGreaterThanOrEqual(2);
      expect(await k.entry("friend-1@example.dev")).toMatchObject({
        status: "joined",
        user_id: friend.id,
      });
      expect((await k.entry("friend-1@example.dev")).joined_at).not.toBeNull();
      const refs = await h.tdb.admin<{ inviter_id: string; code: string; status: string }[]>`
        select inviter_id, code, status from public.referrals where invitee_id = ${friend.id}::uuid`;
      expect(refs).toEqual([{ inviter_id: ana.id, code, status: "pending" }]);
      expect((await referral(friend)).invited_by).toMatchObject({ name: "Ana" });
      // Someone who came through a campaign code has no inviter.
      expect((await k.entry("camp-b@example.dev")).status).toBe("joined");
      const none = await h.tdb
        .admin`select 1 from public.referrals where invitee_id = ${plain.id}::uuid`;
      expect(none).toHaveLength(0);
      // Running it again changes nothing, and a joined person can still sign up after deleting.
      expect(await linkWaitlistSignups({ db: h.handle.db, referrals: true })).toBe(0);
      expect(await hookVerdict(await k.hook("friend-1@example.dev"))).toBe(200);
    });

    it("a yes to the monthly email is applied once the person has signed up", async () => {
      await joinWaitlist(h.handle.db, { email: "rae+news@gmail.com", newsletter: true });
      await h.tdb
        .admin`update public.waitlist_entries set status = 'admitted', admitted_at = now() where email = 'rae+news@gmail.com'`;
      const rae = await h.user("rae@gmail.com");
      // Resend hears about it once the address is confirmed (D-408); the choice is saved now.
      const fakeResend = (async () =>
        new Response(JSON.stringify({ id: "contact_1" }), {
          status: 200,
          headers: { "content-type": "application/json" },
        })) as typeof fetch;
      await linkWaitlistSignups({
        db: h.handle.db,
        referrals: true,
        newsletter: { apiKey: "re_test", segmentId: "seg", topicId: "top", fetch: fakeResend },
      });
      const [sub] = await h.tdb.admin<{ subscribed: boolean; changed_via: string }[]>`
        select subscribed, changed_via from public.newsletter_subscriptions where user_id = ${rae.id}::uuid`;
      expect(sub).toEqual({ subscribed: true, changed_via: "signup" });
      // Someone who said nothing about the monthly email is not signed up to it.
      const others = await h.tdb.admin`
        select 1 from public.newsletter_subscriptions s
        join auth.users u on u.id = s.user_id where u.email = 'friend-1@example.dev'`;
      expect(others).toHaveLength(0);
    });

    it("the account's export says how the person got in, and nothing about anyone else", async () => {
      const res = await h.request("/v1/me/export", { token: friend.token });
      expect(res.status).toBe(200);
      const files = unzipSync(new Uint8Array(await res.arrayBuffer()));
      const account = JSON.parse(strFromU8(files["account.json"] as Uint8Array));
      expect(account.waitlist).toMatchObject({ admitted_via: "invite", self_hosting: false });
      expect(JSON.stringify(account.waitlist)).not.toContain(ana.id);
    });

    it("the numbers add up by where people came from and how they got in", async () => {
      const stats = (await j(await h.request("/v1/admin/waitlist", { token: owner.token }))).stats;
      expect(stats.joined).toBeGreaterThanOrEqual(3);
      expect(stats.admitted).toBeGreaterThanOrEqual(stats.joined);
      const via = Object.fromEntries(stats.by_via.map((r: { key: string }) => [r.key, r]));
      expect(via.invite).toMatchObject({ admitted: 5, joined: 1 });
      expect(via["campaign:SHOWHN-TEST"]).toMatchObject({ admitted: 3, joined: 1 });
      expect(via["campaign:RACE-CODE"]).toMatchObject({ admitted: 3, joined: 0 });
      expect(stats.by_source.some((r: { key: string }) => r.key === "order")).toBe(true);
    });
  });

  it("a deleted account leaves no address behind, and its inbox can still come back", async () => {
    const gone = await h.user("goner@example.dev");
    await joinWaitlist(h.handle.db, { email: "goner@example.dev", note: "Remember me" });
    await h.tdb
      .admin`update public.waitlist_entries set status = 'admitted', admitted_at = now() where email = 'goner@example.dev'`;
    await linkWaitlistSignups({ db: h.handle.db, referrals: true });
    expect((await k.entry("goner@example.dev")).user_id).toBe(gone.id);
    await h.tdb.admin`delete from auth.users where id = ${gone.id}::uuid`;
    expect(await k.entry("goner@example.dev")).toMatchObject({
      email: "",
      note: null,
      ip_hash: null,
      user_id: null,
      status: "joined",
    });
    expect(await hookVerdict(await k.hook("goner@example.dev"))).toBe(200);
  });

  it("no new function can be called by someone signed in or signed out through the database API", async () => {
    const rows = await h.handle.db.execute<{ fn: string; role: string }>(sql`
      select p.proname as fn, r.rolname as role
      from pg_proc p cross join pg_roles r
      where p.pronamespace = 'public'::regnamespace
        and p.proname in ('signup_admitted', 'signup_invited_with_seat', 'invites_used',
          'invites_unlocked', 'invite_campaign_open', 'invite_code_preview', 'waitlist_claim',
          'worker_waitlist_link', 'worker_admitted_via')
        and r.rolname in ('anon', 'authenticated')
        and has_function_privilege(r.oid, p.oid, 'execute')`);
    expect([...rows]).toEqual([]);
  });
});

// --- Phases 2 and 3 (D-427): codes at sign-up, sign-in tokens, one-time codes, the daily batch ----

class Recorder implements ProductAnalytics {
  readonly enabled = true;
  events: CaptureOptions[] = [];
  capture(o: CaptureOptions) {
    this.events.push(o);
  }
  async flush() {}
  async close() {}
}

const sha256hex = (s: string) => createHash("sha256").update(s).digest("hex");

describe("codes at sign-up, sign-in tokens, one-time codes and the daily batch", () => {
  let h: Harness;
  const k = kit(() => h);
  let owner: U;
  const rec = new Recorder();
  const events = (name: string) => rec.events.filter((e) => e.event === name);
  type Key = Awaited<ReturnType<typeof generateKeyPair>>["privateKey"];
  let appleKey: Key;
  let googleKey: Key;
  let strayKey: Key;
  let appleJwk: JWK;
  let googleJwk: JWK;
  const fetched: string[] = [];
  const fakeFetch = (async (url: string | URL | Request) => {
    const u = String(url);
    fetched.push(u);
    const keys = u === JWKS_URLS.apple ? [appleJwk] : u === JWKS_URLS.google ? [googleJwk] : null;
    if (!keys) return new Response("no", { status: 404 });
    return Response.json({ keys }, { headers: { "cache-control": "public, max-age=600" } });
  }) as typeof fetch;
  const sign = (
    key: Key,
    kid: string,
    claims: Record<string, unknown>,
    exp: string | number = "10m",
  ) =>
    new SignJWT(claims)
      .setProtectedHeader({ alg: "RS256", kid })
      .setIssuedAt()
      .setExpirationTime(exp)
      .sign(key);
  const apple = (claims: Record<string, unknown> = {}, key?: Key, exp?: string | number) =>
    sign(
      key ?? appleKey,
      "apple-1",
      {
        iss: "https://appleid.apple.com",
        aud: "ai.casama.app",
        sub: "000123.abc",
        email: "x1y2z3@privaterelay.appleid.com",
        email_verified: "true",
        is_private_email: "true",
        nonce: sha256hex("raw-nonce-1"),
        ...claims,
      },
      exp,
    );
  const google = (claims: Record<string, unknown> = {}) =>
    sign(googleKey, "google-1", {
      iss: "https://accounts.google.com",
      aud: "ios.apps.googleusercontent.com",
      sub: "1098",
      email: "gina@gmail.com",
      email_verified: true,
      nonce: sha256hex("raw-nonce-2"),
      ...claims,
    });
  const redeemToken = async (json: Record<string, unknown>, from = ip()) =>
    h.request("/v1/waitlist/redeem", {
      method: "POST",
      headers: { "x-forwarded-for": from },
      json: { proof: await k.proof(), ...json },
    });
  const campaign = (json: Record<string, unknown>) =>
    h.request("/v1/admin/invite-campaigns", { method: "POST", token: owner.token, json });
  const send = () =>
    sendWaitlistInvites({
      db: h.handle.db,
      email: h.deps.email,
      env: h.deps.env,
      secret: internalToken(h.deps.env),
      perTick: 50,
    });

  beforeAll(async () => {
    resetSignupGateCache();
    h = await startHarness({
      env: {
        ...ENV,
        ABUSE_CONTROLS: "on",
        GOOGLE_AUTH_CLIENT_ID: "web.apps.googleusercontent.com,ios.apps.googleusercontent.com",
        INSTANCE_ADMIN_EMAILS: "p2-owner@example.dev",
      },
      email: true,
    });
    owner = await h.user("p2-owner@example.dev");
    await k.setGate(owner, { mode: "invite_only" });
    h.deps.idTokenFetch = fakeFetch;
    const a = await generateKeyPair("RS256");
    const g = await generateKeyPair("RS256");
    const x = await generateKeyPair("RS256");
    appleKey = a.privateKey;
    googleKey = g.privateKey;
    strayKey = x.privateKey;
    appleJwk = { ...(await exportJWK(a.publicKey)), kid: "apple-1", alg: "RS256", use: "sig" };
    googleJwk = { ...(await exportJWK(g.publicKey)), kid: "google-1", alg: "RS256", use: "sig" };
    expect((await campaign({ code: "SIGNUP-CODE", label: "At sign-up", max_uses: 1 })).status).toBe(
      200,
    );
    expect((await campaign({ code: "TOKEN-CODE", label: "Tokens", max_uses: 50 })).status).toBe(
      200,
    );
    setProductAnalytics(rec);
  }, 60_000);
  afterAll(async () => {
    setProductAnalytics(null);
    await h?.stop();
  });

  describe("a code sent with the sign-up (rule 4)", () => {
    const used = async (code: string) =>
      (
        await h.tdb.admin<{ used: number }[]>`
          select used from public.invite_campaigns where code = ${code}`
      )[0]?.used;

    it("lets a good code in on the spot, claimed exactly as the claim route does", async () => {
      const res = await k.hook("coded@example.dev", {
        provider: "google",
        inviteCode: "signup-code",
      });
      expect(await hookVerdict(res)).toBe(200);
      expect(await k.entry("coded@example.dev")).toMatchObject({
        status: "admitted",
        source: "signup",
        admitted_via: "campaign:SIGNUP-CODE",
        notified_at: null,
      });
      expect(await used("SIGNUP-CODE")).toBe(1);
      expect(events("invite_claimed").at(-1)?.properties).toEqual({
        kind: "campaign",
        outcome: "admitted",
        via: "signup",
      });
      // In now: the same address needs no code again, and uses up nothing.
      expect(await hookVerdict(await k.hook("coded@example.dev", { provider: "google" }))).toBe(
        200,
      );
      expect(
        await hookVerdict(
          await k.hook("coded@example.dev", { provider: "google", inviteCode: "SIGNUP-CODE" }),
        ),
      ).toBe(200);
      expect(await used("SIGNUP-CODE")).toBe(1);
    });

    it("a used-up code is refused with the usual sentence and puts the address near the front", async () => {
      const res = await k.hook("late@example.dev", {
        provider: "google",
        inviteCode: "SIGNUP-CODE",
      });
      expect(await hookVerdict(res)).toBe(403);
      expect((await j(res)).error.message).toContain("Casama Cloud is invite-only for now");
      expect(await k.entry("late@example.dev")).toMatchObject({
        status: "waiting",
        priority: 10,
        invite_code: "SIGNUP-CODE",
      });
      expect(events("signup_refused").at(-1)?.properties).toEqual({ reason: "code_used_up" });
    });

    it("an unknown code, a code that isn't text and a throwaway address are refused", async () => {
      const unknown = await k.hook("guess@example.dev", {
        provider: "google",
        inviteCode: "NOPE-NOPE",
      });
      expect(await hookVerdict(unknown)).toBe(403);
      expect(await k.entry("guess@example.dev")).toBeUndefined();
      expect(events("signup_refused").at(-1)?.properties).toEqual({ reason: "code_not_found" });
      expect(
        await hookVerdict(await k.hook("odd@example.dev", { provider: "google", inviteCode: 42 })),
      ).toBe(403);
      const before = await used("TOKEN-CODE");
      expect(
        await hookVerdict(
          await k.hook("me@mailinator.com", { provider: "google", inviteCode: "TOKEN-CODE" }),
        ),
      ).toBe(403);
      expect(await used("TOKEN-CODE")).toBe(before);
    });

    it("an email sign-up needs its proof before a code is spent, and the proof is used once", async () => {
      await campaign({ code: "PROOF-CODE", label: "Proof", max_uses: 5 });
      // No proof: refused by the proof check, and the code is untouched.
      const bare = await k.hook("bare@example.dev", { inviteCode: "PROOF-CODE" });
      expect(await hookVerdict(bare)).toBe(403);
      expect((await j(bare)).error.message).toContain("Sign-up needs a check from the app");
      expect(await used("PROOF-CODE")).toBe(0);
      expect(await k.entry("bare@example.dev")).toBeUndefined();
      // With a proof: let in, and the one proof covers both checks.
      const p = await k.proof();
      expect(
        await hookVerdict(
          await k.hook("proved@example.dev", {
            inviteCode: "PROOF-CODE",
            proof: { kind: "pow", ...p },
          }),
        ),
      ).toBe(200);
      expect(await used("PROOF-CODE")).toBe(1);
      // The same proof again is refused, even for the address it just let in.
      expect(
        await hookVerdict(await k.hook("proved@example.dev", { proof: { kind: "pow", ...p } })),
      ).toBe(403);
    });
  });

  describe("the \"You're in\" email's one-time code", () => {
    let code: string;

    it("each email carries one, and only its hash is kept", async () => {
      await joinWaitlist(h.handle.db, { email: "listed@example.dev" });
      const id = (await k.entry("listed@example.dev")).id;
      await h.request("/v1/admin/waitlist/admit", {
        method: "POST",
        token: owner.token,
        json: { ids: [id] },
      });
      expect(await send()).toBeGreaterThanOrEqual(1);
      const mail = h.outbox.find((m) => m.to === "listed@example.dev");
      code = /invite code ([0-9A-Z]{4}-[0-9A-Z]{4}) once/.exec(mail?.text ?? "")?.[1] ?? "";
      expect(code).toMatch(/^[0-9A-Z]{4}-[0-9A-Z]{4}$/);
      expect(mail?.text).toContain("Hide My Email");
      const row = await k.entry("listed@example.dev");
      expect(row.one_time_code_hash).toBe(sha256hex(code.replace("-", "")));
      expect(JSON.stringify(row)).not.toContain(code);
      expect(events("waitlist_admitted").at(-1)?.properties).toEqual({ via: "hand" });
    });

    it("lets in exactly one other address, however it is typed", async () => {
      const pv = await j(await h.request(`/v1/invites/preview?code=${code.toLowerCase()}`));
      expect(pv).toEqual({
        kind: "one_time",
        label: null,
        inviter_name: null,
        available: true,
        welcome_usd: 0,
      });
      const typed = code.toLowerCase().replace("-", "");
      const a = await k.redeem("q9w8e7@privaterelay.appleid.com", typed, { source: "app_ios" });
      expect(await j(a)).toEqual({ outcome: "admitted", kind: "one_time" });
      expect(
        await hookVerdict(await k.hook("q9w8e7@privaterelay.appleid.com", { provider: "apple" })),
      ).toBe(200);
      const issuer = await k.entry("listed@example.dev");
      expect(await k.entry("q9w8e7@privaterelay.appleid.com")).toMatchObject({
        status: "admitted",
        admitted_via: `one_time:${issuer.id}`,
        invite_code: "ONE-TIME",
      });
      expect(issuer.one_time_used_at).not.toBeNull();
      expect(events("invite_claimed").at(-1)?.properties).toEqual({
        kind: "one_time",
        outcome: "admitted",
        via: "app",
      });
      // Used: the next address goes on the list instead.
      expect(await j(await k.redeem("second@example.dev", code))).toEqual({
        outcome: "waitlisted",
        kind: "one_time",
      });
      expect((await k.entry("second@example.dev")).invite_code).toBe("ONE-TIME");
      expect((await j(await h.request(`/v1/invites/preview?code=${code}`))).available).toBe(false);
    });

    it("a campaign code of the same shape still works as a campaign", async () => {
      expect((await campaign({ code: "SHOW-HN26", label: "Same shape", max_uses: 1 })).status).toBe(
        200,
      );
      expect(await j(await k.redeem("shape@example.dev", "show-hn26"))).toEqual({
        outcome: "admitted",
        kind: "campaign",
      });
    });
  });

  describe("claiming with an Apple or Google sign-in token", () => {
    it("lets in the address inside a good Apple token, Hide My Email included", async () => {
      const res = await redeemToken({
        code: "TOKEN-CODE",
        provider: "apple",
        id_token: await apple(),
        token_nonce: "raw-nonce-1",
        source: "app_ios",
      });
      expect(res.status).toBe(200);
      expect(await j(res)).toEqual({ outcome: "admitted", kind: "campaign" });
      expect(
        await hookVerdict(await k.hook("x1y2z3@privaterelay.appleid.com", { provider: "apple" })),
      ).toBe(200);
      expect(events("invite_claimed").at(-1)?.properties).toMatchObject({ via: "id_token" });
      // The browser's token is for the Services ID.
      const web = await redeemToken({
        code: "TOKEN-CODE",
        provider: "apple",
        id_token: await apple({
          aud: "ai.casama.app.signin",
          email: "web@privaterelay.appleid.com",
        }),
        token_nonce: "raw-nonce-1",
      });
      expect((await j(web)).outcome).toBe("admitted");
    });

    it("and a good Google token for any client Auth takes", async () => {
      const res = await redeemToken({
        code: "TOKEN-CODE",
        provider: "google",
        id_token: await google(),
        token_nonce: "raw-nonce-2",
      });
      expect(await j(res)).toEqual({ outcome: "admitted", kind: "campaign" });
      expect(await hookVerdict(await k.hook("gina@gmail.com", { provider: "google" }))).toBe(200);
    });

    it("turns away a token that doesn't pass, and lets nobody in", async () => {
      const bad = async (
        provider: "apple" | "google",
        token: string,
        nonce: string | undefined,
        why: string,
      ) => {
        const res = await redeemToken({
          code: "TOKEN-CODE",
          provider,
          id_token: token,
          ...(nonce ? { token_nonce: nonce } : {}),
        });
        expect(res.status, why).toBe(400);
        expect((await j(res)).code, why).toBe("bad_id_token");
      };
      const who = { email: "nobody@privaterelay.appleid.com" };
      await bad("apple", await apple(who), "another-nonce", "wrong nonce");
      await bad("apple", await apple(who), undefined, "nonce in the token but none sent");
      await bad(
        "apple",
        await apple({ ...who, aud: "com.someone.else" }),
        "raw-nonce-1",
        "audience",
      );
      await bad(
        "apple",
        await apple({ ...who, iss: "https://evil.example" }),
        "raw-nonce-1",
        "issuer",
      );
      await bad(
        "apple",
        await apple(who, undefined, Math.floor(Date.now() / 1000) - 600),
        "raw-nonce-1",
        "expired",
      );
      await bad("apple", await apple(who, strayKey), "raw-nonce-1", "signed by someone else");
      await bad(
        "apple",
        await google({ email: who.email }),
        "raw-nonce-2",
        "Google's token as Apple's",
      );
      await bad(
        "google",
        await google({ email: "unverified@gmail.com", email_verified: false }),
        "raw-nonce-2",
        "unverified address",
      );
      await bad("google", await google({ email: undefined }), "raw-nonce-2", "no address");
      expect(await k.entry("nobody@privaterelay.appleid.com")).toBeUndefined();
      expect(await k.entry("unverified@gmail.com")).toBeUndefined();
    });

    it("takes an email or a token, not both, and a token needs its provider", async () => {
      const t = await apple();
      expect(
        (
          await redeemToken({
            code: "TOKEN-CODE",
            email: "a@example.dev",
            provider: "apple",
            id_token: t,
          })
        ).status,
      ).toBe(400);
      expect((await redeemToken({ code: "TOKEN-CODE", id_token: t })).status).toBe(400);
      expect((await redeemToken({ code: "TOKEN-CODE" })).status).toBe(400);
    });

    it("fetched each provider's keys once and kept them", () => {
      expect(fetched.filter((u) => u === JWKS_URLS.apple)).toHaveLength(1);
      expect(fetched.filter((u) => u === JWKS_URLS.google)).toHaveLength(1);
    });
  });

  it("the sign-in token check caches keys, follows a new key, and keeps old keys when offline", async () => {
    let t = Date.parse("2031-01-01T00:00:00Z");
    let jwks: JWK[] = [appleJwk];
    let down = false;
    let calls = 0;
    const v = new IdTokenVerifier({
      audiences: { apple: ["ai.casama.app"], google: [] },
      now: () => t,
      fetch: (async () => {
        calls++;
        if (down) throw new Error("offline");
        return Response.json({ keys: jwks }, { headers: { "cache-control": "max-age=600" } });
      }) as typeof fetch,
    });
    const at = (key: Key, kid: string) =>
      new SignJWT({
        iss: "https://appleid.apple.com",
        aud: "ai.casama.app",
        email: "cache@example.dev",
      })
        .setProtectedHeader({ alg: "RS256", kid })
        .setIssuedAt(Math.floor(t / 1000))
        .setExpirationTime(Math.floor(t / 1000) + 600)
        .sign(key);
    expect((await v.verify("apple", await at(appleKey, "apple-1"))).email).toBe(
      "cache@example.dev",
    );
    await v.verify("apple", await at(appleKey, "apple-1"));
    expect(calls).toBe(1);
    // Apple rotates to a new key: an unknown key id fetches again, but not more than every 30 s.
    const next = await generateKeyPair("RS256");
    jwks = [{ ...(await exportJWK(next.publicKey)), kid: "apple-2", alg: "RS256" }];
    t += 10_000;
    await expect(v.verify("apple", await at(next.privateKey, "apple-2"))).rejects.toThrow();
    expect(calls).toBe(1);
    t += 30_000;
    expect((await v.verify("apple", await at(next.privateKey, "apple-2"))).email).toBe(
      "cache@example.dev",
    );
    expect(calls).toBe(2);
    // Past max-age it asks again; when Apple can't be reached, the keys it has still work.
    t += 601_000;
    down = true;
    expect((await v.verify("apple", await at(next.privateKey, "apple-2"))).email).toBe(
      "cache@example.dev",
    );
    expect(calls).toBe(3);
    await expect(v.verify("google", "x.y.z")).rejects.toMatchObject({ reason: "unconfigured" });
  });

  describe("the daily batch", () => {
    const pushes: Array<{ user: string; kind: string; title: string; body: string }> = [];
    const notifications = {
      notify: async (
        user: string,
        _org: string | null,
        kind: string,
        m: { title: string; body: string },
      ) => {
        pushes.push({ user, kind, title: m.title, body: m.body });
        return null as never;
      },
    };
    const run = (iso: string, extra: Partial<Parameters<typeof runDailyBatch>[0]> = {}) =>
      runDailyBatch({
        db: h.handle.db,
        budgetMb: 9216,
        openRouterDailyCapUsd: 50,
        notifications,
        adminEmails: "p2-owner@example.dev",
        now: Date.parse(iso),
        ...extra,
      });
    const stats = async () =>
      (await j(await h.request("/v1/admin/waitlist", { token: owner.token }))).stats;

    it("does nothing while it's off, before its hour, or with the gate open", async () => {
      expect(await run("2031-03-01T16:00:00Z")).toBeNull(); // daily_admit is 0
      await k.setGate(owner, { daily_admit: 2, batch_hour_utc: 15, daily_emails_max: 1000 });
      expect(await run("2031-03-01T14:59:00Z")).toBeNull();
      await k.setGate(owner, { mode: "open" });
      expect(await run("2031-03-01T16:00:00Z")).toBeNull();
      await k.setGate(owner, { mode: "invite_only" });
    });

    it("chooses the day's number in batch order, once a day, and they get their emails", async () => {
      // Only these three are waiting, so the order is easy to see.
      await h.tdb
        .admin`update public.waitlist_entries set queued_at = now() where status = 'waiting'`;
      await h.tdb
        .admin`update public.waitlist_entries set notify_attempts = 8 where status = 'waiting'`;
      for (const [email, e] of [
        ["b-old@example.dev", {}],
        ["b-host@example.dev", { selfHosting: true }],
        ["b-new@example.dev", {}],
      ] as const)
        await joinWaitlist(h.handle.db, { email, ...e });
      const [a, b] = await Promise.all([run("2031-03-01T15:00:00Z"), run("2031-03-01T15:00:00Z")]);
      const r = a ?? b;
      expect([a, b].filter(Boolean)).toHaveLength(1);
      expect(r).toMatchObject({ day: "2031-03-01", admitted: 2, skipped: null });
      expect(await run("2031-03-01T23:00:00Z")).toBeNull();
      expect((await k.entry("b-host@example.dev")).admitted_via).toBe("auto");
      expect((await k.entry("b-old@example.dev")).queued_at).not.toBeNull();
      expect((await k.entry("b-new@example.dev")).queued_at).toBeNull();
      rec.events.length = 0;
      expect(await send()).toBe(2);
      expect(events("waitlist_admitted").map((e) => e.properties)).toEqual([
        { via: "batch" },
        { via: "batch" },
      ]);
      expect(h.outbox.filter((m) => m.to === "b-host@example.dev")).toHaveLength(1);
      expect((await stats()).last_batch).toMatchObject({
        day: "2031-03-01",
        admitted: 2,
        skipped_reason: null,
      });
    });

    it("never chooses more than the day's mail has room for", async () => {
      await joinWaitlist(h.handle.db, { email: "b-more@example.dev" });
      const s = await stats();
      await k.setGate(owner, { daily_admit: 5, daily_emails_max: s.emails_today + s.queued + 1 });
      expect(await run("2031-03-02T16:00:00Z")).toMatchObject({ admitted: 1, skipped: null });
      const s2 = await stats();
      await k.setGate(owner, { daily_emails_max: s2.emails_today + s2.queued });
      expect(await run("2031-03-03T16:00:00Z")).toMatchObject({ admitted: 0, skipped: "no_mail" });
      await k.setGate(owner, { daily_emails_max: 1000 });
      expect(pushes).toHaveLength(0);
    });

    it("skips a day after a busy one for computers, and tells the owner why", async () => {
      await h.tdb.admin`
        insert into public.capacity_samples (at, mem_total_mb, mem_available_mb, load1, cpus,
          computers_running, computers_mem_mb, budget_mb)
        values ('2031-03-04T19:00:00Z', 12288, 2000, 3.1, 6, 7, 7300, 9216),
               ('2031-03-04T09:00:00Z', 12288, 8000, 0.4, 6, 2, 2048, 9216)`;
      const before = (await stats()).queued;
      const r = await run("2031-03-05T16:00:00Z");
      expect(r).toMatchObject({ admitted: 0, skipped: "capacity" });
      expect(r?.detail).toContain("7 computers");
      expect((await stats()).queued).toBe(before);
      expect(pushes).toEqual([
        expect.objectContaining({
          user: owner.id,
          kind: "server_capacity",
          title: "Today's waitlist batch was skipped",
        }),
      ]);
      // Under 7 of 9: the day runs.
      await h.tdb.admin`
        insert into public.capacity_samples (at, mem_total_mb, mem_available_mb, load1, cpus,
          computers_running, computers_mem_mb, budget_mb)
        values ('2031-03-05T19:00:00Z', 12288, 4000, 2.0, 6, 6, 6144, 9216)`;
      expect((await run("2031-03-06T16:00:00Z"))?.skipped).not.toBe("capacity");
    });

    it("skips a day after model spend on Casama's key passed 60% of the daily cap", async () => {
      pushes.length = 0;
      const org = (
        await j(
          await h.request("/v1/orgs", {
            method: "POST",
            token: owner.token,
            json: { name: "Spend" },
          }),
        )
      ).id;
      // One model call's two rows: each carries the call's whole cost in meta ($32 here).
      const call = (at: string, usd: number) => {
        const meta = JSON.stringify({ key: "server", provider_cost_usd: usd });
        return h.handle.db.execute(sql`
          insert into public.usage_ledger (org_id, kind, quantity, cost_usd, upstream_cost_usd, billable, meta, created_at)
          values
            (${org}::uuid, 'tokens_in', 1000, 0, ${usd * 0.6 * 1.055}, true, ${meta}::jsonb, ${at}::timestamptz),
            (${org}::uuid, 'tokens_out', 100, 0, ${usd * 0.4 * 1.055}, true, ${meta}::jsonb, ${at}::timestamptz)`);
      };
      await call("2031-03-08T10:00:00Z", 20); // $20: under $30, counted once, not twice
      expect((await run("2031-03-09T16:00:00Z"))?.skipped).not.toBe("model_spend");
      await call("2031-03-09T10:00:00Z", 32);
      const r = await run("2031-03-10T16:00:00Z");
      expect(r).toMatchObject({ skipped: "model_spend" });
      expect(r?.detail).toContain("$32.00");
      expect(r?.detail).toContain("$50.00");
      expect(pushes).toHaveLength(1);
      expect((await stats()).last_batch).toMatchObject({
        day: "2031-03-10",
        skipped_reason: "model_spend",
      });
    });
  });

  it("Casama Help tells a member about their invites while Cloud is invite-only", async () => {
    const member = await h.user("helper@example.dev");
    await h.tdb.admin`
      insert into public.analytics_milestones (user_id, milestone) values (${member.id}::uuid, 'first_value')
      on conflict do nothing`;
    const code = (await j(await h.request("/v1/me/referral", { token: member.token }))).code;
    const claims = { sub: member.id, email: member.email } as JwtClaims;
    const lookups = supportLookups(h.handle.db, {} as never, {
      waitlist: { inviteBase: "https://casama.ai/invite" },
    });
    const out = await lookups.invites(claims, null);
    expect(out.cloud_invite_only).toMatchObject({
      my_invite_code: code,
      my_invite_link: `https://casama.ai/invite/${code}`,
      invites_total: 3,
      invites_used: 0,
      invites_left: 3,
      invites_unlocked: true,
    });
    // A server without the waitlist says nothing about it.
    const plain = await supportLookups(h.handle.db, {} as never).invites(claims, null);
    expect(plain.cloud_invite_only).toBeUndefined();
    // Nor does Cloud once the gate is open.
    await k.setGate(owner, { mode: "open" });
    expect((await lookups.invites(claims, null)).cloud_invite_only).toBeUndefined();
    await k.setGate(owner, { mode: "invite_only" });
  });

  it("events say how people got in, and never carry an address or a code", async () => {
    await k.join("joiner@example.dev", { source: "home", self_hosting: true });
    expect(events("waitlist_joined").at(-1)?.properties).toEqual({
      source: "home",
      self_hosting: true,
    });
    const n = events("waitlist_joined").length;
    await k.join("joiner@example.dev"); // already there: no second event
    expect(events("waitlist_joined")).toHaveLength(n);
    await k.hook("stranger-ev@example.dev", { provider: "google" });
    expect(events("signup_refused").at(-1)?.properties).toEqual({ reason: "gate" });
    // signed_up and first_value carry how the person got in.
    await h.user("coded@example.dev");
    await sweepSignups(h.handle.db, rec);
    const signup = events("signed_up").find((e) =>
      rec.events.length ? e.properties?.admitted_via === "code" : false,
    );
    expect(signup).toBeDefined();
    expect(events("signed_up").some((e) => e.properties?.admitted_via === "none")).toBe(true);
    for (const e of rec.events.filter((x) =>
      ["waitlist_joined", "invite_claimed", "waitlist_admitted", "signup_refused"].includes(
        x.event,
      ),
    )) {
      const text = JSON.stringify(e);
      expect(text, e.event).not.toContain("@");
      expect(text, e.event).not.toMatch(/SIGNUP-CODE|TOKEN-CODE|PROOF-CODE/);
      expect(e.personless, e.event).toBe(true);
    }
  });
});
