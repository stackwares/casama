import { createHash } from "node:crypto";
import { once } from "node:events";
import { createServer, type IncomingMessage, type Server, type ServerResponse } from "node:http";
import type { AddressInfo } from "node:net";
import { loadIntegration, parseOAuthSecret } from "@casama/agent";
import type { CatalogApp } from "@casama/domain";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { oauthRedirectFor } from "../src/api/routes/apps.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

/**
 * A fake vendor: an MCP server behind OAuth 2.1 the way the MCP authorization spec describes it
 * (protected-resource metadata, authorization-server metadata, dynamic client registration, PKCE,
 * refresh tokens). Tokens expire after a second so the refresh path runs too.
 */
let vendor: Server;
let base = "";
const issued = { challenge: "", registered: 0, refreshed: 0, confidential: false };
const valid = new Set(["key-123"]);

async function startVendor() {
  const json = (
    res: ServerResponse,
    status: number,
    data: unknown,
    headers: Record<string, string> = {},
  ) =>
    res
      .writeHead(status, { "content-type": "application/json", ...headers })
      .end(JSON.stringify(data));
  vendor = createServer(async (req: IncomingMessage, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    const raw = Buffer.concat(chunks).toString();
    const url = new URL(req.url ?? "/", base);
    const p = url.pathname;
    if (p.startsWith("/.well-known/oauth-protected-resource"))
      return json(res, 200, {
        // The resource the metadata was asked about: /mcp, or /custom/mcp (D-473).
        resource: `${base}${p.slice("/.well-known/oauth-protected-resource".length) || "/mcp"}`,
        authorization_servers: [base],
        // Like Google's servers: every scope it accepts, including far more than needed.
        scopes_supported: ["read", "everything"],
      });
    if (p === "/.well-known/oauth-authorization-server")
      return json(res, 200, {
        issuer: base,
        authorization_endpoint: `${base}/authorize`,
        token_endpoint: `${base}/token`,
        registration_endpoint: `${base}/register`,
        response_types_supported: ["code"],
        grant_types_supported: ["authorization_code", "refresh_token"],
        code_challenge_methods_supported: ["S256"],
        token_endpoint_auth_methods_supported: ["none"],
      });
    if (p === "/register") {
      issued.registered++;
      const body = JSON.parse(raw);
      // Like Composio's: a confidential client with a secret unless a public one is asked for,
      // even though the token endpoint only announces `none`.
      if (body.token_endpoint_auth_method === "none")
        return json(res, 201, { ...body, client_id: "casama-client" });
      issued.confidential = true;
      return json(res, 201, {
        ...body,
        client_id: "casama-client",
        client_secret: "shh",
        token_endpoint_auth_method: "client_secret_basic",
      });
    }
    if (p === "/authorize") {
      // The person signs in and approves; the vendor sends the browser back with a code.
      issued.challenge = url.searchParams.get("code_challenge") ?? "";
      const back = new URL(url.searchParams.get("redirect_uri") ?? "");
      back.searchParams.set("code", "the-code");
      back.searchParams.set("state", url.searchParams.get("state") ?? "");
      return res.writeHead(302, { location: back.toString() }).end();
    }
    if (p === "/token") {
      const form = new URLSearchParams(raw);
      if (issued.confidential && !req.headers.authorization && !form.get("client_secret"))
        return json(res, 401, {
          error: "invalid_client",
          error_description: "Missing client_secret.",
        });
      if (form.get("grant_type") === "authorization_code") {
        const verifier = form.get("code_verifier") ?? "";
        const challenge = createHash("sha256").update(verifier).digest("base64url");
        if (form.get("code") !== "the-code" || challenge !== issued.challenge)
          return json(res, 400, { error: "invalid_grant" });
        valid.add("at-1");
        return json(res, 200, {
          access_token: "at-1",
          refresh_token: "rt-1",
          expires_in: 1,
          token_type: "Bearer",
        });
      }
      if (form.get("grant_type") === "refresh_token" && form.get("refresh_token") === "rt-1") {
        issued.refreshed++;
        valid.add("at-2");
        return json(res, 200, { access_token: "at-2", expires_in: 3600, token_type: "Bearer" });
      }
      return json(res, 400, { error: "invalid_grant" });
    }
    // A Zoho-style server: the key is in the URL, no auth header.
    const keyed = /^\/srv\/mcp\/([^/]+)\/message$/.exec(p);
    if (keyed) {
      if (keyed[1] !== "zkey" || req.headers.authorization)
        return json(res, 401, { error: "invalid_key" });
      const server = new McpServer({ name: "zoho", version: "1.0.0" });
      server.registerTool(
        "mail_list",
        { description: "List mail", annotations: { readOnlyHint: true } },
        async () => ({ content: [{ type: "text", text: "inbox" }] }),
      );
      const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
      res.on("close", () => void transport.close());
      await server.connect(transport);
      return transport.handleRequest(req, res, raw ? JSON.parse(raw) : undefined);
    }
    if (p === "/mcp" || p === "/custom/mcp") {
      const token = (req.headers.authorization ?? "").replace(/^Bearer /, "");
      if (!valid.has(token))
        return json(
          res,
          401,
          { error: "invalid_token" },
          {
            "www-authenticate": `Bearer resource_metadata="${base}/.well-known/oauth-protected-resource${p}"`,
          },
        );
      const server = new McpServer({ name: "acme", version: "1.0.0" });
      server.registerTool(
        "whoami",
        { description: "Who the token belongs to", annotations: { readOnlyHint: true } },
        async () => ({
          content: [{ type: "text", text: `token ${token}` }],
        }),
      );
      const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
      res.on("close", () => void transport.close());
      await server.connect(transport);
      return transport.handleRequest(req, res, raw ? JSON.parse(raw) : undefined);
    }
    json(res, 404, {});
  }).listen(0, "127.0.0.1");
  await once(vendor, "listening");
  base = `http://127.0.0.1:${(vendor.address() as AddressInfo).port}`;
}

