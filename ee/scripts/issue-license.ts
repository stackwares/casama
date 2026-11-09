/**
 * Issues an enterprise license key (maintainers only). Needs the private signing key, kept outside
 * the repository (default ~/.config/kasama/license-signing-key.pem or KASAMA_LICENSE_SIGNING_KEY).
 *   node ee/scripts/issue-license.ts --customer Acme --features audit_export,sso --seats 50 --days 365
 */
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { parseArgs } from "node:util";
import { importPKCS8, SignJWT } from "jose";

const { values } = parseArgs({
  options: {
    customer: { type: "string" },
    features: { type: "string", default: "audit_export,sso" },
    seats: { type: "string", default: "25" },
    days: { type: "string", default: "365" },
  },
});
if (!values.customer) throw new Error("--customer is required");
const pem = readFileSync(
  process.env.KASAMA_LICENSE_SIGNING_KEY ??
    join(homedir(), ".config/kasama/license-signing-key.pem"),
  "utf8",
);
const token = await new SignJWT({
  features: (values.features as string).split(","),
  seats: Number(values.seats),
})
  .setProtectedHeader({ alg: "EdDSA" })
  .setIssuer("kasama-licensing")
  .setSubject(values.customer)
  .setIssuedAt()
  .setExpirationTime(`${values.days}d`)
  .sign(await importPKCS8(pem, "EdDSA"));
console.log(token);
