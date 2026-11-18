/**
 * Sharing anything in the Library (D-281): workspace and public links, a viewer on the pages
 * origin that never runs what it shows, reports that hide a link, and the owner's takedown.
 */
import { afterAll, beforeAll, expect, it } from "vitest";
import { createPagesApp } from "../src/pages/app.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let admin: { id: string; token: string };
let owner: { id: string; token: string };
let member: { id: string; token: string };
let pages: ReturnType<typeof createPagesApp>;
let orgId = "";
let botId = "";
let convId = "";

beforeAll(async () => {
  h = await startHarness({
    env: { PAGES_URL: "https://pages.example.com", INSTANCE_ADMIN_EMAILS: "boss@example.com" },
  });
  pages = createPagesApp({ db: h.handle.db });
  admin = await h.user("boss@example.com");
  owner = await h.user("share-owner@example.com");
  member = await h.user("share-member@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Share" } }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Artist" },
      }),
    )
  ).id;
  convId = (
    await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: botId },
      }),
    )
  ).id;
  await h.tdb.admin`update public.conversations set private = true where id = ${convId}`;
}, 60_000);
afterAll(async () => h?.stop());

const mediaCreation = async (name: string, type: string, bytes = "IMAGEBYTES") => {
  const [m] = await h.tdb.admin<{ id: string }[]>`
    insert into public.chat_media (org_id, bot_id, conversation_id, name, content_type, bytes, size)
    values (${orgId}, ${botId}, ${convId}, ${name}, ${type}, ${Buffer.from(bytes)}, ${bytes.length}) returning id`;
  const [c] = await h.tdb.admin<
    { id: string }[]
  >`select id from public.creations where media_id = ${m!.id}`;
  return c!.id;
};
const share = (id: string, visibility: string, token = owner.token) =>
  h.request(`/v1/creations/${id}`, { method: "PATCH", token, json: { visibility } });

it("workspace sharing lets every member open something from a private chat", async () => {
  const id = await mediaCreation("poster.png", "image/png");
  expect((await h.request(`/v1/creations/${id}`, { token: member.token })).status).toBe(404);
  expect((await share(id, "workspace", member.token)).status).toBe(404);
  const shared = await j(await share(id, "workspace"));
  expect(shared).toMatchObject({ visibility: "workspace" });
  expect(shared.public_url).toBeUndefined();
  expect((await h.request(`/v1/creations/${id}`, { token: member.token })).status).toBe(200);
});

it("a public link shows a viewer that only displays, serves the bytes safely, and stops when private again", async () => {
  const id = await mediaCreation("logo.png", "image/png");
  const res = await j(await share(id, "public"));
  expect(res.visibility).toBe("public");
  const path = new URL(res.public_url).pathname;
  expect(path).toMatch(/^\/c\//);
  const view = await pages.request(path);
  expect(view.status).toBe(200);
  expect(view.headers.get("content-security-policy")).toContain("default-src 'none'");
  expect(view.headers.get("content-security-policy")).not.toContain("script-src");
  expect(await view.text()).toContain(`<img src="${path}/raw"`);
  const raw = await pages.request(`${path}/raw`);
  expect(raw.headers.get("content-type")).toBe("image/png");
  expect(await raw.text()).toBe("IMAGEBYTES");

  // An HTML file never renders inline on the public origin.
  const page = await mediaCreation("trap.html", "text/html", "<script>alert(1)</script>");
  const trap = new URL((await j(await share(page, "public"))).public_url).pathname;
  const trapRaw = await pages.request(`${trap}/raw`);
  expect(trapRaw.headers.get("content-type")).toBe("application/octet-stream");
  expect(trapRaw.headers.get("content-disposition")).toMatch(/^attachment/);

  await share(id, "private");
  expect((await pages.request(path)).status).toBe(404);
});

it("three different people reporting a link hide it; the owner sees reports and can take one down", async () => {
  const id = await mediaCreation("meme.png", "image/png");
  const path = new URL((await j(await share(id, "public"))).public_url).pathname;
  const report = (ip: string) =>
    pages.request(`${path}/report`, {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded", "x-forwarded-for": ip },
      body: "reason=This+is+someone+else%27s+art",
    });
  await report("198.51.100.1");
  await report("198.51.100.1");
  await report("198.51.100.2");
  expect((await pages.request(path)).status).toBe(200);
  await report("198.51.100.3");
  expect((await pages.request(path)).status).toBe(404);

  expect((await h.request("/v1/admin/reports", { token: owner.token })).status).toBe(403);
  const list = await j(await h.request("/v1/admin/reports", { token: admin.token }));
  expect(list.items[0]).toMatchObject({ id, reports: 4, reporters: 3, taken_down: true });
  const back = await j(
    await h.request(`/v1/admin/creations/${id}/takedown`, {
      method: "POST",
      token: admin.token,
      json: { down: false },
    }),
  );
  expect(back.taken_down).toBe(false);
  expect((await pages.request(path)).status).toBe(200);
});

it("a page shared from the Library becomes a public page with a Report link", async () => {
  await h.tdb
    .admin`insert into public.pages (org_id, bot_id, created_by, title, html) values (${orgId}, ${botId}, ${owner.id}, 'Menu', '<p>Soup</p>')`;
  const [c] = await h.tdb.admin<
    { id: string }[]
  >`select id from public.creations where title = 'Menu'`;
  const res = await j(await share(c!.id, "public"));
  const path = new URL(res.public_url).pathname;
  expect(path).toMatch(/^\/s\//);
  const html = await (await pages.request(path)).text();
  expect(html).toContain(`href="${path}/report"`);
  expect((await pages.request(`${path}/report`)).status).toBe(200);
});
