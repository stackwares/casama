import { createAdapter, loadIntegration, parseOAuthSecret } from "@casama/agent";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

/**
 * Casama's own Zoho sign-in (D-350) against a fake Zoho reached through the injected fetch, so the
 * real host names apply: the sign-in starts on accounts.zoho.com, the person's account lives in
 * the EU data centre, and the code must be traded at accounts.zoho.eu.
 */
const seen = {
  tokenAt: [] as string[],
  tokenBody: null as URLSearchParams | null,
  refreshed: 0,
  sent: null as Record<string, unknown> | null,
  auth: [] as string[],
};
let access = "at-1";

const zohoFetch: typeof fetch = async (input, init) => {
  const url = new URL(input instanceof Request ? input.url : String(input));
  const reply = (status: number, data: unknown) =>
    new Response(JSON.stringify(data), { status, headers: { "content-type": "application/json" } });
  const auth = new Headers(init?.headers).get("authorization") ?? "";
  if (url.pathname === "/oauth/v2/token") {
    seen.tokenAt.push(url.origin);
    const body = new URLSearchParams(String(init?.body ?? ""));
    if (body.get("grant_type") === "refresh_token") {
      seen.refreshed++;
      access = "at-2";
      // Zoho keeps the refresh token and doesn't send it again.
      return reply(200, {
        access_token: "at-2",
        expires_in: 3600,
        api_domain: "https://www.zohoapis.eu",
        token_type: "Bearer",
      });
    }
    seen.tokenBody = body;
    if (body.get("code") !== "zcode") return reply(200, { error: "invalid_code" });
    return reply(200, {
      access_token: "at-1",
      refresh_token: "rt-1",
      expires_in: 1,
      api_domain: "https://www.zohoapis.eu",
      token_type: "Bearer",
    });
  }
  seen.auth.push(auth);
  if (auth !== `Zoho-oauthtoken ${access}`) return reply(401, { code: "INVALID_OAUTHTOKEN" });
  const at = `${url.host}${url.pathname}`;
  if (at === "mail.zoho.eu/api/accounts")
    return reply(200, { data: [{ accountId: "111", primaryEmailAddress: "ana@example.eu" }] });
  if (at === "www.zohoapis.eu/crm/v8/org") return reply(200, { org: [{ id: "c1" }] });
  // No Desk on this account.
  if (at === "desk.zoho.eu/api/v1/organizations") return reply(401, { errorCode: "INVALID_OAUTH" });
  if (at === "www.zohoapis.eu/books/v3/organizations")
    return reply(200, {
      organizations: [
        { organization_id: "b2", name: "Side", is_default_org: false },
        { organization_id: "b1", name: "Main", is_default_org: true },
      ],
    });
  if (at === "mail.zoho.eu/api/accounts/111/messages/search")
    return reply(200, {
      data: [
        {
          messageId: "m1",
          folderId: "f1",
          subject: "Invoice",
          sender: "Bo",
          fromAddress: "bo@x.com",
          receivedTime: "1763366400000",
          status: "0",
          summary: "Here it is",
        },
      ],
    });
  if (at === "mail.zoho.eu/api/accounts/111/messages" && init?.method === "POST") {
    seen.sent = JSON.parse(String(init.body));
    return reply(200, { data: { messageId: "m2" } });
  }
  if (at === "www.zohoapis.eu/books/v3/invoices")
    return reply(200, {
      invoices: [
        {
          invoice_id: "i1",
          invoice_number: "INV-1",
          customer_name: "Bo",
          status: "overdue",
          total: 10,
          balance: 10,
        },
      ],
      org: url.searchParams.get("organization_id"),
    });
  return reply(404, { message: `no route ${at}` });
};

let h: Harness;
let owner: { token: string };
let orgId: string;

beforeAll(async () => {
  h = await startHarness({
    apps: { fetch: zohoFetch },
    env: {
      ZOHO_OAUTH_CLIENT_ID: "zoho-client",
      ZOHO_OAUTH_CLIENT_SECRET: "zoho-secret",
      OAUTH_REDIRECT_URL: "http://localhost:8787/oauth/callback",
    },
  });
  owner = await h.user("zoho-owner@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Zoho" } }),
    )
  ).id;
});
afterAll(async () => {
  await h?.stop();
});

