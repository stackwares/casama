/**
 * Chat apps (D-134): connect Telegram, email, SMS, Slack, WhatsApp, Messenger, Feishu or iMessage
 * to a bot. Secrets go to Vault and are never returned. Providers post to /hooks/channels/:id; each
 * request is checked with the provider's signature before anything happens.
 */
import { randomBytes } from "node:crypto";
import { ADAPTERS, handleInbound, loadChannel, track } from "@casama/agent";
import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

/** What each kind needs before it can work. */
const REQUIRED: Record<string, { secrets: string[]; config: string[] }> = {
  telegram: { secrets: ["bot_token"], config: [] },
  email: { secrets: ["api_key", "signing_secret"], config: ["address"] },
  sms: { secrets: ["account_sid", "auth_token"], config: ["phone_number"] },
  slack: { secrets: ["bot_token", "signing_secret"], config: [] },
  whatsapp: { secrets: ["access_token", "app_secret"], config: ["phone_number_id"] },
  messenger: { secrets: ["page_token", "app_secret"], config: [] },
  feishu: { secrets: ["app_secret", "encrypt_key", "verification_token"], config: ["app_id"] },
  imessage: { secrets: [], config: ["computer_id"] },
};

type Row = {
  id: string;
  bot_id: string;
  kind: "telegram";
  name: string;
  config: Record<string, unknown>;
  allowed_senders: string[];
  enabled: boolean;
  last_inbound_at: string | null;
  last_error: string | null;
  created_at: string;
};

