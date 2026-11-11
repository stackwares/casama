import { fileURLToPath } from "node:url";
import { ModelCallError, type ModelGateway } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { testCredential } from "../src/worker/workflows.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));
const KEY = "sk-or-v1-THIS-IS-A-SECRET-KEY-0123456789";

let h: Harness;
let owner: { id: string; token: string };
let orgId: string;
let credentialId: string;
let botId: string;
const bodies: string[] = [];

/** Every response body is kept so the test can prove no API response ever contains the key. */
async function call(path: string, init: Parameters<Harness["request"]>[1] = {}) {
  const res = await h.request(path, init);
  bodies.push(await res.clone().text());
  return res;
}

async function waitForRun(runId: string, token: string, timeoutMs = 15_000) {
  const until = Date.now() + timeoutMs;
  for (;;) {
    const run = await j(await call(`/v1/runs/${runId}`, { token }));
    if (["completed", "failed", "cancelled"].includes(run.status)) return run;
    if (Date.now() > until) throw new Error(`run ${runId} still ${run.status}`);
    await new Promise((r) => setTimeout(r, 100));
  }
}

async function chat(conversationId: string, text: string) {
  const sent = await j(
    await call(`/v1/conversations/${conversationId}/messages`, {
      method: "POST",
      token: owner.token,
      json: { text },
    }),
  );
  return { ...sent, run: await waitForRun(sent.run_id, owner.token) };
}

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  owner = await h.user("chat-owner@example.com");
  orgId = (
    await j(
      await call("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Chat Org" } }),
    )
  ).id;
}, 60_000);
afterAll(() => h?.stop());

describe("model keys", () => {
  it("stores keys in Vault and returns metadata only", async () => {
    const res = await call("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "Main", api_key: KEY },
    });
    expect(res.status).toBe(201);
    const cred = await j(res);
    credentialId = cred.id;
    expect(cred).toMatchObject({ provider: "openrouter", label: "Main", key_hint: "6789" });
    expect(cred.api_key).toBeUndefined();
    const [row] = await h.tdb.admin<
      { vault_secret_id: string }[]
    >`select vault_secret_id from public.model_credentials where id = ${cred.id}`;
    const [secret] = await h.tdb.admin<
      { decrypted_secret: string }[]
    >`select decrypted_secret from vault.decrypted_secrets where id = ${row!.vault_secret_id}`;
    expect(secret?.decrypted_secret).toBe(KEY);
  });

  it("tests a key on a model that always reasons, and says what a provider objected to", async () => {
    const efforts: Array<string | undefined> = [];
    // A provider that, like OpenRouter's Muse Ember, refuses to switch reasoning off.
    const fussy: ModelGateway = {
      async *stream(req) {
        efforts.push(req.model.reasoningEffort);
        if (req.model.reasoningEffort === "none")
          throw new ModelCallError("provider returned 400", {
            retryable: false,
            status: 400,
            cause: {
              responseBody: JSON.stringify({
                error: {
                  message: "Reasoning is mandatory for this endpoint and cannot be disabled.",
                },
              }),
            },
          });
        yield { type: "text", text: "OK" };
      },
    };
    expect(await testCredential(h.handle.db, fussy, credentialId, orgId)).toMatchObject({
      ok: true,
    });
    expect(efforts).toEqual(["none", "low"]);
    const broken: ModelGateway = {
      // biome-ignore lint/correctness/useYield: it fails before answering
      async *stream() {
        throw new ModelCallError("provider returned 400", {
          retryable: false,
          status: 400,
          cause: {
            responseBody: JSON.stringify({
              error: { message: "This model is not available in your region." },
            }),
          },
        });
      },
    };
    expect(await testCredential(h.handle.db, broken, credentialId, orgId)).toMatchObject({
      ok: false,
      error: "The provider returned 400: This model is not available in your region.",
    });
  });

  it("tests a key through the worker with a 1-token call", async () => {
    const res = await call(`/v1/credentials/${credentialId}/test`, {
      method: "POST",
      token: owner.token,
      json: {},
    });
    expect(await j(res)).toMatchObject({ ok: true, model: "meta/muse-ember" });
    const list = await j(await call(`/v1/credentials?org_id=${orgId}`, { token: owner.token }));
    expect(list.items[0]).toMatchObject({ id: credentialId, last_test_ok: true });
  });

  it("lists models for the picker, recommended first (fixture mode: Casama's short list)", async () => {
    const res = await call(`/v1/credentials/${credentialId}/models`, { token: owner.token });
    expect(res.status).toBe(200);
    const body = await j(res);
    expect(body.source).toBe("featured");
    expect(body.items[0]).toMatchObject({ id: "meta/muse-ember", featured: true });
    const stranger = await h.user("models-stranger@example.com");
    const denied = await call(`/v1/credentials/${credentialId}/models`, { token: stranger.token });
    expect(denied.status).toBe(404);
  });

  it("only admins add keys", async () => {
    const member = await h.user("chat-member@example.com");
    const invite = await j(
      await call(`/v1/orgs/${orgId}/invites`, {
        method: "POST",
        token: owner.token,
        json: { email: "chat-member@example.com" },
      }),
    );
    await call(`/v1/invites/${invite.accept_token}/accept`, {
      method: "POST",
      token: member.token,
    });
    const res = await call("/v1/credentials", {
      method: "POST",
      token: member.token,
      json: { org_id: orgId, provider: "openai", label: "Mine", api_key: "sk-member-key-123" },
    });
    expect(res.status).toBe(403);
  });
});

