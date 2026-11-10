/** Search (D-103): grouped results that never cross workspaces; file search on awake computers. */
import { execFileSync } from "node:child_process";
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { fileSearchCommand, parseFileSearch } from "../src/api/routes/search.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let ada: { id: string; token: string };
let eve: { id: string; token: string };
let orgA: string;
let orgB: string;

const setup = async (user: { id: string; token: string }, name: string, secret: string) => {
  const org = (
    await j(await h.request("/v1/orgs", { method: "POST", token: user.token, json: { name } }))
  ).id;
  const [bot] = await h.tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, name, created_by, visibility) values (${org}, ${`${name} bot`}, ${user.id}, 'team') returning id`;
  const [conv] = await h.tdb.admin<{ id: string }[]>`
    insert into public.conversations (org_id, bot_id, title, created_by) values (${org}, ${bot!.id}, ${`Quarterly ${secret}`}, ${user.id}) returning id`;
  await h.tdb.admin`
    insert into public.messages (org_id, conversation_id, role, author_user_id, content)
    values (${org}, ${conv!.id}, 'user', ${user.id}, ${JSON.stringify([{ type: "text", text: `Please draft the ${secret} invoice for Northwind` }])}::text::jsonb)`;
  await h.tdb.admin`insert into public.skills (org_id, bot_id, name, description, body_md)
    values (${org}, ${bot!.id}, 'invoice-drafting', 'How we draft invoices', 'Steps')`;
  await h.tdb
    .admin`insert into public.tasks (org_id, title, created_by_user_id) values (${org}, ${`Send ${secret} invoice`}, ${user.id})`;
  await h.tdb
    .admin`insert into public.memories (org_id, bot_id, kind, content) values (${org}, ${bot!.id}, 'fact', ${`Northwind pays invoices on the 15th (${secret})`})`;
  return org;
};

beforeAll(async () => {
  h = await startHarness();
  ada = await h.user("search-ada@example.com");
  eve = await h.user("search-eve@example.com");
  orgA = await setup(ada, "Alpha", "alphacorp");
  orgB = await setup(eve, "Beta", "betacorp");
}, 60_000);
afterAll(async () => h?.stop());

describe("search", () => {
  it("groups messages, chats, memories, skills and tickets in the workspace", async () => {
    const res = await j(
      await h.request(`/v1/search?org_id=${orgA}&q=invoice`, { token: ada.token }),
    );
    const kinds = new Set(res.items.map((i: { kind: string }) => i.kind));
    expect([...kinds].sort()).toEqual(["memory", "message", "skill", "ticket"]);
    const msg = res.items.find((i: { kind: string }) => i.kind === "message");
    expect(msg.snippet).toContain("«invoice»");
    expect(msg.conversation_id).toBeTruthy();
    const chat = await j(
      await h.request(`/v1/search?org_id=${orgA}&q=quarterly`, { token: ada.token }),
    );
    expect(chat.items.map((i: { kind: string }) => i.kind)).toContain("chat");
  });

  it("never returns another workspace's results", async () => {
    const res = await j(
      await h.request(`/v1/search?org_id=${orgA}&q=betacorp`, { token: ada.token }),
    );
    expect(res.items).toEqual([]);
    const peek = await j(
      await h.request(`/v1/search?org_id=${orgB}&q=invoice`, { token: ada.token }),
    );
    expect(peek.items).toEqual([]);
    expect(
      JSON.stringify(
        await j(await h.request(`/v1/search?org_id=${orgB}&q=invoice`, { token: eve.token })),
      ),
    ).toContain("betacorp");
  });

  it("rejects too-short queries and treats wildcards literally", async () => {
    expect((await h.request(`/v1/search?org_id=${orgA}&q=a`, { token: ada.token })).status).toBe(
      400,
    );
    const res = await j(
      await h.request(`/v1/search?org_id=${orgA}&q=${encodeURIComponent("%_")}`, {
        token: ada.token,
      }),
    );
    expect(res.items).toEqual([]);
  });
});

describe("file search command", () => {
  it("finds names and contents under ~/workspace, safely quoted", () => {
    const home = mkdtempSync(join(tmpdir(), "ksearch-"));
    mkdirSync(join(home, "workspace", "docs"), { recursive: true });
    writeFileSync(join(home, "workspace", "docs", "Invoice-May.md"), "totals");
    writeFileSync(join(home, "workspace", "notes.txt"), "the northwind INVOICE is due");
    writeFileSync(join(home, "workspace", "other.txt"), "nothing");
    const run = (q: string) =>
      parseFileSearch(
        execFileSync("sh", ["-c", fileSearchCommand(q)], {
          env: { ...process.env, HOME: home },
        }).toString(),
      );
    expect(run("invoice")).toEqual([
      { path: "docs/Invoice-May.md", match: "name" },
      { path: "notes.txt", match: "content" },
    ]);
    expect(run("'; touch pwned; echo '")).toEqual([]);
    expect(run("*")).toEqual([]);
  });
});
