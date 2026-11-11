import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
beforeAll(async () => {
  h = await startHarness();
});
afterAll(() => h?.stop());

describe("system", () => {
  it("serves health, readiness and config without auth", async () => {
    expect((await h.request("/healthz")).status).toBe(200);
    const ready = await h.request("/readyz");
    expect(await j(ready)).toEqual({ status: "ok", checks: { database: "ok" } });
    const cfg = await j(await h.request("/v1/config"));
    expect(cfg).toMatchObject({
      product_name: "Kasama",
      supabase_anon_key: "anon",
      billing_enabled: false,
      wallpapers_enabled: false,
    });
  });

  it("serves the OpenAPI document and the reference page", async () => {
    const doc = await j(await h.request("/openapi.json"));
    expect(Object.keys(doc.paths)).toContain("/v1/orgs/{id}/invites");
    expect(doc.components.schemas.RunEvent).toBeDefined();
    expect((await h.request("/docs")).status).toBe(200);
  });

  it("returns problem JSON for unknown routes", async () => {
    const res = await h.request("/v1/nope");
    expect(res.status).toBe(404);
    expect(res.headers.get("content-type")).toContain("application/problem+json");
    expect(await j(res)).toMatchObject({ status: 404, code: "not_found" });
  });
});

describe("auth", () => {
  it("rejects missing and invalid tokens", async () => {
    const missing = await h.request("/v1/me");
    expect(missing.status).toBe(401);
    expect((await j(missing)).code).toBe("unauthorized");
    const bad = await h.request("/v1/me", { token: "not-a-jwt" });
    expect(bad.status).toBe(401);
    expect((await j(bad)).code).toBe("invalid_token");
  });
});

