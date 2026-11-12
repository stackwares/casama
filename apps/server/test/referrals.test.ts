/** Invite friends (D-211): codes, redeeming, the public preview, and rewards for the inviter. */
import { strFromU8, unzipSync } from "fflate";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { clientIp } from "../src/api/util.ts";
import { normalizeReferralCode, sweepReferralRewards } from "../src/services/referrals.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

type U = { id: string; email: string; token: string };
let h: Harness;
let ana: U;
let ben: U;
let cy: U;
let dee: U;
let old: U;
let anaOrg: string;
let benOrg: string;
let deeOrg: string;

const redeem = (u: U, code: string) =>
  h.request("/v1/me/referral/redeem", { method: "POST", token: u.token, json: { code } });
const me = async (u: U) => j(await h.request("/v1/me/referral", { token: u.token }));
const qualify = async (u: U) => {
  await h.tdb.admin`update auth.users set email_confirmed_at = now() where id = ${u.id}::uuid`;
  await h.tdb
    .admin`insert into public.analytics_milestones (user_id, milestone) values (${u.id}::uuid, 'first_value')
    on conflict do nothing`;
};
const balance = async (org: string) =>
  Number(
    (
      await h.tdb.admin<{ b: string }[]>`
        select coalesce((select balance_after from public.credit_ledger where org_id = ${org}::uuid
          order by seq desc limit 1), 0) as b`
    )[0]?.b ?? 0,
  );
const cfg = { enabled: true, rewardUsd: 2, welcomeUsd: 1, cap: 2 };

beforeAll(async () => {
  h = await startHarness({
    env: { REFERRALS: "on", REFERRAL_REDEEM_DAYS: "7", REFERRAL_LINK_BASE: "https://casama.ai/i/" },
  });
  ana = await h.user("ana@example.dev");
  ben = await h.user("ben@example.dev");
  cy = await h.user("cy@example.dev");
  dee = await h.user("dee@example.dev");
  old = await h.user("old@example.dev");
  await h.tdb
    .admin`update public.profiles set display_name = 'Ana Reyes' where user_id = ${ana.id}::uuid`;
  await h.tdb
    .admin`update auth.users set created_at = now() - interval '30 days' where id = ${old.id}::uuid`;
  anaOrg = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: ana.token, json: { name: "Ana" } }),
    )
  ).id;
}, 60_000);
afterAll(() => h?.stop());

describe("codes", () => {
  it("reads codes however they're typed or linked", () => {
    expect(normalizeReferralCode("k7m 2qx")).toBe("K7M2QX");
    expect(normalizeReferralCode("https://casama.ai/i/K7M2QX?utm=x")).toBe("K7M2QX");
    expect(normalizeReferralCode("O1LIUA")).toBe("0111VA");
    expect(normalizeReferralCode("7F3Q-9XWD")).toBeNull();
  });

  it("gives everyone one code and link, the same every time", async () => {
    const a = await me(ana);
    expect(a).toMatchObject({ enabled: true, reward_cap: 20, invited: 0, invited_by: null });
    expect(a.code).toMatch(/^[0-9A-HJKMNP-TV-Z]{6}$/);
    expect(a.link).toBe(`https://casama.ai/i/${a.code}`);
    expect(a.redeem_until).toEqual(expect.any(String));
    expect((await me(ana)).code).toBe(a.code);
    expect((await me(old)).redeem_until).toBeNull();
  });

  it("previews a code without sign-in, with the first name only", async () => {
    const { code } = await me(ana);
    const ok = await h.request(`/v1/referral/preview?code=${code.toLowerCase()}`);
    expect(ok.status).toBe(200);
    expect(await ok.json()).toMatchObject({ inviter_name: "Ana", welcome_usd: 0 });
    // Someone with only the email fallback name isn't named.
    const { code: benCode } = await me(ben);
    expect(await j(await h.request(`/v1/referral/preview?code=${benCode}`))).toMatchObject({
      inviter_name: null,
    });
    expect((await h.request("/v1/referral/preview?code=ZZZZZZ")).status).toBe(404);
  });
});

