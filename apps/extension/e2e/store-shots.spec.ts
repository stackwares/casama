/**
 * The Chrome Web Store pictures (plan §12): five 1280×800 screenshots, the 440×280 small tile and
 * the 1400×560 marquee, written to apps/extension/store/. Each screenshot is a page on the left and
 * the real panel on the right, as the side panel looks. Runs only when asked:
 *
 *   CASAMA_STORE_SHOTS=1 pnpm --filter @casama/extension e2e -- store-shots
 */
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import type { BrowserContext, Page } from "@playwright/test";
import { ARTICLE, endRunsAtOnce, openPanel, SITE, signIn, sse } from "./fixtures.ts";
import { expect, optionsPage, type TestAccount, test } from "./harness.ts";

const OUT = resolve(import.meta.dirname, "../store");
const ICON = `data:image/png;base64,${readFileSync(resolve(import.meta.dirname, "../public/icons/icon-128.png")).toString("base64")}`;
const W = 1280;
const H = 800;
const PANEL = 400;

test.skip(!process.env.CASAMA_STORE_SHOTS, "Set CASAMA_STORE_SHOTS=1 to render the store pictures");
test.describe.configure({ mode: "serial" });

const shot = async (page: Page, width: number) => {
  await page.setViewportSize({ width, height: H });
  return `data:image/png;base64,${(await page.screenshot()).toString("base64")}`;
};

/** The page and the panel side by side, with a caption bar along the top. */
async function compose(
  context: BrowserContext,
  name: string,
  caption: string,
  left: string,
  right: string,
) {
  const canvas = await context.newPage();
  await canvas.setViewportSize({ width: W, height: H });
  await canvas.setContent(`<!doctype html><html><body style="margin:0;font-family:system-ui,sans-serif;background:#fff">
    <div style="display:flex;height:${H}px">
      <div style="position:relative;width:${W - PANEL}px;overflow:hidden">
        <img src="${left}" style="display:block;width:${W - PANEL}px">
        <div style="position:absolute;left:24px;bottom:24px;background:#111;color:#fff;padding:12px 18px;border-radius:12px;font-size:20px;font-weight:600;max-width:640px">${caption}</div>
      </div>
      <div style="width:${PANEL}px;border-left:1px solid #ddd;overflow:hidden"><img src="${right}" style="display:block;width:${PANEL}px"></div>
    </div></body></html>`);
  await canvas.screenshot({ path: `${OUT}/screenshot-${name}.png` });
  await canvas.close();
}

const NEWS = ARTICLE.replace(
  "</article>",
  `<p>Reservoir levels, which fell to a ten-year low in October, are expected to recover slowly. "One wet week doesn't end a drought," said the regional water board.</p>
   <p>Orchards in the north of the valley, where the dry spell hit hardest, will see the most benefit.</p></article>`,
).replace(
  "<body>",
  `<body style="font:18px/1.6 Georgia,serif;max-width:720px;margin:40px auto;padding:0 32px;color:#222">`,
);

