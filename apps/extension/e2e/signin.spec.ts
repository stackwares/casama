/**
 * Phase 0's "done when" (plan §15): the built extension signs in to a Casama server by each of the
 * three routes, lists bots, and signs out. Also: the first-run agreement comes first, tokens stay
 * where §9.2 says, and the account and workspace switchers work.
 */
import type { Page, Worker } from "@playwright/test";
import { openOtherWays } from "./fixtures.ts";
import { API, expect, optionsPage, storage, TestAccount, test } from "./harness.ts";

type Stored = {
  accounts: { refreshToken: string; authUrl: string; anonKey: string; email: string }[];
};

async function agree(page: Page, opts: { siteAccess?: boolean } = {}) {
  await expect(page.getByTestId("consent")).toBeVisible();
  await page.getByTestId("agree").click();
  await expect(page.getByTestId("consent")).toHaveCount(0);
  if (opts.siteAccess === false) return;
  // First run's site access step; "when you click" needs no permission prompt.
  await page.getByTestId("access-click").check();
  await page.getByTestId("save-access").click();
  await expect(page.getByTestId("first-run-access")).toHaveCount(0);
}

async function useServer(page: Page, server: string) {
  await page.getByTestId("change-server").click();
  await page.getByTestId("server-input").fill(server);
  await page.getByTestId("use-server").click();
  await expect(page.getByTestId("server")).toContainText(new URL(server).host);
}

async function expectSignedIn(page: Page, account: TestAccount) {
  await expect(page.getByRole("heading", { name: "You're signed in" })).toBeVisible();
  await expect(page.getByTestId("account-select")).toContainText(account.email);
  await expect(page.getByTestId("bot").filter({ hasText: account.botName })).toBeVisible();
}

/** Signs out and checks the session really ended: forgotten here, refused by Auth. */
async function signOutAndCheck(page: Page, worker: Worker) {
  const before = (await storage(worker)).local as Stored;
  const { refreshToken, authUrl, anonKey } = before.accounts.at(-1)!;
  await page.getByTestId("sign-out").click();
  await expect(page.getByRole("heading", { name: "Sign in to Casama" })).toBeVisible();
  const after = await storage(worker);
  expect((after.local as Stored).accounts).toEqual([]);
  expect(after.session.tokens).toEqual({});
  const res = await fetch(`${authUrl}/auth/v1/token?grant_type=refresh_token`, {
    method: "POST",
    headers: { apikey: anonKey, "content-type": "application/json" },
    body: JSON.stringify({ refresh_token: refreshToken }),
  });
  expect(res.status).toBe(400);
}

test("shows the first-run agreement before anything else", async ({
  context,
  extensionId,
  worker,
}) => {
  const page = await optionsPage(context, extensionId);
  await expect(page.getByTestId("consent")).toContainText("never in the background");
  await expect(page.getByTestId("route-paste")).toHaveCount(0);
  expect((await storage(worker)).local.consent).toBeUndefined();
  await agree(page);
  await expect(page.getByRole("heading", { name: "Sign in to Casama" })).toBeVisible();
  await expect(page.getByTestId("route-email")).toBeVisible();
  await expect(page.getByTestId("provider-google")).toBeVisible();
  await expect(page.getByTestId("provider-apple")).toBeVisible();
  await openOtherWays(page);
  for (const id of ["route-webapp", "route-paste"])
    await expect(page.getByTestId(id)).toBeVisible();
  expect((await storage(worker)).local.consent).toMatchObject({ version: 1 });
});

