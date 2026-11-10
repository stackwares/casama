/**
 * A fake of OpenAI's "Sign in with ChatGPT" auth server and plan-usage Responses API, for tests.
 * Follows the documented shapes (developers.openai.com/siwc): loopback authorize redirect, S256
 * PKCE, a dynamic client on first registration, rotating refresh tokens with reuse detection,
 * revocation, `GET /v1/models` with visibility, and `POST /v1/responses` server-sent events.
 */
import { createHash, randomBytes, randomUUID } from "node:crypto";
import { createServer, type IncomingMessage, type Server, type ServerResponse } from "node:http";
import type { AddressInfo } from "node:net";
import { exportJWK, generateKeyPair, SignJWT } from "jose";

export type ScriptedResponse =
  | { text: string }
  | { toolCall: { name: string; args: Record<string, unknown> } }
  | { limit: "before" | "mid" }
  | { error: { status: number; code?: string; message?: string; param?: string } };

const FORBIDDEN = [
  "temperature",
  "top_p",
  "max_output_tokens",
  "metadata",
  "user",
  "truncation",
  "background",
  "previous_response_id",
];

export interface FakeOpenAI {
  url: string;
  apiUrl: string;
  state: {
    /** Seconds until access tokens expire (default 3600). */
    expiresIn: number;
    /** Grant plan usage on consent (default true). */
    grantPlan: boolean;
    /** The person declines on the consent screen. */
    decline: boolean;
    email: string;
    sub: string;
    authorizeRequests: URLSearchParams[];
    refreshCalls: number;
    revoked: Array<{ token: string; clientId: string }>;
    responsesBodies: Array<Record<string, unknown>>;
    script: ScriptedResponse[];
    /** Make every refresh token unusable (the person disconnected the app in ChatGPT). */
    killRefresh: boolean;
  };
  stop(): Promise<void>;
}

const b64url = (b: Buffer) => b.toString("base64url");

async function readBody(req: IncomingMessage) {
  const chunks: Buffer[] = [];
  for await (const c of req) chunks.push(c as Buffer);
  return Buffer.concat(chunks).toString("utf8");
}

function json(res: ServerResponse, status: number, body: unknown) {
  res.writeHead(status, { "content-type": "application/json" });
  res.end(JSON.stringify(body));
}

