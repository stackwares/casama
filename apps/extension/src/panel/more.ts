/**
 * The More tab: things to do with this page (Phase 2: translate, read aloud, watch, read later,
 * send these tabs), search (D4), routines with Run now and Pause (D6), usage (D7), settings.
 */

import { FEATURES, IS_FIREFOX, shortcutsUrl } from "../lib/browser.ts";
import {
  type CaptionsState,
  captionsState,
  isMeetCall,
  NOTICE,
  startCaptions,
  stopCaptions,
  transcript,
} from "../lib/captions.ts";
import { h } from "../lib/dom.ts";
import { LiveView, popOutLiveView } from "../lib/live-view.ts";
import { emptyState } from "../lib/look.ts";
import { activeTab } from "../lib/page.ts";
import { flag, remoteConfig } from "../lib/remote-config.ts";
import { getSettings } from "../lib/settings.ts";
import { ensureTabs, SET_MAX, tabBlock, tabChoices } from "../lib/tabs.ts";
import { appUrl, type Here } from "../lib/workspace.ts";
import { readPageAloud, translateHere } from "./page-tools.ts";
import { ago, errorBox, message, T, toast } from "./shared.ts";
import { YourBrowser } from "./your-browser.ts";

export class MoreView {
  readonly el = h("section", { className: "view", "data-testid": "more" });
  private here: Here;
  /** Hooks into the Chat tab, set by the panel. */
  hooks: {
    pageAction: (action: "watch" | "read-later") => Promise<void>;
    addTab: (label: string, text: string) => void;
    ask: (text: string, readText: boolean) => Promise<void>;
  } | null = null;
  private yours: YourBrowser;
  private watching: LiveView | null = null;
  constructor(here: Here) {
    this.here = here;
    this.yours = new YourBrowser(here);
  }

  private pageTools() {
    const b = (label: string, testid: string, run: () => Promise<void>) =>
      h(
        "button",
        {
          "data-testid": testid,
          onClick: async (e: Event) => {
            const el = e.currentTarget as HTMLButtonElement;
            el.disabled = true;
            try {
              await run();
            } catch (err) {
              toast(message(err));
            } finally {
              el.disabled = false;
            }
          },
        },
        label,
      );
    const tab = async () => {
      const t = await activeTab();
      if (!t) throw new Error("No tab open.");
      return t;
    };
    return h(
      "div",
      { className: "row wrap", style: "margin-top:0", "data-testid": "page-tools" },
      b("Translate the page", "translate-page", async () => {
        const t = await tab();
        const r = await translateHere(t);
        if (r === "same") toast("The page is already in your language.");
        else if (r) toast("Translated on this computer.");
        // This computer can't: the bot translates it in the chat.
        else await this.hooks?.ask("Translate this page into my language.", true);
      }),
      b("Read the page aloud", "read-page", async () => {
        const on = await readPageAloud(await tab());
        toast(on ? "Reading aloud. Tap again to stop." : "Stopped.");
      }),
      b("Watch part of this page", "watch-page", async () => this.hooks?.pageAction("watch")),
      b("Read it for me later", "read-later", async () => this.hooks?.pageAction("read-later")),
      b("Send these tabs", "send-tabs", async () => {
        if (!(await ensureTabs())) throw new Error("Casama needs to see your tabs to send them.");
        const active = await tab();
        const choices = await tabChoices();
        // The tab group the page in view is in, else every tab in this window.
        const group =
          active.groupId !== undefined && active.groupId >= 0
            ? choices.find((c) => c.kind === "group" && c.tabs.some((x) => x.id === active.id))
                ?.tabs
            : undefined;
        const tabs = (
          group ?? choices.filter((c) => c.kind === "tab").flatMap((c) => c.tabs)
        ).slice(0, SET_MAX);
        let added = 0;
        for (const t of tabs) {
          const block = await tabBlock(t, 6000);
          if (!block.skipped) {
            this.hooks?.addTab(block.label, block.text);
            added++;
          }
        }
        toast(
          added
            ? `${added} tab${added === 1 ? "" : "s"} added to your next message.`
            : "None of these tabs can be sent.",
        );
      }),
    );
  }