describe("redeeming", () => {
  it("lets a new person enter a friend's code once", async () => {
    const { code } = await me(ana);
    const res = await redeem(ben, ` ${code.toLowerCase()} `);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { invited_by: unknown; redeem_until: unknown };
    expect(body.invited_by).toEqual({ name: "Ana", welcome_earned_usd: null });
    expect(body.redeem_until).toBeNull();
    expect((await redeem(ben, code)).status).toBe(409);
    expect(await me(ana)).toMatchObject({ invited: 1, pending: 1, rewarded: 0 });
  });

  it("refuses your own code, unknown codes, late redeems and inviting back", async () => {
    const { code } = await me(ana);
    const own = await redeem(ana, code);
    expect(own.status).toBe(400);
    expect(((await own.json()) as { code: string }).code).toBe("referral_own_code");
    expect((await redeem(cy, "ZZZZZZ")).status).toBe(404);
    expect((await redeem(cy, "nope")).status).toBe(404);
    const late = await redeem(old, code);
    expect(((await late.json()) as { code: string }).code).toBe("referral_window_closed");
    // Ben was invited by Ana, so Ana can't then use Ben's code.
    const { code: benCode } = await me(ben);
    expect(((await (await redeem(ana, benCode)).json()) as { code: string }).code).toBe(
      "referral_mutual",
    );
  });

  it("only shows people their own referrals", async () => {
    const [visible] = await h.tdb.admin.begin(async (tx) => {
      await tx`select set_config('request.jwt.claims', ${JSON.stringify({ sub: cy.id, role: "authenticated" })}, true)`;
      await tx`set local role authenticated`;
      return tx<{ n: number }[]>`select count(*)::int as n from public.referrals`;
    });
    expect(visible?.n).toBe(0);
  });
});

describe("rewards", () => {
  it("pays the inviter once the friend verified and finished a first run, up to the cap", async () => {
    const { code } = await me(ana);
    benOrg = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: ben.token, json: { name: "Ben" } }),
      )
    ).id;
    // Not real yet: nothing happens, and Ben's welcome bonus is still to come.
    expect(await sweepReferralRewards(h.handle.db, cfg)).toBe(0);
    expect((await me(ben)).invited_by).toEqual({ name: "Ana", welcome_earned_usd: null });
    await qualify(ben);
    expect(await sweepReferralRewards(h.handle.db, cfg)).toBe(1);
    expect(await balance(anaOrg)).toBe(2);
    // Ben gets his welcome bonus in his own workspace, and hears about it.
    expect(await balance(benOrg)).toBe(1);
    expect((await me(ben)).invited_by).toEqual({ name: "Ana", welcome_earned_usd: 1 });
    const [welcome] = await h.tdb.admin<{ payload: { title: string } }[]>`
      select payload from public.notifications where user_id = ${ben.id}::uuid and kind = 'referral_welcome'`;
    expect(welcome?.payload.title).toBe("Your welcome bonus is here");
    expect(await me(ana)).toMatchObject({ rewarded: 1, pending: 0, earned_usd: 2 });
    const [note] = await h.tdb.admin<{ kind: string; payload: { link: string } }[]>`
      select kind, payload from public.notifications where user_id = ${ana.id}::uuid and kind = 'referral_rewarded'`;
    expect(note?.payload.link).toBe("/settings/invite");
    // Running again pays nothing more.
    expect(await sweepReferralRewards(h.handle.db, cfg)).toBe(0);
    expect(await balance(anaOrg)).toBe(2);
    expect(await balance(benOrg)).toBe(1);

    // Two more friends with a cap of 2: the second is counted but Ana isn't paid. Dee still gets her
    // welcome bonus; Cy owns no workspace, so there's nowhere to put one.
    deeOrg = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: dee.token, json: { name: "Dee" } }),
      )
    ).id;
    for (const u of [cy, dee]) {
      expect((await redeem(u, code)).status).toBe(200);
      await qualify(u);
    }
    expect(await sweepReferralRewards(h.handle.db, cfg)).toBe(2);
    expect(await balance(anaOrg)).toBe(4);
    expect(await me(ana)).toMatchObject({ invited: 3, rewarded: 2, earned_usd: 4 });
    const statuses = await h.tdb.admin<{ status: string }[]>`
      select status from public.referrals where inviter_id = ${ana.id}::uuid order by status`;
    expect(statuses.map((s) => s.status)).toEqual(["capped", "rewarded", "rewarded"]);
    expect(await balance(deeOrg)).toBe(1);
    expect((await me(cy)).invited_by).toEqual({ name: "Ana", welcome_earned_usd: 0 });
    expect((await me(dee)).invited_by).toEqual({ name: "Ana", welcome_earned_usd: 1 });
  });

  it("does nothing when invites are off", async () => {
    expect(await sweepReferralRewards(h.handle.db, { ...cfg, enabled: false })).toBe(0);
  });
});

