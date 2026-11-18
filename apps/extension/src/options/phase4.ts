/**
 * Settings for Phase 4 (D-323 E2–E7, B11, F3): this browser as a device, each kind opt-in and
 * asking Chrome for its permission only when switched on; bringing bookmarks in as knowledge; and
 * meeting captions, when the server turns that feature on.
 */

import type { BrowserDevice, BrowserDevicePatch } from "../background/device/index.ts";
import { browserName, FEATURES, IS_FIREFOX } from "../lib/browser.ts";
import { h } from "../lib/dom.ts";
import { botIsPrivate } from "../lib/private-model.ts";
import { flag, remoteConfig } from "../lib/remote-config.ts";
import { getSettings, updateSettings } from "../lib/settings.ts";
import type { Account } from "../lib/store.ts";
import { appUrl, here } from "../lib/workspace.ts";

type Reply<T> = { ok: true; result: T } | { ok: false; error: string };
async function send<T>(m: Record<string, unknown>): Promise<T> {
  const r = (await chrome.runtime.sendMessage(m)) as Reply<T> | undefined;
  if (!r) throw new Error("Casama's background didn't answer.");
  if (!r.ok) throw new Error(r.error);
  return r.result;
}

type Perm = chrome.runtime.ManifestOptionalPermission;

const KINDS: Array<{
  key: keyof BrowserDevicePatch;
  label: string;
  detail: string;
  perms: Perm[];
}> = [
  {
    key: "tab",
    label: "Share the tab in front when a bot you allow asks",
    detail:
      'For "what am I looking at?" from your phone or a chat app: the address, title, your selection and the page\'s text (with site access). Read only when asked; never stored.',
    perms: ["tabs"],
  },
  {
    key: "history",
    label: "Let bots you allow search your history and bookmarks",
    detail: 'For "the article I read last week". Only pages matching the search go; never stored.',
    perms: ["history", "bookmarks"],
  },
  {
    key: "triggers",
    label: "Start your routines from this browser",
    detail:
      "When you open a site a routine names, a download finishes, or you add a bookmark. Only those events are sent, and only when a routine of yours starts on them. Banking, health, password manager and government ID sites never start routines.",
    perms: ["tabs", "downloads", "bookmarks"],
  },
  {
    key: "activity",
    label: "Activity recap",
    detail:
      "Minutes per site, per hour (site names only, never pages or titles), for end-of-day recaps. Kept 30 days.",
    perms: ["tabs", "idle"],
  },
];

/** This browser as a device: the kinds, the private model rule, and where to pick bots. */
export async function deviceCard(account: Account): Promise<HTMLElement> {
  const card = h(
    "div",
    { className: "card", "data-testid": "device-card" },
    h("h2", {}, "This browser as a device"),
  );
  const status = h("p", { className: "muted", role: "status", "data-testid": "device-status" });
  const got = await send<{ device: BrowserDevice | null; listening: boolean }>({
    type: "device:get",
  }).catch(() => ({ device: null, listening: false }));
  const d = got.device;
  const set = async (patch: BrowserDevicePatch) => {
    status.textContent = "Saving…";
    try {
      await send({ type: "device:set", patch });
      status.textContent = "Saved.";
      card.replaceWith(await deviceCard(account));
    } catch (e) {
      status.textContent = (e as Error).message;
    }
  };
  for (const k of KINDS) {
    const box = h("input", {
      type: "checkbox",
      checked: !!d?.[k.key],
      "data-testid": `device-${k.key}`,
    }) as HTMLInputElement;
    box.addEventListener("change", async () => {
      if (box.checked && k.perms.length) {
        // The browser asks now, while this click counts as the person's.
        const ok = await chrome.permissions.request({ permissions: k.perms }).catch(() => false);
        if (!ok) {
          box.checked = false;
          status.textContent = `${browserName()} didn't give the permission, so it stays off.`;
          return;
        }
      }
      await set({ [k.key]: box.checked });
    });
    card.append(
      h(
        "label",
        { className: "choice" },
        box,
        h(
          "span",
          {},
          h("strong", {}, k.label),
          h("br"),
          h("span", { className: "muted" }, k.detail),
        ),
      ),
    );
  }
  const priv = h("input", {
    type: "checkbox",
    checked: !!d?.privateModel,
    "data-testid": "device-private",
  }) as HTMLInputElement;
  priv.addEventListener("change", () => void set({ privateModel: priv.checked }));
  card.append(
    h(
      "label",
      { className: "choice" },
      priv,
      h(
        "span",
        {},
        h("strong", {}, "Private models only"),
        h("br"),
        h(
          "span",
          { className: "muted" },
          "What this browser shares, and page content you send from the panel, goes only to bots whose models all run privately. Otherwise the browser's built-in model answers on this computer where it can, or nothing is sent.",
        ),
      ),
    ),
    h(
      "p",
      { className: "muted" },
      "Pick which bots may ask in Casama, under Settings, Device connections. ",
      h(
        "a",
        { href: appUrl(account, "/settings/devices"), target: "_blank", rel: "noopener" },
        "Open Device connections",
      ),
    ),
    ...(d && (d.tab || d.history)
      ? [
          h(
            "p",
            { className: "muted", "data-testid": "device-listening" },
            got.listening ? "Listening for bots' requests." : "Connecting…",
          ),
        ]
      : []),
    status,
  );
  return card;
}

