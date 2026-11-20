/**
 * Hosted bot mail (BOT-EMAIL-PLAN): claim `name@<mail domain>` for a bot, pause, move and release
 * it, and POST /hooks/mail where the mail Worker posts what arrives. Requests run in the caller's
 * session; the hook is signed with the Worker's shared secret instead.
 */
import { createHash, randomUUID } from "node:crypto";
import {
  baseSubject,
  ClaimMailError,
  claimBotMailAddress,
  cloudflareAuthResults,
  handleInbound,
  isAutomaticMail,
  loadChannel,
  type ParsedMail,
  parsedToInbound,
  parseMime,
  replySubject,
  senderAllowed,
  senderCheckFrom,
  track,
  verifyMailHook,
} from "@casama/agent";
import { routes } from "@casama/contracts";
import { contentKeys, type JwtClaims, withUserSession } from "@casama/db";
import {
  likeEscape,
  mailNameIssue,
  pgTextArray,
  splitMailTag,
  suggestMailNames,
} from "@casama/domain";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { mailReservedNames } from "../../services/mail-reserved-names.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";
import { isInstanceOwner } from "./admin.ts";

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

type AddressRow = {
  id: string;
  bot_id: string;
  channel_id: string;
  local_part: string;
  status: "active" | "paused" | "retired";
  created_at: string;
};

/** Senders refused at the door and the new-sender bell, both kept on the channel's config. */
const blockedOf = (config: unknown): string[] =>
  Array.isArray((config as { blocked_senders?: unknown })?.blocked_senders)
    ? (config as { blocked_senders: unknown[] }).blocked_senders.filter(
        (s): s is string => typeof s === "string",
      )
    : [];
const notifyNewOf = (config: unknown): boolean =>
  (config as { notify_new_senders?: unknown })?.notify_new_senders === true;

