/**
 * A more capable bot (D-269): files.edit, pictures in tool results, read-only calls run together,
 * and memory that learns from the work and corrects what it knew.
 */
import { createDb, type DbHandle } from "@casama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { z } from "zod";
import { keepNewestImages } from "../src/context.ts";
import { toModelMessages } from "../src/gateway/ai-sdk.ts";
import type { ChatMessage, GatewayEvent, ModelGateway } from "../src/gateway/types.ts";
import {
  builtinTools,
  CredentialResolver,
  directSteps,
  type FixtureFile,
  hashEmbedder,
  PostgresMemoryStore,
  ReplayGateway,
  runAgent,
} from "../src/index.ts";
import { memoryTranscript, parseExtraction } from "../src/memory.ts";
import { registerComputerTools } from "../src/tools/computer.ts";
import { type ToolContext, ToolRegistry } from "../src/tools/registry.ts";

let tdb: TestDatabase;
let h: DbHandle;
let orgId: string;
let userId: string;
let credId: string;

beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 5 });
  userId = (await createAuthUser(tdb.admin, "abilities@example.com")).id;
  const [org] = await tdb.admin<
    { id: string }[]
  >`insert into public.organizations (name, slug) values ('Abilities Org', 'abilities-org') returning id`;
  orgId = org!.id;
  await tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${userId}, 'owner')`;
  const [cred] = await tdb.admin<{ id: string }[]>`
    insert into public.model_credentials (org_id, provider, label, vault_secret_id)
    values (${orgId}, 'openrouter', 'Main', vault.create_secret('sk-live-SECRET-1234567890')) returning id`;
  credId = cred!.id;
});
afterAll(async () => {
  await h?.close();
  await tdb?.stop();
});

async function makeBot() {
  const policy = { primary: { credential_id: credId, model: "fixture-primary" } };
  const [bot] = await tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name, model_policy, budget)
    values (${orgId}, ${userId}, 'Ada', ${tdb.admin.json(policy)}, ${tdb.admin.json({ per_run_usd: 50, daily_usd: 500 })})
    returning id`;
  return bot!.id;
}
async function startRun(botId: string, text: string) {
  const [convo] = await tdb.admin<
    { id: string }[]
  >`insert into public.conversations (org_id, bot_id) values (${orgId}, ${botId}) returning id`;
  const [run] = await tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, created_by) values (${orgId}, ${botId}, ${convo!.id}, ${userId}) returning id`;
  await tdb.admin`
    insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
    values (${orgId}, ${convo!.id}, 'user', ${userId}, ${tdb.admin.json([{ type: "text", text }])}, ${run!.id})`;
  return run!.id;
}
const finish = () => ({
  type: "finish" as const,
  usage: { inputTokens: 100, outputTokens: 10 },
  finishReason: "stop",
  model: "",
});
const embedder = hashEmbedder();
function deps(gateway: ModelGateway, register?: (r: ToolRegistry) => void) {
  const tools = builtinTools({
    db: h.db,
    memory: async () => new PostgresMemoryStore(h.db, embedder),
  });
  register?.(tools);
  return {
    db: h.db,
    gateway,
    tools,
    credentials: new CredentialResolver(h.db),
    embedderFor: async () => embedder,
    step: directSteps,
    deltaIntervalMs: 20,
    cancelPollMs: 50,
    fallback: { backoffMs: 1, sleep: async () => {} },
  };
}

/** A computer with only a file system, enough for the file tools. */
function fakeComputer(files: Map<string, Uint8Array>): ToolContext {
  const handle = {
    readFile: async (p: string) => {
      const f = files.get(p);
      if (!f) throw new Error(`no such file: ${p}`);
      return f;
    },
    writeFile: async (p: string, b: Uint8Array) => void files.set(p, b),
  };
  return {
    runId: "r",
    botId: "b",
    orgId: "o",
    output: async () => {},
    emit: async () => {},
    computer: async () => handle as never,
  };
}

describe("files.edit", () => {
  const registry = new ToolRegistry();
  registerComputerTools(registry);
  const edit = (ctx: ToolContext, args: Record<string, unknown>) => {
    const { def, args: parsed } = registry.parse("files.edit", args);
    return def.execute(parsed as never, ctx);
  };
  const enc = (t: string) => new TextEncoder().encode(t);
  const dec = (b?: Uint8Array) => new TextDecoder().decode(b);

  it("replaces one exact match and leaves the rest of the file alone", async () => {
    const files = new Map([["notes.md", enc("# Plan\nship on Friday\nthen rest\n")]]);
    const r = await edit(fakeComputer(files), {
      path: "notes.md",
      old_text: "ship on Friday",
      new_text: "ship on Monday",
    });
    expect(r.content).toContain("Replaced 1 place");
    expect(dec(files.get("notes.md"))).toBe("# Plan\nship on Monday\nthen rest\n");
  });
  it("refuses text that isn't there or isn't unique, unless replace_all", async () => {
    const files = new Map([["a.txt", enc("x = 1\nx = 1\n")]]);
    const ctx = fakeComputer(files);
    await expect(edit(ctx, { path: "a.txt", old_text: "y", new_text: "z" })).rejects.toThrow(
      "isn't in a.txt",
    );
    await expect(
      edit(ctx, { path: "a.txt", old_text: "x = 1", new_text: "x = 2" }),
    ).rejects.toThrow("appears 2 times");
    await edit(ctx, { path: "a.txt", old_text: "x = 1", new_text: "x = 2", replace_all: true });
    expect(dec(files.get("a.txt"))).toBe("x = 2\nx = 2\n");
  });
  it("keeps $ signs in the new text as written", async () => {
    const files = new Map([["p.txt", enc("price: TBD")]]);
    await edit(fakeComputer(files), { path: "p.txt", old_text: "TBD", new_text: "$& $1 $$" });
    expect(dec(files.get("p.txt"))).toBe("price: $& $1 $$");
  });
});

describe("pictures in tool results", () => {
  it("files.read attaches an image instead of refusing it as binary", async () => {
    const registry = new ToolRegistry();
    registerComputerTools(registry);
    const png = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0, 1, 2, 3]);
    const { def, args } = registry.parse("files.read", { path: "shot.png" });
    const r = await def.execute(args as never, fakeComputer(new Map([["shot.png", png]])));
    expect(r.image).toEqual({ data: Buffer.from(png).toString("base64"), mediaType: "image/png" });
  });

  it("are sent to the model as image parts of the tool result", () => {
    const [m] = toModelMessages([
      {
        role: "tool",
        callId: "c1",
        name: "browser.screenshot",
        content: "Saved screenshot.",
        images: [{ data: "aGk=", mediaType: "image/png" }],
      },
    ]);
    expect(m).toMatchObject({
      role: "tool",
      content: [
        {
          type: "tool-result",
          output: {
            type: "content",
            value: [
              { type: "text", text: "Saved screenshot." },
              { type: "file", data: { type: "data", data: "aGk=" }, mediaType: "image/png" },
            ],
          },
        },
      ],
    });
  });

  it("only the newest two stay in a run", () => {
    const shot = (n: number): ChatMessage => ({
      role: "tool",
      callId: `s${n}`,
      name: "browser.screenshot",
      content: `shot ${n}`,
      images: [{ data: "aGk=", mediaType: "image/png" }],
    });
    const turn = [shot(1), shot(2), shot(3)];
    keepNewestImages(turn);
    expect(turn.map((m) => (m.role === "tool" ? (m.images?.length ?? 0) : 0))).toEqual([0, 1, 1]);
    expect(turn[0]?.content).toContain("removed to save space");
  });
});

describe("read-only calls run together", () => {
  it("two reads in one step run at the same time, and a write waits for them", async () => {
    const log: string[] = [];
    const register = (r: ToolRegistry) => {
      for (const name of ["probe.read_a", "probe.read_b"])
        r.register({
          name,
          description: "Reads.",
          risk: "low",
          readOnly: true,
          schema: z.object({}),
          async execute() {
            log.push(`${name} start`);
            await new Promise((res) => setTimeout(res, 80));
            log.push(`${name} end`);
            return { content: `${name} done` };
          },
        });
      r.register({
        name: "probe.write",
        description: "Writes.",
        risk: "low",
        schema: z.object({}),
        async execute() {
          log.push("probe.write");
          return { content: "written" };
        },
      });
    };
    const fixtures: FixtureFile[] = [
      {
        name: "parallel",
        turns: [
          {
            when: { systemIncludes: "extract lasting memories" },
            events: [{ type: "text", text: '{"memories":[]}' }, finish()],
          },
          {
            when: { lastRole: "user", lastUserIncludes: "read both then write" },
            events: [
              { type: "tool_call", call: { callId: "a", name: "probe__read_a", args: {} } },
              { type: "tool_call", call: { callId: "b", name: "probe__read_b", args: {} } },
              { type: "tool_call", call: { callId: "w", name: "probe__write", args: {} } },
              finish(),
            ],
          },
          { when: { lastRole: "tool" }, events: [{ type: "text", text: "All done." }, finish()] },
        ],
      },
    ];
    const gateway = new ReplayGateway(fixtures);
    const runId = await startRun(await makeBot(), "Read both then write");
    expect((await runAgent(runId, deps(gateway, register))).status).toBe("completed");
    expect(log.slice(0, 2).sort()).toEqual(["probe.read_a start", "probe.read_b start"]);
    expect(log.at(-1)).toBe("probe.write");
    // Results come back in the order the model asked for them.
    const results = gateway.requests
      .filter((r) => r.messages.some((m) => m.role === "tool"))
      .at(-1)
      ?.messages.filter((m) => m.role === "tool")
      .map((m) => m.content);
    expect(results).toEqual(["probe.read_a done", "probe.read_b done", "written"]);
  });
});

describe("memory learns from the work (D-269)", () => {
  it("the memory model sees a digest of the steps, marked as outside content", () => {
    const text = memoryTranscript([
      { role: "user", content: "Find Acme's office address" },
      {
        role: "assistant",
        content: "",
        toolCalls: [{ callId: "1", name: "web.search", args: { q: "Acme office" } }],
      },
      {
        role: "tool",
        callId: "1",
        name: "web.search",
        content: "Acme Corp, 12 Harbor Road, Duluth",
      },
      { role: "assistant", content: "It's at 12 Harbor Road." },
    ]);
    expect(text).toContain("USER: Find Acme's office address");
    expect(text).toContain("WHAT THE TEAMMATE DID (outside content");
    expect(text).toContain("web.search: Acme Corp, 12 Harbor Road");
    expect(text.indexOf("WHAT THE TEAMMATE DID")).toBeLessThan(text.indexOf("ASSISTANT:"));
  });

  it("parses which known memory a new one replaces", () => {
    expect(
      parseExtraction('{"memories":[{"kind":"fact","content":"Lives in Austin","replaces":2}]}')[0],
    ).toMatchObject({ content: "Lives in Austin", replaces: 2 });
    expect(
      parseExtraction('{"memories":[{"kind":"fact","content":"x","replaces":"no"}]}')[0]?.replaces,
    ).toBeUndefined();
  });

  it("a correction updates the old memory instead of adding a second one", async () => {
    const botId = await makeBot();
    const store = new PostgresMemoryStore(h.db, embedder);
    const old = await store.write({
      orgId,
      botId,
      kind: "fact",
      content: "The client's office is in Duluth.",
    });
    const gateway: ModelGateway = {
      async *stream(req): AsyncIterable<GatewayEvent> {
        const sys = req.system.join("\n");
        if (sys.includes("extract lasting memories")) {
          expect(sys).toContain("1. The client's office is in Duluth.");
          yield {
            type: "text",
            text: '{"memories":[{"kind":"fact","about":"work","content":"The client\'s office moved to Austin.","replaces":1}]}',
          };
        } else yield { type: "text", text: "Noted, Austin it is." };
        yield { ...finish(), model: req.model.model };
      },
    };
    const runId = await startRun(botId, "The client's office moved to Austin");
    expect((await runAgent(runId, deps(gateway))).status).toBe("completed");
    const rows = await tdb.admin<{ id: string; content: string }[]>`
      select id, content from public.memories where bot_id = ${botId}`;
    expect(rows).toEqual([{ id: old.id, content: "The client's office moved to Austin." }]);
  });
});

describe("a check before done (D-269)", () => {
  it("a long run's reply that claims more than its steps show goes back once to be fixed", async () => {
    const register = (r: ToolRegistry) =>
      r.register({
        name: "probe.step",
        description: "One step of work.",
        risk: "low",
        schema: z.object({ n: z.number() }),
        async execute(args) {
          return { content: args.n === 4 ? "Error: upload failed" : `step ${args.n} ok` };
        },
      });
    let checks = 0;
    const gateway: ModelGateway = {
      async *stream(req): AsyncIterable<GatewayEvent> {
        const sys = req.system.join("\n");
        const last = req.messages.at(-1);
        if (sys.includes("extract lasting memories"))
          yield { type: "text", text: '{"memories":[]}' };
        else if (sys.includes("check an AI teammate's final reply")) {
          checks++;
          expect(last?.content).toContain("probe.step: Error: upload failed");
          yield {
            type: "text",
            text:
              checks === 1
                ? '{"ok":false,"issue":"The upload in step 4 failed, but the reply says it worked."}'
                : '{"ok":true}',
          };
        } else if (last?.role === "user" && last.content.includes("Casama check before")) {
          yield {
            type: "text",
            text: "Steps 1 to 3 worked; the upload failed, so nothing is online yet.",
          };
        } else {
          const done = req.messages.filter((m) => m.role === "tool").length;
          if (done < 4)
            yield {
              type: "tool_call",
              call: { callId: `s${done + 1}`, name: "probe__step", args: { n: done + 1 } },
            };
          else yield { type: "text", text: "All done, everything is uploaded." };
        }
        yield { ...finish(), model: req.model.model };
      },
    };
    const runId = await startRun(await makeBot(), "Build and upload the site");
    expect((await runAgent(runId, deps(gateway, register))).status).toBe("completed");
    expect(checks).toBe(1);
    const replies = await tdb.admin<{ content: Array<{ text?: string }> }[]>`
      select content from public.messages where run_id = ${runId} and role = 'assistant' order by created_at`;
    expect(replies.map((m) => m.content[0]?.text)).toEqual([
      "Steps 1 to 3 worked; the upload failed, so nothing is online yet.",
    ]);
  });
});
