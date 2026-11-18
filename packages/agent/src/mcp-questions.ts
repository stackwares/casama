/**
 * A connected MCP server's question to the person mid-call (MCP elicitation, D-363). The tool call
 * waits: the question becomes a card in the chat (`mcp.question`), the person answers through
 * `POST /v1/mcp-questions/{id}/answer`, and the answer goes back to the server. Unanswered for 10
 * minutes, or the run stopped: the server is told the question was cancelled.
 */
import type { Database } from "@casama/db";
import { mcpQuestionFields } from "@casama/domain";
import { sql } from "drizzle-orm";
import type { McpQuestionAnswer, McpQuestionRequest } from "./integrations.ts";
import type { NotificationService } from "./notifications.ts";

export const MCP_QUESTION_TTL_MS = 10 * 60 * 1000;

export interface AskMcpQuestionArgs {
  runId: string;
  orgId: string;
  botId: string;
  botName?: string;
  integrationId: string;
  /** What the person knows the connection as. */
  connection: string;
  emit: (type: string, payload: Record<string, unknown>) => Promise<void>;
  signal?: AbortSignal;
  notifications?: NotificationService;
  pollMs?: number;
}

const wait = (ms: number, signal?: AbortSignal) =>
  new Promise<void>((resolve) => {
    const t = setTimeout(resolve, ms);
    signal?.addEventListener(
      "abort",
      () => {
        clearTimeout(t);
        resolve();
      },
      { once: true },
    );
  });

export async function askMcpQuestion(
  db: Database,
  args: AskMcpQuestionArgs,
  q: McpQuestionRequest,
): Promise<McpQuestionAnswer> {
  // A form Casama can't show (nested objects, arrays) is declined rather than half-shown.
  if (!mcpQuestionFields(q.schema)) return { action: "decline" };
  const message = q.message.slice(0, 4000);
  const connection = args.connection.slice(0, 200) || "A connected app";
  const [row] = await db.execute<{ id: string; expires_at: Date | string }>(sql`
    insert into public.mcp_questions (org_id, bot_id, run_id, integration_id, connection, message, schema, expires_at)
    values (${args.orgId}::uuid, ${args.botId}::uuid, ${args.runId}::uuid, ${args.integrationId}::uuid,
            ${connection}, ${message}, ${JSON.stringify(q.schema)}::jsonb,
            now() + make_interval(secs => ${MCP_QUESTION_TTL_MS / 1000}))
    returning id, expires_at`);
  const id = (row as { id: string }).id;
  await args.emit("mcp.question", {
    question_id: id,
    connection,
    message,
    schema: q.schema,
    expires_at: new Date(String(row?.expires_at)).toISOString(),
  });
  if (args.notifications) {
    const [run] = await db.execute<{ created_by: string | null; conversation_id: string | null }>(
      sql`select created_by, conversation_id from public.runs where id = ${args.runId}::uuid`,
    );
    if (run?.created_by)
      await args.notifications
        .notify(run.created_by, args.orgId, "mcp_question", {
          title: `${connection} has a question`,
          body: message || `${args.botName ?? "Your bot"} is waiting for your answer.`,
          link: run.conversation_id
            ? `/bots/${args.botId}/chat?c=${run.conversation_id}`
            : `/bots/${args.botId}/chat`,
          bot_id: args.botId,
          mcp_question_id: id,
        })
        .catch(() => {});
  }
  const resolved = async (outcome: "accepted" | "declined" | "cancelled" | "expired") =>
    args.emit("mcp.question_resolved", { question_id: id, outcome }).catch(() => {});
  for (;;) {
    if (args.signal?.aborted) {
      await db.execute(sql`update public.mcp_questions set status = 'cancelled', resolved_at = now()
        where id = ${id}::uuid and status = 'pending'`);
      await resolved("cancelled");
      return { action: "cancel" };
    }
    const [r] = await db.execute<{
      status: string;
      answer: Record<string, string | number | boolean> | null;
      past: boolean;
    }>(
      sql`select status, answer, expires_at <= now() as past from public.mcp_questions where id = ${id}::uuid`,
    );
    if (!r) return { action: "cancel" };
    if (r.status === "pending" && r.past) {
      await db.execute(sql`update public.mcp_questions set status = 'expired', resolved_at = now()
        where id = ${id}::uuid and status = 'pending'`);
      await resolved("expired");
      return { action: "cancel" };
    }
    if (r.status !== "pending") {
      // The answer goes to the server; the row keeps only that it was answered.
      await db.execute(sql`update public.mcp_questions set answer = null where id = ${id}::uuid`);
      const outcome = r.status as "accepted" | "declined" | "cancelled" | "expired";
      await resolved(outcome);
      if (outcome === "accepted") return { action: "accept", content: r.answer ?? {} };
      return { action: outcome === "declined" ? "decline" : "cancel" };
    }
    await wait(args.pollMs ?? 1000, args.signal);
  }
}
