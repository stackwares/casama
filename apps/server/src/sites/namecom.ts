/**
 * Name.com's Core API v1 (docs/SITES-AND-DOMAINS-PLAN.md §2.2, §7.6): Basic auth with the reseller
 * username and token, JSON over HTTPS. The test system is `https://api.dev.name.com`.
 *
 * The paths and the few fields marked "checked by registrar-live-check.ts" come from Name.com's
 * documentation and are confirmed against the test system by that script before buying is turned
 * on; each is in one place here, so a difference is a one-line fix.
 */
import { createHmac, timingSafeEqual } from "node:crypto";
import { type DnsRecord, type DomainContact, registrarPhone } from "@casama/domain";
import {
  type AvailabilityResult,
  CallBudget,
  type Registrar,
  type RegistrarDomain,
  RegistrarError,
  type RegistrarEvent,
} from "./registrar.ts";

const BASE_PATH = "/core/v1";

interface NcDomain {
  domainName: string;
  nameservers?: string[];
  privacyEnabled?: boolean;
  locked?: boolean;
  autorenewEnabled?: boolean;
  expireDate?: string;
  /** Checked by registrar-live-check.ts: the registrant's email confirmation. */
  contactVerification?: { status?: string } | null;
}
interface NcRecord {
  id: number | string;
  domainName?: string;
  host?: string;
  fqdn?: string;
  type: string;
  answer: string;
  ttl?: number;
  priority?: number | null;
}

export interface NameComOptions {
  username: string;
  token: string;
  /** https://api.name.com, or https://api.dev.name.com for the test system. */
  apiUrl?: string;
  webhookSecret?: string;
  fetch?: typeof fetch;
  budget?: CallBudget;
  timeoutMs?: number;
}

const ncContact = (c: DomainContact) => ({
  firstName: c.first_name,
  lastName: c.last_name,
  companyName: c.organization ?? "",
  address1: c.address1,
  address2: c.address2 ?? "",
  city: c.city,
  state: c.state,
  zip: c.zip,
  country: c.country,
  phone: registrarPhone(c.phone),
  email: c.email,
});
const contacts = (c: DomainContact) => {
  const x = ncContact(c);
  return { registrant: x, admin: x, tech: x, billing: x };
};

const toRecord = (r: NcRecord): DnsRecord => ({
  id: String(r.id),
  host: r.host ?? "",
  type: r.type.toUpperCase(),
  answer: r.answer,
  ttl: r.ttl ?? 300,
  priority: r.priority ?? null,
});

export class NameComRegistrar implements Registrar {
  readonly id = "namecom";
  private readonly o: NameComOptions;
  private readonly base: string;
  private readonly budget: CallBudget;
  private readonly cache = new Map<string, { at: number; r: AvailabilityResult }>();

  constructor(o: NameComOptions) {
    this.o = o;
    this.base = (o.apiUrl ?? "https://api.name.com").replace(/\/$/, "") + BASE_PATH;
    this.budget = o.budget ?? new CallBudget();
  }

  private async call<T>(
    method: string,
    path: string,
    body?: unknown,
    purpose: "search" | "order" = "order",
  ): Promise<T> {
    await this.budget.take(purpose);
    // Name.com refuses a POST without a JSON content type, even an action with no fields.
    if (body === undefined && method !== "GET" && method !== "DELETE") body = {};
    let res: Response;
    try {
      res = await (this.o.fetch ?? fetch)(`${this.base}${path}`, {
        method,
        headers: {
          authorization: `Basic ${Buffer.from(`${this.o.username}:${this.o.token}`).toString("base64")}`,
          ...(body === undefined ? {} : { "content-type": "application/json" }),
        },
        body: body === undefined ? undefined : JSON.stringify(body),
        signal: AbortSignal.timeout(this.o.timeoutMs ?? 30_000),
      });
    } catch (e) {
      throw new RegistrarError(
        503,
        "unreachable",
        `Name.com did not answer: ${(e as Error).message}`,
      );
    }
    const text = await res.text();
    let json: Record<string, unknown> = {};
    try {
      json = text ? (JSON.parse(text) as Record<string, unknown>) : {};
    } catch {
      // Not the API's JSON (a proxy or an outage).
    }
    if (!res.ok) {
      const message = String(json.message ?? json.details ?? `Name.com answered ${res.status}`);
      throw new RegistrarError(res.status, String(json.code ?? res.status), message);
    }
    return json as T;
  }

