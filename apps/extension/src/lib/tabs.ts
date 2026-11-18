/**
 * Other tabs as context (A14) and "send these tabs" (B9). Needs the optional `tabs` permission,
 * asked the first time; each tab is read only when the person picks it, through the same guard.
 */
import { TEXT_CAP } from "./context.ts";
import { readTab } from "./page.ts";

export const TAB_CAP = 12_000;
export const SET_MAX = 10;

/** Asks for `tabs` if it isn't granted. Must run from a click or a key press. */
export async function ensureTabs(): Promise<boolean> {
  if (await chrome.permissions.contains({ permissions: ["tabs"] })) return true;
  return chrome.permissions.request({ permissions: ["tabs"] }).catch(() => false);
}

export interface TabChoice {
  kind: "tab" | "group";
  label: string;
  tabs: chrome.tabs.Tab[];
}

/** Open tabs in this window (not the one in view), then its tab groups. */
export async function tabChoices(activeId?: number): Promise<TabChoice[]> {
  const own = chrome.runtime.getURL("");
  const tabs = (await chrome.tabs.query({ lastFocusedWindow: true })).filter(
    (t) => t.id !== activeId && t.url && !t.url.startsWith(own) && /^(https?|file):/.test(t.url),
  );
  const out: TabChoice[] = tabs.map((t) => ({
    kind: "tab",
    label: t.title || t.url || "Tab",
    tabs: [t],
  }));
  const groups = new Map<number, chrome.tabs.Tab[]>();
  for (const t of await chrome.tabs.query({ lastFocusedWindow: true }))
    if (t.groupId !== undefined && t.groupId >= 0 && t.url && !t.url.startsWith(own))
      groups.set(t.groupId, [...(groups.get(t.groupId) ?? []), t]);
  for (const [, g] of groups)
    out.push({ kind: "group", label: `Tab group (${g.length} tabs)`, tabs: g });
  return out;
}

export function filterChoices(all: TabChoice[], query: string): TabChoice[] {
  const q = query.toLowerCase();
  return all
    .filter(
      (c) =>
        !q ||
        c.label.toLowerCase().includes(q) ||
        c.tabs.some((t) => t.url?.toLowerCase().includes(q)),
    )
    .slice(0, 8);
}

export interface TabText {
  label: string;
  text: string;
  /** Why it wasn't read, when it wasn't. */
  skipped?: string;
}

/** A tab's address, title and text, as a block for the message. Blocked tabs give only why. */
export async function tabBlock(tab: chrome.tabs.Tab, cap = TAB_CAP): Promise<TabText> {
  const label = tab.title || tab.url || "Tab";
  try {
    const ctx = await readTab(tab);
    if (ctx.blocked) return { label, text: "", skipped: ctx.blocked };
    const body = (ctx.text ?? "").trim().slice(0, Math.min(cap, TEXT_CAP));
    return {
      label,
      text: `Other tab: ${ctx.title ?? label} (${ctx.url ?? tab.url})${body ? `\n${body}` : ""}`,
    };
  } catch (e) {
    return { label, text: "", skipped: (e as Error).message };
  }
}
