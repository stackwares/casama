/**
 * Settings (plan §6 G1–G8) and the first-run site access step: what the extension may read and
 * where, what goes with a message by default, notifications, the account's analytics switch,
 * signed-in devices and "sign out everywhere".
 */

import { logout } from "../lib/auth.ts";
import { browserName, FEATURES } from "../lib/browser.ts";
import { h } from "../lib/dom.ts";
import { GUARD_REASON } from "../lib/guard.ts";
import { accessToken, signOut } from "../lib/session.ts";
import {
  type Chips,
  cleanHost,
  getSettings,
  originsFor,
  type SiteAccess,
  updateSettings,
} from "../lib/settings.ts";
import type { Account } from "../lib/store.ts";
import { rest } from "../lib/workspace.ts";
import { onPagesCard, pageCommandsCard } from "./phase2.ts";
import { actSitesCard } from "./phase3.ts";
import { bookmarksCard, captionsCard, deviceCard } from "./phase4.ts";

const ACCESS: Array<{ value: SiteAccess; title: string; text: string }> = [
  {
    value: "all",
    title: "On all sites (recommended)",
    text: "Casama can read whichever tab you're on when you ask, and the panel follows you from tab to tab. It still reads nothing until you ask.",
  },
  {
    value: "sites",
    title: "On sites you pick",
    text: "Like the above, but only on the sites you list. Elsewhere, click the Casama button first.",
  },
  {
    value: "click",
    title: "When you click",
    text: "Casama can read a tab only after you click its button or use its menu or shortcut there.",
  },
];

/** Asks Chrome for the mode's site permissions (from a click) and drops the ones not needed. */
export async function applySiteAccess(access: SiteAccess, sites: string[]): Promise<boolean> {
  const want = originsFor(access, sites);
  if (want.length && !(await chrome.permissions.request({ origins: want }))) return false;
  const have = (await chrome.permissions.getAll()).origins ?? [];
  const extra = have.filter(
    (o) =>
      !want.includes(o) &&
      /^https?:\/\/\*?/.test(o) &&
      (access !== "sites" || o === "https://*/*" || o === "http://*/*"),
  );
  if (access !== "all" && extra.length)
    await chrome.permissions.remove({ origins: extra }).catch(() => false);
  await updateSettings((s) => {
    s.siteAccess = access;
    s.sites = sites;
    s.siteAccessChosen = true;
  });
  return true;
}

export async function siteAccessCard(onDone: () => void, firstRun = false): Promise<HTMLElement> {
  const s = await getSettings();
  const sitesInput = h("textarea", {
    placeholder: "docs.example.com\nmail.example.com",
    "data-testid": "sites-input",
    "aria-label": "Sites",
  }) as HTMLTextAreaElement;
  sitesInput.value = s.sites.join("\n");
  const error = h("div", { className: "error", role: "alert" });
  const form = h(
    "form",
    { className: "card", "data-testid": firstRun ? "first-run-access" : "site-access" },
    h("h2", {}, firstRun ? "Where may Casama read pages?" : "Site access"),
    h(
      "p",
      { className: "muted" },
      "Pages are read only when you ask a bot about them or save them. You can change this any time.",
    ),
    ...ACCESS.map((a) =>
      h(
        "label",
        { className: "choice" },
        h("input", {
          type: "radio",
          name: "access",
          value: a.value,
          checked: (firstRun ? "all" : s.siteAccess) === a.value,
          "data-testid": `access-${a.value}`,
        }),
        h("span", {}, h("strong", {}, a.title), h("br"), h("span", { className: "muted" }, a.text)),
      ),
    ),
    h("label", { for: "sites" }, "Sites, one per line (for “On sites you pick”)"),
    sitesInput,
    h(
      "div",
      { className: "row" },
      h(
        "button",
        { className: "primary", type: "submit", "data-testid": "save-access" },
        firstRun ? "Continue" : "Save",
      ),
    ),
    error,
  );
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    error.textContent = "";
    const access = (new FormData(form).get("access") as SiteAccess) ?? "click";
    const sites = sitesInput.value
      .split(/[\s,]+/)
      .map(cleanHost)
      .filter((x): x is string => !!x);
    if (access === "sites" && !sites.length) {
      error.textContent = "List at least one site.";
      return;
    }
    if (await applySiteAccess(access, sites)) onDone();
    else
      error.textContent = `${browserName()} didn't give the permission. Pick another option, or try again.`;
  });
  return form;
}