  private path(name: string, suffix = "") {
    return `/domains/${encodeURIComponent(name)}${suffix}`;
  }

  async check(names: string[], purpose: "search" | "order" = "search") {
    const now = Date.now();
    const fresh = (n: string) => {
      const hit = this.cache.get(n);
      return purpose === "search" && hit && now - hit.at < 60_000 ? hit.r : null;
    };
    const missing = names.filter((n) => !fresh(n)).slice(0, 50);
    if (missing.length) {
      const r = await this.call<{
        results?: Array<{
          domainName: string;
          purchasable?: boolean;
          premium?: boolean;
          purchasePrice?: number;
          renewalPrice?: number;
        }>;
      }>("POST", "/domains:checkAvailability", { domainNames: missing }, purpose);
      for (const x of r.results ?? []) {
        const name = x.domainName.toLowerCase();
        this.cache.set(name, {
          at: now,
          r: {
            name,
            available: !!x.purchasable,
            premium: !!x.premium,
            registerCostUsd: typeof x.purchasePrice === "number" ? x.purchasePrice : null,
            renewCostUsd: typeof x.renewalPrice === "number" ? x.renewalPrice : null,
          },
        });
      }
    }
    return names.map(
      (n) =>
        this.cache.get(n)?.r ?? {
          name: n,
          available: false,
          premium: false,
          registerCostUsd: null,
          renewCostUsd: null,
        },
    );
  }

  async register(o: {
    name: string;
    contact: DomainContact;
    maxCostUsd: number;
    reference: string;
  }) {
    // purchasePrice makes Name.com refuse rather than charge more than we agreed to.
    const r = await this.call<{ domain?: NcDomain }>("POST", "/domains", {
      domain: {
        domainName: o.name,
        contacts: contacts(o.contact),
        locked: true,
        autorenewEnabled: false,
        privacyEnabled: true,
      },
      purchasePrice: o.maxCostUsd,
      years: 1,
      // Our order id, so a retried call can be matched to its order (checked by the live check).
      clientReference: o.reference,
    });
    if (!r.domain?.expireDate)
      throw new RegistrarError(502, "no_expiry", "Name.com returned no expiry date");
    return { expiresAt: new Date(r.domain.expireDate) };
  }

  async renew(o: { name: string; maxCostUsd: number; reference: string }) {
    const r = await this.call<{ domain?: NcDomain }>("POST", this.path(o.name, ":renew"), {
      purchasePrice: o.maxCostUsd,
      years: 1,
      clientReference: o.reference,
    });
    if (!r.domain?.expireDate)
      throw new RegistrarError(502, "no_expiry", "Name.com returned no expiry date");
    return { expiresAt: new Date(r.domain.expireDate) };
  }

  async renewCost(name: string) {
    // Checked by registrar-live-check.ts.
    const r = await this.call<{ renewalPrice?: number }>("GET", this.path(name, ":getPricing"));
    return typeof r.renewalPrice === "number" ? r.renewalPrice : null;
  }

  async get(name: string): Promise<RegistrarDomain | null> {
    let d: NcDomain;
    try {
      d = await this.call<NcDomain>("GET", this.path(name));
    } catch (e) {
      if (e instanceof RegistrarError && e.status === 404) return null;
      throw e;
    }
    return {
      expiresAt: new Date(d.expireDate ?? 0),
      locked: !!d.locked,
      autoRenew: !!d.autorenewEnabled,
      privacy: !!d.privacyEnabled,
      nameservers: d.nameservers ?? [],
      contactVerified: d.contactVerification?.status === "verified",
    };
  }

