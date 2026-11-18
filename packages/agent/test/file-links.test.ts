import { createDb, type DbHandle } from "@casama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@casama/db/testing";
import type { FileEntry, SandboxHandle } from "@casama/sandbox";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import type { ComputerService } from "../src/computers.ts";
import { computerPathFromLink, linkedFilePaths, missingLinkedFiles } from "../src/file-links.ts";
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

// A computer whose files are a fixed set of absolute-ish paths relative to ~/workspace.
function fakeComputers(files: string[], opts: { kind?: string; failStart?: boolean } = {}) {
  const listed: string[] = [];
  const handle = {
    listDir: async (dir: string): Promise<FileEntry[]> => {
      listed.push(dir);
      const prefix = dir ? `${dir.replace(/\/$/, "")}/` : "";
      const names = files
        .filter((f) => f.startsWith(prefix) && !f.slice(prefix.length).includes("/"))
        .map((f) => f.slice(prefix.length));
      if (dir && names.length === 0 && !files.some((f) => f.startsWith(prefix)))
        throw Object.assign(new Error(`No such file: ${dir}`), { code: "not_found" });
      return names.map((name) => ({
        name,
        path: prefix + name,
        type: "file",
        size: 1,
        modified: "",
      }));
    },
  } as unknown as SandboxHandle;
  const computers = {
    forBot: async () => ({
      id: "c1",
      org_id: "o1",
      kind: opts.kind ?? "team",
      profile: "headless",
    }),
    ensureRunning: async () => {
      if (opts.failStart) throw new Error("device_offline");
      return handle;
    },
    touch: async () => {},
  } as unknown as ComputerService;
  return { computers, listed };
}

const run = { runId: "r1", botId: "b1", botName: "Ada" };

describe("file links in replies (D-231)", () => {
  it("reads links the way the app opens them", () => {
    expect(computerPathFromLink("workspace/bots/casama/index.html")).toBe("bots/casama/index.html");
    expect(computerPathFromLink("~/workspace/a.md")).toBe("a.md");
    expect(computerPathFromLink("~/Downloads/a.md")).toBe("~/Downloads/a.md");
    expect(computerPathFromLink("/home/casama/workspace/a.md")).toBe("a.md");
    expect(computerPathFromLink("/Users/me/Desktop/x.mp4")).toBe("/Users/me/Desktop/x.mp4");
    expect(computerPathFromLink("notes.md")).toBe("notes.md");
    expect(computerPathFromLink("https://example.com/a.html")).toBeNull();
    expect(computerPathFromLink("media:workspace/a.png")).toBeNull();
    expect(computerPathFromLink("#top")).toBeNull();
    expect(computerPathFromLink("hello")).toBeNull();
  });

  it("finds Markdown links and images, not code or web links", () => {
    const text = [
      "Open [index.html](workspace/bots/casama/index.html) or ![pic](shared/a.png).",
      "See [the docs](https://casama.ai/docs) and `[x](y.md)`.",
      "```\n[z](z.md)\n```",
      "Again [index.html](workspace/bots/casama/index.html).",
    ].join("\n");
    expect(linkedFilePaths(text)).toEqual(["bots/casama/index.html", "shared/a.png"]);
  });

  it("reports linked files that aren't on the computer", async () => {
    const { computers } = fakeComputers(["bots/casama/real.html"]);
    const text =
      "[real](workspace/bots/casama/real.html) and [fake](workspace/bots/casama/index.html)";
    expect(await missingLinkedFiles(computers, run, text)).toEqual(["bots/casama/index.html"]);
  });

  it("treats a missing folder as a missing file", async () => {
    const { computers } = fakeComputers([]);
    expect(await missingLinkedFiles(computers, run, "[x](nowhere/x.html)")).toEqual([
      "nowhere/x.html",
    ]);
  });

  it("fails open when the computer can't be reached or the reply has no file links", async () => {
    const offline = fakeComputers([], { failStart: true });
    expect(await missingLinkedFiles(offline.computers, run, "[x](x.html)")).toEqual([]);
    const plain = fakeComputers([]);
    expect(await missingLinkedFiles(plain.computers, run, "No links here.")).toEqual([]);
    expect(plain.listed).toEqual([]);
    expect(await missingLinkedFiles(undefined, run, "[x](x.html)")).toEqual([]);
  });

  it("doesn't look at someone else's personal computer", async () => {
    const { computers, listed } = fakeComputers([], { kind: "local" });
    const other = { ...run, actingUserId: "u2", localOwner: async () => "u1" };
    expect(await missingLinkedFiles(computers, other, "[x](x.html)")).toEqual([]);
    expect(listed).toEqual([]);
  });
});

