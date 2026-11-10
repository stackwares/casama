import { describe, expect, it } from "vitest";
import { describeStep, focusedIsPassword, nextSecretName, teachTranscript } from "../src/teach.ts";

describe("teach", () => {
  it("spots a focused password field in either snapshot style", () => {
    expect(focusedIsPassword('- textbox "Password" [focused, password]')).toBe(true);
    expect(focusedIsPassword("AXSecureTextField focused")).toBe(true);
    expect(focusedIsPassword('- textbox "Password" [ref=e2]\n- textbox "Name" [focused]')).toBe(false);
    expect(focusedIsPassword(null)).toBe(false);
  });

  it("names secrets without clashes", () => {
    expect(nextSecretName([])).toBe("PASSWORD");
    expect(nextSecretName(["PASSWORD", null, "PASSWORD_2"])).toBe("PASSWORD_3");
  });

  it("describes steps with placeholders for secrets and groups them by page", () => {
    expect(describeStep({ seq: 1, kind: "click", x: 3, y: 4, button: 3 })).toBe("right-click at (3, 4)");
    expect(describeStep({ seq: 2, kind: "type", secretName: "PASSWORD", password: true })).toContain("{{secret:PASSWORD}}");
    const t = teachTranscript([
      { seq: 1, kind: "click", x: 1, y: 2, url: "https://a.example", snapshot: "- button Save" },
      { seq: 2, kind: "type", text: "hi", url: "https://a.example" },
      { seq: 3, kind: "key", key: "Enter", url: "https://b.example" },
    ]);
    expect(t.match(/On https:\/\/a\.example/g)).toHaveLength(1);
    expect(t).toContain("On https://b.example");
    expect(t).toContain("Screen after: - button Save");
    expect(teachTranscript([{ seq: 1, kind: "type", text: "x".repeat(500) }], { maxChars: 1200 })).toContain("(recording trimmed)");
  });
});
