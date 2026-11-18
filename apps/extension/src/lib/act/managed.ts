/**
 * Settings an administrator sets for Casama for Chrome through Chrome's enterprise policies
 * (chrome.storage.managed, schema in public/managed_schema.json; D-323 G9). They win over the
 * person's own choices: an administrator can turn Act or the whole extension off, block sites,
 * allow sites, or fix the server.
 */
export interface ManagedSettings {
  /** The Casama server to sign in to, e.g. a self-hosted address. */
  ServerAddress?: string;
  /** Bots may not use this browser. */
  ActDisabled?: boolean;
  /** Sites bots may never act on. */
  BlockedSites?: string[];
  /** Sites bots may act on without asking. */
  AllowedSites?: string[];
  /** The extension does nothing but say it's turned off. */
  ExtensionDisabled?: boolean;
}

const strings = (v: unknown) =>
  Array.isArray(v)
    ? v.filter((x): x is string => typeof x === "string" && !!x.trim()).slice(0, 500)
    : undefined;

/** Keeps only well-formed values: a policy typo shouldn't break the extension. */
export function cleanManaged(raw: Record<string, unknown> | undefined | null): ManagedSettings {
  if (!raw) return {};
  const out: ManagedSettings = {};
  if (typeof raw.ServerAddress === "string" && /^https?:\/\/\S+$/.test(raw.ServerAddress))
    out.ServerAddress = raw.ServerAddress.replace(/\/+$/, "");
  if (typeof raw.ActDisabled === "boolean") out.ActDisabled = raw.ActDisabled;
  if (typeof raw.ExtensionDisabled === "boolean") out.ExtensionDisabled = raw.ExtensionDisabled;
  const b = strings(raw.BlockedSites);
  if (b) out.BlockedSites = b;
  const a = strings(raw.AllowedSites);
  if (a) out.AllowedSites = a;
  return out;
}

/** The managed settings, or none when the browser isn't managed (or in tests). */
export async function getManaged(): Promise<ManagedSettings> {
  try {
    const area = chrome.storage?.managed;
    if (!area) return {};
    return cleanManaged((await area.get(null)) as Record<string, unknown>);
  } catch {
    return {};
  }
}
