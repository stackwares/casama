/**
 * The options page: first-run agreement, signing in (three ways), and the signed-in view with the
 * account, server and workspace switchers. Plain DOM; nothing here needs a framework.
 */

import type { Schemas } from "@casama/client";
import { browserName, FEATURES, IS_FIREFOX, productName } from "../lib/browser.ts";
import { giveConsent, hasConsent, PRIVACY_URL } from "../lib/consent.ts";
import { type Child, h } from "../lib/dom.ts";
import { botAvatar } from "../lib/look.ts";
import { type Gate, gate, remoteConfig } from "../lib/remote-config.ts";
import {
  CLOUD_API,
  CLOUD_APP,
  normalizeServer,
  originPattern,
  serverLabel,
} from "../lib/servers.ts";
import {
  chooseWorkspace,
  clientFor,
  sendEmailCode,
  serverProviders,
  signInWithEmailCode,
  signInWithLink,
  signInWithProvider,
  signOut,
  switchAccount,
  UnreachableError,
} from "../lib/session.ts";
import { getSettings } from "../lib/settings.ts";
import { type Account, getLocal, getSession, updateSession } from "../lib/store.ts";
import { microphoneScreen, settingsSection, siteAccessCard } from "./settings.ts";

const VERSION = __CASAMA_VERSION__;
const app = document.getElementById("app")!;

const openTab = (url: string) => chrome.tabs.create({ url });

function brand() {
  return h(
    "header",
    { className: "brand" },
    h("img", { src: "/icons/icon-128.png", alt: "" }),
    h("strong", {}, productName()),
  );
}

function footer() {
  return h(
    "footer",
    { className: "muted" },
    `Version ${VERSION} · `,
    h("a", { href: PRIVACY_URL, target: "_blank", rel: "noopener" }, "Privacy"),
  );
}

function render(...nodes: Child[]) {
  app.classList.remove("narrow");
  app.replaceChildren(brand(), ...nodes.filter((n): n is Node | string => !!n), footer());
}

/** The short steps (agreement, sign-in, gates) as the app's sign-in sheet: one narrow centred column. */
function renderNarrow(...nodes: Child[]) {
  render(...nodes);
  app.classList.add("narrow");
}

/** UI state that lives only while this page is open. */
document.title = productName();

const ui = {
  adding: false,
  server: CLOUD_API,
  editingServer: false,
  emailSentTo: null as null | { server: string; email: string },
  /** "Other ways to sign in" stays open across re-renders once opened. */
  otherWaysOpen: !FEATURES.providerSignIn,
};
function setUi(patch: Partial<typeof ui>) {
  Object.assign(ui, patch);
  void refresh();
}

// ---------------------------------------------------------------------------
// Errors, with a way past the one that needs a permission
// ---------------------------------------------------------------------------

function errorView(e: unknown, retry: () => void): HTMLElement {
  const box = h("div", { className: "error", role: "alert", "data-testid": "error" });
  if (e instanceof UnreachableError) {
    box.append(
      `${e.message} Check the address and your connection. If it's a self-hosted server, ${browserName()} may need your permission to reach it. `,
      h(
        "button",
        {
          className: "link",
          "data-testid": "allow-server",
          onClick: async () => {
            // Asked straight from the click: the browser only shows the prompt for a user gesture.
            const granted = await chrome.permissions.request({ origins: [originPattern(e.url)] });
            if (granted) retry();
          },
        },
        "Allow access",
      ),
    );
  } else box.textContent = (e as Error)?.message || "Something went wrong.";
  return box;
}

/** Wires a form: disables while [action] runs, shows its error, re-renders when done. */
function busyForm(form: HTMLFormElement, action: () => Promise<void>) {
  const slot = h("div");
  form.append(slot);
  const run = async () => {
    const buttons = [...form.querySelectorAll("button")];
    for (const b of buttons) b.disabled = true;
    slot.replaceChildren();
    try {
      await action();
      await refresh();
    } catch (e) {
      slot.replaceChildren(errorView(e, () => void run()));
    } finally {
      for (const b of buttons) b.disabled = false;
    }
  };
  form.addEventListener("submit", (ev) => {
    ev.preventDefault();
    void run();
  });
  return form;
}

// ---------------------------------------------------------------------------
// Screens
// ---------------------------------------------------------------------------

