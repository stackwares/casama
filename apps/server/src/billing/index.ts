/** Builds billing from the environment; every provider is optional (D-070). */
import { existsSync, readFileSync } from "node:fs";
import {
  ApnsClient,
  ApnsVoipSender,
  ApnsWatchSender,
  ApnsWidgetSender,
  computerProviderCostUsd,
  computerRates,
  FcmPushSender,
  widgetPushSender,
} from "@casama/agent";
import type { Database } from "@casama/db";
import { SupervisorProvider } from "@casama/sandbox";
import { appLink, cloudModelRouting, type Env } from "../env.ts";
import { LinkServers } from "../link/servers.ts";
import { CloudflareTunnels } from "../link/tunnels.ts";
import { CloudflareTurn } from "../link/turn.ts";
import { DodoProvider } from "./dodo.ts";
import { RevenueCatProvider } from "./revenuecat.ts";
import { BillingService } from "./service.ts";
import type { BillingProvider, ProviderId } from "./types.ts";

export * from "./link.ts";
export * from "./service.ts";
export * from "./types.ts";

/** PEM/JSON given inline or as a file path. */
export const inlineOrFile = (v: string) => {
  // A PEM key kept on one line in an env file (Compose's .env has no multi-line values) writes
  // its line breaks as \n. JSON keeps its own escapes, so only a bare PEM is unescaped.
  if (v.trim().startsWith("-----BEGIN")) return v.trim().replace(/\\n/g, "\n");
  return !v.trim().startsWith("{") && !v.includes("-----BEGIN") && existsSync(v)
    ? readFileSync(v, "utf8")
    : v;
};

/**
 * Widget refresh pushes straight to Apple (D-405), with the same Apple key as call rings
 * (APNS_KEY_P8, APNS_KEY_ID, APNS_TEAM_ID) and the app's own topic. Unset without a key.
 */
export function apnsWidgetsFromEnv(env: Env): ApnsWidgetSender | undefined {
  if (!env.APNS_KEY_P8 || !env.APNS_KEY_ID || !env.APNS_TEAM_ID) return undefined;
  return new ApnsWidgetSender(
    new ApnsClient({
      keyP8: inlineOrFile(env.APNS_KEY_P8),
      keyId: env.APNS_KEY_ID,
      teamId: env.APNS_TEAM_ID,
      url: env.APNS_URL,
    }),
    { appBundleId: env.APNS_TOPIC_APP },
  );
}

/**
 * Alerts straight to Apple Watches' own tokens (D-410), with the same Apple key and the watch
 * app's topic (APNS_TOPIC_APP + ".watchkitapp"). Unset without a key.
 */
export function apnsWatchFromEnv(env: Env): ApnsWatchSender | undefined {
  if (!env.APNS_KEY_P8 || !env.APNS_KEY_ID || !env.APNS_TEAM_ID) return undefined;
  return new ApnsWatchSender(
    new ApnsClient({
      keyP8: inlineOrFile(env.APNS_KEY_P8),
      keyId: env.APNS_KEY_ID,
      teamId: env.APNS_TEAM_ID,
      url: env.APNS_URL,
    }),
    { appBundleId: env.APNS_TOPIC_APP },
  );
}

