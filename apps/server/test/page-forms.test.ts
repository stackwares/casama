/**
 * Pages that take input (D-279): a page published with collect gets a form runtime and may send
 * only to its own origin; responses are stored, read by the bot, and can start a routine.
 */
import { registerPageTools, ToolRegistry } from "@casama/agent";
import { PAGE_CSP, PAGE_CSP_COLLECT } from "@casama/domain";
import { afterAll, beforeAll, expect, it } from "vitest";
import { createPagesApp } from "../src/pages/app.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let orgId = "";
let botId = "";
let runId = "";
let pages: ReturnType<typeof createPagesApp>;
const started: string[] = [];
const reg = new ToolRegistry();
const ctx = () => ({ runId, botId, orgId, output: async () => {}, emit: async () => {} }) as never;
const tool = (name: string, args: unknown) => reg.get(name)!.execute(args as never, ctx());

beforeAll(async () => {
  h = await startHarness({ env: { PAGES_URL: "https://pages.example.com" } });
  pages = createPagesApp({
    db: h.handle.db,
    workflows: { startRun: async (id) => void started.push(id) },
  });
  owner = await h.user("forms@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "F" } }),
    )
  ).id;
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Host" },
      }),
    )
  ).id;
  const [run] = await h.tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, trigger, status, created_by) values (${orgId}, ${botId}, 'chat', 'completed', ${owner.id}) returning id`;
  runId = run!.id;
  registerPageTools(reg, { db: h.handle.db, pagesUrl: "https://pages.example.com" });
}, 60_000);
afterAll(async () => h?.stop());

const FORM = `<!doctype html><html><head><title>RSVP</title></head><body>
<form data-casama-form data-casama-sent="See you there!"><input name="name"><select name="diet"><option>none</option></select><button type="submit">Send</button></form></body></html>`;

it("a collecting page gets the form runtime and may send only to its own origin", async () => {
  const r = await tool("pages.publish", {
    title: "Party RSVP",
    html: FORM,
    collect: true,
    on_submit: "Add them to the guest list and thank them by name.",
  });
  const pageId = /page ([0-9a-f-]{36})/.exec(r.content)![1]!;
  const share = await tool("pages.share", { page_id: pageId, visibility: "public" });
  const url = /https:\/\/pages\.example\.com(\/s\/[^\s)."]+)/.exec(share.content)![1]!;
  const page = await pages.request(url);
  expect(page.headers.get("content-security-policy")).toBe(PAGE_CSP_COLLECT);
  expect(PAGE_CSP_COLLECT).toContain("connect-src 'self'");
  expect(PAGE_CSP_COLLECT).toContain("form-action 'none'");
  const html = await page.text();
  expect(html).toContain("window.casama.submit");
  expect(html).toContain(`${url}/collect`);

  // A public visitor answers; the routine starts with their response.
  const sent = await pages.request(`${url}/collect`, {
    method: "POST",
    headers: { "content-type": "application/json", "x-forwarded-for": "203.0.113.9" },
    body: JSON.stringify({ name: "Ana", diet: "none" }),
  });
  expect(sent.status).toBe(201);
  expect(started).toHaveLength(1);
  const [routineRun] = await h.tdb.admin<
    { id: string }[]
  >`select id from public.runs where id = ${started[0]!}`;
  expect(routineRun).toBeTruthy();
  const read = await tool("pages.submissions", { page_id: pageId });
  expect(read.content).toContain('"name":"Ana"');
  expect(read.content).toContain("<untrusted");

  // Bad input and floods are refused.
  expect(
    (
      await pages.request(`${url}/collect`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: "[1,2]",
      })
    ).status,
  ).toBe(400);
  let last = 0;
  for (let i = 0; i < 21; i++)
    last = (
      await pages.request(`${url}/collect`, {
        method: "POST",
        headers: { "content-type": "application/json", "x-forwarded-for": "198.51.100.7" },
        body: JSON.stringify({ name: `bot ${i}` }),
      })
    ).status;
  expect(last).toBe(429);
});

it("a page that doesn't collect keeps the strict policy and takes nothing", async () => {
  const r = await tool("pages.publish", { title: "Plain", html: "<p>hi</p>" });
  const pageId = /page ([0-9a-f-]{36})/.exec(r.content)![1]!;
  const share = await tool("pages.share", { page_id: pageId, visibility: "public" });
  const url = /https:\/\/pages\.example\.com(\/s\/[^\s)."]+)/.exec(share.content)![1]!;
  const page = await pages.request(url);
  expect(page.headers.get("content-security-policy")).toBe(PAGE_CSP);
  expect(await page.text()).not.toContain("casama.submit");
  expect(
    (
      await pages.request(`${url}/collect`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: "{}",
      })
    ).status,
  ).toBe(404);
});
