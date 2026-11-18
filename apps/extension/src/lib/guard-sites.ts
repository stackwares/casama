/**
 * Sites the guard keeps out on top of its built-in lists (D-374), from each signed-in server's
 * GET /v1/browser-guard. They only ever add: the built-in lists in packages/domain never shrink,
 * whatever a server sends, so a server (or someone pretending to be one) can't open a bank to a
 * bot. Cached per server for an hour; a server that can't be reached keeps its last list.
 */
import {
  checkGuardAdditions,
  type SensitiveSiteAdditions,
} from "../../../../packages/domain/src/browser-guard.ts";
import { publicClient } from "./session.ts";
import { getLocal, updateLocal } from "./store.ts";

const FRESH_MS = 60 * 60_000;

/** Fetches one server's added sites and keeps them. Returns them (empty when it can't be reached). */
export async function refreshGuardSites(server: string): Promise<SensitiveSiteAdditions> {
  try {
    const api = publicClient(server);
    const got = await api.unwrap(
      api.GET("/v1/browser-guard", { signal: AbortSignal.timeout(8_000) }),
    );
    // Hosts that aren't hosts and kinds this version doesn't know are dropped.
    const hosts = checkGuardAdditions(got.hosts).hosts;
    await updateLocal((s) => {
      s.guardSites = { ...s.guardSites, [server]: { fetchedAt: Date.now(), hosts } };
    });
    return hosts;
  } catch {
    // An older server answers 404, an offline one not at all: keep what was there.
    return ((await getLocal()).guardSites[server]?.hosts ?? {}) as SensitiveSiteAdditions;
  }
}

/** Every signed-in server's added sites together; stale ones are refreshed in the background. */
export async function guardAdditions(now = Date.now()): Promise<SensitiveSiteAdditions> {
  const local = await getLocal();
  const out: Record<string, string[]> = {};
  for (const server of new Set(local.accounts.map((a) => a.server))) {
    const cached = local.guardSites[server];
    if (!cached || now - cached.fetchedAt > FRESH_MS) void refreshGuardSites(server);
    for (const [kind, list] of Object.entries(checkGuardAdditions(cached?.hosts).hosts))
      out[kind] = [...(out[kind] ?? []), ...list];
  }
  return out as SensitiveSiteAdditions;
}
