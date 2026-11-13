/** Taking a chat out (D-282): Markdown and JSON exports, and a public read-only link. */
import { afterAll, beforeAll, expect, it } from "vitest";
import { createPagesApp } from "../src/pages/app.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let stranger: { id: string; token: string };
let pages: ReturnType<typeof createPagesApp>;
let convId = "";

beforeAll(async () => {
  h = await startHarness({ env: { PAGES_URL: "https://pages.example.com" } });
  pages = createPagesApp({ db: h.handle.db });
  owner = await h.user("export-owner@example.com");
  stranger = await h.user("export-stranger@example.com");
  const org = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "E" } }),
    )
  ).id;
  const bot = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: { org_id: org, name: "Scribe" },
      }),
    )
  ).id;
  convId = (
    await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: bot },
      }),
    )
  ).id;
  await h.tdb.admin`update public.conversations set title = 'Trip plan' where id = ${convId}`;
  const [u] = await h.tdb.admin<{ id: string }[]>`
    insert into public.messages (org_id, conversation_id, role, author_user_id, content)
    values (${org}, ${convId}, 'user', ${owner.id}, ${h.tdb.admin.json([{ type: "text", text: "Plan 3 days in Lisbon <b>please</b>" }])}) returning id`;
  await h.tdb.admin`
    insert into public.messages (org_id, conversation_id, role, content, parent_message_id, bot_id)
    values (${org}, ${convId}, 'assistant', ${h.tdb.admin.json([
      { type: "text", text: "Day 1: Alfama.\nDay 2: Belém." },
      { type: "file", path: "media:x", name: "map.png" },
    ])}, ${u!.id}, ${bot})`;
}, 60_000);
afterAll(async () => h?.stop());

it("exports a chat as Markdown and JSON", async () => {
  const md = await h.request(`/v1/conversations/${convId}/export`, { token: owner.token });
  expect(md.headers.get("content-disposition")).toContain('filename="Trip plan.md"');
  const text = await md.text();
  expect(text).toContain("# Trip plan");
  expect(text).toContain("**You**");
  expect(text).toContain("**Scribe**");
  expect(text).toContain("Day 2: Belém.");
  expect(text).toContain("📎 map.png");
  const json = await j(
    await h.request(`/v1/conversations/${convId}/export?format=json`, { token: owner.token }),
  );
  expect(json.messages.map((m: { role: string }) => m.role)).toEqual(["user", "assistant"]);
  expect(
    (await h.request(`/v1/conversations/${convId}/export`, { token: stranger.token })).status,
  ).toBe(404);
});

it("a public link shows the chat read-only, escapes what's in it, and stops when turned off", async () => {
  const { url } = await j(
    await h.request(`/v1/conversations/${convId}/share`, {
      method: "POST",
      token: owner.token,
      json: { public: true },
    }),
  );
  const path = new URL(url).pathname;
  const page = await pages.request(path);
  expect(page.headers.get("content-security-policy")).not.toContain("script-src");
  const html = await page.text();
  expect(html).toContain("Day 1: Alfama.<br>Day 2: Belém.");
  expect(html).toContain("&#60;b&#62;please&#60;/b&#62;");
  await h.request(`/v1/conversations/${convId}/share`, {
    method: "POST",
    token: owner.token,
    json: { public: false },
  });
  expect((await pages.request(path)).status).toBe(404);
  // A chat with personal device data can't be made public.
  await h.tdb.admin`update public.conversations set private = true where id = ${convId}`;
  expect(
    (
      await h.request(`/v1/conversations/${convId}/share`, {
        method: "POST",
        token: owner.token,
        json: { public: true },
      })
    ).status,
  ).toBe(409);
});
