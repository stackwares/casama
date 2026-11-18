import { describe, expect, it } from "vitest";
import { parseInvite } from "../src/api/routes/joining.ts";
import { appLink, loadEnv } from "../src/env.ts";
import { accountEmailContent } from "../src/services/account-emails.ts";

/** Links in emails and invites open the installed app where there is one (D-326). */
describe("app links (D-326)", () => {
  const cloud = {
    PUBLIC_APP_URL: "https://app.casama.ai",
    PUBLIC_OPEN_URL: "https://casama.ai/open",
  };

  it("go through PUBLIC_OPEN_URL when set, else the web app", () => {
    expect(appLink(cloud, "/settings/billing")).toBe("https://casama.ai/open/settings/billing");
    expect(appLink(cloud)).toBe("https://casama.ai/open");
    expect(appLink({ PUBLIC_APP_URL: "https://casama.example.com/" }, "/join/x")).toBe(
      "https://casama.example.com/join/x",
    );
    expect(appLink({ ...cloud, PUBLIC_OPEN_URL: "https://casama.ai/open/" }, "/import/t")).toBe(
      "https://casama.ai/open/import/t",
    );
  });

  it("an empty PUBLIC_OPEN_URL (compose writes KEY=) means unset", () => {
    const env = loadEnv({
      DATABASE_URL: "postgres://x",
      SUPABASE_URL: "https://sb.example.com",
      SUPABASE_ANON_KEY: "anon",
      PUBLIC_APP_URL: "https://casama.example.com",
      PUBLIC_OPEN_URL: "",
    });
    expect(env.PUBLIC_OPEN_URL).toBeUndefined();
    expect(appLink(env, "/bots")).toBe("https://casama.example.com/bots");
  });

  it("every account email's button opens an app route through the open link", () => {
    const routes = new Set([
      "/open",
      "/open/bots",
      "/open/settings/billing",
      "/open/settings/gallery",
    ]);
    for (const kind of [
      "trial_started",
      "trial_ending",
      "plan_started",
      "payment_failed",
      "cancel_scheduled",
      "expired",
      "refunded",
      "credits_low",
      "credits_out",
      "yearly_renewal",
      "welcome",
      "first_bot_nudge",
      "week_one_tips",
      "come_back",
      "gallery_digest",
    ] as const) {
      const c = accountEmailContent(kind, { plan: "Pro", items: [] }, appLink(cloud));
      const url = c.email.button?.url;
      expect(url, kind).toBeTruthy();
      if (!url) continue;
      const u = new URL(url);
      expect(u.origin, kind).toBe("https://casama.ai");
      expect(routes.has(u.pathname), `${kind}: ${u.pathname}`).toBe(true);
    }
  });

  it("invites read from a pasted casama.ai/open link", () => {
    expect(parseInvite("https://casama.ai/open/join/kjoin_abcdefghijklmnopqrstuv")).toEqual({
      kind: "link",
      token: "kjoin_abcdefghijklmnopqrstuv",
    });
    expect(parseInvite("https://casama.ai/open/join/7F3Q-9XWD")).toEqual({
      kind: "code",
      token: "7F3Q9XWD",
    });
  });
});
