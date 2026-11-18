/** Joining a workspace (D-167): standing link, codes, preview, approvals, email invites, domains. */
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { normalizeCode, parseInvite } from "../src/api/routes/joining.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

type U = { id: string; token: string };
let h: Harness;
let alice: U;
let bob: U;
let carol: U;
let dave: U;
let gmail: U;
let org: string;

const confirm = (id: string) =>
  h.tdb.admin`update auth.users set email_confirmed_at = now() where id = ${id}::uuid`;
const notes = (userId: string, kind: string) =>
  h.tdb.admin<{ payload: { title: string; link: string } }[]>`
    select payload from public.notifications where user_id = ${userId}::uuid and kind = ${kind} order by created_at`;
const join = (u: U, invite: string) =>
  h.request("/v1/join", { method: "POST", token: u.token, json: { invite } });

beforeAll(async () => {
  h = await startHarness({
    env: {
      PUBLIC_APP_URL: "https://app.example.com",
      APPLE_APP_IDS: "TEAM123.ai.casama.app",
      ANDROID_CERT_SHA256: "AA:BB",
    },
  });
  alice = await h.user("alice@acme.dev");
  bob = await h.user("bob@acme.dev");
  carol = await h.user("carol@acme.dev");
  dave = await h.user("dave@other.dev");
  gmail = await h.user("someone@gmail.com");
  org = (
    await j(
      await h.request("/v1/orgs", {
        method: "POST",
        token: alice.token,
        json: { name: "Acme <Team>" },
      }),
    )
  ).id;
}, 60_000);
afterAll(() => h?.stop());

describe("parsing", () => {
  it("reads links, tokens and codes however they're typed", () => {
    expect(parseInvite("https://x.dev/join/kjoin_abcdefghijklmnopqrstuv")).toEqual({
      kind: "link",
      token: "kjoin_abcdefghijklmnopqrstuv",
    });
    expect(parseInvite("kinv_abcdefghijklmnopqrstuv")?.kind).toBe("email");
    expect(normalizeCode("7f3q 9xwd")).toBe("7F3Q9XWD");
    expect(normalizeCode("O1LI-ABCD")).toBe("0111ABCD");
    expect(parseInvite("https://x.dev/join/7F3Q-9XWD?x=1")).toEqual({
      kind: "code",
      token: "7F3Q9XWD",
    });
    expect(parseInvite("hello")).toBeNull();
  });
});

describe("the standing link", () => {
  it("is the same link every time until reset", async () => {
    const a = await j(await h.request(`/v1/orgs/${org}/default-invite`, { token: alice.token }));
    const b = await j(await h.request(`/v1/orgs/${org}/default-invite`, { token: alice.token }));
    expect(a.token).toMatch(/^kjoin_/);
    expect(b.token).toBe(a.token);
    expect(a.url).toBe(`https://app.example.com/join/${a.token}`);
    expect(a).toMatchObject({ is_default: true, role: "member", expires_at: null });
    expect((await h.request(`/v1/orgs/${org}/default-invite`, { token: bob.token })).status).toBe(
      403,
    );

    const reset = await j(
      await h.request(`/v1/orgs/${org}/default-invite`, {
        method: "PATCH",
        token: alice.token,
        json: { reset: true },
      }),
    );
    expect(reset.token).not.toBe(a.token);
    expect((await h.request(`/v1/join/preview?invite=${a.token}`)).status).toBe(404);
  });

  it("shows what it opens without signing in, then joins and tells the inviter", async () => {
    const link = await j(await h.request(`/v1/orgs/${org}/default-invite`, { token: alice.token }));
    const preview = await j(
      await h.request(`/v1/join/preview?invite=${encodeURIComponent(link.url)}`),
    );
    expect(preview).toMatchObject({
      kind: "link",
      workspace: { name: "Acme <Team>", member_count: 1 },
      role: "member",
      inviter_name: "alice",
      requires_approval: false,
      already_member: null,
    });
    const signedIn = await j(
      await h.request(`/v1/join/preview?invite=${link.token}`, { token: bob.token }),
    );
    expect(signedIn.already_member).toBe(false);

    const res = await j(await join(bob, link.url));
    expect(res).toMatchObject({
      status: "joined",
      workspace_name: "Acme <Team>",
      organization: { id: org, role: "member" },
    });
    expect((await j(await join(bob, link.token))).status).toBe("member");
    expect((await notes(alice.id, "member_joined"))[0]?.payload.title).toBe(
      "bob joined Acme <Team>",
    );
  });
});

