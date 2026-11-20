import { randomUUID } from "node:crypto";
import { resolveTxt as dnsResolveTxt } from "node:dns/promises";
import { track } from "@casama/agent";
import { openApiConfig, registerComponents } from "@casama/contracts";
import { pgErrorCode, pgErrorMessage } from "@casama/db";
import { computerHoursMessage } from "@casama/domain";
import { captureError } from "@casama/observability";
import { SandboxError } from "@casama/sandbox";
import { OpenAPIHono } from "@hono/zod-openapi";
import { Scalar } from "@scalar/hono-api-reference";
import { sql } from "drizzle-orm";
import { cors } from "hono/cors";
import { HTTPException } from "hono/http-exception";
import { registerCasamaLinkRoutes } from "../billing/link.ts";
import { ee, registerEnterpriseFallback } from "../ee.ts";
import {
  adminPathExempt,
  requireFreshAdminAuthentication,
  requireSecondStep,
} from "./admin-security.ts";
import { corsOrigins } from "./cors.ts";
import { ApiError, problem } from "./errors.ts";
import { httpMetrics, renderMetrics } from "./metrics.ts";
import { idempotency } from "./middleware/idempotency.ts";
import { bearerKey, rateLimit } from "./middleware/rate-limit.ts";
import { registerA2aRoutes } from "./routes/a2a.ts";
import { registerAboutYouRoutes } from "./routes/about-you.ts";
import { registerAbuseRoutes } from "./routes/abuse.ts";
import { registerActionRuleRoutes } from "./routes/action-rules.ts";
import { instanceOwnerCheck, registerAdminRoutes } from "./routes/admin.ts";
import { registerAgentImportRoutes } from "./routes/agent-import.ts";
import { registerAppearanceRoutes } from "./routes/appearance.ts";
import { registerAppRoutes } from "./routes/apps.ts";
import { registerAttentionRoutes } from "./routes/attention.ts";
import { registerAutonomyRoutes } from "./routes/autonomy.ts";
import { billingFor, registerBillingRoutes } from "./routes/billing.ts";
import { registerBotSharingRoutes } from "./routes/bot-sharing.ts";
import { registerBotTemplateRoutes } from "./routes/bot-template.ts";
import { registerBotRoutes } from "./routes/bots.ts";
import { registerBrowserRoutes } from "./routes/browser.ts";
import { registerBrowserMcpRoutes } from "./routes/browser-mcp.ts";
import { registerChannelRoutes } from "./routes/channels.ts";
import { registerChatExportRoutes } from "./routes/chat-export.ts";
import { registerChatMediaRoutes } from "./routes/chat-media.ts";
import { registerChatGptRoutes } from "./routes/chatgpt.ts";
import { registerCheckinRoutes } from "./routes/checkins.ts";
import { registerComputerRoutes, sandboxApiError } from "./routes/computers.ts";
import { registerCreationRoutes } from "./routes/creations.ts";
import { registerDeviceDataRoutes } from "./routes/device-data.ts";
import { registerDevicePermissionRoutes } from "./routes/device-permissions.ts";
import { registerDomainRoutes, registerTlsAsk } from "./routes/domains.ts";
import { registerEncryptionRoutes } from "./routes/encryption.ts";
import { registerGalleryRoutes } from "./routes/gallery.ts";
import { registerGalleryContentRoutes } from "./routes/gallery-content.ts";
import { registerGlanceRoutes, widgetCaller, widgetClaims } from "./routes/glance.ts";
import { registerJoiningRoutes } from "./routes/joining.ts";
import { registerKnowledgeRoutes } from "./routes/knowledge.ts";
import { registerLimitResetRoutes } from "./routes/limit-resets.ts";
import { registerConnectAppRoutes } from "./routes/link.ts";
import { registerLinkRoutes } from "./routes/links.ts";
import { registerLiveRoutes } from "./routes/live.ts";
import { registerInternalRoutes, registerLocalRoutes } from "./routes/local.ts";
import { type InProcessEnv, registerMcpRoutes } from "./routes/mcp.ts";
import { registerModerationRoutes } from "./routes/moderation.ts";
import { registerNewsletterRoutes } from "./routes/newsletter.ts";
import { registerPackRoutes } from "./routes/packs.ts";
import { registerPageRoutes } from "./routes/pages.ts";
import { registerPasswordManagerRoutes } from "./routes/password-managers.ts";
import { registerPaymentRoutes } from "./routes/payments.ts";
import { registerPluginRoutes } from "./routes/plugins.ts";
import { registerPrivacyRoutes } from "./routes/privacy.ts";
import { registerProjectRoutes } from "./routes/projects.ts";
import { registerReactionRoutes } from "./routes/reactions.ts";
import { registerReferralRoutes } from "./routes/referrals.ts";
import { registerRemoteSettingsRoutes } from "./routes/remote-settings.ts";
import { registerReplayRoutes } from "./routes/replays.ts";
import { registerSearchRoutes } from "./routes/search.ts";
import { registerSecretStoreRoutes } from "./routes/secret-store.ts";
import { registerSignInCodeRoutes } from "./routes/signin-codes.ts";
import { registerSiteRoutes } from "./routes/sites.ts";
import { registerSkillLearningRoutes } from "./routes/skill-learning.ts";
import { registerSkillRoutes } from "./routes/skills.ts";
import { registerStarterRoutes } from "./routes/starters.ts";
import { registerSupportRoutes } from "./routes/support.ts";
import { registerSupportWebRoutes } from "./routes/support-web.ts";
import { registerSystemRoutes } from "./routes/system.ts";
import { registerTeachRoutes } from "./routes/teach.ts";
import { registerTelephonyRoutes } from "./routes/telephony.ts";
import { registerVoiceRoutes } from "./routes/voice.ts";
import { registerWaitlistRoutes } from "./routes/waitlist.ts";
import {
  registerWatchRoutes,
  watchAction,
  watchCaller,
  watchClaims,
  watchScope,
  watchSurface,
} from "./routes/watch.ts";
import { registerWatcherRoutes } from "./routes/watchers.ts";
import { registerWorkspaceFileRoutes } from "./routes/workspace-files.ts";
import { registerWorkspaceRoutes } from "./routes/workspaces.ts";
import type { AppDeps, AppEnv } from "./types.ts";
import { clientIp } from "./util.ts";

