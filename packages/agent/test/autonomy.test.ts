import { once } from "node:events";
import { createServer, type IncomingMessage, type Server, type ServerResponse } from "node:http";
import type { AddressInfo } from "node:net";
import { createDb, type DbHandle } from "@casama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { z } from "zod";
import {
  BraveSearchProvider,
  builtinTools,
  CredentialResolver,
  createSafeFetch,
  directSteps,
  FalMediaProvider,
  type FixtureFile,
  type FixtureTurn,
  hashEmbedder,
  NotificationService,
  PostgresMemoryStore,
  RecordingPushSender,
  ReplayGateway,
  type RunDeps,
  refreshIntegration,
  registerAutonomyTools,
  runAgent,
  ToolRegistry,
} from "../src/index.ts";

const SECRET_VALUE = "tok_live_ABCDEF1234567890";

let tdb: TestDatabase;
let h: DbHandle;
let orgId: string;
let userId: string;
let credId: string;
let api: Server;
let apiUrl: string;
const received: Array<{
  method: string;
  url: string;
  headers: IncomingMessage["headers"];
  body: string;
}> = [];
const push = new RecordingPushSender();
const testFetch = createSafeFetch({ exemptCidrs: ["127.0.0.1/32"] });

const finish = (n = 1) => ({
  type: "finish" as const,
  usage: { inputTokens: 1000 * n, outputTokens: 100 * n },
  finishReason: "stop",
  model: "",
});
const call = (callId: string, name: string, args: Record<string, unknown>) => ({
  type: "tool_call" as const,
  call: { callId, name, args },
});
const say = (text: string) => ({ type: "text" as const, text });
const turn = (when: FixtureTurn["when"], ...events: FixtureTurn["events"]): FixtureTurn => ({
  when,
  events,
});

/** A local stand-in for outside services: echo API, OpenAPI source, Composio, Pipedream, fal.ai, Brave, MCP. */
async function startApi() {
  const mcp = async (req: IncomingMessage, res: ServerResponse, body: unknown) => {
    const server = new McpServer({ name: "calc", version: "1.0.0" });
    server.registerTool(
      "add",
      {
        description: "Add two numbers",
        inputSchema: { a: z.number(), b: z.number() },
        annotations: { readOnlyHint: true },
      },
      async ({ a, b }) => ({ content: [{ type: "text", text: String(a + b) }] }),
    );
    const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
    res.on("close", () => void transport.close());
    await server.connect(transport);
    await transport.handleRequest(req, res, body);
  };
  const json = (res: ServerResponse, status: number, data: unknown) =>
    res.writeHead(status, { "content-type": "application/json" }).end(JSON.stringify(data));
  api = createServer(async (req, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    const raw = Buffer.concat(chunks).toString();
    const url = new URL(req.url ?? "/", "http://x");
    received.push({
      method: req.method ?? "",
      url: url.pathname + url.search,
      headers: req.headers,
      body: raw,
    });
    const body = raw ? JSON.parse(raw) : undefined;
    if (url.pathname === "/mcp") return mcp(req, res, body);
    if (url.pathname === "/echo")
      return json(res, 200, { ok: true, auth: req.headers.authorization ?? null });
    if (url.pathname.startsWith("/pets/"))
      return json(res, 200, { id: url.pathname.split("/")[2], name: "Rex" });
    // Composio v3
    if (url.pathname === "/api/v3/tools") {
      return json(res, 200, {
        items: [
          {
            slug: "GITHUB_STAR_REPO",
            name: "Star repo",
            description: "Star a GitHub repository",
            input_parameters: {
              type: "object",
              properties: { repo: { type: "string" } },
              required: ["repo"],
            },
          },
        ],
      });
    }
    if (url.pathname === "/api/v3/tools/execute/GITHUB_STAR_REPO")
      return json(res, 200, {
        successful: true,
        data: { starred: body?.arguments?.repo, user: body?.user_id },
      });
    // Pipedream Connect
    if (url.pathname === "/v1/oauth/token")
      return json(res, 200, { access_token: "pd-token", expires_in: 3600 });
    if (url.pathname === "/v1/connect/proj_1/actions") {
      return json(res, 200, {
        data: [
          {
            key: "slack-send-message",
            name: "Send message",
            description: "Send a Slack message",
            configurable_props: [
              { name: "slack", type: "app" },
              { name: "text", type: "string" },
            ],
          },
        ],
      });
    }
    if (url.pathname === "/v1/connect/proj_1/actions/run")
      return json(res, 200, { ret: { sent: body?.configured_props?.text, action: body?.id } });
    // fal.ai
    if (url.pathname === "/fal-ai/bytedance/seedream/v4.5/text-to-image")
      return json(res, 200, {
        images: [
          { url: `${apiUrl}/files/img.png`, content_type: "image/png", width: 1024, height: 1024 },
        ],
      });
    // fal's queue: animating a picture (image-to-video).
    if (url.pathname === "/fal-ai/ltx-video/image-to-video" && req.method === "POST")
      return json(res, 200, {
        request_id: "v1",
        status_url: `${apiUrl}/queue/v1/status`,
        response_url: `${apiUrl}/queue/v1`,
      });
    if (url.pathname === "/queue/v1/status") return json(res, 200, { status: "COMPLETED" });
    if (url.pathname === "/queue/v1")
      return json(res, 200, { video: { url: `${apiUrl}/files/clip.mp4` } });
    if (url.pathname === "/files/clip.mp4")
      return res.writeHead(200, { "content-type": "video/mp4" }).end(Buffer.from("mp4"));
    if (url.pathname === "/files/img.png")
      return res
        .writeHead(200, { "content-type": "image/png" })
        .end(Buffer.from([137, 80, 78, 71]));
    // Brave Search
    if (url.pathname === "/res/v1/web/search")
      return json(res, 200, {
        web: {
          results: [
            { title: "Casama", url: "https://example.com/k", description: "Result <b>one</b>" },
          ],
        },
      });
    json(res, 404, { error: "not found" });
  }).listen(0, "127.0.0.1");
  await once(api, "listening");
  apiUrl = `http://127.0.0.1:${(api.address() as AddressInfo).port}`;
}

