/**
 * Phase 2's "done when" (plan §15): with site access on, the selection bar and "write in any text
 * box" work on Gmail and three ordinary sites; each site helper survives a changed page by hiding;
 * a watcher is made by pointing at a price; on-device quick answers work with the network off.
 * Plus the "/" and "@" menus, this page before, highlights, read it later, today's brief and a live
 * call. (The watcher firing on a changed test page is a server test: chrome-phase2.test.ts.)
 *
 * Fixture pages (including a fake Gmail) are served by Playwright on their real-looking addresses;
 * run events and Gemini Live are faked. Everything else is the real local server.
 */
import type { BrowserContext, Page, Worker } from "@playwright/test";
import {
  ARTICLE,
  endRunsAtOnce,
  lastUserMessage,
  openPanel,
  SITE,
  signIn,
  sse,
} from "./fixtures.ts";
import { expect, type TestAccount, test } from "./harness.ts";

const GMAIL = "https://mail.google.com/mail/u/0/";
const GMAIL_PAGE = `<!doctype html><html><head><meta charset="utf-8"><title>Inbox - Gmail</title></head><body>
<h2 class="hP">Lunch on Tuesday?</h2>
<div class="a3s"><p id="lead">Hi! Are you free for lunch on Tuesday at noon near the office?</p></div>
<div role="textbox" contenteditable="true" aria-label="Message Body" style="width:500px;height:120px;border:1px solid #ccc"></div>
</body></html>`;
const ORDINARY = [
  { url: `${SITE}/blog`, title: "A blog" },
  { url: "https://docs.example.org/guide", title: "A guide" },
  { url: "https://forum.example.net/t/42", title: "A forum" },
];
const ordinaryPage = (
  title: string,
) => `<!doctype html><html lang="en"><head><meta charset="utf-8"><title>${title}</title></head><body>
<h1>${title}</h1><p id="lead">Kettles boil water faster when they are descaled every month with vinegar.</p>
<textarea id="box" style="width:400px;height:100px"></textarea></body></html>`;

const KETTLE = `<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Blue kettle</title>
<script type="application/ld+json">{"@context":"https://schema.org","@type":"Product","name":"Blue kettle"}</script></head><body>
<h1>Blue kettle</h1><p>A kettle that boils fast.</p><div id="price" style="font-size:24px;padding:8px">Price: $40.00 per kettle</div>
<p>Free delivery on orders over $50.</p></body></html>`;

async function serve(context: BrowserContext) {
  await context.route(`${GMAIL}**`, (r) =>
    r.fulfill({ contentType: "text/html", body: GMAIL_PAGE }),
  );
  for (const o of ORDINARY)
    await context.route(o.url, (r) =>
      r.fulfill({ contentType: "text/html", body: ordinaryPage(o.title) }),
    );
  await context.route(`${SITE}/news`, (r) =>
    r.fulfill({ contentType: "text/html", body: ARTICLE }),
  );
  await context.route(`${SITE}/kettle`, (r) =>
    r.fulfill({ contentType: "text/html", body: KETTLE }),
  );
}

/** Signs in and switches the selection bar and the write button on, then waits for the kit. */
async function setUp(
  context: BrowserContext,
  extensionId: string,
  account: TestAccount,
  worker: Worker,
) {
  const options = await signIn(context, extensionId, account);
  await options.getByTestId("opt-selection-bar").check();
  await options.getByTestId("opt-write-box").check();
  await expect
    .poll(() =>
      worker.evaluate(async () =>
        (await chrome.scripting.getRegisteredContentScripts()).map((s) =>
          [...(s.matches ?? [])].sort(),
        ),
      ),
    )
    .toEqual([["http://*/*", "https://*/*"]]);
  await serve(context);
  // Playwright can't reach Chrome's side panel (nor mock its network), so it's off here and kit
  // buttons open the panel as a tab instead, as they do wherever the side panel can't open.
  await worker.evaluate(() => chrome.sidePanel.setOptions({ enabled: false }));
  return options;
}

