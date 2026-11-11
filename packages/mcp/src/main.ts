#!/usr/bin/env node
/**
 * casama-mcp: stdio MCP server. Add it to your coding tool, for example
 *   claude mcp add casama -- npx -y @casama/mcp
 * Settings: CASAMA_API_URL (default from `casama config`, else http://localhost:8787), and either
 * the CLI login (`casama login`) or CASAMA_TOKEN.
 */
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CasamaApi, createCasamaMcpServer, defaultSessionFile } from "./server.ts";

const configFile = join(dirname(defaultSessionFile()), "config.json");
const saved = existsSync(configFile)
  ? (JSON.parse(readFileSync(configFile, "utf8")) as { api_url?: string })
  : {};
const api = new CasamaApi({
  apiUrl: process.env.CASAMA_API_URL ?? saved.api_url ?? "http://localhost:8787",
  token: process.env.CASAMA_TOKEN,
});
await createCasamaMcpServer(api).connect(new StdioServerTransport());
