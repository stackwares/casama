/** Step replay (D-127): list, run (a replay run, no model unless a step fails), delete, and save from a teach recording. */
import type { OpenAPIHono } from "@hono/zod-openapi";
import { replayFromTeach } from "@kasama/agent";
import { routes } from "@kasama/contracts";
import { contentKeys, type JwtClaims, pgErrorCode, withUserSession } from "@kasama/db";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

type Row = {
  id: string;
  org_id: string;
  bot_id: string;
  name: string;
  description: string;
  params: Array<{ name: string; default?: string; secret?: boolean }>;
  steps: Array<{ tool: string; note?: string }>;
  source: "bot";
  runs: number;
  failures: number;
  last_failure: string | null;
  last_run_at: string | null;
  updated_at: string;
};
const out = ({ org_id: _o, ...r }: Row) => ({
  ...r,
  steps: r.steps.map((s) => ({ tool: s.tool, ...(s.note ? { note: s.note } : {}) })),
  last_run_at: r.last_run_at ? iso(r.last_run_at) : null,
  updated_at: iso(r.updated_at),
});

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

export function registerReplayRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const visible = async (claims: JwtClaims, id: string) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<Row & { manage: boolean }>(
        sql`select *, public.can_manage_bot(bot_id) as manage from public.replays where id = ${id}::uuid`,
      ),
    );
    if (!r) throw new ApiError(404, "replay_not_found", "Replay not found");
    return r;
  };

  app.openapi(routes.listReplays, async (c) => {
    const claims = claimsOf(c);
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<Row>(
        sql`select * from public.replays where bot_id = ${c.req.valid("query").bot_id}::uuid order by name`,
      ),
    );
    return c.json({ items: rows.map(out) }, 200);
  });

  app.openapi(routes.runReplay, async (c) => {
    const claims = claimsOf(c);
    const r = await visible(claims, c.req.valid("param").id);
    const params = c.req.valid("json").params ?? {};
    const missing = r.params
      .filter((p) => params[p.name] === undefined && p.default === undefined)
      .map((p) => p.name);
    if (missing.length)
      throw new ApiError(400, "missing_params", `The replay needs: ${missing.join(", ")}`);
    const text = `Run the replay "${r.name}"${
      Object.keys(params).length
        ? ` with ${Object.entries(params)
            .map(([k, v]) => `${k} = ${v}`)
            .join(", ")}`
        : ""
    }.`;
    const created = await withUserSession(db, claims, async (tx) => {
      const [conv] = await tx.execute<{ id: string }>(sql`
        insert into public.conversations (org_id, bot_id, title, created_by, last_message_at)
        values (${r.org_id}::uuid, ${r.bot_id}::uuid, ${`Replay: ${r.name}`}, ${claims.sub}::uuid, now()) returning id`);
      const [run] = await tx.execute<{ id: string }>(sql`
        insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger, replay)
        values (${r.org_id}::uuid, ${r.bot_id}::uuid, ${conv?.id}::uuid, ${claims.sub}::uuid, 'replay',
                ${JSON.stringify({ replay_id: r.id, params })}::jsonb) returning id`);
      await tx.execute(sql`
        insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
        values (${r.org_id}::uuid, ${conv?.id}::uuid, 'user', ${claims.sub}::uuid, ${contentKeys.sealJson(r.org_id, [{ type: "text", text }])}::jsonb, ${run?.id}::uuid)`);
      return { conversation_id: conv?.id as string, run_id: run?.id as string };
    });
    await deps.workflows.startRun(created.run_id);
    return c.json(created, 202);
  });

  app.openapi(routes.deleteReplay, async (c) => {
    const claims = claimsOf(c);
    const r = await visible(claims, c.req.valid("param").id);
    if (!r.manage)
      throw new ApiError(
        403,
        "forbidden",
        "Only people who manage this bot can delete its replays",
      );
    await db.execute(sql`delete from public.replays where id = ${r.id}::uuid`);
    return c.json({ deleted: r.id }, 200);
  });

  app.openapi(routes.replayFromTeach, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const b = c.req.valid("json");
    const [s] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string; org_id: string; bot_id: string; manage: boolean }>(sql`
        select id, org_id, bot_id, public.can_manage_bot(bot_id) as manage from public.teach_sessions where id = ${id}::uuid`),
    );
    if (!s) throw new ApiError(404, "teach_not_found", "Recording not found");
    if (!s.manage)
      throw new ApiError(
        403,
        "forbidden",
        "Only people who manage this bot can save replays for it",
      );
    const steps = await db.execute<{
      seq: number;
      kind: string;
      x: number | null;
      y: number | null;
      button: number | null;
      text: string | null;
      key: string | null;
      secret_name: string | null;
      url: string | null;
    }>(
      sql`select seq, kind, x, y, button, text, key, secret_name, url from public.teach_steps where session_id = ${id}::uuid order by seq`,
    );
    const r = replayFromTeach(steps);
    if (!r.steps.length)
      throw new ApiError(
        409,
        "nothing_to_replay",
        "The recording has no clicks, typing or keys to replay",
      );
    try {
      const [row] = await db.execute<Row>(sql`
        insert into public.replays (org_id, bot_id, name, description, params, steps, source, source_id, created_by)
        values (${s.org_id}::uuid, ${s.bot_id}::uuid, ${b.name}, ${b.description ?? ""}, ${JSON.stringify(r.params)}::jsonb,
                ${JSON.stringify(r.steps)}::jsonb, 'teach', ${id}::uuid, ${claims.sub}::uuid)
        returning *`);
      return c.json(out(row as Row), 201);
    } catch (err) {
      if (pgErrorCode(err) === "23505")
        throw new ApiError(409, "replay_exists", `This bot already has a replay named ${b.name}`);
      throw err;
    }
  });
}
