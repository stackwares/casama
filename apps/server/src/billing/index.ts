/** Builds billing from the environment; every provider is optional (D-070). */
import { existsSync, readFileSync } from "node:fs";
import type { Database } from "@casama/db";
import { SupervisorProvider } from "@casama/sandbox";
import type { Env } from "../env.ts";
import { APPLE_ROOT_G3, AppStoreProvider } from "./app-store.ts";
import { DodoProvider } from "./dodo.ts";
import { GooglePlayProvider, type ServiceAccount } from "./google-play.ts";
import { BillingService } from "./service.ts";
import type { BillingProvider, BillingSource } from "./types.ts";

export * from "./connect.ts";
export * from "./service.ts";
export * from "./types.ts";

/** PEM/JSON given inline or as a file path. */
export const inlineOrFile = (v: string) =>
  !v.trim().startsWith("{") && !v.includes("-----BEGIN") && existsSync(v)
    ? readFileSync(v, "utf8")
    : v;

export function billingFromEnv(
  env: Env,
  db: Database,
  logger?: { warn(msg: string, data?: Record<string, unknown>): void },
) {
  const providers: Partial<Record<BillingSource, BillingProvider>> = {};
  if (env.BILLING_ENABLED) {
    if (env.DODO_API_KEY && env.DODO_WEBHOOK_SECRET)
      providers.dodo = new DodoProvider({
        apiKey: env.DODO_API_KEY,
        webhookSecret: env.DODO_WEBHOOK_SECRET,
        environment: env.DODO_ENVIRONMENT,
        baseUrl: env.DODO_API_URL,
      });
    if (env.APP_STORE_ISSUER_ID && env.APP_STORE_KEY_ID && env.APP_STORE_PRIVATE_KEY)
      providers.app_store = new AppStoreProvider({
        issuerId: env.APP_STORE_ISSUER_ID,
        keyId: env.APP_STORE_KEY_ID,
        privateKey: inlineOrFile(env.APP_STORE_PRIVATE_KEY),
        bundleId: env.APP_STORE_BUNDLE_ID,
        environment: env.APP_STORE_ENVIRONMENT,
        baseUrl: env.APP_STORE_API_URL,
        rootPems: [
          readFileSync(APPLE_ROOT_G3, "utf8"),
          ...(env.APP_STORE_ROOT_CA?.includes("-----BEGIN")
            ? [env.APP_STORE_ROOT_CA]
            : (env.APP_STORE_ROOT_CA ?? "")
                .split(",")
                .filter(Boolean)
                .map((p) => readFileSync(p.trim(), "utf8"))),
        ],
      });
    if (env.GOOGLE_PLAY_SERVICE_ACCOUNT)
      providers.google_play = new GooglePlayProvider({
        packageName: env.GOOGLE_PLAY_PACKAGE_NAME,
        serviceAccount: JSON.parse(inlineOrFile(env.GOOGLE_PLAY_SERVICE_ACCOUNT)) as ServiceAccount,
        baseUrl: env.GOOGLE_PLAY_API_URL,
        rtdnToken: env.GOOGLE_PLAY_RTDN_TOKEN,
        rtdnAudience: env.GOOGLE_PLAY_RTDN_AUDIENCE,
        rtdnEmail: env.GOOGLE_PLAY_RTDN_EMAIL,
      });
  }
  return new BillingService({
    db,
    enabled: env.BILLING_ENABLED,
    providers,
    cloudComputerUsdPerHour: env.CLOUD_COMPUTER_USD_PER_HOUR,
    logger,
  });
}

/** Cloud side: what the Cloud Connect proxy forwards to. */
export function connectFromEnv(env: Env) {
  if (!env.BILLING_ENABLED || !env.CLOUD_CONNECT) return undefined;
  return {
    supervisor:
      env.SUPERVISOR_URL && env.SUPERVISOR_TOKEN
        ? { url: env.SUPERVISOR_URL, token: env.SUPERVISOR_TOKEN }
        : undefined,
    models: env.CLOUD_MODEL_UPSTREAM_KEY
      ? {
          url: env.CLOUD_MODEL_UPSTREAM_URL,
          key: env.CLOUD_MODEL_UPSTREAM_KEY,
          markup: env.CLOUD_MODEL_MARKUP,
        }
      : undefined,
  };
}

/** Self-hosted side: the `casama-cloud` computer provider (D-071). */
export function casamaCloudProvider(cloud: { url: string; key: string }) {
  return new SupervisorProvider(
    `${cloud.url.replace(/\/$/, "")}/connect/v1/sandbox`,
    cloud.key,
    "casama-cloud",
    { desktop: true, snapshots: true, liveStream: false },
  );
}
