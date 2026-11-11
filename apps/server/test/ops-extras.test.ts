/** Ops extras (D-145): the sign-up allowlist, Cloudflare AI Gateway, and Infisical as the secret store. */
import { randomUUID } from "node:crypto";
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { CredentialResolver, loadSecrets } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { standardWebhookSignature } from "../src/billing/dodo.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const HOOK_SECRET = `whsec_${Buffer.from("allowlist-hook-secret-0123").toString("base64")}`;
let h: Harness;
let infisical: Server;
let infisicalUrl = "";
const store = new Map<string, string>();
let _logins = 0;

beforeAll(async () => {
  infisical = createServer(async (req, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    const b = chunks.length ? JSON.parse(Buffer.concat(chunks).toString()) : {};
    const url = new URL(req.url ?? "/", "http://x");
    const send = (s: number, x: unknown) =>
      res.writeHead(s, { "content-type": "application/json" }).end(JSON.stringify(x));
    if (url.pathname === "/api/v1/auth/universal-auth/login") {
      if (b.clientSecret !== "inf-secret") return send(401, { message: "bad credentials" });
      _logins++;
      return send(200, { accessToken: "inf-access", expiresIn: 3600, tokenType: "Bearer" });
    }
    if (req.headers.authorization !== "Bearer inf-access") return send(401, {});
    if (url.pathname === "/api/v3/secrets/raw" && req.method === "GET") {
      expect(url.searchParams.get("workspaceId")).toBe("proj-1");
      return send(200, {
        secrets: [...store.entries()].map(([secretKey, secretValue]) => ({
          secretKey,
          secretValue,
        })),
      });
    }
    const m = url.pathname.match(/^\/api\/v3\/secrets\/raw\/([^/]+)$/);
    if (m) {
      const name = decodeURIComponent(m[1] as string);
      if (req.method === "POST") {
        if (store.has(name)) return send(400, { message: "Secret already exist" });
        store.set(name, b.secretValue);
        return send(200, { secret: { secretKey: name } });
      }
      if (req.method === "PATCH") return (store.set(name, b.secretValue), send(200, {}));
      if (req.method === "DELETE") return (store.delete(name), send(200, {}));
    }
    send(404, {});
  }).listen(0, "127.0.0.1");
  await once(infisical, "listening");
  infisicalUrl = `http://127.0.0.1:${(infisical.address() as AddressInfo).port}`;
  h = await startHarness({
    env: {
      SIGNUP_ALLOWED_EMAILS: "ana@example.com, @acme.com",
      AUTH_HOOK_SECRET: `v1,${HOOK_SECRET}`,
    },
  });
}, 60_000);
afterAll(async () => {
  await h?.stop();
  infisical?.close();
});

const hook = (email: string, provider = "email") => {
  const body = JSON.stringify({ user: { email, app_metadata: { provider } } });
  const id = `msg_${randomUUID()}`;
  const ts = String(Math.floor(Date.now() / 1000));
  return h.request("/hooks/auth/before-user-created", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "webhook-id": id,
      "webhook-timestamp": ts,
      "webhook-signature": `v1,${standardWebhookSignature(HOOK_SECRET, id, ts, body)}`,
    },
    body,
  });
};

