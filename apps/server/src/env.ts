import type { OpenRouterRouting } from "@casama/agent";
import { z } from "zod";

const bool = z.enum(["true", "false", "1", "0"]).transform((v) => v === "true" || v === "1");

/**
 * A link to `path` in the app for emails, invites and shared links (D-326): through
 * PUBLIC_OPEN_URL when set, so an installed app opens it, else straight to the web app.
 */
export function appLink(
  env: { PUBLIC_APP_URL: string; PUBLIC_OPEN_URL?: string },
  path = "",
): string {
  return `${(env.PUBLIC_OPEN_URL ?? env.PUBLIC_APP_URL).replace(/\/$/, "")}${path}`;
}

export const EnvSchema = z.object({
  MODE: z.enum(["api", "worker"]).default("api"),
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().default(8787),
  /**
   * Stopping (D-402): how long the API lets requests it is answering finish, and how long, when a
   * deploy hands over to a new API (SIGUSR2), it keeps carrying live and phone calls before closing
   * them with "server restarting" (the app resumes an in-app call on the new API).
   */
  API_DRAIN_SECONDS: z.coerce.number().int().min(0).default(30),
  CALL_HANDOVER_SECONDS: z.coerce.number().int().min(0).default(600),
  /** Stopping (D-402): how long the worker lets steps in flight finish before it exits. */
  WORKER_DRAIN_SECONDS: z.coerce.number().int().min(0).default(45),
  DATABASE_URL: z.string().min(1),
  /** The worker's least-privilege role (casama_worker, D-095); unset: the worker uses DATABASE_URL. */
  WORKER_DATABASE_URL: z.string().min(1).optional(),
  SUPABASE_URL: z.url(),
  SUPABASE_ANON_KEY: z.string().min(1),
  /** Legacy HS256 secret. When unset, tokens are verified against the project's JWKS. */
  SUPABASE_JWT_SECRET: z.string().optional(),
  PUBLIC_APP_URL: z.url().default("http://localhost:3000"),
  /**
   * Where links in emails and invites open (D-326), when not the web app itself. Casama Cloud:
   * https://casama.ai/open, which phones and the Mac App Store build hand to the installed app and
   * which otherwise sends the browser on to the web app. Unset: PUBLIC_APP_URL.
   */
  PUBLIC_OPEN_URL: z.url().optional(),
  /**
   * App links for invite links (D-167): iOS app ids (TEAMID.bundle, comma-separated) for
   * apple-app-site-association, and the Android package with its signing certificates' SHA-256
   * fingerprints for assetlinks.json. Unset: invite links open the join page or the web app.
   */
  APPLE_APP_IDS: z.string().optional(),
  ANDROID_APP_PACKAGE: z.string().default("ai.casama.app"),
  ANDROID_CERT_SHA256: z.string().optional(),
  /** Store pages shown on the invite join page. */
  APP_STORE_URL: z.url().optional(),
  PLAY_STORE_URL: z.url().optional(),
  /**
   * A header the edge sets with the caller's address and clients can't override, used for signed-out
   * rate limits. Casama Cloud: cf-connecting-ip (behind Cloudflare Tunnel, X-Forwarded-For is the
   * tunnel's own address). Unset: the first X-Forwarded-For entry, which Caddy sets.
   */
  TRUSTED_CLIENT_IP_HEADER: z
    .string()
    .optional()
    .transform((v) => v?.trim().toLowerCase() || undefined),
  /** Extra comma-separated origins allowed to call the API from a browser. */
  CORS_ORIGINS: z.string().default(""),
  /**
   * Casama for Chrome (D-323): extension ids whose pages may call the API from the browser, comma
   * separated. The default is the id the repository's manifest key gives the extension. Outside
   * production any chrome-extension:// origin is allowed, as localhost is.
   */
  CHROME_EXTENSION_IDS: z.string().default("ppbkfncjfhfhkgbkdleajcpacfljphpl"),
  /**
   * Casama for Firefox (D-323 Phase 5): allow any moz-extension:// origin. Firefox gives each
   * install its own random origin, so there's no id to list. Off keeps Firefox out.
   */
  FIREFOX_EXTENSIONS: bool.default(true),
  /**
   * ChatGPT plan sign-in (SPEC: ChatGPT plan sign-in). auto: on for self-hosted servers, off when
   * billing is on (Casama Cloud needs OpenAI's approval for hosted use first).
   */
  CHATGPT_SIGN_IN: z.enum(["auto", "on", "off"]).default("auto"),
  /**
   * Casama Cloud abuse controls (D-094): sign-up proofs, a verified email before a free computer
   * starts, and automatic suspension on egress abuse. auto: on when billing is on.
   */
  ABUSE_CONTROLS: z.enum(["auto", "on", "off"]).default("auto"),
  /**
   * Health data (D-150) is stored only sealed with a workspace content key the person owns (encryption
   * at rest). auto: required when billing is on (Casama Cloud); self-hosted keeps it on its own machine.
   */
  HEALTH_REQUIRES_ENCRYPTION: z.enum(["auto", "on", "off"]).default("auto"),
  /**
   * Private networks the API and worker may call (comma-separated CIDRs), for self-hosted services on
   * your LAN such as Vaultwarden or Ollama. Everything private is blocked otherwise (SSRF guard).
   */
  OUTBOUND_ALLOW_CIDRS: z.string().optional(),
  /** Proofs a new account may carry (comma-separated): app_check, pow. */
  SIGNUP_PROOFS: z.string().default("app_check,pow"),
  /** Proof-of-work difficulty in leading zero bits (about 2^n hashes; 18 is a second or two). */
  SIGNUP_POW_DIFFICULTY: z.coerce.number().int().min(8).max(28).default(18),
  /** Firebase project number for App Check tokens; JWKS and issuer are overridable for tests. */
  APP_CHECK_PROJECT_NUMBER: z.string().optional(),
  APP_CHECK_JWKS_URL: z.url().default("https://firebaseappcheck.googleapis.com/v1/jwks"),
  APP_CHECK_ISSUER_BASE: z.url().default("https://firebaseappcheck.googleapis.com"),
  /** Supabase Auth "before user created" hook secret (`v1,whsec_…`, Standard Webhooks). */
  AUTH_HOOK_SECRET: z.string().optional(),
  /** OpenAI's auth server and Responses API; overridable for tests and proxies. */
  CHATGPT_AUTH_URL: z.url().default("https://auth.openai.com"),
  CHATGPT_API_URL: z.url().default("https://api.openai.com/v1"),
  /**
   * Continue with Google, read here only to tell the apps which client ids Auth accepts (D-217).
   * The same comma-separated list the auth service gets: the web client first, then the iOS one.
   */
  GOOGLE_AUTH_ENABLED: bool.default(false),
  GOOGLE_AUTH_CLIENT_ID: z.string().optional(),
  /** Optional wallpaper photo search (D-087). Unset: the app offers its own patterns and photos. */
  UNSPLASH_ACCESS_KEY: z.string().optional(),
  /** Worker: the server's SearXNG for web search without a workspace key (D-179), e.g. http://searxng:8080. */
  SEARXNG_URL: z.url().optional(),
  /**
   * Worker: the server's own web search for workspaces without a key (D-384), tried in this order
   * before SearXNG. Names: parallel, serper, deepseek, searxng; a provider without its key is
   * skipped. DeepSeek is used only when named here (queries go to DeepSeek's servers).
   */
  SEARCH_PROVIDER_ORDER: z.string().default("parallel,serper,searxng"),
  /** Parallel Search (fast mode, $1 per 1,000 queries, D-384). */
  PARALLEL_API_KEY: z.string().optional(),
  /** Serper, Google results ($1 per 1,000 queries, D-384). */
  SERPER_API_KEY: z.string().optional(),
  /** DeepSeek Search ($0.75 per 1,000, D-384): also needs "deepseek" in SEARCH_PROVIDER_ORDER. */
  DEEPSEEK_SEARCH_API_KEY: z.string().optional(),
  UNSPLASH_API_URL: z.url().default("https://api.unsplash.com"),
  /**
   * Open gallery of themes, schemes, wallpapers and skills (D-184). `off` turns it off.
   * The default is the public site; a fetch failure leaves the bundled looks in place.
   */
  GALLERY_URL: z.string().default("https://gallery.casama.ai"),
  /**
   * Signed gallery (D-315): the catalog's Ed25519 public key (base64 of the raw 32 bytes). Empty:
   * the Casama gallery's own key for the default GALLERY_URL, none for another address.
   */
  GALLERY_PUBLIC_KEY: z.string().default(""),
  /**
   * required: a missing or bad manifest.sig makes the gallery unavailable; optional: checked when
   * the catalog has one (a bad one still makes it unavailable); off: never checked. Without a key
   * it's off.
   */
  GALLERY_SIGNATURE: z.enum(["required", "optional", "off"]).default("optional"),
  /** More catalogs, comma-separated: `url`, `name=url` or `name=url#<base64 public key>`. */
  GALLERY_SOURCES: z.string().default(""),
  /** Where use counts come from on a self-hosted server; `off` hides them. Casama Cloud serves its own. */
  GALLERY_STATS_URL: z.string().default("https://api.casama.ai/v1/gallery/stats"),
  /** Submissions from the app open pull requests here (owner/repo). */
  GALLERY_SUBMIT_REPO: z.string().default("stackwares/casama-gallery"),
  /** A GitHub token that may push branches and open pull requests on GALLERY_SUBMIT_REPO. Unset: submissions are off. */
  GALLERY_SUBMIT_TOKEN: z.string().optional(),
  /**
   * Contributor rewards in credits (1 credit = $1) by active users, as JSON, or `off`. Only with
   * billing on. Default (D-315): $10 at 50 people still using an item, $25 at 250, $75 at 1,000.
   */
  GALLERY_REWARDS: z.string().default('{"50":10,"250":25,"1000":75}'),
  /** Casama Cloud only (D-070). Self-hosted servers keep it off: no paywall, unlimited use. */
  BILLING_ENABLED: bool.default(false),
  /**
   * Invite friends (D-211): personal invite codes, and free credits for the inviter and a welcome
   * bonus for the friend once the friend verifies and finishes a first run. auto: on when billing is on. A reward of 0 keeps the codes and
   * counts but grants nothing.
   */
  REFERRALS: z.enum(["auto", "on", "off"]).default("auto"),
  REFERRAL_REWARD_USD: z.coerce.number().min(0).max(100).default(2),
  /** The new person's welcome bonus, given at the same moment as the inviter's reward. */
  REFERRAL_WELCOME_USD: z.coerce.number().min(0).max(100).default(2),
  /** Rewarded friends per person; friends past it still count but earn nothing. */
  REFERRAL_REWARD_CAP: z.coerce.number().int().min(0).max(1000).default(20),
  /** Days after signing up that a person can still enter a friend's code. */
  REFERRAL_REDEEM_DAYS: z.coerce.number().int().min(0).max(90).default(7),
  /** Where invite links point; the code is appended (casama.ai/i/<code>, served by site/). */
  REFERRAL_LINK_BASE: z.url().default("https://casama.ai/i"),
  /**
   * The waitlist and invite gate (docs/WAITLIST-PLAN.md). auto: there when billing is on (Casama
   * Cloud), and even then sign-up stays open until an owner turns the gate on in Admin. A
   * self-hosted server leaves this alone; its own switches are SIGNUP_ALLOWED_EMAILS,
   * SIGNUP_INVITED_ONLY and DISABLE_SIGNUP.
   */
  SIGNUP_WAITLIST: z.enum(["auto", "on", "off"]).default("auto"),
  /** Where the apps and refusals send people to join the waitlist or enter a code. */
  WAITLIST_URL: z.url().default("https://casama.ai/waitlist"),
  /**
   * OpenRouter's daily spending cap on Casama's key, in US dollars (set at OpenRouter; this only
   * mirrors it). The waitlist's daily batch skips a day when yesterday's spend on the key passed
   * 60% of it (docs/WAITLIST-PLAN.md §6.4).
   */
  OPENROUTER_DAILY_CAP_USD: z.coerce.number().nonnegative().default(50),
  /** Dodo Payments (web, desktop, credit packs). */
  DODO_API_KEY: z.string().optional(),
  DODO_WEBHOOK_SECRET: z.string().optional(),
  DODO_ENVIRONMENT: z.enum(["test", "live"]).default("test"),
  DODO_API_URL: z.url().optional(),
  /**
   * RevenueCat (D-297): App Store (iOS, Mac App Store) and Google Play purchases. A v2 secret key
   * with read access to customers, subscriptions, purchases and products; the webhook's
   * Authorization header value; and its signing secret when signatures are on.
   */
  REVENUECAT_PROJECT_ID: z.string().optional(),
  REVENUECAT_API_KEY: z.string().optional(),
  REVENUECAT_WEBHOOK_AUTH: z.string().min(16).optional(),
  REVENUECAT_WEBHOOK_SIGNING_SECRET: z.string().optional(),
  REVENUECAT_API_URL: z.url().optional(),
  /** Casama Link, cloud side (D-071): on whenever billing is on, unless turned off. */
  CASAMA_LINK_CLOUD: bool.default(true),
  CLOUD_MODEL_UPSTREAM_URL: z.url().default("https://openrouter.ai/api/v1"),
  CLOUD_MODEL_UPSTREAM_KEY: z.string().optional(),
  /** Existing management key used only for vendor balance reads. */
  VENDOR_OPENROUTER_MANAGEMENT_KEY: z.string().optional(),
  /** MapTiler only offers full-access service tokens; use an existing approved token only. */
  VENDOR_MAPTILER_SERVICE_TOKEN: z.string().optional(),
  VENDOR_TWILIO_ACCOUNT_SID: z
    .string()
    .regex(/^AC[a-fA-F0-9]{32}$/)
    .optional(),
  VENDOR_TWILIO_AUTH_TOKEN: z.string().optional(),
  VENDOR_CLOUDFLARE_ACCOUNT_ID: z.string().optional(),
  VENDOR_CLOUDFLARE_BILLING_TOKEN: z.string().optional(),
  VENDOR_HERE_KEY_ID: z.string().optional(),
  VENDOR_HERE_KEY_SECRET: z.string().optional(),
  VENDOR_HERE_REALM: z.string().optional(),
  VENDOR_HERE_FEATURE_ID: z.string().optional(),
  GOOGLE_USAGE_SA_JSON: z.string().optional(),
  GOOGLE_USAGE_TILE_METHOD: z.string().default("maps_api.tas.TileService.GetTileMedia"),
  VENDOR_COMPOSIO_ORG_KEY: z.string().optional(),
  VENDOR_ALERT_EMAILS: z.string().optional(),
  /**
   * Which OpenRouter providers serve calls on that key (D-354). One model is sold by dozens of
   * providers at very different prices, each with its own prompt cache. `price` tries the cheapest
   * first; `off` leaves OpenRouter's own spread across providers.
   */
  CLOUD_MODEL_PROVIDER_SORT: z.enum(["price", "throughput", "latency", "off"]).default("price"),
  /** Provider tags tried before the rest, in order (`wafer,deepinfra/fp8`). Unset: only the sort. */
  CLOUD_MODEL_PROVIDERS: z.string().optional(),
  /**
   * A different sort for the model steps of chats a person is waiting on (D-355). `throughput`
   * answers about 2.4 times faster at about 3 times the price; routines, check-ins and background
   * work keep CLOUD_MODEL_PROVIDER_SORT. Unset: chats use it too.
   */
  CLOUD_MODEL_CHAT_SORT: z.enum(["price", "throughput", "latency"]).optional(),
  // Unset: Casama Link model calls cost what Casama's own key charges (OpenRouter's fee × markup).
  CLOUD_MODEL_MARKUP: z.coerce.number().positive().optional(),
  CLOUD_COMPUTER_USD_PER_HOUR: z.coerce.number().nonnegative().default(0.05),
  /** Worker: live model prices (D-181). Default OpenRouter's public model list; "off" turns it off. */
  MODEL_PRICES_URL: z.string().optional(),
  /** Computer prices by provider, overriding the defaults (D-180): {"docker":{"cpu_hour":0.003,"gb_hour":0.005}}. */
  COMPUTER_RATES: z.string().optional(),
  /**
   * Casama Link addresses, cloud side (D-296): each linked server gets a Cloudflare tunnel and
   * https://<label>.<CASAMA_LINK_ZONE>. All four set: this cloud gives out addresses. The token needs
   * Cloudflare Tunnel edit on the account and DNS edit on that zone only. The zone must be a
   * domain of its own, never the one the cloud itself is served from.
   */
  CASAMA_LINK_ZONE: z.string().optional(),
  CASAMA_LINK_CF_ACCOUNT_ID: z.string().optional(),
  CASAMA_LINK_CF_ZONE_ID: z.string().optional(),
  CASAMA_LINK_CF_API_TOKEN: z.string().optional(),
  /** Tests point this at a fake Cloudflare. */
  CASAMA_LINK_CF_API_URL: z.url().optional(),
  /** Where a workspace admin approves a link code; default <PUBLIC_OPEN_URL or PUBLIC_APP_URL>/link. */
  CASAMA_LINK_SIGN_IN_URL: z.url().optional(),
  /**
   * Removing the tunnels of servers that stopped checking in (the address is kept and the tunnel
   * returns with the server). off, dry-run (only counts), or on.
   */
  CASAMA_LINK_PARKING: z.enum(["off", "dry-run", "on"]).default("off"),
  CASAMA_LINK_PARK_AFTER_DAYS: z.coerce.number().int().min(1).default(14),
  /**
   * When the instance owners are warned: at this many tunnels (Cloudflare includes 1,000 and
   * charges for each one past that), and at three quarters of the DNS records the address zone
   * holds on its plan (200 on a new Free zone, 3,500 on Pro; two records per server).
   */
  CASAMA_LINK_TUNNEL_ALERT: z.coerce.number().int().min(1).default(700),
  CASAMA_LINK_RECORD_LIMIT: z.coerce.number().int().min(2).default(200),
  /**
   * Casama Link, cloud side: the relay for live view away from the computer (Cloudflare's TURN
   * service). The key's id and its API token; unset = this cloud gives no relay and servers show
   * screenshots to phones away from home. CASAMA_LINK_TURN_API_URL points tests at a fake.
   */
  CASAMA_LINK_TURN_KEY_ID: z.string().optional(),
  CASAMA_LINK_TURN_API_TOKEN: z.string().optional(),
  CASAMA_LINK_TURN_API_URL: z.url().optional(),
  /**
   * Casama Link, self-hosted side: where the relay container forwards a bot's computer to for
   * live view away from the computer. It must match what Casama Cloud says its relay is.
   */
  CASAMA_LINK_RELAY_UPSTREAM: z.string().default("turn.cloudflare.com:3478"),
  /**
   * Casama Link remote access, self-hosted side (D-296). on: this server keeps a public address
   * through its link to Casama Cloud (CASAMA_CLOUD_URL and CASAMA_CLOUD_KEY) and the connector
   * container. Set by `casama selfhost remote on` or the desktop app, with the address in
   * PUBLIC_API_URL and SUPABASE_URL; not something to switch by hand.
   */
  CASAMA_REMOTE_ACCESS: z.enum(["on", "off"]).default("off"),
  /** This server's id at Casama Cloud: the same id gets the same address back. */
  CASAMA_INSTANCE_ID: z.string().optional(),
  /**
   * The address this server answers on from its own machine (http://localhost:8080). The app on
   * that machine keeps using it, also for Auth, so it stays signed in and works with no internet.
   */
  CASAMA_LOCAL_URL: z.url().optional(),
  /** Where the API keeps the connector's secret (a volume shared with the connector). */
  CASAMA_LINK_TOKEN_FILE: z.string().default("/link/token"),
  /** The connector's readiness address on the stack's network. */
  CONNECTOR_URL: z.url().optional(),
  /** Casama Link, self-hosted side: this server's link to Casama Cloud. Unset = off. */
  CASAMA_CLOUD_URL: z.url().optional(),
  /** GitHub API base for skill imports (tests point it at a fake). */
  GITHUB_API_URL: z.url().optional(),
  /** A read-only GitHub token for plugin and pack fetches (raises the rate limit). Optional. */
  GITHUB_API_TOKEN: z.string().optional(),
  CASAMA_CLOUD_KEY: z.string().optional(),
  /**
   * Push notifications: a Firebase service account (JSON text, or a path to the JSON file) for the
   * Firebase project the apps are built with. Unset: no push; the in-app inbox still works.
   */
  FCM_SERVICE_ACCOUNT: z.string().optional(),
  /** That Firebase project's number (its sender id), so Casama for Chrome can take pushes (D-323). */
  FCM_SENDER_ID: z
    .string()
    .regex(/^\d{6,20}$/)
    .optional(),
  /** Paid data resale (D-138, Casama Cloud only, after a written agreement with Treg): Casama's Treg key and the switch. */
  /**
   * Live data cards (docs/RICH-CARDS-PLAN.md): weather, prices, rates and more from named
   * providers. LIVE_DATA=off leaves the live.* tools out. Open-Meteo's free API is non-commercial:
   * "auto" uses it only on servers that don't bill (BILLING_ENABLED off) or with LIVE_OPEN_METEO_KEY.
   * LIVE_UNOFFICIAL ("auto" likewise) allows public endpoints without published API terms
   * (Yahoo Finance quotes and movers, ESPN scores); Casama Cloud uses a licensed key instead.
   */
  LIVE_DATA: z.enum(["on", "off"]).default("on"),
  LIVE_OPEN_METEO: z.enum(["auto", "on", "off"]).default("auto"),
  LIVE_OPEN_METEO_KEY: z.string().optional(),
  LIVE_UNOFFICIAL: z.enum(["auto", "on", "off"]).default("auto"),
  LIVE_COINGECKO_KEY: z.string().optional(),
  LIVE_FINNHUB_KEY: z.string().optional(),
  LIVE_AVIATIONSTACK_KEY: z.string().optional(),
  LIVE_17TRACK_KEY: z.string().optional(),
  LIVE_TMDB_KEY: z.string().optional(),
  TREG_API_KEY: z.string().optional(),
  TREG_RESALE: z.enum(["on", "off"]).default("off"),
  TREG_API_URL: z.url().optional(),
  /** Calls for you (D-141): override for Twilio's API (tests, proxies). */
  TWILIO_API_URL: z.url().optional(),
  /** Phone calls through Twilio are off for now: bots get no voice.call tool unless this is on. */
  PHONE_CALLS: bool.default(false),
  /** Live calls on Gemini Live (when a workspace has a Google AI key); default gemini-3.8-live. */
  GEMINI_LIVE_MODEL: z.string().optional(),
  /**
   * Live calls: once the conversation passes the trigger (tokens), Gemini drops its oldest turns
   * down to the target. Gemini Live bills every turn for the whole call so far, so a lower pair
   * makes long calls cheaper and a higher pair lets the bot remember more of the call (two-way
   * talk is about 1,500 tokens a minute). The instructions and tools a call always carries come
   * on top. Target must be below trigger.
   */
  VOICE_CONTEXT_TRIGGER_TOKENS: z.coerce.number().int().min(1000).default(8000),
  VOICE_CONTEXT_TARGET_TOKENS: z.coerce.number().int().min(1000).default(3000),
  /**
   * The server's own Google AI key: live calls in workspaces without a Gemini or OpenAI key of
   * their own use it. With billing on (Casama Cloud) those calls are paid from credits.
   */
  GOOGLE_AI_API_KEY: z.string().optional(),
  /** Payments (D-142): override for Stripe's API (tests, proxies). */
  STRIPE_API_URL: z.url().optional(),
  /** Cloudflare AI Gateway (D-145): model calls go through it; the token is for authenticated gateways. */
  AI_GATEWAY_URL: z.url().optional(),
  AI_GATEWAY_TOKEN: z.string().optional(),
  AI_GATEWAY_PROVIDERS: z.string().optional(),
  /** Self-host sign-up allowlist (D-145): emails or domains, comma-separated (needs the sign-up hook). */
  SIGNUP_ALLOWED_EMAILS: z.string().optional(),
  /**
   * New accounts by invitation only (D-296; needs the sign-up hook, like the allowlist): an email
   * may sign up only while an invitation for it stands. Set with remote access when its owner
   * lets invited people in; emails on SIGNUP_ALLOWED_EMAILS are let in too.
   */
  SIGNUP_INVITED_ONLY: bool.optional(),
  /**
   * Refuse email sign-ups at addresses that can never receive mail (example.com, .test,
   * .invalid, ...), so Auth's confirmation emails don't bounce off them. On for Casama Cloud;
   * off by default so local setups and tests can use made-up addresses.
   */
  SIGNUP_REFUSE_TEST_DOMAINS: bool.optional(),
  /** Encryption at rest (D-136): the server key that wraps workspace data keys (32 bytes, base64), and older keys during a rotation (comma-separated). */
  CONTENT_ENCRYPTION_KEY: z.string().optional(),
  CONTENT_ENCRYPTION_KEY_PREVIOUS: z.string().optional(),
  /** Or AWS KMS: the key's id or ARN, its region, and credentials (an optional endpoint for tests or VPC endpoints). */
  CONTENT_KMS_KEY_ID: z.string().optional(),
  CONTENT_KMS_REGION: z.string().optional(),
  CONTENT_KMS_ENDPOINT: z.url().optional(),
  AWS_ACCESS_KEY_ID: z.string().optional(),
  AWS_SECRET_ACCESS_KEY: z.string().optional(),
  AWS_SESSION_TOKEN: z.string().optional(),
  /**
   * Apple's push service with a token key (.p8, inline or a path), its id and the team: iOS call
   * rings through PushKit (D-135, the app's VoIP topic) and widget refresh pushes (D-405, topic
   * `<APNS_TOPIC_APP>.push-type.widgets`). APNS_URL replaces Apple's host (tests, a proxy).
   */
  APNS_KEY_P8: z.string().optional(),
  APNS_KEY_ID: z.string().optional(),
  APNS_TEAM_ID: z.string().optional(),
  APNS_VOIP_TOPIC: z.string().default("ai.casama.app.voip"),
  /** The app's bundle id, which widget pushes are addressed to. */
  APNS_TOPIC_APP: z.string().default("ai.casama.app"),
  APNS_URL: z.url().optional(),
  RESEND_API_KEY: z.string().optional(),
  /** Invite and notice email over SMTP instead of Resend (D-174). Resend wins when both are set. */
  SMTP_HOST: z.string().optional(),
  SMTP_PORT: z.coerce.number().int().positive().default(587),
  SMTP_USER: z.string().optional(),
  SMTP_PASS: z.string().optional(),
  EMAIL_FROM: z.string().default("Casama <no-reply@localhost>"),
  /**
   * A second way out for the same email (D-433): a Resend key used only when the main sender
   * (RESEND_API_KEY or SMTP) fails. Sends from EMAIL_BACKUP_FROM, or EMAIL_FROM when unset, so
   * that address's domain must be verified in Resend too.
   */
  EMAIL_BACKUP_RESEND_API_KEY: z.string().optional(),
  EMAIL_BACKUP_FROM: z.string().optional(),
  /**
   * Casama's monthly email (D-404, D-408), Casama Cloud only: a Resend key with access to contacts,
   * for the list behind the app's "Casama's monthly email" switch. Kept apart from RESEND_API_KEY,
   * which a self-hosted server may set for its own invite emails. Unset: the app hides the switch
   * and the server never calls Resend for it.
   */
  NEWSLETTER_RESEND_API_KEY: z.string().optional(),
  /** Resend webhook signing secret (`whsec_…`) for /hooks/newsletter/resend. */
  NEWSLETTER_WEBHOOK_SECRET: z.string().optional(),
  /** The Resend segment and topic people join (Casama's own by default, D-404). */
  NEWSLETTER_SEGMENT_ID: z.string().default("bcf1b930-13c0-4bbc-a720-aa4cfd544e3c"),
  NEWSLETTER_TOPIC_ID: z.string().default("4b2d83b2-6f0a-4d6b-9981-de572951bf3c"),
  /**
   * Help & support (D-298). Messages people send from the app go to SUPPORT_INBOX (with their own
   * address as reply-to). The assistant runs when CLOUD_MODEL_UPSTREAM_KEY is set and is off with
   * SUPPORT_ASSISTANT=false; SUPPORT_MODEL picks its model (default: the cloud chat default).
   * SUPPORT_DAILY_USD caps what the assistant may spend in a day across everyone.
   */
  SUPPORT_INBOX: z.string().default("support@casama.ai"),
  /** Reports from inside the app are emailed here too (D-301). */
  ABUSE_INBOX: z.string().default("abuse@casama.ai"),
  /**
   * Account emails (D-302): billing changes and a short welcome series, sent by the worker.
   * Tips and news emails go out only when EMAIL_POSTAL_ADDRESS is set (US CAN-SPAM wants a postal
   * address in them); billing emails don't need it.
   */
  ACCOUNT_EMAILS: bool.default(true),
  EMAIL_POSTAL_ADDRESS: z.string().optional(),
  SUPPORT_ASSISTANT: bool.default(true),
  SUPPORT_MODEL: z.string().optional(),
  SUPPORT_DAILY_USD: z.coerce.number().nonnegative().default(10),
  SUPPORT_MESSAGES_PER_DAY: z.coerce.number().int().positive().default(60),
  /** Messages to support a day from everyone together, so a flood can't eat the email quota. */
  SUPPORT_TICKETS_PER_DAY: z.coerce.number().int().positive().default(200),
  /**
   * Casama Help on casama.ai and docs.casama.ai (D-401), for signed-out visitors. It runs when
   * SUPPORT_WEB is on and a model key is set (SUPPORT_WEB_UPSTREAM_KEY, its own capped key, or else
   * CLOUD_MODEL_UPSTREAM_KEY), and in production only with Turnstile keys. SUPPORT_WEB_MODEL picks
   * its model (default SUPPORT_MODEL). SUPPORT_WEB_DAILY_USD is its own budget, apart from the
   * app's. SUPPORT_WEB_ORIGINS are the pages allowed to call it.
   */
  SUPPORT_WEB: bool.default(true),
  SUPPORT_WEB_UPSTREAM_KEY: z.string().optional(),
  SUPPORT_WEB_MODEL: z.string().optional(),
  SUPPORT_WEB_DAILY_USD: z.coerce.number().nonnegative().default(5),
  SUPPORT_WEB_MESSAGES_PER_DAY: z.coerce.number().int().positive().default(20),
  SUPPORT_WEB_ORIGINS: z
    .string()
    .default("https://casama.ai,https://www.casama.ai,https://docs.casama.ai"),
  TURNSTILE_SITE_KEY: z.string().optional(),
  TURNSTILE_SECRET_KEY: z.string().optional(),
  /** The public docs; the assistant refreshes its copy from <DOCS_URL>/llms-full.txt hourly. */
  DOCS_URL: z.url().default("https://docs.casama.ai"),
  RATE_LIMIT_PER_MINUTE: z.coerce.number().int().positive().default(120),
  /** Error reporting (D-063): auto = Sentry if SENTRY_DSN, else PostHog if POSTHOG_API_KEY. */
  ERROR_REPORTING: z.enum(["auto", "sentry", "posthog", "none"]).default("auto"),
  /** Sentry protocol: sentry.io, self-hosted Sentry or GlitchTip. */
  SENTRY_DSN: z.string().optional(),
  POSTHOG_API_KEY: z.string().optional(),
  POSTHOG_HOST: z.url().optional(),
  /** Product analytics environment tag (production|staging|development). Defaults to NODE_ENV. */
  ANALYTICS_ENVIRONMENT: z.string().optional(),
  /**
   * Comma- or space-separated internal/test emails and email domains (`@` optional on domains).
   * Accounts matching these are tagged `is_internal: true` in PostHog and `traffic_type: "internal"`
   * in GA4, without sending any email address to analytics.
   */
  INTERNAL_EMAILS: z.string().optional(),
  INTERNAL_EMAIL_DOMAINS: z.string().optional(),
  /** Product analytics events and daily rollups (Casama Cloud). Off unless "on" and POSTHOG_API_KEY is set. */
  PRODUCT_ANALYTICS: z.enum(["on", "off"]).default("off"),
  /** Which analytics providers get product events (D-397): "posthog", "ga4", both, or "none". Unset = every provider with keys. */
  ANALYTICS_PROVIDERS: z.string().optional(),
  /** Google Analytics 4 over the Measurement Protocol: a web data stream's id (G-…) and its API secret. */
  GA4_MEASUREMENT_ID: z.string().optional(),
  GA4_API_SECRET: z.string().optional(),
  /** "1" sends to GA4's validation endpoint (nothing is recorded). */
  GA4_DEBUG: z.string().optional(),
  /** Erasing purged accounts from GA4: the numeric property id and a service account JSON with Editor on it. */
  GA4_PROPERTY_ID: z.string().optional(),
  GA4_SERVICE_ACCOUNT_JSON: z.string().optional(),
  OTEL_EXPORTER_OTLP_ENDPOINT: z.string().optional(),
  /** Langfuse LLM traces (D-107): all three set turns them on (workspaces can opt out). */
  LANGFUSE_BASE_URL: z.url().optional(),
  LANGFUSE_PUBLIC_KEY: z.string().min(1).optional(),
  LANGFUSE_SECRET_KEY: z.string().min(1).optional(),
  /** A trace viewer link with {trace_id} in it, shown on run timelines (D-107). */
  TRACE_URL_TEMPLATE: z.string().includes("{trace_id}").optional(),
  LOG_LEVEL: z.enum(["debug", "info", "warn", "error"]).default("info"),
  /** Worker: replay recorded model responses (comma-separated fixture files) instead of calling providers. */
  CASAMA_MODEL_FIXTURES: z.string().optional(),
  /** Worker: append real model exchanges to this file as fixture turns. */
  CASAMA_MODEL_RECORD: z.string().optional(),
  /** Worker: memory embeddings. auto = the org's OpenAI key when present, else full-text search only. */
  EMBEDDINGS: z.enum(["auto", "none", "hash"]).default("auto"),
  /** Default models (D-064): DeepSeek V4.1 Flash 1017 on OpenRouter, GPT-6 Luna on OpenAI, unless overridden. */
  DEFAULT_MODEL_OPENROUTER: z.string().optional(),
  DEFAULT_MODEL_OPENAI: z.string().optional(),
  DEFAULT_REASONING_EFFORT: z
    .enum(["none", "low", "medium", "high", "xhigh", "max"])
    .default("medium"),
  /** Worker: cap on output tokens per model call (live checks use a small cap). */
  CASAMA_MAX_OUTPUT_TOKENS: z.coerce.number().int().positive().optional(),
  RUN_CONCURRENCY: z.coerce.number().int().positive().default(20),
  /** Runs one workspace may have going at once; the rest wait their turn (0 = no limit). */
  RUN_WORKSPACE_CONCURRENCY: z.coerce.number().int().min(0).default(5),
  /**
   * Live calls paid from credits go through the server's relay, which counts what Gemini reports
   * (billing audit 2026-11-17). Needs PUBLIC_API_URL; off: the app talks to Gemini directly and
   * reports the counts itself.
   */
  LIVE_CALL_RELAY: z.enum(["on", "off"]).default("on"),
  /** Lazy tool loading (D-106): bots with more tools than this load the rest on demand; 0 = off. */
  LAZY_TOOLS_THRESHOLD: z.coerce.number().int().min(0).default(30),
  /** Sandbox supervisor (computers). Both unset: bots have no computers. */
  SUPERVISOR_URL: z.url().optional(),
  SUPERVISOR_TOKEN: z.string().min(16).optional(),
  /** Live view (Phase 5): coturn's static-auth-secret and the TURN address clients use. */
  TURN_SECRET: z.string().min(16).optional(),
  TURN_PUBLIC_HOST: z.string().default("localhost"),
  TURN_PORT: z.coerce.number().int().default(3478),
  TURN_TLS_PORT: z.coerce.number().int().optional(),
  /** Owner admin console: comma-separated emails; when unset, the first user to sign up. */
  INSTANCE_ADMIN_EMAILS: z.string().optional(),
  /**
   * Memory this server can give hosted computers, in GB (D-252): computer starts past it answer
   * capacity_full, and the Admin screen's capacity card and alerts measure against it. 0 = no budget.
   */
  COMPUTER_HOST_MEMORY_GB: z.coerce.number().min(0).default(0),
  /** A computer's memory when its size isn't recorded (matches the supervisor's default). */
  COMPUTER_MEMORY_MB: z.coerce.number().int().min(256).default(2048),
  /** Where the console checks for newer releases (GitHub "latest release" API shape); unset = off. */
  UPDATE_CHECK_URL: z.url().optional(),
  /** Desktop companion (D-066): personal computers as bot computers. On by default. */
  LOCAL_COMPUTERS: bool.default(true),
  /** Worker: how it reaches the API's internal endpoints (the companion tunnel). */
  API_INTERNAL_URL: z.url().optional(),
  /** Shared secret for /internal/*; derived from DATABASE_URL when unset. */
  INTERNAL_TOKEN: z.string().min(32).optional(),
  /** Casama's own Slack app (D-277): one-click install for every workspace. Unset: self-hosters paste a bot token. */
  SLACK_CLIENT_ID: z.string().optional(),
  SLACK_CLIENT_SECRET: z.string().optional(),
  SLACK_SIGNING_SECRET: z.string().optional(),
  SLACK_API_BASE: z.string().optional(),
  /**
   * Sign in with Apple token revocation (D-420, App Store 5.1.1(v)): the Sign in with Apple key
   * (.p8, inline or a path), its key id and the team id. The API swaps the app's authorization code
   * for a refresh token and revokes it when the account is deleted. APP_ID is the iOS/macOS bundle
   * id (the system sheet), SERVICES_ID the Services ID (the browser sign-in). Unset: off.
   */
  APPLE_SIGNIN_KEY_P8: z.string().optional(),
  APPLE_SIGNIN_KEY_ID: z.string().optional(),
  APPLE_SIGNIN_TEAM_ID: z.string().optional(),
  APPLE_SIGNIN_APP_ID: z.string().default("ai.casama.app"),
  APPLE_SIGNIN_SERVICES_ID: z.string().default("ai.casama.app.signin"),
  /** Tests: another host for Apple's token and revoke endpoints. */
  APPLE_SIGNIN_URL: z.url().optional(),
  /** Days between an account deletion request and the purge (D-072). */
  ACCOUNT_DELETION_GRACE_DAYS: z.coerce.number().int().min(0).max(30).default(7),
  /** Opt-in anonymous telemetry (D-074): off unless set to "on". */
  TELEMETRY: z.enum(["on", "off"]).default("off"),
  TELEMETRY_URL: z.url().default("https://telemetry.casama.ai/v1/ping"),
  /** Enterprise features in ee/ (D-073): a signed license key. */
  CASAMA_LICENSE_KEY: z.string().optional(),
  /** Tests only (ignored unless NODE_ENV=test): another license public key. */
  CASAMA_LICENSE_PUBLIC_KEY: z.string().optional(),
  /** Supabase service role key: SSO provider admin (ee) and scan-to-sign-in codes (D-296). */
  SUPABASE_SERVICE_ROLE_KEY: z.string().optional(),
  /**
   * How this server reaches Supabase itself (the self-host stack: http://kong:8000). Unset:
   * SUPABASE_URL, which is the public address and may not answer from inside the server.
   */
  SUPABASE_INTERNAL_URL: z.url().optional(),
  /**
   * Whether Auth refuses new accounts (the stack's DISABLE_SIGNUP, which Auth enforces). Given to
   * the API too so the apps can say so instead of offering a sign-up that fails.
   */
  DISABLE_SIGNUP: bool.optional(),
  /** What a sign-in QR code opens: a page that hands the code to the app (the code rides after "#"). */
  PAIR_LINK_URL: z.url().default("https://casama.ai/pair"),
  /** Prometheus metrics at /metrics (D-075); protect with a bearer token in production. */
  METRICS_TOKEN: z.string().min(16).optional(),
  /** OAuth clients for apps that don't allow automatic registration (D-089), as JSON by app id:
   * {"slack": {"client_id": "...", "client_secret": "..."}}. Redirect URI: <API>/oauth/callback. */
  MCP_OAUTH_CLIENTS: z.string().optional(),
  /** A Google OAuth client for Gmail, Calendar and Drive (Google's MCP servers, D-089). */
  GOOGLE_OAUTH_CLIENT_ID: z.string().optional(),
  GOOGLE_OAUTH_CLIENT_SECRET: z.string().optional(),
  /**
   * A Zoho client for Casama's own Zoho sign-in (D-350): a "Server-based application" in
   * api-console.zoho.com with multi-DC on and <API>/oauth/callback as its redirect URI.
   */
  ZOHO_OAUTH_CLIENT_ID: z.string().optional(),
  ZOHO_OAUTH_CLIENT_SECRET: z.string().optional(),
  /** Where Zoho sign-ins start (default Zoho's US accounts server, which hands off to the rest). */
  ZOHO_ACCOUNTS_URL: z.url().default("https://accounts.zoho.com"),
  /**
   * Where vendors send people back after an app sign-in (default <API>/oauth/callback, or localhost
   * when the API is on a private network address over http: vendors only accept https or
   * localhost). Admin-registered clients (Google, MCP_OAUTH_CLIENTS) must list it.
   */
  OAUTH_REDIRECT_URL: z.url().optional(),
  /** Public base URL of this API (signaling URLs); defaults to the request's origin. */
  PUBLIC_API_URL: z.url().optional(),
  /**
   * Pages (D-119) are served from their own origin: PAGES_URL is its public address, PAGES_PORT
   * the port the API process serves it on (unset: not served by this process).
   */
  PAGES_URL: z.url().default("http://localhost:8790"),
  PAGES_PORT: z.coerce.number().int().optional(),
  /**
   * Sites (docs/SITES-AND-DOMAINS-PLAN.md): the zone published sites live on, name.<zone>. A domain
   * of its own, never the app's: one bad site must not touch the app's reputation. Its wildcard
   * record points at the pages port. Unset: no site addresses.
   */
  CASAMA_SITES_ZONE: z
    .string()
    .regex(/^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$/)
    .optional(),
  /**
   * Connected domains on Casama Cloud: Cloudflare for SaaS custom hostnames on the sites zone. The
   * token needs only SSL and Certificates: Edit on that zone. Unset: no connected domains here.
   */
  CASAMA_SITES_CF_ZONE_ID: z.string().optional(),
  CASAMA_SITES_CF_API_TOKEN: z.string().optional(),
  CASAMA_SITES_CF_API_URL: z.url().optional(),
  /**
   * A self-hosted server whose Caddy answers on 80 and 443 issues certificates for connected
   * domains on demand, asking the API first (/internal/tls-ask).
   */
  CASAMA_SITES_OWN_EDGE: bool.default(false),
  /** What a self-hosted server's connected domains point at: its public IPv4 and IPv6 addresses. */
  CASAMA_SITES_SERVER_IPV4: z.string().optional(),
  CASAMA_SITES_SERVER_IPV6: z.string().optional(),
  /**
   * How a bought domain's bare name reaches its site: "forward" sends it to www at the registrar
   * (always works); "aname" points it at the site directly (only once the live check shows
   * Cloudflare validates ALIAS/ANAME records, §7.5).
   */
  CASAMA_SITES_APEX: z.enum(["forward", "aname"]).default("forward"),
  /** Public DNS-over-HTTPS resolvers that must agree on a domain's records (two, comma-separated). */
  CASAMA_SITES_DOH_URLS: z
    .string()
    .default("https://cloudflare-dns.com/dns-query,https://dns.google/resolve"),
  /** Buying domains: "none" or the registrar (namecom). Casama Cloud only. */
  CASAMA_DOMAINS_REGISTRAR: z.enum(["none", "namecom"]).default("none"),
  /** The endings on sale, comma-separated (default: com net org co io app dev xyz me info). */
  CASAMA_DOMAINS_TLDS: z.string().optional(),
  /** Name.com reseller API: username and token; NAMECOM_API_URL is api.dev.name.com for the test system. */
  NAMECOM_USERNAME: z.string().optional(),
  NAMECOM_API_TOKEN: z.string().optional(),
  NAMECOM_API_URL: z.url().default("https://api.name.com"),
  /** Signs Name.com's webhooks to /hooks/registrar/namecom. */
  NAMECOM_WEBHOOK_SECRET: z.string().optional(),
  /** Dodo products for domains: a Pay What You Want one-time product and an on-demand subscription. */
  DODO_DOMAIN_PRODUCT_ID: z.string().optional(),
  DODO_DOMAIN_RENEWAL_PRODUCT_ID: z.string().optional(),
  /** Below this registrar balance (USD) the instance owners are told. */
  CASAMA_DOMAINS_BALANCE_ALERT: z.coerce.number().min(0).default(100),
  /**
   * Casama Cloud's Composio key (D-130): inbox reading through Composio's managed Google sign-in
   * until Google's restricted-scope review passes. Unset: that option is hidden on Casama Cloud.
   */
  COMPOSIO_API_KEY: z.string().optional(),
  COMPOSIO_API_URL: z.url().optional(),
  /**
   * Signing secret of the Composio project's webhook subscription to {PUBLIC_API_URL}/hooks/composio
   * (D-247). Set: new mail and calendar changes start check-in scans. Unset: scans keep their schedule.
   */
  COMPOSIO_WEBHOOK_SECRET: z.string().optional(),
  /** Headless Chromium for page PDFs (unset: PDF export is off). */
  PDF_CHROMIUM_PATH: z.string().optional(),
  /**
   * A Gotenberg sidecar for page PDFs, e.g. http://pdf:3000 (compose profile `pdf`). Wins over
   * PDF_CHROMIUM_PATH: Chromium keeps no sandbox inside the API's container, so it runs isolated.
   */
  PDF_RENDERER_URL: z.url().optional(),
});
export type Env = z.infer<typeof EnvSchema>;

