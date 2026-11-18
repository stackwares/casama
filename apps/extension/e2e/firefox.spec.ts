/**
 * Phase 5's Firefox build (plan §13): Ask, Capture and Stay in the loop, without Act. In
 * Playwright's Firefox, against the real local server (e2e/firefox.ts says how):
 *
 * - The add-on installs with Firefox's manifest: a background script, the sidebar, no side panel,
 *   none of Act's permissions.
 * - The first run and sign-in by link work; there's no "Use the web app" route (Firefox has no
 *   externally_connectable).
 * - The panel (Firefox's sidebar page) lists the bot and sends a message the server keeps.
 * - Act, the browser as a device, recording, meeting notes and the page helpers are nowhere to be
 *   seen, and the whole background script ran (the account is on the minute check).
 *
 * Needs `vite build --mode firefox-e2e` (pnpm e2e builds it) and Playwright's Firefox.
 */
import { firefoxBuilt, IN_ADDON, launchFirefoxWithCasama } from "./firefox.ts";
import { expect, test } from "./harness.ts";

test.skip(!firefoxBuilt(), "No Firefox build: run vite build --mode firefox-e2e");

test("Casama for Firefox signs in, chats from its sidebar page, and offers no Act", async ({
  account,
}) => {
  test.setTimeout(150_000);
  const { addon, close } = await launchFirefoxWithCasama();
  try {
    const shape = await addon.run<{
      sidePanel: string;
      sidebar: string;
      permissions: string[];
      background: unknown;
    }>(`
      const m = chrome.runtime.getManifest();
      return {
        sidePanel: typeof chrome.sidePanel,
        sidebar: typeof browser.sidebarAction,
        permissions: m.permissions,
        background: m.background,
      };
    `);
    expect(shape.sidePanel).toBe("undefined");
    expect(shape.sidebar).toBe("object");
    expect(shape.background).toMatchObject({ type: "module", service_worker: null });
    expect((shape.background as { scripts: string[] }).scripts[0]).toMatch(/\/background\.js$/);
    for (const p of ["debugger", "tabGroups", "tabCapture", "sidePanel", "gcm", "offscreen"])
      expect(shape.permissions).not.toContain(p);

    // First run: the agreement, site access on click (no prompt), then sign in by link.
    const link = await account.signInLink();
    const signedIn = await addon.run<{ webapp: boolean; limitedUse: boolean; title: string }>(
      `
      ${IN_ADDON}
      let doc = await page("options/options.html");
      await text(doc, "Welcome to Casama for Firefox");
      const limitedUse = doc.body.innerText.includes("Chrome Web Store User Data Policy");
      (await el(doc, "agree")).click();
      (await el(doc, "access-click")).click();
      (await el(doc, "save-access")).click();
      await until("the sign-in screen", () => none(doc, "first-run-access") && doc.querySelector('[data-testid="link-input"]'));
      const webapp = !none(doc, "route-webapp");
      fill(await el(doc, "link-input"), ${JSON.stringify(link)});
      (await el(doc, "link-submit")).click();
      await text(doc, "You're signed in", 30000);
      return { webapp, limitedUse, title: doc.title };
    `,
      60_000,
    );
    expect(signedIn.webapp).toBe(false);
    expect(signedIn.limitedUse).toBe(false);
    expect(signedIn.title).toBe("Casama for Firefox");

    // Settings: bookmarks without the reading list; no page helpers, Act sites, device kinds or
    // captions.
    const settings = await addon.run<Record<string, boolean>>(`
      ${IN_ADDON}
      const doc = await page("options/options.html");
      await el(doc, "bookmarks-card");
      return {
        device: !none(doc, "device-card"),
        act: !none(doc, "act-sites"),
        captions: !none(doc, "captions-card"),
        onPages: !none(doc, "on-pages"),
        reading: !none(doc, "bookmarks-reading"),
        accounts: (await chrome.storage.local.get("accounts")).accounts.length === 1,
      };
    `);
    expect(settings).toEqual({
      device: false,
      act: false,
      captions: false,
      onPages: false,
      reading: false,
      accounts: true,
    });

    // The sidebar's page: the bot, no Record button, and a message that reaches the server.
    const panel = await addon.run<{ bot: boolean; record: boolean; yours: boolean }>(`
      ${IN_ADDON}
      const doc = await page("panel/panel.html");
      await el(doc, "chat");
      await text(doc, ${JSON.stringify(account.botName)});
      const record = !none(doc, "record-tab");
      fill(await el(doc, "composer"), "Hello from Firefox");
      (await el(doc, "send")).click();
      await sleep(1500);
      (await el(doc, "tab-more")).click();
      await el(doc, "open-settings");
      await sleep(500);
      const yours = [...doc.querySelectorAll(".section-title")].some((t) => t.textContent === "Your browser");
      return { bot: true, record, yours };
    `);
    expect(panel).toEqual({ bot: true, record: false, yours: false });

    await expect
      .poll(
        async () => {
          const convs = (await (
            await account.api(`/v1/bots/${account.botId}/conversations`)
          ).json()) as { items: { id: string }[] };
          if (!convs.items.length) return "";
          const thread = (await (
            await account.api(`/v1/conversations/${convs.items[0]!.id}/thread?limit=10`)
          ).json()) as { items: { role: string; content: unknown }[] };
          return JSON.stringify(thread.items.filter((m) => m.role === "user"));
        },
        { timeout: 30_000 },
      )
      .toContain("Hello from Firefox");

    // The whole background ran: the sign-in reached storage.onChanged, which registered for
    // pushes, found none in Firefox, and put the account on the once-a-minute check.
    const polled = await addon.run<boolean>(`
      ${IN_ADDON}
      const { accounts } = await chrome.storage.local.get("accounts");
      return until("the account on the minute check", async () =>
        ((await chrome.storage.session.get("polled")).polled ?? []).includes(accounts[0].id));
    `);
    expect(polled).toBe(true);

    // Act never started: none of its alarms.
    const alarms = await addon.run<string[]>(
      "return (await chrome.alarms.getAll()).map((a) => a.name);",
    );
    expect(alarms).toContain("tick");
    expect(alarms.filter((a) => a.startsWith("act"))).toEqual([]);
  } finally {
    await close();
  }
});
