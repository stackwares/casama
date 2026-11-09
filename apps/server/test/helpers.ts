import { ComputerService } from "@kasama/agent";
import { createDb, type DbHandle } from "@kasama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@kasama/db/testing";
import { createLogger } from "@kasama/observability";
import type { SandboxStack } from "@kasama/sandbox/testing";
import { SignJWT } from "jose";
import { createApp } from "../src/api/app.ts";
import { createTokenVerifier } from "../src/api/auth.ts";
import { pgRunEventHub, type RunEventHub } from "../src/api/run-event-hub.ts";
import { dbosWorkflows, type Workflows } from "../src/api/workflows.ts";
import { loadEnv } from "../src/env.ts";
import type { EmailMessage, EmailSender } from "../src/services/email.ts";

export const JWT_SECRET = "test-secret-at-least-32-characters-long!!";

export interface Harness {
  deps: import("../src/api/types.ts").AppDeps;
  computers?: ComputerService;
  tdb: TestDatabase;
  handle: DbHandle;
  app: ReturnType<typeof createApp>;
  outbox: EmailMessage[];
  user(email: string): Promise<{ id: string; email: string; token: string }>;
  request(path: string, init?: RequestInit & { token?: string; json?: unknown }): Promise<Response>;
  stop(): Promise<void>;
}

const noWorkflows: Workflows = {
  startRun: async () => {},
  testCredential: async () => ({ ok: false, model: "", latency_ms: 0, error: "no worker" }),
  close: async () => {},
  signalRun: async () => {},
  testIntegration: async () => ({ ok: false, tools: [], error: "no worker" }),
  routineWebhook: async () => {},
};

export async function startHarness(
  opts: {
    email?: boolean;
    rateLimit?: number;
    worker?: {
      /** Recorded model responses; omit only in live checks (real provider calls). */
      fixtures?: string;
      maxOutputTokens?: number;
      push?: import("@kasama/agent").PushSender;
      egressExemptCidrs?: string[];
      providerBases?: { fal?: string; brave?: string; tavily?: string };
    };
    workflowsClient?: boolean;
    sandbox?: SandboxStack;
  } = {},
): Promise<Harness> {
  const tdb = await startTestDatabase();
  const handle = createDb(tdb.url, { max: 5 });
  const env = loadEnv({
    DATABASE_URL: tdb.url,
    SUPABASE_URL: "http://127.0.0.1:54321",
    SUPABASE_ANON_KEY: "anon",
    SUPABASE_JWT_SECRET: JWT_SECRET,
    NODE_ENV: "test",
    RATE_LIMIT_PER_MINUTE: String(opts.rateLimit ?? 10_000),
  });
  const outbox: EmailMessage[] = [];
  const email: EmailSender = opts.email
    ? { enabled: true, send: async (m) => void outbox.push(m) }
    : { enabled: false, send: async () => {} };
  const hub: RunEventHub = await pgRunEventHub(handle.client);
  let workflows = noWorkflows;
  let worker: { stop(): Promise<void> } | undefined;
  if (opts.worker) {
    const { startWorker } = await import("../src/worker/index.ts");
    worker = await startWorker({
      databaseUrl: tdb.url,
      logger: createLogger("worker", "error"),
      logLevel: "error",
      modelFixtures: opts.worker.fixtures,
      maxOutputTokens: opts.worker.maxOutputTokens,
      embeddings: "hash",
      supervisor: opts.sandbox
        ? { url: opts.sandbox.supervisorUrl, token: opts.sandbox.token }
        : undefined,
      push: opts.worker.push,
      egressExemptCidrs: opts.worker.egressExemptCidrs,
      providerBases: opts.worker.providerBases,
    });
    workflows = await dbosWorkflows(tdb.url);
  } else if (opts.workflowsClient) {
    workflows = await dbosWorkflows(tdb.url);
  }
  const computers = opts.sandbox
    ? new ComputerService(handle.db, opts.sandbox.provider)
    : undefined;
  const live = opts.sandbox
    ? {
        turnSecret: opts.sandbox.turn.secret,
        turnHost: opts.sandbox.turn.host,
        turnPort: opts.sandbox.turn.udpPort,
        tokenSecret: "test-stream-token-secret-0123456789",
      }
    : undefined;
  const deps = {
    workflows,
    hub,
    computers,
    live,
    env,
    db: handle.db,
    logger: createLogger("test", "error"),
    verifyToken: createTokenVerifier({ supabaseUrl: env.SUPABASE_URL, jwtSecret: JWT_SECRET }),
    email,
    readiness: { database: async () => void (await tdb.admin`select 1`) },
  };
  const app = createApp(deps);
  return {
    deps,
    computers,
    tdb,
    handle,
    app,
    outbox,
    async user(address) {
      const u = await createAuthUser(tdb.admin, address);
      const token = await new SignJWT({ email: address, role: "authenticated" })
        .setProtectedHeader({ alg: "HS256" })
        .setSubject(u.id)
        .setAudience("authenticated")
        .setIssuedAt()
        .setExpirationTime("1h")
        .sign(new TextEncoder().encode(JWT_SECRET));
      return { ...u, token };
    },
    request(path, init = {}) {
      const headers = new Headers(init.headers);
      if (init.token) headers.set("authorization", `Bearer ${init.token}`);
      let body = init.body;
      if (init.json !== undefined) {
        headers.set("content-type", "application/json");
        body = JSON.stringify(init.json);
      }
      return Promise.resolve(app.request(path, { ...init, headers, body }));
    },
    async stop() {
      await workflows.close();
      await worker?.stop();
      await hub.close();
      await handle.close();
      await tdb.stop();
    },
  };
}

/** Response body as a loosely typed value for assertions. */
// biome-ignore lint/suspicious/noExplicitAny: test assertions inspect arbitrary JSON
export const j = (res: Response): Promise<any> => res.json();
