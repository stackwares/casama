import { describe, expect, it } from "vitest";
import { healthTrends, isPrivateBaseUrl } from "../src/device-data.ts";

describe("device data", () => {
  it("private model servers: this machine and private networks only", () => {
    for (const u of [
      "http://localhost:11434/v1",
      "http://127.0.0.1:1234",
      "http://10.0.0.5",
      "http://192.168.1.20:8080",
      "http://172.20.0.3",
      "http://ollama.local",
      "http://host.docker.internal:11434",
      "http://[::1]:8000",
      "http://100.101.1.2",
    ])
      expect(isPrivateBaseUrl(u), u).toBe(true);
    for (const u of [
      null,
      undefined,
      "",
      "https://api.openai.com/v1",
      "https://openrouter.ai/api/v1",
      "http://172.32.0.1",
      "http://8.8.8.8",
      "not a url",
    ])
      expect(isPrivateBaseUrl(u as string), String(u)).toBe(false);
  });

  it("health days compared with the person's previous 30 days, in neutral words", () => {
    const day = (date: string, minutes: number, steps?: number) => ({
      type: "day",
      date,
      sleep: { minutes },
      steps,
    });
    const history = [1, 2, 3, 4, 5, 6].map((i) =>
      day(`2027-01-${String(10 - i).padStart(2, "0")}`, 420, 8000),
    );
    const t = healthTrends(history, day("2027-01-10", 300, 8200));
    expect(t.sleep_minutes).toEqual({ value: 300, usual: 420, compared: "lower than your usual" });
    expect(t.steps?.compared).toBe("about your usual");
    expect(healthTrends(history, day("2027-01-10", 500)).sleep_minutes?.compared).toBe(
      "higher than your usual",
    );
    // Too little history, or days outside the 30 before: no "usual".
    expect(healthTrends(history.slice(0, 4), day("2027-01-10", 300))).toEqual({});
    expect(healthTrends(history, day("2027-03-01", 300))).toEqual({});
    // Later days never count towards an earlier one.
    expect(
      healthTrends(
        [...history, day("2027-01-11", 100), day("2027-01-12", 100)],
        day("2027-01-10", 420),
      ).sleep_minutes?.usual,
    ).toBe(420);
  });
});
