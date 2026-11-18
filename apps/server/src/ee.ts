/**
 * The enterprise features (ee/, D-073) are optional (D-339). Delete ee/ (scripts/oss-edition.sh)
 * and the server runs as the open-source edition: no license checks, and the enterprise routes
 * answer 402 license_required, as an unlicensed enterprise build does.
 *
 * Only types come from @casama/ee statically; Node strips them, so nothing loads it at runtime
 * except the import below.
 */

import type * as Ee from "@casama/ee";
import type { Context, Hono } from "hono";

export type EeModule = typeof Ee;

/** Loads ee/, or null when it isn't there. Any other failure (a broken ee/) is thrown. */
export async function loadEe(
  importer: () => Promise<EeModule> = () => import("@casama/ee"),
): Promise<EeModule | null> {
  try {
    return await importer();
  } catch (err) {
    const e = err as { code?: string; message?: string };
    const missing =
      (e.code === "ERR_MODULE_NOT_FOUND" || e.code === "MODULE_NOT_FOUND") &&
      (e.message ?? "").includes("@casama/ee");
    if (missing) return null;
    throw err;
  }
}

export const ee: EeModule | null = await loadEe();

/** "enterprise" when ee/ is present (a license key still decides what's on), else "oss". */
export const edition: "enterprise" | "oss" = ee ? "enterprise" : "oss";

/** The routes ee/ would register, answering 402 so clients behave as they do without a key. */
export const ENTERPRISE_PATHS = [
  "/v1/orgs/:id/audit-forwarders",
  "/v1/orgs/:id/audit-forwarders/:fid",
  "/v1/orgs/:id/audit-log/export",
  "/v1/orgs/:id/sso",
  "/v1/orgs/:id/sso/verification",
] as const;

export function registerEnterpriseFallback(app: Hono) {
  const answer = (c: Context) =>
    c.json(
      {
        type: "https://casama.ai/problems/license_required",
        title: "license_required",
        status: 402,
        code: "license_required",
        detail:
          "This is an enterprise feature, and this server is the open-source edition (built without ee/).",
      },
      402,
    );
  for (const path of ENTERPRISE_PATHS) app.all(path, answer);
}
