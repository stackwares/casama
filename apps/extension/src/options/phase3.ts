/**
 * Settings for Phase 3 (D-323 C6, G9): where bots may work in this browser. Sites they may use
 * without asking, sites they may never use, and the kinds of site that are off by default (banking,
 * health, password managers, government ID), which ask every time when switched back on.
 * An administrator's managed settings are shown and win.
 */
import type { Schemas } from "@casama/client";
import { getManaged } from "../lib/act/managed.ts";
import { h } from "../lib/dom.ts";

type Reply<T> = { ok: true; result: T } | { ok: false; error: string };
async function act<T>(m: Record<string, unknown>): Promise<T> {
  const r = (await chrome.runtime.sendMessage(m)) as Reply<T> | undefined;
  if (!r) throw new Error("Casama's background didn't answer.");
  if (!r.ok) throw new Error(r.error);
  return r.result;
}

const KINDS = [
  ["banking", "Banking and payments"],
  ["health", "Health portals"],
  ["passwords", "Password managers"],
  ["government", "Government ID sites"],
] as const;

export async function actSitesCard(): Promise<HTMLElement> {
  const card = h(
    "div",
    { className: "card", "data-testid": "act-sites" },
    h("h2", {}, "Your browser: where bots may work"),
  );
  const managed = await getManaged();
  if (managed.ActDisabled) {
    card.append(
      h("p", { className: "muted" }, "Your administrator turned off bots in this browser."),
    );
    return card;
  }
  const device = await act<Schemas["LocalDevice"] | null>({ type: "act:device" }).catch(() => null);
  if (!device) {
    card.append(
      h(
        "p",
        { className: "muted" },
        'Bots can use this browser once you pair it: open Casama\'s panel, then More, then "Let bots use this browser".',
      ),
    );
    return card;
  }
  const status = h("p", { className: "muted", role: "status" });
  const save = async (body: Record<string, unknown>) => {
    try {
      await act({ type: "act:update", body });
      status.textContent = "Saved.";
      card.replaceWith(await actSitesCard());
    } catch (e) {
      status.textContent = (e as Error).message;
    }
  };
  const list = (
    title: string,
    key: "allowed_sites" | "blocked_sites",
    items: string[],
    testid: string,
  ) => {
    const input = h("input", {
      type: "text",
      placeholder: "example.com",
      "aria-label": title,
      "data-testid": `${testid}-input`,
    }) as HTMLInputElement;
    const form = h("form", { className: "row" }, input, h("button", { type: "submit" }, "Add"));
    form.addEventListener("submit", (e) => {
      e.preventDefault();
      const v = input.value.trim();
      if (v) void save({ [key]: [...new Set([...items, v])] });
    });
    return h(
      "div",
      { "data-testid": testid },
      h("h3", {}, title),
      items.length
        ? h(
            "ul",
            {},
            ...items.map((s) =>
              h(
                "li",
                {},
                s,
                " ",
                h(
                  "button",
                  {
                    className: "link",
                    onClick: () => void save({ [key]: items.filter((x) => x !== s) }),
                  },
                  "Remove",
                ),
              ),
            ),
          )
        : h("p", { className: "muted" }, "None yet."),
      form,
    );
  };
  const kinds = device.allowed_kinds ?? [];
  card.append(
    h(
      "p",
      { className: "muted" },
      "Other sites ask the first time a bot wants to use them: this once, always, or never. Casama's own pages are always off.",
    ),
    list("Bots may use without asking", "allowed_sites", device.allowed_sites ?? [], "act-allowed"),
    list("Bots may never use", "blocked_sites", device.blocked_sites ?? [], "act-blocked"),
    h("h3", {}, "Off by default"),
    ...KINDS.map(([k, label]) =>
      h(
        "label",
        { className: "choice" },
        h("input", {
          type: "checkbox",
          checked: kinds.includes(k),
          "data-testid": `act-kind-${k}`,
          onChange: (e: Event) => {
            const on = (e.target as HTMLInputElement).checked;
            void save({
              allowed_kinds: on ? [...new Set([...kinds, k])] : kinds.filter((x) => x !== k),
            });
          },
        }),
        h("span", {}, `Let bots ask to use ${label.toLowerCase()}`),
      ),
    ),
    managed.BlockedSites?.length || managed.AllowedSites?.length
      ? h(
          "p",
          { className: "muted" },
          `Set by your administrator: ${[...(managed.BlockedSites ?? []).map((s) => `never ${s}`), ...(managed.AllowedSites ?? []).map((s) => `always ${s}`)].join(", ")}.`,
        )
      : "",
    status,
  );
  return card;
}
