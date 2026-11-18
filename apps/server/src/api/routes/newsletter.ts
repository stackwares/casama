/**
 * Casama's monthly email from the app (D-408): read and set the switch, and Resend's webhook that
 * turns it off when someone unsubscribes from an email. Only on servers with
 * NEWSLETTER_RESEND_API_KEY (Casama Cloud); elsewhere the switch reads as unavailable.
 */
import { routes } from "@casama/contracts";
import type { JwtClaims } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import {
  applyResendEvent,
  newsletterConfig,
  newsletterState,
  setNewsletterChoice,
  verifySvix,
} from "../../services/newsletter.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

function requireClaims(claims: JwtClaims | undefined): JwtClaims {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
}

export function registerNewsletterRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const config = newsletterConfig(deps.env, deps.newsletterFetch);
  const log = (msg: string, extra?: Record<string, unknown>) => deps.logger.warn(msg, extra);

  app.openapi(routes.getNewsletter, async (c) => {
    const claims = requireClaims(c.get("claims"));
    if (!config) return c.json({ available: false, subscribed: false, asked: false }, 200);
    return c.json({ available: true, ...(await newsletterState(db, claims.sub)) }, 200);
  });

  app.openapi(routes.setNewsletter, async (c) => {
    const claims = requireClaims(c.get("claims"));
    if (!config)
      throw new ApiError(
        404,
        "newsletter_unavailable",
        "This server doesn't send Casama's monthly email",
      );
    const body = c.req.valid("json");
    const state = await setNewsletterChoice(
      db,
      config,
      claims.sub,
      { subscribed: body.subscribed, via: body.from ?? "settings" },
      log,
    );
    return c.json({ available: true, ...state }, 200);
  });

  // Resend's webhook (svix-signed): contact.updated, contact.deleted, contact.topics.updated.
  app.post("/hooks/newsletter/resend", async (c) => {
    if (!config?.webhookSecret) throw new ApiError(404, "not_found", "No such route");
    const rawBody = await c.req.text();
    if (!verifySvix(config.webhookSecret, c.req.raw.headers, rawBody)) {
      deps.logger.warn("newsletter webhook rejected", { code: "bad_signature" });
      throw new ApiError(401, "bad_signature", "Webhook signature does not match");
    }
    let event: Parameters<typeof applyResendEvent>[2];
    try {
      event = JSON.parse(rawBody);
    } catch {
      throw new ApiError(400, "bad_json", "The body isn't JSON");
    }
    const changed = await applyResendEvent(db, config, event);
    if (changed) deps.logger.info("newsletter turned off from an email", { type: event.type });
    return c.json({ ok: true }, 200);
  });
}
