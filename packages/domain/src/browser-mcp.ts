/**
 * Coding agents check their work in the person's own browser (D-323 C16). When `coding.delegate`
 * runs Claude Code or Codex on the person's computer and their paired Chrome lets the bot in, the
 * agent gets an MCP server, `<API>/mcp/browser`, whose tools drive that browser through the same
 * path as the bot's own browser tools (the extension's rules, asks and blocked sites all apply).
 *
 * Its token names the run and the browser, ends with the agent's time limit, and is signed with
 * the server's internal token, so nothing is stored. A run that has finished can't use it.
 */
import { createHmac, timingSafeEqual } from "node:crypto";

export interface BrowserMcpClaims {
  /** The run the coding agent works for. */
  run: string;
  /** The paired browser (local_devices.id). */
  device: string;
  /** Unix seconds. */
  exp: number;
}

const PREFIX = "kbmcp_";

const sign = (body: string, secret: string) =>
  createHmac("sha256", `browser-mcp:${secret}`).update(body).digest("base64url");

export function signBrowserMcpToken(c: BrowserMcpClaims, secret: string): string {
  const body = Buffer.from(JSON.stringify(c)).toString("base64url");
  return `${PREFIX}${body}.${sign(body, secret)}`;
}

/** The claims of a token this server signed, or null when it's forged, malformed or expired. */
export function verifyBrowserMcpToken(
  token: string,
  secret: string,
  now = Date.now(),
): BrowserMcpClaims | null {
  if (!token.startsWith(PREFIX)) return null;
  const [body, mac] = token.slice(PREFIX.length).split(".");
  if (!body || !mac) return null;
  const want = Buffer.from(sign(body, secret));
  const got = Buffer.from(mac);
  if (want.length !== got.length || !timingSafeEqual(want, got)) return null;
  try {
    const c = JSON.parse(Buffer.from(body, "base64url").toString()) as BrowserMcpClaims;
    if (typeof c.run !== "string" || typeof c.device !== "string" || typeof c.exp !== "number")
      return null;
    return c.exp * 1000 > now ? c : null;
  } catch {
    return null;
  }
}

type Json = Record<string, unknown>;
const ref = { type: "string", description: "A ref from the last snapshot, e.g. @e3" };

/** The tools a coding agent gets, each one browser action. */
export const BROWSER_MCP_TOOLS: Array<{
  name: string;
  action: string;
  description: string;
  inputSchema: Json;
  readOnly?: boolean;
}> = [
  {
    name: "open",
    action: "open",
    description:
      "Open an address in the person's own Chrome, in the bot's tab group. Local addresses (http://localhost:3000) work. Then use snapshot.",
    inputSchema: { type: "object", properties: { url: { type: "string" } }, required: ["url"] },
  },
  {
    name: "snapshot",
    action: "snapshot",
    description:
      "Accessibility snapshot of the current page; interactive elements get refs (@e1, @e2) for click and fill.",
    inputSchema: { type: "object", properties: { interactive_only: { type: "boolean" } } },
    readOnly: true,
  },
  {
    name: "read",
    action: "read",
    description: "The current page's main text.",
    inputSchema: { type: "object", properties: {} },
    readOnly: true,
  },
  {
    name: "click",
    action: "click",
    description:
      "Click an element by ref. Buttons that send, buy, delete, publish or sign in ask the person first.",
    inputSchema: { type: "object", properties: { ref }, required: ["ref"] },
  },
  {
    name: "fill",
    action: "fill",
    description: "Clear a form field by ref and type text into it.",
    inputSchema: {
      type: "object",
      properties: { ref, text: { type: "string" } },
      required: ["ref", "text"],
    },
  },
  {
    name: "press",
    action: "press",
    description: "Press a key, e.g. Enter, Tab, Escape.",
    inputSchema: { type: "object", properties: { key: { type: "string" } }, required: ["key"] },
  },
  {
    name: "scroll",
    action: "scroll",
    description: "Scroll the page up or down.",
    inputSchema: {
      type: "object",
      properties: {
        direction: { type: "string", enum: ["up", "down"] },
        amount: { type: "number" },
      },
      required: ["direction"],
    },
  },
  {
    name: "screenshot",
    action: "screenshot",
    description: "A picture of the current page.",
    inputSchema: { type: "object", properties: {} },
    readOnly: true,
  },
  {
    name: "wait",
    action: "wait",
    description:
      "Wait for text to appear on the page, or a number of milliseconds (at most 30000).",
    inputSchema: {
      type: "object",
      properties: { text: { type: "string" }, ms: { type: "number" } },
    },
    readOnly: true,
  },
  {
    name: "console",
    action: "console",
    description: "The page's console messages and errors.",
    inputSchema: { type: "object", properties: {} },
    readOnly: true,
  },
  {
    name: "network",
    action: "network",
    description:
      "The page's recent network requests (method, status, address), optionally filtered.",
    inputSchema: { type: "object", properties: { filter: { type: "string" } } },
    readOnly: true,
  },
  {
    name: "tabs",
    action: "tabs",
    description: "The tabs in the bot's tab group.",
    inputSchema: { type: "object", properties: {} },
    readOnly: true,
  },
];

/** What the agent is told, after its task. */
export const BROWSER_MCP_HINT =
  "To check your work in a browser, use the casama_browser tools: they drive the user's own Chrome (open, snapshot, click, fill, screenshot, console). Local addresses such as http://localhost:3000 work.";
