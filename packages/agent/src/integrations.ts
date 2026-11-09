import type { Database } from "@kasama/db";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";
import { sql } from "drizzle-orm";
import { wrapUntrusted } from "./context.ts";
import { type NamedSecret, resolvePlaceholders } from "./secrets.ts";

export type IntegrationKind = "mcp" | "openapi" | "composio" | "pipedream";

import type { Risk } from "./tools/registry.ts";

export interface IntegrationToolInfo {
  /** Name inside the integration (the full tool name adds kind and integration name). */
  name: string;
  description: string;
  inputSchema: Record<string, unknown>;
  risk?: Risk;
}

export interface IntegrationRecord {
  id: string;
  org_id: string;
  kind: IntegrationKind;
  name: string;
  config: Record<string, unknown>;
  secret: string | null;
}

/** One integration source: lists its tools and calls them. */
export interface IntegrationAdapter {
  listTools(): Promise<IntegrationToolInfo[]>;
  callTool(name: string, args: Record<string, unknown>): Promise<string>;
  close?(): Promise<void>;
}

export interface AdapterContext {
  fetch: typeof fetch;
  /** Named secrets the bot may use (OpenAPI auth through {{secret:NAME}}). */
  secrets: NamedSecret[];
}

const str = (v: unknown) => (typeof v === "string" ? v : undefined);
const textOf = (v: unknown) => (typeof v === "string" ? v : JSON.stringify(v, null, 2));

// ---------------------------------------------------------------------------
// MCP (Streamable HTTP)
// ---------------------------------------------------------------------------

export class McpAdapter implements IntegrationAdapter {
  private client?: Client;
  private readonly url: string;
  private readonly headers: Record<string, string>;
  private readonly fetchImpl: typeof fetch;

  constructor(rec: IntegrationRecord, ctx: AdapterContext) {
    const url = str(rec.config.url);
    if (!url) throw new Error("MCP integration needs a url");
    this.url = url;
    const header = str(rec.config.auth_header) ?? "authorization";
    this.headers = rec.secret
      ? {
          [header]:
            header.toLowerCase() === "authorization" && !/^\w+ /.test(rec.secret)
              ? `Bearer ${rec.secret}`
              : rec.secret,
        }
      : {};
    this.fetchImpl = ctx.fetch;
  }

  private async connect() {
    if (this.client) return this.client;
    const client = new Client({ name: "kasama", version: "0.1.0" });
    const transport = new StreamableHTTPClientTransport(new URL(this.url), {
      requestInit: { headers: this.headers },
      fetch: this.fetchImpl as never,
    });
    await client.connect(transport);
    this.client = client;
    return client;
  }

  async listTools() {
    const client = await this.connect();
    const out: IntegrationToolInfo[] = [];
    let cursor: string | undefined;
    do {
      const r = await client.listTools(cursor ? { cursor } : undefined);
      for (const t of r.tools) {
        out.push({
          name: t.name,
          description: t.description ?? t.name,
          inputSchema: (t.inputSchema as Record<string, unknown>) ?? { type: "object" },
          risk: t.annotations?.readOnlyHint
            ? "low"
            : t.annotations?.destructiveHint
              ? "high"
              : "medium",
        });
      }
      cursor = r.nextCursor;
    } while (cursor && out.length < 500);
    return out;
  }

  async callTool(name: string, args: Record<string, unknown>) {
    const client = await this.connect();
    const r = (await client.callTool({ name, arguments: args })) as {
      content?: Array<{ type: string; text?: string }>;
      isError?: boolean;
      structuredContent?: unknown;
    };
    const text =
      (r.content ?? [])
        .map((c) => (c.type === "text" ? (c.text ?? "") : `[${c.type} content]`))
        .join("\n") || textOf(r.structuredContent ?? "");
    if (r.isError) throw new Error(text || "MCP tool returned an error");
    return text;
  }

  async close() {
    await this.client?.close().catch(() => {});
  }
}

// ---------------------------------------------------------------------------
// OpenAPI 3 sources
// ---------------------------------------------------------------------------

interface OpenApiOperation {
  method: string;
  path: string;
  params: Array<{
    name: string;
    in: string;
    required?: boolean;
    schema?: Record<string, unknown>;
    description?: string;
  }>;
  body?: Record<string, unknown>;
  bodyRequired?: boolean;
  description: string;
}

