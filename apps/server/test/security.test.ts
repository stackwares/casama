/**
 * Phase 8 security review: a cross-tenant sweep of every API route. User A owns a workspace full
 * of resources; user B (another workspace) calls every operation in the OpenAPI document with A's
 * ids and schema-valid bodies. Nothing may succeed and no response may contain A's ids.
 */
import { fileURLToPath } from "node:url";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));

type Schema = {
  $ref?: string;
  type?: string | string[];
  properties?: Record<string, Schema>;
  required?: string[];
  items?: Schema;
  enum?: unknown[];
  format?: string;
  minimum?: number;
  minItems?: number;
  minLength?: number;
  pattern?: string;
  anyOf?: Schema[];
  oneOf?: Schema[];
  allOf?: Schema[];
  default?: unknown;
};

describe("cross-tenant sweep (Phase 8 security review)", () => {
  let h: Harness;
  let doc: {
    paths: Record<
      string,
      Record<
        string,
        { operationId: string; requestBody?: { content: Record<string, { schema: Schema }> } }
      >
    >;
    components: { schemas: Record<string, Schema> };
  };
  let a: { id: string; token: string };
  let b: { id: string; token: string };
  const ids: Record<string, string> = {};

  beforeAll(async () => {
    h = await startHarness({ worker: { fixtures: FIXTURES } });
    a = await h.user("tenant-a@example.com");
    b = await h.user("tenant-b@example.com");
    const post = async (token: string, path: string, json: unknown) => {
      const r = await h.request(path, { method: "POST", token, json });
      if (r.status >= 300) throw new Error(`${path}: ${r.status} ${await r.text()}`);
      return j(r);
    };
    ids.org = (await post(a.token, "/v1/orgs", { name: "Tenant A" })).id;
    await post(b.token, "/v1/orgs", { name: "Tenant B" });
    ids.credential = (
      await post(a.token, "/v1/credentials", {
        org_id: ids.org,
        provider: "openrouter",
        label: "k",
        api_key: "sk-tenant-a-secret",
      })
    ).id;
    ids.bot = (
      await post(a.token, "/v1/bots", {
        org_id: ids.org,
        name: "A bot",
        model_policy: { primary: { credential_id: ids.credential, model: "fixture-main" } },
      })
    ).id;
    ids.conversation = (await post(a.token, "/v1/conversations", { bot_id: ids.bot })).id;
    ids.run = (
      await post(a.token, `/v1/conversations/${ids.conversation}/messages`, { text: "hello" })
    ).run_id;
    for (let i = 0; i < 100; i++) {
      const r = await j(await h.request(`/v1/runs/${ids.run}`, { token: a.token }));
      if (r.status === "completed") break;
      await new Promise((res) => setTimeout(res, 200));
    }
    const [m] = await h.handle.db.execute<{ id: string }>(
      sql`select id from public.messages where conversation_id = ${ids.conversation}::uuid order by created_at desc limit 1`,
    );
    ids.message = m?.id as string;
    ids.routine = (
      await post(a.token, "/v1/routines", {
        bot_id: ids.bot,
        name: "R",
        instructions: "x",
        trigger: "webhook",
      })
    ).id;
    ids.secret = (
      await post(a.token, "/v1/secrets", {
        org_id: ids.org,
        name: "A_SECRET",
        value: "s3cret-tenant-a",
        allowed_hosts: ["example.com"],
      })
    ).id;
    ids.integration = (
      await post(a.token, "/v1/integrations", {
        org_id: ids.org,
        kind: "mcp",
        name: "a_tools",
        config: { url: "https://mcp.example.com/mcp" },
      })
    ).id;
    ids.task = (
      await h.handle.db.execute<{ id: string }>(
        sql`insert into public.tasks (org_id, title, created_by_user_id) values (${ids.org}::uuid, 'A task', ${a.id}::uuid) returning id`,
      )
    )[0]?.id as string;
    ids.computer = (
      await j(await h.request(`/v1/computers?org_id=${ids.org}`, { token: a.token }))
    ).items[0].id;
    ids.device = (
      await post(a.token, "/v1/local-devices", {
        org_id: ids.org,
        name: "A laptop",
        platform: "macos",
      })
    ).id;
    ids.connectKey = "00000000-0000-4000-8000-000000000001";
    doc = await j(await h.request("/openapi.json"));
  }, 180_000);
  afterAll(async () => h?.stop());

  /** The resource id a path parameter refers to, by the path's first segment. */
  const idFor = (path: string, param: string) => {
    const seg = path.split("/")[2] ?? "";
    if (param === "id") {
      const byPath: Record<string, string | undefined> = {
        orgs: ids.org,
        bots: ids.bot,
        conversations: ids.conversation,
        runs: ids.run,
        messages: ids.message,
        routines: ids.routine,
        secrets: ids.secret,
        integrations: ids.integration,
        tasks: ids.task,
        computers: ids.computer,
        credentials: ids.credential,
        "local-devices": ids.device,
        approvals: ids.run,
        invites: ids.org,
        admin: ids.org,
      };
      return byPath[seg] ?? ids.org ?? "";
    }
    const named: Record<string, string | undefined> = {
      bot_id: ids.bot,
      org_id: ids.org,
      integration_id: ids.integration,
      key_id: ids.connectKey,
      routine_id: ids.routine,
      cid: ids.computer,
    };
    return named[param] ?? ids.org ?? "";
  };

  const resolve = (s: Schema): Schema =>
    s.$ref ? resolve(doc.components.schemas[s.$ref.split("/").pop() as string] as Schema) : s;

  /** A small schema-valid sample that points every id at tenant A's resources. */
  const sample = (s0: Schema, key = ""): unknown => {
    const s = resolve(s0);
    if (s.allOf) return Object.assign({}, ...s.allOf.map((x) => sample(x, key) as object));
    if (s.anyOf || s.oneOf)
      return sample((s.anyOf ?? s.oneOf)?.find((x) => resolve(x).type !== "null") ?? {}, key);
    if (s.enum) return s.enum[0];
    if (s.default !== undefined) return s.default;
    const type = Array.isArray(s.type) ? s.type.find((t) => t !== "null") : s.type;
    if (type === "object" || s.properties) {
      const out: Record<string, unknown> = {};
      for (const k of s.required ?? []) out[k] = sample(s.properties?.[k] ?? {}, k);
      return out;
    }
    if (type === "array")
      return Array.from({ length: Math.max(1, s.minItems ?? 0) }, () => sample(s.items ?? {}, key));
    if (type === "integer" || type === "number") return Math.max(1, s.minimum ?? 1);
    if (type === "boolean") return false;
    if (s.format === "uuid")
      return key.endsWith("org_id")
        ? ids.org
        : key.endsWith("bot_id")
          ? ids.bot
          : idFor(`/v1/${key.replace(/_id$/, "s")}`, "id");
    if (s.format === "email") return "tenant-b@example.com";
    if (s.format === "uri" || s.format === "url") return "https://example.com";
    if (s.format === "date-time") return new Date().toISOString();
    if (s.pattern?.startsWith("^[A-Z]")) return "X_NAME";
    return "x".repeat(Math.max(1, s.minLength ?? 1));
  };

  it("no operation lets another workspace read or change tenant A's data", async () => {
    const leaks: string[] = [];
    const secretsLeaked: string[] = [];
    let checked = 0;
    const statuses: Record<number, string[]> = {};
    // Operations anyone signed in may call on their own behalf; they never take A's ids.
    const own = new Set([
      "getMe",
      "listOrgs",
      "createOrg",
      "acceptInvite",
      "healthz",
      "readyz",
      "getConfig",
      "listPlans",
      "listTemplates",
      "exportMyData",
      "deleteMyAccount",
      "listNotifications",
      "markNotificationsRead",
      "registerDevice",
      "listMyDevices",
      "adminOverview",
      "adminUsers",
      "adminOrgs",
      "adminServices",
      "adminUpdates",
      // Text utilities with no tenant data (D-122).
      "getMemoryImportPrompt",
      "parseMemoryImport",
      // Device connections (D-149): keys live in the caller's own namespace, so B "saving" A's key
      // registers B's own device (device-data.test.ts proves A's device is untouched).
      "saveDeviceSource",
      "deleteDeviceSource",
      // Named places (D-151) are created in the caller's own list; device-triggers.test.ts checks isolation.
      "saveDevicePlace",
    ]);
    for (const [path, ops] of Object.entries(doc.paths)) {
      if (!path.startsWith("/v1/")) continue;
      for (const [method, op] of Object.entries(ops)) {
        if (own.has(op.operationId)) continue;
        const url = path.replace(/\{([^}]+)\}/g, (_, p: string) => idFor(path, p));
        const query = `?org_id=${ids.org}&bot_id=${ids.bot}&conversation_id=${ids.conversation}&path=x`;
        const schema = op.requestBody?.content["application/json"]?.schema;
        const res = await h.request(`${url}${query}`, {
          method: method.toUpperCase(),
          token: b.token,
          ...(schema
            ? { json: sample(schema) }
            : op.requestBody
              ? { body: "x", headers: { "content-type": "application/octet-stream" } }
              : {}),
        });
        const body = await res.text();
        checked++;
        statuses[res.status] = [...(statuses[res.status] ?? []), op.operationId];
        const aIds = [
          ids.bot,
          ids.conversation,
          ids.run,
          ids.routine,
          ids.secret,
          ids.integration,
          ids.computer,
          ids.device,
          ids.credential,
        ];
        if (res.status < 300) {
          // A 2xx is only acceptable when it reveals nothing of tenant A (for example an empty list).
          if (aIds.some((x) => x && body.includes(x)) || method !== "get")
            leaks.push(
              `${op.operationId} ${method.toUpperCase()} ${path} -> ${res.status} ${body.slice(0, 120)}`,
            );
        } else if (aIds.some((x) => x && body.includes(x) && !url.includes(x))) {
          leaks.push(`${op.operationId} error body mentions A's ids: ${body.slice(0, 120)}`);
        }
        if (/s3cret-tenant-a|sk-tenant-a-secret/.test(body)) secretsLeaked.push(op.operationId);
      }
    }
    // Most operations must reach the authorization check (not just fail validation).
    expect((statuses[403]?.length ?? 0) + (statuses[404]?.length ?? 0)).toBeGreaterThan(50);
    expect(checked).toBeGreaterThan(60);
    expect(secretsLeaked).toEqual([]);
    expect(leaks).toEqual([]);
    // Tenant A still has everything.
    const bots = (await j(await h.request(`/v1/bots?org_id=${ids.org}`, { token: a.token }))).items;
    expect(bots.find((x: { id: string }) => x.id === ids.bot)?.name).toBe("A bot");
    expect((await h.request(`/v1/secrets?org_id=${ids.org}`, { token: a.token })).status).toBe(200);
  }, 120_000);

  it("never returns secrets or model keys to their owner either", async () => {
    for (const path of [
      `/v1/credentials?org_id=${ids.org}`,
      `/v1/secrets?org_id=${ids.org}`,
      `/v1/integrations?org_id=${ids.org}`,
    ]) {
      const body = await (await h.request(path, { token: a.token })).text();
      expect(body).not.toMatch(/s3cret-tenant-a|sk-tenant-a-secret/);
    }
  });
});
