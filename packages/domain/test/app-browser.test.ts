import { describe, expect, it } from "vitest";
import {
  APP_BROWSER_OFF,
  appBrowserFor,
  checkAppBrowserSettings,
  detectBrowserBlock,
} from "../src/index.ts";

const U1 = "11111111-1111-4111-8111-111111111111";
const U2 = "22222222-2222-4222-8222-222222222222";

describe("phone browser stage", () => {
  it("starts off, with only 'asked' as a reason", () => {
    expect(APP_BROWSER_OFF).toMatchObject({
      stage: "off",
      reasons: { asked: true, blocked: false, signed_in: false },
    });
    expect(
      appBrowserFor(APP_BROWSER_OFF, { userId: U1, system: "android", workspaceOn: true }),
    ).toEqual({ available: false, reason: "off" });
  });

  it("refuses anything it doesn't know, so a typo can't switch it on", () => {
    expect(checkAppBrowserSettings({ stage: "everyone" }).settings).toBeUndefined();
    expect(checkAppBrowserSettings({ stage: "on", sytems: ["ios"] }).settings).toBeUndefined();
    expect(checkAppBrowserSettings({ stage: "on", systems: ["web"] }).settings).toBeUndefined();
    expect(
      checkAppBrowserSettings({ stage: "on", reasons: { blokced: true } }).settings,
    ).toBeUndefined();
    expect(checkAppBrowserSettings({ stage: "testers", testers: ["me"] }).settings).toBeUndefined();
    expect(checkAppBrowserSettings("on").settings).toBeUndefined();
  });

  it("testers get both systems; the public only the listed ones", () => {
    const testers = checkAppBrowserSettings({ stage: "testers", testers: [U1.toUpperCase()] })
      .settings!;
    expect(appBrowserFor(testers, { userId: U1, system: "ios", workspaceOn: true }).available).toBe(
      true,
    );
    expect(appBrowserFor(testers, { userId: U2, system: "ios", workspaceOn: true })).toEqual({
      available: false,
      reason: "not_a_tester",
    });
    const on = checkAppBrowserSettings({ stage: "on", systems: ["android"] }).settings!;
    expect(appBrowserFor(on, { userId: U2, system: "android", workspaceOn: true }).available).toBe(
      true,
    );
    expect(appBrowserFor(on, { userId: U2, system: "ios", workspaceOn: true })).toEqual({
      available: false,
      reason: "system_off",
    });
    expect(appBrowserFor(on, { userId: U2, system: "android", workspaceOn: false })).toEqual({
      available: false,
      reason: "workspace_off",
    });
  });
});

describe("pages that keep a bot's computer out", () => {
  it("sees challenges and refusals", () => {
    expect(detectBrowserBlock("Just a moment...\nVerify you are human")?.kind).toBe("challenge");
    expect(detectBrowserBlock("Press & Hold to confirm you are a human")?.kind).toBe("challenge");
    expect(
      detectBrowserBlock(
        "Our systems have detected unusual traffic from your computer network. This page checks to see if it's really you.",
      )?.kind,
    ).toBe("challenge");
    expect(detectBrowserBlock("Access Denied\nYou don't have permission")?.kind).toBe("denied");
    expect(detectBrowserBlock("Sorry, you have been blocked")?.kind).toBe("denied");
    expect(detectBrowserBlock("403 Forbidden")?.kind).toBe("denied");
  });

  it("leaves ordinary pages alone, even ones that mention a CAPTCHA", () => {
    expect(detectBrowserBlock("")).toBeNull();
    expect(detectBrowserBlock('- button "Add to basket" [ref=e1]')).toBeNull();
    const article = `How CAPTCHAs work. ${"Sites sometimes ask visitors to complete the captcha before they continue, and a page may say access denied when a rule matches. ".repeat(20)}`;
    expect(article.length).toBeGreaterThan(1200);
    expect(detectBrowserBlock(article)).toBeNull();
    // A long page still counts when it carries a phrase only a block page has.
    expect(detectBrowserBlock(`${article} Sorry, you have been blocked.`)?.kind).toBe("denied");
  });
});
