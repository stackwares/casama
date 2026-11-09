/**
 * Eval runner (SPEC "Evals"). Runs tasks against a Kasama API, checks results automatically,
 * writes a report and compares it with the stored baseline.
 *
 *   node --env-file=.env packages/evals/src/run.ts --mode fixtures --subset quick
 *   OPENROUTER_API_KEY=... node packages/evals/src/run.ts --mode live --subset all
 *
 * Fixture mode needs a worker started with KASAMA_MODEL_FIXTURES=packages/evals/fixtures/quick.json
 * (deterministic, used in CI to check the harness and tools); live mode uses a real key and the
 * default model (GPT-6 Luna, medium effort) and measures model quality. Exit code 1 when the
 * success rate drops below the baseline for the same mode and subset.
 */
import { readFileSync, writeFileSync } from "node:fs";
import { parseArgs } from "node:util";
import { QUICK, TASKS } from "./tasks.ts";
import type { EvalReport, EvalRun, EvalTask, TaskResult } from "./types.ts";

const { values: a } = parseArgs({
  options: {
    api: { type: "string", default: process.env.KASAMA_API_URL ?? "http://127.0.0.1:8787" },
    mode: { type: "string", default: "fixtures" },
    subset: { type: "string", default: "quick" },
    model: { type: "string" },
    only: { type: "string" },
    out: { type: "string", default: "packages/evals/results/latest.json" },
    baseline: { type: "string", default: "packages/evals/baseline.json" },
    "update-baseline": { type: "boolean", default: false },
    "max-output-tokens": { type: "string" },
  },
});

const live = a.mode === "live";
const model = a.model ?? (live ? "openai/gpt-6-luna" : "fixture-main");
const available = new Set((process.env.EVAL_CAPABILITIES ?? "").split(",").filter(Boolean));

async function token() {
  if (process.env.EVAL_TOKEN) return process.env.EVAL_TOKEN;
  const sb = process.env.SUPABASE_URL ?? "http://127.0.0.1:54321";
  const r = await fetch(`${sb}/auth/v1/signup`, {
    method: "POST",
    headers: { apikey: process.env.SUPABASE_ANON_KEY ?? "", "content-type": "application/json" },
    body: JSON.stringify({ email: `evals-${Date.now()}@example.com`, password: "evals-pw-123" }),
  });
  const j = (await r.json()) as { access_token?: string };
  if (!j.access_token) throw new Error(`sign up failed: ${JSON.stringify(j)}`);
  return j.access_token;
}

const T = await token();
const call = async <R = Record<string, unknown>>(
  path: string,
  init: RequestInit & { json?: unknown } = {},
) => {
  const r = await fetch(`${a.api}${path}`, {
    ...init,
    headers: {
      authorization: `Bearer ${T}`,
      ...(init.json !== undefined ? { "content-type": "application/json" } : {}),
      ...(init.headers as Record<string, string>),
    },
    body: init.json !== undefined ? JSON.stringify(init.json) : init.body,
  });
  if (!r.ok) throw new Error(`${init.method ?? "GET"} ${path}: ${r.status} ${await r.text()}`);
  return (r.headers.get("content-type")?.includes("json") ? r.json() : r.text()) as Promise<R>;
};

const org = await call<{ id: string }>("/v1/orgs", {
  method: "POST",
  json: { name: `Evals ${a.mode}` },
});
const cred = await call<{ id: string }>("/v1/credentials", {
  method: "POST",
  json: {
    org_id: org.id,
    provider: "openrouter",
    label: "evals",
    api_key: live ? (process.env.OPENROUTER_API_KEY ?? "") : "sk-evals-fixture",
  },
});
if (live && !process.env.OPENROUTER_API_KEY) throw new Error("live mode needs OPENROUTER_API_KEY");
const computers = await call<{ items: Array<{ id: string; kind: string }> }>(
  `/v1/computers?org_id=${org.id}`,
);
const team = computers.items.find((c) => c.kind === "team")?.id;

