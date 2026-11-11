/**
 * ChatGPT plan sign-in end to end against a fake OpenAI (SPEC: ChatGPT plan sign-in; D-091):
 * loopback sign-in through the API, tokens kept in Vault, runs on the plan at cost 0, owner-only
 * use, plan limits, refresh rotation under concurrency, reconnect and revocation.
 */
import { CredentialResolver } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type FakeOpenAI, startFakeOpenAI } from "./fake-openai.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let fake: FakeOpenAI;
let owner: { id: string; token: string };
let teammate: { id: string; token: string };
let orgId: string;
let credentialId: string;
let botId: string;
const bodies: string[] = [];

async function call(path: string, init: Parameters<Harness["request"]>[1] = {}) {
  const res = await h.request(path, init);
  bodies.push(await res.clone().text());
  return res;
}

/** What the desktop app or CLI does: start, let the browser hit the authorize URL, relay the code. */
async function signIn(token: string, extra: Record<string, unknown> = {}) {
  const start = await call("/v1/credentials/chatgpt/start", {
    method: "POST",
    token,
    json: { org_id: orgId, redirect_port: 53682, ...extra },
  });
  expect(start.status).toBe(200);
  const s = await j(start);
  expect(s.redirect_uri).toBe("http://127.0.0.1:53682/auth/callback");
  const browser = await fetch(s.authorize_url, { redirect: "manual" });
  expect(browser.status).toBe(302);
  const cb = new URL(browser.headers.get("location") ?? "");
  expect(`${cb.origin}${cb.pathname}`).toBe(s.redirect_uri);
  const q = Object.fromEntries(cb.searchParams);
  return call("/v1/credentials/chatgpt/complete", { method: "POST", token, json: q });
}

async function waitForRun(runId: string, token: string, timeoutMs = 20_000) {
  const until = Date.now() + timeoutMs;
  for (;;) {
    const run = await j(await call(`/v1/runs/${runId}`, { token }));
    if (["completed", "failed", "cancelled"].includes(run.status)) return run;
    if (Date.now() > until) throw new Error(`run ${runId} still ${run.status}`);
    await new Promise((r) => setTimeout(r, 100));
  }
}

async function chat(token: string, text: string) {
  const conv = await j(
    await call("/v1/conversations", { method: "POST", token, json: { bot_id: botId } }),
  );
  const sent = await j(
    await call(`/v1/conversations/${conv.id}/messages`, { method: "POST", token, json: { text } }),
  );
  return waitForRun(sent.run_id, token);
}

