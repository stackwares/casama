/** Watches (D-410): signing a watch in, what a watch key may do, and its limits. */
import { randomBytes } from "node:crypto";
import { NotificationService, RecordingPushSender } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import {
  addressKey,
  hashWatchKey,
  normalizeWatchCode,
  WATCH_FAILED_KEYS_PER_MINUTE,
  WATCH_KEY_PER_MINUTE,
  WATCH_STREAM,
  WATCH_STREAMS_PER_KEY,
  watchCaller,
  windowCounter,
} from "../src/api/routes/watch.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let me: { id: string; email: string; token: string };
let member: { id: string; email: string; token: string };
let stranger: { id: string; email: string; token: string };
let orgId = "";
let otherOrgId = "";
let botId = "";
let otherBotId = "";
const push = new RecordingPushSender();

const newKey = () => `cwt_${randomBytes(32).toString("base64url")}`;
const key = newKey();
let keyId = "";

const watch = (path: string, init: RequestInit & { json?: unknown } = {}, k = key) =>
  h.request(path, { ...init, headers: { authorization: `Watch ${k}`, ...init.headers } });

const run = async (o: { by?: string; status?: string; bot?: string; org?: string } = {}) => {
  const [r] = await h.tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, trigger, status, created_by)
    values (${o.org ?? orgId}, ${o.bot ?? botId}, 'chat', ${o.status ?? "waiting_approval"},
            ${o.by ?? me.id}) returning id`;
  return r?.id as string;
};
const approval = async (o: {
  risk: "low" | "medium" | "high";
  tool?: string;
  args?: object;
  runBy?: string;
  bot?: string;
  org?: string;
}) => {
  const runId = await run({ by: o.runBy, bot: o.bot, org: o.org });
  const [a] = await h.tdb.admin<{ id: string }[]>`
    insert into public.approvals (org_id, bot_id, run_id, call_id, tool_name, args_redacted, summary, risk, expires_at)
    values (${o.org ?? orgId}, ${o.bot ?? botId}, ${runId}, 'c1', ${o.tool ?? "mail.send"},
            ${JSON.stringify(o.args ?? { to: "dana@example.com", subject: "Lunch" })}::jsonb,
            'Ada wants to run mail.send', ${o.risk}, now() + interval '1 hour') returning id`;
  return { id: a?.id as string, runId };
};
const decide = (id: string, decision: "approved" | "denied", always?: boolean) =>
  watch(`/v1/approvals/${id}/decision`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ decision, ...(always ? { always_allow: true } : {}) }),
  });

beforeAll(async () => {
  h = await startHarness();
  h.deps.notifications = new NotificationService(h.handle.db, push);
  me = await h.user("watch-me@example.com");
  member = await h.user("watch-member@example.com");
  stranger = await h.user("watch-stranger@example.com");
  const org = async (token: string, name: string) =>
    (await j(await h.request("/v1/orgs", { method: "POST", token, json: { name } }))).id as string;
  orgId = await org(me.token, "Home");
  otherOrgId = await org(me.token, "Work");
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
  const bot = async (org: string, name: string) =>
    (
      await j(
        await h.request("/v1/bots", {
          method: "POST",
          token: me.token,
          json: { org_id: org, name },
        }),
      )
    ).id as string;
  botId = await bot(orgId, "Ada");
  otherBotId = await bot(otherOrgId, "Bea");
  await h.tdb.admin`update public.profiles set preferred_name = 'Ana' where user_id = ${me.id}`;
}, 600_000);

afterAll(async () => {
  await h?.stop();
});

describe("signing a watch in from the phone", () => {
  it("registers the fingerprint, never the key, and lists it", async () => {
    const res = await h.request("/v1/watch-keys", {
      method: "POST",
      token: me.token,
      json: {
        org_id: orgId,
        fingerprint: hashWatchKey(key),
        platform: "watchos",
        name: "Ana's Apple Watch",
        model: "Apple Watch Series 10",
      },
    });
    expect(res.status).toBe(201);
    const made = await j(res);
    expect(made).toMatchObject({
      org_id: orgId,
      platform: "watchos",
      name: "Ana's Apple Watch",
      paired_by: "phone",
      has_push: false,
    });
    expect(made).not.toHaveProperty("fingerprint");
    keyId = made.id;
    const list = await j(await h.request(`/v1/watch-keys?org_id=${orgId}`, { token: me.token }));
    expect(list.items.map((k: { id: string }) => k.id)).toEqual([keyId]);
    // Registering again updates it.
    const again = await h.request("/v1/watch-keys", {
      method: "POST",
      token: me.token,
      json: { org_id: orgId, fingerprint: hashWatchKey(key), platform: "watchos", name: "Wrist" },
    });
    expect((await j(again)).id).toBe(keyId);
  });

  it("refuses a workspace the person isn't in and a fingerprint someone else has", async () => {
    const outside = await h.request("/v1/watch-keys", {
      method: "POST",
      token: stranger.token,
      json: { org_id: orgId, fingerprint: hashWatchKey(newKey()), platform: "wearos", name: "W" },
    });
    expect(outside.status).toBe(404);
    const strangerOrg = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: stranger.token, json: { name: "S" } }),
      )
    ).id;
    const taken = await h.request("/v1/watch-keys", {
      method: "POST",
      token: stranger.token,
      json: { org_id: strangerOrg, fingerprint: hashWatchKey(key), platform: "watchos", name: "W" },
    });
    expect(taken.status).toBe(409);
    expect((await j(taken)).code).toBe("watch_key_taken");
  });

  it("keeps ten watches per person and workspace", async () => {
    for (let i = 0; i < 11; i++)
      await h.request("/v1/watch-keys", {
        method: "POST",
        token: me.token,
        json: {
          org_id: otherOrgId,
          fingerprint: hashWatchKey(newKey()),
          platform: "wearos",
          name: `W${i}`,
        },
      });
    const [n] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.watch_keys where user_id = ${me.id} and org_id = ${otherOrgId}`;
    expect(n?.n).toBe(10);
  });

  it("removes a watch only for its person", async () => {
    const k = newKey();
    const made = await j(
      await h.request("/v1/watch-keys", {
        method: "POST",
        token: me.token,
        json: { org_id: orgId, fingerprint: hashWatchKey(k), platform: "wearos", name: "Old" },
      }),
    );
    expect(
      (await h.request(`/v1/watch-keys/${made.id}`, { method: "DELETE", token: stranger.token }))
        .status,
    ).toBe(404);
    expect((await watch("/v1/watch/me", {}, k)).status).toBe(200);
    expect(
      (await h.request(`/v1/watch-keys/${made.id}`, { method: "DELETE", token: me.token })).status,
    ).toBe(200);
    const gone = await watch("/v1/watch/me", {}, k);
    expect(gone.status).toBe(401);
    expect((await j(gone)).code).toBe("invalid_watch_key");
  });
});

