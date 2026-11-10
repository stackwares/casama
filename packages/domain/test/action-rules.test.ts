import { describe, expect, it } from "vitest";
import {
  type ActionRule,
  describeActionRule,
  extractTarget,
  isCredentialChange,
  resolveActionRule,
  toolCategory,
} from "../src/action-rules.ts";

const rule = (r: Partial<ActionRule>): ActionRule => ({
  id: Math.random().toString(),
  bot_id: null,
  match_kind: "category",
  match_value: "send",
  target: null,
  rule: "ask",
  ...r,
});
const BOT = "b1";

describe("action rules", () => {
  it("categorizes tools and reads targets from arguments", () => {
    expect(toolCategory("composio.gmail.GMAIL_SEND_EMAIL")).toBe("send");
    expect(toolCategory("stripe.create_refund")).toBe("pay");
    expect(toolCategory("files.read")).toBeNull();
    expect(
      extractTarget({ to: "Ana <ana@acme.com>", cc: ["bo@sub.acme.com"], amount: "$120.50" }),
    ).toEqual({
      recipients: ["ana@acme.com", "bo@sub.acme.com"],
      domains: ["acme.com", "sub.acme.com"],
      amount: 120.5,
    });
    expect(isCredentialChange("browser.fill", { field: "change password" })).toBe(true);
    expect(isCredentialChange("browser.fill", { field: "search" })).toBe(false);
  });

  it("email to your domain is allowed, external email asks", () => {
    const rules = [
      rule({ rule: "ask" }),
      rule({ rule: "allow_within_limits", target: { domains: ["acme.com"] } }),
    ];
    const send = (to: string) =>
      resolveActionRule(rules, {
        botId: BOT,
        tool: "mail.send",
        category: "send",
        target: extractTarget({ to }),
      })?.rule;
    expect(send("ana@acme.com")).toBe("allow_within_limits");
    expect(send("ana@acme.com, eve@evil.example")).toBe("ask");
    expect(send("eve@evil.example")).toBe("ask");
  });

  it("the most specific rule wins; ask or hand off wins ties", () => {
    const t = extractTarget({});
    expect(
      resolveActionRule(
        [
          rule({ rule: "ask" }),
          rule({ match_kind: "tool", match_value: "mail.send", rule: "allow" }),
        ],
        { botId: BOT, tool: "mail.send", category: "send", target: t },
      )?.rule,
    ).toBe("allow");
    expect(
      resolveActionRule([rule({ rule: "allow" }), rule({ bot_id: BOT, rule: "hand_off" })], {
        botId: BOT,
        tool: "mail.send",
        category: "send",
        target: t,
      })?.rule,
    ).toBe("hand_off");
    expect(
      resolveActionRule([rule({ rule: "allow" }), rule({ rule: "ask" })], {
        botId: BOT,
        tool: "mail.send",
        category: "send",
        target: t,
      })?.rule,
    ).toBe("ask");
    expect(
      resolveActionRule([rule({ bot_id: "other", rule: "allow" })], {
        botId: BOT,
        tool: "mail.send",
        category: "send",
        target: t,
      }),
    ).toBeNull();
  });

  it("reads rules in plain language", () => {
    expect(
      describeActionRule({
        match_kind: "category",
        match_value: "send",
        target: { domains: ["acme.com"] },
        rule: "allow_within_limits",
      }),
    ).toBe("Sends messages to anyone at acme.com without asking");
    expect(
      describeActionRule({
        match_kind: "category",
        match_value: "pay",
        target: null,
        rule: "hand_off",
      }),
    ).toBe("Makes payments only by handing it to you to finish");
  });
});
