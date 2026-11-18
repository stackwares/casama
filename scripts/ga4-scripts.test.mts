/**
 * Tests for the GA4 scripts (D-398): node --test scripts/ga4-scripts.test.mts
 */
import assert from "node:assert/strict";
import { createVerify, generateKeyPairSync } from "node:crypto";
import { test } from "node:test";
import { FUNNELS, funnelRequest, tableRows, unknownSteps } from "./ga4-funnels.mts";
import { accessToken, api, jwtAssertion, listAll, propertyId } from "./ga4-lib.mts";
import {
  applyPlan,
  KEY_EVENTS,
  MAX_EVENT_DIMENSIONS,
  plan,
  USER_DIMENSIONS,
  wantedEventDimensions,
} from "./ga4-setup.mts";

const { privateKey, publicKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
const account = {
  client_email: "ga4@casama.iam.gserviceaccount.com",
  private_key: privateKey.export({ type: "pkcs8", format: "pem" }).toString(),
};

test("property id: flag, env, default; numeric only", () => {
  assert.equal(propertyId([]), process.env.GA4_PROPERTY_ID ?? "563408057");
  assert.equal(propertyId(["--property", "properties/42"], {}), "42");
  assert.equal(propertyId([], { GA4_PROPERTY_ID: "7" }), "7");
  assert.throws(() => propertyId(["--property", "G-ABC"], {}));
});

test("JWT assertion is signed RS256 with both scopes", () => {
  const jwt = jwtAssertion(account, ["a", "b"], 1_700_000_000_000);
  const [h, p, s] = jwt.split(".");
  assert.ok(createVerify("RSA-SHA256").update(`${h}.${p}`).verify(publicKey, s!, "base64url"));
  const claims = JSON.parse(Buffer.from(p!, "base64url").toString());
  assert.equal(claims.scope, "a b");
  assert.equal(claims.exp - claims.iat, 3600);
});

test("access token: GOOGLE_ACCESS_TOKEN wins, else the service account grant", async () => {
  assert.equal(await accessToken({ GOOGLE_ACCESS_TOKEN: " tok \n" }), "tok");
  const calls: { url: string; body: string }[] = [];
  const fake = (async (url: string, init: RequestInit) => {
    calls.push({ url, body: String(init.body) });
    return Response.json({ access_token: "sa-token" });
  }) as unknown as typeof fetch;
  assert.equal(
    await accessToken({ GA4_SERVICE_ACCOUNT_JSON: JSON.stringify(account) }, fake),
    "sa-token",
  );
  assert.equal(calls[0]?.url, "https://oauth2.googleapis.com/token");
  assert.match(calls[0]!.body, /grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer/);
  await assert.rejects(accessToken({}), /No Google credentials/);
});

test("listAll follows page tokens", async () => {
  const urls: string[] = [];
  const fake = (async (url: string) => {
    urls.push(url);
    return Response.json(
      url.includes("pageToken")
        ? { keyEvents: [{ eventName: "b" }] }
        : { keyEvents: [{ eventName: "a" }], nextPageToken: "n 1" },
    );
  }) as unknown as typeof fetch;
  const all = await listAll<{ eventName: string }>(
    api("t", fake),
    "https://x/keyEvents",
    "keyEvents",
  );
  assert.deepEqual(
    all.map((k) => k.eventName),
    ["a", "b"],
  );
  assert.match(urls[1]!, /pageToken=n%201/);
});

test("wanted dimensions: catalog-known, capped, no ids", () => {
  const { wanted, leftOut } = wantedEventDimensions();
  assert.ok(wanted.length <= MAX_EVENT_DIMENSIONS);
  assert.deepEqual(wanted.slice(0, 2), ["app", "environment"]);
  for (const id of ["workspace_id", "user_id"])
    assert.ok(!wanted.includes(id) && !leftOut.includes(id));
  assert.ok(wanted.includes("plan") && wanted.includes("method"));
  const small = wantedEventDimensions(undefined, 3);
  assert.equal(small.wanted.length, 3);
  assert.ok(small.leftOut.includes("plan"));
});

test("plan is idempotent: creates only what's missing, keeps retention when right", () => {
  const empty = plan({ dimensions: [], metrics: [], keyEvents: [] }, ["app", "plan"]);
  assert.deepEqual(
    empty.dimensions.filter((d) => d.scope === "EVENT").map((d) => d.parameterName),
    ["app", "plan"],
  );
  assert.equal(empty.dimensions.filter((d) => d.scope === "USER").length, USER_DIMENSIONS.length);
  assert.deepEqual(empty.keyEvents, KEY_EVENTS);
  assert.deepEqual(empty.retention, {
    eventDataRetention: "FOURTEEN_MONTHS",
    resetUserDataOnNewActivity: true,
  });

  const done = plan(
    {
      dimensions: [
        { parameterName: "app", scope: "EVENT" },
        { parameterName: "plan", scope: "EVENT" },
        ...USER_DIMENSIONS.map((p) => ({ parameterName: p, scope: "USER" as const })),
      ],
      metrics: [{ parameterName: "duration_s" }, { parameterName: "minutes_since_signup" }],
      keyEvents: KEY_EVENTS.map((eventName) => ({ eventName })),
      retention: { eventDataRetention: "FOURTEEN_MONTHS", resetUserDataOnNewActivity: true },
    },
    ["app", "plan"],
  );
  assert.deepEqual(done, { dimensions: [], metrics: [], keyEvents: [], retention: null });

  // A user-scoped "plan" doesn't count as the event-scoped one.
  const scoped = plan(
    { dimensions: [{ parameterName: "plan", scope: "USER" }], metrics: [], keyEvents: [] },
    ["plan"],
  );
  assert.ok(scoped.dimensions.some((d) => d.scope === "EVENT" && d.parameterName === "plan"));

  // Never more event dimensions than the cap, counting the ones that exist.
  const full = plan(
    {
      dimensions: Array.from({ length: MAX_EVENT_DIMENSIONS }, (_, i) => ({
        parameterName: `p${i}`,
        scope: "EVENT" as const,
      })),
      metrics: [],
      keyEvents: [],
    },
    ["plan"],
  );
  assert.equal(full.dimensions.filter((d) => d.scope === "EVENT").length, 0);
});

test("applyPlan posts each piece to the Admin API", async () => {
  const calls: { method: string; url: string; body: unknown }[] = [];
  const fake = (async (url: string, init: RequestInit) => {
    calls.push({
      method: String(init.method),
      url,
      body: init.body ? JSON.parse(String(init.body)) : undefined,
    });
    return Response.json({});
  }) as unknown as typeof fetch;
  await applyPlan(
    api("t", fake),
    "1",
    plan({ dimensions: [], metrics: [], keyEvents: [] }, ["plan"]),
  );
  const base = "https://analyticsadmin.googleapis.com/v1beta/properties/1";
  assert.ok(
    calls.some(
      (c) =>
        c.url === `${base}/customDimensions` &&
        (c.body as { parameterName: string }).parameterName === "plan",
    ),
  );
  assert.ok(
    calls.some(
      (c) =>
        c.url === `${base}/keyEvents` &&
        (c.body as { countingMethod: string }).countingMethod === "ONCE_PER_EVENT",
    ),
  );
  const patch = calls.find((c) => c.method === "PATCH");
  assert.equal(
    patch?.url,
    `${base}/dataRetentionSettings?updateMask=eventDataRetention,resetUserDataOnNewActivity`,
  );
  assert.ok(calls.every((c) => c.method !== "DELETE"));
});

test("every funnel step is a catalog event, a GA4 twin or a website event", () => {
  assert.deepEqual(unknownSteps(), []);
  assert.equal(new Set(FUNNELS.map((f) => f.id)).size, FUNNELS.length);
  assert.ok(FUNNELS.find((f) => f.id === "W1")?.open);
});

test("funnel request: production filter on app/server steps only, OR groups, breakdown", () => {
  const w1 = FUNNELS.find((f) => f.id === "W1")!;
  const body = funnelRequest(w1, { days: 7, breakdown: "environment" }) as any;
  assert.deepEqual(body.dateRanges, [{ startDate: "7daysAgo", endDate: "today" }]);
  assert.equal(body.funnel.isOpenFunnel, true);
  const [visit, click, signup] = body.funnel.steps;
  assert.equal(visit.filterExpression.funnelEventFilter.eventName, "page_view");
  assert.equal(visit.filterExpression.funnelEventFilter.funnelParameterFilterExpression, undefined);
  assert.deepEqual(
    click.filterExpression.orGroup.expressions.map((e: any) => e.funnelEventFilter.eventName),
    ["start_click", "download_click"],
  );
  assert.equal(
    signup.filterExpression.funnelEventFilter.funnelParameterFilterExpression.funnelParameterFilter
      .stringFilter.value,
    "production",
  );
  assert.equal(body.funnelBreakdown.breakdownDimension.name, "customEvent:environment");
  const all = funnelRequest(FUNNELS[1]!, { production: false, breakdown: "platform" }) as any;
  assert.equal(
    all.funnel.steps[0].filterExpression.funnelEventFilter.funnelParameterFilterExpression,
    undefined,
  );
  assert.equal(all.funnelBreakdown.breakdownDimension.name, "platform");
});

test("table rows: step, users, completion and abandonment as percentages", () => {
  const rows = tableRows({
    dimensionHeaders: [{ name: "funnelStepName" }],
    metricHeaders: [
      { name: "activeUsers" },
      { name: "funnelStepCompletionRate" },
      { name: "funnelStepAbandonments" },
      { name: "funnelStepAbandonmentRate" },
    ],
    rows: [
      {
        dimensionValues: [{ value: "1. Signed up" }],
        metricValues: [{ value: "40" }, { value: "0.25" }, { value: "30" }, { value: "0.75" }],
      },
    ],
  });
  assert.deepEqual(rows, [["1. Signed up", "40", "25.0%", "75.0%"]]);
});
