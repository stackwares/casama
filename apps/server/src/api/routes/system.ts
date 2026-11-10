import type { OpenAPIHono } from "@hono/zod-openapi";
import { API_VERSION, PRODUCT_NAME, routes } from "@kasama/contracts";
import { DEFAULT_MODELS, defaultModelFor } from "@kasama/domain";
import { modelOverrides } from "../../env.ts";
import type { AppDeps, AppEnv } from "../types.ts";

export function registerSystemRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  app.openapi(routes.healthz, (c) => c.json({ status: "ok" as const }, 200));

  app.openapi(routes.readyz, async (c) => {
    const checks: Record<string, string> = {};
    let ok = true;
    for (const [name, check] of Object.entries(deps.readiness)) {
      try {
        await check();
        checks[name] = "ok";
      } catch {
        checks[name] = "unavailable";
        ok = false;
      }
    }
    return ok
      ? c.json({ status: "ok" as const, checks }, 200)
      : c.json({ status: "degraded" as const, checks }, 503);
  });

  app.openapi(routes.getConfig, (c) =>
    c.json(
      {
        product_name: PRODUCT_NAME,
        api_version: API_VERSION,
        supabase_url: deps.env.SUPABASE_URL,
        supabase_anon_key: deps.env.SUPABASE_ANON_KEY,
        billing_enabled: deps.env.BILLING_ENABLED,
        default_models: Object.fromEntries(
          Object.keys(DEFAULT_MODELS).map((p) => [
            p,
            defaultModelFor(p, modelOverrides(deps.env)) as string,
          ]),
        ),
        default_reasoning_effort: deps.env.DEFAULT_REASONING_EFFORT,
        wallpapers_enabled: Boolean(deps.env.UNSPLASH_ACCESS_KEY),
      },
      200,
    ),
  );
}
