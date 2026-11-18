/**
 * Erases a purged account's product analytics from every provider (D-208, D-397): PostHog (see
 * posthog-erase.ts) and Google Analytics 4 through the User Deletion API, by user id and by the client id the
 * server derived from it. GA4 needs the property id and a service account with Editor on the property
 * (GA4_PROPERTY_ID, GA4_SERVICE_ACCOUNT_JSON); without them, or with product analytics off, it does nothing.
 * Each provider is tried on its own; the first failure is thrown after all of them ran.
 */
import { createSign } from "node:crypto";
import { deterministicUuid } from "@casama/observability";
import { erasePostHogPerson } from "./posthog-erase.ts";

export interface Ga4EraseOptions {
  enabled?: boolean;
  propertyId?: string;
  serviceAccountJson?: string;
  fetch?: typeof fetch;
}

const SCOPE = "https://www.googleapis.com/auth/analytics.user.deletion";
const UPSERT = "https://www.googleapis.com/analytics/v3/userDeletion/userDeletionRequests:upsert";

async function googleToken(
  account: { client_email: string; private_key: string; token_uri?: string },
  doFetch: typeof fetch,
): Promise<string> {
  const b64 = (o: unknown) => Buffer.from(JSON.stringify(o)).toString("base64url");
  const now = Math.floor(Date.now() / 1000);
  const aud = account.token_uri ?? "https://oauth2.googleapis.com/token";
  const unsigned = `${b64({ alg: "RS256", typ: "JWT" })}.${b64({
    iss: account.client_email,
    scope: SCOPE,
    aud,
    iat: now,
    exp: now + 3600,
  })}`;
  const signature = createSign("RSA-SHA256")
    .update(unsigned)
    .sign(account.private_key, "base64url");
  const res = await doFetch(aud, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${signature}`,
    }),
  });
  if (!res.ok) throw new Error(`Google token answered ${res.status}`);
  return ((await res.json()) as { access_token: string }).access_token;
}

export async function eraseGa4User(
  userId: string,
  opts: Ga4EraseOptions = {},
): Promise<"skipped" | "queued"> {
  const enabled = opts.enabled ?? process.env.PRODUCT_ANALYTICS === "on";
  const propertyId = opts.propertyId ?? process.env.GA4_PROPERTY_ID;
  const json = opts.serviceAccountJson ?? process.env.GA4_SERVICE_ACCOUNT_JSON;
  if (!enabled || !propertyId || !json) return "skipped";
  const doFetch = opts.fetch ?? fetch;
  const token = await googleToken(JSON.parse(json), doFetch);
  const ids = [
    { type: "USER_ID", userId },
    { type: "CLIENT_ID", clientId: deterministicUuid("ga4", userId) },
  ];
  for (const id of ids) {
    const res = await doFetch(UPSERT, {
      method: "POST",
      headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
      body: JSON.stringify({ kind: "analytics#userDeletionRequest", id, propertyId }),
    });
    if (!res.ok) throw new Error(`GA4 user deletion answered ${res.status}`);
  }
  return "queued";
}

/** Erases the person from every analytics provider; throws the first failure after trying them all. */
export async function eraseAnalyticsPerson(userId: string): Promise<void> {
  const results = await Promise.allSettled([erasePostHogPerson(userId), eraseGa4User(userId)]);
  const failed = results.find((r): r is PromiseRejectedResult => r.status === "rejected");
  if (failed) throw failed.reason;
}
