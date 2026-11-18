/**
 * "Your browser" in the panel's More tab (D-323 C1, C4, C5, C11): pair this browser and pick which
 * bots may use it, watch what a bot is doing here with Stop and Hand back, answer its questions,
 * teach a skill by doing it in a tab, and unpair.
 */
import type { Schemas } from "@casama/client";
import type { Ask } from "../background/act/ask.ts";
import type { ActStatus } from "../background/act/device.ts";
import type { TeachState } from "../background/act/teach.ts";
import { getManaged } from "../lib/act/managed.ts";
import { teachFailure } from "../lib/billing.ts";
import { h } from "../lib/dom.ts";
import { emptyState } from "../lib/look.ts";
import { activeTab } from "../lib/page.ts";
import { appUrl, type Here } from "../lib/workspace.ts";
import { errorBox, failureBox, message, T, toast } from "./shared.ts";

interface RunView {
  key: string;
  runId: string | null;
  bot: string;
  state: "working" | "paused" | "asking" | "stopped";
  stoppedBy: string | null;
  steps: Array<{ at: number; text: string }>;
}

type Reply<T = unknown> = { ok: true; result: T } | { ok: false; error: string };
async function act<T = unknown>(m: Record<string, unknown>): Promise<T> {
  const r = (await chrome.runtime.sendMessage(m)) as Reply<T> | undefined;
  if (!r) throw new Error("Casama's background didn't answer. Try again.");
  if (!r.ok) throw new Error(r.error);
  return r.result;
}

const session = async <T>(key: string) =>
  (await chrome.storage.session.get(key))[key] as T | undefined;

export class YourBrowser {
  readonly el = h("div", { "data-testid": "your-browser" });
  private here: Here;
  private bots: Schemas["Bot"][] = [];
  private live = h("div", { "data-testid": "act-live" });
  private asks = h("div", { "data-testid": "act-asks" });
  private teach = h("div", { "data-testid": "act-teach" });
  private onChange = (changes: Record<string, chrome.storage.StorageChange>, area: string) => {
    if (area === "session" && (changes.actRuns || changes.actAsks)) void this.renderLive();
    if (area === "session" && changes.actTeach) void this.renderTeach();
    if (area === "session" && changes.actStatus) void this.load();
  };

  constructor(here: Here) {
    this.here = here;
    chrome.storage.onChanged.addListener(this.onChange);
  }

  async load() {
    const { api, org } = this.here;
    try {
      if ((await getManaged()).ActDisabled) {
        this.el.replaceChildren(
          emptyState({
            mascot: "shy",
            compact: true,
            message: "Your administrator turned off bots in this browser.",
          }),
        );
        return;
      }
      this.bots = (
        await api.unwrap(
          api.GET("/v1/bots", { params: { query: { org_id: org.id } }, signal: T() }),
        )
      ).items;
      const status = await session<ActStatus>("actStatus");
      const device = status?.paired
        ? await act<Schemas["LocalDevice"] | null>({ type: "act:device" }).catch(() => null)
        : null;
      if (!status?.paired) return this.unpaired();
      this.paired(status, device);
    } catch (e) {
      this.el.replaceChildren(errorBox(e, () => void this.load()));
    }
  }

  private botChecks(selected: string[]) {
    return h(
      "div",
      { className: "checks", "data-testid": "act-bots" },
      ...this.bots.map((b) =>
        h(
          "label",
          { className: "check" },
          h("input", {
            type: "checkbox",
            value: b.id,
            checked: selected.includes(b.id),
            "data-testid": `act-bot-${b.id}`,
          }),
          ` ${b.name}`,
        ),
      ),
    );
  }

  private checked(box: HTMLElement) {
    return [...box.querySelectorAll<HTMLInputElement>("input[type=checkbox]")]
      .filter((i) => i.checked)
      .map((i) => i.value);
  }

