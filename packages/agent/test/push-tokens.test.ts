/** Push tokens are only forgotten when the push service says the token itself is dead (D-271). */
import { describe, expect, it } from "vitest";
import { fcmTokenGone } from "../src/notifications.ts";

describe("fcmTokenGone", () => {
  it("404 always, 400 only when it names the token, nothing else", async () => {
    expect(await fcmTokenGone(new Response("", { status: 404 }))).toBe(true);
    expect(
      await fcmTokenGone(
        new Response(
          JSON.stringify({
            error: {
              status: "INVALID_ARGUMENT",
              message: "The registration token is not a valid FCM registration token",
            },
          }),
          { status: 400 },
        ),
      ),
    ).toBe(true);
    expect(
      await fcmTokenGone(
        new Response(
          JSON.stringify({
            error: {
              status: "INVALID_ARGUMENT",
              message: "Invalid value at 'message.data[0].value'",
            },
          }),
          { status: 400 },
        ),
      ),
    ).toBe(false);
    expect(await fcmTokenGone(new Response("", { status: 500 }))).toBe(false);
    expect(await fcmTokenGone(new Response("{}", { status: 200 }))).toBe(false);
  });
});
