/**
 * Remote settings from the server's GET /v1/app-config (D-241, plan §9.8): the kill switch, a
 * minimum version, a maintenance notice and feature flags. Every feature a flag switches is already
 * in the package; the server only turns it on or off.
 *
 * Flags this version reads:
 * - `chrome_extension`: false turns the whole extension off.
 *
 * A server that can't be reached counts as "no settings" (the last ones fetched, else none), so a
 * network blip never locks anyone out.
 */
import type { Schemas } from "@casama/client";
import { publicClient } from "./session.ts";
import { getLocal, updateLocal } from "./store.ts";

export type RemoteAppConfig = Schemas["RemoteAppConfig"];

const FRESH_MS = 10 * 60_000;

export const EMPTY: RemoteAppConfig = {
  min_versions: {},
  update_urls: {},
  maintenance: null,
  announcements: [],
  flags: {},
};

export function compareVersions(a: string, b: string): number {
  const pa = a.split(".").map((n) => Number.parseInt(n, 10) || 0);
  const pb = b.split(".").map((n) => Number.parseInt(n, 10) || 0);
  for (let i = 0; i < 3; i++) {
    const d = (pa[i] ?? 0) - (pb[i] ?? 0);
    if (d) return d < 0 ? -1 : 1;
  }
  return 0;
}

export type Gate =
  | { state: "ok" }
  | { state: "off" }
  | { state: "update"; minVersion: string; updateUrl?: string }
  | { state: "maintenance"; message: string };

/** What the settings mean for this version of the extension. */
export function gate(config: RemoteAppConfig, version: string): Gate {
  if (config.flags.chrome_extension === false) return { state: "off" };
  const min = config.min_versions.chrome;
  if (min && compareVersions(version, min) < 0)
    return { state: "update", minVersion: min, updateUrl: config.update_urls.chrome };
  if (config.maintenance?.message)
    return { state: "maintenance", message: config.maintenance.message };
  return { state: "ok" };
}

/** A flag's value, or [fallback] when the server doesn't set it. */
export const flag = (config: RemoteAppConfig, name: string, fallback: boolean) =>
  config.flags[name] ?? fallback;

/**
 * A prompt the server's owner set (D-372): `selection.explain`, `write.draft`…, or [fallback], the
 * extension's own text. Older servers send none.
 */
export function promptFor(
  config: RemoteAppConfig | null | undefined,
  name: string,
  fallback: string,
): string {
  const v = (config?.prompts as Record<string, unknown> | undefined)?.[name];
  return typeof v === "string" && v.trim() ? v : fallback;
}

/** The last settings fetched from the server, without waiting on the network (or null). */
export async function cachedRemoteConfig(server: string): Promise<RemoteAppConfig | null> {
  try {
    return ((await getLocal()).remoteConfig[server]?.config as RemoteAppConfig | undefined) ?? null;
  } catch {
    return null;
  }
}

/** The server's settings, from cache when fetched in the last ten minutes. */
export async function remoteConfig(server: string, opts: { fresh?: boolean } = {}) {
  const cached = (await getLocal()).remoteConfig[server];
  if (!opts.fresh && cached && Date.now() - cached.fetchedAt < FRESH_MS)
    return cached.config as RemoteAppConfig;
  try {
    const api = publicClient(server);
    const config = await api.unwrap(
      api.GET("/v1/app-config", { signal: AbortSignal.timeout(8_000) }),
    );
    await updateLocal((s) => {
      s.remoteConfig = { ...s.remoteConfig, [server]: { fetchedAt: Date.now(), config } };
    });
    return config;
  } catch {
    return (cached?.config as RemoteAppConfig | undefined) ?? EMPTY;
  }
}
