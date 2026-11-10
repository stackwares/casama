import { describe, expect, it } from "vitest";
import { composioDirectory, pipedreamDirectory } from "../src/integrations.ts";

type Call = { url: string; method: string; body: unknown; headers: Record<string, string> };

function fake(routes: Record<string, unknown>) {
  const calls: Call[] = [];
  const f = (async (input: string | URL, init?: RequestInit) => {
    const url = String(input);
    calls.push({
      url,
      method: init?.method ?? "GET",
      body: init?.body ? JSON.parse(String(init.body)) : undefined,
      headers: (init?.headers as Record<string, string>) ?? {},
    });
    const key = Object.keys(routes).find((k) => url.includes(k));
    return new Response(JSON.stringify(key ? routes[key] : {}), { status: key ? 200 : 404 });
  }) as typeof fetch;
  return { f, calls };
}

const rec = (kind: "composio" | "pipedream", config: Record<string, unknown>) => ({
  id: "i1",
  org_id: "org-1",
  kind,
  name: kind,
  config,
  secret: "secret-key",
});

describe("guided provider connections", () => {
  it("Composio: searches toolkits, starts a managed sign-in, and reads account status", async () => {
    const { f, calls } = fake({
      "/api/v3/toolkits": {
        items: [
          { slug: "gmail", name: "Gmail", meta: { description: "Email", logo: "https://logo" } },
        ],
      },
      "/api/v3/auth_configs": { auth_config: { id: "ac_1" } },
      "/api/v3/connected_accounts?": { items: [{ toolkit: { slug: "gmail" }, status: "ACTIVE" }] },
      "/api/v3/connected_accounts": { id: "ca_1", redirect_url: "https://composio.dev/link/abc" },
    });
    const dir = composioDirectory(rec("composio", {}), f);
    expect(await dir.apps("mail")).toEqual([
      { slug: "gmail", name: "Gmail", description: "Email", logo: "https://logo" },
    ]);
    expect(calls[0]?.url).toContain("search=mail");
    expect(calls[0]?.headers["x-api-key"]).toBe("secret-key");
    expect(await dir.connect("gmail", "https://api.test/oauth/done")).toEqual({
      redirect_url: "https://composio.dev/link/abc",
    });
    expect(calls[1]?.body).toEqual({
      toolkit: { slug: "gmail" },
      auth_config: { type: "use_composio_managed_auth" },
    });
    expect(calls[2]?.body).toEqual({
      auth_config: { id: "ac_1" },
      connection: { user_id: "org-1", callback_url: "https://api.test/oauth/done" },
    });
    expect(await dir.accounts()).toEqual([{ app: "gmail", status: "connected" }]);
  });

  it("Pipedream: searches apps, makes a Connect Link for one app, and reads accounts", async () => {
    const { f, calls } = fake({
      "/v1/oauth/token": { access_token: "pd-token", expires_in: 3600 },
      "/v1/apps": {
        data: [{ name_slug: "slack", name: "Slack", description: "Chat", img_src: "https://img" }],
      },
      "/tokens": {
        token: "ctok",
        connect_link_url: "https://pipedream.com/_static/connect.html?token=ctok&connectLink=true",
      },
      "/accounts": { data: [{ app: { name_slug: "slack" }, healthy: true }] },
    });
    const dir = pipedreamDirectory(rec("pipedream", { project_id: "proj_1", client_id: "cid" }), f);
    expect(await dir.apps("sl")).toEqual([
      { slug: "slack", name: "Slack", description: "Chat", logo: "https://img" },
    ]);
    const link = await dir.connect("slack", "https://api.test/oauth/done");
    expect(link.redirect_url).toBe(
      "https://pipedream.com/_static/connect.html?token=ctok&connectLink=true&app=slack",
    );
    const tokenCall = calls.find((c) => c.url.endsWith("/v1/connect/proj_1/tokens"));
    expect(tokenCall?.body).toEqual({
      external_user_id: "org-1",
      success_redirect_uri: "https://api.test/oauth/done",
    });
    expect(tokenCall?.headers.authorization).toBe("Bearer pd-token");
    expect(await dir.accounts()).toEqual([{ app: "slack", status: "connected" }]);
  });
});
