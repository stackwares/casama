#!/usr/bin/env node
/**
 * kasama-mcp: stdio MCP server. Add it to your coding tool, for example
 *   claude mcp add kasama -- npx -y @kasama/mcp
 * Settings: KASAMA_API_URL (default from `kasama config`, else http://localhost:8787), and either
 * the CLI login (`kasama login`) or KASAMA_TOKEN.
 */
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { createKasamaMcpServer, defaultSessionFile, KasamaApi } from "./server.ts";

const configFile = join(dirname(defaultSessionFile()), "config.json");
const saved = existsSync(configFile)
  ? (JSON.parse(readFileSync(configFile, "utf8")) as { api_url?: string })
  : {};
const api = new KasamaApi({
  apiUrl: process.env.KASAMA_API_URL ?? saved.api_url ?? "http://localhost:8787",
  token: process.env.KASAMA_TOKEN,
});
await createKasamaMcpServer(api).connect(new StdioServerTransport());
