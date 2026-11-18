/**
 * The built-in apps' marks (client/assets/apps), served by the API so apps built before a mark
 * was bundled still show it: the catalog gives each built-in app a `logo_url` at
 * /v1/apps/logos/<id>.svg (under /v1 so every proxy in front of the API passes it), which shipped
 * apps draw the same way as a gallery app's logo. Newer apps use their bundled copy first.
 */
import { createHash } from "node:crypto";
import { readdirSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

/** client/assets/apps next to the server: ../../../../client/assets/apps from here, in the repo and in the image. */
const dir = () => fileURLToPath(new URL("../../../../client/assets/apps/", import.meta.url));

export interface AppLogo {
  svg: string;
  /** Short content hash, so a changed mark gets a new address past any cache. */
  version: string;
}

let logos: Map<string, AppLogo> | null = null;

/** The marks by app id, read once. Empty when the folder isn't there (a trimmed image). */
export function appLogos(): Map<string, AppLogo> {
  if (logos) return logos;
  const out = new Map<string, AppLogo>();
  try {
    for (const f of readdirSync(dir())) {
      const m = /^([a-z0-9_]+)\.svg$/.exec(f);
      if (!m) continue;
      const svg = readFileSync(dir() + f, "utf8");
      out.set(m[1]!, { svg, version: createHash("sha256").update(svg).digest("hex").slice(0, 10) });
    }
  } catch {
    // No marks: the catalog just leaves logo_url out.
  }
  logos = out;
  return out;
}
