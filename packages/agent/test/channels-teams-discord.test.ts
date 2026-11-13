/** Microsoft Teams and Discord as chat apps (D-278), with real signatures. */
import { generateKeyPairSync, sign } from "node:crypto";
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { exportJWK, generateKeyPair, SignJWT } from "jose";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { ADAPTERS, type WebhookRequest } from "../src/channels/index.ts";

const req = (body: string, headers: Record<string, string> = {}): WebhookRequest => ({
  method: "POST",
  url: "https://api.example.com/hooks/channels/x",
  headers,
  body,
});

describe("Discord", () => {
  const { publicKey, privateKey } = generateKeyPairSync("ed25519");
  const pub = publicKey.export({ format: "der", type: "spki" }).subarray(12).toString("hex");
  const signed = (body: string) => {
    const ts = String(Math.floor(Date.now() / 1000));
    return req(body, {
      "x-signature-timestamp": ts,
      "x-signature-ed25519": sign(null, Buffer.from(ts + body), privateKey).toString("hex"),
    });
  };
  const a = ADAPTERS.discord;

  it("checks the Ed25519 signature, answers PING, and defers a command", () => {
    const ping = JSON.stringify({ type: 1 });
    expect(a.verify(signed(ping), { public_key: pub }, {})).toBe(true);
    expect(a.verify({ ...signed(ping), body: '{"type":2}' }, { public_key: pub }, {})).toBe(false);
    expect(a.respond?.(req(ping))?.body).toBe('{"type":1}');
    const cmd = JSON.stringify({
      type: 2,
      id: "i1",
      application_id: "app1",
      token: "tok",
      channel_id: "ch1",
      member: { user: { id: "u1", global_name: "Ana" } },
      data: { name: "ask", options: [{ name: "message", value: "summarize the thread" }] },
    });
    expect(a.respond?.(req(cmd))?.body).toBe('{"type":5}');
    expect(a.normalize(req(cmd), {})[0]).toMatchObject({
      messageId: "i1",
      threadKey: "discord:ch1",
      sender: "u1",
      senderName: "Ana",
      text: "summarize the thread",
      reply: { channel_id: "ch1", application_id: "app1", token: "tok" },
    });
  });

  it("replies through the interaction while it's fresh, then as a channel message", async () => {
    const calls: Array<{ url: string; auth?: string }> = [];
    const f = (async (url: string, init: RequestInit = {}) => {
      calls.push({ url, auth: (init.headers as Record<string, string>)?.authorization });
      return new Response("{}", { status: 200 });
    }) as unknown as typeof fetch;
    const cfg = { api_base: "http://discord.test" };
    await a.send(cfg, { bot_token: "bt" }, { application_id: "app1", token: "tok", channel_id: "ch1", at: Date.now() }, "hi", f);
    await a.send(cfg, { bot_token: "bt" }, { application_id: "app1", token: "tok", channel_id: "ch1", at: Date.now() - 20 * 60_000 }, "later", f);
    expect(calls).toEqual([
      { url: "http://discord.test/webhooks/app1/tok", auth: undefined },
      { url: "http://discord.test/channels/ch1/messages", auth: "Bot bt" },
    ]);
  });
});

describe("Microsoft Teams", () => {
  let server: Server;
  let base = "";
  let key: CryptoKey;
  const sent: Array<{ path: string; body: string; auth?: string }> = [];

  beforeAll(async () => {
    const pair = await generateKeyPair("RS256");
    key = pair.privateKey as CryptoKey;
    const jwk = { ...(await exportJWK(pair.publicKey)), kid: "k1", alg: "RS256", use: "sig" };
    server = createServer(async (r, res) => {
      const chunks: Buffer[] = [];
      for await (const c of r) chunks.push(c as Buffer);
      const body = Buffer.concat(chunks).toString();
      sent.push({ path: r.url ?? "", body, auth: r.headers.authorization });
      const out =
        r.url === "/openid"
          ? { jwks_uri: `${base}/keys` }
          : r.url === "/keys"
            ? { keys: [jwk] }
            : r.url?.endsWith("/oauth2/v2.0/token")
              ? { access_token: "bf-token" }
              : {};
      res.writeHead(200, { "content-type": "application/json" }).end(JSON.stringify(out));
    }).listen(0, "127.0.0.1");
    await once(server, "listening");
    base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  });
  afterAll(() => server?.close());

  const token = (aud: string, serviceurl: string) =>
    new SignJWT({ serviceurl })
      .setProtectedHeader({ alg: "RS256", kid: "k1" })
      .setIssuer("https://api.botframework.com")
      .setAudience(aud)
      .setIssuedAt()
      .setExpirationTime("5m")
      .sign(key);

  it("accepts only tokens Microsoft signed for this bot, then reads and answers the message", async () => {
    const a = ADAPTERS.teams;
    const cfg = { app_id: "bot-app", openid_url: `${base}/openid`, login_base: base, api_base: base };
    const activity = JSON.stringify({
      type: "message",
      id: "act1",
      serviceUrl: "https://smba.trafficmanager.net/amer/",
      text: "<at>Casama</at> book the room",
      from: { id: "29:x", aadObjectId: "aad-1", name: "Ana" },
      conversation: { id: "conv1" },
    });
    const good = await token("bot-app", "https://smba.trafficmanager.net/amer/");
    expect(await a.verifyAsync?.(req(activity, { authorization: `Bearer ${good}` }), cfg, {}, fetch)).toBe(true);
    const wrongBot = await token("someone-else", "https://smba.trafficmanager.net/amer/");
    expect(await a.verifyAsync?.(req(activity, { authorization: `Bearer ${wrongBot}` }), cfg, {}, fetch)).toBe(false);
    const wrongService = await token("bot-app", "https://evil.example/");
    expect(await a.verifyAsync?.(req(activity, { authorization: `Bearer ${wrongService}` }), cfg, {}, fetch)).toBe(false);
    const [m] = a.normalize(req(activity), cfg);
    expect(m).toMatchObject({ messageId: "act1", sender: "aad-1", text: "book the room", threadKey: "teams:conv1" });
    await a.send(cfg, { app_password: "pw" }, m!.reply, "Booked.", fetch);
    const post = sent.find((s) => s.path === "/v3/conversations/conv1/activities");
    expect(post?.auth).toBe("Bearer bf-token");
    expect(JSON.parse(post!.body)).toEqual({ type: "message", text: "Booked.", replyToId: "act1" });
  });
});
