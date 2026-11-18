#!/usr/bin/env node
/**
 * casama-mcp: stdio MCP server. Add it to your coding tool, for example
 *   claude mcp add casama -- npx -y @casama/mcp
 * Settings: CASAMA_API_URL (default from `casama config`, else https://api.casama.ai), and either
 * the CLI login (`casama login`) or CASAMA_TOKEN. CASAMA_DOCS_URL points the docs tools at another
 * docs site (default https://docs.casama.ai), CASAMA_GALLERY_URL the gallery (default
 * https://gallery.casama.ai) for gallery_search.
 *
 * `casama-mcp --docs-only` serves just the docs tools, gallery_search and check_plugin, with no sign-in.
 */
import { existsSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CasamaApi,
  createCasamaDocsMcpServer,
  createCasamaMcpServer,
  defaultSessionFile,
  type PluginCheckResult,
  RemoteDocs,
  RemoteGallery,
} from "./server.ts";

const configFile = join(dirname(defaultSessionFile()), "config.json");
const saved = existsSync(configFile)
  ? (JSON.parse(readFileSync(configFile, "utf8")) as { api_url?: string })
  : {};
const docs = new RemoteDocs({ docsUrl: process.env.CASAMA_DOCS_URL });
const gallery = new RemoteGallery({ galleryUrl: process.env.CASAMA_GALLERY_URL });

// check_plugin runs the same checks as `npx @casama/plugin-check`, when that package is installed.
let checker: ((dir: string) => PluginCheckResult) | undefined;
try {
  const { checkPluginFolder } = await import("@casama/plugin-check");
  checker = checkPluginFolder;
} catch {
  checker = undefined;
}
const checkPlugin = checker
  ? (dir: string) => {
      const full = resolve(dir);
      if (!existsSync(full)) throw new Error(`No folder at ${full}`);
      return (checker as (d: string) => PluginCheckResult)(full);
    }
  : undefined;

const server = process.argv.includes("--docs-only")
  ? createCasamaDocsMcpServer(docs, { checkPlugin, gallery })
  : createCasamaMcpServer(
      new CasamaApi({
        apiUrl: process.env.CASAMA_API_URL ?? saved.api_url ?? "https://api.casama.ai",
        token: process.env.CASAMA_TOKEN,
      }),
      { docs, checkPlugin, gallery },
    );
await server.connect(new StdioServerTransport());
