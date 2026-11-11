/**
 * Step replay (SPEC: Post-v1 roadmap → Step replay; D-127). A replay is a list of browser and
 * desktop tool calls with parameters ({{param:NAME}}), element targets (found again by role and
 * label in a fresh snapshot, so page changes that keep the label still work) and checks. Running
 * one makes no model calls; when an element is missing or a check fails, it stops there and the
 * bot carries on from that step and can update the replay. Typed passwords are never stored:
 * replays use {{secret:NAME}}, filled only for the secret's allowed hosts.
 */
import type { Database } from "@casama/db";
import { collectExec } from "@casama/sandbox";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { hasLoginPlaceholders, resolveLoginPlaceholders } from "./password-managers.ts";
import { loadSecrets, resolvePlaceholders } from "./secrets.ts";
import { type ToolContext, ToolError, type ToolRegistry } from "./tools/registry.ts";

export const REPLAY_TOOLS = new Set([
  "browser.open",
  "browser.click",
  "browser.fill",
  "browser.type",
  "browser.press",
  "browser.scroll",
  "desktop.launch",
  "desktop.click",
  "desktop.type",
  "desktop.press",
]);
export const REPLAY_STOPPED = "REPLAY_STOPPED";

export const ReplayStep = z.object({
  tool: z.string().refine((t) => REPLAY_TOOLS.has(t), "only browser and desktop actions"),
  args: z.record(z.string(), z.unknown()),
  target: z
    .object({ role: z.string().max(50).optional(), name: z.string().min(1).max(200) })
    .optional(),
  check: z
    .object({
      url_contains: z.string().max(500).optional(),
      text_contains: z.string().max(500).optional(),
    })
    .optional(),
  host: z.string().max(253).optional(),
  note: z.string().max(300).optional(),
});
export type ReplayStep = z.infer<typeof ReplayStep>;
export const ReplayParam = z.object({
  name: z.string().regex(/^[a-z][a-z0-9_]{0,40}$/),
  description: z.string().max(200).optional(),
  default: z.string().max(2000).optional(),
  secret: z.boolean().optional(),
});
export type ReplayParam = z.infer<typeof ReplayParam>;

const PARAM = /\{\{param:([a-z][a-z0-9_]{0,40})\}\}/g;
const PASSWORDISH = /pass(word|code)?|\bpin\b|secret|one.?time|otp|2fa/i;

/** Replaces {{param:NAME}} in every string of the arguments. */
export function fillParams<T>(value: T, params: Record<string, string>): T {
  const walk = (v: unknown): unknown => {
    if (typeof v === "string")
      return v.replace(PARAM, (_m, name: string) => {
        if (!(name in params)) throw new ToolError("missing_param", `The replay needs ${name}.`);
        return params[name] as string;
      });
    if (Array.isArray(v)) return v.map(walk);
    if (v && typeof v === "object")
      return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, walk(x)]));
    return v;
  };
  return walk(value) as T;
}

/** The ref of the element with this role and label in an accessibility snapshot. */
export function findRef(snapshot: string, target: { role?: string; name: string }) {
  const name = target.name.toLowerCase();
  const lines = snapshot.split("\n").filter((l) => /\[ref=@?e\d+\]|\bref=@?e\d+/.test(l));
  const score = (l: string) => {
    const low = l.toLowerCase();
    if (!low.includes(name)) return 0;
    let s = low.includes(`"${name}"`) ? 3 : 1;
    if (target.role && low.includes(target.role.toLowerCase())) s += 2;
    return s;
  };
  const best = lines
    .map((l) => ({ l, s: score(l) }))
    .filter((x) => x.s > 0)
    .sort((a, b) => b.s - a.s)[0];
  return best ? (/ref=@?(e\d+)/.exec(best.l)?.[1] ?? null) : null;
}

