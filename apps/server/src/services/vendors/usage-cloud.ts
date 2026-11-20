import { createHmac, randomUUID } from "node:crypto";
import { importPKCS8, SignJWT } from "jose";
import { z } from "zod";
import type { Env } from "../../env.ts";
import type { Reading } from "./readers.ts";

const encode = (s: string) =>
  encodeURIComponent(s).replace(
    /[!'()*]/g,
    (c) => `%${c.charCodeAt(0).toString(16).toUpperCase()}`,
  );
/** Google Maps daily quotas reset at midnight Pacific, including daylight saving changes. */
function pacificPeriod(now: Date, monthly: boolean) {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: "America/Los_Angeles",
    year: "numeric",
    month: "numeric",
    day: "numeric",
  }).formatToParts(now);
  const value = (key: string) => Number(parts.find((p) => p.type === key)!.value);
  const year = value("year"),
    month = value("month") - 1,
    day = monthly ? 1 : value("day");
  const midnight = (base: number) => {
    // At UTC midnight the Pacific clock is still on the preceding afternoon. Its offset is
    // the offset at the upcoming local midnight, even on a 23-hour or 25-hour DST day.
    const label = new Intl.DateTimeFormat("en-US", {
      timeZone: "America/Los_Angeles",
      timeZoneName: "shortOffset",
    })
      .formatToParts(base)
      .find((p) => p.type === "timeZoneName")!.value;
    const match = /GMT([+-])(\d{1,2})(?::(\d{2}))?/.exec(label);
    const offset = match
      ? (match[1] === "-" ? -1 : 1) * (Number(match[2]) * 60 + Number(match[3] ?? 0))
      : 0;
    return new Date(base - offset * 60000).toISOString();
  };
  return {
    start: midnight(Date.UTC(year, month, day)),
    end: midnight(monthly ? Date.UTC(year, month + 1, 1) : Date.UTC(year, month, day + 1)),
  };
}
async function decoded(r: Response): Promise<unknown> {
  if (!r.ok) throw new Error(`provider_http_${r.status}`);
  return r.json();
}
export async function readCloudUsage(
  vendor: string,
  env: Env,
  now: Date,
  f: typeof fetch,
): Promise<Reading | null> {
  const month = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
  const next = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1)).toISOString();
  if (
    vendor === "cloudflare" &&
    env.VENDOR_CLOUDFLARE_ACCOUNT_ID &&
    env.VENDOR_CLOUDFLARE_BILLING_TOKEN
  ) {
    const params = new URLSearchParams({
      from: month.toISOString().slice(0, 10),
      to: now.toISOString().slice(0, 10),
    });
    const data = z
      .object({
        success: z.literal(true),
        result: z.array(
          z.object({ BillingCurrency: z.literal("USD"), ContractedCost: z.number() }),
        ),
      })
      .parse(
        await decoded(
          await f(
            `https://api.cloudflare.com/client/v4/accounts/${encode(env.VENDOR_CLOUDFLARE_ACCOUNT_ID)}/billable-usage?${params}`,
            {
              headers: { authorization: `Bearer ${env.VENDOR_CLOUDFLARE_BILLING_TOKEN}` },
              signal: AbortSignal.timeout(15000),
            },
          ),
        ),
      );
    return {
      used: data.result.reduce((sum, r) => sum + r.ContractedCost, 0),
      remaining: null,
      limit_value: null,
      resets_at: next,
      source: "api",
    };
  }
  if (
    vendor === "here" &&
    env.VENDOR_HERE_KEY_ID &&
    env.VENDOR_HERE_KEY_SECRET &&
    env.VENDOR_HERE_REALM &&
    env.VENDOR_HERE_FEATURE_ID
  ) {
    const tokenUrl = "https://account.api.here.com/oauth2/token";
    const oauth: Record<string, string> = {
      oauth_consumer_key: env.VENDOR_HERE_KEY_ID,
      oauth_nonce: randomUUID(),
      oauth_signature_method: "HMAC-SHA256",
      oauth_timestamp: String(Math.floor(now.getTime() / 1000)),
      oauth_version: "1.0",
    };
    const params = { grant_type: "client_credentials", ...oauth };
    const normalized = Object.entries(params)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([k, v]) => `${encode(k)}=${encode(v)}`)
      .join("&");
    oauth.oauth_signature = createHmac("sha256", `${encode(env.VENDOR_HERE_KEY_SECRET)}&`)
      .update(`POST&${encode(tokenUrl)}&${encode(normalized)}`)
      .digest("base64");
    const token = z.object({ access_token: z.string() }).parse(
      await decoded(
        await f(tokenUrl, {
          method: "POST",
          headers: {
            authorization: `OAuth ${Object.entries(oauth)
              .map(([k, v]) => `${k}="${encode(v)}"`)
              .join(",")}`,
            "content-type": "application/x-www-form-urlencoded",
          },
          body: "grant_type=client_credentials",
          signal: AbortSignal.timeout(15000),
        }),
      ),
    );
    let offset = 0;
    let used = 0;
    for (let page = 0; page < 100; page++) {
      const query = new URLSearchParams({
        startDate: month.toISOString().slice(0, 19),
        endDate: now.toISOString().slice(0, 19),
        featureId: env.VENDOR_HERE_FEATURE_ID,
        offset: String(offset),
      });
      const data = z
        .object({
          items: z.array(z.object({ usageValue: z.coerce.number().finite() })),
          nextOffset: z.number(),
        })
        .parse(
          await decoded(
            await f(
              `https://usage.bam.api.here.com/v2/usage/realms/${encode(env.VENDOR_HERE_REALM)}?${query}`,
              {
                headers: { authorization: `Bearer ${token.access_token}` },
                signal: AbortSignal.timeout(15000),
              },
            ),
          ),
        );
      used += data.items.reduce((n, r) => n + r.usageValue, 0);
      if (!data.nextOffset)
        return { used, remaining: null, limit_value: null, resets_at: next, source: "api" };
      if (data.nextOffset <= offset) throw new Error("invalid_reading");
      offset = data.nextOffset;
    }
    throw new Error("invalid_reading");
  }
  // A method name confirmed from the project's Monitoring descriptor is required: session and
  // viewport calls share the service but do not consume the 2D tile quota.
  if (
    (vendor === "google_maps" || vendor === "google_maps_month") &&
    env.GOOGLE_USAGE_SA_JSON &&
    env.GOOGLE_USAGE_TILE_METHOD
  ) {
    const sa = z
      .object({ client_email: z.string(), private_key: z.string(), project_id: z.string() })
      .parse(JSON.parse(env.GOOGLE_USAGE_SA_JSON));
    const signed = await new SignJWT({ scope: "https://www.googleapis.com/auth/monitoring.read" })
      .setProtectedHeader({ alg: "RS256" })
      .setIssuer(sa.client_email)
      .setAudience("https://oauth2.googleapis.com/token")
      .setIssuedAt()
      .setExpirationTime("5m")
      .sign(await importPKCS8(sa.private_key, "RS256"));
    const token = z.object({ access_token: z.string() }).parse(
      await decoded(
        await f("https://oauth2.googleapis.com/token", {
          method: "POST",
          headers: { "content-type": "application/x-www-form-urlencoded" },
          body: new URLSearchParams({
            grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
            assertion: signed,
          }),
          signal: AbortSignal.timeout(15000),
        }),
      ),
    );
    const interval = pacificPeriod(now, vendor === "google_maps_month");
    const start = interval.start;
    const query = new URLSearchParams({
      filter: `metric.type="serviceruntime.googleapis.com/api/request_count" AND resource.labels.service="tile.googleapis.com" AND resource.labels.method=${JSON.stringify(env.GOOGLE_USAGE_TILE_METHOD)}`,
      "interval.startTime": start,
      "interval.endTime": now.toISOString(),
      view: "FULL",
    });
    let used = 0;
    for (let page = 0; page < 100; page++) {
      const data = z
        .object({
          timeSeries: z
            .array(
              z.object({
                points: z.array(
                  z.object({ value: z.object({ int64Value: z.coerce.number().finite() }) }),
                ),
              }),
            )
            .optional(),
          nextPageToken: z.string().optional(),
        })
        .parse(
          await decoded(
            await f(
              `https://monitoring.googleapis.com/v3/projects/${encode(sa.project_id)}/timeSeries?${query}`,
              {
                headers: { authorization: `Bearer ${token.access_token}` },
                signal: AbortSignal.timeout(15000),
              },
            ),
          ),
        );
      used += (data.timeSeries ?? []).reduce(
        (n, s) => n + s.points.reduce((a, p) => a + p.value.int64Value, 0),
        0,
      );
      if (!data.nextPageToken)
        return {
          used,
          remaining: null,
          limit_value: null,
          resets_at: interval.end,
          source: "api",
        };
      query.set("pageToken", data.nextPageToken);
    }
    throw new Error("invalid_reading");
  }
  return null;
}