function chipsCard(chips: Chips) {
  const labels: Record<keyof Chips, string> = {
    page: "The page's address and title",
    selection: "The text you've selected",
    text: "The page's text",
    screenshot: "A screenshot",
  };
  return h(
    "div",
    { className: "card", "data-testid": "chip-defaults" },
    h("h2", {}, "Sent with a message, unless you switch it off"),
    ...(Object.keys(labels) as (keyof Chips)[]).map((k) =>
      h(
        "label",
        { className: "choice" },
        h("input", {
          type: "checkbox",
          checked: chips[k],
          "data-testid": `default-${k}`,
          onChange: (e: Event) =>
            void updateSettings((s) => {
              s.chips[k] = (e.target as HTMLInputElement).checked;
            }),
        }),
        h("span", {}, labels[k]),
      ),
    ),
  );
}

async function neverCard() {
  const s = await getSettings();
  const input = h("textarea", {
    "data-testid": "never-input",
    "aria-label": "Never-list",
  }) as HTMLTextAreaElement;
  input.value = s.neverList.join("\n");
  const note = h("div", { className: "notice", role: "status" });
  return h(
    "div",
    { className: "card", "data-testid": "never-list" },
    h("h2", {}, "Never read these sites"),
    h(
      "p",
      { className: "muted" },
      `Always off: Casama's own pages, and pages with a password or card field. Off by default: banking and payments, health sites, password managers and government ID sites. ${GUARD_REASON.never}`.replace(
        GUARD_REASON.never,
        "Add your own below, one per line.",
      ),
    ),
    input,
    h(
      "div",
      { className: "row" },
      h(
        "button",
        {
          "data-testid": "save-never",
          onClick: async () => {
            const list = input.value
              .split(/[\s,]+/)
              .map(cleanHost)
              .filter((x): x is string => !!x);
            await updateSettings((x) => {
              x.neverList = [...new Set(list)];
            });
            input.value = list.join("\n");
            note.textContent = "Saved.";
          },
        },
        "Save",
      ),
    ),
    note,
  );
}

async function accountCard(account: Account) {
  const s = await getSettings();
  const analytics = h("input", {
    type: "checkbox",
    "data-testid": "analytics",
    disabled: true,
  }) as HTMLInputElement;
  // G5: the account's own opt-out, the same switch as in the app.
  void rest(account, `profiles?user_id=eq.${account.userId}&select=analytics_opt_out`)
    .then((r) => r.json() as Promise<{ analytics_opt_out: boolean }[]>)
    .then((rows) => {
      analytics.checked = !rows[0]?.analytics_opt_out;
      analytics.disabled = false;
    })
    .catch(() => {});
  analytics.addEventListener("change", async () => {
    const token = await accessToken(account.id);
    await fetch(`${account.server}/v1/me/analytics-opt-out`, {
      method: "POST",
      headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
      body: JSON.stringify({ opt_out: !analytics.checked }),
    }).catch(() => {});
  });
  const devices = h("ul", { className: "bots", "data-testid": "devices" });
  void rest(
    account,
    `devices?user_id=eq.${account.userId}&select=id,platform,last_seen_at,fcm_token&order=last_seen_at.desc`,
  )
    .then(
      (r) =>
        r.json() as Promise<
          { id: string; platform: string; last_seen_at: string; fcm_token: string }[]
        >,
    )
    .then((rows) =>
      devices.replaceChildren(
        ...(rows.length
          ? rows.map((d) =>
              h(
                "li",
                {},
                h(
                  "span",
                  {},
                  `${d.platform === "chrome" ? "Chrome" : d.platform}${d.fcm_token === account.deviceToken ? " (this browser)" : ""}`,
                ),
                h(
                  "span",
                  { className: "muted" },
                  ` · seen ${new Date(d.last_seen_at).toLocaleDateString("en-US")}`,
                ),
              ),
            )
          : [h("li", { className: "muted" }, "No devices take notifications yet.")]),
      ),
    )
    .catch(() =>
      devices.replaceChildren(h("li", { className: "muted" }, "Couldn't load devices.")),
    );
  const note = h("div", { className: "notice", role: "status" });
  return h(
    "div",
    { className: "card", "data-testid": "account-settings" },
    h("h2", {}, "Notifications and privacy"),
    h(
      "label",
      { className: "choice" },
      h("input", {
        type: "checkbox",
        checked: s.notifications,
        "data-testid": "notifications",
        onChange: (e: Event) =>
          void updateSettings((x) => {
            x.notifications = (e.target as HTMLInputElement).checked;
          }),
      }),
      h("span", {}, "Show a notification when a bot needs you or finishes"),
    ),
    h(
      "label",
      { className: "choice" },
      analytics,
      h("span", {}, "Share which features I use (never page content or addresses)"),
    ),
    h("h2", { style: "margin-top:16px" }, "Signed-in devices"),
    devices,
    h(
      "div",
      { className: "row" },
      h(
        "button",
        {
          "data-testid": "sign-out-everywhere",
          onClick: async () => {
            if (!confirm("Sign out of Casama on every device, including this browser?")) return;
            const token = await accessToken(account.id);
            if (token)
              await logout(
                { authUrl: account.authUrl, anonKey: account.anonKey },
                token,
                fetch,
                "global",
              ).catch(() => {});
            await signOut(account.id);
            note.textContent = "Signed out everywhere.";
          },
        },
        "Sign out everywhere",
      ),
    ),
    note,
  );
}

