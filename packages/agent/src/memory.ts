import { contentKeys, type Database } from "@casama/db";
import { sql } from "drizzle-orm";
import { type Embedder, toPgVector } from "./embeddings.ts";
import {
  type ChatMessage,
  collect,
  type ModelGateway,
  type ResolvedModel,
  type Usage,
} from "./gateway/types.ts";

export type MemoryKind = "fact" | "episode" | "summary" | "preference";

export type MemoryRow = {
  id: string;
  kind: MemoryKind;
  content: string;
  pinned: boolean;
  importance: number;
};

/** Near-duplicate threshold on cosine distance (1 - similarity). */
const DUPLICATE_DISTANCE = 0.12;

const normalize = (s: string) =>
  s
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, " ")
    .trim();

export class MemoryService {
  private readonly db: Database;
  private readonly embedder: Embedder | null;
  constructor(db: Database, embedder: Embedder | null) {
    this.db = db;
    this.embedder = embedder;
  }

  private async vector(text: string) {
    if (!this.embedder) return null;
    try {
      return toPgVector(await this.embedder.embed(text));
    } catch {
      return null; // embeddings are best effort; full-text search still works
    }
  }

  /** Hybrid search (vector + full text, reciprocal rank fusion): top `limit` plus every pinned memory. */
  async recall(botId: string, query: string, limit = 8): Promise<MemoryRow[]> {
    const vec = await this.vector(query);
    const found = await this.db.execute<MemoryRow>(
      sql`select id, kind, content, pinned, importance from public.search_memories(${botId}::uuid, ${query}, ${vec}::extensions.vector, ${limit})`,
    );
    const pinned = await this.db.execute<MemoryRow>(
      sql`select id, kind, content, pinned, importance from public.memories where bot_id = ${botId}::uuid and pinned order by created_at`,
    );
    const seen = new Set<string>();
    return [...pinned, ...found].filter((m) => {
      if (seen.has(m.id)) return false;
      seen.add(m.id);
      return true;
    });
  }

  /** Writes a memory, updating a near-duplicate instead of appending. Returns the id and whether it was new. */
  async write(input: {
    orgId: string;
    botId: string;
    kind: MemoryKind;
    content: string;
    importance?: number;
    sourceRunId?: string;
  }): Promise<{ id: string; created: boolean }> {
    const content = input.content.trim().slice(0, 8000);
    const vec = await this.vector(content);
    let dup: { id: string } | undefined;
    if (vec) {
      [dup] = await this.db.execute<{ id: string }>(sql`
        select id from public.memories
        where bot_id = ${input.botId}::uuid and kind = ${input.kind} and embedding is not null
          and embedding operator(extensions.<=>) ${vec}::extensions.vector < ${DUPLICATE_DISTANCE}
        order by embedding operator(extensions.<=>) ${vec}::extensions.vector limit 1`);
    }
    if (!dup) {
      const same = await this.db.execute<{ id: string; content: string }>(
        sql`select id, content from public.memories where bot_id = ${input.botId}::uuid and kind = ${input.kind}`,
      );
      dup = same.find((m) => normalize(m.content) === normalize(content));
    }
    if (dup) {
      await this.db.execute(sql`
        update public.memories set content = ${contentKeys.seal(input.orgId, content)}, embedding = coalesce(${vec}::extensions.vector, embedding),
          importance = greatest(importance, ${input.importance ?? 0.5}), source_run_id = coalesce(${input.sourceRunId ?? null}::uuid, source_run_id),
          updated_at = now()
        where id = ${dup.id}::uuid`);
      return { id: dup.id, created: false };
    }
    const [row] = await this.db.execute<{ id: string }>(sql`
      insert into public.memories (org_id, bot_id, kind, content, embedding, importance, source_run_id)
      values (${input.orgId}::uuid, ${input.botId}::uuid, ${input.kind}, ${contentKeys.seal(input.orgId, content)}, ${vec}::extensions.vector,
              ${input.importance ?? 0.5}, ${input.sourceRunId ?? null}::uuid)
      returning id`);
    if (!row) throw new Error("memory insert returned nothing");
    return { id: row.id, created: true };
  }
}

export const EXTRACTION_SYSTEM = `You extract lasting memories from a conversation between a user and their AI teammate.
Return only JSON: {"memories":[{"kind":"fact"|"preference","about":"person"|"work","content":"...","importance":0.0-1.0}]}.
Keep only durable facts about the user, their work, people and preferences that will matter in future conversations.
"about" is "person" for facts about the user themselves (their job, family, places, tastes, how they like things written) and "work" for facts about projects, clients, tools and tasks.
Never save health, religion, politics, sexuality or money troubles unless the user explicitly asks you to remember it.
Write each memory as one standalone sentence. Skip small talk, one-off requests and anything already obvious. Return {"memories":[]} if nothing qualifies.`;

export const COMPACTION_SYSTEM = `You summarize the earlier conversation between a user and their AI teammate.
Merge the previous summary with the new messages into one concise summary (at most 300 words) that keeps decisions, open tasks, names and facts.`;

export interface ExtractedMemory {
  kind: "fact" | "preference";
  /** About the person (their private profile, D-169) or about the work (the bot's memory). */
  about: "person" | "work";
  content: string;
  importance: number;
}

/** Leniently parses the extraction model's JSON answer. */
export function parseExtraction(text: string): ExtractedMemory[] {
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end <= start) return [];
  try {
    const data = JSON.parse(text.slice(start, end + 1)) as { memories?: unknown };
    if (!Array.isArray(data.memories)) return [];
    return data.memories
      .filter((m): m is Record<string, unknown> => !!m && typeof m === "object")
      .map((m) => ({
        kind: m.kind === "preference" ? ("preference" as const) : ("fact" as const),
        about: m.about === "person" ? ("person" as const) : ("work" as const),
        content: String(m.content ?? "").trim(),
        importance: Math.min(1, Math.max(0, Number(m.importance ?? 0.5) || 0.5)),
      }))
      .filter((m) => m.content.length > 0 && m.content.length <= 1000)
      .slice(0, 10);
  } catch {
    return [];
  }
}

/** Runs the cheap model over the latest exchange and returns candidate memories plus usage. */
export async function extractMemories(
  gateway: ModelGateway,
  model: ResolvedModel,
  transcript: ChatMessage[],
  known: string[],
): Promise<{ memories: ExtractedMemory[]; usage: Usage; model: string }> {
  const text = transcript
    .filter((m) => m.role !== "tool")
    .map((m) => `${m.role.toUpperCase()}: ${m.content}`)
    .join("\n");
  const r = await collect(
    gateway.stream({
      model,
      system: [
        EXTRACTION_SYSTEM,
        known.length
          ? `Already known (do not repeat):\n${known.map((k) => `- ${k}`).join("\n")}`
          : "",
      ].filter(Boolean),
      messages: [{ role: "user", content: text }],
      maxOutputTokens: 600,
    }),
  );
  return { memories: parseExtraction(r.text), usage: r.usage, model: r.model || model.model };
}