/** Checks a replay before saving: allowed tools, and no password typed in clear text. */
export function checkReplaySteps(steps: ReplayStep[], params: ReplayParam[]) {
  const names = new Set(params.map((p) => p.name));
  steps.forEach((s, i) => {
    for (const [, name] of JSON.stringify(s.args).matchAll(PARAM))
      if (!names.has(name as string))
        throw new ToolError(
          "unknown_param",
          `Step ${i + 1} uses {{param:${name}}}, which isn't declared.`,
        );
    const typed = typeof s.args.text === "string" ? (s.args.text as string) : null;
    if (
      typed &&
      /fill|type/.test(s.tool) &&
      s.target &&
      PASSWORDISH.test(s.target.name) &&
      !/\{\{(secret|param|login|totp):/.test(typed)
    )
      throw new ToolError(
        "password_in_replay",
        `Step ${i + 1} types into "${s.target.name}" in clear text; use {{secret:NAME}} instead.`,
      );
  });
}

const sh = async (ctx: ToolContext, cmd: string) => {
  if (!ctx.computer) return "";
  const r = await collectExec((await ctx.computer()).exec(cmd, { timeoutMs: 20_000 })).catch(
    () => null,
  );
  return r?.code === 0 ? r.stdout : "";
};

export interface ReplayOutcome {
  ok: boolean;
  done: number;
  total: number;
  stoppedAt?: number;
  reason?: string;
  log: string[];
}

/** Runs a replay's steps through the registered tools; stops at the first problem. */
export async function executeReplay(
  deps: { db: Database; registry: () => ToolRegistry; fetch?: typeof fetch },
  replay: { name: string; params: ReplayParam[]; steps: ReplayStep[] },
  given: Record<string, string>,
  ctx: ToolContext,
): Promise<ReplayOutcome> {
  const params: Record<string, string> = {};
  for (const p of replay.params) {
    const v = given[p.name] ?? p.default;
    if (v === undefined)
      throw new ToolError("missing_param", `The replay "${replay.name}" needs ${p.name}.`);
    params[p.name] = v;
  }
  const secrets = await loadSecrets(deps.db, ctx.orgId, ctx.botId);
  const log: string[] = [];
  const total = replay.steps.length;
  for (const [i, step] of replay.steps.entries()) {
    const n = i + 1;
    const stop = (reason: string): ReplayOutcome => ({
      ok: false,
      done: i,
      total,
      stoppedAt: n,
      reason,
      log,
    });
    const def = deps.registry().get(step.tool);
    if (!def) return stop(`${step.tool} isn't available to this bot`);
    let args = fillParams(step.args, params);
    if (step.target) {
      const snap = await sh(
        ctx,
        step.tool.startsWith("desktop.")
          ? "agent-desktop snapshot -i --compact"
          : "agent-browser snapshot -i",
      );
      const ref = findRef(snap, step.target);
      if (!ref)
        return stop(
          `couldn't find ${step.target.role ?? "element"} "${step.target.name}" on the screen`,
        );
      args = { ...args, ref };
    }
    try {
      if (/\{\{(secret|totp|login):/.test(JSON.stringify(args))) {
        const host = (await def.destinationHost?.(args as never, ctx)) ?? step.host ?? null;
        if (/\{\{(secret|totp):/.test(JSON.stringify(args)))
          args = resolvePlaceholders(args, secrets, host);
        if (hasLoginPlaceholders(args))
          args = await resolveLoginPlaceholders(deps.db, ctx, args, host, {
            fetch: deps.fetch ?? fetch,
          });
      }
      const parsed = def.schema.safeParse(args);
      if (!parsed.success) return stop(`the step's arguments don't fit ${step.tool}`);
      await def.execute(parsed.data as never, ctx);
    } catch (err) {
      return stop((err as Error).message.slice(0, 300));
    }
    if (step.check?.url_contains) {
      const url = await sh(ctx, "agent-browser get url");
      if (!url.includes(step.check.url_contains))
        return stop(
          `expected the address to contain "${step.check.url_contains}", got "${url.trim()}"`,
        );
    }
    if (step.check?.text_contains) {
      const snap = await sh(
        ctx,
        step.tool.startsWith("desktop.")
          ? "agent-desktop snapshot --compact"
          : "agent-browser snapshot",
      );
      if (!snap.toLowerCase().includes(step.check.text_contains.toLowerCase()))
        return stop(`expected to see "${step.check.text_contains}"`);
    }
    log.push(`${n}. ${step.note ?? step.tool}`);
  }
  return { ok: true, done: total, total, log };
}

export function describeOutcome(name: string, o: ReplayOutcome) {
  if (o.ok) return `Replay "${name}" finished all ${o.total} steps:\n${o.log.join("\n")}`;
  return `${REPLAY_STOPPED}: replay "${name}" stopped at step ${o.stoppedAt} of ${o.total}: ${o.reason}.${o.log.length ? `\nDone so far:\n${o.log.join("\n")}` : ""}\nCarry on from step ${o.stoppedAt} yourself, then offer to update the replay with replay.save.`;
}

async function recordOutcome(db: Database, id: string, o: ReplayOutcome) {
  await db.execute(sql`
    update public.replays set runs = runs + 1, failures = failures + ${o.ok ? 0 : 1},
      last_failure = case when ${o.ok} then last_failure else ${o.ok ? null : `step ${o.stoppedAt}: ${o.reason}`.slice(0, 500)} end,
      last_run_at = now() where id = ${id}::uuid`);
}

export async function loadReplay(db: Database, botId: string, nameOrId: string) {
  const [r] = await db.execute<{
    id: string;
    name: string;
    params: ReplayParam[];
    steps: ReplayStep[];
  }>(sql`
    select id, name, params, steps from public.replays where bot_id = ${botId}::uuid
      and (name = ${nameOrId} or id::text = ${nameOrId}) limit 1`);
  return r ?? null;
}

export function registerReplayTools(
  registry: ToolRegistry,
  deps: { db: Database; fetch?: typeof fetch },
) {
  const { db } = deps;
  const tools = () => registry;
  registry.register({
    name: "replay.run",
    // Outside content (audit 2026-11): later risky calls ask first.
    untrustedOutput: true,
    description:
      "Run one of your saved replays (recorded browser or desktop steps) with its parameters, without thinking through each step. If it stops, finish from that step yourself.",
    risk: "medium",
    requires: { computer: true },
    screen: true,
    schema: z.object({
      name: z.string().min(1).max(100),
      params: z.record(z.string(), z.string().max(2000)).optional(),
    }),
    async execute(args, ctx) {
      const r = await loadReplay(db, ctx.botId, args.name);
      if (!r) throw new ToolError("replay_not_found", `You have no replay named ${args.name}.`);
      const o = await executeReplay(
        { db, registry: tools, fetch: deps.fetch },
        r,
        args.params ?? {},
        ctx,
      );
      await recordOutcome(db, r.id, o);
      return {
        content: describeOutcome(r.name, o),
        preview: o.ok ? `${r.name}: ${o.total} steps` : `${r.name}: stopped at step ${o.stoppedAt}`,
      };
    },
  });

  registry.register({
    name: "replay.save",
    description:
      "Save (or update) steps you just did in the browser or on the desktop as a replay, so next time they run without you thinking through each one. Give each step its tool and arguments, the element's role and label as target (instead of a ref), and checks of what the page shows after it. Values that change become {{param:name}}; passwords and codes are {{secret:NAME}}, never typed out.",
    risk: "low",
    keepsPlaceholders: true,
    schema: z.object({
      name: z.string().regex(/^[a-z0-9][a-z0-9_-]{0,62}$/),
      description: z.string().max(300).optional(),
      params: z.array(ReplayParam).max(30).optional(),
      steps: z.array(ReplayStep).min(1).max(200),
    }),
    async execute(args, ctx) {
      checkReplaySteps(args.steps, args.params ?? []);
      const [row] = await db.execute<{ created: boolean }>(sql`
        insert into public.replays (org_id, bot_id, name, description, params, steps, source)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${args.name}, ${args.description ?? ""}, ${JSON.stringify(args.params ?? [])}::jsonb,
                ${JSON.stringify(args.steps)}::jsonb, 'bot')
        on conflict (bot_id, name) do update set description = excluded.description, params = excluded.params, steps = excluded.steps, updated_at = now()
        returning (xmax = 0) as created`);
      return {
        content: `${row?.created ? "Saved" : "Updated"} the replay ${args.name} (${args.steps.length} steps).`,
        preview: args.name,
      };
    },
  });
}

/** A teach recording as a replay: clicks, typing (secrets stay placeholders, other text a parameter) and keys. */
export function replayFromTeach(
  steps: Array<{
    seq: number;
    kind: string;
    x: number | null;
    y: number | null;
    button: number | null;
    text: string | null;
    key: string | null;
    secret_name: string | null;
    url: string | null;
  }>,
) {
  const params: ReplayParam[] = [];
  const out: ReplayStep[] = [];
  for (const s of steps) {
    const host = s.url
      ? (() => {
          try {
            return new URL(s.url as string).hostname;
          } catch {
            return undefined;
          }
        })()
      : undefined;
    const check = s.url
      ? {
          url_contains: (() => {
            try {
              const u = new URL(s.url as string);
              return u.host + u.pathname;
            } catch {
              return undefined;
            }
          })(),
        }
      : undefined;
    if (s.kind === "click" && s.x !== null && s.y !== null)
      out.push({
        tool: "desktop.click",
        args: { x: s.x, y: s.y },
        check,
        host,
        note: `click at ${s.x}, ${s.y}`,
      });
    else if (s.kind === "type") {
      let text: string;
      if (s.secret_name) text = `{{secret:${s.secret_name}}}`;
      else {
        const name = `text_${params.length + 1}`;
        params.push({ name, default: s.text ?? "", description: `Typed at step ${s.seq}` });
        text = `{{param:${name}}}`;
      }
      out.push({
        tool: "desktop.type",
        args: { text },
        check,
        host,
        note: s.secret_name ? `type ${s.secret_name}` : `type ${params.at(-1)?.name}`,
      });
    } else if (s.kind === "key" && s.key)
      out.push({
        tool: "desktop.press",
        args: { keys: s.key.replace(/^Ctrl\+/, "ctrl+").replace(/^Cmd\+/, "super+") },
        host,
        note: `press ${s.key}`,
      });
  }
  return { params, steps: out };
}