/** Turns an OpenAPI 3 document into one tool per operation. */
export function parseOpenApi(spec: Record<string, unknown>): Map<string, OpenApiOperation> {
  const ops = new Map<string, OpenApiOperation>();
  const paths = (spec.paths ?? {}) as Record<string, Record<string, Record<string, unknown>>>;
  const components = ((spec.components as Record<string, unknown>)?.schemas ?? {}) as Record<
    string,
    unknown
  >;
  const deref = (s: unknown, depth = 0): Record<string, unknown> => {
    if (!s || typeof s !== "object" || depth > 8) return (s as Record<string, unknown>) ?? {};
    const ref = (s as { $ref?: string }).$ref;
    if (ref?.startsWith("#/components/schemas/"))
      return deref(components[ref.slice(21)], depth + 1);
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(s)) {
      out[k] = Array.isArray(v)
        ? v.map((x) => deref(x, depth + 1))
        : v && typeof v === "object"
          ? deref(v, depth + 1)
          : v;
    }
    return out;
  };
  for (const [path, methods] of Object.entries(paths)) {
    const shared = (methods.parameters as unknown as OpenApiOperation["params"]) ?? [];
    for (const method of ["get", "post", "put", "patch", "delete"]) {
      const op = methods[method];
      if (!op) continue;
      const id =
        str(op.operationId) ??
        `${method}_${path.replace(/[^a-zA-Z0-9]+/g, "_").replace(/^_|_$/g, "")}`;
      const content = ((op.requestBody as Record<string, unknown>)?.content ?? {}) as Record<
        string,
        { schema?: unknown }
      >;
      const body = content["application/json"]?.schema;
      ops.set(id.replace(/[^a-zA-Z0-9_]/g, "_").slice(0, 64), {
        method: method.toUpperCase(),
        path,
        params: [...shared, ...((op.parameters as OpenApiOperation["params"]) ?? [])].filter(
          (p) => p && p.in !== "header" && p.in !== "cookie",
        ),
        body: body ? deref(body) : undefined,
        bodyRequired: Boolean((op.requestBody as Record<string, unknown>)?.required),
        description: str(op.summary) ?? str(op.description) ?? `${method.toUpperCase()} ${path}`,
      });
    }
  }
  return ops;
}

export class OpenApiAdapter implements IntegrationAdapter {
  private readonly ops: Map<string, OpenApiOperation>;
  private readonly baseUrl: string;
  private readonly auth?: { type: "bearer" | "header"; header?: string; secret: string };
  private readonly ctx: AdapterContext;

  constructor(rec: IntegrationRecord, ctx: AdapterContext) {
    const spec = (rec.config.spec ?? {}) as Record<string, unknown>;
    this.ops = parseOpenApi(spec);
    const server = ((spec.servers as Array<{ url?: string }>) ?? [])[0]?.url;
    const base = str(rec.config.base_url) ?? server;
    if (!base) throw new Error("OpenAPI integration needs servers[0].url or base_url");
    this.baseUrl = base.replace(/\/$/, "");
    this.auth = rec.config.auth as typeof this.auth;
    this.ctx = ctx;
  }

  async listTools() {
    return [...this.ops.entries()].map(([name, op]) => {
      const properties: Record<string, unknown> = {};
      const required: string[] = [];
      for (const p of op.params) {
        properties[p.name] = {
          ...(p.schema ?? { type: "string" }),
          ...(p.description ? { description: p.description } : {}),
        };
        if (p.required || p.in === "path") required.push(p.name);
      }
      if (op.body) {
        properties.body = op.body;
        if (op.bodyRequired) required.push("body");
      }
      return {
        name,
        description: op.description,
        inputSchema: { type: "object", properties, required },
        risk: (op.method === "GET" ? "low" : "medium") as Risk,
      };
    });
  }

  async callTool(name: string, args: Record<string, unknown>) {
    const op = this.ops.get(name);
    if (!op) throw new Error(`Unknown operation ${name}`);
    let path = op.path;
    const query = new URLSearchParams();
    for (const p of op.params) {
      const v = args[p.name];
      if (v === undefined || v === null) continue;
      if (p.in === "path") path = path.replace(`{${p.name}}`, encodeURIComponent(String(v)));
      else if (p.in === "query") query.set(p.name, String(v));
    }
    const url = new URL(`${this.baseUrl}${path}${query.size ? `?${query}` : ""}`);
    const headers: Record<string, string> = { accept: "application/json" };
    if (this.auth?.secret) {
      // Auth comes from a named secret, so it obeys the secret's host allowlist.
      const value = resolvePlaceholders(
        `{{secret:${this.auth.secret}}}`,
        this.ctx.secrets,
        url.hostname,
      );
      if (this.auth.type === "bearer") headers.authorization = `Bearer ${value}`;
      else headers[this.auth.header ?? "x-api-key"] = value;
    }
    if (args.body !== undefined) headers["content-type"] = "application/json";
    const res = await this.ctx.fetch(url, {
      method: op.method,
      headers,
      body: args.body !== undefined ? JSON.stringify(args.body) : undefined,
    });
    const text = await res.text();
    if (!res.ok)
      throw new Error(`${op.method} ${path} returned ${res.status}: ${text.slice(0, 500)}`);
    return text;
  }
}

