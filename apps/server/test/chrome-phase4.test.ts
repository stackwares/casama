/**
 * Casama for Chrome, Phase 4 (D-323): the browser as a device. A fake extension stands in for the
 * real one: it registers a web device source and answers requests the way the extension does
 * (apps/extension/src/background/device/), polling the requests list instead of listening on
 * Realtime.
 */
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = new URL("./fixtures/chrome-phase4.json", import.meta.url).pathname;
const KEY = "chrome-phase4-browser";

type Req = { id: string; kind: string; action: string; params: Record<string, unknown> };

describe("Casama for Chrome Phase 4: the browser as a device", () => {
  let h: Harness;
  let telegram: Server;
  let telegramApi = "";
  let user: { id: string; token: string };
  let stranger: { id: string; token: string };
  let orgId: string;
  let botId: string;
  /** What the fake extension answers for each kind; null = it doesn't answer. */
  let answer: ((r: Req) => Record<string, unknown> | null) | null = null;
  let polling = true;
  const answered: Req[] = [];

  /** The fake extension: picks up requests and uploads its live reading. */
  const extensionLoop = async () => {
    while (polling) {
      const res = await h.request(`/v1/device-sources/${KEY}/requests`, { token: user.token });
      if (res.status === 200 && answer) {
        for (const r of (await j(res)).items as Req[]) {
          const summary = answer(r);
          if (!summary) continue;
          answered.push(r);
          const now = new Date().toISOString();
          await h.request(`/v1/device-sources/${KEY}/readings`, {
            method: "POST",
            token: user.token,
            json: {
              request_id: r.id,
              readings: [
                {
                  kind: r.kind,
                  period_start: now,
                  period_end: now,
                  external_id: `${r.kind}-${r.id}`,
                  summary,
                },
              ],
            },
          });
        }
      }
      await new Promise((r) => setTimeout(r, 150));
    }
  };

  const settle = async (runId: string) => {
    for (let i = 0; i < 300; i++) {
      const r = await j(await h.request(`/v1/runs/${runId}`, { token: user.token }));
      if (["completed", "failed", "waiting_approval"].includes(r.status)) return r;
      await new Promise((res) => setTimeout(res, 200));
    }
    throw new Error("run did not settle");
  };

  beforeAll(async () => {
    telegram = createServer(async (req, res) => {
      for await (const _ of req) {
        // Drain.
      }
      res
        .writeHead(200, { "content-type": "application/json" })
        .end(JSON.stringify({ ok: true, result: true }));
    }).listen(0, "127.0.0.1");
    await once(telegram, "listening");
    telegramApi = `http://127.0.0.1:${(telegram.address() as AddressInfo).port}`;
    h = await startHarness({ worker: { fixtures: FIXTURES } });
    user = await h.user("chrome4@example.com");
    stranger = await h.user("chrome4-stranger@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: user.token, json: { name: "Dev" } }),
      )
    ).id;
    const cred = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: user.token,
        json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-chrome4-key" },
      }),
    );
    botId = (
      await j(
        await h.request("/v1/bots", {
          method: "POST",
          token: user.token,
          json: {
            org_id: orgId,
            name: "Helper",
            autonomy: "autonomous",
            model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
          },
        }),
      )
    ).id;
    void extensionLoop();
  }, 120_000);
  afterAll(async () => {
    polling = false;
    await h?.stop();
    telegram?.close();
  });

  it("registers the browser as a web device: browser kinds only there, never stored", async () => {
    const saved = await j(
      await h.request(`/v1/device-sources/${KEY}`, {
        method: "PUT",
        token: user.token,
        json: {
          name: "Chrome",
          platform: "web",
          kinds: { browser_tab: { retention_days: 30 }, browser_history: {} },
        },
      }),
    );
    expect(saved.kinds.browser_tab.retention_days).toBe(0);
    expect(saved.kinds.browser_history.retention_days).toBe(0);
    const phone = await h.request("/v1/device-sources/chrome-phase4-phone", {
      method: "PUT",
      token: user.token,
      json: { name: "Phone", platform: "ios", kinds: { browser_tab: {} } },
    });
    expect(phone.status).toBe(400);
    expect((await j(phone)).code).toBe("kind_not_here");
  });

  it("grants for browser kinds are left out unless the app asks for every kind", async () => {
    const set = await j(
      await h.request("/v1/device-grants", {
        method: "PUT",
        token: user.token,
        json: { bot_id: botId, kind: "browser_tab", allowed: true },
      }),
    );
    expect(set.items.map((g: { kind: string }) => g.kind)).toEqual(["browser_tab"]);
    await h.request("/v1/device-grants", {
      method: "PUT",
      token: user.token,
      json: { bot_id: botId, kind: "browser_history", allowed: true },
    });
    await h.request("/v1/device-grants", {
      method: "PUT",
      token: user.token,
      json: { bot_id: botId, kind: "calendar", allowed: true },
    });
    // An app build that doesn't know the browser kinds must not see them (its enum is strict).
    const old = await j(await h.request("/v1/device-grants", { token: user.token }));
    expect(old.items.map((g: { kind: string }) => g.kind)).toEqual(["calendar"]);
    const all = await j(await h.request("/v1/device-grants?all_kinds=true", { token: user.token }));
    expect(all.items.map((g: { kind: string }) => g.kind).sort()).toEqual([
      "browser_history",
      "browser_tab",
      "calendar",
    ]);
  });

  it("a bot on Telegram answers what's on my screen from the browser, with the read in the timeline", async () => {
    answer = (r) =>
      r.kind === "browser_tab"
        ? {
            type: "tab",
            url: "https://wiki.example.com/releases",
            title: "Release notes · Team wiki",
            text: "Release 4.2 ships the new importer.",
          }
        : null;
    const ch = await j(
      await h.request("/v1/channels", {
        method: "POST",
        token: user.token,
        json: {
          bot_id: botId,
          kind: "telegram",
          name: "Telegram",
          config: { api_base: telegramApi },
          secrets: { bot_token: "123:abc" },
          allowed_senders: ["7"],
        },
      }),
    );
    const [s] = await h.tdb.admin<{ s: string }[]>`
      select v.decrypted_secret as s from public.channels c join vault.decrypted_secrets v on v.id = c.vault_secret_id where c.id = ${ch.id}`;
    const { webhook_secret } = JSON.parse(s!.s) as { webhook_secret: string };
    const hook = await h.request(`/hooks/channels/${ch.id}`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-telegram-bot-api-secret-token": webhook_secret,
      },
      body: JSON.stringify({
        update_id: 1,
        message: {
          text: "what's on my screen?",
          chat: { id: 70 },
          from: { id: 7, first_name: "Oli" },
        },
      }),
    });
    expect(hook.status).toBe(200);
    let runId = "";
    for (let i = 0; i < 50 && !runId; i++) {
      const [r] = await h.tdb.admin<{ id: string }[]>`
        select id from public.runs where bot_id = ${botId} and trigger = 'channel' order by created_at desc limit 1`;
      runId = r?.id ?? "";
      if (!runId) await new Promise((res) => setTimeout(res, 100));
    }
    const run = await settle(runId);
    expect(run.status).toBe("completed");
    const events = (
      await j(await h.request(`/v1/runs/${runId}/events?limit=200`, { token: user.token }))
    ).items as Array<{ type: string; payload: Record<string, unknown> }>;
    const used = events.find((e) => e.type === "device.data_used");
    expect(used?.payload).toMatchObject({ kind: "browser_tab", count: 1, devices: ["Chrome"] });
    const done = events.find((e) => e.type === "tool.completed");
    expect(done?.payload.result_preview).toBe("1 current browser tab items");
    // Live only: nothing of the tab was stored.
    expect(
      (await h.tdb.admin`select 1 from public.device_readings where kind like 'browser%'`).length,
    ).toBe(0);
  });

  it("finds a page in the browser's history on request", async () => {
    answer = (r) =>
      r.kind === "browser_history"
        ? {
            type: "history",
            query: String(r.params.query),
            items: [
              {
                url: "https://science.example/tides",
                title: "How tides work",
                source: "history",
                visited_at: new Date().toISOString(),
              },
            ],
          }
        : null;
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: user.token,
        json: { bot_id: botId },
      }),
    );
    const sent = await j(
      await h.request(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token: user.token,
        json: { text: "find the article about tides I read last week" },
      }),
    );
    expect((await settle(sent.run_id)).status).toBe("completed");
    const req = answered.find((r) => r.kind === "browser_history");
    expect(req?.params.query).toBe("tides");
    // The browser searches its own history: no one-day range is imposed (review).
    expect(req?.params.from).toBeUndefined();
    // Live only: the answer isn't kept once the bot has read it.
    const [kept] = await h.tdb.admin<{ result: unknown }[]>`
      select result from public.device_requests where id = ${req!.id}`;
    expect(kept?.result ?? null).toBeNull();
  });

  it("a bot asks for the browser with its own event, which older apps skip", async () => {
    const cred = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: user.token,
        json: { org_id: orgId, provider: "openrouter", label: "k2", api_key: "sk-chrome4-key2" },
      }),
    );
    const other = await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: user.token,
        json: {
          org_id: orgId,
          name: "Asker",
          autonomy: "autonomous",
          model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
        },
      }),
    );
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: user.token,
        json: { bot_id: other.id },
      }),
    );
    const sent = await j(
      await h.request(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token: user.token,
        json: { text: "can you look at my browser?" },
      }),
    );
    expect((await settle(sent.run_id)).status).toBe("completed");
    const events = (
      await j(await h.request(`/v1/runs/${sent.run_id}/events?limit=200`, { token: user.token }))
    ).items as Array<{ type: string; payload: Record<string, unknown> }>;
    expect(events.find((e) => e.type === "device.browser_access_requested")?.payload).toMatchObject(
      {
        kind: "browser_tab",
        bot_id: other.id,
      },
    );
    expect(events.some((e) => e.type === "device.access_requested")).toBe(false);
  });

  it("the desktop app's quick ask gets the tab through the server, and a clear error when the browser is away", async () => {
    answer = (r) =>
      r.kind === "browser_tab"
        ? { type: "tab", url: "https://news.example/a", title: "An article" }
        : null;
    const ok = await j(
      await h.request("/v1/device-requests", {
        method: "POST",
        token: user.token,
        json: { kind: "browser_tab" },
      }),
    );
    expect(ok).toMatchObject({ device: "Chrome", result: { url: "https://news.example/a" } });
    const none = await h.request("/v1/device-requests", {
      method: "POST",
      token: stranger.token,
      json: { kind: "browser_tab" },
    });
    expect(none.status).toBe(404);
    answer = null;
    const away = await h.request("/v1/device-requests", {
      method: "POST",
      token: user.token,
      json: { kind: "browser_tab" },
    });
    expect(away.status).toBe(409);
    expect((await j(away)).code).toBe("browser_offline");
    // Only the address and title are asked for, and nothing is kept.
    const quick = answered.filter((r) => r.kind === "browser_tab").at(-1);
    expect(quick?.params.brief).toBe(true);
    const [kept] = await h.tdb.admin<{ result: unknown }[]>`
      select result from public.device_requests where id = ${quick!.id}`;
    expect(kept?.result ?? null).toBeNull();
    // A browser kept to private models doesn't answer a quick ask, whose bot isn't known.
    await h.tdb.admin`
      update public.device_sources set kinds = jsonb_set(kinds, '{browser_tab,private_model}', 'true')
      where device_key = ${KEY}`;
    const priv = await h.request("/v1/device-requests", {
      method: "POST",
      token: user.token,
      json: { kind: "browser_tab" },
    });
    expect(priv.status).toBe(409);
    expect((await j(priv)).code).toBe("private_model_required");
    await h.tdb.admin`
      update public.device_sources set kinds = kinds #- '{browser_tab,private_model}' where device_key = ${KEY}`;
  }, 30_000);

  it("browser triggers: the team wiki starts its routine, a bank's site can't", async () => {
    const make = (site: string) =>
      h.request("/v1/routines", {
        method: "POST",
        token: user.token,
        json: {
          bot_id: botId,
          name: `When I open ${site}`,
          instructions: "Summarize what changed since yesterday.",
          trigger: "device",
          device: { event: "site_opened", site },
        },
      });
    const wiki = await make("https://wiki.example.com/home");
    expect(wiki.status).toBe(201);
    expect((await j(wiki)).device).toMatchObject({
      event: "site_opened",
      site: "wiki.example.com",
    });
    for (const bank of ["chase.com", "online.secure-bank.co", "app.casama.ai"]) {
      const r = await make(bank);
      expect(r.status, bank).toBe(400);
    }
    const report = (events: unknown[], key = KEY) =>
      h.request(`/v1/device-sources/${key}/events`, {
        method: "POST",
        token: user.token,
        json: { events },
      });
    const at = new Date().toISOString();
    const opened = await j(
      await report([
        { id: "o1", type: "site_opened", at, site: "docs.wiki.example.com" },
        { id: "o2", type: "site_opened", at, site: "chase.com" },
      ]),
    );
    expect(opened.runs).toBe(1);
    // The extension asks what to listen for: only the wiki.
    const watched = await j(await h.request("/v1/device-triggers/browser", { token: user.token }));
    expect(watched.items).toEqual([{ event: "site_opened", site: "wiki.example.com" }]);
    // Older apps parse device events strictly: the routine list leaves browser events out
    // unless the client asks for every event.
    const plain = await j(await h.request(`/v1/bots/${botId}/routines`, { token: user.token }));
    const mine = (x: { name: string }) => x.name === "When I open https://wiki.example.com/home";
    expect(plain.items.find(mine)).toMatchObject({ trigger: "device", device: null });
    const all = await j(
      await h.request(`/v1/bots/${botId}/routines?all_events=true`, { token: user.token }),
    );
    expect(all.items.find(mine)?.device).toMatchObject({ event: "site_opened" });
    // Opening the wiki again within the hour doesn't start it twice.
    expect(
      (await j(await report([{ id: "o3", type: "site_opened", at, site: "wiki.example.com" }])))
        .runs,
    ).toBe(0);
    // Browser events come only from the extension's device.
    await h.request("/v1/device-sources/chrome-phase4-mac", {
      method: "PUT",
      token: user.token,
      json: { name: "Mac", platform: "macos", kinds: {} },
    });
    expect(
      (
        await report(
          [{ id: "o4", type: "site_opened", at, site: "wiki.example.com" }],
          "chrome-phase4-mac",
        )
      ).status,
    ).toBe(400);
  });

  it("browser triggers never start (or bill) runs in a workspace the person has left", async () => {
    const mate = await h.user("chrome4-mate@example.com");
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${mate.id}, 'member')`;
    const made = await h.request("/v1/routines", {
      method: "POST",
      token: mate.token,
      json: {
        bot_id: botId,
        name: "When I open the board",
        instructions: "Summarize the board.",
        trigger: "device",
        device: { event: "site_opened", site: "board.example.com" },
      },
    });
    expect(made.status).toBe(201);
    const key = "chrome-phase4-mate";
    await h.request(`/v1/device-sources/${key}`, {
      method: "PUT",
      token: mate.token,
      json: { name: "Chrome", platform: "web", kinds: { browser_tab: {} } },
    });
    await h.tdb
      .admin`delete from public.memberships where org_id = ${orgId} and user_id = ${mate.id}`;
    const res = await h.request(`/v1/device-sources/${key}/events`, {
      method: "POST",
      token: mate.token,
      json: {
        events: [
          {
            id: "m1",
            type: "site_opened",
            at: new Date().toISOString(),
            site: "board.example.com",
          },
        ],
      },
    });
    expect(res.status).toBe(200);
    expect((await j(res)).runs).toBe(0);
    const [row] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.runs where org_id = ${orgId} and created_by = ${mate.id}`;
    expect(row?.n).toBe(0);
  });

  it("tells the extension whether a bot's models are all private (the private model rule)", async () => {
    const r = await j(await h.request(`/v1/bots/${botId}/model-privacy`, { token: user.token }));
    expect(r).toEqual({ private_model: false });
    expect(
      (await h.request(`/v1/bots/${botId}/model-privacy`, { token: stranger.token })).status,
    ).toBe(404);
  });
});
