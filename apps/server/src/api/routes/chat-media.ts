/**
 * Chat media (D-205): images and videos a bot generated, kept in Postgres and shown under the
 * reply. Members of the workspace read them here with their token; a single byte range is
 * honoured (video players ask for ranges and AVPlayer won't play without them), and only the
 * asked-for slice is read from the database.
 */
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

/** A single `bytes=` range against a file of `size` bytes: inclusive start and end, or null when unsatisfiable. */
export function parseRange(header: string, size: number): { start: number; end: number } | null {
  const m = /^bytes=(\d*)-(\d*)$/.exec(header.trim());
  if (!m || (m[1] === "" && m[2] === "")) return null;
  let start: number;
  let end: number;
  if (m[1] === "") {
    // Suffix: the last n bytes.
    const n = Number(m[2]);
    if (n <= 0) return null;
    start = Math.max(0, size - n);
    end = size - 1;
  } else {
    start = Number(m[1]);
    end = m[2] === "" ? size - 1 : Math.min(Number(m[2]), size - 1);
  }
  if (!Number.isSafeInteger(start) || !Number.isSafeInteger(end)) return null;
  if (start >= size || start > end) return null;
  return { start, end };
}

export function registerChatMediaRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  app.get("/v1/media/:id", async (c) => {
    const claims = c.get("claims") as JwtClaims | undefined;
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    const id = c.req.param("id");
    const missing = () => new ApiError(404, "media_not_found", "No such file");
    if (!/^[0-9a-f-]{36}$/i.test(id)) throw missing();
    const [meta] = await db.execute<{ org_id: string; content_type: string; size: number }>(sql`
      select org_id, content_type, size from public.chat_media where id = ${id}::uuid`);
    if (!meta) throw missing();
    const [m] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.is_member(${meta.org_id}::uuid) as ok`),
    );
    if (!m?.ok) throw missing();

    const size = Number(meta.size);
    const headers: Record<string, string> = {
      "content-type": meta.content_type,
      "cache-control": "private, max-age=31536000, immutable",
      "accept-ranges": "bytes",
      "content-security-policy": "default-src 'none'",
    };
    const rangeHeader = c.req.header("range");
    if (rangeHeader) {
      const range = parseRange(rangeHeader, size);
      if (!range) return c.body(null, 416, { ...headers, "content-range": `bytes */${size}` });
      const length = range.end - range.start + 1;
      // substring() on bytea is 1-based.
      const [slice] = await db.execute<{ part: Buffer }>(sql`
        select substring(bytes from ${range.start + 1}::int for ${length}::int) as part
        from public.chat_media where id = ${id}::uuid`);
      if (!slice) throw missing();
      return c.body(new Uint8Array(slice.part), 206, {
        ...headers,
        "content-range": `bytes ${range.start}-${range.end}/${size}`,
        "content-length": String(length),
      });
    }
    const [row] = await db.execute<{ bytes: Buffer }>(sql`
      select bytes from public.chat_media where id = ${id}::uuid`);
    if (!row) throw missing();
    return c.body(new Uint8Array(row.bytes), 200, {
      ...headers,
      "content-length": String(size),
    });
  });
}
