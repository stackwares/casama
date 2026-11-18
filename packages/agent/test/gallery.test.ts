/** Gallery tools (D-315): search, suggestion cards, skill drafts and the repeated-request hint. */
import { createDb, type DbHandle } from "@casama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import {
  builtinTools,
  CredentialResolver,
  directSteps,
  type FixtureFile,
  type GalleryCatalog,
  type GalleryEntry,
  hashEmbedder,
  PostgresMemoryStore,
  ReplayGateway,
  registerGalleryTools,
  repeatedRequestHint,
  runAgent,
  searchGallery,
  skillIdFor,
} from "../src/index.ts";

const ITEMS: GalleryEntry[] = [
  {
    type: "skill",
    id: "inbox-digest",
    name: "Inbox digest",
    description: "Summarize unread email into a short list of what needs a reply.",
    icon: "mail",
    tags: ["email"],
    access: { reads: ["email"] },
  },
  {
    type: "routine",
    id: "morning-email",
    name: "Morning email summary",
    description: "Every weekday at 8: a summary of unread email.",
    tags: ["email", "morning"],
    needs: { apps: ["gmail"] },
  },
  {
    type: "theme",
    id: "forest-night",
    name: "Forest night",
    description: "A dark green look.",
    tags: ["dark", "green"],
  },
  { type: "skill", id: "old-digest", name: "Old email digest", retired: true },
  { type: "skill", id: "blocked-mail", name: "Blocked mail summary", blocked: true },
  {
    type: "app",
    id: "cal-com",
    name: "Cal.com",
    description: "Book meetings.",
    tags: ["calendar"],
  },
];

describe("searchGallery", () => {
  it("ranks names over descriptions and uses synonyms", () => {
    const hits = searchGallery(ITEMS, "summarize my unread mail");
    expect(hits.map((h) => h.id).slice(0, 2)).toEqual(["inbox-digest", "morning-email"]);
  });

  it("never returns retired or blocked items", () => {
    const ids = searchGallery(ITEMS, "email digest summary").map((h) => h.id);
    expect(ids).not.toContain("old-digest");
    expect(ids).not.toContain("blocked-mail");
  });

  it("filters by kind and finds looks", () => {
    expect(searchGallery(ITEMS, "dark green", { types: ["theme"] }).map((h) => h.id)).toEqual([
      "forest-night",
    ]);
    expect(searchGallery(ITEMS, "email", { types: ["routine"] }).map((h) => h.id)).toEqual([
      "morning-email",
    ]);
    expect(searchGallery(ITEMS, "cal").map((h) => h.id)).toContain("cal-com");
  });

  it("returns at most five", () => {
    const many = Array.from({ length: 9 }, (_, i) => ({
      type: "skill" as const,
      id: `notes-${i}`,
      name: `Notes ${i}`,
    }));
    expect(searchGallery(many, "notes")).toHaveLength(5);
  });
});

describe("repeatedRequestHint", () => {
  const at = (d: string) => new Date(`${d}T09:00:00Z`);
  const ask = "Summarize my unread email from today";
  it("hints after the same kind of request on three different days", () => {
    const hint = repeatedRequestHint({ text: ask, at: at("2026-11-16") }, [
      { text: "summarize unread email please", at: at("2026-11-15") },
      { text: "Can you summarize my unread email?", at: at("2026-11-13") },
    ]);
    expect(hint).toMatch(/3 different days/);
    expect(hint).toMatch(/gallery\.search/);
  });

  it("stays quiet for two days, same-day repeats or unrelated asks", () => {
    expect(
      repeatedRequestHint({ text: ask, at: at("2026-11-16") }, [
        { text: "summarize unread email", at: at("2026-11-15") },
        { text: "summarize unread email again", at: at("2026-11-15") },
        { text: "summarize unread email", at: at("2026-11-16") },
      ]),
    ).toBeNull();
    expect(
      repeatedRequestHint({ text: ask, at: at("2026-11-16") }, [
        { text: "book a table for two", at: at("2026-11-15") },
        { text: "what's the weather", at: at("2026-11-14") },
      ]),
    ).toBeNull();
    expect(repeatedRequestHint({ text: "thanks", at: at("2026-11-16") }, [])).toBeNull();
  });
});

