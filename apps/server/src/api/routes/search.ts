/**
 * Search (SPEC: Post-v1 roadmap → Search; D-103). Database results come from
 * `public.search_workspace` run as the caller (RLS keeps them in their workspaces and bots). File
 * names and contents are searched only on computers that are already awake; none is woken.
 */

import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import { collectExec } from "@casama/sandbox";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

const FILE_COMPUTERS = 3;
const FILE_TIMEOUT_MS = 4000;
const FILE_RESULTS = 20;

const shellQuote = (s: string) => `'${s.replace(/'/g, "'\\''")}'`;
/** A find -iname pattern that matches `q` literally anywhere in the name. */
const globLiteral = (q: string) => `*${q.replace(/[\\*?[\]]/g, (c) => `\\${c}`)}*`;

/** One shell command: names first, then contents (text files only), each capped. */
export function fileSearchCommand(q: string) {
  const root = "$HOME/workspace";
  return [
    `cd "${root}" 2>/dev/null || exit 0`,
    `find . -path ./node_modules -prune -o -path ./.git -prune -o -iname ${shellQuote(globLiteral(q))} -print 2>/dev/null | head -n ${FILE_RESULTS} | sed 's/^/N /'`,
    `grep -rIlis --exclude-dir=node_modules --exclude-dir=.git -F -- ${shellQuote(q)} . 2>/dev/null | head -n ${FILE_RESULTS} | sed 's/^/C /'`,
  ].join("; ");
}

export function parseFileSearch(stdout: string) {
  const seen = new Set<string>();
  const out: Array<{ path: string; match: "name" | "content" }> = [];
  for (const line of stdout.split("\n")) {
    const m = /^([NC]) \.\/(.+)$/.exec(line.trim());
    if (!m?.[2] || seen.has(m[2])) continue;
    seen.add(m[2]);
    out.push({ path: m[2], match: m[1] === "N" ? "name" : "content" });
  }
  return out;
}

const timeout = <T>(p: Promise<T>, ms: number) =>
  Promise.race([p, new Promise<null>((r) => setTimeout(() => r(null), ms))]);

export function registerSearchRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  app.openapi(routes.search, async (c) => {
    const claims = c.get("claims") as JwtClaims | undefined;
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    const { org_id, q, files, kinds } = c.req.valid("query");
    // A scoped search (D-235) lists more of the kinds asked for and skips the rest.
    const only = kinds ? new Set(kinds.split(",")) : null;
    const perKind = only ? 25 : 8;
    const query = q.trim();
    if (query.length < 2) throw new ApiError(400, "query_too_short", "Type at least 2 characters");
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<{
        kind: "message" | "chat" | "memory" | "skill" | "routine" | "ticket";
        id: string;
        title: string;
        snippet: string;
        bot_id: string | null;
        conversation_id: string | null;
        created_at: string;
      }>(sql`select kind, id, title, snippet, bot_id, conversation_id, created_at
             from public.search_workspace(${org_id}::uuid, ${query}, ${perKind})`),
    );
    const items = only ? rows.filter((r) => only.has(r.kind)) : rows;

    let fileResults: Array<{
      computer_id: string;
      computer_name: string;
      path: string;
      match: "name" | "content";
    }> = [];
    let searched = 0;
    if (files !== "false" && (!only || only.has("file")) && deps.computers) {
      // Awake computers the caller can see (RLS); never wake one for a search.
      const awake = await withUserSession(db, claims, (tx) =>
        tx.execute<{ id: string; name: string }>(sql`
          select id, name from public.computers
          where org_id = ${org_id}::uuid and provider <> 'local' and state in ('running', 'idle')
          order by last_active_at desc nulls last limit ${FILE_COMPUTERS}`),
      );
      const computers = deps.computers;
      const found = await Promise.all(
        awake.map(async (comp) => {
          const run = async () => {
            const h = await computers.ensureRunning(comp.id);
            const r = await collectExec(
              h.exec(fileSearchCommand(query), { timeoutMs: FILE_TIMEOUT_MS }),
            );
            return parseFileSearch(r.stdout).map((f) => ({
              computer_id: comp.id,
              computer_name: comp.name,
              ...f,
            }));
          };
          return timeout(
            run().catch(() => null),
            FILE_TIMEOUT_MS + 1000,
          );
        }),
      );
      searched = found.filter((f) => f !== null).length;
      fileResults = found.flatMap((f) => f ?? []).slice(0, FILE_RESULTS * 2);
    }

    return c.json(
      {
        query,
        items: items.map((r) => ({ ...r, created_at: iso(r.created_at) })),
        files: fileResults,
        files_searched: searched,
      },
      200,
    );
  });
}
