import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { exportPKCS8, exportSPKI, generateKeyPair, importPKCS8, SignJWT } from "jose";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

/** ee/ (Phase 8, D-073): license-gated audit export and SAML SSO. */
describe("enterprise features", () => {
  let licensed: Harness;
  let unlicensed: Harness;
  let auth: Server;
  const providers: Array<{ method: string; body: string; auth?: string }> = [];
  let owner: { token: string };
  let member: { id: string; token: string };
  let orgId: string;

  beforeAll(async () => {
    const { publicKey, privateKey } = await generateKeyPair("EdDSA", { extractable: true });
    const license = await new SignJWT({ features: ["audit_export", "sso"], seats: 10 })
      .setProtectedHeader({ alg: "EdDSA" })
      .setIssuer("kasama-licensing")
      .setSubject("Acme Corp")
      .setExpirationTime("30d")
      .sign(await importPKCS8(await exportPKCS8(privateKey), "EdDSA"));
    auth = createServer(async (req, res) => {
      let body = "";
      for await (const c of req) body += c;
      providers.push({ method: req.method ?? "", body, auth: req.headers.authorization });
      res.writeHead(req.method === "POST" ? 201 : 200, { "content-type": "application/json" });
      res.end(JSON.stringify({ id: "sso-provider-1", saml: {} }));
    });
    await new Promise<void>((r) => auth.listen(0, "127.0.0.1", r));
    const authUrl = `http://127.0.0.1:${(auth.address() as AddressInfo).port}`;
    licensed = await startHarness({
      env: {
        KASAMA_LICENSE_KEY: license,
        KASAMA_LICENSE_PUBLIC_KEY: await exportSPKI(publicKey),
        SUPABASE_URL: authUrl,
        SUPABASE_SERVICE_ROLE_KEY: "service-role-test-key",
      },
    });
    unlicensed = await startHarness();
    owner = await licensed.user("ee-owner@example.com");
    member = await licensed.user("ee-member@example.com");
    orgId = (
      await j(
        await licensed.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Acme" },
        }),
      )
    ).id;
    await licensed.handle.db.execute(
      (await import("drizzle-orm"))
        .sql`insert into public.memberships (org_id, user_id, role) values (${orgId}::uuid, ${member.id}::uuid, 'member')`,
    );
    await licensed.request(`/v1/orgs/${orgId}/settings`, {
      method: "PATCH",
      token: owner.token,
      json: { run_event_retention_days: 90 },
    });
  }, 180_000);
  afterAll(async () => {
    await licensed?.stop();
    await unlicensed?.stop();
    auth?.close();
  });

  it("without a license the enterprise endpoints answer 402 and the rest works", async () => {
    const u = await unlicensed.user("ee-free@example.com");
    const org = (
      await j(
        await unlicensed.request("/v1/orgs", {
          method: "POST",
          token: u.token,
          json: { name: "Free" },
        }),
      )
    ).id;
    const res = await unlicensed.request(`/v1/orgs/${org}/audit-log/export`, { token: u.token });
    expect(res.status).toBe(402);
    expect((await j(res)).code).toBe("license_required");
  });

  it("exports the audit log as CSV (admins only)", async () => {
    const res = await licensed.request(`/v1/orgs/${orgId}/audit-log/export`, {
      token: owner.token,
    });
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toContain("text/csv");
    const csv = await res.text();
    expect(csv.split("\n")[0]).toBe(
      "id,created_at,actor_type,actor_id,action,target_type,target_id,metadata",
    );
    expect(csv).toContain("org.settings");
    expect(
      (await licensed.request(`/v1/orgs/${orgId}/audit-log/export`, { token: member.token }))
        .status,
    ).toBe(403);
    const json = await j(
      await licensed.request(`/v1/orgs/${orgId}/audit-log/export?format=json`, {
        token: owner.token,
      }),
    );
    expect(json.items.some((r: { action: string }) => r.action === "audit.export")).toBe(true);
  });

  it("registers a SAML identity provider with Supabase Auth", async () => {
    const bad = await licensed.request(`/v1/orgs/${orgId}/sso`, {
      method: "POST",
      token: owner.token,
      json: { domains: ["acme.com"] },
    });
    expect(bad.status).toBe(400);
    const res = await licensed.request(`/v1/orgs/${orgId}/sso`, {
      method: "POST",
      token: owner.token,
      json: { metadata_url: "https://idp.acme.com/saml/metadata", domains: ["Acme.com"] },
    });
    expect(res.status).toBe(201);
    expect(providers[0]).toMatchObject({ method: "POST", auth: "Bearer service-role-test-key" });
    expect(JSON.parse(providers[0]?.body ?? "{}")).toEqual({
      type: "saml",
      metadata_url: "https://idp.acme.com/saml/metadata",
      domains: ["acme.com"],
    });
    expect(
      await j(await licensed.request(`/v1/orgs/${orgId}/sso`, { token: owner.token })),
    ).toEqual({
      configured: true,
      domains: ["acme.com"],
    });
    expect(
      (await licensed.request(`/v1/orgs/${orgId}/sso`, { method: "DELETE", token: owner.token }))
        .status,
    ).toBe(200);
    expect(providers.at(-1)?.method).toBe("DELETE");
  });

  it("shows the license in the admin console", async () => {
    const items = (await j(await licensed.request("/v1/admin/services", { token: owner.token })))
      .items;
    const l = items.find((i: { name: string }) => i.name === "Enterprise license");
    expect(l).toMatchObject({ configured: true, healthy: true });
    expect(l.detail).toContain("Acme Corp");
  });
});
