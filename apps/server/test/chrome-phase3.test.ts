/**
 * Casama for Chrome, Phase 3 (D-323): bots in the person's own browser. A fake browser device stands
 * in for the extension on the device WebSocket; the real worker runs browser tools against it.
 * (The extension's side, against real pages, is apps/extension/e2e/phase3.spec.ts.)
 */
import { checkWatchers } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { WebSocket } from "ws";
import { internalToken } from "../src/api/routes/local.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = new URL("./fixtures/chrome-phase3.json", import.meta.url).pathname;

type Call = {
  action: string;
  args: Record<string, unknown>;
  run?: { id: string; bot_name: string };
  watcher?: { id: string };
  policy?: Record<string, unknown>;
};

/** A stand-in for the extension: answers browser calls over the device socket. */
async function fakeBrowser(serverUrl: string, token: string, answer: (c: Call) => unknown) {
  const calls: Call[] = [];
  const ws = new WebSocket(`${serverUrl.replace("http", "ws")}/v1/local-computer/connect`, {
    headers: { authorization: `Device ${token}` },
  });
  await new Promise<void>((resolve, reject) => {
    ws.once("message", () => resolve());
    ws.once("unexpected-response", (_q, r) => reject(new Error(`refused ${r.statusCode}`)));
    ws.once("error", reject);
  });
  ws.on("message", (raw) => {
    const m = JSON.parse(String(raw)) as { type: string; id: string; body?: string };
    if (m.type !== "request") return;
    const call = JSON.parse(Buffer.from(m.body ?? "", "base64").toString()) as Call;
    calls.push(call);
    const body = Buffer.from(JSON.stringify(answer(call))).toString("base64");
    ws.send(JSON.stringify({ type: "response", id: m.id, status: 200, headers: {} }));
    ws.send(JSON.stringify({ type: "chunk", id: m.id, data: body }));
    ws.send(JSON.stringify({ type: "end", id: m.id }));
  });
  return {
    calls,
    // Closing twice (a test closes it, then the cleanup does) mustn't wait for a second "close".
    close: () =>
      ws.readyState === ws.CLOSED
        ? Promise.resolve()
        : new Promise<void>((r) => (ws.once("close", () => r()), ws.close())),
  };
}

