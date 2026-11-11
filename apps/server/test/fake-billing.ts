/**
 * Local stand-ins for Dodo Payments, the App Store Server API and the Google Play Developer API,
 * using their real request and response shapes. Apple payloads are signed by a throwaway test PKI
 * (root -> intermediate -> leaf, with Apple's marker extensions) made with openssl.
 */
import { execFileSync } from "node:child_process";
import { randomBytes, randomUUID } from "node:crypto";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { createServer, type IncomingMessage, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  CompactSign,
  exportPKCS8,
  exportSPKI,
  generateKeyPair,
  importPKCS8,
  importSPKI,
  jwtVerify,
} from "jose";
import { standardWebhookSignature } from "../src/billing/dodo.ts";

export interface TestPki {
  rootPem: string;
  leafKeyPem: string;
  x5c: string[];
}

/** Root CA, intermediate (Apple WWDR marker) and leaf (App Store marker), EC P-256. */
export function makeTestPki(cn = "Test"): TestPki {
  const dir = mkdtempSync(join(tmpdir(), "casama-pki-"));
  const o = (...args: string[]) => execFileSync("openssl", args, { cwd: dir, stdio: "pipe" });
  try {
    for (const k of ["root", "int", "leaf"])
      o("ecparam", "-name", "prime256v1", "-genkey", "-noout", "-out", `${k}.key`);
    o(
      "req",
      "-new",
      "-x509",
      "-key",
      "root.key",
      "-subj",
      `/CN=${cn} Root`,
      "-days",
      "3650",
      "-addext",
      "basicConstraints=critical,CA:TRUE",
      "-addext",
      "keyUsage=critical,keyCertSign,cRLSign",
      "-out",
      "root.crt",
    );
    writeFileSync(
      join(dir, "int.ext"),
      "basicConstraints=critical,CA:TRUE\nkeyUsage=critical,keyCertSign,cRLSign\n1.2.840.113635.100.6.2.1=ASN1:NULL\n",
    );
    writeFileSync(
      join(dir, "leaf.ext"),
      "basicConstraints=critical,CA:FALSE\nkeyUsage=critical,digitalSignature\n1.2.840.113635.100.6.11.1=ASN1:NULL\n",
    );
    o("req", "-new", "-key", "int.key", "-subj", `/CN=${cn} WWDR`, "-out", "int.csr");
    o(
      "x509",
      "-req",
      "-in",
      "int.csr",
      "-CA",
      "root.crt",
      "-CAkey",
      "root.key",
      "-CAcreateserial",
      "-days",
      "3650",
      "-extfile",
      "int.ext",
      "-out",
      "int.crt",
    );
    o(
      "req",
      "-new",
      "-key",
      "leaf.key",
      "-subj",
      `/CN=${cn} App Store Signing`,
      "-out",
      "leaf.csr",
    );
    o(
      "x509",
      "-req",
      "-in",
      "leaf.csr",
      "-CA",
      "int.crt",
      "-CAkey",
      "int.key",
      "-CAcreateserial",
      "-days",
      "3650",
      "-extfile",
      "leaf.ext",
      "-out",
      "leaf.crt",
    );
    o("pkcs8", "-topk8", "-nocrypt", "-in", "leaf.key", "-out", "leaf.p8");
    const der = (f: string) =>
      readFileSync(join(dir, f), "utf8").replace(/-----[^-]+-----|\s/g, "");
    return {
      rootPem: readFileSync(join(dir, "root.crt"), "utf8"),
      leafKeyPem: readFileSync(join(dir, "leaf.p8"), "utf8"),
      x5c: [der("leaf.crt"), der("int.crt"), der("root.crt")],
    };
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

export async function signApple(pki: TestPki, payload: unknown) {
  return new CompactSign(new TextEncoder().encode(JSON.stringify(payload)))
    .setProtectedHeader({ alg: "ES256", x5c: pki.x5c })
    .sign(await importPKCS8(pki.leafKeyPem, "ES256"));
}

type DodoSub = {
  subscription_id: string;
  status: string;
  product_id: string;
  customer: { customer_id: string; email: string };
  next_billing_date: string;
  cancel_at_next_billing_date: boolean;
  metadata: Record<string, string>;
};
type DodoPayment = {
  payment_id: string;
  subscription_id: string | null;
  customer: { customer_id: string };
  metadata: Record<string, string>;
  product_cart: Array<{ product_id: string; quantity: number }>;
  status: string;
};
type AppleSub = {
  originalTransactionId: string;
  transactionId: string;
  productId: string;
  appAccountToken?: string;
  expiresDate: number;
  status: number;
  autoRenewStatus: number;
  revocationDate?: number;
};
type PlaySub = {
  subscriptionState: string;
  acknowledgementState: string;
  externalAccountIdentifiers: { obfuscatedExternalAccountId?: string };
  lineItems: Array<{
    productId: string;
    expiryTime: string;
    autoRenewingPlan: { autoRenewEnabled: boolean };
    offerDetails: { basePlanId: string };
  }>;
};

export interface FakeBilling {
  url: string;
  requests: Array<{ method: string; path: string; auth?: string }>;
  dodo: {
    apiKey: string;
    webhookSecret: string;
    subs: Map<string, DodoSub>;
    payments: Map<string, DodoPayment>;
    checkouts: Map<
      string,
      { product_id: string; metadata: Record<string, string>; email?: string }
    >;
    usageEvents: Array<Record<string, unknown>>;
    /** Pays a checkout: creates the subscription (or one-time payment) and returns ids. */
    complete(sessionId: string): { subscriptionId: string | null; paymentId: string };
    /** A signed Standard Webhooks delivery. */
    webhook(
      type: string,
      data: Record<string, unknown>,
      opts?: { secret?: string; ts?: number },
    ): {
      headers: Record<string, string>;
      body: string;
    };
  };
  apple: {
    pki: TestPki;
    bundleId: string;
    keyId: string;
    issuerId: string;
    privateKeyPem: string;
    subs: Map<string, AppleSub>;
    add(sub: Partial<AppleSub> & { productId: string }): AppleSub;
    notification(type: string, otid: string, subtype?: string, pki?: TestPki): Promise<string>;
  };
  google: {
    packageName: string;
    serviceAccount: { client_email: string; private_key: string; token_uri: string };
    rtdnToken: string;
    subs: Map<string, PlaySub>;
    acknowledged: string[];
    add(
      token: string,
      sub: { productId: string; basePlanId: string; orgId?: string; state?: string },
    ): PlaySub;
    rtdn(n: Record<string, unknown>): string;
  };
  models: { calls: Array<Record<string, unknown>> };
  stop(): Promise<void>;
}

const readBody = async (req: IncomingMessage) => {
  let s = "";
  for await (const c of req) s += c;
  return s;
};

export async function startFakeBilling(
  opts: {
    /** When set, opening a checkout URL "pays" it and delivers the signed webhook to this API. */
    deliverTo?: string;
    port?: number;
  } = {},
): Promise<FakeBilling> {
  const requests: FakeBilling["requests"] = [];
  // ---- Dodo
  const dodoKey = `dodo_test_${randomBytes(8).toString("hex")}`;
  const webhookSecret = `whsec_${randomBytes(24).toString("base64")}`;
  const subs = new Map<string, DodoSub>();
  const payments = new Map<string, DodoPayment>();
  const checkouts: FakeBilling["dodo"]["checkouts"] = new Map();
  const usageEvents: Array<Record<string, unknown>> = [];
  // ---- Apple
  const pki = makeTestPki("Fake Apple");
  const appleKeys = await generateKeyPair("ES256", { extractable: true });
  const applePub = await exportSPKI(appleKeys.publicKey);
  const appleSubs = new Map<string, AppleSub>();
  // ---- Google
  const googleKeys = await generateKeyPair("RS256", { extractable: true });
  const googlePub = await exportSPKI(googleKeys.publicKey);
  const accessTokens = new Set<string>();
  const playSubs = new Map<string, PlaySub>();
  const acknowledged: string[] = [];
  const modelCalls: Array<Record<string, unknown>> = [];

  let url = "";
  const bundleId = "ai.casama.app";
  const issuerId = randomUUID();
  const keyId = "TESTKEY123";

  const appleTx = async (s: AppleSub) =>
    signApple(pki, {
      transactionId: s.transactionId,
      originalTransactionId: s.originalTransactionId,
      productId: s.productId,
      bundleId,
      expiresDate: s.expiresDate,
      appAccountToken: s.appAccountToken,
      revocationDate: s.revocationDate,
      type: "Auto-Renewable Subscription",
      environment: "Sandbox",
    });

  const server: Server = createServer(async (req, res) => {
    const u = new URL(req.url ?? "/", "http://x");
    const path = u.pathname;
    const auth = req.headers.authorization;
    requests.push({ method: req.method ?? "GET", path, auth });
    const send = (status: number, body?: unknown, type = "application/json") => {
      res.writeHead(status, { "content-type": type });
      res.end(body === undefined ? "" : typeof body === "string" ? body : JSON.stringify(body));
    };
    try {
      const body = req.method === "GET" ? "" : await readBody(req);
      // ---------------- Hosted checkout and portal pages (local stand-ins)
      const pay = path.match(/^\/pay\/([^/]+)$/);
      if (pay && req.method === "GET") {
        if (!checkouts.has(pay[1] as string)) return send(404, "No such checkout", "text/plain");
        const r = self.dodo.complete(pay[1] as string);
        if (opts.deliverTo) {
          const w = r.subscriptionId
            ? self.dodo.webhook("subscription.active", {
                payload_type: "Subscription",
                subscription_id: r.subscriptionId,
              })
            : self.dodo.webhook("payment.succeeded", {
                payload_type: "Payment",
                payment_id: r.paymentId,
              });
          const res2 = await fetch(`${opts.deliverTo}/hooks/billing/dodo`, {
            method: "POST",
            headers: w.headers,
            body: w.body,
          });
          if (!res2.ok)
            return send(502, `Webhook failed: ${res2.status} ${await res2.text()}`, "text/plain");
        }
        return send(
          200,
          "<html><body><h1>Payment complete</h1><p>You can return to Casama.</p></body></html>",
          "text/html",
        );
      }
      if (path.startsWith("/portal/"))
        return send(200, "<html><body><h1>Customer portal</h1></body></html>", "text/html");
      // ---------------- Dodo
      if (path.startsWith("/dodo/")) {
        if (auth !== `Bearer ${dodoKey}`) return send(401, { code: "UNAUTHORIZED" });
        const p = path.slice(5);
        if (p === "/checkouts" && req.method === "POST") {
          const b = JSON.parse(body);
          const id = `cks_${randomBytes(6).toString("hex")}`;
          checkouts.set(id, {
            product_id: b.product_cart[0].product_id,
            metadata: b.metadata ?? {},
            email: b.customer?.email,
          });
          return send(200, { session_id: id, checkout_url: `${url}/pay/${id}` });
        }
        let m = p.match(/^\/subscriptions\/([^/]+)$/);
        if (m) {
          const s = subs.get(m[1] as string);
          return s ? send(200, s) : send(404, { code: "NOT_FOUND" });
        }
        m = p.match(/^\/payments\/([^/]+)$/);
        if (m) {
          const pay = payments.get(m[1] as string);
          return pay ? send(200, pay) : send(404, { code: "NOT_FOUND" });
        }
        m = p.match(/^\/customers\/([^/]+)\/customer-portal\/session$/);
        if (m && req.method === "POST")
          return send(200, {
            link: `${url}/portal/${m[1]}?return=${u.searchParams.get("return_url")}`,
          });
        if (p === "/events/ingest" && req.method === "POST") {
          const b = JSON.parse(body) as { events: Array<Record<string, unknown>> };
          usageEvents.push(...b.events);
          return send(200, { ingested_count: b.events.length });
        }
        return send(404, { code: "NOT_FOUND" });
      }
      // ---------------- App Store Server API
      if (path.startsWith("/apple/")) {
        try {
          const token = (auth ?? "").replace("Bearer ", "");
          const { payload, protectedHeader } = await jwtVerify(
            token,
            await importSPKI(applePub, "ES256"),
            {
              audience: "appstoreconnect-v1",
              issuer: issuerId,
            },
          );
          if (protectedHeader.kid !== keyId || payload.bid !== bundleId) throw new Error("claims");
        } catch {
          return send(401, { errorCode: 4010000 });
        }
        const p = path.slice(6);
        let m = p.match(/^\/inApps\/v1\/transactions\/([^/]+)$/);
        if (m) {
          const s = [...appleSubs.values()].find((x) => x.transactionId === m?.[1]);
          return s
            ? send(200, { signedTransactionInfo: await appleTx(s) })
            : send(404, { errorCode: 4040010 });
        }
        m = p.match(/^\/inApps\/v1\/subscriptions\/([^/]+)$/);
        if (m) {
          const s = appleSubs.get(m[1] as string);
          if (!s) return send(404, { errorCode: 4040005 });
          return send(200, {
            bundleId,
            environment: "Sandbox",
            data: [
              {
                subscriptionGroupIdentifier: "21000000",
                lastTransactions: [
                  {
                    originalTransactionId: s.originalTransactionId,
                    status: s.status,
                    signedTransactionInfo: await appleTx(s),
                    signedRenewalInfo: await signApple(pki, {
                      originalTransactionId: s.originalTransactionId,
                      autoRenewStatus: s.autoRenewStatus,
                    }),
                  },
                ],
              },
            ],
          });
        }
        return send(404, {});
      }
      // ---------------- Google OAuth + Play Developer API
      if (path === "/google/token" && req.method === "POST") {
        const form = new URLSearchParams(body);
        try {
          await jwtVerify(form.get("assertion") ?? "", await importSPKI(googlePub, "RS256"), {
            audience: `${url}/google/token`,
          });
        } catch {
          return send(400, { error: "invalid_grant" });
        }
        const t = `ya29.${randomBytes(12).toString("hex")}`;
        accessTokens.add(t);
        return send(200, { access_token: t, expires_in: 3599, token_type: "Bearer" });
      }
      if (path.startsWith("/google/androidpublisher/")) {
        if (!accessTokens.has((auth ?? "").replace("Bearer ", "")))
          return send(401, { error: { code: 401 } });
        const m = path.match(/applications\/([^/]+)\/purchases\/subscriptionsv2\/tokens\/([^/]+)$/);
        if (m) {
          if (m[1] !== "ai.casama.app") return send(404, {});
          const s = playSubs.get(decodeURIComponent(m[2] as string));
          return s ? send(200, s) : send(404, { error: { code: 404 } });
        }
        const a = path.match(/purchases\/subscriptions\/([^/]+)\/tokens\/([^/]+):acknowledge$/);
        if (a && req.method === "POST") {
          const token = decodeURIComponent(a[2] as string);
          const s = playSubs.get(token);
          if (!s) return send(404, {});
          s.acknowledgementState = "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED";
          acknowledged.push(token);
          return send(200);
        }
        return send(404, {});
      }
      // ---------------- Model upstream (OpenAI-compatible)
      if (path === "/models/chat/completions" && req.method === "POST") {
        if (auth !== "Bearer upstream-key") return send(401, { error: "bad key" });
        const b = JSON.parse(body) as Record<string, unknown> & { stream?: boolean };
        modelCalls.push(b);
        const usage = { prompt_tokens: 120, completion_tokens: 30, cost: 0.0009 };
        if (!b.stream)
          return send(200, {
            id: "gen-1",
            choices: [
              { index: 0, message: { role: "assistant", content: "Hello from the cloud." } },
            ],
            usage,
          });
        res.writeHead(200, { "content-type": "text/event-stream" });
        for (const piece of ["Hello", " from", " the cloud."])
          res.write(
            `data: ${JSON.stringify({ choices: [{ index: 0, delta: { content: piece } }] })}\n\n`,
          );
        res.write(`data: ${JSON.stringify({ choices: [], usage })}\n\n`);
        res.end("data: [DONE]\n\n");
        return;
      }
      return send(404, {});
    } catch (err) {
      return send(500, { error: (err as Error).message });
    }
  });
  await new Promise<void>((r) => server.listen(opts.port ?? 0, "127.0.0.1", r));
  url = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;

  const self: FakeBilling = {
    url,
    requests,
    dodo: {
      apiKey: dodoKey,
      webhookSecret,
      subs,
      payments,
      checkouts,
      usageEvents,
      complete(sessionId) {
        const ck = checkouts.get(sessionId);
        if (!ck) throw new Error(`no checkout ${sessionId}`);
        const customer = {
          customer_id: `cus_${randomBytes(5).toString("hex")}`,
          email: ck.email ?? "buyer@example.com",
        };
        const paymentId = `pay_${randomBytes(6).toString("hex")}`;
        let subscriptionId: string | null = null;
        if (ck.product_id.startsWith("pdt_sub_")) {
          subscriptionId = `sub_${randomBytes(6).toString("hex")}`;
          subs.set(subscriptionId, {
            subscription_id: subscriptionId,
            status: "active",
            product_id: ck.product_id,
            customer,
            next_billing_date: new Date(Date.now() + 30 * 86400_000).toISOString(),
            cancel_at_next_billing_date: false,
            metadata: ck.metadata,
          });
        }
        payments.set(paymentId, {
          payment_id: paymentId,
          subscription_id: subscriptionId,
          customer,
          metadata: ck.metadata,
          product_cart: [{ product_id: ck.product_id, quantity: 1 }],
          status: "succeeded",
        });
        return { subscriptionId, paymentId };
      },
      webhook(type, data, opts = {}) {
        const id = `msg_${randomBytes(8).toString("hex")}`;
        const ts = String(opts.ts ?? Math.floor(Date.now() / 1000));
        const body = JSON.stringify({
          business_id: "bus_test",
          type,
          timestamp: new Date().toISOString(),
          data,
        });
        const sig = standardWebhookSignature(opts.secret ?? webhookSecret, id, ts, body);
        return {
          headers: {
            "content-type": "application/json",
            "webhook-id": id,
            "webhook-timestamp": ts,
            "webhook-signature": `v1,${sig}`,
          },
          body,
        };
      },
    },
    apple: {
      pki,
      bundleId,
      keyId,
      issuerId,
      privateKeyPem: await exportPKCS8(appleKeys.privateKey),
      subs: appleSubs,
      add(s) {
        const otid =
          s.originalTransactionId ?? String(2000000000 + Math.floor(Math.random() * 1e8));
        const sub: AppleSub = {
          originalTransactionId: otid,
          transactionId: s.transactionId ?? otid,
          productId: s.productId,
          appAccountToken: s.appAccountToken,
          expiresDate: s.expiresDate ?? Date.now() + 30 * 86400_000,
          status: s.status ?? 1,
          autoRenewStatus: s.autoRenewStatus ?? 1,
        };
        appleSubs.set(otid, sub);
        return sub;
      },
      async notification(type, otid, subtype, signer = pki) {
        const s = appleSubs.get(otid);
        if (!s) throw new Error(`no apple sub ${otid}`);
        return JSON.stringify({
          signedPayload: await signApple(signer, {
            notificationType: type,
            subtype,
            notificationUUID: randomUUID(),
            version: "2.0",
            signedDate: Date.now(),
            data: {
              bundleId,
              environment: "Sandbox",
              signedTransactionInfo: await signApple(signer, {
                transactionId: s.transactionId,
                originalTransactionId: s.originalTransactionId,
                productId: s.productId,
                bundleId,
                expiresDate: s.expiresDate,
                type: "Auto-Renewable Subscription",
              }),
            },
          }),
        });
      },
    },
    google: {
      packageName: "ai.casama.app",
      serviceAccount: {
        client_email: "play-billing@casama-test.iam.gserviceaccount.com",
        private_key: await exportPKCS8(googleKeys.privateKey),
        token_uri: `${url}/google/token`,
      },
      rtdnToken: randomBytes(16).toString("hex"),
      subs: playSubs,
      acknowledged,
      add(token, s) {
        const sub: PlaySub = {
          subscriptionState: s.state ?? "SUBSCRIPTION_STATE_ACTIVE",
          acknowledgementState: "ACKNOWLEDGEMENT_STATE_PENDING",
          externalAccountIdentifiers: { obfuscatedExternalAccountId: s.orgId },
          lineItems: [
            {
              productId: s.productId,
              expiryTime: new Date(Date.now() + 30 * 86400_000).toISOString(),
              autoRenewingPlan: { autoRenewEnabled: true },
              offerDetails: { basePlanId: s.basePlanId },
            },
          ],
        };
        playSubs.set(token, sub);
        return sub;
      },
      rtdn(n) {
        return JSON.stringify({
          message: {
            data: Buffer.from(
              JSON.stringify({
                version: "1.0",
                packageName: "ai.casama.app",
                eventTimeMillis: String(Date.now()),
                ...n,
              }),
            ).toString("base64"),
            messageId: String(Math.floor(Math.random() * 1e15)),
            publishTime: new Date().toISOString(),
          },
          subscription: "projects/casama-test/subscriptions/play-rtdn",
        });
      },
    },
    models: { calls: modelCalls },
    stop: () => new Promise((r) => server.close(() => r())),
  };
  return self;
}

/** Billing env for a harness pointed at the fakes. */
export function billingEnv(f: FakeBilling): Record<string, string> {
  return {
    BILLING_ENABLED: "true",
    DODO_API_KEY: f.dodo.apiKey,
    DODO_WEBHOOK_SECRET: f.dodo.webhookSecret,
    DODO_API_URL: `${f.url}/dodo`,
    APP_STORE_ISSUER_ID: f.apple.issuerId,
    APP_STORE_KEY_ID: f.apple.keyId,
    APP_STORE_PRIVATE_KEY: f.apple.privateKeyPem,
    APP_STORE_BUNDLE_ID: f.apple.bundleId,
    APP_STORE_API_URL: `${f.url}/apple`,
    APP_STORE_ROOT_CA: f.apple.pki.rootPem,
    GOOGLE_PLAY_SERVICE_ACCOUNT: JSON.stringify(f.google.serviceAccount),
    GOOGLE_PLAY_API_URL: `${f.url}/google`,
    GOOGLE_PLAY_RTDN_TOKEN: f.google.rtdnToken,
    CLOUD_MODEL_UPSTREAM_URL: `${f.url}/models`,
    CLOUD_MODEL_UPSTREAM_KEY: "upstream-key",
  };
}
