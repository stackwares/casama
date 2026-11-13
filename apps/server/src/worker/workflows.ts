import {
  type ChatGptConfig,
  type ComputerService,
  CredentialResolver,
  checkCalendarTriggers,
  checkWatchers,
  collect,
  EventBus,
  expireCalls,
  expireCards,
  followUpLeftovers,
  gitSyncTick,
  knowledgeTick,
  listModels,
  type ModelGateway,
  type ModelList,
  mergeModelList,
  pollIMessage,
  postSuggestions,
  postTopicResults,
  projectHeartbeat,
  purgeDeviceData,
  type RunDeps,
  refreshIntegration,
  revokeToken,
  rewrapAllKeys,
  runAgent,
  safeFetch,
  sendDueSuggestions,
  sweepEncryption,
  syncComposioTriggers,
} from "@casama/agent";
import { contentKeys, type Database, liftTimeouts } from "@casama/db";
import { DEFAULT_MODELS } from "@casama/domain";
import { captureError } from "@casama/observability";
import { DBOS } from "@dbos-inc/dbos-sdk";
import { sql } from "drizzle-orm";
import superjson from "superjson";
import { sweepSignups } from "../services/analytics-signups.ts";
import { sweepReferralRewards } from "../services/referrals.ts";
import {
  claimDueRoutines,
  expireRoutines,
  fireDueCalendarRuns,
  handleRoutineWebhook,
  retimeRoutines,
  startRoutineForMessage,
} from "./routines.ts";
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
      /** Fixture mode: the model picker uses Casama's short list instead of calling providers. */
      offlineModels?: boolean;
      /** ChatGPT plan sign-in endpoints (tests point them at a fake OpenAI). */
      chatgpt?: ChatGptConfig;
      /** iOS call rings (D-135). */
      voip?: import("@casama/agent").VoipSender;
      /** Audit-log forwarding is licensed (D-146). */
      auditForwarding?: boolean;
      /** Invite friends rewards (D-211). */
      referrals?: { enabled: boolean; rewardUsd: number; welcomeUsd: number; cap: number };
      /** Leave-now device triggers (D-151): maps key and fetch. */
      leaveNow?: import("./device-triggers.ts").LeaveNowDeps;
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

/**
 * What the chat says about an unhandled error. A replay that no longer matches the code (DBOS
 * codes 26 and 37) means Casama was updated while the run waited; DBOS's own text is for us.
 */
function runErrorMessage(err: unknown): string {
  const code = (err as { dbosErrorCode?: number } | null)?.dbosErrorCode;
  if (code === 26 || code === 37)
    return "Casama was updated while this was waiting, so it stopped. Send your message again to pick up where it left off.";
  return (err as Error)?.message ?? String(err);
}

/** Marks a run that hasn't ended as failed and tells the chat, so nothing waits on it any more. */
async function failUnfinishedRun(runId: string, message: string) {
  const db = rt().db;
  const [failed] = await db.execute<{ id: string }>(sql`
    update public.runs
    set status = 'failed', ended_at = now(),
        error = ${JSON.stringify({ ok: false, code: "run_error", message })}::jsonb
    where id = ${runId}::uuid and status not in ('completed', 'failed', 'cancelled')
    returning id
  `);
  if (failed)
    await new EventBus(db).append(runId, "run.failed", { error_code: "run_error", message });
}

