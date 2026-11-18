/** Messages between the page kit (content script) and the service worker (Phase 2). */
import type { IndexedHighlight } from "../lib/page-index.ts";

export const HELPERS = ["youtube", "gmail", "github", "search", "threads", "shopping"] as const;
export type HelperName = (typeof HELPERS)[number];

export const HELPER_LABELS: Record<HelperName, string> = {
  youtube: "YouTube: summary and chapters",
  gmail: "Gmail: thread summary and a draft reply",
  github: "GitHub: pull request and issue summaries, review notes",
  search: "Search results: an answer beside them",
  threads: "Long threads on X, LinkedIn and Reddit",
  shopping: "Shopping pages: compare, watch the price",
};

export type WriteMode = "draft" | "rewrite" | "shorten" | "reply";

export interface KitConfig {
  off?: boolean;
  selectionBar: boolean;
  writeBox: boolean;
  helpers: HelperName[];
  highlights: IndexedHighlight[];
  /** The person's first page commands, for the selection bar. */
  commands: { name: string; prompt: string }[];
}

export type KitMessage =
  | { type: "kit:config"; url: string }
  | { type: "kit:refresh" }
  | { type: "kit:ask"; prompt?: string; send: boolean; selection?: string; readText?: boolean }
  | { type: "kit:write"; mode: WriteMode; fieldId: string; text: string }
  | {
      type: "kit:highlight";
      url: string;
      title: string;
      text: string;
      prefix: string;
      suffix: string;
    }
  | { type: "kit:watch-price" }
  | { type: "kit:helper-missing"; helper: HelperName };