type Ans = { ok?: boolean; code?: string };
describe("Casama for Chrome Phase 3: your own browser", () => {
  let h: Harness;
  let owner: { id: string; token: string };
  let member: { id: string; token: string };
  let orgId: string;
  let botId: string;
  let device: { id: string; token: string; computer_id: string | null };
  let browser: Awaited<ReturnType<typeof fakeBrowser>>;
  let page = "Price: $40.00";
  let internal: string;

  const settle = async (token: string, runId: string) => {
    for (let i = 0; i < 300; i++) {
      const r = await j(await h.request(`/v1/runs/${runId}`, { token }));
      if (["completed", "failed", "waiting_approval"].includes(r.status)) return r;
      await new Promise((res) => setTimeout(res, 200));
    }
    throw new Error("run did not settle");
  };
  const chat = async (token: string, text: string, sourceUrl?: string) => {
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token,
        json: { bot_id: botId, ...(sourceUrl ? { source_url: sourceUrl } : {}) },
      }),
    );
    const sent = await j(
      await h.request(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token,
        json: { text },
      }),
    );
    return sent.run_id as string;
  };
  const callInternal = (body: Record<string, unknown>) =>
    fetch(`${h.serverUrl}/internal/browser/${device.id}/call`, {
      method: "POST",
      headers: { "x-casama-internal": internal, "content-type": "application/json" },
      body: JSON.stringify(body),
    });

  beforeAll(async () => {
    h = await startHarness({ worker: { fixtures: FIXTURES }, local: true });
    internal = internalToken(h.deps.env);
    owner = await h.user("chrome3-owner@example.com");
    member = await h.user("chrome3-member@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Act" } }),
      )
    ).id;
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
    const cred = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-chrome3-key" },
      }),
    );
    botId = (
      await j(
        await h.request("/v1/bots", {
          method: "POST",
          token: owner.token,
          json: {
            org_id: orgId,
            name: "Shopper",
            autonomy: "autonomous",
            model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
          },
        }),
      )
    ).id;
  }, 120_000);
  afterAll(async () => {
    await browser?.close().catch(() => {});
    await h?.stop();
  });

  it("pairs a browser-only device: no computer, browser only, and a bot let in", async () => {
    const res = await h.request("/v1/local-devices", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, name: "Chrome on my Mac", platform: "chrome" },
    });
    expect(res.status).toBe(201);
    device = await j(res);
    expect(device.computer_id).toBeNull();
    expect((device as unknown as { capabilities: unknown }).capabilities).toEqual({
      browser: true,
    });
    const upd = await j(
      await h.request(`/v1/local-devices/${device.id}`, {
        method: "PATCH",
        token: owner.token,
        json: {
          allowed_bot_ids: [botId],
          allowed_sites: ["https://www.Shop.example/orders"],
          blocked_sites: ["ads.example"],
        },
      }),
    );
    expect(upd).toMatchObject({
      allowed_sites: ["shop.example"],
      blocked_sites: ["ads.example"],
      online: false,
    });
    expect(
      (
        await h.request(`/v1/local-devices/${device.id}`, {
          method: "PATCH",
          token: owner.token,
          json: { allowed_sites: ["not a site"] },
        })
      ).status,
    ).toBe(400);
    let url = "about:blank";
    browser = await fakeBrowser(h.serverUrl as string, device.token, (c) => {
      if (c.action === "open") url = String(c.args.url);
      if (c.action === "snapshot")
        return { ok: true, text: '- link "Orders" [ref=e1]\n- button "Order #1042" [ref=e2]', url };
      if (c.action === "read")
        return { ok: true, text: "Order #1042: Blue kettle. Shipped yesterday.", url };
      if (c.action === "page_text")
        return { ok: true, text: `Blue kettle. ${page}. Free delivery.`, url: c.args.url };
      if (c.action === "url") return { ok: true, text: url, url };
      return { ok: true, text: `${c.action} done`, url };
    });
    const list = await j(
      await h.request(`/v1/local-devices?org_id=${orgId}`, { token: owner.token }),
    );
    expect(list.items.find((d: { id: string }) => d.id === device.id)?.online).toBe(true);
  });

  it("a bot finishes a task in the person's browser, signed in, from a chat started there", async () => {
    const runId = await chat(owner.token, "Please check my last order", "https://shop.example/");
    const run = await settle(owner.token, runId);
    const evs = (
      await j(await h.request(`/v1/runs/${runId}/events?limit=200`, { token: owner.token }))
    ).items as Array<{ type: string; payload: unknown }>;
    expect(
      run.status,
      JSON.stringify(evs.filter((e) => /tool|failed/.test(e.type)).map((e) => [e.type, e.payload])),
    ).toBe("completed");
    expect(browser.calls.map((c) => c.action)).toEqual(["open", "snapshot", "click", "read"]);
    // Each call says who's asking and carries the browser's site lists.
    expect(browser.calls[0]).toMatchObject({
      args: { url: "https://shop.example/orders" },
      run: { id: runId, bot_name: "Shopper" },
      policy: { allowed_sites: ["shop.example"], blocked_sites: ["ads.example"] },
    });
    const [audit] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.audit_log where action = 'browser.click' and target_id = ${device.id}`;
    expect(audit?.n).toBe(1);
  }, 60_000);

  it("refuses Casama's own pages, someone else's runs and blocked workspaces", async () => {
    const before = browser.calls.length;
    const runId = await chat(
      owner.token,
      "Please open the approvals page",
      "https://shop.example/",
    );
    await settle(owner.token, runId);
    expect(browser.calls.length).toBe(before);
    const events = (
      await j(await h.request(`/v1/runs/${runId}/events?limit=200`, { token: owner.token }))
    ).items as Array<{
      type: string;
      payload: Record<string, unknown>;
    }>;
    expect(
      JSON.stringify(events.filter((e) => e.type === "tool.completed" || e.type === "tool.failed")),
    ).toMatch(/Casama's own pages/);

    // Another member's run with the same bot can't reach the owner's browser (owner only).
    const theirs = (
      await h.tdb.admin<{ id: string }[]>`
        insert into public.runs (org_id, bot_id, trigger, status, created_by)
        values (${orgId}, ${botId}, 'chat', 'running', ${member.id}) returning id`
    )[0]!.id;
    const denied = await callInternal({ action: "read", args: {}, run_id: theirs });
    expect(denied.status).toBe(403);
    expect(((await denied.json()) as Ans).code).toBe("not_your_browser");
    const mine = (
      await h.tdb.admin<{ id: string }[]>`
        insert into public.runs (org_id, bot_id, trigger, status, created_by)
        values (${orgId}, ${botId}, 'chat', 'running', ${owner.id}) returning id`
    )[0]!.id;
    const casama = await callInternal({
      action: "open",
      args: { url: "https://app.casama.ai/rules" },
      run_id: mine,
    });
    expect(((await casama.json()) as Ans).code).toBe("refused");
    const chromePage = await callInternal({
      action: "open",
      args: { url: "chrome://settings" },
      run_id: mine,
    });
    expect(((await chromePage.json()) as Ans).code).toBe("refused");

    // The workspace turns Act off: calls stop, and no new browser can pair.
    await h.request(`/v1/orgs/${orgId}/settings`, {
      method: "PATCH",
      token: owner.token,
      json: { chrome_act: false },
    });
    const off = await callInternal({ action: "read", args: {}, run_id: mine });
    expect(((await off.json()) as Ans).code).toBe("act_off");
    expect(
      (
        await h.request("/v1/local-devices", {
          method: "POST",
          token: owner.token,
          json: { org_id: orgId, name: "Another Chrome", platform: "chrome" },
        })
      ).status,
    ).toBe(403);
    const settings = await j(await h.request(`/v1/orgs/${orgId}/settings`, { token: owner.token }));
    expect(settings).toMatchObject({ chrome_act: false, chrome_extension: true });
    await h.request(`/v1/orgs/${orgId}/settings`, {
      method: "PATCH",
      token: owner.token,
      json: { chrome_act: true, chrome_blocked_sites: ["https://Bank.example/login"] },
    });
    const ok = await callInternal({ action: "read", args: {}, run_id: mine });
    expect(((await ok.json()) as Ans).ok).toBe(true);
    expect(browser.calls.at(-1)?.policy).toMatchObject({
      blocked_sites: ["bank.example", "ads.example"],
    });
  }, 60_000);

  it("a watcher on a signed-in page is checked in the person's browser, and waits while it's offline", async () => {
    const res = await h.request("/v1/watchers", {
      method: "POST",
      token: owner.token,
      json: {
        bot_id: botId,
        name: "Kettle price",
        url: "https://shop.example/kettle",
        anchor: "Blue kettle",
        where: "mine",
      },
    });
    expect(res.status).toBe(201);
    const w = await j(res);
    expect(w.target).toMatchObject({ where: "mine", offline: "wait" });
    const started: string[] = [];
    const deps = {
      db: h.handle.db,
      fetch,
      startRun: async (id: string) => void started.push(id),
      local: { apiUrl: h.serverUrl as string, internalToken: internal },
    };
    const t0 = Date.now() + 1000;
    await checkWatchers(deps, new Date(t0));
    page = "Price: $35.00";
    await checkWatchers(deps, new Date(t0 + 61 * 60_000));
    expect(started).toHaveLength(1);
    expect(browser.calls.filter((c) => c.action === "page_text").at(-1)).toMatchObject({
      watcher: { id: w.id },
    });

    await browser.close();
    page = "Price: $30.00";
    await checkWatchers(deps, new Date(t0 + 122 * 60_000));
    expect(started).toHaveLength(1);
    const [row] = await h.tdb.admin<
      { last_error: string }[]
    >`select last_error from public.watchers where id = ${w.id}`;
    expect(row?.last_error).toMatch(/offline/);
    const offline = await j(
      await h.request(`/v1/local-devices?org_id=${orgId}`, { token: owner.token }),
    );
    expect(offline.items.find((d: { id: string }) => d.id === device.id)?.online).toBe(false);
  }, 60_000);

  it("a task taught in the browser becomes a draft and a replay that runs in the browser", async () => {
    const s = await j(
      await h.request("/v1/teach", {
        method: "POST",
        token: owner.token,
        json: { device_id: device.id, bot_id: botId },
      }),
    );
    expect(s).toMatchObject({ device_id: device.id, computer_id: null, status: "recording" });
    const step = (json: Record<string, unknown>) =>
      h.request(`/v1/teach/${s.id}/steps`, { method: "POST", token: owner.token, json });
    await step({ kind: "open", url: "https://wiki.example/new" });
    await step({
      kind: "type",
      text: "Weekly notes",
      target: { role: "textbox", name: "Title" },
      url: "https://wiki.example/new",
    });
    const pw = await j(
      await step({
        kind: "type",
        text: "hunter2",
        password: true,
        target: { role: "textbox", name: "Password" },
      }),
    );
    expect(pw).toMatchObject({ text: null, password: true, secret_name: "PASSWORD" });
    await step({
      kind: "click",
      target: { role: "button", name: "Publish" },
      url: "https://wiki.example/new",
    });
    const replay = await j(
      await h.request(`/v1/teach/${s.id}/replay`, {
        method: "POST",
        token: owner.token,
        json: { name: "weekly-notes" },
      }),
    );
    expect(replay.steps.map((x: { tool: string }) => x.tool)).toEqual([
      "browser.open",
      "browser.fill",
      "browser.fill",
      "browser.click",
    ]);
    const [stored] = await h.tdb.admin<
      { steps: Array<{ args: Record<string, unknown>; target?: unknown }> }[]
    >`
      select steps from public.replays where id = ${replay.id}`;
    expect(stored?.steps[0]?.args).toMatchObject({
      url: "https://wiki.example/new",
      where: "mine",
    });
    expect(stored?.steps[2]?.args.text).toBe("{{secret:PASSWORD}}");
    expect(stored?.steps[3]?.target).toEqual({ role: "button", name: "Publish" });
  });

  it("a routine edited by another member goes back to the bot's computer (review)", async () => {
    const r = await j(
      await h.request("/v1/routines", {
        method: "POST",
        token: owner.token,
        json: {
          bot_id: botId,
          name: "Check my orders",
          instructions: "Look at my orders on the shop.",
          schedule_cron: "0 9 * * *",
          browser: "mine",
        },
      }),
    );
    expect(r.browser).toBe("mine");
    const patch = (token: string, json: Record<string, unknown>) =>
      h.request(`/v1/routines/${r.id}`, { method: "PATCH", token, json });
    // Another member can't point it at the owner's browser...
    expect((await patch(member.token, { browser: "mine" })).status).toBe(400);
    // ...and any edit of theirs takes it off the owner's browser.
    const edited = await j(await patch(member.token, { instructions: "Use my browser." }));
    expect(edited.browser).toBe("computer");
    const [row] = await h.tdb.admin<{ edited_by_other: boolean }[]>`
      select edited_by_other from public.routines where id = ${r.id}`;
    expect(row?.edited_by_other).toBe(true);
    // The owner can turn it back on.
    const back = await j(await patch(owner.token, { browser: "mine" }));
    expect(back.browser).toBe("mine");
    const [after] = await h.tdb.admin<{ edited_by_other: boolean }[]>`
      select edited_by_other from public.routines where id = ${r.id}`;
    expect(after?.edited_by_other).toBe(false);
  });
});