export async function startFakeOpenAI(): Promise<FakeOpenAI> {
  const { privateKey, publicKey } = await generateKeyPair("RS256");
  const jwk = { ...(await exportJWK(publicKey)), kid: "fake-1", alg: "RS256", use: "sig" };
  const codes = new Map<
    string,
    { clientId: string; challenge: string; redirectUri: string; nonce: string; plan: boolean }
  >();
  const access = new Map<string, number>(); // token -> expiry ms
  const refresh = new Map<string, { clientId: string; used: boolean; plan: boolean }>();
  const issuedClients = new Set<string>();
  let base = "";
  const state: FakeOpenAI["state"] = {
    expiresIn: 3600,
    grantPlan: true,
    decline: false,
    email: "plan.owner@example.com",
    sub: "user-chatgpt-1",
    authorizeRequests: [],
    refreshCalls: 0,
    revoked: [],
    responsesBodies: [],
    script: [],
    killRefresh: false,
  };

  const issue = async (clientId: string, plan: boolean, nonce?: string) => {
    const at = `at_${b64url(randomBytes(18))}`;
    const rt = `rt_${b64url(randomBytes(18))}`;
    access.set(at, Date.now() + state.expiresIn * 1000);
    refresh.set(rt, { clientId, used: false, plan });
    const idToken = await new SignJWT({ email: state.email, ...(nonce ? { nonce } : {}) })
      .setProtectedHeader({ alg: "RS256", kid: "fake-1" })
      .setIssuer(base)
      .setAudience(clientId)
      .setSubject(state.sub)
      .setIssuedAt()
      .setExpirationTime("1h")
      .sign(privateKey);
    const scope = `openid profile email offline_access resource.invoke${plan ? " chatgpt.tokens.use.direct" : ""}`;
    return {
      access_token: at,
      refresh_token: rt,
      id_token: idToken,
      token_type: "Bearer",
      expires_in: state.expiresIn,
      scope,
    };
  };

  const authed = (req: IncomingMessage) => {
    const token = (req.headers.authorization ?? "").replace(/^Bearer\s+/, "");
    const exp = access.get(token);
    return exp !== undefined && exp > Date.now();
  };

  const sse = (res: ServerResponse, events: Array<Record<string, unknown>>) => {
    res.writeHead(200, { "content-type": "text/event-stream", "x-request-id": "req_fake" });
    for (const e of events) res.write(`event: ${e.type}\ndata: ${JSON.stringify(e)}\n\n`);
    res.end();
  };

  const server: Server = createServer(async (req, res) => {
    const url = new URL(req.url ?? "/", base);
    try {
      if (url.pathname === "/.well-known/openid-configuration")
        return json(res, 200, {
          issuer: base,
          jwks_uri: `${base}/jwks`,
          token_endpoint: `${base}/api/accounts/oauth/token`,
          revocation_endpoint: `${base}/api/accounts/oauth/revoke`,
        });
      if (url.pathname === "/jwks") return json(res, 200, { keys: [jwk] });

      if (url.pathname === "/api/accounts/authorize") {
        const q = url.searchParams;
        state.authorizeRequests.push(q);
        const redirect = new URL(q.get("redirect_uri") ?? "");
        if (redirect.hostname !== "127.0.0.1") return json(res, 400, { error: "invalid_redirect" });
        redirect.searchParams.set("state", q.get("state") ?? "");
        if (state.decline) {
          redirect.searchParams.set("error", "access_denied");
        } else {
          let clientId = q.get("client_id") ?? "";
          if (clientId === "dynamic_agent_client") {
            clientId = `oaiapp_${b64url(randomBytes(8))}`;
            issuedClients.add(clientId);
            redirect.searchParams.set("client_id", clientId);
          } else if (!issuedClients.has(clientId))
            return json(res, 400, { error: "invalid_client" });
          const code = `code_${b64url(randomBytes(12))}`;
          codes.set(code, {
            clientId,
            challenge: q.get("code_challenge") ?? "",
            redirectUri: q.get("redirect_uri") ?? "",
            nonce: q.get("nonce") ?? "",
            plan: state.grantPlan,
          });
          redirect.searchParams.set("code", code);
        }
        res.writeHead(302, { location: redirect.toString() });
        return res.end();
      }

      if (url.pathname === "/api/accounts/oauth/token" && req.method === "POST") {
        const form = new URLSearchParams(await readBody(req));
        if (form.get("resource") !== "https://api.openai.com/v1")
          return json(res, 400, { error: "invalid_target" });
        if (form.get("grant_type") === "authorization_code") {
          const c = codes.get(form.get("code") ?? "");
          codes.delete(form.get("code") ?? "");
          const challenge = b64url(
            createHash("sha256")
              .update(form.get("code_verifier") ?? "")
              .digest(),
          );
          if (
            !c ||
            c.clientId !== form.get("client_id") ||
            c.redirectUri !== form.get("redirect_uri") ||
            c.challenge !== challenge
          )
            return json(res, 400, { error: "invalid_grant" });
          return json(res, 200, await issue(c.clientId, c.plan, c.nonce));
        }
        if (form.get("grant_type") === "refresh_token") {
          state.refreshCalls++;
          if (form.has("scope")) return json(res, 400, { error: "invalid_scope" });
          const r = refresh.get(form.get("refresh_token") ?? "");
          if (!r || state.killRefresh) return json(res, 400, { error: "invalid_grant" });
          if (r.used) return json(res, 400, { error: "refresh_token_reused" });
          if (r.clientId !== form.get("client_id"))
            return json(res, 400, { error: "invalid_client" });
          r.used = true;
          const out = await issue(r.clientId, r.plan);
          const { id_token: _drop, ...rest } = out;
          return json(res, 200, rest);
        }
        return json(res, 400, { error: "unsupported_grant_type" });
      }

      if (url.pathname === "/api/accounts/oauth/revoke" && req.method === "POST") {
        const form = new URLSearchParams(await readBody(req));
        state.revoked.push({
          token: form.get("token") ?? "",
          clientId: form.get("client_id") ?? "",
        });
        refresh.delete(form.get("token") ?? "");
        res.writeHead(200);
        return res.end();
      }

      if (url.pathname === "/v1/models") {
        if (!authed(req)) return json(res, 401, { detail: "unauthorized" });
        return json(res, 200, {
          data: [
            { slug: "gpt-6.1-sol", display_name: "GPT-6.1 Sol", visibility: "list" },
            { slug: "gpt-6.1-terra", display_name: "GPT-6.1 Terra", visibility: "list" },
            { slug: "internal-preview", display_name: "Internal", visibility: "hide" },
          ],
        });
      }

      if (url.pathname === "/v1/responses" && req.method === "POST") {
        if (!authed(req))
          return json(res, 401, {
            error: { code: "subscription_sharing_invalid_user", message: "sign in again" },
          });
        const body = JSON.parse(await readBody(req)) as Record<string, unknown>;
        state.responsesBodies.push(body);
        const bad = FORBIDDEN.find((k) => k in body);
        if (bad || body.stream !== true || body.store !== false)
          return json(res, 400, {
            error: {
              code: "subscription_sharing_unsupported_capability",
              param: bad ?? "stream",
              message: "unsupported",
            },
          });
        const step = state.script.shift() ?? { text: "OK from your ChatGPT plan." };
        const id = `resp_${randomUUID()}`;
        const usage = { input_tokens: 42, output_tokens: 7 };
        if ("limit" in step && step.limit === "before")
          return json(res, 429, {
            error: { code: "subscription_sharing_usage_limit_exceeded", message: "limit" },
          });
        if ("error" in step)
          return json(res, step.error.status, {
            error: { code: step.error.code, message: step.error.message, param: step.error.param },
          });
        if ("limit" in step)
          return sse(res, [
            { type: "response.created", response: { id } },
            { type: "response.output_text.delta", delta: "Partial " },
            {
              type: "response.failed",
              response: {
                id,
                error: { code: "subscription_sharing_usage_limit_exceeded", message: "limit" },
              },
            },
          ]);
        if ("toolCall" in step)
          return sse(res, [
            { type: "response.created", response: { id } },
            {
              type: "response.output_item.done",
              item: {
                type: "function_call",
                id: "fc_1",
                call_id: `call_${randomUUID().slice(0, 8)}`,
                name: step.toolCall.name,
                arguments: JSON.stringify(step.toolCall.args),
              },
            },
            {
              type: "response.completed",
              response: { id, model: body.model, usage },
            },
          ]);
        const words = step.text.split(/(?<= )/);
        return sse(res, [
          { type: "response.created", response: { id } },
          ...words.map((w) => ({ type: "response.output_text.delta", delta: w })),
          { type: "response.completed", response: { id, model: body.model, usage } },
        ]);
      }
      json(res, 404, { error: "not_found" });
    } catch (err) {
      json(res, 500, { error: String(err) });
    }
  });
  await new Promise<void>((r) => server.listen(0, "127.0.0.1", () => r()));
  base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  return {
    url: base,
    apiUrl: `${base}/v1`,
    state,
    stop: () => new Promise((r) => server.close(() => r())),
  };
}