/** The settings cards shown under the account on the signed-in screen. */
export async function settingsSection(account: Account, redraw: () => void): Promise<HTMLElement> {
  const s = await getSettings();
  const wrap = h(
    "div",
    { "data-testid": "settings" },
    h("h1", { style: "margin-top:32px" }, "Settings"),
  );
  wrap.append(
    await siteAccessCard(redraw),
    chipsCard(s.chips),
    ...(FEATURES.pageKit ? [await onPagesCard()] : []),
    await pageCommandsCard(account),
    await neverCard(),
    // Phase 5: Firefox has no Act and isn't a device source (src/lib/browser.ts).
    ...(FEATURES.act ? [await actSitesCard()] : []),
    ...(FEATURES.device ? [await deviceCard(account)] : []),
    await bookmarksCard(),
    ...(FEATURES.device ? [await captionsCard(account)] : []).filter((c): c is HTMLElement => !!c),
    await accountCard(account),
    h(
      "div",
      { className: "card" },
      h("h2", {}, "More"),
      h(
        "div",
        { className: "row" },
        h(
          "button",
          { onClick: () => chrome.tabs.create({ url: "chrome://extensions/shortcuts" }) },
          "Keyboard shortcuts",
        ),
        h(
          "a",
          { href: "https://casama.ai/chrome/whats-new", target: "_blank", rel: "noopener" },
          "What's new",
        ),
        h(
          "a",
          { href: "https://docs.casama.ai/guide/chrome", target: "_blank", rel: "noopener" },
          "Help",
        ),
      ),
    ),
  );
  return wrap;
}

/** Settings#microphone: the side panel can't ask for the microphone, so this page asks once. */
export async function microphoneScreen(): Promise<HTMLElement> {
  const status = h(
    "p",
    { className: "muted", role: "status" },
    `${browserName()} will ask to use your microphone.`,
  );
  const card = h(
    "div",
    { className: "card", "data-testid": "microphone" },
    h("h1", {}, "Dictation"),
    status,
    h(
      "button",
      {
        className: "primary",
        onClick: async () => {
          try {
            const s = await navigator.mediaDevices.getUserMedia({ audio: true });
            for (const t of s.getTracks()) t.stop();
            status.textContent = "Done. Close this tab and use the Mic button in the panel.";
          } catch {
            status.textContent = `${browserName()} didn't allow it. Check the microphone setting for Casama in ${browserName()}'s site settings.`;
          }
        },
      },
      "Allow the microphone",
    ),
  );
  return card;
}
