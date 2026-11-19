/**
 * End-to-end `@App` mentions (D-434):
 * - Direct chat: explicit picker refs + plain-text `@App` mentions stored as `{ type: "app" }` parts.
 * - Edit message: re-resolves `@App` parts.
 * - Run loop: preloads mentioned app tools (including hub-toolkit filtering) before Turn 1 under
 *   lazy loading, appends the one-line hint to model input only, and silently skips detached apps.
 * - Group chat: bot name wins plain-text collision; unavailable app posts `notice` (`app_not_available`).
 * - Chat apps: inbound messages resolve `@App` text mentions into `{ type: "app" }` parts.
 */
import {
  builtinTools,
  CredentialResolver,
  directSteps,
  type GatewayEvent,
  handleInbound,
  hashEmbedder,
  type ModelGateway,
  type ModelRequest,
  PostgresMemoryStore,
  registerToolsLoad,
  runAgent,
} from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let orgId: string;
let credId: string;
let leadBot: string;
let opsBot: string;
let linearBot: string;
let composioId: string;
let linearIntId: string;

const makeScriptedGateway = (captured: ModelRequest[]): ModelGateway => ({
  async *stream(req: ModelRequest): AsyncIterable<GatewayEvent> {
    captured.push(req);
    yield { type: "text", text: "All checked." };
    yield {
      type: "finish",
      finishReason: "stop",
      model: req.model.model,
      usage: { inputTokens: 10, outputTokens: 5 },
    };
  },
});

const createBot = async (name: string) =>
  (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name,
          persona_md: `You are ${name}.`,
          visibility: "team",
          model_policy: { primary: { credential_id: credId, model: "openai/gpt-4o-mini" } },
        },
      }),
    )
  ).id as string;

beforeAll(async () => {
  h = await startHarness();
  owner = await h.user("app-mentions-owner@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", {
        method: "POST",
        token: owner.token,
        json: { name: "MentionsOrg" },
      }),
    )
  ).id as string;
  await h.tdb
    .admin`update public.entitlements set limits = limits - 'max_bots' where org_id = ${orgId}`;
  credId = (
    await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          provider: "openrouter",
          label: "k",
          api_key: "sk-or-v1-abcdefabcdef",
        },
      }),
    )
  ).id as string;

  leadBot = await createBot("Lead");
  opsBot = await createBot("Ops");
  linearBot = await createBot("Linear");

  // Composio hub with Gmail + Slack tools cached.
  const [comp] = await h.tdb.admin<{ id: string }[]>`
    insert into public.integrations (org_id, kind, name, status, config, tools_cache, tools_cached_at)
    values (
      ${orgId}::uuid, 'composio', 'apps', 'ok',
      ${h.tdb.admin.json({ toolkits: ["gmail", "slack"] })},
      ${h.tdb.admin.json([
        {
          name: "gmail_fetch_emails",
          description: "Fetch Gmail emails",
          inputSchema: { type: "object" },
        },
        {
          name: "gmail_send_email",
          description: "Send Gmail email",
          inputSchema: { type: "object" },
        },
        {
          name: "slack_post_message",
          description: "Post Slack message",
          inputSchema: { type: "object" },
        },
        {
          name: "slack_list_channels",
          description: "List Slack channels",
          inputSchema: { type: "object" },
        },
      ])},
      now()
    )
    returning id`;
  composioId = comp!.id;

  // Direct MCP Linear integration with cached tools.
  const [lin] = await h.tdb.admin<{ id: string }[]>`
    insert into public.integrations (org_id, kind, name, status, config, tools_cache, tools_cached_at)
    values (
      ${orgId}::uuid, 'mcp', 'linear', 'ok',
      ${h.tdb.admin.json({ app: "linear", url: "https://mcp.linear.app/sse" })},
      ${h.tdb.admin.json([
        { name: "list_issues", description: "List Linear issues", inputSchema: { type: "object" } },
        {
          name: "create_issue",
          description: "Create Linear issue",
          inputSchema: { type: "object" },
        },
      ])},
      now()
    )
    returning id`;
  linearIntId = lin!.id;

  // Attach Composio (Gmail+Slack) to Lead; attach Linear to Ops only.
  await h.tdb.admin`
    insert into public.bot_integrations (org_id, bot_id, integration_id)
    values (${orgId}::uuid, ${leadBot}::uuid, ${composioId}::uuid), (${orgId}::uuid, ${opsBot}::uuid, ${linearIntId}::uuid)`;
}, 60_000);

