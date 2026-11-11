/**
 * Memory backends (SPEC: Memory backends; D-137). A `MemoryStore` holds a bot's long-term memory.
 * The built-in Postgres store is the default; a workspace can point memory at Honcho or
 * Supermemory with its own key. The run loop, the memory tools, the memory screen, the privacy
 * export and account deletion all go through this interface. Provider request shapes come from
 * their public API docs and are tested against local fakes only.
 */
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import type { Embedder } from "./embeddings.ts";
import { type MemoryKind, type MemoryRow, MemoryService } from "./memory.ts";

export type StoredMemory = MemoryRow & { bot_id: string; created_at: string; updated_at: string };

export interface MemoryWrite {
  orgId: string;
  botId: string;
  kind: MemoryKind;
  content: string;
  importance?: number;
  sourceRunId?: string;
  pinned?: boolean;
}

export interface MemoryStore {
  readonly provider: "postgres" | "honcho" | "supermemory";
  /** The most relevant memories for a query, plus every pinned one. */
  recall(botId: string, query: string, limit?: number): Promise<MemoryRow[]>;
  /** Writes a memory, updating a near-duplicate instead where the backend can tell. */
  write(input: MemoryWrite): Promise<{ id: string; created: boolean }>;
  update(
    botId: string,
    id: string,
    patch: { content?: string; pinned?: boolean },
  ): Promise<StoredMemory | null>;
  delete(botId: string, id: string): Promise<void>;
  list(botId: string, query?: string): Promise<StoredMemory[]>;
  /** Removes every memory of these bots (account and workspace deletion). */
  deleteAll(botIds: string[]): Promise<void>;
}

// ------------------------------------------------------------------ Postgres (built in)
export class PostgresMemoryStore implements MemoryStore {
  readonly provider = "postgres" as const;
  private readonly db: Database;
  private readonly svc: MemoryService;
  constructor(db: Database, embedder: Embedder | null) {
    this.db = db;
    this.svc = new MemoryService(db, embedder);
  }
  recall(botId: string, query: string, limit?: number) {
    return this.svc.recall(botId, query, limit);
  }
  async write(input: MemoryWrite) {
    const r = await this.svc.write(input);
    if (input.pinned)
      await this.db.execute(sql`update public.memories set pinned = true where id = ${r.id}::uuid`);
    return r;
  }
  async update(botId: string, id: string, patch: { content?: string; pinned?: boolean }) {
    const { contentKeys } = await import("@casama/db");
    const [m] = await this.db.execute<{ org_id: string }>(
      sql`select org_id from public.memories where id = ${id}::uuid and bot_id = ${botId}::uuid`,
    );
    if (!m) return null;
    const [row] = await this.db.execute<StoredMemory>(sql`
      update public.memories set content = coalesce(${contentKeys.seal(m.org_id, patch.content ?? null)}, content),
        pinned = coalesce(${patch.pinned ?? null}::boolean, pinned), updated_at = now()
      where id = ${id}::uuid returning id, bot_id, kind, content, pinned, importance, created_at, updated_at`);
    return row ?? null;
  }
  async delete(botId: string, id: string) {
    await this.db.execute(
      sql`delete from public.memories where id = ${id}::uuid and bot_id = ${botId}::uuid`,
    );
  }
  async list(botId: string, query?: string) {
    return this.db.execute<StoredMemory>(sql`
      select id, bot_id, kind, content, pinned, importance, created_at, updated_at from public.memories
      where bot_id = ${botId}::uuid ${query ? sql`and tsv @@ websearch_to_tsquery('simple', ${query})` : sql``}
      order by pinned desc, updated_at desc limit 500`);
  }
  async deleteAll(botIds: string[]) {
    if (botIds.length)
      await this.db.execute(
        sql`delete from public.memories where bot_id = any(array(select jsonb_array_elements_text(${JSON.stringify(botIds)}::jsonb))::uuid[])`,
      );
  }
}