/**
 * Selects text the way a person would and waits for the selection bar. The kit starts once the page
 * is idle and the service worker has answered, and only puts itself on the page when there's
 * something to show, so this tries again until it does.
 */
async function select(page: Page, sel = "#lead") {
  await expect
    .poll(async () => {
      await page.evaluate((s) => {
        const range = document.createRange();
        range.selectNodeContents(document.querySelector(s)!);
        getSelection()!.removeAllRanges();
        getSelection()!.addRange(range);
        document.dispatchEvent(new MouseEvent("mouseup", { bubbles: true }));
      }, sel);
      return page.getByTestId("selection-bar").count();
    })
    .toBe(1);
}

/** Clicks into a text box until the kit's write button shows beside it. */
async function focusBox(page: Page, sel: string) {
  await expect
    .poll(async () => {
      await page.locator("body").click({ position: { x: 5, y: 5 } });
      await page.locator(sel).click();
      return page.getByTestId("write-button").count();
    })
    .toBe(1);
}

/** The panel a kit button opened, as a tab (see setUp). */
async function viaPanel(context: BrowserContext, extensionId: string, action: () => Promise<void>) {
  const opened = context.waitForEvent("page", {
    predicate: (p) => p.url().startsWith(`chrome-extension://${extensionId}/panel/`),
    timeout: 15_000,
  });
  await action();
  const panel = await opened;
  await expect(panel.getByTestId("chat")).toBeVisible();
  return panel;
}

test("the selection bar and the write button work on Gmail and three ordinary sites", async ({
  context,
  extensionId,
  account,
  worker,
}) => {
  test.setTimeout(150_000);
  await setUp(context, extensionId, account, worker);
  await endRunsAtOnce(context, account);

  // Every site: the bar shows beside a selection, the write button in a text box.
  for (const url of [GMAIL, ...ORDINARY.map((o) => o.url)]) {
    const page = await context.newPage();
    await page.goto(url);
    await select(page);
    await expect(page.getByTestId("selection-bar")).toBeVisible();
    await expect(page.getByTestId("sb-explain")).toBeVisible();
    await page.keyboard.press("Escape");
    await expect(page.getByTestId("selection-bar")).toHaveCount(0);
    await focusBox(page, url === GMAIL ? "[role=textbox]" : "#box");
    await expect(page.getByTestId("write-button")).toBeVisible();
    await page.close();
  }

  // An ordinary site: Explain sends the selection to the bot.
  const blog = await context.newPage();
  await blog.goto(ORDINARY[0]!.url);
  await select(blog);
  await viaPanel(context, extensionId, () => blog.getByTestId("sb-explain").click());
  await expect.poll(() => lastUserMessage(account).catch(() => "")).toContain("Explain this.");
  expect(await lastUserMessage(account)).toContain("descaled every month with vinegar");
  await blog.close();
});

test("write in a text box: the bot's draft goes into Gmail's reply box for you to send", async ({
  context,
  extensionId,
  account,
  worker,
}) => {
  await setUp(context, extensionId, account, worker);
  const DRAFT = "Tuesday at noon works for me. See you then!";
  await context.route(/\/v1\/runs\/[^/]+\/events/, (route) => {
    const runId = /\/v1\/runs\/([^/]+)\/events/.exec(route.request().url())![1]!;
    const base = { v: 1, run_id: runId, bot_id: account.botId, ts: new Date().toISOString() };
    return route.fulfill({
      contentType: "text/event-stream",
      body: sse([
        { ...base, seq: 1, type: "message.delta", payload: { text: DRAFT } },
        { ...base, seq: 2, type: "run.completed", payload: {} },
      ]),
    });
  });
  const gmail = await context.newPage();
  await gmail.goto(GMAIL);
  await focusBox(gmail, "[role=textbox]");
  await gmail.getByTestId("write-button").click();
  const panel = await viaPanel(context, extensionId, () =>
    gmail.getByTestId("write-reply").click(),
  );
  await expect.poll(() => lastUserMessage(account).catch(() => "")).toContain("Write my reply");
  // The thread went with it, so the bot can answer it.
  expect(await lastUserMessage(account)).toContain("free for lunch on Tuesday");
  // Nothing goes into the page until the person says so.
  await expect(gmail.locator("[role=textbox]")).toHaveText("");
  await panel.getByTestId("insert-reply").click();
  await expect(gmail.locator("[role=textbox]")).toHaveText(DRAFT);
});