  private unpaired() {
    const checks = this.botChecks([]);
    const pairBtn = h(
      "button",
      {
        className: "primary",
        "data-testid": "act-pair",
        onClick: async () => {
          const botIds = this.checked(checks);
          if (!botIds.length) return toast("Pick at least one bot.");
          pairBtn.disabled = true;
          try {
            await act({
              type: "act:pair",
              accountId: this.here.account.id,
              orgId: this.here.org.id,
              botIds,
            });
            toast("This browser is paired.");
            await this.load();
          } catch (e) {
            const m = message(e);
            toast(
              /act_off|doesn't let bots/.test(m)
                ? "Your workspace doesn't let bots use members' browsers."
                : m,
            );
          } finally {
            pairBtn.disabled = false;
          }
        },
      },
      "Let bots use this browser",
    );
    this.el.replaceChildren(
      h(
        "p",
        { className: "meta" },
        "Bots you pick can open pages and act in this browser, where you're already signed in. Each works in its own tab group and never sees your other tabs. Steps that send, buy, delete, publish, share or sign in ask you first. While a bot works, Chrome shows a bar saying Casama is debugging this browser; its Cancel stops the bot.",
      ),
      checks,
      h("div", { className: "row" }, pairBtn),
    );
  }

  private paired(status: ActStatus, device: Schemas["LocalDevice"] | null) {
    const checks = this.botChecks(device?.allowed_bot_ids ?? []);
    checks.addEventListener("change", async () => {
      try {
        await act({ type: "act:update", body: { allowed_bot_ids: this.checked(checks) } });
        toast("Saved.");
      } catch (e) {
        toast(message(e));
      }
    });
    const state = status.online ? "Connected" : status.error ? status.error : "Connecting…";
    this.el.replaceChildren(
      h(
        "p",
        { className: "meta", "data-testid": "act-status" },
        `This browser is paired · ${state}`,
      ),
      h("div", { className: "meta" }, "Bots that may use it"),
      checks,
      this.asks,
      this.live,
      h("div", { className: "section-title" }, "Teach a skill here"),
      this.teach,
      h(
        "div",
        { className: "row" },
        h(
          "button",
          {
            "data-testid": "act-unpair",
            onClick: async () => {
              await act({ type: "act:unpair" }).catch((e) => toast(message(e)));
              toast("Unpaired. Bots can't use this browser now.");
              await this.load();
            },
          },
          "Unpair this browser",
        ),
        h("button", { onClick: () => chrome.runtime.openOptionsPage() }, "Sites"),
      ),
    );
    void this.renderLive();
    void this.renderTeach();
  }

  private async renderLive() {
    const runs = (await session<RunView[]>("actRuns")) ?? [];
    const asks = (await session<Ask[]>("actAsks")) ?? [];
    this.asks.replaceChildren(
      ...asks.map((a) =>
        h(
          "div",
          { className: "item", "data-testid": "act-ask" },
          h("h3", {}, a.title),
          h("p", {}, a.detail),
          h(
            "div",
            { className: "row" },
            ...(a.kind === "site"
              ? ([
                  ["Allow this once", "once"],
                  ["Always allow", "always"],
                  ["Never", "never"],
                ] as const)
              : ([
                  ["Allow", "allow"],
                  ["Deny", "deny"],
                ] as const)
            ).map(([label, answer]) =>
              h(
                "button",
                { onClick: () => void act({ type: "act:answer", id: a.id, answer }) },
                label,
              ),
            ),
          ),
        ),
      ),
    );
    this.live.replaceChildren(
      ...runs.slice(-5).map((r) => {
        const card = h(
          "div",
          { className: "item", "data-testid": "act-run" },
          h("h3", {}, r.bot),
          h(
            "div",
            { className: "meta", "data-testid": "act-run-state" },
            r.state === "working"
              ? "Working in this browser"
              : r.state === "paused"
                ? "You took over"
                : r.state === "asking"
                  ? "Waiting for you"
                  : "Stopped",
          ),
          h("ol", { className: "steps" }, ...r.steps.slice(-8).map((s) => h("li", {}, s.text))),
        );
        if (r.state !== "stopped")
          card.append(
            h(
              "div",
              { className: "row" },
              h(
                "button",
                {
                  "data-testid": "act-stop",
                  onClick: () => void act({ type: "act:stop", key: r.key }),
                },
                "Stop",
              ),
              r.state === "paused"
                ? h(
                    "button",
                    {
                      "data-testid": "act-handback",
                      onClick: () => void act({ type: "act:handback", key: r.key }),
                    },
                    "Hand back",
                  )
                : "",
            ),
          );
        return card;
      }),
    );
  }