  async load() {
    const q = h("input", {
      type: "search",
      placeholder: "Search Casama",
      "aria-label": "Search Casama",
      "data-testid": "search-input",
    }) as HTMLInputElement;
    const results = h("div", { "data-testid": "search-results" });
    const form = h("form", {}, q);
    form.addEventListener("submit", (e) => {
      e.preventDefault();
      void this.search(q.value, results);
    });
    const routines = h(
      "div",
      { "data-testid": "routines" },
      h("p", { className: "empty" }, "Loading…"),
    );
    const usage = h("div", { "data-testid": "usage" });
    const computers = h("div", { "data-testid": "computers" });
    const captions = h("div", { "data-testid": "captions" });
    this.el.replaceChildren(
      h("div", { className: "section-title" }, "This page"),
      this.pageTools(),
      captions,
      form,
      results,
      h("div", { className: "section-title" }, "Routines"),
      routines,
      h("div", { className: "section-title" }, "Live view"),
      computers,
      h("div", { className: "section-title" }, "Usage this month"),
      usage,
      ...(FEATURES.act
        ? [h("div", { className: "section-title" }, "Your browser"), this.yours.el]
        : []),
      h("div", { className: "section-title" }, "This browser"),
      h(
        "div",
        { className: "row", style: "margin-top:0" },
        h(
          "button",
          { "data-testid": "open-settings", onClick: () => chrome.runtime.openOptionsPage() },
          "Settings",
        ),
        h(
          "button",
          { "data-testid": "open-shortcuts", onClick: () => void openShortcuts() },
          "Keyboard shortcuts",
        ),
      ),
    );
    await Promise.all([
      this.routines(routines),
      this.computers(computers),
      FEATURES.device ? this.captions(captions) : undefined,
      this.usage(usage),
      FEATURES.act ? this.yours.load() : undefined,
    ]);
  }

  private async search(text: string, el: HTMLElement) {
    if (!text.trim()) return;
    const { api, org, account } = this.here;
    el.replaceChildren(h("p", { className: "empty" }, "Searching…"));
    try {
      const r = await api.unwrap(
        api.GET("/v1/search", {
          params: { query: { org_id: org.id, q: text.trim() } },
          signal: T(),
        }),
      );
      el.replaceChildren(
        ...(r.items.length
          ? r.items.slice(0, 20).map((it) =>
              h(
                "div",
                { className: "item", "data-testid": "search-result" },
                h(
                  "h3",
                  {},
                  h(
                    "a",
                    {
                      href: appUrl(
                        account,
                        it.bot_id
                          ? `/bots/${it.bot_id}/chat${it.conversation_id ? `?c=${it.conversation_id}` : ""}`
                          : "/search",
                      ),
                      target: "_blank",
                      rel: "noopener",
                    },
                    it.title || it.kind,
                  ),
                ),
                h("div", { className: "meta" }, `${it.kind} · ${ago(it.created_at)}`),
                it.snippet ? h("p", {}, it.snippet.slice(0, 240)) : "",
              ),
            )
          : [emptyState({ mascot: "thinker", compact: true, message: "Nothing found." })]),
      );
    } catch (e) {
      el.replaceChildren(errorBox(e));
    }
  }

  private async routines(el: HTMLElement) {
    const { api, org } = this.here;
    try {
      const bots = (
        await api.unwrap(
          api.GET("/v1/bots", { params: { query: { org_id: org.id } }, signal: T() }),
        )
      ).items;
      const lists = await Promise.all(
        bots.map((b) =>
          api
            .unwrap(
              api.GET("/v1/bots/{id}/routines", { params: { path: { id: b.id } }, signal: T() }),
            )
            .then((r) => r.items.map((x) => ({ ...x, botName: b.name })))
            .catch(() => []),
        ),
      );
      const all = lists.flat();
      el.replaceChildren(
        ...(all.length
          ? all.map((r) => {
              const card = h(
                "div",
                { className: "item", "data-testid": "routine" },
                h("h3", {}, r.name),
                h(
                  "div",
                  { className: "meta" },
                  `${r.botName} · ${r.enabled ? (r.next_run_at ? `next ${new Date(r.next_run_at).toLocaleString("en-US", { weekday: "short", hour: "numeric", minute: "2-digit" })}` : "on") : "paused"}`,
                ),
              );
              card.append(
                h(
                  "div",
                  { className: "row" },
                  h(
                    "button",
                    {
                      onClick: async () => {
                        try {
                          await api.unwrap(
                            api.POST("/v1/routines/{id}/run", {
                              params: { path: { id: r.id } },
                              signal: T(),
                            }),
                          );
                          toast(`${r.name} is running.`);
                        } catch (e) {
                          toast(message(e));
                        }
                      },
                    },
                    "Run now",
                  ),
                  h(
                    "button",
                    {
                      onClick: async () => {
                        try {
                          await api.unwrap(
                            api.PATCH("/v1/routines/{id}", {
                              params: { path: { id: r.id } },
                              body: { enabled: !r.enabled },
                              signal: T(),
                            }),
                          );
                          await this.routines(el);
                        } catch (e) {
                          toast(message(e));
                        }
                      },
                    },
                    r.enabled ? "Pause" : "Resume",
                  ),
                ),
              );
              return card;
            })
          : [emptyState({ mascot: "sleepy", compact: true, message: "No routines yet." })]),
      );
    } catch (e) {
      el.replaceChildren(errorBox(e, () => void this.routines(el)));
    }
  }

