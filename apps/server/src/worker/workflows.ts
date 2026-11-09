import { DBOS } from "@dbos-inc/dbos-sdk";
import {
  type ComputerService,
  CredentialResolver,
  collect,
  type ModelGateway,
  type RunDeps,
  refreshIntegration,
  runAgent,
  safeFetch,
} from "@kasama/agent";
import type { Database } from "@kasama/db";
import { DEFAULT_MODELS } from "@kasama/domain";
import { sql } from "drizzle-orm";
import { claimDueRoutines, handleRoutineWebhook } from "./routines.ts";

export const QUEUES = { runs: "runs", subruns: "subruns", system: "system" } as const;
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
      fetch?: typeof fetch;
    }
  | undefined;
export function configureWorkflows(r: NonNullable<typeof runtime>) {
  runtime = r;
}
const rt = () => {
  if (!runtime) throw new Error("worker not configured");
  return runtime;
};

/** Current approval state as seen by the waiting workflow. */
async function approvalState(db: Database, approvalId: string, runId: string) {
  const [row] = await db.execute<{ status: string; cancel: Date | null }>(sql`
    select a.status, r.cancel_requested_at as cancel from public.approvals a join public.runs r on r.id = a.run_id
    where a.id = ${approvalId}::uuid and a.run_id = ${runId}::uuid`);
  if (!row) return "gone";
  if (row.cancel) return "cancelled";
  return row.status;
}

/** One durable workflow per run: every model and tool call is a checkpointed step. */
export const agentRunWorkflow = DBOS.registerWorkflow(
  async (runId: string) =>
    runAgent(runId, {
      ...rt().agent,
      step: (name, fn) => DBOS.runStep(fn, { name }),
      // Waits durably (days if needed) without holding a process: woken by decisions and cancels.
      waitUntil: async (name, done, timeoutMs) => {
        const deadline = (await DBOS.now()) + timeoutMs;
        for (;;) {
          if (await DBOS.runStep(done, { name: `${name}-check` })) return;
          const now = await DBOS.now();
          if (now >= deadline) return;
          await DBOS.recv("signal", Math.max(1, Math.min(300, Math.ceil((deadline - now) / 1000))));
        }
      },
      waitForApproval: async (approvalId, run, timeoutMs) => {
        const deadline = (await DBOS.now()) + timeoutMs;
        for (;;) {
          const state = await DBOS.runStep(() => approvalState(rt().db, approvalId, run), {
            name: "approval-state",
          });
          if (state !== "pending") return;
          const now = await DBOS.now();
          if (now >= deadline) return;
          await DBOS.recv("signal", Math.max(1, Math.min(300, Math.ceil((deadline - now) / 1000))));
        }
      },
    }),
  { name: WORKFLOWS.agentRun },
);

/** Every minute: start runs for routines that are due. */
export const routinesTickWorkflow = DBOS.registerWorkflow(
  async (_scheduledAt: Date, _context: unknown) => {
    const runIds = await DBOS.runStep(() => claimDueRoutines(rt().db), { name: "claim-due" });
    for (const runId of runIds) {
      await DBOS.startWorkflow(agentRunWorkflow, { workflowID: runId, queueName: QUEUES.runs })(
        runId,
      );
    }
  },
  { name: "routinesTick" },
);

/** A GitHub or custom webhook for a routine (signature checked here because only the worker reads Vault). */
export const routineWebhookWorkflow = DBOS.registerWorkflow(
  async (
    routineId: string,
    kind: "github" | "custom",
    body: string,
    headers: Record<string, string>,
  ) => {
    const r = await DBOS.runStep(
      () => handleRoutineWebhook(rt().db, routineId, kind, body, headers),
      { name: "verify-and-create" },
    );
    if (r.ok && r.runId)
      await DBOS.startWorkflow(agentRunWorkflow, { workflowID: r.runId, queueName: QUEUES.runs })(
        r.runId,
      );
    return r;
  },
  { name: "routineWebhook" },
);

/** Lists an integration's tools to prove the connection works (credentials are read here). */
export const testIntegrationWorkflow = DBOS.registerWorkflow(
  async (integrationId: string) =>
    DBOS.runStep(
      async () => {
        const r = await refreshIntegration(rt().db, integrationId, {
          fetch: rt().fetch ?? safeFetch,
          secrets: [],
        });
        return { ok: r.ok, tools: r.tools.map((t) => t.name), error: r.ok ? undefined : r.error };
      },
      { name: "list-tools" },
    ),
  { name: "testIntegration" },
);

export const DEFAULT_TEST_MODELS: Record<string, string> = {
  ...DEFAULT_MODELS,
  anthropic: "claude-haiku-5-5",
  google: "gemini-2.5-flash",
  xai: "grok-3-mini",
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
  if (cred && ["fal", "brave_search", "tavily"].includes(cred.provider)) {
    return {
      ok: true,
      model: cred.provider,
      latency_ms: 0,
      error: "Stored. This provider is checked on first use.",
    };
  }
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
        // A key check needs no reasoning; it keeps the call to a few tokens.
        reasoning_effort: "none",
      });
      await collect(
        gateway.stream({
          model: resolved,
          system: ["Reply with OK."],
          messages: [{ role: "user", content: "ping" }],
          maxOutputTokens: 16,
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
