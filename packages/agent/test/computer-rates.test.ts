/** Computer time priced at what the provider charges (D-180). */
import { describe, expect, it } from "vitest";
import { COMPUTER_RATES, computerCostUsd, computerRates } from "../src/computers.ts";

describe("computer prices", () => {
  it("E2B and Daytona charge about $0.166 an hour for 2 vCPU / 4 GiB", () => {
    for (const p of ["e2b", "daytona"])
      expect(computerCostUsd(p, { cpus: 2, memory_mb: 4096 }, 3600)).toBeCloseTo(0.1656, 4);
  });

  it("our own Docker servers cost about $0.008 an hour for the default 1 vCPU / 1 GB", () => {
    expect(computerCostUsd("docker", { cpus: 1, memory_mb: 1024 }, 3600)).toBeCloseTo(0.008, 4);
    expect(computerCostUsd("docker", null, 1800)).toBeCloseTo(0.004, 4);
    expect(computerCostUsd("local", { cpus: 4, memory_mb: 8192 }, 3600)).toBe(0);
    // Unknown providers fall back to the Docker price.
    expect(computerCostUsd("other", { cpus: 1, memory_mb: 1024 }, 3600)).toBeCloseTo(0.008, 4);
  });

  it("COMPUTER_RATES overrides some prices and keeps the rest", () => {
    const rates = computerRates('{"docker":{"cpu_hour":0.001},"e2b":{"gb_hour":0}}');
    expect(rates.docker).toEqual({ cpu_hour: 0.001, gb_hour: 0.005 });
    expect(rates.e2b).toEqual({ cpu_hour: 0.0504, gb_hour: 0 });
    expect(rates.daytona).toEqual(COMPUTER_RATES.daytona);
    expect(computerRates(undefined)).toBe(COMPUTER_RATES);
    expect(() => computerRates('{"docker":{"cpu_hour":-1}}')).toThrow("bad rate");
  });
});