test("site helpers show on their pages and hide when the page changes under them", async ({
  context,
  extensionId,
  account,
  worker,
}) => {
  await signIn(context, extensionId, account);
  await serve(context);
  await context.route("https://www.youtube.com/watch**", (r) =>
    r.fulfill({
      contentType: "text/html",
      body: `<!doctype html><html><head><meta charset="utf-8"><title>How rain forms - YouTube</title></head><body><div id="above-the-fold"><h1 id="title">How rain forms</h1></div></body></html>`,
    }),
  );
  await context.route("https://github.com/acme/app/pull/7", (r) =>
    r.fulfill({
      contentType: "text/html",
      // A redesigned page: none of the elements the helper knows.
      body: `<!doctype html><html><head><meta charset="utf-8"><title>Fix the kettle · Pull Request #7</title></head><body><main><h1 class="new-title">Fix the kettle</h1></main></body></html>`,
    }),
  );
  await expect
    .poll(() =>
      worker.evaluate(async () => (await chrome.scripting.getRegisteredContentScripts()).length),
    )
    .toBe(1);

  const yt = await context.newPage();
  await yt.goto("https://www.youtube.com/watch?v=rain1");
  await expect(yt.getByTestId("helper-youtube")).toBeVisible();
  await expect(yt.getByTestId("helper-action")).toHaveText(["Summarize the video", "Chapters"]);
  // The site changes its page: the helper hides instead of misbehaving, and says so (no page data).
  await yt.evaluate(() => document.getElementById("above-the-fold")!.remove());
  await expect(yt.getByTestId("helper-youtube")).toHaveCount(0);

  const gh = await context.newPage();
  await gh.goto("https://github.com/acme/app/pull/7");
  await gh.waitForTimeout(800);
  await expect(gh.getByTestId("helper-github")).toHaveCount(0);
  await expect
    .poll(() =>
      worker.evaluate(async () => (await chrome.storage.session.get("helperMisses")).helperMisses),
    )
    .toEqual({ youtube: 1, github: 1 });

  // The shopping helper finds a product page by its structured data.
  const shop = await context.newPage();
  await shop.goto(`${SITE}/kettle`);
  await expect(shop.getByTestId("helper-shopping")).toBeVisible();
});

test("watch this page: pointing at the price makes a server watcher on that part", async ({
  context,
  extensionId,
  account,
}) => {
  await signIn(context, extensionId, account);
  await serve(context);
  const shop = await context.newPage();
  await shop.goto(`${SITE}/kettle`);
  const panel = await openPanel(context, extensionId);
  await panel.getByTestId("tab-more").click();
  await panel.getByTestId("watch-page").click();
  // The picker is in the shop's tab: hover, then click the price.
  await shop.bringToFront();
  await expect(shop.locator("[data-casama-picker]")).toHaveCount(1);
  await shop.hover("#price");
  await shop.click("#price");
  await expect(panel.getByTestId("toast")).toContainText("Watching it");
  const r = (await (await account.api(`/v1/watchers?bot_id=${account.botId}`)).json()) as {
    items: { kind: string; target: { url: string; anchor: string; chars: number } }[];
  };
  expect(r.items).toHaveLength(1);
  expect(r.items[0]).toMatchObject({ kind: "page_change", target: { url: `${SITE}/kettle` } });
  // The anchor is the steady text just before the price (the price itself is what changes), and
  // the part compared runs from there through the price.
  const { anchor, chars } = r.items[0]!.target;
  expect(anchor).toContain("boils fast");
  expect(anchor).not.toContain("$40");
  expect(chars).toBeGreaterThan(anchor.length + "Price: $40.00".length);
  expect(chars).toBeLessThan(100);
});