beforeAll(async () => {
  await startApi();
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 5 });
  const user = await createAuthUser(tdb.admin, "auto@example.com");
  userId = user.id;
  const [org] = await tdb.admin<
    { id: string }[]
  >`insert into public.organizations (name, slug) values ('Auto', 'auto-org') returning id`;
  orgId = org!.id;
  await tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${userId}, 'owner')`;
  await tdb.admin`insert into public.devices (user_id, platform, fcm_token) values (${userId}, 'ios', 'device-token-1')`;
  const [cred] = await tdb.admin<{ id: string }[]>`
    insert into public.model_credentials (org_id, provider, label, vault_secret_id) values (${orgId}, 'openrouter', 'm', vault.create_secret('sk-model-key-xyz123')) returning id`;
  credId = cred!.id;
  await tdb.admin`insert into public.model_credentials (org_id, provider, label, vault_secret_id) values (${orgId}, 'fal', 'fal', vault.create_secret('fal-key-123456'))`;
  await tdb.admin`insert into public.model_credentials (org_id, provider, label, vault_secret_id) values (${orgId}, 'brave_search', 'brave', vault.create_secret('brave-key-123456'))`;
  await tdb.admin`insert into public.secrets (org_id, name, vault_secret_id, allowed_hosts) values (${orgId}, 'API_TOKEN', vault.create_secret(${SECRET_VALUE}), '{127.0.0.1}')`;
}, 60_000);
afterAll(async () => {
  api?.close();
  await h?.close();
  await tdb?.stop();
});

async function makeBot(name: string, opts: { autonomy?: string; budget?: object } = {}) {
  const [bot] = await tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name, model_policy, autonomy, budget)
    values (${orgId}, ${userId}, ${name}, ${tdb.admin.json({ primary: { credential_id: credId, model: "fixture-main" } })},
            ${opts.autonomy ?? "ask_risky"}, ${tdb.admin.json(opts.budget ?? { per_run_usd: 5, daily_usd: 100 })})
    returning id`;
  return bot!.id;
}

