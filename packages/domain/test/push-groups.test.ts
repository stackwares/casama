import { describe, expect, it } from "vitest";
import { pushGroup, pushGroupOn, pushIsHighPriority } from "../src/push-groups.ts";

describe("push groups (D-325)", () => {
  it("maps each kind to its settings row", () => {
    expect(pushGroup("reply")).toBe("replies");
    expect(pushGroup("approval_request")).toBe("needs_you");
    expect(pushGroup("secret")).toBe("needs_you");
    expect(pushGroup("takeover")).toBe("needs_you");
    expect(pushGroup("call_missed")).toBe("needs_you");
    expect(pushGroup("routine_result")).toBe("routines");
    expect(pushGroup("bot_message")).toBe("routines");
    expect(pushGroup("suggestion")).toBe("suggestions");
    expect(pushGroup("credits_low")).toBe("account");
    expect(pushGroup("something_new")).toBe("account");
  });

  it("is on unless turned off", () => {
    expect(pushGroupOn(null, "replies")).toBe(true);
    expect(pushGroupOn({}, "routines")).toBe(true);
    expect(pushGroupOn({ routines: false }, "routines")).toBe(false);
    expect(pushGroupOn({ routines: false }, "replies")).toBe(true);
  });

  it("sends replies and requests at high priority", () => {
    expect(pushIsHighPriority("replies")).toBe(true);
    expect(pushIsHighPriority("needs_you")).toBe(true);
    expect(pushIsHighPriority("routines")).toBe(false);
    expect(pushIsHighPriority("account")).toBe(false);
  });
});
