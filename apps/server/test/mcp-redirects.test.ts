import { describe, expect, it } from "vitest";
import {
  impersonatesKnownApp,
  isKnownRedirect,
  redirectProblem,
} from "../src/api/mcp-redirects.ts";

describe("hosted MCP redirect rules (security report 2026-11-20)", () => {
  it("accepts https, loopback http and an app's own scheme", () => {
    for (const u of [
      "https://claude.ai/api/mcp/auth_callback",
      "https://ai.example/cb",
      "http://localhost:33418/callback",
      "http://127.0.0.1:6274/oauth/callback",
      "http://[::1]:9000/cb",
      "cursor://anysphere.cursor-retrieval/oauth/callback",
      "com.example.app:/oauth",
    ])
      expect(redirectProblem(u), u).toBeNull();
  });

  it("refuses odd schemes, plain http elsewhere, credentials and fragments", () => {
    for (const u of [
      "http://evil.example/cb",
      "javascript:alert(1)",
      "JavaScript:alert(1)",
      "data:text/html,hi",
      "file:///etc/passwd",
      "blob:https://evil.example/x",
      "vbscript:x",
      "about:blank",
      "intent://x#Intent;end",
      "https://user:pw@evil.example/cb",
      "https://ai.example/cb#frag",
      "not a url",
    ])
      expect(redirectProblem(u), u).not.toBeNull();
  });

  it("knows well-known AI apps and the person's own device", () => {
    expect(isKnownRedirect("https://claude.ai/api/mcp/auth_callback")).toBe(true);
    expect(isKnownRedirect("https://chatgpt.com/connector_platform_oauth_redirect")).toBe(true);
    expect(isKnownRedirect("http://localhost:3000/cb")).toBe(true);
    expect(isKnownRedirect("cursor://anysphere.cursor-retrieval/oauth/callback")).toBe(true);
    expect(isKnownRedirect("https://claude.ai.evil.example/cb")).toBe(false);
    expect(isKnownRedirect("https://evilclaude.ai/cb")).toBe(false);
    expect(isKnownRedirect("com.example.app:/oauth")).toBe(false);
  });

  it("refuses a well-known name sending people elsewhere", () => {
    expect(impersonatesKnownApp("Claude", ["https://evil.example/cb"])).toBe(true);
    expect(impersonatesKnownApp("ChatGPT connector", ["https://evil.example/cb"])).toBe(true);
    expect(impersonatesKnownApp("Casama", ["https://evil.example/cb"])).toBe(true);
    expect(impersonatesKnownApp("Claude", ["https://claude.ai/api/mcp/auth_callback"])).toBe(false);
    expect(impersonatesKnownApp("Claude Code", ["http://localhost:4567/callback"])).toBe(false);
    expect(impersonatesKnownApp("Phone AI", ["https://ai.example/cb"])).toBe(false);
  });
});
