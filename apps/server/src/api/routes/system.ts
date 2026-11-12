import { API_VERSION, PRODUCT_NAME, routes } from "@casama/contracts";
import { DEFAULT_MODELS, defaultModelFor } from "@casama/domain";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { type Env, modelOverrides } from "../../env.ts";
import { abuseControlsOn, signupProofKinds } from "../../services/abuse.ts";
import { getCloudModels } from "../../services/cloud-models.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { chatGptSignInEnabled } from "./chatgpt.ts";

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

  app.openapi(routes.getConfig, async (c) => {
    const defaults = Object.fromEntries(
      Object.keys(DEFAULT_MODELS).map((p) => [
        p,
        defaultModelFor(p, modelOverrides(deps.env)) as string,
      ]),
    );
    if (deps.env.BILLING_ENABLED) defaults.openrouter = (await getCloudModels(deps.db)).chat;
    return c.json(
      {
        product_name: PRODUCT_NAME,
        api_version: API_VERSION,
        supabase_url: deps.env.SUPABASE_URL,
        supabase_anon_key: deps.env.SUPABASE_ANON_KEY,
        billing_enabled: deps.env.BILLING_ENABLED,
        default_models: defaults,
        default_reasoning_effort: deps.env.DEFAULT_REASONING_EFFORT,
        wallpapers_enabled: Boolean(deps.env.UNSPLASH_ACCESS_KEY),
        chatgpt_sign_in: chatGptSignInEnabled(deps.env),
        server_voice: serverVoice(deps.env),
        signup_proofs: abuseControlsOn(deps.env) ? signupProofKinds(deps.env) : [],
        trace_url_template: deps.env.TRACE_URL_TEMPLATE ?? null,
        google_client_ids: googleClientIds(deps.env),
      },
      200,
    );
  });
}

/** Voice features the server's own keys cover (the same defaults as Casama Cloud). */
export function serverVoice(env: {
  GOOGLE_AI_API_KEY?: string;
  CLOUD_MODEL_UPSTREAM_KEY?: string;
}): Array<"live" | "read_aloud" | "dictation"> {
  return [
    ...(env.GOOGLE_AI_API_KEY ? (["live", "read_aloud"] as const) : []),
    ...(env.CLOUD_MODEL_UPSTREAM_KEY ? (["dictation"] as const) : []),
  ];
}

/**
 * The Google client ids this server's Auth accepts in an ID token (D-217). The apps use Google's
 * own sign-in sheet only when their client id is listed, and the browser otherwise.
 */
export function googleClientIds(env: Pick<Env, "GOOGLE_AUTH_ENABLED" | "GOOGLE_AUTH_CLIENT_ID">) {
  if (!env.GOOGLE_AUTH_ENABLED) return [];
  return (env.GOOGLE_AUTH_CLIENT_ID ?? "")
    .split(",")
    .map((id) => id.trim())
    .filter(Boolean);
}
