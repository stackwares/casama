import { describe, expect, it } from "vitest";
import { balanceStatus, quotaStatus } from "./status.ts";

describe("quotaStatus", () => {
  it("classifies threshold crossings", () => {
    expect(quotaStatus(79, 100)).toBe("ok");
    expect(quotaStatus(80, 100)).toBe("low");
    expect(quotaStatus(100, 100)).toBe("out");
    expect(quotaStatus(50, 100, 0.5)).toBe("low");
  });
  it("does not report invalid or missing readings as healthy", () => {
    expect(quotaStatus(null, 100)).toBe("unknown");
    expect(quotaStatus(0, 0)).toBe("unknown");
    expect(quotaStatus(Number.NaN, 100)).toBe("unknown");
    expect(quotaStatus(1, 100, 0)).toBe("unknown");
  });
});

describe("balanceStatus", () => {
  it("classifies depletion and low balance in currency units", () => {
    expect(balanceStatus(6, 5)).toBe("ok");
    expect(balanceStatus(5, 5)).toBe("low");
    expect(balanceStatus(0, 5)).toBe("out");
    expect(balanceStatus(-1, 5)).toBe("out");
  });
  it("rejects missing or invalid readings and thresholds", () => {
    expect(balanceStatus(null, 5)).toBe("unknown");
    expect(balanceStatus(Number.NaN, 5)).toBe("unknown");
    expect(balanceStatus(10, -1)).toBe("unknown");
  });
});