function consentScreen() {
  renderNarrow(
    h("h1", {}, `Welcome to ${productName()}`),
    h(
      "p",
      { className: "muted" },
      "It connects this browser to your Casama bots. Before you sign in, here is what it does with your data.",
    ),
    h(
      "div",
      { className: "card", "data-testid": "consent" },
      h(
        "ul",
        { className: "points" },
        h(
          "li",
          {},
          "It reads a page only when you ask a bot about it or send it to Casama, never in the background.",
        ),
        h(
          "li",
          {},
          "What you send goes to the Casama server you sign in to (Casama Cloud, or your own server), and nowhere else.",
        ),
        h(
          "li",
          {},
          "Each message shows the context that went with it, and you can leave any part out before sending.",
        ),
        h(
          "li",
          {},
          "Your sign-in stays in this browser. It is never synced to your other computers and pages can't read it.",
        ),
        h(
          "li",
          {},
          "Usage counts are only which features you use, never page addresses or content, and you can turn them off in your account.",
        ),
      ),
      h(
        "p",
        { className: "muted" },
        IS_FIREFOX
          ? ""
          : "Casama's use of information follows the Chrome Web Store User Data Policy, including the Limited Use requirements. ",
        h("a", { href: PRIVACY_URL, target: "_blank", rel: "noopener" }, "Read the privacy policy"),
      ),
      h(
        "div",
        { className: "row" },
        h(
          "button",
          {
            className: "primary",
            "data-testid": "agree",
            onClick: async () => {
              await giveConsent();
              await finishPendingHandover();
              await refresh();
            },
          },
          "Agree and continue",
        ),
      ),
    ),
    h(
      "p",
      {},
      "New to Casama? ",
      h(
        "button",
        { className: "link", onClick: () => openTab(`${CLOUD_APP}/signup`) },
        "Create an account",
      ),
      FEATURES.webAppSignIn
        ? ", then come back through Connect Chrome in the web app."
        : ", then sign in here with the link from Sign In on Another Device.",
    ),
  );
}

function gateScreen(g: Exclude<Gate, { state: "ok" }>, account: Account | null) {
  const body =
    g.state === "off"
      ? h("p", {}, `${productName()} is turned off for now. The Casama apps still work as usual.`)
      : g.state === "update"
        ? h(
            "p",
            {},
            `This version (${VERSION}) is too old for ${serverLabel(account?.server ?? CLOUD_API)}. Update to ${g.minVersion} or newer. `,
            g.updateUrl
              ? h("a", { href: g.updateUrl, target: "_blank", rel: "noopener" }, "Update")
              : `${browserName()} updates extensions by itself within a few hours.`,
          )
        : h("p", {}, g.message);
  renderNarrow(
    h("h1", {}, g.state === "maintenance" ? "Casama is down for maintenance" : "Not available"),
    h("div", { className: "card", "data-testid": `gate-${g.state}` }, body),
    account &&
      h("button", { onClick: async () => (await signOut(account.id), refresh()) }, "Sign out"),
  );
}

function serverPicker() {
  if (!ui.editingServer)
    return h(
      "p",
      { "data-testid": "server" },
      "Server: ",
      h("strong", {}, serverLabel(ui.server)),
      " · ",
      h(
        "button",
        {
          className: "link",
          "data-testid": "change-server",
          onClick: () => setUi({ editingServer: true }),
        },
        "Change",
      ),
    );
  const input = h("input", {
    id: "server",
    value: ui.server === CLOUD_API ? "" : ui.server,
    placeholder: "casama.example.com",
    autocomplete: "url",
    "data-testid": "server-input",
  });
  return busyForm(
    h(
      "form",
      { className: "card" },
      h("label", { for: "server" }, "Server address"),
      h(
        "p",
        { className: "muted" },
        "For a self-hosted server or a Casama Link address. Leave it empty for Casama Cloud.",
      ),
      input,
      h(
        "div",
        { className: "row" },
        h(
          "button",
          { className: "primary", type: "submit", "data-testid": "use-server" },
          "Use this server",
        ),
        h("button", { type: "button", onClick: () => setUi({ editingServer: false }) }, "Cancel"),
      ),
    ),
    async () => {
      ui.server = input.value.trim() ? normalizeServer(input.value) : CLOUD_API;
      ui.editingServer = false;
    },
  );
}

const GOOGLE_G =
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" aria-hidden="true"><path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/><path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/><path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/><path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/></svg>';
const APPLE_LOGO =
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 814 1000" aria-hidden="true"><path fill="currentColor" d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76.5 0-103.7 40.8-165.9 40.8s-105.6-57-155.5-127C46.7 790.7 0 663 0 541.8c0-194.4 126.4-297.5 250.8-297.5 66.1 0 121.2 43.4 162.7 43.4 39.5 0 101.1-46 176.3-46 28.5 0 130.9 2.6 198.3 99.2zm-234-181.5c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8 1.3 15.6 1.9 18.1 3.2.6 8.4 1.3 13.6 1.3 45.4 0 102.5-30.4 135.5-71.3z"/></svg>';