beforeAll(async () => {
  fake = await startFakeOpenAI();
  h = await startHarness({
    env: { CHATGPT_AUTH_URL: fake.url, CHATGPT_API_URL: fake.apiUrl },
    worker: { chatgpt: { authUrl: fake.url, apiUrl: fake.apiUrl } },
  });
  owner = await h.user("plan-owner@example.com");
  teammate = await h.user("plan-teammate@example.com");
  orgId = (
    await j(
      await call("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Plan Org" } }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${teammate.id}, 'member')`;
}, 60_000);
afterAll(async () => {
  await h?.stop();
  await fake?.stop();
});

describe("sign-in", () => {
  it("connects a plan: loopback redirect, dynamic client, tokens only in Vault", async () => {
    const res = await signIn(owner.token);
    expect(res.status).toBe(200);
    const cred = await j(res);
    credentialId = cred.id;
    expect(cred).toMatchObject({
      provider: "chatgpt",
      owner_user_id: owner.id,
      status: "ok",
      account: "plan.owner@example.com",
      fallback_on_limit: false,
    });
    const q = fake.state.authorizeRequests[0];
    expect(q?.get("client_id")).toBe("dynamic_agent_client");
    expect(q?.get("agent_name_hint")).toBe("Casama");
    expect(q?.get("code_challenge_method")).toBe("S256");
    expect(q?.get("scope")).toContain("chatgpt.tokens.use.direct");
    expect(q?.get("resource")).toBe("https://api.openai.com/v1");
    expect(q?.get("ext_agent_host_id")).toMatch(/^urn:uuid:[0-9a-f-]{36}$/);

    const [row] = await h.tdb.admin<
      { vault_secret_id: string; oauth: { client_id: string } }[]
    >`select vault_secret_id, oauth from public.model_credentials where id = ${credentialId}`;
    expect(row?.oauth.client_id).toMatch(/^oaiapp_/);
    const [secret] = await h.tdb.admin<
      { decrypted_secret: string }[]
    >`select decrypted_secret from vault.decrypted_secrets where id = ${row!.vault_secret_id}`;
    const tokens = JSON.parse(secret!.decrypted_secret);
    expect(tokens.refresh_token).toMatch(/^rt_/);
    expect(tokens.client_id).toBe(row?.oauth.client_id);
    // No API response ever carries a token.
    for (const b of bodies) expect(b).not.toMatch(/\b(at|rt)_[A-Za-z0-9_-]{10,}/);
  });

  it("reconnects with the issued client and the same host id, without a duplicate", async () => {
    const res = await signIn(owner.token, { credential_id: credentialId });
    expect(res.status).toBe(200);
    expect((await j(res)).id).toBe(credentialId);
    const [first, second] = fake.state.authorizeRequests;
    expect(second?.get("client_id")).toMatch(/^oaiapp_/);
    expect(second?.get("agent_name_hint")).toBeNull();
    expect(second?.get("login_hint")).toBe("plan.owner@example.com");
    expect(second?.get("ext_agent_host_id")).toBe(first?.get("ext_agent_host_id"));
    const [count] = await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.model_credentials where provider = 'chatgpt'`;
    expect(count?.n).toBe(1);
  });

  it("reports a declined consent and never reuses a sign-in", async () => {
    fake.state.decline = true;
    const res = await signIn(teammate.token);
    fake.state.decline = false;
    expect(res.status).toBe(400);
    expect((await j(res)).code).toBe("chatgpt_sign_in_declined");
  });

  it("keeps a sign-in without plan usage as plan_usage_off", async () => {
    fake.state.grantPlan = false;
    fake.state.sub = "user-chatgpt-2";
    const res = await signIn(teammate.token);
    fake.state.grantPlan = true;
    fake.state.sub = "user-chatgpt-1";
    expect(res.status).toBe(200);
    const cred = await j(res);
    expect(cred).toMatchObject({ status: "plan_usage_off", owner_user_id: teammate.id });
    // The teammate removes it again (the owner of a personal credential may delete it).
    const del = await call(`/v1/credentials/${cred.id}`, {
      method: "DELETE",
      token: teammate.token,
    });
    expect(del.status).toBe(204);
  });

  it("refuses a ChatGPT key through the plain key route", async () => {
    const res = await call("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "chatgpt", label: "x", api_key: "x" },
    });
    expect(res.status).toBe(400);
  });

  it("lists the plan's models through the worker (visibility list only)", async () => {
    const res = await j(
      await call(`/v1/credentials/${credentialId}/models`, { token: owner.token }),
    );
    expect(res.source).toBe("live");
    const ids = res.items.map((m: { id: string }) => m.id);
    expect(ids).toContain("gpt-6.1-sol");
    expect(ids).toContain("gpt-6.1-terra");
    expect(ids).not.toContain("internal-preview");
  });
});

describe("runs on the plan", () => {
  it("replies on the plan with the plan-usage request shape, recorded at cost 0", async () => {
    const bot = await j(
      await call("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Planner",
          model_policy: { primary: { credential_id: credentialId, model: "gpt-6.1-sol" } },
        },
      }),
    );
    botId = bot.id;
    fake.state.responsesBodies.length = 0;
    fake.state.script.push({ text: "Hello from your plan." });
    const run = await chat(owner.token, "Say hello.");
    expect(run.status).toBe("completed");
    expect(run.cost_usd).toBe(0);
    const body = fake.state.responsesBodies[0] as Record<string, unknown>;
    expect(body).toMatchObject({ model: "gpt-6.1-sol", stream: true, store: false });
    expect(typeof body.instructions).toBe("string");
    for (const k of ["temperature", "max_output_tokens", "previous_response_id", "metadata"])
      expect(body).not.toHaveProperty(k);
    const rows = await h.tdb.admin<
      { source: string; cost_usd: string }[]
    >`select source, cost_usd from public.usage_ledger where run_id = ${run.id}`;
    expect(rows.length).toBeGreaterThan(0);
    for (const r of rows) {
      expect(r.source).toBe("chatgpt_plan");
      expect(Number(r.cost_usd)).toBe(0);
    }
  });

  it("never uses one person's plan for a teammate's run", async () => {
    const before = fake.state.responsesBodies.length;
    const run = await chat(teammate.token, "Use the plan, please.");
    expect(run.status).toBe("failed");
    expect(run.error.code).toBe("chatgpt_plan_not_yours");
    expect(fake.state.responsesBodies.length).toBe(before);
  });

  it("stops at the plan limit with a clear message, mid-stream too", async () => {
    fake.state.script.push({ limit: "before" });
    const before = await chat(owner.token, "One more.");
    expect(before.status).toBe("failed");
    expect(before.error.code).toBe("chatgpt_plan_limit");
    expect(before.error.message).toContain("ChatGPT plan limit");
    fake.state.script.push({ limit: "mid" });
    const mid = await chat(owner.token, "And another.");
    expect(mid.status).toBe("failed");
    expect(mid.error.code).toBe("chatgpt_plan_limit");
  });

  it("lets only the owner turn on the next-model fallback", async () => {
    const denied = await call(`/v1/credentials/${credentialId}`, {
      method: "PATCH",
      token: teammate.token,
      json: { fallback_on_limit: true },
    });
    expect(denied.status).toBe(403);
    const ok = await j(
      await call(`/v1/credentials/${credentialId}`, {
        method: "PATCH",
        token: owner.token,
        json: { fallback_on_limit: true },
      }),
    );
    expect(ok.fallback_on_limit).toBe(true);
  });
});