describe("ops extras", () => {
  it("the sign-up allowlist admits listed emails and domains, by any sign-in method", async () => {
    expect((await hook("ana@example.com")).status).toBe(200);
    expect((await hook("Lee@ACME.com", "google")).status).toBe(200);
    const no = await hook("eve@example.com");
    expect(no.status).toBe(403);
    expect((await j(no)).error.message).toContain("approved email addresses");
    expect((await hook("bob@notacme.com", "google")).status).toBe(403);
  });

  it("model calls go through a Cloudflare AI Gateway when set, unless a credential has its own address", async () => {
    const u = await h.user("gw@example.com");
    const orgId = (
      await j(await h.request("/v1/orgs", { method: "POST", token: u.token, json: { name: "GW" } }))
    ).id;
    const own = (
      await j(
        await h.request("/v1/credentials", {
          method: "POST",
          token: u.token,
          json: { org_id: orgId, provider: "anthropic", label: "a", api_key: "sk-ant-gw-key-123" },
        }),
      )
    ).id;
    const custom = (
      await j(
        await h.request("/v1/credentials", {
          method: "POST",
          token: u.token,
          json: {
            org_id: orgId,
            provider: "openai",
            label: "o",
            api_key: "sk-oa-gw-key-123",
            base_url: "https://proxy.example.com/v1",
          },
        }),
      )
    ).id;
    const r = new CredentialResolver(h.handle.db, {
      aiGateway: { url: "https://gateway.ai.cloudflare.com/v1/acct/casama/", token: "cf-token" },
    });
    expect(await r.resolve(orgId, { credential_id: own, model: "claude-x" })).toMatchObject({
      baseUrl: "https://gateway.ai.cloudflare.com/v1/acct/casama/anthropic/v1",
      headers: { "cf-aig-authorization": "Bearer cf-token" },
    });
    expect((await r.resolve(orgId, { credential_id: custom, model: "gpt-x" })).baseUrl).toBe(
      "https://proxy.example.com/v1",
    );
    const only = new CredentialResolver(h.handle.db, {
      aiGateway: { url: "https://gw.example/v1/a/b", providers: ["openai"] },
    });
    expect(
      (await only.resolve(orgId, { credential_id: own, model: "claude-x" })).baseUrl,
    ).toBeUndefined();
  });

  it("Infisical as the secret store: move existing secrets, add new ones, bots read them, and back to Vault", async () => {
    const u = await h.user("sec@example.com");
    const orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: u.token, json: { name: "Sec" } }),
      )
    ).id;
    const botId = (
      await j(
        await h.request("/v1/bots", {
          method: "POST",
          token: u.token,
          json: { org_id: orgId, name: "Sly" },
        }),
      )
    ).id;
    await h.request("/v1/secrets", {
      method: "POST",
      token: u.token,
      json: {
        org_id: orgId,
        name: "OLD_KEY",
        value: "old-value",
        allowed_hosts: ["api.example.com"],
      },
    });

    const bad = await h.request(`/v1/orgs/${orgId}/secret-store`, {
      method: "PUT",
      token: u.token,
      json: {
        site_url: infisicalUrl,
        project_id: "proj-1",
        client_id: "cid",
        client_secret: "wrong",
      },
    });
    expect(bad.status).toBe(400);
    const set = await j(
      await h.request(`/v1/orgs/${orgId}/secret-store`, {
        method: "PUT",
        token: u.token,
        json: {
          site_url: infisicalUrl,
          project_id: "proj-1",
          client_id: "cid",
          client_secret: "inf-secret",
          move_existing: true,
        },
      }),
    );
    expect(set).toMatchObject({
      provider: "infisical",
      project_id: "proj-1",
      environment: "prod",
      secret_path: "/",
    });
    expect(store.get("OLD_KEY")).toBe("old-value");
    const [moved] = await h.tdb.admin<
      { store: string; vault_secret_id: string | null }[]
    >`select store, vault_secret_id from public.secrets where name = 'OLD_KEY'`;
    expect(moved).toEqual({ store: "infisical", vault_secret_id: null });

    expect(
      (
        await h.request("/v1/secrets", {
          method: "POST",
          token: u.token,
          json: {
            org_id: orgId,
            name: "NEW_KEY",
            value: "new-value",
            allowed_hosts: ["api.example.com"],
          },
        })
      ).status,
    ).toBe(201);
    expect(store.get("NEW_KEY")).toBe("new-value");
    expect(
      await h.tdb
        .admin`select 1 from public.secrets where name = 'NEW_KEY' and vault_secret_id is null and store = 'infisical'`,
    ).toHaveLength(1);
    const loaded = await loadSecrets(h.handle.db, orgId, botId);
    expect(loaded.map((s) => [s.name, s.value]).sort()).toEqual([
      ["NEW_KEY", "new-value"],
      ["OLD_KEY", "old-value"],
    ]);

    // Back to Vault: values are copied back first.
    expect(
      (
        await j(
          await h.request(`/v1/orgs/${orgId}/secret-store`, { method: "DELETE", token: u.token }),
        )
      ).provider,
    ).toBe("vault");
    const back = await h.tdb.admin<{ name: string; store: string; v: string }[]>`
      select s.name, s.store, v.decrypted_secret as v from public.secrets s join vault.decrypted_secrets v on v.id = s.vault_secret_id where s.org_id = ${orgId} order by s.name`;
    expect(back).toEqual([
      { name: "NEW_KEY", store: "vault", v: "new-value" },
      { name: "OLD_KEY", store: "vault", v: "old-value" },
    ]);
  });
});