export function registerMailRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const isOwner = isInstanceOwner(deps);
  const fetchOut = () => deps.apps?.fetch ?? fetch;

  const bot = async (claims: JwtClaims, id: string) => {
    const [b] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ org_id: string; manage: boolean; name: string }>(sql`
        select org_id, public.can_manage_bot(id) as manage, name from public.bots
        where id = ${id}::uuid and archived_at is null`),
    );
    if (!b) throw new ApiError(404, "bot_not_found", "Bot not found");
    return b;
  };
  const out = (domain: string, r: AddressRow, config: unknown) => ({
    ...r,
    address: `${r.local_part}@${domain}`,
    blocked_senders: blockedOf(config),
    notify_new_senders: notifyNewOf(config),
    created_at: iso(r.created_at),
  });
  const channelConfig = async (channelId: string) => {
    const [r] = await db.execute<{ config: unknown }>(
      sql`select config from public.channels where id = ${channelId}::uuid`,
    );
    return r?.config ?? {};
  };

  // Read-modify-write of the blocked list under the channel row's lock, so two changes at once
  // can't drop each other's sender.
  const updateBlocked = (channelId: string, change: (list: string[]) => string[]) =>
    db.transaction(async (tx) => {
      const [r] = await tx.execute<{ config: unknown }>(
        sql`select config from public.channels where id = ${channelId}::uuid for update`,
      );
      const next = change(blockedOf(r?.config ?? {}));
      await tx.execute(sql`
        update public.channels
        set config = jsonb_set(coalesce(config, '{}'::jsonb), '{blocked_senders}', ${JSON.stringify(next)}::jsonb)
        where id = ${channelId}::uuid`);
    });

  app.openapi(routes.claimMailAddress, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    const mail = deps.hostedMail;
    if (!mail) throw new ApiError(400, "hosted_mail_unavailable", "This server has no mail domain");
    const b = await bot(claims, id);
    try {
      const row = await claimBotMailAddress(
        {
          db,
          domain: mail.domain,
          sender: mail.sender,
          sendPaused: mail.sendPaused,
          fetch: fetchOut(),
          logger: deps.logger,
          extraReserved: await mailReservedNames(db),
        },
        {
          orgId: b.org_id,
          botId: id,
          botName: b.name,
          name: body.name,
          claimerUserId: claims.sub,
          manage: b.manage,
          surface: body.surface ?? "profile",
          instanceOwner: await isOwner(claims).catch(() => false),
        },
      );
      return c.json(out(mail.domain, row, await channelConfig(row.channel_id)), 201);
    } catch (e) {
      if (e instanceof ClaimMailError) throw new ApiError(e.status, e.code, e.message);
      throw e;
    }
  });

  app.openapi(routes.getMailAddress, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const mail = deps.hostedMail;
    if (!mail) throw new ApiError(400, "hosted_mail_unavailable", "This server has no mail domain");
    const b = await bot(claims, id);
    if (!b.manage)
      throw new ApiError(403, "forbidden", "Only people who manage this bot can see its address");
    const [row] = await db.execute<AddressRow>(sql`
      select id, bot_id, channel_id, local_part, status, created_at from public.mail_addresses
      where bot_id = ${id}::uuid and status in ('active', 'paused')`);
    if (!row) throw new ApiError(404, "address_not_found", "This bot has no address");
    return c.json(out(mail.domain, row, await channelConfig(row.channel_id)), 200);
  });

  app.openapi(routes.checkMailName, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const { name: raw } = c.req.valid("query");
    const mail = deps.hostedMail;
    if (!mail) throw new ApiError(400, "hosted_mail_unavailable", "This server has no mail domain");
    const b = await bot(claims, id);
    if (!b.manage)
      throw new ApiError(403, "forbidden", "Only people who manage this bot can claim addresses");
    void b;
    const name = raw.trim().toLowerCase();
    const extraReserved = await mailReservedNames(db);
    const owner = await isOwner(claims).catch(() => false);
    const issue = mailNameIssue(name, extraReserved, { instanceOwner: owner });
    // Alternatives from the requested name (the sheet calls this with the bot's name first).
    const candidates = [
      ...new Set([name, ...suggestMailNames(name, null, () => false, extraReserved, 10)]),
    ];
    const takenRows = await db.execute<{ local_part: string }>(sql`
      select local_part from public.mail_addresses where local_part = any(${pgTextArray(candidates)}::text[])`);
    const taken = new Set(takenRows.map((r) => r.local_part));
    return c.json(
      {
        name,
        available: !issue && !taken.has(name),
        issue: issue ?? (taken.has(name) ? "That name is taken." : null),
        suggestions: candidates.filter((n) => n !== name && !taken.has(n)).slice(0, 3),
      },
      200,
    );
  });

  app.openapi(routes.updateMailAddress, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    const mail = deps.hostedMail;
    if (!mail) throw new ApiError(400, "hosted_mail_unavailable", "This server has no mail domain");
    const b = await bot(claims, id);
    if (!b.manage)
      throw new ApiError(
        403,
        "forbidden",
        "Only people who manage this bot can change its address",
      );
    const [row] = await db.execute<AddressRow & { auto_paused_at: string | null }>(sql`
      update public.mail_addresses
      set status = coalesce(${body.status ?? null}, status), updated_at = now()
      where bot_id = ${id}::uuid and status in ('active', 'paused')
        and (auto_paused_at is null or ${body.status ?? null} is distinct from 'active')
      returning id, bot_id, channel_id, local_part, status, created_at, auto_paused_at`);
    if (!row) {
      const [auto] = await db.execute<{ id: string }>(sql`
        select id from public.mail_addresses
        where bot_id = ${id}::uuid and auto_paused_at is not null`);
      if (auto && body.status === "active")
        throw new ApiError(
          403,
          "forbidden",
          "This address was paused automatically. Only the instance owner can lift the pause, from Admin.",
        );
      throw new ApiError(404, "address_not_found", "This bot has no live address");
    }
    if (body.notify_new_senders !== undefined)
      await db.execute(sql`
        update public.channels
        set config = jsonb_set(coalesce(config, '{}'::jsonb), '{notify_new_senders}', ${JSON.stringify(body.notify_new_senders)}::jsonb)
        where id = ${row.channel_id}::uuid`);
    return c.json(out(mail.domain, row, await channelConfig(row.channel_id)), 200);
  });

  app.openapi(routes.moveMailAddress, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    const mail = deps.hostedMail;
    if (!mail) throw new ApiError(400, "hosted_mail_unavailable", "This server has no mail domain");
    const b = await bot(claims, id);
    if (!b.manage)
      throw new ApiError(403, "forbidden", "Only people who manage this bot can move its address");
    const target = await bot(claims, body.to_bot_id);
    if (target.org_id !== b.org_id)
      throw new ApiError(400, "validation_failed", "Addresses move within a workspace only");
    if (!target.manage)
      throw new ApiError(
        403,
        "forbidden",
        "Only people who manage the other bot can take the address",
      );
    if (body.to_bot_id === id)
      throw new ApiError(400, "validation_failed", "The address is already on this bot");
    // One transaction: the address, its channel and its chats move together or not at all.
    const row = await db.transaction(async (tx) => {
      await tx.execute(sql`select pg_advisory_xact_lock(hashtext(${`mail_address:${b.org_id}`}))`);
      const [busy] = await tx.execute<{ id: string }>(sql`
        select id from public.mail_addresses
        where bot_id = ${body.to_bot_id}::uuid and status in ('active', 'paused')`);
      if (busy) throw new ApiError(409, "address_exists", "The other bot already has an address");
      const [moved] = await tx.execute<AddressRow>(sql`
        update public.mail_addresses set bot_id = ${body.to_bot_id}::uuid, updated_at = now()
        where bot_id = ${id}::uuid and status in ('active', 'paused')
        returning id, bot_id, channel_id, local_part, status, created_at`);
      if (!moved) throw new ApiError(404, "address_not_found", "This bot has no live address");
      // The channel and its chats move with the address; the mail rows already key on it. The
      // person moving it (who manages both bots) becomes who it acts for and who hears about it.
      await tx.execute(sql`
        update public.channels set bot_id = ${body.to_bot_id}::uuid, created_by = ${claims.sub}::uuid
        where id = ${moved.channel_id}::uuid`);
      await tx.execute(sql`
        update public.conversations set bot_id = ${body.to_bot_id}::uuid where id in
          (select conversation_id from public.channel_threads where channel_id = ${moved.channel_id}::uuid)`);
      return moved;
    });
    return c.json(out(mail.domain, row, await channelConfig(row.channel_id)), 200);
  });

  app.openapi(routes.releaseMailAddress, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const mail = deps.hostedMail;
    if (!mail) throw new ApiError(400, "hosted_mail_unavailable", "This server has no mail domain");
    const b = await bot(claims, id);
    if (!b.manage)
      throw new ApiError(
        403,
        "forbidden",
        "Only people who manage this bot can release its address",
      );
    const row = await db.transaction(async (tx) => {
      await tx.execute(sql`select pg_advisory_xact_lock(hashtext(${`mail_address:${b.org_id}`}))`);
      const [live] = await tx.execute<AddressRow & { auto_paused_at: string | null }>(sql`
        select id, bot_id, channel_id, local_part, status, created_at, auto_paused_at
        from public.mail_addresses
        where bot_id = ${id}::uuid and status in ('active', 'paused')`);
      if (!live) throw new ApiError(404, "address_not_found", "This bot has no live address");
      if (live.auto_paused_at)
        throw new ApiError(
          403,
          "forbidden",
          "This address was paused automatically. Only the instance owner can lift or clear it from Admin.",
        );
      // Releasing always works; the claims-a-year cap keeps name cycling slow (claim-mail.ts).
      const [updated] = await tx.execute<AddressRow>(sql`
        update public.mail_addresses set status = 'retired', released_at = now(), updated_at = now()
        where id = ${live.id}::uuid
        returning id, bot_id, channel_id, local_part, status, created_at`);
      await tx.execute(
        sql`update public.channels set enabled = false where id = ${live.channel_id}::uuid`,
      );
      await tx.execute(sql`
        update public.mail_messages set expires_at = now() + interval '30 days'
        where address_id = ${live.id}::uuid and expires_at is null`);
      return updated!;
    });
    return c.json(out(mail.domain, row, await channelConfig(row.channel_id)), 200);
  });

  const mailRow = (r: MailRowOut) => ({
    id: r.id,
    direction: r.direction,
    from_addr: r.from_addr,
    from_name: r.from_name,
    to_tag: r.to_tag,
    subject: r.subject,
    snippet: mailSnippet(r.content),
    verdict: r.verdict,
    sender_check: r.sender_check,
    has_files: (Array.isArray(r.files) ? r.files.length : 0) > 0,
    file_count: Array.isArray(r.files) ? r.files.length : 0,
    size: Number(r.size),
    conversation_id: r.conversation_id,
    created_at: iso(r.created_at),
  });

  app.openapi(routes.listMailMessages, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const q = c.req.valid("query");
    const mail = deps.hostedMail;
    if (!mail) throw new ApiError(400, "hosted_mail_unavailable", "This server has no mail domain");
    const b = await bot(claims, id);
    if (!b.manage)
      throw new ApiError(403, "forbidden", "Only people who manage this bot can read its mail");
    // Retired addresses stay readable until the purge deletes their mail.
    const [a] = await db.execute<{ id: string }>(sql`
      select id from public.mail_addresses where bot_id = ${id}::uuid order by created_at desc limit 1`);
    if (!a) throw new ApiError(404, "address_not_found", "This bot has no address");
    const limit = Math.min(q.limit ?? 50, 100);
    let cursorAt: string | null = null;
    let cursorId: string | null = null;
    // Garbage cursors start from the top instead of 500ing on the cast.
    if (q.cursor && /^[0-9a-f-]{36}$/i.test(q.cursor)) {
      const [cur] = await db.execute<{ created_at: string }>(
        sql`select created_at from public.mail_messages where id = ${q.cursor}::uuid and address_id = ${a.id}::uuid`,
      );
      if (cur) {
        cursorAt = cur.created_at;
        cursorId = q.cursor;
      }
    }
    const rows = await db.execute<MailRowOut>(sql`
      select id, direction, from_addr, from_name, to_tag, subject, content, verdict, sender_check,
             files, size, conversation_id, created_at
      from public.mail_messages where address_id = ${a.id}::uuid
        ${q.verdict ? sql`and verdict = ${q.verdict}` : sql``}
        ${q.tag ? sql`and lower(to_tag) = lower(${q.tag})` : sql``}
        ${q.sender ? sql`and from_addr ilike ${`%${likeEscape(q.sender)}%`}` : sql``}
        ${q.q ? sql`and subject ilike ${`%${likeEscape(q.q)}%`}` : sql``}
        ${cursorAt && cursorId ? sql`and (created_at, id) < (${cursorAt}::timestamptz, ${cursorId}::uuid)` : sql``}
      order by created_at desc, id desc limit ${limit + 1}`);
    const items = rows.slice(0, limit);
    return c.json(
      {
        items: items.map(mailRow),
        next_cursor: rows.length > limit ? (items[items.length - 1]?.id ?? null) : null,
      },
      200,
    );
  });

  app.openapi(routes.getMailMessage, async (c) => {
    const claims = claimsOf(c);
    const { id, messageId } = c.req.valid("param");
    const mail = deps.hostedMail;
    if (!mail) throw new ApiError(400, "hosted_mail_unavailable", "This server has no mail domain");
    const b = await bot(claims, id);
    if (!b.manage)
      throw new ApiError(403, "forbidden", "Only people who manage this bot can read its mail");
    const [r] = await db.execute<MailRowOut>(sql`
      select m.id, m.direction, m.from_addr, m.from_name, m.to_tag, m.subject, m.content, m.verdict,
             m.sender_check, m.files, m.size, m.conversation_id, m.created_at
      from public.mail_messages m join public.mail_addresses a on a.id = m.address_id
      where m.id = ${messageId}::uuid and a.bot_id = ${id}::uuid`);
    if (!r) throw new ApiError(404, "message_not_found", "No such mail");
    const files = Array.isArray(r.files) ? r.files : [];
    return c.json(
      {
        ...mailRow(r),
        text: mailFullText(r.content),
        files: files.map((f: unknown, i: number) => {
          const m = (f ?? {}) as { name?: unknown; mime?: unknown; size?: unknown };
          return {
            index: i,
            name: typeof m.name === "string" ? m.name : `file-${i + 1}`,
            mime: typeof m.mime === "string" ? m.mime : "application/octet-stream",
            size: Number(m.size ?? 0),
          };
        }),
      },
      200,
    );
  });

  app.openapi(routes.downloadMailFile, async (c) => {
    const claims = claimsOf(c);
    const { id, messageId, index } = c.req.valid("param");
    const mail = deps.hostedMail;
    if (!mail) throw new ApiError(400, "hosted_mail_unavailable", "This server has no mail domain");
    const b = await bot(claims, id);
    if (!b.manage)
      throw new ApiError(403, "forbidden", "Only people who manage this bot can read its mail");
    const [r] = await db.execute<{ files: unknown }>(sql`
      select m.files from public.mail_messages m join public.mail_addresses a on a.id = m.address_id
      where m.id = ${messageId}::uuid and a.bot_id = ${id}::uuid`);
    const files = Array.isArray(r?.files) ? (r.files as Array<Record<string, unknown>>) : [];
    const f = files[Number(index)];
    const key = typeof f?.key === "string" ? f.key : null;
    if (!f || !key || !deps.objects) throw new ApiError(404, "file_not_found", "No such file");
    const bytes = await deps.objects
      .get(key)
      .then(async (s) => new Uint8Array(await new Response(s).arrayBuffer()))
      .catch(() => null);
    if (!bytes) throw new ApiError(404, "file_not_found", "The file is gone");
    const name = typeof f.name === "string" && f.name ? f.name : `file-${index}`;
    return c.body(Buffer.from(bytes), 200, {
      "content-type": typeof f.mime === "string" && f.mime ? f.mime : "application/octet-stream",
      "content-disposition": `attachment; filename*=UTF-8''${encodeURIComponent(name)}`,
    }) as never;
  });

  app.openapi(routes.blockMailSender, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    const mail = deps.hostedMail;
    if (!mail) throw new ApiError(400, "hosted_mail_unavailable", "This server has no mail domain");
    const b = await bot(claims, id);
    if (!b.manage)
      throw new ApiError(403, "forbidden", "Only people who manage this bot can block senders");
    const [row] = await db.execute<AddressRow>(sql`
      select id, bot_id, channel_id, local_part, status, created_at from public.mail_addresses
      where bot_id = ${id}::uuid and status in ('active', 'paused')`);
    if (!row) throw new ApiError(404, "address_not_found", "This bot has no live address");
    const sender = body.sender.trim().toLowerCase();
    if (!sender.includes("@"))
      throw new ApiError(400, "validation_failed", "That doesn't look like an email address");
    await updateBlocked(row.channel_id, (list) => [...new Set([...list, sender])].slice(0, 200));
    return c.json(out(mail.domain, row, await channelConfig(row.channel_id)), 200);
  });

  app.openapi(routes.unblockMailSender, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const { sender } = c.req.valid("query");
    const mail = deps.hostedMail;
    if (!mail) throw new ApiError(400, "hosted_mail_unavailable", "This server has no mail domain");
    const b = await bot(claims, id);
    if (!b.manage)
      throw new ApiError(403, "forbidden", "Only people who manage this bot can unblock senders");
    const [row] = await db.execute<AddressRow>(sql`
      select id, bot_id, channel_id, local_part, status, created_at from public.mail_addresses
      where bot_id = ${id}::uuid and status in ('active', 'paused')`);
    if (!row) throw new ApiError(404, "address_not_found", "This bot has no live address");
    const gone = sender.trim().toLowerCase();
    await updateBlocked(row.channel_id, (list) => list.filter((s) => s !== gone));
    return c.json(out(mail.domain, row, await channelConfig(row.channel_id)), 200);
  });

  // Read a request body up to maxBytes before signature verification or JSON parsing, so an
  // unauthenticated caller cannot OOM the API server with a huge payload.
  const readLimitedBytes = async (req: Request, maxBytes: number): Promise<Uint8Array | null> => {
    const len = Number(req.headers.get("content-length") ?? "");
    if (Number.isFinite(len) && len > maxBytes) return null;
    if (!req.body) return new Uint8Array(0);
    const reader = req.body.getReader();
    const chunks: Uint8Array[] = [];
    let total = 0;
    try {
      for (;;) {
        const { done, value } = await reader.read();
        if (done) break;
        if (!value) continue;
        total += value.byteLength;
        if (total > maxBytes) {
          await reader.cancel().catch(() => {});
          return null;
        }
        chunks.push(value);
      }
    } finally {
      reader.releaseLock();
    }
    const out = new Uint8Array(total);
    let offset = 0;
    for (const chunk of chunks) {
      out.set(chunk, offset);
      offset += chunk.byteLength;
    }
    return out;
  };

  // The mail Worker posts every mail here: either raw binary (`message/rfc822` with `x-mail-to`
  // and `x-mail-from` headers, signed over `${to}\n${from}\n${sha256}`) or JSON `{ to, from, raw }`.
  // 404 (`no_such_address`/`sender_blocked`), 413 and 400 reject; 5xx/401/429 retry.
  const hook = async (c: {
    req: {
      method: string;
      raw: Request;
      text(): Promise<string>;
      query(k: string): string | undefined;
    };
  }) => {
    const mail = deps.hostedMail;
    const secret = deps.env.MAIL_HOOK_SECRET;
    if (!mail || !secret)
      return new Response(JSON.stringify({ code: "service_unavailable" }), { status: 503 });
    const headers = c.req.raw.headers;
    const ct = (headers.get("content-type") ?? "").toLowerCase();
    const isRaw = ct.startsWith("message/rfc822") || ct.startsWith("application/octet-stream");
    const rawLimit = isRaw ? 25 * 1024 * 1024 : 35 * 1024 * 1024;
    const rawBody = await readLimitedBytes(c.req.raw, rawLimit);
    if (!rawBody) return new Response(JSON.stringify({ code: "too_large" }), { status: 413 });
    let toAddr: string;
    let envelopeFrom: string | undefined;
    let bytes: Uint8Array;
    if (isRaw) {
      toAddr = headers.get("x-mail-to") ?? "";
      envelopeFrom = headers.get("x-mail-from") ?? "";
      const digest = createHash("sha256").update(rawBody).digest("hex");
      if (
        !verifyMailHook(
          secret,
          headers.get("x-mail-timestamp") ?? "",
          headers.get("x-mail-signature") ?? "",
          `${toAddr}\n${envelopeFrom}\n${digest}`,
        )
      )
        return new Response(JSON.stringify({ code: "bad_signature" }), { status: 401 });
      if (!toAddr)
        return new Response(JSON.stringify({ code: "validation_failed" }), { status: 400 });
      bytes = rawBody;
    } else {
      const body = Buffer.from(rawBody).toString("utf8");
      if (
        !verifyMailHook(
          secret,
          headers.get("x-mail-timestamp") ?? "",
          headers.get("x-mail-signature") ?? "",
          body,
        )
      )
        return new Response(JSON.stringify({ code: "bad_signature" }), { status: 401 });
      let parsed: { to?: unknown; from?: unknown; raw?: unknown };
      try {
        parsed = JSON.parse(body) as { to?: unknown; from?: unknown; raw?: unknown };
      } catch {
        return new Response(JSON.stringify({ code: "validation_failed" }), { status: 400 });
      }
      if (typeof parsed.to !== "string" || typeof parsed.raw !== "string")
        return new Response(JSON.stringify({ code: "validation_failed" }), { status: 400 });
      toAddr = parsed.to;
      envelopeFrom = typeof parsed.from === "string" ? parsed.from : undefined;
      // Node's base64 decode never throws; the parse below is what can reject a message.
      bytes = Uint8Array.from(Buffer.from(parsed.raw, "base64"));
    }
    const { name, tag } = splitMailTag(toAddr);
    const [a] = await db.execute<{
      id: string;
      org_id: string;
      bot_id: string;
      channel_id: string;
      status: string;
      created_at: string;
      bot_name: string;
    }>(sql`
      select a.id, a.org_id, a.bot_id, a.channel_id, a.status, a.created_at, b.name as bot_name
      from public.mail_addresses a join public.bots b on b.id = a.bot_id
      where a.local_part = ${name} and b.archived_at is null`);
    if (!a || (a.status !== "active" && a.status !== "paused"))
      return new Response(JSON.stringify({ code: "no_such_address" }), { status: 404 });
    const ch = await loadChannel(db, a.channel_id);
    if (!ch) return new Response(JSON.stringify({ code: "no_such_address" }), { status: 404 });
    const blocked = blockedOf(ch.config);
    // Blocked at the door, before the bytes are even decoded. `*@domain` entries work like the
    // allowed list's.
    if (envelopeFrom && senderAllowed(blocked, envelopeFrom.trim()))
      return new Response(JSON.stringify({ code: "sender_blocked" }), { status: 404 });
    if (bytes.length > 25 * 1024 * 1024)
      return new Response(JSON.stringify({ code: "too_large" }), { status: 413 });
    let email: ParsedMail;
    try {
      email = await parseMime(bytes);
    } catch {
      // Unparseable mail would never succeed on retry: reject it instead of 500ing.
      return new Response(JSON.stringify({ code: "validation_failed" }), { status: 400 });
    }
    if (senderAllowed(blocked, email.from))
      return new Response(JSON.stringify({ code: "sender_blocked" }), { status: 404 });
    const fromDomain = email.from.split("@")[1] ?? "";
    const check = email.multipleFrom
      ? "fail"
      : senderCheckFrom(cloudflareAuthResults(email.headers), fromDomain);
    const automatic = isAutomaticMail(email.headers, email.from, envelopeFrom);
    const allowed = senderAllowed(ch.allowed_senders, email.from);
    const bareSubj = baseSubject(email.subject).toLowerCase();
    let threadKey = `${email.from}|${bareSubj}`.slice(0, 300);
    // A confirmed reply in a thread the bot wrote to first (including CC'd recipients) reaches it
    // as a chat message for that thread, without joining the allowed list (BOT-EMAIL-PLAN §6.1).
    // In-Reply-To naming one of its own mails always counts; matching on the subject alone needs
    // a real subject and a mail sent to them in the last 90 days.
    const inReplyTo = email.inReplyTo?.slice(0, 500) ?? null;
    const [priorOut] =
      !automatic && check === "pass" && (inReplyTo || bareSubj)
        ? await db.execute<{ id: string; thread_key: string | null }>(sql`
            select id, thread_key from public.mail_messages
            where address_id = ${a.id}::uuid and direction = 'out'
              and to_addrs @> ${pgTextArray([email.from])}::text[]
              and (
                ${inReplyTo ? sql`message_id = ${inReplyTo}` : sql`false`}
                ${
                  bareSubj
                    ? sql`or (created_at > now() - interval '90 days'
                              and (thread_key = ${threadKey}
                                   or thread_key like ${`%|${likeEscape(bareSubj)}`}))`
                    : sql``
                }
              )
            order by ${inReplyTo ? sql`(message_id = ${inReplyTo}) desc nulls last,` : sql``} created_at desc
            limit 1`)
        : [];
    const threadReply = !!priorOut;
    if (priorOut?.thread_key) threadKey = priorOut.thread_key;
    // "Stop" from someone off the allowed list suppresses them for this address; the mail is
    // kept but starts nothing.
    const stopWords = new Set([
      "stop",
      "unsubscribe",
      "opt out",
      "opt-out",
      "remove me",
      "stop emailing me",
    ]);
    const isStop =
      !allowed && !automatic && check === "pass" && stopWords.has(email.text.trim().toLowerCase());
    if (isStop)
      await db.execute(sql`
        insert into public.mail_suppressions (address_id, email, reason)
        values (${a.id}::uuid, ${email.from}, 'stop') on conflict do nothing`);
    const verdict = automatic
      ? "automatic"
      : isStop
        ? "stranger"
        : (allowed || threadReply) && check === "pass"
          ? "allowed"
          : "stranger";
    track(db, { event: "mail_received", orgId: a.org_id, properties: { verdict } });
    // A Worker retry of mail already kept (POST delivered, response lost) is never refused for
    // space: the mail is already counted, and it goes on to the duplicate-safe steps below.
    const [kept] = email.messageId
      ? await db.execute<{ id: string }>(sql`
          select id from public.mail_messages
          where address_id = ${a.id}::uuid and direction = 'in' and message_id = ${email.messageId.slice(0, 500)}`)
      : [];
    // A full mailbox refuses new mail, and the owner hears about it once.
    const [usage] = await db.execute<{ total: string }>(sql`
      select coalesce(sum(size), 0)::text as total from public.mail_messages where address_id = ${a.id}::uuid`);
    const [ent] = await db.execute<{ plan_code: string; limits: Record<string, unknown> }>(
      sql`select plan_code, limits from public.entitlements where org_id = ${a.org_id}::uuid order by created_at desc limit 1`,
    );
    const quotaMb = ent?.limits?.mail_storage_mb;
    const overQuota =
      !kept &&
      ent?.plan_code !== "selfhost" &&
      (typeof quotaMb !== "number" ||
        Number(usage?.total ?? 0) + bytes.length > quotaMb * 1024 * 1024);
    if (overQuota) {
      if (ch.created_by) {
        const [told] = await db.execute<{ id: string }>(sql`
          select id from public.notifications
          where kind = 'mail_mailbox_full' and payload ->> 'address_id' = ${a.id}
            and created_at > now() - interval '7 days' limit 1`);
        if (!told)
          await deps.notifications
            ?.notify(ch.created_by, a.org_id, "mail_mailbox_full", {
              title: `${a.bot_name}'s mailbox is full`,
              body: "New mail is being refused. Free space by releasing the address, or upgrade.",
              link: `/bots/${a.bot_id}/settings`,
              bot_id: a.bot_id,
              address_id: a.id,
            })
            .catch(() => undefined);
      }
      return new Response(JSON.stringify({ code: "mailbox_full" }), { status: 413 });
    }
    const rowId = await keepInbound(db, deps, a, email, tag, check, verdict, bytes);
    // A paused address still receives and keeps mail; nothing runs or sends. A stop-note is
    // kept and handled, but also starts nothing.
    if (a.status === "paused" || isStop)
      return new Response(JSON.stringify({ ok: true }), {
        status: 200,
        headers: { "content-type": "application/json" },
      });
    const { startRoutineForMessage } = await import("../../worker/routines.ts");
    const runIds = await handleInbound(
      db,
      ch,
      [
        {
          ...parsedToInbound(email, threadKey, replySubject(email.subject)),
          senderCheck: check,
          toTag: tag,
          automatic,
          ...(threadReply ? { threadReply: true as const } : {}),
        },
      ],
      {
        startRoutine: (rid, text) => startRoutineForMessage(db, rid, text),
        fetch: fetchOut(),
        transcribe: async (data, mime) => {
          const r = await deps.workflows.voiceTranscribe(
            ch.org_id,
            ch.bot_id,
            Buffer.from(data).toString("base64"),
            mime,
          );
          return r.ok ? r.text : null;
        },
      },
    );
    for (const r of runIds) await deps.workflows.startRun(r);
    const [t] = await db.execute<{ conversation_id: string }>(sql`
      select conversation_id from public.channel_threads
      where channel_id = ${ch.id}::uuid and thread_key = ${threadKey}`);
    if (t)
      await db.execute(
        sql`update public.mail_messages set conversation_id = ${t.conversation_id}::uuid where id = ${rowId}::uuid`,
      );
    if (verdict === "stranger" && check === "pass" && ch.created_by) {
      // Someone forwarding from a second address in the first days: ask, don't stay silent.
      if (Date.now() - new Date(a.created_at).getTime() < 14 * 24 * 3600 * 1000) {
        // Only this mail's own ignored row exists: the first from this sender.
        const [rows] = await db.execute<{ n: number }>(sql`
          select count(*)::int as n from public.channel_events
          where channel_id = ${ch.id}::uuid and sender = ${email.from}`);
        if ((rows?.n ?? 0) <= 1)
          await deps.notifications
            ?.notify(ch.created_by, a.org_id, "mail_unknown_sender", {
              title: `Mail from ${email.from} for ${a.bot_name}`,
              body: `It's waiting in ${a.bot_name}'s inbox. If this is you, allow ${email.from}.`,
              link: `/bots/${a.bot_id}/email`,
              bot_id: a.bot_id,
              sender: email.from,
              channel_id: ch.id,
            })
            .catch(() => undefined);
      } else if (notifyNewOf(ch.config)) {
        // The optional bell for new senders: a first-time sender, at most once a day per bot.
        const [seen] = await db.execute<{ id: string }>(sql`
          select id from public.mail_messages
          where address_id = ${a.id}::uuid and from_addr = ${email.from} and id <> ${rowId}::uuid limit 1`);
        if (!seen) {
          const [recent] = await db.execute<{ id: string }>(sql`
            select id from public.notifications
            where kind = 'mail_new_sender' and payload ->> 'bot_id' = ${a.bot_id}
              and created_at > now() - interval '1 day' limit 1`);
          if (!recent)
            await deps.notifications
              ?.notify(ch.created_by, a.org_id, "mail_new_sender", {
                title: `Mail from ${email.from} for ${a.bot_name}`,
                body: "It's in the inbox. Nothing runs until you allow the sender or set up a routine.",
                link: `/bots/${a.bot_id}/email`,
                bot_id: a.bot_id,
              })
              .catch(() => undefined);
        }
      }
    }
    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  };

  // Before posting a large mail the Worker asks whether the address exists (signed over `to`).
  const exists = async (c: { req: { raw: Request; query(k: string): string | undefined } }) => {
    const mail = deps.hostedMail;
    const secret = deps.env.MAIL_HOOK_SECRET;
    if (!mail || !secret)
      return new Response(JSON.stringify({ code: "service_unavailable" }), { status: 503 });
    const headers = c.req.raw.headers;
    const to = c.req.query("to") ?? "";
    // Signed over the address asked about, so a captured signature answers for no other.
    if (
      !verifyMailHook(
        secret,
        headers.get("x-mail-timestamp") ?? "",
        headers.get("x-mail-signature") ?? "",
        to,
      )
    )
      return new Response(JSON.stringify({ code: "bad_signature" }), { status: 401 });
    const { name } = splitMailTag(to);
    const [a] = await db.execute<{ id: string }>(sql`
      select id from public.mail_addresses
      where local_part = ${name} and status in ('active', 'paused')`);
    if (!a) return new Response(JSON.stringify({ code: "no_such_address" }), { status: 404 });
    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  };

  app.post("/hooks/mail", (c) => hook(c));
  // A GET, not a HEAD: Hono doesn't match HEAD routes. The answer is tiny either way.
  app.get("/hooks/mail", (c) => exists(c));

  // Delivery events (Cloudflare Queues → the mail Worker → here, one signed POST per event):
  // delivered, bounced and complained. Anything else is acknowledged and ignored.
  app.post("/hooks/mail/events", async (c) => {
    const mail = deps.hostedMail;
    const secret = deps.env.MAIL_HOOK_SECRET;
    if (!mail || !secret)
      return new Response(JSON.stringify({ code: "service_unavailable" }), { status: 503 });
    const headers = c.req.raw.headers;
    const body = await c.req.text();
    if (
      !verifyMailHook(
        secret,
        headers.get("x-mail-timestamp") ?? "",
        headers.get("x-mail-signature") ?? "",
        body,
      )
    )
      return new Response(JSON.stringify({ code: "bad_signature" }), { status: 401 });
    let event: {
      type?: unknown;
      payload?: {
        eventId?: unknown;
        messageId?: unknown;
        sender?: unknown;
        recipient?: unknown;
        bounce?: { type?: unknown; reason?: unknown };
        complaint?: { reason?: unknown };
      };
    };
    try {
      event = JSON.parse(body) as typeof event;
    } catch {
      return new Response(JSON.stringify({ code: "validation_failed" }), { status: 400 });
    }
    const kind =
      event.type === "cf.email.sending.message.delivered"
        ? "delivered"
        : event.type === "cf.email.sending.message.bounced"
          ? "bounced"
          : event.type === "cf.email.sending.message.complained"
            ? "complained"
            : null;
    if (!kind)
      return new Response(JSON.stringify({ ok: true }), {
        status: 200,
        headers: { "content-type": "application/json" },
      });
    const p = event.payload ?? {};
    const eventId = typeof p.eventId === "string" ? p.eventId : null;
    const recipient = typeof p.recipient === "string" ? p.recipient.trim().toLowerCase() : "";
    const sender = typeof p.sender === "string" ? p.sender.trim().toLowerCase() : "";
    if (!eventId || !recipient || !sender)
      return new Response(JSON.stringify({ code: "validation_failed" }), { status: 400 });
    const { name } = splitMailTag(sender);
    const [a] = await db.execute<{
      id: string;
      org_id: string;
      bot_id: string;
      bot_name: string;
    }>(sql`
      select a.id, a.org_id, a.bot_id, b.name as bot_name
      from public.mail_addresses a join public.bots b on b.id = a.bot_id
      where a.local_part = ${name}`);
    // Unknown address: acknowledge (retrying won't create it).
    if (!a)
      return new Response(JSON.stringify({ ok: true }), {
        status: 200,
        headers: { "content-type": "application/json" },
      });
    const hardBounce =
      kind === "bounced" &&
      (p.bounce && typeof p.bounce === "object" ? p.bounce.type : undefined) === "hard";
    const reason =
      kind === "bounced"
        ? p.bounce && typeof p.bounce === "object" && typeof p.bounce.reason === "string"
          ? p.bounce.reason
          : null
        : kind === "complained" &&
            p.complaint &&
            typeof p.complaint === "object" &&
            typeof p.complaint.reason === "string"
          ? p.complaint.reason
          : null;
    await db.execute(sql`
      insert into public.mail_events (address_id, org_id, event_id, message_id, event, hard, recipient, detail)
      values (${a.id}::uuid, ${a.org_id}::uuid, ${eventId},
              ${typeof p.messageId === "string" ? p.messageId : null}, ${kind}, ${hardBounce},
              ${recipient}, ${reason?.slice(0, 500) ?? null})
      on conflict do nothing`);
    if (kind === "complained" || hardBounce)
      await db.execute(sql`
        insert into public.mail_suppressions (address_id, email, reason)
        values (${a.id}::uuid, ${recipient}, ${kind === "complained" ? "complaint" : "bounce"})
        on conflict do nothing`);
    if (kind === "complained" || hardBounce) await autoPauseIfNeeded(db, deps, a);
    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  });
}