export function billingFromEnv(
  env: Env,
  db: Database,
  logger?: { warn(msg: string, data?: Record<string, unknown>): void },
) {
  const providers: Partial<Record<ProviderId, BillingProvider>> = {};
  if (env.BILLING_ENABLED) {
    if (env.DODO_API_KEY && env.DODO_WEBHOOK_SECRET)
      providers.dodo = new DodoProvider({
        apiKey: env.DODO_API_KEY,
        webhookSecret: env.DODO_WEBHOOK_SECRET,
        environment: env.DODO_ENVIRONMENT,
        baseUrl: env.DODO_API_URL,
      });
    if (env.REVENUECAT_PROJECT_ID && env.REVENUECAT_API_KEY && env.REVENUECAT_WEBHOOK_AUTH)
      providers.revenuecat = new RevenueCatProvider({
        projectId: env.REVENUECAT_PROJECT_ID,
        apiKey: env.REVENUECAT_API_KEY,
        webhookAuth: env.REVENUECAT_WEBHOOK_AUTH,
        signingSecret: env.REVENUECAT_WEBHOOK_SIGNING_SECRET,
        baseUrl: env.REVENUECAT_API_URL,
      });
  }
  const service = new BillingService({
    db,
    enabled: env.BILLING_ENABLED,
    providers,
    cloudComputerUsdPerHour: env.CLOUD_COMPUTER_USD_PER_HOUR,
    // A Link computer runs on the server's own Docker; one size step (1 vCPU, 1 GB) an hour.
    cloudComputerCostPerHour:
      computerProviderCostUsd("docker", null, 3600, computerRates(env.COMPUTER_RATES)) ?? undefined,
    cloudDailyCap: Boolean(env.CLOUD_MODEL_UPSTREAM_KEY),
    linkSupervisor:
      env.SUPERVISOR_URL && env.SUPERVISOR_TOKEN
        ? { url: env.SUPERVISOR_URL, token: env.SUPERVISOR_TOKEN }
        : undefined,
    logger,
  });
  // The markup can change from the Admin screen (D-244): load it now and every minute. Every
  // server writes whether it bills, so the database picks the right plan for new workspaces (D-246).
  void service.loadSettings();
  if (env.BILLING_ENABLED) setInterval(() => void service.loadSettings(), 60_000).unref();
  return service;
}

/** Cloud side: the servers' addresses (D-296), when this cloud has a zone to put them on. */
export function linkServersFromEnv(env: Env, db: Database) {
  if (
    !env.CASAMA_LINK_ZONE ||
    !env.CASAMA_LINK_CF_ACCOUNT_ID ||
    !env.CASAMA_LINK_CF_ZONE_ID ||
    !env.CASAMA_LINK_CF_API_TOKEN
  )
    return undefined;
  return new LinkServers({
    db,
    tunnels: new CloudflareTunnels({
      zone: env.CASAMA_LINK_ZONE,
      accountId: env.CASAMA_LINK_CF_ACCOUNT_ID,
      zoneId: env.CASAMA_LINK_CF_ZONE_ID,
      apiToken: env.CASAMA_LINK_CF_API_TOKEN,
      apiUrl: env.CASAMA_LINK_CF_API_URL,
    }),
    linkUrl: env.CASAMA_LINK_SIGN_IN_URL ?? appLink(env, "/link"),
    parkAfterDays: env.CASAMA_LINK_PARK_AFTER_DAYS,
  });
}

/** Cloud side, in the worker: the hourly upkeep of the servers' tunnels (parking and warnings). */
export function linkUpkeepFromEnv(env: Env, db?: Database) {
  if (!db || !env.BILLING_ENABLED || !env.CASAMA_LINK_CLOUD) return undefined;
  const servers = linkServersFromEnv(env, db);
  if (!servers) return undefined;
  return {
    servers,
    parking: env.CASAMA_LINK_PARKING,
    tunnelAlert: env.CASAMA_LINK_TUNNEL_ALERT,
    recordLimit: env.CASAMA_LINK_RECORD_LIMIT,
    adminEmails: env.INSTANCE_ADMIN_EMAILS,
  };
}

