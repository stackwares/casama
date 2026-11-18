/**
 * Casama's monthly email from the app (D-408): the switch, what Resend is told, retries when Resend
 * fails, the webhook that turns it off, email changes and account deletion.
 */
import { sql } from "drizzle-orm";
import { strFromU8, unzipSync } from "fflate";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import {
  applyResendEvent,
  newsletterConfig,
  svixSignature,
  syncDueNewsletters,
  verifySvix,
} from "../src/services/newsletter.ts";
import { purgeDueAccounts } from "../src/services/privacy.ts";
import { type Harness, startHarness } from "./helpers.ts";

const SECRET = `whsec_${Buffer.from("newsletter-webhook-test-secret").toString("base64")}`;
const SEGMENT = "bcf1b930-13c0-4bbc-a720-aa4cfd544e3c";
const TOPIC = "4b2d83b2-6f0a-4d6b-9981-de572951bf3c";

interface Call {
  method: string;
  path: string;
  body: unknown;
  auth: string | null;
}

/** A fake Resend: records every call; `down` makes every call fail with 503. */
function fakeResend() {
  const calls: Call[] = [];
  const state = { down: false };
  const fetchFn = (async (input: string | URL | Request, init?: RequestInit) => {
    const url = new URL(String(input));
    const headers = new Headers(init?.headers);
    calls.push({
      method: init?.method ?? "GET",
      path: decodeURIComponent(url.pathname),
      body: init?.body ? JSON.parse(String(init.body)) : undefined,
      auth: headers.get("authorization"),
    });
    if (state.down) return new Response("{}", { status: 503 });
    return Response.json({ object: "contact", id: "c_1" }, { status: 200 });
  }) as typeof fetch;
  return { calls, state, fetch: fetchFn };
}

const j = async (r: Response) => (await r.json()) as Record<string, unknown>;

function signed(body: string, now = Date.now()) {
  const id = `msg_${Math.random().toString(36).slice(2)}`;
  const ts = String(Math.floor(now / 1000));
  return {
    "svix-id": id,
    "svix-timestamp": ts,
    "svix-signature": `v1,${svixSignature(SECRET, id, ts, body)}`,
    "content-type": "application/json",
  };
}

