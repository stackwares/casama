/**
 * Teach a task by showing it (D-120). Recording only runs while the recorder holds control of the
 * computer; the app shows a red "Recording" banner the whole time. Each step stores the input the
 * app sent plus what the server captures from the computer afterwards (accessibility snapshot,
 * screenshot, browser address). Password fields and fields marked secret keep no text.
 */
import type { OpenAPIHono } from "@hono/zod-openapi";
import { activeUserLease, captureTeachContext } from "@kasama/agent";
import { routes } from "@kasama/contracts";
import { type JwtClaims, pgErrorCode, withUserSession, contentKeys } from "@kasama/db";
import { focusedIsPassword, nextSecretName, type TeachStepView, teachTranscript } from "@kasama/domain";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

type SessionRow = {
  id: string;
  org_id: string;
  bot_id: string;
  computer_id: string;
  user_id: string;
  status: "recording" | "drafting" | "drafted" | "saved" | "cancelled" | "failed";
  run_id: string | null;
  conversation_id: string | null;
  draft: null;
  skill_id: string | null;
  started_at: string;
  stopped_at: string | null;
};
type StepRow = {
  seq: number;
  kind: "click" | "type" | "key" | "scroll";
  x: number | null;
  y: number | null;
  button: number | null;
  text: string | null;
  key: string | null;
  dx: number | null;
  dy: number | null;
  secret_name: string | null;
  password: boolean;
  url: string | null;
  snapshot?: string | null;
  has_screenshot: boolean;
  created_at: string;
};
const STEP_COLS = sql`seq, kind, x, y, button, text, key, dx, dy, secret_name, password, url, screenshot is not null as has_screenshot, created_at`;
const stepOut = ({ snapshot: _s, ...r }: StepRow) => ({ ...r, created_at: iso(r.created_at) });

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

