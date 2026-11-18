/**
 * B11 (D-323): bookmarks and the reading list as one Markdown list for a bot's knowledge. Titles,
 * addresses and folders only; pages the guard keeps out (Casama's own, the never-list, the
 * off-by-default kinds of site) are left out.
 */
import { browserName } from "../browser.ts";
import { guardUrl } from "../guard.ts";
import { guardAdditions } from "../guard-sites.ts";
import { getSettings } from "../settings.ts";

const MAX = 2000;

interface Item {
  title: string;
  url: string;
  folder: string;
}

export function flatten(nodes: chrome.bookmarks.BookmarkTreeNode[], path: string[] = []): Item[] {
  const out: Item[] = [];
  for (const n of nodes) {
    if (n.url) out.push({ title: n.title || n.url, url: n.url, folder: path.join(" / ") });
    if (n.children) out.push(...flatten(n.children, n.title ? [...path, n.title] : path));
  }
  return out;
}

/** The list as Markdown, grouped by folder, with how many it holds. */
export function toMarkdown(items: Item[], reading: Array<{ title: string; url: string }>) {
  const groups = new Map<string, Item[]>();
  for (const i of items) groups.set(i.folder, [...(groups.get(i.folder) ?? []), i]);
  const lines = [`# Bookmarks from ${browserName()}`, ""];
  for (const [folder, list] of groups) {
    lines.push(`## ${folder || "Bookmarks"}`, "");
    for (const i of list) lines.push(`- [${i.title.replace(/[[\]]/g, "")}](${i.url})`);
    lines.push("");
  }
  if (reading.length) {
    lines.push("## Reading list", "");
    for (const r of reading) lines.push(`- [${r.title.replace(/[[\]]/g, "")}](${r.url})`);
    lines.push("");
  }
  return { text: lines.join("\n"), count: items.length + reading.length };
}

export async function bookmarksMarkdown(withReading: boolean) {
  const s = await getSettings();
  const extraHosts = await guardAdditions();
  const ok = (url: string) =>
    /^https?:/.test(url) && !guardUrl(url, { neverList: s.neverList, extraHosts });
  const tree = await chrome.bookmarks.getTree();
  const items = flatten(tree)
    .filter((i) => ok(i.url))
    .slice(0, MAX);
  const reading =
    __CASAMA_BROWSER__ !== "firefox" && withReading && chrome.readingList
      ? (await chrome.readingList.query({}))
          .filter((r) => ok(r.url))
          .slice(0, MAX)
          .map((r) => ({ title: r.title, url: r.url }))
      : [];
  return toMarkdown(items, reading);
}
