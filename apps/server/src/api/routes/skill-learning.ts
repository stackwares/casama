/** Self-improving skills (D-126): proposals to accept (with edits) or dismiss, and skill stats. */
import type { OpenAPIHono } from "@hono/zod-openapi";
import { applySkillProposal } from "@kasama/agent";
import { routes } from "@kasama/contracts";
import { type JwtClaims, pgErrorCode, withUserSession } from "@kasama/db";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

type Row = {
  id: string;
  org_id: string;
  bot_id: string;
  kind: "new";
  skill_id: string | null;
  name: string;
  description: string;
  body_md: string;
  previous_body_md: string | null;
  tools: string[];
  reason: string;
  status: "pending";
  created_at: string;
};
const COLS = sql`id, org_id, bot_id, kind, skill_id, name, description, body_md, previous_body_md, tools, reason, status, created_at`;
const out = ({ org_id: _o, ...r }: Row) => ({ ...r, created_at: iso(r.created_at) });

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

export function registerSkillLearningRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  /** A pending proposal for a bot this person manages. */
  const pending = async (claims: JwtClaims, id: string) => {
    const [p] = await withUserSession(db, claims, (tx) =>
      tx.execute<Row & { manage: boolean }>(sql`select ${COLS}, public.can_manage_bot(bot_id) as manage from public.skill_proposals where id = ${id}::uuid`),
    );
    if (!p) throw new ApiError(404, "proposal_not_found", "Proposal not found");
    if (!p.manage) throw new ApiError(403, "forbidden", "Only people who manage this bot can change its skills");
    if (p.status !== "pending") throw new ApiError(409, "proposal_closed", `This proposal was already ${p.status}`);
    return p;
  };
  const reload = async (id: string) => {
    const [r] = await db.execute<Row>(sql`select ${COLS} from public.skill_proposals where id = ${id}::uuid`);
    return out(r as Row);
  };

  app.openapi(routes.listSkillProposals, async (c) => {
    const claims = claimsOf(c);
    const { org_id, bot_id } = c.req.valid("query");
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<Row>(sql`select ${COLS} from public.skill_proposals where org_id = ${org_id}::uuid and status = 'pending'
        and (${bot_id ?? null}::uuid is null or bot_id = ${bot_id ?? null}::uuid) order by created_at desc limit 50`),
    );
    return c.json({ items: rows.map(out) }, 200);
  });

  app.openapi(routes.acceptSkillProposal, async (c) => {
    const claims = claimsOf(c);
    const p = await pending(claims, c.req.valid("param").id);
    const b = c.req.valid("json");
    try {
      await applySkillProposal(db, p.id, { name: b.name, description: b.description, body: b.body_md });
    } catch (err) {
      if (pgErrorCode(err) === "23505") throw new ApiError(409, "skill_exists", "This bot already has a skill with that name");
      throw err;
    }
    await db.execute(sql`update public.skill_proposals set status = 'accepted', resolved_at = now(), resolved_by = ${claims.sub}::uuid where id = ${p.id}::uuid`);
    return c.json(await reload(p.id), 200);
  });

  app.openapi(routes.dismissSkillProposal, async (c) => {
    const claims = claimsOf(c);
    const p = await pending(claims, c.req.valid("param").id);
    await db.execute(sql`update public.skill_proposals set status = 'dismissed', resolved_at = now(), resolved_by = ${claims.sub}::uuid where id = ${p.id}::uuid`);
    return c.json(await reload(p.id), 200);
  });

  app.openapi(routes.getSkillStats, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const [s] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string; name: string; org_id: string; bot_id: string | null }>(sql`select id, name, org_id, bot_id from public.skills where id = ${id}::uuid`),
    );
    if (!s) throw new ApiError(404, "skill_not_found", "Skill not found");
    const [st] = await db.execute<{ uses: number; ok: number; bad: number; corrected: number; last_fail: string | null; last_run: string | null }>(sql`
      select count(*)::int as uses, count(*) filter (where status = 'completed' and not corrected)::int as ok,
        count(*) filter (where status = 'failed')::int as bad, count(*) filter (where corrected)::int as corrected,
        max(created_at) filter (where status = 'failed' or corrected) as last_fail,
        (array_agg(run_id order by created_at desc) filter (where status = 'failed' or corrected))[1] as last_run
      from public.run_digests where org_id = ${s.org_id}::uuid and ${s.name} = any(skills)
        and (${s.bot_id}::uuid is null or bot_id = ${s.bot_id}::uuid)`);
    const revisions = await db.execute<{ id: string; description: string; body_md: string; changed_by_bot: string | null; created_at: string }>(sql`
      select id, description, body_md, changed_by_bot, created_at from public.skill_revisions where skill_id = ${id}::uuid order by created_at desc limit 50`);
    const uses = st?.uses ?? 0;
    return c.json(
      {
        uses,
        successes: st?.ok ?? 0,
        failures: st?.bad ?? 0,
        corrections: st?.corrected ?? 0,
        success_rate: uses ? (st?.ok ?? 0) / uses : null,
        last_failure_at: st?.last_fail ? iso(st.last_fail) : null,
        last_failure_run_id: st?.last_run ?? null,
        revisions: revisions.map((r) => ({ id: r.id, description: r.description, body_md: r.body_md, by_bot: !!r.changed_by_bot, created_at: iso(r.created_at) })),
      },
      200,
    );
  });
}
