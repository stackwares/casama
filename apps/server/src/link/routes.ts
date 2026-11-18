/**
 * Casama Link, what a self-hosted server calls on Casama Cloud (D-296):
 *
 *   POST   /link/v1/sign-in/start        ask to be linked; answers a code to show and a device code
 *   POST   /link/v1/sign-in/poll         the key, once a workspace admin approved the code
 *   PUT    /link/v1/remote            this server's address and its connector's secret
 *   GET    /link/v1/remote            the address and whether a connector is attached
 *   POST   /link/v1/remote/heartbeat  "I'm here"; says whether to ask for the address again,
 *                                        and whether the plan has live view away from the computer
 *   DELETE /link/v1/remote            turn remote access off (the address stays reserved)
 *
 * Linking has no key yet; everything else needs one with the remote_access scope. Answers and
 * errors are plain JSON ({ code, message }), like the rest of /link/v1.
 */
import type { Context, Hono } from "hono";
import { z } from "zod";
import { rateLimit } from "../api/middleware/rate-limit.ts";
import { linkCaller } from "./keys.ts";
import { LinkError, type LinkServers } from "./servers.ts";

const Server = z.object({
  instance_id: z.string().min(8).max(64),
  instance_name: z.string().max(200).optional(),
  platform: z.string().max(200).optional(),
  version: z.string().max(200).optional(),
});
const Heartbeat = Server.extend({ generation: z.number().int().optional() });
const Poll = z.object({ device_code: z.string().min(16).max(200) });

export function registerRemoteRoutes(
  app: Hono,
  o: {
    servers: LinkServers;
    trustedIpHeader?: string;
    /** Whether a workspace's plan has live view away from the computer; unset: no relay here. */
    liveView?: (orgId: string) => Promise<boolean>;
  },
) {
  const { servers } = o;

  /** Runs a handler, turning the service's refusals into this API's { code, message }. */
  const answer = async (c: Context, fn: () => Promise<Response>) => {
    try {
      return await fn();
    } catch (e) {
      if (e instanceof LinkError)
        return c.json({ code: e.code, message: e.message }, e.status as 400);
      throw e;
    }
  };
  const body = async <T extends z.ZodType>(c: Context, schema: T): Promise<z.infer<T>> => {
    const parsed = schema.safeParse(await c.req.json().catch(() => null));
    if (!parsed.success) throw new LinkError(400, "bad_request", "The request isn't valid");
    return parsed.data;
  };

  // Linking is open to anyone who can reach this cloud, so it is limited per caller address: a
  // handful of starts, and enough polls for one server waiting on its approval.
  app.use(
    "/link/v1/sign-in/start",
    rateLimit({ perMinute: 10, trustedIpHeader: o.trustedIpHeader }),
  );
  app.use(
    "/link/v1/sign-in/poll",
    rateLimit({ perMinute: 60, trustedIpHeader: o.trustedIpHeader }),
  );

  app.post("/link/v1/sign-in/start", (c) =>
    answer(c, async () => c.json(await servers.startLink(await body(c, Server)))),
  );

  app.post("/link/v1/sign-in/poll", (c) =>
    answer(c, async () => c.json(await servers.pollLink((await body(c, Poll)).device_code))),
  );

  app.put("/link/v1/remote", (c) =>
    answer(c, async () => c.json(await servers.provision(linkCaller(c), await body(c, Server)))),
  );

  /**
   * Live view away from the computer, so the server can say what its plan gives: "included",
   * "plan" (a higher plan has it), or null when this cloud runs no relay.
   */
  const liveView = async (orgId: string) =>
    o.liveView ? ((await o.liveView(orgId).catch(() => false)) ? "included" : "plan") : null;

  app.get("/link/v1/remote", (c) =>
    answer(c, async () => {
      const caller = linkCaller(c);
      const found = await servers.describe(caller, c.req.query("instance_id") ?? "");
      if (!found) throw new LinkError(404, "not_found", "This server has no address");
      return c.json({ ...found, live_view: await liveView(caller.orgId) });
    }),
  );

  app.post("/link/v1/remote/heartbeat", (c) =>
    answer(c, async () => {
      const caller = linkCaller(c);
      const beat = await servers.heartbeat(caller, await body(c, Heartbeat));
      return c.json({ ...beat, live_view: await liveView(caller.orgId) });
    }),
  );

  app.delete("/link/v1/remote", (c) =>
    answer(c, async () => {
      const released = await servers.release(linkCaller(c), c.req.query("instance_id") ?? "");
      return c.json({ released });
    }),
  );
}