/** Cloud side: what Casama Link forwards to, and the addresses it gives out. */
export function linkFromEnv(env: Env, db?: Database) {
  if (!env.BILLING_ENABLED || !env.CASAMA_LINK_CLOUD) return undefined;
  const push = env.FCM_SERVICE_ACCOUNT
    ? new FcmPushSender(inlineOrFile(env.FCM_SERVICE_ACCOUNT))
    : undefined;
  return {
    servers: db ? linkServersFromEnv(env, db) : undefined,
    // The push relay (D-296): linked self-hosted servers send through this cloud's Firebase key.
    push,
    // ...their widget refresh pushes (D-405): Android through Firebase, iPhones and Macs through
    // this cloud's Apple key (skipped without one).
    widgets: push ? widgetPushSender({ push, apple: apnsWidgetsFromEnv(env) }) : undefined,
    // ...alerts to their Apple Watches' own tokens (D-410) through this cloud's Apple key...
    watch: apnsWatchFromEnv(env),
    // ...and their iPhone call rings through this cloud's Apple key.
    voip:
      env.APNS_KEY_P8 && env.APNS_KEY_ID && env.APNS_TEAM_ID
        ? new ApnsVoipSender({
            keyP8: inlineOrFile(env.APNS_KEY_P8),
            keyId: env.APNS_KEY_ID,
            teamId: env.APNS_TEAM_ID,
            topic: env.APNS_VOIP_TOPIC,
            url: env.APNS_URL,
          })
        : undefined,
    // Live view away from the computer (D-296): credentials for a relay phones can reach.
    turn:
      env.CASAMA_LINK_TURN_KEY_ID && env.CASAMA_LINK_TURN_API_TOKEN
        ? new CloudflareTurn({
            keyId: env.CASAMA_LINK_TURN_KEY_ID,
            apiToken: env.CASAMA_LINK_TURN_API_TOKEN,
            apiUrl: env.CASAMA_LINK_TURN_API_URL,
          })
        : undefined,
    supervisor:
      env.SUPERVISOR_URL && env.SUPERVISOR_TOKEN
        ? { url: env.SUPERVISOR_URL, token: env.SUPERVISOR_TOKEN }
        : undefined,
    models: env.CLOUD_MODEL_UPSTREAM_KEY
      ? {
          url: env.CLOUD_MODEL_UPSTREAM_URL,
          key: env.CLOUD_MODEL_UPSTREAM_KEY,
          markup: env.CLOUD_MODEL_MARKUP,
          routing: cloudModelRouting(env),
        }
      : undefined,
  };
}

/** Answers from Casama Cloud's whoami, per key, for a few minutes. */
const keyComputers = new Map<string, { at: number; ok: boolean }>();
const KEY_SCOPES_TTL_MS = 5 * 60_000;

/**
 * Whether this server's Casama Link key may use cloud computers (the `computers` scope, D-071). A
 * key made by linking (D-296) has only remote_access and push, so cloud computers would fail at
 * Casama Cloud with "computers_unavailable". Null when the cloud can't be asked right now: the
 * caller goes ahead, and a refusal later is still explained (sandboxApiError).
 */
export async function cloudKeyHasComputers(
  cloud: { url: string; key: string },
  fetchImpl: typeof fetch = fetch,
): Promise<boolean | null> {
  const hit = keyComputers.get(cloud.key);
  if (hit && Date.now() - hit.at < KEY_SCOPES_TTL_MS) return hit.ok;
  try {
    const res = await fetchImpl(`${cloud.url.replace(/\/$/, "")}/link/v1/whoami`, {
      headers: { authorization: `Bearer ${cloud.key}` },
      signal: AbortSignal.timeout(5_000),
    });
    // A key the cloud doesn't know can't use its computers either.
    const ok =
      res.status === 401 || res.status === 403
        ? false
        : res.ok
          ? ((await res.json()) as { computers?: boolean }).computers === true
          : null;
    if (ok !== null) keyComputers.set(cloud.key, { at: Date.now(), ok });
    return ok;
  } catch {
    return null;
  }
}

/** Self-hosted side: the `casama-cloud` computer provider (D-071). */
export function casamaCloudProvider(cloud: { url: string; key: string }) {
  return new SupervisorProvider(
    `${cloud.url.replace(/\/$/, "")}/link/v1/sandbox`,
    cloud.key,
    "casama-cloud",
    { desktop: true, snapshots: true, liveStream: false },
  );
}