describe("Casama's own Zoho sign-in", () => {
  it("offers one Zoho app in place of the Composio tiles when the server has a Zoho client", async () => {
    const cat = await j(await h.request("/v1/apps", { token: owner.token }));
    const ids = cat.apps.map((a: { id: string }) => a.id);
    expect(ids).toContain("zoho_apps");
    expect(ids).toContain("zoho"); // the pasted-URL Zoho MCP stays
    for (const id of ["zoho_mail", "zoho_crm", "zoho_desk", "zoho_books"])
      expect(ids).not.toContain(id);
    expect(cat.apps.find((a: { id: string }) => a.id === "zoho_apps").oauth_available).toBe(true);
  });

  it("signs in through another data centre, finds the account's apps, and refreshes there", async () => {
    const start = await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, app_id: "zoho_apps", method: "oauth" },
      }),
    );
    expect(start.status).toBe("authorize");
    const authorize = new URL(start.authorize_url);
    expect(authorize.origin).toBe("https://accounts.zoho.com");
    expect(authorize.pathname).toBe("/oauth/v2/auth");
    expect(authorize.searchParams.get("client_id")).toBe("zoho-client");
    expect(authorize.searchParams.get("access_type")).toBe("offline");
    expect(authorize.searchParams.get("code_challenge_method")).toBe("S256");
    expect(authorize.searchParams.get("scope")).toContain("ZohoMail.messages.ALL,");
    const state = authorize.searchParams.get("state");

    // A forged callback naming some other "accounts server" never gets the client secret.
    const forged = await h.request(
      `/oauth/callback?state=${state}&code=zcode&location=eu&accounts-server=${encodeURIComponent("https://accounts.evil.example")}`,
    );
    expect(forged.status).toBe(400);
    expect(await forged.text()).toContain("unknown accounts server");
    expect(seen.tokenAt).toEqual([]);

    const start2 = await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, app_id: "zoho_apps", method: "oauth" },
      }),
    );
    const state2 = new URL(start2.authorize_url).searchParams.get("state");
    const page = await h.request(
      `/oauth/callback?state=${state2}&code=zcode&location=eu&accounts-server=${encodeURIComponent("https://accounts.zoho.eu")}`,
    );
    expect(await page.text()).toContain("Zoho is connected");
    // The code is traded at the EU server, and (the first token lasting a second) the refresh
    // when the connection is saved goes there too.
    expect(seen.tokenAt).toEqual(["https://accounts.zoho.eu", "https://accounts.zoho.eu"]);
    expect(seen.tokenBody?.get("client_secret")).toBe("zoho-secret");
    expect(seen.tokenBody?.get("code_verifier")).toBeTruthy();

    const done = await j(
      await h.request(`/v1/apps/connect/${start2.flow_id}`, { token: owner.token }),
    );
    expect(done.status).toBe("connected");
    expect(done.integration).toMatchObject({ app_id: "zoho_apps", status: "ok", kind: "mcp" });
    const tools = done.integration.tools.map((t: { name: string }) => t.name);
    expect(tools).toContain("mail_search");
    expect(tools).toContain("crm_search");
    expect(tools).toContain("books_list_invoices");
    // No Desk on this account: no Desk tools.
    expect(tools.some((t: string) => t.startsWith("desk_"))).toBe(false);
    const risk = Object.fromEntries(
      done.integration.tools.map((t: { name: string; risk: string }) => [t.name, t.risk]),
    );
    expect(risk.mail_send).toBe("high");
    expect(risk.books_send_invoice).toBe("high");
    expect(risk.mail_search).toBe("low");

    const [row] = await h.deps.db.execute<{ config: Record<string, any> }>(
      sql`select config from public.integrations where id = ${done.integration.id}::uuid`,
    );
    expect(row?.config.provider).toBe("zoho");
    expect(row?.config.zoho).toMatchObject({
      accounts_server: "https://accounts.zoho.eu",
      api_domain: "https://www.zohoapis.eu",
      mail_base: "https://mail.zoho.eu",
      mail: { account_id: "111", email: "ana@example.eu" },
      crm: true,
      desk: null,
      books: { org_id: "b1", name: "Main" },
    });

    // The refreshed token is what runs load.
    const rec = await loadIntegration(h.deps.db, done.integration.id, zohoFetch);
    const secret = parseOAuthSecret(rec?.secret);
    const [st] = await h.deps.db.execute<{ error: string | null }>(
      sql`select error from public.integrations where id = ${done.integration.id}::uuid`,
    );
    expect(st?.error ?? null).toBeNull();
    expect(secret?.access_token).toBe("at-2");
    expect(secret?.refresh_token).toBe("rt-1");
    expect(seen.refreshed).toBe(1);

    // Tools call Zoho's EU APIs with the fresh token.
    const adapter = createAdapter(rec!, { fetch: zohoFetch, secrets: [] });
    let structured: unknown;
    const found = JSON.parse(
      await adapter.callTool(
        "mail_search",
        { query: "invoice" },
        { onStructured: (v) => (structured = v) },
      ),
    );
    expect(found[0]).toMatchObject({ message_id: "m1", subject: "Invoice", unread: true });
    expect(structured).toEqual(found);
    const sent = JSON.parse(
      await adapter.callTool("mail_send", {
        to: "bo@x.com, cy@x.com",
        subject: "Hi",
        body: "Hello",
      }),
    );
    expect(sent).toEqual({ sent: true, message_id: "m2" });
    expect(seen.sent).toMatchObject({
      fromAddress: "ana@example.eu",
      toAddress: "bo@x.com,cy@x.com",
      mailFormat: "plaintext",
    });
    const inv = JSON.parse(await adapter.callTool("books_list_invoices", { status: "overdue" }));
    expect(inv[0]).toMatchObject({ invoice_id: "i1", number: "INV-1" });
    await expect(adapter.callTool("desk_list_tickets", {})).rejects.toThrow(/No Zoho tool/);

    // A revoked token reads as "reconnect".
    access = "revoked";
    await expect(adapter.callTool("mail_search", { query: "x" })).rejects.toThrow(/reconnect Zoho/);
    access = "at-2";
  });

  it("a refused code fails the sign-in with Zoho's reason", async () => {
    const start = await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, app_id: "zoho_apps", method: "oauth" },
      }),
    );
    const state = new URL(start.authorize_url).searchParams.get("state");
    const page = await h.request(
      `/oauth/callback?state=${state}&code=bad&accounts-server=https%3A%2F%2Faccounts.zoho.com`,
    );
    expect(page.status).toBe(400);
    expect(await page.text()).toContain("invalid_code");
  });
});
