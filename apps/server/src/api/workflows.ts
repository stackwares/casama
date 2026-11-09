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
  close(): Promise<void>;
}

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
    close: () => client.destroy(),
  };
}
