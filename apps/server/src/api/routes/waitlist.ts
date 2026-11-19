/**
 * The waitlist and invite gate for Casama Cloud (docs/WAITLIST-PLAN.md): joining the list,
 * claiming an invite code for an email address, and the owner's side (numbers, letting people
 * in, campaign codes, the gate itself). The gate is enforced in Auth's hook (routes/abuse.ts);
 * the worker sends the "You're in" emails (services/waitlist.ts).
 */
import { routes } from "@casama/contracts";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { useChallenge, verifyPow } from "../../services/abuse.ts";
import { referralConfig } from "../../services/referrals.ts";
import {
  addWaitlistEntries,
  campaignCodeForm,
  checkSignupGate,
  claimInvite,
  cleanEmail,
  createCampaign,
  gateClosed,
  getSignupGate,
  type InviteCampaign,
  ipHash,
  isDisposableEmail,
  joinsFrom,
  joinWaitlist,
  leaveWaitlist,
  listCampaigns,
  listWaitlist,
  previewInvite,
  queueWaitlist,
  removeWaitlistEntry,
  resolveInviteCode,
  setSignupGate,
  updateCampaign,
  type WaitlistRow,
  waitlistAvailable,
  waitlistStats,
} from "../../services/waitlist.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { clientIp, iso } from "../util.ts";
import { instanceOwnerCheck } from "./admin.ts";
import { requireClaims } from "./autonomy.ts";
import { failureLimiter } from "./joining.ts";
import { internalToken } from "./local.ts";

/** Joins and claims from one address in ten minutes, and new entries from one address in a day. */
const TRIES_PER_TEN_MINUTES = 5;
const JOINS_PER_DAY = 30;

/** Counts every call, unlike failureLimiter, which counts only wrong codes. */
function attemptLimiter(max: number, windowMs: number, now: () => number = Date.now) {
  const windows = new Map<string, { start: number; count: number }>();
  return (key: string) => {
    const t = now();
    let w = windows.get(key);
    if (!w || t - w.start >= windowMs) {
      w = { start: t, count: 0 };
      windows.set(key, w);
      if (windows.size > 50_000)
        for (const [k, v] of windows) if (t - v.start >= windowMs) windows.delete(k);
    }
    w.count++;
    if (w.count > max) {
      const retry = Math.max(1, Math.ceil((w.start + windowMs - t) / 1000));
      throw new ApiError(429, "too_many_attempts", "Too many tries. Wait a few minutes.", {
        headers: { "retry-after": String(retry) },
      });
    }
  };
}