async function startRun(botId: string, text: string) {
  const [conv] = await tdb.admin<
    { id: string }[]
  >`insert into public.conversations (org_id, bot_id) values (${orgId}, ${botId}) returning id`;
  const [run] = await tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, created_by) values (${orgId}, ${botId}, ${conv!.id}, ${userId}) returning id`;
  await tdb.admin`insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
    values (${orgId}, ${conv!.id}, 'user', ${userId}, ${tdb.admin.json([{ type: "text", text }])}, ${run!.id})`;
  return run!.id;
}

const events = (runId: string) =>
  tdb.admin<
    { seq: number; type: string; payload: Record<string, unknown> }[]
  >`select seq, type, payload from public.run_events where run_id = ${runId} order by seq`;

function makeDeps(fixtures: FixtureFile[], extra: Partial<RunDeps> = {}) {
  const gateway = new ReplayGateway(fixtures);
  const notifications = new NotificationService(h.db, push);
  const embedder = hashEmbedder();
  const credentials = new CredentialResolver(h.db);
  const keyFor = async (provider: string) => {
    const [r] = await h.db.execute<{ key: string }>(
      (await import("drizzle-orm"))
        .sql`select v.decrypted_secret as key from public.model_credentials c join vault.decrypted_secrets v on v.id = c.vault_secret_id where c.org_id = ${orgId}::uuid and c.provider = ${provider} limit 1`,
    );
    return r?.key ?? null;
  };
  const tools = builtinTools({
    db: h.db,
    memory: async () => new PostgresMemoryStore(h.db, embedder),
  });
  const deps: RunDeps = {
    db: h.db,
    gateway,
    tools,
    credentials,
    embedderFor: async () => embedder,
    step: directSteps,
    notifications,
    fetch: testFetch,
    deltaIntervalMs: 10,
    cancelPollMs: 50,
    fallback: { backoffMs: 1 },
    ...extra,
  };
  registerAutonomyTools(tools, {
    db: h.db,
    fetch: testFetch,
    notifications,
    mediaFor: async () => {
      const key = await keyFor("fal");
      return key
        ? new FalMediaProvider({
            apiKey: key,
            fetch: testFetch,
            syncBase: apiUrl,
            queueBase: apiUrl,
          })
        : null;
    },
    searchFor: async () => {
      const key = await keyFor("brave_search");
      return key ? new BraveSearchProvider(key, { base: apiUrl, fetch: testFetch }) : null;
    },
    runChild: (id) => runAgent(id, deps),
  });
  return { deps, gateway };
}

/** Approves (or denies) the first pending approval of a run as soon as it appears. */
function decideWhenPending(runId: string, decision: "approved" | "denied", alwaysAllow = false) {
  return (async () => {
    for (let i = 0; i < 200; i++) {
      const [a] = await tdb.admin<
        { id: string }[]
      >`select id from public.approvals where run_id = ${runId} and status = 'pending' limit 1`;
      if (a) {
        await tdb.admin`update public.approvals set status = ${decision}, always_allow = ${alwaysAllow}, decided_by = ${userId}, decided_at = now() where id = ${a.id}`;
        if (alwaysAllow) {
          // What decide_approval does for "always allow": a tool rule (D-115).
          await tdb.admin`insert into public.action_rules (org_id, bot_id, match_kind, match_value, rule) select org_id, bot_id, 'tool', tool_name, 'allow' from public.approvals where id = ${a.id}`;
        }
        return a.id;
      }
      await new Promise((r) => setTimeout(r, 50));
    }
    throw new Error("no approval appeared");
  })();
}

describe("approvals", () => {
  const fixtures: FixtureFile[] = [
    {
      name: "approvals",
      turns: [
        turn({ systemIncludes: "extract lasting memories" }, say('{"memories":[]}'), finish()),
        turn(
          { lastRole: "user", lastUserIncludes: "schedule a check" },
          call("r1", "routines__create", {
            name: "Check",
            instructions: "Check the site",
            schedule_cron: "0 9 * * *",
          }),
          finish(),
        ),
        turn(
          { lastRole: "tool", lastToolName: "routines.create" },
          say("Done scheduling."),
          finish(),
        ),
        turn(
          { lastRole: "user", lastUserIncludes: "make an image" },
          call("m1", "media__image__generate", { prompt: "a teal robot" }),
          finish(),
        ),
        turn(
          { lastRole: "tool", lastToolName: "media.image.generate" },
          say("Here is your image."),
          finish(),
        ),
        turn(
          { lastRole: "user", lastUserIncludes: "search then call" },
          call("s1", "web__search", { query: "casama" }),
          finish(),
        ),
        turn(
          { lastRole: "tool", lastToolName: "web.search", lastUserIncludes: "search then call" },
          call("h1", "http__request", { method: "POST", url: `PLACEHOLDER/echo`, body: "{}" }),
          finish(),
        ),
        turn(
          { lastRole: "user", lastUserIncludes: "search then read" },
          call("s2", "web__search", { query: "casama" }),
          finish(),
        ),
        turn(
          { lastRole: "tool", lastToolName: "web.search", lastUserIncludes: "search then read" },
          call("h2", "http__request", { method: "GET", url: `PLACEHOLDER/echo` }),
          finish(),
        ),
        turn({ lastRole: "tool", lastToolName: "http.request" }, say("Called the API."), finish()),
      ],
    },
  ];
  const fix = () =>
    JSON.parse(JSON.stringify(fixtures).replaceAll("PLACEHOLDER", apiUrl)) as FixtureFile[];

  it("medium-risk tools run without approval under ask_risky until untrusted content is read", async () => {
    const botId = await makeBot("Planner");
    const runId = await startRun(botId, "Please schedule a check every morning");
    expect((await runAgent(runId, makeDeps(fix()).deps)).status).toBe("completed");
    const [r] = await tdb.admin<
      { next_run_at: Date; timezone: string }[]
    >`select next_run_at, timezone from public.routines where bot_id = ${botId}`;
    expect(r?.next_run_at).toBeTruthy();
    expect((await events(runId)).some((e) => e.type === "approval.requested")).toBe(false);
  });

  it("reading the web after untrusted input runs without approval under ask_risky (D-213)", async () => {
    const botId = await makeBot("Reader");
    const runId = await startRun(botId, "search then read the api");
    expect((await runAgent(runId, makeDeps(fix()).deps)).status).toBe("completed");
    const evs = await events(runId);
    expect(evs.some((e) => e.type === "approval.requested")).toBe(false);
    expect(evs.filter((e) => e.type === "tool.completed")).toHaveLength(2);
  });

  it("asks before sending data out after untrusted input; approval resumes the run", async () => {
    const botId = await makeBot("Searcher");
    const runId = await startRun(botId, "search then call the api");
    const decided = decideWhenPending(runId, "approved");
    expect((await runAgent(runId, makeDeps(fix()).deps)).status).toBe("completed");
    await decided;
    const types = (await events(runId)).map((e) => e.type);
    expect(types.indexOf("approval.requested")).toBeGreaterThan(types.indexOf("tool.completed"));
    expect(types).toContain("approval.resolved");
    const [run] = await tdb.admin<
      { status: string }[]
    >`select status from public.runs where id = ${runId}`;
    expect(run?.status).toBe("completed");
    // The owner was notified with a deep link.
    expect(
      push.sent.some(
        (p) => p.message.link?.startsWith("/approvals/") && p.tokens.includes("device-token-1"),
      ),
    ).toBe(true);
  });

  it("media generation runs without asking under ask_risky (D-213)", async () => {
    const botId = await makeBot("ArtistFree");
    const runId = await startRun(botId, "make an image of a robot");
    expect((await runAgent(runId, makeDeps(fix()).deps)).status).toBe("completed");
    const evs = await events(runId);
    expect(evs.some((e) => e.type === "approval.requested")).toBe(false);
    expect(evs.find((e) => e.type === "tool.completed")?.payload.result_preview).toBe(
      "image generated",
    );
  });

  // The approval flow itself, on bots that ask before acting.
  it("media generation waits for approval when the bot asks first, and denying cancels that step only", async () => {
    const botId = await makeBot("Artist", { autonomy: "ask_always" });
    const runId = await startRun(botId, "make an image of a robot");
    const decided = decideWhenPending(runId, "denied");
    expect((await runAgent(runId, makeDeps(fix()).deps)).status).toBe("completed");
    await decided;
    const evs = await events(runId);
    expect(evs.find((e) => e.type === "tool.failed")?.payload).toMatchObject({
      error_code: "approval_denied",
    });
    expect(evs.find((e) => e.type === "approval.resolved")?.payload).toMatchObject({
      decision: "denied",
    });
    expect(evs.at(-1)?.type).toBe("run.completed");
  });

  it("without a media key nobody is asked to approve: the step says what's missing", async () => {
    await tdb.admin`delete from public.model_credentials where org_id = ${orgId} and provider = 'fal'`;
    try {
      const botId = await makeBot("ArtistNoKey");
      const runId = await startRun(botId, "make an image of a robot");
      expect((await runAgent(runId, makeDeps(fix()).deps)).status).toBe("completed");
      const evs = await events(runId);
      expect(evs.some((e) => e.type === "approval.requested")).toBe(false);
      expect(evs.find((e) => e.type === "tool.failed")?.payload).toMatchObject({
        error_code: "no_media_provider",
      });
    } finally {
      await tdb.admin`insert into public.model_credentials (org_id, provider, label, vault_secret_id) values (${orgId}, 'fal', 'fal', vault.create_secret('fal-key-123456'))`;
    }
  });

  it("approved media generation succeeds and is recorded; always-allow skips the next approval", async () => {
    const botId = await makeBot("Artist2", { autonomy: "ask_always" });
    const runId = await startRun(botId, "make an image of a robot");
    const decided = decideWhenPending(runId, "approved", true);
    expect((await runAgent(runId, makeDeps(fix()).deps)).status).toBe("completed");
    await decided;
    expect(
      (await events(runId)).find((e) => e.type === "tool.completed")?.payload.result_preview,
    ).toBe("image generated");
    const [u] = await tdb.admin<
      { n: string }[]
    >`select count(*) as n from public.usage_ledger where run_id = ${runId} and kind = 'media_images'`;
    expect(Number(u?.n)).toBe(1);
    // Priced per model: Seedream 4.5 at $0.04 an image on fal (D-182, D-183).
    const [priced] = await tdb.admin<{ cost_usd: string; model: string }[]>`
      select cost_usd, model from public.usage_ledger where run_id = ${runId} and kind = 'media_images'`;
    expect(priced).toMatchObject({ model: "fal-ai/bytedance/seedream/v4.5/text-to-image" });
    expect(Number(priced?.cost_usd)).toBeCloseTo(0.04, 6);
    // Kept for the chat (D-205) even without a computer, and shown under the reply.
    const [kept] = await tdb.admin<
      { id: string; content_type: string; size: number; width: number | null; n: number }[]
    >`select id, content_type, size, width, octet_length(bytes) as n from public.chat_media where run_id = ${runId}`;
    expect(kept).toMatchObject({ content_type: "image/png", width: 1024 });
    expect(kept!.n).toBe(kept!.size);
    const [reply] = await tdb.admin<{ content: Array<Record<string, unknown>> }[]>`
      select content from public.messages where run_id = ${runId} and role = 'assistant' order by created_at desc limit 1`;
    expect(reply!.content).toContainEqual({
      type: "file",
      path: `media:${kept!.id}`,
      name: "image.png",
      mime_type: "image/png",
      size: kept!.size,
      width: 1024,
      height: 1024,
    });
    const completed = (await events(runId)).filter((e) => e.type === "message.completed").at(-1);
    expect(JSON.stringify(completed?.payload)).toContain(`media:${kept!.id}`);
    const again = await startRun(botId, "make an image of a robot");
    expect((await runAgent(again, makeDeps(fix()).deps)).status).toBe("completed");
    expect((await events(again)).some((e) => e.type === "approval.requested")).toBe(false);
  });

  it("animating a picture from the chat sends that exact picture to the video model", async () => {
    const [pic] = await tdb.admin<{ id: string }[]>`
      insert into public.chat_media (org_id, name, content_type, bytes, size)
      values (${orgId}, 'dog.png', 'image/png', ${Buffer.from([137, 80, 78, 71])}, 4) returning id`;
    const botId = await makeBot("Animator");
    const runId = await startRun(botId, "make this picture a video");
    const fixtures: FixtureFile[] = [
      {
        name: "animate",
        turns: [
          turn({ systemIncludes: "extract lasting memories" }, say('{"memories":[]}'), finish()),
          turn(
            { lastRole: "user", lastUserIncludes: "make this picture a video" },
            call("v1", "media__video__generate", {
              prompt: "the dog wags",
              image: `media:${pic!.id}`,
            }),
            finish(),
          ),
          turn(
            { lastRole: "tool", lastToolName: "media.video.generate" },
            say("Here it is."),
            finish(),
          ),
        ],
      },
    ];
    expect((await runAgent(runId, makeDeps(fixtures).deps)).status).toBe("completed");
    const posted = received.find((r) => r.url === "/fal-ai/ltx-video/image-to-video");
    expect(JSON.parse(posted!.body)).toMatchObject({
      prompt: "the dog wags",
      image_url: "data:image/png;base64,iVBORw==",
    });
    const done = (await events(runId)).find((e) => e.type === "tool.completed");
    expect(String(done?.payload.result_preview)).toContain("video generated");
  });

  it("files.from_chat copies a chat file onto the computer, only from this workspace", async () => {
    const [pic] = await tdb.admin<{ id: string }[]>`
      insert into public.chat_media (org_id, name, content_type, bytes, size)
      values (${orgId}, 'cat.png', 'image/png', ${Buffer.from([1, 2, 3])}, 3) returning id`;
    const writes: Array<[string, number[]]> = [];
    const computer = async () =>
      ({ writeFile: async (p: string, d: Uint8Array) => void writes.push([p, [...d]]) }) as never;
    const ctx = (org: string) => ({
      runId: crypto.randomUUID(),
      botId: crypto.randomUUID(),
      orgId: org,
      output: async () => {},
      emit: async () => {},
      computer,
    });
    const tool = makeDeps([]).deps.tools.get("files.from_chat")!;
    const res = await tool.execute({ file: `media:${pic!.id}` }, ctx(orgId));
    expect(writes).toEqual([["media/cat.png", [1, 2, 3]]]);
    expect(res.content).toBe("Copied cat.png (image/png) to ~/workspace/media/cat.png.");
    await expect(
      tool.execute({ file: `media:${pic!.id}` }, ctx(crypto.randomUUID())),
    ).rejects.toMatchObject({ code: "file_not_found" });
  });

  it("an approval left undecided expires and the run continues", async () => {
    const botId = await makeBot("Waiter", { autonomy: "ask_always" });
    const runId = await startRun(botId, "make an image of a robot");
    const { deps } = makeDeps(fix(), { waitForApproval: async () => {} });
    expect((await runAgent(runId, deps)).status).toBe("completed");
    expect(
      (await events(runId)).find((e) => e.type === "approval.resolved")?.payload,
    ).toMatchObject({ decision: "expired" });
  });
});

describe("routine tools", () => {
  it("schedules one-time work with in_minutes, lists and deletes routines", async () => {
    const botId = await makeBot("Scheduler");
    const runId = await startRun(botId, "remind me later");
    const tools = new ToolRegistry();
    registerAutonomyTools(tools, {
      db: h.db,
      fetch: testFetch,
      notifications: new NotificationService(h.db, push),
    });
    const ctx = { runId, botId, orgId, output: async () => {}, emit: async () => {} };
    const exec = (name: string, args: Record<string, unknown>) =>
      tools.get(name)!.execute(args as never, ctx);

    const before = Date.now();
    const made = await exec("routines.create", {
      name: "Water",
      instructions: "Remind them to drink water.",
      in_minutes: 1,
    });
    expect(made.content).toContain("runs once");
    const [row] = await tdb.admin<
      { id: string; schedule_cron: string | null; trigger: { type: string }; next_run_at: Date }[]
    >`
      select id, schedule_cron, trigger, next_run_at from public.routines where bot_id = ${botId}`;
    expect(row!.schedule_cron).toBeNull();
    expect(row!.trigger.type).toBe("once");
    // It runs in the chat it was asked for in, not a new thread (D-155).
    const [saved] = await tdb.admin<{ same: boolean }[]>`
      select r.conversation_id = run.conversation_id as same from public.routines r, public.runs run
      where r.id = ${row!.id} and run.id = ${runId}`;
    expect(saved!.same).toBe(true);
    const delay = new Date(row!.next_run_at).getTime() - before;
    expect(delay).toBeGreaterThanOrEqual(55_000);
    expect(delay).toBeLessThan(70_000);

    // Exactly one way to schedule.
    await expect(
      exec("routines.create", {
        name: "x",
        instructions: "y",
        in_minutes: 1,
        schedule_cron: "* * * * *",
      }),
    ).rejects.toThrow(/exactly one/);

    const listed = await exec("routines.list", {});
    expect(listed.content).toContain(row!.id);
    expect(listed.content).toContain("once");

    const paused = await exec("routines.update", { routine_id: row!.id, enabled: false });
    expect(paused.preview).toBe("paused");
    const deleted = await exec("routines.delete", { routine_id: row!.id });
    expect(deleted.content).toContain("Water");
    const [left] = await tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.routines where bot_id = ${botId}`;
    expect(left?.n).toBe(0);
  });
});