test("/ runs a page command, @ adds another tab, and the page remembers its chats", async ({
  context,
  extensionId,
  account,
}) => {
  const options = await signIn(context, extensionId, account);
  await serve(context);
  await endRunsAtOnce(context, account);
  await options.getByTestId("command-name").fill("tldr");
  await options
    .getByTestId("command-prompt")
    .fill("Summarize this page in three bullets for my team.");
  await options.getByTestId("add-command").click();
  await expect(options.getByTestId("page-command")).toHaveCount(1);

  const other = await context.newPage();
  await other.goto(ORDINARY[1]!.url);
  const news = await context.newPage();
  await news.goto(`${SITE}/news`);
  const panel = await openPanel(context, extensionId);
  const composer = panel.getByTestId("composer");
  await composer.click();
  await composer.pressSequentially("/tl");
  await expect(panel.getByTestId("menu-command")).toHaveText(/\/tldr/);
  await composer.press("Enter");
  await expect(composer).toHaveValue("Summarize this page in three bullets for my team.");

  await composer.pressSequentially(" @gui");
  await panel.getByTestId("menu-tab").filter({ hasText: "A guide" }).click();
  await expect(panel.getByTestId("extra-tab")).toContainText("A guide");
  await expect(composer).toHaveValue("Summarize this page in three bullets for my team.");
  await panel.getByTestId("send").click();
  await expect.poll(() => lastUserMessage(account).catch(() => "")).toContain("Other tab: A guide");
  expect(await lastUserMessage(account)).toContain("Browser tab: Rain returns to the valley");

  // A20: back on the article, the panel knows its chats without asking the server; Show asks.
  await panel.close();
  await news.reload();
  const again = await openPanel(context, extensionId);
  await expect(again.getByTestId("page-before")).toContainText("This page before: 1 chat");
  await again.getByTestId("page-before-show").click();
  await expect(again.getByTestId("history-chat")).toHaveCount(1);
});

test("highlights stay on the page and come back on the next visit; read it later queues a ticket", async ({
  context,
  extensionId,
  account,
  worker,
}) => {
  await setUp(context, extensionId, account, worker);
  const page = await context.newPage();
  await page.goto(ORDINARY[2]!.url);
  await select(page);
  await page.getByTestId("sb-highlight").click();
  await expect(page.getByTestId("kit-note")).toContainText("Highlighted");
  await expect(page.locator("casama-kit")).toHaveAttribute("data-highlights", "1");
  await page.reload();
  await expect(page.locator("casama-kit")).toHaveAttribute("data-highlights", "1");
  const hl = (await (await account.api(`/v1/me/highlights?org_id=${account.orgId}`)).json()) as {
    items: { text: string; url_key: string }[];
  };
  expect(hl.items[0]).toMatchObject({ url_key: ORDINARY[2]!.url });
  expect(hl.items[0]!.text).toContain("descaled every month");

  const panel = await openPanel(context, extensionId);
  await panel.getByTestId("tab-more").click();
  await panel.getByTestId("read-later").click();
  await expect(panel.getByTestId("toast")).toContainText("next brief");
  const tasks = (await (await account.api(`/v1/tasks?org_id=${account.orgId}`)).json()) as {
    items: { title: string; labels: string[] }[];
  };
  expect(tasks.items.find((t) => t.labels.includes("read-for-me"))?.title).toBe("A forum");
});