describe("tokens", () => {
  it("refreshes once for parallel callers and keeps the rotated pair", async () => {
    // Expire the stored access token; both resolves need a refresh, only one may spend the token.
    await h.tdb.admin`
      update vault.secrets set secret = jsonb_set(secret::jsonb, '{expires_at}', '0')::text
      where id = (select vault_secret_id from public.model_credentials where id = ${credentialId})`;
    const resolver = new CredentialResolver(h.handle.db, {
      chatgpt: { authUrl: fake.url, apiUrl: fake.apiUrl },
    });
    const calls = fake.state.refreshCalls;
    const choice = { credential_id: credentialId, model: "gpt-6.1-sol" };
    const [a, b] = await Promise.all([
      resolver.resolve(orgId, choice, { actingUserId: owner.id }),
      resolver.resolve(orgId, choice, { actingUserId: owner.id }),
    ]);
    expect(fake.state.refreshCalls - calls).toBe(1);
    expect(a.apiKey).toBe(b.apiKey);
    expect(a.provider).toBe("chatgpt");
  });

  it("marks a dead sign-in needs_reconnect and tells the owner", async () => {
    await h.tdb.admin`
      update vault.secrets set secret = jsonb_set(secret::jsonb, '{expires_at}', '0')::text
      where id = (select vault_secret_id from public.model_credentials where id = ${credentialId})`;
    fake.state.killRefresh = true;
    const resolver = new CredentialResolver(h.handle.db, {
      chatgpt: { authUrl: fake.url, apiUrl: fake.apiUrl },
    });
    await expect(
      resolver.resolve(
        orgId,
        { credential_id: credentialId, model: "gpt-6.1-sol" },
        { actingUserId: owner.id },
      ),
    ).rejects.toMatchObject({ code: "chatgpt_needs_reconnect" });
    fake.state.killRefresh = false;
    const [row] = await h.tdb.admin<
      { status: string }[]
    >`select status from public.model_credentials where id = ${credentialId}`;
    expect(row?.status).toBe("needs_reconnect");
    const notes = await h.tdb.admin<
      { kind: string }[]
    >`select kind from public.notifications where user_id = ${owner.id} and kind = 'credential'`;
    expect(notes.length).toBe(1);
    // Signing in again restores it.
    const res = await signIn(owner.token, { credential_id: credentialId });
    expect((await j(res)).status).toBe("ok");
  });

  it("revokes the sign-in at OpenAI and deletes the Vault secret on disconnect", async () => {
    const [row] = await h.tdb.admin<
      { vault_secret_id: string; oauth: { client_id: string } }[]
    >`select vault_secret_id, oauth from public.model_credentials where id = ${credentialId}`;
    const [secret] = await h.tdb.admin<
      { decrypted_secret: string }[]
    >`select decrypted_secret from vault.decrypted_secrets where id = ${row!.vault_secret_id}`;
    const refresh = JSON.parse(secret!.decrypted_secret).refresh_token;
    const res = await call(`/v1/credentials/${credentialId}`, {
      method: "DELETE",
      token: owner.token,
    });
    expect(res.status).toBe(204);
    expect(fake.state.revoked).toContainEqual({ token: refresh, clientId: row!.oauth.client_id });
    const left = await h.tdb.admin`select 1 from vault.secrets where id = ${row!.vault_secret_id}`;
    expect(left.length).toBe(0);
  });

  it("is off when the server turns ChatGPT sign-in off", async () => {
    const off = await startHarness({ env: { CHATGPT_SIGN_IN: "off" } });
    try {
      const u = await off.user("off@example.com");
      const org = await j(
        await off.request("/v1/orgs", { method: "POST", token: u.token, json: { name: "Off" } }),
      );
      const res = await off.request("/v1/credentials/chatgpt/start", {
        method: "POST",
        token: u.token,
        json: { org_id: org.id, redirect_port: 50000 },
      });
      expect(res.status).toBe(403);
      expect((await j(res)).code).toBe("chatgpt_sign_in_disabled");
    } finally {
      await off.stop();
    }
  });
});
