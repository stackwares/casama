/** Pages (D-119): publish, update data, private/workspace/public, view links, PDF, versions. */
import { registerPageTools, ToolRegistry } from "@casama/agent";
import { PAGE_CSP } from "@casama/domain";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { createPagesApp } from "../src/pages/app.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let member: { id: string; token: string };
let orgId: string;
let botId: string;
let runId: string;
let pages: ReturnType<typeof createPagesApp>;
const printed: string[] = [];

const reg = new ToolRegistry();
const ctx = () => ({ runId, botId, orgId, output: async () => {}, emit: async () => {} }) as never;
const tool = (name: string, args: unknown) => reg.get(name)!.execute(args as never, ctx());
const pathOf = (url: string) => new URL(url).pathname;

/** Opens a view link like a browser: follows the redirect with the cookie it sets. */
const open = async (link: string) => {
  const first = await pages.request(pathOf(link));
  if (first.status !== 302) return first;
  const cookie = first.headers.get("set-cookie")?.split(";")[0] ?? "";
  return pages.request(first.headers.get("location") as string, { headers: { cookie } });
};
const viewLink = async (id: string, token: string, format?: "pdf") =>
  (
    await j(
      await h.request(`/v1/pages/${id}/view-link`, {
        method: "POST",
        token,
        json: format ? { format } : {},
      }),
    )
  ).url as string;

beforeAll(async () => {
  h = await startHarness({ env: { PAGES_URL: "https://pages.example.com" } });
  pages = createPagesApp({
    db: h.handle.db,
    pdf: {
      render: async (html) => (printed.push(html), new TextEncoder().encode("%PDF-1.7 fake")),
    },
  });
  owner = await h.user("pages@example.com");
  member = await h.user("teammate@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "P" } }),
    )
  ).id;
  const link = await j(
    await h.request(`/v1/orgs/${orgId}/invite-links`, {
      method: "POST",
      token: owner.token,
      json: { role: "member" },
    }),
  );
  await h.request(`/v1/invite-links/${link.token}/accept`, { method: "POST", token: member.token });
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
    }),
  );
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Reporter",
          model_policy: { primary: { credential_id: cred.id, model: "m" } },
        },
      }),
    )
  ).id;
  const [run] = await h.tdb.admin<
    { id: string }[]
  >`insert into public.runs (org_id, bot_id, trigger, status, created_by) values (${orgId}, ${botId}, 'chat', 'completed', ${owner.id}) returning id`;
  runId = run!.id;
  registerPageTools(reg, { db: h.handle.db, pagesUrl: "https://pages.example.com" });
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

const HTML = `<!doctype html><html><head><title>Sales</title></head><body><h1 id="t"></h1>
<script>const d = JSON.parse(document.getElementById("casama-data").textContent); document.getElementById("t").textContent = "Total " + d.total;</script></body></html>`;