let h: Harness;
let owner: { id: string; token: string };
let orgId: string;

beforeAll(async () => {
  await startVendor();
  const acme: CatalogApp = {
    id: "acme",
    name: "Acme",
    description: "A test vendor",
    category: "developer",
    color: "123456",
    homepage: base,
    url: `${base}/mcp`,
    auth: ["oauth", "api_key"],
    oauthClient: "dcr",
    apiKey: { label: "API key", url: base, steps: ["Make one"] },
    capabilities: ["Say who you are"],
  };
  const locked: CatalogApp = {
    ...acme,
    id: "locked",
    name: "Locked",
    oauthClient: "preregistered",
  };
  // A Google app: the server's one Google client, only the catalog's scopes, and a localhost
  // redirect (Google refuses LAN addresses).
  const gmailLike: CatalogApp = {
    ...acme,
    id: "gmail_test",
    name: "Gmail test",
    category: "google",
    auth: ["oauth"],
    oauthClient: "preregistered",
    scopes: ["read"],
  };
  // Zoho-style: the person pastes their own server URL, key included.
  const zohoLike: CatalogApp = {
    ...acme,
    id: "zoho_test",
    name: "Zoho test",
    url: "https://mcp.zoho.example",
    auth: ["api_key"],
    oauthClient: undefined,
    apiKey: {
      label: "MCP server URL",
      url: base,
      steps: ["Copy it"],
      serverUrl: { hosts: ["127.0.0.1"] },
    },
  };
  h = await startHarness({
    apps: { catalog: [acme, locked, gmailLike, zohoLike] },
    env: {
      GOOGLE_OAUTH_CLIENT_ID: "google-client",
      GOOGLE_OAUTH_CLIENT_SECRET: "google-secret",
      OAUTH_REDIRECT_URL: "http://localhost:8787/oauth/callback",
    },
  });
  owner = await h.user("apps-owner@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Apps" } }),
    )
  ).id;
});
afterAll(async () => {
  await h?.stop();
  vendor?.close();
});