describe("bots and chat", () => {
  it("creates a bot with a model policy", async () => {
    const res = await call("/v1/bots", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: orgId,
        name: "Ada",
        persona_md: "Brief and friendly.",
        model_policy: {
          primary: { credential_id: credentialId, model: "fixture-main" },
          cheap: { credential_id: credentialId, model: "fixture-cheap" },
        },
      },
    });
    expect(res.status).toBe(201);
    const bot = await j(res);
    botId = bot.id;
    expect(bot).toMatchObject({
      name: "Ada",
      autonomy: "ask_risky",
      visibility: "team",
      budget: { per_run_usd: 1, daily_usd: 10 },
    });
    const list = await j(await call(`/v1/bots?org_id=${orgId}`, { token: owner.token }));
    expect(list.items.map((b: { id: string }) => b.id)).toContain(botId);
  });

  it("rejects model policies that point at another org's credential", async () => {
    const res = await call("/v1/bots", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: orgId,
        name: "Bad",
        model_policy: {
          primary: { credential_id: "00000000-0000-4000-8000-000000000000", model: "x" },
        },
      },
    });
    expect(res.status).toBe(400);
  });

  it("chats: the run streams, finishes, saves the reply and remembers across conversations", async () => {
    const convA = await j(
      await call("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: botId },
      }),
    );
    const first = await chat(convA.id, "Please note: my favorite color is teal.");
    expect(first.run).toMatchObject({ status: "completed", conversation_id: convA.id });
    expect(first.run.cost_usd).toBeGreaterThan(0);

    const page = await j(await call(`/v1/runs/${first.run_id}/events`, { token: owner.token }));
    const types = page.items.map((e: { type: string }) => e.type);
    expect(page.run_status).toBe("completed");
    expect(types[0]).toBe("run.started");
    expect(types).toEqual(
      expect.arrayContaining([
        "tool.started",
        "tool.completed",
        "message.delta",
        "message.completed",
        "memory.written",
        "usage",
      ]),
    );
    expect(types.at(-1)).toBe("run.completed");
    expect(page.items.map((e: { seq: number }) => e.seq)).toEqual(
      page.items.map((_: unknown, i: number) => i + 1),
    );

    // Catch-up after a seq
    const tail = await j(
      await call(`/v1/runs/${first.run_id}/events?after_seq=${page.items.length - 2}`, {
        token: owner.token,
      }),
    );
    expect(tail.items).toHaveLength(2);

    // A different conversation recalls the fact
    const convB = await j(
      await call("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: botId },
      }),
    );
    const second = await chat(convB.id, "Quick question: what is my favorite color?");
    const events = await j(await call(`/v1/runs/${second.run_id}/events`, { token: owner.token }));
    const done = events.items.find((e: { type: string }) => e.type === "message.completed");
    expect(done.payload.content[0].text).toBe("Your favorite color is teal.");

    const memories = await j(await call(`/v1/bots/${botId}/memories`, { token: owner.token }));
    expect(memories.items.some((m: { content: string }) => /teal/.test(m.content))).toBe(true);
    const convos = await j(await call(`/v1/bots/${botId}/conversations`, { token: owner.token }));
    expect(convos.items[0].id).toBe(convB.id);
    expect(convos.items.find((c: { id: string }) => c.id === convA.id).title).toContain(
      "favorite color",
    );
  });

  it("streams live events over SSE until the run ends", async () => {
    const conv = await j(
      await call("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: botId },
      }),
    );
    const sent = await j(
      await call(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token: owner.token,
        json: { text: "hello there" },
      }),
    );
    const res = await h.request(`/v1/runs/${sent.run_id}/events?after_seq=0`, {
      token: owner.token,
      headers: { accept: "text/event-stream" },
    });
    expect(res.headers.get("content-type")).toContain("text/event-stream");
    const text = await res.text(); // the stream closes after the terminal event
    bodies.push(text);
    const events = text
      .split("\n")
      .filter((l) => l.startsWith("data: "))
      .map((l) => JSON.parse(l.slice(6)))
      .filter((e) => e.type);
    expect(events[0].type).toBe("run.started");
    expect(events.at(-1).type).toBe("run.completed");
    expect(
      events
        .filter((e) => e.type === "message.delta")
        .map((e) => e.payload.text)
        .join(""),
    ).toBe("Hello! How can I help?");
  });

  it("cancels a running run", async () => {
    const conv = await j(
      await call("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: botId },
      }),
    );
    const sent = await j(
      await call(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token: owner.token,
        json: { text: "count slow" },
      }),
    );
    for (let i = 0; i < 50; i++) {
      const page = await j(await call(`/v1/runs/${sent.run_id}/events`, { token: owner.token }));
      if (page.items.some((e: { type: string }) => e.type === "message.delta")) break;
      await new Promise((r) => setTimeout(r, 100));
    }
    const cancelledAt = Date.now();
    const res = await call(`/v1/runs/${sent.run_id}/cancel`, {
      method: "POST",
      token: owner.token,
    });
    expect(res.status).toBe(202);
    const run = await waitForRun(sent.run_id, owner.token);
    expect(run.status).toBe("cancelled");
    expect(Date.now() - cancelledAt).toBeLessThan(2000);
    const again = await call(`/v1/runs/${sent.run_id}/cancel`, {
      method: "POST",
      token: owner.token,
    });
    expect(again.status).toBe(409);
  });

  it("hides runs from other organizations", async () => {
    const stranger = await h.user("chat-stranger@example.com");
    const page = await j(await call(`/v1/bots?org_id=${orgId}`, { token: stranger.token }));
    expect(page.items).toEqual([]);
    const [anyRun] = await h.tdb.admin<{ id: string }[]>`select id from public.runs limit 1`;
    expect((await call(`/v1/runs/${anyRun!.id}`, { token: stranger.token })).status).toBe(404);
    expect((await call(`/v1/runs/${anyRun!.id}/events`, { token: stranger.token })).status).toBe(
      404,
    );
    expect(
      (await call(`/v1/runs/${anyRun!.id}/cancel`, { method: "POST", token: stranger.token }))
        .status,
    ).toBe(404);
    expect((await call(`/v1/bots/${botId}/memories`, { token: stranger.token })).status).toBe(404);
    expect((await call(`/v1/usage?org_id=${orgId}`, { token: stranger.token })).status).toBe(404);
  });

  it("reports usage by bot", async () => {
    const usage = await j(
      await call(`/v1/usage?org_id=${orgId}&period=month`, { token: owner.token }),
    );
    expect(usage.total_cost_usd).toBeGreaterThan(0);
    expect(usage.by_bot[0]).toMatchObject({ bot_id: botId, name: "Ada" });
    expect(usage.by_bot[0].tokens_in).toBeGreaterThan(0);
    expect(usage.by_day.length).toBeGreaterThan(0);
    expect(usage.by_day[0].day).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    expect(usage.by_model[0].tokens_in).toBeGreaterThan(0);
    expect(usage.by_kind.map((k: { kind: string }) => k.kind)).toContain("tokens_in");
    expect(usage.runs).toBeGreaterThan(0);
  });
});

describe("secrets", () => {
  it("no API response ever contains the model key", () => {
    expect(bodies.length).toBeGreaterThan(20);
    for (const body of bodies) expect(body).not.toContain(KEY);
  });
});