  /** E7: meeting notes from Meet's captions, when the person turned it on and is on a call. */
  async captions(el: HTMLElement) {
    el.replaceChildren();
    if (!(await getSettings()).meetingCaptions) return;
    // The server's switch is checked here too, so turning it off takes effect at once.
    const config = await remoteConfig(this.here.account.server).catch(() => null);
    if (!config || !flag(config, "chrome_meeting_captions", false)) return;
    const tab = await activeTab();
    if (!tab?.id || !isMeetCall(tab.url)) return;
    const tabId = tab.id;
    const run = async <T>(func: (...a: never[]) => T, args: unknown[] = []): Promise<T> => {
      const [r] = await chrome.scripting.executeScript({
        target: { tabId },
        func: func as () => T,
        args: args as [],
      });
      return r?.result as T;
    };
    const state = await run<CaptionsState>(captionsState).catch(() => null);
    if (!state) {
      el.replaceChildren(
        emptyState({
          mascot: "shy",
          compact: true,
          message: "Casama can't reach Google Meet. Turn meeting notes on again in Settings.",
        }),
      );
      return;
    }
    const status = h("p", { className: "meta", "data-testid": "captions-status" });
    if (!state.running) {
      const told = h("input", {
        type: "checkbox",
        "data-testid": "captions-told",
      }) as HTMLInputElement;
      const start = h(
        "button",
        {
          className: "primary",
          disabled: true,
          "data-testid": "captions-start",
          onClick: async () => {
            const s = await run<CaptionsState>(startCaptions, [
              "Casama is taking notes from the captions",
            ]);
            if (!s.found) toast("Turn on captions in Meet (the CC button): notes come from them.");
            await this.captions(el);
          },
        },
        "Take notes from captions",
      ) as HTMLButtonElement;
      told.addEventListener("change", () => {
        start.disabled = !told.checked;
      });
      el.replaceChildren(
        h(
          "div",
          { className: "item", "data-testid": "captions-consent" },
          h("h3", {}, "Meeting notes"),
          h(
            "p",
            {},
            "This collects what Meet's captions show, everyone's words, until you stop. A banner shows on your screen while it runs. Recording what others say can need their consent where you are: tell them first.",
          ),
          h(
            "div",
            { className: "row" },
            h(
              "button",
              {
                onClick: async () => {
                  await navigator.clipboard.writeText(NOTICE).catch(() => {});
                  toast("Copied. Paste it in the Meet chat.");
                },
              },
              "Copy a note for the chat",
            ),
          ),
          h(
            "label",
            { className: "choice" },
            told,
            h("span", {}, "I've told the others on the call"),
          ),
          h("div", { className: "row" }, start),
        ),
      );
      return;
    }
    status.textContent = `${state.lines} caption line${state.lines === 1 ? "" : "s"} so far.${state.found ? "" : " Captions are off in Meet."}`;
    el.replaceChildren(
      h(
        "div",
        { className: "item" },
        h("h3", {}, "Taking notes from captions"),
        status,
        h(
          "div",
          { className: "row" },
          h(
            "button",
            {
              className: "primary",
              "data-testid": "captions-stop",
              onClick: async () => {
                const r = await run<{
                  lines: { speaker: string; text: string; at: number }[];
                  title: string;
                }>(stopCaptions);
                await this.captions(el);
                if (!r.lines.length) return toast("No captions were collected.");
                this.hooks?.addTab(
                  `Transcript: ${r.title || "Meet call"}`,
                  transcript(r.lines, r.title),
                );
                await this.hooks?.ask(
                  "Write meeting notes from this transcript: a short summary, decisions, action items with owners, and open questions.",
                  false,
                );
              },
            },
            "Stop and write notes",
          ),
          h(
            "button",
            {
              "data-testid": "captions-discard",
              onClick: async () => {
                await run(stopCaptions);
                toast("Stopped. Nothing was sent.");
                await this.captions(el);
              },
            },
            "Stop without sending",
          ),
        ),
      ),
    );
  }

