/**
 * Langfuse LLM traces (SPEC: Model gateway, Run tracing; D-107). Every model attempt, including
 * failed ones that fell over to the next model, becomes a Langfuse generation in the run's trace,
 * with input and output passed through the run's redactor. Off unless the server has Langfuse keys,
 * and off for workspaces that turn `llm_tracing` off. Failures to send never affect the run.
 */
import type { ChatMessage } from "./gateway/types.ts";

export interface LangfuseConfig {
  baseUrl: string;
  publicKey: string;
  secretKey: string;
  fetch?: typeof fetch;
}

export interface GenerationRecord {
  traceId: string;
  runId: string;
  botName: string;
  orgId: string;
  model: string;
  attempt: number;
  start: Date;
  end: Date;
  input: { system: string[]; messages: ChatMessage[] };
  output: string | null;
  usage?: { inputTokens: number; outputTokens: number; cachedInputTokens?: number };
  costUsd?: number;
  error?: string;
}

export class LangfuseSink {
  private readonly cfg: LangfuseConfig;
  constructor(cfg: LangfuseConfig) {
    this.cfg = cfg;
  }

  /** Sends one generation (and its trace) through the public ingestion API. */
  async generation(g: GenerationRecord) {
    const now = new Date().toISOString();
    const batch = [
      {
        id: `${g.traceId}-trace`,
        type: "trace-create",
        timestamp: now,
        body: {
          id: g.traceId,
          name: `run ${g.botName}`,
          metadata: { run_id: g.runId, org_id: g.orgId },
        },
      },
      {
        id: `${g.traceId}-${g.start.getTime()}-${g.attempt}`,
        type: "generation-create",
        timestamp: now,
        body: {
          traceId: g.traceId,
          name: `chat ${g.model}`,
          model: g.model,
          startTime: g.start.toISOString(),
          endTime: g.end.toISOString(),
          input: g.input,
          output: g.output,
          level: g.error ? "ERROR" : "DEFAULT",
          statusMessage: g.error,
          metadata: { attempt: g.attempt },
          usageDetails: g.usage
            ? {
                input: g.usage.inputTokens,
                output: g.usage.outputTokens,
                ...(g.usage.cachedInputTokens !== undefined
                  ? { cache_read: g.usage.cachedInputTokens }
                  : {}),
              }
            : undefined,
          costDetails: g.costUsd !== undefined ? { total: g.costUsd } : undefined,
        },
      },
    ];
    const auth = Buffer.from(`${this.cfg.publicKey}:${this.cfg.secretKey}`).toString("base64");
    await (this.cfg.fetch ?? fetch)(`${this.cfg.baseUrl.replace(/\/$/, "")}/api/public/ingestion`, {
      method: "POST",
      headers: { authorization: `Basic ${auth}`, "content-type": "application/json" },
      body: JSON.stringify({ batch }),
      signal: AbortSignal.timeout(5000),
    }).catch(() => {});
  }
}