/** B11: bookmarks (and the reading list) into a bot's or the workspace's knowledge, once. */
export async function bookmarksCard(): Promise<HTMLElement> {
  const card = h(
    "div",
    { className: "card", "data-testid": "bookmarks-card" },
    h("h2", {}, "Bring in your bookmarks"),
    h(
      "p",
      { className: "muted" },
      "Your bookmarks and reading list go to a bot's knowledge as one list of titles and addresses, once. Nothing is synced after that. Pages the guard keeps out are left out.",
    ),
  );
  const w = await here().catch(() => null);
  if (!w) return card;
  const bots = (
    await w.api.unwrap(w.api.GET("/v1/bots", { params: { query: { org_id: w.org.id } } }))
  ).items;
  const select = h(
    "select",
    { "aria-label": "Bot", "data-testid": "bookmarks-bot" },
    ...bots.map((b) => h("option", { value: b.id }, b.name)),
  ) as HTMLSelectElement;
  const reading = h("input", {
    type: "checkbox",
    checked: FEATURES.readingList,
    "data-testid": "bookmarks-reading",
  }) as HTMLInputElement;
  const status = h("p", { className: "muted", role: "status", "data-testid": "bookmarks-status" });
  const go = h(
    "button",
    {
      className: "primary",
      "data-testid": "bookmarks-go",
      onClick: async () => {
        const perms: Perm[] = reading.checked ? ["bookmarks", "readingList"] : ["bookmarks"];
        // Firefox also asks the person's consent to send bookmarks (its data consent, Phase 5).
        const ok = await chrome.permissions
          .request({
            permissions: perms,
            ...(IS_FIREFOX ? { data_collection: ["bookmarksInfo"] } : {}),
          } as chrome.permissions.Permissions)
          .catch(() => false);
        if (!ok) {
          status.textContent = `${browserName()} didn't give the permission.`;
          return;
        }
        go.disabled = true;
        status.textContent = "Bringing them in…";
        try {
          // F3: kept to private models, bookmarks go only to a bot on them.
          const rule = !!(
            (await chrome.storage.local.get("browserDevice")).browserDevice as
              | { privateModel?: boolean }
              | undefined
          )?.privateModel;
          if (rule && !(await botIsPrivate(w.api, select.value).catch(() => false))) {
            status.textContent =
              "You keep this browser's content to private models, and this bot uses a hosted model.";
            return;
          }
          const { bookmarksMarkdown } = await import("../lib/device/bookmarks.ts");
          const md = await bookmarksMarkdown(reading.checked);
          if (!md.count) {
            status.textContent = "There are no bookmarks to bring in.";
            return;
          }
          const bytes = new TextEncoder().encode(md.text);
          let bin = "";
          for (const b of bytes) bin += String.fromCharCode(b);
          await w.api.unwrap(
            w.api.POST("/v1/knowledge-sources", {
              body: {
                org_id: w.org.id,
                bot_id: select.value,
                kind: "upload",
                name: `Bookmarks from ${browserName()}`,
                files: [{ name: "bookmarks.md", content_base64: btoa(bin) }],
              },
            }),
          );
          status.textContent = `Brought in ${md.count} bookmark${md.count === 1 ? "" : "s"}.`;
        } catch (e) {
          status.textContent = (e as Error).message;
        } finally {
          go.disabled = false;
        }
      },
    },
    "Bring in bookmarks",
  ) as HTMLButtonElement;
  card.append(
    h("div", { className: "row" }, select, go),
    ...(FEATURES.readingList
      ? [h("label", { className: "choice" }, reading, h("span", {}, "Include the reading list"))]
      : []),
    status,
  );
  return card;
}

/** E7: meeting captions, behind the server's flag and off until the person turns it on. */
export async function captionsCard(account: Account): Promise<HTMLElement | null> {
  const config = await remoteConfig(account.server).catch(() => null);
  if (!config || !flag(config, "chrome_meeting_captions", false)) return null;
  const s = await getSettings();
  const box = h("input", {
    type: "checkbox",
    checked: s.meetingCaptions,
    "data-testid": "captions-switch",
  }) as HTMLInputElement;
  const status = h("p", { className: "muted", role: "status" });
  box.addEventListener("change", async () => {
    if (box.checked) {
      const ok = await chrome.permissions
        .request({ origins: ["https://meet.google.com/*"] })
        .catch(() => false);
      if (!ok) {
        box.checked = false;
        status.textContent = `${browserName()} didn't give access to Google Meet, so it stays off.`;
        return;
      }
    }
    await updateSettings((x) => {
      x.meetingCaptions = box.checked;
    });
    status.textContent = "Saved.";
  });
  return h(
    "div",
    { className: "card", "data-testid": "captions-card" },
    h("h2", {}, "Meeting notes from captions"),
    h(
      "label",
      { className: "choice" },
      box,
      h(
        "span",
        {},
        "On a Google Meet call, start it from Casama's panel: a banner tells everyone in your view that notes are being taken, and the captions go to a bot as a transcript when you stop. Turn on captions in Meet first.",
      ),
    ),
    status,
  );
}