/**
 * An address pauses itself after 2 complaints in 30 days, or when more than 1 in 10 of its
 * last 20 sends hard-bounced (at least 10 sends, so one typo can't pause it). The owner hears
 * why; only the instance owner lifts it, from Admin.
 */
async function autoPauseIfNeeded(
  db: AppDeps["db"],
  deps: AppDeps,
  a: { id: string; org_id: string; bot_id: string; bot_name: string },
) {
  const [already] = await db.execute<{ status: string; auto_paused_at: string | null }>(sql`
    select status, auto_paused_at from public.mail_addresses where id = ${a.id}::uuid`);
  if (already?.status !== "active" || already.auto_paused_at) return;
  const [complaints] = await db.execute<{ n: number }>(sql`
    select count(*)::int as n from public.mail_events
    where address_id = ${a.id}::uuid and event = 'complained' and created_at > now() - interval '30 days'`);
  const [sends] = await db.execute<{ n: number; bounced: number }>(sql`
    with last20 as (
      select message_id, provider_message_id from public.mail_messages
      where address_id = ${a.id}::uuid and direction = 'out' order by created_at desc limit 20
    )
    select count(*)::int as n,
           (select count(*)::int from public.mail_events e
            where e.address_id = ${a.id}::uuid and e.event = 'bounced' and e.hard
              and (e.message_id in (select provider_message_id from last20 where provider_message_id is not null)
                   or e.message_id in (select message_id from last20 where message_id is not null))) as bounced
    from last20`);
  const why =
    (complaints?.n ?? 0) >= 2
      ? "two people reported its mail"
      : (sends?.n ?? 0) >= 10 && (sends?.bounced ?? 0) / (sends?.n ?? 1) > 0.1
        ? "too much of its mail bounced"
        : null;
  if (!why) return;
  await db.execute(sql`
    update public.mail_addresses set status = 'paused', auto_paused_at = now(), updated_at = now()
    where id = ${a.id}::uuid`);
  const [ch] = await db.execute<{ created_by: string | null }>(
    sql`select c.created_by from public.channels c join public.mail_addresses x on x.channel_id = c.id where x.id = ${a.id}::uuid`,
  );
  if (ch?.created_by)
    await deps.notifications
      ?.notify(ch.created_by, a.org_id, "mail_auto_paused", {
        title: `${a.bot_name}'s address was paused automatically`,
        body: `Its mail stops going out because ${why}. The instance owner can lift the pause from Admin.`,
        link: `/bots/${a.bot_id}/settings`,
        bot_id: a.bot_id,
      })
      .catch(() => undefined);
}

