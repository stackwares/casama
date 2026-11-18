/** Shared by the panel tests and the store screenshots: sign-in, the panel, fixture pages, fake run events. */
import type { BrowserContext, Page } from "@playwright/test";
import { expect, optionsPage, type TestAccount } from "./harness.ts";

export const SITE = "http://localhost:5999";

/** Opens "Other ways to sign in", where the pasted link lives. */
export async function openOtherWays(page: Page) {
  const box = page.getByTestId("other-ways");
  if ((await box.getAttribute("open")) === null) await box.locator("summary").click();
}

export async function signIn(context: BrowserContext, extensionId: string, account: TestAccount) {
  const page = await optionsPage(context, extensionId);
  await page.getByTestId("agree").click();
  await page.getByTestId("access-all").check();
  await page.getByTestId("save-access").click();
  await expect(page.getByTestId("first-run-access")).toHaveCount(0);
  await openOtherWays(page);
  await page.getByTestId("link-input").fill(await account.signInLink());
  await page.getByTestId("link-submit").click();
  await expect(page.getByRole("heading", { name: "You're signed in" })).toBeVisible();
  return page;
}

export async function openPanel(context: BrowserContext, extensionId: string): Promise<Page> {
  const panel = await context.newPage();
  await panel.goto(`chrome-extension://${extensionId}/panel/panel.html`);
  await expect(panel.getByTestId("chat")).toBeVisible();
  return panel;
}

export const ARTICLE = `<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Rain returns to the valley</title></head><body>
<header><nav>Home · World · Weather</nav></header>
<article><h1>Rain returns to the valley</h1>
<p id="lead">After eleven dry weeks, farmers in the valley welcomed steady rain on Tuesday.</p>
<p>Forecasters expect two more days of showers before the weekend clears.</p></article>
<footer>© The Valley Times</footer></body></html>`;

/** A one-page PDF with a line of text and a title, built by hand. */
export function tinyPdf(text: string, title: string): Buffer {
  const content = `BT /F1 24 Tf 72 700 Td (${text}) Tj ET`;
  const objects = [
    "<< /Type /Catalog /Pages 2 0 R >>",
    "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
    "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>",
    `<< /Length ${content.length} >>\nstream\n${content}\nendstream`,
    "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
    `<< /Title (${title}) >>`,
  ];
  let out = "%PDF-1.4\n";
  const offsets: number[] = [];
  objects.forEach((o, i) => {
    offsets.push(out.length);
    out += `${i + 1} 0 obj\n${o}\nendobj\n`;
  });
  const xref = out.length;
  out += `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n`;
  for (const o of offsets) out += `${String(o).padStart(10, "0")} 00000 n \n`;
  out += `trailer\n<< /Size ${objects.length + 1} /Root 1 0 R /Info 6 0 R >>\nstartxref\n${xref}\n%%EOF\n`;
  return Buffer.from(out, "latin1");
}

export const YOUTUBE_PLAYER = {
  videoDetails: { title: "How rain forms" },
  captions: {
    playerCaptionsTracklistRenderer: {
      captionTracks: [
        { baseUrl: "https://www.youtube.com/api/timedtext?v=rain1&lang=en", languageCode: "en" },
      ],
    },
  },
};
export const YOUTUBE_PAGE = `<!doctype html><html><head><meta charset="utf-8"><title>How rain forms - YouTube</title></head><body>
<div id="movie_player"></div>
<script>
var ytInitialPlayerResponse = ${JSON.stringify(YOUTUBE_PLAYER)};
document.getElementById("movie_player").getCurrentTime = function () { return 75; };
</script><p>How rain forms</p></body></html>`;
export const CAPTIONS = {
  events: [
    { tStartMs: 0, segs: [{ utf8: "Water vapour rises and cools." }] },
    { tStartMs: 4000, segs: [{ utf8: "Droplets gather around dust." }] },
  ],
};

/** Reads the stored text of the newest user message in the account's newest conversation. */
export async function lastUserMessage(account: TestAccount): Promise<string> {
  const convs = (await (await account.api(`/v1/bots/${account.botId}/conversations`)).json()) as {
    items: { id: string; created_at: string }[];
  };
  const conv = convs.items.sort((a, b) => b.created_at.localeCompare(a.created_at))[0]!;
  const thread = (await (
    await account.api(`/v1/conversations/${conv.id}/thread?limit=40`)
  ).json()) as {
    items: {
      role: string;
      content: { type: string; text?: string; path?: string; uploaded?: boolean }[] | string;
    }[];
  };
  const mine = thread.items.filter((m) => m.role === "user").at(-1)!;
  return typeof mine.content === "string" ? mine.content : JSON.stringify(mine.content);
}

export const sse = (events: object[]) =>
  events.map((e) => `event: run_event\ndata: ${JSON.stringify(e)}\n\n`).join("");

/** Every run ends straight away, with no reply. */
export function endRunsAtOnce(context: BrowserContext, account: TestAccount) {
  return context.route(/\/v1\/runs\/[^/]+\/events/, (route) => {
    const runId = /\/v1\/runs\/([^/]+)\/events/.exec(route.request().url())![1]!;
    return route.fulfill({
      contentType: "text/event-stream",
      body: sse([
        {
          v: 1,
          run_id: runId,
          bot_id: account.botId,
          ts: new Date().toISOString(),
          seq: 1,
          type: "run.completed",
          payload: {},
        },
      ]),
    });
  });
}