const PROVIDER_NAMES: Record<string, string> = {
  google: "Google",
  apple: "Apple",
  github: "GitHub",
  azure: "Microsoft",
  gitlab: "GitLab",
  discord: "Discord",
  slack_oidc: "Slack",
};

/** Which providers each server signs in with, looked up once per page. */
const providerCache = new Map<string, Promise<string[]>>();

/** "Continue with Apple" and "Continue with Google": the server's providers, the app's way (Apple first on the web). */
function providerButtons() {
  if (!FEATURES.providerSignIn) return null;
  const box = h("div", { className: "providers", "data-testid": "route-providers" });
  const slot = h("div");
  const server = ui.server;
  let list = providerCache.get(server);
  if (!list) {
    list = serverProviders(server).catch(() => []);
    providerCache.set(server, list);
  }
  void list.then((names) => {
    if (ui.server !== server) return;
    const ordered = [
      ...["apple", "google"].filter((n) => names.includes(n)),
      ...names.filter((n) => n !== "apple" && n !== "google"),
    ];
    const buttons = ordered.map((name) => {
      const b = h(
        "button",
        {
          type: "button",
          className: `brand-pill brand-${name}`,
          "data-testid": `provider-${name}`,
        },
        `Continue with ${PROVIDER_NAMES[name] ?? name[0]!.toUpperCase() + name.slice(1)}`,
      );
      const logo = name === "google" ? GOOGLE_G : name === "apple" ? APPLE_LOGO : "";
      if (logo) b.insertAdjacentHTML("afterbegin", `<span class="brand-logo">${logo}</span>`);
      b.addEventListener("click", async () => {
        const all = [...box.querySelectorAll("button")];
        for (const x of all) x.disabled = true;
        slot.replaceChildren();
        try {
          await signInWithProvider(server, name);
          ui.adding = false;
          await refresh();
        } catch (e) {
          slot.replaceChildren(errorView(e, () => b.click()));
        } finally {
          for (const x of all) x.disabled = false;
        }
      });
      return b;
    });
    box.replaceChildren(...buttons, slot);
    box.after(...(buttons.length ? [h("div", { className: "or" }, h("span", {}, "or"))] : []));
  });
  return box;
}

function webAppCard() {
  // Firefox has no externally_connectable, so the web app can't hand it a sign-in.
  if (ui.server !== CLOUD_API || !FEATURES.webAppSignIn) return null;
  return h(
    "div",
    { className: "card", "data-testid": "route-webapp" },
    h("h2", {}, "Use the web app"),
    h(
      "p",
      { className: "muted" },
      "In the Casama web app, open Settings, then Sign In on Another Device, and press Connect Chrome. This page signs in by itself.",
    ),
    h(
      "div",
      { className: "row" },
      h(
        "button",
        { className: "primary", onClick: () => openTab(`${CLOUD_APP}/settings`) },
        "Open the web app",
      ),
    ),
  );
}

function pasteCard() {
  const field = h("textarea", {
    id: "link",
    placeholder: "https://casama.ai/pair#…",
    "data-testid": "link-input",
    spellcheck: "false",
  });
  return busyForm(
    h(
      "form",
      { className: "card", "data-testid": "route-paste" },
      h("h2", {}, "Paste a sign-in link"),
      h(
        "p",
        { className: "muted" },
        "In any Casama app you're signed in to, open Settings, then Sign In on Another Device, and copy the link. A link works once, for a few minutes.",
      ),
      h("label", { for: "link" }, "Sign-in link or code"),
      field,
      h(
        "div",
        { className: "row" },
        h(
          "button",
          { className: "primary", type: "submit", "data-testid": "link-submit" },
          "Sign in",
        ),
      ),
    ),
    async () => {
      await signInWithLink(field.value, { fallbackServer: ui.server });
      ui.adding = false;
    },
  );
}

