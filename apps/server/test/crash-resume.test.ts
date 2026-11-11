import { type ChildProcess, spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));
const SERVER_DIR = fileURLToPath(new URL("..", import.meta.url));

let h: Harness;
let current: ChildProcess | undefined;

/** Starts a real worker process (MODE=worker) against the test database. */
function startWorkerProcess(): Promise<ChildProcess> {
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
      },
    });
    let out = "";
    const onData = (d: Buffer) => {
      out += d;
      if (out.includes("worker started")) resolve(p);
    };
    p.stdout?.on("data", onData);
    p.stderr?.on("data", onData);
    p.once("exit", (code) =>
      reject(new Error(`worker exited early (${code}): ${out.slice(-2000)}`)),
    );
    setTimeout(() => reject(new Error(`worker did not start: ${out.slice(-2000)}`)), 30_000);
  });
}

const events = (runId: string) =>
  h.tdb.admin<{ seq: number; type: string; payload: Record<string, unknown> }[]>`
    select seq, type, payload from public.run_events where run_id = ${runId} order by seq`;

async function waitFor<T>(
  fn: () => Promise<T | undefined | false>,
  timeoutMs: number,
  what: string,
): Promise<T> {
  const until = Date.now() + timeoutMs;
  for (;;) {
    const v = await fn();
    if (v) return v;
    if (Date.now() > until) {
      const runs = await h.tdb.admin`select id, status, error from public.runs`;
      const evs = await h.tdb
        .admin`select run_id, seq, type from public.run_events order by run_id, seq`;
      const wf = await h.tdb
        .admin`select workflow_uuid, status, name, queue_name, error from dbos.workflow_status`.catch(
        (e) => [String(e)],
      );
      throw new Error(`timed out waiting for ${what}: ${JSON.stringify({ runs, evs, wf })}`);
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

it("resumes a run at the last finished step after the worker is killed", async () => {
  current = await startWorkerProcess();

  const owner = await h.user("crash@example.com");
  const org = await j(
    await h.request("/v1/orgs", {
      method: "POST",
      token: owner.token,
      json: { name: "Crash Org" },
    }),
  );
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: org.id, provider: "openrouter", label: "k", api_key: "sk-crash-test-key" },
    }),
  );
  const bot = await j(
    await h.request("/v1/bots", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: org.id,
        name: "Crashy",
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

  // Kill the worker after the tool step finished and the final answer started streaming.
  await waitFor(
    async () => {
      const evs = await events(sent.run_id);
      return (
        evs.some((e) => e.type === "tool.completed") && evs.some((e) => e.type === "message.delta")
      );
    },
    20_000,
    "the final model step to start",
  );
  current.kill("SIGKILL");
  await new Promise((r) => current?.once("exit", r));

  const [mid] = await h.tdb.admin<
    { status: string }[]
  >`select status from public.runs where id = ${sent.run_id}`;
  expect(mid?.status).toBe("running");
  const beforeRestart = await events(sent.run_id);
  expect(beforeRestart.some((e) => e.type === "run.completed")).toBe(false);

  // A new worker recovers the pending workflow and finishes it.
  current = await startWorkerProcess();
  await waitFor(
    async () => {
      const [r] = await h.tdb.admin<
        { status: string }[]
      >`select status from public.runs where id = ${sent.run_id}`;
      return r?.status === "completed";
    },
    30_000,
    "the run to complete after restart",
  );

  const evs = await events(sent.run_id);
  expect(evs.map((e) => e.seq)).toEqual(evs.map((_, i) => i + 1)); // gap-free
  expect(evs.filter((e) => e.type === "run.started")).toHaveLength(1);
  expect(evs.filter((e) => e.type === "tool.started")).toHaveLength(1); // the finished tool step did not run again
  expect(evs.filter((e) => e.type === "run.completed")).toHaveLength(1);
  const done = evs.filter((e) => e.type === "message.completed");
  expect(done).toHaveLength(1);
  expect(JSON.stringify(done[0]?.payload)).toContain("Resumed after the crash and finished.");

  const msgs = await h.tdb
    .admin`select id from public.messages where conversation_id = ${conv.id} and role = 'assistant'`;
  expect(msgs).toHaveLength(1);
  const mems = await h.tdb
    .admin`select id from public.memories where bot_id = ${bot.id} and content = 'Crash test marker fact.'`;
  expect(mems).toHaveLength(1);
}, 90_000);
