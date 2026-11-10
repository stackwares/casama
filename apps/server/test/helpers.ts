import type { Server } from "node:http";
import { createServer as createNetServer } from "node:net";
import { serve } from "@hono/node-server";
import { ComputerService } from "@kasama/agent";
import { contentKeys, createDb, type DbHandle, LocalKeyWrapper } from "@kasama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@kasama/db/testing";
import { createLogger } from "@kasama/observability";
import { LocalProvider, unavailableProvider } from "@kasama/sandbox";
import type { SandboxStack } from "@kasama/sandbox/testing";
import { SignJWT } from "jose";
import { createApp } from "../src/api/app.ts";
import { createTokenVerifier } from "../src/api/auth.ts";
import { attachLocalConnect, DeviceRegistry, internalToken } from "../src/api/routes/local.ts";
import { pgRunEventHub, type RunEventHub } from "../src/api/run-event-hub.ts";
import type { AppDeps } from "../src/api/types.ts";
import { dbosWorkflows, type Workflows } from "../src/api/workflows.ts";
import { billingFromEnv, kasamaCloudProvider } from "../src/billing/index.ts";
import { loadEnv } from "../src/env.ts";
import type { EmailMessage, EmailSender } from "../src/services/email.ts";
import { attachTelephony } from "../src/api/routes/telephony.ts";

export const JWT_SECRET = "test-secret-at-least-32-characters-long!!";

export interface Harness {
  /** Set when started with `local`: the real HTTP server's URL. */
  serverUrl?: string;
  deps: import("../src/api/types.ts").AppDeps;
  computers?: ComputerService;
  tdb: TestDatabase;
  handle: DbHandle;
  app: ReturnType<typeof createApp>;
  outbox: EmailMessage[];
  /** A user and their token; `claims` adds JWT claims such as `aal: "aal2"` (two-step sign-in). */
  user(
    email: string,
    claims?: Record<string, unknown>,
  ): Promise<{ id: string; email: string; token: string }>;
  /** Another token for an existing user, with extra claims. */
  tokenFor(user: { id: string; email: string }, claims?: Record<string, unknown>): Promise<string>;
  request(path: string, init?: RequestInit & { token?: string; json?: unknown }): Promise<Response>;
  stop(): Promise<void>;
}

const noWorkflows: Workflows = {
  startRun: async () => {},
  testCredential: async () => ({ ok: false, model: "", latency_ms: 0, error: "no worker" }),
  listCredentialModels: async () => ({ models: [], source: "featured", error: "no worker" }),
  revokeCredential: async () => ({ ok: false, error: "no worker" }),
  close: async () => {},
  signalRun: async () => {},
  testIntegration: async () => ({ ok: false, tools: [], error: "no worker" }),
  routineWebhook: async () => {},
  voiceTranscribe: async () => ({ ok: false, error: "no worker" }),
  voiceSpeak: async () => ({ ok: false, error: "no worker" }),
  voiceSession: async () => ({ ok: false, error: "no worker" }),
};

