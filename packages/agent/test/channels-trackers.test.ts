/** Linear and Jira issues as a way to give a bot work (D-285). */
import { createHmac } from "node:crypto";
import { describe, expect, it } from "vitest";
import { ADAPTERS, adfText, type WebhookRequest } from "../src/channels/index.ts";

const req = (body: string, headers: Record<string, string> = {}): WebhookRequest => ({
  method: "POST",
  url: "https://api.example.com/hooks/channels/x",
  headers,
  body,
});
const recorder = () => {
  const calls: Array<{ url: string; body: string; auth?: string }> = [];
  const f = (async (url: string, init: RequestInit = {}) => {
    calls.push({
      url,
      body: String(init.body),
      auth: (init.headers as Record<string, string>)?.authorization,
    });
    return new Response(JSON.stringify({ data: { commentCreate: { success: true } } }), {
      status: 200,
    });
  }) as unknown as typeof fetch;
  return { calls, f };
};

describe("Linear", () => {
  const a = ADAPTERS.linear;
  const cfg = { assignee_id: "bot-user", api_base: "http://linear.test" };
  it("checks the signature and hears an issue being assigned to the bot", () => {
    const body = JSON.stringify({
      type: "Issue",
      action: "update",
      webhookTimestamp: Date.now(),
      actor: { id: "ana", name: "Ana" },
      updatedFrom: { assigneeId: null },
      data: {
        id: "iss1",
        identifier: "ENG-12",
        title: "Fix login",
        description: "It loops",
        assigneeId: "bot-user",
      },
    });
    const sig = createHmac("sha256", "whs").update(body).digest("hex");
    expect(a.verify(req(body, { "linear-signature": sig }), cfg, { webhook_secret: "whs" })).toBe(
      true,
    );
    expect(a.verify(req(body, { "linear-signature": "00" }), cfg, { webhook_secret: "whs" })).toBe(
      false,
    );
    const [m] = a.normalize(req(body), cfg);
    expect(m).toMatchObject({
      threadKey: "linear:iss1",
      sender: "ana",
      subject: "ENG-12 Fix login",
      reply: { issue_id: "iss1" },
    });
    expect(m?.text).toContain("It loops");
    // Edits that don't change the assignee, and the bot's own changes, are ignored.
    const edit = JSON.parse(body);
    edit.updatedFrom = { title: "Old" };
    expect(a.normalize(req(JSON.stringify(edit)), cfg)).toEqual([]);
    edit.actor = { id: "bot-user" };
    expect(a.normalize(req(JSON.stringify(edit)), cfg)).toEqual([]);
  });
  it("replies as a comment on the issue", async () => {
    const { calls, f } = recorder();
    await a.send(cfg, { api_key: "lin_api_x" }, { issue_id: "iss1" }, "Fixed in #42.", f);
    expect(calls[0]?.url).toBe("http://linear.test/graphql");
    expect(calls[0]?.auth).toBe("lin_api_x");
    expect(JSON.parse(calls[0]!.body).variables).toEqual({
      input: { issueId: "iss1", body: "Fixed in #42." },
    });
  });
});

describe("Jira", () => {
  const a = ADAPTERS.jira;
  const cfg = {
    assignee_account_id: "bot-acc",
    site_url: "https://acme.atlassian.net",
    email: "bot@acme.com",
    api_base: "http://jira.test",
  };
  it("checks the signature and hears an issue being assigned to the bot, reading its description", () => {
    const body = JSON.stringify({
      webhookEvent: "jira:issue_updated",
      timestamp: 1,
      user: { accountId: "ana", displayName: "Ana" },
      changelog: { items: [{ field: "assignee", to: "bot-acc" }] },
      issue: {
        id: "10001",
        key: "OPS-7",
        fields: {
          summary: "Rotate the keys",
          assignee: { accountId: "bot-acc" },
          description: {
            type: "doc",
            content: [{ type: "paragraph", content: [{ type: "text", text: "All three." }] }],
          },
        },
      },
    });
    const sig = `sha256=${createHmac("sha256", "js").update(body).digest("hex")}`;
    expect(a.verify(req(body, { "x-hub-signature": sig }), cfg, { webhook_secret: "js" })).toBe(
      true,
    );
    const [m] = a.normalize(req(body), cfg);
    expect(m).toMatchObject({
      threadKey: "jira:10001",
      sender: "ana",
      subject: "OPS-7 Rotate the keys",
      reply: { issue_key: "OPS-7" },
    });
    expect(m?.text).toContain("All three.");
  });
  it("replies as a comment in Atlassian's document format", async () => {
    const { calls, f } = recorder();
    await a.send(cfg, { api_token: "tok" }, { issue_key: "OPS-7" }, "Done.\n\nAll rotated.", f);
    expect(calls[0]?.url).toBe("http://jira.test/rest/api/3/issue/OPS-7/comment");
    expect(calls[0]?.auth).toBe(`Basic ${Buffer.from("bot@acme.com:tok").toString("base64")}`);
    expect(JSON.parse(calls[0]!.body).body.content).toHaveLength(2);
    expect(
      adfText({
        type: "doc",
        content: [{ type: "paragraph", content: [{ type: "text", text: "Hi" }] }],
      }),
    ).toBe("Hi\n");
  });
});
