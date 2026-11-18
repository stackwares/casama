/** The glance and widget keys (D-405): what a widget may read, and with what. */
import { GlancePusher, RecordingWidgetPushSender } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { hashWidgetKey, WIDGET_KEY_PER_HOUR, widgetCaller } from "../src/api/routes/glance.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let me: { id: string; token: string };
let stranger: { id: string; token: string };
let orgId = "";
let otherOrgId = "";
let key = "";
let keyId = "";
const widgets = new RecordingWidgetPushSender();

const widget = (path: string, init: RequestInit & { json?: unknown } = {}, k = key) =>
  h.request(path, { ...init, headers: { authorization: `Widget ${k}`, ...init.headers } });

beforeAll(async () => {
  h = await startHarness();
  h.deps.glance = new GlancePusher(h.handle.db, widgets, { urgentDelayMs: 10 });
  me = await h.user("widget-me@example.com");
  stranger = await h.user("widget-stranger@example.com");
  const org = async (token: string, name: string) =>
    (await j(await h.request("/v1/orgs", { method: "POST", token, json: { name } }))).id as string;
  orgId = await org(me.token, "Home");
  otherOrgId = await org(me.token, "Work");
  await h.request("/v1/bots", {
    method: "POST",
    token: me.token,
    json: { org_id: orgId, name: "Ada" },
  });
}, 600_000);

afterAll(async () => {
  h?.deps.glance?.stop();
  await h?.stop();
});