describe("audit fixes", () => {
  it("never leaves a referral stuck when the inviter owns no workspace", async () => {
    // Eve owns nothing and belongs nowhere: her friend is decided anyway and still gets a welcome.
    const eve = await h.user("eve@example.dev");
    const fay = await h.user("fay@example.dev");
    const fayOrg = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: fay.token, json: { name: "Fay" } }),
      )
    ).id;
    expect((await redeem(fay, (await me(eve)).code)).status).toBe(200);
    await qualify(fay);
    // Gus only belongs to Ana's workspace: his reward lands there.
    const gus = await h.user("gus@example.dev");
    const hal = await h.user("hal@example.dev");
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${anaOrg}::uuid, ${gus.id}::uuid, 'member')`;
    expect((await redeem(hal, (await me(gus)).code)).status).toBe(200);
    await qualify(hal);
    const before = await balance(anaOrg);
    expect(await sweepReferralRewards(h.handle.db, { ...cfg, cap: 20 })).toBe(2);
    const rows = await h.tdb.admin<
      { invitee_id: string; status: string; welcome_usd: string | null }[]
    >`
      select invitee_id, status, welcome_usd from public.referrals
      where invitee_id in (${fay.id}::uuid, ${hal.id}::uuid)`;
    const byId = Object.fromEntries(rows.map((r) => [r.invitee_id, r]));
    expect(byId[fay.id]).toMatchObject({ status: "none", welcome_usd: "1.00" });
    expect(byId[hal.id]?.status).toBe("rewarded");
    expect(await balance(fayOrg)).toBe(1);
    expect(await balance(anaOrg)).toBe(before + 2);
    // Nothing is left pending for the next sweep.
    expect(await sweepReferralRewards(h.handle.db, { ...cfg, cap: 20 })).toBe(0);
  });

  it("pays nothing to an inviter whose account is deleted or banned", async () => {
    const kim = await h.user("kim@example.dev");
    const kimOrg = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: kim.token, json: { name: "Kim" } }),
      )
    ).id;
    const lee = await h.user("lee@example.dev");
    expect((await redeem(lee, (await me(kim)).code)).status).toBe(200);
    await qualify(lee);
    await h.tdb.admin`update auth.users set banned_until = 'infinity' where id = ${kim.id}::uuid`;
    expect(await sweepReferralRewards(h.handle.db, { ...cfg, cap: 20 })).toBe(1);
    expect(await balance(kimOrg)).toBe(0);
    const [row] = await h.tdb.admin<{ status: string }[]>`
      select status from public.referrals where invitee_id = ${lee.id}::uuid`;
    expect(row?.status).toBe("none");
  });

  it("answers a second redeem at the same moment as already used, not a server error", async () => {
    const ivy = await h.user("ivy@example.dev");
    const { code } = await me(ana);
    const results = await Promise.all([redeem(ivy, code), redeem(ivy, code), redeem(ivy, code)]);
    const statuses = results.map((r) => r.status).sort();
    expect(statuses).toEqual([200, 409, 409]);
  });

  it("puts your invites in your data export without naming the friends", async () => {
    const res = await h.request("/v1/me/export", { token: ana.token });
    expect(res.status).toBe(200);
    const files = unzipSync(new Uint8Array(await res.arrayBuffer()));
    const account = JSON.parse(strFromU8(files["account.json"] as Uint8Array));
    expect(account.invites.code.code).toBe((await me(ana)).code);
    expect(account.invites.invited.length).toBeGreaterThan(0);
    expect(JSON.stringify(account.invites)).not.toContain(ben.id);
    const benExport = unzipSync(
      new Uint8Array(await (await h.request("/v1/me/export", { token: ben.token })).arrayBuffer()),
    );
    const benAccount = JSON.parse(strFromU8(benExport["account.json"] as Uint8Array));
    expect(benAccount.invites.joined_with).toMatchObject({ status: "rewarded" });
  });

  it("keeps redeeming and previews API-only (nothing callable through PostgREST)", async () => {
    const rows = await h.tdb.admin<{ role: string; fn: string; ok: boolean }[]>`
      select r as role, f as fn, has_function_privilege(r, f, 'execute') as ok
      from (values ('anon'), ('authenticated')) a(r),
           (values ('public.redeem_referral_for(uuid,text,integer)'), ('public.referral_preview(text)'),
                   ('public.referral_inviter_name(uuid)'), ('public.referral_credit_org(uuid)'),
                   ('public.worker_reward_referrals(numeric,numeric,integer,integer)')) b(f)`;
    expect(rows.filter((r) => r.ok)).toEqual([]);
    const [old] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from pg_proc where proname = 'redeem_referral'`;
    expect(old?.n).toBe(0);
  });

  it("reads the caller's address from the trusted edge header when one is set", () => {
    const headers: Record<string, string> = {
      "x-forwarded-for": "172.18.0.1",
      "cf-connecting-ip": "203.0.113.7",
    };
    const get = (n: string) => headers[n];
    expect(clientIp(get, "cf-connecting-ip")).toBe("203.0.113.7");
    // Without the setting, a client-sent CF header is ignored and Caddy's X-Forwarded-For wins.
    expect(clientIp(get)).toBe("172.18.0.1");
    expect(clientIp(() => undefined, "cf-connecting-ip")).toBe("unknown");
  });
});