test("route 2: signs in with a pasted sign-in link, lists bots, signs out", async ({
  context,
  extensionId,
  worker,
  account,
}) => {
  const page = await optionsPage(context, extensionId);
  await agree(page);
  const link = await account.signInLink();
  await openOtherWays(page);
  await page.getByTestId("link-input").fill(link);
  await page.getByTestId("link-submit").click();
  await expectSignedIn(page, account);

  // Tokens: refresh token on disk, access token in memory only, nothing synced.
  const s = await storage(worker);
  const local = s.local as Stored;
  expect(local.accounts).toHaveLength(1);
  expect(local.accounts[0]!.refreshToken).toBeTruthy();
  const tokens = Object.values(s.session.tokens as Record<string, { token: string }>);
  expect(tokens).toHaveLength(1);
  expect(JSON.stringify(s.local)).not.toContain(tokens[0]!.token);
  expect(s.sync).toEqual({});

  // A page's own scripts can't see the extension's storage.
  await context.route("http://localhost:5999/**", (r) =>
    r.fulfill({ contentType: "text/html", body: "<title>page</title>" }),
  );
  const web = await context.newPage();
  await web.goto("http://localhost:5999/");
  expect(
    await web.evaluate(
      () => typeof (globalThis as { chrome?: { storage?: unknown } }).chrome?.storage,
    ),
  ).toBe("undefined");
  await web.close();

  await signOutAndCheck(page, worker);

  // A link works once.
  await openOtherWays(page);
  await page.getByTestId("link-input").fill(link);
  await page.getByTestId("link-submit").click();
  await expect(page.getByTestId("error")).toContainText("isn't valid any more");
});

test("route 3: signs in with an email code, lists bots, signs out", async ({
  context,
  extensionId,
  worker,
  account,
}) => {
  const page = await optionsPage(context, extensionId);
  await agree(page);
  await useServer(page, API);

  // An address with no account is told so; Auth sends nothing (create_user is false).
  await page.getByTestId("email-input").fill(`nobody-${Date.now()}@example.com`);
  await page.getByTestId("email-submit").click();
  await expect(page.getByTestId("error")).toContainText("no Casama account");

  // For the real account, keep Auth from emailing a test address; the code comes from the admin API.
  let otpBody: unknown;
  await page.route("**/auth/v1/otp", async (route) => {
    otpBody = route.request().postDataJSON();
    await route.fulfill({ status: 200, contentType: "application/json", body: "{}" });
  });
  await page.getByTestId("email-input").fill(account.email);
  await page.getByTestId("email-submit").click();
  await expect(page.getByTestId("code-input")).toBeVisible();
  expect(otpBody).toEqual({ email: account.email, create_user: false });

  await page.getByTestId("code-input").fill("000000");
  await page.getByTestId("code-submit").click();
  await expect(page.getByTestId("error")).toContainText("wrong or has run out");

  await page.getByTestId("code-input").fill(await account.emailCode());
  await page.getByTestId("code-submit").click();
  await expectSignedIn(page, account);
  await signOutAndCheck(page, worker);
});

const FIXTURE = `<!doctype html><title>web app</title><script>
  window.send = (id, message) => new Promise((resolve) => {
    if (!globalThis.chrome?.runtime?.sendMessage) return resolve({ unavailable: true });
    chrome.runtime.sendMessage(id, message, (reply) => resolve(reply ?? { error: chrome.runtime.lastError?.message }));
  });
</script>`;

/** Sends a message to the extension from [page], as the web app does. */
const send = (page: Page, id: string, message: unknown) =>
  page.evaluate(
    ([i, m]) =>
      (window as unknown as { send: (id: unknown, m: unknown) => Promise<unknown> }).send(i, m),
    [id, message] as const,
  );