// ---------------------------------------------------------------------------
// Composio (REST v3)
// ---------------------------------------------------------------------------

export class ComposioAdapter implements IntegrationAdapter {
  private readonly base: string;
  private readonly key: string;
  private readonly toolkits: string[];
  private readonly userId: string;
  private readonly fetchImpl: typeof fetch;

  constructor(rec: IntegrationRecord, ctx: AdapterContext) {
    if (!rec.secret) throw new Error("Composio integration needs an API key");
    this.key = rec.secret;
    this.base = (str(rec.config.base_url) ?? "https://backend.composio.dev").replace(/\/$/, "");
    this.toolkits = (rec.config.toolkits as string[]) ?? [];
    this.userId = str(rec.config.user_id) ?? rec.org_id;
    this.fetchImpl = ctx.fetch;
  }

  private async call(path: string, init: RequestInit = {}) {
    const res = await this.fetchImpl(`${this.base}${path}`, {
      ...init,
      headers: {
        "x-api-key": this.key,
        "content-type": "application/json",
        ...(init.headers as Record<string, string>),
      },
    });
    const json = (await res.json().catch(() => ({}))) as Record<string, unknown>;
    if (!res.ok)
      throw new Error(
        `Composio returned ${res.status}: ${textOf(json.error ?? json.message ?? "")}`,
      );
    return json;
  }

  async listTools() {
    const out: IntegrationToolInfo[] = [];
    for (const toolkit of this.toolkits.length ? this.toolkits : [""]) {
      const r = await this.call(
        `/api/v3/tools?limit=200${toolkit ? `&toolkit_slug=${encodeURIComponent(toolkit)}` : ""}`,
      );
      for (const t of (r.items as Array<Record<string, unknown>>) ?? []) {
        out.push({
          name: String(t.slug).toLowerCase(),
          description: str(t.description) ?? str(t.name) ?? String(t.slug),
          inputSchema: (t.input_parameters as Record<string, unknown>) ?? { type: "object" },
        });
      }
    }
    return out;
  }

  async callTool(name: string, args: Record<string, unknown>) {
    const r = await this.call(`/api/v3/tools/execute/${encodeURIComponent(name.toUpperCase())}`, {
      method: "POST",
      body: JSON.stringify({ user_id: this.userId, arguments: args }),
    });
    if (r.successful === false) throw new Error(textOf(r.error ?? "Composio tool failed"));
    return textOf(r.data ?? r);
  }
}

// ---------------------------------------------------------------------------
// Pipedream Connect
// ---------------------------------------------------------------------------

export class PipedreamAdapter implements IntegrationAdapter {
  private readonly base: string;
  private readonly projectId: string;
  private readonly clientId: string;
  private readonly clientSecret: string;
  private readonly environment: string;
  private readonly apps: string[];
  private readonly externalUserId: string;
  private readonly fetchImpl: typeof fetch;
  private token: { value: string; expires: number } | null = null;

  constructor(rec: IntegrationRecord, ctx: AdapterContext) {
    if (!rec.secret) throw new Error("Pipedream Connect needs a client secret");
    const project = str(rec.config.project_id);
    const client = str(rec.config.client_id);
    if (!project || !client) throw new Error("Pipedream Connect needs project_id and client_id");
    this.base = (str(rec.config.base_url) ?? "https://api.pipedream.com").replace(/\/$/, "");
    this.projectId = project;
    this.clientId = client;
    this.clientSecret = rec.secret;
    this.environment = str(rec.config.environment) ?? "production";
    this.apps = (rec.config.apps as string[]) ?? [];
    this.externalUserId = str(rec.config.external_user_id) ?? rec.org_id;
    this.fetchImpl = ctx.fetch;
  }