async function seedInbox(account: TestAccount) {
  const [run] = await account.rest<{ id: string }[]>("/runs", {
    method: "POST",
    body: JSON.stringify({
      org_id: account.orgId,
      bot_id: account.botId,
      status: "waiting_approval",
    }),
  });
  await account.rest("/approvals", {
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
  await account.rest("/runs", {
    method: "POST",
    body: JSON.stringify({
      org_id: account.orgId,
      bot_id: account.botId,
      status: "running",
      trigger: "routine",
    }),
  });
}

test("store screenshots and tiles", async ({ context, extensionId, account }) => {
  test.setTimeout(180_000);
  await account.rest(`/bots?id=eq.${account.botId}`, {
    method: "PATCH",
    body: JSON.stringify({ name: "Researcher" }),
  });
  await signIn(context, extensionId, account);
  await context.route(`${SITE}/news`, (r) => r.fulfill({ contentType: "text/html", body: NEWS }));

  // 1. Chat: a question about the article, the reply streaming with a card.
  await context.route(/\/v1\/runs\/[^/]+\/events/, async (route) => {
    const runId = /\/v1\/runs\/([^/]+)\/events/.exec(route.request().url())![1]!;
    const base = { v: 1, run_id: runId, bot_id: account.botId, ts: new Date().toISOString() };
    if (route.request().headers()["last-event-id"] !== "0") return; // Leave the reconnect hanging.
    await route.fulfill({
      contentType: "text/event-stream",
      body: sse([
        {
          ...base,
          seq: 1,
          type: "message.delta",
          payload: {
            text: "After **eleven dry weeks**, steady rain returned on Tuesday. Two more days of showers are expected, but the water board says one wet week won't end the drought.",
          },
        },
        {
          ...base,
          seq: 2,
          type: "ui.shown",
          payload: {
            surface_id: "s1",
            messages: [
              { version: "1.0", createSurface: { surfaceId: "s1", catalogId: "basic" } },
              {
                version: "1.0",
                updateComponents: {
                  surfaceId: "s1",
                  components: [
                    { id: "root", component: "Column", children: ["t", "b"] },
                    { id: "t", component: "Text", text: "**Rain this week**: Tue, Wed, Thu" },
                    {
                      id: "b",
                      component: "Button",
                      child: "bl",
                      action: { event: { name: "remind" } },
                    },
                    { id: "bl", component: "Text", text: "Remind me Friday" },
                  ],
                },
              },
            ],
          },
        },
      ]),
    });
  });
  const news = await context.newPage();
  await news.goto(`${SITE}/news`);
  await news.evaluate(() => {
    const range = document.createRange();
    range.selectNodeContents(document.getElementById("lead")!);
    getSelection()!.addRange(range);
  });
  const newsShot = await shot(news, W - PANEL);
  const panel = await openPanel(context, extensionId);
  await panel.getByTestId("composer").click();
  await expect(panel.getByTestId("chip-selection")).toBeVisible();
  await panel.getByTestId("composer").fill("What does this mean for the drought?");
  await panel.getByTestId("send").click();
  await expect(panel.getByTestId("live-reply").getByTestId("ui-card")).toBeVisible();
  await compose(
    context,
    "1-chat",
    "Ask any bot about the page you're on",
    newsShot,
    await shot(panel, PANEL),
  );

  // 2. Chips: what goes with the next message, with sizes.
  await panel.getByTestId("new-chat").click();
  await panel.getByTestId("chip-text").click();
  await panel.getByTestId("composer").fill("Summarise this in three points");
  await compose(
    context,
    "2-context",
    "You choose what's sent: page, selection, text or a screenshot",
    newsShot,
    await shot(panel, PANEL),
  );
  await panel.close();

  // 3. Inbox: approve a bot's step without opening the app.
  await context.unroute(/\/v1\/runs\/[^/]+\/events/);
  await endRunsAtOnce(context, account);
  await seedInbox(account);
  const inbox = await openPanel(context, extensionId);
  await inbox.getByTestId("tab-inbox").click();
  await expect(inbox.getByTestId("approval")).toBeVisible();
  await compose(
    context,
    "3-inbox",
    "Approve your bots' steps from Chrome",
    newsShot,
    await shot(inbox, PANEL),
  );

  // 4. Library: save the page.
  await inbox.getByTestId("tab-library").click();
  await inbox.getByTestId("save-markdown").click();
  await expect(inbox.getByTestId("creation").first()).toBeVisible();
  await compose(
    context,
    "4-library",
    "Save pages to your Library in one click",
    newsShot,
    await shot(inbox, PANEL),
  );
  await inbox.close();

  // 5. Settings: site access and the never-list.
  const options = await optionsPage(context, extensionId);
  await options.setViewportSize({ width: W, height: H });
  await options.getByTestId("site-access").scrollIntoViewIfNeeded();
  await options.screenshot({ path: `${OUT}/screenshot-5-settings.png` });

  // Promo tiles.
  const tile = await context.newPage();
  const promo = (w: number, h: number, big: boolean) =>
    `<!doctype html><html><body style="margin:0;width:${w}px;height:${h}px;display:flex;align-items:center;gap:${big ? 48 : 20}px;padding:0 ${big ? 96 : 32}px;box-sizing:border-box;background:#111;color:#fff;font-family:system-ui,sans-serif">
      <img src="${ICON}" width="${big ? 160 : 88}" height="${big ? 160 : 88}" style="border-radius:22%">
      <div><div style="font-size:${big ? 64 : 34}px;font-weight:700;letter-spacing:-0.03em">Casama</div>
      <div style="font-size:${big ? 30 : 17}px;opacity:.85;margin-top:${big ? 12 : 6}px">Your AI bots in Chrome</div>
      ${big ? '<div style="font-size:22px;opacity:.7;margin-top:20px">Ask about any page · Save what matters · Approve from anywhere</div>' : ""}</div></body></html>`;
  await tile.setViewportSize({ width: 440, height: 280 });
  await tile.setContent(promo(440, 280, false));
  await tile.screenshot({ path: `${OUT}/small-tile-440x280.png` });
  await tile.setViewportSize({ width: 1400, height: 560 });
  await tile.setContent(promo(1400, 560, true));
  await tile.screenshot({ path: `${OUT}/marquee-1400x560.png` });
});
