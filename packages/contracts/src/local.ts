import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

/** Kinds of site that are off for Act by default (D-323 decision 6). */
export const SiteKind = z
  .enum(["banking", "health", "passwords", "government"])
  .openapi("SiteKind");

export const LocalCapabilities = z
  .object({
    shell: z.boolean().optional(),
    files: z.boolean().optional(),
    browser: z.boolean().optional(),
    desktop: z.boolean().optional(),
    /** Local MCP servers on this computer (D-096). */
    mcp: z.boolean().optional(),
    /** Messages on a Mac: read new iMessages and send replies for an iMessage chat app (D-134). */
    messages: z.boolean().optional(),
  })
  .openapi("LocalCapabilities");

export const LocalMcpServerInfo = z
  .object({
    key: z.string().regex(/^[a-z][a-z0-9_]{0,30}$/),
    label: z.string().trim().min(1).max(80),
    kind: z.enum(["stdio", "loopback"]),
    summary: z
      .string()
      .max(300)
      .openapi({ description: "Shown to the workspace, e.g. the command without its environment" }),
    timeout_s: z.number().int().min(10).max(7200).optional().openapi({
      description: "Longest a call may take (default 1800 s); progress keeps it alive",
    }),
    auth: z.enum(["none", "token", "header", "oauth"]).optional().openapi({
      description:
        "How the server signs in (D-363). The token, header or sign-in itself stays on the computer",
    }),
  })
  .openapi("LocalMcpServerInfo");

export const SetLocalMcpServersRequest = z
  .object({ servers: z.array(LocalMcpServerInfo).max(50) })
  .openapi("SetLocalMcpServersRequest");

export const LocalDevice = z
  .object({
    id: Uuid,
    org_id: Uuid,
    user_id: Uuid,
    computer_id: Uuid.nullable(),
    name: z.string(),
    platform: z.enum(["macos", "windows", "linux", "chrome"]).openapi({
      description:
        '"chrome": a browser-only device (Casama for Chrome, D-323): no computer, browser tools only',
    }),
    os_version: z.string().nullable().optional().openapi({
      description: 'What the desktop app reported when it last connected, e.g. "macOS 26.2"',
    }),
    capabilities: LocalCapabilities,
    allowed_roots: z.array(z.string()),
    allowed_bot_ids: z.array(Uuid),
    allowed_sites: z
      .array(z.string())
      .optional()
      .openapi({ description: "Browser: sites bots may act on without asking (D-323 C6)" }),
    blocked_sites: z
      .array(z.string())
      .optional()
      .openapi({ description: "Browser: sites bots may never act on" }),
    allowed_kinds: z.array(SiteKind).optional().openapi({
      description: "Browser: off-by-default kinds of site switched back on; they still ask",
    }),
    allowed_coding_agents: z.array(z.string()).optional().openapi({
      description:
        "Coding agents beyond the built-in five that the owner allowed on this computer (D-370)",
    }),
    enabled: z.boolean(),
    online: z.boolean(),
    last_seen_at: ts.nullable(),
    created_at: ts,
  })
  .openapi("LocalDevice");

export const CreateLocalDeviceRequest = z
  .object({
    org_id: Uuid,
    name: z.string().trim().min(1).max(80),
    platform: z.enum(["macos", "windows", "linux", "chrome"]),
  })
  .openapi("CreateLocalDeviceRequest");

export const CreatedLocalDevice = LocalDevice.extend({
  token: z
    .string()
    .openapi({ description: "Device token, shown once; the app keeps it in secure storage" }),
}).openapi("CreatedLocalDevice");

export const UpdateLocalDeviceRequest = z
  .object({
    name: z.string().trim().min(1).max(80).optional(),
    capabilities: LocalCapabilities.optional(),
    allowed_roots: z.array(z.string().min(1).max(1000)).max(20).optional(),
    allowed_bot_ids: z.array(Uuid).max(100).optional(),
    allowed_sites: z.array(z.string().min(1).max(253)).max(500).optional(),
    blocked_sites: z.array(z.string().min(1).max(253)).max(500).optional(),
    allowed_kinds: z.array(SiteKind).max(4).optional(),
    allowed_coding_agents: z
      .array(z.string().regex(/^[a-z][a-z0-9_]{1,31}$/))
      .max(100)
      .optional()
      .openapi({
        description:
          "Coding agents beyond the built-in five allowed on this computer (D-370); one Allow each",
      }),
    enabled: z.boolean().optional(),
  })
  .openapi("UpdateLocalDeviceRequest");

// ---------------------------------------------------------------- coding agents (D-370, D-371)

const resultMode = z
  .string()
  .regex(/^(json_result|marker|stream_json|tail|json_field:[A-Za-z_][A-Za-z0-9_]{0,31})$/)
  .openapi({
    description:
      "How the answer is read: json_result (a JSON `result`), marker (the agent writes it to {result_file}), json_field:<name>, stream_json or tail",
  });

export const CodingAgentInfo = z
  .object({
    id: z.string().openapi({ description: "What coding.delegate takes as `agent`" }),
    label: z.string(),
    bin: z.string().openapi({ description: "The command the desktop app looks for" }),
    where: z.array(z.string()).openapi({ description: "my_computer and/or bot_computer" }),
    needs_folder: z.boolean(),
    hint: z.string().nullable(),
    preallowed: z.boolean().openapi({
      description:
        "Runs whenever commands are on; any other agent needs one Allow on each computer (allowed_coding_agents)",
    }),
  })
  .openapi("CodingAgentInfo");

export const CodingAgentList = z
  .object({ items: z.array(CodingAgentInfo) })
  .openapi("CodingAgentList");

export const OwnCodingAgent = z
  .object({
    key: z.string().regex(/^[a-z][a-z0-9_]{0,23}$/),
    label: z.string().trim().min(1).max(40),
    bin: z.string().regex(/^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/),
    command: z.string().min(1).max(1000).openapi({
      description:
        "Template with {task} (optionally {folder}, {result_file}); every command in it starts with bin",
    }),
    result: resultMode,
    timeout_min: z.number().int().min(1).max(120).optional(),
  })
  .openapi("OwnCodingAgent");

export const OwnCodingAgentEntry = OwnCodingAgent.extend({
  id: z.string().openapi({ description: "own_<key>, what coding.delegate takes as `agent`" }),
}).openapi("OwnCodingAgentEntry");

export const OwnCodingAgentList = z
  .object({ items: z.array(OwnCodingAgentEntry) })
  .openapi("OwnCodingAgentList");

export const SetOwnCodingAgentsRequest = z
  .object({ agents: z.array(OwnCodingAgent).max(20) })
  .openapi("SetOwnCodingAgentsRequest");

export const TestOwnCodingAgentRequest = z
  .object({
    label: OwnCodingAgent.shape.label,
    bin: OwnCodingAgent.shape.bin,
    command: OwnCodingAgent.shape.command,
    result: resultMode,
    timeout_min: z.number().int().min(1).max(10).optional().openapi({
      description: "Longest the test may take (default 3 minutes)",
    }),
  })
  .openapi("TestOwnCodingAgentRequest");

export const CodingAgentTestResult = z
  .object({
    ok: z.boolean(),
    exit_code: z.number().int(),
    timed_out: z.boolean(),
    reply: z
      .string()
      .openapi({ description: "The answer as Casama reads it with the chosen result" }),
    output: z.string().openapi({ description: "The end of what the command printed" }),
    command: z.string().openapi({ description: "The command that ran" }),
  })
  .openapi("CodingAgentTestResult");