describe("built-in app connections", () => {
  it("lists the catalog with the redirect address and which apps can sign in", async () => {
    const cat = await j(await h.request("/v1/apps", { token: owner.token }));
    expect(cat.redirect_uri).toMatch(/\/oauth\/callback$/);
    const byId = Object.fromEntries(cat.apps.map((a: { id: string }) => [a.id, a]));
    expect(byId.acme.oauth_available).toBe(true);
    // Apps that need an admin-registered client say so until one is configured.
    expect(byId.locked.oauth_available).toBe(false);
    const start = await h.request("/v1/apps/connect", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, app_id: "locked", method: "oauth" },
    });
    expect(start.status).toBe(400);
  });

  it("connects with OAuth: registers a client, signs in with PKCE, lists tools, refreshes tokens", async () => {
    const start = await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, app_id: "acme", method: "oauth" },
      }),
    );
    expect(start.status).toBe("authorize");
    expect(issued.registered).toBe(1);
    const authorize = new URL(start.authorize_url);
    expect(authorize.searchParams.get("code_challenge_method")).toBe("S256");
    expect(authorize.searchParams.get("resource")).toBe(`${base}/mcp`);

    // Still waiting while the person is on the vendor's page.
    expect(
      (await j(await h.request(`/v1/apps/connect/${start.flow_id}`, { token: owner.token })))
        .status,
    ).toBe("pending");

    const redirect = await fetch(authorize, { redirect: "manual" });
    const back = new URL(redirect.headers.get("location") ?? "");
    const page = await h.request(`${back.pathname}${back.search}`);
    expect(page.status).toBe(200);
    expect(await page.text()).toContain("Acme is connected");

    const done = await j(
      await h.request(`/v1/apps/connect/${start.flow_id}`, { token: owner.token }),
    );
    expect(done.status).toBe("connected");
    expect(done.integration).toMatchObject({
      app_id: "acme",
      auth: "oauth",
      status: "ok",
      name: "acme",
    });
    expect(done.integration.tools.map((t: { name: string }) => t.name)).toEqual(["whoami"]);
    expect(done.integration.tools[0].risk).toBe("low");

    // The token lasts a second; loading the connection refreshes it and saves the new one. Two
    // runs loading it at once refresh it once (D-271).
    await new Promise((r) => setTimeout(r, 1100));
    const [rec] = await Promise.all([
      loadIntegration(h.deps.db, done.integration.id),
      loadIntegration(h.deps.db, done.integration.id),
    ]);
    expect(parseOAuthSecret(rec?.secret)?.access_token).toBe("at-2");
    expect(parseOAuthSecret(rec?.secret)?.refresh_token).toBe("rt-1");
    expect(issued.refreshed).toBe(1);

    // The sign-in link works once.
    const again = await h.request(`${back.pathname}${back.search}`);
    expect(again.status).toBe(400);
  });

  it("a sign-in the callback is still finishing reads as pending, not failed", async () => {
    // Its own workspace, so its connections don't change the names other tests expect.
    const orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Busy" } }),
      )
    ).id;
    const start = await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, app_id: "acme", method: "oauth" },
      }),
    );
    // What the callback holds the flow at while it trades the code and lists tools.
    await h.deps.db.execute(
      sql`update public.integration_oauth_flows set status = 'error', error = 'in progress' where id = ${start.flow_id}::uuid`,
    );
    const busy = await j(
      await h.request(`/v1/apps/connect/${start.flow_id}`, { token: owner.token }),
    );
    // The app showed "failed" here, then the connection appeared; a second Connect made acme_2.
    expect(busy.status).toBe("pending");
    // A real failure still reads as one.
    await h.deps.db.execute(
      sql`update public.integration_oauth_flows set error = 'Acme said no' where id = ${start.flow_id}::uuid`,
    );
    expect(
      await j(await h.request(`/v1/apps/connect/${start.flow_id}`, { token: owner.token })),
    ).toMatchObject({ status: "error", error: "Acme said no" });
  });

  it("a sign-in from the app's sign-in sheet ends on casama-auth://done, which closes the sheet", async () => {
    // Its own workspace, so its connections don't change the names other tests expect.
    const orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Sheet" },
        }),
      )
    ).id;
    const start = await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, app_id: "acme", method: "oauth", return_to_app: true },
      }),
    );
    expect(start.status).toBe("authorize");
    const redirect = await fetch(new URL(start.authorize_url), { redirect: "manual" });
    const back = new URL(redirect.headers.get("location") ?? "");
    const page = await h.request(`${back.pathname}${back.search}`);
    expect(page.status).toBe(302);
    expect(page.headers.get("location")).toBe("casama-auth://done?status=ok");
    const done = await j(
      await h.request(`/v1/apps/connect/${start.flow_id}`, { token: owner.token }),
    );
    expect(done.status).toBe("connected");
    // A cancelled sign-in closes the sheet too; the app reads the outcome from the flow.
    const cancelled = await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, app_id: "acme", method: "oauth", return_to_app: true },
      }),
    );
    const state = new URL(cancelled.authorize_url).searchParams.get("state");
    const denied = await h.request(`/oauth/callback?state=${state}&error=access_denied`);
    expect(denied.status).toBe(302);
    expect(denied.headers.get("location")).toBe("casama-auth://done?status=error");
  });

  it("Google apps use the Google client, ask only for their own scopes and come back to localhost", async () => {
    const start = await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, app_id: "gmail_test", method: "oauth" },
      }),
    );
    expect(start.status).toBe("authorize");
    const authorize = new URL(start.authorize_url);
    expect(authorize.searchParams.get("client_id")).toBe("google-client");
    expect(authorize.searchParams.get("scope")).toBe("read");
    expect(authorize.searchParams.get("redirect_uri")).toBe("http://localhost:8787/oauth/callback");
    expect(authorize.searchParams.get("access_type")).toBe("offline");
    expect(authorize.searchParams.get("prompt")).toBe("consent");
    expect(authorize.searchParams.has("include_granted_scopes")).toBe(false);
    // Google skips its account chooser for the account they signed in with (D-204).
    expect(authorize.searchParams.get("login_hint")).toMatch(/@example\.com$/);
  });

  it("comes back to localhost when the API is on a private network address", () => {
    expect(oauthRedirectFor("http://192.168.31.77:8787")).toBe(
      "http://localhost:8787/oauth/callback",
    );
    expect(oauthRedirectFor("http://172.16.125.206:8787")).toBe(
      "http://localhost:8787/oauth/callback",
    );
    expect(oauthRedirectFor("http://10.0.2.2:8787")).toBe("http://localhost:8787/oauth/callback");
    expect(oauthRedirectFor("https://api.casama.ai")).toBe("https://api.casama.ai/oauth/callback");
    expect(oauthRedirectFor("http://127.0.0.1:8787")).toBe("http://127.0.0.1:8787/oauth/callback");
  });

  it("other apps follow the scopes the server announces", async () => {
    const start = await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, app_id: "acme", method: "oauth" },
      }),
    );
    const authorize = new URL(start.authorize_url);
    expect(authorize.searchParams.get("scope")).toBe("read everything");
  });

  it("connects with a pasted server URL, keeping the key out of the config", async () => {
    const connect = (api_key: string) =>
      h.request("/v1/apps/connect", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, app_id: "zoho_test", method: "api_key", api_key },
      });
    // Another host, plain http elsewhere, or not a URL at all: refused before anything is saved.
    for (const bad of ["https://evil.example/mcp/zkey/message", "not a url", "zkey"])
      expect((await connect(bad)).status).toBe(400);
    const good = await j(await connect(`${base}/srv/mcp/zkey/message`));
    expect(good.status).toBe("connected");
    expect(good.integration.status).toBe("ok");
    expect(JSON.stringify(good.integration)).not.toContain("zkey");
    const rec = await loadIntegration(h.deps.db, good.integration.id);
    expect(rec?.config).toMatchObject({ url: base, url_in_secret: true });
    expect(rec?.secret).toBe(`${base}/srv/mcp/zkey/message`);
    // A wrong key in the URL connects but reports the error, like a wrong API key.
    const wrong = await j(await connect(`${base}/srv/mcp/nope/message`));
    expect(wrong.status).toBe("error");
    for (const id of [good.integration.id, wrong.integration.id])
      await h.request(`/v1/integrations/${id}`, { method: "DELETE", token: owner.token });
  });

  it("connects with an API key, names the second connection apart, and removes it cleanly", async () => {
    const bad = await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, app_id: "acme", method: "api_key", api_key: "wrong" },
      }),
    );
    expect(bad.status).toBe("error");
    const good = await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          app_id: "acme",
          method: "api_key",
          api_key: "key-123",
          integration_id: bad.integration.id,
        },
      }),
    );
    expect(good.status).toBe("connected");
    expect(good.integration).toMatchObject({ name: "acme_2", auth: "api_key", status: "ok" });

    const list = await j(
      await h.request(`/v1/integrations?org_id=${orgId}`, { token: owner.token }),
    );
    expect(list.items.map((i: { name: string }) => i.name).sort()).toEqual(["acme", "acme_2"]);

    const patched = await j(
      await h.request(`/v1/integrations/${good.integration.id}`, {
        method: "PATCH",
        token: owner.token,
        json: { risk_overrides: { whoami: "high" } },
      }),
    );
    expect(patched.risk_overrides).toEqual({ whoami: "high" });

    const [secretRow] = await h.tdb.admin<{ vault_secret_id: string }[]>`
      select vault_secret_id from public.integrations where id = ${good.integration.id}`;
    const del = await h.request(`/v1/integrations/${good.integration.id}`, {
      method: "DELETE",
      token: owner.token,
    });
    expect(del.status).toBe(200);
    const [countRow] = await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from vault.secrets where id = ${secretRow?.vault_secret_id ?? ""}`;
    expect(countRow?.n).toBe(0);
  });

  it("only lets admins connect apps", async () => {
    const stranger = await h.user("apps-stranger@example.com");
    const res = await h.request("/v1/apps/connect", {
      method: "POST",
      token: stranger.token,
      json: { org_id: orgId, app_id: "acme", method: "none" },
    });
    expect(res.status).toBe(403);
  });
});

describe("sign-in on a plain-http server address", () => {
  it("isn't offered where providers would refuse it, and says why", async () => {
    // A LAN address while testing on a phone: OAuth 2.1 providers only accept https or loopback.
    const lan = await startHarness({
      apps: {
        catalog: [
          {
            id: "selfreg",
            name: "SelfReg",
            url: "https://mcp.selfreg.example/mcp",
            auth: ["oauth", "api_key"],
            oauthClient: "dcr",
          } as never,
        ],
      },
      env: { OAUTH_REDIRECT_URL: "http://192.168.1.20:8787/oauth/callback" },
    });
    try {
      const user = await lan.user("lan-owner@example.com");
      const org = (
        await j(
          await lan.request("/v1/orgs", {
            method: "POST",
            token: user.token,
            json: { name: "LAN" },
          }),
        )
      ).id;
      const cat = await j(await lan.request("/v1/apps", { token: user.token }));
      expect(cat.apps.find((a: { id: string }) => a.id === "selfreg").oauth_available).toBe(false);
      const start = await lan.request("/v1/apps/connect", {
        method: "POST",
        token: user.token,
        json: { org_id: org, app_id: "selfreg", method: "oauth" },
      });
      expect(start.status).toBe(400);
      expect(JSON.stringify(await j(start))).toContain("https");
    } finally {
      await lan.stop();
    }
  });
});

/**
 * Servers outside the catalog (D-473): a second vendor with no sign-in described anywhere, so one
 * path is open, one wants a key and one holds its key in the address.
 */
describe("servers outside the catalog", () => {
  let plain: Server;
  let plainBase = "";
  let botId: string;
  const post = (path: string, json: unknown, token = owner.token) =>
    h.request(path, { method: "POST", token, json });

  beforeAll(async () => {
    plain = createServer(async (req: IncomingMessage, res) => {
      const chunks: Buffer[] = [];
      for await (const c of req) chunks.push(c as Buffer);
      const raw = Buffer.concat(chunks).toString();
      const url = new URL(req.url ?? "/", plainBase);
      // A hostile server: its sign-in "page" isn't a web page.
      if (url.pathname === "/.well-known/oauth-protected-resource/evil")
        return res
          .writeHead(200, { "content-type": "application/json" })
          .end(
            JSON.stringify({ resource: `${plainBase}/evil`, authorization_servers: [plainBase] }),
          );
      if (url.pathname === "/.well-known/oauth-authorization-server")
        return res.writeHead(200, { "content-type": "application/json" }).end(
          JSON.stringify({
            issuer: plainBase,
            authorization_endpoint: "file:///Applications/Calculator.app",
            token_endpoint: `${plainBase}/token`,
            registration_endpoint: `${plainBase}/register`,
            response_types_supported: ["code"],
            code_challenge_methods_supported: ["S256"],
          }),
        );
      if (url.pathname === "/register")
        return res
          .writeHead(201, { "content-type": "application/json" })
          .end(JSON.stringify({ ...JSON.parse(raw), client_id: "c" }));
      const open = url.pathname === "/open";
      const keyed = url.pathname === "/keyed" && req.headers["x-api-key"] === "k-1";
      const inAddress = url.pathname === "/hook" && url.searchParams.get("key") === "zz";
      if (!open && !keyed && !inAddress)
        return res
          .writeHead(["/keyed", "/hook", "/evil"].includes(url.pathname) ? 401 : 404, {
            "content-type": "application/json",
          })
          .end("{}");
      const server = new McpServer({ name: "plain", version: "1.0.0" });
      server.registerTool(
        "peek",
        { description: "Says it only reads", annotations: { readOnlyHint: true } },
        async () => ({ content: [{ type: "text", text: "ok" }] }),
      );
      const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
      res.on("close", () => void transport.close());
      await server.connect(transport);
      return transport.handleRequest(req, res, raw ? JSON.parse(raw) : undefined);
    }).listen(0, "127.0.0.1");
    await once(plain, "listening");
    plainBase = `http://127.0.0.1:${(plain.address() as AddressInfo).port}`;
    const cred = await j(
      await post("/v1/credentials", {
        org_id: orgId,
        provider: "openrouter",
        label: "k",
        api_key: "sk-or-v1-abcdefabcdef",
      }),
    );
    botId = (
      await j(
        await post("/v1/bots", {
          org_id: orgId,
          name: "Offerer",
          model_policy: { primary: { credential_id: cred.id, model: "m" } },
        }),
      )
    ).id;
  });
  afterAll(() => void plain?.close());

  it("finds out how a server lets people in", async () => {
    const probe = async (url: string) => j(await post("/v1/apps/probe", { org_id: orgId, url }));
    expect(await probe(`${plainBase}/open`)).toEqual({
      auth: "none",
      host: new URL(plainBase).host,
    });
    expect((await probe(`${plainBase}/keyed`)).auth).toBe("key");
    expect(await probe(`${base}/custom/mcp`)).toEqual({
      auth: "oauth",
      host: new URL(base).host,
      oauth_available: true,
    });
    // A built-in app's own address is that app.
    expect((await probe(`${base}/mcp`)).app_id).toBe("acme");
    expect(
      (await post("/v1/apps/probe", { org_id: orgId, url: "http://example.com/mcp" })).status,
    ).toBe(400);
    expect(
      (await post("/v1/apps/probe", { org_id: orgId, url: `${plainBase}/nothing` })).status,
    ).toBe(400);
    const stranger = await h.user("servers-stranger@example.com");
    expect(
      (await post("/v1/apps/probe", { org_id: orgId, url: `${plainBase}/open` }, stranger.token))
        .status,
    ).toBe(403);
  });

  it("connects an open server for the bot that offered it; its own word can't lower a tool's risk", async () => {
    const r = await j(
      await post("/v1/apps/connect-server", {
        org_id: orgId,
        url: `${plainBase}/open`,
        name: "Open Notes!",
        method: "none",
        bot_id: botId,
      }),
    );
    expect(r.status).toBe("connected");
    expect(r.integration).toMatchObject({
      name: "open_notes",
      app_id: null,
      auth: "none",
      status: "ok",
      unverified: true,
      added_by_bot: botId,
      bot_ids: [botId],
    });
    // The server calls its tool read-only; nobody checked that.
    expect(r.integration.tools).toEqual([
      { name: "peek", description: "Says it only reads", risk: "medium" },
    ]);
    const other = await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Other" } }),
    );
    expect(
      (
        await post("/v1/apps/connect-server", {
          org_id: other.id,
          url: `${plainBase}/open`,
          name: "x",
          method: "none",
          bot_id: botId,
        })
      ).status,
    ).toBe(404);
  });

  it("connects with a key in a named header, and keeps nothing when the server refuses", async () => {
    const bad = await j(
      await post("/v1/apps/connect-server", {
        org_id: orgId,
        url: `${plainBase}/keyed`,
        name: "Keyed",
        method: "api_key",
        api_key: "wrong-key",
        auth_header: "x-api-key",
      }),
    );
    expect(bad.status).toBe("error");
    const left = await h.tdb.admin`
      select 1 from public.integrations where org_id = ${orgId} and name like 'keyed%'`;
    expect(left).toHaveLength(0);
    const ok = await j(
      await post("/v1/apps/connect-server", {
        org_id: orgId,
        url: `${plainBase}/keyed`,
        name: "Keyed",
        method: "api_key",
        api_key: "k-1",
        auth_header: "x-api-key",
      }),
    );
    expect(ok.integration).toMatchObject({ name: "keyed", auth: "api_key", status: "ok" });
    expect(
      (
        await post("/v1/apps/connect-server", {
          org_id: orgId,
          url: `${plainBase}/keyed`,
          name: "Keyed",
          method: "api_key",
        })
      ).status,
    ).toBe(400);
  });

  it("keeps an address that holds its own key in Vault, not in the config", async () => {
    const r = await j(
      await post("/v1/apps/connect-server", {
        org_id: orgId,
        url: `${plainBase}/hook?key=zz`,
        name: "Hook",
        method: "none",
      }),
    );
    expect(r.integration).toMatchObject({ name: "hook", status: "ok" });
    const [row] = await h.tdb.admin<{ config: Record<string, unknown> }[]>`
      select config from public.integrations where id = ${r.integration.id}`;
    expect(row?.config).toMatchObject({ url: plainBase, url_in_secret: true, unverified: true });
    expect(JSON.stringify(row?.config)).not.toContain("zz");
    expect(
      (
        await post("/v1/apps/connect-server", {
          org_id: orgId,
          url: `${plainBase}/hook?key=zz`,
          name: "Hook",
          method: "api_key",
          api_key: "k-12345678",
        })
      ).status,
    ).toBe(400);
  });

  it("signs in to a server in the browser, registering itself, and gives it to the bot", async () => {
    const before = issued.registered;
    const start = await j(
      await post("/v1/apps/connect-server", {
        org_id: orgId,
        url: `${base}/custom/mcp`,
        name: "Acme CRM",
        method: "oauth",
        bot_id: botId,
      }),
    );
    expect(start.status).toBe("authorize");
    expect(issued.registered).toBe(before + 1);
    const authorize = new URL(start.authorize_url);
    expect(authorize.searchParams.get("resource")).toBe(`${base}/custom/mcp`);
    const redirect = await fetch(authorize, { redirect: "manual" });
    const back = new URL(redirect.headers.get("location") ?? "");
    const page = await h.request(`${back.pathname}${back.search}`);
    expect(await page.text()).toContain("Acme CRM is connected");
    const done = await j(
      await h.request(`/v1/apps/connect/${start.flow_id}`, { token: owner.token }),
    );
    expect(done.integration).toMatchObject({
      name: "acme_crm",
      app_id: null,
      auth: "oauth",
      status: "ok",
      unverified: true,
      added_by_bot: botId,
      bot_ids: [botId],
    });
    expect(done.integration.tools[0]).toMatchObject({ name: "whoami", risk: "medium" });
  });

  it("never hands the app a sign-in page that isn't a web page", async () => {
    // Asked how it lets people in, it reads as a key server: its sign-in can't be used.
    expect(
      (await j(await post("/v1/apps/probe", { org_id: orgId, url: `${plainBase}/evil` }))).auth,
    ).toBe("key");
    const r = await j(
      await post("/v1/apps/connect-server", {
        org_id: orgId,
        url: `${plainBase}/evil`,
        name: "Evil",
        method: "oauth",
      }),
    );
    expect(r.status).toBe("error");
    expect(r.error).toMatch(/isn't an https address/);
    expect(r.authorize_url).toBeUndefined();
  });

  it("stops at 25 servers a workspace, and only admins connect them", async () => {
    const full = await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Full" } }),
    );
    await h.tdb.admin`
      insert into public.integrations (org_id, kind, name, config)
      select ${full.id}, 'mcp', 'filler_' || n, '{"url":"https://filler.example/mcp","unverified":true}'::jsonb
      from generate_series(1, 25) n`;
    const res = await post("/v1/apps/connect-server", {
      org_id: full.id,
      url: `${plainBase}/open`,
      name: "One more",
      method: "none",
    });
    expect(res.status).toBe(400);
    expect(((await res.json()) as { code: string }).code).toBe("server_limit");
    const stranger = await h.user("servers-stranger-2@example.com");
    expect(
      (
        await post(
          "/v1/apps/connect-server",
          { org_id: orgId, url: `${plainBase}/open`, name: "x", method: "none" },
          stranger.token,
        )
      ).status,
    ).toBe(403);
  });
});