// ------------------------------------------------------------------ shared HTTP
type Fetch = typeof fetch;
async function call<T>(
  f: Fetch,
  url: string,
  key: string,
  method: string,
  body?: unknown,
): Promise<T> {
  const res = await f(url, {
    method,
    headers: { authorization: `Bearer ${key}`, "content-type": "application/json" },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  if (!res.ok)
    throw new Error(
      `${new URL(url).host} answered ${res.status}: ${(await res.text()).slice(0, 200)}`,
    );
  const text = await res.text();
  return (text ? JSON.parse(text) : {}) as T;
}
const now = () => new Date().toISOString();
const normalize = (s: string) =>
  s
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, " ")
    .trim();
const KINDS = new Set(["fact", "episode", "summary", "preference"]);
const kindOf = (k: unknown): MemoryKind =>
  KINDS.has(String(k)) ? (String(k) as MemoryKind) : "fact";

// ------------------------------------------------------------------ Honcho
/**
 * Honcho (honcho.dev, v2 API). Each bot's memory is one session (`casama-<bot>`) in the workspace's
 * Honcho workspace; each memory is a message from the bot's peer, with kind, pinned and importance
 * in its metadata. Search uses Honcho's search with the session as a filter. Honcho keeps messages;
 * deleting one marks it deleted in metadata and hides it, and deleting all memory deletes the sessions.
 */
export class HonchoMemoryStore implements MemoryStore {
  readonly provider = "honcho" as const;
  private readonly o: { key: string; base: string; workspace: string; fetch: Fetch };
  private ready = new Set<string>();
  constructor(o: { key: string; base?: string; workspace: string; fetch?: Fetch }) {
    this.o = {
      key: o.key,
      base: (o.base ?? "https://api.honcho.dev").replace(/\/$/, ""),
      workspace: o.workspace,
      fetch: o.fetch ?? fetch,
    };
  }
  private url(path: string) {
    return `${this.o.base}/v2/workspaces/${encodeURIComponent(this.o.workspace)}${path}`;
  }
  private req<T>(method: string, path: string, body?: unknown) {
    return call<T>(this.o.fetch, this.url(path), this.o.key, method, body);
  }
  private session = (botId: string) => `casama-${botId}`;
  private peer = (botId: string) => `bot-${botId}`;

  private async ensure(botId: string) {
    if (this.ready.has(botId)) return;
    await call(this.o.fetch, `${this.o.base}/v2/workspaces`, this.o.key, "POST", {
      id: this.o.workspace,
    });
    await this.req("POST", "/peers", { id: this.peer(botId) });
    await this.req("POST", "/sessions", {
      id: this.session(botId),
      peers: { [this.peer(botId)]: {} },
    });
    this.ready.add(botId);
  }

  private toRow(
    botId: string,
    m: { id: string; content: string; metadata?: Record<string, unknown>; created_at?: string },
  ): StoredMemory {
    const md = m.metadata ?? {};
    return {
      id: m.id,
      bot_id: botId,
      kind: kindOf(md.kind),
      content: String(md.content ?? m.content),
      pinned: md.pinned === true,
      importance: Number(md.importance ?? 0.5),
      created_at: m.created_at ?? now(),
      updated_at: String(md.updated_at ?? m.created_at ?? now()),
    };
  }

  async list(botId: string, query?: string) {
    await this.ensure(botId);
    const r = await this.req<{
      items?: Array<{
        id: string;
        content: string;
        metadata?: Record<string, unknown>;
        created_at?: string;
      }>;
    }>("POST", `/sessions/${this.session(botId)}/messages/list`, {
      filters: { peer_id: this.peer(botId) },
      size: 500,
    });
    const rows = (r.items ?? [])
      .filter((m) => m.metadata?.deleted !== true)
      .map((m) => this.toRow(botId, m));
    const q = query ? normalize(query) : "";
    return rows
      .filter((m) => !q || normalize(m.content).includes(q))
      .sort(
        (a, b) => Number(b.pinned) - Number(a.pinned) || b.updated_at.localeCompare(a.updated_at),
      );
  }

  async recall(botId: string, query: string, limit = 8) {
    await this.ensure(botId);
    const found = await this.req<
      | Array<{
          id: string;
          content: string;
          metadata?: Record<string, unknown>;
          created_at?: string;
        }>
      | { items?: unknown[] }
    >("POST", "/search", { query, filters: { session_id: this.session(botId) }, limit });
    const hits = (Array.isArray(found) ? found : ((found.items ?? []) as never[])) as Array<{
      id: string;
      content: string;
      metadata?: Record<string, unknown>;
    }>;
    const pinned = (await this.list(botId)).filter((m) => m.pinned);
    const seen = new Set<string>();
    return [
      ...pinned,
      ...hits.filter((m) => m.metadata?.deleted !== true).map((m) => this.toRow(botId, m)),
    ].filter((m) => !seen.has(m.id) && seen.add(m.id));
  }

  async write(input: MemoryWrite) {
    const content = input.content.trim().slice(0, 8000);
    const dup = (await this.list(input.botId)).find(
      (m) => m.kind === input.kind && normalize(m.content) === normalize(content),
    );
    if (dup) return { id: dup.id, created: false };
    const r = await this.req<Array<{ id: string }> | { id: string }>(
      "POST",
      `/sessions/${this.session(input.botId)}/messages`,
      {
        messages: [
          {
            peer_id: this.peer(input.botId),
            content,
            metadata: {
              kind: input.kind,
              importance: input.importance ?? 0.5,
              pinned: input.pinned ?? false,
              source_run_id: input.sourceRunId ?? null,
              updated_at: now(),
            },
          },
        ],
      },
    );
    const id = Array.isArray(r) ? r[0]?.id : r.id;
    if (!id) throw new Error("Honcho returned no message id");
    return { id, created: true };
  }

  async update(botId: string, id: string, patch: { content?: string; pinned?: boolean }) {
    const cur = (await this.list(botId)).find((m) => m.id === id);
    if (!cur) return null;
    // Honcho messages are immutable apart from metadata, so edited text lives in metadata.
    const metadata = {
      kind: cur.kind,
      importance: cur.importance,
      pinned: patch.pinned ?? cur.pinned,
      content: patch.content ?? cur.content,
      updated_at: now(),
    };
    await this.req("PUT", `/sessions/${this.session(botId)}/messages/${encodeURIComponent(id)}`, {
      metadata,
    });
    return {
      ...cur,
      content: metadata.content,
      pinned: metadata.pinned,
      updated_at: metadata.updated_at,
    };
  }

  async delete(botId: string, id: string) {
    await this.req("PUT", `/sessions/${this.session(botId)}/messages/${encodeURIComponent(id)}`, {
      metadata: { deleted: true, updated_at: now() },
    });
  }

  async deleteAll(botIds: string[]) {
    for (const b of botIds)
      await this.req("DELETE", `/sessions/${this.session(b)}`).catch(() => {});
  }
}

// ------------------------------------------------------------------ Supermemory
/**
 * Supermemory (supermemory.ai, v3 API). Each memory is a document tagged with the bot's container
 * tag (`casama_bot_<bot>`), with kind, pinned and importance in its metadata.
 */
export class SupermemoryStore implements MemoryStore {
  readonly provider = "supermemory" as const;
  private readonly o: { key: string; base: string; fetch: Fetch };
  constructor(o: { key: string; base?: string; fetch?: Fetch }) {
    this.o = {
      key: o.key,
      base: (o.base ?? "https://api.supermemory.ai").replace(/\/$/, ""),
      fetch: o.fetch ?? fetch,
    };
  }
  private req<T>(method: string, path: string, body?: unknown) {
    return call<T>(this.o.fetch, `${this.o.base}${path}`, this.o.key, method, body);
  }
  private tag = (botId: string) => `casama_bot_${botId}`;
  private toRow(
    botId: string,
    d: {
      id: string;
      content?: string;
      summary?: string;
      metadata?: Record<string, unknown>;
      createdAt?: string;
      updatedAt?: string;
    },
  ): StoredMemory {
    const md = d.metadata ?? {};
    return {
      id: d.id,
      bot_id: botId,
      kind: kindOf(md.kind),
      content: String(d.content ?? d.summary ?? ""),
      pinned: md.pinned === true || md.pinned === "true",
      importance: Number(md.importance ?? 0.5),
      created_at: d.createdAt ?? now(),
      updated_at: d.updatedAt ?? d.createdAt ?? now(),
    };
  }

  async list(botId: string, query?: string) {
    const r = await this.req<{
      memories?: Array<{
        id: string;
        content?: string;
        summary?: string;
        metadata?: Record<string, unknown>;
        createdAt?: string;
        updatedAt?: string;
      }>;
    }>("POST", "/v3/documents/list", {
      containerTags: [this.tag(botId)],
      limit: 500,
      includeContent: true,
    });
    const q = query ? normalize(query) : "";
    return (r.memories ?? [])
      .map((d) => this.toRow(botId, d))
      .filter((m) => !q || normalize(m.content).includes(q))
      .sort(
        (a, b) => Number(b.pinned) - Number(a.pinned) || b.updated_at.localeCompare(a.updated_at),
      );
  }

  async recall(botId: string, query: string, limit = 8) {
    const r = await this.req<{
      results?: Array<{
        documentId: string;
        chunks?: Array<{ content: string }>;
        content?: string;
        metadata?: Record<string, unknown>;
      }>;
    }>("POST", "/v3/search", { q: query, containerTags: [this.tag(botId)], limit });
    const hits = (r.results ?? []).map((x) =>
      this.toRow(botId, {
        id: x.documentId,
        content: x.content ?? x.chunks?.map((c) => c.content).join(" "),
        metadata: x.metadata,
      }),
    );
    const pinned = (await this.list(botId)).filter((m) => m.pinned);
    const seen = new Set<string>();
    return [...pinned, ...hits].filter((m) => !seen.has(m.id) && seen.add(m.id));
  }

  async write(input: MemoryWrite) {
    const content = input.content.trim().slice(0, 8000);
    const dup = (await this.list(input.botId)).find(
      (m) => m.kind === input.kind && normalize(m.content) === normalize(content),
    );
    if (dup) return { id: dup.id, created: false };
    const r = await this.req<{ id: string }>("POST", "/v3/documents", {
      content,
      containerTags: [this.tag(input.botId)],
      metadata: {
        kind: input.kind,
        importance: input.importance ?? 0.5,
        pinned: input.pinned ?? false,
        ...(input.sourceRunId ? { source_run_id: input.sourceRunId } : {}),
      },
    });
    return { id: r.id, created: true };
  }

  async update(botId: string, id: string, patch: { content?: string; pinned?: boolean }) {
    const cur = (await this.list(botId)).find((m) => m.id === id);
    if (!cur) return null;
    await this.req("PATCH", `/v3/documents/${encodeURIComponent(id)}`, {
      ...(patch.content !== undefined ? { content: patch.content } : {}),
      metadata: { kind: cur.kind, importance: cur.importance, pinned: patch.pinned ?? cur.pinned },
    });
    return {
      ...cur,
      content: patch.content ?? cur.content,
      pinned: patch.pinned ?? cur.pinned,
      updated_at: now(),
    };
  }

  async delete(_botId: string, id: string) {
    await this.req("DELETE", `/v3/documents/${encodeURIComponent(id)}`);
  }

  async deleteAll(botIds: string[]) {
    if (botIds.length)
      await this.req("DELETE", "/v3/documents/bulk", {
        containerTags: botIds.map((b) => this.tag(b)),
      });
  }
}

// ------------------------------------------------------------------ choosing a store
export interface MemoryBackendConfig {
  provider: "honcho" | "supermemory";
  key: string;
  base_url?: string | null;
  workspace?: string | null;
}

export function storeFromConfig(c: MemoryBackendConfig, orgId: string, f?: Fetch): MemoryStore {
  if (c.provider === "honcho")
    return new HonchoMemoryStore({
      key: c.key,
      base: c.base_url ?? undefined,
      workspace: c.workspace || `casama-${orgId}`,
      fetch: f,
    });
  return new SupermemoryStore({ key: c.key, base: c.base_url ?? undefined, fetch: f });
}

/** The workspace's memory backend (with its key from Vault), or null for the built-in store. */
export async function memoryBackendConfig(
  db: Database,
  orgId: string,
): Promise<MemoryBackendConfig | null> {
  const [r] = await db.execute<{
    provider: "honcho";
    key: string | null;
    base_url: string | null;
    workspace: string | null;
  }>(sql`
    select b.provider, v.decrypted_secret as key, b.base_url, b.workspace from public.org_memory_backends b
    left join vault.decrypted_secrets v on v.id = b.vault_secret_id where b.org_id = ${orgId}::uuid`);
  return r?.key
    ? { provider: r.provider, key: r.key, base_url: r.base_url, workspace: r.workspace }
    : null;
}

export async function memoryStoreFor(
  db: Database,
  orgId: string,
  embedder: Embedder | null,
  f?: Fetch,
): Promise<MemoryStore> {
  const c = await memoryBackendConfig(db, orgId);
  return c ? storeFromConfig(c, orgId, f) : new PostgresMemoryStore(db, embedder);
}
