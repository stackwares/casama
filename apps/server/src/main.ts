import { serve } from "@hono/node-server";
import { ComputerService } from "@kasama/agent";
import { createDb } from "@kasama/db";
import { createLogger, initObservability, shutdownObservability } from "@kasama/observability";
import { SupervisorProvider } from "@kasama/sandbox";
import { sql } from "drizzle-orm";
import { createApp } from "./api/app.ts";
import { createTokenVerifier } from "./api/auth.ts";
import { attachTerminal } from "./api/routes/computers.ts";
import { attachStream, liveConfigFromEnv } from "./api/routes/live.ts";
import { pgRunEventHub } from "./api/run-event-hub.ts";
import { dbosWorkflows } from "./api/workflows.ts";
import { loadEnv } from "./env.ts";
import { disabledEmail, resendEmail } from "./services/email.ts";

const env = loadEnv();
const logger = createLogger(`server-${env.MODE}`, env.LOG_LEVEL);
initObservability({
  service: `kasama-${env.MODE}`,
  environment: env.NODE_ENV,
  sentryDsn: env.SENTRY_DSN,
  otlpEndpoint: env.OTEL_EXPORTER_OTLP_ENDPOINT,
});

const stoppers: Array<() => Promise<unknown>> = [];
const shutdown = async (signal: string) => {
  logger.info("shutting down", { signal });
  for (const stop of stoppers.reverse()) await stop().catch(() => {});
  await shutdownObservability();
  process.exit(0);
};
process.once("SIGTERM", () => void shutdown("SIGTERM"));
process.once("SIGINT", () => void shutdown("SIGINT"));

if (env.MODE === "api") {
  const handle = createDb(env.DATABASE_URL);
  stoppers.push(handle.close);
  const workflows = await dbosWorkflows(env.DATABASE_URL);
  stoppers.push(workflows.close);
  const hub = await pgRunEventHub(handle.client);
  stoppers.push(hub.close);
  const deps = {
    workflows,
    hub,
    computers:
      env.SUPERVISOR_URL && env.SUPERVISOR_TOKEN
        ? new ComputerService(
            handle.db,
            new SupervisorProvider(env.SUPERVISOR_URL, env.SUPERVISOR_TOKEN),
          )
        : undefined,
    live: liveConfigFromEnv(env),
    env,
    db: handle.db,
    logger,
    verifyToken: createTokenVerifier({
      supabaseUrl: env.SUPABASE_URL,
      jwtSecret: env.SUPABASE_JWT_SECRET,
    }),
    email: env.RESEND_API_KEY ? resendEmail(env.RESEND_API_KEY, env.EMAIL_FROM) : disabledEmail,
    readiness: { database: async () => void (await handle.db.execute(sql`select 1`)) },
  };
  const app = createApp(deps);
  const server = serve({ fetch: app.fetch, port: env.PORT }, (info) =>
    logger.info("api listening", { port: info.port }),
  );
  attachTerminal(server as unknown as import("node:http").Server, deps);
  attachStream(server as unknown as import("node:http").Server, deps);
  stoppers.push(() => new Promise((r) => server.close(r)));
} else {
  const { startWorker } = await import("./worker/index.ts");
  const worker = await startWorker({
    databaseUrl: env.DATABASE_URL,
    logger,
    logLevel: env.LOG_LEVEL,
    modelFixtures: env.KASAMA_MODEL_FIXTURES,
    modelRecord: env.KASAMA_MODEL_RECORD,
    embeddings: env.EMBEDDINGS,
    runConcurrency: env.RUN_CONCURRENCY,
    supervisor:
      env.SUPERVISOR_URL && env.SUPERVISOR_TOKEN
        ? { url: env.SUPERVISOR_URL, token: env.SUPERVISOR_TOKEN }
        : undefined,
  });
  stoppers.push(worker.stop);
}
