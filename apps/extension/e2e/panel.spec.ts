/**
 * Phase 1's "done when" (plan §15): from the side panel, ask about a news article, a PDF and a
 * YouTube video with each one's context; watch the reply stream in with a card; save to the
 * Library; send a file; approve a bot's step from the Inbox.
 *
 * Fixture pages are served by Playwright on made-up addresses, and the run's event stream is
 * faked (the local stack may have no model). Everything else is the real server. The panel opens
 * as a tab, since Playwright can't click the toolbar button; it reads the tab used last.
 */
import type { Route } from "@playwright/test";
import {
  ARTICLE,
  CAPTIONS,
  endRunsAtOnce,
  lastUserMessage,
  openPanel,
  SITE,
  signIn,
  sse,
  tinyPdf,
  YOUTUBE_PAGE,
} from "./fixtures.ts";
import { API, expect, optionsPage, test } from "./harness.ts";

test("asks about a news article with its selection and text, and watches the reply stream in", async ({
  context,
  extensionId,
  account,
}) => {
  await signIn(context, extensionId, account);
  await context.route(`${SITE}/news`, (r) =>
    r.fulfill({ contentType: "text/html", body: ARTICLE }),
  );

  // The run's events: first the reply so far and a card, then (once the test has looked) the end.
  let release!: () => void;
  const released = new Promise<void>((r) => {
    release = r;
  });
  let calls = 0;
  await context.route(/\/v1\/runs\/[^/]+\/events/, async (route: Route) => {
    calls += 1;
    const runId = /\/v1\/runs\/([^/]+)\/events/.exec(route.request().url())![1]!;
    const base = { v: 1, run_id: runId, bot_id: account.botId, ts: new Date().toISOString() };
    if (calls === 1)
      return route.fulfill({
        contentType: "text/event-stream",
        body: sse([
          { ...base, seq: 1, type: "message.delta", payload: { text: "The valley had " } },
          { ...base, seq: 2, type: "message.delta", payload: { text: "**eleven dry weeks**." } },
          {
            ...base,
            seq: 3,
            type: "ui.shown",
            payload: {
              surface_id: "s-rain",
              messages: [
                { version: "1.0", createSurface: { surfaceId: "s-rain", catalogId: "basic" } },
                {
                  version: "1.0",
                  updateComponents: {
                    surfaceId: "s-rain",
                    components: [
                      { id: "root", component: "Column", children: ["t"] },
                      { id: "t", component: "Text", text: "Showers for two more days" },
                    ],
                  },
                },
              ],
            },
          },
        ]),
      });
    await released;
    return route.fulfill({
      contentType: "text/event-stream",
      body: sse([{ ...base, seq: 4, type: "run.completed", payload: {} }]),
    });
  });

  const news = await context.newPage();
  await news.goto(`${SITE}/news`);
  await news.evaluate(() => {
    const range = document.createRange();
    range.selectNodeContents(document.getElementById("lead")!);
    getSelection()!.addRange(range);
  });

  const panel = await openPanel(context, extensionId);
  // Before the person asks, the chips know only the tab's address and title.
  await expect(panel.getByTestId("chip-page")).toContainText("Rain returns to the valley");
  await expect(panel.getByTestId("chip-selection")).toHaveCount(0);
  await expect(panel.getByTestId("chip-text")).toHaveText("Page text");
  // Starting a message reads the page: the selection and the text's size appear.
  await panel.getByTestId("composer").click();
  await expect(panel.getByTestId("chip-selection")).toBeVisible();
  await expect(panel.getByTestId("chip-selection")).toHaveAttribute("aria-pressed", "true");
  // Page text is off by default (§10); switch it on for this one.
  await expect(panel.getByTestId("chip-text")).toHaveAttribute("aria-pressed", "false");
  await panel.getByTestId("chip-text").click();
  await panel.getByTestId("composer").fill("What happened?");
  await panel.getByTestId("send").click();

  const live = panel.getByTestId("live-reply");
  await expect(live).toContainText("The valley had eleven dry weeks.");
  await expect(live.locator("strong")).toHaveText("eleven dry weeks");
  await expect(live.getByTestId("ui-card")).toContainText("Showers for two more days");
  await expect(panel.getByTestId("stop")).toBeVisible();
  release();
  await expect(panel.getByTestId("send")).toBeVisible();

  // What went to the server: the typed question, then the context block.
  const stored = await lastUserMessage(account);
  expect(stored).toContain("What happened?");
  expect(stored).toContain(`Browser tab: Rain returns to the valley (${SITE}/news)`);
  expect(stored).toContain("Selected text:\\nAfter eleven dry weeks");
  expect(stored).toContain("Page text:");
  expect(stored).toContain("Forecasters expect two more days");
  expect(stored).not.toContain("The Valley Times");

  // The person's bubble shows only what they typed; "What was sent" lists the rest.
  const mine = panel.getByTestId("msg-user").last();
  await expect(mine.locator(".body")).toHaveText("What happened?");
  await mine.getByTestId("what-was-sent").locator("summary").click();
  await expect(mine.getByTestId("what-was-sent")).toContainText("Selected text");
});