describe("watch settings", () => {
  it("default, change and go back to the built-in replies", async () => {
    const d = await j(await h.request("/v1/watch-prefs", { token: me.token }));
    expect(d).toEqual({
      allow: "medium",
      show_details: true,
      quick_replies: ["Yes", "No", "Tell me more", "Not now"],
    });
    const set = await j(
      await h.request("/v1/watch-prefs", {
        method: "PATCH",
        token: me.token,
        json: { allow: "low", quick_replies: ["On my way", "Later"] },
      }),
    );
    expect(set).toEqual({
      allow: "low",
      show_details: true,
      quick_replies: ["On my way", "Later"],
    });
    const keep = await j(
      await h.request("/v1/watch-prefs", {
        method: "PATCH",
        token: me.token,
        json: { show_details: false },
      }),
    );
    expect(keep.quick_replies).toEqual(["On my way", "Later"]);
    const back = await j(
      await h.request("/v1/watch-prefs", {
        method: "PATCH",
        token: me.token,
        json: { allow: "medium", show_details: true, quick_replies: [] },
      }),
    );
    expect(back).toEqual(d);
  });

  it("are the phone's: a watch can't read or change them", async () => {
    const res = await watch("/v1/watch-prefs");
    expect(res.status).toBe(403);
    expect((await j(res)).code).toBe("watch_key_not_allowed");
  });
});

describe("signing in with a code", () => {
  const codeKey = newKey();
  let code = "";

  it("gives a signed-out watch a code, five an hour per address", async () => {
    const res = await h.request("/v1/watch/codes", {
      method: "POST",
      headers: { "x-forwarded-for": "203.0.113.9" },
      json: { fingerprint: hashWatchKey(codeKey), platform: "wearos", name: "Pixel Watch 3" },
    });
    expect(res.status).toBe(201);
    const c = await j(res);
    expect(c.code).toMatch(/^[2-9A-HJKMNP-Z]{8}$/);
    expect(c.poll_every_s).toBe(5);
    code = c.code;
    const [row] = await h.tdb.admin<{ code_hash: string }[]>`
      select code_hash from public.watch_key_requests where key_hash = ${hashWatchKey(codeKey)}`;
    expect(row?.code_hash).not.toContain(code);
    // Not signed in yet: the watch is told it's still waiting.
    const waiting = await watch("/v1/watch/me", {}, codeKey);
    expect(waiting.status).toBe(401);
    expect((await j(waiting)).code).toBe("watch_code_pending");
  });

  it("shows the phone which watch it is, then signs it in as the person", async () => {
    const shown = `${code.slice(0, 4).toLowerCase()}-${code.slice(4)}`;
    expect(normalizeWatchCode(shown)).toBe(code);
    const info = await h.request(`/v1/watch-codes/${shown}`, { token: me.token });
    expect(info.status).toBe(200);
    expect(await j(info)).toMatchObject({ platform: "wearos", name: "Pixel Watch 3", model: null });
    // Looking the right code up doesn't use it up, however often (a sheet opened twice, a retry).
    for (let i = 0; i < 6; i++)
      expect((await h.request(`/v1/watch-codes/${code}`, { token: me.token })).status).toBe(200);
    expect((await j(await watch("/v1/watch/me", {}, codeKey))).code).toBe("watch_code_pending");
    const claimed = await h.request(`/v1/watch-codes/${code}/claim`, {
      method: "POST",
      token: me.token,
      json: { org_id: orgId },
    });
    expect(claimed.status).toBe(201);
    expect(await j(claimed)).toMatchObject({ paired_by: "code", platform: "wearos" });
    const self = await watch("/v1/watch/me", {}, codeKey);
    expect(self.status).toBe(200);
    // A code works once.
    const again = await h.request(`/v1/watch-codes/${code}/claim`, {
      method: "POST",
      token: me.token,
      json: { org_id: orgId },
    });
    expect(again.status).toBe(404);
    expect((await j(again)).code).toBe("watch_code_not_found");
    // The phone registering the watch again later (a workspace switch) keeps how it was signed in.
    const later = await j(
      await h.request("/v1/watch-keys", {
        method: "POST",
        token: me.token,
        json: {
          org_id: orgId,
          fingerprint: hashWatchKey(codeKey),
          platform: "wearos",
          name: "Pixel Watch 3",
        },
      }),
    );
    expect(later.paired_by).toBe("code");
  });

  it("stops telling a watch to wait once its code ran out", async () => {
    const k = newKey();
    const made = await h.request("/v1/watch/codes", {
      method: "POST",
      headers: { "x-forwarded-for": "203.0.113.77" },
      json: { fingerprint: hashWatchKey(k), platform: "watchos", name: "Late" },
    });
    expect(made.status).toBe(201);
    expect((await j(await watch("/v1/watch/me", {}, k))).code).toBe("watch_code_pending");
    await h.tdb.admin`update public.watch_key_requests set expires_at = now() - interval '1 second'
      where key_hash = ${hashWatchKey(k)}`;
    const late = await watch("/v1/watch/me", {}, k);
    expect(late.status).toBe(401);
    expect((await j(late)).code).toBe("invalid_watch_key");
    expect(
      (await h.request(`/v1/watch-codes/${(await j(made)).code}`, { token: me.token })).status,
    ).toBe(404);
  });

  it("stops after five wrong codes in an hour", async () => {
    let last = 0;
    for (let i = 0; i < 5; i++)
      last = (await h.request("/v1/watch-codes/ZZZZZZZZ", { token: stranger.token })).status;
    expect(last).toBe(404);
    const blocked = await h.request("/v1/watch-codes/ZZZZZZZZ", { token: stranger.token });
    expect(blocked.status).toBe(429);
    expect(blocked.headers.get("retry-after")).toBeTruthy();
  });

  it("five codes an hour per address", async () => {
    let last = 0;
    for (let i = 0; i < 5; i++)
      last = (
        await h.request("/v1/watch/codes", {
          method: "POST",
          headers: { "x-forwarded-for": "198.51.100.7" },
          json: { fingerprint: hashWatchKey(newKey()), platform: "watchos", name: "W" },
        })
      ).status;
    expect(last).toBe(201);
    // The harness may not trust forwarded addresses; either way the sixth from one place is refused.
    const sixth = await h.request("/v1/watch/codes", {
      method: "POST",
      headers: { "x-forwarded-for": "198.51.100.7" },
      json: { fingerprint: hashWatchKey(newKey()), platform: "watchos", name: "W" },
    });
    expect(sixth.status).toBe(429);
  });
});

