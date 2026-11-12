/** Action rules (D-115): people manage them here; bots have no tool that changes them. */

import { track } from "@casama/agent";
import { routes } from "@casama/contracts";
import { type JwtClaims, pgErrorCode, withUserSession } from "@casama/db";
import { type ActionRule, describeActionRule } from "@casama/domain";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

type Row = ActionRule & { org_id: string; created_at: string };
const out = (r: Row) => ({ ...r, preview: describeActionRule(r), created_at: iso(r.created_at) });

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

export function registerActionRuleRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  app.openapi(routes.listActionRules, async (c) => {
    const claims = claimsOf(c);
    const { org_id, bot_id } = c.req.valid("query");
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<Row>(sql`
        select id, org_id, bot_id, match_kind, match_value, target, rule, created_at from public.action_rules
        where org_id = ${org_id}::uuid and (bot_id is null or bot_id = ${bot_id ?? null}::uuid)
        order by bot_id nulls first, match_kind, match_value, created_at`),
    );
    return c.json({ items: rows.map(out) }, 200);
  });

  app.openapi(routes.createActionRule, async (c) => {
    const claims = claimsOf(c);
    const b = c.req.valid("json");
    if (b.rule === "allow_within_limits" && !b.target)
      throw new ApiError(
        400,
        "limits_required",
        "Say what the limits are (domains, recipients or an amount)",
      );
    if (
      b.match_kind === "category" &&
      !["send", "pay", "delete", "publish", "share", "sign_in"].includes(b.match_value)
    )
      throw new ApiError(
        400,
        "unknown_category",
        "Pick send, pay, delete, publish, share or sign_in",
      );
    try {
      const [row] = await withUserSession(db, claims, (tx) =>
        tx.execute<Row>(sql`
          insert into public.action_rules (org_id, bot_id, match_kind, match_value, target, rule, created_by)
          values (${b.org_id}::uuid, ${b.bot_id ?? null}::uuid, ${b.match_kind}, ${b.match_value},
                  ${b.target ? JSON.stringify(b.target) : null}::jsonb, ${b.rule}, ${claims.sub}::uuid)
          returning id, org_id, bot_id, match_kind, match_value, target, rule, created_at`),
      );
      if (!row) throw new Error("rule insert returned nothing");
      await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
        values (${b.org_id}::uuid, 'user', ${claims.sub}::uuid, 'action_rule.created', 'action_rule', ${row.id}::uuid, ${JSON.stringify({ preview: describeActionRule(row) })}::jsonb)`);
      track(db, {
        event: "action_rule_created",
        userId: claims.sub,
        orgId: b.org_id,
        properties: { decision: b.rule },
      });
      return c.json(out(row), 201);
    } catch (err) {
      if (pgErrorCode(err) === "42501")
        throw new ApiError(
          403,
          "forbidden",
          "Workspace rules need an admin; a bot's rules need someone who manages it",
        );
      throw err;
    }
  });

  app.openapi(routes.deleteActionRule, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string; org_id: string }>(
        sql`delete from public.action_rules where id = ${id}::uuid returning id, org_id`,
      ),
    );
    if (!rows[0])
      throw new ApiError(404, "rule_not_found", "Rule not found (or you can't change it)");
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id)
      values (${rows[0].org_id}::uuid, 'user', ${claims.sub}::uuid, 'action_rule.deleted', 'action_rule', ${id}::uuid)`);
    return c.json({ deleted: id }, 200);
  });
}
