/**
 * Casama Link, what people do from the app on Casama Cloud (D-296): approve the code their
 * server shows, see and remove linked servers, and (the instance owner) take an address down.
 * The server-to-cloud half is in ../../link/routes.ts.
 */
import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { orgLimits } from "../../billing/limits.ts";
import { LinkError, type LinkServers, type ServerRow } from "../../link/servers.ts";
import { privateNotifications, setPrivateNotifications } from "../../services/link-settings.ts";
import type { RemoteAccessStatus } from "../../services/remote-access.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

function requireClaims(claims: JwtClaims | undefined): JwtClaims {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
}

/** LinkError -> problem JSON. */
async function linkCall<T>(fn: () => Promise<T>): Promise<T> {
  try {
    return await fn();
  } catch (err) {
    if (err instanceof LinkError) throw new ApiError(err.status as 400, err.code, err.message);
    throw err;
  }
}

export function registerConnectAppRoutes(
  app: OpenAPIHono<AppEnv>,
  deps: AppDeps,
  requireOwner: (claims: JwtClaims) => Promise<void>,
) {
  const { db } = deps;

  const service = (): LinkServers => {
    const servers = deps.casamaLink?.servers;
    if (!servers)
      throw new ApiError(404, "link_unavailable", "This server doesn't give out addresses");
    return servers;
  };
  const requireAdmin = async (claims: JwtClaims, orgId: string) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.has_role(${orgId}::uuid, 'admin') as ok`),
    );
    if (!r?.ok) throw new ApiError(403, "forbidden", "Only owners and admins can link servers");
  };
  const serverOut = (servers: LinkServers, s: ServerRow) => ({
    id: s.id,
    instance_name: s.instance_name,
    ...servers.addresses(s.label),
    status: s.status,
    status_reason: s.status_reason,
    platform: s.platform,
    version: s.version,
    last_seen_at: s.last_seen_at ? iso(s.last_seen_at) : null,
    created_at: iso(s.created_at),
  });

  app.openapi(routes.getLinkSignIn, async (c) => {
    requireClaims(c.get("claims"));
    const found = await service().describeLink(c.req.valid("param").user_code);
    if (!found)
      throw new ApiError(404, "link_not_found", "That code isn't valid any more. Start again.");
    return c.json({ ...found, expires_at: iso(found.expires_at) }, 200);
  });

  app.openapi(routes.approveLinkSignIn, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { user_code } = c.req.valid("json");
    const servers = service();
    await requireAdmin(claims, id);
    return c.json(await linkCall(() => servers.approveLink(user_code, id, claims.sub)), 200);
  });

  app.openapi(routes.listLinkServers, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const servers = service();
    await requireAdmin(claims, id);
    const limit = (await orgLimits(db, id)).remote_servers;
    // Released addresses are only reservations; the list shows servers that hold a place.
    const rows = (await servers.list(id)).filter((s) => s.status !== "released");
    return c.json(
      {
        items: rows.map((s) => serverOut(servers, s)),
        limit: typeof limit === "number" ? limit : 1,
      },
      200,
    );
  });

  app.openapi(routes.removeLinkServer, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id, server_id } = c.req.valid("param");
    const servers = service();
    await requireAdmin(claims, id);
    if (!(await servers.removeServer(id, server_id, claims.sub)))
      throw new ApiError(404, "server_not_found", "No such server");
    return c.json({ removed: server_id }, 200);
  });

  app.openapi(routes.adminLinkServers, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const servers = service();
    const rows = await servers.list();
    return c.json(
      {
        items: rows.map((s) => ({
          ...serverOut(servers, s),
          org_id: s.org_id,
          org_name: s.org_name,
        })),
        tunnels: await servers.tunnelCount(),
        zone: servers.zone,
      },
      200,
    );
  });

  const adminOne = async (servers: LinkServers, id: string) => {
    const s = (await servers.list()).find((r) => r.id === id);
    if (!s) throw new ApiError(404, "server_not_found", "No such server");
    return { ...serverOut(servers, s), org_id: s.org_id, org_name: s.org_name };
  };

  app.openapi(routes.suspendLinkServer, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const servers = service();
    const { id } = c.req.valid("param");
    if (!(await servers.suspendServer(id, c.req.valid("json").reason, claims.sub)))
      throw new ApiError(404, "server_not_found", "No such server");
    return c.json(await adminOne(servers, id), 200);
  });

  // This server's own address (the self-hosted side). Off when it was never turned on.
  const offStatus = {
    state: "off" as const,
    address: null,
    pages_address: null,
    local_address: deps.env.CASAMA_LOCAL_URL ?? null,
    linked: !!(deps.env.CASAMA_CLOUD_URL && deps.env.CASAMA_CLOUD_KEY),
    problem: null,
    connections: null,
    checked_at: null,
  };

  /** The address's status, with how notifications leave this server. */
  const withPush = async (status: typeof offStatus | RemoteAccessStatus) => ({
    ...status,
    // Its own Firebase key first; else through Casama Cloud when it is linked (the relay).
    push: deps.env.FCM_SERVICE_ACCOUNT ? "own" : status.linked ? "relay" : "off",
    private_notifications: await privateNotifications(db),
    invites: !!deps.env.SIGNUP_INVITED_ONLY && !deps.env.DISABLE_SIGNUP,
    // Live view away from the computer: what the linked workspace's plan says about it.
    ...(deps.remoteAccess?.liveView ? { live_view: deps.remoteAccess.liveView } : {}),
  });

  app.openapi(routes.adminRemoteAccess, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    return c.json(await withPush(deps.remoteAccess?.status() ?? offStatus), 200);
  });

  app.openapi(routes.checkRemoteAccess, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    return c.json(await withPush((await deps.remoteAccess?.check()) ?? offStatus), 200);
  });

  app.openapi(routes.setRemoteAccessSettings, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    await setPrivateNotifications(db, c.req.valid("json").private_notifications);
    return c.json(await withPush(deps.remoteAccess?.status() ?? offStatus), 200);
  });

  app.openapi(routes.unsuspendLinkServer, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const servers = service();
    const { id } = c.req.valid("param");
    if (!(await servers.unsuspendServer(id, claims.sub)))
      throw new ApiError(404, "server_not_found", "No such server, or it isn't suspended");
    return c.json(await adminOne(servers, id), 200);
  });
}
