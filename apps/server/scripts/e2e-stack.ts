/**
 * Local end-to-end stack without Docker: throwaway Postgres, a minimal stand-in for the
 * Supabase Auth endpoints the CLI uses (signup, password and refresh grants), and the real API.
 * Prints KASAMA_API_URL=<url> once ready. CI runs the same CLI tests against `supabase start`.
 */
import { randomBytes, randomUUID } from "node:crypto";
import { createServer } from "node:http";
import { fileURLToPath } from "node:url";
import { serve } from "@hono/node-server";
import { createDb } from "@kasama/db";
import { startTestDatabase } from "@kasama/db/testing";
import { createLogger } from "@kasama/observability";
import { SignJWT } from "jose";
import { createApp } from "../src/api/app.ts";
import { createTokenVerifier } from "../src/api/auth.ts";
import { pgRunEventHub } from "../src/api/run-event-hub.ts";
import { dbosWorkflows } from "../src/api/workflows.ts";
import { loadEnv } from "../src/env.ts";
import { disabledEmail } from "../src/services/email.ts";
import { startWorker } from "../src/worker/index.ts";

const secret = randomBytes(32).toString("hex");
const tdb = await startTestDatabase();
const users = new Map<string, { id: string; password: string }>();
const refresh = new Map<string, string>();

async function session(id: string, email: string) {
  const access = await new SignJWT({ email, role: "authenticated" })
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(id)
    .setAudience("authenticated")
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(new TextEncoder().encode(secret));
  const rt = randomBytes(16).toString("hex");
  refresh.set(rt, email);
  return {
    access_token: access,
    refresh_token: rt,
    expires_in: 3600,
    token_type: "bearer",
    user: { id, email },
  };
}

const auth = createServer(async (req, res) => {
  const chunks: Buffer[] = [];
  for await (const c of req) chunks.push(c as Buffer);
  const body = chunks.length ? JSON.parse(Buffer.concat(chunks).toString()) : {};
  const url = new URL(req.url ?? "/", "http://x");
  const send = (status: number, data: unknown) => {
    res.writeHead(status, { "content-type": "application/json" });
    res.end(JSON.stringify(data));
  };
  if (url.pathname === "/auth/v1/signup") {
    if (users.has(body.email)) return send(422, { msg: "User already registered" });
    const id = randomUUID();
    await tdb.admin`insert into auth.users (id, email, aud, role) values (${id}, ${body.email}, 'authenticated', 'authenticated')`;
    users.set(body.email, { id, password: body.password });
    return send(200, await session(id, body.email));
  }
  if (url.pathname === "/auth/v1/token" && url.searchParams.get("grant_type") === "password") {
    const u = users.get(body.email);
    if (!u || u.password !== body.password)
      return send(400, { error_description: "Invalid login credentials" });
    return send(200, await session(u.id, body.email));
  }
  if (url.pathname === "/auth/v1/token" && url.searchParams.get("grant_type") === "refresh_token") {
    const email = refresh.get(body.refresh_token);
    if (!email) return send(400, { error_description: "Invalid refresh token" });
    const user = users.get(email);
    if (!user) return send(400, { error_description: "Unknown user" });
    return send(200, await session(user.id, email));
  }
  send(404, { msg: "not found" });
});
await new Promise<void>((r) => auth.listen(0, "127.0.0.1", r));
const authPort = (auth.address() as { port: number }).port;

const handle = createDb(tdb.url, { max: 5 });
const env = loadEnv({
  DATABASE_URL: tdb.url,
  SUPABASE_URL: `http://127.0.0.1:${authPort}`,
  SUPABASE_ANON_KEY: "e2e-anon",
  SUPABASE_JWT_SECRET: secret,
  NODE_ENV: "test",
});
// The real worker, replaying recorded model responses (no provider calls, no keys needed).
const fixtures = fileURLToPath(new URL("../test/fixtures/chat.json", import.meta.url));
const worker = await startWorker({
  databaseUrl: tdb.url,
  logger: createLogger("e2e-worker", "error"),
  logLevel: "error",
  modelFixtures: fixtures,
  embeddings: "hash",
});
const workflows = await dbosWorkflows(tdb.url);
const hub = await pgRunEventHub(handle.client);
const app = createApp({
  workflows,
  hub,
  env,
  db: handle.db,
  logger: createLogger("e2e", "error"),
  verifyToken: createTokenVerifier({ supabaseUrl: env.SUPABASE_URL, jwtSecret: secret }),
  email: disabledEmail,
  readiness: {},
});
const server = serve({ fetch: app.fetch, port: 0 }, (info) => {
  console.log(`KASAMA_API_URL=http://127.0.0.1:${info.port}`);
});

const stop = async () => {
  server.close();
  await workflows.close();
  await worker.stop();
  await hub.close();
  auth.close();
  await handle.close();
  await tdb.stop();
  process.exit(0);
};
process.on("SIGTERM", stop);
process.on("SIGINT", stop);