/** One durable workflow per run: every model and tool call is a checkpointed step. */
export const agentRunWorkflow = DBOS.registerWorkflow(
  async (runId: string) => {
    let result: { status: string };
    try {
      result = await runAgentDurably(runId);
    } catch (err) {
      captureError(err, {
        service: "casama-worker",
        run_id: runId,
        trace_id: runId.replace(/-/g, ""),
        step: "agentRunWorkflow",
      });
      // Never leave workflow or run hanging in non-terminal state on unhandled exception (ANALYTICS-PLAN §8.3 / §1.3 bug 1).
      // Written directly, not as a DBOS step: when the error is a replay that no longer matches
      // the code (D-228), every later step hits the same mismatch, so a step here never ran and
      // the run stayed "waiting" for good. The update only changes a run that hasn't ended.
      await failUnfinishedRun(runId, runErrorMessage(err)).catch(() => {});
      result = { status: "failed" };
    }
    // Stopped or failed: what the person sent meanwhile still gets an answer.
    if (result.status !== "completed") {
      try {
        const next = await DBOS.runStep(() => followUpLeftovers(rt().db, runId).catch(() => null), {
          name: "leftover-after-stop",
        });
        if (next)
          await rt()
            .agent.startRun?.(next)
            .catch(() => {});
      } catch {
        // A replay that no longer matches the code fails here too; the run is already marked.
      }
    }
    return result;
  },
  { name: WORKFLOWS.agentRun },
);

/**
 * A step's result as the workflow engine stores it. In a workspace that encrypts content (D-136)
 * the engine's own tables would otherwise hold replies, tool results and history in plain text
 * (D-267), so the result is sealed with the workspace's key before the engine sees it.
 */
export function sealStepOutput(orgId: string | null, value: unknown): unknown {
  if (!contentKeys.seals(orgId)) return value;
  return {
    $sealedStep: contentKeys.seal(orgId, superjson.stringify(value === undefined ? null : value)),
    u: value === undefined,
  };
}

/** The reverse of sealStepOutput; results stored before sealing pass through. */
export function openStepOutput(value: unknown): unknown {
  const sealed = (value as { $sealedStep?: unknown } | null)?.$sealedStep;
  if (typeof sealed !== "string") return value;
  if ((value as { u?: boolean }).u) return undefined;
  return superjson.parse(contentKeys.open(sealed) as string);
}

function runAgentDurably(runId: string) {
  // Read outside a step: a run's workspace never changes, so replays see the same value.
  let org: Promise<string | null> | undefined;
  const orgOf = () => {
    org ??= rt()
      .db.execute<{ org_id: string }>(sql`select org_id from public.runs where id = ${runId}::uuid`)
      .then((r) => r[0]?.org_id ?? null);
    return org;
  };
  return runAgent(runId, {
    ...rt().agent,
    step: async <T>(name: string, fn: () => Promise<T>) => {
      if (!contentKeys.anySealing) return DBOS.runStep(fn, { name });
      const orgId = await orgOf();
      return openStepOutput(
        await DBOS.runStep(async () => sealStepOutput(orgId, await fn()), { name }),
      ) as T;
    },
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
  });
}

/**
 * Fails runs that say they're working although their workflow ended two minutes ago or more.
 * Runs without a workflow (live calls, teach sessions) are left alone. Returns how many it failed.
 */
export async function failOrphanedRuns(db: Database) {
  const rows = await db.execute<{ id: string }>(sql`
    select r.id from public.runs r
    join dbos.workflow_status w on w.workflow_uuid = r.id::text
    where r.status in ('running', 'waiting_approval', 'waiting_takeover')
      and coalesce(r.started_at, r.created_at) > now() - interval '7 days'
      and w.status in ('SUCCESS', 'ERROR', 'CANCELLED', 'MAX_RECOVERY_ATTEMPTS_EXCEEDED')
      and w.updated_at < (extract(epoch from now()) * 1000)::bigint - 120000
    limit 50`);
  for (const r of rows)
    await failUnfinishedRun(
      r.id,
      "Casama stopped while this was running, so it couldn't finish. Send your message again to pick it up.",
    );
  return rows.length;
}

/** How long an ended workflow's recorded steps are kept. */
export const WORKFLOW_KEEP_DAYS = 7;

