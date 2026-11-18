import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { PROVIDER_HOOKS } from "../src/api/app.ts";
import { type Harness, startHarness } from "./helpers.ts";

describe("webhook rate limits", () => {
  let h: Harness;
  beforeAll(async () => {
    h = await startHarness({ rateLimit: 2 });
  });
  afterAll(async () => {
    await h.stop();
  });

  it("knows the signed provider webhooks", () => {
    for (const p of [
      "/hooks/billing/dodo",
      "/hooks/billing/revenuecat",
      "/hooks/payments/0b0e5c3a-1f2e-4c6d-9a8b-7c6d5e4f3a2b",
      "/hooks/registrar/namecom",
      "/hooks/newsletter/resend",
    ])
      expect(PROVIDER_HOOKS.test(p), p).toBe(true);
    for (const p of [
      "/hooks/composio",
      "/hooks/billing/other",
      "/hooks/payments/not-an-org",
      "/hooks/channels/abc",
      "/hooks/registrar/a/b",
      "/hooks/newsletter/other",
    ])
      expect(PROVIDER_HOOKS.test(p), p).toBe(false);
  });

  it("other hooks keep the ordinary limit; provider hooks get their own, higher one", async () => {
    const post = (path: string) => h.request(path, { method: "POST", body: "{}" });
    for (let i = 0; i < 2; i++) await post("/hooks/composio");
    expect((await post("/hooks/composio")).status).toBe(429);
    // Same address, well past the ordinary limit: Stripe Issuing still gets an answer (404 here,
    // no such workspace), never a 429 that would decline the card.
    for (let i = 0; i < 10; i++)
      expect((await post("/hooks/payments/0b0e5c3a-1f2e-4c6d-9a8b-7c6d5e4f3a2b")).status).not.toBe(
        429,
      );
    expect((await post("/hooks/billing/dodo")).status).not.toBe(429);
  });
});