test("reads a PDF's text and a YouTube video's transcript", async ({
  context,
  extensionId,
  account,
}) => {
  await signIn(context, extensionId, account);
  await endRunsAtOnce(context, account);
  const pdf = tinyPdf("Quarterly revenue rose nine percent", "Quarterly report");
  // The tab shows a page; the extension's own fetch of the address gets the PDF's bytes.
  await context.route(`${SITE}/report.pdf`, (r) =>
    r.request().resourceType() === "document"
      ? r.fulfill({ contentType: "text/html", body: "<title>report.pdf</title><p>PDF viewer</p>" })
      : r.fulfill({ contentType: "application/pdf", body: pdf }),
  );
  const doc = await context.newPage();
  await doc.goto(`${SITE}/report.pdf`);
  const panel = await openPanel(context, extensionId);
  await expect(panel.getByTestId("chip-text")).toContainText("PDF text");
  await panel.getByTestId("composer").click();
  await expect(panel.getByTestId("chip-page")).toContainText("Quarterly report");
  await panel.getByTestId("chip-text").click();
  await panel.getByTestId("composer").fill("Summarise this");
  await panel.getByTestId("send").click();
  await expect(panel.getByTestId("msg-user").last()).toContainText("Summarise this");
  const stored = await lastUserMessage(account);
  expect(stored).toContain("PDF text:");
  expect(stored).toContain("Quarterly revenue rose nine percent");
  await panel.close();
  await doc.close();

  await context.route("https://www.youtube.com/watch**", (r) =>
    r.fulfill({ contentType: "text/html", body: YOUTUBE_PAGE }),
  );
  await context.route("https://www.youtube.com/api/timedtext**", (r) =>
    r.fulfill({ contentType: "application/json", body: JSON.stringify(CAPTIONS) }),
  );
  const video = await context.newPage();
  await video.goto("https://www.youtube.com/watch?v=rain1");
  const panel2 = await openPanel(context, extensionId);
  await expect(panel2.getByTestId("chip-text")).toContainText("Transcript");
  await panel2.getByTestId("chip-text").click();
  await panel2.getByTestId("composer").fill("Key points?");
  await panel2.getByTestId("send").click();
  await expect(panel2.getByTestId("msg-user").last()).toContainText("Key points?");
  const said = await lastUserMessage(account);
  expect(said).toContain("Browser tab: How rain forms (https://www.youtube.com/watch?v=rain1)");
  expect(said).toContain("Video position: 1:15");
  expect(said).toContain("Video transcript:");
  expect(said).toContain("Water vapour rises and cools.");
});

