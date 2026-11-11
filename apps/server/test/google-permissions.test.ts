/** Google sign-in and permissions (D-130): no restricted scopes in Casama's own app; inbox through Composio on Cloud. */
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { APP_CATALOG } from "@casama/domain";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { catalogFor } from "../src/api/routes/apps.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let composio: Server;
const calls: Array<{ path: string; key: string; body: unknown }> = [];

beforeAll(async () => {
  composio = createServer(async (req, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    calls.push({
      path: req.url ?? "",
      key: String(req.headers["x-api-key"]),
      body: chunks.length ? JSON.parse(Buffer.concat(chunks).toString()) : null,
    });
    res.setHeader("content-type", "application/json");
    if (req.url?.startsWith("/api/v3/auth_configs?")) return res.end(JSON.stringify({ items: [] }));
    if (req.url === "/api/v3/auth_configs")
      return res.end(JSON.stringify({ auth_config: { id: "ac_1" } }));
    if (req.url === "/api/v3/connected_accounts/link")
      return res.end(JSON.stringify({ redirect_url: "https://composio.example/signin/123" }));
    res.writeHead(404).end("{}");
  }).listen(0, "127.0.0.1");
  await once(composio, "listening");
  h = await startHarness({
    env: {
      COMPOSIO_API_KEY: "cmp-key",
      INSTANCE_ADMIN_EMAILS: "instance-owner@example.com",
      COMPOSIO_API_URL: `http://127.0.0.1:${(composio.address() as AddressInfo).port}`,
    },
  });
}, 60_000);
afterAll(async () => {
  await h?.stop();
  composio?.close();
});