  private async accessToken() {
    if (this.token && this.token.expires > Date.now() + 60_000) return this.token.value;
    const res = await this.fetchImpl(`${this.base}/v1/oauth/token`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        grant_type: "client_credentials",
        client_id: this.clientId,
        client_secret: this.clientSecret,
      }),
    });
    if (!res.ok) throw new Error(`Pipedream auth failed with ${res.status}`);
    const json = (await res.json()) as { access_token: string; expires_in?: number };
    this.token = {
      value: json.access_token,
      expires: Date.now() + (json.expires_in ?? 3600) * 1000,
    };
    return this.token.value;
  }

  private async call(path: string, init: RequestInit = {}) {
    const res = await this.fetchImpl(`${this.base}${path}`, {
      ...init,
      headers: {
        authorization: `Bearer ${await this.accessToken()}`,
        "x-pd-environment": this.environment,
        "content-type": "application/json",
      },
    });
    const json = (await res.json().catch(() => ({}))) as Record<string, unknown>;
    if (!res.ok) throw new Error(`Pipedream returned ${res.status}: ${textOf(json.error ?? "")}`);
    return json;
  }

  async listTools() {
    const out: IntegrationToolInfo[] = [];
    for (const app of this.apps) {
      const r = await this.call(
        `/v1/connect/${this.projectId}/actions?app=${encodeURIComponent(app)}&limit=100`,
      );
      for (const a of (r.data as Array<Record<string, unknown>>) ?? []) {
        const props = ((a.configurable_props as Array<Record<string, unknown>>) ?? []).filter(
          (p) => p.type !== "app",
        );
        out.push({
          name: String(a.key).replace(/[^a-zA-Z0-9_]/g, "_"),
          description: str(a.description) ?? str(a.name) ?? String(a.key),
          inputSchema: {
            type: "object",
            properties: Object.fromEntries(
              props.map((p) => [
                String(p.name),
                {
                  type:
                    p.type === "integer" ? "integer" : p.type === "boolean" ? "boolean" : "string",
                  description: str(p.description),
                },
              ]),
            ),
            required: props.filter((p) => !p.optional).map((p) => String(p.name)),
          },
        });
      }
    }
    return out;
  }

  async callTool(name: string, args: Record<string, unknown>) {
    // Action keys use dashes (slack-send-message); tool names use underscores.
    const key = name.replace(/_/g, "-");
    const r = await this.call(`/v1/connect/${this.projectId}/actions/run`, {
      method: "POST",
      body: JSON.stringify({
        id: key,
        external_user_id: this.externalUserId,
        configured_props: args,
      }),
    });
    return textOf(r.ret ?? r.exports ?? r);
  }
}

export function createAdapter(rec: IntegrationRecord, ctx: AdapterContext): IntegrationAdapter {
  switch (rec.kind) {
    case "mcp":
      return new McpAdapter(rec, ctx);
    case "openapi":
      return new OpenApiAdapter(rec, ctx);
    case "composio":
      return new ComposioAdapter(rec, ctx);
    case "pipedream":
      return new PipedreamAdapter(rec, ctx);
  }
}

/** Full tool name for the model and the registry. */
export const integrationToolName = (rec: Pick<IntegrationRecord, "kind" | "name">, tool: string) =>
  `${rec.kind}.${rec.name}.${tool.replace(/[^a-zA-Z0-9_-]/g, "_")}`.slice(0, 120);

/** Loads integrations with their credential (worker only: reads Vault). */
export async function loadIntegration(db: Database, id: string): Promise<IntegrationRecord | null> {
  const [row] = await db.execute<IntegrationRecord & { [k: string]: unknown }>(sql`
    select i.id, i.org_id, i.kind, i.name, i.config, v.decrypted_secret as secret
    from public.integrations i left join vault.decrypted_secrets v on v.id = i.vault_secret_id
    where i.id = ${id}::uuid`);
  return row ?? null;
}

/** Lists an integration's tools and caches them (with status) on the row. */
export async function refreshIntegration(db: Database, id: string, ctx: AdapterContext) {
  const rec = await loadIntegration(db, id);
  if (!rec) throw new Error("integration_not_found");
  let adapter: IntegrationAdapter | undefined;
  try {
    adapter = createAdapter(rec, ctx);
    const tools = await adapter.listTools();
    await db.execute(sql`
      update public.integrations set status = 'ok', error = null, tools_cache = ${JSON.stringify(tools)}::jsonb, tools_cached_at = now()
      where id = ${id}::uuid`);
    return { ok: true as const, tools };
  } catch (err) {
    const message = (err as Error).message.slice(0, 500);
    await db.execute(
      sql`update public.integrations set status = 'error', error = ${message} where id = ${id}::uuid`,
    );
    return { ok: false as const, error: message, tools: [] as IntegrationToolInfo[] };
  } finally {
    await adapter?.close?.();
  }
}

/** Integration output is untrusted (it comes from outside services). */
export const wrapIntegrationOutput = (
  rec: Pick<IntegrationRecord, "kind" | "name">,
  text: string,
) => wrapUntrusted(`${rec.kind}:${rec.name}`, text);
