/**
 * Linked agents (D-143), the API side: invites, accepting (on this server, or on another Kasama
 * server through a token handshake), listing, revoking, and each link's exchanges. Requests between
 * servers arrive at the A2A endpoint with the link's token (routes/a2a.ts).
 */
import { createHash, randomBytes } from "node:crypto";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { hashLinkToken, newLinkToken } from "@kasama/agent";
import { routes } from "@kasama/contracts";
import { type JwtClaims, withUserSession } from "@kasama/db";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

const hashCode = (c: string) => createHash("sha256").update(c).digest("hex");
const INVITE_PREFIX = "kasama-link:";

type Row = {
  id: string;
  bot_id: string;
  org_id: string;
  owner_user_id: string;
  name: string;
  status: "pending";
  peer_link_id: string | null;
  peer_bot_name: string | null;
  remote_url: string | null;
  exchanges: number;
  created_at: string;
  activated_at: string | null;
};

export function registerLinkRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const base = (c: { req: { url: string } }) => (deps.env.PUBLIC_API_URL ?? new URL(c.req.url).origin).replace(/\/$/, "");
  const f = () => deps.apps?.fetch ?? fetch;
  const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
    const claims = c.get("claims");
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    return claims;
  };
  const myBot = async (claims: JwtClaims, botId: string) => {
    const [b] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ org_id: string; name: string; manage: boolean }>(sql`select org_id, name, public.can_manage_bot(id) as manage from public.bots where id = ${botId}::uuid and archived_at is null`),
    );
    if (!b) throw new ApiError(404, "bot_not_found", "Bot not found");
    if (!b.manage) throw new ApiError(403, "forbidden", "Only people who manage this bot can link it");
    return b;
  };
  const cols = sql`l.id, l.bot_id, l.org_id, l.owner_user_id, l.name, l.status, l.peer_link_id, l.peer_bot_name, l.remote_url,
    (select count(*)::int from public.link_exchanges e where e.link_id = l.id) as exchanges, l.created_at, l.activated_at`;
  const one = async (id: string) => (await db.execute<Row>(sql`select ${cols} from public.bot_links l where l.id = ${id}::uuid`))[0];
  const out = (r: Row) => ({
    id: r.id,
    bot_id: r.bot_id,
    name: r.name,
    status: r.status,
    peer_bot_name: r.peer_bot_name,
    remote_url: r.remote_url,
    exchanges: r.exchanges,
    created_at: iso(r.created_at),
    activated_at: r.activated_at ? iso(r.activated_at) : null,
  });

  app.openapi(routes.listBotLinks, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const rows = await withUserSession(db, claims, (tx) => tx.execute<Row>(sql`select ${cols} from public.bot_links l where l.bot_id = ${id}::uuid order by l.created_at desc`));
    return c.json({ items: rows.map(out) }, 200);
  });

  app.openapi(routes.createBotLink, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const { name } = c.req.valid("json");
    const b = await myBot(claims, id);
    const code = randomBytes(18).toString("base64url");
    const [row] = await db.execute<{ id: string }>(sql`
      insert into public.bot_links (org_id, bot_id, owner_user_id, name, invite_code_hash, invite_expires_at)
      values (${b.org_id}::uuid, ${id}::uuid, ${claims.sub}::uuid, ${name}, ${hashCode(code)}, now() + interval '7 days') returning id`);
    const invite = INVITE_PREFIX + Buffer.from(JSON.stringify({ s: base(c), l: row?.id, c: code, b: b.name })).toString("base64url");
    return c.json({ ...out((await one(row?.id as string)) as Row), invite }, 201);
  });

  /** Claims a pending invite on this server: checks the code and expiry, then activates it. */
  const claim = async (linkId: string, code: string) => {
    const [l] = await db.execute<{ id: string; bot_id: string; name: string; bot_name: string; ok: boolean }>(sql`
      update public.bot_links l set status = 'active', invite_code_hash = null, activated_at = now()
      from public.bots b
      where l.id = ${linkId}::uuid and b.id = l.bot_id and l.status = 'pending' and l.invite_code_hash = ${hashCode(code)} and l.invite_expires_at > now()
      returning l.id, l.bot_id, l.name, b.name as bot_name, true as ok`);
    return l ?? null;
  };

  app.openapi(routes.acceptBotLink, async (c) => {
    const claims = claimsOf(c);
    const body = c.req.valid("json");
    const b = await myBot(claims, body.bot_id);
    let inv: { s: string; l: string; c: string; b: string };
    try {
      if (!body.invite.startsWith(INVITE_PREFIX)) throw new Error();
      inv = JSON.parse(Buffer.from(body.invite.slice(INVITE_PREFIX.length), "base64url").toString());
      if (!/^[0-9a-f-]{36}$/.test(inv.l) || typeof inv.c !== "string") throw new Error();
    } catch {
      throw new ApiError(400, "bad_invite", "That isn't a Kasama link invite");
    }
    const [local] = await db.execute<{ bot_id: string }>(sql`select bot_id from public.bot_links where id = ${inv.l}::uuid`);
    if (local) {
      // Same server: two rows that point at each other.
      if (local.bot_id === body.bot_id) throw new ApiError(409, "same_bot", "A bot can't link with itself");
      const [mine] = await db.execute<{ id: string }>(sql`
        insert into public.bot_links (org_id, bot_id, owner_user_id, name, status, peer_link_id, peer_bot_name, activated_at)
        values (${b.org_id}::uuid, ${body.bot_id}::uuid, ${claims.sub}::uuid, ${body.name}, 'pending', ${inv.l}::uuid, ${inv.b}, null) returning id`);
      const theirs = await claim(inv.l, inv.c);
      if (!theirs) {
        await db.execute(sql`delete from public.bot_links where id = ${mine?.id}::uuid`);
        throw new ApiError(409, "invite_used", "This invite was already used or has expired");
      }
      await db.execute(sql`update public.bot_links set peer_link_id = ${mine?.id}::uuid, peer_bot_name = ${b.name} where id = ${inv.l}::uuid`);
      await db.execute(sql`update public.bot_links set status = 'active', activated_at = now() where id = ${mine?.id}::uuid`);
      return c.json(out((await one(mine?.id as string)) as Row), 201);
    }
    // Another Kasama server: swap per-link tokens; requests then go over A2A.
    const inbound = newLinkToken();
    const [mine] = await db.execute<{ id: string }>(sql`
      insert into public.bot_links (org_id, bot_id, owner_user_id, name, peer_link_id, peer_bot_name, remote_url, inbound_token_hash)
      values (${b.org_id}::uuid, ${body.bot_id}::uuid, ${claims.sub}::uuid, ${body.name}, ${inv.l}::uuid, ${inv.b}, ${inv.s.replace(/\/$/, "")}, ${hashLinkToken(inbound)}) returning id`);
    let res: Response | null = null;
    try {
      res = await f()(`${inv.s.replace(/\/$/, "")}/links/${inv.l}/accept`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ code: inv.c, peer_url: base(c), peer_link_id: mine?.id, peer_bot_id: body.bot_id, peer_bot_name: b.name, token: inbound }),
      });
    } catch {}
    if (!res?.ok) {
      await db.execute(sql`delete from public.bot_links where id = ${mine?.id}::uuid`);
      throw new ApiError(409, "invite_used", res ? "This invite was already used or has expired" : "Couldn't reach your contact's Kasama server");
    }
    const r = (await res.json()) as { token: string; bot_id: string; bot_name: string };
    await db.execute(sql`
      update public.bot_links set status = 'active', activated_at = now(), peer_bot_id = ${r.bot_id}, peer_bot_name = ${r.bot_name},
        outbound_secret_id = (select vault.create_secret(${r.token}, null, 'link token'))
      where id = ${mine?.id}::uuid`);
    return c.json(out((await one(mine?.id as string)) as Row), 201);
  });

  // Server to server: the other Kasama server accepts our invite.
  app.post("/links/:id/accept", async (c) => {
    const id = c.req.param("id");
    const b = (await c.req.json().catch(() => null)) as { code?: string; peer_url?: string; peer_link_id?: string; peer_bot_id?: string; peer_bot_name?: string; token?: string } | null;
    if (!/^[0-9a-f-]{36}$/.test(id) || !b?.code || !b.token?.startsWith("klink_") || !/^https?:\/\//.test(b.peer_url ?? "")) return c.json({ error: "bad_request" }, 400);
    const l = await claim(id, b.code);
    if (!l) return c.json({ error: "invite_used" }, 409);
    const ours = newLinkToken();
    await db.execute(sql`
      update public.bot_links set remote_url = ${(b.peer_url as string).replace(/\/$/, "")}, peer_link_id = ${b.peer_link_id ?? null}::uuid, peer_bot_id = ${b.peer_bot_id ?? null},
        peer_bot_name = ${b.peer_bot_name ?? null}, outbound_secret_id = (select vault.create_secret(${b.token}, null, 'link token')), inbound_token_hash = ${hashLinkToken(ours)}
      where id = ${id}::uuid`);
    return c.json({ token: ours, bot_id: l.bot_id, bot_name: l.bot_name });
  });

  // Server to server: the other side revoked.
  app.post("/links/:id/revoke", async (c) => {
    const id = c.req.param("id");
    const tok = (c.req.header("authorization") ?? "").replace(/^Bearer\s+/i, "");
    if (!/^[0-9a-f-]{36}$/.test(id) || !tok.startsWith("klink_")) return c.json({}, 400);
    const [r] = await db.execute<{ id: string }>(sql`
      update public.bot_links set status = 'revoked', revoked_at = now() where id = ${id}::uuid and inbound_token_hash = ${hashLinkToken(tok)} returning id`);
    return c.json({ revoked: !!r }, r ? 200 : 404);
  });

  app.openapi(routes.revokeBotLink, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const [l] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string; peer_link_id: string | null; remote_url: string | null; token: string | null }>(sql`select id, peer_link_id, remote_url, null::text as token from public.bot_links where id = ${id}::uuid`),
    );
    if (!l) throw new ApiError(404, "link_not_found", "Link not found");
    const [tok] = await db.execute<{ token: string | null }>(sql`
      select v.decrypted_secret as token from public.bot_links l left join vault.decrypted_secrets v on v.id = l.outbound_secret_id where l.id = ${id}::uuid`);
    await db.execute(sql`update public.bot_links set status = 'revoked', revoked_at = now(), invite_code_hash = null where id = ${id}::uuid`);
    // Either side's revoke ends the link for both.
    if (l.remote_url && l.peer_link_id && tok?.token)
      await f()(`${l.remote_url}/links/${l.peer_link_id}/revoke`, { method: "POST", headers: { authorization: `Bearer ${tok.token}` } }).catch(() => {});
    else if (l.peer_link_id) await db.execute(sql`update public.bot_links set status = 'revoked', revoked_at = now() where id = ${l.peer_link_id}::uuid`);
    return c.json(out((await one(id)) as Row), 200);
  });

  app.openapi(routes.listLinkExchanges, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string; direction: "out"; request: string; response: string | null; status: "answered"; created_at: string }>(sql`
        select id, direction, request, response, status, created_at from public.link_exchanges where link_id = ${id}::uuid order by created_at desc limit 100`),
    );
    return c.json({ items: rows.map((r) => ({ ...r, created_at: iso(r.created_at) })) }, 200);
  });
}
