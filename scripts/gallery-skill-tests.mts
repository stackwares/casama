/**
 * Runs gallery skills' tests.json against a model and records passes in gallery/tested.json
 * (D-315). Opt-in and paid: it needs OPENROUTER_API_KEY and is never part of `pnpm test`.
 *   OPENROUTER_API_KEY=... node scripts/gallery-skill-tests.mts [skill-id ...]
 *   --dry-run   list what would run, call nothing, write nothing
 * Env: GALLERY_TEST_MODEL (default google/gemini-2.5-flash-lite) answers with the skill loaded;
 * GALLERY_JUDGE_MODEL (default the same) checks each answer against the case's `expect`.
 * A skill passes when every case passes. Afterwards run `node gallery/check.mjs` so index.json
 * carries `tested` for skills that passed on their current version.
 */
import { readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import {
  checkGalleryTests,
  type GalleryTestCase,
  type GalleryTestedEntry,
  parseGalleryTested,
} from "../packages/domain/src/gallery-catalog.ts";
import { parseSkillMd } from "../packages/domain/src/skill-format.ts";

const root = fileURLToPath(new URL("../gallery", import.meta.url));
const args = process.argv.slice(2);
const dryRun = args.includes("--dry-run");
const only = new Set(args.filter((a) => !a.startsWith("--")));
const key = process.env.OPENROUTER_API_KEY;
const model = process.env.GALLERY_TEST_MODEL || "google/gemini-2.5-flash-lite";
const judge = process.env.GALLERY_JUDGE_MODEL || model;

if (!key && !dryRun) {
  console.error(
    "OPENROUTER_API_KEY is not set. This runner calls a paid model, so it only runs when asked.",
  );
  process.exit(1);
}

async function chat(modelId: string, messages: { role: string; content: string }[], json = false) {
  const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: { authorization: `Bearer ${key}`, "content-type": "application/json" },
    body: JSON.stringify({
      model: modelId,
      messages,
      temperature: 0,
      max_tokens: 1500,
      ...(json ? { response_format: { type: "json_object" } } : {}),
    }),
    signal: AbortSignal.timeout(120_000),
  });
  if (!res.ok) throw new Error(`${modelId}: HTTP ${res.status} ${await res.text()}`);
  const body = (await res.json()) as { choices?: { message?: { content?: string } }[] };
  return body.choices?.[0]?.message?.content ?? "";
}

async function runCase(skillMd: string, c: GalleryTestCase) {
  const { body } = parseSkillMd(skillMd);
  const answer = await chat(model, [
    {
      role: "system",
      content: `You are a helpful assistant. Follow this skill's instructions for the request.\n\n${body}`,
    },
    { role: "user", content: c.prompt },
  ]);
  const verdict = await chat(
    judge,
    [
      {
        role: "system",
        content:
          'You grade an assistant\'s answer against a rubric. Reply with JSON only: {"pass": true|false, "reason": "one sentence"}. Pass only when the answer meets every point of the rubric.',
      },
      {
        role: "user",
        content: `Request:\n${c.prompt}\n\nRubric:\n${c.expect}\n\nAnswer:\n${answer}`,
      },
    ],
    true,
  );
  try {
    const parsed = JSON.parse(verdict) as { pass?: unknown; reason?: unknown };
    return { pass: parsed.pass === true, reason: String(parsed.reason ?? "") };
  } catch {
    return { pass: false, reason: `judge didn't answer in JSON: ${verdict.slice(0, 120)}` };
  }
}

const testedPath = join(root, "tested.json");
let tested: Record<string, GalleryTestedEntry> = {};
try {
  tested = parseGalleryTested(JSON.parse(readFileSync(testedPath, "utf8"))).tested;
} catch {
  tested = {};
}

const today = new Date().toISOString().slice(0, 10);
let failures = 0;
for (const id of readdirSync(join(root, "skills")).sort()) {
  if (only.size && !only.has(id)) continue;
  const folder = join(root, "skills", id);
  let testsRaw: unknown;
  try {
    testsRaw = JSON.parse(readFileSync(join(folder, "tests.json"), "utf8"));
  } catch {
    continue;
  }
  const { cases, errors } = checkGalleryTests(testsRaw);
  if (!cases) {
    console.error(`${id}: ${errors.join("; ")}`);
    failures++;
    continue;
  }
  const meta = JSON.parse(readFileSync(join(folder, "item.json"), "utf8")) as { version?: number };
  const version = Number.isInteger(meta.version) ? (meta.version as number) : 1;
  if (dryRun) {
    console.log(`${id} v${version}: ${cases.length} case(s) with ${model}, judged by ${judge}`);
    continue;
  }
  const skillMd = readFileSync(join(folder, "SKILL.md"), "utf8");
  let passed = true;
  for (const [i, c] of cases.entries()) {
    try {
      const r = await runCase(skillMd, c);
      console.log(`${id} case ${i + 1}: ${r.pass ? "pass" : "FAIL"} ${r.reason}`);
      if (!r.pass) passed = false;
    } catch (err) {
      console.log(`${id} case ${i + 1}: ERROR ${(err as Error).message}`);
      passed = false;
    }
  }
  if (!passed) failures++;
  tested[id] = { version, passed, date: today };
}

if (!dryRun) {
  const sorted = Object.fromEntries(Object.entries(tested).sort(([a], [b]) => a.localeCompare(b)));
  writeFileSync(testedPath, `${JSON.stringify(sorted, null, 2)}\n`);
  console.log("wrote gallery/tested.json; run node gallery/check.mjs to refresh the index");
}
process.exit(failures ? 1 : 0);
