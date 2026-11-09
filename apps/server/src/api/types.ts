import type { Database, JwtClaims } from "@kasama/db";
import type { Logger } from "@kasama/observability";
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
  computers?: import("@kasama/agent").ComputerService;
  hub: RunEventHub;
  /** Connected desktop companions (Phase 6, D-066). */
  devices?: import("./routes/local.ts").DeviceRegistry;
  /** Live view (Phase 5); unset when no TURN relay is configured. */
  live?: import("./routes/live.ts").LiveConfig;
  /** Readiness checks by name; each throws when unhealthy. */
  readiness: Record<string, () => Promise<void>>;
}

export type AppEnv = {
  Variables: {
    claims?: JwtClaims;
    requestId: string;
  };
};
