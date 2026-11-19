import type { Database, JwtClaims } from "@casama/db";
import type { Logger } from "@casama/observability";
import type { Env } from "../env.ts";
import type { EmailSender } from "../services/email.ts";
import type { TokenVerifier } from "./auth.ts";
import type { RunEventHub } from "./run-event-hub.ts";
import type { Workflows } from "./workflows.ts";

export interface AppDeps {
  env: Env;
  db: Database;
  verifyToken: TokenVerifier;
  email: EmailSender;
  logger: Logger;
  workflows: Workflows;
  /** Computers (Phase 2); unset when no supervisor is configured. */
  computers?: import("@casama/agent").ComputerService;
  /** Where the Library keeps files copied off computers (D-276); unset: none are kept. */
  objects?: import("@casama/sandbox").ObjectStore | null;
  hub: RunEventHub;
  /** Connected desktop companions (Phase 6, D-066). */
  devices?: import("./routes/local.ts").DeviceRegistry;
  /** Live view (Phase 5); unset when no TURN relay is configured. */
  live?: import("./routes/live.ts").LiveConfig;
  /** Billing (Phase 7, D-070); off on self-hosted servers. */
  billing?: import("../billing/service.ts").BillingService;
  /** Casama Link, cloud side: proxy targets (D-071) and the servers' addresses (D-296). */
  casamaLink?: {
    supervisor?: { url: string; token: string };
    models?: {
      url: string;
      key: string;
      markup?: number;
      routing?: import("@casama/agent").OpenRouterRouting;
    };
    servers?: import("../link/servers.ts").LinkServers;
    /** The push relay's sender (D-296). */
    push?: import("@casama/agent").PushSender;
    /** The push relay's sender of iPhone call rings. */
    voip?: import("@casama/agent").VoipSender;
    /** The push relay's sender of widget refresh pushes (D-405). */
    widgets?: import("@casama/agent").WidgetPushSender;
    /** The push relay's sender of alerts to Apple Watches' own tokens (D-410). */
    watch?: import("@casama/agent").WatchAlertSender;
    /** The relay for live view away from the computer (D-296). */
    turn?: import("../link/turn.ts").TurnProvider;
  };
  /** The support assistant's model calls (tests replace it); default: fetch. */
  supportFetch?: typeof fetch;
  /** Calls to Resend for the monthly email (D-408; tests replace it); default: fetch. */
  newsletterFetch?: typeof fetch;
  /** Calls to Apple's Sign in with Apple token and revoke endpoints (D-420; tests replace it). */
  appleFetch?: typeof fetch;
  /** Fetches Apple's and Google's sign-in keys (D-427 ID-token invite claims; tests replace it). */
  idTokenFetch?: typeof fetch;
  /** Auth's admin API (tests replace it); default: from SUPABASE_SERVICE_ROLE_KEY. */
  authAdmin?: { url: string; serviceRoleKey: string; fetch?: typeof fetch };
  /** Casama Link, self-hosted side (D-296): this server's own public address, when it has one. */
  remoteAccess?: import("../services/remote-access.ts").RemoteAccess;
  /** Casama Link, self-hosted side: the relay for live view away from the computer. */
  outsideRelay?: import("../services/outside-relay.ts").OutsideRelay;
  /** Wallpaper photo search (D-087); defaults to Unsplash when UNSPLASH_ACCESS_KEY is set. */
  wallpapers?: import("../services/wallpapers.ts").WallpaperSource | null;
  /** Built-in app connections: outbound fetch and catalog overrides (tests). */
  apps?: import("./routes/apps.ts").AppsOptions;
  /** DNS TXT lookups (SSO domain verification; tests replace it). */
  resolveTxt?: (domain: string) => Promise<string[][]>;
  /** Page PDFs (D-119); unset: PDF export is off. */
  pdf?: import("../services/pdf.ts").PdfRenderer | null;
  /** Work that goes on after a response, such as a computer reset (D-240); tests await it. */
  onBackgroundTask?: (task: Promise<unknown>) => void;
  /** Connected domains (D-329): the edge and DNS lookups; tests replace them. Default: from env. */
  sites?: {
    provider?: import("../sites/hostnames.ts").HostnameProvider | null;
    dns?: import("../sites/dns.ts").DnsLookup;
    fetch?: typeof fetch;
    /** Buying domains: the registrar and domain payments (tests replace them). */
    registrar?: import("../sites/registrar.ts").Registrar | null;
    payments?: import("../sites/payments.ts").DomainPayments;
  };
  /** Readiness checks by name; each throws when unhealthy. */
  readiness: Record<string, () => Promise<void>>;
  /** Widget refresh pushes for changes made through the API (D-405); unset: none. */
  glance?: import("@casama/agent").GlancePusher;
  /** Pushes the API sends itself, such as a watch's "Open on phone" (D-410); unset: none. */
  notifications?: import("@casama/agent").NotificationService;
}

/** A request signed with a watch key (D-410): whose watch, in which workspace, with which limits. */
export interface WatchCaller {
  id: string;
  userId: string;
  orgId: string;
  platform: "watchos" | "wearos";
  /** What the person lets their watches allow (watch_prefs.allow). */
  allow: "medium" | "low" | "none";
  /** Show details on the watch; off is private. */
  showDetails: boolean;
}

/** A request signed with a widget key (D-405): who it reads for, in which workspace. */
export interface WidgetCaller {
  id: string;
  userId: string;
  orgId: string;
  private: boolean;
}

export type AppEnv = {
  Variables: {
    claims?: JwtClaims;
    requestId: string;
    widgetKey?: WidgetCaller;
    watchKey?: WatchCaller;
  };
};
