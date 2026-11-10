/**
 * Self-improving skills (SPEC: Post-v1 roadmap → Self-improving skills; D-126).
 * - Every finished run leaves a digest: the request, the tools and skills it used, how it ended.
 * - A successful run that matches two or more earlier successful runs (by embedding, or by shared
 *   words without one) and used tools but no skill makes the bot propose a skill.
 * - A run that used a skill and failed, or that the person corrected in their next message, makes
 *   the bot propose an edit (shown as a diff).
 * - Proposals wait for the owner unless an action rule allows skills.create / skills.update.
 */
import type { Database } from "@kasama/db";
import { type ActionRule, resolveActionRule, SKILL_NAME } from "@kasama/domain";
import { sql } from "drizzle-orm";
import { type Embedder, toPgVector } from "./embeddings.ts";

export const SKILL_PROPOSAL_SYSTEM = `You turn a task the assistant has now done successfully several times into a reusable skill. Reply with only JSON: {"name": "lowercase-with-dashes", "description": "one line: when to use it", "steps": "numbered Markdown steps that work next time (name the tools to use, describe values that change as inputs)", "tools": ["tool names used"]}.`;
export const SKILL_EDIT_SYSTEM = `You improve a skill after it went wrong. You get the skill, what was asked, and what failed or how the person corrected it. Reply with only JSON: {"description": "one line: when to use it", "body": "the whole improved skill in Markdown", "reason": "one sentence on what changed"}.`;

