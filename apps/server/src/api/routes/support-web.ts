/**
 * Casama Help on the websites (D-401): casama.ai and docs.casama.ai visitors, signed out.
 *
 * It answers from the same docs as the app's assistant (D-298) and follows the same shared rules,
 * but sees no account and can do nothing: its tools are search_docs, get_plans, note_gap (a
 * question the docs didn't answer, kept without any identity so the FAQ can grow) and
 * decline_off_topic. Anyone can reach it, so it is fenced harder than the app's:
 *
 * - only the allowed site origins, and in production only after a Cloudflare Turnstile check,
 *   which buys a short session tied to the visitor's address (signed with a key that lives only in
 *   this process, so a restart just asks for a new check);
 * - per address: one request at a time, a few a minute, a daily message and dollar cap, a cap per
 *   session, and three off-topic requests pause it for a day;
 * - short inputs and answers, few tool rounds;
 * - its own daily budget (SUPPORT_WEB_DAILY_USD), apart from the app's, and its own capped model key
 *   when SUPPORT_WEB_UPSTREAM_KEY is set, so a flood on the website can't use up help for customers
 *   and a bug in these counters still stops at the provider's cap.
 *
 * Counters live in public.support_usage under 'web:…' keys.
 */
import { createHash, createHmac, randomBytes, timingSafeEqual } from "node:crypto";
import { withOpenRouterRouting } from "@casama/agent";
import { routes } from "@casama/contracts";
import { CLOUD_MODEL_DEFAULTS } from "@casama/domain";
import { captureError } from "@casama/observability";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { cloudModelRouting } from "../../env.ts";
import { SupportDocs } from "../../services/support-docs.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { clientIp } from "../util.ts";
import { instanceOwnerCheck } from "./admin.ts";
import { billingFor } from "./billing.ts";
import { bump, citedSources, pausedUntil, SHARED_RULES, usage } from "./support.ts";

type Msg = { role: "user" | "assistant"; content: string };

/** The fences around the website assistant. Exported for tests. */
export const WebLimits = {
  perMinute: 5,
  /** The visitor's messages in one session before it suggests email or the app. */
  perSession: 8,
  addressDailyUsd: 0.1,
  strikesBeforePause: 3,
  pauseHours: 24,
  sessionMs: 2 * 3_600_000,
  /** One message, and what of the conversation reaches the model. */
  messageChars: 1_000,
  historyMessages: 8,
  historyChars: 8_000,
  maxTokens: 600,
  toolRounds: 3,
  callsPerRound: 4,
  timeoutMs: 40_000,
  /** Questions kept for the FAQ, and for how long. */
  gapChars: 200,
  gapDays: 90,
  /** Share of the daily budget at which the team hears about it. */
  alertAt: 0.8,
};

const SYSTEM = `You are Casama Help, the support assistant on Casama's websites (casama.ai and its docs). Casama is an app where people run AI bots ("Casama bots") that chat, remember, use apps and computers, run routines and work together in workspaces. Casama Cloud is the hosted service (casama.ai); people can also self-host the server for free.

The person is a website visitor. They may not have an account, and you can't see any account, purchase or workspace. Your job: answer questions about what Casama is, what it does, plans and prices, privacy and safety, self-hosting, and how to use it, so they can decide and get started.

How to answer:
- Search the docs (search_docs) before answering anything about Casama, and base the answer only on what you find. Never invent features, settings, menu names, prices, limits or policies. For prices and what plans include, use get_plans.
- If the docs don't answer it, call note_gap with the question in a few words, say plainly you're not sure, and point to support@casama.ai.
- Questions about their own account, a charge, a purchase that didn't show up, a bot that stopped, or anything you'd need to look up: say you can't see accounts from the website, and that they get account help by signing in and opening Settings > Help & support in the app, or by emailing support@casama.ai. Never guess about their account.
- Comparisons with other products: only what the docs and casama.ai's pages say; stay fair and don't run others down.
${SHARED_RULES.sources}
${SHARED_RULES.brief}
${SHARED_RULES.refunds}
${SHARED_RULES.stores}
${SHARED_RULES.inviteOnly}

What you must not do:
${SHARED_RULES.onlyCasama}
${SHARED_RULES.never}
- Never ask for an email address or any personal details.`;