describe("a watch key", () => {
  it("says who it is, its settings and what the server can do", async () => {
    const res = await watch("/v1/watch/me");
    expect(res.status).toBe(200);
    expect(await j(res)).toMatchObject({
      key_id: keyId,
      org_id: orgId,
      org_name: "Home",
      person: { name: "Ana" },
      prefs: { allow: "medium", show_details: true },
      hide_reply_text: false,
      ask_bot_id: botId,
      features: { dictation: false, speech: false, out_of_credits: false },
    });
  });

  it("may use only the watch's routes, and not the phone's", async () => {
    for (const [method, path] of [
      ["GET", "/v1/bots"],
      ["GET", `/v1/watch-keys?org_id=${orgId}`],
      ["POST", "/v1/watch-keys"],
      ["DELETE", `/v1/watch-keys/${keyId}`],
      ["DELETE", "/v1/watch-keys"],
      ["GET", "/v1/me"],
    ] as const) {
      const res = await watch(path, { method });
      expect(res.status, `${method} ${path}`).toBe(403);
      expect((await j(res)).code).toBe("watch_key_not_allowed");
    }
    const config = await j(await watch("/v1/config"));
    expect(config.watch).toBe(true);
  });

  it("counts keys that don't work per address, before looking them up", async () => {
    const call = watchCaller({ db: h.handle.db }, { now: () => 0 });
    for (let i = 0; i < WATCH_FAILED_KEYS_PER_MINUTE; i++)
      await expect(call("GET", "/v1/watch/me", newKey(), "192.0.2.1")).rejects.toMatchObject({
        status: 401,
      });
    await expect(call("GET", "/v1/watch/me", newKey(), "192.0.2.1")).rejects.toMatchObject({
      status: 429,
    });
    // Even a working key from there waits; another address doesn't.
    await expect(call("GET", "/v1/watch/me", key, "192.0.2.1")).rejects.toMatchObject({
      status: 429,
    });
    await expect(call("GET", "/v1/watch/me", key, "192.0.2.2")).resolves.toMatchObject({
      id: keyId,
    });
    // Working keys are given back: they never use up an address's budget.
    for (let i = 0; i < WATCH_FAILED_KEYS_PER_MINUTE + 5; i++)
      await call("GET", "/v1/watch/me", key, "192.0.2.3");
  });

  it("doesn't lock out a watch that works when junk keys come from its address", async () => {
    const call = watchCaller({ db: h.handle.db }, { now: () => 0 });
    // The watch is in use at this address (shared Wi-Fi, a carrier's network)...
    await call("GET", "/v1/watch/me", key, "192.0.2.10");
    // ...then someone there sends junk until the address is over its limit.
    for (let i = 0; i < WATCH_FAILED_KEYS_PER_MINUTE; i++)
      await expect(call("GET", "/v1/glance", newKey(), "192.0.2.10")).rejects.toMatchObject({
        status: 401,
      });
    await expect(call("GET", "/v1/glance", newKey(), "192.0.2.10")).rejects.toMatchObject({
      status: 429,
    });
    // The watch that worked a moment ago still does; a key never seen here waits like the junk.
    await expect(call("GET", "/v1/watch/me", key, "192.0.2.10")).resolves.toMatchObject({
      id: keyId,
    });
    const fresh = newKey();
    await h.request("/v1/watch-keys", {
      method: "POST",
      token: me.token,
      json: { org_id: orgId, fingerprint: hashWatchKey(fresh), platform: "wearos", name: "New" },
    });
    await expect(call("GET", "/v1/watch/me", fresh, "192.0.2.10")).rejects.toMatchObject({
      status: 429,
    });
    // Once removed, a key that worked counts like any other again.
    const [gone] = await h.tdb.admin<{ id: string }[]>`
      select id from public.watch_keys where key_hash = ${hashWatchKey(fresh)}`;
    await call("GET", "/v1/watch/me", fresh, "192.0.2.11");
    await h.request(`/v1/watch-keys/${gone?.id}`, { method: "DELETE", token: me.token });
    await expect(call("GET", "/v1/watch/me", fresh, "192.0.2.11")).rejects.toMatchObject({
      status: 401,
      code: "invalid_watch_key",
    });
  });

  it("doesn't count watches waiting on a code against their address", async () => {
    const call = watchCaller({ db: h.handle.db }, { now: () => 0 });
    const waiting = newKey();
    await h.tdb.admin`insert into public.watch_key_requests (code_hash, key_hash, platform, name)
      values (${"c".repeat(64)}, ${hashWatchKey(waiting)}, 'wearos', 'Waiting')`;
    // Three watches signing in at one address ask every five seconds: far more than thirty a minute.
    for (let i = 0; i < WATCH_FAILED_KEYS_PER_MINUTE + 10; i++)
      await expect(call("GET", "/v1/watch/me", waiting, "192.0.2.20")).rejects.toMatchObject({
        status: 401,
        code: "watch_code_pending",
      });
    // The address still has its whole budget for keys that don't work.
    await expect(call("GET", "/v1/watch/me", newKey(), "192.0.2.20")).rejects.toMatchObject({
      status: 401,
      code: "invalid_watch_key",
    });
    // One watch asking without end is held to its own minute.
    let last: unknown;
    for (let i = 0; i < WATCH_KEY_PER_MINUTE; i++)
      last = await call("GET", "/v1/watch/me", waiting, "192.0.2.20").catch((e) => e);
    expect(last).toMatchObject({ status: 429 });
    await h.tdb
      .admin`delete from public.watch_key_requests where key_hash = ${hashWatchKey(waiting)}`;
  });

  it("counts an IPv6 network as one address and keeps its counters bounded", () => {
    expect(addressKey("203.0.113.9")).toBe("203.0.113.9");
    expect(addressKey("::ffff:203.0.113.9")).toBe("203.0.113.9");
    expect(addressKey("2001:db8:1:2:aaaa:bbbb:cccc:dddd")).toBe("2001:db8:1:2::/64");
    expect(addressKey("2001:DB8:1:2::1")).toBe("2001:db8:1:2::/64");
    expect(addressKey("2001:db8::1")).toBe("2001:db8:0:0::/64");
    expect(addressKey("[fe80::1%eth0]")).toBe("fe80:0:0:0::/64");
    expect(addressKey("unknown")).toBe("unknown");
    let t = 0;
    const c = windowCounter(60_000, 5, () => t, { sweepAt: 100, cap: 500 });
    // A flood of addresses within one window: the map stays bounded.
    for (let i = 0; i < 5000; i++) c.hit(`a${i}`);
    expect(c.size()).toBeLessThanOrEqual(751);
    // The newest keep their count.
    for (let i = 0; i < 4; i++) c.hit("a4999");
    expect(c.hit("a4999")).not.toBeNull();
    // Windows that ran out go once the map is looked over.
    t += 60_000;
    for (let i = 0; i < 800; i++) c.hit(`b${i}`);
    expect(c.size()).toBeLessThanOrEqual(751);
    expect(c.over("a4999")).toBeNull();
  });

  it("refuses a malformed key", async () => {
    const res = await watch("/v1/watch/me", {}, "cwt_short");
    expect(res.status).toBe(401);
    expect((await j(res)).code).toBe("invalid_watch_key");
  });

  it("stops working when its person leaves the workspace", async () => {
    const k = newKey();
    await h.request("/v1/watch-keys", {
      method: "POST",
      token: member.token,
      json: { org_id: orgId, fingerprint: hashWatchKey(k), platform: "wearos", name: "M" },
    });
    expect((await watch("/v1/watch/me", {}, k)).status).toBe(200);
    await h.tdb
      .admin`delete from public.memberships where org_id = ${orgId} and user_id = ${member.id}`;
    expect((await watch("/v1/watch/me", {}, k)).status).toBe(401);
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
  });

  it("is held to sixty requests a minute", async () => {
    let t = 0;
    const call = watchCaller({ db: h.handle.db }, { now: () => t });
    for (let i = 0; i < WATCH_KEY_PER_MINUTE; i++) await call("GET", "/v1/watch/me", key);
    await expect(call("GET", "/v1/watch/me", key)).rejects.toMatchObject({
      status: 429,
      code: "rate_limited",
    });
    t += 60_000;
    await expect(call("GET", "/v1/watch/me", key)).resolves.toMatchObject({ id: keyId });
  });

  it("saves its push token: Apple's on an Apple Watch, taken over from an old key", async () => {
    const wrong = await watch("/v1/watch-keys/current", {
      method: "PUT",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ push_token: "fcm-token-123", push_kind: "fcm" }),
    });
    expect(wrong.status).toBe(400);
    expect((await j(wrong)).code).toBe("wrong_token_kind");
    const ok = await watch("/v1/watch-keys/current", {
      method: "PUT",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        push_token: "ab".repeat(32),
        sandbox: true,
        app_version: "0.1.0",
        os_version: "watchOS 26.1",
      }),
    });
    expect(ok.status).toBe(200);
    const [row] = await h.tdb.admin<
      { push_kind: string; push_sandbox: boolean; app_version: string; os_version: string }[]
    >`select push_kind, push_sandbox, app_version, os_version from public.watch_keys where id = ${keyId}`;
    expect(row).toEqual({
      push_kind: "apns",
      push_sandbox: true,
      app_version: "0.1.0",
      os_version: "watchOS 26.1",
    });
    const list = await j(await h.request(`/v1/watch-keys?org_id=${orgId}`, { token: me.token }));
    expect(list.items.find((k: { id: string }) => k.id === keyId).has_push).toBe(true);
  });

  it("reads the glance of its own workspace, privately when details are off", async () => {
    const g = await watch("/v1/glance");
    expect(g.status).toBe(200);
    const body = await j(g);
    expect(body.flags.private).toBe(false);
    expect(Array.isArray(body.runs)).toBe(true);
    expect((await watch(`/v1/glance?org_id=${otherOrgId}`)).status).toBe(403);
    await h.request("/v1/watch-prefs", {
      method: "PATCH",
      token: me.token,
      json: { show_details: false },
    });
    expect((await j(await watch("/v1/glance"))).flags.private).toBe(true);
    await h.request("/v1/watch-prefs", {
      method: "PATCH",
      token: me.token,
      json: { show_details: true },
    });
  });
});

