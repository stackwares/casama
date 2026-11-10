/**
 * Knowledge sources (SPEC: Post-v1 roadmap → Knowledge sources; D-125). The worker parses uploads,
 * crawls websites within one domain (respecting robots.txt), reads GitHub repositories, and pulls
 * documents through app connections, then stores chunks with embeddings. knowledge.search uses
 * the same hybrid search as memory and returns snippets with citations. Without an embedding key,
 * search is full-text only (D-017).
 */
import type { Database } from "@kasama/db";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { type Embedder, toPgVector } from "./embeddings.ts";
import { createAdapter, loadIntegration } from "./integrations.ts";
import { chunkSections, type ParsedDoc, parseDocument, parseHtml } from "./knowledge-parse.ts";
import type { ToolRegistry } from "./tools/registry.ts";
import { contentKeys } from "@kasama/db";

export const KNOWLEDGE_SYNC_HOURS = 24;
const MAX_PAGES = 50;
const MAX_CHUNKS = 5000;

export interface KnowledgeDeps {
  db: Database;
  fetch: typeof fetch;
  embedderFor: (orgId: string) => Promise<Embedder | null>;
  githubApiUrl?: string;
}

interface Doc extends ParsedDoc {
  ref: string;
  url: string | null;
}

// ---------------------------------------------------------------------------
// Websites
// ---------------------------------------------------------------------------