function emailCard() {
  const sent = ui.emailSentTo;
  if (!sent) {
    const email = h("input", {
      id: "email",
      type: "email",
      autocomplete: "email",
      placeholder: "you@example.com",
      "data-testid": "email-input",
    });
    return busyForm(
      h(
        "form",
        { className: "card", "data-testid": "route-email" },
        h("h2", {}, "Email me a code"),
        h(
          "p",
          { className: "muted" },
          `We'll email a one-time code to your account on ${serverLabel(ui.server)}.`,
        ),
        h("label", { for: "email" }, "Email"),
        email,
        h(
          "div",
          { className: "row" },
          h(
            "button",
            { className: "primary", type: "submit", "data-testid": "email-submit" },
            "Send code",
          ),
        ),
      ),
      async () => {
        const server = await sendEmailCode(ui.server, email.value);
        ui.emailSentTo = { server, email: email.value.trim() };
      },
    );
  }
  const code = h("input", {
    id: "code",
    inputmode: "numeric",
    autocomplete: "one-time-code",
    placeholder: "123456",
    "data-testid": "code-input",
  });
  return busyForm(
    h(
      "form",
      { className: "card", "data-testid": "route-email" },
      h("h2", {}, "Enter the code"),
      h("p", { className: "muted" }, `We sent a code to ${sent.email}.`),
      h("label", { for: "code" }, "Code"),
      code,
      h(
        "div",
        { className: "row" },
        h(
          "button",
          { className: "primary", type: "submit", "data-testid": "code-submit" },
          "Sign in",
        ),
        h(
          "button",
          { type: "button", onClick: () => setUi({ emailSentTo: null }) },
          "Use another email",
        ),
      ),
    ),
    async () => {
      await signInWithEmailCode(sent.server, sent.email, code.value);
      ui.emailSentTo = null;
      ui.adding = false;
    },
  );
}

/** The web app's hand-over and a pasted link: still there, out of the way. */
function otherWays() {
  const cards = [webAppCard(), pasteCard()].filter((c) => !!c);
  const box = h(
    "details",
    { className: "other-ways", "data-testid": "other-ways", open: ui.otherWaysOpen },
    h("summary", {}, "Other ways to sign in"),
    ...cards,
  ) as HTMLDetailsElement;
  box.addEventListener("toggle", () => {
    ui.otherWaysOpen = box.open;
  });
  return box;
}

function signInScreen(hasAccounts: boolean) {
  renderNarrow(
    h("h1", {}, hasAccounts ? "Add an account" : "Sign in to Casama"),
    h("p", { className: "muted" }, "You never type a password into the extension."),
    serverPicker(),
    providerButtons(),
    emailCard(),
    otherWays(),
    hasAccounts && h("button", { onClick: () => setUi({ adding: false }) }, "Back"),
    !hasAccounts &&
      h(
        "p",
        {},
        "New to Casama? ",
        h(
          "button",
          { className: "link", onClick: () => openTab(`${CLOUD_APP}/signup`) },
          "Create an account",
        ),
      ),
  );
}

async function homeScreen(accounts: Account[], account: Account) {
  const accountSelect = h(
    "select",
    {
      id: "account",
      "data-testid": "account-select",
      onChange: async (ev: Event) => {
        const v = (ev.target as HTMLSelectElement).value;
        if (v === "__add") {
          ui.adding = true;
          await refresh();
        } else {
          await switchAccount(v);
          await refresh();
        }
      },
    },
    ...accounts.map((a) =>
      h(
        "option",
        { value: a.id, selected: a.id === account.id },
        `${a.email} · ${serverLabel(a.server)}`,
      ),
    ),
    h("option", { value: "__add" }, "Add an account or server…"),
  );
  const workspaceSlot = h("div");
  const settingsSlot = h("div");
  const botsSlot = h(
    "div",
    { className: "card", "data-testid": "bots" },
    h("p", { className: "muted" }, "Loading bots…"),
  );
  render(
    h("h1", {}, "You're signed in"),
    h(
      "div",
      { className: "card" },
      h("label", { for: "account" }, "Account"),
      accountSelect,
      workspaceSlot,
      h(
        "div",
        { className: "row" },
        h(
          "button",
          {
            "data-testid": "sign-out",
            onClick: async () => {
              await signOut(account.id);
              await refresh();
            },
          },
          "Sign out",
        ),
        h(
          "button",
          {
            className: "link",
            onClick: () => openTab(account.server === CLOUD_API ? CLOUD_APP : account.server),
          },
          "Open Casama",
        ),
      ),
    ),
    botsSlot,
    settingsSlot,
  );
  void settingsSection(account, () => void refresh(true)).then((el) =>
    settingsSlot.replaceChildren(el),
  );

  const api = clientFor(account);
  let orgs: Schemas["OrganizationWithRole"][];
  try {
    orgs = (await api.unwrap(api.GET("/v1/orgs", { signal: AbortSignal.timeout(20_000) }))).items;
  } catch (e) {
    botsSlot.replaceChildren(errorView(e, () => void refresh(true)));
    return;
  }
  const org = orgs.find((o) => o.id === account.orgId) ?? orgs[0];
  if (orgs.length > 1)
    workspaceSlot.replaceChildren(
      h("label", { for: "workspace" }, "Workspace"),
      h(
        "select",
        {
          id: "workspace",
          "data-testid": "workspace-select",
          onChange: async (ev: Event) => {
            await chooseWorkspace(account.id, (ev.target as HTMLSelectElement).value);
            await refresh();
          },
        },
        ...orgs.map((o) => h("option", { value: o.id, selected: o.id === org?.id }, o.name)),
      ),
    );
  else if (org)
    workspaceSlot.replaceChildren(
      h("p", { className: "muted", "data-testid": "workspace" }, `Workspace: ${org.name}`),
    );
  if (!org) {
    botsSlot.replaceChildren(
      h("p", {}, "You're not in a workspace yet. Create one in the Casama app."),
    );
    return;
  }
  try {
    const bots = (
      await api.unwrap(
        api.GET("/v1/bots", {
          params: { query: { org_id: org.id } },
          signal: AbortSignal.timeout(20_000),
        }),
      )
    ).items;
    botsSlot.replaceChildren(
      h("h2", {}, "Bots"),
      bots.length
        ? h(
            "ul",
            { className: "bots" },
            ...bots.map((b) =>
              h(
                "li",
                { "data-testid": "bot" },
                botAvatar(b.name, b.avatar_url, 32),
                h("span", {}, b.name),
              ),
            ),
          )
        : h(
            "p",
            { className: "muted" },
            "No bots in this workspace yet. Create one in the Casama app.",
          ),
    );
  } catch (e) {
    botsSlot.replaceChildren(errorView(e, () => void refresh(true)));
  }
}

