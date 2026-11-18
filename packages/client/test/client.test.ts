import { describe, expect, it } from "vitest";
import { CasamaError, createCasamaClient, type RunEvent } from "../src/index.ts";
import { readSse } from "../src/sse.ts";

const BOT = "5d0c1e6a-8b7f-4e8a-a1d2-3c4b5a6f7e80";
const CONV = "11111111-1111-4111-8111-111111111111";
const RUN = "0b9e7c52-1f0a-4a4e-9d2c-6f3f1b0d8a11";
const MSG = "22222222-2222-4222-8222-222222222222";
const APPROVAL = "33333333-3333-4333-8333-333333333333";

type Handler = (req: Request) => Response | Promise<Response>;

/** A fetch that answers from `routes` ("METHOD /path") and records every request. */
function mockFetch(routes: Record<string, Handler | Handler[]>) {
  const calls: Request[] = [];
  const fetch = async (input: string | URL | Request, init?: RequestInit) => {
    const req = input instanceof Request ? input : new Request(input, init);
    calls.push(req);
    const url = new URL(req.url);
    const key = `${req.method} ${url.pathname}`;
    const route = routes[key];
    const handler = Array.isArray(route) ? (route.length > 1 ? route.shift() : route[0]) : route;
    if (!handler) return problem(404, "not_found", `No mock for ${key}`);
    return handler(req);
  };
  return { fetch: fetch as typeof globalThis.fetch, calls };
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

const problem = (
  status: number,
  code: string,
  detail?: string,
  headers: Record<string, string> = {},
) =>
  new Response(
    JSON.stringify({
      type: `https://casama.ai/problems/${code}`,
      title: "Error",
      status,
      code,
      detail,
      instance: "/v1/x",
    }),
    {
      status,
      headers: { "content-type": "application/problem+json", "x-request-id": "req-1", ...headers },
    },
  );

let seq = 0;
const ev = (type: string, payload: Record<string, unknown>) =>
  ({
    v: 1,
    run_id: RUN,
    seq: ++seq,
    ts: "2026-11-15T00:00:00.000Z",
    bot_id: BOT,
    type,
    payload,
  }) as RunEvent;

const run = (status: string) => ({
  id: RUN,
  bot_id: BOT,
  conversation_id: CONV,
  parent_run_id: null,
  trigger: "message",
  status,
  tokens_in: 10,
  tokens_out: 5,
  cost_usd: 0.001,
  last_seq: seq,
  started_at: null,
  ended_at: null,
  error: null,
  trace_id: null,
  created_at: "2026-11-15T00:00:00.000Z",
});

const sse = (events: RunEvent[], extra = "") =>
  new Response(
    events.map((e) => `event: run_event\ndata: ${JSON.stringify(e)}\nid: ${e.seq}\n\n`).join("") +
      extra,
    { headers: { "content-type": "text/event-stream" } },
  );

function replyEvents() {
  seq = 0;
  return [
    ev("run.started", { trigger: "message", model: "m", computer_id: null }),
    ev("message.delta", { message_id: MSG, text: "Hel" }),
    ev("message.delta", { message_id: MSG, text: "lo" }),
    ev("message.completed", { message_id: MSG, content: [{ type: "text", text: "Hello" }] }),
    ev("run.completed", { final_message_id: MSG }),
  ];
}

describe("auth", () => {
  it("sends a fixed token as a bearer token", async () => {
    const m = mockFetch({ "GET /v1/orgs": () => json({ items: [] }) });
    const c = createCasamaClient({ apiUrl: "https://casama.test/", token: "tok", fetch: m.fetch });
    const { data } = await c.GET("/v1/orgs");
    expect(data).toEqual({ items: [] });
    expect(m.calls[0]!.url).toBe("https://casama.test/v1/orgs");
    expect(m.calls[0]!.headers.get("authorization")).toBe("Bearer tok");
  });

  it("asks getToken before every request", async () => {
    let n = 0;
    const m = mockFetch({ "GET /v1/orgs": () => json({ items: [] }) });
    const c = createCasamaClient({ getToken: async () => `t${++n}`, fetch: m.fetch });
    await c.GET("/v1/orgs");
    await c.GET("/v1/orgs");
    expect(m.calls.map((r) => r.headers.get("authorization"))).toEqual(["Bearer t1", "Bearer t2"]);
    expect(m.calls[0]!.url).toBe("https://api.casama.ai/v1/orgs");
  });

  it("sends no authorization header without a token", async () => {
    const m = mockFetch({ "GET /v1/config": () => json({ product_name: "Casama" }) });
    const c = createCasamaClient({ fetch: m.fetch });
    await c.GET("/v1/config");
    expect(m.calls[0]!.headers.has("authorization")).toBe(false);
  });
});

describe("errors", () => {
  it("maps problem+json to CasamaError", async () => {
    const m = mockFetch({
      [`POST /v1/runs/${RUN}/cancel`]: () => problem(409, "run_finished", "The run already ended"),
    });
    const c = createCasamaClient({ token: "t", fetch: m.fetch });
    const err = await c.cancelRun(RUN).catch((e: unknown) => e);
    expect(err).toBeInstanceOf(CasamaError);
    const e = err as CasamaError;
    expect(e.status).toBe(409);
    expect(e.code).toBe("run_finished");
    expect(e.detail).toBe("The run already ended");
    expect(e.requestId).toBe("req-1");
    expect(e.problem?.instance).toBe("/v1/x");
    expect(e.message).toContain("run_finished");
  });

  it("unwraps raw calls and keeps validation errors and Retry-After", async () => {
    const m = mockFetch({
      "GET /v1/bots": () =>
        new Response(
          JSON.stringify({
            type: "x",
            title: "Bad Request",
            status: 400,
            code: "validation_failed",
            errors: [{ path: "org_id", message: "Invalid UUID" }],
          }),
          { status: 400, headers: { "content-type": "application/problem+json" } },
        ),
      "GET /v1/orgs": () => problem(429, "rate_limited", undefined, { "retry-after": "7" }),
    });
    const c = createCasamaClient({ token: "t", fetch: m.fetch });
    const bad = (await c
      .unwrap(c.GET("/v1/bots", { params: { query: { org_id: "nope" } } }))
      .catch((e: unknown) => e)) as CasamaError;
    expect(bad.code).toBe("validation_failed");
    expect(bad.errors).toEqual([{ path: "org_id", message: "Invalid UUID" }]);
    const limited = (await c.unwrap(c.GET("/v1/orgs")).catch((e: unknown) => e)) as CasamaError;
    expect(limited.retryAfter).toBe(7);
  });

  it("handles answers that aren't problem+json", async () => {
    const m = mockFetch({
      "GET /v1/orgs": () => new Response("<html>bad gateway</html>", { status: 502 }),
    });
    const c = createCasamaClient({ token: "t", fetch: m.fetch });
    const e = (await c.unwrap(c.GET("/v1/orgs")).catch((x: unknown) => x)) as CasamaError;
    expect(e).toBeInstanceOf(CasamaError);
    expect(e.code).toBe("http_502");
    expect(e.problem).toBeUndefined();
  });
});

describe("ask", () => {
  it("creates a conversation, sends, polls the run's events and returns the reply", async () => {
    const events = replyEvents();
    const m = mockFetch({
      "POST /v1/conversations": () => json({ id: CONV }, 201),
      [`POST /v1/conversations/${CONV}/messages`]: () =>
        json({ message_id: MSG, run_id: RUN, conversation_id: CONV }, 202),
      [`GET /v1/runs/${RUN}/events`]: [
        () => json({ items: events.slice(0, 2), run_status: "running" }),
        () => json({ items: events.slice(1), run_status: "completed" }),
      ],
      [`GET /v1/runs/${RUN}`]: () => json(run("completed")),
    });
    const c = createCasamaClient({ token: "t", fetch: m.fetch });
    const seen: string[] = [];
    const r = await c.ask(BOT, "Say hello", {
      transport: "poll",
      pollIntervalMs: 1,
      onEvent: (e) => {
        seen.push(e.type);
      },
    });

    expect(
      m.calls.map((q) => `${q.method} ${new URL(q.url).pathname}${new URL(q.url).search}`),
    ).toEqual([
      "POST /v1/conversations",
      `POST /v1/conversations/${CONV}/messages`,
      `GET /v1/runs/${RUN}/events?after_seq=0&limit=1000`,
      `GET /v1/runs/${RUN}/events?after_seq=2&limit=1000`,
      `GET /v1/runs/${RUN}`,
    ]);
    expect(await m.calls[0]!.json()).toEqual({ bot_id: BOT });
    expect(await m.calls[1]!.json()).toEqual({ text: "Say hello" });
    expect(m.calls[1]!.headers.get("idempotency-key")).toMatch(/^[0-9a-f-]{36}$/);
    expect(r.text).toBe("Hello");
    expect(r.conversationId).toBe(CONV);
    expect(r.runId).toBe(RUN);
    expect(r.messageId).toBe(MSG);
    expect(r.run.status).toBe("completed");
    expect(r.timedOut).toBe(false);
    // No repeats even though the second page overlapped the first.
    expect(seen).toEqual([
      "run.started",
      "message.delta",
      "message.delta",
      "message.completed",
      "run.completed",
    ]);
    expect(r.events).toHaveLength(5);
  });

  it("streams over SSE and reuses a conversation", async () => {
    const events = replyEvents();
    const m = mockFetch({
      [`POST /v1/conversations/${CONV}/messages`]: () =>
        json({ message_id: MSG, run_id: RUN, conversation_id: CONV }, 202),
      // The first stream drops after two events; the client reconnects after seq 2.
      [`GET /v1/runs/${RUN}/events`]: [
        () => sse(events.slice(0, 2), "event: ping\ndata: {}\n\n"),
        () => sse(events.slice(2)),
      ],
      [`GET /v1/runs/${RUN}`]: () => json(run("completed")),
    });
    const c = createCasamaClient({ token: "t", fetch: m.fetch });
    const r = await c.ask(BOT, "Again", { conversationId: CONV });
    expect(r.text).toBe("Hello");
    expect(r.events.map((e) => e.seq)).toEqual([1, 2, 3, 4, 5]);
    const streams = m.calls.filter((q) => q.url.includes("/events"));
    expect(streams).toHaveLength(2);
    expect(streams[0]!.headers.get("accept")).toBe("text/event-stream");
    expect(streams[0]!.headers.get("authorization")).toBe("Bearer t");
    expect(streams[1]!.headers.get("last-event-id")).toBe("2");
    expect(new URL(streams[1]!.url).searchParams.get("after_seq")).toBe("2");
    expect(m.calls.some((q) => q.url.endsWith("/v1/conversations"))).toBe(false);
  });

  it("decides approvals with onApproval", async () => {
    seq = 0;
    const events = [
      ev("run.started", { trigger: "message", model: "m", computer_id: null }),
      ev("approval.requested", {
        approval_id: APPROVAL,
        tool: "shell",
        args_redacted: {},
        risk: "high",
        expires_at: "2026-11-15T01:00:00.000Z",
      }),
      ev("approval.resolved", { approval_id: APPROVAL, decision: "approved", decided_by: "u" }),
      ev("message.completed", { message_id: MSG, content: [{ type: "text", text: "Done" }] }),
      ev("run.completed", { final_message_id: MSG }),
    ];
    const m = mockFetch({
      [`POST /v1/conversations/${CONV}/messages`]: () =>
        json({ message_id: MSG, run_id: RUN, conversation_id: CONV }, 202),
      [`GET /v1/runs/${RUN}/events`]: () => sse(events),
      [`POST /v1/approvals/${APPROVAL}/decision`]: () => json({ id: APPROVAL, status: "approved" }),
      [`GET /v1/runs/${RUN}`]: () => json(run("completed")),
    });
    const c = createCasamaClient({ token: "t", fetch: m.fetch });
    const r = await c.ask(BOT, "Clean up", {
      conversationId: CONV,
      onApproval: (req) =>
        req.risk === "high" ? { decision: "approved", alwaysAllow: true } : "denied",
    });
    const decision = m.calls.find((q) => q.url.includes("/decision"))!;
    expect(await decision.json()).toEqual({ decision: "approved", always_allow: true });
    expect(r.text).toBe("Done");
    expect(r.pendingApproval).toBeUndefined();
  });

  it("returns pendingApproval when the run waits and nobody decides", async () => {
    seq = 0;
    const events = [
      ev("run.started", { trigger: "message", model: "m", computer_id: null }),
      ev("approval.requested", {
        approval_id: APPROVAL,
        tool: "shell",
        args_redacted: {},
        risk: "medium",
        expires_at: "2026-11-15T01:00:00.000Z",
      }),
    ];
    const m = mockFetch({
      [`POST /v1/conversations/${CONV}/messages`]: () =>
        json({ message_id: MSG, run_id: RUN, conversation_id: CONV }, 202),
      [`GET /v1/runs/${RUN}/events`]: () => sse(events),
      [`GET /v1/runs/${RUN}`]: () => json(run("waiting_approval")),
    });
    const c = createCasamaClient({ token: "t", fetch: m.fetch });
    const r = await c.ask(BOT, "Clean up", { conversationId: CONV });
    expect(r.pendingApproval?.approval_id).toBe(APPROVAL);
    expect(r.run.status).toBe("waiting_approval");
  });

  it("stops at timeoutMs and says so", async () => {
    const m = mockFetch({
      [`POST /v1/conversations/${CONV}/messages`]: () =>
        json({ message_id: MSG, run_id: RUN, conversation_id: CONV }, 202),
      [`GET /v1/runs/${RUN}/events`]: () => json({ items: [], run_status: "running" }),
      [`GET /v1/runs/${RUN}`]: () => json(run("running")),
    });
    const c = createCasamaClient({ token: "t", fetch: m.fetch });
    const r = await c.ask(BOT, "Slow", {
      conversationId: CONV,
      transport: "poll",
      pollIntervalMs: 5,
      timeoutMs: 40,
    });
    expect(r.timedOut).toBe(true);
    expect(r.run.status).toBe("running");
  });
});

describe("watchRun", () => {
  it("gives up at once on a client error", async () => {
    const m = mockFetch({ [`GET /v1/runs/${RUN}/events`]: () => problem(404, "run_not_found") });
    const c = createCasamaClient({ token: "t", fetch: m.fetch });
    const it = c.watchRun(RUN);
    await expect(it.next()).rejects.toMatchObject({ code: "run_not_found" });
    expect(m.calls).toHaveLength(1);
  });
});

describe("readSse", () => {
  it("handles events split across chunks, CRLF and multi-line data", async () => {
    const text =
      "event: run_event\r\ndata: a\r\ndata: b\r\nid: 3\r\n\r\n: comment\n\nevent: ping\ndata: {}\n\n";
    const bytes = new TextEncoder().encode(text);
    const body = new ReadableStream<Uint8Array>({
      start(ctrl) {
        for (let i = 0; i < bytes.length; i += 5) ctrl.enqueue(bytes.slice(i, i + 5));
        ctrl.close();
      },
    });
    const out = [];
    for await (const m of readSse(body)) out.push(m);
    expect(out).toEqual([
      { event: "run_event", data: "a\nb", id: "3" },
      { event: "ping", data: "{}", id: undefined },
    ]);
  });
});

describe("sites and domains", () => {
  const ORG = "44444444-4444-4444-8444-444444444444";
  const PAGE = "55555555-5555-4555-8555-555555555555";
  const DOMAIN = "66666666-6666-4666-8666-666666666666";

  it("lists, publishes and connects with the right paths and bodies", async () => {
    const m = mockFetch({
      [`GET /v1/orgs/${ORG}/sites`]: () => json({ items: [{ page_id: PAGE }] }),
      [`PUT /v1/pages/${PAGE}/site`]: async (req) =>
        json({ page_id: PAGE, ...((await req.json()) as object) }),
      [`DELETE /v1/pages/${PAGE}/site`]: () => new Response(null, { status: 204 }),
      [`POST /v1/orgs/${ORG}/domains`]: async (req) =>
        json({ domain: { id: DOMAIN, ...((await req.json()) as object) }, claim: null }, 201),
      "GET /v1/domains/search": (req) =>
        json({ items: [{ name: new URL(req.url).searchParams.get("q") }] }),
    });
    const c = createCasamaClient({ token: "t", fetch: m.fetch });
    expect(await c.sites.list(ORG)).toEqual([{ page_id: PAGE }]);
    expect(await c.sites.publish(PAGE, { label: "crumb" })).toMatchObject({ label: "crumb" });
    await c.sites.unpublish(PAGE);
    const r = await c.domains.connect(ORG, "bakery.com", { pageId: PAGE });
    expect(r.domain).toMatchObject({ id: DOMAIN, name: "bakery.com", page_id: PAGE });
    expect(await c.domains.search(ORG, "bakery")).toEqual([{ name: "bakery" }]);
    expect(m.calls.map((x) => x.method)).toEqual(["GET", "PUT", "DELETE", "POST", "GET"]);
  });

  it("throws CasamaError with the problem's code", async () => {
    const m = mockFetch({
      [`POST /v1/orgs/${ORG}/domains`]: () => problem(402, "plan_limit", "Upgrade"),
    });
    const c = createCasamaClient({ token: "t", fetch: m.fetch });
    const err = await c.domains.connect(ORG, "bakery.com").catch((e: unknown) => e);
    expect(err).toBeInstanceOf(CasamaError);
    expect((err as CasamaError).code).toBe("plan_limit");
  });
});

describe("packs", () => {
  const ORG = "44444444-4444-4444-8444-444444444444";
  const PACK = "55555555-5555-4555-8555-555555555555";
  const C = "a".repeat(40);

  it("installs a link at the previewed commit, and removes keeping bots by default", async () => {
    const m = mockFetch({
      "POST /v1/packs/preview": () => json({ name: "hello-pack", commit: C }),
      "POST /v1/packs": async (req) => json({ status: "installed", body: await req.json() }, 201),
      [`DELETE /v1/packs/${PACK}`]: (req) =>
        json({ deleted: PACK, kept: new URL(req.url).searchParams.get("bots") === "keep" ? 1 : 0 }),
    });
    const c = createCasamaClient({ token: "t", fetch: m.fetch });
    const r = (await c.packs.install(
      ORG,
      { url: "https://github.com/acme/packs" },
      { inputs: { team: "Crumb" } },
    )) as unknown as { body: Record<string, unknown> };
    expect(r.body).toEqual({
      org_id: ORG,
      url: "https://github.com/acme/packs",
      commit: C,
      inputs: { team: "Crumb" },
    });
    expect(await c.packs.remove(PACK)).toEqual({ deleted: PACK, kept: 1 });
    expect(m.calls.map((x) => x.method)).toEqual(["POST", "POST", "DELETE"]);
  });
});
