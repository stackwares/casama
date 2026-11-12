import { createServer, type IncomingMessage } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/chat.json", import.meta.url));

/** One local server standing in for OpenAI, Deepgram and ElevenLabs (their REST shapes). */
async function mockVoiceProviders() {
  const calls: Array<{ path: string; headers: IncomingMessage["headers"]; body: string }> = [];
  const server = createServer((req, res) => {
    const chunks: Buffer[] = [];
    req.on("data", (c) => chunks.push(c));
    req.on("end", () => {
      const body = Buffer.concat(chunks);
      const path = (req.url ?? "").split("?")[0] ?? "";
      calls.push({ path, headers: req.headers, body: body.toString("latin1") });
      const json = (o: unknown) => {
        res.writeHead(200, { "content-type": "application/json" });
        res.end(JSON.stringify(o));
      };
      if (path === "/v1/audio/transcriptions")
        return json({ text: "remind me to water the plants", duration: 3.2 });
      if (path === "/v1/listen")
        return json({
          metadata: { duration: 2 },
          results: { channels: [{ alternatives: [{ transcript: "deepgram heard you" }] }] },
        });
      if (path.startsWith("/v1/text-to-speech/") || path === "/v1/audio/speech") {
        res.writeHead(200, { "content-type": "audio/mpeg" });
        return res.end(Buffer.from("ID3-fake-mp3"));
      }
      if (path.endsWith(":generateContent"))
        return json({
          candidates: [
            { content: { parts: [{ inlineData: { data: Buffer.alloc(48).toString("base64") } }] } },
          ],
        });
      if (path === "/v1beta/auth_tokens") return json({ name: "auth_tokens/gemini-test-token" });
      if (path === "/v1/realtime/client_secrets")
        return json({
          value: "ek_test_ephemeral",
          expires_at: Math.floor(Date.now() / 1000) + 600,
        });
      res.writeHead(404);
      res.end();
    });
  });
  await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
  return {
    url: `http://127.0.0.1:${(server.address() as AddressInfo).port}`,
    calls,
    close: () => server.close(),
  };
}

/**
 * The server's own Google AI key (GOOGLE_AI_API_KEY): workspaces without a live-call key of their
 * own still get calls, and on Casama Cloud (billing on) those calls come out of credits.
 */
describe("live calls on the server's key", () => {
  let mock: Awaited<ReturnType<typeof mockVoiceProviders>>;
  const stacks: Harness[] = [];
  afterAll(async () => {
    for (const h of stacks) await h.stop();
    mock?.close();
  });
  beforeAll(async () => {
    mock = await mockVoiceProviders();
  });

  async function workspace(h: Harness, email: string) {
    const owner = await h.user(email);
    const orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Calls" },
        }),
      )
    ).id as string;
    const llm = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, provider: "openrouter", label: "llm", api_key: "sk-llm" },
      }),
    );
    const bot = await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Vox",
          model_policy: { primary: { credential_id: llm.id, model: "fixture-main" } },
        },
      }),
    );
    return { owner, orgId, botId: bot.id as string };
  }
  const start = (h: Harness, token: string, botId: string) =>
    h.request("/v1/voice/session", { method: "POST", token, json: { bot_id: botId } });

  it("self-hosted: the server's key covers workspaces without one, and the call isn't billed", async () => {
    const h = await startHarness({
      env: { GOOGLE_AI_API_KEY: "server-gemini-key" },
      worker: { fixtures: FIXTURES, providerBases: { gemini: mock.url, openai: mock.url } },
    });
    stacks.push(h);
    const w = await workspace(h, "server-key@example.com");
    const res = await start(h, w.owner.token, w.botId);
    expect(res.status).toBe(200);
    const s = await j(res);
    expect(s.provider).toBe("gemini");
    expect(
      mock.calls.findLast((c) => c.path === "/v1beta/auth_tokens")?.headers["x-goog-api-key"],
    ).toBe("server-gemini-key");
    await h.request("/v1/voice/transcript", {
      method: "POST",
      token: w.owner.token,
      json: {
        conversation_id: s.conversation_id,
        turns: [{ role: "user", text: "hi" }],
        seconds: 60,
        provider: "gemini",
      },
    });
    const [row] = await h.handle.db.execute<{ billable: boolean }>(
      sql`select billable from public.usage_ledger where org_id = ${w.orgId}::uuid and kind = 'voice_seconds'`,
    );
    expect(row?.billable).toBe(false);

    // Read-aloud uses the same key with Gemini when the workspace has no voice key of its own.
    const [conv] = await h.handle.db.execute<{ id: string }>(
      sql`select id from public.conversations where org_id = ${w.orgId}::uuid limit 1`,
    );
    const [m] = await h.handle.db.execute<{ id: string }>(sql`
      insert into public.messages (org_id, conversation_id, role, content)
      values (${w.orgId}::uuid, ${conv?.id}::uuid, 'assistant', '[{"type":"text","text":"Water the fern."}]'::jsonb)
      returning id`);
    const speech = await h.request(`/v1/messages/${m?.id}/speech`, { token: w.owner.token });
    expect(speech.status).toBe(200);
    expect(
      mock.calls.findLast((c) => c.path.endsWith(":generateContent"))?.headers["x-goog-api-key"],
    ).toBe("server-gemini-key");
  }, 120_000);
});