export function registerChannelRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const fetchOut = () => deps.apps?.fetch ?? fetch;
  const base = (c: { req: { url: string } }) =>
    (deps.env.PUBLIC_API_URL ?? new URL(c.req.url).origin).replace(/\/$/, "");
  const out = (c: { req: { url: string } }, r: Row, verifyToken: string | null = null) => ({
    ...r,
    webhook_url: r.kind === ("imessage" as string) ? null : `${base(c)}/hooks/channels/${r.id}`,
    verify_token: verifyToken,
    last_inbound_at: r.last_inbound_at ? iso(r.last_inbound_at) : null,
    created_at: iso(r.created_at),
  });
  const cols = sql`id, bot_id, kind, name, config, allowed_senders, enabled, last_inbound_at, last_error, created_at`;

  const bot = async (claims: JwtClaims, id: string) => {
    const [b] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ org_id: string; manage: boolean }>(sql`
        select org_id, public.can_manage_bot(id) as manage from public.bots where id = ${id}::uuid and archived_at is null`),
    );
    if (!b) throw new ApiError(404, "bot_not_found", "Bot not found");
    return b;
  };
  const channel = async (claims: JwtClaims, id: string, manage = true) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<Row>(sql`select ${cols} from public.channels where id = ${id}::uuid`),
    );
    if (!r) throw new ApiError(404, "channel_not_found", "Chat app not found");
    if (manage) {
      const b = await bot(claims, r.bot_id);
      if (!b.manage)
        throw new ApiError(
          403,
          "forbidden",
          "Only people who manage this bot can change its chat apps",
        );
    }
    return r;
  };

  app.openapi(routes.listChannels, async (c) => {
    const claims = claimsOf(c);
    const { bot_id } = c.req.valid("query");
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<Row>(
        sql`select ${cols} from public.channels where bot_id = ${bot_id}::uuid order by created_at`,
      ),
    );
    return c.json({ items: rows.map((r) => out(c, r)) }, 200);
  });

  app.openapi(routes.createChannel, async (c) => {
    const claims = claimsOf(c);
    const body = c.req.valid("json");
    const b = await bot(claims, body.bot_id);
    if (!b.manage)
      throw new ApiError(403, "forbidden", "Only people who manage this bot can connect chat apps");
    const config: Record<string, unknown> = { ...(body.config ?? {}) };
    const secrets: Record<string, string> = { ...(body.secrets ?? {}) };
    const need = REQUIRED[body.kind] ?? { secrets: [], config: [] };
    const missing = [
      ...need.secrets.filter((k) => !secrets[k]),
      ...need.config.filter((k) => !config[k]),
    ];
    if (missing.length)
      throw new ApiError(400, "validation_failed", `${body.kind} needs: ${missing.join(", ")}`);
    if (body.kind === "imessage") {
      const [own] = await db.execute<{ id: string }>(sql`
        select id from public.local_devices where computer_id::text = ${String(config.computer_id)} and user_id = ${claims.sub}::uuid and platform = 'macos' and enabled`);
      if (!own)
        throw new ApiError(
          400,
          "validation_failed",
          "iMessage needs one of your own Macs connected as a computer",
        );
    }
    if (body.kind === "telegram") secrets.webhook_secret = randomBytes(24).toString("hex");
    let verifyToken: string | null = null;
    if (body.kind === "whatsapp" || body.kind === "messenger")
      secrets.verify_token = verifyToken = randomBytes(16).toString("hex");
    const [row] = await db.execute<Row>(sql`
      insert into public.channels (org_id, bot_id, kind, name, config, vault_secret_id, allowed_senders, created_by)
      values (${b.org_id}::uuid, ${body.bot_id}::uuid, ${body.kind}, ${body.name}, ${JSON.stringify(config)}::jsonb,
              ${Object.keys(secrets).length ? sql`(select vault.create_secret(${JSON.stringify(secrets)}, null, 'chat app'))` : sql`null`},
              array(select jsonb_array_elements_text(${JSON.stringify(body.allowed_senders.map((s) => s.trim()))}::jsonb)), ${claims.sub}::uuid)
      returning ${cols}`);
    const r = row as Row;
    // Telegram: point the bot's webhook here, with the secret Telegram echoes back on every call.
    if (body.kind === "telegram") {
      const api = String(config.api_base ?? "https://api.telegram.org").replace(/\/$/, "");
      try {
        const res = await fetchOut()(`${api}/bot${secrets.bot_token}/setWebhook`, {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({
            url: `${base(c)}/hooks/channels/${r.id}`,
            secret_token: secrets.webhook_secret,
            allowed_updates: ["message"],
          }),
        });
        if (!res.ok) throw new Error(`Telegram answered ${res.status}`);
      } catch (e) {
        r.last_error = `Couldn't set the Telegram webhook: ${(e as Error).message}`;
        await db.execute(
          sql`update public.channels set last_error = ${r.last_error} where id = ${r.id}::uuid`,
        );
      }
    }
    track(db, {
      event: "chat_app_connected",
      userId: claims.sub,
      orgId: b.org_id,
      properties: { channel: body.kind },
    });
    return c.json(out(c, r, verifyToken), 201);
  });

  app.openapi(routes.updateChannel, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    await channel(claims, id);
    const [r] = await db.execute<Row>(sql`
      update public.channels set
        name = coalesce(${body.name ?? null}, name),
        enabled = coalesce(${body.enabled ?? null}::boolean, enabled),
        allowed_senders = case when ${body.allowed_senders ? 1 : 0} = 1
          then array(select jsonb_array_elements_text(${JSON.stringify((body.allowed_senders ?? []).map((s) => s.trim()))}::jsonb)) else allowed_senders end
      where id = ${id}::uuid returning ${cols}`);
    return c.json(out(c, r as Row), 200);
  });

  app.openapi(routes.deleteChannel, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    await channel(claims, id);
    await db.execute(sql`
      with gone as (delete from public.channels where id = ${id}::uuid returning vault_secret_id)
      delete from vault.secrets where id in (select vault_secret_id from gone)`);
    return c.json({ deleted: id }, 200);
  });

  app.openapi(routes.listChannelEvents, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<{
        id: string;
        direction: "in";
        status: "accepted";
        sender: string | null;
        preview: string | null;
        detail: string | null;
        created_at: string;
      }>(sql`
        select id, direction, status, sender, preview, detail, created_at from public.channel_events
        where channel_id = ${id}::uuid order by created_at desc limit 100`),
    );
    return c.json({ items: rows.map((r) => ({ ...r, created_at: iso(r.created_at) })) }, 200);
  });

  // Provider webhooks. Handshakes answer setup checks; everything else must carry a valid signature.
  const hook = async (c: {
    req: {
      param(k: string): string;
      method: string;
      url: string;
      raw: Request;
      text(): Promise<string>;
    };
  }) => {
    const id = c.req.param("id");
    if (!/^[0-9a-f-]{36}$/.test(id))
      return new Response(JSON.stringify({ code: "not_found" }), { status: 404 });
    const ch = await loadChannel(db, id);
    if (!ch || ch.kind === "imessage")
      return new Response(JSON.stringify({ code: "not_found" }), { status: 404 });
    const adapter = ADAPTERS[ch.kind];
    const headers: Record<string, string> = {};
    c.req.raw.headers.forEach((v, k) => {
      headers[k.toLowerCase()] = v;
    });
    // Behind a proxy the URL the provider signed is the public one.
    const u = new URL(c.req.url);
    const url = deps.env.PUBLIC_API_URL
      ? `${deps.env.PUBLIC_API_URL.replace(/\/$/, "")}${u.pathname}${u.search}`
      : c.req.url;
    const req = {
      method: c.req.method,
      url,
      headers,
      body: c.req.method === "GET" ? "" : await c.req.text(),
    };
    const hs = adapter.handshake?.(req, ch.config, ch.secrets);
    if (hs)
      return new Response(hs.body, { status: hs.status, headers: { "content-type": hs.type } });
    if (c.req.method !== "POST")
      return new Response(JSON.stringify({ code: "not_found" }), { status: 404 });
    if (!adapter.verify(req, ch.config, ch.secrets))
      return new Response(
        JSON.stringify({ code: "bad_signature", message: "Signature doesn't match" }),
        { status: 401, headers: { "content-type": "application/json" } },
      );
    const messages = adapter.normalize(req, ch.config);
    const { startRoutineForMessage } = await import("../../worker/routines.ts");
    const runIds = await handleInbound(db, ch, messages, {
      startRoutine: (rid, text) => startRoutineForMessage(db, rid, text),
    });
    for (const r of runIds) await deps.workflows.startRun(r);
    // SMS (Twilio) wants TwiML; an empty response means "no reply now" — replies go out through the API.
    if (ch.kind === "sms")
      return new Response("<Response></Response>", {
        status: 200,
        headers: { "content-type": "text/xml" },
      });
    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  };
  app.post("/hooks/channels/:id", (c) => hook(c));
  app.get("/hooks/channels/:id", (c) => hook(c));
}
