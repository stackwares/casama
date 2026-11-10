import { DBOS } from "@dbos-inc/dbos-sdk";
import {
  type ChatGptConfig,
  type ComputerService,
  CredentialResolver,
  checkWatchers,
  gitSyncTick,
  collect,
  listModels,
  type ModelGateway,
  type ModelList,
  mergeModelList,
  projectHeartbeat,
  type RunDeps,
  refreshIntegration,
  revokeToken,
  runAgent,
  safeFetch,
} from "@kasama/agent";
import type { Database } from "@kasama/db";
import { DEFAULT_MODELS } from "@kasama/domain";
import { sql } from "drizzle-orm";
import { claimDueRoutines, handleRoutineWebhook } from "./routines.ts";
import { type VoiceRuntime, voiceSession, voiceSpeak, voiceTranscribe } from "./voice.ts";

export const QUEUES = {
  runs: "runs",
  subruns: "subruns",
  system: "system",
  voice: "voice",
} as const;
export const WORKFLOWS = {
  agentRun: "agentRun",
  testCredential: "testCredential",
  listCredentialModels: "listCredentialModels",
  revokeCredential: "revokeCredential",
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
      voice?: VoiceRuntime;
      billing?: import("../billing/service.ts").BillingService;
      telemetry?: { url: string; version: string };
      /** Fixture mode: the model picker uses Kasama's short list instead of calling providers. */
      offlineModels?: boolean;
      /** ChatGPT plan sign-in endpoints (tests point them at a fake OpenAI). */
      chatgpt?: ChatGptConfig;
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
    // Pushes held back by quiet hours go out once the window ends (D-109).
    await DBOS.runStep(
      () =>
        rt()
          .agent.notifications?.sendDeferred()
          .catch(() => 0) ?? Promise.resolve(0),
      {
        name: "deferred-pushes",
      },
    );
    const runIds = await DBOS.runStep(() => claimDueRoutines(rt().db), { name: "claim-due" });
    // Projects (D-113): start the next session of each active project that has ready work.
    const sessions = await DBOS.runStep(
      (): Promise<string[]> =>
        projectHeartbeat(rt().db, async () => {}, rt().agent.notifications).catch(() => []),
      { name: "project-heartbeat" },
    );
    runIds.push(...sessions);
    // Watchers (D-116): checks without a model; matches start their runs right away.
    const fired = await DBOS.runStep(
      (): Promise<string[]> =>
        checkWatchers({
          db: rt().db,
          fetch: rt().agent.fetch ?? fetch,
          startRun: async () => {},
          local: rt().agent.local,
        }).catch(() => []),
      { name: "watchers" },
    );
    runIds.push(...fired);
    // Git sync of routines and skills (D-124): changed workspaces, and a check every 10 minutes.
    await DBOS.runStep(
      () =>
        gitSyncTick({ db: rt().db, fetch: rt().agent.fetch ?? fetch, apiUrl: process.env.GITHUB_API_URL }).catch(() => []),
      { name: "git-sync" },
    );
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
          local: rt().agent.local,
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
  credentials: CredentialResolver = new CredentialResolver(db),
) {
  const [cred] = await db.execute<{ provider: string }>(
    sql`select provider from public.model_credentials where id = ${credentialId}::uuid and org_id = ${orgId}::uuid`,
  );
  if (cred?.provider === "chatgpt") {
    // A ChatGPT plan is checked by listing its models, which spends none of the plan's allowance.
    const started = Date.now();
    const list = await listCredentialModels(db, credentialId, orgId, { credentials });
    const outcome: CredentialTestOutcome = {
      ok: list.source === "live",
      model: list.models[0]?.id ?? "",
      latency_ms: Date.now() - started,
      error: list.source === "live" ? undefined : (list.error ?? "ChatGPT did not answer."),
    };
    await db.execute(
      sql`update public.model_credentials set last_tested_at = now(), last_test_ok = ${outcome.ok} where id = ${credentialId}::uuid`,
    );
    return outcome;
  }
  if (
    cred &&
    ["fal", "brave_search", "tavily", "deepgram", "elevenlabs", "cartesia", "fish_audio"].includes(
      cred.provider,
    )
  ) {
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
    DBOS.runStep(
      () =>
        testCredential(rt().db, rt().gateway, credentialId, orgId, model, rt().agent.credentials),
      { name: "test" },
    ),
  { name: WORKFLOWS.testCredential },
);

/** The model picker's list for a key. Runs in the worker because only the worker reads Vault. */
export async function listCredentialModels(
  db: Database,
  credentialId: string,
  orgId: string,
  opts: { offline?: boolean; fetch?: typeof fetch; credentials?: CredentialResolver } = {},
): Promise<ModelList> {
  const [row] = await db.execute<{
    provider: string;
    base_url: string | null;
    key: string | null;
  }>(sql`
    select c.provider, c.base_url, s.decrypted_secret as key
    from public.model_credentials c
    left join vault.decrypted_secrets s on s.id = c.vault_secret_id
    where c.id = ${credentialId}::uuid and c.org_id = ${orgId}::uuid`);
  if (!row) return { models: [], source: "featured", error: "Credential not found." };
  if (opts.offline) return { models: mergeModelList(row.provider, []), source: "featured" };
  if (row.provider === "chatgpt") {
    // The tokens are refreshed if needed; the access token is the bearer for the model list.
    let resolved: Awaited<ReturnType<CredentialResolver["resolve"]>>;
    try {
      resolved = await (opts.credentials ?? new CredentialResolver(db)).resolve(orgId, {
        credential_id: credentialId,
        model: "",
      });
    } catch (err) {
      return {
        models: mergeModelList("chatgpt", []),
        source: "featured",
        error: (err as Error).message,
      };
    }
    return listModels(
      { provider: "chatgpt", apiKey: resolved.apiKey, baseUrl: resolved.baseUrl },
      opts.fetch ?? rt().chatgpt?.fetch,
    );
  }
  // The admin chose this base URL (it may be a local Ollama), so the plain fetch is used, as in chats.
  return listModels(
    { provider: row.provider, apiKey: row.key ?? undefined, baseUrl: row.base_url ?? undefined },
    opts.fetch,
  );
}

export const listCredentialModelsWorkflow = DBOS.registerWorkflow(
  async (credentialId: string, orgId: string) =>
    DBOS.runStep(
      () =>
        listCredentialModels(rt().db, credentialId, orgId, {
          offline: rt().offlineModels,
          credentials: rt().agent.credentials,
        }),
      { name: "list" },
    ),
  { name: WORKFLOWS.listCredentialModels },
);

/**
 * Revokes a ChatGPT sign-in before its credential is deleted (SPEC: Disconnect). Best effort: the
 * API deletes the credential either way, and the outcome says whether OpenAI confirmed.
 */
export async function revokeCredential(
  credentials: CredentialResolver,
  credentialId: string,
  cfg: ChatGptConfig = {},
): Promise<{ ok: boolean; error?: string }> {
  const tokens = await credentials.chatGptTokens(credentialId);
  if (!tokens) return { ok: true };
  try {
    await revokeToken(
      { authUrl: cfg.authUrl, fetch: cfg.fetch },
      { clientId: tokens.client_id, token: tokens.refresh_token },
    );
    return { ok: true };
  } catch (err) {
    return { ok: false, error: (err as Error).message };
  }
}

export const revokeCredentialWorkflow = DBOS.registerWorkflow(
  async (credentialId: string) =>
    DBOS.runStep(() => revokeCredential(rt().agent.credentials, credentialId, rt().chatgpt), {
      name: "revoke",
    }),
  { name: WORKFLOWS.revokeCredential },
);

/** Refresh tokens last 30 days from their last use: refresh plans idle for 20 days. */
export async function refreshIdleChatGpt(db: Database, credentials: CredentialResolver) {
  const rows = await db.execute<{ id: string }>(sql`
    select id from public.model_credentials
    where provider = 'chatgpt' and status = 'ok'
      and coalesce(refreshed_at, created_at) < now() - interval '20 days'
    order by coalesce(refreshed_at, created_at) limit 200`);
  let refreshed = 0;
  for (const r of rows) {
    try {
      await credentials.refreshChatGpt(r.id, { force: true });
      refreshed++;
    } catch {
      // Marked needs_reconnect (owner told) or left for the next hour on a network error.
    }
  }
  return refreshed;
}

/** Voice (D-065): short, keyed operations on their own queue. */
const voiceRt = () => {
  const v = rt().voice;
  if (!v) throw new Error("voice not configured");
  return v;
};
export const voiceTranscribeWorkflow = DBOS.registerWorkflow(
  async (orgId: string, botId: string, audioB64: string, mime: string, language?: string) =>
    DBOS.runStep(() => voiceTranscribe(voiceRt(), orgId, botId, audioB64, mime, language), {
      name: "transcribe",
    }),
  { name: "voiceTranscribe" },
);
export const voiceSpeakWorkflow = DBOS.registerWorkflow(
  async (orgId: string, messageId: string) =>
    DBOS.runStep(() => voiceSpeak(voiceRt(), orgId, messageId), { name: "speak" }),
  { name: "voiceSpeak" },
);
export const voiceSessionWorkflow = DBOS.registerWorkflow(
  async (orgId: string, botId: string) =>
    DBOS.runStep(() => voiceSession(voiceRt(), orgId, botId), { name: "session" }),
  { name: "voiceSession" },
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
    await DBOS.runStep(() => refreshIdleChatGpt(rt().db, rt().agent.credentials), {
      name: "chatgpt-refresh",
    });
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

/** Every minute on Kasama Cloud: usage becomes credit deductions; expired plans fall back (D-070). */
export const billingSettleWorkflow = DBOS.registerWorkflow(
  async (_scheduledAt: Date, _context: unknown) => {
    const billing = rt().billing;
    if (!billing?.enabled) return;
    await DBOS.runStep(() => billing.settle(), { name: "settle" });
  },
  { name: "billingSettle" },
);

/** Daily: purge deleted accounts after their grace period; drop run events past retention (D-072). */
export const privacyWorkflow = DBOS.registerWorkflow(
  async (_scheduledAt: Date, _context: unknown) => {
    const { purgeDueAccounts, applyRetention } = await import("../services/privacy.ts");
    await DBOS.runStep(() => purgeDueAccounts(rt().db, rt().computers), { name: "purge-accounts" });
    await DBOS.runStep(() => applyRetention(rt().db), { name: "retention" });
  },
  { name: "privacy" },
);

/** Weekly, only with TELEMETRY=on: anonymous counts (D-074). */
export const telemetryWorkflow = DBOS.registerWorkflow(
  async (_scheduledAt: Date, _context: unknown) => {
    const t = rt().telemetry;
    if (!t) return;
    const { sendTelemetry } = await import("../services/telemetry.ts");
    await DBOS.runStep(() => sendTelemetry(rt().db, t.url, t.version).catch(() => null), {
      name: "ping",
    });
  },
  { name: "telemetry" },
);
