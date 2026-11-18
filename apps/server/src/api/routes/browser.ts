/**
 * Casama for Chrome, Phase 2 (D-323): page commands for the / menu, highlights, a page's history,
 * and page watchers a person makes by pointing at part of a page.
 */
import { track } from "@casama/agent";
import { pageKey, routes } from "@casama/contracts";
import { type JwtClaims, pgErrorCode, withUserSession } from "@casama/db";
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

type CommandRow = {
  id: string;
  name: string;
  prompt: string;
  position: number;
  created_at: string;
  updated_at: string;
};
const commandOut = (r: CommandRow) => ({
  ...r,
  created_at: iso(r.created_at),
  updated_at: iso(r.updated_at),
});

type HighlightRow = {
  id: string;
  org_id: string;
  url: string;
  url_key: string;
  title: string;
  text: string;
  prefix: string;
  suffix: string;
  note: string;
  created_at: string;
};
const H_COLS = sql`id, org_id, url, url_key, title, text, prefix, suffix, note, created_at`;
const highlightOut = (r: HighlightRow) => ({ ...r, created_at: iso(r.created_at) });

/** At most this many page commands per person. */
const MAX_COMMANDS = 50;

/** Page keys fit the 2,000-character columns they're stored in. */
const keyOf = (url: string) => pageKey(url).slice(0, 2000);

/** At most this many active page watchers a person makes from the browser. */
const MAX_PAGE_WATCHERS = 25;
/** A pointed-at watcher stops by itself after this many days unless renewed. */
const WATCHER_DAYS = 90;

const duplicate = () =>
  new ApiError(409, "page_command_exists", "You already have a page command with that name");

