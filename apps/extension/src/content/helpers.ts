/**
 * Site helpers (A17): a small bar on pages of a known kind with the one or two things people ask
 * there. Each checks for the element it needs and hides itself when the element is missing (the
 * site changed), so a broken helper disappears instead of misbehaving. Nothing is read until the
 * person taps a button; the panel then reads the page as usual.
 */
import type { HelperName } from "./protocol.ts";

export interface HelperAction {
  label: string;
  prompt?: string;
  /** Send the page's text with it. */
  readText?: boolean;
  watchPrice?: boolean;
}

export interface Helper {
  name: HelperName;
  match(u: URL, doc: Document): boolean;
  anchor(doc: Document): Element | null;
  actions(u: URL): HelperAction[];
}

const q = (doc: Document, sel: string) => doc.querySelector(sel);
const host = (u: URL, re: RegExp) => re.test(u.hostname.replace(/^www\./, ""));
const productLd = (doc: Document) =>
  [...doc.querySelectorAll('script[type="application/ld+json"]')].some((s) =>
    /"@type"\s*:\s*"Product"/.test(s.textContent ?? ""),
  );

export const SITE_HELPERS: Helper[] = [
  {
    name: "youtube",
    match: (u) => host(u, /^(m\.)?youtube\.com$/) && u.pathname === "/watch",
    anchor: (d) => q(d, "ytd-watch-metadata #title, #above-the-fold #title, h1.ytd-watch-metadata"),
    actions: () => [
      {
        label: "Summarize the video",
        prompt: "Summarize this video in five bullet points, with timestamps.",
        readText: true,
      },
      {
        label: "Chapters",
        prompt: "List this video's chapters with their timestamps.",
        readText: true,
      },
    ],
  },
  {
    name: "gmail",
    match: (u) => u.hostname === "mail.google.com",
    anchor: (d) => q(d, "h2.hP"),
    actions: () => [
      {
        label: "Summarize the thread",
        prompt: "Summarize this email thread: who wants what, and what's left to answer.",
        readText: true,
      },
      {
        label: "Draft a reply",
        prompt: "Draft a reply to this email thread in my voice. Reply with only the email's text.",
        readText: true,
      },
    ],
  },
  {
    name: "github",
    match: (u) =>
      u.hostname === "github.com" && /^\/[^/]+\/[^/]+\/(pull|issues)\/\d+/.test(u.pathname),
    anchor: (d) =>
      q(
        d,
        '.gh-header-title, bdi.js-issue-title, [data-testid="issue-title"], h1[data-component="PH_Title"]',
      ),
    actions: (u) => [
      {
        label: /\/pull\//.test(u.pathname) ? "Summarize the pull request" : "Summarize the issue",
        prompt: "Summarize this: what it's about, where it stands, and what's being asked.",
        readText: true,
      },
      ...(/\/pull\//.test(u.pathname)
        ? [
            {
              label: "Review notes",
              prompt: "Write review notes for this pull request: risks, questions and suggestions.",
              readText: true,
            },
          ]
        : []),
    ],
  },
  {
    name: "search",
    match: (u) =>
      (host(u, /^google\.[a-z.]+$/) && u.pathname === "/search") ||
      (host(u, /^bing\.com$/) && u.pathname === "/search") ||
      (host(u, /^duckduckgo\.com$/) && u.searchParams.has("q")) ||
      (host(u, /^search\.brave\.com$/) && u.pathname === "/search"),
    anchor: (d) => q(d, '#search, #b_results, [data-testid="mainline"], #results'),
    actions: (u) => [
      {
        label: "Answer this",
        prompt: `Answer my search from these results, with the links you used: ${u.searchParams.get("q") ?? ""}`,
        readText: true,
      },
    ],
  },
  {
    name: "threads",
    match: (u) =>
      (host(u, /^(x|twitter)\.com$/) && /\/status\/\d+/.test(u.pathname)) ||
      (host(u, /^(old\.)?reddit\.com$/) && /\/comments\//.test(u.pathname)) ||
      (host(u, /^linkedin\.com$/) && /\/(feed\/update|posts)\//.test(u.pathname)),
    anchor: (d) =>
      q(
        d,
        'article[data-testid="tweet"], shreddit-post, [data-test-id="post-content"], .feed-shared-update-v2, div.thing.link',
      ),
    actions: () => [
      {
        label: "Summarize the thread",
        prompt: "Summarize this thread: the main points, where people agree and disagree.",
        readText: true,
      },
    ],
  },
  {
    name: "shopping",
    match: (u, d) =>
      (host(u, /^amazon\.[a-z.]+$/) && /\/(dp|gp\/product)\//.test(u.pathname)) || productLd(d),
    anchor: (d) => q(d, '#productTitle, [itemprop="name"], h1'),
    actions: () => [
      {
        label: "Compare",
        prompt:
          "Compare this product with two or three alternatives: price, what's better, what's worse.",
        readText: true,
      },
      { label: "Watch the price", watchPrice: true },
    ],
  },
];

/** The helper for this page, if one is on and its element is there. */
export function helperFor(u: URL, doc: Document, on: HelperName[]): Helper | null {
  return SITE_HELPERS.find((h) => on.includes(h.name) && h.match(u, doc)) ?? null;
}
