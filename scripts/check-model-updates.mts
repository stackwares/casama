/**
 * Newer models for the ones Casama Cloud runs (D-364). Reads CLOUD_MODEL_DEFAULTS, asks
 * OpenRouter's public model list for newer models from the same maker and family, and prints a
 * Markdown report with prices next to what we pay now. Read-only; it changes nothing.
 *   node scripts/check-model-updates.mts          report, marking models not seen before as NEW
 *   node scripts/check-model-updates.mts --json   the same as JSON
 * Models already reported are remembered in ~/.config/casama/model-updates-seen.json.
 *
 * Switching to a newer model: add it to the OpenRouter guardrail "Casama privacy" FIRST
 * (openrouter.ai/workspaces/casama/guardrails, Only allow), then change the model in Admin →
 * Cloud models or in packages/domain/src/cloud-model-assignment.ts. Otherwise every call on
 * Casama's key fails with 404 "Model blocked by guardrail".
 */
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { CLOUD_MODEL_DEFAULTS } from "../packages/domain/src/cloud-model-assignment.ts";
import { DEFAULT_SHADOW_MODELS } from "../packages/domain/src/decision-settings.ts";

type OrModel = {
  id: string;
  name: string;
  created: number;
  pricing: Record<string, string | undefined>;
  architecture?: { input_modalities?: string[]; output_modalities?: string[] };
};

const json = process.argv.includes("--json");
const seenFile = join(homedir(), ".config", "casama", "model-updates-seen.json");

// The roles that run on OpenRouter, and the words that keep a candidate in the same family.
// (live runs on Google directly and is checked by hand: OpenRouter doesn't list Live models.)
const FAMILY: Record<string, RegExp> = {
  chat: /flash/,
  background: /flash/,
  image: /nano-banana|image/,
  tts: /tts/,
  stt: /whisper|transcri|stt/,
  embedding: /embedding/,
  video: /omni|veo|video/,
};

function openRouterId(role: string, id: string): string {
  // The embedding default is stored by OpenAI's own name; on OpenRouter it is openai/….
  if (role === "embedding" && !id.includes("/")) return `openai/${id}`;
  return id;
}

function perMillion(price: string | undefined): string {
  if (price === undefined) return "?";
  const n = Number(price) * 1_000_000;
  return Number.isFinite(n) ? `$${n < 1 ? n.toFixed(3) : n.toFixed(2)}` : "?";
}

function priceLine(m: OrModel): string {
  const p = m.pricing;
  const parts = [`in ${perMillion(p.prompt)}/M`, `out ${perMillion(p.completion)}/M`];
  if (p.image && Number(p.image) > 0) parts.push(`image $${Number(p.image).toFixed(4)}`);
  return parts.join(", ");
}

const res = await fetch("https://openrouter.ai/api/v1/models?output_modalities=all");
if (!res.ok) throw new Error(`OpenRouter models: HTTP ${res.status}`);
const all = ((await res.json()) as { data: OrModel[] }).data;
const byId = new Map(all.map((m) => [m.id, m]));

let seen: string[] = [];
try {
  seen = JSON.parse(readFileSync(seenFile, "utf8"));
} catch {}
const seenSet = new Set(seen);

type Row = {
  role: string;
  current: string;
  currentFound: boolean;
  currentPrice?: string;
  newer: { id: string; name: string; created: string; price: string; isNew: boolean }[];
};
const rows: Row[] = [];
const done = new Set<string>();

// Decision models (D-454): the shadow candidates, each against newer decision models of its maker.
// The model running in production is in Admin → Decisions; check it here when it isn't one of these.
const decides = (m: OrModel) => m.architecture?.output_modalities?.includes("decisions") === true;
const checks: Array<{ role: string; raw: string; family: (m: OrModel) => boolean }> = [
  ...Object.entries(FAMILY).map(([role, re]) => ({
    role,
    raw: (CLOUD_MODEL_DEFAULTS as unknown as Record<string, string>)[role] ?? "",
    family: (m: OrModel) => re.test(m.id),
  })),
  ...DEFAULT_SHADOW_MODELS.map((raw) => ({ role: "decision", raw, family: decides })),
];

for (const { role, raw, family } of checks) {
  if (!raw) continue;
  const id = openRouterId(role, raw);
  if (done.has(id)) continue; // chat and background share a model
  done.add(id);
  const cur = byId.get(id);
  const vendor = id.split("/")[0];
  const since = cur?.created ?? 0;
  const newer = all
    .filter(
      (m) =>
        m.id.startsWith(`${vendor}/`) &&
        m.id !== id &&
        !m.id.includes(":") && // :free, :batch
        family(m) &&
        m.created > since,
    )
    .sort((a, b) => b.created - a.created)
    .map((m) => ({
      id: m.id,
      name: m.name,
      created: new Date(m.created * 1000).toISOString().slice(0, 10),
      price: priceLine(m),
      isNew: !seenSet.has(m.id),
    }));
  rows.push({
    role: role === "chat" ? "chat + background" : role,
    current: id,
    currentFound: !!cur,
    currentPrice: cur ? priceLine(cur) : undefined,
    newer,
  });
}

const fresh = rows.flatMap((r) => r.newer.filter((n) => n.isNew).map((n) => n.id));
mkdirSync(join(homedir(), ".config", "casama"), { recursive: true });
writeFileSync(seenFile, JSON.stringify([...new Set([...seen, ...fresh])].sort(), null, 2));

if (json) {
  console.log(JSON.stringify({ checked: new Date().toISOString(), rows, fresh }, null, 2));
} else {
  console.log(`# Cloud model check (${new Date().toISOString().slice(0, 10)})\n`);
  console.log(
    fresh.length
      ? `**${fresh.length} model(s) not reported before.**\n`
      : "Nothing new since the last check.\n",
  );
  for (const r of rows) {
    console.log(`## ${r.role}: \`${r.current}\``);
    console.log(
      r.currentFound
        ? `Now: ${r.currentPrice}`
        : "**Not on OpenRouter's list any more (retired or renamed?)**",
    );
    if (!r.newer.length) console.log("- no newer model in this family");
    for (const n of r.newer)
      console.log(
        `- ${n.isNew ? "**NEW** " : ""}\`${n.id}\` (${n.name}, ${n.created}): ${n.price}`,
      );
    console.log("");
  }
  console.log(
    'Switching: add the model to the OpenRouter guardrail "Casama privacy" first, then change it in Admin → Cloud models (D-364).',
  );
}
