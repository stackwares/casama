/**
 * Things to do with the page in view (Phase 2): watch part of it (B10), read it for me later (B8),
 * send a link's file to the bot's computer (B6), translate it (A18) and read it aloud.
 */
import type { Schemas } from "@casama/client";
import { privateHost } from "../lib/hosts.ts";
import { insertIntoField, pickElement, translatePage } from "../lib/inject.ts";
import { blockedReason, readTab } from "../lib/page.ts";
import { accessToken } from "../lib/session.ts";
import type { Here } from "../lib/workspace.ts";
import { T } from "./shared.ts";

type Bot = Schemas["Bot"];

async function inTab<T, A extends unknown[]>(
  tab: chrome.tabs.Tab,
  func: (...a: A) => T | Promise<T>,
  args: A,
): Promise<T> {
  const [r] = await chrome.scripting.executeScript({ target: { tabId: tab.id! }, func, args });
  return r?.result as T;
}

/** B10: the person points at part of the page; the server checks it and wakes the bot on a change. */
export async function watchPart(here: Here, bot: Bot, tab: chrome.tabs.Tab, hint?: "price") {
  const blocked = await blockedReason(tab.url);
  if (blocked) throw new Error(blocked);
  if (!tab.url || !/^https?:/.test(tab.url)) throw new Error("Only web pages can be watched.");
  await chrome.tabs.update(tab.id!, { active: true });
  const picked = await inTab(tab, pickElement, [
    hint === "price" ? "Click the price to watch" : "Click the part of the page to watch",
  ]);
  if (!picked) return null;
  if (!picked.anchor) throw new Error("That part has no text to watch. Try a bigger part.");
  const name = (
    hint === "price"
      ? `Price on ${tab.title ?? "a page"}`
      : `${tab.title ?? "A page"}: ${picked.anchor}`
  ).slice(0, 120);
  const w = await here.api.unwrap(
    here.api.POST("/v1/watchers", {
      body: {
        bot_id: bot.id,
        name,
        url: tab.url,
        anchor: picked.anchor.slice(0, 200),
        chars: picked.chars,
        condition: hint === "price" ? "the price goes down" : undefined,
        check_every_minutes: 60,
      },
      signal: T(),
    }),
  );
  return { watcher: w, picked };
}

/** B8: a ticket the bot reads and sums up in the next brief. */
export async function readLater(here: Here, tab: chrome.tabs.Tab) {
  const blocked = await blockedReason(tab.url);
  if (blocked) throw new Error(blocked);
  if (!tab.url || !/^https?:/.test(tab.url)) throw new Error("Only web pages can be read later.");
  return here.api.unwrap(
    here.api.POST("/v1/tasks", {
      body: {
        org_id: here.org.id,
        title: (tab.title || tab.url).slice(0, 300),
        details_md: `Read this page and sum it up for me in my next brief:\n\n${tab.url}`,
        labels: ["read-for-me"],
      },
      signal: T(),
    }),
  );
}

/** B6: downloads a link here and puts the file in the bot's computer, under Downloads. */
export async function sendFile(here: Here, bot: Bot, linkUrl: string, from?: chrome.tabs.Tab) {
  const blocked = (await blockedReason(from?.url)) ?? (await blockedReason(linkUrl));
  if (blocked) throw new Error(blocked);
  if (!/^https?:/i.test(linkUrl) || privateHost(linkUrl))
    throw new Error("Only files on the public web can be sent this way.");
  // The bot's own computer only; never a shared one by surprise.
  let computerId = (bot as { default_computer_id?: string | null }).default_computer_id ?? null;
  if (!computerId) {
    const list = await here.api.unwrap(
      here.api.GET("/v1/computers", { params: { query: { org_id: here.org.id } }, signal: T() }),
    );
    computerId = list.items.find((c) => c.owner_bot_id === bot.id)?.id ?? null;
  }
  if (!computerId) throw new Error(`${bot.name} has no computer of its own yet.`);
  // No cookies go with it: a file behind a sign-in comes back as a page, and is refused below.
  const res = await fetch(linkUrl, { signal: T(120_000), credentials: "omit" });
  if (!res.ok) throw new Error(`The file couldn't be downloaded (${res.status}).`);
  const landed = res.url || linkUrl;
  if (privateHost(landed) || (await blockedReason(landed)))
    throw new Error("That link leads somewhere Casama doesn't send from.");
  if (/^text\/html/i.test(res.headers.get("content-type") ?? ""))
    throw new Error("That link opens a web page, not a file (it may need you to sign in).");
  const blob = await res.blob();
  if (blob.size > 100 * 1024 * 1024)
    throw new Error("Files sent to a computer are limited to 100 MB.");
  const name =
    decodeURIComponent(new URL(res.url || linkUrl).pathname.split("/").pop() || "download").replace(
      /[^\w.\- ]+/g,
      "_",
    ) || "download";
  const token = await accessToken(here.account.id);
  const put = await fetch(
    `${here.account.server}/v1/computers/${computerId}/files?path=${encodeURIComponent(`Downloads/${name}`)}`,
    {
      method: "PUT",
      headers: { authorization: `Bearer ${token}`, "content-type": "application/octet-stream" },
      body: blob,
      signal: T(300_000),
    },
  );
  if (!put.ok) throw new Error(`The computer didn't take the file (${put.status}).`);
  return { name, size: blob.size };
}

/** A18: translates the page on this computer when Chrome can; null means "ask the bot". */
export async function translateHere(
  tab: chrome.tabs.Tab,
): Promise<{ done: number } | "same" | null> {
  const blocked = await blockedReason(tab.url);
  if (blocked) throw new Error(blocked);
  const target = (navigator.language || "en").split("-")[0]!;
  const r = await inTab(tab, translatePage, [target]);
  return r === "unavailable" ? null : r;
}

/** Reads the page aloud with the computer's own voice. Calling it again stops. */
let speaking = false;
export async function readPageAloud(tab: chrome.tabs.Tab): Promise<boolean> {
  if (speaking) {
    speechSynthesis.cancel();
    speaking = false;
    return false;
  }
  const ctx = await readTab(tab);
  if (ctx.blocked) throw new Error(ctx.blocked);
  const text = (ctx.text ?? "").trim();
  if (!text) throw new Error("There's no text on this page to read.");
  speechSynthesis.cancel();
  // Chrome stops long utterances; speak it in pieces.
  const pieces = text.slice(0, 40_000).match(/[^.!?\n]{1,280}[.!?\n]*/g) ?? [text];
  speaking = true;
  for (const [i, p] of pieces.entries()) {
    const u = new SpeechSynthesisUtterance(p);
    u.lang = document.documentElement.lang || navigator.language;
    if (i === pieces.length - 1)
      u.onend = () => {
        speaking = false;
      };
    speechSynthesis.speak(u);
  }
  return true;
}

/** A16: puts a reply into the page's text box it was written for. */
export async function putInField(tabId: number, fieldId: string, text: string): Promise<boolean> {
  const [r] = await chrome.scripting.executeScript({
    target: { tabId },
    func: insertIntoField,
    args: [fieldId, text],
  });
  return r?.result === true;
}