describe("secrets", () => {
  const fixtures = (): FixtureFile[] => [
    {
      name: "secrets",
      turns: [
        turn({ systemIncludes: "extract lasting memories" }, say('{"memories":[]}'), finish()),
        turn(
          { lastRole: "user", lastUserIncludes: "call with token" },
          call("h1", "http__request", {
            method: "GET",
            url: `${apiUrl}/echo`,
            headers: { authorization: "Bearer {{secret:API_TOKEN}}" },
          }),
          finish(),
        ),
        turn(
          { lastRole: "user", lastUserIncludes: "leak to another host" },
          call("h2", "http__request", {
            method: "GET",
            url: "http://localhost:9/echo",
            headers: { authorization: "{{secret:API_TOKEN}}" },
          }),
          finish(),
        ),
        turn(
          { lastRole: "tool", lastToolName: "http.request" },
          say(`The token was ${SECRET_VALUE}`),
          finish(),
        ),
      ],
    },
  ];

  it("fills placeholders only for allowed hosts and never exposes values to the model, events or messages", async () => {
    const botId = await makeBot("Caller", { autonomy: "autonomous" });
    const runId = await startRun(botId, "call with token please");
    const { deps, gateway } = makeDeps(fixtures());
    expect((await runAgent(runId, deps)).status).toBe("completed");
    // The outside service got the real value...
    expect(
      received.find(
        (r) => r.url === "/echo" && r.headers.authorization === `Bearer ${SECRET_VALUE}`,
      ),
    ).toBeTruthy();
    // ...but the model input, events and saved messages never contain it.
    expect(JSON.stringify(gateway.requests)).not.toContain(SECRET_VALUE);
    const evs = await events(runId);
    expect(JSON.stringify(evs)).not.toContain(SECRET_VALUE);
    expect(JSON.stringify(evs)).toContain("[secret:API_TOKEN]");
    const msgs = await tdb.admin`select content from public.messages where run_id = ${runId}`;
    expect(JSON.stringify(msgs)).not.toContain(SECRET_VALUE);
  });

  it("refuses to send a secret to a host outside its allowlist", async () => {
    const botId = await makeBot("Leaker", { autonomy: "autonomous" });
    const runId = await startRun(botId, "leak to another host");
    expect((await runAgent(runId, makeDeps(fixtures()).deps)).status).toBe("completed");
    expect((await events(runId)).find((e) => e.type === "tool.failed")?.payload).toMatchObject({
      error_code: "secret_host_not_allowed",
    });
  });

  it("blocks requests to private addresses", async () => {
    const strict = createSafeFetch();
    await expect(strict(`${apiUrl}/echo`)).rejects.toThrow();
    await expect(strict("http://169.254.169.254/latest/meta-data/")).rejects.toThrow(/blocked/);
  });
});