describe("pages", () => {
  let pageId: string;

  it("a bot publishes a private page; only the person it was for opens it, with a strict CSP", async () => {
    const r = await tool("pages.publish", {
      title: "Sales",
      html: HTML,
      data: JSON.stringify({ total: 42, note: "</script><b>x" }),
    });
    pageId = /page ([0-9a-f-]{36})/.exec(r.content)![1] as string;
    const list = await j(await h.request(`/v1/pages?org_id=${orgId}`, { token: owner.token }));
    expect(list.items).toHaveLength(1);
    expect(list.items[0]).toMatchObject({
      title: "Sales",
      visibility: "private",
      version: 1,
      can_manage: true,
    });
    // A teammate can see the bot but not a private page.
    expect(
      (await j(await h.request(`/v1/pages?org_id=${orgId}`, { token: member.token }))).items,
    ).toHaveLength(0);
    expect(
      (
        await h.request(`/v1/pages/${pageId}/view-link`, {
          method: "POST",
          token: member.token,
          json: {},
        })
      ).status,
    ).toBe(404);

    const link = await viewLink(pageId, owner.token);
    expect(link).toMatch(/^https:\/\/pages\.example\.com\/v\//);
    const res = await open(link);
    expect(res.status).toBe(200);
    expect(res.headers.get("content-security-policy")).toBe(PAGE_CSP);
    expect(res.headers.get("content-security-policy")).toContain("connect-src 'none'");
    expect(res.headers.get("x-robots-tag")).toContain("noindex");
    const body = await res.text();
    expect(body).toContain('id="casama-data"');
    expect(body).toContain('"total":42');
    expect(body).not.toContain("</script><b>"); // data can't break out of its script block
    expect(body).toContain("casama-updated");
    // Single use.
    expect((await pages.request(pathOf(link))).status).toBe(404);
    // No cookie, no page.
    expect((await pages.request(`/p/${pageId}`)).status).toBe(404);
  });

  it("the cookie is scoped to its page and stops working when access goes", async () => {
    const first = await pages.request(pathOf(await viewLink(pageId, owner.token)));
    const setCookie = first.headers.get("set-cookie") ?? "";
    expect(setCookie).toContain(`Path=/p/${pageId}`);
    expect(setCookie).toContain("HttpOnly");
    const cookie = setCookie.split(";")[0] as string;
    expect((await pages.request(`/p/${pageId}`, { headers: { cookie } })).status).toBe(200);
    // Another page id with the same cookie: no.
    expect((await pages.request(`/p/${crypto.randomUUID()}`, { headers: { cookie } })).status).toBe(
      404,
    );
  });

  it("update_data changes the data only and keeps versions; revert brings one back", async () => {
    await tool("pages.update_data", { page_id: pageId, data: JSON.stringify({ total: 99 }) });
    const d = await j(await h.request(`/v1/pages/${pageId}`, { token: owner.token }));
    expect(d.version).toBe(2);
    expect(d.versions.map((v: { version: number }) => v.version)).toEqual([2, 1]);
    expect(await (await open(await viewLink(pageId, owner.token))).text()).toContain('"total":99');
    const reverted = await j(
      await h.request(`/v1/pages/${pageId}/revert`, {
        method: "POST",
        token: owner.token,
        json: { version: 1 },
      }),
    );
    expect(reverted.version).toBe(3);
    expect(await (await open(await viewLink(pageId, owner.token))).text()).toContain('"total":42');
    // Only the last 20 are kept.
    for (let i = 0; i < 22; i++)
      await tool("pages.update_data", { page_id: pageId, data: JSON.stringify({ total: i }) });
    const kept = await j(await h.request(`/v1/pages/${pageId}`, { token: owner.token }));
    expect(kept.versions).toHaveLength(20);
    expect(kept.versions[0].version).toBe(25);
  });

  it("workspace pages open for teammates; public links work signed out, expire and are revocable", async () => {
    expect(
      reg.get("pages.share")!.riskFor!({ page_id: pageId, visibility: "public" } as never),
    ).toBe("high");
    await tool("pages.share", { page_id: pageId, visibility: "workspace" });
    expect(
      (await j(await h.request(`/v1/pages?org_id=${orgId}`, { token: member.token }))).items,
    ).toHaveLength(1);
    expect((await open(await viewLink(pageId, member.token))).status).toBe(200);
    // Teammates can open it but not change it.
    expect(
      (
        await h.request(`/v1/pages/${pageId}`, {
          method: "PATCH",
          token: member.token,
          json: { visibility: "public" },
        })
      ).status,
    ).toBe(403);

    const shared = await j(
      await h.request(`/v1/pages/${pageId}`, {
        method: "PATCH",
        token: owner.token,
        json: { visibility: "public", expires_in_days: 7 },
      }),
    );
    expect(shared.public_url).toMatch(/^https:\/\/pages\.example\.com\/s\//);
    expect(shared.page).toMatchObject({ visibility: "public" });
    const pub = await pages.request(pathOf(shared.public_url));
    expect(pub.status).toBe(200);
    expect(pub.headers.get("x-robots-tag")).toContain("noindex");
    const [audit] = await h.tdb.admin<
      { action: string }[]
    >`select action from public.audit_log where target_id = ${pageId}`;
    expect(audit?.action).toBe("page.made_public");

    // Expired: gone.
    await h.tdb
      .admin`update public.pages set expires_at = now() - interval '1 minute' where id = ${pageId}`;
    expect((await pages.request(pathOf(shared.public_url))).status).toBe(404);
    // Sharing again gives a new link; the old one stays dead; taking it back kills the new one.
    const again = await j(
      await h.request(`/v1/pages/${pageId}`, {
        method: "PATCH",
        token: owner.token,
        json: { visibility: "public" },
      }),
    );
    expect(again.public_url).not.toBe(shared.public_url);
    expect((await pages.request(pathOf(shared.public_url))).status).toBe(404);
    expect((await pages.request(pathOf(again.public_url))).status).toBe(200);
    await h.request(`/v1/pages/${pageId}`, {
      method: "PATCH",
      token: owner.token,
      json: { visibility: "workspace" },
    });
    expect((await pages.request(pathOf(again.public_url))).status).toBe(404);
  });

  it("PDF export prints the same document", async () => {
    const res = await open(await viewLink(pageId, owner.token, "pdf"));
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toBe("application/pdf");
    expect(printed.at(-1)).toContain('id="casama-data"');
    const off = createPagesApp({ db: h.handle.db });
    const first = await pages.request(pathOf(await viewLink(pageId, owner.token, "pdf")));
    const cookie = first.headers.get("set-cookie")?.split(";")[0] ?? "";
    expect((await off.request(`/p/${pageId}/pdf`, { headers: { cookie } })).status).toBe(503);
  });

  it("refresh_cron links a routine that updates the data; deleting the page turns it off", async () => {
    await tool("pages.publish", {
      title: "Sales",
      html: HTML,
      page_id: pageId,
      refresh_cron: "0 8 * * *",
      refresh_instructions: "Sum today's orders.",
    });
    const [p] = await h.tdb.admin<
      { refresh_routine_id: string }[]
    >`select refresh_routine_id from public.pages where id = ${pageId}`;
    const [rt] = await h.tdb.admin<
      { instructions_md: string; schedule_cron: string; enabled: boolean }[]
    >`select instructions_md, schedule_cron, enabled from public.routines where id = ${p!.refresh_routine_id}`;
    expect(rt).toMatchObject({ schedule_cron: "0 8 * * *", enabled: true });
    expect(rt?.instructions_md).toContain("pages.update_data");
    expect(rt?.instructions_md).toContain(pageId);
    expect(
      (await h.request(`/v1/pages/${pageId}`, { method: "DELETE", token: member.token })).status,
    ).toBe(403);
    expect(
      (await h.request(`/v1/pages/${pageId}`, { method: "DELETE", token: owner.token })).status,
    ).toBe(200);
    const [after] = await h.tdb.admin<
      { enabled: boolean }[]
    >`select enabled from public.routines where id = ${p!.refresh_routine_id}`;
    expect(after?.enabled).toBe(false);
  });

  it("a fragment gets a full document; another bot can't touch the page", async () => {
    const r = await tool("pages.publish", { title: "Bit", html: "<p>Hi</p>" });
    const id = /page ([0-9a-f-]{36})/.exec(r.content)![1] as string;
    const body = await (await open(await viewLink(id, owner.token))).text();
    // The content security policy comes first, so it also applies to a local print.
    expect(body).toMatch(
      /^<!doctype html><html><head><meta http-equiv="Content-Security-Policy"[^>]*><meta charset/,
    );
    const [other] = await h.tdb.admin<
      { id: string }[]
    >`insert into public.bots (org_id, name, model_policy, created_by) select org_id, 'Other', model_policy, created_by from public.bots where id = ${botId} returning id`;
    await expect(
      reg
        .get("pages.update_data")!
        .execute(
          { page_id: id, data: "{}" } as never,
          { ...(ctx() as object), botId: other!.id } as never,
        ),
    ).rejects.toThrow(/no page/);
  });
});
