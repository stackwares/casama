import { beforeEach, describe, expect, it } from "vitest";
import { intentFor } from "../src/background/menus.ts";
import { approvalIdOf, onPush, SHOWN_KINDS } from "../src/lib/alerts.ts";
import { setIntent, takeIntent } from "../src/lib/intent.ts";
import { cleanHost, getSettings, originsFor, updateSettings } from "../src/lib/settings.ts";
import { installFakeChrome } from "./fake-chrome.ts";

beforeEach(() => {
  installFakeChrome();
});

describe("settings (G1–G3)", () => {
  it("start with page and selection on, page text off, nothing chosen yet", async () => {
    const s = await getSettings();
    expect(s.chips).toEqual({ page: true, selection: true, text: false, screenshot: false });
    expect(s.siteAccessChosen).toBe(false);
    await updateSettings((x) => {
      x.chips.text = true;
    });
    expect((await getSettings()).chips.text).toBe(true);
    expect(
      (globalThis as unknown as { chrome: { storage: { sync: unknown } } }).chrome,
    ).toBeTruthy();
  });

  it("clean hosts and map access modes to permissions", () => {
    expect(cleanHost("https://Mail.Example.com/inbox")).toBe("mail.example.com");
    expect(cleanHost("www.example.org")).toBe("example.org");
    expect(cleanHost("not a host")).toBeNull();
    expect(originsFor("all", [])).toEqual(["https://*/*", "http://*/*"]);
    expect(originsFor("sites", ["example.com"])).toEqual([
      "https://example.com/*",
      "https://*.example.com/*",
    ]);
    expect(originsFor("click", ["example.com"])).toEqual([]);
  });
});

describe("the right-click menu and intents (A7)", () => {
  it("turns menu items into what the panel does", () => {
    expect(intentFor({ menuItemId: "summarize", selectionText: "abc" } as never, 3)).toEqual({
      text: "Summarize this.",
      send: true,
      selection: "abc",
      tabId: 3,
    });
    expect(
      intentFor({ menuItemId: "remember", selectionText: "I like tea" } as never),
    ).toMatchObject({ action: "remember" });
    expect(
      intentFor({ menuItemId: "save-image", srcUrl: "https://x/y.png" } as never),
    ).toMatchObject({ action: "save-image", imageUrl: "https://x/y.png" });
    expect(intentFor({ menuItemId: "unknown" } as never)).toBeNull();
  });

  it("uses the server owner's wording for a ready-made prompt, its own otherwise (D-372)", () => {
    const config = {
      min_versions: {},
      update_urls: {},
      maintenance: null,
      announcements: [],
      flags: {},
      prompts: { "selection.explain": "Explain this like I'm new to it." },
    };
    expect(intentFor({ menuItemId: "explain" } as never, 1, config)?.text).toBe(
      "Explain this like I'm new to it.",
    );
    expect(intentFor({ menuItemId: "summarize" } as never, 1, config)?.text).toBe(
      "Summarize this.",
    );
    expect(intentFor({ menuItemId: "explain" } as never, 1, null)?.text).toBe("Explain this.");
  });

  it("hands an intent over once, and not when it's stale", async () => {
    await setIntent({ text: "hi" });
    expect((await takeIntent())?.text).toBe("hi");
    expect(await takeIntent()).toBeNull();
    await chrome.storage.session.set({ intent: { text: "old", at: Date.now() - 120_000 } });
    expect(await takeIntent()).toBeNull();
  });
});

describe("notifications (D3)", () => {
  it("find the approval in a push's link and show only needs-you and done", () => {
    expect(approvalIdOf("/approvals/7d0a6c61-3b7e-4b39-a0c8-4ac1b8b1e0aa")).toBe(
      "7d0a6c61-3b7e-4b39-a0c8-4ac1b8b1e0aa",
    );
    expect(approvalIdOf("/bots/x/chat")).toBeUndefined();
    expect(SHOWN_KINDS.has("approval_request")).toBe(true);
    expect(SHOWN_KINDS.has("reply")).toBe(true);
    expect(SHOWN_KINDS.has("member_joined")).toBe(false);
  });

  it("show a push under the account it names, not the active one", async () => {
    const created: { id: string }[] = [];
    const c = globalThis.chrome as unknown as Record<string, unknown>;
    c.notifications = { create: async (id: string) => void created.push({ id }) };
    c.action = { setBadgeText: async () => {}, setBadgeBackgroundColor: async () => {} };
    const account = (id: string, userId: string) => ({
      id,
      server: "https://api.example.test",
      authUrl: "https://auth.example.test",
      anonKey: "anon",
      userId,
      email: `${userId}@example.test`,
      refreshToken: "r",
      addedAt: "2026-11-16T00:00:00Z",
    });
    await chrome.storage.local.set({
      accounts: [account("a", "user-a"), account("b", "user-b")],
      activeAccountId: "a",
    });
    const link = "/approvals/7d0a6c61-3b7e-4b39-a0c8-4ac1b8b1e0aa";
    await onPush({
      kind: "approval_request",
      title: "Approve?",
      body: "Send it",
      link,
      user_id: "user-b",
    });
    const shown = await chrome.storage.session.get(null);
    expect(Object.values(shown)).toEqual([expect.objectContaining({ accountId: "b" })]);
    // A push for an account that isn't here any more shows nothing.
    await onPush({ kind: "approval_request", title: "Approve?", body: "x", link, user_id: "gone" });
    expect(created).toHaveLength(1);
  });
});
