/**
 * Apps a workspace's packs brought (docs/PLUGINS-AND-PACKS-PLAN.md §5.4). They join that
 * workspace's catalog as `<pack>.<app>` and connect the way gallery apps do: their own sign-in,
 * a key or nothing, checked again here on every read.
 */
import type { Database } from "@casama/db";
import { catalogAppFromGallery } from "@casama/domain";
import { sql } from "drizzle-orm";
import type { GalleryCatalogApp } from "./gallery.ts";

export const packAppId = (pack: string, app: string) => `${pack}.${app}`;

export async function packApps(db: Database, orgId: string): Promise<GalleryCatalogApp[]> {
  const rows = await db.execute<{
    name: string;
    apps: Array<{ id: string; name: string; doc: unknown; logo?: string }> | null;
  }>(sql`select name, content -> 'apps' as apps from public.packs where org_id = ${orgId}::uuid`);
  const out: GalleryCatalogApp[] = [];
  for (const r of rows)
    for (const a of r.apps ?? []) {
      const app = catalogAppFromGallery(packAppId(r.name, a.id), a.name, a.doc);
      if (app) out.push(app as GalleryCatalogApp);
    }
  return out;
}
