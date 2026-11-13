/**
 * Chat apps (D-134): connect Telegram, email, SMS, Slack, WhatsApp, Messenger, Feishu or iMessage
 * to a bot. Secrets go to Vault and are never returned. Providers post to /hooks/channels/:id; each
 * request is checked with the provider's signature before anything happens.
 */
import { createHmac, randomBytes, timingSafeEqual } from "node:crypto";
import {
  ADAPTERS,
  type ChannelRow,
  decideFromChannel,
  handleInbound,
  loadChannel,
  senderAllowed,
  track,
} from "@casama/agent";
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
  // D-278. Teams: the Azure bot's app id and password. Discord: the application's id, its public
  // key (signatures) and the bot token (replies after the 15-minute interaction window).
  teams: { secrets: ["app_password"], config: ["app_id"] },
  discord: { secrets: ["bot_token"], config: ["application_id", "public_key"] },
  // D-285: the tracker user that stands for the bot (assign issues to it), a key to comment with,
  // and the webhook's signing secret.
  linear: { secrets: ["api_key", "webhook_secret"], config: ["assignee_id"] },
  jira: {
    secrets: ["api_token", "webhook_secret"],
    config: ["site_url", "email", "assignee_account_id"],
  },
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
    const raw = {
      method: c.req.method,
      url,
      headers,
      body: c.req.method === "GET" ? "" : await c.req.text(),
    };
    // The signature covers the body as sent; handshakes and parsing read the decrypted one (D-270).
    const req = adapter.decode?.(raw, ch.config, ch.secrets) ?? raw;
    const hs = adapter.handshake?.(req, ch.config, ch.secrets);
    if (hs)
      return new Response(hs.body, { status: hs.status, headers: { "content-type": hs.type } });
    if (c.req.method !== "POST")
      return new Response(JSON.stringify({ code: "not_found" }), { status: 404 });
    const verified = adapter.verifyAsync
      ? await adapter.verifyAsync(raw, ch.config, ch.secrets, fetchOut())
      : adapter.verify(raw, ch.config, ch.secrets);
    if (!verified)
      return new Response(
        JSON.stringify({ code: "bad_signature", message: "Signature doesn't match" }),
        { status: 401, headers: { "content-type": "application/json" } },
      );
    return inbound(ch, req);
  };

  /** A verified webhook's messages: runs for them, and a sign they arrived (D-277). */
  const inbound = async (
    ch: ChannelRow,
    req: { method: string; url: string; headers: Record<string, string>; body: string },
  ) => {
    const adapter = ADAPTERS[ch.kind];
    let messages = adapter.normalize(req, ch.config);
    if (adapter.enrich)
      messages = await adapter.enrich(messages, ch.config, ch.secrets, fetchOut());
    const { startRoutineForMessage } = await import("../../worker/routines.ts");
    const runIds = await handleInbound(db, ch, messages, {
      startRoutine: (rid, text) => startRoutineForMessage(db, rid, text),
    });
    for (const r of runIds) await deps.workflows.startRun(r);
    if (adapter.acknowledge && ch.enabled)
      for (const m of messages)
        if (senderAllowed(ch.allowed_senders, m.sender))
          await adapter.acknowledge(ch.config, ch.secrets, m, fetchOut()).catch(() => {});
    // Discord expects its own answer (PING, or "thinking…" while the bot works).
    const custom = adapter.respond?.(req);
    if (custom)
      return new Response(custom.body, {
        status: custom.status,
        headers: { "content-type": custom.type },
      });
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

  /** An Approve or Deny press from a chat app (D-277): decided, the run woken, the message updated. */
  const act = async (
    ch: ChannelRow,
    raw: { method: string; url: string; headers: Record<string, string>; body: string },
  ) => {
    const adapter = ADAPTERS[ch.kind];
    const action = adapter.parseAction?.(raw);
    if (!action) return new Response("", { status: 200 });
    const r = await decideFromChannel(db, ch, action);
    if (r.ok) await deps.workflows.signalRun(r.runId);
    const text = r.ok
      ? `${r.decision === "approved" ? "Approved" : "Denied"} by <@${action.sender}>.`
      : r.reason;
    if (action.responseUrl)
      await fetchOut()(action.responseUrl, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(
          r.ok
            ? { replace_original: true, text }
            : { response_type: "ephemeral", replace_original: false, text },
        ),
      }).catch(() => {});
    return new Response("", { status: 200 });
  };

  const rawOf = async (c: {
    req: { method: string; url: string; raw: Request; text(): Promise<string> };
  }) => {
    const headers: Record<string, string> = {};
    c.req.raw.headers.forEach((v, k) => {
      headers[k.toLowerCase()] = v;
    });
    const u = new URL(c.req.url);
    const url = deps.env.PUBLIC_API_URL
      ? `${deps.env.PUBLIC_API_URL.replace(/\/$/, "")}${u.pathname}${u.search}`
      : c.req.url;
    return { method: c.req.method, url, headers, body: await c.req.text() };
  };

  // A self-hosted Slack app's interactivity address (each channel has its own).
  app.post("/hooks/channels/:id/interact", async (c) => {
    const id = c.req.param("id");
    const ch = /^[0-9a-f-]{36}$/.test(id) ? await loadChannel(db, id) : null;
    if (!ch || !ADAPTERS[ch.kind].parseAction)
      return new Response(JSON.stringify({ code: "not_found" }), { status: 404 });
    const raw = await rawOf(c);
    if (!ADAPTERS[ch.kind].verify(raw, ch.config, ch.secrets))
      return new Response(JSON.stringify({ code: "bad_signature" }), { status: 401 });
    return act(ch, raw);
  });

  // ---------------------------------------------------------------- Casama's own Slack app (D-277)
  const slackApi = (deps.env.SLACK_API_BASE ?? "https://slack.com").replace(/\/$/, "");
  const stateKey = () => deps.env.INTERNAL_TOKEN ?? deps.env.SLACK_CLIENT_SECRET ?? "";
  const signState = (payload: Record<string, unknown>) => {
    const body = Buffer.from(JSON.stringify(payload)).toString("base64url");
    const mac = createHmac("sha256", stateKey()).update(body).digest("base64url");
    return `${body}.${mac}`;
  };
  const readState = (state: string) => {
    const [body, mac] = state.split(".");
    if (!body || !mac || !stateKey()) return null;
    const want = createHmac("sha256", stateKey()).update(body).digest("base64url");
    if (want.length !== mac.length || !timingSafeEqual(Buffer.from(want), Buffer.from(mac)))
      return null;
    const p = JSON.parse(Buffer.from(body, "base64url").toString()) as {
      bot_id: string;
      user_id: string;
      exp: number;
    };
    return p.exp > Date.now() ? p : null;
  };
  const slackOn = () =>
    !!(deps.env.SLACK_CLIENT_ID && deps.env.SLACK_CLIENT_SECRET && deps.env.SLACK_SIGNING_SECRET);

  app.openapi(routes.startSlackInstall, async (c) => {
    const claims = claimsOf(c);
    const { bot_id } = c.req.valid("query");
    if (!slackOn())
      throw new ApiError(
        409,
        "slack_unavailable",
        "This server has no Slack app. Connect your own with a bot token instead.",
      );
    const b = await bot(claims, bot_id);
    if (!b.manage)
      throw new ApiError(403, "forbidden", "Only people who manage this bot can connect chat apps");
    const state = signState({ bot_id, user_id: claims.sub, exp: Date.now() + 15 * 60_000 });
    const q = new URLSearchParams({
      client_id: deps.env.SLACK_CLIENT_ID as string,
      scope: "app_mentions:read,chat:write,im:history,im:read,reactions:write,users:read",
      redirect_uri: `${base(c)}/hooks/slack/oauth`,
      state,
    });
    return c.json({ url: `${slackApi}/oauth/v2/authorize?${q}` }, 200);
  });

  app.get("/hooks/slack/oauth", async (c) => {
    const page = (title: string, text: string, status = 200) =>
      c.html(
        `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>${title}</title><body style="font:16px system-ui;max-width:32rem;margin:15vh auto;padding:0 1rem"><h1>${title}</h1><p>${text}</p></body>`,
        status as 200,
      );
    const st = readState(c.req.query("state") ?? "");
    const code = c.req.query("code");
    if (!slackOn() || !st || !code)
      return page(
        "That didn't work",
        "The Slack sign-in link expired or wasn't Casama's. Start again from the bot's chat apps.",
        400,
      );
    const res = await fetchOut()(`${slackApi}/api/oauth.v2.access`, {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        code,
        client_id: deps.env.SLACK_CLIENT_ID as string,
        client_secret: deps.env.SLACK_CLIENT_SECRET as string,
        redirect_uri: `${base(c)}/hooks/slack/oauth`,
      }),
    }).catch(() => null);
    const t = (res?.ok ? await res.json().catch(() => ({})) : {}) as {
      ok?: boolean;
      access_token?: string;
      bot_user_id?: string;
      team?: { id?: string; name?: string };
      authed_user?: { id?: string };
    };
    if (!t.ok || !t.access_token || !t.team?.id)
      return page("That didn't work", "Slack didn't finish the sign-in. Try again.", 400);
    const [b] = await db.execute<{ org_id: string }>(
      sql`select org_id from public.bots where id = ${st.bot_id}::uuid and archived_at is null`,
    );
    if (!b) return page("That didn't work", "That bot no longer exists.", 404);
    const secrets = JSON.stringify({ bot_token: t.access_token });
    const config = JSON.stringify({
      team_id: t.team.id,
      team_name: t.team.name ?? null,
      bot_user_id: t.bot_user_id ?? null,
      app: "casama",
      ...(deps.env.SLACK_API_BASE ? { api_base: slackApi } : {}),
    });
    // One Casama bot per Slack workspace through Casama's app: installing again moves it.
    await db.execute(sql`
      delete from public.channels where kind = 'slack' and config ->> 'app' = 'casama' and config ->> 'team_id' = ${t.team.id}`);
    await db.execute(sql`
      insert into public.channels (org_id, bot_id, kind, name, config, vault_secret_id, allowed_senders, created_by)
      values (${b.org_id}::uuid, ${st.bot_id}::uuid, 'slack', ${`Slack: ${t.team.name ?? t.team.id}`.slice(0, 100)}, ${config}::jsonb,
              (select vault.create_secret(${secrets}, null, 'chat app')),
              ${t.authed_user?.id ? sql`array[${t.authed_user.id}]::text[]` : sql`'{}'::text[]`}, ${st.user_id}::uuid)`);
    return page(
      "Slack is connected",
      "Mention the bot in a channel, or message it directly. You can add more people who may talk to it in the bot's chat apps. You can close this page.",
    );
  });

  /** The channel Casama's Slack app routes a team's events to. */
  const slackChannelFor = async (teamId: string) => {
    const [r] = await db.execute<{ id: string }>(sql`
      select id from public.channels where kind = 'slack' and config ->> 'app' = 'casama'
        and config ->> 'team_id' = ${teamId} order by created_at desc limit 1`);
    const ch = r ? await loadChannel(db, r.id) : null;
    // Casama's app signs with its own secret, not a per-channel one.
    return ch
      ? {
          ...ch,
          secrets: { ...ch.secrets, signing_secret: deps.env.SLACK_SIGNING_SECRET as string },
        }
      : null;
  };
  const appSecrets = () => ({ signing_secret: deps.env.SLACK_SIGNING_SECRET ?? "" });

  app.post("/hooks/slack/events", async (c) => {
    if (!slackOn()) return new Response(JSON.stringify({ code: "not_found" }), { status: 404 });
    const raw = await rawOf(c);
    if (!ADAPTERS.slack.verify(raw, {}, appSecrets()))
      return new Response(JSON.stringify({ code: "bad_signature" }), { status: 401 });
    const hs = ADAPTERS.slack.handshake?.(raw, {}, appSecrets());
    if (hs)
      return new Response(hs.body, { status: hs.status, headers: { "content-type": hs.type } });
    let team = "";
    try {
      team = String((JSON.parse(raw.body) as { team_id?: string }).team_id ?? "");
    } catch {}
    const ch = team ? await slackChannelFor(team) : null;
    if (!ch) return new Response(JSON.stringify({ ok: true }), { status: 200 });
    return inbound(ch, raw);
  });

  app.post("/hooks/slack/interact", async (c) => {
    if (!slackOn()) return new Response(JSON.stringify({ code: "not_found" }), { status: 404 });
    const raw = await rawOf(c);
    if (!ADAPTERS.slack.verify(raw, {}, appSecrets()))
      return new Response(JSON.stringify({ code: "bad_signature" }), { status: 401 });
    let team = "";
    try {
      const p = JSON.parse(new URLSearchParams(raw.body).get("payload") ?? "{}") as {
        team?: { id?: string };
      };
      team = String(p.team?.id ?? "");
    } catch {}
    const ch = team ? await slackChannelFor(team) : null;
    if (!ch) return new Response("", { status: 200 });
    return act(ch, raw);
  });
}