describe("a reply that links to a file it never made (D-231)", () => {
  let tdb: TestDatabase;
  let h: DbHandle;
  let orgId: string;
  let userId: string;
  let botId: string;

  beforeAll(async () => {
    tdb = await startTestDatabase();
    h = createDb(tdb.url, { max: 5 });
    userId = (await createAuthUser(tdb.admin, "links@example.com")).id;
    const [org] = await tdb.admin<
      { id: string }[]
    >`insert into public.organizations (name, slug) values ('Links', 'links') returning id`;
    orgId = org!.id;
    await tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${userId}, 'owner')`;
    const [cred] = await tdb.admin<{ id: string }[]>`
      insert into public.model_credentials (org_id, provider, label, vault_secret_id)
      values (${orgId}, 'openrouter', 'Main', vault.create_secret('sk-test')) returning id`;
    const policy = {
      primary: { credential_id: cred!.id, model: "fixture-primary" },
      cheap: { credential_id: cred!.id, model: "fixture-cheap" },
    };
    const [bot] = await tdb.admin<{ id: string }[]>`
      insert into public.bots (org_id, created_by, name, persona_md, model_policy, budget)
      values (${orgId}, ${userId}, 'Ada', 'Brief.', ${tdb.admin.json(policy)},
              ${tdb.admin.json({ per_run_usd: 5, daily_usd: 50 })}) returning id`;
    botId = bot!.id;
  });
  afterAll(async () => {
    await h?.close();
    await tdb?.stop();
  });

  async function startRun(text: string) {
    const [convo] = await tdb.admin<
      { id: string }[]
    >`insert into public.conversations (org_id, bot_id) values (${orgId}, ${botId}) returning id`;
    const [r] = await tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, conversation_id, created_by)
      values (${orgId}, ${botId}, ${convo!.id}, ${userId}) returning id`;
    await tdb.admin`
      insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
      values (${orgId}, ${convo!.id}, 'user', ${userId}, ${tdb.admin.json([{ type: "text", text }])}, ${r!.id})`;
    return r!.id;
  }

  const finish = {
    type: "finish" as const,
    usage: { inputTokens: 10, outputTokens: 10 },
    finishReason: "stop",
    model: "",
  };
  const fixtures: FixtureFile[] = [
    {
      name: "file-links",
      turns: [
        {
          when: { systemIncludes: "extract lasting memories" },
          events: [{ type: "text", text: '{"memories":[]}' }, finish],
        },
        {
          when: { lastRole: "user", lastUserIncludes: "the link won't open" },
          events: [
            {
              type: "text",
              text: "Sorry, I didn't make the website yet. Want me to build it now?",
            },
            finish,
          ],
        },
        {
          when: { lastRole: "user", lastUserIncludes: "make me a website" },
          events: [
            {
              type: "text",
              text: "Done! Open it here: [index.html](workspace/bots/ada/index.html)",
            },
            finish,
          ],
        },
        {
          when: { lastRole: "user", lastUserIncludes: "my real page" },
          events: [
            { type: "text", text: "Here it is: [page.html](workspace/bots/ada/page.html)" },
            finish,
          ],
        },
      ],
    },
  ];

  const deps = (computers: ComputerService) => {
    const embedder = hashEmbedder();
    return {
      db: h.db,
      gateway: new ReplayGateway(fixtures),
      tools: builtinTools({
        db: h.db,
        memory: async () => new PostgresMemoryStore(h.db, embedder),
      }),
      credentials: new CredentialResolver(h.db),
      embedderFor: async () => embedder,
      step: directSteps,
      deltaIntervalMs: 20,
      cancelPollMs: 50,
      fallback: { backoffMs: 1 },
      computers,
    };
  };

  const events = (runId: string) =>
    tdb.admin<{ type: string; payload: Record<string, unknown> }[]>`
      select type, payload from public.run_events where run_id = ${runId} order by seq`;

  it("takes the draft back and has the bot say plainly what it did", async () => {
    const runId = await startRun("Please make me a website with the video");
    const { computers } = fakeComputers(["bots/ada/other.txt"]);
    expect((await runAgent(runId, deps(computers))).status).toBe("completed");
    const done = (await events(runId)).filter((e) => e.type === "message.completed");
    // The draft is retracted with an empty message, then the honest reply is the one kept.
    expect(done).toHaveLength(2);
    expect(done[0]!.payload.content).toEqual([]);
    expect(JSON.stringify(done[1]!.payload.content)).toContain("didn't make the website");
    const [saved] = await tdb.admin<{ content: unknown }[]>`
      select content from public.messages where run_id = ${runId} and role = 'assistant'`;
    expect(JSON.stringify(saved?.content)).toContain("didn't make the website");
    expect(JSON.stringify(saved?.content)).not.toContain("index.html");
  });

  it("keeps a reply whose linked file exists", async () => {
    const runId = await startRun("Show me my real page");
    const { computers, listed } = fakeComputers(["bots/ada/page.html"]);
    expect((await runAgent(runId, deps(computers))).status).toBe("completed");
    const done = (await events(runId)).filter((e) => e.type === "message.completed");
    expect(done).toHaveLength(1);
    expect(JSON.stringify(done[0]!.payload.content)).toContain("page.html");
    expect(listed).toEqual(["bots/ada"]);
  });
});
