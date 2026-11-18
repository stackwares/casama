/** Small pieces the panel's views share. */
import { CasamaError } from "@casama/client";
import { BILLING_PATH, needsPlan, planMessage } from "../lib/billing.ts";
import { h } from "../lib/dom.ts";
import { NoAccessError } from "../lib/page.ts";
import { UnreachableError } from "../lib/session.ts";
import { activeAccount } from "../lib/store.ts";
import { appUrl } from "../lib/workspace.ts";

/** "See plans": opens Billing in the web app for the active account (no purchases here). */
export function seePlans(): HTMLElement {
  return h(
    "button",
    {
      className: "link",
      "data-testid": "see-plans",
      onClick: async () => {
        const account = await activeAccount();
        if (account) await chrome.tabs.create({ url: appUrl(account, BILLING_PATH) });
      },
    },
    "See plans",
  );
}

/** Messages of plan and credit refusals that message() produced, so a toast of one offers Billing. */
const planTexts = new Set<string>();

let toastTimer: ReturnType<typeof setTimeout> | undefined;
export function toast(text: string) {
  document.querySelector(".toast")?.remove();
  const plan = planTexts.has(text);
  const el = h(
    "div",
    { className: "toast", role: "status", "data-testid": "toast" },
    text,
    ...(plan ? [" ", seePlans()] : []),
  );
  document.body.append(el);
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.remove(), plan ? 10_000 : 4000);
}

/** A run's failure under the message: its reason, and "See plans" when Billing fixes it. */
export function failureBox(text: string, code?: string | null, testId?: string): HTMLElement {
  return h(
    "div",
    { className: "error", role: "alert", ...(testId ? { "data-testid": testId } : {}) },
    text,
    ...(code && needsPlan(code) ? [" ", seePlans()] : []),
  );
}

export function message(e: unknown): string {
  if (e instanceof CasamaError && needsPlan(e)) {
    const text = planMessage(e);
    planTexts.add(text);
    return text;
  }
  if (e instanceof CasamaError) return e.message || `The server said no (${e.status}).`;
  if (e instanceof UnreachableError) return `${e.message} Check your connection.`;
  return (e as Error)?.message || "Something went wrong.";
}

export function errorBox(e: unknown, retry?: () => void): HTMLElement {
  const box = h(
    "div",
    { className: "error", role: "alert", "data-testid": "error" },
    message(e),
    " ",
  );
  if (needsPlan(e)) box.append(seePlans());
  else if (e instanceof NoAccessError && e.origin) {
    const origin = e.origin;
    box.append(
      h(
        "button",
        {
          className: "link",
          "data-testid": "allow-site",
          onClick: async () => {
            if (await chrome.permissions.request({ origins: [origin] })) retry?.();
          },
        },
        "Allow on this site",
      ),
    );
  } else if (retry) box.append(h("button", { className: "link", onClick: retry }, "Try again"));
  return box;
}

export const T = (ms = 20_000) => AbortSignal.timeout(ms);

export const ago = (iso: string | null | undefined) => {
  if (!iso) return "";
  const s = (Date.now() - new Date(iso).getTime()) / 1000;
  if (s < 60) return "just now";
  if (s < 3600) return `${Math.floor(s / 60)} min ago`;
  if (s < 86400) return `${Math.floor(s / 3600)} h ago`;
  return new Date(iso).toLocaleDateString("en-US", { month: "short", day: "numeric" });
};