test("quick answers on this computer work with the network off", async ({
  context,
  extensionId,
  account,
}) => {
  await signIn(context, extensionId, account);
  await serve(context);
  // Chrome's built-in model, faked: present and downloaded.
  await context.addInitScript(() => {
    (globalThis as Record<string, unknown>).LanguageModel = {
      availability: async () => "available",
      create: async () => ({
        prompt: async () => "- Rain is back after eleven dry weeks.",
        destroy() {},
      }),
    };
  });
  const news = await context.newPage();
  await news.goto(`${SITE}/news`);
  // A selection on the page (the selection bar is off here; the panel reads it when asked).
  await news.evaluate(() => {
    const range = document.createRange();
    range.selectNodeContents(document.querySelector("p")!);
    getSelection()!.removeAllRanges();
    getSelection()!.addRange(range);
  });
  const panel = await openPanel(context, extensionId);
  await panel.getByTestId("composer").click();
  await expect(panel.getByTestId("quick-summarize")).toBeVisible();
  await context.setOffline(true);
  await panel.getByTestId("quick-summarize").click();
  await expect(panel.getByTestId("quick-answer")).toContainText(
    "Rain is back after eleven dry weeks.",
  );
  await expect(panel.getByTestId("quick-answer")).toContainText("Nothing was sent.");
  await context.setOffline(false);
});

test("today's brief shows in the Inbox", async ({ context, extensionId, account }) => {
  await signIn(context, extensionId, account);
  await context.route(/\/v1\/for-you\?/, (r) =>
    r.fulfill({
      contentType: "application/json",
      body: JSON.stringify({
        briefs: [
          {
            bot_id: account.botId,
            conversation_id: crypto.randomUUID(),
            text: "Two meetings today; **lunch with Sam** at noon.",
            created_at: new Date().toISOString(),
          },
        ],
        suggestions: [],
        approvals: [],
      }),
    }),
  );
  const panel = await openPanel(context, extensionId);
  await panel.getByTestId("tab-inbox").click();
  await expect(panel.getByTestId("brief")).toContainText("Two meetings today");
  await expect(panel.getByTestId("brief").locator("strong")).toHaveText("lunch with Sam");
});

test("a live call in the panel: connects, shows what was said, and saves it", async ({
  context,
  extensionId,
  account,
}) => {
  await signIn(context, extensionId, account);
  const conversation = crypto.randomUUID();
  await context.route(/\/v1\/voice\/session$/, (r) =>
    r.fulfill({
      contentType: "application/json",
      body: JSON.stringify({
        provider: "gemini",
        model: "gemini-live",
        client_secret: "tok",
        expires_at: new Date(Date.now() + 60_000).toISOString(),
        connect_url: "wss://live.example.test/ws",
        setup: { model: "models/gemini-live" },
        conversation_id: conversation,
        tools: 0,
        speak_first: false,
      }),
    }),
  );
  let saved: { turns: { role: string; text: string }[] } | null = null;
  await context.route(/\/v1\/voice\/transcript$/, async (r) => {
    saved = r.request().postDataJSON();
    await r.fulfill({ contentType: "application/json", body: JSON.stringify({ message_ids: [] }) });
  });
  const got: string[] = [];
  await context.routeWebSocket(/wss:\/\/live\.example\.test\/ws/, (ws) => {
    ws.onMessage((m) => {
      const msg = JSON.parse(String(m));
      got.push(Object.keys(msg)[0]!);
      if (msg.setup) {
        ws.send(JSON.stringify({ setupComplete: {} }));
        ws.send(
          JSON.stringify({ serverContent: { inputTranscription: { text: "Is it raining?" } } }),
        );
        ws.send(
          JSON.stringify({
            serverContent: {
              outputTranscription: { text: "Yes, for two more days." },
              turnComplete: true,
            },
          }),
        );
      }
    });
  });
  const panel = await openPanel(context, extensionId);
  await panel.getByTestId("call").click();
  await expect(panel.getByTestId("call-state")).toContainText("On a call");
  await expect(panel.getByTestId("call-turn")).toHaveText([
    "You: Is it raining?",
    /Yes, for two more days\./,
  ]);
  await panel.getByTestId("hang-up").click();
  await expect(panel.getByTestId("call-state")).toContainText("Call ended");
  await expect.poll(() => saved?.turns.length ?? 0).toBe(2);
  expect(got[0]).toBe("setup");
});