afterAll(async () => h?.stop());

describe("@App mentions end-to-end", () => {
  it("stores picked and typed app parts, preloads only the mentioned hub toolkit on Turn 1, and appends hint in memory only", async () => {
    const conv = (
      await j(
        await h.request("/v1/conversations", {
          method: "POST",
          token: owner.token,
          json: { bot_id: leadBot, title: "Inbox" },
        }),
      )
    ).id as string;

    const sent = await j(
      await h.request(`/v1/conversations/${conv}/messages`, {
        method: "POST",
        token: owner.token,
        json: {
          text: "Check @Gmail for receipts",
          apps: [{ integration_id: composioId, toolkit: "gmail" }],
        },
      }),
    );

    const [msg] = await h.tdb.admin<{ content: Array<Record<string, unknown>> }[]>`
      select content from public.messages where id = ${sent.message_id}::uuid`;
    expect(msg?.content).toEqual([
      { type: "text", text: "Check @Gmail for receipts" },
      {
        type: "app",
        integration_id: composioId,
        toolkit: "gmail",
        label: "Gmail",
        app_id: "gmail",
        source: "picker",
      },
    ]);

    // Execute the run with a low lazyToolsThreshold so lazy mode is active.
    const captured: ModelRequest[] = [];
    const embedder = hashEmbedder();
    const tools = builtinTools({
      db: h.handle.db,
      memory: async () => new PostgresMemoryStore(h.handle.db, embedder),
    });
    registerToolsLoad(tools);
    const out = await runAgent(
      sent.run_id as string,
      {
        db: h.handle.db,
        gateway: makeScriptedGateway(captured),
        tools,
        credentials: new CredentialResolver(h.handle.db),
        embedderFor: async () => embedder,
        step: directSteps,
        deltaIntervalMs: 20,
        cancelPollMs: 50,
        fallback: { backoffMs: 1 },
        lazyToolsThreshold: 1,
      } as never,
    );
    if (out.status !== "completed") {
      const [r] = await h.tdb.admin<{ error: string | null }[]>`
        select error from public.runs where id = ${sent.run_id}::uuid`;
      throw new Error(`runAgent failed: ${JSON.stringify(r?.error)}`);
    }
    expect(out.status).toBe("completed");

    expect(captured.length).toBeGreaterThanOrEqual(1);
    const firstReq = captured[0]!;
    const offeredTools = (firstReq.tools ?? []).map((t) => t.name);
    // Gmail tools preloaded on Turn 1 without tools.load; Slack tools from same hub NOT preloaded.
    expect(offeredTools).toContain("composio__apps__gmail_fetch_emails");
    expect(offeredTools).toContain("composio__apps__gmail_send_email");
    expect(offeredTools).not.toContain("composio__apps__slack_post_message");
    expect(offeredTools).not.toContain("composio__apps__slack_list_channels");
    const lastUser = [...firstReq.messages].reverse().find((m) => m.role === "user");
    expect(typeof lastUser?.content === "string" ? lastUser.content : "").toContain(
      "The person pointed at these apps for this message: Gmail (composio.apps). Use them if the request needs an app.",
    );
    // Stored message text in DB was NOT modified by the in-memory model hint.
    const [afterRun] = await h.tdb.admin<{ content: Array<Record<string, unknown>> }[]>`
      select content from public.messages where id = ${sent.message_id}::uuid`;
    expect(afterRun?.content[0]).toEqual({
      type: "text",
      text: "Check @Gmail for receipts",
    });
  });

  it("resolves plain-text @App mentions and re-resolves on editMessage", async () => {
    const conv = (
      await j(
        await h.request("/v1/conversations", {
          method: "POST",
          token: owner.token,
          json: { bot_id: opsBot, title: "Issues" },
        }),
      )
    ).id as string;

    const sent = await j(
      await h.request(`/v1/conversations/${conv}/messages`, {
        method: "POST",
        token: owner.token,
        json: { text: "Triage @linear backlog" },
      }),
    );

    const [msg] = await h.tdb.admin<{ content: Array<Record<string, unknown>> }[]>`
      select content from public.messages where id = ${sent.message_id}::uuid`;
    expect(msg?.content).toEqual([
      { type: "text", text: "Triage @linear backlog" },
      {
        type: "app",
        integration_id: linearIntId,
        label: "Linear",
        app_id: "linear",
        source: "typed",
      },
    ]);

    // Finish the initial run so editMessage is allowed.
    await h.tdb
      .admin`update public.runs set status = 'completed', ended_at = now() where id = ${sent.run_id}::uuid`;
    // Edit removes @linear -> edited message has no app parts.
    const edited = await j(
      await h.request(`/v1/conversations/${conv}/messages/${sent.message_id}/edit`, {
        method: "POST",
        token: owner.token,
        json: { text: "Just say hi" },
      }),
    );
    const [editedMsg] = await h.tdb.admin<{ content: Array<Record<string, unknown>> }[]>`
      select content from public.messages where id = ${edited.message_id}::uuid`;
    expect(editedMsg?.content).toEqual([{ type: "text", text: "Just say hi" }]);
  });

  it("in group chats, bot name wins plain-text collision and unavailable app emits app_not_available notice", async () => {
    // Attach Linear integration to linearBot as well so we test bot-vs-app text collision.
    await h.tdb.admin`
      insert into public.bot_integrations (org_id, bot_id, integration_id)
      values (${orgId}::uuid, ${linearBot}::uuid, ${linearIntId}::uuid) on conflict do nothing`;

    const group = (
      await j(
        await h.request("/v1/conversations", {
          method: "POST",
          token: owner.token,
          json: {
            bot_id: leadBot,
            bot_ids: [opsBot, linearBot],
            title: "Triage",
          },
        }),
      )
    ).id as string;

    // 1. Plain-text "@Linear hi": bot named Linear wins; no app part stored.
    const collision = await j(
      await h.request(`/v1/conversations/${group}/messages`, {
        method: "POST",
        token: owner.token,
        json: { text: "@Linear hi" },
      }),
    );
    const [colMsg] = await h.tdb.admin<{ content: Array<Record<string, unknown>> }[]>`
      select content from public.messages where id = ${collision.message_id}::uuid`;
    expect(colMsg?.content.some((p) => p.type === "app")).toBe(false);

    // 2. Picking Linear app while waking only @Lead (which does not have Linear) posts notice.
    const unavail = await j(
      await h.request(`/v1/conversations/${group}/messages`, {
        method: "POST",
        token: owner.token,
        json: {
          text: "@Lead check the backlog",
          apps: [{ integration_id: linearIntId }],
        },
      }),
    );
    const notices = await h.tdb.admin<{ payload: { code: string; message: string } }[]>`
      select payload from public.run_events
      where run_id = ${unavail.run_id}::uuid and type = 'notice'`;
    expect(notices).toEqual([
      {
        payload: {
          code: "app_not_available",
          message: "@Lead doesn't have Linear connected.",
        },
      },
    ]);
  });

  it("resolves @App mentions from inbound chat app messages (Telegram)", async () => {
    const [ch] = await h.tdb.admin<{ id: string }[]>`
      insert into public.channels (org_id, bot_id, kind, name, created_by, allowed_senders, config)
      values (
        ${orgId}::uuid, ${leadBot}::uuid, 'telegram', 'Bot', ${owner.id}::uuid,
        array['tg-user-1']::text[],
        ${h.tdb.admin.json({})}
      )
      returning id`;

    const runIds = await handleInbound(
      h.handle.db,
      {
        id: ch!.id,
        org_id: orgId,
        bot_id: leadBot,
        kind: "telegram",
        name: "Bot",
        enabled: true,
        config: {},
        allowed_senders: ["tg-user-1"],
        created_by: owner.id,
        secrets: {},
      },
      [
        {
          messageId: "tg-msg-1",
          sender: "tg-user-1",
          senderName: "Alice",
          threadKey: "chat-1",
          text: "Check @Gmail for my flight confirmation",
          reply: { chat_id: "chat-1" },
        },
      ],
      {
        startRoutine: async () => null,
      },
    );
    expect(runIds.length).toBe(1);
    const runId = runIds[0]!;
    const [msg] = await h.tdb.admin<{ content: Array<Record<string, unknown>> }[]>`
      select content from public.messages where run_id = ${runId}::uuid and role = 'user'`;
    expect(msg?.content).toEqual(
      expect.arrayContaining([
        {
          type: "app",
          integration_id: composioId,
          toolkit: "gmail",
          label: "Gmail",
          app_id: "gmail",
          source: "typed",
        },
      ]),
    );
  });
});
