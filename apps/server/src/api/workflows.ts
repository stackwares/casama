import { DBOSClient } from "@dbos-inc/dbos-sdk";

export interface CredentialTestOutcome {
  ok: boolean;
  model: string;
  latency_ms: number;
  error?: string;
}

/** How the API hands work to the worker. */
export interface Workflows {
  startRun(runId: string): Promise<void>;
  testCredential(
    credentialId: string,
    orgId: string,
    model?: string,
  ): Promise<CredentialTestOutcome>;
  /** Wakes a run that waits for an approval (decided or cancelled). */
  signalRun(runId: string): Promise<void>;
  testIntegration(integrationId: string): Promise<{ ok: boolean; tools: string[]; error?: string }>;
  /** Hands a webhook to the worker, which verifies its signature and starts the routine. */
  routineWebhook(
    routineId: string,
    kind: "github" | "custom",
    body: string,
    headers: Record<string, string>,
  ): Promise<void>;
  /** Voice (D-065): keyed operations run in the worker; each returns quickly. */
  voiceTranscribe(
    orgId: string,
    botId: string,
    audioB64: string,
    mime: string,
    language?: string,
  ): Promise<VoiceResult<{ text: string; provider: string; seconds: number }>>;
  voiceSpeak(
    orgId: string,
    messageId: string,
  ): Promise<VoiceResult<{ voiceKey: string; cached: boolean }>>;
  voiceSession(
    orgId: string,
    botId: string,
  ): Promise<
    VoiceResult<{
      model: string;
      clientSecret: string;
      expiresAt: string;
      connectUrl: string;
      tools: number;
    }>
  >;
  close(): Promise<void>;
}

export type VoiceResult<T> = ({ ok: true } & T) | { ok: false; error: string };

const withTimeout = <T>(p: Promise<T>, ms: number, what: string) =>
  Promise.race([
    p,
    new Promise<never>((_, reject) => setTimeout(() => reject(new Error(`${what} timed out`)), ms)),
  ]);

/** Enqueues DBOS workflows from the API process; the worker executes them. */
export async function dbosWorkflows(databaseUrl: string): Promise<Workflows> {
  const client = await DBOSClient.create({
    systemDatabaseUrl: databaseUrl,
    systemDatabaseSchemaName: "dbos",
  });
  return {
    async startRun(runId) {
      // The run id is the workflow id, so a retried enqueue never starts a second run.
      await client.enqueue(
        { queueName: "runs", workflowName: "agentRun", workflowID: runId },
        runId,
      );
    },
    async testCredential(credentialId, orgId, model) {
      const handle = await client.enqueue<
        (c: string, o: string, m?: string) => Promise<CredentialTestOutcome>
      >({ queueName: "system", workflowName: "testCredential" }, credentialId, orgId, model);
      const timeout = new Promise<never>((_, reject) =>
        setTimeout(() => reject(new Error("credential test timed out")), 30_000),
      );
      return Promise.race([handle.getResult({ pollingIntervalMs: 200 }), timeout]);
    },
    async signalRun(runId) {
      await client.send(runId, { at: Date.now() }, "signal").catch(() => {});
    },
    async testIntegration(integrationId) {
      const handle = await client.enqueue<
        (id: string) => Promise<{ ok: boolean; tools: string[]; error?: string }>
      >({ queueName: "system", workflowName: "testIntegration" }, integrationId);
      const timeout = new Promise<never>((_, reject) =>
        setTimeout(() => reject(new Error("integration test timed out")), 60_000),
      );
      return Promise.race([handle.getResult({ pollingIntervalMs: 200 }), timeout]);
    },
    async routineWebhook(routineId, kind, body, headers) {
      await client.enqueue(
        { queueName: "system", workflowName: "routineWebhook" },
        routineId,
        kind,
        body,
        headers,
      );
    },
    async voiceTranscribe(orgId, botId, audioB64, mime, language) {
      const h = await client.enqueue<(...a: unknown[]) => Promise<never>>(
        { queueName: "voice", workflowName: "voiceTranscribe" },
        orgId,
        botId,
        audioB64,
        mime,
        language,
      );
      return withTimeout(h.getResult({ pollingIntervalMs: 50 }), 60_000, "transcription");
    },
    async voiceSpeak(orgId, messageId) {
      const h = await client.enqueue<(...a: unknown[]) => Promise<never>>(
        { queueName: "voice", workflowName: "voiceSpeak" },
        orgId,
        messageId,
      );
      return withTimeout(h.getResult({ pollingIntervalMs: 50 }), 60_000, "speech");
    },
    async voiceSession(orgId, botId) {
      const h = await client.enqueue<(...a: unknown[]) => Promise<never>>(
        { queueName: "voice", workflowName: "voiceSession" },
        orgId,
        botId,
      );
      return withTimeout(h.getResult({ pollingIntervalMs: 25 }), 20_000, "voice session");
    },
    close: () => client.destroy(),
  };
}