describe("delegation", () => {
  const fixtures: FixtureFile[] = [
    {
      name: "delegation",
      turns: [
        turn({ systemIncludes: "extract lasting memories" }, say('{"memories":[]}'), finish()),
        // Parent spawns a subagent with a tiny budget; the child loops expensive steps until it stops.
        turn(
          { lastRole: "user", lastUserIncludes: "dig deep" },
          call("sa1", "subagent__spawn", { task: "Loop forever on research", budget_usd: 0.01 }),
          finish(),
        ),
        turn(
          { lastUserIncludes: "loop forever on research" },
          call("x", "memory__search", { query: "anything" }),
          finish(50),
        ),
        turn(
          { lastRole: "tool", lastToolName: "subagent.spawn" },
          say("The helper ran out of budget."),
          finish(),
        ),
        // Delegation to a peer bot
        turn(
          { lastRole: "user", lastUserIncludes: "ask the writer" },
          call("d1", "bots__delegate", { bot: "Writer", task: "Write a haiku about teal" }),
          finish(),
        ),
        turn({ lastUserIncludes: "write a haiku about teal" }, say("Teal water at dawn"), finish()),
        turn(
          { lastRole: "tool", lastToolName: "bots.delegate" },
          say("The writer replied."),
          finish(),
        ),
      ],
    },
  ];

  it("a subagent stops at its budget and the parent receives its summary", async () => {
    const botId = await makeBot("Lead");
    const runId = await startRun(botId, "Please dig deep into this");
    expect((await runAgent(runId, makeDeps(fixtures).deps)).status).toBe("completed");
    const evs = await events(runId);
    const started = evs.find((e) => e.type === "subrun.started");
    const done = evs.find((e) => e.type === "subrun.completed");
    expect(done?.payload).toMatchObject({ status: "failed" });
    expect(String(done?.payload.summary)).toContain("budget_exceeded");
    const [child] = await tdb.admin<
      { status: string; parent_run_id: string; budget: { per_run_usd: number } }[]
    >`
      select status, parent_run_id, budget from public.runs where id = ${started?.payload.child_run_id as string}`;
    expect(child).toMatchObject({ status: "failed", parent_run_id: runId });
    expect(child?.budget.per_run_usd).toBe(0.01);
  });

  it("bots.delegate runs a peer bot and returns its answer; cycles are rejected", async () => {
    await makeBot("Writer");
    const botId = await makeBot("Manager");
    const runId = await startRun(botId, "Please ask the writer for a poem");
    expect((await runAgent(runId, makeDeps(fixtures).deps)).status).toBe("completed");
    const done = (await events(runId)).find((e) => e.type === "subrun.completed");
    expect(done?.payload).toMatchObject({ status: "completed", summary: "Teal water at dawn" });
  });
});

