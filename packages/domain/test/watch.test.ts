import { describe, expect, it } from "vitest";
import {
  isMoneyLike,
  isOutsideTool,
  isPaymentTool,
  spendsMoney,
  watchAllowance,
} from "../src/watch.ts";

const base = { risk: "low", payment: false, level: "medium", isYours: true } as const;

describe("watchAllowance (D-410)", () => {
  it("allows low risk in one tap and medium risk with a hold", () => {
    expect(watchAllowance(base)).toEqual({ can_allow: "tap", why_phone: null });
    expect(watchAllowance({ ...base, risk: "medium" })).toEqual({
      can_allow: "hold",
      why_phone: null,
    });
  });

  it("keeps high risk and payments on the phone", () => {
    expect(watchAllowance({ ...base, risk: "high" })).toEqual({
      can_allow: "phone",
      why_phone: "high_risk",
    });
    expect(watchAllowance({ ...base, payment: true })).toEqual({
      can_allow: "phone",
      why_phone: "payment",
    });
    // A payment says payment, not high risk.
    expect(watchAllowance({ ...base, risk: "high", payment: true }).why_phone).toBe("payment");
  });

  it("follows the person's setting", () => {
    expect(watchAllowance({ ...base, level: "low" })).toEqual({
      can_allow: "tap",
      why_phone: null,
    });
    expect(watchAllowance({ ...base, level: "low", risk: "medium" }).why_phone).toBe("setting");
    expect(watchAllowance({ ...base, level: "none" }).why_phone).toBe("setting");
    expect(watchAllowance({ ...base, level: "none", risk: "high" }).why_phone).toBe("high_risk");
  });

  it("follows the workspace, and allows only the person's own runs", () => {
    expect(watchAllowance({ ...base, workspaceOff: true }).why_phone).toBe("workspace");
    expect(watchAllowance({ ...base, isYours: false })).toEqual({
      can_allow: "phone",
      why_phone: "not_yours",
    });
  });

  it("knows payment tools", () => {
    expect(isPaymentTool("payments.request")).toBe(true);
    expect(isPaymentTool("web.search")).toBe(false);
  });

  it("keeps a paid data call on the phone: it buys something at medium risk", () => {
    expect(spendsMoney("data.call")).toBe(true);
    expect(spendsMoney("payments.request")).toBe(true);
    expect(spendsMoney("data.search")).toBe(false);
    expect(spendsMoney("mail.send")).toBe(false);
    // By the tool's name alone, whatever the caller passed as `payment`.
    expect(watchAllowance({ ...base, risk: "medium", tool: "data.call" })).toEqual({
      can_allow: "phone",
      why_phone: "payment",
    });
  });

  it("lets a tool from outside allow in one tap only when it is low risk and not about money", () => {
    const gmailRead = "composio.gmail.GMAIL_FETCH_EMAILS";
    expect(watchAllowance({ ...base, tool: gmailRead })).toEqual({
      can_allow: "tap",
      why_phone: null,
    });
    // Medium from outside: phone, not a hold.
    expect(watchAllowance({ ...base, risk: "medium", tool: "mcp.linear.create_issue" })).toEqual({
      can_allow: "phone",
      why_phone: "high_risk",
    });
    // Money by name, even when it calls itself read-only.
    for (const tool of [
      "composio.stripe.STRIPE_CREATE_REFUND",
      "mcp.paypal.create_payment",
      "mcp.shopify.createOrder",
      "pipedream.square.charge_card",
      "openapi.bank.transferFunds",
    ])
      expect(watchAllowance({ ...base, tool }).why_phone, tool).toBe("high_risk");
    // Built-in tools keep their own rating.
    expect(watchAllowance({ ...base, risk: "medium", tool: "mail.send" }).can_allow).toBe("hold");
    expect(isOutsideTool("mail.send")).toBe(false);
    expect(isOutsideTool("local_mcp.files.read")).toBe(true);
    expect(isMoneyLike("composio.gmail.GMAIL_SEND_EMAIL")).toBe(false);
  });
});