describe("widget keys", () => {
  it("are made with a session, shown once and stored only as a hash", async () => {
    const res = await h.request("/v1/widget-keys", {
      method: "POST",
      token: me.token,
      json: { org_id: orgId, platform: "ios", label: "Ana's iPhone" },
    });
    expect(res.status).toBe(201);
    const made = await j(res);
    expect(made.key).toMatch(/^cwk_[\w-]{43}$/);
    key = made.key;
    keyId = made.id;
    const [row] = await h.tdb.admin<{ key_hash: string; label: string }[]>`
      select key_hash, label from public.widget_keys where id = ${keyId}`;
    expect(row).toEqual({ key_hash: hashWidgetKey(key), label: "Ana's iPhone" });
    expect(row?.key_hash).not.toContain(key);

    // Not in a workspace someone isn't in.
    const outside = await h.request("/v1/widget-keys", {
      method: "POST",
      token: stranger.token,
      json: { org_id: orgId, platform: "android" },
    });
    expect(outside.status).toBe(404);
  });

  it("keep only the twenty most recent per person and workspace", async () => {
    for (let i = 0; i < 21; i++)
      await h.request("/v1/widget-keys", {
        method: "POST",
        token: me.token,
        json: { org_id: otherOrgId, platform: "android" },
      });
    const [n] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.widget_keys where user_id = ${me.id} and org_id = ${otherOrgId}`;
    expect(n?.n).toBe(20);
  });

  it("can be made private, and only by their person", async () => {
    const theirs = await h.request(`/v1/widget-keys/${keyId}`, {
      method: "PATCH",
      token: stranger.token,
      json: { private: true },
    });
    expect(theirs.status).toBe(404);
    const res = await h.request(`/v1/widget-keys/${keyId}`, {
      method: "PATCH",
      token: me.token,
      json: { private: true },
    });
    expect(res.status).toBe(200);
    expect(await j(res)).toMatchObject({
      id: keyId,
      private: true,
      has_push: false,
      platform: "ios",
    });
    expect(h.deps.glance?.pending(me.id).urgent).toBe(true);
    const g = await j(await widget("/v1/glance"));
    expect(g.flags.private).toBe(true);
    await h.request(`/v1/widget-keys/${keyId}`, {
      method: "PATCH",
      token: me.token,
      json: { private: false },
    });
  });

  it("can't make or change keys themselves", async () => {
    expect(
      (
        await widget("/v1/widget-keys", {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({ org_id: orgId, platform: "ios" }),
        })
      ).status,
    ).toBe(401);
    expect((await widget(`/v1/widget-keys/${keyId}`, { method: "DELETE" })).status).toBe(401);
  });
});

describe("the glance", () => {
  it("reads with a widget key, with an etag that answers 304", async () => {
    const res = await widget("/v1/glance");
    expect(res.status).toBe(200);
    const g = await j(res);
    expect(g.org_id).toBe(orgId);
    expect(g.bots.map((b: { name: string }) => b.name)).toContain("Ada");
    expect(res.headers.get("etag")).toBe(`"${g.version}"`);
    expect(res.headers.get("cache-control")).toBe("private, no-cache");
    const same = await widget("/v1/glance", { headers: { "if-none-match": `"${g.version}"` } });
    expect(same.status).toBe(304);
    expect(await same.text()).toBe("");
    const bare = await widget("/v1/glance", { headers: { "if-none-match": g.version } });
    expect(bare.status).toBe(304);
    const weak = await widget("/v1/glance", { headers: { "if-none-match": `W/"${g.version}"` } });
    expect(weak.status).toBe(304);
    const changed = await widget("/v1/glance", { headers: { "if-none-match": `"old"` } });
    expect(changed.status).toBe(200);
    const [row] = await h.tdb.admin<{ last_used_at: Date | null }[]>`
      select last_used_at from public.widget_keys where id = ${keyId}`;
    expect(row?.last_used_at).toBeTruthy();
  });

  it("reads only the key's workspace", async () => {
    expect((await widget(`/v1/glance?org_id=${orgId}`)).status).toBe(200);
    expect((await widget(`/v1/glance?org_id=${otherOrgId}`)).status).toBe(403);
  });

  it("reads with a session for a workspace the person is in", async () => {
    expect((await h.request("/v1/glance", { token: me.token })).status).toBe(400);
    const res = await h.request(`/v1/glance?org_id=${otherOrgId}`, { token: me.token });
    expect(res.status).toBe(200);
    expect((await j(res)).org_id).toBe(otherOrgId);
    expect((await h.request(`/v1/glance?org_id=${orgId}`, { token: stranger.token })).status).toBe(
      404,
    );
  });

  it("refuses a widget key everywhere else, and keys that don't exist", async () => {
    for (const path of ["/v1/me", `/v1/bots?org_id=${orgId}`, "/v1/orgs", "/v1/widget-keys"])
      expect((await widget(path)).status, path).toBe(401);
    const res = await widget("/v1/me");
    expect((await j(res)).code).toBe("widget_key_not_allowed");
    expect((await widget("/v1/glance", {}, "cwk_nope")).status).toBe(401);
    expect((await widget("/v1/glance", {}, "not-a-key")).status).toBe(401);
    expect((await h.request("/v1/glance")).status).toBe(401);
  });

  it("stops working once its person leaves the workspace or deletes it", async () => {
    const made = await j(
      await h.request("/v1/widget-keys", {
        method: "POST",
        token: me.token,
        json: { org_id: orgId, platform: "macos" },
      }),
    );
    expect((await widget("/v1/glance", {}, made.key)).status).toBe(200);
    expect(
      (await h.request(`/v1/widget-keys/${made.id}`, { method: "DELETE", token: stranger.token }))
        .status,
    ).toBe(404);
    const del = await h.request(`/v1/widget-keys/${made.id}`, {
      method: "DELETE",
      token: me.token,
    });
    expect(await j(del)).toEqual({ deleted: made.id });
    expect((await widget("/v1/glance", {}, made.key)).status).toBe(401);
  });
});

describe("push tokens", () => {
  it("are set by the widget key and checked against the device", async () => {
    const put = (json: unknown, k = key) =>
      widget(
        "/v1/widget-keys/current/push-token",
        {
          method: "PUT",
          headers: { "content-type": "application/json" },
          body: JSON.stringify(json),
        },
        k,
      );
    expect((await put({ token: "f".repeat(64), kind: "fcm" })).status).toBe(400);
    expect((await put({ token: "not hex at all!", kind: "apns_widgets" })).status).toBe(400);
    const ok = await put({ token: "ab".repeat(32), kind: "apns_widgets", sandbox: true });
    expect(ok.status).toBe(200);
    expect(await j(ok)).toEqual({ ok: true });
    const [row] = await h.tdb.admin<
      { push_token: string; push_kind: string; push_sandbox: boolean }[]
    >`
      select push_token, push_kind, push_sandbox from public.widget_keys where id = ${keyId}`;
    expect(row).toEqual({
      push_token: "ab".repeat(32),
      push_kind: "apns_widgets",
      push_sandbox: true,
    });
    const list = await j(
      await h.request(`/v1/widget-keys/${keyId}`, { method: "PATCH", token: me.token, json: {} }),
    );
    expect(list.has_push).toBe(true);
  });

  it("are set by the app with its session and the key's id, and move to a newer key", async () => {
    const made = await j(
      await h.request("/v1/widget-keys", {
        method: "POST",
        token: me.token,
        json: { org_id: orgId, platform: "ios" },
      }),
    );
    const path = "/v1/widget-keys/current/push-token";
    const json = { token: "ab".repeat(32), kind: "apns_widgets" };
    expect((await h.request(path, { method: "PUT", token: me.token, json })).status).toBe(400);
    expect(
      (await h.request(`${path}?key_id=${made.id}`, { method: "PUT", token: stranger.token, json }))
        .status,
    ).toBe(404);
    expect(
      (await h.request(`${path}?key_id=${made.id}`, { method: "PUT", token: me.token, json }))
        .status,
    ).toBe(200);
    const rows = await h.tdb.admin<{ id: string; push_token: string | null }[]>`
      select id, push_token from public.widget_keys where id in (${keyId}, ${made.id})`;
    expect(Object.fromEntries(rows.map((r) => [r.id, r.push_token]))).toEqual({
      [keyId]: null,
      [made.id]: "ab".repeat(32),
    });
  });
});

describe("covers", () => {
  it("a widget key reads covers in its own workspace only", async () => {
    const [bot] = await h.tdb.admin<{ id: string }[]>`
      select id from public.bots where org_id = ${orgId} limit 1`;
    const [mine] = await h.tdb.admin<{ id: string }[]>`
      insert into public.creations (org_id, bot_id, kind, title) values (${orgId}, ${bot!.id}, 'page', 'Mine') returning id`;
    const [workBot] = await h.tdb.admin<{ id: string }[]>`
      insert into public.bots (org_id, created_by, name) values (${otherOrgId}, ${me.id}, 'Wes') returning id`;
    const [work] = await h.tdb.admin<{ id: string }[]>`
      insert into public.creations (org_id, bot_id, kind, title) values (${otherOrgId}, ${workBot!.id}, 'page', 'Work') returning id`;
    // No cover stored in this test: "no_cover" means the key got past the workspace check.
    const own = await widget(`/v1/creations/${mine!.id}/cover`);
    expect(own.status).toBe(404);
    expect((await j(own)).code).toBe("no_cover");
    const other = await widget(`/v1/creations/${work!.id}/cover`);
    expect(other.status).toBe(404);
    expect((await j(other)).code).toBe("creation_not_found");
    // ...and nothing else about a creation.
    expect((await widget(`/v1/creations/${mine!.id}`)).status).toBe(401);
  });
});

describe("the hourly limit", () => {
  it("allows 120 requests an hour per key, then says when to come back", async () => {
    let t = 1_000_000;
    const check = widgetCaller({ db: h.handle.db }, { now: () => t });
    for (let i = 0; i < WIDGET_KEY_PER_HOUR; i++) await check("GET", "/v1/glance", key);
    const over = await check("GET", "/v1/glance", key).catch((e) => e);
    expect(over.status).toBe(429);
    expect(over.code).toBe("rate_limited");
    t += 3_600_000;
    await expect(check("GET", "/v1/glance", key)).resolves.toMatchObject({ id: keyId });
  });
});