  /** D10: bots' cloud computers that are on, each with a live view here or in its own window. */
  private async computers(el: HTMLElement) {
    const { api, org, account } = this.here;
    this.watching?.stop();
    this.watching = null;
    try {
      const list = (
        await api.unwrap(
          api.GET("/v1/computers", { params: { query: { org_id: org.id } }, signal: T() }),
        )
      ).items.filter((c) => c.kind !== "local" && (c.state === "running" || c.state === "idle"));
      if (!list.length) {
        el.replaceChildren(
          emptyState({ mascot: "sleepy", compact: true, message: "No computer is on right now." }),
        );
        return;
      }
      const viewer = h("div", { "data-testid": "live-view" });
      el.replaceChildren(
        ...list.map((c) =>
          h(
            "div",
            { className: "item", "data-testid": "computer" },
            h("h3", {}, c.name),
            h("div", { className: "meta" }, `${c.profile} · ${c.state}`),
            h(
              "div",
              { className: "row" },
              h(
                "button",
                {
                  "data-testid": "watch-computer",
                  onClick: () => void this.watch(c.id, c.name, viewer),
                },
                "Watch",
              ),
              h(
                "button",
                {
                  onClick: () => void popOutLiveView(c.id, c.name).catch((e) => toast(message(e))),
                },
                "Pop out",
              ),
              h(
                "a",
                {
                  href: appUrl(account, `/computer/live?c=${c.id}`),
                  target: "_blank",
                  rel: "noopener",
                },
                "Take over in Casama",
              ),
            ),
          ),
        ),
        viewer,
      );
    } catch (e) {
      el.replaceChildren(errorBox(e, () => void this.computers(el)));
    }
  }

  private async watch(id: string, name: string, viewer: HTMLElement) {
    this.watching?.stop();
    const status = h("span", { className: "meta", "data-testid": "live-status" }, "Connecting…");
    const img = h("img", {
      alt: `${name}'s screen`,
      style: "width:100%;border-radius:6px;display:block",
      "data-testid": "live-img",
    }) as HTMLImageElement;
    viewer.replaceChildren(
      h(
        "div",
        { className: "item" },
        h(
          "div",
          { className: "row", style: "margin-top:0" },
          h("strong", {}, name),
          status,
          h(
            "button",
            {
              onClick: () => {
                this.watching?.stop();
                this.watching = null;
                viewer.replaceChildren();
              },
            },
            "Stop watching",
          ),
        ),
        img,
      ),
    );
    const view = new LiveView({
      account: this.here.account,
      api: this.here.api,
      computerId: id,
      img,
      status: (t) => {
        status.textContent = t;
      },
    });
    this.watching = view;
    await view.start().catch((e) => {
      status.textContent = message(e);
    });
  }

  private async usage(el: HTMLElement) {
    const { api, org, account } = this.here;
    try {
      // The plan and credits left come from Billing, as in the app; usage's cost also counts
      // spend on the workspace's own keys, so it isn't a credit balance.
      const [u, b] = await Promise.all([
        api.unwrap(
          api.GET("/v1/usage", {
            params: { query: { org_id: org.id, period: "month" } },
            signal: T(),
          }),
        ),
        api
          .unwrap(
            api.GET("/v1/orgs/{id}/billing", { params: { path: { id: org.id } }, signal: T() }),
          )
          .catch(() => null),
      ]);
      const lines: string[] = [];
      if (b?.enabled) {
        lines.push(`${b.plan_name} · $${b.credits_usd.toFixed(2)} in credits left`);
        if (b.daily)
          lines.push(`Today: $${b.daily.used_usd.toFixed(2)} of $${b.daily.cap_usd.toFixed(2)}`);
      }
      lines.push(`${u.runs ?? 0} runs this month`);
      el.replaceChildren(
        ...lines.map((l) => h("p", {}, l)),
        h(
          "a",
          { href: appUrl(account, "/settings/billing"), target: "_blank", rel: "noopener" },
          "See plans",
        ),
      );
    } catch (e) {
      el.replaceChildren(errorBox(e));
    }
  }
}

/** The browser's keyboard shortcut settings. Firefox opens its own page (it won't open about:addons). */
async function openShortcuts() {
  const commands = chrome.commands as typeof chrome.commands & {
    openShortcutSettings?: () => Promise<void>;
  };
  if (IS_FIREFOX && commands.openShortcutSettings) return commands.openShortcutSettings();
  await chrome.tabs.create({ url: shortcutsUrl() });
}
