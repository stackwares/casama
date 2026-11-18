/**
 * The registrar adapter against Name.com's TEST system (docs/SITES-AND-DOMAINS-PLAN.md §10, end of
 * Phase 3). api.dev.name.com uses test credit: nothing here costs money or registers a real name.
 *
 * Proves, and prints for §14, each assumption `namecom.ts` makes about the API:
 *   1. checkAvailability answers `purchasable`, `premium`, `purchasePrice` and `renewalPrice`;
 *   2. registering with `purchasePrice` set and our order id as `clientReference` works, with
 *      lock on, privacy on and the registrar's auto-renew off;
 *   3. a second register of the same name is refused (what a retried call sees);
 *   4. GET domain gives the expiry, lock, auto-renew, privacy and contact verification fields;
 *   5. records: add a CNAME and a TXT, read them back, change one, delete them; ANAME at the root
 *      (decides CASAMA_SITES_APEX=aname for bought domains);
 *   6. URL forwarding on and off;
 *   7. getPricing answers the renewal price, and renew adds exactly one year;
 *   8. lock, unlock, the transfer code (only when unlocked), relock;
 *   9. setContacts and resendVerificationEmail answer;
 *  10. the account balance path;
 *  11. a webhook signature, when NAMECOM_WEBHOOK_SECRET is set and a delivery body is given.
 *
 *   NAMECOM_USERNAME=<user>-test NAMECOM_API_TOKEN=… [NAMECOM_API_URL=https://api.dev.name.com] \
 *   node apps/server/scripts/registrar-live-check.ts
 *
 * The test system's domains are never real and it can't be pointed at production: the script
 * refuses any API address other than the test system unless LIVE_REGISTRAR_OK=yes (never set this
 * without Oliver's yes, §10 "One real purchase").
 */
import { randomBytes } from "node:crypto";
import { NameComRegistrar } from "../src/sites/namecom.ts";
import { RegistrarError } from "../src/sites/registrar.ts";

const need = (k: string) => {
  const v = process.env[k];
  if (!v) throw new Error(`${k} is required`);
  return v;
};
const apiUrl = (process.env.NAMECOM_API_URL ?? "https://api.dev.name.com").replace(/\/$/, "");
if (!/api\.dev\.name\.com/.test(apiUrl) && process.env.LIVE_REGISTRAR_OK !== "yes")
  throw new Error("This check runs against Name.com's test system only (api.dev.name.com).");

const reg = new NameComRegistrar({
  username: need("NAMECOM_USERNAME"),
  token: need("NAMECOM_API_TOKEN"),
  apiUrl,
  webhookSecret: process.env.NAMECOM_WEBHOOK_SECRET,
});
const name = `casama-check-${randomBytes(4).toString("hex")}.com`;
const results: string[] = [];
const step = async <T>(what: string, fn: () => Promise<T>) => {
  try {
    const out = await fn();
    console.log(`ok    ${what}`);
    return out;
  } catch (e) {
    console.log(`FAIL  ${what}: ${(e as Error).message}`);
    results.push(`FAIL ${what}: ${(e as Error).message}`);
    return null;
  }
};
const contact = {
  first_name: "Casama",
  last_name: "Check",
  organization: "Casama",
  address1: "1 Test Street",
  city: "Portland",
  state: "OR",
  zip: "97201",
  country: "US",
  phone: "+1 503 555 0100",
  email: process.env.CHECK_EMAIL ?? "registrar-check@example.com",
};

const [avail] = (await step(`checkAvailability ${name}`, () => reg.check([name], "order"))) ?? [];
console.log("      ", avail);
if (!avail?.available || avail.registerCostUsd === null)
  throw new Error("The test name isn't purchasable or has no price; nothing else can be checked.");
results.push(
  `checkAvailability: purchasable=${avail.available} premium=${avail.premium} purchasePrice=${avail.registerCostUsd} renewalPrice=${avail.renewCostUsd}`,
);

const reference = `check-${randomBytes(4).toString("hex")}`;
const registered = await step("register with purchasePrice and clientReference", () =>
  reg.register({ name, contact, maxCostUsd: avail.registerCostUsd as number, reference }),
);
if (!registered) throw new Error("Registration failed; see above.");

await step("a second register is refused", async () => {
  try {
    await reg.register({ name, contact, maxCostUsd: avail.registerCostUsd as number, reference });
  } catch (e) {
    results.push(
      `second register: ${e instanceof RegistrarError ? `${e.status} "${e.message}"` : (e as Error).message}`,
    );
    return;
  }
  throw new Error("it was accepted");
});

