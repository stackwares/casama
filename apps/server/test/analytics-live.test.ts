/** Live product events (D-208): after the change is saved, only ids and enums, and never for opt-outs. */
import { clearAnalyticsConsentCache } from "@casama/agent";
import {
  type CaptureOptions,
  type ProductAnalytics,
  setInternalAccountRules,
  setProductAnalytics,
} from "@casama/observability";
import { afterAll, afterEach, beforeAll, expect, it } from "vitest";
import { sweepSignups } from "../src/services/analytics-signups.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

class Recorder implements ProductAnalytics {
  readonly enabled = true;
  readonly providers = ["posthog", "ga4"] as const;
  events: CaptureOptions[] = [];
  capture(o: CaptureOptions) {
    this.events.push(o);
  }
  async flush() {}
  async close() {}
}

let h: Harness;
const rec = new Recorder();
const settle = () => new Promise((r) => setTimeout(r, 150));

beforeAll(async () => {
  h = await startHarness();
  setProductAnalytics(rec);
});
afterEach(() => {
  setInternalAccountRules(undefined);
  h.deps.env.INTERNAL_EMAILS = undefined;
  h.deps.env.INTERNAL_EMAIL_DOMAINS = undefined;
});
afterAll(async () => {
  setProductAnalytics(null);
  await h.stop();
});

it("bot_created carries the person, the workspace and enums, never the bot's name", async () => {
  const owner = await h.user("live-owner@example.com");
  const org = await j(
    await h.request("/v1/orgs", {
      method: "POST",
      token: owner.token,
      json: { name: "Secret Corp" },
    }),
  );
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: org.id,
        provider: "openrouter",
        label: "k",
        api_key: "sk-or-v1-abcdefabcdef",
      },
    }),
  );
  const create = (name: string) =>
    h.request("/v1/bots", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: org.id,
        name,
        autonomy: "ask_risky",
        credential_id: cred.id,
        model: "openai/gpt-4o-mini",
      },
    });
  expect((await create("Quiet Quokka")).status).toBe(201);
  await settle();
  const made = rec.events.filter((e) => e.event === "bot_created");
  expect(made).toHaveLength(1);
  expect(made[0]).toMatchObject({ distinctId: owner.id, orgId: org.id, personless: false });
  expect(made[0]?.properties).toEqual({ source: "manual", autonomy: "ask_risky" });
  expect(JSON.stringify(rec.events)).not.toContain("Quiet Quokka");
  expect(JSON.stringify(rec.events)).not.toContain("Secret Corp");

  // The workspace turns usage data off: no more events from it.
  await h.tdb.admin`update public.organizations set analytics_opt_out = true where id = ${org.id}`;
  clearAnalyticsConsentCache();
  rec.events.length = 0;
  expect((await create("Another")).status).toBe(201);
  await settle();
  expect(rec.events).toHaveLength(0);

  // So does the person, in a workspace that did not.
  await h.tdb.admin`update public.organizations set analytics_opt_out = false where id = ${org.id}`;
  await h.tdb
    .admin`update public.profiles set analytics_opt_out = true where user_id = ${owner.id}`;
  clearAnalyticsConsentCache();
  expect((await create("Third")).status).toBe(201);
  await settle();
  expect(rec.events).toHaveLength(0);
});

it("marks internal accounts across /v1/me, GA4 relay, server events, and signup sweep without leaking emails", async () => {
  h.deps.env.INTERNAL_EMAIL_DOMAINS = "casama.ai";
  h.deps.env.INTERNAL_EMAILS = "qa-lead@external.org";
  setInternalAccountRules({
    emails: "qa-lead@external.org",
    domains: "casama.ai",
  });

  const qa = await h.user("qa@casama.ai");
  const lead = await h.user("QA-Lead@external.org");
  const customer = await h.user("customer@acme.com");

  const qaMe = await j(await h.request("/v1/me", { token: qa.token }));
  const leadMe = await j(await h.request("/v1/me", { token: lead.token }));
  const customerMe = await j(await h.request("/v1/me", { token: customer.token }));
  expect(qaMe.is_internal).toBe(true);
  expect(leadMe.is_internal).toBe(true);
  expect(customerMe.is_internal).toBe(false);

  rec.events.length = 0;
  const relayQa = await h.request("/v1/analytics/events", {
    method: "POST",
    token: qa.token,
    json: {
      platform: "windows",
      events: [{ name: "feature_used", properties: { feature: "search" } }],
    },
  });
  expect(relayQa.status).toBe(204);
  const relayCust = await h.request("/v1/analytics/events", {
    method: "POST",
    token: customer.token,
    json: {
      platform: "linux",
      events: [{ name: "feature_used", properties: { feature: "search" } }],
    },
  });
  expect(relayCust.status).toBe(204);

  expect(rec.events.find((e) => e.distinctId === qa.id && e.only === "ga4")).toMatchObject({
    event: "feature_used",
    internal: true,
  });
  expect(rec.events.find((e) => e.distinctId === customer.id && e.only === "ga4")).toMatchObject({
    event: "feature_used",
    internal: false,
  });

  // Server event + signup sweep.
  rec.events.length = 0;
  const org = await j(
    await h.request("/v1/orgs", {
      method: "POST",
      token: qa.token,
      json: { name: "QA Workspace" },
    }),
  );
  expect(org.id).toBeTruthy();
  await settle();
  const wsCreated = rec.events.find(
    (e) => e.event === "workspace_created" && e.distinctId === qa.id,
  );
  expect(wsCreated?.internal).toBe(true);

  rec.events.length = 0;
  await sweepSignups(h.handle.db, rec);
  const qaSignup = rec.events.find((e) => e.event === "signed_up" && e.distinctId === qa.id);
  const custSignup = rec.events.find(
    (e) => e.event === "signed_up" && e.distinctId === customer.id,
  );
  expect(qaSignup?.internal).toBe(true);
  expect(custSignup?.internal).toBe(false);
  expect(JSON.stringify(rec.events)).not.toContain("qa@casama.ai");
  expect(JSON.stringify(rec.events)).not.toContain("QA-Lead@external.org");
});
