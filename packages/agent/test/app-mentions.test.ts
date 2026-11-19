import { describe, expect, it } from "vitest";
import { z } from "zod";
import { mentionableAppsFromRows, partsApps, toolMatchesToolkit } from "../src/app-mentions.ts";
import {
  MENTIONED_TOOL_TOKENS,
  planLazyTools,
  rememberedTools,
  selectMentionedTools,
  toolGroup,
} from "../src/lazy-tools.ts";
import type { ToolDefinition } from "../src/tools/registry.ts";

const fakeTool = (name: string): ToolDefinition => ({
  name,
  description: `Tool ${name}`,
  risk: "low",
  schema: z.object({}),
  async execute() {
    return { content: "ok" };
  },
});

describe("toolGroup", () => {
  it("groups computer_mcp and a2a per integration", () => {
    expect(toolGroup("computer_mcp.figma.get_file")).toBe("computer_mcp.figma");
    expect(toolGroup("a2a.researcher.ask")).toBe("a2a.researcher");
    expect(toolGroup("composio.apps.gmail_fetch_emails")).toBe("composio.apps");
    expect(toolGroup("mcp.linear.list_issues")).toBe("mcp.linear");
  });
});

describe("toolMatchesToolkit", () => {
  it("matches Composio and Pipedream tool names by normalized toolkit prefix", () => {
    expect(toolMatchesToolkit("gmail_fetch_emails", "gmail")).toBe(true);
    expect(toolMatchesToolkit("googlecalendar_list_events", "googlecalendar")).toBe(true);
    expect(toolMatchesToolkit("slack_send_message", "slack")).toBe(true);
    expect(toolMatchesToolkit("gmail_fetch_emails", "slack")).toBe(false);
    expect(toolMatchesToolkit("gmailer_send", "gmail")).toBe(false);
  });
});

describe("mentionableAppsFromRows", () => {
  it("expands Composio and Pipedream hubs into per-app mentionables", () => {
    const out = mentionableAppsFromRows([
      {
        id: "hub-1",
        kind: "composio",
        name: "apps",
        status: "ok",
        config: { toolkits: ["gmail", "googlecalendar", "my_custom_crm"] },
      },
      {
        id: "hub-2",
        kind: "pipedream",
        name: "pd",
        status: "ok",
        config: { apps: ["linear"] },
      },
    ]);
    expect(out.map((a) => [a.integrationId, a.toolkit, a.label, a.appId])).toEqual([
      ["hub-1", "gmail", "Gmail", "gmail"],
      ["hub-1", "googlecalendar", "Google Calendar", "google_calendar"],
      ["hub-1", "my_custom_crm", "My Custom Crm", undefined],
      ["hub-2", "linear", "Linear", "linear"],
    ]);
  });

  it("uses catalog names for default slugs, preserves custom account labels, and uses config.label for local_mcp", () => {
    const out = mentionableAppsFromRows([
      {
        id: "mcp-1",
        kind: "mcp",
        name: "linear",
        status: "ok",
        config: { app: "linear" },
      },
      {
        id: "mcp-2",
        kind: "mcp",
        name: "Linear Eng",
        status: "ok",
        config: { app: "linear" },
      },
      {
        id: "local-1",
        kind: "local_mcp",
        name: "t3code_ab12cd",
        status: "ok",
        config: { label: "T3 Code" },
      },
    ]);
    expect(out.map((a) => [a.label, a.appId])).toEqual([
      ["Linear", "linear"],
      ["Linear Eng", "linear"],
      ["T3 Code", undefined],
    ]);
  });
});

describe("selectMentionedTools and rememberedTools", () => {
  it("preloads mentioned tools within MENTIONED_TOOL_TOKENS and skips oversized apps atomically", () => {
    const gmailTools = [
      fakeTool("composio.apps.gmail_fetch_emails"),
      fakeTool("composio.apps.gmail_send_email"),
    ];
    const slackTools = [fakeTool("composio.apps.slack_post_message")];
    const hugeTools = Array.from({ length: 60 }, (_, i) => fakeTool(`mcp.huge.tool_${i}`));
    const linearTools = [fakeTool("mcp.linear.list_issues")];
    const available = [...gmailTools, ...slackTools, ...hugeTools, ...linearTools];

    // 200 tokens per tool → gmail (400) fits, huge (12_000) exceeds 8_000 and is skipped,
    // linear (200) still fits.
    const { loaded, loadedIndices } = selectMentionedTools(
      available,
      [
        { group: "composio.apps", toolNames: gmailTools.map((t) => t.name) },
        { group: "mcp.huge", toolNames: hugeTools.map((t) => t.name) },
        { group: "mcp.linear", toolNames: linearTools.map((t) => t.name) },
      ],
      (defs) => defs.length * 200,
      MENTIONED_TOOL_TOKENS,
    );

    expect([...loadedIndices]).toEqual([0, 2]);
    expect(loaded.map((t) => t.name)).toEqual([
      "composio.apps.gmail_fetch_emails",
      "composio.apps.gmail_send_email",
      "mcp.linear.list_issues",
    ]);
    // Slack inside the same Composio hub was NOT loaded.
    expect(loaded.some((t) => t.name.includes("slack"))).toBe(false);
  });

  it("does not duplicate already-preloaded tools when loading remembered groups", () => {
    const tools = [
      fakeTool("memory.read"),
      ...Array.from({ length: 30 }, (_, i) => fakeTool(`browser.op_${i}`)),
      fakeTool("mcp.linear.list_issues"),
      fakeTool("mcp.linear.create_issue"),
      fakeTool("mcp.notion.search"),
    ];
    const plan = planLazyTools(tools, 10);
    expect(plan).not.toBeNull();
    const { loaded: mentioned } = selectMentionedTools(
      tools,
      [{ group: "mcp.linear", toolNames: ["mcp.linear.list_issues", "mcp.linear.create_issue"] }],
      (defs) => defs.length * 100,
    );
    const mentionedNames = new Set(mentioned.map((t) => t.name));
    const remembered = rememberedTools(
      plan!,
      ["mcp.linear", "mcp.notion"],
      (defs) => defs.length * 100,
      mentionedNames,
    );
    expect(remembered.map((t) => t.name)).toEqual(["mcp.notion.search"]);
  });
});

describe("partsApps", () => {
  it("extracts up to 3 valid app parts and ignores non-app or malformed parts", () => {
    const content = [
      { type: "text", text: "Hi @Gmail" },
      {
        type: "app",
        integration_id: "1",
        toolkit: "gmail",
        label: "Gmail",
        app_id: "gmail",
        source: "picker",
      },
      { type: "app", integration_id: "2", label: "Linear", source: "typed" },
      { type: "app", integration_id: "bad-missing-label" },
      { type: "app", integration_id: "3", label: "Notion" },
      { type: "app", integration_id: "4", label: "Slack" },
    ];
    const out = partsApps(content);
    expect(out).toHaveLength(3);
    expect(out.map((p) => p.label)).toEqual(["Gmail", "Linear", "Notion"]);
    expect(out[0]?.source).toBe("picker");
    expect(out[1]?.source).toBe("typed");
  });
});
