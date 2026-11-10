import { randomUUID } from "node:crypto";
import { OpenAPIHono } from "@hono/zod-openapi";
import { openApiConfig, registerComponents } from "@kasama/contracts";
import { pgErrorCode, pgErrorMessage } from "@kasama/db";
import { registerEnterpriseRoutes } from "@kasama/ee";
import { captureError } from "@kasama/observability";
import { Scalar } from "@scalar/hono-api-reference";
import { sql } from "drizzle-orm";
import { cors } from "hono/cors";
import { HTTPException } from "hono/http-exception";
import { registerConnectRoutes } from "../billing/connect.ts";
import { ApiError, problem } from "./errors.ts";
import { httpMetrics, renderMetrics } from "./metrics.ts";
import { idempotency } from "./middleware/idempotency.ts";
import { rateLimit } from "./middleware/rate-limit.ts";
import { registerAbuseRoutes } from "./routes/abuse.ts";
import { registerActionRuleRoutes } from "./routes/action-rules.ts";
import { registerAdminRoutes } from "./routes/admin.ts";
import { registerAppearanceRoutes } from "./routes/appearance.ts";
import { registerAppRoutes } from "./routes/apps.ts";
import { registerAutonomyRoutes } from "./routes/autonomy.ts";
import { billingFor, registerBillingRoutes } from "./routes/billing.ts";
import { registerBotTemplateRoutes } from "./routes/bot-template.ts";
import { registerBotRoutes } from "./routes/bots.ts";
import { registerChatGptRoutes } from "./routes/chatgpt.ts";
import { registerCheckinRoutes } from "./routes/checkins.ts";
import { registerComputerRoutes } from "./routes/computers.ts";
import { registerLiveRoutes } from "./routes/live.ts";
import { registerInternalRoutes, registerLocalRoutes } from "./routes/local.ts";
import { type InProcessEnv, registerMcpRoutes } from "./routes/mcp.ts";
import { registerPageRoutes } from "./routes/pages.ts";
import { registerAgentImportRoutes } from "./routes/agent-import.ts";
import { registerPluginRoutes } from "./routes/plugins.ts";
import { registerPrivacyRoutes } from "./routes/privacy.ts";
import { registerTeachRoutes } from "./routes/teach.ts";
import { registerProjectRoutes } from "./routes/projects.ts";
import { registerSearchRoutes } from "./routes/search.ts";
import { registerSkillRoutes } from "./routes/skills.ts";
import { registerSystemRoutes } from "./routes/system.ts";
import { registerVoiceRoutes } from "./routes/voice.ts";
import { registerWatcherRoutes } from "./routes/watchers.ts";
import { registerWorkspaceFileRoutes } from "./routes/workspace-files.ts";
import { registerWorkspaceRoutes } from "./routes/workspaces.ts";
import type { AppDeps, AppEnv } from "./types.ts";

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
    if (err instanceof Error && err.message === "email_unverified")
      return problem(
        c,
        new ApiError(403, "email_unverified", "Confirm your email address to start a computer."),
      );
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

  // Browsers (the web app) call the API from another origin.
  const allowed = new Set([
    deps.env.PUBLIC_APP_URL,
    ...deps.env.CORS_ORIGINS.split(",")
      .map((o) => o.trim())
      .filter(Boolean),
  ]);
  app.use(
    "*",
    cors({
      origin: (origin) => {
        if (!origin) return null;
        if (allowed.has(origin)) return origin;
        if (
          deps.env.NODE_ENV !== "production" &&
          /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)
        )
          return origin;
        return null;
      },
      allowHeaders: [
        "authorization",
        "content-type",
        "idempotency-key",
        "last-event-id",
        "x-request-id",
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
  app.use("/v1/*", async (c, next) => {
    // Hosted MCP tool calls (D-117) arrive in-process with their person already resolved.
    const inProcess = (c.env as InProcessEnv | undefined)?.kasamaClaims;
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
    }
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
  app.use("/v1/*", rateLimit({ perMinute: deps.env.RATE_LIMIT_PER_MINUTE }));
  app.use("/hooks/*", rateLimit({ perMinute: deps.env.RATE_LIMIT_PER_MINUTE }));
  app.use("/connect/*", rateLimit({ perMinute: deps.env.RATE_LIMIT_PER_MINUTE * 10 }));
  app.use("/v1/*", idempotency(deps.db));

  registerSystemRoutes(app, deps);
  registerWorkspaceRoutes(app, deps);
  registerBotRoutes(app, deps);
  registerChatGptRoutes(app, deps);
  registerComputerRoutes(app, deps);
  registerLiveRoutes(app, deps);
  registerVoiceRoutes(app, deps);
  registerLocalRoutes(app, deps);
  registerAdminRoutes(app, deps);
  registerInternalRoutes(app as never, deps);
  registerAbuseRoutes(app, deps);
  registerAutonomyRoutes(app, deps);
  registerBillingRoutes(app, deps);
  registerPrivacyRoutes(app, deps);
  registerAppearanceRoutes(app, deps, deps.wallpapers);
  registerAppRoutes(app, deps, deps.apps);
  registerSearchRoutes(app, deps);
  registerSkillRoutes(app, deps);
  registerBotTemplateRoutes(app, deps);
  registerProjectRoutes(app, deps);
  registerCheckinRoutes(app, deps);
  registerActionRuleRoutes(app, deps);
  registerWatcherRoutes(app, deps);
  registerPageRoutes(app, deps);
  registerTeachRoutes(app, deps);
  registerPluginRoutes(app, deps);
  registerAgentImportRoutes(app, deps);
  registerWorkspaceFileRoutes(app, deps);
  registerMcpRoutes(app, deps);
  // Enterprise features (ee/, commercial license, D-073); inert without a license key.
  registerEnterpriseRoutes(app as never, {
    db: deps.db,
    licenseKey: deps.env.KASAMA_LICENSE_KEY,
    licensePublicKey: deps.env.NODE_ENV === "test" ? deps.env.KASAMA_LICENSE_PUBLIC_KEY : undefined,
    authAdmin: deps.env.SUPABASE_SERVICE_ROLE_KEY
      ? {
          url: `${deps.env.SUPABASE_URL}/auth/v1`,
          serviceRoleKey: deps.env.SUPABASE_SERVICE_ROLE_KEY,
        }
      : undefined,
    claims: (c) => c.get("claims" as never),
  });
  const billing = billingFor(deps);
  if (billing.enabled && deps.connect)
    registerConnectRoutes(app as never, { db: deps.db, billing, ...deps.connect });

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
