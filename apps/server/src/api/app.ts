import { randomUUID } from "node:crypto";
import { OpenAPIHono } from "@hono/zod-openapi";
import { openApiConfig, registerComponents } from "@kasama/contracts";
import { pgErrorCode, pgErrorMessage } from "@kasama/db";
import { captureError } from "@kasama/observability";
import { Scalar } from "@scalar/hono-api-reference";
import { HTTPException } from "hono/http-exception";
import { ApiError, problem } from "./errors.ts";
import { idempotency } from "./middleware/idempotency.ts";
import { rateLimit } from "./middleware/rate-limit.ts";
import { registerBotRoutes } from "./routes/bots.ts";
import { registerComputerRoutes } from "./routes/computers.ts";
import { registerSystemRoutes } from "./routes/system.ts";
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

  app.onError((err, c) => {
    if (err instanceof ApiError) return problem(c, err);
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
  app.use("/v1/*", rateLimit({ perMinute: deps.env.RATE_LIMIT_PER_MINUTE }));
  app.use("/v1/*", idempotency(deps.db));

  registerSystemRoutes(app, deps);
  registerWorkspaceRoutes(app, deps);
  registerBotRoutes(app, deps);
  registerComputerRoutes(app, deps);

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
