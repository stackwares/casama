/** Notification text (D-312): phones draw plain text, so markdown, repeated headings and mid-word cuts go. */
import { generateKeyPairSync } from "node:crypto";
import { describe, expect, it } from "vitest";
import { BRIEF_INSTRUCTIONS, briefInstructions, QUIET_BRIEF } from "../src/checkins.ts";
import { FcmPushSender, plainText, pushText } from "../src/notifications.ts";

describe("pushText", () => {
  it("turns the morning brief from the 16 Nov screenshot into plain words", () => {
    const md = [
      "**Morning brief — Mon 16 Nov**",
      "",
      "**Today**",
      "- No meetings.",
      "",
      "**Needs your reply or a decision**",
      "- **Casama plan**: Plus ended, workspace moved to **Free**.",
    ].join("\n");
    const { title, body } = pushText("Morning brief", md);
    expect(title).toBe("Morning brief");
    expect(body).toBe(
      "Today · No meetings. Needs your reply or a decision · Casama plan: Plus ended, workspace moved to Free.",
    );
    expect(body).not.toContain("*");
  });

  it("drops a heading that repeats a 'Bot: Routine' title, but not a sentence starting with the bot's name", () => {
    expect(
      pushText("Max: Morning brief", "# Morning brief, Tuesday\nTwo meetings today.").body,
    ).toBe("Two meetings today.");
    expect(pushText("Casama", "Casama plan dropped to Free\nWant a look?").body).toBe(
      "Casama plan dropped to Free · Want a look?",
    );
  });

  it("cuts at a word with an ellipsis, and never leaves a dangling **", () => {
    const { body } = pushText("T", `${"word ".repeat(80)}**bold`);
    expect(body.length).toBeLessThanOrEqual(240);
    expect(body.endsWith("word…")).toBe(true);
    expect(pushText("T", "Moved to **Free").body).toBe("Moved to Free");
  });

  it("keeps link words, code text and snake_case names", () => {
    expect(plainText("See [the ticket](https://x.y/1), run `pnpm test` on my_file_name")).toBe(
      "See the ticket, run pnpm test on my_file_name",
    );
    expect(plainText("_soon_ and *now*")).toBe("soon and now");
  });
});

describe("brief instructions", () => {
  it("briefs made with the original text get today's wording; a rewritten brief keeps its own", () => {
    expect(
      briefInstructions("Write my morning brief for today. Check what you can reach: old text"),
    ).toBe(BRIEF_INSTRUCTIONS);
    expect(briefInstructions("Tell me the weather and my first meeting.")).toBe(
      "Tell me the weather and my first meeting.",
    );
    expect(BRIEF_INSTRUCTIONS).toContain("Quiet day");
    expect(QUIET_BRIEF.test("Quiet day: nothing on the calendar.")).toBe(true);
    expect(QUIET_BRIEF.test("**Quiet day** today")).toBe(true);
    expect(QUIET_BRIEF.test("Two meetings; not a quiet day.")).toBe(false);
  });
});

describe("FCM tag", () => {
  it("a tagged push replaces the last one on the phone (Android tag, iOS collapse id)", async () => {
    const { privateKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
    const bodies: Array<Record<string, any>> = [];
    const fetchImpl = (async (url: string, init: { body: unknown }) => {
      if (String(url).includes("oauth2"))
        return new Response(JSON.stringify({ access_token: "t", expires_in: 3600 }));
      bodies.push(JSON.parse(String(init.body)));
      return new Response("{}");
    }) as unknown as typeof fetch;
    const fcm = new FcmPushSender(
      JSON.stringify({
        client_email: "a@b.c",
        project_id: "p",
        private_key: privateKey.export({ type: "pkcs8", format: "pem" }),
      }),
      fetchImpl,
    );
    await fcm.send(["tok"], { title: "Morning brief", body: "b", tag: "brief-1" });
    await fcm.send(["tok"], { title: "Hi", body: "b" });
    expect(bodies[0]?.message.android).toEqual({ notification: { tag: "brief-1" } });
    expect(bodies[0]?.message.apns.headers).toEqual({ "apns-collapse-id": "brief-1" });
    expect(bodies[1]?.message.android).toBeUndefined();
    expect(bodies[1]?.message.apns.headers).toBeUndefined();
  });
});
