/**
 * Casama Link: live view away from the computer (D-296), cloud side.
 *
 *   POST /link/v1/turn-credentials   { ttl_seconds? }
 *
 * Live view is WebRTC through a relay. A self-hosted server's own relay sits behind its router, so
 * a phone on another network can't reach it. For a linked server whose workspace's plan has live
 * view away from home, Casama Cloud hands out short-lived credentials for a relay both sides can
 * reach (Cloudflare's TURN service): the phone uses them directly, and the bot's computer uses
 * them through a forwarder in the server's own relay container, because a bot's computer has no
 * route to the internet of its own.
 *
 * Whoever holds credentials can relay traffic at our cost until they expire, so they last half a
 * day at most, are counted per key and day, and are given only on plans that include this.
 */
import type { Database } from "@casama/db";
import type { Hono } from "hono";
import { z } from "zod";
import { orgLimits } from "../billing/limits.ts";
import { linkCaller, linkSuspended } from "./keys.ts";

export interface TurnCredentials {
  urls: string[];
  username: string;
  credential: string;
}

export interface TurnProvider {
  /** Where the relay answers (host:port), for the forwarder in a server's relay container. */
  readonly upstream: string;
  generate(ttlSeconds: number): Promise<TurnCredentials>;
}

export interface CloudflareTurnOptions {
  keyId: string;
  apiToken: string;
  /** Tests point this at a fake. */
  apiUrl?: string;
  fetch?: typeof fetch;
}

/** Cloudflare's TURN service: one key, short-lived credentials from its API. */
export class CloudflareTurn implements TurnProvider {
  readonly upstream = "turn.cloudflare.com:3478";
  private readonly o: CloudflareTurnOptions;
  constructor(o: CloudflareTurnOptions) {
    this.o = o;
  }

  async generate(ttlSeconds: number): Promise<TurnCredentials> {
    const base = (this.o.apiUrl ?? "https://rtc.live.cloudflare.com/v1").replace(/\/$/, "");
    const res = await (this.o.fetch ?? fetch)(
      `${base}/turn/keys/${this.o.keyId}/credentials/generate-ice-servers`,
      {
        method: "POST",
        headers: {
          authorization: `Bearer ${this.o.apiToken}`,
          "content-type": "application/json",
        },
        body: JSON.stringify({ ttl: ttlSeconds }),
        signal: AbortSignal.timeout(15_000),
      },
    );
    if (!res.ok) throw new Error(`The relay service answered ${res.status}`);
    const json = (await res.json()) as {
      iceServers?: Array<{ urls?: string[] | string; username?: string; credential?: string }>;
    };
    // The answer lists a STUN entry and a TURN entry; only the one with credentials relays.
    const turn = json.iceServers?.find((s) => s.username && s.credential);
    const urls = turn ? (Array.isArray(turn.urls) ? turn.urls : [turn.urls ?? ""]) : [];
    if (!turn?.username || !turn.credential || !urls.length)
      throw new Error("The relay service gave no credentials");
    return {
      // Port 53 is blocked by browsers and only slows the connection down.
      urls: urls.filter((u) => u && !/:53(\?|$)/.test(u)),
      username: turn.username,
      credential: turn.credential,
    };
  }
}

const Body = z.object({ ttl_seconds: z.number().int().min(60).max(43_200).optional() });

/** Whether the workspace's plan has live view away from the computer. */
export async function liveViewIncluded(db: Database, orgId: string) {
  const allowed = (await orgLimits(db, orgId)).link_live_view;
  return typeof allowed === "number" && allowed > 0;
}

export function registerTurnRoutes(
  app: Hono,
  o: { db: Database; turn: TurnProvider; perDay?: number; now?: () => number },
) {
  // A server keeps what it is given for hours, so a handful a day is all an honest one asks for.
  const perDay = o.perDay ?? 24;
  const now = o.now ?? Date.now;
  const windows = new Map<string, { start: number; count: number }>();

  app.post("/link/v1/turn-credentials", async (c) => {
    const k = linkCaller(c);
    if (!k.scopes.includes("remote_access"))
      return c.json(
        { code: "remote_access_unavailable", message: "This key can't use the relay" },
        403,
      );
    const parsed = Body.safeParse(await c.req.json().catch(() => ({})));
    if (!parsed.success)
      return c.json({ code: "bad_request", message: "The request isn't valid" }, 400);
    if (await linkSuspended(o.db, k))
      return c.json(
        { code: "suspended", message: "Remote access is turned off for this server" },
        403,
      );
    if (!(await liveViewIncluded(o.db, k.orgId)))
      return c.json(
        {
          code: "plan_limit",
          message:
            "Live view away from the computer comes with Plus and up. It still works on the computer itself.",
        },
        402,
      );

    const t = now();
    let w = windows.get(k.keyId);
    if (!w || t - w.start >= 86_400_000) {
      w = { start: t, count: 0 };
      windows.set(k.keyId, w);
    }
    if (w.count >= perDay) {
      const retry = Math.max(1, Math.ceil((w.start + 86_400_000 - t) / 1000));
      c.header("retry-after", String(retry));
      return c.json({ code: "rate_limited", message: "Too many live view sessions today" }, 429);
    }
    w.count++;

    // Long enough for a stream that stays open all day: the bot's computer gets these once, when
    // its streamer starts.
    const ttl = parsed.data.ttl_seconds ?? 43_200;
    try {
      const creds = await o.turn.generate(ttl);
      return c.json({ ice_servers: [creds], upstream: o.turn.upstream, expires_in: ttl });
    } catch {
      return c.json(
        { code: "relay_unavailable", message: "The relay isn't available right now. Try again." },
        503,
      );
    }
  });
}