describe("requests on the wrist", () => {
  it("are told in everyday words with what the watch may do", async () => {
    const low = await approval({ risk: "low" });
    const res = await watch(`/v1/watch/approvals/${low.id}`);
    expect(res.status).toBe(200);
    const a = await j(res);
    expect(a).toMatchObject({
      id: low.id,
      run_id: low.runId,
      bot: "Ada",
      status: "pending",
      risk: "low",
      payment: false,
      can_allow: "tap",
      why_phone: null,
      link: `/approvals/${low.id}`,
    });
    expect(a.title).toBeTruthy();
    expect(a.title).not.toContain("{");
    expect(a).not.toHaveProperty("org_id");
    const med = await approval({ risk: "medium" });
    expect((await j(await watch(`/v1/watch/approvals/${med.id}`))).can_allow).toBe("hold");
    const high = await approval({ risk: "high" });
    expect(await j(await watch(`/v1/watch/approvals/${high.id}`))).toMatchObject({
      can_allow: "phone",
      why_phone: "high_risk",
    });
    const pay = await approval({ risk: "low", tool: "payments.request", args: { amount: 5 } });
    expect(await j(await watch(`/v1/watch/approvals/${pay.id}`))).toMatchObject({
      payment: true,
      can_allow: "phone",
      why_phone: "payment",
    });
    // Another workspace's request isn't this watch's.
    const elsewhere = await approval({ risk: "low", bot: otherBotId, org: otherOrgId });
    expect((await watch(`/v1/watch/approvals/${elsewhere.id}`)).status).toBe(404);
  });

  it("can be allowed from the watch only within its limits", async () => {
    const low = await approval({ risk: "low" });
    const allowed = await decide(low.id, "approved");
    expect(allowed.status).toBe(200);
    // The answer says it was decided, never the request's raw arguments.
    expect(await j(allowed)).toMatchObject({
      id: low.id,
      status: "approved",
      args_redacted: {},
      tool_name: "mail.send",
    });
    // With details off, no words about it either; the phone still gets everything.
    await h.request("/v1/watch-prefs", {
      method: "PATCH",
      token: me.token,
      json: { show_details: false },
    });
    const quiet = await approval({ risk: "low" });
    const denied = await j(await decide(quiet.id, "denied"));
    expect(denied).toMatchObject({
      status: "denied",
      args_redacted: {},
      tool_name: "",
      summary: "",
    });
    expect(JSON.stringify(denied)).not.toContain("dana@");
    await h.request("/v1/watch-prefs", {
      method: "PATCH",
      token: me.token,
      json: { show_details: true },
    });
    const byPhone = await approval({ risk: "low" });
    const full = await j(
      await h.request(`/v1/approvals/${byPhone.id}/decision`, {
        method: "POST",
        token: me.token,
        json: { decision: "denied" },
      }),
    );
    expect(full.args_redacted).toMatchObject({ to: "dana@example.com" });
    // A paid data call buys something: medium risk, and still the phone's.
    const paid = await approval({ risk: "medium", tool: "data.call", args: { endpoint: "x" } });
    expect(await j(await decide(paid.id, "approved"))).toMatchObject({
      code: "watch_allow_refused",
      detail: "payment",
    });
    const high = await approval({ risk: "high" });
    const refused = await decide(high.id, "approved");
    expect(refused.status).toBe(403);
    expect(await j(refused)).toMatchObject({ code: "watch_allow_refused", detail: "high_risk" });
    // Deny always works.
    expect((await decide(high.id, "denied")).status).toBe(200);
    const pay = await approval({ risk: "low", tool: "payments.request" });
    expect(await j(await decide(pay.id, "approved"))).toMatchObject({ detail: "payment" });
    // Never "always allow" from a watch.
    const always = await approval({ risk: "low" });
    const a = await decide(always.id, "approved", true);
    expect(a.status).toBe(403);
    expect((await j(a)).code).toBe("watch_always_allow");
    // The person's setting.
    await h.request("/v1/watch-prefs", {
      method: "PATCH",
      token: me.token,
      json: { allow: "low" },
    });
    const med = await approval({ risk: "medium" });
    expect(await j(await decide(med.id, "approved"))).toMatchObject({ detail: "setting" });
    await h.request("/v1/watch-prefs", {
      method: "PATCH",
      token: me.token,
      json: { allow: "medium" },
    });
    // Someone else's run, for a member who isn't an admin.
    const mk = newKey();
    await h.request("/v1/watch-keys", {
      method: "POST",
      token: member.token,
      json: { org_id: orgId, fingerprint: hashWatchKey(mk), platform: "wearos", name: "M2" },
    });
    const theirs = await approval({ risk: "low", runBy: me.id });
    const view = await j(await watch(`/v1/watch/approvals/${theirs.id}`, {}, mk));
    expect(view).toMatchObject({ can_allow: "phone", why_phone: "not_yours" });
    const nope = await watch(
      `/v1/approvals/${theirs.id}/decision`,
      {
        method: "POST",
        headers: { "content-type": "application/json", authorization: `Watch ${mk}` },
        body: JSON.stringify({ decision: "approved" }),
      },
      mk,
    );
    expect(await j(nope)).toMatchObject({ code: "watch_allow_refused", detail: "not_yours" });
    // Another workspace's request.
    const elsewhere = await approval({ risk: "low", bot: otherBotId, org: otherOrgId });
    expect((await decide(elsewhere.id, "denied")).status).toBe(404);
  });
});