describe("skillIdFor", () => {
  it("makes a SKILL.md name", () => {
    expect(skillIdFor("Weekly Report!")).toBe("weekly-report");
    expect(skillIdFor("  Café   notes_v2 ")).toBe("cafe-notes-v2");
  });
});

// ---------------------------------------------------------------- in a run

let tdb: TestDatabase;
let h: DbHandle;
let orgId: string;
let userId: string;
let botId: string;

const fin = {
  type: "finish" as const,
  usage: { inputTokens: 10, outputTokens: 5 },
  finishReason: "stop",
  model: "",
};
const callTool = (id: string, name: string, args: Record<string, unknown>) => ({
  type: "tool_call" as const,
  call: { callId: id, name, args },
});

const fixtures: FixtureFile[] = [
  {
    name: "gallery",
    turns: [
      {
        when: { systemIncludes: "extract lasting memories" },
        events: [{ type: "text", text: '{"memories":[]}' }, fin],
      },
      {
        when: { lastRole: "user", lastUserIncludes: "different days" },
        events: [{ type: "text", text: "HINT_SEEN" }, fin],
      },
      {
        when: { lastRole: "user", lastUserIncludes: "find an email skill" },
        events: [
          callTool("s1", "gallery__search", { query: "summarize unread email" }),
          { ...fin, finishReason: "tool-calls" },
        ],
      },
      {
        when: { lastRole: "tool", lastToolName: "gallery.search" },
        events: [
          callTool("s2", "gallery__suggest", {
            type: "skill",
            id: "inbox-digest",
            reason: "It sums up your unread email.",
          }),
          callTool("s3", "gallery__suggest", {
            type: "routine",
            id: "morning-email",
            reason: "Every morning, without asking.",
          }),
          { ...fin, finishReason: "tool-calls" },
        ],
      },
      {
        when: { lastRole: "user", lastUserIncludes: "suggest it again" },
        events: [
          callTool("s4", "gallery__suggest", {
            type: "skill",
            id: "inbox-digest",
            reason: "Again.",
          }),
          { ...fin, finishReason: "tool-calls" },
        ],
      },
      {
        when: { lastRole: "user", lastUserIncludes: "make this a skill" },
        events: [
          callTool("d1", "gallery__draft_skill", {
            name: "Weekly report",
            description: "Write the weekly status report from this week's tasks.",
            instructions_md: "1. List what shipped.\n2. List what's blocked.\n3. Keep it short.",
          }),
          { ...fin, finishReason: "tool-calls" },
        ],
      },
      { when: { lastRole: "tool" }, events: [{ type: "text", text: "Done." }, fin] },
    ],
  },
];

const catalog: GalleryCatalog = { items: async () => ITEMS };

function registry() {
  const t = builtinTools({
    db: h.db,
    memory: async () => new PostgresMemoryStore(h.db, hashEmbedder()),
  });
  registerGalleryTools(t, { db: h.db, gallery: catalog });
  return t;
}

async function newConversation() {
  const [conv] = await tdb.admin<
    { id: string }[]
  >`insert into public.conversations (org_id, bot_id) values (${orgId}, ${botId}) returning id`;
  return conv!.id;
}

