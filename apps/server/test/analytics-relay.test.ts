import { expect, it } from "vitest";
import { relayedGa4Events } from "../src/api/routes/privacy.ts";

it("relays only catalog app events with their catalog properties, plus twins and screens (D-399)", () => {
  const out = relayedGa4Events("windows", [
    {
      name: "paywall_view",
      properties: { source: "limit", paywall_kind: "credits", email: "a@b.c", nested: { x: 1 } },
    },
    { name: "referral_shared", properties: { method: "copy" } },
    { name: "screen_view", properties: { screen: "/chat/:id" } },
    { name: "screen_view", properties: { screen: "https://evil" } },
    { name: "signed_up", properties: { method: "x" } }, // server-only: dropped
    { name: "made_up_event" },
  ]);
  expect(out.map((e) => e.event)).toEqual([
    "paywall_view",
    "referral_shared",
    "share",
    "page_view",
  ]);
  // The event's own catalog properties win over the defaults (paywall_view has its own `source`).
  expect(out[0]?.properties).toEqual({
    platform: "windows",
    source: "limit",
    paywall_kind: "credits",
  });
  expect(out[2]?.properties).toEqual({
    platform: "windows",
    source: "app",
    content_type: "referral",
    method: "copy",
  });
  expect(out[3]?.properties).toMatchObject({
    page_title: "/chat/:id",
    page_location: "https://app.casama.ai/chat/:id",
  });
});
