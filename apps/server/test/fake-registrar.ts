/**
 * A local stand-in for Name.com's Core API v1 (docs/SITES-AND-DOMAINS-PLAN.md §7.6, §10), serving
 * the same HTTP shapes `NameComRegistrar` sends and reads, so the tests run the real adapter.
 */
import { createHmac, randomBytes } from "node:crypto";
import { createServer, type IncomingMessage, type Server } from "node:http";
import type { AddressInfo } from "node:net";

export type FakeNcDomain = {
  domainName: string;
  nameservers: string[];
  privacyEnabled: boolean;
  locked: boolean;
  autorenewEnabled: boolean;
  expireDate: string;
  createDate: string;
  contactVerification: { status: string };
  contacts: Record<string, Record<string, string>>;
};
export type FakeNcRecord = {
  id: number;
  domainName: string;
  host: string;
  fqdn: string;
  type: string;
  answer: string;
  ttl: number;
  priority?: number;
};

export interface FakeRegistrar {
  url: string;
  username: string;
  token: string;
  webhookSecret: string;
  requests: Array<{ method: string; path: string; body?: unknown }>;
  domains: Map<string, FakeNcDomain>;
  records: Map<string, FakeNcRecord[]>;
  forwarding: Map<string, string>;
  /** Registrations as Name.com received them, with the reference and the agreed price. */
  registrations: Array<{ name: string; purchasePrice: number; clientReference?: string }>;
  renewals: Array<{ name: string; purchasePrice: number; clientReference?: string }>;
  authCodes: string[];
  /** Names somebody else already holds. */
  taken: Set<string>;
  premium: Set<string>;
  /** Cost per ending: what Casama pays to register and to renew. */
  prices: Map<string, { purchase: number; renewal: number }>;
  /** Account credit; null answers 404 (an account paying by card). */
  balance: number | null;
  /** The next call whose path contains `match` answers `status` (`times` times, default once). */
  failNext(match: string, status: number, times?: number): void;
  /** A signed webhook delivery as Name.com would send it. */
  webhook(
    eventName: string,
    domainName: string,
    opts?: { secret?: string },
  ): { headers: Record<string, string>; body: string };
  stop(): Promise<void>;
}

const readBody = async (req: IncomingMessage) => {
  let s = "";
  for await (const c of req) s += c;
  return s;
};

