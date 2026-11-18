import { describe, expect, it } from "vitest";
import { compareVersions, EMPTY, flag, gate, promptFor } from "../src/lib/remote-config.ts";

describe("remote settings", () => {
  it("compares versions", () => {
    expect(compareVersions("0.1.0", "0.2.0")).toBe(-1);
    expect(compareVersions("0.10.0", "0.9.9")).toBe(1);
    expect(compareVersions("1.0", "1.0.0")).toBe(0);
  });

  it("reads a prompt from the settings and keeps its own when it's missing or blank (D-372)", () => {
    const config = { ...EMPTY, prompts: { "write.draft": "Draft it.", "write.reply": " " } };
    expect(promptFor(config, "write.draft", "x")).toBe("Draft it.");
    expect(promptFor(config, "write.reply", "Own reply")).toBe("Own reply");
    expect(promptFor(EMPTY, "write.draft", "Own")).toBe("Own");
    expect(promptFor(null, "write.draft", "Own")).toBe("Own");
  });

  it("lets the extension run with no settings", () => {
    expect(gate(EMPTY, "0.1.0")).toEqual({ state: "ok" });
  });

  it("turns the extension off with the kill switch", () => {
    expect(gate({ ...EMPTY, flags: { chrome_extension: false } }, "0.1.0")).toEqual({
      state: "off",
    });
    expect(gate({ ...EMPTY, flags: { chrome_extension: true } }, "0.1.0")).toEqual({ state: "ok" });
  });

  it("asks an old version to update, and ignores other platforms' minimums", () => {
    const config = {
      ...EMPTY,
      min_versions: { chrome: "0.2.0", ios: "9.0.0" },
      update_urls: { chrome: "https://chromewebstore.google.com/" },
    };
    expect(gate(config, "0.1.0")).toEqual({
      state: "update",
      minVersion: "0.2.0",
      updateUrl: "https://chromewebstore.google.com/",
    });
    expect(gate(config, "0.2.0")).toEqual({ state: "ok" });
  });

  it("shows maintenance", () => {
    expect(gate({ ...EMPTY, maintenance: { message: "Back soon" } }, "0.1.0")).toEqual({
      state: "maintenance",
      message: "Back soon",
    });
  });

  it("reads flags with a default", () => {
    expect(flag({ ...EMPTY, flags: { a: false } }, "a", true)).toBe(false);
    expect(flag(EMPTY, "b", true)).toBe(true);
  });
});