/** Deletes the engine's records of workflows that ended over a week ago, a batch at a time. */
export async function purgeEndedWorkflows(
  db: Database,
  keepDays = WORKFLOW_KEEP_DAYS,
  batch = 2000,
) {
  const rows = await db.execute<{ id: string }>(sql`
    select workflow_uuid as id from dbos.workflow_status
    where status in ('SUCCESS', 'ERROR', 'CANCELLED', 'MAX_RECOVERY_ATTEMPTS_EXCEEDED')
      and updated_at < (extract(epoch from now()) * 1000)::bigint - ${keepDays * 86_400_000}::bigint
    limit ${batch}`);
  if (rows.length === 0) return 0;
  await DBOS.deleteWorkflows(rows.map((r) => r.id));
  return rows.length;
}

/** Advisory lock keys for tick steps that must not overlap. */
const TICK_LOCKS = { projects: 731_001, imessage: 731_002 } as const;

/** Logs, captures to observability, and returns a fallback value when a background step throws. */
function captureStep<T>(stepName: string, fallback: T): (err: unknown) => T {
  return (err: unknown) => {
    captureError(err, { service: "casama-worker", step: stepName });
    return fallback;
  };
}

/** Every minute: start runs for routines that are due. */
export const routinesTickWorkflow = DBOS.registerWorkflow(
  async (scheduledAt: Date, _context: unknown) => {
    // Pushes held back by quiet hours go out once the window ends (D-109).
    await DBOS.runStep(
      () =>
        rt().agent.notifications?.sendDeferred().catch(captureStep("deferred-pushes", 0)) ??
        Promise.resolve(0),
      {
        name: "deferred-pushes",
      },
    );
    // Proactive bots (D-247): suggestions that waited for their time ("an hour before the show").
    await DBOS.runStep(
      () =>
        sendDueSuggestions(rt().db, rt().agent.notifications).catch(
          captureStep("due-suggestions", 0),
        ),
      { name: "due-suggestions" },
    );
    // General and topics (D-253): suggestion cards and topic results that waited for General to be free.
    await DBOS.runStep(
      async () =>
        (await postSuggestions(rt().db).catch(captureStep("general-suggestions", 0))) +
        (await postTopicResults(rt().db).catch(captureStep("general-topic-results", 0))),
      { name: "general-posts" },
    );
    // Timezones that follow the person (D-250): routines that moved zone get their next run anew.
    await DBOS.runStep(() => retimeRoutines(rt().db).catch(captureStep("retime-routines", 0)), {
      name: "retime-routines",
    });
    // Routines that end (D-262): past their end time, they switch off.
    await DBOS.runStep(() => expireRoutines(rt().db).catch(captureStep("expire-routines", 0)), {
      name: "expire-routines",
    });
    // App events start scans: subscribe Composio triggers for new connections, every 10 minutes,
    // once the Composio webhook is set up (COMPOSIO_WEBHOOK_SECRET).
    if (process.env.COMPOSIO_WEBHOOK_SECRET && new Date(scheduledAt).getUTCMinutes() % 10 === 0)
      await DBOS.runStep(
        () =>
          syncComposioTriggers(rt().db, rt().agent.fetch ?? fetch).catch(
            captureStep("composio-triggers", 0),
          ),
        { name: "composio-triggers" },
      );
    // New sign-ups become `signed_up` events (the sign-up is a database trigger the API never sees).
    await DBOS.runStep(() => sweepSignups(rt().db).catch(captureStep("analytics-signups", 0)), {
      name: "analytics-signups",
    });
    // Invite friends (D-211): friends who verified and finished a first run earn their inviter credits.
    const referrals = rt().referrals;
    if (referrals?.enabled)
      await DBOS.runStep(
        () => sweepReferralRewards(rt().db, referrals).catch(captureStep("referral-rewards", 0)),
        { name: "referral-rewards" },
      );
    // Encryption at rest (D-136): seal existing rows, or open them when it's turned off.
    await DBOS.runStep(() => sweepEncryption(rt().db).catch(captureStep("encryption-sweep", 0)), {
      name: "encryption-sweep",
    });
    // Payments (D-142): unused cards are cancelled after their hour.
    await DBOS.runStep(
      () =>
        rt().agent.payments
          ? expireCards(rt().agent.payments as never).catch(captureStep("expire-cards", 0))
          : Promise.resolve(0),
      { name: "expire-cards" },
    );
    // Audit-log forwarding (D-146, enterprise): stream new rows to each workspace's destinations.
    if (rt().auditForwarding)
      await DBOS.runStep(
        () =>
          import("@casama/ee")
            .then((m) => m.forwardAuditLogs(rt().db, { fetch: rt().fetch }))
            .catch(captureStep("audit-forward", 0)),
        { name: "audit-forward" },
      );
    // Phone calls nobody answered (D-135) become a push with the reason.
    await DBOS.runStep(
      () =>
        expireCalls({ db: rt().db, notifications: rt().agent.notifications }).catch(
          captureStep("expire-calls", 0),
        ),
      { name: "expire-calls" },
    );
    // Every step catches its own errors, so one failing step never blocks the rest (audit 2026-11).
    const runIds = await DBOS.runStep(
      () => claimDueRoutines(rt().db).catch(captureStep("claim-due", [] as string[])),
      {
        name: "claim-due",
      },
    );
    // Device triggers (D-151): leave now for the next event with a place.
    const lnDeps = rt().leaveNow;
    if (lnDeps)
      runIds.push(
        ...(await DBOS.runStep(
          () =>
            import("./device-triggers.ts")
              .then((m) => m.checkLeaveNow(rt().db, lnDeps))
              .catch(captureStep("leave-now", [] as string[])),
          { name: "leave-now" },
        )),
      );
    // Calendar triggers (D-132): read calendars every 5 minutes; start the runs whose time has come.
    await DBOS.runStep(
      () =>
        checkCalendarTriggers({ db: rt().db, fetch: rt().agent.fetch ?? fetch }).catch(
          captureStep("calendar-check", 0),
        ),
      { name: "calendar-check" },
    );
    runIds.push(
      ...(await DBOS.runStep(
        () => fireDueCalendarRuns(rt().db).catch(captureStep("calendar-fire", [] as string[])),
        {
          name: "calendar-fire",
        },
      )),
    );
    // Projects (D-113): start the next session of each active project that has ready work.
    // One heartbeat at a time across overlapping ticks and workers (a project never gets two sessions).
    const sessions = await DBOS.runStep(
      (): Promise<string[]> =>
        rt()
          .db.transaction(async (tx) => {
            // Notifications (push) go out while the lock is held.
            await liftTimeouts(tx);
            const [lock] = await tx.execute<{ ok: boolean }>(
              sql`select pg_try_advisory_xact_lock(${TICK_LOCKS.projects}) as ok`,
            );
            return lock?.ok
              ? projectHeartbeat(tx as Database, async () => {}, rt().agent.notifications)
              : [];
          })
          .catch(captureStep("project-heartbeat", [] as string[])),
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
        }).catch(captureStep("watchers", [] as string[])),
      { name: "watchers" },
    );
    runIds.push(...fired);
    // Chat apps (D-134): new iMessages from the user's Mac.
    if (rt().agent.local) {
      const local = rt().agent.local as { apiUrl: string; internalToken: string };
      runIds.push(
        ...(await DBOS.runStep(
          () =>
            rt()
              .db.transaction(async (tx) => {
                // Overlapping ticks would reply twice: one poll at a time. Each Mac is asked in turn
                // while the lock is held.
                await liftTimeouts(tx);
                const [lock] = await tx.execute<{ ok: boolean }>(
                  sql`select pg_try_advisory_xact_lock(${TICK_LOCKS.imessage}) as ok`,
                );
                return lock?.ok
                  ? pollIMessage(tx as Database, local, fetch, (id, text) =>
                      startRoutineForMessage(tx as Database, id, text),
                    )
                  : [];
              })
              .catch(captureStep("imessage", [] as string[])),
          { name: "imessage" },
        )),
      );
    }
    // Device connections (D-149): retention per kind, and stale device requests.
    // Hourly is plenty for retention (audit 2026-11: it scanned device_readings every minute).
    // (The scheduled time decides it, so a recovered workflow replays the same steps.)
    if (new Date(scheduledAt).getMinutes() === 7)
      await DBOS.runStep(() => purgeDeviceData(rt().db).catch(captureStep("device-retention", 0)), {
        name: "device-retention",
      });
    // Knowledge sources (D-125): new, resynced and daily-due sources.
    await DBOS.runStep(
      () =>
        knowledgeTick({
          db: rt().db,
          fetch: rt().agent.fetch ?? fetch,
          embedderFor: rt().agent.embedderFor,
          githubApiUrl: process.env.GITHUB_API_URL,
        }).catch(captureStep("knowledge", [] as string[])),
      { name: "knowledge" },
    );
    // Git sync of routines and skills (D-124): changed workspaces, and a check every 10 minutes.
    await DBOS.runStep(
      () =>
        gitSyncTick({
          db: rt().db,
          fetch: rt().agent.fetch ?? fetch,
          apiUrl: process.env.GITHUB_API_URL,
        }).catch(captureStep("git-sync", [] as string[])),
      { name: "git-sync" },
    );
    // Runs made by a step that failed partway, or by the API when starting failed, are still queued:
    // start any queued for 2 minutes (the workflow id is the run id, so starting twice is harmless).
    runIds.push(
      ...(await DBOS.runStep(
        async () =>
          (
            await rt().db.execute<{ id: string }>(sql`
              select id from public.runs where status = 'queued' and created_at < now() - interval '2 minutes'
                and created_at > now() - interval '1 day' order by created_at limit 50`)
          ).map((r) => r.id),
        { name: "queued-sweep" },
      ).catch(captureStep("queued-sweep", [] as string[]))),
    );
    // Runs still marked as working whose workflow has ended or was never recorded (a crash between
    // the two writes): nothing will finish them, so the chat would show "working" forever (D-268).
    await DBOS.runStep(() => failOrphanedRuns(rt().db).catch(captureStep("orphaned-runs", 0)), {
      name: "orphaned-runs",
    });
    for (const runId of new Set(runIds)) {
      try {
        await DBOS.startWorkflow(agentRunWorkflow, { workflowID: runId, queueName: QUEUES.runs })(
          runId,
        );
      } catch (err) {
        console.error(
          JSON.stringify({
            msg: "starting a run failed",
            run_id: runId,
            error: (err as Error).message,
          }),
        );
      }
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
  if (cred && ["brave_search", "tavily", "treg"].includes(cred.provider)) {
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
    const ping = async (effort: "none" | "low") => {
      const resolved = await new CredentialResolver(db).resolve(orgId, {
        credential_id: credentialId,
        model: chosen,
        reasoning_effort: effort,
      });
      await collect(
        gateway.stream({
          model: resolved,
          system: ["Reply with OK."],
          messages: [{ role: "user", content: "ping" }],
          // Room for a little reasoning on models that always reason.
          maxOutputTokens: effort === "none" ? 16 : 512,
        }),
      );
    };
    try {
      // A key check needs no reasoning, which keeps it to a few tokens. Some models always reason
      // and refuse "none" (OpenRouter's Muse Ember): then try again with the least.
      try {
        await ping("none");
      } catch (err) {
        if (!/reasoning/i.test(providerMessage(err) ?? "")) throw err;
        await ping("low");
      }
      outcome = { ok: true, model: chosen, latency_ms: Date.now() - started };
    } catch (err) {
      const status = (err as { status?: number }).status;
      const said = providerMessage(err);
      const error =
        status === 401 || status === 403
          ? "The provider rejected the key."
          : status
            ? `The provider returned ${status}${said ? `: ${said}` : "."}`
            : "Could not reach the provider.";
      outcome = { ok: false, model: chosen, latency_ms: Date.now() - started, error };
    }
  }
  await db.execute(
    sql`update public.model_credentials set last_tested_at = now(), last_test_ok = ${outcome.ok} where id = ${credentialId}::uuid`,
  );
  return outcome;
}

