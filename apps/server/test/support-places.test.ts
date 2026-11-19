import { describe, expect, it } from "vitest";
import {
  filterPlaces,
  linkPlaces,
  normalizePlatform,
  normalizeRole,
  parseBuildNumber,
  placesPromptSection,
} from "../src/api/routes/support-places.ts";

describe("support-places helpers", () => {
  it("parses build numbers and normalizes platforms/roles", () => {
    expect(parseBuildNumber("1.2.3 (45)")).toBe(45);
    expect(parseBuildNumber("18")).toBe(18);
    expect(parseBuildNumber("1.2.3")).toBeNull();
    expect(parseBuildNumber(undefined)).toBeNull();

    expect(normalizePlatform("iOS")).toBe("ios");
    expect(normalizePlatform("macOS")).toBe("macos");
    expect(normalizePlatform("Android")).toBe("android");
    expect(normalizePlatform("fridge")).toBeNull();

    expect(normalizeRole("OWNER")).toBe("owner");
    expect(normalizeRole("member")).toBe("member");
    expect(normalizeRole("guest")).toBeNull();
  });

  it("filters places by publicOnly, cloud, platform, and role", () => {
    const webPublic = filterPlaces({
      publicOnly: true,
      cloud: true,
      platform: null,
      build: null,
      role: null,
    });
    expect(webPublic.every((p) => p.public)).toBe(true);
    expect(webPublic.some((p) => p.id === "store_subscriptions_apple")).toBe(true);
    expect(webPublic.some((p) => p.id === "store_subscriptions_google")).toBe(true);
    expect(webPublic.some((p) => p.id === "bot_settings")).toBe(false);

    const iosMember = filterPlaces({
      cloud: false,
      platform: "ios",
      build: 18,
      role: "member",
    });
    expect(iosMember.some((p) => p.id === "billing")).toBe(false);
    expect(iosMember.some((p) => p.id === "domains")).toBe(false);
    expect(iosMember.some((p) => p.id === "store_subscriptions_google")).toBe(false);
    expect(iosMember.some((p) => p.id === "store_subscriptions_apple")).toBe(false);
    expect(iosMember.some((p) => p.id === "widgets")).toBe(true);

    const iosCloudMember = filterPlaces({
      cloud: true,
      platform: "ios",
      build: 18,
      role: "member",
    });
    expect(iosCloudMember.some((p) => p.id === "store_subscriptions_apple")).toBe(true);
    expect(iosCloudMember.some((p) => p.id === "store_subscriptions_google")).toBe(false);
    expect(iosCloudMember.some((p) => p.id === "domains")).toBe(false);

    const macOwnerCloud = filterPlaces({
      cloud: true,
      platform: "macos",
      build: 18,
      role: "owner",
    });
    expect(macOwnerCloud.some((p) => p.id === "billing")).toBe(true);
    expect(macOwnerCloud.some((p) => p.id === "domains")).toBe(true);
  });

  it("rewrites valid place links, validates highlights and botIds, and deduplicates chips", () => {
    const allowed = filterPlaces({ cloud: true, platform: "ios", build: 18, role: "owner" });
    const botId = "11111111-1111-4111-8111-111111111111";
    const otherBotId = "22222222-2222-4222-8222-222222222222";
    const input = [
      "Open [Billing](place:billing?highlight=restore) or [Restore](place:billing?highlight=restore).",
      "Check [your bot](place:bot_settings?botId=11111111-1111-4111-8111-111111111111).",
      "Skip [bad highlight](place:privacy?highlight=nope), [forged bot](place:bot_settings?botId=22222222-2222-4222-8222-222222222222), [unknown](place:made_up), and [raw](casama://app/settings/billing).",
      "Keep `[code](place:billing)` and ```\n[fenced](place:privacy)\n``` intact.",
    ].join("\n");

    const res = linkPlaces(input, {
      mode: "app",
      enabled: true,
      allowed,
      verifiedBotIds: new Set([botId]),
    });

    expect(res.reply).toContain("[Billing](casama://app/settings/billing?highlight=restore)");
    expect(res.reply).toContain(`[your bot](casama://app/bots/${botId}/settings)`);
    expect(res.reply).toContain("[bad highlight](casama://app/settings/privacy)");
    expect(res.reply).toContain("forged bot, unknown, and raw.");
    expect(res.reply).not.toContain(otherBotId);
    expect(res.reply).toContain("`[code](place:billing)`");
    expect(res.reply).toContain("```\n[fenced](place:privacy)\n```");

    expect(res.places).toEqual([
      {
        id: "billing",
        label: "Billing",
        route: "/settings/billing?highlight=restore",
        url: "casama://app/settings/billing?highlight=restore",
      },
      {
        id: "bot_settings",
        label: "Bot settings",
        route: `/bots/${botId}/settings`,
        url: `casama://app/bots/${botId}/settings`,
      },
    ]);
  });

  it("strips place links when disabled and rewrites web links to casama.ai/open", () => {
    const allowed = filterPlaces({
      publicOnly: true,
      cloud: true,
      platform: null,
      build: null,
      role: null,
    });
    const disabled = linkPlaces(
      "Go to [Billing](place:billing?highlight=plan) or [X](casama://app/x).",
      {
        mode: "app",
        enabled: false,
        allowed,
      },
    );
    expect(disabled.reply).toBe("Go to Billing or X.");
    expect(disabled.places).toEqual([]);

    const web = linkPlaces(
      "Open [Privacy](place:privacy?highlight=export) or [Apple](place:store_subscriptions_apple).",
      {
        mode: "web",
        enabled: true,
        allowed,
      },
    );
    expect(web.reply).toBe(
      "Open [Privacy](https://casama.ai/open/settings/privacy?highlight=export) or [Apple](https://apps.apple.com/account/subscriptions).",
    );
    expect(web.places).toEqual([
      {
        id: "privacy",
        label: "Privacy & data",
        url: "https://casama.ai/open/settings/privacy?highlight=export",
      },
      {
        id: "store_subscriptions_apple",
        label: "Apple subscriptions",
        url: "https://apps.apple.com/account/subscriptions",
      },
    ]);
    expect(placesPromptSection(allowed, "web")).toContain("Clickable places");
  });
});
