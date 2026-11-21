/**
 * The browser inside the phone app (docs/PHONE-BROWSER-PLAN.md). A fake phone stands in for the app
 * on the device WebSocket and answers as the page script would; the real API tunnel and the real
 * worker run against it. (The page script itself is tested in packages/page-agent.)
 */
import { resetAppBrowserCache } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { WebSocket } from "ws";
import { internalToken } from "../src/api/routes/local.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = new URL("./fixtures/app-browser.json", import.meta.url).pathname;

type Call = {
  action: string;
  args: Record<string, unknown>;
  run?: { id: string; bot_name: string };
  policy?: Record<string, unknown>;
  expect?: string;
};

/** A stand-in for the phone app: answers browser calls over the device socket. */
async function fakePhone(serverUrl: string, token: string, answer: (c: Call) => unknown) {
  const calls: Call[] = [];
  let closed: number | null = null;
  const ws = new WebSocket(`${serverUrl.replace("http", "ws")}/v1/local-computer/connect`, {
    headers: { authorization: `Device ${token}`, "x-casama-os": "Android 16" },
  });
  await new Promise<void>((resolve, reject) => {
    ws.once("message", () => resolve());
    ws.once("unexpected-response", (_q, r) => reject(new Error(`refused ${r.statusCode}`)));
    ws.once("error", reject);
  });
  ws.on("close", (code) => {
    closed = code;
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
    closedWith: () => closed,
    close: () =>
      ws.readyState === ws.CLOSED
        ? Promise.resolve()
        : new Promise<void>((r) => (ws.once("close", () => r()), ws.close())),
  };
}

const CLIENT = "phone-client-0001";
type Ans = { ok?: boolean; code?: string; text?: string; message?: string };

describe("the browser inside the phone app", () => {
  let h: Harness;
  let owner: { id: string; token: string };
  let member: { id: string; token: string };
  let orgId: string;
  let botId: string;
  let device: { id: string; token: string; computer_id: string | null; system?: string };
  let phone: Awaited<ReturnType<typeof fakePhone>>;
  let internal: string;
  /** What the page says about each ref, as packages/page-agent's `probe` would. */
  const facts: Record<string, Record<string, unknown>> = {
    e1: { role: "button", name: "Add to basket", host: "shop.example" },
    e2: { role: "button", name: "Send message", host: "shop.example" },
    e3: { role: "button", name: "Buy now", host: "shop.example" },
    e4: { role: "textbox", name: "Password", inputType: "password", host: "shop.example" },
    e5: { role: "textbox", name: "Note", inputType: "text", host: "shop.example" },
  };
  let answerAsk = "deny";
  let url = "about:blank";
  let pageText = "Basket: Blue kettle";

  const settle = async (token: string, runId: string) => {
    for (let i = 0; i < 300; i++) {
      const r = await j(await h.request(`/v1/runs/${runId}`, { token }));
      if (["completed", "failed", "waiting_approval"].includes(r.status)) return r;
      await new Promise((res) => setTimeout(res, 200));
    }
    throw new Error("run did not settle");
  };
  /** A conversation that is (or isn't) open on the phone, then a message in it. */
  const chat = async (who: { id: string; token: string }, text: string, onScreen = true) => {
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: who.token,
        json: { bot_id: botId },
      }),
    );
    if (onScreen) await focus(who.id, conv.id);
    const sent = await j(
      await h.request(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token: who.token,
        json: { text },
      }),
    );
    return { runId: sent.run_id as string, conversationId: conv.id as string };
  };
  const focus = (userId: string, conversationId: string | null, client = CLIENT) =>
    h.tdb.admin`
      insert into public.chat_focus (user_id, client_id, conversation_id, updated_at)
      values (${userId}, ${client}, ${conversationId}, now())
      on conflict (user_id, client_id) do update
        set conversation_id = excluded.conversation_id, updated_at = now()`;
  const callInternal = async (body: Record<string, unknown>) => {
    const res = await fetch(`${h.serverUrl}/internal/browser/${device.id}/call`, {
      method: "POST",
      headers: { "x-casama-internal": internal, "content-type": "application/json" },
      body: JSON.stringify(body),
    });
    return { status: res.status, body: (await res.json()) as Ans };
  };
  const stage = (json: Record<string, unknown>, token = owner.token) =>
    h.request("/v1/admin/app-browser", { method: "PUT", token, json });
  const state = async (token: string, system = "android") =>
    j(
      await h.request(`/v1/app-browser?org_id=${orgId}&system=${system}&client_id=${CLIENT}`, {
        token,
      }),
    );
  const pair = (token: string, client = CLIENT) =>
    h.request("/v1/local-devices", {
      method: "POST",
      token,
      json: {
        org_id: orgId,
        name: "My phone",
        platform: "app",
        system: "android",
        client_id: client,
      },
    });

  beforeAll(async () => {
    resetAppBrowserCache();
    h = await startHarness({ worker: { fixtures: FIXTURES }, local: true });
    internal = internalToken(h.deps.env);
    owner = await h.user("phone-owner@example.com");
    member = await h.user("phone-member@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Phones" },
        }),
      )
    ).id;
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
    const cred = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-phone-key" },
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
    await phone?.close().catch(() => {});
    await h?.stop();
    resetAppBrowserCache();
  });

  it("is off until the owner switches it on: no pairing, and the app is told why", async () => {
    expect(await state(owner.token)).toMatchObject({
      available: false,
      reason: "off",
      device: null,
    });
    const res = await pair(owner.token);
    expect(res.status).toBe(403);
    expect((await j(res)).code).toBe("app_browser_off");
  });

  it("only the instance owner changes the stage, and a typo can't switch it on", async () => {
    expect((await stage({ stage: "on", systems: ["android"] }, member.token)).status).toBe(403);
    expect((await stage({ stage: "on", systems: ["windows"] })).status).toBe(400);
    expect((await stage({ stage: "everyone" })).status).toBe(400);
    expect((await stage({ stage: "on", sytems: ["android"] })).status).toBe(400);
    const saved = await j(await stage({ stage: "testers", testers: [owner.id] }));
    expect(saved.settings).toMatchObject({
      stage: "testers",
      testers: [owner.id],
      reasons: { asked: true, blocked: false, signed_in: false },
    });
    expect(await state(owner.token)).toMatchObject({ available: true, reason: null });
    expect(await state(member.token)).toMatchObject({ available: false, reason: "not_a_tester" });
    expect((await pair(member.token, "member-client-01")).status).toBe(403);
  });

  it("pairs one browser per app install, hidden from apps that don't ask for it", async () => {
    // A phone browser needs to say which install it is.
    expect(
      (
        await h.request("/v1/local-devices", {
          method: "POST",
          token: owner.token,
          json: { org_id: orgId, name: "My phone", platform: "app" },
        })
      ).status,
    ).toBe(400);
    const first = await j(await pair(owner.token));
    expect(first).toMatchObject({ platform: "app", system: "android", computer_id: null });
    expect(first.capabilities).toEqual({ browser: true });
    // Pairing again from the same install keeps the row and replaces the token.
    const res = await pair(owner.token);
    expect(res.status).toBe(201);
    device = await j(res);
    expect(device.id).toBe(first.id);
    expect(device.token).not.toBe(first.token);
    await j(
      await h.request(`/v1/local-devices/${device.id}`, {
        method: "PATCH",
        token: owner.token,
        json: { allowed_bot_ids: [botId], blocked_sites: ["ads.example"] },
      }),
    );
    // Older apps read `platform` strictly, so they never see this row.
    const old = await j(
      await h.request(`/v1/local-devices?org_id=${orgId}`, { token: owner.token }),
    );
    expect(old.items.some((d: { id: string }) => d.id === device.id)).toBe(false);
    const all = await j(
      await h.request(`/v1/local-devices?org_id=${orgId}&all_platforms=true`, {
        token: owner.token,
      }),
    );
    expect(all.items.find((d: { id: string }) => d.id === device.id)).toMatchObject({
      platform: "app",
      system: "android",
    });
    expect((await state(owner.token)).device).toMatchObject({ id: device.id });

    phone = await fakePhone(h.serverUrl as string, device.token, (c) => {
      if (c.action === "open") url = String(c.args.url);
      if (c.action === "probe") {
        const f = c.args.focused ? facts.e5 : facts[String(c.args.ref).replace("@", "")];
        if (!f) return { ok: false, code: "stale_ref", message: "That ref is gone" };
        return { ok: true, text: JSON.stringify({ facts: f, fingerprint: `fp-${f.name}` }) };
      }
      if (c.action === "ask") return { ok: true, text: answerAsk };
      if (c.action === "handoff") return { ok: true, text: "shown" };
      if (c.action === "snapshot")
        return { ok: true, text: '- button "Add to basket" [ref=e1]', url };
      if (c.action === "read") return { ok: true, text: pageText, url };
      return { ok: true, text: `${c.action} done`, url };
    });
  });

  it("works only while the person's own chat is open on that phone", async () => {
    const away = await chat(owner, "hello", false);
    await settle(owner.token, away.runId);
    const before = phone.calls.length;
    const no = await callInternal({
      action: "open",
      args: { url: "https://shop.example/" },
      run_id: away.runId,
    });
    expect(no).toMatchObject({ status: 409, body: { ok: false, code: "away" } });
    // The same chat open on another of their devices doesn't count.
    await focus(owner.id, away.conversationId, "desktop-client-01");
    expect(
      (
        await callInternal({
          action: "open",
          args: { url: "https://shop.example/" },
          run_id: away.runId,
        })
      ).body.code,
    ).toBe("away");
    expect(phone.calls.length).toBe(before);

    await focus(owner.id, away.conversationId);
    const yes = await callInternal({
      action: "open",
      args: { url: "https://shop.example/" },
      run_id: away.runId,
    });
    expect(yes.body).toMatchObject({ ok: true });
    expect(phone.calls.at(-1)).toMatchObject({
      action: "open",
      run: { id: away.runId, bot_name: "Shopper" },
      policy: { blocked_sites: ["ads.example"] },
    });
    // Casama's own pages are refused before the phone hears of them.
    const n = phone.calls.length;
    expect(
      (
        await callInternal({
          action: "open",
          args: { url: "https://casama.ai/" },
          run_id: away.runId,
        })
      ).body.code,
    ).toBe("refused");
    expect(phone.calls.length).toBe(n);

    // A teammate's run, a routine's run and a watcher never reach it.
    const theirs = await chat(member, "hello", false);
    await settle(member.token, theirs.runId);
    expect((await callInternal({ action: "read", args: {}, run_id: theirs.runId })).body.code).toBe(
      "not_your_browser",
    );
    await h.tdb.admin`update public.runs set trigger = 'routine' where id = ${away.runId}`;
    expect((await callInternal({ action: "read", args: {}, run_id: away.runId })).body.code).toBe(
      "not_a_chat",
    );
    await h.tdb.admin`update public.runs set trigger = 'chat' where id = ${away.runId}`;
  }, 60_000);

  it("runs the step rules on the server: ask, hand over, or go ahead", async () => {
    const { runId } = await chat(owner, "hello");
    await settle(owner.token, runId);
    const step = (action: string, args: Record<string, unknown>) =>
      callInternal({ action, args, run_id: runId });
    const sent = () => phone.calls.map((c) => c.action);

    // No console or network on a phone.
    expect((await step("console", {})).body).toMatchObject({ ok: false, code: "unsupported" });

    // An ordinary click: the page is asked what it is, then the click goes with its fingerprint.
    let n = phone.calls.length;
    expect((await step("click", { ref: "e1" })).body).toMatchObject({ ok: true });
    expect(sent().slice(n)).toEqual(["probe", "click"]);
    expect(phone.calls.at(-1)?.expect).toBe("fp-Add to basket");

    // A click that sends something asks the person first; "no" means the click never happens.
    n = phone.calls.length;
    answerAsk = "deny";
    expect((await step("click", { ref: "e2" })).body).toMatchObject({
      ok: false,
      code: "asked_denied",
    });
    expect(sent().slice(n)).toEqual(["probe", "ask"]);
    expect(phone.calls.at(-1)?.args).toMatchObject({ step: "click", name: "Send message" });
    answerAsk = "allow";
    n = phone.calls.length;
    expect((await step("click", { ref: "e2" })).body).toMatchObject({ ok: true });
    expect(sent().slice(n)).toEqual(["probe", "ask", "click"]);
    // Anything but a clear "allow" is a no (a timeout, a closed sheet).
    answerAsk = "timeout";
    expect((await step("click", { ref: "e2" })).body.code).toBe("asked_denied");

    // A purchase and a password are the person's to do: never asked, never sent.
    n = phone.calls.length;
    expect((await step("click", { ref: "e3" })).body).toMatchObject({
      ok: false,
      code: "handed_off",
    });
    expect((await step("fill", { ref: "e4", text: "hunter2" })).body.code).toBe("handed_off");
    expect(
      sent()
        .slice(n)
        .filter((a) => a === "click" || a === "fill" || a === "ask"),
    ).toEqual([]);

    // A ref the page no longer knows comes back as the page said it.
    expect((await step("click", { ref: "e99" })).body).toMatchObject({
      ok: false,
      code: "stale_ref",
    });

    // Text read on one site and typed into another asks (the cross-site check).
    url = "https://mail.example/inbox";
    pageText = "Your code is QK-88123-ALPHA-BRAVO-7731, keep it safe.";
    expect((await step("read", {})).body).toMatchObject({ ok: true });
    answerAsk = "deny";
    n = phone.calls.length;
    const carried = await step("fill", { ref: "e5", text: "QK-88123-ALPHA-BRAVO-7731" });
    expect(carried.body.code).toBe("asked_denied");
    expect(phone.calls.at(-1)?.args.reason).toContain("mail.example");
    // The same field takes ordinary text without asking.
    n = phone.calls.length;
    expect((await step("fill", { ref: "e5", text: "Leave it by the door" })).body.ok).toBe(true);
    expect(sent().slice(n)).toEqual(["probe", "fill"]);
    // Uploads always ask.
    answerAsk = "allow";
    n = phone.calls.length;
    await step("upload", {
      ref: "e5",
      file: { name: "a.txt", media_type: "text/plain", data: "" },
    });
    expect(sent().slice(n)).toEqual(["probe", "ask", "upload"]);

    const rows = await h.tdb.admin<{ action: string; n: number }[]>`
      select action, count(*)::int as n from public.audit_log
      where target_id = ${device.id} group by action`;
    const by = Object.fromEntries(rows.map((r) => [r.action, r.n]));
    expect(by["browser.step_denied"]).toBe(3);
    expect(by["browser.step_handed_off"]).toBe(2);
    expect(by["browser.click"]).toBe(2);
  }, 60_000);

  it("a bot asked to do it on the phone works there, through the real worker", async () => {
    answerAsk = "allow";
    const before = phone.calls.length;
    const { runId } = await chat(owner, "Add the kettle to my basket on my phone");
    const run = await settle(owner.token, runId);
    const evs = (
      await j(await h.request(`/v1/runs/${runId}/events?limit=200`, { token: owner.token }))
    ).items as Array<{ type: string; payload: unknown }>;
    expect(
      run.status,
      JSON.stringify(evs.filter((e) => /tool|failed/.test(e.type)).map((e) => [e.type, e.payload])),
    ).toBe("completed");
    expect(phone.calls.slice(before).map((c) => c.action)).toEqual([
      "open",
      "snapshot",
      "probe",
      "click",
    ]);
    expect(phone.calls[before]).toMatchObject({ args: { url: "https://shop.example/basket" } });
  }, 60_000);

  it("a chat that isn't on the phone's screen never reaches it", async () => {
    const before = phone.calls.length;
    const { runId } = await chat(owner, "Add the kettle to my basket on my phone", false);
    await settle(owner.token, runId);
    expect(phone.calls.length).toBe(before);
    const evs = (
      await j(await h.request(`/v1/runs/${runId}/events?limit=200`, { token: owner.token }))
    ).items as Array<{ type: string; payload: unknown }>;
    expect(JSON.stringify(evs)).toContain("browser_offline");
  }, 60_000);

  it("shows the owner the numbers, and going back to Off drops the phone at once", async () => {
    const admin = await j(await h.request("/v1/admin/app-browser?days=7", { token: owner.token }));
    expect(admin.numbers).toMatchObject({ days: 7, phones_paired: 1, phone_people: 1 });
    expect(admin.numbers.phone_runs).toBeGreaterThanOrEqual(2);
    expect(admin.numbers.refused_steps).toBe(5);
    expect((await h.request("/v1/admin/app-browser", { token: member.token })).status).toBe(403);

    // The workspace's own switch turns it off for its members.
    await h.request(`/v1/orgs/${orgId}/settings`, {
      method: "PATCH",
      token: owner.token,
      json: { app_browser: false },
    });
    expect(await state(owner.token)).toMatchObject({ available: false, reason: "workspace_off" });
    await h.request(`/v1/orgs/${orgId}/settings`, {
      method: "PATCH",
      token: owner.token,
      json: { app_browser: true },
    });

    await stage({ stage: "off" });
    for (let i = 0; i < 50 && phone.closedWith() === null; i++)
      await new Promise((r) => setTimeout(r, 100));
    expect(phone.closedWith()).toBe(4001);
    await expect(fakePhone(h.serverUrl as string, device.token, () => ({}))).rejects.toThrow(
      "refused 403",
    );
    expect(await state(owner.token)).toMatchObject({ available: false, reason: "off" });
  }, 60_000);
});