describe("integrations", () => {
  async function addIntegration(kind: string, name: string, config: object, secret?: string) {
    const [i] = await tdb.admin<{ id: string }[]>`
      insert into public.integrations (org_id, kind, name, config, vault_secret_id)
      values (${orgId}, ${kind}, ${name}, ${tdb.admin.json(config)}, ${secret ? tdb.admin`vault.create_secret(${secret})` : null})
      returning id`;
    return i!.id;
  }

  it("MCP, OpenAPI, Composio and Pipedream tools appear and run", async () => {
    const spec = {
      openapi: "3.0.0",
      servers: [{ url: apiUrl }],
      paths: {
        "/pets/{petId}": {
          get: {
            operationId: "getPet",
            summary: "Get a pet",
            parameters: [{ name: "petId", in: "path", required: true, schema: { type: "string" } }],
          },
        },
      },
    };
    const ids = [
      await addIntegration("mcp", "calc", { url: `${apiUrl}/mcp` }),
      await addIntegration("openapi", "pets", { spec }),
      await addIntegration(
        "composio",
        "gh",
        { base_url: apiUrl, toolkits: ["github"] },
        "composio-key-123",
      ),
      await addIntegration(
        "pipedream",
        "pd",
        { base_url: apiUrl, project_id: "proj_1", client_id: "cid", apps: ["slack"] },
        "pd-secret-123",
      ),
    ];
    for (const id of ids) {
      const r = await refreshIntegration(h.db, id, { fetch: testFetch, secrets: [] });
      expect(r, JSON.stringify(r)).toMatchObject({ ok: true });
    }
    const botId = await makeBot("Integrator", { autonomy: "autonomous" });
    for (const id of ids)
      await tdb.admin`insert into public.bot_integrations (org_id, bot_id, integration_id) values (${orgId}, ${botId}, ${id})`;

    const fixtures: FixtureFile[] = [
      {
        name: "integrations",
        turns: [
          turn({ systemIncludes: "extract lasting memories" }, say('{"memories":[]}'), finish()),
          turn(
            { lastRole: "user", lastUserIncludes: "use every integration" },
            call("i1", "mcp__calc__add", { a: 2, b: 3 }),
            call("i2", "openapi__pets__getPet", { petId: "7" }),
            call("i3", "composio__gh__github_star_repo", { repo: "casama/casama" }),
            call("i4", "pipedream__pd__slack_send_message", { text: "hello" }),
            finish(),
          ),
          turn({ lastRole: "tool" }, say("All done."), finish()),
        ],
      },
    ];
    const runId = await startRun(botId, "Please use every integration");
    const { deps, gateway } = makeDeps(fixtures);
    expect((await runAgent(runId, deps)).status).toBe("completed");
    const toolNames = gateway.requests[0]?.tools?.map((t) => t.name) ?? [];
    expect(toolNames).toEqual(
      expect.arrayContaining([
        "mcp__calc__add",
        "openapi__pets__getPet",
        "composio__gh__github_star_repo",
        "pipedream__pd__slack_send_message",
      ]),
    );
    const evs = await events(runId);
    const completed = evs
      .filter((e) => e.type === "tool.completed")
      .map((e) => String(e.payload.result_preview));
    expect(evs.filter((e) => e.type === "tool.failed")).toEqual([]);
    expect(completed[0]).toBe("5");
    expect(completed[1]).toContain("Rex");
    expect(completed[2]).toContain("casama/casama");
    expect(completed[3]).toContain("hello");
    // Tool results reach the model wrapped as untrusted content.
    const last = gateway.requests.at(-1)?.messages.filter((m) => m.role === "tool") ?? [];
    expect(last.every((m) => m.content.includes("<untrusted"))).toBe(true);
    expect(
      received.find((r) => r.url === "/api/v3/tools/execute/GITHUB_STAR_REPO")?.headers[
        "x-api-key"
      ],
    ).toBe("composio-key-123");
  });
});