describe("monthly email on Casama Cloud (D-408)", () => {
  let h: Harness;
  const resend = fakeResend();
  let ana: { id: string; email: string; token: string };
  let ben: { id: string; email: string; token: string };

  const row = async (userId: string) => {
    const [r] = await h.handle.db.execute<{
      subscribed: boolean;
      resend_email: string | null;
      sync_due: boolean;
      changed_via: string | null;
    }>(sql`select subscribed, resend_email, sync_due, changed_via
      from public.newsletter_subscriptions where user_id = ${userId}::uuid`);
    return r;
  };
  const put = (token: string, json: unknown) =>
    h.request("/v1/me/newsletter", { method: "PUT", token, json });

  beforeAll(async () => {
    h = await startHarness({
      env: { NEWSLETTER_RESEND_API_KEY: "re_test_key", NEWSLETTER_WEBHOOK_SECRET: SECRET },
      newsletterFetch: resend.fetch,
    });
    ana = await h.user("ana@example.com");
    ben = await h.user("ben@example.com");
    await h.handle.db.execute(
      sql`update auth.users set email_confirmed_at = now() where id in (${ana.id}::uuid, ${ben.id}::uuid)`,
    );
  });
  afterAll(async () => {
    await h.stop();
  });
  beforeEach(() => {
    resend.calls.length = 0;
    resend.state.down = false;
  });

  it("tells the apps it's offered, and starts off and unasked", async () => {
    expect((await j(await h.request("/v1/config"))).newsletter).toBe(true);
    const s = await j(await h.request("/v1/me/newsletter", { token: ana.token }));
    expect(s).toEqual({ available: true, subscribed: false, asked: false });
    expect(resend.calls).toHaveLength(0);
  });

  it("needs a signed-in person", async () => {
    expect((await h.request("/v1/me/newsletter")).status).toBe(401);
    expect((await h.request("/v1/me/newsletter", { method: "PUT", json: {} })).status).toBe(401);
  });

  it("turning it on adds the sign-in address to the segment and topic, source app", async () => {
    const s = await j(await put(ana.token, { subscribed: true, from: "settings" }));
    expect(s).toEqual({ available: true, subscribed: true, asked: true });
    const create = resend.calls.find((c) => c.method === "POST" && c.path === "/contacts");
    expect(create?.auth).toBe("Bearer re_test_key");
    expect(create?.body).toMatchObject({
      email: "ana@example.com",
      unsubscribed: false,
      segments: [{ id: SEGMENT }],
      topics: [{ id: TOPIC, subscription: "opt_in" }],
      properties: { signup_source: "app" },
    });
    expect(resend.calls.map((c) => `${c.method} ${c.path}`)).toEqual(
      expect.arrayContaining([
        "PATCH /contacts/ana@example.com",
        `POST /contacts/ana@example.com/segments/${SEGMENT}`,
        "PATCH /contacts/ana@example.com/topics",
      ]),
    );
    expect(resend.calls.find((c) => c.path.endsWith("/topics"))?.body).toEqual([
      { id: TOPIC, subscription: "opt_in" },
    ]);
    expect(await row(ana.id)).toMatchObject({
      subscribed: true,
      resend_email: "ana@example.com",
      sync_due: false,
      changed_via: "settings",
    });
  });

  it("turning it off marks the contact unsubscribed", async () => {
    const s = await j(await put(ana.token, { subscribed: false }));
    expect(s.subscribed).toBe(false);
    expect(resend.calls).toEqual([
      expect.objectContaining({
        method: "PATCH",
        path: "/contacts/ana@example.com",
        body: { unsubscribed: true },
      }),
    ]);
    expect((await row(ana.id))?.sync_due).toBe(false);
  });

  it("a Resend outage never breaks the save; the worker sends it later", async () => {
    resend.state.down = true;
    const res = await put(ana.token, { subscribed: true });
    expect(res.status).toBe(200);
    expect((await j(res)).subscribed).toBe(true);
    expect(await row(ana.id)).toMatchObject({ subscribed: true, sync_due: true });
    // Still down: the sweep tries and keeps it due.
    expect(await syncDueNewsletters(h.handle.db, newsletterConfig(h.deps.env, resend.fetch)!)).toBe(
      0,
    );
    expect((await row(ana.id))?.sync_due).toBe(true);
    resend.state.down = false;
    resend.calls.length = 0;
    expect(await syncDueNewsletters(h.handle.db, newsletterConfig(h.deps.env, resend.fetch)!)).toBe(
      1,
    );
    expect((await row(ana.id))?.sync_due).toBe(false);
    expect(resend.calls.some((c) => c.method === "POST" && c.path === "/contacts")).toBe(true);
  });

  it("closing the card only records that the app asked", async () => {
    const s = await j(await put(ben.token, { from: "card" }));
    expect(s).toEqual({ available: true, subscribed: false, asked: true });
    expect(resend.calls).toHaveLength(0);
  });

  it("an unconfirmed address waits instead of being added", async () => {
    const cleo = await h.user("cleo@example.com");
    await put(cleo.token, { subscribed: true, from: "signup" });
    expect(resend.calls).toHaveLength(0);
    expect(await row(cleo.id)).toMatchObject({ subscribed: true, sync_due: true });
  });

  it("someone else can't read or change your choice", async () => {
    // Ana is on; Ben's view and his change are his own.
    expect((await j(await h.request("/v1/me/newsletter", { token: ben.token }))).subscribed).toBe(
      false,
    );
    await put(ben.token, { subscribed: false });
    expect((await row(ana.id))?.subscribed).toBe(true);
  });

  it("is in the person's data export, without the address Resend has", async () => {
    const res = await h.request("/v1/me/export", { token: ana.token });
    expect(res.status).toBe(200);
    const files = unzipSync(new Uint8Array(await res.arrayBuffer()));
    const account = JSON.parse(strFromU8(files["account.json"] as Uint8Array));
    expect(account.newsletter).toMatchObject({ subscribed: true });
    expect(account.newsletter.resend_email).toBeUndefined();
  });

  it("an email change moves the contact to the new address", async () => {
    await h.handle.db.execute(
      sql`update auth.users set email = 'ana.new@example.com' where id = ${ana.id}::uuid`,
    );
    expect((await row(ana.id))?.sync_due).toBe(true);
    expect(await syncDueNewsletters(h.handle.db, newsletterConfig(h.deps.env, resend.fetch)!)).toBe(
      1,
    );
    const lines = resend.calls.map((c) => `${c.method} ${c.path}`);
    expect(lines[0]).toBe("DELETE /contacts/ana@example.com");
    expect(lines).toContain("PATCH /contacts/ana.new@example.com");
    expect(await row(ana.id)).toMatchObject({
      resend_email: "ana.new@example.com",
      sync_due: false,
    });
  });

  it("the webhook turns the switch off when they unsubscribe from an email", async () => {
    const body = JSON.stringify({
      type: "contact.updated",
      created_at: new Date(Date.now() + 1000).toISOString(),
      data: { email: "ANA.NEW@example.com", unsubscribed: true },
    });
    const res = await h.request("/hooks/newsletter/resend", {
      method: "POST",
      headers: signed(body),
      body,
    });
    expect(res.status).toBe(200);
    expect(await row(ana.id)).toMatchObject({ subscribed: false, changed_via: "email" });
    // Unsubscribing is Resend's own record: nothing is sent back.
    expect(resend.calls).toHaveLength(0);
  });

  it("a topic opt-out on Resend's preference page turns it off too", async () => {
    await put(ana.token, { subscribed: true });
    const event = {
      type: "contact.topics.updated",
      created_at: new Date(Date.now() + 1000).toISOString(),
      data: { email: "ana.new@example.com", topics: [{ id: TOPIC, subscription: "opt_out" }] },
    };
    expect(await applyResendEvent(h.handle.db, newsletterConfig(h.deps.env)!, event)).toBe(1);
    expect((await row(ana.id))?.subscribed).toBe(false);
  });

  it("a late webhook can't undo a newer choice in the app", async () => {
    await put(ana.token, { subscribed: true });
    const old = {
      type: "contact.updated",
      created_at: new Date(Date.now() - 60_000).toISOString(),
      data: { email: "ana.new@example.com", unsubscribed: true },
    };
    expect(await applyResendEvent(h.handle.db, newsletterConfig(h.deps.env)!, old)).toBe(0);
    expect((await row(ana.id))?.subscribed).toBe(true);
  });

  it("refuses an unsigned or forged webhook", async () => {
    const body = JSON.stringify({
      type: "contact.deleted",
      data: { email: "ana.new@example.com" },
    });
    expect((await h.request("/hooks/newsletter/resend", { method: "POST", body })).status).toBe(
      401,
    );
    const forged = { ...signed(body), "svix-signature": "v1,AAAA" };
    expect(
      (await h.request("/hooks/newsletter/resend", { method: "POST", headers: forged, body }))
        .status,
    ).toBe(401);
    const stale = signed(body, Date.now() - 3_600_000);
    expect(
      (await h.request("/hooks/newsletter/resend", { method: "POST", headers: stale, body }))
        .status,
    ).toBe(401);
    expect((await row(ana.id))?.subscribed).toBe(true);
  });

  it("deleting the account turns it off and removes the contact now, and again at the purge", async () => {
    const res = await h.request("/v1/me", {
      method: "DELETE",
      token: ana.token,
      json: { confirm_email: "ana.new@example.com" },
    });
    expect(res.status).toBe(200);
    expect(resend.calls.map((c) => `${c.method} ${c.path}`)).toContain(
      "DELETE /contacts/ana.new@example.com",
    );
    expect(await row(ana.id)).toMatchObject({ subscribed: false, resend_email: null });

    // A deletion while Resend is down is retried by the sweep.
    resend.state.down = true;
    await put(ben.token, { subscribed: true });
    resend.state.down = false;
    await put(ben.token, { subscribed: true });
    expect((await row(ben.id))?.resend_email).toBe("ben@example.com");
    resend.state.down = true;
    expect(
      (
        await h.request("/v1/me", {
          method: "DELETE",
          token: ben.token,
          json: { confirm_email: "ben@example.com" },
        })
      ).status,
    ).toBe(200);
    expect(await row(ben.id)).toMatchObject({
      subscribed: false,
      resend_email: "ben@example.com",
      sync_due: true,
    });
    resend.state.down = false;
    resend.calls.length = 0;
    // The purge removes what's still there before the account's rows go.
    await h.handle.db.execute(
      sql`update public.account_deletions set purge_after = now() - interval '1 minute' where user_id = ${ben.id}::uuid`,
    );
    const forgotten: string[] = [];
    await purgeDueAccounts(h.handle.db, undefined, {
      erase: async () => {},
      forgetNewsletter: async (id) => {
        forgotten.push(id);
        return true;
      },
    });
    expect(forgotten).toContain(ben.id);
    expect(await row(ben.id)).toBeUndefined();
  });
  it("deleting an account also removes a casama.ai sign-up with the same address", async () => {
    const dee = await h.user("dee@example.com");
    resend.calls.length = 0;
    expect(
      (
        await h.request("/v1/me", {
          method: "DELETE",
          token: dee.token,
          json: { confirm_email: "dee@example.com" },
        })
      ).status,
    ).toBe(200);
    expect(resend.calls.map((c) => `${c.method} ${c.path}`)).toEqual([
      "DELETE /contacts/dee@example.com",
    ]);
    expect(await row(dee.id)).toMatchObject({
      subscribed: false,
      resend_email: null,
      sync_due: false,
    });
  });
});