  async setAutoRenew(name: string, on: boolean) {
    await this.call("POST", this.path(name, on ? ":enableAutorenew" : ":disableAutorenew"));
  }
  async setLock(name: string, locked: boolean) {
    await this.call("POST", this.path(name, locked ? ":lock" : ":unlock"));
  }
  async transferCode(name: string) {
    const r = await this.call<{ authCode?: string }>("GET", this.path(name, ":getAuthCode"));
    if (!r.authCode) throw new RegistrarError(502, "no_code", "Name.com returned no transfer code");
    return r.authCode;
  }
  async setContact(name: string, contact: DomainContact) {
    await this.call("POST", this.path(name, ":setContacts"), { contacts: contacts(contact) });
  }
  async resendVerification(name: string) {
    // Name.com keys verification by record, not domain: find the pending record that covers
    // this domain, then resend it. A new domain's record shows up within about ten minutes.
    const want = name.toLowerCase();
    for (let page = 1; page <= 50; page++) {
      const r = await this.call<{
        unverifiedContacts?: { verificationId: number; domains?: string[] }[];
        nextPage?: number | null;
      }>("GET", `/contacts/unverified?perPage=1000&page=${page}`);
      const hit = r.unverifiedContacts?.find((c) =>
        c.domains?.some((d) => d.toLowerCase() === want),
      );
      if (hit) {
        await this.call("POST", `/contacts/verify/${hit.verificationId}:resend`);
        return;
      }
      if (!r.nextPage) break;
    }
    throw new RegistrarError(
      409,
      "no_pending_verification",
      "There's no pending contact verification for this domain yet.",
    );
  }

  async records(name: string) {
    const r = await this.call<{ records?: NcRecord[] }>("GET", this.path(name, "/records"));
    return (r.records ?? []).map(toRecord);
  }
  async putRecord(name: string, rec: DnsRecord) {
    const body = {
      host: rec.host,
      type: rec.type.toUpperCase(),
      answer: rec.answer,
      ttl: rec.ttl,
      ...(rec.priority != null ? { priority: rec.priority } : {}),
    };
    const r = rec.id
      ? await this.call<NcRecord>(
          "PUT",
          this.path(name, `/records/${encodeURIComponent(rec.id)}`),
          body,
        )
      : await this.call<NcRecord>("POST", this.path(name, "/records"), body);
    return toRecord(r);
  }
  async deleteRecord(name: string, id: string) {
    try {
      await this.call("DELETE", this.path(name, `/records/${encodeURIComponent(id)}`));
    } catch (e) {
      if (e instanceof RegistrarError && e.status === 404) return;
      throw e;
    }
  }
  async setForwarding(name: string, to: string | null) {
    if (to)
      await this.call("POST", this.path(name, "/url/forwarding"), {
        host: name,
        forwardsTo: to,
        type: "redirect",
      });
    else
      try {
        await this.call("DELETE", this.path(name, `/url/forwarding/${encodeURIComponent(name)}`));
      } catch (e) {
        if (!(e instanceof RegistrarError) || e.status !== 404) throw e;
      }
  }

  async balanceUsd() {
    // Checked by registrar-live-check.ts.
    try {
      const r = await this.call<{ balance?: number }>("GET", "/accountinfo/balance");
      return typeof r.balance === "number" ? r.balance : null;
    } catch {
      return null;
    }
  }

  /** HMAC-SHA256 of the raw body with the webhook secret, hex (checked by the live check). */
  async verifyWebhook(req: { headers: Headers; rawBody: string }): Promise<RegistrarEvent> {
    const secret = this.o.webhookSecret;
    const sig = req.headers.get("x-namecom-signature") ?? "";
    if (!secret) throw new RegistrarError(401, "bad_signature", "No webhook secret is set");
    const expected = Buffer.from(createHmac("sha256", secret).update(req.rawBody).digest("hex"));
    const got = Buffer.from(sig);
    if (got.length !== expected.length || !timingSafeEqual(got, expected))
      throw new RegistrarError(401, "bad_signature", "Webhook signature does not match");
    const body = JSON.parse(req.rawBody) as {
      id?: string;
      eventId?: string;
      eventName?: string;
      domainName?: string;
    };
    const name = (body.eventName ?? "").toLowerCase();
    const kind: RegistrarEvent["kind"] = name.includes("verif")
      ? "contact_verified"
      : name.includes("expir")
        ? "expiry"
        : name.includes("lock")
          ? "lock"
          : name.includes("transfer")
            ? "transfer_out"
            : name.includes("delet") || name.includes("remov")
              ? "removed"
              : name.includes("balance")
                ? "balance"
                : "other";
    return {
      id: String(
        body.eventId ?? body.id ?? createHmac("sha256", "id").update(req.rawBody).digest("hex"),
      ),
      kind,
      domain: body.domainName?.toLowerCase() ?? null,
      raw: body,
    };
  }
}
