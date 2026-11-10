/** Hosted MCP endpoint (D-117): connect by URL with OAuth, ask a bot, approvals still apply. */
import { createHash, randomBytes } from "node:crypto";
import type { Server } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import { serve } from "@hono/node-server";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/hosted-mcp.json", import.meta.url));
let h: Harness;
let server: Server;
let base: string;
let owner: { id: string; token: string };
let orgId: string;
let otherOrg: string;
let accessToken: string;

const connect = async (bearer: string) => {
  const client = new Client({ name: "test-app", version: "1.0.0" });
  await client.connect(
    new StreamableHTTPClientTransport(new URL(`${base}/mcp`), {
      requestInit: { headers: { authorization: `Bearer ${bearer}` } },
    }),
  );
  return client;
};
const textOf = (r: unknown) =>
  (r as { content: Array<{ text: string }> }).content.map((c) => c.text).join("\n");

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  server = serve({ fetch: h.app.fetch, port: 0 }) as unknown as Server;
  await new Promise((r) => server.once("listening", r));
  base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  owner = await h.user("mcp-owner@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", {
        method: "POST",
        token: owner.token,
        json: { name: "MCP Org" },
      }),
    )
  ).id;
  otherOrg = (
    await j(
      await h.request("/v1/orgs", {
        method: "POST",
        token: owner.token,
        json: { name: "Other Org" },
      }),
    )
  ).id;
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
    }),
  );
  await h.request("/v1/bots", {
    method: "POST",
    token: owner.token,
    json: {
      org_id: orgId,
      name: "Ada",
      autonomy: "ask_risky",
      model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
    },
  });
}, 60_000);
afterAll(async () => {
  server?.close();
  await h?.stop();
});

