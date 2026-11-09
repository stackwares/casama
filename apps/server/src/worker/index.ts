import { readFileSync } from "node:fs";
import { DBOS } from "@dbos-inc/dbos-sdk";
import {
  AiSdkGateway,
  builtinTools,
  ComputerService,
  CredentialResolver,
  type Embedder,
  type FixtureFile,
  type FixtureTurn,
  hashEmbedder,
  MemoryService,
  type ModelGateway,
  openAiEmbedder,
  ReplayGateway,
  recordingGateway,
  registerComputerTools,
} from "@kasama/agent";
import { createDb, type Database } from "@kasama/db";
import { SupervisorProvider } from "@kasama/sandbox";
import type { Logger } from "@kasama/observability";
import { computersIdleWorkflow, configureWorkflows, maintenanceWorkflow, QUEUES } from "./workflows.ts";

export interface WorkerOptions {
  databaseUrl: string;
  logger: Logger;
  logLevel?: string;
  /** Comma-separated fixture files: replay recorded model responses instead of calling providers. */
  modelFixtures?: string;
  /** Append every real model exchange to this file as fixture turns. */
  modelRecord?: string;
  embeddings?: "auto" | "none" | "hash";
  runConcurrency?: number;
  db?: Database;
  /** Sandbox supervisor; without it bots have no computers. */
  supervisor?: { url: string; token: string };
}

function loadFixtures(paths: string): FixtureFile[] {
  return paths.split(",").map((p) => {
    const text = readFileSync(p.trim(), "utf8");
    if (p.trim().endsWith(".jsonl")) {
      const turns = text
        .split("\n")
        .filter(Boolean)
        .map((l) => JSON.parse(l) as FixtureTurn);
      return { name: p, turns };
    }
    return JSON.parse(text) as FixtureFile;
  });
}

export function buildGateway(
  opts: Pick<WorkerOptions, "modelFixtures" | "modelRecord">,
): ModelGateway {
  if (opts.modelFixtures) return new ReplayGateway(loadFixtures(opts.modelFixtures));
  const real = new AiSdkGateway();
  return opts.modelRecord ? recordingGateway(real, opts.modelRecord) : real;
}

/** Launches DBOS on the application Postgres, in its own `dbos` schema. */
export async function startWorker(opts: WorkerOptions) {
  const handle = opts.db
    ? undefined
    : createDb(opts.databaseUrl, { max: (opts.runConcurrency ?? 20) + 5 });
  const db = opts.db ?? (handle as NonNullable<typeof handle>).db;
  const gateway = buildGateway(opts);
  const credentials = new CredentialResolver(db);
  const mode = opts.embeddings ?? "auto";
  const embedderFor = async (orgId: string): Promise<Embedder | null> => {
    if (mode === "none") return null;
    if (mode === "hash") return hashEmbedder();
    const cred = await credentials.embeddingCredential(orgId);
    return cred ? openAiEmbedder(cred) : null;
  };
  const computers = opts.supervisor
    ? new ComputerService(db, new SupervisorProvider(opts.supervisor.url, opts.supervisor.token))
    : undefined;
  const tools = builtinTools({ db, memory: async (orgId) => new MemoryService(db, await embedderFor(orgId)) });
  if (computers) registerComputerTools(tools);
  configureWorkflows({
    db,
    gateway,
    computers,
    agent: { db, gateway, credentials, embedderFor, tools, computers, logger: opts.logger },
  });

  DBOS.setConfig({
    name: "kasama",
    systemDatabaseUrl: opts.databaseUrl,
    systemDatabaseSchemaName: "dbos",
    logLevel: opts.logLevel ?? "info",
  });
  await DBOS.launch();
  await DBOS.registerQueue(QUEUES.runs, { workerConcurrency: opts.runConcurrency ?? 20 });
  await DBOS.registerQueue(QUEUES.system, { workerConcurrency: 5 });
  await DBOS.applySchedules([
    { scheduleName: "maintenance-hourly", workflowFn: maintenanceWorkflow, schedule: "0 * * * *" },
    { scheduleName: "computers-idle", workflowFn: computersIdleWorkflow, schedule: "* * * * *" },
  ]);
  opts.logger.info("worker started", { fixtures: !!opts.modelFixtures });
  return {
    async stop() {
      await DBOS.shutdown();
      await handle?.close();
    },
  };
}

export {
  agentRunWorkflow,
  pingWorkflow,
  QUEUES,
  testCredentialWorkflow,
  WORKFLOWS,
} from "./workflows.ts";