/** robots.txt rules for us: the group for "kasama" if any, else "*". */
export function robotsRules(txt: string) {
  const groups: Array<{ agents: string[]; rules: Array<{ allow: boolean; path: string }> }> = [];
  let cur: (typeof groups)[number] | null = null;
  let lastWasAgent = false;
  for (const raw of txt.split(/\r?\n/)) {
    const line = raw.replace(/#.*/, "").trim();
    const m = /^([A-Za-z-]+)\s*:\s*(.*)$/.exec(line);
    if (!m) continue;
    const key = (m[1] as string).toLowerCase();
    const val = (m[2] as string).trim();
    if (key === "user-agent") {
      if (!cur || !lastWasAgent) {
        cur = { agents: [], rules: [] };
        groups.push(cur);
      }
      cur.agents.push(val.toLowerCase());
      lastWasAgent = true;
    } else {
      lastWasAgent = false;
      if (cur && (key === "allow" || key === "disallow") && val) cur.rules.push({ allow: key === "allow", path: val });
    }
  }
  const group = groups.find((g) => g.agents.some((a) => a.includes("kasama"))) ?? groups.find((g) => g.agents.includes("*"));
  const rules = group?.rules ?? [];
  return (path: string) => {
    // The longest matching rule wins; Allow wins a tie.
    let best: { allow: boolean; len: number } | null = null;
    for (const r of rules) {
      const pattern = new RegExp(`^${r.path.replace(/[.+?^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*").replace(/\\\$$/, "$")}`);
      if (pattern.test(path) && (!best || r.path.length > best.len || (r.path.length === best.len && r.allow)))
        best = { allow: r.allow, len: r.path.length };
    }
    return best ? best.allow : true;
  };
}

async function crawlWebsite(d: KnowledgeDeps, start: string, maxPages: number): Promise<Doc[]> {
  const origin = new URL(start).origin;
  const robots = await d
    .fetch(`${origin}/robots.txt`, { headers: { "user-agent": "KasamaBot (knowledge sources)" } })
    .then(async (r) => (r.ok ? robotsRules(await r.text()) : () => true))
    .catch(() => () => true);
  const queue = [new URL(start).href.replace(/#.*$/, "")];
  const seen = new Set(queue);
  const docs: Doc[] = [];
  while (queue.length && docs.length < maxPages) {
    const url = queue.shift() as string;
    const u = new URL(url);
    if (!robots(u.pathname + u.search)) continue;
    const res = await d.fetch(url, { headers: { "user-agent": "KasamaBot (knowledge sources)", accept: "text/html,text/plain,text/markdown" } }).catch(() => null);
    if (!res?.ok) continue;
    const type = res.headers.get("content-type") ?? "";
    if (!/text\/(html|plain|markdown)/.test(type)) continue;
    const body = await res.text();
    const parsed = type.includes("html") ? parseHtml(body, u.pathname) : parseDocument(`${u.pathname || "page"}.md`, new TextEncoder().encode(body));
    docs.push({ ...parsed, ref: url, url });
    if (!type.includes("html")) continue;
    for (const m of body.matchAll(/<a\s[^>]*href=["']([^"'#]+)["']/gi)) {
      try {
        const next = new URL(m[1] as string, url);
        next.hash = "";
        if (next.origin !== origin || seen.has(next.href) || !/^https?:$/.test(next.protocol)) continue;
        if (/\.(png|jpe?g|gif|svg|pdf|zip|css|js|ico|mp4|webp)$/i.test(next.pathname)) continue;
        seen.add(next.href);
        queue.push(next.href);
      } catch {}
    }
  }
  return docs;
}

// ---------------------------------------------------------------------------
// GitHub (Markdown and text files of a repository)
// ---------------------------------------------------------------------------

async function readGitHub(d: KnowledgeDeps, orgId: string, c: { owner: string; repo: string; path?: string; ref?: string }): Promise<Doc[]> {
  const api = d.githubApiUrl ?? "https://api.github.com";
  const [tok] = await d.db.execute<{ token: string | null }>(sql`
    select v.decrypted_secret as token from public.secrets s join vault.decrypted_secrets v on v.id = s.vault_secret_id
    where s.org_id = ${orgId}::uuid and s.name = 'GITHUB_TOKEN' and 'api.github.com' = any(s.allowed_hosts)`);
  const get = async <T>(p: string) => {
    const r = await d.fetch(`${api}/repos/${c.owner}/${c.repo}${p}`, {
      headers: { accept: "application/vnd.github+json", "user-agent": "kasama-knowledge", ...(tok?.token ? { authorization: `Bearer ${tok.token}` } : {}) },
    });
    if (!r.ok) throw new Error(`GitHub answered ${r.status}`);
    return (await r.json()) as T;
  };
  const ref = c.ref ?? (await get<{ default_branch: string }>("")).default_branch;
  const tree = await get<{ tree: Array<{ path: string; type: string; sha: string; size?: number }> }>(`/git/trees/${encodeURIComponent(ref)}?recursive=1`);
  const prefix = c.path ? `${c.path.replace(/^\/|\/$/g, "")}/` : "";
  const files = tree.tree
    .filter((e) => e.type === "blob" && e.path.startsWith(prefix) && /\.(md|mdx|markdown|txt|rst|html?|csv)$/i.test(e.path) && (e.size ?? 0) < 2_000_000)
    .slice(0, 300);
  const docs: Doc[] = [];
  for (const f of files) {
    const b = await get<{ content: string; encoding: string }>(`/git/blobs/${f.sha}`);
    const bytes = new Uint8Array(Buffer.from(b.content, b.encoding === "base64" ? "base64" : "utf8"));
    const parsed = parseDocument(f.path.split("/").pop() as string, bytes);
    docs.push({ ...parsed, ref: f.path, url: `https://github.com/${c.owner}/${c.repo}/blob/${ref}/${f.path}` });
  }
  return docs;
}

// ---------------------------------------------------------------------------
// App connections: documents a connection's tools return (for example a Notion or Drive fetch)
// ---------------------------------------------------------------------------

async function readConnection(
  d: KnowledgeDeps,
  c: { integration_id: string; documents: Array<{ tool: string; args?: Record<string, unknown>; title: string; url?: string }> },
): Promise<Doc[]> {
  const rec = await loadIntegration(d.db, c.integration_id, d.fetch);
  if (!rec) throw new Error("The connection was removed");
  const adapter = createAdapter(rec, { fetch: d.fetch, secrets: [] });
  const docs: Doc[] = [];
  try {
    for (const doc of c.documents.slice(0, 100)) {
      const text = await adapter.callTool(doc.tool, doc.args ?? {});
      const parsed = /<html|<body|<h[1-6]/i.test(text) ? parseHtml(text, doc.title) : parseDocument("doc.md", new TextEncoder().encode(text));
      docs.push({ title: doc.title, sections: parsed.sections, ref: `${doc.tool}:${JSON.stringify(doc.args ?? {})}`, url: doc.url ?? null });
    }
  } finally {
    await adapter.close?.();
  }
  return docs;
}

// ---------------------------------------------------------------------------
// Syncing
// ---------------------------------------------------------------------------

/** Re-reads one source and replaces its chunks. */
export async function syncKnowledgeSource(d: KnowledgeDeps, sourceId: string) {
  const { db } = d;
  const [s] = await db.execute<{ id: string; org_id: string; kind: string; config: Record<string, unknown> }>(sql`
    update public.knowledge_sources set status = 'syncing', error = null where id = ${sourceId}::uuid returning id, org_id, kind, config`);
  if (!s) throw new Error("Knowledge source not found");
  try {
    let docs: Doc[] = [];
    const errors: string[] = [];
    if (s.kind === "upload") {
      const files = await db.execute<{ name: string; content: Buffer }>(sql`select name, content from public.knowledge_uploads where source_id = ${s.id}::uuid order by created_at`);
      for (const f of files) {
        try {
          docs.push({ ...parseDocument(f.name, new Uint8Array(f.content)), ref: f.name, url: null });
        } catch (err) {
          errors.push(`${f.name}: ${(err as Error).message}`);
        }
      }
    } else if (s.kind === "website") {
      docs = await crawlWebsite(d, String(s.config.url), Math.min(Number(s.config.max_pages ?? MAX_PAGES) || MAX_PAGES, 200));
      if (!docs.length) throw new Error("No pages could be read (check the address, and that robots.txt allows it)");
    } else if (s.kind === "github") {
      docs = await readGitHub(d, s.org_id, s.config as never);
    } else {
      docs = await readConnection(d, s.config as never);
    }
    const embedder = await d.embedderFor(s.org_id);
    const rows: Array<{ doc: Doc; location: string | null; text: string; position: number }> = [];
    for (const doc of docs) for (const c of chunkSections(doc.sections)) rows.push({ doc, location: c.location, text: c.text, position: c.position });
    if (rows.length > MAX_CHUNKS) errors.push(`Kept the first ${MAX_CHUNKS} of ${rows.length} chunks`);
    const kept = rows.slice(0, MAX_CHUNKS);
    const vectors: Array<string | null> = [];
    for (const r of kept) vectors.push(embedder ? toPgVector(await embedder.embed(`${r.doc.title}\n${r.location ?? ""}\n${r.text}`)) : null);
    await db.transaction(async (tx) => {
      await tx.execute(sql`delete from public.knowledge_chunks where source_id = ${s.id}::uuid`);
      for (const [i, r] of kept.entries())
        await tx.execute(sql`
          insert into public.knowledge_chunks (org_id, source_id, doc_ref, doc_title, location, url, position, text, embedding)
          values (${s.org_id}::uuid, ${s.id}::uuid, ${r.doc.ref.slice(0, 2000)}, ${r.doc.title.slice(0, 300)}, ${r.location?.slice(0, 300) ?? null},
                  ${r.doc.url}, ${r.position}, ${contentKeys.seal(s.org_id, r.text)}, ${vectors[i] ?? null}::extensions.vector)`);
      await tx.execute(sql`
        update public.knowledge_sources set status = ${docs.length ? "ready" : "error"}, documents = ${docs.length}, chunks = ${kept.length},
          error = ${errors.length ? errors.join("\n").slice(0, 2000) : docs.length ? null : "Nothing could be read"},
          last_synced_at = now(), next_sync_at = now() + make_interval(hours => ${s.kind === "upload" ? 24 * 365 : KNOWLEDGE_SYNC_HOURS})
        where id = ${s.id}::uuid`);
    });
    return { documents: docs.length, chunks: kept.length, errors };
  } catch (err) {
    await db.execute(sql`
      update public.knowledge_sources set status = 'error', error = ${(err as Error).message.slice(0, 2000)},
        next_sync_at = now() + interval '6 hours' where id = ${s.id}::uuid`);
    throw err;
  }
}

/** The worker's minute tick: sources that are new, asked to resync, or due for their daily sync. */
export async function knowledgeTick(d: KnowledgeDeps) {
  const due = await d.db.execute<{ id: string }>(sql`
    select id from public.knowledge_sources where status <> 'syncing' and next_sync_at <= now() order by next_sync_at limit 5`);
  const done: string[] = [];
  for (const r of due) {
    await syncKnowledgeSource(d, r.id).then(() => done.push(r.id)).catch(() => {});
  }
  return done;
}

// ---------------------------------------------------------------------------
// The tool
// ---------------------------------------------------------------------------

export function registerKnowledgeTools(registry: ToolRegistry, deps: { db: Database; embedderFor: (orgId: string) => Promise<Embedder | null> }) {
  registry.register({
    name: "knowledge.search",
    readOnly: true,
    description:
      "Search the documents you and your workspace were given (uploaded files, websites, repositories, connected apps). Returns snippets with their source; cite them as [n] with the document and link when you use them.",
    risk: "low",
    schema: z.object({ query: z.string().min(1).max(500), limit: z.number().int().min(1).max(12).optional() }),
    async execute(args, ctx) {
      const embedder = await deps.embedderFor(ctx.orgId);
      const vec = embedder ? toPgVector(await embedder.embed(args.query)) : null;
      const rows = await deps.db.execute<{ doc_title: string; location: string | null; url: string | null; text: string; doc_ref: string }>(sql`
        select doc_title, location, url, text, doc_ref from public.search_knowledge(${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${args.query}, ${vec}::extensions.vector, ${args.limit ?? 6})`);
      if (!rows.length) return { content: "Nothing in your knowledge sources matches that.", preview: "0 sources" };
      const titles = [...new Set(rows.map((r) => r.doc_title))];
      return {
        content: rows
          .map((r, i) => `[${i + 1}] ${r.doc_title}${r.location ? ` (${r.location})` : ""}${r.url ? ` ${r.url}` : ""}\n${r.text.slice(0, 1200)}`)
          .join("\n\n"),
        preview: `Sources: ${titles.slice(0, 4).join(", ")}${titles.length > 4 ? ` +${titles.length - 4}` : ""}`,
      };
    },
  });
}
