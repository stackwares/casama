import type { Database } from "@kasama/db";
import { refreshAuthorization } from "@modelcontextprotocol/sdk/client/auth.js";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { SSEClientTransport } from "@modelcontextprotocol/sdk/client/sse.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";
import { sql } from "drizzle-orm";
import { wrapUntrusted } from "./context.ts";
import { type NamedSecret, resolvePlaceholders } from "./secrets.ts";

export type IntegrationKind = "mcp" | "openapi" | "composio" | "pipedream" | "local_mcp";

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

/** Options for a tool call (long local calls report progress and can be cancelled). */
export interface CallToolOptions {
  signal?: AbortSignal;
  onProgress?: (text: string) => void;
}

/** One integration source: lists its tools and calls them. */
export interface IntegrationAdapter {
  listTools(): Promise<IntegrationToolInfo[]>;
  callTool(name: string, args: Record<string, unknown>, opts?: CallToolOptions): Promise<string>;
  close?(): Promise<void>;
}

export interface AdapterContext {
  fetch: typeof fetch;
  /** Named secrets the bot may use (OpenAPI auth through {{secret:NAME}}). */
  secrets: NamedSecret[];
  /** The API's device tunnel, for local MCP servers on a user's computer (D-096). */
  local?: { apiUrl: string; internalToken: string };
  /** The run a call belongs to (shown on the companion's overlay, checked against allowed bots). */
  activity?: { run_id: string; bot: string; tool: string; summary: string };
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
    const oauth = parseOAuthSecret(rec.secret);
    const value = oauth ? oauth.access_token : rec.secret;
    this.headers = value
      ? {
          [oauth ? "authorization" : header]:
            (oauth || header.toLowerCase() === "authorization") && !/^\w+ /.test(value)
              ? `Bearer ${value}`
              : value,
        }
      : {};
    this.fetchImpl = ctx.fetch;
  }

  private async connect() {
    if (this.client) return this.client;
    const client = new Client({ name: "kasama", version: "0.1.0" });
    const url = new URL(this.url);
    const opts = { requestInit: { headers: this.headers }, fetch: this.fetchImpl as never };
    // Legacy SSE servers still exist; their endpoint ends in /sse.
    const transport = url.pathname.endsWith("/sse")
      ? new SSEClientTransport(url, opts)
      : new StreamableHTTPClientTransport(url, opts);
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
// Local MCP servers on a user's computer (D-096): MCP over the API's device tunnel to the
// companion's computerd, which bridges to the server (stdio or loopback).
// ---------------------------------------------------------------------------

export class LocalMcpAdapter implements IntegrationAdapter {
  private client?: Client;
  private readonly url: string;
  private readonly headers: Record<string, string>;
  private readonly timeoutMs: number;

  constructor(rec: IntegrationRecord, ctx: AdapterContext) {
    const computer = str(rec.config.computer_id);
    const server = str(rec.config.server);
    if (!computer || !server) throw new Error("This local MCP server has no computer");
    if (!ctx.local) throw new Error("Personal computers are not set up on this server");
    this.url = `${ctx.local.apiUrl.replace(/\/$/, "")}/internal/local/${computer}/http/mcp/${server}`;
    this.headers = {
      "x-kasama-internal": ctx.local.internalToken,
      ...(ctx.activity
        ? { "x-kasama-activity": Buffer.from(JSON.stringify(ctx.activity)).toString("base64") }
        : {}),
    };
    const t = Number(rec.config.timeout_s);
    this.timeoutMs = (Number.isFinite(t) && t > 0 ? t : 1800) * 1000;
  }

  private async connect() {
    if (this.client) return this.client;
    const client = new Client({ name: "kasama", version: "0.1.0" });
    const transport = new StreamableHTTPClientTransport(new URL(this.url), {
      requestInit: { headers: this.headers },
    });
    try {
      await client.connect(transport);
    } catch (err) {
      throw localError(err);
    }
    this.client = client;
    return client;
  }

  async listTools() {
    const client = await this.connect();
    const r = await client.listTools().catch((err: unknown) => {
      throw localError(err);
    });
    return r.tools.map((t) => ({
      name: t.name,
      description: t.description ?? t.name,
      inputSchema: (t.inputSchema as Record<string, unknown>) ?? { type: "object" },
      risk: (t.annotations?.readOnlyHint
        ? "low"
        : t.annotations?.destructiveHint
          ? "high"
          : "medium") as Risk,
    }));
  }

  async callTool(name: string, args: Record<string, unknown>, opts: CallToolOptions = {}) {
    const client = await this.connect();
    const r = (await client
      .callTool({ name, arguments: args }, undefined, {
        signal: opts.signal,
        timeout: this.timeoutMs,
        resetTimeoutOnProgress: true,
        maxTotalTimeout: this.timeoutMs * 4,
        onprogress: (p) =>
          opts.onProgress?.(
            p.message ?? (p.total ? `Progress ${p.progress}/${p.total}` : `Progress ${p.progress}`),
          ),
      })
      .catch((err: unknown) => {
        throw localError(err);
      })) as {
      content?: Array<{ type: string; text?: string }>;
      isError?: boolean;
      structuredContent?: unknown;
    };
    const text =
      (r.content ?? [])
        .map((c) => (c.type === "text" ? (c.text ?? "") : `[${c.type} content]`))
        .join("\n") || textOf(r.structuredContent ?? "");
    if (r.isError) throw new Error(text || "The local MCP tool returned an error");
    return text;
  }

  async close() {
    await this.client?.close().catch(() => {});
  }
}

/** Turns tunnel failures into plain messages (offline computer, bot not allowed). */
function localError(err: unknown): Error {
  const msg = (err as Error)?.message ?? String(err);
  if (/device_offline|409/.test(msg))
    return new Error(
      'The computer running this MCP server is offline. Open the Kasama desktop app there and turn on "Use this computer for bots".',
    );
  if (/bot_not_allowed|403/.test(msg))
    return new Error(
      "This bot is not allowed to use that computer, or local tools are turned off there.",
    );
  return err instanceof Error ? err : new Error(msg);
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

  /** The Connect API token, for the guided-connection calls. */
  token_() {
    return this.accessToken();
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
    case "local_mcp":
      return new LocalMcpAdapter(rec, ctx);
  }
}

/** Full tool name for the model and the registry. */
export const integrationToolName = (rec: Pick<IntegrationRecord, "kind" | "name">, tool: string) =>
  `${rec.kind}.${rec.name}.${tool.replace(/[^a-zA-Z0-9_-]/g, "_")}`.slice(0, 120);

/**
 * An OAuth connection's credential, kept as JSON in Vault (D-089): the tokens, plus what is
 * needed to refresh them (the authorization server, its metadata, and the client).
 */
export interface OAuthSecret {
  type: "oauth";
  access_token: string;
  refresh_token?: string;
  /** Epoch milliseconds. */
  expires_at?: number;
  auth_server: string;
  metadata?: Record<string, unknown>;
  client: { client_id: string; client_secret?: string; [k: string]: unknown };
  resource?: string;
}

export function parseOAuthSecret(secret: string | null | undefined): OAuthSecret | null {
  if (!secret?.startsWith("{")) return null;
  try {
    const v = JSON.parse(secret) as Partial<OAuthSecret>;
    return v.type === "oauth" && typeof v.access_token === "string" ? (v as OAuthSecret) : null;
  } catch {
    return null;
  }
}

/** Builds the stored credential from a token response. */
export function oauthSecretFrom(
  tokens: { access_token: string; refresh_token?: string; expires_in?: number },
  ctx: Omit<OAuthSecret, "type" | "access_token" | "refresh_token" | "expires_at">,
  previous?: OAuthSecret | null,
): OAuthSecret {
  return {
    type: "oauth",
    access_token: tokens.access_token,
    // Some servers only send a refresh token the first time.
    refresh_token: tokens.refresh_token ?? previous?.refresh_token,
    expires_at: tokens.expires_in ? Date.now() + tokens.expires_in * 1000 : undefined,
    ...ctx,
  };
}

/** Loads integrations with their credential (worker and API service role: reads Vault). OAuth
 * tokens that expire within two minutes are refreshed first and saved back to Vault. */
export async function loadIntegration(
  db: Database,
  id: string,
  fetchImpl: typeof fetch = fetch,
): Promise<IntegrationRecord | null> {
  const [row] = await db.execute<
    IntegrationRecord & { vault_secret_id: string | null; [k: string]: unknown }
  >(sql`
    select i.id, i.org_id, i.kind, i.name, i.config, i.vault_secret_id, v.decrypted_secret as secret
    from public.integrations i left join vault.decrypted_secrets v on v.id = i.vault_secret_id
    where i.id = ${id}::uuid`);
  if (!row) return null;
  const oauth = parseOAuthSecret(row.secret);
  if (oauth?.refresh_token && oauth.expires_at && oauth.expires_at < Date.now() + 120_000) {
    try {
      const tokens = await refreshAuthorization(oauth.auth_server, {
        metadata: oauth.metadata as never,
        clientInformation: oauth.client as never,
        refreshToken: oauth.refresh_token,
        resource: oauth.resource ? new URL(oauth.resource) : undefined,
        fetchFn: fetchImpl as never,
      });
      const { type: _t, access_token: _a, refresh_token: _r, expires_at: _e, ...ctx } = oauth;
      const next = JSON.stringify(oauthSecretFrom(tokens, ctx, oauth));
      if (row.vault_secret_id)
        await db.execute(sql`select vault.update_secret(${row.vault_secret_id}::uuid, ${next})`);
      row.secret = next;
    } catch (err) {
      await db.execute(sql`
        update public.integrations set status = 'error', error = ${`Sign-in expired: ${(err as Error).message}`.slice(0, 500)}
        where id = ${id}::uuid`);
    }
  }
  const { vault_secret_id: _v, ...rec } = row;
  return rec;
}

/** Lists an integration's tools and caches them (with status) on the row. */
export async function refreshIntegration(db: Database, id: string, ctx: AdapterContext) {
  const rec = await loadIntegration(db, id, ctx.fetch);
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

// ---------------------------------------------------------------------------
// Guided connections through Composio and Pipedream (D-089): their app directories, and
// connecting a person's account to one app through the provider's hosted sign-in page.
// ---------------------------------------------------------------------------

export interface ProviderApp {
  slug: string;
  name: string;
  description: string;
  logo: string | null;
}

export interface ProviderAccount {
  app: string;
  status: "connected" | "pending" | "error";
}

async function providerJson(fetchImpl: typeof fetch, url: string, init: RequestInit) {
  const res = await fetchImpl(url, init);
  const json = (await res.json().catch(() => ({}))) as Record<string, unknown>;
  if (!res.ok) {
    const msg = textOf(json.error ?? json.message ?? "");
    throw new Error(`${new URL(url).hostname} returned ${res.status}${msg ? `: ${msg}` : ""}`);
  }
  return json;
}

/** Composio: toolkits, Composio-managed sign-in links, and connected accounts (REST v3). */
export function composioDirectory(rec: IntegrationRecord, fetchImpl: typeof fetch) {
  if (!rec.secret) throw new Error("Composio needs an API key");
  const base = (str(rec.config.base_url) ?? "https://backend.composio.dev").replace(/\/$/, "");
  const userId = str(rec.config.user_id) ?? rec.org_id;
  const headers = { "x-api-key": rec.secret, "content-type": "application/json" };
  const call = (path: string, init: RequestInit = {}) =>
    providerJson(fetchImpl, `${base}${path}`, { ...init, headers });
  return {
    async apps(query: string): Promise<ProviderApp[]> {
      const r = await call(
        `/api/v3/toolkits?limit=50${query ? `&search=${encodeURIComponent(query)}` : ""}`,
      );
      return ((r.items as Array<Record<string, unknown>>) ?? []).map((t) => {
        const meta = (t.meta as Record<string, unknown>) ?? {};
        return {
          slug: String(t.slug),
          name: str(t.name) ?? String(t.slug),
          description: str(meta.description) ?? "",
          logo: str(meta.logo) ?? null,
        };
      });
    },
    /** Starts a sign-in for one app; returns the page to open. */
    async connect(app: string, callbackUrl: string): Promise<{ redirect_url: string }> {
      const config = await call("/api/v3/auth_configs", {
        method: "POST",
        body: JSON.stringify({
          toolkit: { slug: app },
          auth_config: { type: "use_composio_managed_auth" },
        }),
      });
      const authConfigId =
        str((config.auth_config as Record<string, unknown>)?.id) ?? str(config.id);
      if (!authConfigId) throw new Error("Composio did not return an auth config");
      const account = await call("/api/v3/connected_accounts", {
        method: "POST",
        body: JSON.stringify({
          auth_config: { id: authConfigId },
          connection: { user_id: userId, callback_url: callbackUrl },
        }),
      });
      const redirect =
        str(account.redirect_url) ??
        str((account.connectionData as Record<string, unknown>)?.redirect_url);
      if (!redirect) throw new Error("Composio did not return a sign-in link");
      return { redirect_url: redirect };
    },
    async accounts(): Promise<ProviderAccount[]> {
      const r = await call(
        `/api/v3/connected_accounts?user_ids=${encodeURIComponent(userId)}&limit=100`,
      );
      return ((r.items as Array<Record<string, unknown>>) ?? []).map((a) => ({
        app: str((a.toolkit as Record<string, unknown>)?.slug) ?? "",
        status:
          a.status === "ACTIVE"
            ? "connected"
            : a.status === "INITIATED" || a.status === "INITIALIZING"
              ? "pending"
              : "error",
      }));
    },
  };
}

/** Pipedream Connect: the app directory, Connect Link sign-in pages, and connected accounts. */
export function pipedreamDirectory(rec: IntegrationRecord, fetchImpl: typeof fetch) {
  const adapter = new PipedreamAdapter(rec, { fetch: fetchImpl, secrets: [] });
  const base = (str(rec.config.base_url) ?? "https://api.pipedream.com").replace(/\/$/, "");
  const project = str(rec.config.project_id) ?? "";
  const externalUserId = str(rec.config.external_user_id) ?? rec.org_id;
  const call = async (path: string, init: RequestInit = {}) =>
    providerJson(fetchImpl, `${base}${path}`, {
      ...init,
      headers: {
        authorization: `Bearer ${await adapter.token_()}`,
        "x-pd-environment": str(rec.config.environment) ?? "production",
        "content-type": "application/json",
      },
    });
  return {
    async apps(query: string): Promise<ProviderApp[]> {
      const r = await call(`/v1/apps?limit=50${query ? `&q=${encodeURIComponent(query)}` : ""}`);
      return ((r.data as Array<Record<string, unknown>>) ?? []).map((a) => ({
        slug: String(a.name_slug),
        name: str(a.name) ?? String(a.name_slug),
        description: str(a.description) ?? "",
        logo: str(a.img_src) ?? null,
      }));
    },
    async connect(app: string, callbackUrl: string): Promise<{ redirect_url: string }> {
      const r = await call(`/v1/connect/${project}/tokens`, {
        method: "POST",
        body: JSON.stringify({
          external_user_id: externalUserId,
          success_redirect_uri: callbackUrl,
        }),
      });
      const link = str(r.connect_link_url);
      if (!link) throw new Error("Pipedream did not return a Connect Link");
      return {
        redirect_url: `${link}${link.includes("?") ? "&" : "?"}app=${encodeURIComponent(app)}`,
      };
    },
    async accounts(): Promise<ProviderAccount[]> {
      const r = await call(
        `/v1/connect/${project}/accounts?external_user_id=${encodeURIComponent(externalUserId)}`,
      );
      return ((r.data as Array<Record<string, unknown>>) ?? []).map((a) => ({
        app: str((a.app as Record<string, unknown>)?.name_slug) ?? "",
        status: a.healthy === false || a.dead === true ? "error" : "connected",
      }));
    },
  };
}
