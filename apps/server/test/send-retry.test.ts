import { randomUUID } from "node:crypto";
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

// The app sends a message again when it got no answer (D-402), with the same Idempotency-Key. A
// retry never posts the message twice: not after the first send finished, and not while it is
// still being answered.

const FIXTURES = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));

let h: Harness;
let token: string;
let conversationId: string;

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  const owner = await h.user("send-retry@example.com");
  token = owner.token;
  const org = await j(await h.request("/v1/orgs", { method: "POST", token, json: { name: "S" } }));
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token,
      json: { org_id: org.id, provider: "openrouter", label: "k", api_key: "sk-send-retry" },
    }),
  );
  const bot = await j(
    await h.request("/v1/bots", {
      method: "POST",
      token,
      json: {
        org_id: org.id,
        name: "Once",
        model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
      },
    }),
  );
  conversationId = (
    await j(
      await h.request("/v1/conversations", { method: "POST", token, json: { bot_id: bot.id } }),
    )
  ).id;
}, 60_000);
afterAll(() => h?.stop());

const send = (key: string, text: string) =>
  h.request(`/v1/conversations/${conversationId}/messages`, {
    method: "POST",
    token,
    json: { text },
    headers: { "idempotency-key": key },
  });

const copies = (text: string) =>
  h.tdb.admin<{ id: string }[]>`
    select id from public.messages
    where conversation_id = ${conversationId} and role = 'user' and content::text like ${`%${text}%`}`;

it("a retry after the send finished returns the same message and run", async () => {
  const key = randomUUID();
  const first = await send(key, "what is my favorite color");
  expect(first.status).toBe(202);
  const a = await j(first);
  expect(a.message_id).toBe(key);
  const b = await j(await send(key, "what is my favorite color"));
  expect(b).toMatchObject({ message_id: a.message_id, run_id: a.run_id });
  expect(await copies("what is my favorite color")).toHaveLength(1);
});

it("two copies of the same send at once post it once", async () => {
  const key = randomUUID();
  const [r1, r2] = await Promise.all([send(key, "say hello twice"), send(key, "say hello twice")]);
  expect([r1.status, r2.status]).toEqual([202, 202]);
  const [a, b] = [await j(r1), await j(r2)];
  expect(a.message_id).toBe(key);
  expect(b.message_id).toBe(key);
  expect(b.run_id).toBe(a.run_id);
  expect(await copies("say hello twice")).toHaveLength(1);
});

it("a key that isn't a UUID still works through the stored replay", async () => {
  const key = `retry-${randomUUID()}`;
  const a = await j(await send(key, "plain key message"));
  const b = await j(await send(key, "plain key message"));
  expect(b).toMatchObject({ message_id: a.message_id, run_id: a.run_id });
  expect(await copies("plain key message")).toHaveLength(1);
});
