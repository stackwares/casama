/**
 * Words said before acting reach the chat app too (D-134): a Telegram user hears "On it" when the
 * bot starts working, not only the answer at the end, like the Casama app shows it.
 */
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import {
  builtinTools,
  CredentialResolver,
  directSteps,
  type FixtureFile,
  hashEmbedder,
  PostgresMemoryStore,
  ReplayGateway,
  runAgent,
} from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/watchers.json", import.meta.url));
let h: Harness;
let provider: Server;
let api = "";
const sent: string[] = [];

beforeAll(async () => {
  provider = createServer(async (req, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    if (req.url?.endsWith("/sendMessage"))
      sent.push(JSON.parse(Buffer.concat(chunks).toString()).text);
    res
      .writeHead(200, { "content-type": "application/json" })
      .end(JSON.stringify({ ok: true, result: { message_id: sent.length + 100 } }));
  }).listen(0, "127.0.0.1");
  await once(provider, "listening");
  api = `http://127.0.0.1:${(provider.address() as AddressInfo).port}`;
  h = await startHarness({ worker: { fixtures: FIXTURES } });
}, 60_000);
afterAll(async () => {
  await h?.stop();
  provider?.close();
});

const finish = () => ({
  type: "finish" as const,
  usage: { inputTokens: 1000, outputTokens: 100 },
  finishReason: "stop",
  model: "",
});

describe("chat app interim lines", () => {
  it("sends the line said before the first tool call to Telegram, then the answer", async () => {
    const u = await h.user("tg-interim@example.com");
    const orgId = (
      await j(await h.request("/v1/orgs", { method: "POST", token: u.token, json: { name: "I" } }))
    ).id;
    const cred = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: u.token,
        json: {
          org_id: orgId,
          provider: "openrouter",
          label: "k",
          api_key: "sk-or-v1-abcdefabcdef",
        },
      }),
    );
    const botId = (
      await j(
        await h.request("/v1/bots", {
          method: "POST",
          token: u.token,
          json: {
            org_id: orgId,
            name: "Helper",
            model_policy: { primary: { credential_id: cred.id, model: "fixture-primary" } },
          },
        }),
      )
    ).id;
    const ch = await j(
      await h.request("/v1/channels", {
        method: "POST",
        token: u.token,
        json: {
          bot_id: botId,
          kind: "telegram",
          name: "Telegram",
          config: { api_base: api },
          secrets: { bot_token: "123:abc" },
          allowed_senders: ["7"],
        },
      }),
    );
    const [s] = await h.tdb.admin<{ s: string }[]>`
      select v.decrypted_secret as s from public.channels c join vault.decrypted_secrets v on v.id = c.vault_secret_id where c.id = ${ch.id}`;
    const { webhook_secret } = JSON.parse(s!.s) as Record<string, string>;
    const res = await h.request(`/hooks/channels/${ch.id}`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-telegram-bot-api-secret-token": webhook_secret!,
      },
      body: JSON.stringify({
        message: {
          message_id: 1,
          text: "Crop my photo please",
          chat: { id: 70 },
          from: { id: 7, first_name: "Ana" },
        },
      }),
    });
    expect(res.status).toBe(200);
    const [r] = await h.tdb.admin<{ id: string }[]>`
      select id from public.runs where bot_id = ${botId} order by created_at limit 1`;

    const fixtures: FixtureFile[] = [
      {
        name: "interim",
        turns: [
          {
            when: { lastUserIncludes: "Crop my photo", lastRole: "user" },
            events: [
              { type: "text", text: "On it, cropping now." },
              { type: "tool_call", call: { callId: "c1", name: "no.such_tool", args: {} } },
              finish(),
            ],
          },
          { when: { lastRole: "tool" }, events: [{ type: "text", text: "Done." }, finish()] },
        ],
      },
    ];
    const embedder = hashEmbedder();
    sent.length = 0;
    const out = await runAgent(r!.id, {
      db: h.handle.db,
      gateway: new ReplayGateway(fixtures),
      tools: builtinTools({
        db: h.handle.db,
        memory: async () => new PostgresMemoryStore(h.handle.db, embedder),
      }),
      credentials: new CredentialResolver(h.handle.db),
      embedderFor: async () => embedder,
      step: directSteps,
      deltaIntervalMs: 20,
      cancelPollMs: 50,
      fallback: { backoffMs: 1 },
      fetch,
    } as never);
    expect(out.status).toBe("completed");
    expect(sent).toEqual(["On it, cropping now.", "Done."]);
  });
});