describe("runs and chats", () => {
  it("ask a bot in a new chat, and a retry sends it once", async () => {
    const send = (idem: string, json: object) =>
      watch("/v1/watch/ask", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "idempotency-key": idem,
          "x-casama-surface": "complication",
        },
        body: JSON.stringify(json),
      });
    const res = await send("ask-1", { bot_id: botId, text: "What's on today?" });
    expect(res.status).toBe(201);
    const a = await j(res);
    expect(a).toMatchObject({ heard: "What's on today?" });
    expect(a.run_id).toBeTruthy();
    const again = await j(await send("ask-1", { bot_id: botId, text: "What's on today?" }));
    expect(again.conversation_id).toBe(a.conversation_id);
    expect(again.message_id).toBe(a.message_id);
    // A reply continues the chat.
    const reply = await j(
      await send("ask-2", { bot_id: botId, conversation_id: a.conversation_id, text: "Yes" }),
    );
    expect(reply.conversation_id).toBe(a.conversation_id);
    // The chat as a watch reads it.
    const chat = await watch(`/v1/watch/chats/${botId}?conversation_id=${a.conversation_id}`);
    expect(chat.status).toBe(200);
    const c = await j(chat);
    expect(c.bot).toMatchObject({ id: botId, name: "Ada" });
    expect(c.messages.map((m: { text: string }) => m.text)).toEqual(["What's on today?", "Yes"]);
    expect(c.link).toBe(`/bots/${botId}/chat?c=${a.conversation_id}`);
  });

  it("refuses other workspaces' bots, empty asks and recordings with no voice", async () => {
    const send = (json: object) =>
      watch("/v1/watch/ask", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(json),
      });
    expect((await send({ bot_id: otherBotId, text: "Hi" })).status).toBe(404);
    expect((await send({ bot_id: botId })).status).toBe(400);
    const audio = { data: Buffer.alloc(2000, 1).toString("base64"), mime: "audio/aac" };
    const noVoice = await send({ bot_id: botId, audio });
    expect(noVoice.status).toBe(409);
    expect((await watch(`/v1/watch/chats/${otherBotId}`)).status).toBe(404);
  });

  it("sends a recording as what was heard", async () => {
    const before = h.deps.workflows.voiceTranscribe;
    h.deps.workflows.voiceTranscribe = async () => ({
      ok: true,
      text: "Book a table for two",
      provider: "test",
      seconds: 2,
    });
    try {
      const res = await watch("/v1/watch/ask", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          bot_id: botId,
          audio: { data: Buffer.alloc(2000, 1).toString("base64"), mime: "audio/aac" },
        }),
      });
      expect(res.status).toBe(201);
      expect((await j(res)).heard).toBe("Book a table for two");
      h.deps.workflows.voiceTranscribe = async () => ({
        ok: true,
        text: "  ",
        provider: "test",
        seconds: 1,
      });
      const silent = await watch("/v1/watch/ask", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          bot_id: botId,
          audio: { data: Buffer.alloc(2000, 1).toString("base64"), mime: "audio/aac" },
        }),
      });
      expect((await j(silent)).code).toBe("nothing_heard");
    } finally {
      h.deps.workflows.voiceTranscribe = before;
    }
  });

  it("shows a run's whole state, and streams it until it ends", async () => {
    const { id: aId, runId } = await approval({ risk: "medium" });
    const r = await watch(`/v1/watch/runs/${runId}`);
    expect(r.status).toBe(200);
    const body = await j(r);
    expect(body).toMatchObject({
      id: runId,
      bot_id: botId,
      phase: "needs_ok",
      approval: { id: aId, can_allow: "hold" },
      link: `/approvals/${aId}`,
    });
    const elsewhere = await run({ bot: otherBotId, org: otherOrgId, status: "running" });
    expect((await watch(`/v1/watch/runs/${elsewhere}`)).status).toBe(404);

    const saved = { ...WATCH_STREAM };
    Object.assign(WATCH_STREAM, { ms: 5000, beatMs: 100, minGapMs: 0 });
    try {
      const res = await watch(`/v1/watch/runs/${runId}?stream=1`);
      expect(res.headers.get("content-type")).toContain("text/event-stream");
      setTimeout(async () => {
        await h.tdb.admin`update public.approvals set status = 'denied' where id = ${aId}`;
        await h.tdb
          .admin`update public.runs set status = 'cancelled', ended_at = now() where id = ${runId}`;
      }, 300);
      const text = await res.text();
      const events = text
        .split("\n")
        .filter((l) => l.startsWith("data: "))
        .map((l) => JSON.parse(l.slice(6)));
      expect(events[0].phase).toBe("needs_ok");
      expect(events.at(-1).phase).toBe("stopped");
      expect(text).toContain("event: run");
    } finally {
      Object.assign(WATCH_STREAM, saved);
    }
  });

  it("keeps an open stream to the person's settings as they change them", async () => {
    const { id: aId, runId } = await approval({ risk: "medium" });
    const saved = { ...WATCH_STREAM };
    Object.assign(WATCH_STREAM, { ms: 5000, beatMs: 50, minGapMs: 0, recheckMs: 100 });
    try {
      const res = await watch(`/v1/watch/runs/${runId}?stream=1`);
      setTimeout(() => {
        void h.request("/v1/watch-prefs", {
          method: "PATCH",
          token: me.token,
          json: { show_details: false },
        });
      }, 150);
      setTimeout(async () => {
        await h.tdb.admin`update public.approvals set status = 'denied' where id = ${aId}`;
        await h.tdb
          .admin`update public.runs set status = 'cancelled', ended_at = now() where id = ${runId}`;
      }, 900);
      const events = (await res.text())
        .split("\n")
        .filter((l) => l.startsWith("data: "))
        .map((l) => JSON.parse(l.slice(6)));
      expect(events[0].approval.title).toBe("Send an email");
      // Details went off while it was open: the same request, without its words.
      expect(
        events.some(
          (e: { phase: string; approval: { title: string } | null }) =>
            e.phase === "needs_ok" && e.approval?.title === "",
        ),
      ).toBe(true);
    } finally {
      Object.assign(WATCH_STREAM, saved);
      await h.request("/v1/watch-prefs", {
        method: "PATCH",
        token: me.token,
        json: { show_details: true },
      });
    }
  });

  it("reads a run once per gap while a reply is being written, not once per event", async () => {
    const runId = await run({ status: "running" });
    const saved = { ...WATCH_STREAM };
    Object.assign(WATCH_STREAM, {
      ms: 1500,
      beatMs: 5000,
      minGapMs: 300,
      recheckMs: 60_000,
      reads: 0,
    });
    try {
      const res = await watch(`/v1/watch/runs/${runId}?stream=1`);
      const ended = res.text();
      // Thirty events in about a second that change nothing a watch shows.
      for (let i = 0; i < 30; i++) {
        await h.tdb.admin`select pg_notify('casama_run_events', ${`${runId}:${i}`})`;
        await new Promise((r) => setTimeout(r, 30));
      }
      await ended;
      expect(WATCH_STREAM.reads).toBeGreaterThan(0);
      expect(WATCH_STREAM.reads).toBeLessThanOrEqual(7);
    } finally {
      Object.assign(WATCH_STREAM, saved);
    }
  });

  it("can stop a run, and is counted where a suggestion or routine is done", async () => {
    const r = await run({ status: "running" });
    const res = await watch(`/v1/runs/${r}/cancel`, { method: "POST" });
    expect(res.status).toBeLessThan(300);
    // Allowed routes answer as for the person (here: no such suggestion), not with a refusal.
    const s = await watch(`/v1/suggestions/${crypto.randomUUID()}/dismiss`, { method: "POST" });
    expect(s.status).not.toBe(403);
  });
});