describe("hosted MCP", () => {
  it("asks unauthenticated clients to sign in, pointing at the OAuth metadata", async () => {
    const res = await fetch(`${base}/mcp`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        accept: "application/json, text/event-stream",
      },
      body: "{}",
    });
    expect(res.status).toBe(401);
    expect(res.headers.get("www-authenticate")).toContain("/.well-known/oauth-protected-resource");
    const meta = (await (
      await fetch(`${base}/.well-known/oauth-authorization-server`)
    ).json()) as Record<string, string>;
    expect(meta).toMatchObject({
      code_challenge_methods_supported: ["S256"],
      registration_endpoint: expect.stringContaining("/oauth/register"),
    });
  });

  it("completes OAuth with dynamic registration, PKCE and in-app consent for one workspace", async () => {
    const reg = (await (
      await fetch(`${base}/oauth/register`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          client_name: "Phone AI",
          redirect_uris: ["https://ai.example/callback"],
        }),
      })
    ).json()) as Record<string, string>;
    const verifier = randomBytes(32).toString("base64url");
    const challenge = createHash("sha256").update(verifier).digest("base64url");
    const auth = await fetch(
      `${base}/oauth/authorize?response_type=code&client_id=${reg.client_id}&redirect_uri=${encodeURIComponent("https://ai.example/callback")}&code_challenge=${challenge}&code_challenge_method=S256&state=xyz`,
      { redirect: "manual" },
    );
    expect(auth.status).toBe(302);
    const requestId = (auth.headers.get("location") ?? "").split("/").pop() as string;
    const info = await j(
      await h.request(`/v1/oauth/requests/${requestId}`, { token: owner.token }),
    );
    expect(info).toMatchObject({ client_name: "Phone AI", redirect_host: "ai.example" });
    const consent = await j(
      await h.request(`/v1/oauth/requests/${requestId}/consent`, {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, approve: true },
      }),
    );
    const redirect = new URL(consent.redirect_url);
    expect(redirect.searchParams.get("state")).toBe("xyz");
    const tokenRes = await fetch(`${base}/oauth/token`, {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "authorization_code",
        code: redirect.searchParams.get("code") as string,
        code_verifier: "wrong-verifier",
        client_id: reg.client_id as string,
      }),
    });
    expect(tokenRes.status).toBe(400);
    // The code is single use: the failed attempt spent it. Go through consent again for a valid exchange.
    const auth2 = await fetch(
      `${base}/oauth/authorize?response_type=code&client_id=${reg.client_id}&redirect_uri=${encodeURIComponent("https://ai.example/callback")}&code_challenge=${challenge}&code_challenge_method=S256`,
      { redirect: "manual" },
    );
    const id2 = (auth2.headers.get("location") ?? "").split("/").pop() as string;
    const c2 = await j(
      await h.request(`/v1/oauth/requests/${id2}/consent`, {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, approve: true },
      }),
    );
    const tokens = (await (
      await fetch(`${base}/oauth/token`, {
        method: "POST",
        headers: { "content-type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          grant_type: "authorization_code",
          code: new URL(c2.redirect_url).searchParams.get("code") as string,
          code_verifier: verifier,
        }),
      })
    ).json()) as Record<string, string>;
    expect(tokens.access_token).toMatch(/^kmcp_/);
    const refreshed = (await (
      await fetch(`${base}/oauth/token`, {
        method: "POST",
        headers: { "content-type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          grant_type: "refresh_token",
          refresh_token: tokens.refresh_token as string,
        }),
      })
    ).json()) as Record<string, string>;
    accessToken = refreshed.access_token as string;
    expect(accessToken).toMatch(/^kmcp_/);
  });

  it("connects by URL, sees only that workspace, and asks a bot", async () => {
    const client = await connect(accessToken);
    const tools = (await client.listTools()).tools.map((t) => t.name);
    expect(tools).toEqual(
      expect.arrayContaining([
        "list_workspaces",
        "list_bots",
        "ask_bot",
        "get_run",
        "list_approvals",
        "decide_approval",
      ]),
    );
    const ws = JSON.parse(
      textOf(await client.callTool({ name: "list_workspaces", arguments: {} })),
    );
    expect(ws.map((w: { id: string }) => w.id)).toEqual([orgId]);
    expect(JSON.stringify(ws)).not.toContain(otherOrg);
    const reply = textOf(
      await client.callTool({ name: "ask_bot", arguments: { bot: "Ada", message: "Say hello" } }),
    );
    expect(reply).toContain("Hello from Kasama.");
    expect(reply).toContain("status: completed");
    await client.close();
  });

  it("a high-risk step waits for approval; deciding over MCP needs the workspace's permission", async () => {
    const client = await connect(accessToken);
    const reply = textOf(
      await client.callTool({
        name: "ask_bot",
        arguments: { bot: "Ada", message: "Please make a helper bot" },
      }),
    );
    expect(reply).toContain("status: waiting_approval");
    const approvals = JSON.parse(
      textOf(await client.callTool({ name: "list_approvals", arguments: {} })),
    );
    expect(approvals[0].tool_name).toBe("bots.create");
    const refused = await client.callTool({
      name: "decide_approval",
      arguments: { approval_id: approvals[0].id, decision: "approve" },
    });
    expect(refused.isError).toBe(true);
    expect(textOf(refused)).toContain("doesn't allow");
    await h.request(`/v1/orgs/${orgId}/settings`, {
      method: "PATCH",
      token: owner.token,
      json: { mcp_decide_approvals: true },
    });
    const ok = await client.callTool({
      name: "decide_approval",
      arguments: { approval_id: approvals[0].id, decision: "approve" },
    });
    expect(ok.isError).toBeFalsy();
    await client.close();
  });

  it("workspace API keys work too, and stop working when revoked", async () => {
    const key = await j(
      await h.request(`/v1/orgs/${orgId}/mcp-keys`, {
        method: "POST",
        token: owner.token,
        json: { name: "Laptop" },
      }),
    );
    expect(key.key).toMatch(/^ksk_/);
    expect(key.mcp_url).toContain("/mcp");
    const client = await connect(key.key);
    expect(
      JSON.parse(textOf(await client.callTool({ name: "list_bots", arguments: {} }))).map(
        (b: { name: string }) => b.name,
      ),
    ).toContain("Ada");
    await client.close();
    await h.request(`/v1/orgs/${orgId}/mcp-keys/${key.id}`, {
      method: "DELETE",
      token: owner.token,
    });
    await expect(connect(key.key)).rejects.toThrow();
  });
});