/** Similar enough to count as the same kind of task (cosine distance). */
export const SIMILAR_DISTANCE = 0.3;
/** Minimum share of words in common when there are no embeddings. */
export const SIMILAR_WORDS = 0.6;
const CORRECTION =
  /^\s*(no\b|nope\b|not (that|quite|right)|that'?s (not|wrong)|wrong\b|actually\b|instead\b|you (forgot|missed)|it should)/i;
const IGNORED_TOOLS = /^(memory|knowledge|skills|tools|suggestions)\./;

export interface LearnDeps {
  db: Database;
  embedder: Embedder | null;
  /** One cheap model call: system prompt and user text in, text out. */
  complete: (system: string, text: string) => Promise<string>;
  notify?: (
    userId: string,
    orgId: string,
    payload: { title: string; body: string; link: string; bot_id: string },
  ) => Promise<void>;
}

export interface FinishedRun {
  runId: string;
  orgId: string;
  botId: string;
  conversationId: string | null;
  task: string;
  status: "completed" | "failed" | "cancelled";
  error?: string;
  owner: string | null;
}

const words = (s: string) =>
  new Set((s.toLowerCase().match(/[\p{L}\p{N}]+/gu) ?? []).filter((w) => w.length > 2));
export function wordOverlap(a: string, b: string) {
  const A = words(a);
  const B = words(b);
  if (!A.size || !B.size) return 0;
  let n = 0;
  for (const w of A) if (B.has(w)) n++;
  return n / Math.min(A.size, B.size);
}

const parseJson = <T>(text: string): T | null => {
  const m = /\{[\s\S]*\}/.exec(text);
  if (!m) return null;
  try {
    return JSON.parse(m[0]) as T;
  } catch {
    return null;
  }
};

/** Whether an action rule lets the bot change skills without asking. */
async function ruleAllows(
  db: Database,
  orgId: string,
  botId: string,
  tool: "skills.create" | "skills.update",
) {
  const rules = await db.execute<ActionRule>(sql`
    select id, bot_id, match_kind, match_value, target, rule from public.action_rules
    where org_id = ${orgId}::uuid and (bot_id is null or bot_id = ${botId}::uuid)`);
  const r = resolveActionRule([...rules], {
    botId,
    tool,
    category: null,
    target: { domains: [], recipients: [], amount: null },
  });
  return r?.rule === "allow" || r?.rule === "allow_within_limits";
}

/** Applies a proposal: a new skill, or the edit (the old text goes to skill_revisions). */
export async function applySkillProposal(
  db: Database,
  proposalId: string,
  override: { name?: string; description?: string; body?: string } = {},
) {
  const [p] = await db.execute<{
    id: string;
    org_id: string;
    bot_id: string;
    kind: string;
    skill_id: string | null;
    name: string;
    description: string;
    body_md: string;
  }>(
    sql`select id, org_id, bot_id, kind, skill_id, name, description, body_md from public.skill_proposals where id = ${proposalId}::uuid`,
  );
  if (!p) throw new Error("Proposal not found");
  const name = override.name ?? p.name;
  const description = override.description ?? p.description;
  const body = override.body ?? p.body_md;
  if (p.kind === "edit" && p.skill_id) {
    await db.execute(
      sql`update public.skills set description = ${description}, body_md = ${body}, updated_at = now(), updated_by_bot = ${p.bot_id}::uuid where id = ${p.skill_id}::uuid`,
    );
    return p.skill_id;
  }
  const [s] = await db.execute<{ id: string }>(sql`
    insert into public.skills (org_id, bot_id, name, description, body_md, source, updated_by_bot)
    values (${p.org_id}::uuid, ${p.bot_id}::uuid, ${name}, ${description}, ${body}, 'bot', ${p.bot_id}::uuid) returning id`);
  await db.execute(
    sql`update public.skill_proposals set skill_id = ${s?.id}::uuid where id = ${p.id}::uuid`,
  );
  return s?.id as string;
}

/** Records the run's digest and proposes a new skill or an edit when it should. */
export async function learnFromRun(d: LearnDeps, run: FinishedRun) {
  const { db } = d;
  if (!run.task.trim()) return null;
  const events = await db.execute<{ type: string; payload: { tool?: string; name?: string } }>(sql`
    select type, payload from public.run_events where run_id = ${run.runId}::uuid and type in ('tool.started', 'skill.loaded') order by seq`);
  const tools = [
    ...new Set(
      events
        .filter(
          (e) => e.type === "tool.started" && e.payload.tool && !IGNORED_TOOLS.test(e.payload.tool),
        )
        .map((e) => e.payload.tool as string),
    ),
  ];
  const skills = [
    ...new Set(
      events
        .filter((e) => e.type === "skill.loaded" && e.payload.name)
        .map((e) => e.payload.name as string),
    ),
  ];
  const vec = d.embedder ? toPgVector(await d.embedder.embed(run.task.slice(0, 4000))) : null;
  await db.execute(sql`
    insert into public.run_digests (run_id, org_id, bot_id, task, tools, skills, status, embedding)
    values (${run.runId}::uuid, ${run.orgId}::uuid, ${run.botId}::uuid, ${run.task.slice(0, 4000)},
            array(select jsonb_array_elements_text(${JSON.stringify(tools)}::jsonb)), array(select jsonb_array_elements_text(${JSON.stringify(skills)}::jsonb)),
            ${run.status}, ${vec}::extensions.vector)
    on conflict (run_id) do nothing`);
  if (run.status === "cancelled") return null;

  // The person correcting the previous answer, which used a skill.
  if (run.conversationId && CORRECTION.test(run.task)) {
    const [prev] = await db.execute<{ run_id: string; task: string; skills: string[] }>(sql`
      select d.run_id, d.task, d.skills from public.run_digests d join public.runs r on r.id = d.run_id
      where r.conversation_id = ${run.conversationId}::uuid and d.run_id <> ${run.runId}::uuid and cardinality(d.skills) > 0
      order by d.created_at desc limit 1`);
    if (prev) {
      await db.execute(
        sql`update public.run_digests set corrected = true, correction = ${run.task.slice(0, 4000)} where run_id = ${prev.run_id}::uuid`,
      );
      return proposeEdit(
        d,
        run,
        prev.skills[0] as string,
        `Asked: ${prev.task}\n\nThe person then corrected it: ${run.task}`,
        [prev.run_id, run.runId],
      );
    }
  }
  // A run that used a skill and failed.
  if (run.status === "failed" && skills.length)
    return proposeEdit(
      d,
      run,
      skills[0] as string,
      `Asked: ${run.task}\n\nIt failed: ${run.error ?? "unknown error"}`,
      [run.runId],
    );
  if (run.status !== "completed" || skills.length || tools.length < 2) return null;

  // The same kind of task, done successfully at least twice before.
  const earlier = await db.execute<{
    run_id: string;
    task: string;
    tools: string[];
    distance: number | null;
  }>(sql`
    select run_id, task, tools,
      case when ${vec}::extensions.vector is null or embedding is null then null else (embedding operator(extensions.<=>) ${vec}::extensions.vector) end as distance
    from public.run_digests
    where bot_id = ${run.botId}::uuid and run_id <> ${run.runId}::uuid and status = 'completed' and cardinality(skills) = 0
    order by created_at desc limit 200`);
  const similar = earlier.filter((e) =>
    e.distance !== null
      ? Number(e.distance) < SIMILAR_DISTANCE
      : wordOverlap(e.task, run.task) >= SIMILAR_WORDS,
  );
  if (similar.length < 2) return null;
  // Already proposed for this kind of task (any of these runs), or dismissed recently.
  const ids = [run.runId, ...similar.map((s) => s.run_id)];
  const [dup] = await db.execute<{ id: string }>(sql`
    select id from public.skill_proposals where bot_id = ${run.botId}::uuid and kind = 'new'
      and source_run_ids && array(select jsonb_array_elements_text(${JSON.stringify(ids)}::jsonb))::uuid[] limit 1`);
  if (dup) return null;
  const answers = (
    await db.execute<{ run_id: string; content: Array<{ type?: string; text?: string }> }>(sql`
    select m.run_id, m.content
    from public.messages m where m.role = 'assistant' and m.run_id = any(array(select jsonb_array_elements_text(${JSON.stringify(ids.slice(0, 4))}::jsonb))::uuid[])`)
  ).map((a) => ({
    run_id: a.run_id,
    text: (Array.isArray(a.content) ? a.content : [])
      .filter((p) => p.type === "text")
      .map((p) => p.text ?? "")
      .join(" "),
  }));
  const examples = [run, ...similar.slice(0, 3).map((s) => ({ runId: s.run_id, task: s.task }))]
    .map((r, i) => {
      const t =
        r.runId === run.runId ? tools : (similar.find((s) => s.run_id === r.runId)?.tools ?? []);
      return `Example ${i + 1}\nAsked: ${r.task}\nTools used: ${t.join(", ") || "none"}\nAnswer: ${(answers.find((a) => a.run_id === r.runId)?.text ?? "").slice(0, 1500)}`;
    })
    .join("\n\n");
  const draft = parseJson<{
    name?: string;
    description?: string;
    steps?: string;
    tools?: string[];
  }>(await d.complete(SKILL_PROPOSAL_SYSTEM, examples));
  if (!draft?.steps || !draft.description) return null;
  let name = SKILL_NAME.test(draft.name ?? "")
    ? (draft.name as string)
    : (draft.name ?? "new-skill")
        .toLowerCase()
        .replace(/[^a-z0-9_-]+/g, "-")
        .replace(/^-+/, "")
        .slice(0, 60) || "new-skill";
  const taken = new Set(
    (
      await db.execute<{ name: string }>(
        sql`select name from public.skills where bot_id = ${run.botId}::uuid union select name from public.skill_proposals where bot_id = ${run.botId}::uuid and status = 'pending'`,
      )
    ).map((r) => r.name),
  );
  for (let i = 2; taken.has(name); i++) name = `${name.replace(/-\d+$/, "")}-${i}`;
  return saveProposal(d, run, {
    kind: "new",
    skillId: null,
    name,
    description: draft.description.slice(0, 300),
    body: draft.steps.slice(0, 50_000),
    previous: null,
    tools: (draft.tools ?? tools).filter((t) => typeof t === "string").slice(0, 30),
    reason: `You've asked for this ${similar.length + 1} times.`,
    runIds: ids.slice(0, 10),
  });
}

async function proposeEdit(
  d: LearnDeps,
  run: FinishedRun,
  skillName: string,
  what: string,
  runIds: string[],
) {
  const [s] = await d.db.execute<{
    id: string;
    name: string;
    description: string;
    body_md: string;
    plugin_id: string | null;
  }>(sql`
    select id, name, description, body_md, plugin_id from public.skills
    where org_id = ${run.orgId}::uuid and name = ${skillName} and (bot_id = ${run.botId}::uuid or bot_id is null)
    order by bot_id nulls last limit 1`);
  if (!s || s.plugin_id) return null;
  const [pending] = await d.db.execute<{ id: string }>(
    sql`select id from public.skill_proposals where skill_id = ${s.id}::uuid and status = 'pending' limit 1`,
  );
  if (pending) return null;
  const draft = parseJson<{ description?: string; body?: string; reason?: string }>(
    await d.complete(
      SKILL_EDIT_SYSTEM,
      `Skill "${s.name}" (${s.description}):\n\n${s.body_md}\n\n---\n\n${what}`,
    ),
  );
  if (!draft?.body || draft.body.trim() === s.body_md.trim()) return null;
  return saveProposal(d, run, {
    kind: "edit",
    skillId: s.id,
    name: s.name,
    description: (draft.description ?? s.description).slice(0, 300),
    body: draft.body.slice(0, 50_000),
    previous: s.body_md,
    tools: [],
    reason: (draft.reason ?? "").slice(0, 500),
    runIds,
  });
}

async function saveProposal(
  d: LearnDeps,
  run: FinishedRun,
  p: {
    kind: "new" | "edit";
    skillId: string | null;
    name: string;
    description: string;
    body: string;
    previous: string | null;
    tools: string[];
    reason: string;
    runIds: string[];
  },
) {
  const [row] = await d.db.execute<{ id: string }>(sql`
    insert into public.skill_proposals (org_id, bot_id, kind, skill_id, name, description, body_md, previous_body_md, tools, reason, source_run_ids)
    values (${run.orgId}::uuid, ${run.botId}::uuid, ${p.kind}, ${p.skillId}::uuid, ${p.name}, ${p.description}, ${p.body}, ${p.previous},
            array(select jsonb_array_elements_text(${JSON.stringify(p.tools)}::jsonb)), ${p.reason},
            array(select jsonb_array_elements_text(${JSON.stringify(p.runIds)}::jsonb))::uuid[])
    returning id`);
  const id = row?.id as string;
  if (
    await ruleAllows(
      d.db,
      run.orgId,
      run.botId,
      p.kind === "new" ? "skills.create" : "skills.update",
    )
  ) {
    await applySkillProposal(d.db, id);
    await d.db.execute(
      sql`update public.skill_proposals set status = 'applied', resolved_at = now() where id = ${id}::uuid`,
    );
    return { id, applied: true };
  }
  if (run.owner)
    await d
      .notify?.(run.owner, run.orgId, {
        title: p.kind === "new" ? `Save "${p.name}" as a skill?` : `Improve the skill "${p.name}"?`,
        body: p.kind === "new" ? p.description : p.reason || p.description,
        link: "/inbox",
        bot_id: run.botId,
      })
      .catch(() => {});
  return { id, applied: false };
}