test("route 1: signs in with a sign-in handed over by the web app, lists bots, signs out", async ({
  context,
  extensionId,
  worker,
  account,
}) => {
  const page = await optionsPage(context, extensionId);
  const serve = (r: { fulfill: (o: object) => Promise<void> }) =>
    r.fulfill({ contentType: "text/html", body: FIXTURE });
  await context.route("https://app.casama.ai/**", serve);
  await context.route("http://localhost:5998/**", serve);
  await context.route("https://elsewhere.example/**", serve);

  // Casama Cloud's web app can reach the extension, but only to sign in to Casama Cloud.
  const cloud = await context.newPage();
  await cloud.goto("https://app.casama.ai/settings");
  expect(await send(cloud, extensionId, { type: "casama.ping" })).toEqual({
    ok: true,
    version: "0.1.0",
  });
  const link = await account.signInLink();
  expect(await send(cloud, extensionId, { type: "casama.signIn", link: link })).toMatchObject({
    ok: false,
  });

  // Other sites can't talk to it at all.
  const other = await context.newPage();
  await other.goto("https://elsewhere.example/");
  expect(await send(other, extensionId, { type: "casama.ping" })).not.toMatchObject({
    ok: true,
  });

  // The dev build takes a local web app's handover. Before the agreement it waits for it.
  const local = await context.newPage();
  await local.goto("http://localhost:5998/settings");
  expect(await send(local, extensionId, { type: "casama.signIn", link: link })).toEqual({
    ok: true,
    pending: true,
  });
  await page.bringToFront();
  await agree(page);
  await expectSignedIn(page, account);

  // Once agreed, a handover signs in straight away.
  await signOutAndCheck(page, worker);
  const reply = await send(local, extensionId, {
    type: "casama.signIn",
    link: await account.signInLink(),
  });
  expect(reply).toEqual({ ok: true, email: account.email });
  await expectSignedIn(page, account);
  await signOutAndCheck(page, worker);
});

test("switches between accounts and workspaces", async ({
  context,
  extensionId,
  worker,
  account,
}) => {
  const second = await new TestAccount(account.serviceKey).create();
  try {
    // A second workspace for the first account, with no bots in it.
    await account.api("/v1/orgs", {
      method: "POST",
      body: JSON.stringify({ name: "Second space" }),
    });

    const page = await optionsPage(context, extensionId);
    await agree(page);
    await openOtherWays(page);
    await page.getByTestId("link-input").fill(await account.signInLink());
    await page.getByTestId("link-submit").click();
    await expectSignedIn(page, account);

    await page.getByTestId("workspace-select").selectOption({ label: "Second space" });
    await expect(page.getByTestId("bots")).toContainText("No bots in this workspace yet");
    await page.getByTestId("workspace-select").selectOption({ label: "Chrome test" });
    await expect(page.getByTestId("bot").filter({ hasText: account.botName })).toBeVisible();

    await page.getByTestId("account-select").selectOption({ label: "Add an account or server…" });
    await expect(page.getByRole("heading", { name: "Add an account" })).toBeVisible();
    await openOtherWays(page);
    await page.getByTestId("link-input").fill(await second.signInLink());
    await page.getByTestId("link-submit").click();
    await expectSignedIn(page, second);

    await page
      .getByTestId("account-select")
      .selectOption({ label: `${account.email} · localhost:${new URL(API).port}` });
    await expectSignedIn(page, account);
    expect(((await storage(worker)).local as Stored).accounts).toHaveLength(2);
  } finally {
    await second.remove();
  }
});

test("follows the server's remote settings: kill switch and minimum version", async ({
  context,
  extensionId,
}) => {
  let config: object = { flags: { chrome_extension: false } };
  await context.route("**/v1/app-config", (r) =>
    r.fulfill({
      contentType: "application/json",
      body: JSON.stringify({
        min_versions: {},
        update_urls: {},
        maintenance: null,
        announcements: [],
        flags: {},
        ...config,
      }),
    }),
  );
  const page = await optionsPage(context, extensionId);
  await agree(page, { siteAccess: false });
  await expect(page.getByTestId("gate-off")).toContainText("turned off for now");

  // A fresh page reads settings again once the cached ones are cleared.
  config = {
    min_versions: { chrome: "9.0.0" },
    update_urls: { chrome: "https://example.com/update" },
  };
  await page.evaluate(() => chrome.storage.local.set({ remoteConfig: {} }));
  await page.reload();
  await expect(page.getByTestId("gate-update")).toContainText("Update to 9.0.0");
});