/** Rules that span more than one setting. */
function crossChecks(env: Env): string[] {
  const problems: string[] = [];
  if (env.VOICE_CONTEXT_TARGET_TOKENS >= env.VOICE_CONTEXT_TRIGGER_TOKENS)
    problems.push(
      `VOICE_CONTEXT_TARGET_TOKENS: must be below VOICE_CONTEXT_TRIGGER_TOKENS (${env.VOICE_CONTEXT_TRIGGER_TOKENS})`,
    );
  return problems;
}

/** Per-server overrides of the default models. */
export const modelOverrides = (env: Env) => ({
  openrouter: env.DEFAULT_MODEL_OPENROUTER,
  openai: env.DEFAULT_MODEL_OPENAI,
});

/** Which providers serve the shared OpenRouter key (D-354); undefined leaves OpenRouter's default. */
export function cloudModelRouting(
  env: Pick<Env, "CLOUD_MODEL_PROVIDER_SORT" | "CLOUD_MODEL_PROVIDERS">,
): OpenRouterRouting | undefined {
  const order = (env.CLOUD_MODEL_PROVIDERS ?? "")
    .split(",")
    .map((p) => p.trim())
    .filter(Boolean);
  const sort = env.CLOUD_MODEL_PROVIDER_SORT === "off" ? undefined : env.CLOUD_MODEL_PROVIDER_SORT;
  if (!order.length && !sort) return undefined;
  return { ...(order.length ? { order } : {}), ...(sort ? { sort } : {}) };
}

