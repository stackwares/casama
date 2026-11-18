/**
 * Phase 4's "done when" (plan §15), the extension's side, against the real local server:
 *
 * - The browser as a device: switched on in Settings, it answers a request for the tab in front
 *   (the desktop app's quick ask, E3) over Realtime, with the fixture page's address and title
 *   and nothing else.
 * - Triggers: "when I open the team wiki" starts its routine when the wiki opens; other sites
 *   send nothing.
 * - The live view and meeting notes stay out of the way when there's nothing to show.
 *
 * The bot side ("what's on my screen" from Telegram) is apps/server/test/chrome-phase4.test.ts.
 */
import { ARTICLE, openPanel, SITE, signIn } from "./fixtures.ts";
import { expect, storage, test } from "./harness.ts";

const WIKI = "https://wiki.example.com";

test("the browser answers a request for the tab in front, and starts a routine from a site", async ({
  context,
  extensionId,
  worker,
  account,
}) => {
  test.setTimeout(120_000);
  await context.route(`${SITE}/**`, (r) => r.fulfill({ contentType: "text/html", body: ARTICLE }));
  await context.route(`${WIKI}/**`, (r) =>
    r.fulfill({
      contentType: "text/html",
      body: "<!doctype html><html><head><title>Team wiki</title></head><body><h1>Wiki</h1></body></html>",
    }),
  );
  await context.route("https://news.example.org/**", (r) =>
    r.fulfill({ contentType: "text/html", body: "<title>News</title><h1>News</h1>" }),
  );
  const options = await signIn(context, extensionId, account);
  await options.reload();
  await expect(options.getByTestId("device-card")).toBeVisible();

  // E2/E3: share the tab in front. The e2e build has the optional permissions already.
  await options.getByTestId("device-tab").check();
  await expect
    .poll(async () => (await storage(worker)).session.deviceListening, { timeout: 20_000 })
    .toBe(true);
  const dev = (await storage(worker)).local.browserDevice as { sourceId: string; tab: boolean };
  expect(dev.tab).toBe(true);
  expect(dev.sourceId).toBeTruthy();

  const article = await context.newPage();
  await article.goto(`${SITE}/rain`);
  await article.bringToFront();
  const res = await account.api("/v1/device-requests", {
    method: "POST",
    body: JSON.stringify({ kind: "browser_tab" }),
  });
  expect(res.status).toBe(200);
  const answer = (await res.json()) as {
    device: string;
    result: { url: string; title: string; text?: string };
  };
  expect(answer.result.url).toBe(`${SITE}/rain`);
  expect(answer.result.title).toBe("Rain returns to the valley");
  // Quick ask asks for the address and title only (brief), so the page's text stays home.
  expect(answer.result.text).toBeUndefined();

  // E4: a routine that starts when the team wiki opens.
  const made = await account.api("/v1/routines", {
    method: "POST",
    body: JSON.stringify({
      bot_id: account.botId,
      name: "When I open the wiki",
      instructions: "Summarize what changed since yesterday.",
      trigger: "device",
      device: { event: "site_opened", site: "wiki.example.com" },
    }),
  });
  expect(made.status).toBe(201);
  const routine = (await made.json()) as { id: string };
  const lastRun = async () => {
    const list = (await (await account.api(`/v1/bots/${account.botId}/routines`)).json()) as {
      items: Array<{ id: string; last_run_at: string | null }>;
    };
    return list.items.find((r) => r.id === routine.id)?.last_run_at ?? null;
  };
  await options.bringToFront();
  await options.getByTestId("device-triggers").check();
  await expect(options.getByTestId("device-status")).toHaveCount(1);
  await expect
    .poll(
      async () => ((await storage(worker)).local.browserDevice as { triggers?: boolean }).triggers,
    )
    .toBe(true);
  // Another site: nothing starts.
  const news = await context.newPage();
  await news.goto("https://news.example.org/today");
  await news.waitForTimeout(1500);
  expect(await lastRun()).toBeNull();
  const wiki = await context.newPage();
  await wiki.goto(`${WIKI}/home`);
  await expect.poll(lastRun, { timeout: 20_000 }).not.toBeNull();

  // Nothing switched on for the live view or meeting notes: the panel says so quietly.
  const panel = await openPanel(context, extensionId);
  await panel.getByTestId("tab-more").click();
  await expect(panel.getByTestId("computers")).toContainText("No computer is on right now.");
  await expect(panel.getByTestId("captions-consent")).toHaveCount(0);

  // Turning the kinds off removes the device.
  await options.bringToFront();
  await options.getByTestId("device-tab").uncheck();
  await options.getByTestId("device-triggers").uncheck();
  await expect
    .poll(
      async () =>
        (
          await account.api("/v1/device-requests", {
            method: "POST",
            body: JSON.stringify({ kind: "browser_tab" }),
          })
        ).status,
      { timeout: 15_000 },
    )
    .toBe(404);
});