describe("codes", () => {
  it("joins with a short code typed loosely, for 48 hours", async () => {
    const code = await j(
      await h.request(`/v1/orgs/${org}/invite-codes`, {
        method: "POST",
        token: alice.token,
        json: {},
      }),
    );
    expect(code.token).toMatch(/^[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$/);
    expect(code.kind).toBe("code");
    const hours = (Date.parse(code.expires_at) - Date.now()) / 3_600_000;
    expect(hours).toBeGreaterThan(47);
    expect(hours).toBeLessThanOrEqual(48);
    const typed = code.token.toLowerCase().replace("-", " ").replaceAll("0", "o");
    expect(
      (await j(await h.request(`/v1/join/preview?invite=${encodeURIComponent(typed)}`))).kind,
    ).toBe("code");
    expect((await j(await join(carol, typed))).status).toBe("joined");
  });

  it("caps wrong guesses", async () => {
    let last = 0;
    for (let i = 0; i < 11; i++) last = (await join(dave, "ZZZZ-ZZZZ")).status;
    expect(last).toBe(429);
  });
});

describe("asking to join", () => {
  let second: string;
  beforeAll(async () => {
    second = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: alice.token,
          json: { name: "Gated" },
        }),
      )
    ).id;
  });

  it("files a request that an admin approves", async () => {
    const link = await j(
      await h.request(`/v1/orgs/${second}/default-invite`, {
        method: "PATCH",
        token: alice.token,
        json: { requires_approval: true },
      }),
    );
    expect(link.requires_approval).toBe(true);
    expect(
      (await j(await h.request(`/v1/join/preview?invite=${link.token}`))).requires_approval,
    ).toBe(true);
    const res = await j(await join(bob, link.token));
    expect(res).toMatchObject({ status: "requested", workspace_name: "Gated" });
    expect(res.organization).toBeUndefined();
    expect((await j(await join(bob, link.token))).status).toBe("requested");
    expect((await notes(alice.id, "join_request")).at(-1)?.payload.title).toBe(
      "bob asked to join Gated",
    );

    const list = await j(
      await h.request(`/v1/orgs/${second}/join-requests`, { token: alice.token }),
    );
    expect(list.items).toHaveLength(1);
    expect(list.items[0]).toMatchObject({ email: "bob@acme.dev", status: "pending" });
    expect((await h.request(`/v1/orgs/${second}/join-requests`, { token: bob.token })).status).toBe(
      403,
    );

    const decided = await j(
      await h.request(`/v1/orgs/${second}/join-requests/${list.items[0].id}`, {
        method: "POST",
        token: alice.token,
        json: { approve: true },
      }),
    );
    expect(decided.status).toBe("approved");
    const orgs = await j(await h.request("/v1/orgs", { token: bob.token }));
    expect(orgs.items.map((o: { id: string }) => o.id)).toContain(second);
    expect((await notes(bob.id, "join_approved"))[0]?.payload.link).toBe(`/joined/${second}`);
  });

  it("can be declined", async () => {
    const link = await j(
      await h.request(`/v1/orgs/${second}/default-invite`, { token: alice.token }),
    );
    await join(carol, link.token);
    const [req] = (
      await j(await h.request(`/v1/orgs/${second}/join-requests`, { token: alice.token }))
    ).items;
    await h.request(`/v1/orgs/${second}/join-requests/${req.id}`, {
      method: "POST",
      token: alice.token,
      json: { approve: false },
    });
    const orgs = await j(await h.request("/v1/orgs", { token: carol.token }));
    expect(orgs.items.map((o: { id: string }) => o.id)).not.toContain(second);
    expect(
      (await j(await h.request(`/v1/orgs/${second}/join-requests`, { token: alice.token }))).items,
    ).toHaveLength(0);
  });
});

describe("email invites", () => {
  it("invites several at once, lists, resends and revokes", async () => {
    const res = await j(
      await h.request(`/v1/orgs/${org}/invites/batch`, {
        method: "POST",
        token: alice.token,
        json: { emails: ["new1@acme.dev", "NEW1@acme.dev", "new2@acme.dev"] },
      }),
    );
    expect(res.items).toHaveLength(2);
    expect(res.items[0].accept_token).toMatch(/^kinv_/);
    const pending = await j(await h.request(`/v1/orgs/${org}/invites`, { token: alice.token }));
    expect(pending.items.map((i: { email: string }) => i.email).sort()).toEqual([
      "new1@acme.dev",
      "new2@acme.dev",
    ]);

    const old = res.items[0].accept_token;
    const resent = await j(
      await h.request(`/v1/orgs/${org}/invites/${res.items[0].id}/resend`, {
        method: "POST",
        token: alice.token,
      }),
    );
    expect(resent.accept_token).not.toBe(old);
    expect((await h.request(`/v1/join/preview?invite=${old}`)).status).toBe(404);
    const preview = await j(await h.request(`/v1/join/preview?invite=${resent.accept_token}`));
    expect(preview).toMatchObject({ kind: "email", email_hint: "n•••@acme.dev" });

    const del = await h.request(`/v1/orgs/${org}/invites/${res.items[1].id}`, {
      method: "DELETE",
      token: alice.token,
    });
    expect(del.status).toBe(204);
    expect(
      (await j(await h.request(`/v1/orgs/${org}/invites`, { token: alice.token }))).items,
    ).toHaveLength(1);

    // The right person joins through the same endpoint; anyone else is told to switch accounts.
    expect((await join(gmail, resent.accept_token)).status).toBe(403);
    const new1 = await h.user("new1@acme.dev");
    expect(
      (await j(await join(new1, `https://app.example.com/join/${resent.accept_token}`))).status,
    ).toBe("joined");
  });
});