export function registerTeachRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  const session = async (claims: JwtClaims, id: string) => {
    const [s] = await withUserSession(db, claims, (tx) =>
      tx.execute<SessionRow>(sql`select * from public.teach_sessions where id = ${id}::uuid`),
    );
    if (!s) throw new ApiError(404, "teach_not_found", "Recording not found");
    return s;
  };
  const steps = (id: string, withSnapshot = false) =>
    db.execute<StepRow>(sql`select ${STEP_COLS}${withSnapshot ? sql`, snapshot` : sql``} from public.teach_steps
      where session_id = ${id}::uuid order by seq`);
  const full = async (s: SessionRow) => ({
    id: s.id,
    bot_id: s.bot_id,
    computer_id: s.computer_id,
    status: s.status,
    conversation_id: s.conversation_id,
    draft: s.draft,
    skill_id: s.skill_id,
    steps: (await steps(s.id)).map(stepOut),
    started_at: iso(s.started_at),
    stopped_at: s.stopped_at ? iso(s.stopped_at) : null,
  });
  const holdsControl = async (s: { computer_id: string }, claims: JwtClaims) =>
    (await activeUserLease(db, s.computer_id))?.holderId === claims.sub;
  const computers = () => {
    if (!deps.computers) throw new ApiError(503, "computers_unavailable", "Computers aren't set up on this server");
    return deps.computers;
  };

  /** A chat with the bot started by this person, with one message and a run. */
  const startChat = async (s: SessionRow, claims: JwtClaims, title: string, text: string, trigger: string) => {
    const created = await withUserSession(db, claims, async (tx) => {
      const [conv] = await tx.execute<{ id: string }>(sql`
        insert into public.conversations (org_id, bot_id, title, created_by, last_message_at)
        values (${s.org_id}::uuid, ${s.bot_id}::uuid, ${title}, ${claims.sub}::uuid, now()) returning id`);
      const [run] = await tx.execute<{ id: string }>(sql`
        insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger)
        values (${s.org_id}::uuid, ${s.bot_id}::uuid, ${conv?.id}::uuid, ${claims.sub}::uuid, ${trigger}) returning id`);
      await tx.execute(sql`
        insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
        values (${s.org_id}::uuid, ${conv?.id}::uuid, 'user', ${claims.sub}::uuid, ${contentKeys.sealJson(s.org_id, [{ type: "text", text }])}::jsonb, ${run?.id}::uuid)`);
      return { conversation_id: conv?.id as string, run_id: run?.id as string };
    });
    return created;
  };

  app.openapi(routes.startTeach, async (c) => {
    const claims = claimsOf(c);
    const { computer_id, bot_id } = c.req.valid("json");
    const [ok] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ org_id: string; manage: boolean }>(sql`
        select b.org_id, public.can_manage_bot(b.id) as manage from public.bots b
        join public.computers k on k.id = ${computer_id}::uuid and k.org_id = b.org_id
        where b.id = ${bot_id}::uuid and b.archived_at is null`),
    );
    if (!ok) throw new ApiError(404, "not_found", "Bot or computer not found");
    if (!ok.manage) throw new ApiError(403, "forbidden", "Only people who manage this bot can teach it skills");
    if (!(await holdsControl({ computer_id }, claims)))
      throw new ApiError(409, "not_in_control", "Take control of the computer first; recording only runs while you have control");
    try {
      const [s] = await db.execute<SessionRow>(sql`
        insert into public.teach_sessions (org_id, bot_id, computer_id, user_id)
        values (${ok.org_id}::uuid, ${bot_id}::uuid, ${computer_id}::uuid, ${claims.sub}::uuid) returning *`);
      await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id)
        values (${ok.org_id}::uuid, 'user', ${claims.sub}::uuid, 'teach.recording_started', 'computer', ${computer_id}::uuid)`);
      return c.json(await full(s as SessionRow), 201);
    } catch (err) {
      if (pgErrorCode(err) === "23505") throw new ApiError(409, "already_recording", "This computer is already being recorded");
      throw err;
    }
  });

  app.openapi(routes.getTeach, async (c) => {
    const claims = claimsOf(c);
    let s = await session(claims, c.req.valid("param").id);
    // A drafting run that ended without a draft.
    if (s.status === "drafting" && s.run_id) {
      const [r] = await db.execute<{ status: string }>(sql`select status from public.runs where id = ${s.run_id}::uuid`);
      if (r && ["completed", "failed", "cancelled"].includes(r.status)) {
        await db.execute(sql`update public.teach_sessions set status = 'failed' where id = ${s.id}::uuid and status = 'drafting'`);
        s = await session(claims, s.id);
      }
    }
    return c.json(await full(s), 200);
  });

  app.openapi(routes.addTeachStep, async (c) => {
    const claims = claimsOf(c);
    const s = await session(claims, c.req.valid("param").id);
    if (s.status !== "recording") throw new ApiError(409, "not_recording", "This recording has stopped");
    if (!(await holdsControl(s, claims)))
      throw new ApiError(409, "control_ended", "You no longer have control of the computer, so recording stopped");
    const b = c.req.valid("json");
    const h = await computers().ensureRunning(s.computer_id);
    const ctx = await captureTeachContext(h);
    const prior = await db.execute<{ secret_name: string | null }>(
      sql`select secret_name from public.teach_steps where session_id = ${s.id}::uuid`,
    );
    // Keystrokes into password fields are never stored.
    const password = b.kind === "type" && focusedIsPassword(ctx.snapshot);
    const secretName = password ? nextSecretName(prior.map((p) => p.secret_name)) : null;
    const [step] = await db.execute<StepRow>(sql`
      insert into public.teach_steps (session_id, seq, org_id, kind, x, y, button, text, key, dx, dy, secret_name, password, url, snapshot, screenshot)
      values (${s.id}::uuid, (select coalesce(max(seq), 0) + 1 from public.teach_steps where session_id = ${s.id}::uuid), ${s.org_id}::uuid,
              ${b.kind}, ${b.x ?? null}, ${b.y ?? null}, ${b.button ?? null}, ${password ? null : (b.text ?? null)}, ${b.key ?? null},
              ${b.dx ?? null}, ${b.dy ?? null}, ${secretName}, ${password}, ${ctx.url}, ${ctx.snapshot},
              ${ctx.screenshot ? Buffer.from(ctx.screenshot) : null})
      returning ${STEP_COLS}`);
    return c.json(stepOut(step as StepRow), 201);
  });

  app.openapi(routes.markTeachSecret, async (c) => {
    const claims = claimsOf(c);
    const { id, seq } = c.req.valid("param");
    const s = await session(claims, id);
    if (s.status !== "recording")
      throw new ApiError(409, "not_recording", "Mark secrets before you stop recording");
    const [step] = await db.execute<StepRow>(sql`
      update public.teach_steps set text = null, secret_name = ${c.req.valid("json").secret_name}
      where session_id = ${s.id}::uuid and seq = ${seq} and kind = 'type' returning ${STEP_COLS}`);
    if (!step) throw new ApiError(404, "step_not_found", "No typed step with that number");
    return c.json(stepOut(step), 200);
  });

  app.openapi(routes.stopTeach, async (c) => {
    const claims = claimsOf(c);
    const s = await session(claims, c.req.valid("param").id);
    if (s.status !== "recording") throw new ApiError(409, "not_recording", "This recording has already stopped");
    const recorded = await steps(s.id, true);
    if (!recorded.length) throw new ApiError(409, "nothing_recorded", "Nothing was recorded yet");
    const view: TeachStepView[] = recorded.map((r) => ({ ...r, secretName: r.secret_name }));
    const chat = await startChat(s, claims, "Teach: draft a skill", teachTranscript(view), "teach");
    await db.execute(sql`
      update public.teach_sessions set status = 'drafting', stopped_at = now(), run_id = ${chat.run_id}::uuid,
        conversation_id = ${chat.conversation_id}::uuid where id = ${s.id}::uuid`);
    await deps.workflows.startRun(chat.run_id);
    return c.json(await full(await session(claims, s.id)), 200);
  });

  app.openapi(routes.saveTeach, async (c) => {
    const claims = claimsOf(c);
    const s = await session(claims, c.req.valid("param").id);
    if (s.status !== "drafted" && s.status !== "failed")
      throw new ApiError(409, "no_draft", s.status === "saved" ? "This skill is already saved" : "The draft isn't ready yet");
    const b = c.req.valid("json");
    let skillId: string;
    try {
      const [row] = await withUserSession(db, claims, (tx) =>
        tx.execute<{ id: string }>(sql`
          insert into public.skills (org_id, bot_id, name, description, body_md, source, source_ref)
          values (${s.org_id}::uuid, ${s.bot_id}::uuid, ${b.name}, ${b.description}, ${b.body}, 'manual',
                  ${JSON.stringify({ teach_session_id: s.id })}::jsonb)
          returning id`),
      );
      if (!row) throw new ApiError(403, "forbidden", "You can't add skills to this bot");
      skillId = row.id;
    } catch (err) {
      const code = pgErrorCode(err);
      if (code === "23505") throw new ApiError(409, "skill_exists", `This bot already has a skill named ${b.name}`);
      if (code === "42501") throw new ApiError(403, "forbidden", "You can't add skills to this bot");
      throw err;
    }
    await db.execute(sql`update public.teach_sessions set status = 'saved', skill_id = ${skillId}::uuid where id = ${s.id}::uuid`);
    let tried: { conversation_id: string; run_id: string } | null = null;
    if (b.try_now) {
      tried = await startChat(
        s,
        claims,
        `Try: ${b.name}`,
        `Try your new skill "${b.name}" now: load it with skills.load and follow it. Ask me for any inputs you need.`,
        "chat",
      );
      await deps.workflows.startRun(tried.run_id);
    }
    return c.json({ skill_id: skillId, conversation_id: tried?.conversation_id ?? null, run_id: tried?.run_id ?? null }, 200);
  });

  app.openapi(routes.cancelTeach, async (c) => {
    const claims = claimsOf(c);
    const s = await session(claims, c.req.valid("param").id);
    // Deleting the recording deletes every captured step, snapshot and screenshot.
    await db.execute(sql`delete from public.teach_sessions where id = ${s.id}::uuid`);
    return c.json({ deleted: s.id }, 200);
  });
}