test("saves the page to the Library and sends a file with a message", async ({
  context,
  extensionId,
  account,
}) => {
  await signIn(context, extensionId, account);
  await endRunsAtOnce(context, account);
  await context.route(`${SITE}/news`, (r) =>
    r.fulfill({ contentType: "text/html", body: ARTICLE }),
  );
  const news = await context.newPage();
  await news.goto(`${SITE}/news`);
  const panel = await openPanel(context, extensionId);

  await panel.getByTestId("tab-library").click();
  await panel.getByTestId("save-markdown").click();
  await expect(panel.getByTestId("creation").first()).toContainText("Rain returns to the valley");
  const creations = (await (await account.api(`/v1/creations?org_id=${account.orgId}`)).json()) as {
    items: { title: string; mime_type?: string }[];
  };
  expect(creations.items.some((c) => c.title.includes("Rain returns to the valley"))).toBe(true);

  // A file sent with a message is kept in the chat, not the Library.
  await panel.getByTestId("tab-chat").click();
  await panel.getByTestId("file-input").setInputFiles({
    name: "notes.txt",
    mimeType: "text/plain",
    buffer: Buffer.from("Bring umbrellas on Thursday."),
  });
  await expect(panel.getByTestId("attachment")).toContainText("notes.txt");
  await panel.getByTestId("composer").fill("Read my notes");
  await panel.getByTestId("send").click();
  await expect(panel.getByTestId("msg-user").last()).toContainText("Read my notes");
  const stored = JSON.parse(await lastUserMessage(account)) as {
    type: string;
    path?: string;
    uploaded?: boolean;
  }[];
  const file = stored.find((p) => p.type === "file")!;
  expect(file.path).toMatch(/^media:[0-9a-f-]{36}$/);
  expect(file.uploaded).toBe(true);
  const after = (await (await account.api(`/v1/creations?org_id=${account.orgId}`)).json()) as {
    items: { title: string }[];
  };
  expect(after.items.some((c) => c.title.includes("notes"))).toBe(false);
});

test("approves a bot's step from the Inbox", async ({ context, extensionId, account }) => {
  await signIn(context, extensionId, account);
  const [run] = await account.rest<{ id: string }[]>("/runs", {
    method: "POST",
    body: JSON.stringify({
      org_id: account.orgId,
      bot_id: account.botId,
      status: "waiting_approval",
    }),
  });
  const [approval] = await account.rest<{ id: string }[]>("/approvals", {
    method: "POST",
    body: JSON.stringify({
      org_id: account.orgId,
      bot_id: account.botId,
      run_id: run!.id,
      call_id: "call-1",
      tool_name: "email.send",
      summary: "Send the weekly update to the team",
      risk: "medium",
    }),
  });
  const panel = await openPanel(context, extensionId);
  await panel.getByTestId("tab-inbox").click();
  const item = panel.getByTestId("approval").filter({ hasText: "Send the weekly update" });
  await expect(item).toBeVisible();
  await item.getByTestId("approve").click();
  await expect(panel.getByTestId("approval")).toHaveText("Approved");
  await expect
    .poll(async () => {
      const [row] = await account.rest<{ status: string }[]>(
        `/approvals?id=eq.${approval!.id}&select=status`,
      );
      return row!.status;
    })
    .toBe("approved");
});

test("the panel sends people to Settings before setup and when signed out", async ({
  context,
  extensionId,
}) => {
  const panel = await context.newPage();
  await panel.goto(`chrome-extension://${extensionId}/panel/panel.html`);
  await expect(panel.getByTestId("finish-setup")).toBeVisible();
  const options = await optionsPage(context, extensionId);
  await options.getByTestId("agree").click();
  await expect(panel.getByTestId("sign-in")).toBeVisible();
});

test("sends nothing from Casama's own pages or a page with a password field", async ({
  context,
  extensionId,
  account,
}) => {
  await signIn(context, extensionId, account);
  await endRunsAtOnce(context, account);
  // The signed-in server's own address counts as Casama's, from the address alone.
  const own = await context.newPage();
  await own.goto(`${API}/readyz`);
  const panel = await openPanel(context, extensionId);
  await expect(panel.getByTestId("blocked")).toContainText("Casama's own pages");
  await expect(panel.getByTestId("chip-page")).toHaveCount(0);
  await panel.getByTestId("composer").fill("Just a question");
  await panel.getByTestId("send").click();
  await expect(panel.getByTestId("msg-user").last()).toContainText("Just a question");
  expect(await lastUserMessage(account)).not.toContain("Browser tab:");
  await panel.close();
  await own.close();

  await context.route(`${SITE}/login`, (r) =>
    r.fulfill({
      contentType: "text/html",
      body: '<meta charset="utf-8"><title>Sign in</title><p>Welcome back</p><input type="password">',
    }),
  );
  const login = await context.newPage();
  await login.goto(`${SITE}/login`);
  const panel2 = await openPanel(context, extensionId);
  await panel2.getByTestId("composer").click();
  await expect(panel2.getByTestId("blocked")).toContainText("password or card field");
  await panel2.getByTestId("tab-library").click();
  await panel2.getByTestId("save-screenshot").click();
  await expect(panel2.getByTestId("toast")).toContainText("password or card field");
});
