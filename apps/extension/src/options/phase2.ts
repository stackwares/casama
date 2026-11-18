/**
 * Settings for Phase 2: what shows on pages (the selection bar, the write button, site helpers,
 * highlights), sending less of long pages, and page commands for the "/" menu (A13).
 */
import { HELPER_LABELS, HELPERS } from "../content/protocol.ts";
import { h } from "../lib/dom.ts";
import { clientFor } from "../lib/session.ts";
import { getSettings, updateSettings } from "../lib/settings.ts";
import type { Account } from "../lib/store.ts";

const T = () => AbortSignal.timeout(15_000);

function toggle(
  label: string,
  testid: string,
  checked: boolean,
  set: (on: boolean) => void,
  note?: string,
) {
  return h(
    "label",
    { className: "choice" },
    h("input", {
      type: "checkbox",
      checked,
      "data-testid": testid,
      onChange: (e: Event) => set((e.target as HTMLInputElement).checked),
    }),
    h(
      "span",
      {},
      label,
      note ? h("span", { className: "muted", style: "display:block;font-size:12px" }, note) : "",
    ),
  );
}

export async function onPagesCard(): Promise<HTMLElement> {
  const s = await getSettings();
  const misses = ((await chrome.storage.session.get("helperMisses")).helperMisses ?? {}) as Record<
    string,
    number
  >;
  const card = h(
    "div",
    { className: "card", "data-testid": "on-pages" },
    h("h2", {}, "On pages"),
    h(
      "p",
      { className: "muted" },
      s.siteAccess === "click"
        ? 'These need site access (on all sites, or on sites you pick) above. With "When you click", they stay off.'
        : "Only on the sites Casama has access to. They read nothing until you tap them.",
    ),
    toggle(
      "A bar beside text you select",
      "opt-selection-bar",
      s.selectionBar,
      (on) =>
        void updateSettings((x) => {
          x.selectionBar = on;
        }),
      "Ask, explain, summarize, translate, highlight, and your page commands.",
    ),
    toggle(
      "A write button in text boxes",
      "opt-write-box",
      s.writeBox,
      (on) =>
        void updateSettings((x) => {
          x.writeBox = on;
        }),
      "Draft, rewrite, shorten or reply in your voice; the text is put in for you to send.",
    ),
    toggle(
      "Show my highlights again",
      "opt-highlights",
      s.highlights,
      (on) =>
        void updateSettings((x) => {
          x.highlights = on;
        }),
    ),
    h("h3", { style: "margin:16px 0 4px;font-size:14px" }, "Site helpers"),
    ...HELPERS.map((n) =>
      toggle(
        HELPER_LABELS[n],
        `opt-helper-${n}`,
        s.helpers[n],
        (on) =>
          void updateSettings((x) => {
            x.helpers[n] = on;
          }),
        misses[n]
          ? `Hidden ${misses[n]} time${misses[n] === 1 ? "" : "s"} today because the site changed.`
          : undefined,
      ),
    ),
    h("h3", { style: "margin:16px 0 4px;font-size:14px" }, "Long pages"),
    toggle(
      "Send less of long pages",
      "opt-send-less",
      s.sendLess,
      (on) =>
        void updateSettings((x) => {
          x.sendLess = on;
        }),
      "Cuts a long page down to the parts that match your question, on this computer, before it's sent. Saves credits.",
    ),
  );
  return card;
}

/** A13: saved prompts for the "/" menu, kept in the account (every browser sees them). */
export async function pageCommandsCard(account: Account): Promise<HTMLElement> {
  const api = clientFor(account);
  const list = h("ul", { className: "bots", "data-testid": "page-commands" });
  const note = h("p", { className: "muted", role: "status" });
  const name = h("input", {
    placeholder: "Name, e.g. tldr",
    maxLength: 60,
    "aria-label": "Command name",
    "data-testid": "command-name",
  }) as HTMLInputElement;
  const prompt = h("textarea", {
    placeholder: "What to ask, e.g. Summarize this page for my team in three bullets.",
    maxLength: 4000,
    "aria-label": "Command prompt",
    "data-testid": "command-prompt",
  }) as HTMLTextAreaElement;
  const draw = async () => {
    try {
      const r = await api.unwrap(api.GET("/v1/me/page-commands", { signal: T() }));
      list.replaceChildren(
        ...(r.items.length
          ? r.items.map((c) =>
              h(
                "li",
                { "data-testid": "page-command" },
                h("strong", {}, `/${c.name}`),
                h("span", { className: "muted" }, ` ${c.prompt.slice(0, 80)}`),
                h(
                  "button",
                  {
                    className: "link",
                    "data-testid": "delete-command",
                    onClick: async () => {
                      await api.unwrap(
                        api.DELETE("/v1/me/page-commands/{id}", {
                          params: { path: { id: c.id } },
                          signal: T(),
                        }),
                      );
                      await chrome.storage.session.remove("pageCommands");
                      await draw();
                    },
                  },
                  "Delete",
                ),
              ),
            )
          : [h("li", { className: "muted" }, "None yet.")]),
      );
    } catch (e) {
      note.textContent = (e as Error).message;
    }
  };
  const form = h(
    "form",
    {},
    name,
    prompt,
    h("button", { type: "submit", className: "primary", "data-testid": "add-command" }, "Add"),
  );
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const n = name.value.trim().replace(/^\//, "");
    if (!n || !prompt.value.trim()) return;
    try {
      await api.unwrap(
        api.POST("/v1/me/page-commands", {
          body: { name: n, prompt: prompt.value.trim() },
          signal: T(),
        }),
      );
      name.value = "";
      prompt.value = "";
      note.textContent = "";
      await chrome.storage.session.remove("pageCommands");
      await draw();
    } catch (err) {
      note.textContent = (err as Error).message;
    }
  });
  void draw();
  return h(
    "div",
    { className: "card", id: "page-commands", "data-testid": "page-commands-card" },
    h("h2", {}, "Page commands"),
    h(
      "p",
      { className: "muted" },
      "Type / in the panel to use one. They're kept in your account, so every browser has them.",
    ),
    list,
    form,
    note,
  );
}
