/**
 * The Library (docs/LIBRARY-PLAN.md, Phase 1; D-274): everything a bot made, from one index.
 * Lists run in the person's own database session, so row-level security decides what they see
 * (a page by its visibility, anything else by the chat it was made in).
 */
import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";
import { requireClaims } from "./autonomy.ts";
import { parseRange, videoPoster } from "./chat-media.ts";

/** Deleted creations can be restored for this long; then the worker purges them. */
export const CREATION_UNDO_DAYS = 30;

type CreationRow = {
  id: string;
  org_id: string;
  bot_id: string | null;
  bot_name: string | null;
  made_for: string | null;
  conversation_id: string | null;
  run_id: string | null;
  kind: "page" | "image" | "video" | "audio" | "document" | "file";
  label: string | null;
  title: string;
  page_id: string | null;
  media_id: string | null;
  mime: string | null;
  size: string | number;
  width: number | null;
  height: number | null;
  duration_s: number | null;
  cover_key: string | null;
  version: number;
  pinned_at: Date | null;
  last_opened_at: Date | null;
  can_change: boolean;
  deleted_at: Date | null;
  created_at: Date;
  updated_at: Date;
  [k: string]: unknown;
};

const out = (r: CreationRow) => ({
  id: r.id,
  org_id: r.org_id,
  bot_id: r.bot_id,
  bot_name: r.bot_name,
  made_for: r.made_for,
  conversation_id: r.conversation_id,
  run_id: r.run_id,
  kind: r.kind,
  label: r.label,
  title: r.title,
  page_id: r.page_id,
  media_id: r.media_id,
  mime: r.mime,
  size: Number(r.size),
  width: r.width,
  height: r.height,
  duration_s: r.duration_s,
  // Pictures are their own cover and videos get a frame; the rest get theirs in Phase 3.
  has_cover: !!r.cover_key || (!!r.media_id && (r.kind === "image" || r.kind === "video")),
  version: r.version,
  pinned: !!r.pinned_at,
  last_opened_at: r.last_opened_at ? iso(r.last_opened_at) : null,
  can_change: r.can_change,
  deleted_at: r.deleted_at ? iso(r.deleted_at) : null,
  created_at: iso(r.created_at),
  updated_at: iso(r.updated_at),
});

/** The columns every read returns, for the person asking. */
const columns = (_userId: string) => sql`
  c.id, c.org_id, c.bot_id, b.name as bot_name, c.made_for, c.conversation_id, c.run_id, c.kind,
  c.label, c.title, c.page_id, c.media_id, c.mime, c.size, c.width, c.height, c.duration_s,
  c.cover_key, c.version, m.pinned_at, m.last_opened_at, public.can_change_creation(c.id) as can_change,
  c.deleted_at, c.created_at, c.updated_at`;
const joins = (userId: string) => sql`
  from public.creations c
  left join public.bots b on b.id = c.bot_id
  left join public.creation_marks m on m.creation_id = c.id and m.user_id = ${userId}::uuid`;

/** An opaque keyset cursor: the sort value and the id of the last row. */
const encodeCursor = (at: Date | string | null, id: string) =>
  Buffer.from(`${at ? new Date(at).toISOString() : ""}|${id}`).toString("base64url");
function decodeCursor(s: string): { at: string | null; id: string } | null {
  const [at, id] = Buffer.from(s, "base64url").toString().split("|");
  if (!id || !/^[0-9a-f-]{36}$/i.test(id)) return null;
  if (at && Number.isNaN(Date.parse(at))) return null;
  return { at: at || null, id };
}

