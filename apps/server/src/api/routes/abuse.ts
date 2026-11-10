/**
 * Kasama Cloud abuse controls (D-094):
 * - GET /v1/signup/challenge: a proof-of-work puzzle for clients without App Check.
 * - POST /hooks/auth/before-user-created: Supabase Auth's hook; a new email account must carry a
 *   valid `signup_proof` in its user metadata (App Check token or solved puzzle).
 * - POST /internal/abuse: the egress proxy reports abuse; mining stops the computer and suspends
 *   the workspace.
 */
import type { OpenAPIHono } from "@hono/zod-openapi";
import { routes } from "@kasama/contracts";
import { sql } from "drizzle-orm";
import { verifyStandardWebhook } from "../../billing/dodo.ts";
import {
  abuseControlsOn,
  newChallenge,
  signupProofKinds,
  suspendOrg,
  useChallenge,
  verifyAppCheck,
  verifyPow,
} from "../../services/abuse.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { internalToken } from "./local.ts";

/** Signals that stop the computer and suspend the workspace at once. */
const SEVERE = new Set(["mining_pool"]);
/** Floods within an hour before the workspace is suspended. */
const FLOOD_LIMIT = 3;

export function registerAbuseRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db, env } = deps;
  const secret = `${internalToken(env)}:signup`;

  app.openapi(routes.getSignupChallenge, (c) => {
    const ch = newChallenge(secret, env.SIGNUP_POW_DIFFICULTY);
    return c.json({ ...ch, expires_at: ch.expires_at.toISOString() }, 200);
  });

  // Supabase Auth hook: answer 200 {} to allow, or an error object to refuse the sign-up.
  app.post("/hooks/auth/before-user-created", async (c) => {
    const body = await c.req.text();
    if (env.AUTH_HOOK_SECRET) {
      try {
        verifyStandardWebhook(env.AUTH_HOOK_SECRET.replace(/^v1,/, ""), c.req.raw.headers, body);
      } catch {
        return c.json({ error: { http_code: 401, message: "Bad hook signature" } }, 401);
      }
    } else if (abuseControlsOn(env)) {
      // The gate is on but nobody configured the hook secret: refuse rather than trust anyone.
      return c.json({ error: { http_code: 500, message: "Sign-up hook is not configured" } }, 500);
    }
    if (!abuseControlsOn(env)) return c.json({}, 200);
    const payload = JSON.parse(body || "{}") as {
      user?: {
        email?: string;
        app_metadata?: { provider?: string };
        user_metadata?: {
          signup_proof?: { kind?: string; token?: string; challenge?: string; nonce?: string };
        };
      };
    };
    const user = payload.user ?? {};
    const provider = user.app_metadata?.provider ?? "email";
    // Google, Apple and SSO sign-ins already prove a real account elsewhere.
    if (provider !== "email" && provider !== "phone") return c.json({}, 200);
    const proof = user.user_metadata?.signup_proof;
    const kinds = signupProofKinds(env);
    const refuse = async (reason: string) => {
      await db.execute(sql`
        insert into public.abuse_events (kind, detail)
        values ('signup_blocked', ${JSON.stringify({ reason, email_domain: (user.email ?? "").split("@")[1] ?? null })}::jsonb)`);
      return c.json(
        {
          error: {
            http_code: 403,
            message: "Sign-up needs a check from the app. Update the app and try again.",
          },
        },
        403,
      );
    };
    if (!proof?.kind || !kinds.includes(proof.kind as "pow")) return refuse("missing_proof");
    if (proof.kind === "pow") {
      const v = verifyPow(secret, proof.challenge ?? "", proof.nonce ?? "");
      if (!v.ok) return refuse(`pow_${v.reason}`);
      if (!(await useChallenge(db, proof.challenge ?? ""))) return refuse("pow_reused");
      return c.json({}, 200);
    }
    if (!env.APP_CHECK_PROJECT_NUMBER) return refuse("app_check_unconfigured");
    try {
      await verifyAppCheck(proof.token ?? "", {
        projectNumber: env.APP_CHECK_PROJECT_NUMBER,
        jwksUrl: env.APP_CHECK_JWKS_URL,
        issuerBase: env.APP_CHECK_ISSUER_BASE,
      });
      return c.json({}, 200);
    } catch {
      return refuse("app_check_invalid");
    }
  });

  // The egress proxy reports what it blocked (internal token checked by the /internal/* middleware).
  app.post("/internal/abuse", async (c) => {
    const b = (await c.req.json().catch(() => ({}))) as {
      computer?: string;
      kind?: string;
      target?: string;
    };
    if (!b.computer || !/^[0-9a-f-]{36}$/i.test(b.computer) || !b.kind)
      return c.json({ code: "bad_request" }, 400);
    const kind = ["mining_pool", "blocked_port", "egress_flood"].includes(b.kind) ? b.kind : null;
    if (!kind) return c.json({ code: "bad_request" }, 400);
    const [comp] = await db.execute<{ org_id: string }>(
      sql`select org_id from public.computers where id = ${b.computer}::uuid`,
    );
    if (!comp) return c.json({ code: "computer_not_found" }, 404);
    const on = abuseControlsOn(env);
    let action = "recorded";
    if (on) {
      const [floods] = await db.execute<{ n: number }>(sql`
        select count(*)::int as n from public.abuse_events
        where org_id = ${comp.org_id}::uuid and kind = 'egress_flood' and created_at > now() - interval '1 hour'`);
      const suspend =
        SEVERE.has(kind) || (kind === "egress_flood" && (floods?.n ?? 0) + 1 >= FLOOD_LIMIT);
      if (suspend) {
        await suspendOrg(
          { db, stopComputer: deps.computers ? (id) => deps.computers!.sleep(id) : undefined },
          comp.org_id,
          kind === "mining_pool" ? "Crypto mining detected" : "Repeated outbound traffic floods",
          { kind: "system" },
        );
        action = "workspace_suspended";
        // Tell the instance owners.
        const admins = (env.INSTANCE_ADMIN_EMAILS ?? "")
          .split(",")
          .map((e) => e.trim().toLowerCase())
          .filter(Boolean);
        if (admins.length)
          await db.execute(sql`
            insert into public.notifications (user_id, kind, payload)
            select u.id, 'abuse', ${JSON.stringify({ title: "A workspace was suspended", body: `${kind} on computer ${b.computer}`, link: "/settings/admin" })}::jsonb
            from auth.users u where lower(u.email) = any(${admins})`);
      }
    }
    await db.execute(sql`
      insert into public.abuse_events (org_id, computer_id, kind, detail, action)
      values (${comp.org_id}::uuid, ${b.computer}::uuid, ${kind}, ${JSON.stringify({ target: b.target ?? null })}::jsonb, ${action})`);
    return c.json({ ok: true, action }, 200);
  });
}