describe("a watch stays in its workspace", () => {
  it("can't reach another workspace's routine, run, suggestion, message, recording or chat", async () => {
    const work = otherOrgId;
    const [routine] = await h.tdb.admin<{ id: string }[]>`
      insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, next_run_at)
      values (${work}, ${otherBotId}, ${me.id}, 'Brief', 'x', '0 8 * * *', 'UTC', now() + interval '1 day') returning id`;
    const runId = await run({ bot: otherBotId, org: work, status: "running" });
    const [sug] = await h.tdb.admin<{ id: string }[]>`
      insert into public.suggestions (org_id, bot_id, user_id, title)
      values (${work}, ${otherBotId}, ${me.id}, 'Book the dentist') returning id`;
    const [conv] = await h.tdb.admin<{ id: string }[]>`
      insert into public.conversations (org_id, bot_id, created_by, last_message_at)
      values (${work}, ${otherBotId}, ${me.id}, now()) returning id`;
    const [msg] = await h.tdb.admin<{ id: string }[]>`
      insert into public.messages (org_id, conversation_id, role, content, bot_id)
      values (${work}, ${conv?.id as string}, 'assistant', ${h.tdb.admin.json([{ type: "text", text: "Hi" }])}, ${otherBotId})
      returning id`;
    for (const [method, path] of [
      ["POST", `/v1/routines/${routine?.id}/run`],
      ["POST", `/v1/runs/${runId}/cancel`],
      ["POST", `/v1/suggestions/${sug?.id}/accept`],
      ["POST", `/v1/suggestions/${sug?.id}/dismiss`],
      ["GET", `/v1/messages/${msg?.id}/speech`],
      ["POST", `/v1/voice/transcribe?bot_id=${otherBotId}`],
    ] as const) {
      const res = await watch(path, {
        method,
        ...(path.includes("transcribe")
          ? { headers: { "content-type": "audio/aac" }, body: "abcd" }
          : {}),
      });
      expect(res.status, `${method} ${path}`).toBe(404);
    }
    // The run in the other workspace is still running.
    const [still] = await h.tdb.admin<
      { status: string }[]
    >`select status from public.runs where id = ${runId}`;
    expect(still?.status).toBe("running");
    // A reply can't go into another workspace's chat, or another bot's.
    const reply = (json: object) =>
      watch("/v1/watch/ask", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(json),
      });
    expect((await reply({ bot_id: botId, conversation_id: conv?.id, text: "Hi" })).status).toBe(
      404,
    );
    const [mine] = await h.tdb.admin<{ id: string }[]>`
      insert into public.conversations (org_id, bot_id, created_by, last_message_at)
      values (${orgId}, ${botId}, ${me.id}, now()) returning id`;
    const [otherBot] = await h.tdb.admin<{ id: string }[]>`
      insert into public.bots (org_id, name, created_by) values (${orgId}, 'Cy', ${me.id}) returning id`;
    const wrongBot = await reply({ bot_id: otherBot?.id, conversation_id: mine?.id, text: "Hi" });
    expect(wrongBot.status).toBe(404);
    expect((await j(wrongBot)).code).toBe("conversation_not_found");
  });

  it("doesn't read replies aloud when details are off or reply text is hidden", async () => {
    const [conv] = await h.tdb.admin<{ id: string }[]>`
      insert into public.conversations (org_id, bot_id, created_by, last_message_at)
      values (${orgId}, ${botId}, ${me.id}, now()) returning id`;
    const [msg] = await h.tdb.admin<{ id: string }[]>`
      insert into public.messages (org_id, conversation_id, role, content, bot_id)
      values (${orgId}, ${conv?.id as string}, 'assistant', ${h.tdb.admin.json([{ type: "text", text: "Hi" }])}, ${botId})
      returning id`;
    const speech = () => watch(`/v1/messages/${msg?.id}/speech`);
    // Allowed when shown (here no voice is set up, so not a refusal of details).
    expect((await j(await speech())).code).not.toBe("watch_details_hidden");
    await h.request("/v1/watch-prefs", {
      method: "PATCH",
      token: me.token,
      json: { show_details: false },
    });
    const off = await speech();
    expect(off.status).toBe(403);
    expect((await j(off)).code).toBe("watch_details_hidden");
    await h.request("/v1/watch-prefs", {
      method: "PATCH",
      token: me.token,
      json: { show_details: true },
    });
    await h.tdb
      .admin`update public.profiles set push_prefs = '{"hide_reply_text": true}' where user_id = ${me.id}`;
    expect((await j(await speech())).code).toBe("watch_details_hidden");
    await h.tdb.admin`update public.profiles set push_prefs = '{}' where user_id = ${me.id}`;
  });

  it("keeps a few run streams open per watch: a new one closes the oldest", async () => {
    const runId = await run({ status: "running" });
    const saved = { ...WATCH_STREAM };
    Object.assign(WATCH_STREAM, { ms: 3000, beatMs: 50, minGapMs: 0 });
    try {
      const opened: Array<{ res: Response; at: number; ended?: number }> = [];
      for (let i = 0; i <= WATCH_STREAMS_PER_KEY; i++) {
        const res = await watch(`/v1/watch/runs/${runId}?stream=1`);
        const entry: { res: Response; at: number; ended?: number } = { res, at: Date.now() };
        opened.push(entry);
        void res.text().then(() => {
          entry.ended = Date.now();
        });
        await new Promise((r) => setTimeout(r, 30));
      }
      await new Promise((r) => setTimeout(r, 300));
      // The first was closed when the fourth opened; the rest are still going.
      expect(opened[0]?.ended).toBeTruthy();
      expect(opened.slice(1).every((o) => !o.ended)).toBe(true);
    } finally {
      Object.assign(WATCH_STREAM, saved);
    }
  });

  it("ends a stream once its watch is removed", async () => {
    const k = newKey();
    const made = await j(
      await h.request("/v1/watch-keys", {
        method: "POST",
        token: me.token,
        json: { org_id: orgId, fingerprint: hashWatchKey(k), platform: "wearos", name: "Gone" },
      }),
    );
    const runId = await run({ status: "running" });
    const saved = { ...WATCH_STREAM };
    Object.assign(WATCH_STREAM, { ms: 10_000, beatMs: 50, minGapMs: 0, recheckMs: 100 });
    try {
      const started = Date.now();
      const res = await watch(`/v1/watch/runs/${runId}?stream=1`, {}, k);
      setTimeout(async () => {
        await h.request(`/v1/watch-keys/${made.id}`, { method: "DELETE", token: me.token });
      }, 200);
      await res.text();
      expect(Date.now() - started).toBeLessThan(5000);
    } finally {
      Object.assign(WATCH_STREAM, saved);
    }
  });
});

