/**
 * Load test setup (SPEC "Testing: Load"): one user with 200 webhook-triggered bots and 100 chat
 * bots on a local stack with recorded model fixtures. Writes the ids k6 needs.
 *   node --env-file=../../.env load/setup.ts [api] [out]
 */
import { writeFileSync } from "node:fs";

const api = process.argv[2] ?? "http://127.0.0.1:8787";
const out = process.argv[3] ?? "/tmp/kasama-load.json";
const supabase = process.env.SUPABASE_URL ?? "http://127.0.0.1:54321";
const anon = process.env.SUPABASE_ANON_KEY as string;
const WAKE = Number(process.env.LOAD_WAKE_BOTS ?? 200);
const CHAT = Number(process.env.LOAD_CHAT_STREAMS ?? 100);

const email = `load-${Date.now()}@example.com`;
const signup = await fetch(`${supabase}/auth/v1/signup`, {
  method: "POST",
  headers: { apikey: anon, "content-type": "application/json" },
  body: JSON.stringify({ email, password: "load-test-pw-1" }),
});
const session = (await signup.json()) as { access_token?: string };
if (!session.access_token) throw new Error(`signup failed: ${JSON.stringify(session)}`);
const token = session.access_token;
const call = async (path: string, body?: unknown) => {
  const r = await fetch(`${api}${path}`, {
    method: body ? "POST" : "GET",
    headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!r.ok) throw new Error(`${path}: ${r.status} ${await r.text()}`);
  return r.json() as Promise<Record<string, unknown> & { id: string }>;
};

const org = await call("/v1/orgs", { name: "Load test" });
const cred = await call("/v1/credentials", {
  org_id: org.id,
  provider: "openrouter",
  label: "fixture",
  api_key: "sk-load-test-fixture",
});
const policy = { primary: { credential_id: cred.id, model: "fixture-main" } };
const pool = async <T>(n: number, fn: (i: number) => Promise<T>, width = 20) => {
  const res: T[] = [];
  for (let i = 0; i < n; i += width)
    res.push(
      ...(await Promise.all(Array.from({ length: Math.min(width, n - i) }, (_, k) => fn(i + k)))),
    );
  return res;
};
const wake = await pool(WAKE, async (i) => {
  const bot = await call("/v1/bots", {
    org_id: org.id,
    name: `Waker ${i}`,
    autonomy: "autonomous",
    model_policy: policy,
  });
  const r = await call("/v1/routines", {
    bot_id: bot.id,
    name: "Wake",
    instructions: "Say hello.",
    trigger: "webhook",
  });
  return { routine_id: r.id, secret: r.webhook_secret as string };
});
const chat = await pool(CHAT, async (i) => {
  const bot = await call("/v1/bots", {
    org_id: org.id,
    name: `Chatter ${i}`,
    autonomy: "autonomous",
    model_policy: policy,
  });
  const conv = await call("/v1/conversations", { bot_id: bot.id });
  return { conversation_id: conv.id };
});
writeFileSync(out, JSON.stringify({ api, token, org_id: org.id, wake, chat }), { mode: 0o600 });
console.log(
  `load setup: org ${org.id}, ${wake.length} webhook bots, ${chat.length} chat bots -> ${out}`,
);
