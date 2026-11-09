import { readFileSync } from "node:fs";
import { DBOS, DBOSClient } from "@dbos-inc/dbos-sdk";
import {
  AiSdkGateway,
  BraveSearchProvider,
  builtinTools,
  ComputerService,
  CredentialResolver,
  createSafeFetch,
  type Embedder,
  FalMediaProvider,
  FcmPushSender,
  type FixtureFile,
  type FixtureTurn,
  hashEmbedder,
  MemoryService,
  type ModelGateway,
  NotificationService,
  openAiEmbedder,
  type PushSender,
  RecordingPushSender,
  ReplayGateway,
  recordingGateway,
  registerAutonomyTools,
  registerComputerTools,
  registerDesktopTools,
  TavilySearchProvider,
} from "@kasama/agent";
import { createDb, type Database } from "@kasama/db";
import type { Logger } from "@kasama/observability";
import { SupervisorProvider } from "@kasama/sandbox";
import { sql } from "drizzle-orm";
import {
  computersIdleWorkflow,
  configureWorkflows,
  maintenanceWorkflow,
  QUEUES,
  routinesTickWorkflow,
} from "./workflows.ts";

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
  /** Push notifications; defaults to FCM when a service account is given, else recorded only. */
  push?: PushSender;
  fcmServiceAccountJson?: string;
  /** Private address ranges the worker may call (local development and tests only). */
  egressExemptCidrs?: string[];
  /** Base URL overrides for provider APIs (tests). */
  providerBases?: { fal?: string; brave?: string; tavily?: string };
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
  const tools = builtinTools({
    db,
    memory: async (orgId) => new MemoryService(db, await embedderFor(orgId)),
  });
  if (computers) {
    registerComputerTools(tools);
    registerDesktopTools(tools);
  }

  const fetchOut = createSafeFetch({ exemptCidrs: opts.egressExemptCidrs });
  const push =
    opts.push ??
    (opts.fcmServiceAccountJson
      ? new FcmPushSender(opts.fcmServiceAccountJson)
      : new RecordingPushSender());
  const notifications = new NotificationService(db, push);
  const providerKey = async (orgId: string, providers: string[]) => {
    const [row] = await db.execute<{ provider: string; key: string | null }>(sql`
      select c.provider, v.decrypted_secret as key from public.model_credentials c
      left join vault.decrypted_secrets v on v.id = c.vault_secret_id
      where c.org_id = ${orgId}::uuid and c.provider = any(${`{${providers.join(",")}}`}::text[])
      order by c.created_at limit 1`);
    return row?.key ? row : null;
  };
  let client: DBOSClient | undefined;
  registerAutonomyTools(tools, {
    db,
    fetch: fetchOut,
    notifications,
    mediaFor: async (orgId) => {
      const k = await providerKey(orgId, ["fal"]);
      return k?.key
        ? new FalMediaProvider({
            apiKey: k.key,
            fetch: fetchOut,
            syncBase: opts.providerBases?.fal,
            queueBase: opts.providerBases?.fal,
          })
        : null;
    },
    searchFor: async (orgId) => {
      const k = await providerKey(orgId, ["brave_search", "tavily"]);
      if (!k?.key) return null;
      return k.provider === "tavily"
        ? new TavilySearchProvider(k.key, { base: opts.providerBases?.tavily, fetch: fetchOut })
        : new BraveSearchProvider(k.key, { base: opts.providerBases?.brave, fetch: fetchOut });
    },
    // Child runs (subagents, delegation) run on their own queue and are awaited from the tool step.
    runChild: async (childRunId) => {
      if (!client) throw new Error("worker not started");
      const handle = await client.enqueue<(id: string) => Promise<{ status: string }>>(
        { queueName: QUEUES.subruns, workflowName: "agentRun", workflowID: childRunId },
        childRunId,
      );
      return handle.getResult({ pollingIntervalMs: 250 });
    },
  });
  configureWorkflows({
    db,
    gateway,
    computers,
    fetch: fetchOut,
    agent: {
      db,
      gateway,
      credentials,
      embedderFor,
      tools,
      computers,
      notifications,
      fetch: fetchOut,
      logger: opts.logger,
    },
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
  await DBOS.registerQueue(QUEUES.subruns, { workerConcurrency: opts.runConcurrency ?? 20 });
  client = await DBOSClient.create({
    systemDatabaseUrl: opts.databaseUrl,
    systemDatabaseSchemaName: "dbos",
  });
  await DBOS.applySchedules([
    { scheduleName: "maintenance-hourly", workflowFn: maintenanceWorkflow, schedule: "0 * * * *" },
    { scheduleName: "computers-idle", workflowFn: computersIdleWorkflow, schedule: "* * * * *" },
    { scheduleName: "routines-tick", workflowFn: routinesTickWorkflow, schedule: "* * * * *" },
  ]);
  opts.logger.info("worker started", { fixtures: !!opts.modelFixtures });
  return {
    async stop() {
      await client?.destroy();
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