async function chat(conv: string, text: string, at?: string) {
  const [run] = await tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, created_by) values (${orgId}, ${botId}, ${conv}, ${userId}) returning id`;
  await tdb.admin`insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id, created_at)
    values (${orgId}, ${conv}, 'user', ${userId}, ${tdb.admin.json([{ type: "text", text }])}, ${run!.id}, ${at ?? new Date().toISOString()})`;
  return run!.id;
}

const deps = () => ({
  db: h.db,
  gateway: new ReplayGateway(fixtures),
  tools: registry(),
  credentials: new CredentialResolver(h.db),
  embedderFor: async () => hashEmbedder(),
  step: directSteps,
  deltaIntervalMs: 20,
  cancelPollMs: 50,
  fallback: { backoffMs: 1 },
  waitForApproval: async () => {},
});

async function reply(runId: string) {
  const [m] = await tdb.admin<{ content: Array<Record<string, unknown>> }[]>`
    select content from public.messages where run_id = ${runId} and role = 'assistant' order by created_at desc limit 1`;
  return m?.content ?? [];
}

async function failures(runId: string) {
  return tdb.admin<{ payload: { error_code: string } }[]>`
    select payload from public.run_events where run_id = ${runId} and type = 'tool.failed' order by seq`;
}

beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 5 });
  userId = (await createAuthUser(tdb.admin, "gallery@example.com")).id;
  const [org] = await tdb.admin<
    { id: string }[]
  >`insert into public.organizations (name, slug) values ('Gallery', 'gallery') returning id`;
  orgId = org!.id;
  await tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${userId}, 'owner')`;
  const [cred] = await tdb.admin<{ id: string }[]>`
    insert into public.model_credentials (org_id, provider, label, vault_secret_id) values (${orgId}, 'openrouter', 'k', vault.create_secret('sk-test-123456')) returning id`;
  const [bot] = await tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name, autonomy, model_policy) values (${orgId}, ${userId}, 'Finder', 'ask_risky',
      ${tdb.admin.json({ primary: { credential_id: cred!.id, model: "m" } })}) returning id`;
  botId = bot!.id;
});
afterAll(async () => {
  await h?.close();
  await tdb?.stop();
});

describe("gallery tools in a run", () => {
  it("search, then one suggestion card per reply, saved with the reply", async () => {
    const conv = await newConversation();
    const runId = await chat(conv, "Please find an email skill");
    await runAgent(runId, deps());
    const search = await tdb.admin<{ payload: { result_preview: string } }[]>`
      select payload from public.run_events where run_id = ${runId} and type = 'tool.completed' order by seq limit 1`;
    expect(search[0]?.payload.result_preview).toMatch(/match/);
    const parts = (await reply(runId)).filter((p) => p.type === "gallery_suggestion");
    expect(parts).toEqual([
      {
        type: "gallery_suggestion",
        item: {
          type: "skill",
          id: "inbox-digest",
          name: "Inbox digest",
          description: "Summarize unread email into a short list of what needs a reply.",
          icon: "mail",
          access: { reads: ["email"] },
        },
        reason: "It sums up your unread email.",
      },
    ]);
    expect((await failures(runId)).map((f) => f.payload.error_code)).toEqual([
      "one_suggestion_per_reply",
    ]);

    // Never the same item twice in a conversation.
    const again = await chat(conv, "suggest it again");
    await runAgent(again, deps());
    expect((await failures(again)).map((f) => f.payload.error_code)).toEqual(["already_suggested"]);
    expect((await reply(again)).some((p) => p.type === "gallery_suggestion")).toBe(false);
  });

  it("a new conversation may suggest it again; an installed skill isn't offered", async () => {
    const conv = await newConversation();
    const runId = await chat(conv, "suggest it again");
    await runAgent(runId, deps());
    expect((await reply(runId)).some((p) => p.type === "gallery_suggestion")).toBe(true);

    await tdb.admin`insert into public.skills (org_id, name, description, body_md, source, source_ref)
      values (${orgId}, 'inbox-digest', 'd', 'b', 'gallery', ${tdb.admin.json({ id: "inbox-digest" })})`;
    const other = await chat(await newConversation(), "suggest it again");
    await runAgent(other, deps());
    expect((await reply(other)).some((p) => p.type === "gallery_suggestion")).toBe(false);
    await tdb.admin`delete from public.skills where org_id = ${orgId} and name = 'inbox-digest'`;
  });

  it("draft_skill adds a gallery_draft card with a valid SKILL.md", async () => {
    const runId = await chat(await newConversation(), "make this a skill");
    await runAgent(runId, deps());
    const [draft] = (await reply(runId)).filter((p) => p.type === "gallery_draft");
    expect(draft).toMatchObject({
      type: "gallery_draft",
      draft: {
        type: "skill",
        id: "weekly-report",
        item: { name: "Weekly report", license: "Apache-2.0", version: 1 },
      },
    });
    const md = (draft as { draft: { files: Record<string, string> } }).draft.files["SKILL.md"];
    expect(md).toMatch(/^---\nname: weekly-report\ndescription: Write the weekly/);
    expect(md).toContain("# Weekly report");
  });

  it("a request repeated on three days adds the routine hint", async () => {
    const conv = await newConversation();
    const day = (n: number) => new Date(Date.now() - n * 86_400_000).toISOString();
    await chat(conv, "summarize my unread email", day(3));
    await chat(conv, "please summarize unread email", day(1));
    const runId = await chat(conv, "Summarize my unread email from today");
    await runAgent(runId, deps());
    expect((await reply(runId))[0]).toMatchObject({ type: "text", text: "HINT_SEEN" });
  });
});
