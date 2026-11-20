import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import {
  BOT_AVATAR_MAX_LENGTH,
  botImageAvatar,
  isValidBotAvatar,
  parseBotAvatar,
  portableBotAvatar,
} from "../src/bot-avatar.ts";

const { vectors } = JSON.parse(
  readFileSync(new URL("./fixtures/bot-avatar-vectors.json", import.meta.url), "utf8"),
) as {
  vectors: {
    value: string | null;
    kind: string;
    mascot?: string;
    id?: string;
    colors?: string[];
  }[];
};

describe("bot avatar values", () => {
  it.each(vectors)("$value is $kind", (v) => {
    const a = parseBotAvatar(v.value);
    expect(a.kind).toBe(v.kind);
    if (a.kind === "mascot") expect(a.mascot).toBe(v.mascot);
    if (a.kind === "image") {
      expect(a.id).toBe(v.id);
      expect(a.colors).toEqual(v.colors);
    }
  });

  it("builds picture values that fit the widget payload caps", () => {
    const v = botImageAvatar("6F1C2E9A-3B4D-4C5E-8F70-1A2B3C4D5E6F", ["#7A90FF", "7de9f4"]);
    expect(v).toBe("image:6f1c2e9a-3b4d-4c5e-8f70-1a2b3c4d5e6f:7a90ff7de9f4");
    expect(v.length).toBe(BOT_AVATAR_MAX_LENGTH);
    expect(v.length).toBeLessThanOrEqual(64); // glance.ts keeps avatars up to 64 characters
    expect(() => botImageAvatar("nope", ["#000000", "#ffffff"])).toThrow();
  });

  it("accepts only null, known mascots and pictures", () => {
    expect(isValidBotAvatar(null)).toBe(true);
    expect(isValidBotAvatar("mascot:cool")).toBe(true);
    expect(isValidBotAvatar("https://tracker.example/p.gif")).toBe(false);
    expect(isValidBotAvatar("")).toBe(false);
  });

  it("falls back to the earlier mascot where pictures don't travel", () => {
    const pic = "image:6f1c2e9a-3b4d-4c5e-8f70-1a2b3c4d5e6f:7a90ff7de9f4";
    expect(portableBotAvatar("mascot:shy")).toBe("mascot:shy");
    expect(portableBotAvatar(pic, "mascot:wow")).toBe("mascot:wow");
    expect(portableBotAvatar(pic, null)).toBeNull();
    expect(portableBotAvatar(null)).toBeNull();
  });
});
