import { DBOS } from "@dbos-inc/dbos-sdk";
import {
  type ComputerService,
  CredentialResolver,
  collect,
  type ModelGateway,
  type RunDeps,
  runAgent,
} from "@kasama/agent";
import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";

export const QUEUES = { runs: "runs", system: "system" } as const;
export const WORKFLOWS = {
  agentRun: "agentRun",
  testCredential: "testCredential",
  ping: "ping",
} as const;

/** Set by startWorker before DBOS launches; workflows read it when they run. */
let runtime:
  | {
      agent: Omit<RunDeps, "step">;
      db: Database;
      gateway: ModelGateway;
      computers?: ComputerService;
    }
  | undefined;
export function configureWorkflows(r: NonNullable<typeof runtime>) {
  runtime = r;
}
const rt = () => {
  if (!runtime) throw new Error("worker not configured");
  return runtime;
};

/** One durable workflow per run: every model and tool call is a checkpointed step. */
export const agentRunWorkflow = DBOS.registerWorkflow(
  async (runId: string) =>
    runAgent(runId, { ...rt().agent, step: (name, fn) => DBOS.runStep(fn, { name }) }),
  { name: WORKFLOWS.agentRun },
);

export const DEFAULT_TEST_MODELS: Record<string, string> = {
  openai: "gpt-4o-mini",
  anthropic: "claude-haiku-5-5",
  google: "gemini-2.5-flash",
  xai: "grok-3-mini",
  openrouter: "openai/gpt-4o-mini",
};

export interface CredentialTestOutcome {
  ok: boolean;
  model: string;
  latency_ms: number;
  error?: string;
}

/** Validates a key with a 1-token call. Runs in the worker because only the worker reads Vault. */
export async function testCredential(
  db: Database,
  gateway: ModelGateway,
  credentialId: string,
  orgId: string,
  model?: string,
) {
  const [cred] = await db.execute<{ provider: string }>(
    sql`select provider from public.model_credentials where id = ${credentialId}::uuid and org_id = ${orgId}::uuid`,
  );
  const chosen = model ?? (cred ? DEFAULT_TEST_MODELS[cred.provider] : undefined);
  const started = Date.now();
  let outcome: CredentialTestOutcome;
  if (!cred || !chosen) {
    outcome = {
      ok: false,
      model: chosen ?? "",
      latency_ms: 0,
      error: cred ? "Pass a model to test this provider." : "Credential not found.",
    };
  } else {
    try {
      const resolved = await new CredentialResolver(db).resolve(orgId, {
        credential_id: credentialId,
        model: chosen,
      });
      await collect(
        gateway.stream({
          model: resolved,
          system: ["Reply with OK."],
          messages: [{ role: "user", content: "ping" }],
          maxOutputTokens: 1,
        }),
      );
      outcome = { ok: true, model: chosen, latency_ms: Date.now() - started };
    } catch (err) {
      const status = (err as { status?: number }).status;
      const error =
        status === 401 || status === 403
          ? "The provider rejected the key."
          : status
            ? `The provider returned ${status}.`
            : "Could not reach the provider.";
      outcome = { ok: false, model: chosen, latency_ms: Date.now() - started, error };
    }
  }
  await db.execute(
    sql`update public.model_credentials set last_tested_at = now(), last_test_ok = ${outcome.ok} where id = ${credentialId}::uuid`,
  );
  return outcome;
}

export const testCredentialWorkflow = DBOS.registerWorkflow(
  async (credentialId: string, orgId: string, model?: string) =>
    DBOS.runStep(() => testCredential(rt().db, rt().gateway, credentialId, orgId, model), {
      name: "test",
    }),
  { name: WORKFLOWS.testCredential },
);

/** Phase 0 test workflow: two checkpointed steps. */
export const pingWorkflow = DBOS.registerWorkflow(
  async (message: string) => {
    const upper = await DBOS.runStep(async () => message.toUpperCase(), { name: "upper" });
    return DBOS.runStep(async () => `${upper}!`, { name: "exclaim" });
  },
  { name: WORKFLOWS.ping },
);

/** Hourly housekeeping: idempotency keys live 24 hours. */
export async function cleanupIdempotencyKeys(db: Database) {
  const rows = await db.execute<{ n: number }>(
    sql`with d as (delete from public.idempotency_keys where created_at < now() - interval '24 hours' returning 1) select count(*)::int as n from d`,
  );
  return rows[0]?.n ?? 0;
}

export const maintenanceWorkflow = DBOS.registerWorkflow(
  async (_scheduledAt: Date, _context: unknown) => {
    await DBOS.runStep(() => cleanupIdempotencyKeys(rt().db), { name: "idempotency-keys" });
  },
  { name: "maintenance" },
);

/** Every minute: computers idle for 10 minutes are archived to object storage and stopped. */
export const computersIdleWorkflow = DBOS.registerWorkflow(
  async (_scheduledAt: Date, _context: unknown) => {
    const computers = rt().computers;
    if (!computers) return;
    await DBOS.runStep(() => computers.sleepIdle(), { name: "sleep-idle" });
  },
  { name: "computersIdle" },
);