describe("Google permissions", () => {
  it("Casama's Google apps ask only for non-restricted scopes; Gmail (the inbox) is the exception", () => {
    const google = APP_CATALOG.filter((a) => a.category === "google");
    const scopes = google.filter((a) => !a.inbox).flatMap((a) => a.scopes ?? []);
    const restricted = [/gmail\./, /mail\.google\.com/, /^.*\/drive$/, /drive\.readonly/];
    expect(scopes.filter((s) => restricted.some((r) => r.test(s)))).toEqual([]);
    expect(google.filter((a) => a.inbox).map((a) => a.id)).toEqual(["gmail"]);
    expect(google.find((a) => a.id === "gmail")?.scopes).toEqual([
      "https://www.googleapis.com/auth/gmail.modify",
      "https://www.googleapis.com/auth/gmail.compose",
    ]);
  });

  it("on Casama Cloud Gmail goes through Composio, or is hidden without a key; self-hosted keeps its own client", () => {
    const gmail = (o: { cloud: boolean; composio: boolean }) =>
      catalogFor(APP_CATALOG, o).find((a) => a.id === "gmail");
    expect(gmail({ cloud: true, composio: false })).toBeUndefined();
    expect(gmail({ cloud: true, composio: true })?.auth).toEqual(["managed"]);
    expect(gmail({ cloud: false, composio: false })?.auth).toEqual(["oauth"]);
  });

  it("Google's apps go through Composio even with a Google client, unless the owner picks Google's servers (D-166)", () => {
    const google = (o: { cloud: boolean; googleDirect?: boolean }) =>
      catalogFor(APP_CATALOG, { ...o, composio: true, hasClient: () => true }).find(
        (a) => a.id === "gmail",
      )?.auth;
    expect(google({ cloud: false })).toEqual(["managed"]);
    expect(google({ cloud: false, googleDirect: true })).toEqual(["oauth"]);
    // Casama Cloud ignores the choice: Developer Preview terms bar public apps.
    expect(google({ cloud: true, googleDirect: true })).toEqual(["managed"]);
    // Choosing Google's servers doesn't change other apps.
    const slack = catalogFor(APP_CATALOG, {
      cloud: false,
      composio: true,
      googleDirect: true,
    }).find((a) => a.id === "slack")?.auth;
    expect(slack).toEqual(["managed"]);
  });

  it("apps whose own sign-in isn't set up connect through Composio when the server has a key (D-172)", async () => {
    const view = catalogFor(APP_CATALOG, { cloud: false, composio: true, hasClient: () => false });
    expect(view.find((a) => a.id === "slack")?.auth).toEqual(["managed"]);
    expect(view.find((a) => a.id === "github")?.auth).toEqual(["managed", "api_key"]);
    // Apps that register themselves keep their own one-click sign-in.
    expect(view.find((a) => a.id === "notion")?.auth).toEqual(["oauth"]);
    // With the vendor's client set up, the app's own sign-in comes first again.
    const withSlack = catalogFor(APP_CATALOG, {
      cloud: false,
      composio: true,
      hasClient: (id) => id === "slack",
    });
    expect(withSlack.find((a) => a.id === "slack")?.auth).toEqual(["oauth"]);
    // No Composio key: unchanged (the connect sheet offers the hubs instead).
    const none = catalogFor(APP_CATALOG, { cloud: false, composio: false });
    expect(none.find((a) => a.id === "slack")?.auth).toEqual(["oauth"]);
    // Casama Cloud: Google's apps only through Composio.
    const cloud = catalogFor(APP_CATALOG, { cloud: true, composio: true });
    expect(cloud.find((a) => a.id === "google_calendar")?.auth).toEqual(["managed"]);
    expect(
      catalogFor(APP_CATALOG, { cloud: true, composio: false }).some(
        (a) => a.category === "google",
      ),
    ).toBe(false);
  });

  it("the instance owner switches between the server's Composio account and people's own (D-173)", async () => {
    const owner = await h.user("instance-owner@example.com");
    const someone = await h.user("not-the-owner@example.com");
    const slackAuth = async () =>
      (await j(await h.request("/v1/apps", { token: owner.token }))).apps.find(
        (a: { id: string }) => a.id === "slack",
      ).auth;
    expect(await j(await h.request("/v1/admin/connections", { token: owner.token }))).toMatchObject({
      composio: "server",
      google: "composio",
      composio_key: true,
    });
    expect(await slackAuth()).toEqual(["managed"]);
    const denied = await h.request("/v1/admin/connections", {
      method: "PUT",
      token: someone.token,
      json: { composio: "own" },
    });
    expect(denied.status).toBe(403);
    const own = await h.request("/v1/admin/connections", {
      method: "PUT",
      token: owner.token,
      json: { composio: "own" },
    });
    expect(await j(own)).toMatchObject({ composio: "own", google: "composio" });
    // People's own accounts: Slack's sheet offers the hubs, and the server account is refused.
    expect(await slackAuth()).toEqual(["oauth"]);
    expect(
      (
        await h.request("/v1/apps/connect", {
          method: "POST",
          token: owner.token,
          json: { org_id: crypto.randomUUID(), app_id: "slack", method: "managed" },
        })
      ).status,
    ).not.toBe(200);
    await h.request("/v1/admin/connections", {
      method: "PUT",
      token: owner.token,
      json: { composio: "server" },
    });
    expect(await slackAuth()).toEqual(["managed"]);
    // Google's servers instead of Composio for Google's apps; leaving composio out keeps it.
    const direct = await h.request("/v1/admin/connections", {
      method: "PUT",
      token: owner.token,
      json: { google: "direct" },
    });
    expect(await j(direct)).toMatchObject({ composio: "server", google: "direct" });
    await h.request("/v1/admin/connections", {
      method: "PUT",
      token: owner.token,
      json: { google: "composio" },
    });
  });

  it("connecting Slack through Composio asks Composio for its Slack sign-in", async () => {
    const owner = await h.user("composio-slack@example.com");
    const orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "S" } }),
      )
    ).id;
    const before = calls.length;
    const r = await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, app_id: "slack", method: "managed" },
      }),
    );
    expect(r).toMatchObject({
      status: "authorize",
      authorize_url: "https://composio.example/signin/123",
    });
    expect(calls[before]?.path).toContain("/api/v3/auth_configs?toolkit_slug=slack");
    expect(calls[before + 1]).toMatchObject({
      path: "/api/v3/auth_configs",
      body: { toolkit: { slug: "slack" } },
    });
    expect(calls[before + 2]).toMatchObject({
      path: "/api/v3/connected_accounts/link",
      body: { auth_config_id: "ac_1", user_id: orgId },
    });
    const [i] = await h.tdb.admin<{ name: string; config: { toolkits: string[] } }[]>`
      select name, config from public.integrations where org_id = ${orgId}`;
    expect(i).toMatchObject({ name: "apps", config: { toolkits: ["slack"] } });
  });

  it("connecting the inbox through Composio's managed sign-in returns the sign-in page", async () => {
    const owner = await h.user("google@example.com");
    const orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "G" } }),
      )
    ).id;
    const before = calls.length;
    const r = await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, app_id: "gmail", method: "managed" },
      }),
    );
    expect(r).toMatchObject({
      status: "authorize",
      authorize_url: "https://composio.example/signin/123",
    });
    expect(calls[before + 1]).toMatchObject({
      path: "/api/v3/auth_configs",
      key: "cmp-key",
      body: { toolkit: { slug: "gmail" } },
    });
    expect(calls[before + 2]?.body).toMatchObject({ user_id: orgId });
    const [i] = await h.tdb.admin<
      { kind: string; config: { toolkits: string[]; managed: boolean } }[]
    >`select kind, config from public.integrations where org_id = ${orgId}`;
    expect(i).toMatchObject({ kind: "composio", config: { managed: true, toolkits: ["gmail"] } });
  });
});
