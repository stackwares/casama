import { type ChildProcess, spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

// A deploy stops the worker with SIGTERM (D-402): the step in flight finishes and is saved, no new
// step starts, and the next worker carries the run on from there, so nothing runs twice.

const FIXTURES = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));
const SERVER_DIR = fileURLToPath(new URL("..", import.meta.url));

let h: Harness;
let current: ChildProcess | undefined;
let output = "";

function startWorkerProcess(): Promise<ChildProcess> {
  output = "";
  return new Promise((resolve, reject) => {
    const p = spawn("node", ["src/main.ts"], {
      cwd: SERVER_DIR,
      env: {
        ...process.env,
        MODE: "worker",
        DATABASE_URL: h.tdb.url,
        SUPABASE_URL: "http://127.0.0.1:1",
        SUPABASE_ANON_KEY: "x",
        CASAMA_MODEL_FIXTURES: FIXTURES,
        EMBEDDINGS: "hash",
        LOG_LEVEL: "info",
        WORKER_DRAIN_SECONDS: "20",
      },
    });
    const onData = (d: Buffer) => {
      output += d;
      if (output.includes("worker started")) resolve(p);
    };
    p.stdout?.on("data", onData);
    p.stderr?.on("data", onData);
    p.once("exit", (code) =>
      reject(new Error(`worker exited early (${code}): ${output.slice(-2000)}`)),
    );
    setTimeout(() => reject(new Error(`worker did not start: ${output.slice(-2000)}`)), 30_000);
  });
}

const events = (runId: string) =>
  h.tdb.admin<{ seq: number; type: string; payload: Record<string, unknown> }[]>`
    select seq, type, payload from public.run_events where run_id = ${runId} order by seq`;

async function waitFor<T>(fn: () => Promise<T | undefined | false>, ms: number, what: string) {
  const until = Date.now() + ms;
  for (;;) {
    const v = await fn();
    if (v) return v;
    if (Date.now() > until) {
      const runs = await h.tdb.admin`select id, status, error from public.runs`;
      throw new Error(`timed out waiting for ${what}: ${JSON.stringify(runs)}`);
    }
    await new Promise((r) => setTimeout(r, 50));
  }
}

beforeAll(async () => {
  h = await startHarness({ workflowsClient: true });
}, 60_000);
afterAll(async () => {
  current?.kill("SIGKILL");
  await h?.stop();
});

it("finishes the step in flight on SIGTERM and the next worker carries the run on", async () => {
  current = await startWorkerProcess();
  const owner = await h.user("graceful@example.com");
  const org = await j(
    await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "G Org" } }),
  );
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: org.id, provider: "openrouter", label: "k", api_key: "sk-graceful-key" },
    }),
  );
  const bot = await j(
    await h.request("/v1/bots", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: org.id,
        name: "Steady",
        model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
      },
    }),
  );
  const conv = await j(
    await h.request("/v1/conversations", {
      method: "POST",
      token: owner.token,
      json: { bot_id: bot.id },
    }),
  );
  const sent = await j(
    await h.request(`/v1/conversations/${conv.id}/messages`, {
      method: "POST",
      token: owner.token,
      json: { text: "crash test please" },
    }),
  );

  // Stop the worker while the final answer streams (six parts, 250 ms apart).
  await waitFor(
    async () => (await events(sent.run_id)).some((e) => e.type === "message.delta"),
    20_000,
    "the final model step to start",
  );
  const worker = current;
  const exited = new Promise<number | null>((r) => worker.once("exit", r));
  worker.kill("SIGTERM");
  expect(await exited).toBe(0);
  expect(output).toContain("worker drained");
  expect(output).toMatch(/"steps_cut":0/);

  // The step finished and was saved; the run itself waits for the next worker.
  const [mid] = await h.tdb.admin<
    { status: string }[]
  >`select status from public.runs where id = ${sent.run_id}`;
  expect(mid?.status).toBe("running");
  const streamed = (await events(sent.run_id)).filter((e) => e.type === "message.delta");

  current = await startWorkerProcess();
  await waitFor(
    async () => {
      const [r] = await h.tdb.admin<
        { status: string }[]
      >`select status from public.runs where id = ${sent.run_id}`;
      return (
        r?.status === "completed" &&
        (await events(sent.run_id)).some((e) => e.type === "run.completed")
      );
    },
    30_000,
    "the run to complete on the next worker",
  );

  const evs = await events(sent.run_id);
  expect(evs.map((e) => e.seq)).toEqual(evs.map((_, i) => i + 1));
  expect(evs.filter((e) => e.type === "run.started")).toHaveLength(1);
  expect(evs.filter((e) => e.type === "tool.started")).toHaveLength(1);
  // The answer streamed once: the saved model step was not run again (a SIGKILL streams it twice).
  expect(evs.filter((e) => e.type === "message.delta")).toEqual(streamed);
  const done = evs.filter((e) => e.type === "message.completed");
  expect(done).toHaveLength(1);
  expect(JSON.stringify(done[0]?.payload)).toContain("Resumed after the crash and finished.");
  const msgs = await h.tdb
    .admin`select id from public.messages where conversation_id = ${conv.id} and role = 'assistant'`;
  expect(msgs).toHaveLength(1);
}, 90_000);
