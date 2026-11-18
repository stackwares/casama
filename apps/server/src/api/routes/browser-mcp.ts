/**
 * /mcp/browser: the person's own browser as an MCP server for a coding agent on their computer
 * (D-323 C16). Streamable HTTP with plain JSON answers (no sessions, no server-sent events): the
 * agent's token (packages/domain/src/browser-mcp.ts) names the run and the browser, and every tool
 * call goes through /internal/browser/:device/call, in-process, so the owner-only check, the bot
 * allow-list, blocked sites, Casama's own addresses and the audit log all apply as for a bot.
 */

import type { BrowserResult } from "@casama/contracts";
import { BROWSER_MCP_TOOLS, type BrowserMcpClaims, verifyBrowserMcpToken } from "@casama/domain";
import { sql } from "drizzle-orm";
import type { Hono } from "hono";
import { rateLimit } from "../middleware/rate-limit.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { internalToken } from "./local.ts";

type Rpc = {
  jsonrpc?: string;
  id?: string | number | null;
  method?: string;
  params?: Record<string, unknown>;
};

/** Runs that are still going: the token stops working once its run ends. */
const LIVE = ["queued", "running", "waiting_approval", "waiting_takeover"];

export function registerBrowserMcpRoutes(app: Hono<AppEnv>, deps: AppDeps) {
  const secret = internalToken(deps.env);
  app.use(
    "/mcp/browser",
    rateLimit({
      perMinute: deps.env.RATE_LIMIT_PER_MINUTE * 5,
      trustedIpHeader: deps.env.TRUSTED_CLIENT_IP_HEADER,
    }),
  );
  app.all("/mcp/browser", async (c) => {
    const auth = c.req.header("authorization") ?? "";
    const claims = auth.startsWith("Bearer ")
      ? verifyBrowserMcpToken(auth.slice(7).trim(), secret)
      : null;
    if (!claims)
      return c.json(
        { error: "unauthorized", error_description: "This browser link has ended" },
        401,
      );
    if (c.req.method !== "POST")
      return c.json({ error: "method_not_allowed", error_description: "POST JSON-RPC" }, 405);
    const [run] = await deps.db.execute<{ status: string }>(
      sql`select status from public.runs where id = ${claims.run}::uuid`,
    );
    if (!run || !LIVE.includes(run.status))
      return c.json({ error: "unauthorized", error_description: "The run has finished" }, 401);
    const body = (await c.req.json().catch(() => null)) as Rpc | Rpc[] | null;
    if (!body) return c.json(rpcError(null, -32700, "Parse error"), 400);
    // One call at a time: MCP dropped batches (2025-06-18), and a batch of opens would fill the
    // person's real browser with tabs in one request.
    if (Array.isArray(body))
      return c.json(rpcError(null, -32600, "Send one request at a time"), 400);
    const one = await answer(body, claims);
    return one ? c.json(one, 200) : c.body(null, 202);
  });

  async function answer(m: Rpc, claims: BrowserMcpClaims) {
    // Notifications (no id) get no answer.
    if (m.id === undefined || m.id === null) return null;
    switch (m.method) {
      case "initialize":
        return ok(m.id, {
          protocolVersion:
            typeof m.params?.protocolVersion === "string" ? m.params.protocolVersion : "2025-06-18",
          capabilities: { tools: {} },
          serverInfo: { name: "casama-browser", version: "1.0.0" },
          instructions:
            "Tools that drive the user's own Chrome, in the bot's tab group. Steps that send, buy, delete or sign in ask the user first.",
        });
      case "ping":
        return ok(m.id, {});
      case "tools/list":
        return ok(m.id, {
          tools: BROWSER_MCP_TOOLS.map((t) => ({
            name: t.name,
            description: t.description,
            inputSchema: t.inputSchema,
            annotations: { readOnlyHint: !!t.readOnly, openWorldHint: true },
          })),
        });
      case "tools/call": {
        const name = String(m.params?.name ?? "");
        const tool = BROWSER_MCP_TOOLS.find((t) => t.name === name);
        if (!tool) return rpcError(m.id, -32602, `Unknown tool: ${name}`);
        const args = (m.params?.arguments ?? {}) as Record<string, unknown>;
        if (tool.action === "click" && typeof args.ref === "string" && !args.ref.startsWith("@"))
          args.ref = `@${args.ref}`;
        const res = await app.request(`/internal/browser/${claims.device}/call`, {
          method: "POST",
          headers: { "x-casama-internal": secret, "content-type": "application/json" },
          body: JSON.stringify({ action: tool.action, args, run_id: claims.run }),
        });
        const r = (await res.json().catch(() => ({
          ok: false,
          code: "bad_answer",
          message: "The browser's answer couldn't be read",
        }))) as BrowserResult;
        if (!r.ok) return ok(m.id, { content: [{ type: "text", text: r.message }], isError: true });
        const content: Array<Record<string, unknown>> = [{ type: "text", text: r.text || "Done" }];
        if (r.image)
          content.push({ type: "image", data: r.image.data, mimeType: r.image.media_type });
        return ok(m.id, { content });
      }
      default:
        return rpcError(m.id, -32601, `Method not found: ${m.method}`);
    }
  }
}

const ok = (id: string | number, result: unknown) => ({ jsonrpc: "2.0", id, result });
const rpcError = (id: string | number | null, code: number, message: string) => ({
  jsonrpc: "2.0",
  id,
  error: { code, message },
});
