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
  hub: RunEventHub;
  /** Connected desktop companions (Phase 6, D-066). */
  devices?: import("./routes/local.ts").DeviceRegistry;
  /** Live view (Phase 5); unset when no TURN relay is configured. */
  live?: import("./routes/live.ts").LiveConfig;
  /** Billing (Phase 7, D-070); off on self-hosted servers. */
  billing?: import("../billing/service.ts").BillingService;
  /** Cloud Connect proxy targets (cloud side, D-071). */
  connect?: {
    supervisor?: { url: string; token: string };
    models?: { url: string; key: string; markup?: number };
  };
  /** Wallpaper photo search (D-087); defaults to Unsplash when UNSPLASH_ACCESS_KEY is set. */
  wallpapers?: import("../services/wallpapers.ts").WallpaperSource | null;
  /** Built-in app connections: outbound fetch and catalog overrides (tests). */
  apps?: import("./routes/apps.ts").AppsOptions;
  /** DNS TXT lookups (SSO domain verification; tests replace it). */
  resolveTxt?: (domain: string) => Promise<string[][]>;
  /** Page PDFs (D-119); unset: PDF export is off. */
  pdf?: import("../services/pdf.ts").PdfRenderer | null;
  /** Readiness checks by name; each throws when unhealthy. */
  readiness: Record<string, () => Promise<void>>;
}

export type AppEnv = {
  Variables: {
    claims?: JwtClaims;
    requestId: string;
  };
};
