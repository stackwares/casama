/** Spoken audio (D-284): made from text, shown under the reply, kept in the Library, charged. */
import { createDb, type DbHandle } from "@casama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, expect, it } from "vitest";
import { registerAutonomyTools } from "../src/tools/autonomy.ts";
import { ToolRegistry } from "../src/tools/registry.ts";

let tdb: TestDatabase;
let h: DbHandle;
beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 3 });
});
afterAll(async () => {
  await h?.close();
  await tdb?.stop();
});

it("makes a narration, keeps it as audio in the Library, and records the speech", async () => {
  const user = await createAuthUser(tdb.admin, "audio@example.com");
  const [org] = await tdb.admin<
    { id: string }[]
  >`insert into public.organizations (name, slug) values ('A', 'audio') returning id`;
  const [bot] = await tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name) values (${org!.id}, ${user.id}, 'Narrator') returning id`;
  const [conv] = await tdb.admin<{ id: string }[]>`
    insert into public.conversations (org_id, bot_id, created_by) values (${org!.id}, ${bot!.id}, ${user.id}) returning id`;
  const [run] = await tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, created_by) values (${org!.id}, ${bot!.id}, ${conv!.id}, ${user.id}) returning id`;
  const asked: string[] = [];
  const pcm = new Uint8Array(48_000); // one second of 24 kHz 16-bit mono
  const fakeFetch = (async (url: string, init: RequestInit = {}) => {
    asked.push(`${url} ${String(init.body)}`);
    return new Response(pcm, { status: 200, headers: { "content-type": "audio/pcm;rate=24000" } });
  }) as unknown as typeof fetch;
  const tools = new ToolRegistry();
  registerAutonomyTools(tools, {
    db: h.db,
    fetch: fakeFetch,
    speechFor: async () => ({
      key: "sk-or-test",
      billable: false,
      bases: { openrouter: "http://openrouter.test/api/v1" },
    }),
  } as never);
  const def = tools.get("media.audio.generate")!;
  expect(def.confirm).toBe(true);
  const r = await def.execute(
    { text: "Welcome to the Monday briefing. Three things today.", voice: "Kore" } as never,
    {
      runId: run!.id,
      botId: bot!.id,
      orgId: org!.id,
      output: async () => {},
      emit: async () => {},
    },
  );
  expect(r.content).toContain("Made 1 s of audio");
  expect(asked[0]).toContain("http://openrouter.test/api/v1/audio/speech");
  expect(asked[0]).toContain('"voice":"Kore"');
  const [c] = await tdb.admin<{ kind: string; title: string; mime: string }[]>`
    select kind, title, mime from public.creations where bot_id = ${bot!.id}`;
  expect(c).toEqual({
    kind: "audio",
    title: "Welcome to the Monday briefing. Three things today.",
    mime: "audio/wav",
  });
  const [u] = await tdb.admin<{ kind: string; quantity: string }[]>`
    select kind, quantity::text from public.usage_ledger where run_id = ${run!.id}`;
  expect(u).toMatchObject({ kind: "tts_chars" });
  expect(Number(u!.quantity)).toBe(51);
});
