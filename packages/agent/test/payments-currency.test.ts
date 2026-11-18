import { describe, expect, it } from "vitest";
import {
  formatMoney,
  fromMinorUnits,
  minorUnitsPerUnit,
  registerPaymentTools,
  toMinorUnits,
} from "../src/payments.ts";
import { ToolRegistry } from "../src/tools/registry.ts";

describe("card amounts in minor units", () => {
  it("follows Stripe's decimals per currency", () => {
    expect(minorUnitsPerUnit("usd")).toBe(100);
    expect(minorUnitsPerUnit("JPY")).toBe(1);
    expect(minorUnitsPerUnit("krw")).toBe(1);
    expect(minorUnitsPerUnit("KWD")).toBe(1000);
    expect(toMinorUnits(89.5, "USD")).toBe(8950);
    expect(toMinorUnits(0.1 + 0.2, "EUR")).toBe(30);
    expect(toMinorUnits(500, "JPY")).toBe(500);
    expect(toMinorUnits(12000.4, "KRW")).toBe(12000);
    // Stripe takes three-decimal amounts only in tens.
    expect(toMinorUnits(12.345, "BHD")).toBe(12350);
    expect(toMinorUnits(5, "KWD")).toBe(5000);
    expect(fromMinorUnits(500, "JPY")).toBe(500);
    expect(fromMinorUnits(5000, "KWD")).toBe(5);
    expect(formatMoney(8950, "usd")).toBe("$89.50");
    expect(formatMoney(500, "JPY")).toBe("¥500");
  });
});

describe("payments.request currency", () => {
  const reg = new ToolRegistry();
  registerPaymentTools(reg, {
    db: {} as never,
    providerFor: async () => {
      throw new Error("not reached");
    },
  });
  const tool = reg.get("payments.request")!;

  it("asks only in dollars, the caps' currency", () => {
    const base = { merchant: "Amtrak", amount: 40, reason: "tickets" };
    expect(tool.schema.safeParse({ ...base, currency: "usd" }).success).toBe(true);
    expect(tool.schema.safeParse({ ...base, currency: "JPY" }).success).toBe(false);
  });

  it("refuses another currency before any card or cap is looked at", async () => {
    await expect(
      tool.execute(
        { merchant: "Shinkansen", amount: 14000, currency: "JPY", reason: "tickets" } as never,
        { runId: "r", botId: "b", orgId: "o" } as never,
      ),
    ).rejects.toMatchObject({ code: "payment_currency" });
  });
});
