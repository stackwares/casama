import { describe, expect, it } from "vitest";
import { type MentionableApp, parseAppMentions, resolveAppMentions } from "../src/app-mentions.ts";

const apps: MentionableApp[] = [
  {
    integrationId: "int-gmail",
    label: "Gmail",
    aliases: ["gmail"],
    appId: "gmail",
    kind: "composio",
    toolkit: "gmail",
  },
  {
    integrationId: "int-gcal",
    label: "Google Calendar",
    aliases: ["google_calendar", "googlecalendar"],
    appId: "google_calendar",
    kind: "composio",
    toolkit: "googlecalendar",
  },
  {
    integrationId: "int-google",
    label: "Google",
    aliases: ["google"],
    kind: "mcp",
  },
  {
    integrationId: "int-linear",
    label: "Linear",
    aliases: ["linear"],
    appId: "linear",
    kind: "mcp",
  },
  {
    integrationId: "int-notion",
    label: "Notion",
    aliases: ["notion"],
    appId: "notion",
    kind: "mcp",
  },
];

describe("parseAppMentions", () => {
  it("matches exact app names and aliases case-insensitively in order of appearance", () => {
    const out = parseAppMentions("Check @linear then draft in @GMAIL.", apps);
    expect(out.map((m) => m.label)).toEqual(["Linear", "Gmail"]);
  });

  it("ignores email addresses and mid-word @ tokens", () => {
    expect(parseAppMentions("Reply to alice@gmail.com and bob@linear.app", apps)).toEqual([]);
    expect(parseAppMentions("Not @gmailx or @@gmail", apps)).toEqual([]);
  });

  it("matches multi-word names longest-first over shorter prefixes", () => {
    const out = parseAppMentions("Look at @Google Calendar for tomorrow", apps);
    expect(out.map((m) => m.integrationId)).toEqual(["int-gcal"]);
  });

  it("deduplicates repeated mentions and caps at 3", () => {
    const out = parseAppMentions("@Gmail @Linear @Gmail @Notion @Google Calendar", apps);
    expect(out.map((m) => m.label)).toEqual(["Gmail", "Linear", "Notion"]);
  });

  it("lets reserved bot names win plain-text collisions in group chats", () => {
    const out = parseAppMentions("@Linear check @Gmail and @everyone", apps, {
      reservedNames: ["Linear", "everyone", "all", "team"],
    });
    expect(out.map((m) => m.label)).toEqual(["Gmail"]);
  });

  it("does not guess from plain text when two connected apps share the same name or alias", () => {
    const twoGmails: MentionableApp[] = [
      { integrationId: "int-1", label: "Gmail Work", aliases: ["gmail"], appId: "gmail" },
      { integrationId: "int-2", label: "Gmail Personal", aliases: ["gmail"], appId: "gmail" },
    ];
    // Ambiguous @gmail is skipped; specific connection labels still resolve cleanly.
    expect(parseAppMentions("Check @gmail", twoGmails)).toEqual([]);
    expect(parseAppMentions("Check @Gmail Work", twoGmails).map((m) => m.integrationId)).toEqual([
      "int-1",
    ]);
  });
});

describe("resolveAppMentions", () => {
  it("resolves picked apps even when a bot shares the same name", () => {
    const { resolved, unresolvedPicked } = resolveAppMentions(
      "@Linear check @Gmail",
      apps,
      [{ integration_id: "int-linear" }],
      { reservedNames: ["Linear"] },
    );
    expect(unresolvedPicked).toEqual([]);
    expect(resolved).toEqual([
      {
        integrationId: "int-linear",
        label: "Linear",
        appId: "linear",
        kind: "mcp",
        source: "picker",
      },
      {
        integrationId: "int-gmail",
        toolkit: "gmail",
        label: "Gmail",
        appId: "gmail",
        kind: "composio",
        source: "typed",
      },
    ]);
  });

  it("reports picked apps not available on the bot in unresolvedPicked", () => {
    const { resolved, unresolvedPicked } = resolveAppMentions("Check @Slack", apps, [
      { integration_id: "int-other-bot" },
    ]);
    expect(resolved).toEqual([]);
    expect(unresolvedPicked).toEqual([{ integration_id: "int-other-bot" }]);
  });

  it("deduplicates picked and typed mentions of the same app and respects the 3-app cap", () => {
    const { resolved } = resolveAppMentions("@Gmail @Linear @Notion @Google Calendar", apps, [
      { integration_id: "int-gmail", toolkit: "gmail" },
    ]);
    expect(resolved.map((r) => [r.label, r.source])).toEqual([
      ["Gmail", "picker"],
      ["Linear", "typed"],
      ["Notion", "typed"],
    ]);
  });
});
