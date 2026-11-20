import { expect, it } from "vitest";
import { relayedGa4Events } from "../src/api/routes/privacy.ts";

it("relays only catalog app events with their catalog properties, plus twins and screens (D-399)", () => {
  const out = relayedGa4Events("windows", [
    {
      name: "paywall_view",
      properties: {
        source: "limit",
        paywall_kind: "regular",
        default_plan: "pro",
        default_period: "month",
        email: "a@b.c",
        nested: { x: 1 },
      },
    },
    { name: "paywall_plan_select", properties: { plan: "plus_yearly", interval: "year" } },
    { name: "referral_shared", properties: { method: "copy" } },
    { name: "screen_view", properties: { screen: "/chat/:id" } },
    { name: "screen_view", properties: { screen: "https://evil" } },
    { name: "signed_up", properties: { method: "x" } }, // server-only: dropped
    { name: "made_up_event" },
  ]);
  expect(out.map((e) => e.event)).toEqual([
    "paywall_view",
    "view_item_list",
    "paywall_plan_select",
    "select_item",
    "referral_shared",
    "share",
    "page_view",
  ]);
  // The event's own catalog properties win over the defaults (paywall_view has its own `source`).
  expect(out[0]?.properties).toEqual({
    platform: "windows",
    source: "limit",
    paywall_kind: "regular",
    default_plan: "pro",
    default_period: "month",
  });
  expect(out[1]?.properties).toEqual({
    platform: "windows",
    source: "limit",
    item_list_id: "paywall",
    item_list_name: "Casama plans",
    paywall_kind: "regular",
    default_plan: "pro",
    default_period: "month",
  });
  expect(out[3]?.properties).toEqual({
    platform: "windows",
    source: "app",
    item_list_id: "paywall",
    item_list_name: "Casama plans",
    plan: "plus_yearly",
    interval: "year",
  });
  expect(out[5]?.properties).toEqual({
    platform: "windows",
    source: "app",
    content_type: "referral",
    method: "copy",
  });
  expect(out[6]?.properties).toMatchObject({
    page_title: "/chat/:id",
    page_location: "https://app.casama.ai/chat/:id",
  });
});