/** The routing for chat steps a person is waiting on, when it differs (D-355); else undefined. */
export function cloudModelChatRouting(
  env: Pick<Env, "CLOUD_MODEL_CHAT_SORT">,
): OpenRouterRouting | undefined {
  return env.CLOUD_MODEL_CHAT_SORT ? { sort: env.CLOUD_MODEL_CHAT_SORT } : undefined;
}

/** When a live call's oldest turns are dropped, and down to how much (tokens of conversation). */
export const voiceContext = (
  env: Pick<Env, "VOICE_CONTEXT_TRIGGER_TOKENS" | "VOICE_CONTEXT_TARGET_TOKENS">,
) => ({
  triggerTokens: env.VOICE_CONTEXT_TRIGGER_TOKENS,
  targetTokens: env.VOICE_CONTEXT_TARGET_TOKENS,
});

export function loadEnv(source: Record<string, string | undefined> = process.env): Env {
  // An empty value means "not set" (compose files and .env templates write KEY= for optional keys).
  const cleaned = Object.fromEntries(Object.entries(source).filter(([, v]) => v !== ""));
  const parsed = EnvSchema.safeParse(cleaned);
  if (!parsed.success) {
    const fields = parsed.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`).join("; ");
    throw new Error(`Invalid environment: ${fields}`);
  }
  const problems = crossChecks(parsed.data);
  if (problems.length) throw new Error(`Invalid environment: ${problems.join("; ")}`);
  return parsed.data;
}
