/**
 * System permissions on the person's own devices (D-376, docs/OS-PERMISSIONS-PLAN.md). Devices
 * report what the system allows Casama (checked without prompting); a permission card's buttons
 * ask a device to prompt, open its settings or restart Casama, and "Not now" quiets a bot for a day.
 * Everything here is the signed-in person's own devices.
 */

import { computerPermissions } from "@casama/agent";
import { routes } from "@casama/contracts";
import type { JwtClaims } from "@casama/db";
import { deviceRef, osPermission, osPermissionOn } from "@casama/domain";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

/** A device that shares data counts as online when seen this recently (like device.read). */
const SOURCE_ONLINE_MS = 15 * 60_000;
const SNOOZE_MS = 24 * 3600_000;

type Device = {
  type: "computer" | "source";
  id: string;
  user_id: string;
  name: string;
  platform: string;
  permissions: Record<string, string> | null;
  permissions_at: Date | null;
  permission_snoozes: Record<string, string> | null;
  last_seen_at: Date | null;
  computer_id: string | null;
  allowed_roots: string[] | null;
  capabilities: Record<string, unknown> | null;
};

export function registerDevicePermissionRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const me = (claims: JwtClaims | undefined) => {
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    return claims.sub;
  };

  const computerCols = sql`'computer' as type, id, user_id, name, platform, permissions, permissions_at,
    permission_snoozes, last_seen_at, computer_id, allowed_roots, capabilities`;
  const sourceCols = sql`'source' as type, id, user_id, name, platform, permissions, permissions_at,
    permission_snoozes, last_seen_at, null::uuid as computer_id, null::text[] as allowed_roots, null::jsonb as capabilities`;

  /** One of the caller's own devices; 404 for anyone else's (no hint that it exists). */
  const own = async (userId: string, type: "computer" | "source", id: string) => {
    const [d] =
      type === "computer"
        ? await db.execute<Device>(sql`
            select ${computerCols} from public.local_devices
            where id = ${id}::uuid and user_id = ${userId}::uuid and computer_id is not null`)
        : await db.execute<Device>(sql`
            select ${sourceCols} from public.device_sources where id = ${id}::uuid and user_id = ${userId}::uuid`);
    if (!d) throw new ApiError(404, "device_not_found", "Device not found");
    return d;
  };

  const out = (d: Device) => ({
    device_ref: deviceRef(d.type, d.id),
    type: d.type,
    id: d.id,
    name: d.name,
    platform: d.platform,
    permissions: (d.type === "computer" ? computerPermissions(d) : (d.permissions ?? {})) as Record<
      string,
      "granted"
    >,
    reported_at: d.permissions_at ? iso(d.permissions_at) : null,
    online:
      d.type === "computer"
        ? !!(d.computer_id && deps.devices?.online(d.computer_id))
        : !!d.last_seen_at && Date.now() - new Date(d.last_seen_at).getTime() < SOURCE_ONLINE_MS,
  });

  app.openapi(routes.listDevicePermissions, async (c) => {
    const userId = me(c.get("claims"));
    const computers = await db.execute<Device>(sql`
      select ${computerCols} from public.local_devices
      where user_id = ${userId}::uuid and computer_id is not null order by created_at`);
    const sources = await db.execute<Device>(sql`
      select ${sourceCols} from public.device_sources where user_id = ${userId}::uuid order by created_at`);
    return c.json({ items: [...computers, ...sources].map(out) }, 200);
  });

  app.openapi(routes.reportDevicePermissions, async (c) => {
    const userId = me(c.get("claims"));
    const { type, id } = c.req.valid("param");
    const { permissions } = c.req.valid("json");
    await own(userId, type, id);
    const table = type === "computer" ? sql`public.local_devices` : sql`public.device_sources`;
    await db.execute(sql`
      update ${table} set permissions = ${JSON.stringify(permissions)}::jsonb, permissions_at = now()
      where id = ${id}::uuid and user_id = ${userId}::uuid`);
    return c.json(out(await own(userId, type, id)), 200);
  });

  app.openapi(routes.askDevicePermission, async (c) => {
    const userId = me(c.get("claims"));
    const { type, id } = c.req.valid("param");
    const b = c.req.valid("json");
    const d = await own(userId, type, id);
    const info = osPermission(b.permission);
    if (!info)
      throw new ApiError(400, "unknown_permission", `No permission called ${b.permission}`);
    if (!osPermissionOn(b.permission, d.platform))
      throw new ApiError(
        400,
        "permission_not_here",
        `${d.name} has no ${info.label} setting Casama can ask for`,
      );
    if (type === "computer") {
      const sent =
        !!d.computer_id &&
        !!deps.devices?.notify(d.computer_id, {
          type: "permission",
          permission: b.permission,
          do: b.do,
          bot_id: b.bot_id ?? null,
        });
      if (!sent)
        throw new ApiError(
          409,
          "device_offline",
          `${d.name} is offline. Open Casama there and try again.`,
        );
      return c.json({ via: "socket" as const }, 200);
    }
    // A phone can't show a system prompt from the background: it gets a notification to tap,
    // which opens Casama straight into the prompt (or its settings).
    const [bot] = b.bot_id
      ? await db.execute<{ name: string }>(sql`
          select b.name from public.bots b join public.memberships m on m.org_id = b.org_id and m.user_id = ${userId}::uuid
          where b.id = ${b.bot_id}::uuid`)
      : [];
    const link = `/permissions?${new URLSearchParams({
      device: deviceRef("source", d.id),
      ask: b.permission,
      do: b.do,
    }).toString()}`;
    await db.execute(sql`
      insert into public.notifications (user_id, kind, payload, push_status, push_after)
      values (${userId}::uuid, 'permission', ${JSON.stringify({
        title: `Turn on ${info.label}`,
        body: `${bot?.name ?? "Casama"} asked for ${info.label} on ${d.name}. Tap to turn it on.`,
        link,
        ...(bot && b.bot_id ? { bot_id: b.bot_id } : {}),
      })}::jsonb, 'deferred', now())`);
    return c.json({ via: "notification" as const }, 200);
  });

  app.openapi(routes.snoozeDevicePermissions, async (c) => {
    const userId = me(c.get("claims"));
    const { type, id } = c.req.valid("param");
    const b = c.req.valid("json");
    await own(userId, type, id);
    const until = new Date(Date.now() + SNOOZE_MS).toISOString();
    const add = Object.fromEntries(b.permissions.map((p) => [`${b.bot_id}:${p}`, until]));
    const table = type === "computer" ? sql`public.local_devices` : sql`public.device_sources`;
    // Old entries go when they've passed, so the map stays small.
    await db.execute(sql`
      update ${table} set permission_snoozes = (
        select coalesce(jsonb_object_agg(e.key, e.value), '{}'::jsonb) from jsonb_each(permission_snoozes) e
        where (e.value #>> '{}')::timestamptz > now()
      ) || ${JSON.stringify(add)}::jsonb
      where id = ${id}::uuid and user_id = ${userId}::uuid`);
    return c.json({ until }, 200);
  });
}