describe("open on phone and signing out", () => {
  it("sends the person's phones a notification that opens the link", async () => {
    await h.tdb
      .admin`insert into public.devices (user_id, platform, fcm_token) values (${me.id}, 'ios', 'phone-token-1')`;
    const res = await watch("/v1/watch/handoff", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ link: `/bots/${botId}/chat`, title: "Continue with Ada" }),
    });
    expect(res.status).toBe(200);
    expect(await j(res)).toEqual({ sent: 1 });
    const last = push.sent.at(-1);
    expect(last?.tokens).toEqual(["phone-token-1"]);
    expect(last?.message.data).toMatchObject({ link: `/bots/${botId}/chat`, watch_kind: "other" });
    const bad = await watch("/v1/watch/handoff", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ link: "https://evil.example", title: "x" }),
    });
    expect(bad.status).toBe(400);
    // Never another site, however it's written.
    for (const link of ["//evil.example/x", "/\\evil.example"]) {
      const other = await watch("/v1/watch/handoff", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ link, title: "x" }),
      });
      expect(other.status, link).toBe(400);
    }
  });

  it("tells the person's phones when a watch is signed in as them", async () => {
    const before = push.sent.length;
    await h.request("/v1/watch-keys", {
      method: "POST",
      token: me.token,
      json: {
        org_id: orgId,
        fingerprint: hashWatchKey(newKey()),
        platform: "watchos",
        name: "Spare",
      },
    });
    for (let i = 0; i < 50 && push.sent.length === before; i++)
      await new Promise((r) => setTimeout(r, 20));
    const sent = push.sent.at(-1);
    expect(sent?.tokens).toEqual(["phone-token-1"]);
    expect(sent?.message).toMatchObject({
      title: "Spare is signed in to Casama",
      link: "/settings/watch",
    });
  });

  it("says so once: registering a watch again or moving it isn't a new sign-in", async () => {
    const fingerprint = hashWatchKey(newKey());
    const register = async (org: string) =>
      j(
        await h.request("/v1/watch-keys", {
          method: "POST",
          token: me.token,
          json: { org_id: org, fingerprint, platform: "wearos", name: "Mover" },
        }),
      );
    const first = await register(orgId);
    for (
      let i = 0;
      i < 50 && push.sent.at(-1)?.message.title !== "Mover is signed in to Casama";
      i++
    )
      await new Promise((r) => setTimeout(r, 20));
    expect(push.sent.at(-1)?.message.title).toBe("Mover is signed in to Casama");
    const before = push.sent.length;
    // The phone switches workspace and back: the same watch, moved.
    const moved = await register(otherOrgId);
    expect(moved).toMatchObject({ id: first.id, org_id: otherOrgId });
    expect((await register(orgId)).org_id).toBe(orgId);
    await new Promise((r) => setTimeout(r, 200));
    expect(push.sent.length).toBe(before);
  });

  it("signs out everywhere: every watch the person signed in, in every workspace", async () => {
    const own = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: member.token,
          json: { name: "Mine" },
        }),
      )
    ).id as string;
    const k1 = newKey();
    const k2 = newKey();
    for (const [org, k] of [
      [orgId, k1],
      [own, k2],
    ] as const)
      await h.request("/v1/watch-keys", {
        method: "POST",
        token: member.token,
        json: { org_id: org, fingerprint: hashWatchKey(k), platform: "wearos", name: "W" },
      });
    expect((await watch("/v1/watch/me", {}, k2)).status).toBe(200);
    // Only the person's own session may: not a watch's key, and not signed out.
    const byWatch = await watch("/v1/watch-keys", { method: "DELETE" }, k1);
    expect(byWatch.status).toBe(403);
    expect((await j(byWatch)).code).toBe("watch_key_not_allowed");
    expect((await h.request("/v1/watch-keys", { method: "DELETE" })).status).toBe(401);
    const res = await h.request("/v1/watch-keys", { method: "DELETE", token: member.token });
    expect(res.status).toBe(200);
    expect((await j(res)).deleted).toBeGreaterThanOrEqual(2);
    for (const k of [k1, k2]) expect((await watch("/v1/watch/me", {}, k)).status).toBe(401);
    const [left] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.watch_keys where user_id = ${member.id}`;
    expect(left?.n).toBe(0);
    // Someone else's watch is untouched.
    expect((await watch("/v1/watch/me")).status).toBe(200);
    expect(
      await j(await h.request("/v1/watch-keys", { method: "DELETE", token: member.token })),
    ).toEqual({
      deleted: 0,
    });
  });

  it("signs out: the key stops working at once", async () => {
    const res = await watch("/v1/watch-keys/current", { method: "DELETE" });
    expect(res.status).toBe(200);
    expect((await watch("/v1/watch/me")).status).toBe(401);
  });
});
