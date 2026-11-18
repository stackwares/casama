/**
 * Casama for Chrome, Phase 2 (D-323): page commands, highlights (and the bot tool that reads them),
 * past chats about a page, and page watchers made by pointing at part of a page.
 */
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { checkWatchers, registerHighlightTools, ToolRegistry } from "@casama/agent";
import { pageKey } from "@casama/contracts";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let me: { id: string; token: string };
let other: { id: string; token: string };
let orgId: string;
let botId: string;
let page: Server;
let pageUrl: string;
let stock = "In stock";
let heading = "Blue kettle";

beforeAll(async () => {
  page = createServer((_req, res) => {
    res.setHeader("content-type", "text/html");
    res.end(
      `<html><body><nav>Shop</nav><h2>${heading}</h2><p>Price $40. ${stock}.</p><footer>Visitors today: ${Date.now()}</footer></body></html>`,
    );
  }).listen(0, "127.0.0.1");
  await new Promise((r) => page.once("listening", r));
  pageUrl = `http://127.0.0.1:${(page.address() as AddressInfo).port}/kettle`;
  h = await startHarness();
  me = await h.user("chrome-p2@example.com");
  other = await h.user("chrome-p2-other@example.com");
  orgId = (
    await j(await h.request("/v1/orgs", { method: "POST", token: me.token, json: { name: "P2" } }))
  ).id;
  const [bot] = await h.tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, name, created_by) values (${orgId}, 'Reader', ${me.id}) returning id`;
  botId = bot!.id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
  page?.close();
});

describe("pageKey", () => {
  it("drops the fragment and tracking parameters, lowercases the host, trims a trailing slash", () => {
    expect(pageKey("https://Example.com/a/?utm_source=x&id=3&fbclid=y#top")).toBe(
      "https://example.com/a?id=3",
    );
    expect(pageKey("https://example.com/")).toBe("https://example.com");
  });
});

describe("page commands", () => {
  it("are listed, made, renamed and deleted by their owner only, with names unique per person", async () => {
    const made = await h.request("/v1/me/page-commands", {
      method: "POST",
      token: me.token,
      json: { name: "tldr", prompt: "Summarise this page in three bullets." },
    });
    expect(made.status).toBe(201);
    const cmd = await j(made);
    expect(cmd.position).toBe(0);
    const dup = await h.request("/v1/me/page-commands", {
      method: "POST",
      token: me.token,
      json: { name: "tldr", prompt: "x" },
    });
    expect(dup.status).toBe(409);
    // Someone else can have the same name, and can't see or change mine.
    expect(
      (
        await h.request("/v1/me/page-commands", {
          method: "POST",
          token: other.token,
          json: { name: "tldr", prompt: "y" },
        })
      ).status,
    ).toBe(201);
    expect(
      (
        await h.request(`/v1/me/page-commands/${cmd.id}`, {
          method: "PATCH",
          token: other.token,
          json: { name: "mine" },
        })
      ).status,
    ).toBe(404);
    const renamed = await j(
      await h.request(`/v1/me/page-commands/${cmd.id}`, {
        method: "PATCH",
        token: me.token,
        json: { name: "short" },
      }),
    );
    expect(renamed).toMatchObject({
      name: "short",
      prompt: "Summarise this page in three bullets.",
    });
    const list = await j(await h.request("/v1/me/page-commands", { token: me.token }));
    expect(list.items.map((c: { name: string }) => c.name)).toEqual(["short"]);
    expect(
      (await h.request(`/v1/me/page-commands/${cmd.id}`, { method: "DELETE", token: me.token }))
        .status,
    ).toBe(200);
    expect((await j(await h.request("/v1/me/page-commands", { token: me.token }))).items).toEqual(
      [],
    );
  });
});

describe("highlights and a page's history", () => {
  it("keep highlights per person, find them by the page however its address is decorated", async () => {
    const made = await h.request("/v1/me/highlights", {
      method: "POST",
      token: me.token,
      json: {
        org_id: orgId,
        url: "https://news.example/story?utm_campaign=x#p4",
        title: "Rain returns",
        text: "Two more days of showers are expected",
        prefix: "Tuesday. ",
        suffix: ", but",
        note: "check the reservoir",
      },
    });
    expect(made.status).toBe(201);
    expect((await j(made)).url_key).toBe("https://news.example/story");
    const mine = await j(
      await h.request(
        `/v1/me/highlights?org_id=${orgId}&url=${encodeURIComponent("https://news.example/story")}`,
        { token: me.token },
      ),
    );
    expect(mine.items).toHaveLength(1);
    // Not a member: refused; and nobody else sees my highlights.
    expect(
      (
        await h.request("/v1/me/highlights", {
          method: "POST",
          token: other.token,
          json: { org_id: orgId, url: "https://news.example/story", text: "x" },
        })
      ).status,
    ).toBe(404);
    expect(
      (await j(await h.request(`/v1/me/highlights?org_id=${orgId}`, { token: other.token }))).items,
    ).toEqual([]);
  });

  it("lists my past chats that started on the page, with its highlights", async () => {
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: me.token,
        json: { bot_id: botId, source_url: "https://news.example/story/?utm_source=chrome" },
      }),
    );
    await h.request("/v1/conversations", {
      method: "POST",
      token: me.token,
      json: { bot_id: botId, source_url: "https://news.example/other" },
    });
    const hist = await j(
      await h.request(
        `/v1/me/page-history?org_id=${orgId}&url=${encodeURIComponent("https://news.example/story#comments")}`,
        { token: me.token },
      ),
    );
    expect(hist.conversations.map((c: { id: string }) => c.id)).toEqual([conv.id]);
    expect(hist.highlights).toHaveLength(1);
  });

  it("highlights.search reads only the acting person's highlights in the bot's workspace", async () => {
    const reg = new ToolRegistry();
    registerHighlightTools(reg, { db: h.handle.db });
    const [run] = await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, trigger, status, created_by)
      values (${orgId}, ${botId}, 'chat', 'completed', ${me.id}) returning id`;
    const [nobody] = await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, trigger, status)
      values (${orgId}, ${botId}, 'routine', 'completed') returning id`;
    const ctx = (runId: string) =>
      ({ runId, botId, orgId, output: async () => {}, emit: async () => {} }) as never;
    const tool = reg.get("highlights.search")!;
    const hit = await tool.execute({ query: "showers" } as never, ctx(run!.id));
    expect(hit.content).toContain("Two more days of showers");
    expect(hit.content).toContain("check the reservoir");
    expect((await tool.execute({ query: "kettle" } as never, ctx(run!.id))).content).toBe(
      "No highlights found.",
    );
    expect((await tool.execute({} as never, ctx(nobody!.id))).content).toMatch(/isn't acting/);
  });
});

describe("POST /v1/watchers (watch this page)", () => {
  it("makes a page watcher for a bot I can use, comparing only the part I pointed at", async () => {
    const res = await h.request("/v1/watchers", {
      method: "POST",
      token: me.token,
      json: {
        bot_id: botId,
        name: "Kettle stock",
        url: pageUrl,
        anchor: "Blue kettle",
        chars: 40,
        check_every_minutes: 15,
      },
    });
    expect(res.status).toBe(201);
    const w = await j(res);
    expect(w).toMatchObject({ kind: "page_change", status: "active", check_every_seconds: 900 });
    expect(w.target).toMatchObject({ url: pageUrl, anchor: "Blue kettle", chars: 40 });
    const [row] = await h.tdb.admin<{ created_by: string }[]>`
      select created_by from public.watchers where id = ${w.id}`;
    expect(row?.created_by).toBe(me.id);
    // It stops by itself after about 90 days.
    const days = (Date.parse(w.expires_at) - Date.now()) / 86_400_000;
    expect(days).toBeGreaterThan(89);
    expect(days).toBeLessThan(91);

    const started: string[] = [];
    const check = (at: Date) =>
      checkWatchers(
        {
          db: h.handle.db,
          fetch,
          startRun: async (id) => {
            started.push(id);
          },
        },
        at,
      );
    const t0 = new Date(Date.now() + 1000);
    await check(t0); // baseline
    await check(new Date(t0.getTime() + 15 * 60_000)); // the visitor count changed: outside the part
    expect(started).toEqual([]);
    stock = "Sold out";
    await check(new Date(t0.getTime() + 30 * 60_000));
    expect(started).toHaveLength(1);

    // The part pointed at is gone (a redesign, a sign-in page): an error on the watcher, no ping.
    heading = "Red kettle";
    await check(new Date(t0.getTime() + 45 * 60_000));
    expect(started).toHaveLength(1);
    const [after] = await h.tdb.admin<{ last_error: string | null }[]>`
      select last_error from public.watchers where id = ${w.id}`;
    expect(after?.last_error).toMatch(/no longer on the page/);
    heading = "Blue kettle";
  });

  it("caps how many page watchers one person keeps", async () => {
    await h.tdb.admin`
      insert into public.watchers (org_id, bot_id, created_by, name, kind, target)
      select ${orgId}, ${botId}, ${me.id}, 'w' || g, 'page_change',
             '{"url":"https://shop.example/","browser":false,"source":"chrome"}'::jsonb
      from generate_series(1, 30) g`;
    const res = await h.request("/v1/watchers", {
      method: "POST",
      token: me.token,
      json: { bot_id: botId, name: "One more", url: pageUrl },
    });
    expect(res.status).toBe(409);
    expect((await j(res)).code).toBe("too_many_watchers");
    await h.tdb.admin`delete from public.watchers where created_by = ${me.id} and name like 'w%'`;
  });

  it("refuses a bot I can't use and pages that aren't http(s)", async () => {
    const body = { bot_id: botId, name: "x", url: pageUrl };
    expect(
      (await h.request("/v1/watchers", { method: "POST", token: other.token, json: body })).status,
    ).toBe(404);
    expect(
      (
        await h.request("/v1/watchers", {
          method: "POST",
          token: me.token,
          json: { ...body, url: "file:///etc/passwd" },
        })
      ).status,
    ).toBe(400);
  });
});