describe("email domains", () => {
  let gated: string;
  beforeAll(async () => {
    gated = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: alice.token,
          json: { name: "Acme HQ" },
        }),
      )
    ).id;
  });

  it("opens a workspace to the admin's own verified domain only", async () => {
    let d = await j(await h.request(`/v1/orgs/${gated}/join-domains`, { token: alice.token }));
    expect(d).toMatchObject({ items: [], my_domain: null, can_use: false });
    await confirm(alice.id);
    d = await j(await h.request(`/v1/orgs/${gated}/join-domains`, { token: alice.token }));
    expect(d).toMatchObject({ my_domain: "acme.dev", can_use: true });
    d = await j(
      await h.request(`/v1/orgs/${gated}/join-domains`, {
        method: "PUT",
        token: alice.token,
        json: { enabled: true },
      }),
    );
    expect(d.items).toEqual(["acme.dev"]);
  });

  it("lets verified people at that domain see and join it", async () => {
    // Unverified addresses see nothing.
    expect(
      (await j(await h.request("/v1/me/joinable-workspaces", { token: dave.token }))).items,
    ).toEqual([]);
    const fresh = await h.user("erin@acme.dev");
    expect(
      (await j(await h.request("/v1/me/joinable-workspaces", { token: fresh.token }))).items,
    ).toEqual([]);
    expect(
      (await h.request(`/v1/orgs/${gated}/join`, { method: "POST", token: fresh.token })).status,
    ).toBe(404);
    await confirm(fresh.id);
    const list = await j(await h.request("/v1/me/joinable-workspaces", { token: fresh.token }));
    expect(list.items).toEqual([
      expect.objectContaining({ id: gated, name: "Acme HQ", domain: "acme.dev" }),
    ]);
    const joined = await j(
      await h.request(`/v1/orgs/${gated}/join`, { method: "POST", token: fresh.token }),
    );
    expect(joined).toMatchObject({ id: gated, role: "member" });
    expect(
      (await j(await h.request("/v1/me/joinable-workspaces", { token: fresh.token }))).items,
    ).toEqual([]);
    expect((await notes(alice.id, "member_joined")).at(-1)?.payload.title).toContain(
      "joined Acme HQ",
    );
  });

  it("refuses shared domains such as gmail.com", async () => {
    await confirm(gmail.id);
    const own = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: gmail.token, json: { name: "Mine" } }),
      )
    ).id;
    const d = await j(await h.request(`/v1/orgs/${own}/join-domains`, { token: gmail.token }));
    expect(d).toMatchObject({ my_domain: "gmail.com", can_use: false });
    const put = await h.request(`/v1/orgs/${own}/join-domains`, {
      method: "PUT",
      token: gmail.token,
      json: { enabled: true },
    });
    expect(put.status).toBe(400);
  });
});

describe("web", () => {
  it("serves a join page that escapes the workspace name", async () => {
    const link = await j(await h.request(`/v1/orgs/${org}/default-invite`, { token: alice.token }));
    const res = await h.request(`/join/${link.token}`);
    expect(res.status).toBe(200);
    const html = await res.text();
    expect(html).toContain("Acme &lt;Team&gt;");
    expect(html).not.toContain("Acme <Team>");
    expect(html).toContain(`casama://app/join/${link.token}?server=`);
    expect(res.headers.get("content-security-policy")).toContain("default-src 'none'");
    expect((await h.request("/join/kjoin_nothing_here_at_all_123")).status).toBe(404);
  });

  it("publishes app-link files when configured", async () => {
    const aasa = await j(await h.request("/.well-known/apple-app-site-association"));
    expect(aasa.applinks.details[0].appIDs).toEqual(["TEAM123.ai.casama.app"]);
    const links = await j(await h.request("/.well-known/assetlinks.json"));
    expect(links[0].target).toMatchObject({
      package_name: "ai.casama.app",
      sha256_cert_fingerprints: ["AA:BB"],
    });
  });
});
