/**
 * Bots that change their own setup (D-242): connections (their own MCP servers, the workspace's
 * connections, plugins), the person's theme, their action rules, their knowledge and how often
 * they notify. Anything that widens what a bot can reach always asks the person first, whatever
 * its autonomy or rules; anything that only narrows it runs straight away. Billing, members,
 * keys, secrets, sharing and a bot's own autonomy or budget stay out of reach.
 */
import { randomUUID } from "node:crypto";
import { type Database, pgErrorCode } from "@casama/db";
import {
  APP_CATALOG,
  appByIdOrNull,
  CHAT_SERVER_LIMIT,
  customServerUrl,
  describeActionRule,
  isValidQuietHours,
  serverKey,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "../acting.ts";
import { wrapUntrusted } from "../context.ts";
import { ComputerMcpAdapter, managedComposioActive, refreshIntegration } from "../integrations.ts";
import { botComputerId, computerMcpFetch, syncPluginComputer } from "../plugins.ts";
import { leanSchema, type ToolContext, ToolError, type ToolRegistry } from "./registry.ts";
import { surfaceMessages } from "./ui.ts";

/** A name without case, spaces or punctuation: "Google Calendar" and google_calendar are the same. */
const plainName = (s: string) => s.toLowerCase().replace(/[^a-z0-9]/g, "");
/**
 * The built-in apps by id, for when connections.offer is asked for one it doesn't know. The name
 * is added only where the id doesn't already say it (atlassian is Jira & Confluence).
 */
const OFFER_APPS = APP_CATALOG.map((a) =>
  plainName(a.id) === plainName(a.name) ? a.id : `${a.id} (${a.name})`,
).join(", ");
/**
 * The apps nobody would find by name: "Jira & Confluence is atlassian, Zoho is zoho_apps". The
 * full list used to be in connections.offer's description, which goes out with every model call;
 * now only these are, and any other app is found by its name.
 */
const OFFER_ALIASES = APP_CATALOG.filter((a) => !plainName(a.name).startsWith(plainName(a.id)))
  .map((a) => `${a.name} is ${a.id}`)
  .join(", ");

/** A server outside the catalog, shown on a connect card (D-473). */
const OfferServer = z.object({
  name: z.string().min(1).max(60),
  url: z.string().max(2000).optional(),
  command: z.string().max(400).optional(),
});

const OfferArgs = z.object({
  apps: z.array(z.string().min(1).max(64)).max(4).optional(),
  servers: z.array(OfferServer).max(2).optional(),
  why: z.string().min(1).max(300).describe("One sentence for the person: what you'll do with it"),
});

/** A server's first answer that means "sign in first": 401, or the SDK's own words for it. */
const NEEDS_SIGN_IN = /\b401\b|unauthori[sz]ed|invalid_token/i;

/** mcp.find's answers, kept a day: the registry changes slowly and is someone else's server. */
const registryCache = new Map<string, { at: number; text: string }>();
const REGISTRY_URL = "https://registry.modelcontextprotocol.io";

interface RegistryEntry {
  server?: {
    name?: string;
    title?: string;
    description?: string;
    remotes?: Array<{ type?: string; url?: string; headers?: Array<{ isRequired?: boolean }> }>;
  };
  _meta?: Record<string, { status?: string; isLatest?: boolean } | undefined>;
}

/** The app's built-in looks (client/lib/theme/presets.dart). */
export const THEME_PRESETS = [
  "plain",
  "casama",
  "editorial",
  "ocean",
  "forest",
  "sakura",
  "sunset",
  "cosmos",
  "graphite",
] as const;

const NAME = z
  .string()
  .regex(/^[a-z][a-z0-9_]{0,30}$/, "lowercase letters, digits and _, starting with a letter");

/** A bot's own connection names end in its id, like plugin servers' (one name space per workspace). */
export const ownIntegrationName = (name: string, botId: string) =>
  `${name}_${botId.replaceAll("-", "").slice(0, 6)}`;

const McpAddArgs = z
  .object({
    name: NAME.describe("A short name for the server, e.g. linear or weather"),
    url: z
      .string()
      .url()
      .max(2000)
      .optional()
      .describe("A remote server's https address (Streamable HTTP, or legacy SSE ending in /sse)"),
    auth_value: z
      .string()
      .max(4000)
      .optional()
      .describe(
        "Remote only: the key or token, ideally as {{secret:NAME}} from the person's secrets (it must be allowed for the server's host)",
      ),
    auth_header: z
      .string()
      .regex(/^[A-Za-z0-9-]{1,60}$/)
      .optional()
      .describe("Remote only: the header for auth_value (default Authorization, sent as Bearer)"),
    command: z
      .string()
      .max(200)
      .optional()
      .describe("A server run on your computer over stdio, e.g. npx or uvx"),
    args: z.array(z.string().max(500)).max(40).default([]),
    env: z
      .record(z.string().regex(/^[A-Z_][A-Z0-9_]{0,63}$/), z.string().max(2000))
      .default({})
      .describe("Plain environment values for a computer server (no secrets)"),
    why: z.string().max(300).describe("One sentence for the person: what you'll use it for"),
  })
  .refine((a) => !!a.url !== !!a.command, "Give either url (remote) or command (on your computer)");

const RuleArgs = z.object({
  match_kind: z.enum(["tool", "group", "category"]),
  match_value: z
    .string()
    .min(1)
    .max(120)
    .describe(
      "A tool name (gmail.send_email), a group (gmail) or a category: send, pay, delete, publish, share, sign_in",
    ),
  rule: z
    .enum(["ask", "hand_off", "allow", "allow_within_limits"])
    .describe(
      "ask: ask first; hand_off: the person does it; allow: go ahead; allow_within_limits: go ahead within target",
    ),
  target: z
    .object({
      domains: z.array(z.string().max(200)).max(20).optional(),
      recipients: z.array(z.string().max(200)).max(20).optional(),
      max_amount: z.number().min(0).optional(),
    })
    .optional(),
});
const loosens = (rule: string) => rule === "allow" || rule === "allow_within_limits";

export function registerSettingsTools(
  registry: ToolRegistry,
  deps: {
    db: Database;
    fetch: typeof fetch;
    /** The gallery's apps (D-239), beyond the built-in catalog; the server supplies them. */
    galleryApps?: () => Promise<Array<{ id: string; name: string }>>;
    /** The public MCP registry mcp.find searches (D-473); tests point it at a fake. */
    registryUrl?: string;
  },
) {
  const { db } = deps;
  const audit = (ctx: ToolContext, action: string, type: string, id: string, meta: object) =>
    db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${ctx.orgId}::uuid, 'bot', ${ctx.botId}::uuid, ${action}, ${type}, ${id}::uuid, ${JSON.stringify(meta)}::jsonb)`);

  /** Shows a card whose button the app handles itself (an "app:" action); nothing comes back. */
  const card = async (
    ctx: ToolContext,
    o: { title: string; body: string; button: string; event: string; context: object },
  ) => {
    const surfaceId = `ui_${randomUUID().replaceAll("-", "").slice(0, 16)}`;
    const components = [
      { id: "root", component: "Card", child: "col" },
      { id: "col", component: "Column", children: ["title", "body", "go"] },
      { id: "title", component: "Text", text: `## ${o.title}` },
      { id: "body", component: "Text", text: o.body },
      {
        id: "go",
        component: "Button",
        child: "go_label",
        variant: "primary",
        action: { event: { name: o.event, context: o.context } },
      },
      { id: "go_label", component: "Text", text: o.button },
    ];
    await ctx.emit("ui.shown", {
      surface_id: surfaceId,
      messages: surfaceMessages(surfaceId, components),
    });
  };

  /** Lists a new connection's tools; a computer server runs on the bot's computer for this. */
  const listTools = async (ctx: ToolContext, id: string, kind: string, name: string) => {
    if (kind === "mcp") return refreshIntegration(db, id, { fetch: deps.fetch, secrets: [] });
    try {
      const computerId = await botComputerId(db, ctx.botId);
      if (!ctx.computer || !computerId) throw new Error("You need a computer to run this server.");
      const h = await ctx.computer();
      await syncPluginComputer(db, h, computerId);
      const adapter = new ComputerMcpAdapter(
        { id, org_id: ctx.orgId, kind: "computer_mcp", name, config: {}, secret: null },
        { fetch, secrets: [], computerMcp: async () => computerMcpFetch(h, name) },
      );
      try {
        const tools = await adapter.listTools();
        await db.execute(sql`
          update public.integrations set tools_cache = ${JSON.stringify(tools)}::jsonb, tools_cached_at = now(), status = 'ok', error = null
          where id = ${id}::uuid`);
        return { ok: true as const, tools };
      } finally {
        await adapter.close();
      }
    } catch (err) {
      const error = (err as Error).message.slice(0, 500);
      await db.execute(
        sql`update public.integrations set status = 'error', error = ${error} where id = ${id}::uuid`,
      );
      return { ok: false as const, error, tools: [] };
    }
  };

  // ------------------------------------------------------------------ connections

  registry.register({
    name: "connections.list",
    readOnly: true,
    description:
      "List the workspace's connections (apps, MCP servers, plugins) and which ones you can already use.",
    risk: "low",
    schema: z.object({}),
    async execute(_args, ctx) {
      const acting = await actingUserOf(db, ctx.runId);
      const rows = await db.execute<{
        name: string;
        kind: string;
        status: string;
        tools: number;
        mine: boolean;
        label: string | null;
      }>(sql`
        select i.name, i.kind, i.status, jsonb_array_length(coalesce(i.tools_cache, '[]'::jsonb))::int as tools,
               exists (select 1 from public.bot_integrations bi where bi.integration_id = i.id and bi.bot_id = ${ctx.botId}::uuid) as mine,
               coalesce(i.config ->> 'label', i.config ->> 'app') as label
        from public.integrations i
        where i.org_id = ${ctx.orgId}::uuid
          and (i.kind <> 'local_mcp' or coalesce(i.config ->> 'owner_user_id', '') in ('', ${acting ?? ""}))
          and (i.plugin_id is null or exists (select 1 from public.bot_integrations bi where bi.integration_id = i.id and bi.bot_id = ${ctx.botId}::uuid))
        order by i.name`);
      return {
        content:
          rows
            .map(
              (r) =>
                `- ${r.name}${r.label ? ` (${r.label})` : ""}: ${r.kind}, ${r.status}, ${r.tools} tools${r.mine ? ", yours" : ""}`,
            )
            .join("\n") ||
          "No connections yet. To get one, show the person a connect button with connections.offer; they sign in themselves.",
        preview: `${rows.length} connections`,
      };
    },
  });

  registry.register({
    name: "connections.attach",
    description:
      "Start using one of the workspace's connections (see connections.list), optionally only some of its tools. The person approves first. Its tools arrive from your next message.",
    risk: "high",
    alwaysAsk: true,
    sendsOut: true,
    schema: z.object({
      name: z.string().min(1).max(80),
      tools: z.array(z.string().max(200)).max(200).optional().describe("Only these tools"),
    }),
    async execute(args, ctx) {
      const acting = await actingUserOf(db, ctx.runId);
      const [i] = await db.execute<{ id: string; kind: string; owner: string | null }>(sql`
        select id, kind, config ->> 'owner_user_id' as owner from public.integrations
        where org_id = ${ctx.orgId}::uuid and name = ${args.name} and plugin_id is null`);
      if (!i) throw new ToolError("integration_not_found", `No connection named ${args.name}.`);
      if (i.kind === "local_mcp" && i.owner && i.owner !== acting)
        throw new ToolError(
          "forbidden",
          "That server runs on someone else's computer; only they can let you use it.",
        );
      const list = args.tools?.length
        ? `{${args.tools.map((t) => `"${t.replaceAll('"', "").replaceAll("\\", "")}"`).join(",")}}`
        : null;
      await db.execute(sql`
        insert into public.bot_integrations (org_id, bot_id, integration_id, tool_allowlist)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${i.id}::uuid, ${list}::text[])
        on conflict (bot_id, integration_id) do update set tool_allowlist = excluded.tool_allowlist`);
      await audit(ctx, "integration.attached_by_bot", "integration", i.id, { name: args.name });
      return {
        content: `You can use ${args.name}${args.tools?.length ? ` (${args.tools.length} tools)` : ""} from your next message.`,
        preview: `attached ${args.name}`,
      };
    },
  });

  registry.register({
    name: "mcp.add",
    description:
      "Add an MCP server for yourself: a remote one by its https url, or one run on your computer by command (for example npx -y some-mcp-server). The person approves first. Its tools arrive from your next message. A key goes in auth_value as {{secret:NAME}}; if there's none yet, ask for it with secrets.request first.",
    risk: "high",
    alwaysAsk: true,
    sendsOut: true,
    category: "sign_in",
    acceptsSecrets: true,
    destinationHost: (args) => {
      try {
        return args.url ? new URL(args.url).hostname : null;
      } catch {
        return null;
      }
    },
    schema: McpAddArgs,
    async execute(args, ctx) {
      if (args.url && !args.url.startsWith("https://"))
        throw new ToolError("bad_url", "Remote servers need an https address.");
      if (args.command && (args.auth_value || args.auth_header))
        throw new ToolError(
          "bad_args",
          "A server on your computer takes env values, not auth_value or auth_header.",
        );
      const computerId = args.command ? await botComputerId(db, ctx.botId) : null;
      if (args.command && (!computerId || !ctx.computer))
        throw new ToolError(
          "no_computer",
          "You need a computer to run a server by command; use a remote url instead.",
        );
      const name = ownIntegrationName(args.name, ctx.botId);
      const kind = args.command ? "computer_mcp" : "mcp";
      const config = args.command
        ? { server: args.name, command: args.command, args: args.args, env: args.env }
        : { url: args.url, ...(args.auth_header ? { auth_header: args.auth_header } : {}) };
      const acting = await actingUserOf(db, ctx.runId);
      let id: string;
      try {
        id = await db.transaction(async (tx) => {
          const [v] = args.auth_value
            ? await tx.execute<{ id: string }>(
                sql`select vault.create_secret(${args.auth_value}, null, ${`integration ${name}`}) as id`,
              )
            : [];
          const [row] = await tx.execute<{ id: string }>(sql`
            insert into public.integrations (org_id, kind, name, config, vault_secret_id, created_by)
            values (${ctx.orgId}::uuid, ${kind}, ${name},
                    ${JSON.stringify({ ...config, added_by_bot: ctx.botId })}::jsonb, ${v?.id ?? null}::uuid, ${acting}::uuid)
            returning id`);
          if (!row) throw new Error("integration insert returned nothing");
          await tx.execute(sql`
            insert into public.bot_integrations (org_id, bot_id, integration_id)
            values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${row.id}::uuid)`);
          return row.id;
        });
      } catch (err) {
        if (pgErrorCode(err) === "23505")
          throw new ToolError(
            "name_taken",
            `You already have a server named ${args.name}; remove it with mcp.remove or pick another name.`,
          );
        throw err;
      }
      await audit(ctx, "integration.created_by_bot", "integration", id, {
        kind,
        name,
        host: args.url ? new URL(args.url).hostname : null,
        command: args.command ?? null,
      });
      const r = await listTools(ctx, id, kind, name);
      // It wants a browser sign-in, which only the person can do (D-473): nothing dead is kept.
      if (!r.ok && kind === "mcp" && !args.auth_value && NEEDS_SIGN_IN.test(r.error)) {
        await db.execute(sql`delete from public.integrations where id = ${id}::uuid`);
        throw new ToolError(
          "needs_sign_in",
          `${args.name} needs the person to sign in, which you can't do for them. Show it with connections.offer: servers [{ name: "${args.name}", url: "${args.url}" }].`,
        );
      }
      if (!r.ok)
        return {
          content: `Added ${args.name}, but it didn't answer: ${r.error}. Fix it (mcp.remove, then mcp.add again) or tell the person.`,
          preview: `added ${args.name} (not answering)`,
        };
      const names = r.tools.map((t) => t.name);
      return {
        content: `Added ${args.name} with ${names.length} tools (${names.slice(0, 20).join(", ")}${names.length > 20 ? ", …" : ""}). They're yours from your next message.`,
        preview: `added ${args.name}`,
      };
    },
  });

  registry.register({
    name: "mcp.remove",
    description:
      "Stop using a connection. A server you added yourself is deleted; a workspace connection is only detached from you.",
    risk: "low",
    selfOnly: true,
    schema: z.object({ name: z.string().min(1).max(80) }),
    async execute(args, ctx) {
      const own = ownIntegrationName(args.name, ctx.botId);
      const [i] = await db.execute<{
        id: string;
        name: string;
        added_by: string | null;
        plugin_id: string | null;
        vault_secret_id: string | null;
      }>(sql`
        select i.id, i.name, i.config ->> 'added_by_bot' as added_by, i.plugin_id, i.vault_secret_id
        from public.integrations i join public.bot_integrations bi on bi.integration_id = i.id
        where i.org_id = ${ctx.orgId}::uuid and bi.bot_id = ${ctx.botId}::uuid and i.name in (${args.name}, ${own})
        order by (i.name = ${own}) desc limit 1`);
      if (!i) throw new ToolError("integration_not_found", `You aren't using ${args.name}.`);
      if (i.plugin_id)
        throw new ToolError(
          "plugin_server",
          "That server belongs to a plugin; the person removes plugins in your settings.",
        );
      if (i.added_by === ctx.botId) {
        await db.execute(sql`delete from public.integrations where id = ${i.id}::uuid`);
        if (i.vault_secret_id)
          await db.execute(sql`delete from vault.secrets where id = ${i.vault_secret_id}::uuid`);
      } else
        await db.execute(sql`
          delete from public.bot_integrations where bot_id = ${ctx.botId}::uuid and integration_id = ${i.id}::uuid`);
      await audit(ctx, "integration.removed_by_bot", "integration", i.id, { name: i.name });
      return {
        content: `${i.added_by === ctx.botId ? "Deleted" : "Detached"} ${args.name}.`,
        preview: `removed ${args.name}`,
      };
    },
  });

  registry.register({
    name: "plugins.suggest",
    description:
      "Suggest a plugin (a GitHub folder with plugin.json, e.g. https://github.com/owner/repo/tree/main/plugins/x): shows a card that opens its install screen, where the person reviews what it adds and enters any keys. You don't hear back; keep going.",
    risk: "low",
    readOnly: true,
    schema: z.object({
      url: z
        .string()
        .url()
        .max(500)
        .refine((u) => /^https:\/\/github\.com\/[^/]+\/[^/]+/.test(u), "a github.com address"),
      name: z.string().min(1).max(80),
      why: z.string().min(1).max(300),
    }),
    async execute(args, ctx) {
      await card(ctx, {
        title: `Add the ${args.name} plugin?`,
        body: `${args.why}\n\nYou'll see what it adds before anything is installed.`,
        button: "Review plugin",
        event: "app:route",
        context: { path: `/bots/${ctx.botId}/plugins?install=${encodeURIComponent(args.url)}` },
      });
      return {
        content:
          "The card is in the chat. The person installs it there if they want; its tools arrive in a later message.",
        preview: `suggested ${args.name}`,
      };
    },
  });

  // A connect button in any chat (D-259). Without it a bot asked to "connect Google" had no way to
  // do it and made up a request-from-your-admin step that doesn't exist.
  registry.register({
    name: "connections.offer",
    description: `Show a card with a sign-in button per app when the person wants to connect one, or you need an app whose tools you don't have. They sign in; you can't. Never say an app needs an admin: offer it here. Give app names or ids (gmail, cal-com); "Google" usually means google_calendar and gmail; ${OFFER_ALIASES}. An unknown app returns every id. Not built in: give servers, its MCP server's name and url (mcp.find finds one; no url if it holds a key) or a command for their computer. Once they say it's connected, connections.attach it if it isn't yours yet.`,
    risk: "low",
    readOnly: true,
    schema: OfferArgs,
    // Sent with every model call (a core tool), so without the string length limits.
    jsonSchema: leanSchema(OfferArgs),
    async execute(args, ctx) {
      const asked = args.servers ?? [];
      if (!args.apps?.length && !asked.length)
        throw new ToolError("bad_args", "Give apps, servers, or both.");
      // Built-in apps first; the gallery's only when one isn't built in (never replacing one).
      let gallery: Array<{ id: string; name: string; composio?: string }> | null = null;
      const fromGallery = async () => {
        gallery ??= deps.galleryApps ? await deps.galleryApps().catch(() => []) : [];
        return gallery;
      };
      const apps: Array<{ id: string; name: string; composio?: string }> = [];
      // Servers outside the catalog (D-473). One at a built-in app's address is that app.
      const servers: Array<{ name: string; url?: string; command?: string; args?: string[] }> = [];
      const alreadyServers: string[] = [];
      const mine = asked.length
        ? await db.execute<{ url: string | null }>(sql`
            select config ->> 'url' as url from public.integrations
            where org_id = ${ctx.orgId}::uuid and kind = 'mcp' and status <> 'error'
              and coalesce(config ->> 'url_in_secret', '') <> 'true'`)
        : [];
      const have = new Set(
        mine.flatMap((r) => {
          const u = r.url ? customServerUrl(r.url) : null;
          return u ? [serverKey(u)] : [];
        }),
      );
      for (const sv of asked) {
        if (sv.command) {
          if (sv.url) throw new ToolError("bad_args", "Give a server url or a command, not both.");
          // One command line ("npx -y some-server"): the app's form takes the words apart again.
          const [command, ...rest] = sv.command.trim().split(/\s+/);
          if (!command) throw new ToolError("bad_args", "Give the command to run.");
          servers.push({ name: sv.name, command, args: rest });
          continue;
        }
        if (!sv.url) {
          servers.push({ name: sv.name });
          continue;
        }
        const u = customServerUrl(sv.url);
        if (!u) throw new ToolError("bad_url", "A server needs an https address.");
        if (u.search)
          throw new ToolError(
            "bad_url",
            "That address has a key or other values after the ?. Offer the server without url, and the person types the address themselves, so the key stays out of the chat.",
          );
        const key = serverKey(u);
        const builtIn = APP_CATALOG.find((a) => {
          const au = a.provider ? null : customServerUrl(a.url);
          return au !== null && serverKey(au) === key;
        });
        if (builtIn) {
          if (!apps.some((a) => a.id === builtIn.id)) apps.push(builtIn);
        } else if (have.has(key)) alreadyServers.push(sv.name);
        else if (!servers.some((x) => x.url && serverKey(new URL(x.url)) === key))
          servers.push({ name: sv.name, url: u.toString() });
      }
      if (servers.some((x) => !x.command)) {
        const [count] = await db.execute<{ n: number }>(sql`
          select count(*)::int as n from public.integrations
          where org_id = ${ctx.orgId}::uuid and config ->> 'unverified' = 'true'`);
        if ((count?.n ?? 0) >= CHAT_SERVER_LIMIT)
          throw new ToolError(
            "server_limit",
            `This workspace already has ${CHAT_SERVER_LIMIT} servers added from chats. Ask the person to remove one in Settings, Apps first.`,
          );
      }
      for (const id of new Set(args.apps ?? [])) {
        // The exact id first. The description no longer lists the ids (it goes out with every
        // model call), so an app's name finds it too, and then its id written another way.
        const plain = plainName(id);
        const all = [...APP_CATALOG, ...(await fromGallery())];
        const app =
          appByIdOrNull(id) ??
          (await fromGallery()).find((a) => a.id === id) ??
          (plain
            ? (all.find((a) => plainName(a.name) === plain) ??
              all.find((a) => plainName(a.id) === plain))
            : undefined);
        if (!app) {
          const more = (await fromGallery()).map((a) => a.id);
          throw new ToolError(
            "unknown_app",
            `No app called ${id}. Use ids from: ${[OFFER_APPS, ...more].join(", ")}. For an app that isn't one of these, look for its MCP server with mcp.find and offer it as servers.`,
          );
        }
        if (!apps.some((a) => a.id === app.id)) apps.push(app);
      }
      const ids = apps.map((a) => a.id);
      const haveApps = ids.length
        ? await db.execute<{ app: string }>(sql`
        select distinct case when config ->> 'app' = 'gmail_inbox' then 'gmail' else config ->> 'app' end as app
        from public.integrations
        where org_id = ${ctx.orgId}::uuid and status <> 'error'
          and config ->> 'app' = any(${`{${[...ids, ...(ids.includes("gmail") ? ["gmail_inbox"] : [])].join(",")}}`}::text[])`)
        : [];
      const connected = new Set(haveApps.map((r) => r.app));
      // Google and the rest are often connected through the managed Composio route, which isn't
      // a per-app row; ask Composio so a connected Gmail doesn't get a Connect button.
      const viaComposio = apps.filter((a) => !connected.has(a.id) && a.composio);
      const active = await managedComposioActive(
        db,
        ctx.orgId,
        viaComposio.map((a) => a.composio as string),
        deps.fetch,
      );
      for (const a of viaComposio) if (active.has(a.composio as string)) connected.add(a.id);
      const fresh = [
        ...new Map(apps.filter((a) => !connected.has(a.id)).map((a) => [a.id, a])).values(),
      ];
      const already = [
        ...apps.filter((a) => connected.has(a.id)).map((a) => a.name),
        ...alreadyServers,
      ];
      const alreadyNote = already.length
        ? ` ${already.join(" and ")} ${already.length > 1 ? "are" : "is"} already connected in this workspace, so don't ask again: use its tools (tools.load them if they aren't loaded), or connections.list and connections.attach if you don't have them.`
        : "";
      if (!fresh.length && !servers.length)
        return { content: `No card shown.${alreadyNote}`, preview: "already connected" };
      const surfaceId = `ui_${randomUUID().replaceAll("-", "").slice(0, 16)}`;
      const buttons = fresh.flatMap((a, i) => [
        {
          id: `c_${a.id}`,
          component: "Button",
          child: `c_${a.id}_t`,
          variant: i === 0 ? "primary" : "default",
          action: { event: { name: "app:connect", context: { app: a.id } } },
        },
        { id: `c_${a.id}_t`, component: "Text", text: `Connect ${a.name}` },
      ]);
      // A server's button is an "app:route" with the server beside the path: app builds that know
      // it open the connect sheet right there, older ones open the screen where it can be added.
      const serverButtons = servers.flatMap((sv, i) => [
        {
          id: `s_${i}`,
          component: "Button",
          child: `s_${i}_t`,
          variant: i === 0 && !fresh.length ? "primary" : "default",
          action: {
            event: {
              name: "app:route",
              context: {
                path: sv.command ? "/settings/companion" : "/settings/integrations",
                server: sv,
                bot: ctx.botId,
              },
            },
          },
        },
        { id: `s_${i}_t`, component: "Text", text: `Connect ${sv.name}` },
      ]);
      const notes = servers.map((sv) =>
        sv.command
          ? `${sv.name} runs on your own computer (${[sv.command, ...(sv.args ?? [])].join(" ")}). Casama hasn't checked it.`
          : sv.url
            ? `${sv.name} is at ${new URL(sv.url).host}. Casama hasn't checked this server: connect it only if you trust it.`
            : `${sv.name}: you'll type its address. Casama hasn't checked this server.`,
      );
      const components = [
        { id: "root", component: "Card", child: "col" },
        {
          id: "col",
          component: "Column",
          children: ["body", ...(notes.length ? ["notes"] : []), "apps", "more"],
        },
        {
          id: "body",
          component: "Text",
          text: `${args.why}\n\nYou choose what I can do, and I ask before anything risky.`,
        },
        ...(notes.length ? [{ id: "notes", component: "Text", text: notes.join("\n\n") }] : []),
        {
          id: "apps",
          component: "Row",
          children: [...fresh.map((a) => `c_${a.id}`), ...servers.map((_, i) => `s_${i}`)],
        },
        ...buttons,
        ...serverButtons,
        {
          id: "more",
          component: "Button",
          child: "more_t",
          variant: "borderless",
          action: { event: { name: "app:route", context: { path: "/settings/integrations" } } },
        },
        { id: "more_t", component: "Text", text: "More apps" },
      ];
      await ctx.emit("ui.shown", {
        surface_id: surfaceId,
        messages: surfaceMessages(surfaceId, components),
      });
      for (const sv of servers)
        await db.execute(sql`
          insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, metadata)
          values (${ctx.orgId}::uuid, 'bot', ${ctx.botId}::uuid, 'integration.offered_by_bot', 'integration',
            ${JSON.stringify({ name: sv.name, host: sv.url ? new URL(sv.url).host : null, command: sv.command ?? null })}::jsonb)`);
      const names = [...fresh.map((a) => a.name), ...servers.map((sv) => sv.name)].join(" and ");
      return {
        content: `The card to connect ${names} is in the chat; end your turn and let them tap it.${alreadyNote}`,
        preview: `offered ${names}`,
      };
    },
  });

  // A server for an app that isn't built in (D-473): the public MCP registry, remote servers only.
  registry.register({
    name: "mcp.find",
    readOnly: true,
    description:
      "Look up a remote MCP server for an app that isn't built in, in the public MCP registry. Returns names and https addresses: show one to the person with connections.offer servers (they sign in or paste a key there), or mcp.add it when you already hold its key. Nobody at Casama checked these servers, so say whose server it is.",
    risk: "low",
    schema: z.object({ query: z.string().min(2).max(80).describe("The app or service's name") }),
    async execute(args) {
      const q = args.query.trim().toLowerCase();
      const hit = registryCache.get(q);
      if (hit && Date.now() - hit.at < 24 * 3_600_000)
        return { content: hit.text, preview: `servers for ${q}` };
      const base = (deps.registryUrl ?? REGISTRY_URL).replace(/\/$/, "");
      let entries: RegistryEntry[];
      try {
        const res = await deps.fetch(
          `${base}/v0/servers?search=${encodeURIComponent(q)}&version=latest&limit=50`,
          { headers: { accept: "application/json" }, signal: AbortSignal.timeout(15_000) },
        );
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        entries = ((await res.json()) as { servers?: RegistryEntry[] }).servers ?? [];
      } catch (err) {
        throw new ToolError(
          "registry_unreachable",
          `Couldn't reach the MCP registry (${(err as Error).message.slice(0, 120)}). If you know the server's address, offer it with connections.offer servers.`,
        );
      }
      const seen = new Set<string>();
      const lines: string[] = [];
      for (const e of entries) {
        const sv = e.server;
        const meta = Object.values(e._meta ?? {})[0];
        if (!sv?.name || meta?.status === "deleted" || meta?.isLatest === false) continue;
        for (const r of sv.remotes ?? []) {
          const u =
            r.url && !r.url.includes("{") && (r.type === "streamable-http" || r.type === "sse")
              ? customServerUrl(r.url)
              : null;
          if (u?.protocol !== "https:" || u.search) continue;
          const key = serverKey(u);
          if (seen.has(key) || lines.length >= 8) continue;
          seen.add(key);
          const needsKey = (r.headers ?? []).some((h) => h.isRequired);
          lines.push(
            `- ${(sv.title ?? sv.name).slice(0, 60)} (${sv.name.slice(0, 80)}): ${u.toString()}${needsKey ? " (needs a key)" : ""}. ${(sv.description ?? "").replace(/\s+/g, " ").slice(0, 160)}`,
          );
        }
      }
      const text = lines.length
        ? wrapUntrusted(
            "mcp registry",
            `${lines.join("\n")}\n\nThese come from the public MCP registry; anyone can list a server there. Prefer the one on the service's own domain.`,
          )
        : `No remote MCP server for "${args.query}" in the public registry. If the person knows its address, offer it with connections.offer servers.`;
      if (registryCache.size > 500) registryCache.clear();
      registryCache.set(q, { at: Date.now(), text });
      return { content: text, preview: `${lines.length} servers for ${q}` };
    },
  });

  // ------------------------------------------------------------------ appearance

  registry.register({
    name: "appearance.suggest",
    description: `Suggest a new look for the app: a card with an Apply button the person taps (it applies on their device only; you don't hear back). Looks: ${THEME_PRESETS.join(", ")}. Or a color scheme (casama, or a FlexScheme name such as blueWhale, jungle, sakura, mango, deepPurple, shadZinc), fonts (Google Fonts such as Inter, Fraunces, Playfair Display), light/dark mode and fewer effects.`,
    risk: "low",
    readOnly: true,
    schema: z
      .object({
        preset: z.enum(THEME_PRESETS).optional(),
        mode: z.enum(["light", "dark", "system"]).optional(),
        scheme: z
          .string()
          .regex(/^[A-Za-z0-9]{1,40}$/)
          .optional(),
        heading_font: z
          .string()
          .regex(/^[A-Za-z0-9 ]{1,60}$/)
          .optional(),
        body_font: z
          .string()
          .regex(/^[A-Za-z0-9 ]{1,60}$/)
          .optional(),
        fewer_effects: z.boolean().optional(),
        why: z.string().max(300).optional(),
      })
      .refine(
        (a) =>
          [a.preset, a.mode, a.scheme, a.heading_font, a.body_font, a.fewer_effects].some(
            (v) => v !== undefined,
          ),
        "Suggest at least one change",
      ),
    async execute(args, ctx) {
      const { why, ...look } = args;
      const parts = [
        look.preset ? `the ${look.preset[0]?.toUpperCase()}${look.preset.slice(1)} look` : null,
        look.mode ? `${look.mode === "system" ? "system" : look.mode} mode` : null,
        look.scheme ? `${look.scheme} colors` : null,
        look.heading_font ? `${look.heading_font} headings` : null,
        look.body_font ? `${look.body_font} text` : null,
        look.fewer_effects === true
          ? "fewer effects"
          : look.fewer_effects === false
            ? "effects on"
            : null,
      ].filter(Boolean);
      await card(ctx, {
        title: "Try a new look?",
        body: `${why ? `${why}\n\n` : ""}${parts.join(", ")}. You can change it back in Settings → Appearance.`,
        button: "Apply",
        event: "app:appearance",
        context: look,
      });
      return {
        content: "The card is in the chat; the person applies it there if they like it.",
        preview: "suggested a look",
      };
    },
  });

  // ------------------------------------------------------------------ action rules

  registry.register({
    name: "rules.list",
    readOnly: true,
    description: "List the action rules that apply to you (yours and the workspace's).",
    risk: "low",
    schema: z.object({}),
    async execute(_args, ctx) {
      const rows = await db.execute<{
        id: string;
        bot_id: string | null;
        match_kind: "tool" | "group" | "category";
        match_value: string;
        target: { domains?: string[]; recipients?: string[]; max_amount?: number } | null;
        rule: "allow" | "allow_within_limits" | "ask" | "hand_off";
      }>(sql`
        select id, bot_id, match_kind, match_value, target, rule from public.action_rules
        where org_id = ${ctx.orgId}::uuid and (bot_id is null or bot_id = ${ctx.botId}::uuid)
        order by bot_id nulls first, match_kind, match_value`);
      return {
        content:
          rows
            .map(
              (r) =>
                `- ${r.id.slice(0, 8)}: ${describeActionRule(r)}${r.bot_id ? "" : " (workspace)"}`,
            )
            .join("\n") || "No rules.",
        preview: `${rows.length} rules`,
      };
    },
  });

  registry.register({
    name: "rules.add",
    description:
      "Add an action rule for yourself. ask and hand_off (more careful) apply straight away; allow and allow_within_limits (fewer questions) always need the person's approval.",
    risk: "low",
    riskFor: (a) => (loosens(a.rule) ? "high" : "low"),
    alwaysAskFor: (a) => loosens(a.rule),
    schema: RuleArgs,
    async execute(args, ctx) {
      if (args.rule === "allow_within_limits" && !args.target)
        throw new ToolError("limits_required", "Give the limits in target.");
      if (
        args.match_kind === "category" &&
        !["send", "pay", "delete", "publish", "share", "sign_in"].includes(args.match_value)
      )
        throw new ToolError(
          "unknown_category",
          "Pick send, pay, delete, publish, share or sign_in.",
        );
      // Pay and sign-in steps keep their own checks: a bot never waves them through itself.
      if (
        loosens(args.rule) &&
        args.match_kind === "category" &&
        ["pay", "sign_in"].includes(args.match_value)
      )
        throw new ToolError(
          "not_allowed",
          "Payments and sign-ins can't be allowed by a bot; the person sets that in your settings.",
        );
      const acting = await actingUserOf(db, ctx.runId);
      const [row] = await db.execute<{ id: string }>(sql`
        insert into public.action_rules (org_id, bot_id, match_kind, match_value, target, rule, created_by)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${args.match_kind}, ${args.match_value},
                ${args.target ? JSON.stringify(args.target) : null}::jsonb, ${args.rule}, ${acting}::uuid)
        returning id`);
      const text = describeActionRule({ ...args, target: args.target ?? null });
      await audit(ctx, "action_rule.created_by_bot", "action_rule", row?.id as string, {
        preview: text,
      });
      return { content: `Rule added: ${text}.`, preview: text };
    },
  });

  registry.register({
    name: "rules.remove",
    description:
      "Remove one of your own action rules (id from rules.list). Removing an ask or hand_off rule needs the person's approval.",
    risk: "low",
    schema: z.object({
      id: z.string().min(8).max(36),
      rule: z
        .enum(["ask", "hand_off", "allow", "allow_within_limits"])
        .describe("The rule's kind, as rules.list shows it"),
    }),
    // Removing a careful rule means fewer questions; removing an allow rule means more.
    riskFor: (a) => (loosens(a.rule) ? "low" : "high"),
    alwaysAskFor: (a) => !loosens(a.rule),
    async execute(args, ctx) {
      const [r] = await db.execute<{ id: string; rule: string }>(sql`
        select id, rule from public.action_rules
        where org_id = ${ctx.orgId}::uuid and bot_id = ${ctx.botId}::uuid and id::text like ${`${args.id}%`}`);
      if (!r) throw new ToolError("rule_not_found", "No rule of yours with that id.");
      // The approval was for the kind given; a different kind is refused rather than slipping by.
      if (r.rule !== args.rule)
        throw new ToolError("rule_mismatch", `That rule is ${r.rule}; call again with that.`);
      await db.execute(sql`delete from public.action_rules where id = ${r.id}::uuid`);
      await audit(ctx, "action_rule.deleted_by_bot", "action_rule", r.id, {});
      return { content: "Rule removed.", preview: "rule removed" };
    },
  });

  // ------------------------------------------------------------------ knowledge

  registry.register({
    name: "knowledge.add",
    description:
      "Add a website or a GitHub repository to your knowledge, read and kept up to date in the background; search it with knowledge.search once it's ready.",
    risk: "medium",
    schema: z
      .object({
        name: z.string().min(1).max(120),
        url: z.string().url().max(2000).optional().describe("A website to read"),
        max_pages: z.number().int().min(1).max(200).optional(),
        repo_url: z
          .string()
          .max(500)
          .optional()
          .describe("https://github.com/owner/repo[/tree/ref/path]"),
      })
      .refine((a) => !!a.url !== !!a.repo_url, "Give either url or repo_url"),
    async execute(args, ctx) {
      let kind: "website" | "github";
      let config: Record<string, unknown>;
      if (args.url) {
        const u = new URL(args.url);
        if (!/^https?:$/.test(u.protocol))
          throw new ToolError("bad_url", "Websites need an http or https address.");
        kind = "website";
        config = { url: u.href, max_pages: args.max_pages ?? 50 };
      } else {
        const m =
          /^https:\/\/github\.com\/([^/]+)\/([^/#?]+?)(?:\.git)?(?:\/tree\/([^/]+)(?:\/(.+))?)?\/?$/.exec(
            args.repo_url ?? "",
          );
        if (!m) throw new ToolError("bad_url", "Give a github.com repository address.");
        kind = "github";
        config = { owner: m[1], repo: m[2], path: m[4] ?? "", ref: m[3] ?? undefined };
      }
      const acting = await actingUserOf(db, ctx.runId);
      const [row] = await db.execute<{ id: string }>(sql`
        insert into public.knowledge_sources (org_id, bot_id, kind, name, config, created_by)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${kind}, ${args.name}, ${JSON.stringify(config)}::jsonb, ${acting}::uuid)
        returning id`);
      await audit(ctx, "knowledge.added_by_bot", "knowledge_source", row?.id as string, { kind });
      return {
        content: `Added ${args.name}. It's being read now; knowledge.search finds it once it's ready (knowledge.list shows progress).`,
        preview: `added ${args.name}`,
      };
    },
  });

  registry.register({
    name: "knowledge.list",
    readOnly: true,
    description: "List your knowledge sources and the workspace's, with their status.",
    risk: "low",
    schema: z.object({}),
    async execute(_args, ctx) {
      const rows = await db.execute<{
        name: string;
        kind: string;
        status: string;
        documents: number;
        bot_id: string | null;
      }>(sql`
        select name, kind, status, documents, bot_id from public.knowledge_sources
        where org_id = ${ctx.orgId}::uuid and (bot_id is null or bot_id = ${ctx.botId}::uuid)
        order by bot_id nulls last, created_at`);
      return {
        content:
          rows
            .map(
              (r) =>
                `- ${r.name}: ${r.kind}, ${r.status}, ${r.documents} documents${r.bot_id ? "" : " (workspace)"}`,
            )
            .join("\n") || "No knowledge sources.",
        preview: `${rows.length} sources`,
      };
    },
  });

  registry.register({
    name: "knowledge.remove",
    description: "Remove one of your own knowledge sources by name.",
    risk: "low",
    selfOnly: true,
    schema: z.object({ name: z.string().min(1).max(120) }),
    async execute(args, ctx) {
      const rows = await db.execute<{ id: string }>(sql`
        delete from public.knowledge_sources
        where org_id = ${ctx.orgId}::uuid and bot_id = ${ctx.botId}::uuid and name = ${args.name}
        returning id`);
      if (!rows[0])
        throw new ToolError(
          "not_found",
          `You have no knowledge source named ${args.name} (workspace sources are the admins').`,
        );
      return { content: `Removed ${args.name}.`, preview: `removed ${args.name}` };
    },
  });

  // ------------------------------------------------------------------ notifications

  registry.register({
    name: "notifications.quiet",
    description:
      "Change when you may notify the person you're working for: quiet (never notify them; messages still arrive in the chat), custom quiet hours (start/end, their local time), or default (their usual quiet hours). Quieter applies straight away; louder needs their approval.",
    risk: "low",
    schema: z.object({
      quiet: z.enum(["always", "custom", "default"]),
      start: z
        .string()
        .regex(/^([01]\d|2[0-3]):[0-5]\d$/)
        .optional(),
      end: z
        .string()
        .regex(/^([01]\d|2[0-3]):[0-5]\d$/)
        .optional(),
    }),
    // Going back to the person's usual hours can mean more notifications.
    alwaysAskFor: (a) => a.quiet === "default",
    async execute(args, ctx) {
      const user = await actingUserOf(db, ctx.runId);
      if (!user)
        throw new ToolError(
          "no_person",
          "This run isn't for one person, so there's no one to quiet for.",
        );
      const hours =
        args.quiet === "custom" ? { enabled: true, start: args.start, end: args.end } : null;
      if (args.quiet === "custom" && !isValidQuietHours(hours))
        throw new ToolError("bad_hours", "Give start and end as HH:MM, and not the same time.");
      await db.execute(sql`
        insert into public.user_bot_settings (user_id, bot_id, quiet, quiet_hours, updated_at)
        values (${user}::uuid, ${ctx.botId}::uuid, ${args.quiet}, ${hours ? JSON.stringify(hours) : null}::jsonb, now())
        on conflict (user_id, bot_id) do update set quiet = excluded.quiet, quiet_hours = excluded.quiet_hours, updated_at = now()`);
      const said =
        args.quiet === "always"
          ? "You won't notify them; your messages still show in the chat."
          : args.quiet === "custom"
            ? `Quiet from ${args.start} to ${args.end}, their time.`
            : "Back to their usual quiet hours.";
      return { content: said, preview: `notifications: ${args.quiet}` };
    },
  });
}