export async function startFakeRegistrar(): Promise<FakeRegistrar> {
  const username = `casama-test-${randomBytes(3).toString("hex")}`;
  const token = randomBytes(16).toString("hex");
  const webhookSecret = randomBytes(16).toString("hex");
  const failures: Array<{ match: string; status: number; times: number }> = [];
  let nextRecordId = 1000;
  const year = 365 * 86_400_000;

  const self: FakeRegistrar = {
    url: "",
    username,
    token,
    webhookSecret,
    requests: [],
    domains: new Map(),
    records: new Map(),
    forwarding: new Map(),
    registrations: [],
    renewals: [],
    authCodes: [],
    taken: new Set(),
    premium: new Set(),
    prices: new Map([
      ["com", { purchase: 12.03, renewal: 12.03 }],
      ["net", { purchase: 13.5, renewal: 13.5 }],
      ["org", { purchase: 10.5, renewal: 11.5 }],
      ["co", { purchase: 25, renewal: 28 }],
      ["io", { purchase: 39, renewal: 45 }],
      ["app", { purchase: 14, renewal: 16 }],
      ["dev", { purchase: 12, renewal: 14 }],
      ["xyz", { purchase: 2, renewal: 12 }],
      ["me", { purchase: 8, renewal: 18 }],
      ["info", { purchase: 4, renewal: 20 }],
      ["shop", { purchase: 2, renewal: 30 }],
    ]),
    balance: 5000,
    failNext(match, status, times = 1) {
      failures.push({ match, status, times });
    },
    webhook(eventName, domainName, opts = {}) {
      const body = JSON.stringify({
        eventId: `evt_${randomBytes(6).toString("hex")}`,
        eventName,
        domainName,
        timestamp: new Date().toISOString(),
      });
      const sig = createHmac("sha256", opts.secret ?? webhookSecret)
        .update(body)
        .digest("hex");
      return {
        headers: { "content-type": "application/json", "x-namecom-signature": sig },
        body,
      };
    },
    stop: () => new Promise((r) => server.close(() => r())),
  };

  const priceOf = (name: string) => {
    const tld = name.split(".").slice(1).join(".");
    const p = self.prices.get(tld) ?? { purchase: 15, renewal: 15 };
    return self.premium.has(name) ? { purchase: p.purchase * 80, renewal: p.renewal * 80 } : p;
  };
  const available = (name: string) => !self.taken.has(name) && !self.domains.has(name);

  const server: Server = createServer(async (req, res) => {
    const u = new URL(req.url ?? "/", "http://x");
    const path = decodeURIComponent(u.pathname);
    const send = (status: number, body?: unknown) => {
      res.writeHead(status, { "content-type": "application/json" });
      res.end(body === undefined ? "" : JSON.stringify(body));
    };
    try {
      const raw = req.method === "GET" ? "" : await readBody(req);
      const body = raw ? (JSON.parse(raw) as Record<string, unknown>) : {};
      self.requests.push({ method: req.method ?? "GET", path, body: raw ? body : undefined });
      const expected = `Basic ${Buffer.from(`${username}:${token}`).toString("base64")}`;
      if (req.headers.authorization !== expected) return send(401, { message: "Unauthenticated" });
      const f = failures.find((x) => path.includes(x.match));
      if (f) {
        f.times -= 1;
        if (f.times <= 0) failures.splice(failures.indexOf(f), 1);
        return send(f.status, { message: `Injected failure ${f.status}` });
      }
      if (!path.startsWith("/core/v1/")) return send(404, { message: "Not Found" });
      const p = path.slice("/core/v1".length);

      if (p === "/domains:checkAvailability" && req.method === "POST") {
        const names = (body.domainNames as string[]) ?? [];
        if (names.length > 50) return send(400, { message: "Too many names" });
        return send(200, {
          results: names.map((n) => {
            const name = n.toLowerCase();
            const free = available(name);
            const pr = priceOf(name);
            return {
              domainName: name,
              sld: name.split(".")[0],
              tld: name.split(".").slice(1).join("."),
              purchasable: free,
              ...(free
                ? {
                    premium: self.premium.has(name),
                    purchasePrice: pr.purchase,
                    purchaseType: "registration",
                    renewalPrice: pr.renewal,
                  }
                : {}),
            };
          }),
        });
      }

      if (p === "/domains" && req.method === "POST") {
        const d = body.domain as {
          domainName: string;
          contacts: Record<string, Record<string, string>>;
          locked?: boolean;
          autorenewEnabled?: boolean;
          privacyEnabled?: boolean;
        };
        const name = d.domainName.toLowerCase();
        const agreed = Number(body.purchasePrice);
        if (!available(name)) return send(400, { message: "Domain is not available" });
        if (agreed < priceOf(name).purchase)
          return send(400, { message: "Purchase price does not match" });
        if (self.balance !== null) {
          if (self.balance < priceOf(name).purchase)
            return send(402, { message: "Insufficient funds" });
          self.balance -= priceOf(name).purchase;
        }
        self.registrations.push({
          name,
          purchasePrice: agreed,
          clientReference: body.clientReference as string | undefined,
        });
        const now = Date.now();
        const domain: FakeNcDomain = {
          domainName: name,
          nameservers: ["ns1.name.com", "ns2.name.com", "ns3.name.com", "ns4.name.com"],
          privacyEnabled: !!d.privacyEnabled,
          locked: !!d.locked,
          autorenewEnabled: d.autorenewEnabled !== false,
          expireDate: new Date(now + year).toISOString(),
          createDate: new Date(now).toISOString(),
          contactVerification: { status: "pending" },
          contacts: d.contacts,
        };
        self.domains.set(name, domain);
        self.records.set(name, []);
        return send(200, { domain, order: Math.floor(Math.random() * 1e6), totalPaid: agreed });
      }

      // Contact verification is keyed by a verification record, one per pending domain here.
      const pending = [...self.domains.entries()]
        .filter(([, d]) => d.contactVerification.status === "pending")
        .map(([name], i) => ({ verificationId: i + 1, name }));
      if (p === "/contacts/unverified" && req.method === "GET") {
        return send(200, {
          unverifiedContacts: pending.map((x) => ({
            verificationId: x.verificationId,
            email: "registrant@example.com",
            domains: [x.name],
          })),
          nextPage: null,
        });
      }
      const vm = p.match(/^\/contacts\/verify\/(\d+):resend$/);
      if (vm && req.method === "POST") {
        return pending.some((x) => x.verificationId === Number(vm[1]))
          ? send(200, {})
          : send(404, { message: "Not Found" });
      }

      const m = p.match(/^\/domains\/([^/:]+)(:[A-Za-z]+)?(\/.*)?$/);
      if (m) {
        const name = (m[1] as string).toLowerCase();
        const action = m[2];
        const rest = m[3] ?? "";
        const d = self.domains.get(name);
        if (!d) return send(404, { message: "Not Found" });
        if (!action && !rest && req.method === "GET") return send(200, d);
        if (action === ":getPricing" && req.method === "GET") {
          const pr = priceOf(name);
          return send(200, { purchasePrice: pr.purchase, renewalPrice: pr.renewal });
        }
        if (action === ":renew" && req.method === "POST") {
          const agreed = Number(body.purchasePrice);
          if (agreed < priceOf(name).renewal)
            return send(400, { message: "Purchase price does not match" });
          self.renewals.push({
            name,
            purchasePrice: agreed,
            clientReference: body.clientReference as string | undefined,
          });
          d.expireDate = new Date(new Date(d.expireDate).getTime() + year).toISOString();
          return send(200, { domain: d, order: 1, totalPaid: agreed });
        }
        if (action === ":enableAutorenew" || action === ":disableAutorenew") {
          d.autorenewEnabled = action === ":enableAutorenew";
          return send(200, d);
        }
        if (action === ":lock" || action === ":unlock") {
          d.locked = action === ":lock";
          return send(200, d);
        }
        if (action === ":getAuthCode") {
          if (d.locked) return send(400, { message: "Domain is locked" });
          const code = randomBytes(8).toString("hex");
          self.authCodes.push(code);
          return send(200, { authCode: code });
        }
        if (action === ":setContacts") {
          d.contacts = body.contacts as FakeNcDomain["contacts"];
          d.contactVerification = { status: "pending" };
          return send(200, d);
        }
        if (rest === "/records" && req.method === "GET")
          return send(200, { records: self.records.get(name) ?? [] });
        if (rest === "/records" && req.method === "POST") {
          const r: FakeNcRecord = {
            id: nextRecordId++,
            domainName: name,
            host: String(body.host ?? ""),
            fqdn: `${body.host ? `${body.host}.` : ""}${name}.`,
            type: String(body.type),
            answer: String(body.answer),
            ttl: Number(body.ttl ?? 300),
            ...(body.priority != null ? { priority: Number(body.priority) } : {}),
          };
          if (r.ttl < 300) return send(400, { message: "TTL must be at least 300" });
          self.records.get(name)?.push(r);
          return send(200, r);
        }
        const rm = rest.match(/^\/records\/(\d+)$/);
        if (rm) {
          const list = self.records.get(name) ?? [];
          const i = list.findIndex((r) => r.id === Number(rm[1]));
          if (i < 0) return send(404, { message: "Not Found" });
          if (req.method === "DELETE") {
            list.splice(i, 1);
            return send(200, {});
          }
          if (req.method === "PUT") {
            const r = list[i] as FakeNcRecord;
            Object.assign(r, {
              host: String(body.host ?? r.host),
              type: String(body.type ?? r.type),
              answer: String(body.answer ?? r.answer),
              ttl: Number(body.ttl ?? r.ttl),
            });
            return send(200, r);
          }
        }
        if (rest === "/url/forwarding" && req.method === "POST") {
          self.forwarding.set(String(body.host), String(body.forwardsTo));
          return send(200, body);
        }
        const fm = rest.match(/^\/url\/forwarding\/(.+)$/);
        if (fm && req.method === "DELETE") {
          if (!self.forwarding.delete(fm[1] as string)) return send(404, { message: "Not Found" });
          return send(200, {});
        }
        return send(404, { message: "Not Found" });
      }

      if (p === "/accountinfo/balance" && req.method === "GET")
        return self.balance === null
          ? send(404, { message: "Not Found" })
          : send(200, { balance: self.balance });
      return send(404, { message: "Not Found" });
    } catch (err) {
      return send(500, { message: (err as Error).message });
    }
  });
  await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
  self.url = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  return self;
}

/** Registrar env for a harness pointed at the fake. */
export function registrarEnv(f: FakeRegistrar): Record<string, string> {
  return {
    CASAMA_DOMAINS_REGISTRAR: "namecom",
    NAMECOM_USERNAME: f.username,
    NAMECOM_API_TOKEN: f.token,
    NAMECOM_API_URL: f.url,
    NAMECOM_WEBHOOK_SECRET: f.webhookSecret,
  };
}
