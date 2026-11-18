/**
 * The window that asks the person before a bot's step in their browser (D-323 C6, C7). An extension
 * page, so neither the web page nor the bot can see or press its buttons.
 */
import type { Ask } from "../background/act/ask.ts";
import { h } from "../lib/dom.ts";

const app = document.getElementById("app") as HTMLElement;
const id = new URLSearchParams(location.search).get("id") ?? "";

async function main() {
  const asks = ((await chrome.storage.session.get("actAsks")).actAsks as Ask[] | undefined) ?? [];
  const a = asks.find((x) => x.id === id);
  if (!a) {
    app.replaceChildren(h("p", {}, "This was already answered."));
    setTimeout(() => window.close(), 1500);
    return;
  }
  const send = async (answer: string) => {
    await chrome.runtime.sendMessage({ type: "act:answer", id, answer }).catch(() => {});
    window.close();
  };
  const b = (label: string, answer: string, primary = false) =>
    h(
      "button",
      {
        className: primary ? "primary" : "",
        "data-testid": `ask-${answer}`,
        onClick: () => void send(answer),
      },
      label,
    );
  app.replaceChildren(
    h("h1", { "data-testid": "ask-title" }, a.title),
    h("p", { "data-testid": "ask-detail" }, a.detail),
    a.kind === "site"
      ? h(
          "div",
          { className: "row" },
          b("Allow this once", "once", true),
          b("Always allow", "always"),
          b("Never", "never"),
        )
      : h("div", { className: "row" }, b("Allow", "allow", true), b("Deny", "deny")),
    h(
      "p",
      { className: "muted" },
      a.kind === "site"
        ? "You can change sites later in Casama's options, under Your browser."
        : "If nobody answers within 5 minutes, the bot is told no.",
    ),
  );
}

void main();