const TOOLS = [
  {
    type: "function",
    function: {
      name: "search_docs",
      description:
        "Search the Casama docs and casama.ai's pages (FAQ, guides, pricing, explainers). Returns the best-matching sections with their links.",
      parameters: {
        type: "object",
        properties: { query: { type: "string", description: "A few keywords" } },
        required: ["query"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "get_plans",
      description:
        "Casama Cloud's plans and credit packs on sale now, with their limits and prices.",
      parameters: { type: "object", properties: {} },
    },
  },
  {
    type: "function",
    function: {
      name: "note_gap",
      description:
        "Record a Casama question the docs didn't answer, so the team can add it to the FAQ. No names or personal details.",
      parameters: {
        type: "object",
        properties: { question: { type: "string", description: "The question in a few words" } },
        required: ["question"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "decline_off_topic",
      description: "Record that the request isn't about Casama, before declining it.",
      parameters: { type: "object", properties: {} },
    },
  },
] as const;

/** The newest messages that fit, oldest first, starting with the visitor's. Exported for tests. */
export function trimWebHistory(messages: Msg[]): Msg[] {
  const out: Msg[] = [];
  let chars = 0;
  for (let i = messages.length - 1; i >= 0 && out.length < WebLimits.historyMessages; i--) {
    const m = messages[i] as Msg;
    const content = m.content.slice(0, m.role === "user" ? WebLimits.messageChars : 2_000);
    if (chars + content.length > WebLimits.historyChars && out.length) break;
    chars += content.length;
    out.unshift({ role: m.role, content });
  }
  while (out.length && out[0]?.role !== "user") out.shift();
  return out;
}

/** A question for the FAQ list with anything that looks like a person taken out. Exported for tests. */
export function scrubGap(text: string): string {
  return text
    .replace(/[\w.+-]+@[\w-]+\.[\w.-]+/g, "[email]")
    .replace(/https?:\/\/\S+/g, "[link]")
    .replace(/\+?\(?\d[\d\s().-]{6,}\d/g, "[number]")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, WebLimits.gapChars);
}

/** Sessions: `<expiry ms>.<address hash>.<nonce>.<mac>`, signed with a key only this process holds. */
export function sessionSigner(key: Buffer = randomBytes(32)) {
  const mac = (payload: string) =>
    createHmac("sha256", key).update(payload).digest("base64url").slice(0, 32);
  return {
    issue(addr: string, now = Date.now()) {
      const exp = now + WebLimits.sessionMs;
      const payload = `${exp}.${addr}.${randomBytes(9).toString("base64url")}`;
      return { session: `${payload}.${mac(payload)}`, expiresAt: new Date(exp) };
    },
    /** The session's id when it's genuine, unexpired and from the same address; otherwise null. */
    check(session: string, addr: string, now = Date.now()): string | null {
      const parts = session.split(".");
      if (parts.length !== 4) return null;
      const [exp, a, nonce, sig] = parts as [string, string, string, string];
      const want = Buffer.from(mac(`${exp}.${a}.${nonce}`));
      const got = Buffer.from(sig);
      if (want.length !== got.length || !timingSafeEqual(want, got)) return null;
      if (!(Number(exp) > now) || a !== addr) return null;
      return nonce;
    },
  };
}

const limited = (message: string, code = "support_limit") => new ApiError(429, code, message);

export function registerSupportWebRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db, env } = deps;
  const billing = billingFor(deps);
  const docs = new SupportDocs({ docsUrl: env.DOCS_URL });
  const key = env.SUPPORT_WEB_UPSTREAM_KEY || env.CLOUD_MODEL_UPSTREAM_KEY;
  const production = env.NODE_ENV === "production";
  const turnstile = !!(env.TURNSTILE_SITE_KEY && env.TURNSTILE_SECRET_KEY);
  // Production needs the human check: without it the endpoint would be a free model API.
  const on = env.SUPPORT_WEB && !!key && (turnstile || !production);
  const model = env.SUPPORT_WEB_MODEL ?? env.SUPPORT_MODEL ?? CLOUD_MODEL_DEFAULTS.chat;
  const fetchImpl = deps.supportFetch ?? fetch;
  const origins = new Set(
    env.SUPPORT_WEB_ORIGINS.split(",")
      .map((o) => o.trim())
      .filter(Boolean),
  );
  const signer = sessionSigner();
  const busy = new Set<string>();
  const minute = new Map<string, { start: number; count: number }>();
  const perSession = new Map<string, { exp: number; count: number }>();
  let alertedDay = "";

  const addrHash = (header: (n: string) => string | undefined) =>
    createHash("sha256")
      .update(`web:${clientIp(header, env.TRUSTED_CLIENT_IP_HEADER)}`)
      .digest("hex")
      .slice(0, 24);

  /** Only the sites may call it; local pages too while developing. */
  const checkOrigin = (origin: string | undefined) => {
    if (origin && origins.has(origin)) return;
    if (!production && (!origin || /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)))
      return;
    throw new ApiError(403, "origin_not_allowed", "Casama Help answers on casama.ai");
  };

  const assistantOff = () =>
    new ApiError(403, "assistant_off", "Casama Help isn't available here right now");

  app.openapi(routes.getSupportWebConfig, (c) =>
    c.json(
      {
        assistant: on,
        turnstile_site_key: on && turnstile ? (env.TURNSTILE_SITE_KEY ?? null) : null,
        email: env.SUPPORT_INBOX,
        docs_url: env.DOCS_URL,
      },
      200,
    ),
  );

  app.openapi(routes.createSupportWebSession, async (c) => {
    checkOrigin(c.req.header("origin"));
    if (!on) throw assistantOff();
    const addr = addrHash((n) => c.req.header(n));
    const paused = await pausedUntil(db, `web:ip:${addr}`);
    if (paused)
      throw limited(
        "Casama Help is paused for you for now. You can still email support@casama.ai.",
        "support_paused",
      );
    if (turnstile) {
      const token = c.req.valid("json").turnstile_token;
      if (!token)
        throw new ApiError(400, "turnstile_failed", "The check didn't finish. Try again.");
      const form = new URLSearchParams({
        secret: env.TURNSTILE_SECRET_KEY as string,
        response: token,
        remoteip: clientIp((n) => c.req.header(n), env.TRUSTED_CLIENT_IP_HEADER),
      });
      let ok = false;
      try {
        const res = await fetchImpl("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
          method: "POST",
          body: form,
          signal: AbortSignal.timeout(10_000),
        });
        const data = (await res.json()) as { success?: boolean; hostname?: string };
        const hosts = new Set([...origins].map((o) => o.replace(/^https?:\/\//, "")));
        ok = data.success === true && (!data.hostname || hosts.has(data.hostname) || !production);
      } catch {
        ok = false;
      }
      if (!ok)
        throw new ApiError(403, "turnstile_failed", "The check didn't pass. Reload and try again.");
    }
    const s = signer.issue(addr);
    return c.json({ session: s.session, expires_at: s.expiresAt.toISOString() }, 200);
  });

  app.openapi(routes.supportWebChat, async (c) => {
    checkOrigin(c.req.header("origin"));
    if (!on) throw assistantOff();
    const body = c.req.valid("json");
    const addr = addrHash((n) => c.req.header(n));
    const sid = signer.check(body.session, addr);
    if (!sid)
      throw new ApiError(401, "web_session_invalid", "Your session ended. Start a new one.");
    const history = trimWebHistory(body.messages);
    if (history.at(-1)?.role !== "user")
      throw new ApiError(400, "validation_failed", "The last message must be yours");
    if ((body.messages.at(-1)?.content.length ?? 0) > WebLimits.messageChars)
      throw new ApiError(
        400,
        "message_too_long",
        `Keep a message under ${WebLimits.messageChars} characters`,
      );

    const me = `web:ip:${addr}`;
    if (busy.has(me)) throw limited("Wait for the answer to your last message", "support_busy");
    const now = Date.now();
    const w = minute.get(me);
    if (!w || now - w.start >= 60_000) minute.set(me, { start: now, count: 1 });
    else if (++w.count > WebLimits.perMinute)
      throw limited("That's a lot of messages at once. Try again in a minute.", "rate_limited");
    if (minute.size > 20_000)
      for (const [k, v] of minute) if (now - v.start >= 60_000) minute.delete(k);
    const s = perSession.get(sid) ?? { exp: now + WebLimits.sessionMs, count: 0 };
    if (s.count >= WebLimits.perSession)
      throw limited(
        "This conversation is getting long. For more help, email support@casama.ai or open Help & support in the app.",
      );
    if (perSession.size > 50_000)
      for (const [k, v] of perSession) if (v.exp < now) perSession.delete(k);

    const paused = await pausedUntil(db, me);
    if (paused)
      throw limited(
        "Casama Help is paused for you for now. You can still email support@casama.ai.",
        "support_paused",
      );
    const [mine, everyone] = await Promise.all([usage(db, me), usage(db, "web:all")]);
    if (everyone.usd >= env.SUPPORT_WEB_DAILY_USD)
      throw limited(
        "Casama Help is busy right now. The FAQ may have your answer, or email support@casama.ai.",
        "support_busy_global",
      );
    if (mine.messages >= env.SUPPORT_WEB_MESSAGES_PER_DAY || mine.usd >= WebLimits.addressDailyUsd)
      throw limited(
        "You've reached today's limit for Casama Help. The FAQ may have your answer, or email support@casama.ai.",
      );

    busy.add(me);
    s.count++;
    perSession.set(sid, s);
    let spent = 0;
    let strike = false;
    const sources = new Map<string, string>();
    try {
      const index = await docs.current();
      const page = body.page?.replace(/[^\w/.#-]/g, "").slice(0, 120);
      const convo: Record<string, unknown>[] = [
        {
          role: "system",
          content: `${SYSTEM}\n\nToday is ${new Date().toISOString().slice(0, 10)}.${page ? ` The visitor is on ${page}.` : ""}\n\nThe docs (search them for details):\n${index.outline()}`,
        },
        ...history,
      ];
      const runTool = async (name: string, args: Record<string, unknown>): Promise<unknown> => {
        switch (name) {
          case "search_docs": {
            const hits = index.search(String(args.query ?? "").slice(0, 200), 5);
            for (const h of hits) sources.set(h.url, h.title);
            return hits.length
              ? hits.map((h) => ({ title: h.title, url: h.url, text: h.text.slice(0, 2500) }))
              : "Nothing matched. Try other words once, then note_gap and say you're not sure.";
          }
          case "get_plans": {
            if (!billing.enabled) return "Plans aren't on sale on this server.";
            const [plans, packs] = await Promise.all([billing.plans(), billing.packs()]);
            return {
              plans: plans.map((p) => ({
                name: p.name,
                interval: p.interval,
                price: p.price_label,
                limits: p.limits,
              })),
              credit_packs: packs.map((p) => ({
                name: p.name,
                credits_usd: Number(p.credits_usd),
                price: p.price_label,
              })),
            };
          }
          case "note_gap": {
            const question = scrubGap(String(args.question ?? ""));
            if (question.length >= 4)
              await db.execute(sql`
                insert into public.support_web_gaps (question, page) values (${question}, ${page || null})`);
            return "Noted. Say you're not sure and point to support@casama.ai.";
          }
          case "decline_off_topic":
            strike = true;
            return "Recorded. Decline in one sentence.";
          default:
            return "Unknown tool.";
        }
      };
      let reply = "";
      const deadline = Date.now() + WebLimits.timeoutMs;
      for (let round = 0; round <= WebLimits.toolRounds; round++) {
        const last = round === WebLimits.toolRounds;
        const res = await fetchImpl(
          `${env.CLOUD_MODEL_UPSTREAM_URL.replace(/\/$/, "")}/chat/completions`,
          {
            method: "POST",
            headers: {
              authorization: `Bearer ${key}`,
              "content-type": "application/json",
              "x-title": "Casama Help (web)",
            },
            signal: AbortSignal.timeout(Math.max(5_000, deadline - Date.now())),
            body: JSON.stringify(
              withOpenRouterRouting(
                {
                  model,
                  messages: convo,
                  max_tokens: WebLimits.maxTokens,
                  temperature: 0.2,
                  usage: { include: true },
                  user: addr,
                  ...(last ? {} : { tools: TOOLS, tool_choice: "auto" }),
                },
                cloudModelRouting(env),
              ),
            ),
          },
        );
        if (!res.ok)
          throw new ApiError(503, "assistant_unavailable", "Casama Help can't answer right now");
        const data = (await res.json()) as {
          choices?: {
            message?: {
              content?: string | null;
              tool_calls?: { id: string; function: { name: string; arguments: string } }[];
            };
          }[];
          usage?: { cost?: number; prompt_tokens?: number; completion_tokens?: number };
        };
        spent +=
          data.usage?.cost ??
          ((data.usage?.prompt_tokens ?? 0) + (data.usage?.completion_tokens ?? 0)) / 1e6;
        const msg = data.choices?.[0]?.message;
        const calls = msg?.tool_calls ?? [];
        if (!calls.length || last) {
          reply = (msg?.content ?? "").trim();
          break;
        }
        const used = calls.slice(0, WebLimits.callsPerRound);
        convo.push({ role: "assistant", content: msg?.content ?? "", tool_calls: used });
        for (const call of used) {
          let args: Record<string, unknown> = {};
          try {
            args = JSON.parse(call.function.arguments || "{}");
          } catch {}
          let result: unknown;
          try {
            result = await runTool(call.function.name, args);
          } catch {
            result = "That lookup failed. Don't retry it; answer with what you have.";
          }
          convo.push({
            role: "tool",
            tool_call_id: call.id,
            content: JSON.stringify(result).slice(0, 12_000),
          });
        }
      }
      if (!reply)
        reply =
          "Sorry, I couldn't answer that. The FAQ may help, or email support@casama.ai and a person will reply.";
      const cited = citedSources(reply, sources);
      return c.json({ reply: cited.reply || reply, sources: strike ? [] : cited.sources }, 200);
    } finally {
      busy.delete(me);
      const after = await bump(db, me, { messages: 1, usd: spent, strikes: strike ? 1 : 0 });
      const all = await bump(db, "web:all", { messages: 1, usd: spent });
      if (strike && after.strikes >= WebLimits.strikesBeforePause)
        await db.execute(sql`
          update public.support_usage set blocked_until = now() + make_interval(hours => ${WebLimits.pauseHours})
          where key = ${me} and day = current_date`);
      const day = new Date().toISOString().slice(0, 10);
      if (
        env.SUPPORT_WEB_DAILY_USD > 0 &&
        all.usd >= env.SUPPORT_WEB_DAILY_USD * WebLimits.alertAt &&
        alertedDay !== day
      ) {
        alertedDay = day;
        captureError(new Error("Website Casama Help passed 80% of its daily budget"), {
          usd_today: all.usd,
          budget_usd: env.SUPPORT_WEB_DAILY_USD,
        });
      }
      // The FAQ list keeps 90 days.
      if (Math.random() < 0.02)
        await db
          .execute(
            sql`delete from public.support_web_gaps where created_at < now() - make_interval(days => ${WebLimits.gapDays})`,
          )
          .catch(() => {});
    }
  });

  const requireOwner = instanceOwnerCheck(deps);
  app.openapi(routes.getSupportWebStats, async (c) => {
    const claims = c.get("claims");
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    await requireOwner(claims);
    const [all] = await db.execute<{ messages: number; usd: string }>(sql`
      select messages, usd from public.support_usage where key = 'web:all' and day = current_date`);
    const [paused] = await db.execute<{ n: number }>(sql`
      select count(distinct key)::int as n from public.support_usage
      where key like 'web:ip:%' and blocked_until > now()`);
    const gaps = await db.execute<{ question: string; page: string | null; created_at: Date }>(sql`
      select question, page, created_at from public.support_web_gaps order by created_at desc limit 100`);
    return c.json(
      {
        on,
        messages_today: all?.messages ?? 0,
        usd_today: Math.round(Number(all?.usd ?? 0) * 10_000) / 10_000,
        daily_budget_usd: env.SUPPORT_WEB_DAILY_USD,
        paused_addresses: paused?.n ?? 0,
        gaps: gaps.map((g) => ({ ...g, created_at: new Date(g.created_at).toISOString() })),
      },
      200,
    );
  });
}