/** What the provider said about a failed call (its error message), short and without secrets. */
export function providerMessage(err: unknown): string | undefined {
  const cause = (err as { cause?: { responseBody?: unknown; message?: unknown } })?.cause;
  const body = cause?.responseBody;
  let text: unknown;
  if (typeof body === "string") {
    try {
      const parsed = JSON.parse(body) as {
        error?: { message?: unknown } | string;
        message?: unknown;
      };
      text =
        typeof parsed.error === "string" ? parsed.error : (parsed.error?.message ?? parsed.message);
    } catch {
      text = body;
    }
  }
  text ??= cause?.message;
  if (typeof text !== "string" || !text.trim()) return undefined;
  const clean = text
    .replace(/\b(sk|pk|rk|key|tok)[-_][A-Za-z0-9_-]{8,}/gi, "[redacted]")
    .replace(/[A-Za-z0-9_-]{32,}/g, "[redacted]")
    .trim();
  return clean.length > 200 ? `${clean.slice(0, 197)}…` : clean;
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
  async (orgId: string, botId: string, greeting?: string | null, phone?: boolean | null) =>
    DBOS.runStep(
      () => voiceSession(voiceRt(), orgId, botId, greeting ?? undefined, phone ?? undefined),
      { name: "session" },
    ),
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
    await DBOS.runStep(
      () => cleanupIdempotencyKeys(rt().db).catch(captureStep("idempotency-keys", 0)),
      {
        name: "idempotency-keys",
      },
    );
    await DBOS.runStep(
      () =>
        refreshIdleChatGpt(rt().db, rt().agent.credentials).catch(
          captureStep("chatgpt-refresh", 0),
        ),
      {
        name: "chatgpt-refresh",
      },
    );
    // Encryption at rest (D-136): data keys still wrapped with a previous server key are rewrapped
    // with the current one, so changing CONTENT_ENCRYPTION_KEY needs no manual step (audit 2026-11).
    await DBOS.runStep(() => rewrapAllKeys(rt().db).catch(captureStep("rewrap-keys", 0)), {
      name: "rewrap-keys",
    });
    // The engine keeps every step's result for replay. Once a workflow has ended nothing reads
    // them again, so they go after a week instead of growing forever (D-267).
    await DBOS.runStep(
      () => purgeEndedWorkflows(rt().db).catch(captureStep("purge-workflows", 0)),
      {
        name: "purge-workflows",
      },
    );
  },
  { name: "maintenance" },
);