async function runTask(t: EvalTask): Promise<TaskResult> {
  const t0 = Date.now();
  const base = {
    id: t.id,
    category: t.category,
    status: "skipped",
    cost_usd: 0,
    steps: 0,
    seconds: 0,
  };
  const missing = (t.requires ?? []).filter((r) => !available.has(r));
  if (missing.length) return { ...base, pass: false, skipped: `needs ${missing.join(", ")}` };
  const bot = await call<{ id: string }>("/v1/bots", {
    method: "POST",
    json: {
      org_id: org.id,
      name: `Eval ${t.id}`.slice(0, 80),
      autonomy: t.autonomy ?? "autonomous",
      model_policy: {
        primary: { credential_id: cred.id, model, reasoning_effort: live ? "medium" : undefined },
      },
    },
  });
  if (t.secret)
    await call("/v1/secrets", {
      method: "POST",
      json: {
        org_id: org.id,
        name: t.secret.name,
        value: t.secret.value,
        allowed_hosts: ["api.example.com"],
      },
    });
  if (t.files && team)
    for (const [path, content] of Object.entries(t.files))
      await call(`/v1/computers/${team}/files?path=${encodeURIComponent(path)}`, {
        method: "PUT",
        headers: { "content-type": "application/octet-stream" },
        body: content,
      });
  const conv = await call<{ id: string }>("/v1/conversations", {
    method: "POST",
    json: { bot_id: bot.id },
  });
  const sent = await call<{ run_id: string }>(`/v1/conversations/${conv.id}/messages`, {
    method: "POST",
    json: { text: `[eval:${t.id}] ${t.prompt}` },
  });
  let run: { status: string; cost_usd: number } = { status: "queued", cost_usd: 0 };
  const deadline = Date.now() + 240_000;
  while (
    !["completed", "failed", "cancelled", "waiting_approval"].includes(run.status) &&
    Date.now() < deadline
  ) {
    await new Promise((r) => setTimeout(r, 500));
    run = await call(`/v1/runs/${sent.run_id}`);
  }
  const events = (
    await call<{ items: EvalRun["events"] }>(`/v1/runs/${sent.run_id}/events?limit=1000`)
  ).items;
  const answer = events
    .filter((e) => e.type === "message.completed")
    .flatMap((e) => (e.payload.content as Array<{ type: string; text?: string }>) ?? [])
    .filter((p) => p.type === "text")
    .map((p) => p.text ?? "")
    .join("\n")
    .trim();
  const r: EvalRun = {
    status: run.status,
    answer,
    events,
    file: async (path) => {
      if (!team) return null;
      const res = await fetch(
        `${a.api}/v1/computers/${team}/files?path=${encodeURIComponent(path)}`,
        {
          headers: { authorization: `Bearer ${T}` },
        },
      );
      return res.ok ? res.text() : null;
    },
  };
  const verdict = await t.check(r);
  return {
    ...base,
    pass: verdict.pass,
    why: verdict.pass ? undefined : verdict.why,
    status: run.status,
    cost_usd: run.cost_usd,
    steps: events.filter((e) => e.type === "tool.started").length + 1,
    seconds: Math.round((Date.now() - t0) / 100) / 10,
  };
}

const tasks = (a.subset === "all" ? TASKS : QUICK).filter(
  (t) => !a.only || a.only.split(",").includes(t.id),
);
const results: TaskResult[] = [];
for (const t of tasks) {
  const res = await runTask(t).catch(
    (err): TaskResult => ({
      id: t.id,
      category: t.category,
      pass: false,
      why: `harness error: ${(err as Error).message}`,
      status: "error",
      cost_usd: 0,
      steps: 0,
      seconds: 0,
    }),
  );
  results.push(res);
  console.log(
    `${res.skipped ? "SKIP" : res.pass ? "PASS" : "FAIL"}  ${t.id}${res.why ? `  (${res.why})` : ""}${res.skipped ? `  (${res.skipped})` : ""}`,
  );
}

const ran = results.filter((r) => !r.skipped);
const report: EvalReport = {
  mode: a.mode as string,
  model,
  subset: a.only ? `only:${a.only}` : (a.subset as string),
  started_at: new Date().toISOString(),
  tasks: results,
  success_rate: ran.length ? ran.filter((r) => r.pass).length / ran.length : 0,
  cost_usd: ran.reduce((s, r) => s + r.cost_usd, 0),
  avg_steps: ran.length ? ran.reduce((s, r) => s + r.steps, 0) / ran.length : 0,
  avg_seconds: ran.length ? ran.reduce((s, r) => s + r.seconds, 0) / ran.length : 0,
};
writeFileSync(a.out as string, `${JSON.stringify(report, null, 2)}\n`);
console.log(
  `\n${report.mode}/${report.subset}: ${(report.success_rate * 100).toFixed(0)}% of ${ran.length} tasks, $${report.cost_usd.toFixed(4)}, ${report.avg_steps.toFixed(1)} steps, ${report.avg_seconds.toFixed(1)} s each`,
);

type Baselines = Record<
  string,
  { success_rate: number; recorded_at: string; model: string; tasks: number }
>;
let baselines: Baselines = {};
try {
  baselines = JSON.parse(readFileSync(a.baseline as string, "utf8")) as Baselines;
} catch {}
const key = `${report.mode}/${report.subset}`;
const prior = baselines[key];
if (a["update-baseline"]) {
  baselines[key] = {
    success_rate: report.success_rate,
    recorded_at: report.started_at,
    model,
    tasks: ran.length,
  };
  writeFileSync(a.baseline as string, `${JSON.stringify(baselines, null, 2)}\n`);
  console.log(`baseline ${key} set to ${(report.success_rate * 100).toFixed(0)}%`);
} else if (prior) {
  const okay = report.success_rate >= prior.success_rate;
  console.log(
    `baseline ${key}: ${(prior.success_rate * 100).toFixed(0)}% -> ${okay ? "at or above baseline" : "BELOW BASELINE"}`,
  );
  if (!okay) process.exit(1);
}