describe("search and notifications", () => {
  it("web.search returns results and notify.user pushes to the owner's devices", async () => {
    const botId = await makeBot("Notifier", { autonomy: "autonomous" });
    const fixtures: FixtureFile[] = [
      {
        name: "notify",
        turns: [
          turn({ systemIncludes: "extract lasting memories" }, say('{"memories":[]}'), finish()),
          turn(
            { lastRole: "user", lastUserIncludes: "search and tell me" },
            call("w1", "web__search", { query: "casama" }),
            finish(),
          ),
          turn(
            { lastRole: "tool", lastToolName: "web.search" },
            call("n1", "notify__user", { title: "Found it", message: "Casama result one" }),
            finish(),
          ),
          turn({ lastRole: "tool", lastToolName: "notify.user" }, say("Sent."), finish()),
        ],
      },
    ];
    const before = push.sent.length;
    const runId = await startRun(botId, "search and tell me");
    expect((await runAgent(runId, makeDeps(fixtures).deps)).status).toBe("completed");
    expect(
      (await events(runId)).find((e) => e.type === "tool.completed")?.payload.result_preview,
    ).toBe("1 results");
    const sent = push.sent.slice(before).find((p) => p.message.title === "Found it");
    expect(sent?.tokens).toEqual(["device-token-1"]);
    const [n] = await tdb.admin<
      { kind: string }[]
    >`select kind from public.notifications where user_id = ${userId} and payload ->> 'title' = 'Found it'`;
    expect(n?.kind).toBe("bot_message");
  });
});