/** Every minute: computers idle for 5 minutes (IDLE_SLEEP_MS, D-178) are archived to object storage and stopped. */
export const computersIdleWorkflow = DBOS.registerWorkflow(
  async (_scheduledAt: Date, _context: unknown) => {
    const computers = rt().computers;
    if (!computers) return;
    await DBOS.runStep(() => computers.sleepIdle(), { name: "sleep-idle" });
    await DBOS.runStep(() => computers.meterRunning(), { name: "meter-running-computers" });
  },
  { name: "computersIdle" },
);

/** Every minute on Casama Cloud: usage becomes credit deductions; expired plans fall back (D-070). */
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
    await DBOS.runStep(
      () => purgeDueAccounts(rt().db, rt().computers).catch(captureStep("purge-accounts", 0)),
      {
        name: "purge-accounts",
      },
    );
    await DBOS.runStep(() => applyRetention(rt().db).catch(captureStep("retention", 0)), {
      name: "retention",
    });
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

/** Daily at 00:20 UTC: summarize yesterday's product and workspace usage metrics (D-208, ANALYTICS-PLAN §6.11). */
export const analyticsDailyWorkflow = DBOS.registerWorkflow(
  async (_scheduledAt: Date, _context: unknown) => {
    const { runDailyAnalyticsRollup } = await import("./analytics-rollup.ts");
    await DBOS.runStep(
      () => runDailyAnalyticsRollup(rt().db).catch(captureStep("analytics-rollup", 0)),
      {
        name: "analytics-rollup",
      },
    );
  },
  { name: "analyticsDaily" },
);