describe("monthly email on a self-hosted server (D-408)", () => {
  let h: Harness;
  const resend = fakeResend();
  beforeAll(async () => {
    // RESEND_API_KEY alone is for invite emails; it doesn't turn the newsletter on.
    h = await startHarness({
      env: { RESEND_API_KEY: "re_invites" },
      newsletterFetch: resend.fetch,
    });
  });
  afterAll(async () => {
    await h.stop();
  });

  it("hides it and never calls Resend", async () => {
    const u = await h.user("self@example.com");
    expect((await j(await h.request("/v1/config"))).newsletter).toBe(false);
    expect(await j(await h.request("/v1/me/newsletter", { token: u.token }))).toEqual({
      available: false,
      subscribed: false,
      asked: false,
    });
    expect(
      (
        await h.request("/v1/me/newsletter", {
          method: "PUT",
          token: u.token,
          json: { subscribed: true },
        })
      ).status,
    ).toBe(404);
    expect(
      (await h.request("/hooks/newsletter/resend", { method: "POST", body: "{}" })).status,
    ).toBe(404);
    expect(resend.calls).toHaveLength(0);
  });
});

describe("svix signatures", () => {
  it("accepts Resend's format and refuses changes to the body", () => {
    const body = '{"type":"contact.updated"}';
    const headers = new Headers(signed(body));
    expect(verifySvix(SECRET, headers, body)).toBe(true);
    expect(verifySvix(SECRET, headers, `${body} `)).toBe(false);
    expect(verifySvix(SECRET, new Headers(), body)).toBe(false);
  });
});