  private async renderTeach() {
    const t = await session<TeachState | null>("actTeach");
    if (t?.status === "recording") {
      this.teach.replaceChildren(
        h(
          "p",
          { className: "meta", "data-testid": "teach-recording" },
          `Recording · ${t.steps} step${t.steps === 1 ? "" : "s"}. Do the task in the tab; passwords are never recorded.`,
        ),
        h(
          "div",
          { className: "row" },
          h(
            "button",
            {
              className: "primary",
              "data-testid": "teach-stop",
              onClick: () => void act({ type: "act:teach-stop" }).catch((e) => toast(message(e))),
            },
            "Stop recording",
          ),
        ),
      );
      return;
    }
    if (t?.status === "stopped") return this.draft(t);
    const select = h(
      "select",
      { "aria-label": "Bot to teach", "data-testid": "teach-bot" },
      ...this.bots.map((b) => h("option", { value: b.id }, b.name)),
    ) as HTMLSelectElement;
    this.teach.replaceChildren(
      h(
        "p",
        { className: "meta" },
        "Do a task once in the tab you're on, and Casama turns it into a skill the bot can repeat here.",
      ),
      h(
        "div",
        { className: "row" },
        select,
        h(
          "button",
          {
            "data-testid": "teach-start",
            onClick: async () => {
              const tab = await activeTab();
              if (!tab?.id) return toast("Open the page to start on first.");
              try {
                await act({ type: "act:teach-start", tabId: tab.id, botId: select.value });
              } catch (e) {
                toast(message(e));
              }
            },
          },
          "Teach in this tab",
        ),
      ),
    );
  }

  private async draft(t: TeachState) {
    const { api, account } = this.here;
    this.teach.replaceChildren(
      h("p", { className: "meta", "data-testid": "teach-drafting" }, "Writing the skill…"),
    );
    let last: { error_code?: string | null; error_message?: string | null } | null = null;
    for (let i = 0; i < 60; i++) {
      const s = await api
        .unwrap(api.GET("/v1/teach/{id}", { params: { path: { id: t.sessionId } }, signal: T() }))
        .catch(() => null);
      if (s?.status === "drafted" && s.draft) {
        const d = s.draft;
        this.teach.replaceChildren(
          h(
            "div",
            { className: "item", "data-testid": "teach-draft" },
            h("h3", {}, d.name),
            h("p", {}, d.description),
            h("div", { className: "meta" }, `${s.steps.length} steps`),
          ),
          h(
            "div",
            { className: "row" },
            h(
              "button",
              {
                className: "primary",
                "data-testid": "teach-save",
                onClick: async () => {
                  try {
                    await api.unwrap(
                      api.POST("/v1/teach/{id}/save", {
                        params: { path: { id: t.sessionId } },
                        body: { name: d.name, description: d.description, body: d.body },
                      }),
                    );
                    toast(`Saved the skill "${d.name}".`);
                    await chrome.storage.session.set({ actTeach: null });
                  } catch (e) {
                    toast(message(e));
                  }
                },
              },
              "Save skill",
            ),
            h(
              "a",
              {
                href: appUrl(account, `/bots/${t.botId}/skills`),
                target: "_blank",
                rel: "noopener",
              },
              "Edit in Casama",
            ),
            h(
              "button",
              {
                className: "link",
                onClick: () => void chrome.storage.session.set({ actTeach: null }),
              },
              "Discard",
            ),
          ),
        );
        return;
      }
      if (s && ["failed", "cancelled", "saved"].includes(s.status)) {
        last = s;
        break;
      }
      await new Promise((r) => setTimeout(r, 2000));
    }
    // Why it failed, from the server (D-334), with See plans for credit and plan refusals.
    const why = teachFailure(last);
    this.teach.replaceChildren(
      failureBox(why.text, why.code, "teach-failed"),
      h(
        "button",
        { className: "link", onClick: () => void chrome.storage.session.set({ actTeach: null }) },
        "Start over",
      ),
    );
  }
}