const got = await step("GET domain", () => reg.get(name));
console.log("      ", got);
if (got) {
  results.push(
    `GET domain: locked=${got.locked} autoRenew=${got.autoRenew} privacy=${got.privacy} contactVerified=${got.contactVerified} expires=${got.expiresAt.toISOString()}`,
  );
  if (got.autoRenew) results.push("WARNING: autorenewEnabled:false at registration didn't stick");
}

const recs: string[] = [];
await step("records: CNAME and TXT added and read back", async () => {
  const a = await reg.putRecord(name, {
    host: "www",
    type: "CNAME",
    answer: "d-check.sites.example.com",
    ttl: 300,
  });
  const t = await reg.putRecord(name, {
    host: "_casama",
    type: "TXT",
    answer: "casama-check",
    ttl: 300,
  });
  recs.push(a.id as string, t.id as string);
  const all = await reg.records(name);
  if (!all.some((r) => r.id === a.id) || !all.some((r) => r.id === t.id))
    throw new Error("records not read back");
  await reg.putRecord(name, { ...t, answer: "casama-check-2" });
});
await step("ANAME at the bare domain", async () => {
  const r = await reg.putRecord(name, {
    host: "",
    type: "ANAME",
    answer: "d-check.sites.example.com",
    ttl: 300,
  });
  recs.push(r.id as string);
  results.push("ANAME at the root: accepted (bought domains can use CASAMA_SITES_APEX=aname)");
});
await step("records deleted", async () => {
  for (const id of recs) await reg.deleteRecord(name, id);
});
await step("forwarding on and off", async () => {
  await reg.setForwarding(name, `https://www.${name}`);
  await reg.setForwarding(name, null);
});
await step("getPricing answers the renewal price", async () => {
  const cost = await reg.renewCost(name);
  results.push(`getPricing: renewalPrice=${cost}`);
  if (cost === null)
    throw new Error("no renewalPrice (renewal notices would fall back to the stored price)");
});
await step("renew adds one year", async () => {
  const before = (await reg.get(name))?.expiresAt;
  const { expiresAt } = await reg.renew({
    name,
    maxCostUsd: avail.renewCostUsd ?? (avail.registerCostUsd as number),
    reference: `${reference}-renew`,
  });
  const days = before ? (expiresAt.getTime() - before.getTime()) / 86_400_000 : Number.NaN;
  results.push(`renew: +${Math.round(days)} days`);
  if (Math.abs(days - 365) > 1.5) throw new Error(`added ${days} days`);
});
await step("lock, unlock, transfer code, relock", async () => {
  try {
    await reg.setLock(name, false);
  } catch (e) {
    // ICANN's 60-day lock after registration: the expected answer for a new name.
    if (!/unlocked until/i.test((e as Error).message)) throw e;
    await reg.setLock(name, true);
    results.push(`unlock: refused in the first 60 days ("${(e as Error).message}"); lock: ok`);
    return;
  }
  const code = await reg.transferCode(name);
  if (!code) throw new Error("no code");
  await reg.setLock(name, true);
  results.push("transfer code: issued when unlocked (not printed)");
});
await step("auto-renew off", () => reg.setAutoRenew(name, false));
await step("setContacts", () => reg.setContact(name, contact));
await step("resendVerificationEmail", async () => {
  try {
    await reg.resendVerification(name);
    results.push("resend verification: sent");
  } catch (e) {
    // Name.com lists a new domain's verification record about ten minutes after registering.
    if ((e as { code?: string }).code !== "no_pending_verification") throw e;
    results.push(
      "resend verification: no pending record yet (listed ~10 minutes after registering)",
    );
  }
});
const balance = await step("account balance", () => reg.balanceUsd());
results.push(`balance: ${balance === null ? "not available (card account?)" : `$${balance}`}`);

if (process.env.NAMECOM_WEBHOOK_SECRET && process.env.WEBHOOK_BODY && process.env.WEBHOOK_SIGNATURE)
  await step("webhook signature", async () => {
    const ev = await reg.verifyWebhook({
      headers: new Headers({ "x-namecom-signature": process.env.WEBHOOK_SIGNATURE as string }),
      rawBody: process.env.WEBHOOK_BODY as string,
    });
    results.push(`webhook: ${ev.kind} for ${ev.domain}`);
  });

console.log(`\nTest domain ${name} stays in the test account (it can't be deleted over the API).`);
console.log(`\nResults (write these in §14):\n- ${results.join("\n- ")}`);