/**
 * Signed provider webhooks: billing (Dodo, RevenueCat), Stripe Issuing, the domain registrar,
 * Resend for the monthly email (D-408).
 */
export const PROVIDER_HOOKS =
  /^\/hooks\/(?:billing\/(?:dodo|revenuecat)|payments\/[0-9a-f-]{36}|registrar\/[^/]+|newsletter\/resend)\/?$/;

export function createApp(deps: AppDeps) {
  const app = new OpenAPIHono<AppEnv>({
    defaultHook: (result) => {
      if (!result.success) {
        const errors = result.error.issues.map((i) => ({
          path: i.path.join("."),
          message: i.message,
        }));
        throw new ApiError(400, "validation_failed", "Request validation failed", { errors });
      }
    },
  });
  registerComponents(app);

  app.onError(async (err, c) => {
    if (err instanceof ApiError) {
      // An owner or admin held back only by a missing second step gets a clear answer (D-093).
      const claims = c.get("claims");
      if (
        err.status === 403 &&
        err.code === "forbidden" &&
        err.message.startsWith("Only owners and admins") &&
        claims &&
        claims.aal !== "aal2"
      ) {
        const [row] = await deps.db
          .execute<{ blocked: boolean }>(sql`
            select exists (
              select 1 from public.memberships m join public.organizations o on o.id = m.org_id
              where m.user_id = ${claims.sub}::uuid and m.role in ('owner', 'admin') and o.require_mfa
            ) as blocked`)
          .catch(() => [] as Array<{ blocked: boolean }>);
        if (row?.blocked)
          return problem(
            c,
            new ApiError(
              403,
              "mfa_required",
              "This workspace requires two-step sign-in for owners and admins. Sign in with your second step and try again.",
            ),
          );
      }
      return problem(c, err);
    }
    // Computers refuse to start for suspended or unverified workspaces (D-094).
    if (err instanceof Error && err.message === "workspace_suspended")
      return problem(
        c,
        new ApiError(
          403,
          "workspace_suspended",
          "This workspace is suspended. Contact the instance owner.",
        ),
      );
    // The plan's limit on computers running at once (D-249); SQL triggers use PT402 the same way.
    if (err instanceof Error && err.message === "running_limit")
      return problem(
        c,
        new ApiError(
          402,
          "plan_limit",
          `Your plan runs ${(err as Error & { limit?: number }).limit ?? "a limited number of"} computers at once, and they're all in use. Stop one or upgrade.`,
        ),
      );
    if (err instanceof Error && err.message === "email_unverified")
      return problem(
        c,
        new ApiError(403, "email_unverified", "Confirm your email address to start a computer."),
      );
    // A computer that can't start for billing or room reasons (D-248).
    if (err instanceof Error && err.message === "out_of_credits")
      return problem(
        c,
        new ApiError(
          402,
          "out_of_credits",
          "The workspace is out of credits. Add credits or change plans in Billing.",
        ),
      );
    if (err instanceof Error && err.message === "computer_hours_exceeded")
      return problem(c, new ApiError(402, "computer_hours_exceeded", computerHoursMessage()));
    if (err instanceof Error && err.message === "plan_limit")
      return problem(
        c,
        new ApiError(
          402,
          "plan_limit",
          "Your plan runs fewer computers than this workspace has. Upgrade to use this one.",
        ),
      );
    if (err instanceof Error && err.message === "capacity_full")
      return problem(
        c,
        new ApiError(
          503,
          "capacity_full",
          "Casama's computers are all busy right now. Try again in a few minutes.",
        ),
      );
    // A computer that can't be reached is an expected state (stopped, restarting, offline device),
    // not a server bug: answer with what happened instead of a 500.
    if (err instanceof SandboxError) {
      deps.logger.warn("sandbox error", {
        request_id: c.get("requestId"),
        path: c.req.path,
        code: err.code,
        error: err.message,
      });
      return problem(c, sandboxApiError(err));
    }
    if (err instanceof HTTPException) {
      return problem(
        c,
        new ApiError(
          err.status as 400,
          err.status === 400 ? "bad_request" : "http_error",
          err.message,
        ),
      );
    }
    // Plan limits raised inside the database (seats, workspaces per person) open the paywall.
    if (pgErrorCode(err) === "PT402") {
      const what = pgErrorMessage(err) ?? "plan_limit";
      return problem(
        c,
        new ApiError(
          402,
          what === "workspace_limit" ? "workspace_limit" : "plan_limit",
          what === "workspace_limit"
            ? "You own as many workspaces as you can."
            : "Your plan's limit is reached.",
        ),
      );
    }
    deps.logger.error("unhandled error", {
      request_id: c.get("requestId"),
      path: c.req.path,
      error: pgErrorMessage(err) ?? (err as Error).message,
      code: pgErrorCode(err),
    });
    captureError(err, { request_id: c.get("requestId"), path: c.req.path });
    return problem(c, new ApiError(500, "internal_error", "Something went wrong"));
  });
  app.notFound((c) => problem(c, new ApiError(404, "not_found", "No such route")));

  // Browsers (the web app, Casama for Chrome) call the API from another origin.
  const allowedOrigin = corsOrigins(deps.env);
  // Gallery use counts are public aggregate data the web gallery reads from any site (D-315).
  app.use(
    "/v1/gallery/stats",
    cors({ origin: "*", allowMethods: ["GET", "OPTIONS"], maxAge: 86_400 }),
  );
  // Reports from the sites zone's own page, by visitors with no account (SITES-AND-DOMAINS-PLAN §7.11).
  app.use(
    "/v1/site-reports",
    cors({
      origin: "*",
      allowMethods: ["POST", "OPTIONS"],
      allowHeaders: ["content-type"],
      maxAge: 86_400,
    }),
  );
  // Casama Help on the websites (D-401): casama.ai and docs call it with no account.
  const webOrigins = new Set(deps.env.SUPPORT_WEB_ORIGINS.split(",").map((o) => o.trim()));
  app.use(
    "/v1/support/web/*",
    cors({
      origin: (origin) => (webOrigins.has(origin) ? origin : allowedOrigin(origin)),
      allowMethods: ["GET", "POST", "OPTIONS"],
      allowHeaders: ["content-type"],
      maxAge: 86_400,
    }),
  );
  // The waitlist's pages on casama.ai (docs/WAITLIST-PLAN.md): visitors with no account join,
  // claim an invite code and fetch the sign-up puzzle those two need.
  // The apps call the puzzle route too, so these allow the same headers as every other route.
  for (const path of [
    "/v1/waitlist",
    "/v1/waitlist/*",
    "/v1/invites/preview",
    "/v1/signup/challenge",
  ])
    app.use(
      path,
      cors({
        origin: (origin) => (webOrigins.has(origin) ? origin : allowedOrigin(origin)),
        allowMethods: ["GET", "POST", "OPTIONS"],
        allowHeaders: [
          "authorization",
          "content-type",
          "idempotency-key",
          "x-request-id",
          "x-casama-surface",
        ],
        exposeHeaders: ["x-request-id", "retry-after"],
        maxAge: 600,
      }),
    );
  app.use(
    "*",
    cors({
      origin: (origin) => allowedOrigin(origin),
      allowHeaders: [
        "authorization",
        "content-type",
        "idempotency-key",
        "last-event-id",
        "x-request-id",
        "x-casama-surface",
      ],
      allowMethods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
      exposeHeaders: ["x-request-id", "idempotent-replayed", "retry-after", "content-disposition"],
      maxAge: 600,
    }),
  );

  // Request id and security headers.
  app.use("*", async (c, next) => {
    const id = c.req.header("x-request-id") ?? randomUUID();
    c.set("requestId", id);
    await next();
    c.header("x-request-id", id);
    c.header("x-content-type-options", "nosniff");
    c.header("referrer-policy", "no-referrer");
    if (deps.env.NODE_ENV === "production")
      c.header("strict-transport-security", "max-age=63072000; includeSubDomains");
  });

  // Optional bearer auth: verifies the token when present; routes that need it call requireClaims.
  // A widget key (D-405) reads as its person on the few routes it may use, and nowhere else.
  const widgetAuth = widgetCaller(deps);
  // A watch key (D-410) acts as its person on the routes a watch may use, within its limits.
  const watchAuth = watchCaller(deps);
  const watchGuard = watchScope(deps.db);
  app.use("/v1/*", async (c, next) => {
    // Hosted MCP tool calls (D-117) arrive in-process with their person already resolved.
    const inProcess = (c.env as InProcessEnv | undefined)?.casamaClaims;
    if (inProcess) {
      c.set("claims", inProcess);
      return next();
    }
    const header = c.req.header("authorization");
    if (header?.startsWith("Bearer ")) {
      try {
        c.set("claims", await deps.verifyToken(header.slice(7)));
      } catch {
        throw new ApiError(401, "invalid_token", "The access token is invalid or expired");
      }
    } else if (header?.startsWith("Widget ")) {
      const widget = await widgetAuth(c.req.method, c.req.path, header.slice(7).trim());
      c.set("widgetKey", widget);
      c.set("claims", widgetClaims(widget));
    } else if (header?.startsWith("Watch ")) {
      const watch = await watchAuth(
        c.req.method,
        c.req.path,
        header.slice(6).trim(),
        clientIp((n) => c.req.header(n), deps.env.TRUSTED_CLIENT_IP_HEADER),
      );
      c.set("watchKey", watch);
      c.set("claims", watchClaims(watch));
      // Borrowed routes stay in the key's workspace (row-level security alone would open all the
      // person's workspaces).
      await watchGuard(watch, c.req.method, c.req.path, new URL(c.req.url).searchParams);
      await next();
      // What watches are used for (§15): suggestions done, routines run, runs stopped, replies
      // read aloud. Decisions and asks are counted in their own routes.
      const action = watchAction(c.req.method, c.req.path);
      if (action && c.res.status < 300)
        track(deps.db, {
          event: "watch_action",
          userId: watch.userId,
          orgId: watch.orgId,
          properties: {
            action,
            surface: watchSurface(c.req.header("x-casama-surface")),
            platform: watch.platform,
          },
        });
      return;
    }
    await next();
  });
  // Before route validation and idempotent-response replay: expired proof must never mutate.
  app.use("/v1/admin/*", async (c, next) => {
    const claims = c.get("claims");
    requireFreshAdminAuthentication(c.req.method, c.req.path, claims);
    if (claims && !adminPathExempt(c.req.method, c.req.path))
      await requireSecondStep(deps.db, claims, !["GET", "HEAD"].includes(c.req.method));
    await next();
  });
  app.use("/v1/*", httpMetrics);
  app.get("/metrics", async (c) => {
    const token = deps.env.METRICS_TOKEN;
    if (token && c.req.header("authorization") !== `Bearer ${token}`)
      throw new ApiError(401, "unauthorized", "Metrics need the metrics token");
    if (!token && deps.env.NODE_ENV === "production")
      throw new ApiError(404, "not_found", "Set METRICS_TOKEN to enable metrics");
    return c.text(await renderMetrics(deps.db), 200, {
      "content-type": "text/plain; version=0.0.4",
    });
  });
  app.use(
    "/v1/*",
    rateLimit({
      perMinute: deps.env.RATE_LIMIT_PER_MINUTE,
      trustedIpHeader: deps.env.TRUSTED_CLIENT_IP_HEADER,
      // A watch counts apart from its person's phone (it has its own 60 a minute too).
      key: (c) => {
        const watch = c.get("watchKey" as never) as { id: string } | undefined;
        return watch ? `watch:${watch.id}` : undefined;
      },
    }),
  );
  // Signed provider webhooks (Dodo and RevenueCat billing, Stripe Issuing, the domain registrar)
  // arrive in bursts from a few provider addresses and check their own signatures, and a 429 on a
  // Stripe Issuing authorization request declines the card. They get their own, much higher
  // per-address budget; every other hook keeps the ordinary one.
  const hookLimit = rateLimit({
    perMinute: deps.env.RATE_LIMIT_PER_MINUTE,
    trustedIpHeader: deps.env.TRUSTED_CLIENT_IP_HEADER,
  });
  const providerHookLimit = rateLimit({
    perMinute: Math.max(2000, deps.env.RATE_LIMIT_PER_MINUTE * 10),
    trustedIpHeader: deps.env.TRUSTED_CLIENT_IP_HEADER,
  });
  app.use("/hooks/*", (c, next) =>
    PROVIDER_HOOKS.test(c.req.path) ? providerHookLimit(c, next) : hookLimit(c, next),
  );
  app.use(
    "/link/*",
    rateLimit({
      perMinute: deps.env.RATE_LIMIT_PER_MINUTE * 10,
      trustedIpHeader: deps.env.TRUSTED_CLIENT_IP_HEADER,
    }),
  );
  // A2A and hosted MCP calls count per token (callers can share an address); their unauthenticated
  // requests and the OAuth endpoints count per address. OAuth client registration is the
  // tightest, since anyone can call it and each one writes a row.
  const trustedIpHeader = deps.env.TRUSTED_CLIENT_IP_HEADER;
  app.use(
    "/a2a/*",
    rateLimit({ perMinute: deps.env.RATE_LIMIT_PER_MINUTE, trustedIpHeader, key: bearerKey }),
  );
  app.use(
    "/mcp",
    rateLimit({ perMinute: deps.env.RATE_LIMIT_PER_MINUTE, trustedIpHeader, key: bearerKey }),
  );
  // At the default 120 a minute: 10 registrations and 30 other OAuth calls a minute per address.
  const perMinute = deps.env.RATE_LIMIT_PER_MINUTE;
  app.use(
    "/oauth/register",
    rateLimit({ perMinute: Math.max(1, Math.floor(perMinute / 12)), trustedIpHeader }),
  );
  app.use(
    "/oauth/*",
    rateLimit({ perMinute: Math.max(1, Math.floor(perMinute / 4)), trustedIpHeader }),
  );
  app.use("/v1/*", idempotency(deps.db));

  registerSystemRoutes(app, deps);
  registerSupportRoutes(app, deps);
  registerSupportWebRoutes(app, deps);
  registerModerationRoutes(app, deps);
  registerNewsletterRoutes(app, deps);
  registerWorkspaceRoutes(app, deps);
  registerJoiningRoutes(app, deps);
  registerReferralRoutes(app, deps);
  registerWaitlistRoutes(app, deps);
  registerBotRoutes(app, deps);
  registerReactionRoutes(app, deps);
  registerBrowserRoutes(app, deps);
  registerChatGptRoutes(app, deps);
  registerComputerRoutes(app, deps);
  registerLiveRoutes(app, deps);
  registerVoiceRoutes(app, deps);
  registerLocalRoutes(app, deps);
  registerAdminRoutes(app, deps);
  registerRemoteSettingsRoutes(app, deps);
  registerTlsAsk(app as never, deps);
  registerInternalRoutes(app as never, deps);
  registerBrowserMcpRoutes(app as never, deps);
  registerAbuseRoutes(app, deps);
  registerAutonomyRoutes(app, deps);
  registerBillingRoutes(app, deps);
  registerLimitResetRoutes(app, deps);
  registerPrivacyRoutes(app, deps);
  registerAppearanceRoutes(app, deps, deps.wallpapers);
  registerGalleryRoutes(app, deps);
  registerGalleryContentRoutes(app, deps);
  registerAppRoutes(app, deps, deps.apps);
  registerSearchRoutes(app, deps);
  registerSkillRoutes(app, deps);
  registerBotTemplateRoutes(app, deps);
  registerProjectRoutes(app, deps);
  registerCheckinRoutes(app, deps);
  registerActionRuleRoutes(app, deps);
  registerWatcherRoutes(app, deps);
  registerPageRoutes(app, deps);
  registerSiteRoutes(app, deps);
  registerDomainRoutes(app, deps);
  registerTeachRoutes(app, deps);
  registerPluginRoutes(app, deps);
  registerPackRoutes(app, deps);
  registerAgentImportRoutes(app, deps);
  registerWorkspaceFileRoutes(app, deps);
  registerKnowledgeRoutes(app, deps);
  registerSkillLearningRoutes(app, deps);
  registerReplayRoutes(app, deps);
  registerPasswordManagerRoutes(app, deps);
  registerBotSharingRoutes(app, deps);
  registerChannelRoutes(app, deps);
  registerEncryptionRoutes(app, deps);
  registerA2aRoutes(app, deps);
  registerTelephonyRoutes(app, deps);
  registerPaymentRoutes(app, deps);
  registerLinkRoutes(app, deps);
  registerSecretStoreRoutes(app, deps);
  registerDeviceDataRoutes(app, deps);
  registerDevicePermissionRoutes(app, deps);
  registerAttentionRoutes(app, deps);
  registerAboutYouRoutes(app, deps);
  registerStarterRoutes(app, deps);
  registerChatMediaRoutes(app, deps);
  registerCreationRoutes(app, deps);
  registerGlanceRoutes(app, deps);
  registerWatchRoutes(app, deps);
  registerChatExportRoutes(app, deps);
  registerConnectAppRoutes(app, deps, instanceOwnerCheck(deps));
  registerSignInCodeRoutes(app, deps);
  registerMcpRoutes(app, deps);
  // Enterprise features (ee/, commercial license, D-073); inert without a license key. The
  // open-source edition (ee/ deleted, D-339) answers their routes with 402.
  if (!ee) registerEnterpriseFallback(app as never);
  else
    ee.registerEnterpriseRoutes(app as never, {
      db: deps.db,
      licenseKey: deps.env.CASAMA_LICENSE_KEY,
      licensePublicKey:
        deps.env.NODE_ENV === "test" ? deps.env.CASAMA_LICENSE_PUBLIC_KEY : undefined,
      authAdmin: deps.env.SUPABASE_SERVICE_ROLE_KEY
        ? {
            url: `${deps.env.SUPABASE_URL}/auth/v1`,
            serviceRoleKey: deps.env.SUPABASE_SERVICE_ROLE_KEY,
          }
        : undefined,
      claims: (c) => c.get("claims" as never),
      verificationSecret: deps.env.SUPABASE_JWT_SECRET,
      resolveTxt: (d: string) => (deps.resolveTxt ?? dnsResolveTxt)(d),
    });
  const billing = billingFor(deps);
  if (billing.enabled && deps.casamaLink)
    registerCasamaLinkRoutes(app as never, {
      db: deps.db,
      billing,
      trustedIpHeader: deps.env.TRUSTED_CLIENT_IP_HEADER,
      ...deps.casamaLink,
    });

  app.doc31("/openapi.json", (c) => ({
    ...openApiConfig,
    servers: [{ url: new URL(c.req.url).origin }],
  }));
  app.get(
    "/docs",
    Scalar({ url: "/openapi.json", pageTitle: `${openApiConfig.info.title} reference` }),
  );

  return app;
}