export function registerCreationRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  /** One creation the person can see, or a 404. */
  async function visible(claims: JwtClaims, id: string, includeDeleted = false) {
    const [row] = await withUserSession(db, claims, (tx) =>
      tx.execute<CreationRow>(sql`
        select ${columns(claims.sub)} ${joins(claims.sub)}
        where c.id = ${id}::uuid ${includeDeleted ? sql`` : sql`and c.deleted_at is null`}`),
    );
    if (!row) throw new ApiError(404, "creation_not_found", "Nothing like that in the Library");
    return row;
  }

  app.openapi(routes.listCreations, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const q = c.req.valid("query");
    const limit = q.limit ?? 40;
    const byOpened = q.sort === "opened";
    const cursor = q.cursor ? decodeCursor(q.cursor) : null;
    if (q.cursor && !cursor) throw new ApiError(400, "bad_cursor", "That cursor isn't valid");
    const sortCol = byOpened ? sql`m.last_opened_at` : sql`c.created_at`;
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<CreationRow>(sql`
        select ${columns(claims.sub)} ${joins(claims.sub)}
        where c.org_id = ${q.org_id}::uuid
          ${
            q.deleted === "true"
              ? sql`and c.deleted_at > now() - make_interval(days => ${CREATION_UNDO_DAYS}) and public.can_change_creation(c.id)`
              : sql`and c.deleted_at is null`
          }
          ${q.kind ? sql`and c.kind = ${q.kind}` : sql``}
          ${q.bot_id ? sql`and c.bot_id = ${q.bot_id}::uuid` : sql``}
          ${q.conversation_id ? sql`and c.conversation_id = ${q.conversation_id}::uuid` : sql``}
          ${q.project_id ? sql`and c.run_id in (select id from public.runs where project_id = ${q.project_id}::uuid)` : sql``}
          ${q.pinned === "true" ? sql`and m.pinned_at is not null` : q.pinned === "false" ? sql`and m.pinned_at is null` : sql``}
          ${q.q ? sql`and (c.title ilike ${`%${q.q.replace(/[\\%_]/g, (x) => `\\${x}`)}%`} or c.label ilike ${`%${q.q.replace(/[\\%_]/g, (x) => `\\${x}`)}%`})` : sql``}
          ${byOpened ? sql`and m.last_opened_at is not null` : sql``}
          ${
            cursor
              ? sql`and (${sortCol}, c.id) < (${cursor.at}::timestamptz, ${cursor.id}::uuid)`
              : sql``
          }
        order by ${sortCol} desc nulls last, c.id desc
        limit ${limit + 1}::int`),
    );
    const page = rows.slice(0, limit);
    const last = page.at(-1);
    const kinds = await withUserSession(db, claims, (tx) =>
      tx.execute<{ kind: CreationRow["kind"] }>(sql`
        select distinct kind from public.creations
        where org_id = ${q.org_id}::uuid and deleted_at is null order by kind`),
    );
    return c.json(
      {
        items: page.map(out),
        next_cursor:
          rows.length > limit && last
            ? encodeCursor(byOpened ? last.last_opened_at : last.created_at, last.id)
            : null,
        kinds: kinds.map((k) => k.kind),
      },
      200,
    );
  });

  app.openapi(routes.getCreation, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const row = await visible(claims, id);
    const siblings = row.run_id
      ? await withUserSession(db, claims, (tx) =>
          tx.execute<CreationRow>(sql`
            select ${columns(claims.sub)} ${joins(claims.sub)}
            where c.run_id = ${row.run_id}::uuid and c.id <> ${id}::uuid and c.deleted_at is null
            order by c.created_at desc limit 20`),
        )
      : [];
    return c.json({ ...out(row), siblings: siblings.map(out) }, 200);
  });

  app.openapi(routes.updateCreation, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    const row = await visible(claims, id);
    if ((body.title !== undefined || body.label !== undefined) && !row.can_change)
      throw new ApiError(
        403,
        "forbidden",
        "Only the person it was made for, or the bot's managers, can rename it",
      );
    await withUserSession(db, claims, async (tx) => {
      if (body.title !== undefined || body.label !== undefined) {
        await tx.execute(sql`
          update public.creations set
            title = coalesce(${body.title ?? null}, title),
            label = ${body.label === undefined ? sql`label` : body.label},
            updated_at = now()
          where id = ${id}::uuid`);
        // A page's title is the page's own: the Library mirrors it (the pages trigger).
        if (body.title !== undefined && row.page_id && row.can_change)
          await db.execute(
            sql`update public.pages set title = ${body.title} where id = ${row.page_id}::uuid`,
          );
      }
      if (body.pinned !== undefined || body.opened) {
        await tx.execute(sql`
          insert into public.creation_marks (user_id, creation_id, org_id, pinned_at, last_opened_at)
          values (${claims.sub}::uuid, ${id}::uuid, ${row.org_id}::uuid,
                  ${body.pinned ? sql`now()` : sql`null`}, ${body.opened ? sql`now()` : sql`null`})
          on conflict (user_id, creation_id) do update set
            pinned_at = ${body.pinned === undefined ? sql`creation_marks.pinned_at` : body.pinned ? sql`coalesce(creation_marks.pinned_at, now())` : sql`null`},
            last_opened_at = ${body.opened ? sql`now()` : sql`creation_marks.last_opened_at`}`);
      }
    });
    return c.json(out(await visible(claims, id)), 200);
  });

  const setDeleted = async (claims: JwtClaims, id: string, deleted: boolean) => {
    const row = await visible(claims, id, true);
    if (!row.can_change)
      throw new ApiError(
        403,
        "forbidden",
        "Only the person it was made for, or the bot's managers, can delete it",
      );
    if (!deleted && !row.deleted_at) return row;
    await withUserSession(db, claims, (tx) =>
      tx.execute(sql`
        update public.creations set deleted_at = ${deleted ? sql`now()` : sql`null`}, updated_at = now()
        where id = ${id}::uuid`),
    );
    return visible(claims, id, true);
  };

  app.openapi(routes.deleteCreation, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    return c.json(out(await setDeleted(claims, id, true)), 200);
  });

  app.openapi(routes.restoreCreation, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    return c.json(out(await setDeleted(claims, id, false)), 200);
  });

  app.openapi(routes.getCreationContent, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const row = await visible(claims, id);
    if (!row.media_id)
      throw new ApiError(
        404,
        "no_content",
        row.page_id
          ? "Open pages with POST /v1/pages/{id}/view-link"
          : "This creation has no bytes here yet",
      );
    const size = Number(row.size);
    const headers: Record<string, string> = {
      "content-type": row.mime ?? "application/octet-stream",
      "cache-control": "private, max-age=31536000, immutable",
      "accept-ranges": "bytes",
      "content-security-policy": "default-src 'none'",
    };
    const rangeHeader = c.req.header("range");
    if (rangeHeader) {
      const range = parseRange(rangeHeader, size);
      if (!range)
        return c.body(null, 416, { ...headers, "content-range": `bytes */${size}` }) as never;
      const length = range.end - range.start + 1;
      const [slice] = await db.execute<{ part: Buffer }>(sql`
        select substring(bytes from ${range.start + 1}::int for ${length}::int) as part
        from public.chat_media where id = ${row.media_id}::uuid`);
      if (!slice) throw new ApiError(404, "no_content", "The bytes are gone");
      return c.body(new Uint8Array(slice.part), 206, {
        ...headers,
        "content-range": `bytes ${range.start}-${range.end}/${size}`,
        "content-length": String(length),
      }) as never;
    }
    const [m] = await db.execute<{ bytes: Buffer }>(sql`
      select bytes from public.chat_media where id = ${row.media_id}::uuid`);
    if (!m) throw new ApiError(404, "no_content", "The bytes are gone");
    return c.body(new Uint8Array(m.bytes), 200, {
      ...headers,
      "content-length": String(m.bytes.length),
    }) as never;
  });

  // Video frames made since the server started (a creation's media never changes under its id).
  const posters = new Map<string, Buffer | null>();
  app.openapi(routes.getCreationCover, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const row = await visible(claims, id);
    const none = () => new ApiError(404, "no_cover", "This one has no cover; the app draws one");
    if (!row.media_id || (row.kind !== "image" && row.kind !== "video")) throw none();
    let body: Buffer | null;
    let type: string;
    if (row.kind === "image") {
      const [m] = await db.execute<{ bytes: Buffer }>(sql`
        select bytes from public.chat_media where id = ${row.media_id}::uuid`);
      body = m?.bytes ?? null;
      type = row.mime ?? "image/png";
    } else {
      body = posters.get(row.media_id) ?? null;
      if (!posters.has(row.media_id)) {
        const [m] = await db.execute<{ bytes: Buffer }>(sql`
          select bytes from public.chat_media where id = ${row.media_id}::uuid`);
        body = m ? await videoPoster(new Uint8Array(m.bytes), row.duration_s) : null;
        posters.set(row.media_id, body);
        while (posters.size > 300) posters.delete(posters.keys().next().value as string);
      }
      type = "image/jpeg";
    }
    if (!body) throw none();
    return c.body(new Uint8Array(body), 200, {
      "content-type": type,
      "content-length": String(body.length),
      "cache-control": "private, max-age=86400",
      "content-security-policy": "default-src 'none'",
    }) as never;
  });
}
