/** Paging the thread (Fix 10): the newest page, the page before it, and a page around a search hit. */
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let convId: string;
/** The thread's message ids, oldest first: 30 turns of user, tool, assistant. */
const ids: { id: string; role: string; n: number }[] = [];

type Row = { id: string; role: string; content: Array<{ text?: string }> };
const rpc = async (limit: number | null, before: string | null, around: string | null) =>
  h.tdb.admin<Row[]>`
    select * from public.conversation_thread(${convId}::uuid, ${limit}::int, ${before}::uuid, ${around}::uuid)`;
const text = (rows: Row[]) => rows.map((r) => r.content[0]?.text);
const api = async (query: string) =>
  j(await h.request(`/v1/conversations/${convId}/thread${query}`, { token: owner.token }));

beforeAll(async () => {
  h = await startHarness();
  owner = await h.user("paging-owner@example.com");
  const orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "P" } }),
    )
  ).id;
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
    }),
  );
  const bot = await j(
    await h.request("/v1/bots", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: orgId,
        name: "Pager",
        model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
      },
    }),
  );
  convId = (
    await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: bot.id },
      }),
    )
  ).id;
  // Each insert hangs off the one before it (the messages_set_parent trigger).
  for (let n = 1; n <= 30; n++) {
    for (const role of ["user", "tool", "assistant"]) {
      const [row] = await h.tdb.admin<{ id: string }[]>`
        insert into public.messages (org_id, conversation_id, role, content)
        values (${orgId}, ${convId}, ${role}, jsonb_build_array(jsonb_build_object('type', 'text', 'text', ${`${role[0]}${n}`}::text)))
        returning id`;
      ids.push({ id: row?.id as string, role, n });
    }
  }
}, 60_000);
afterAll(async () => h?.stop());

const idOf = (role: string, n: number) =>
  ids.find((m) => m.role === role && m.n === n)?.id as string;

describe("thread paging", () => {
  it("returns the whole branch, every role, when no limit is given", async () => {
    const all = await h.tdb.admin<Row[]>`select * from public.conversation_thread(${convId})`;
    expect(all).toHaveLength(90);
    expect(text(all).slice(0, 3)).toEqual(["u1", "t1", "a1"]);
  });

  it("returns the newest messages people read, oldest first", async () => {
    const page = await rpc(6, null, null);
    expect(text(page)).toEqual(["u28", "a28", "u29", "a29", "u30", "a30"]);
  });

  it("returns the page before a message", async () => {
    const page = await rpc(4, idOf("user", 28), null);
    expect(text(page)).toEqual(["u26", "a26", "u27", "a27"]);
    // The start of the thread: fewer than asked for, then nothing.
    expect(text(await rpc(4, idOf("assistant", 1), null))).toEqual(["u1"]);
    expect(await rpc(4, idOf("user", 1), null)).toHaveLength(0);
  });

  it("opens around an older message: everything after it and half a page before", async () => {
    const page = await rpc(6, null, idOf("user", 10));
    expect(text(page)[0]).toBe("a8");
    expect(text(page).slice(0, 4)).toEqual(["a8", "u9", "a9", "u10"]);
    expect(text(page).at(-1)).toBe("a30");
  });

  it("ignores a message from another chat", async () => {
    const stray = "00000000-0000-4000-8000-000000000000";
    expect(text(await rpc(4, null, stray))).toEqual(["u29", "a29", "u30", "a30"]);
    expect(await rpc(4, stray, null)).toHaveLength(0);
  });

  it("pages through the API the same way (encrypted workspaces read it there)", async () => {
    const newest = await api("?limit=4");
    expect(newest.items.map((m: Row) => m.content[0]?.text)).toEqual(["u29", "a29", "u30", "a30"]);
    const earlier = await api(`?limit=2&before=${newest.items[0].id}`);
    expect(earlier.items.map((m: Row) => m.content[0]?.text)).toEqual(["u28", "a28"]);
    const around = await api(`?limit=4&around=${idOf("assistant", 20)}`);
    expect(around.items[0].content[0].text).toBe("a19");
    const all = await api("");
    expect(all.items).toHaveLength(90);
  });
});