export function registerWaitlistRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db, env } = deps;
  const available = waitlistAvailable(env);
  const secret = internalToken(env);
  const requireOwner = instanceOwnerCheck(deps);
  const welcomeUsd = referralConfig(env).welcomeUsd;
  const misses = failureLimiter();
  const tries = attemptLimiter(TRIES_PER_TEN_MINUTES, 600_000);
  const inviteLink = (code: string) => `${new URL("/invite", env.WAITLIST_URL).toString()}/${code}`;

  const on = () => {
    if (!available) throw new ApiError(404, "waitlist_off", "This server has no waitlist");
  };
  const caller = (c: { req: { header(n: string): string | undefined } }) =>
    clientIp((n) => c.req.header(n), env.TRUSTED_CLIENT_IP_HEADER);
  const email = (input: string) => {
    const e = cleanEmail(input);
    if (!e) throw new ApiError(400, "bad_email", "That doesn't look like an email address.");
    if (isDisposableEmail(e))
      throw new ApiError(400, "disposable_email", "Use a permanent email address.");
    return e;
  };
  /** A solved sign-up puzzle, good once: joining and claiming cost a second or two of work. */
  const prove = async (p: { challenge: string; nonce: string }) => {
    const refused = () => new ApiError(403, "proof_required", "That check has expired. Try again.");
    if (!verifyPow(`${secret}:signup`, p.challenge, p.nonce).ok) throw refused();
    if (!(await useChallenge(db, p.challenge))) throw refused();
  };
  const gateState = async () => {
    const gate = await getSignupGate(db);
    return { gate, closed: gateClosed(gate) };
  };

  // --- no sign-in -------------------------------------------------------------------------------

  app.openapi(routes.joinWaitlist, async (c) => {
    on();
    const ip = caller(c);
    tries(`ip:${ip}`);
    const body = c.req.valid("json");
    const address = email(body.email);
    await prove(body.proof);
    const hash = ipHash(secret, ip);
    if ((await joinsFrom(db, hash)) >= JOINS_PER_DAY)
      throw new ApiError(429, "too_many_attempts", "Too many tries today. Try again tomorrow.");
    await joinWaitlist(db, {
      email: address,
      source: body.source,
      ref: body.ref,
      note: body.note,
      selfHosting: body.self_hosting,
      newsletter: body.newsletter,
      ipHash: hash,
    });
    // The same answer whoever the address belongs to: nothing here says who is on the list.
    return c.json({ ok: true as const }, 200);
  });

  app.openapi(routes.redeemInvite, async (c) => {
    on();
    const ip = caller(c);
    const key = `ip:${ip}`;
    tries(key);
    misses.check(key);
    const body = c.req.valid("json");
    const address = email(body.email);
    await prove(body.proof);
    const notFound = () => {
      misses.miss(key);
      return new ApiError(
        404,
        "invite_not_found",
        "That invite code doesn't exist. Check it and try again.",
      );
    };
    const code = await resolveInviteCode(db, body.code);
    if (!code) throw notFound();
    const gate = await getSignupGate(db);
    const claimed = await claimInvite(db, {
      email: address,
      code,
      perPerson: gate.invites_per_person,
      newsletter: body.newsletter,
      source: body.source,
      ipHash: ipHash(secret, ip),
    });
    if (!claimed) throw notFound();
    return c.json({ outcome: claimed.outcome, kind: claimed.kind }, 200);
  });

  app.openapi(routes.previewInviteCode, async (c) => {
    on();
    const key = `ip:${caller(c)}`;
    misses.check(key);
    const code = await resolveInviteCode(db, c.req.valid("query").code);
    const gate = await getSignupGate(db);
    const row = code ? await previewInvite(db, code, gate.invites_per_person) : null;
    if (!row) {
      misses.miss(key);
      throw new ApiError(404, "invite_not_found", "That invite code doesn't exist");
    }
    // Short: whether an invite is left changes as people claim them.
    c.header("cache-control", "public, max-age=30");
    return c.json(
      {
        kind: row.kind,
        label: row.label,
        inviter_name: row.inviter_name,
        available: row.available,
        welcome_usd: row.kind === "personal" ? welcomeUsd : 0,
      },
      200,
    );
  });

  app.openapi(routes.leaveWaitlist, async (c) => {
    on();
    tries(`ip:${caller(c)}`);
    if (!(await leaveWaitlist(db, secret, c.req.valid("json").token)))
      throw new ApiError(400, "bad_token", "That link isn't valid any more.");
    return c.json({ ok: true as const }, 200);
  });

  // --- owner ------------------------------------------------------------------------------------

  const entryOut = (r: WaitlistRow) => ({
    id: r.id,
    email: r.email,
    status: r.status,
    source: r.source,
    ref: r.ref,
    self_hosting: r.self_hosting,
    note: r.note,
    priority: r.priority,
    invite_code: r.invite_code,
    admitted_via: r.admitted_via,
    admitted_at: r.admitted_at ? iso(r.admitted_at) : null,
    joined_at: r.joined_at ? iso(r.joined_at) : null,
    created_at: iso(r.created_at),
  });
  const campaignOut = (r: InviteCampaign) => ({
    code: r.code,
    label: r.label,
    max_uses: r.max_uses,
    used: r.used,
    per_day: r.per_day,
    starts_at: r.starts_at ? iso(r.starts_at) : null,
    expires_at: r.expires_at ? iso(r.expires_at) : null,
    disabled: !!r.disabled_at,
    created_at: iso(r.created_at),
    link: inviteLink(r.code),
  });

  app.openapi(routes.adminWaitlist, async (c) => {
    on();
    await requireOwner(requireClaims(c.get("claims")));
    const q = c.req.valid("query");
    const items = await listWaitlist(
      db,
      {
        status: q.status,
        source: q.source,
        ref: q.ref,
        selfHosting: q.self_hosting === undefined ? undefined : q.self_hosting === "true",
        q: q.q,
      },
      q.limit ?? 50,
      q.offset ?? 0,
    );
    return c.json(
      { stats: await waitlistStats(db), gate: await gateState(), items: items.map(entryOut) },
      200,
    );
  });

  app.openapi(routes.adminAdmitWaitlist, async (c) => {
    on();
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const body = c.req.valid("json");
    if (!body.ids?.length && !body.count)
      throw new ApiError(400, "validation_failed", "Give the entries to let in, or how many");
    const count = await queueWaitlist(db, {
      ids: body.ids,
      count: body.count,
      filter: { source: body.source, ref: body.ref, selfHosting: body.self_hosting },
      by: claims.sub,
      via: "batch",
    });
    deps.logger.info("waitlist: people chosen", { by: claims.sub, count });
    return c.json({ count }, 200);
  });

  app.openapi(routes.adminAddWaitlistEntries, async (c) => {
    on();
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const body = c.req.valid("json");
    const good: string[] = [];
    const skipped: string[] = [];
    for (const raw of body.emails) {
      const e = cleanEmail(raw);
      if (e) good.push(e);
      else skipped.push(raw);
    }
    const count = await addWaitlistEntries(db, good, { by: claims.sub, notify: body.notify });
    deps.logger.info("waitlist: addresses added by hand", { by: claims.sub, count });
    return c.json({ count, ...(skipped.length ? { skipped } : {}) }, 200);
  });

  app.openapi(routes.adminRemoveWaitlistEntry, async (c) => {
    on();
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    if (!(await removeWaitlistEntry(db, c.req.valid("param").id)))
      throw new ApiError(404, "not_found", "No such entry");
    deps.logger.info("waitlist: entry removed", { by: claims.sub });
    return c.body(null, 204);
  });

  app.openapi(routes.adminSignupGate, async (c) => {
    on();
    await requireOwner(requireClaims(c.get("claims")));
    return c.json(await gateState(), 200);
  });

  app.openapi(routes.adminSetSignupGate, async (c) => {
    on();
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const { gate, errors } = checkSignupGate({
      ...(await getSignupGate(db)),
      ...c.req.valid("json"),
    });
    if (!gate) throw new ApiError(400, "validation_failed", errors.join("; "));
    await setSignupGate(db, gate);
    deps.logger.info("signup gate changed", {
      by: claims.sub,
      mode: gate.mode,
      opens_at: gate.opens_at,
    });
    return c.json(await gateState(), 200);
  });

  app.openapi(routes.adminInviteCampaigns, async (c) => {
    on();
    await requireOwner(requireClaims(c.get("claims")));
    return c.json({ items: (await listCampaigns(db)).map(campaignOut) }, 200);
  });

  app.openapi(routes.adminCreateInviteCampaign, async (c) => {
    on();
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const body = c.req.valid("json");
    const code = campaignCodeForm(body.code);
    if (!code)
      throw new ApiError(
        400,
        "bad_code",
        "A campaign code is letters, digits and hyphens: 9 or more characters, or with a hyphen.",
      );
    const row = await createCampaign(db, {
      code,
      label: body.label.trim(),
      maxUses: body.max_uses,
      perDay: body.per_day,
      startsAt: body.starts_at,
      expiresAt: body.expires_at,
      by: claims.sub,
    });
    if (!row) throw new ApiError(409, "conflict", "A campaign with that code already exists");
    deps.logger.info("invite campaign made", { by: claims.sub, code, max_uses: body.max_uses });
    return c.json(campaignOut(row), 200);
  });

  app.openapi(routes.adminUpdateInviteCampaign, async (c) => {
    on();
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const body = c.req.valid("json");
    const code = campaignCodeForm(c.req.valid("param").code);
    const row = code
      ? await updateCampaign(db, code, {
          label: body.label?.trim(),
          maxUses: body.max_uses,
          ...(Object.hasOwn(body, "per_day") ? { perDay: body.per_day } : {}),
          ...(Object.hasOwn(body, "starts_at") ? { startsAt: body.starts_at } : {}),
          ...(Object.hasOwn(body, "expires_at") ? { expiresAt: body.expires_at } : {}),
          disabled: body.disabled,
        })
      : null;
    if (!row) throw new ApiError(404, "not_found", "No such campaign");
    deps.logger.info("invite campaign changed", { by: claims.sub, code });
    return c.json(campaignOut(row), 200);
  });
}