export function registerBrowserRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  app.openapi(routes.listPageCommands, async (c) => {
    const rows = await withUserSession(db, claimsOf(c), (tx) =>
      tx.execute<CommandRow>(sql`select id, name, prompt, position, created_at, updated_at
        from public.page_commands order by position, name limit ${MAX_COMMANDS}`),
    );
    return c.json({ items: rows.map(commandOut) }, 200);
  });

  app.openapi(routes.createPageCommand, async (c) => {
    const claims = claimsOf(c);
    const b = c.req.valid("json");
    try {
      const [row] = await withUserSession(db, claims, async (tx) => {
        const [n] = await tx.execute<{ n: number }>(
          sql`select count(*)::int as n from public.page_commands`,
        );
        if ((n?.n ?? 0) >= MAX_COMMANDS)
          throw new ApiError(409, "too_many_page_commands", `Up to ${MAX_COMMANDS} page commands`);
        return tx.execute<CommandRow>(sql`
          insert into public.page_commands (name, prompt, position)
          values (${b.name}, ${b.prompt}, ${b.position ?? n?.n ?? 0})
          returning id, name, prompt, position, created_at, updated_at`);
      });
      return c.json(commandOut(row!), 201);
    } catch (e) {
      if (pgErrorCode(e) === "23505") throw duplicate();
      throw e;
    }
  });

  app.openapi(routes.updatePageCommand, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const b = c.req.valid("json");
    try {
      const [row] = await withUserSession(db, claims, (tx) =>
        tx.execute<CommandRow>(sql`
          update public.page_commands set
            name = coalesce(${b.name ?? null}, name),
            prompt = coalesce(${b.prompt ?? null}, prompt),
            position = coalesce(${b.position ?? null}::int, position),
            updated_at = now()
          where id = ${id}::uuid
          returning id, name, prompt, position, created_at, updated_at`),
      );
      if (!row) throw new ApiError(404, "page_command_not_found", "Page command not found");
      return c.json(commandOut(row), 200);
    } catch (e) {
      if (pgErrorCode(e) === "23505") throw duplicate();
      throw e;
    }
  });

  app.openapi(routes.deletePageCommand, async (c) => {
    const { id } = c.req.valid("param");
    const rows = await withUserSession(db, claimsOf(c), (tx) =>
      tx.execute<{ id: string }>(
        sql`delete from public.page_commands where id = ${id}::uuid returning id`,
      ),
    );
    if (!rows[0]) throw new ApiError(404, "page_command_not_found", "Page command not found");
    return c.json({ deleted: id }, 200);
  });

  app.openapi(routes.listHighlights, async (c) => {
    const q = c.req.valid("query");
    const rows = await withUserSession(db, claimsOf(c), (tx) =>
      tx.execute<HighlightRow>(sql`select ${H_COLS} from public.highlights
        where org_id = ${q.org_id}::uuid
          ${q.url ? sql`and url_key = ${keyOf(q.url)}` : sql``}
        order by created_at desc limit 500`),
    );
    return c.json({ items: rows.map(highlightOut) }, 200);
  });

  app.openapi(routes.createHighlight, async (c) => {
    const claims = claimsOf(c);
    const b = c.req.valid("json");
    const [row] = await withUserSession(db, claims, async (tx) => {
      const [m] = await tx.execute<{ ok: boolean }>(
        sql`select public.is_member(${b.org_id}::uuid) as ok`,
      );
      if (!m?.ok) throw new ApiError(404, "org_not_found", "No such workspace");
      return tx.execute<HighlightRow>(sql`
        insert into public.highlights (org_id, url, url_key, title, text, prefix, suffix, note)
        values (${b.org_id}::uuid, ${b.url}, ${keyOf(b.url)}, ${b.title ?? ""}, ${b.text},
                ${b.prefix ?? ""}, ${b.suffix ?? ""}, ${b.note ?? ""})
        returning ${H_COLS}`);
    });
    return c.json(highlightOut(row!), 201);
  });

  app.openapi(routes.deleteHighlight, async (c) => {
    const { id } = c.req.valid("param");
    const rows = await withUserSession(db, claimsOf(c), (tx) =>
      tx.execute<{ id: string }>(
        sql`delete from public.highlights where id = ${id}::uuid returning id`,
      ),
    );
    if (!rows[0]) throw new ApiError(404, "highlight_not_found", "Highlight not found");
    return c.json({ deleted: id }, 200);
  });

  app.openapi(routes.getPageHistory, async (c) => {
    const claims = claimsOf(c);
    const q = c.req.valid("query");
    const key = keyOf(q.url);
    const { convs, marks } = await withUserSession(db, claims, async (tx) => ({
      convs: await tx.execute<{
        id: string;
        bot_id: string;
        title: string | null;
        created_at: string;
      }>(sql`select id, bot_id, title, created_at from public.conversations
          where org_id = ${q.org_id}::uuid and created_by = ${claims.sub}::uuid and source_url = ${key}
          order by created_at desc limit 20`),
      marks: await tx.execute<HighlightRow>(sql`select ${H_COLS} from public.highlights
          where org_id = ${q.org_id}::uuid and url_key = ${key} order by created_at limit 200`),
    }));
    return c.json(
      {
        conversations: convs.map((r) => ({ ...r, created_at: iso(r.created_at) })),
        highlights: marks.map(highlightOut),
      },
      200,
    );
  });

  app.openapi(routes.createPageWatcher, async (c) => {
    const claims = claimsOf(c);
    const b = c.req.valid("json");
    if (!/^https?:\/\//i.test(b.url))
      throw new ApiError(400, "bad_url", "Only http and https pages can be watched");
    // The person must be able to use the bot; the row itself is written by the server, since
    // watchers are otherwise made by bots (D-116).
    const [bot] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ org_id: string }>(
        sql`select org_id from public.bots where id = ${b.bot_id}::uuid and archived_at is null and public.can_access_bot(id)`,
      ),
    );
    if (!bot) throw new ApiError(404, "bot_not_found", "Bot not found");
    const [n] = await db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.watchers
      where created_by = ${claims.sub}::uuid and kind = 'page_change' and status = 'active'
        and target->>'source' = 'chrome'`);
    if ((n?.n ?? 0) >= MAX_PAGE_WATCHERS)
      throw new ApiError(
        409,
        "too_many_watchers",
        `Up to ${MAX_PAGE_WATCHERS} page watchers at a time; stop one in the bot's watchers first`,
      );
    // `source` marks watchers made from the browser, for the cap above.
    // A signed-in page is read in the person's own browser whenever it's online (D-323 B10).
    if (b.where === "mine") {
      const [paired] = await db.execute<{ ok: boolean }>(sql`
        select true as ok from public.local_devices where platform = 'chrome' and enabled
          and user_id = ${claims.sub}::uuid and org_id = ${bot.org_id}::uuid and ${b.bot_id}::uuid = any(allowed_bot_ids) limit 1`);
      if (!paired)
        throw new ApiError(
          409,
          "browser_not_paired",
          "Let this bot use your browser first (Your browser, in the panel's More tab)",
        );
    }
    const target = {
      url: b.url,
      anchor: b.anchor,
      chars: b.chars,
      browser: false,
      source: "chrome",
      ...(b.where === "mine" ? { where: "mine", offline: "wait" } : {}),
    };
    const [row] = await db.execute<Record<string, unknown>>(sql`
      insert into public.watchers (org_id, bot_id, created_by, name, kind, target, condition_md, on_match_md, check_every_seconds, expires_at)
      values (${bot.org_id}::uuid, ${b.bot_id}::uuid, ${claims.sub}::uuid, ${b.name}, 'page_change',
              ${JSON.stringify(target)}::jsonb, ${b.condition ?? ""},
              ${"Tell me what changed on the page, in a sentence or two."},
              ${(b.check_every_minutes ?? 60) * 60}, now() + make_interval(days => ${WATCHER_DAYS}))
      returning id, bot_id, name, kind, target, condition_md, status, check_every_seconds, fired_count,
                last_checked_at, last_error, expires_at, conversation_id, created_at`);
    track(db, {
      event: "watcher_created",
      userId: claims.sub,
      orgId: bot.org_id,
      properties: { kind: "page_change" },
    });
    const r = row as Record<string, string | null>;
    const out = {
      ...r,
      last_checked_at: r.last_checked_at ? iso(r.last_checked_at) : null,
      expires_at: r.expires_at ? iso(r.expires_at) : null,
      created_at: iso(r.created_at as string),
    };
    return c.json(out as never, 201);
  });
}