describe("workspaces (Phase 0 gate flow)", () => {
  it("creates a workspace, invites a member, and keeps orgs isolated", async () => {
    const owner = await h.user("owner@example.com");
    const friend = await h.user("friend@example.com");
    const stranger = await h.user("stranger@example.com");

    // Create
    const created = await h.request("/v1/orgs", {
      method: "POST",
      token: owner.token,
      json: { name: "Acme Team" },
    });
    expect(created.status).toBe(201);
    const org = await j(created);
    expect(org).toMatchObject({ name: "Acme Team", slug: "acme-team", plan: "selfhost" });

    // Same name again gets a suffixed slug
    const second = await j(
      await h.request("/v1/orgs", {
        method: "POST",
        token: stranger.token,
        json: { name: "Acme Team" },
      }),
    );
    expect(second.slug).toMatch(/^acme-team-[0-9a-f]{6}$/);

    // Explicit slug conflict
    const conflict = await h.request("/v1/orgs", {
      method: "POST",
      token: stranger.token,
      json: { name: "X", slug: "acme-team" },
    });
    expect(conflict.status).toBe(409);
    expect((await j(conflict)).code).toBe("slug_taken");

    // whoami
    const me = await j(await h.request("/v1/me", { token: owner.token }));
    expect(me).toMatchObject({ email: "owner@example.com", display_name: "owner" });
    expect(me.organizations).toEqual([
      expect.objectContaining({ slug: "acme-team", role: "owner" }),
    ]);

    // Stranger cannot invite into owner's org: org is invisible -> 404
    const denied = await h.request(`/v1/orgs/${org.id}/invites`, {
      method: "POST",
      token: stranger.token,
      json: { email: "x@example.com" },
    });
    expect(denied.status).toBe(404);

    // Invite (no email provider -> token returned)
    const inv = await h.request(`/v1/orgs/${org.id}/invites`, {
      method: "POST",
      token: owner.token,
      json: { email: "Friend@Example.com" },
    });
    expect(inv.status).toBe(201);
    const invite = await j(inv);
    expect(invite).toMatchObject({
      email: "friend@example.com",
      role: "member",
      email_sent: false,
    });
    expect(invite.accept_token).toMatch(/^kinv_[A-Za-z0-9_-]{43}$/);

    // Wrong user cannot accept
    const wrong = await h.request(`/v1/invites/${invite.accept_token}/accept`, {
      method: "POST",
      token: stranger.token,
    });
    expect(wrong.status).toBe(403);
    expect((await j(wrong)).code).toBe("invite_email_mismatch");

    // Friend accepts
    const acc = await h.request(`/v1/invites/${invite.accept_token}/accept`, {
      method: "POST",
      token: friend.token,
    });
    expect(acc.status).toBe(200);
    expect(await j(acc)).toMatchObject({ org_id: org.id, user_id: friend.id, role: "member" });

    // Single use
    const again = await h.request(`/v1/invites/${invite.accept_token}/accept`, {
      method: "POST",
      token: friend.token,
    });
    expect(again.status).toBe(404);

    // Member cannot invite
    const memberInvite = await h.request(`/v1/orgs/${org.id}/invites`, {
      method: "POST",
      token: friend.token,
      json: { email: "y@example.com" },
    });
    expect(memberInvite.status).toBe(403);

    // Isolation
    const strangerOrgs = await j(await h.request("/v1/orgs", { token: stranger.token }));
    expect(strangerOrgs.items.map((o: { slug: string }) => o.slug)).toEqual([second.slug]);
    const friendOrgs = await j(await h.request("/v1/orgs", { token: friend.token }));
    expect(friendOrgs.items).toEqual([expect.objectContaining({ id: org.id, role: "member" })]);
  });

  it("validates input with field errors", async () => {
    const u = await h.user("validator@example.com");
    const res = await h.request("/v1/orgs", { method: "POST", token: u.token, json: { name: "" } });
    expect(res.status).toBe(400);
    const body = await j(res);
    expect(body.code).toBe("validation_failed");
    expect(body.errors[0].path).toBe("name");
  });

  it("replays responses for a repeated Idempotency-Key", async () => {
    const u = await h.user("idem@example.com");
    const send = (key: string, path = "/v1/orgs") =>
      h.request(path, {
        method: "POST",
        token: u.token,
        json: { name: "Idem Org" },
        headers: { "idempotency-key": key },
      });
    const first = await send("key-1");
    const replay = await send("key-1");
    expect(replay.status).toBe(201);
    expect(replay.headers.get("idempotent-replayed")).toBe("true");
    expect(await j(replay)).toEqual(await j(first));
    const orgs = await j(await h.request("/v1/orgs", { token: u.token }));
    expect(orgs.items).toHaveLength(1);
  });
});

describe("invites with email", () => {
  it("emails the invite and hides the token", async () => {
    const eh = await startHarness({ email: true });
    try {
      const owner = await eh.user("o@example.com");
      const org = await j(
        await eh.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Mail Org" },
        }),
      );
      const invite = await j(
        await eh.request(`/v1/orgs/${org.id}/invites`, {
          method: "POST",
          token: owner.token,
          json: { email: "m@example.com", role: "admin" },
        }),
      );
      expect(invite).toMatchObject({ email_sent: true, role: "admin" });
      expect(invite.accept_token).toBeUndefined();
      expect(eh.outbox).toHaveLength(1);
      expect(eh.outbox[0]!.text).toContain("/join/kinv_");
    } finally {
      await eh.stop();
    }
  });
});

describe("rate limiting", () => {
  it("returns 429 with Retry-After", async () => {
    const rh = await startHarness({ rateLimit: 3 });
    try {
      const statuses = [];
      for (let i = 0; i < 4; i++) statuses.push((await rh.request("/v1/config")).status);
      expect(statuses).toEqual([200, 200, 200, 429]);
      const res = await rh.request("/v1/config");
      expect(Number(res.headers.get("retry-after"))).toBeGreaterThan(0);
    } finally {
      await rh.stop();
    }
  });
});
