/** Live product events (D-208): after the change is saved, only ids and enums, and never for opt-outs. */
import { clearAnalyticsConsentCache } from "@casama/agent";
import {
  type CaptureOptions,
  type ProductAnalytics,
  setProductAnalytics,
} from "@casama/observability";
import { afterAll, beforeAll, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

class Recorder implements ProductAnalytics {
  readonly enabled = true;
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
