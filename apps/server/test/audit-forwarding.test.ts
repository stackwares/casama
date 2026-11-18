/** Audit-log forwarding (D-146, enterprise): webhook, OTLP and S3, at least once from a cursor. */
import { createHmac } from "node:crypto";
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { forwardAuditLogs } from "@casama/ee";
import { exportPKCS8, exportSPKI, generateKeyPair, importPKCS8, SignJWT } from "jose";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let sink: Server;
let sinkUrl = "";
const got: Array<{ path: string; headers: Record<string, string>; body: string }> = [];
let failNext = 1;

beforeAll(async () => {
  sink = createServer(async (req, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    got.push({
      path: req.url ?? "",
      headers: req.headers as Record<string, string>,
      body: Buffer.concat(chunks).toString(),
    });
    if (req.url === "/hook" && failNext > 0) {
      failNext--;
      return res.writeHead(503).end("busy");
    }
    res.writeHead(200).end("{}");
  }).listen(0, "127.0.0.1");
  await once(sink, "listening");
  sinkUrl = `http://127.0.0.1:${(sink.address() as AddressInfo).port}`;
  const { publicKey, privateKey } = await generateKeyPair("EdDSA", { extractable: true });
  const license = await new SignJWT({ features: ["audit_forwarding"], seats: 5 })
    .setProtectedHeader({ alg: "EdDSA" })
    .setIssuer("casama-licensing")
    .setSubject("Acme")
    .setExpirationTime("30d")
    .sign(await importPKCS8(await exportPKCS8(privateKey), "EdDSA"));
  h = await startHarness({
    env: { CASAMA_LICENSE_KEY: license, CASAMA_LICENSE_PUBLIC_KEY: await exportSPKI(publicKey) },
  });
}, 60_000);
afterAll(async () => {
  await h?.stop();
  sink?.close();
});

describe("audit-log forwarding", () => {
  it("streams new audit rows to a signed webhook, OTLP and S3, retrying a failed batch", async () => {
    const owner = await h.user("audit@example.com");
    const orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Audit" },
        }),
      )
    ).id;
    const member = await h.user("audit-member@example.com");
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
    expect(
      (
        await h.request(`/v1/orgs/${orgId}/audit-forwarders`, {
          method: "POST",
          token: member.token,
          json: { kind: "otlp", config: { url: sinkUrl } },
        })
      ).status,
    ).toBe(403);
    expect(
      (
        await h.request(`/v1/orgs/${orgId}/audit-forwarders`, {
          method: "POST",
          token: owner.token,
          json: { kind: "webhook", config: { url: `${sinkUrl}/hook` } },
        })
      ).status,
    ).toBe(400);

    const add = (json: unknown) =>
      h.request(`/v1/orgs/${orgId}/audit-forwarders`, { method: "POST", token: owner.token, json });
    expect(
      (await add({ kind: "webhook", config: { url: `${sinkUrl}/hook` }, secret: "whsec_audit" }))
        .status,
    ).toBe(201);
    expect(
      (
        await add({
          kind: "otlp",
          config: { url: `${sinkUrl}/otel` },
          secret: JSON.stringify({ authorization: "Bearer otel-token" }),
        })
      ).status,
    ).toBe(201);
    expect(
      (
        await add({
          kind: "s3",
          config: { endpoint: `${sinkUrl}/s3`, region: "auto", bucket: "audit", prefix: "logs" },
          secret: JSON.stringify({ access_key_id: "AKID", secret_access_key: "s3secret" }),
        })
      ).status,
    ).toBe(201);
    // Rows from now on (forwarders start at "now" by default).
    await new Promise((r) => setTimeout(r, 20));
    for (const action of ["bot.created", "secret.created", "member.invited"])
      await h.tdb
        .admin`insert into public.audit_log (org_id, actor_type, actor_id, action, metadata) values (${orgId}, 'user', ${owner.id}, ${action}, '{"x":1}'::jsonb)`;

    // First pass: the webhook is busy (cursor stays), OTLP and S3 take the batch.
    await forwardAuditLogs(h.handle.db);
    const hook1 = got.filter((g) => g.path === "/hook");
    expect(hook1).toHaveLength(1);
    const [busy] = await h.tdb.admin<
      { last_error: string; sent_rows: string }[]
    >`select last_error, sent_rows from public.audit_forwarders where kind = 'webhook'`;
    expect(busy).toMatchObject({ last_error: "The webhook answered 503", sent_rows: "0" });
    // Second pass: the webhook gets the same rows; nothing is sent twice to the others.
    await forwardAuditLogs(h.handle.db);
    const hooks = got.filter((g) => g.path === "/hook");
    expect(hooks).toHaveLength(2);
    expect(hooks[1]!.body).toBe(hooks[0]!.body.replace(/x/g, "x"));
    const delivered = JSON.parse(hooks[1]!.body) as { events: Array<{ action: string }> };
    expect(delivered.events.map((e) => e.action).filter((a) => !a.startsWith("audit."))).toEqual([
      "bot.created",
      "secret.created",
      "member.invited",
    ]);
    const sig = hooks[1]!.headers["x-casama-signature"] as string;
    const t = /t=(\d+)/.exec(sig)![1];
    expect(sig).toBe(
      `t=${t},v1=${createHmac("sha256", "whsec_audit").update(`${t}.${hooks[1]!.body}`).digest("hex")}`,
    );

    const otel = got.filter((g) => g.path === "/otel/v1/logs");
    expect(otel).toHaveLength(1);
    expect(otel[0]!.headers.authorization).toBe("Bearer otel-token");
    const logs = JSON.parse(otel[0]!.body);
    expect(
      logs.resourceLogs[0].scopeLogs[0].logRecords.map(
        (l: { body: { stringValue: string } }) => l.body.stringValue,
      ),
    ).toContain("member.invited");

    const s3 = got.filter((g) => g.path.startsWith("/s3/audit/logs/"));
    expect(s3).toHaveLength(1);
    expect(s3[0]!.headers.authorization).toMatch(
      /^AWS4-HMAC-SHA256 Credential=AKID\/\d{8}\/auto\/s3\/aws4_request, SignedHeaders=content-type;host;x-amz-content-sha256;x-amz-date, Signature=[0-9a-f]{64}$/,
    );
    expect(
      s3[0]!.body
        .trim()
        .split("\n")
        .map((l) => JSON.parse(l).action),
    ).toContain("secret.created");

    // Nothing new: nothing sent.
    const before = got.length;
    expect(await forwardAuditLogs(h.handle.db)).toBe(0);
    expect(got.length).toBe(before);
    const list = (
      await j(await h.request(`/v1/orgs/${orgId}/audit-forwarders`, { token: owner.token }))
    ).items as Array<{ kind: string; sent_rows: number; last_error: string | null }>;
    expect(list.find((f) => f.kind === "webhook")).toMatchObject({ last_error: null });
    expect(list.every((f) => f.sent_rows >= 3)).toBe(true);
  });

  it("needs the enterprise license", async () => {
    const plain = await startHarness();
    const u = await plain.user("nolicense@example.com");
    const orgId = (
      await j(
        await plain.request("/v1/orgs", {
          method: "POST",
          token: u.token,
          json: { name: "Plain" },
        }),
      )
    ).id;
    expect(
      (await plain.request(`/v1/orgs/${orgId}/audit-forwarders`, { token: u.token })).status,
    ).toBe(402);
    await plain.stop();
  });
});