type MailRowOut = {
  id: string;
  direction: "in" | "out";
  from_addr: string;
  from_name: string | null;
  to_tag: string;
  subject: string;
  content: unknown;
  verdict: "allowed" | "stranger" | "automatic";
  sender_check: "pass" | "fail" | "none";
  files: unknown;
  size: number | string;
  conversation_id: string | null;
  created_at: string;
};

const mailOpenedText = (content: unknown): string => {
  const parts = contentKeys.open(content);
  if (!Array.isArray(parts)) return "";
  return parts
    .filter((p) => (p as { type?: string })?.type === "text")
    .map((p) => String((p as { text?: string })?.text ?? ""))
    .join("\n");
};

/** The inbox list's preview line: the first 200 characters, flattened. */
const mailSnippet = (content: unknown): string =>
  mailOpenedText(content).replace(/\s+/g, " ").trim().slice(0, 200);

const mailFullText = (content: unknown): string => mailOpenedText(content);

/** Stores an inbound mail's original, its attachments and its row; returns the row id. */
async function keepInbound(
  db: AppDeps["db"],
  deps: AppDeps,
  a: { id: string; org_id: string },
  email: {
    from: string;
    fromName?: string;
    subject: string;
    text: string;
    messageId?: string;
    inReplyTo?: string;
    files: Array<{ name?: string; mime?: string; size: number; bytes: Uint8Array }>;
  },
  tag: string,
  check: string,
  verdict: string,
  bytes: Uint8Array,
): Promise<string> {
  const messageId = email.messageId ? email.messageId.slice(0, 500) : null;
  const inReplyTo = email.inReplyTo ? email.inReplyTo.slice(0, 500) : null;
  const subject = email.subject.slice(0, 500);
  const threadKey = `${email.from}|${baseSubject(subject).toLowerCase()}`.slice(0, 300);
  // A Worker retry (POST delivered, response lost) keeps nothing twice: mail with a
  // Message-ID the address already has resolves to its existing row.
  if (messageId) {
    const [dup] = await db.execute<{ id: string }>(sql`
      select id from public.mail_messages
      where address_id = ${a.id}::uuid and direction = 'in' and message_id = ${messageId}`);
    if (dup) return dup.id;
  }
  const id = randomUUID();
  let rawKey: string | null = null;
  if (deps.objects) {
    rawKey = `mail/${a.id}/${id}.eml`;
    await deps.objects.put(rawKey, bytes).catch(() => {
      rawKey = null;
    });
  }
  const files: Array<{ name: string; mime: string; size: number; key: string | null }> = [];
  for (const [i, f] of email.files.slice(0, 10).entries()) {
    let key: string | null = null;
    if (deps.objects) {
      key = `mail/${a.id}/${id}/att-${i}`;
      await deps.objects.put(key, f.bytes).catch(() => {
        key = null;
      });
    }
    files.push({
      name: f.name ?? `file-${i + 1}`,
      mime: f.mime ?? "application/octet-stream",
      size: f.size,
      key,
    });
  }
  const [inserted] = await db.execute<{ id: string }>(sql`
    insert into public.mail_messages
      (id, address_id, org_id, direction, from_addr, from_name, to_tag, subject, content, message_id,
       in_reply_to, thread_key, sender_check, verdict, files, size, raw_key, expires_at)
    values (${id}::uuid, ${a.id}::uuid, ${a.org_id}::uuid, 'in', ${email.from},
            ${email.fromName?.slice(0, 300) ?? null}, ${tag.slice(0, 100)}, ${subject},
            ${contentKeys.sealJson(a.org_id, [{ type: "text", text: email.text }])}::jsonb,
            ${messageId}, ${inReplyTo},
            ${threadKey},
            ${check}, ${verdict}, ${JSON.stringify(files)}::jsonb, ${bytes.length}, ${rawKey},
            ${verdict === "allowed" ? sql`null` : sql`now() + interval '30 days'`})
    on conflict do nothing returning id`);
  if (!inserted) {
    // Lost the race with a concurrent retry: drop the orphaned objects, keep the first row.
    if (deps.objects) {
      const keys = [rawKey, ...files.map((f) => f.key)].filter((k): k is string => !!k);
      for (const k of keys) await deps.objects.delete(k).catch(() => {});
    }
    const [dup] = await db.execute<{ id: string }>(sql`
      select id from public.mail_messages
      where address_id = ${a.id}::uuid and direction = 'in' and message_id = ${messageId}`);
    return dup?.id ?? id;
  }
  return id;
}