export async function startHarness(
  opts: {
    email?: boolean;
    rateLimit?: number;
    /** Encryption at rest: the server key (base64, 32 bytes). */
    contentKey?: string;
    worker?: {
      /** Recorded model responses; omit only in live checks (real provider calls). */
      fixtures?: string;
      maxOutputTokens?: number;
      push?: import("@kasama/agent").PushSender;
      egressExemptCidrs?: string[];
      providerBases?: {
        fal?: string;
        brave?: string;
        tavily?: string;
        openai?: string;
        deepgram?: string;
        elevenlabs?: string;
        treg?: string;
        twilio?: string;
        twilioLookups?: string;
        stripe?: string;
      };
      /** "self": this harness's own served address. */
      publicApiUrl?: string;
      /** ChatGPT plan sign-in endpoints (a fake OpenAI). */
      chatgpt?: { authUrl?: string; apiUrl?: string };
    };
    workflowsClient?: boolean;
    sandbox?: SandboxStack;
    /** Desktop companion: serve the app on a real port with the device WebSocket (D-066). */
    local?: boolean;
    /** Extra environment (billing, Cloud Connect). */
    env?: Record<string, string>;
    /** Serve on a real port (Cloud Connect cloud side). */
    serve?: boolean;
    /** Cloud Connect proxy targets (cloud side). */
    connect?: AppDeps["connect"];
    /** Cloud Connect, self-hosted side. */
    cloud?: { url: string; key: string };
    /** Built-in app connections: catalog and fetch overrides. */
    apps?: import("../src/api/routes/apps.ts").AppsOptions;
  } = {},
): Promise<Harness> {
  const tdb = await startTestDatabase();
  const handle = createDb(tdb.url, { max: 5 });
  // Encryption at rest (D-136): tests that cover it pass a server key.
  if (opts.contentKey) {
    contentKeys.configure(new LocalKeyWrapper(opts.contentKey));
    await contentKeys.attach(handle.client);
  }
  const env = loadEnv({
    DATABASE_URL: tdb.url,
    SUPABASE_URL: "http://127.0.0.1:54321",
    SUPABASE_ANON_KEY: "anon",
    SUPABASE_JWT_SECRET: JWT_SECRET,
    NODE_ENV: "test",
    RATE_LIMIT_PER_MINUTE: String(opts.rateLimit ?? 10_000),
    UPDATE_CHECK_URL: process.env.TEST_UPDATE_CHECK_URL,
    ...opts.env,
  });
  const billing = billingFromEnv(env, handle.db);
  const outbox: EmailMessage[] = [];
  // A real port for the companion tunnel, chosen before the worker starts.
  const localPort = opts.local || opts.serve ? await freePort() : 0;
  const localOpts = opts.local
    ? { apiUrl: `http://127.0.0.1:${localPort}`, internalToken: internalToken(env) }
    : undefined;
  const email: EmailSender = opts.email
    ? { enabled: true, send: async (m) => void outbox.push(m) }
    : { enabled: false, send: async () => {} };
  const hub: RunEventHub = await pgRunEventHub(handle.client);
  let workflows = noWorkflows;
  let worker: { stop(): Promise<void> } | undefined;
  if (opts.worker) {
    const { startWorker } = await import("../src/worker/index.ts");
    // The worker runs as its least-privilege role (D-095), so tests prove the grants are enough.
    await tdb.admin.unsafe("alter role kasama_worker login password 'kasama-worker-test'");
    const workerUrl = tdb.url.replace("postgres@", "kasama_worker:kasama-worker-test@");
    worker = await startWorker({
      databaseUrl: workerUrl,
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
      publicApiUrl: opts.worker.publicApiUrl === "self" ? `http://127.0.0.1:${localPort}` : opts.worker.publicApiUrl,
      chatgpt: opts.worker.chatgpt,
      local: localOpts,
      billing: billing.enabled ? billing : undefined,
      cloud: opts.cloud,
    });
    workflows = await dbosWorkflows(tdb.url);
  } else if (opts.workflowsClient) {
    workflows = await dbosWorkflows(tdb.url);
  }
  const computers =
    opts.sandbox || localOpts || opts.cloud
      ? new ComputerService(handle.db, opts.sandbox?.provider ?? unavailableProvider(), {
          ...(localOpts ? { local: new LocalProvider(localOpts) } : {}),
          ...(opts.cloud ? { "kasama-cloud": kasamaCloudProvider(opts.cloud) } : {}),
        })
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
    devices: opts.local ? new DeviceRegistry() : undefined,
    billing,
    connect: opts.connect,
    apps: opts.apps,
    env,
    db: handle.db,
    logger: createLogger("test", "error"),
    verifyToken: createTokenVerifier({ supabaseUrl: env.SUPABASE_URL, jwtSecret: JWT_SECRET }),
    email,
    readiness: { database: async () => void (await tdb.admin`select 1`) },
  };
  const app = createApp(deps);
  let server: Server | undefined;
  if (opts.local || opts.serve) {
    server = serve({
      fetch: app.fetch,
      port: localPort,
      hostname: "127.0.0.1",
    }) as unknown as Server;
    await new Promise((r) => server?.once("listening", r));
    if (opts.local) attachLocalConnect(server, deps);
    attachTelephony(server, deps);
  }
  const tokenFor = (u: { id: string; email: string }, claims: Record<string, unknown> = {}) =>
    new SignJWT({ email: u.email, role: "authenticated", ...claims })
      .setProtectedHeader({ alg: "HS256" })
      .setSubject(u.id)
      .setAudience("authenticated")
      .setIssuedAt()
      .setExpirationTime("1h")
      .sign(new TextEncoder().encode(JWT_SECRET));
  return {
    serverUrl: localPort ? `http://127.0.0.1:${localPort}` : undefined,
    deps,
    computers,
    tdb,
    handle,
    app,
    outbox,
    async user(address, claims = {}) {
      const u = await createAuthUser(tdb.admin, address);
      return { ...u, token: await tokenFor({ id: u.id, email: address }, claims) };
    },
    tokenFor,
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
      server?.close();
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

async function freePort() {
  const s = createNetServer();
  await new Promise<void>((r) => s.listen(0, "127.0.0.1", r));
  const port = (s.address() as { port: number }).port;
  await new Promise((r) => s.close(r));
  return port;
}
