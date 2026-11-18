/**
 * Gallery v2 (D-315): a workspace's rules for what members may add from the gallery, and how an
 * update's access compares with what was installed. Pure functions; the API enforces them.
 */
import type { GalleryAccess } from "./gallery.ts";

export const GALLERY_POLICY_MODES = ["open", "approval", "allowlist"] as const;
export type GalleryPolicyMode = (typeof GALLERY_POLICY_MODES)[number];
export const GALLERY_APPROVAL_RULES = ["runs_code", "apps", "all"] as const;
export type GalleryApprovalRule = (typeof GALLERY_APPROVAL_RULES)[number];

export interface GalleryPolicy {
  mode: GalleryPolicyMode;
  /** Item keys (`skill/meeting-notes`) members may always add; the only ones in allowlist mode. */
  allow: string[];
  /** Item keys nobody may add. */
  block: string[];
  /** What needs an admin's approval: items that run code, apps, or everything. */
  approval_for: GalleryApprovalRule[];
}

export const DEFAULT_GALLERY_POLICY: GalleryPolicy = {
  mode: "open",
  allow: [],
  block: [],
  approval_for: [],
};

/** `<type>/<id>`, the key usage counts, policies and links use. */
export const galleryItemKey = (type: string, id: string) => `${type}/${id}`;

const KEY = /^[a-z]+\/([a-z0-9-]{1,40}:)?[a-z0-9][a-z0-9-]{0,62}$/;

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

/** A stored or submitted policy, checked. Errors come back for a submitted one; stored ones fall back. */
export function parseGalleryPolicy(raw: unknown): { policy: GalleryPolicy; errors: string[] } {
  const errors: string[] = [];
  if (!isRecord(raw)) return { policy: { ...DEFAULT_GALLERY_POLICY }, errors: ["not an object"] };
  const mode = GALLERY_POLICY_MODES.includes(raw.mode as GalleryPolicyMode)
    ? (raw.mode as GalleryPolicyMode)
    : (errors.push("mode must be open, approval or allowlist"), "open");
  const keys = (field: "allow" | "block") => {
    const v = raw[field];
    if (v === undefined) return [];
    if (!Array.isArray(v)) {
      errors.push(`${field} must be a list of item keys`);
      return [];
    }
    const out: string[] = [];
    for (const k of v) {
      if (typeof k !== "string" || !KEY.test(k))
        errors.push(`${field}: ${String(k)} isn't an item key such as skill/meeting-notes`);
      else if (!out.includes(k)) out.push(k);
    }
    return out;
  };
  const allow = keys("allow");
  const block = keys("block");
  const rules = Array.isArray(raw.approval_for) ? raw.approval_for : [];
  const approval_for: GalleryApprovalRule[] = [];
  for (const r of rules) {
    if (!GALLERY_APPROVAL_RULES.includes(r as GalleryApprovalRule))
      errors.push(`approval_for: ${String(r)} must be runs_code, apps or all`);
    else if (!approval_for.includes(r as GalleryApprovalRule))
      approval_for.push(r as GalleryApprovalRule);
  }
  return { policy: { mode, allow, block, approval_for }, errors };
}

export type GalleryPolicyDecision =
  | { decision: "allow" }
  | { decision: "block"; reason: string }
  | { decision: "approval"; reason: string };

/**
 * Whether someone may add an item. Blocked items stay blocked for everyone; admins skip approval
 * (they can change the rules anyway); allowlisted items skip approval for members too.
 */
export function galleryPolicyDecision(
  policy: GalleryPolicy,
  item: { type: string; id: string; access?: GalleryAccess },
  opts: { admin?: boolean } = {},
): GalleryPolicyDecision {
  const key = galleryItemKey(item.type, item.id);
  if (policy.block.includes(key))
    return { decision: "block", reason: "This workspace doesn't allow this item." };
  const listed = policy.allow.includes(key);
  if (policy.mode === "allowlist" && !listed && !opts.admin)
    return { decision: "block", reason: "This workspace only allows items an admin picked." };
  if (listed || opts.admin) return { decision: "allow" };
  const rules = policy.approval_for;
  const all = rules.includes("all") || (policy.mode === "approval" && rules.length === 0);
  if (all) return { decision: "approval", reason: "An admin approves gallery items here." };
  if (rules.includes("runs_code") && (item.access?.runs_code || item.access?.computer))
    return { decision: "approval", reason: "Items that run code need an admin's approval here." };
  if (rules.includes("apps") && item.type === "app")
    return { decision: "approval", reason: "Apps need an admin's approval here." };
  return { decision: "allow" };
}

export interface GalleryAccessAdded {
  reads: string[];
  writes: string[];
  runs_code: boolean;
  computer: boolean;
}

/** What `next` can touch that `before` couldn't. */
export function galleryAccessAdded(
  before: GalleryAccess | undefined,
  next: GalleryAccess | undefined,
): GalleryAccessAdded {
  const had = (list: string[] | undefined) => new Set((list ?? []).map((s) => s.toLowerCase()));
  const reads = had(before?.reads);
  const writes = had(before?.writes);
  return {
    reads: (next?.reads ?? []).filter((r) => !reads.has(r.toLowerCase())),
    writes: (next?.writes ?? []).filter((w) => !writes.has(w.toLowerCase())),
    runs_code: !!next?.runs_code && !before?.runs_code,
    computer: !!next?.computer && !before?.computer,
  };
}

export function galleryAccessGrew(added: GalleryAccessAdded): boolean {
  return added.reads.length > 0 || added.writes.length > 0 || added.runs_code || added.computer;
}

/** Changelog entries newer than an installed version, and whether any of them is breaking. */
export function galleryChangesSince<T extends { version: number; breaking?: boolean }>(
  changelog: T[] | undefined,
  installed: number,
): { entries: T[]; breaking: boolean } {
  const entries = (changelog ?? []).filter((c) => c.version > installed);
  return { entries, breaking: entries.some((c) => c.breaking === true) };
}
