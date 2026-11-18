/**
 * Casama's docs and API reference as MCP tools, for people (and their coding agents) building on
 * Casama: search the docs, read a page, list pages, look up an API operation, and (over stdio)
 * check a plugin folder. No sign-in needed. The hosted server serves these at /mcp/docs.
 *
 * The keyword index (BM25 over ## sections) is shared with the API's support assistant (D-298),
 * which imports it from here.
 */
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

export interface DocPage {
  url: string;
  title: string;
  body: string;
}

export interface DocSection {
  url: string;
  /** "Page › Heading". */
  title: string;
  text: string;
}

/** Separates pages in llms-full.txt; the docs build writes it (docs-site/scripts/sync.ts). */
export const PAGE_MARK = /^<!-- page: (\S+) -->$/m;

const STOP = new Set(
  "a an and are as at be but by can do does for from has have how i if in into is it its me my no not of on or our so that the their them then there these this to was we what when where which who why will with you your".split(
    " ",
  ),
);

export function tokens(text: string): string[] {
  return (text.toLowerCase().match(/[a-z0-9][a-z0-9'-]*/g) ?? [])
    .map((t) =>
      t
        .replace(/'s$/, "")
        .replace(/(ing|ed|es|s)$/, (m, _g, _i, w) => (w.length - m.length >= 4 ? "" : m)),
    )
    .filter((t) => t.length > 1 && !STOP.has(t));
}

const slug = (h: string) =>
  h
    .toLowerCase()
    .replace(/[^\w\s-]/g, "")
    .trim()
    .replace(/\s+/g, "-");

/** Drops front matter, VitePress containers' markers and HTML so the text reads plainly. */
function clean(md: string): string {
  return md
    .replace(/^---\n[\s\S]*?\n---\n/, "")
    .replace(/^:::\s*\w*.*$/gm, "")
    .replace(/<[^>]+>/g, "")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

export function pageTitle(md: string, fallback: string): string {
  const fm = /^---\n[\s\S]*?^title:\s*["']?(.+?)["']?\s*$/m.exec(md);
  if (fm?.[1] && md.startsWith("---")) return fm[1];
  return /^#\s+(.+)$/m.exec(md)?.[1]?.trim() ?? fallback;
}

/** Pages split at their ## headings, each section carrying its page's title and an anchor. */
export function sectionsOf(pages: DocPage[]): DocSection[] {
  const out: DocSection[] = [];
  for (const p of pages) {
    const parts = clean(p.body).split(/^(?=##\s)/m);
    for (const part of parts) {
      const heading = /^##\s+(.+)$/m.exec(part)?.[1]?.trim();
      const text = part.replace(/^#{1,2}\s+.+$/gm, "").trim();
      if (text.length < 40) continue;
      out.push({
        url: heading ? `${p.url}#${slug(heading)}` : p.url,
        title: heading ? `${p.title} › ${heading}` : p.title,
        text,
      });
    }
  }
  return out;
}

/** BM25 over sections; titles count twice. */
export class DocIndex {
  readonly sections: DocSection[];
  readonly pages: DocPage[];
  private readonly tf: Map<string, number>[];
  private readonly df = new Map<string, number>();
  private readonly lens: number[];
  private readonly avg: number;

  constructor(pages: DocPage[]) {
    this.pages = pages;
    this.sections = sectionsOf(pages);
    this.tf = this.sections.map((s) => {
      const m = new Map<string, number>();
      for (const t of [...tokens(s.title), ...tokens(s.title), ...tokens(s.text)])
        m.set(t, (m.get(t) ?? 0) + 1);
      for (const t of m.keys()) this.df.set(t, (this.df.get(t) ?? 0) + 1);
      return m;
    });
    this.lens = this.tf.map((m) => [...m.values()].reduce((a, b) => a + b, 0));
    this.avg = this.lens.reduce((a, b) => a + b, 0) / Math.max(1, this.lens.length);
  }

  search(query: string, limit = 5): DocSection[] {
    const q = [...new Set(tokens(query))];
    if (!q.length) return [];
    const n = this.sections.length;
    const scored = this.tf.map((m, i) => {
      let score = 0;
      for (const t of q) {
        const f = m.get(t);
        if (!f) continue;
        const df = this.df.get(t) ?? 0;
        const idf = Math.log(1 + (n - df + 0.5) / (df + 0.5));
        score += (idf * f * 2.2) / (f + 1.2 * (0.25 + (0.75 * (this.lens[i] ?? 0)) / this.avg));
      }
      return { i, score };
    });
    return scored
      .filter((s) => s.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, limit)
      .map((s) => this.sections[s.i] as DocSection);
  }

  /** One line per page, for the assistant's map of what the docs cover. */
  outline(): string {
    return this.pages.map((p) => `- ${p.title}: ${p.url}`).join("\n");
  }

  /** A page by its path or address: "/develop/plugins", "develop/plugins.md", a full URL. */
  page(ref: string): DocPage | undefined {
    const want = pathOf(ref);
    return this.pages.find((p) => pathOf(p.url) === want);
  }
}

/** "/develop/plugins" from any way of writing a page's address. */
function pathOf(ref: string): string {
  let p = ref.trim();
  try {
    p = new URL(p).pathname;
  } catch {
    // already a path
  }
  p = p
    .split("#")[0]
    ?.replace(/\.(md|html)$/, "")
    .replace(/\/index$/, "/")
    .replace(/\/+$/, "") as string;
  return p.startsWith("/") ? p || "/" : `/${p}`;
}

/** Pages from llms-full.txt: each starts with `<!-- page: URL -->` and its markdown follows. */
export function parseLlmsFull(text: string): DocPage[] {
  const parts = text.split(new RegExp(PAGE_MARK.source, "m"));
  const pages: DocPage[] = [];
  for (let i = 1; i + 1 < parts.length; i += 2) {
    const url = (parts[i] ?? "").trim();
    const body = (parts[i + 1] ?? "").trim();
    if (url && body) pages.push({ url, title: pageTitle(body, url), body });
  }
  return pages;
}

// --- where the docs come from ------------------------------------------------------

type OpenApiDoc = {
  paths?: Record<string, Record<string, unknown>>;
  components?: { schemas?: Record<string, unknown> };
};

/** What the docs tools read. The hosted server passes its own; stdio fetches docs.casama.ai. */
export interface DocsSource {
  docs(): Promise<DocIndex>;
  openapi(): Promise<OpenApiDoc>;
}

/** The published docs and OpenAPI document, fetched on first use and again after an hour. */
export class RemoteDocs implements DocsSource {
  private cache = new Map<string, { at: number; value: Promise<unknown> }>();
  private readonly opts: {
    docsUrl?: string;
    fetch?: typeof fetch;
    refreshMs?: number;
    now?: () => number;
  };

  constructor(opts: RemoteDocs["opts"] = {}) {
    this.opts = opts;
  }

  private get base() {
    return (this.opts.docsUrl ?? "https://docs.casama.ai").replace(/\/$/, "");
  }

  private cached<T>(key: string, load: () => Promise<T>): Promise<T> {
    const now = (this.opts.now ?? Date.now)();
    const hit = this.cache.get(key);
    if (hit && now - hit.at < (this.opts.refreshMs ?? 3_600_000)) return hit.value as Promise<T>;
    const value = load().catch((e) => {
      // A failed fetch isn't cached: keep the last good copy, else retry next time.
      if (hit) {
        this.cache.set(key, hit);
        return hit.value as Promise<T>;
      }
      this.cache.delete(key);
      throw e;
    });
    this.cache.set(key, { at: now, value });
    return value;
  }

  private async get(path: string) {
    const r = await (this.opts.fetch ?? fetch)(`${this.base}${path}`, {
      signal: AbortSignal.timeout(15_000),
    });
    if (!r.ok) throw new Error(`Couldn't load ${this.base}${path} (HTTP ${r.status})`);
    return r;
  }

  docs() {
    return this.cached("docs", async () => {
      const pages = parseLlmsFull(await (await this.get("/llms-full.txt")).text());
      if (!pages.length) throw new Error(`No pages in ${this.base}/llms-full.txt`);
      return new DocIndex(pages);
    });
  }

  openapi() {
    return this.cached(
      "openapi",
      async () => (await (await this.get("/api/openapi.json")).json()) as OpenApiDoc,
    );
  }
}

// --- OpenAPI lookup ----------------------------------------------------------------

const METHODS = ["get", "post", "put", "patch", "delete"] as const;

type Operation = {
  method: string;
  path: string;
  id: string;
  op: {
    operationId?: string;
    summary?: string;
    description?: string;
    tags?: string[];
    parameters?: unknown[];
    requestBody?: unknown;
    responses?: Record<string, unknown>;
    security?: unknown[];
  };
};

export function operationsOf(doc: OpenApiDoc): Operation[] {
  const out: Operation[] = [];
  for (const [path, item] of Object.entries(doc.paths ?? {}))
    for (const method of METHODS) {
      const op = item[method] as Operation["op"] | undefined;
      if (op) out.push({ method, path, id: op.operationId ?? `${method} ${path}`, op });
    }
  return out;
}

/** Whether a concrete path (/v1/bots/123) fits a template (/v1/bots/{id}). */
const fits = (template: string, path: string) =>
  new RegExp(
    `^${template.replace(/[.*+?^$()|[\]\\]/g, "\\$&").replace(/\{[^}]+\}/g, "[^/]+")}$`,
  ).test(path);

const words = (s: string) =>
  tokens(s.replace(/([a-z])([A-Z])/g, "$1 $2").replace(/[{}/_.-]+/g, " "));

/** Operations matching an operationId, "METHOD /path", a bare path, or keywords. */
export function findOperations(doc: OpenApiDoc, query: string, limit = 3): Operation[] {
  const ops = operationsOf(doc);
  const q = query.trim();
  const byId = ops.filter((o) => o.id.toLowerCase() === q.toLowerCase());
  if (byId.length) return byId;
  const m = q.match(/^(get|post|put|patch|delete)?\s*(\/\S*)$/i);
  if (m) {
    const path = (m[2] as string).split("?")[0] as string;
    const hits = ops.filter(
      (o) => (!m[1] || o.method === m[1].toLowerCase()) && (o.path === path || fits(o.path, path)),
    );
    if (hits.length) return hits;
  }
  const want = new Set(words(q));
  if (!want.size) return [];
  return ops
    .map((o) => {
      const strong = new Set([
        ...words(o.id),
        ...words(o.path),
        ...(o.op.tags ?? []).flatMap(words),
      ]);
      const weak = new Set(words(`${o.op.summary ?? ""} ${o.op.description ?? ""}`));
      let score = 0;
      for (const w of want) score += strong.has(w) ? 3 : weak.has(w) ? 1 : 0;
      return { o, score };
    })
    .filter((s) => s.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map((s) => s.o);
}

type Schema = Record<string, unknown>;

/** A JSON schema as a compact TypeScript-like type, following $refs a few levels deep. */
export function typeOf(doc: OpenApiDoc, s: unknown, depth = 3, indent = ""): string {
  if (!s || typeof s !== "object") return "unknown";
  const schema = s as Schema;
  if (typeof schema.$ref === "string") {
    const name = schema.$ref.split("/").at(-1) as string;
    const target = doc.components?.schemas?.[name];
    return depth > 0 && target ? typeOf(doc, target, depth - 1, indent) : name;
  }
  const union = (schema.anyOf ?? schema.oneOf) as unknown[] | undefined;
  if (union) return union.map((u) => typeOf(doc, u, depth, indent)).join(" | ");
  if (schema.allOf)
    return (schema.allOf as unknown[]).map((u) => typeOf(doc, u, depth, indent)).join(" & ");
  if (schema.const !== undefined) return JSON.stringify(schema.const);
  if (schema.enum) return (schema.enum as unknown[]).map((v) => JSON.stringify(v)).join(" | ");
  const types = Array.isArray(schema.type) ? (schema.type as string[]) : [schema.type as string];
  const nullable = types.includes("null") || schema.nullable === true;
  const t = types.find((x) => x && x !== "null");
  let out: string;
  if (t === "array") out = `Array<${typeOf(doc, schema.items, depth, indent)}>`;
  else if (t === "object" || schema.properties) {
    const props = Object.entries((schema.properties ?? {}) as Record<string, Schema>);
    const required = new Set((schema.required ?? []) as string[]);
    if (!props.length) {
      const extra = schema.additionalProperties;
      out =
        extra && typeof extra === "object"
          ? `Record<string, ${typeOf(doc, extra, depth, indent)}>`
          : "object";
    } else if (depth < 0) out = "object";
    else {
      const inner = `${indent}  `;
      const lines = props.map(([k, v]) => {
        const note = [
          typeof v.description === "string" ? v.description.replace(/\s+/g, " ").slice(0, 120) : "",
          typeof v.format === "string" ? v.format : "",
          v.maxLength !== undefined ? `max ${v.maxLength} chars` : "",
          v.default !== undefined ? `default ${JSON.stringify(v.default)}` : "",
        ]
          .filter(Boolean)
          .join("; ");
        return `${inner}${k}${required.has(k) ? "" : "?"}: ${typeOf(doc, v, depth - 1, inner)};${note ? ` // ${note}` : ""}`;
      });
      out = `{\n${lines.join("\n")}\n${indent}}`;
    }
  } else out = t === "integer" ? "number" : (t ?? "unknown");
  return nullable ? `${out} | null` : out;
}

const deref = (doc: OpenApiDoc, v: unknown): Schema => {
  const s = (v ?? {}) as Schema;
  if (typeof s.$ref !== "string") return s;
  const [, , kind, name] = s.$ref.split("/");
  return ((doc.components as Record<string, Record<string, unknown>> | undefined)?.[
    kind as string
  ]?.[name as string] ?? {}) as Schema;
};

/** One operation as readable text: what it does, its parameters, body and responses. */
export function describeOperation(doc: OpenApiDoc, o: Operation): string {
  const lines = [`## ${o.method.toUpperCase()} ${o.path}`, `operationId: ${o.id}`];
  if (o.op.tags?.length) lines.push(`tags: ${o.op.tags.join(", ")}`);
  if (o.op.summary) lines.push("", o.op.summary);
  if (o.op.description && o.op.description !== o.op.summary) lines.push("", o.op.description);
  if (o.op.security && !o.op.security.length) lines.push("", "Auth: none (signed-out route).");
  const params = (o.op.parameters ?? []).map((p) => deref(doc, p));
  if (params.length) {
    lines.push("", "Parameters:");
    for (const p of params)
      lines.push(
        `- ${p.name} (${p.in}${p.required ? ", required" : ""}): ${typeOf(doc, p.schema, 1)}${
          typeof p.description === "string" ? ` — ${p.description}` : ""
        }`,
      );
  }
  const body = deref(doc, o.op.requestBody);
  const content = body.content as Record<string, { schema?: unknown }> | undefined;
  if (content) {
    for (const [type, c] of Object.entries(content))
      lines.push(
        "",
        `Request body (${type}${body.required ? ", required" : ""}):`,
        typeOf(doc, c.schema),
      );
  }
  const responses = Object.entries(o.op.responses ?? {});
  if (responses.length) {
    lines.push("", "Responses:");
    for (const [status, r] of responses) {
      const res = deref(doc, r);
      const json = (res.content as Record<string, { schema?: unknown }> | undefined)?.[
        "application/json"
      ]?.schema;
      const ok = status.startsWith("2");
      lines.push(
        `- ${status}: ${res.description ?? ""}${json ? `\n${ok ? typeOf(doc, json, 2) : typeOf(doc, json, 0)}` : ""}`,
      );
    }
  }
  return lines.join("\n");
}

// --- the tools ---------------------------------------------------------------------

const text = (s: string) => ({ content: [{ type: "text" as const, text: s }] });
const mdOf = (url: string) => {
  const [page, hash] = url.split("#");
  const base = (page as string).replace(/\/$/, "");
  const md = /\/\/[^/]+$/.test(base) ? `${base}/index.md` : `${base}.md`;
  return hash ? `${md}#${hash}` : md;
};

export interface PluginCheckResult {
  ok: boolean;
  errors: string[];
  warnings: string[];
  tips: string[];
  skills: Array<{ name: string; description: string }>;
  files: number;
  bytes: number;
  plugin?: { manifest: { name: string; version?: string } };
}

export function registerDocsTools(
  server: McpServer,
  source: DocsSource,
  opts: { checkPlugin?: (dir: string) => PluginCheckResult | Promise<PluginCheckResult> } = {},
) {
  server.registerTool(
    "search_docs",
    {
      title: "Search the Casama docs",
      description:
        "Keyword search over docs.casama.ai (guides, self-hosting, the API, CLI, SDKs, plugins, webhooks, A2A, bot templates, contributing). Returns the best-matching sections with their address; read a whole page with read_doc.",
      inputSchema: {
        query: z.string().min(2).max(500),
        limit: z.number().int().min(1).max(10).optional(),
      },
      annotations: { readOnlyHint: true, openWorldHint: false },
    },
    async ({ query, limit }) => {
      const hits = (await source.docs()).search(query, limit ?? 5);
      if (!hits.length)
        return text(`Nothing in the docs matches "${query}". Try other words, or list_doc_pages.`);
      return text(
        hits
          .map((h) => {
            const body = h.text.length > 900 ? `${h.text.slice(0, 900).trimEnd()} …` : h.text;
            return `## ${h.title}\n${h.url}\n\n${body}`;
          })
          .join("\n\n---\n\n"),
      );
    },
  );

  server.registerTool(
    "read_doc",
    {
      title: "Read a docs page",
      description:
        'One docs page as markdown, by path or address: "/develop/plugins", "develop/api.md" or "https://docs.casama.ai/guide/skills". Pass section to get one ## section only.',
      inputSchema: {
        page: z.string().min(1).max(500),
        section: z
          .string()
          .max(200)
          .optional()
          .describe('A ## heading on the page, e.g. "Secrets"'),
      },
      annotations: { readOnlyHint: true, openWorldHint: false },
    },
    async ({ page, section }) => {
      const docs = await source.docs();
      const p = docs.page(page);
      if (!p) {
        const near = docs
          .search(page.replace(/[/#.-]+/g, " "), 5)
          .map((s) => `- ${s.title}: ${s.url}`);
        return text(
          `No page at "${page}".${near.length ? ` Close matches:\n${near.join("\n")}` : ""}\nAll pages: list_doc_pages.`,
        );
      }
      let body = p.body;
      if (section) {
        const want = section
          .trim()
          .toLowerCase()
          .replace(/^#+\s*/, "");
        const parts = body.split(/^(?=## )/m);
        const hit = parts.find(
          (part) => /^## (.+)$/m.exec(part)?.[1]?.trim().toLowerCase() === want,
        );
        if (!hit) {
          const heads = parts.map((part) => /^## (.+)$/m.exec(part)?.[1]).filter(Boolean);
          return text(`No section "${section}" on ${p.url}. Sections: ${heads.join(", ")}`);
        }
        body = hit;
      }
      const max = 60_000;
      if (body.length > max)
        body = `${body.slice(0, max)}\n\n… (cut at ${max} characters; read one section at a time with section)`;
      return text(`<!-- ${p.url} (markdown: ${mdOf(p.url)}) -->\n${body}`);
    },
  );

  server.registerTool(
    "list_doc_pages",
    {
      title: "List docs pages",
      description: "Every page on docs.casama.ai with its title and address.",
      annotations: { readOnlyHint: true, openWorldHint: false },
    },
    async () => text((await source.docs()).outline()),
  );

  server.registerTool(
    "get_api_operation",
    {
      title: "Look up the Casama API",
      description:
        'Find operations in the Casama HTTP API (OpenAPI 3.1) and show their parameters, request body and responses as types. Query by operationId ("createBot"), "METHOD /path" ("POST /v1/conversations/{id}/messages", concrete ids work too) or keywords ("cancel run").',
      inputSchema: {
        query: z.string().min(2).max(300),
        limit: z.number().int().min(1).max(10).optional(),
      },
      annotations: { readOnlyHint: true, openWorldHint: false },
    },
    async ({ query, limit }) => {
      const doc = await source.openapi();
      const ops = findOperations(doc, query, limit ?? 3);
      if (!ops.length)
        return text(
          `No API operation matches "${query}". Try keywords like "send message" or "list bots".`,
        );
      return text(ops.map((o) => describeOperation(doc, o)).join("\n\n---\n\n"));
    },
  );

  const check = opts.checkPlugin;
  if (check)
    server.registerTool(
      "check_plugin",
      {
        title: "Check a plugin",
        description:
          "Check an Agent Plugins 1.0 folder (plugin.json, mcp.json, skills/) on this computer the way Casama checks it at install: errors (refused), warnings (skipped or ignored) and tips.",
        inputSchema: {
          path: z
            .string()
            .min(1)
            .describe("The plugin folder, absolute or relative to where the server runs"),
        },
        annotations: { readOnlyHint: true, openWorldHint: false },
      },
      async ({ path }) => {
        const r = await check(path);
        const list = (title: string, items: string[]) =>
          items.length ? [`${title}:`, ...items.map((i) => `- ${i}`), ""] : [];
        return text(
          [
            r.plugin ? `${r.plugin.manifest.name} ${r.plugin.manifest.version ?? ""}`.trim() : path,
            `${r.files} files, ${(r.bytes / 1024).toFixed(1)} KB`,
            r.skills.length ? `skills: ${r.skills.map((s) => s.name).join(", ")}` : "",
            "",
            ...list("Casama would refuse it", r.errors),
            ...list("Casama would skip or ignore", r.warnings),
            ...list("Tips", r.tips),
            !r.ok
              ? "Not installable. Fix the errors above."
              : r.warnings.length
                ? `Installable, with ${r.warnings.length} warning(s).`
                : "Ready to install.",
          ]
            .filter((l, i, a) => l !== "" || a[i - 1] !== "")
            .join("\n"),
        );
      },
    );
}