// ---------------------------------------------------------------------------

/** A sign-in the web app handed over before the first-run agreement: finish it now. */
async function finishPendingHandover() {
  const pending = (await getSession()).pendingHandover;
  if (!pending) return;
  await updateSession((s) => {
    s.pendingHandover = null;
  });
  // Sign-in codes last five minutes; older ones would only fail.
  if (Date.now() - pending.at > 5 * 60_000) return;
  try {
    await signInWithLink(pending.link, { allowedServers: pending.allowedServers });
  } catch {
    // The person can still sign in another way on the screen that follows.
  }
}

let rendering: Promise<void> | null = null;
let again = false;
let forceNext = false;
/**
 * Draws the screen for the current state. Skips drawing when nothing it shows has changed, so a
 * storage event echoing this page's own change doesn't wipe what someone is typing. [force] is for
 * Retry.
 */
async function refresh(force = false): Promise<void> {
  forceNext ||= force;
  if (rendering) {
    again = true;
    return rendering;
  }
  rendering = (async () => {
    do {
      again = false;
      const f = forceNext;
      forceNext = false;
      await draw(f);
    } while (again);
  })().finally(() => {
    rendering = null;
  });
  return rendering;
}

let shown = "";
async function draw(force: boolean) {
  const consent = await hasConsent();
  const state = await getLocal();
  const account =
    state.accounts.find((a) => a.id === state.activeAccountId) ?? state.accounts[0] ?? null;
  const g = consent ? gate(await remoteConfig(account?.server ?? ui.server), VERSION) : null;
  const key = JSON.stringify({
    consent,
    g,
    accounts: state.accounts.map((a) => [a.id, a.orgId]),
    active: account?.id,
    ui,
  });
  if (key === shown && !force) return;
  shown = key;
  if (!consent || !g) return consentScreen();
  if (g.state !== "ok") return gateScreen(g, account);
  if (location.hash === "#microphone") return render(await microphoneScreen());
  // First run, after the agreement: where may it read pages (G1, recommended "all sites").
  if (!(await getSettings()).siteAccessChosen)
    return renderNarrow(
      h("h1", {}, "One more thing"),
      await siteAccessCard(() => void refresh(true), true),
    );
  if (!account || ui.adding) return signInScreen(state.accounts.length > 0);
  // Drawn now; its data loads after, so a slow server never holds up the next screen.
  void homeScreen(state.accounts, account);
}

// Another context (the service worker taking a handover, another settings tab) changed accounts.
chrome.storage.onChanged.addListener((changes, area) => {
  if (area !== "local" || !(changes.accounts || changes.activeAccountId || changes.consent)) return;
  const before = (changes.accounts?.oldValue as Account[] | undefined)?.length ?? 0;
  const after = (changes.accounts?.newValue as Account[] | undefined)?.length ?? 0;
  if (after > before) ui.adding = false;
  void refresh();
});

void refresh();
