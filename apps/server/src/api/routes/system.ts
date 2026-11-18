import { API_VERSION, PRODUCT_NAME, routes } from "@casama/contracts";
import { defaultModelFor, defaultModels, KEY_PROVIDERS } from "@casama/domain";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { type Env, modelOverrides } from "../../env.ts";
import { abuseControlsOn, signupProofKinds } from "../../services/abuse.ts";
import { getCloudModels } from "../../services/cloud-models.ts";
import { newsletterConfig } from "../../services/newsletter.ts";
import { sitesSettings } from "../../sites/config.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { chatGptSignInEnabled } from "./chatgpt.ts";
import { authAdminFor } from "./signin-codes.ts";

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
      Object.keys(defaultModels()).map((p) => [
        p,
        defaultModelFor(p, modelOverrides(deps.env)) as string,
      ]),
    );
    if (deps.env.BILLING_ENABLED) defaults.openrouter = (await getCloudModels(deps.db)).chat;
    return c.json(
      {
        product_name: PRODUCT_NAME,
        api_version: API_VERSION,
        supabase_url: supabaseUrlFor(deps.env, c.req.header("host")),
        supabase_anon_key: deps.env.SUPABASE_ANON_KEY,
        billing_enabled: deps.env.BILLING_ENABLED,
        default_models: defaults,
        default_reasoning_effort: deps.env.DEFAULT_REASONING_EFFORT,
        wallpapers_enabled: Boolean(deps.env.UNSPLASH_ACCESS_KEY),
        chatgpt_sign_in: chatGptSignInEnabled(deps.env),
        server_voice: serverVoice(deps.env),
        // Watch keys and their routes (D-410).
        watch: true,
        signup_proofs: abuseControlsOn(deps.env) ? signupProofKinds(deps.env) : [],
        trace_url_template: deps.env.TRACE_URL_TEMPLATE ?? null,
        google_client_ids: googleClientIds(deps.env),
        sign_in_codes: !!authAdminFor(deps),
        // Casama's monthly email (D-408): only where the server has its Resend key.
        newsletter: !!newsletterConfig(deps.env),
        // One list for the apps' add-key form and model pickers (D-374).
        key_providers: KEY_PROVIDERS,
        ...(deps.env.DISABLE_SIGNUP === undefined
          ? {}
          : { signups_open: !deps.env.DISABLE_SIGNUP }),
        ...(deps.env.SIGNUP_INVITED_ONLY ? { signups_by_invitation: true } : {}),
        ...(deps.env.FCM_SENDER_ID ? { push_sender_id: deps.env.FCM_SENDER_ID } : {}),
        ...(deps.env.CASAMA_SITES_ZONE ? { sites: await sitesSettings(deps.env, deps.db) } : {}),
      },
      200,
    );
  });
}

const LOOPBACK_HOST = /^(localhost|127\.0\.0\.1|\[::1\])(:\d+)?$/i;

/** Whether a request was made to this machine's own address (its Host header says so). */
export const isLoopbackHost = (host: string | undefined) =>
  !!host && LOOPBACK_HOST.test(host.trim());

/**
 * Where the app finds Auth. Normally the server's public address. A server with remote access on
 * (D-296) also answers on its own machine: an app that asks there is given that same local address
 * (CASAMA_LOCAL_URL), so it keeps the session it had and works with no internet. Tokens are
 * checked with the shared secret, so one issued through either address is good on both.
 */
export function supabaseUrlFor(
  env: { SUPABASE_URL: string; CASAMA_LOCAL_URL?: string },
  host: string | undefined,
) {
  if (env.CASAMA_LOCAL_URL && isLoopbackHost(host)) return env.CASAMA_LOCAL_URL.replace(/\/$/, "");
  return env.SUPABASE_URL;
}

/** Voice features the server's own keys cover (the same defaults as Casama Cloud). */
export function serverVoice(env: {
  GOOGLE_AI_API_KEY?: string;
  CLOUD_MODEL_UPSTREAM_KEY?: string;
}): Array<"live" | "read_aloud" | "dictation"> {
  // Calls are Gemini Live on Google's key; read-aloud and dictation run on the shared OpenRouter
  // key (D-261).
  return [
    ...(env.GOOGLE_AI_API_KEY ? (["live"] as const) : []),
    ...(env.CLOUD_MODEL_UPSTREAM_KEY ? (["read_aloud", "dictation"] as const) : []),
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
