import { describe, expect, it } from "vitest";
import {
  checkManifest,
  checkMcp,
  checkPlugin,
  insidePlugin,
  MCP_SCHEMA_1_0,
  PLUGIN_SCHEMA_1_0,
  PluginError,
} from "../src/agent-plugins.ts";

const files = (o: Record<string, unknown>) =>
  new Map(Object.entries(o).map(([k, v]) => [k, typeof v === "string" ? v : JSON.stringify(v)]));

describe("Agent Plugins 1.0", () => {
  it("rejects bad manifests and only warns about unknown fields", () => {
    expect(() => checkManifest({ name: "x" })).toThrow(PluginError);
    expect(() =>
      checkManifest({
        $schema: "https://agent-plugins.org/schemas/2.0.0/plugin.schema.json",
        name: "x",
      }),
    ).toThrow(/Unsupported/);
    for (const name of ["Bad", "a--b", "a..b", "-a", "a-", "x".repeat(65)])
      expect(() => checkManifest({ $schema: PLUGIN_SCHEMA_1_0, name })).toThrow(
        /valid plugin name/,
      );
    const w: string[] = [];
    expect(
      checkManifest({ $schema: PLUGIN_SCHEMA_1_0, name: "a", version: "not-semver", hooks: {} }, w),
    ).toMatchObject({ name: "a", version: "not-semver" });
    expect(w).toEqual(["Ignored unknown field hooks"]);
    expect(() =>
      checkManifest({ $schema: PLUGIN_SCHEMA_1_0, name: "a", author: { name: "x", phone: "1" } }),
    ).toThrow(/author.phone/);
  });

  it("checks servers per entry, beyond the schema", () => {
    const w: string[] = [];
    const servers = checkMcp(
      {
        $schema: MCP_SCHEMA_1_0,
        mcpServers: {
          ok: {
            type: "stdio",
            command: "./bin/server",
            args: ["--data", "${PLUGIN_DATA}/db"],
            cwd: "${PLUGIN_ROOT}",
          },
          npx: { type: "stdio", command: "npx", args: ["-y", "pkg"] },
          shell: { type: "stdio", command: "node server.js" },
          escape: { type: "stdio", command: "./bin/x", cwd: "./../up" },
          envroot: { type: "stdio", command: "x", env: { PLUGIN_ROOT: "/" } },
          remote: {
            type: "streamable-http",
            url: "https://mcp.example.com/mcp",
            headers: { "X-Client": "kasama" },
          },
          plain: { type: "streamable-http", url: "http://mcp.example.com/mcp" },
          local: { type: "streamable-http", url: "http://127.0.0.1:9000/mcp" },
          dup: { type: "streamable-http", url: "https://a.example", headers: { A: "1", a: "2" } },
          mixed: { type: "stdio", command: "x", url: "https://a.example" },
          weird: { type: "websocket", url: "wss://a" },
        },
      },
      w,
    );
    expect(servers.map((s) => s.key)).toEqual(["ok", "npx", "remote", "local"]);
    expect(w).toHaveLength(7);
    expect(checkMcp({ $schema: MCP_SCHEMA_1_0, mcpServers: {}, extra: 1 }, [])).toEqual([]);
    expect(insidePlugin("./a/../b")).toBe(true);
    expect(insidePlugin("./a/../../b")).toBe(false);
    expect(insidePlugin("a")).toBe(false);
  });

  it("reads a package: skills, servers, hosts and Kasama's secret declarations", () => {
    const p = checkPlugin(
      files({
        "plugin.json": {
          $schema: PLUGIN_SCHEMA_1_0,
          name: "weather",
          version: "1.2.0",
          extensions: {
            "com.kasama": {
              secrets: [
                {
                  name: "WEATHER_KEY",
                  server: "forecast",
                  env: "WEATHER_API_KEY",
                  description: "API key",
                },
                {
                  name: "MAPS_TOKEN",
                  server: "maps",
                  header: "Authorization",
                  format: "Bearer {{value}}",
                },
                { name: "LOST", server: "nope", env: "X" },
              ],
            },
          },
        },
        "mcp.json": {
          $schema: MCP_SCHEMA_1_0,
          mcpServers: {
            forecast: { type: "stdio", command: "node", args: ["${PLUGIN_ROOT}/server.js"] },
            maps: { type: "streamable-http", url: "https://maps.example.com/mcp" },
          },
        },
        "skills/plan-trip/SKILL.md": "---\nname: plan-trip\n---\nSteps",
        "skills/notes/README.md": "not a skill",
        "skills/deep/nested/SKILL.md": "not immediate",
      }),
    );
    expect(p.manifest.name).toBe("weather");
    expect(p.skills).toEqual([{ name: "plan-trip", path: "skills/plan-trip" }]);
    expect(p.servers.map((s) => s.key)).toEqual(["forecast", "maps"]);
    expect(p.hosts).toEqual(["maps.example.com"]);
    expect(p.secrets.map((s) => s.name)).toEqual(["WEATHER_KEY", "MAPS_TOKEN"]);
    expect(p.warnings).toContain("Ignored secret LOST: no server nope");
    expect(() => checkPlugin(files({ "mcp.json": "{}" }))).toThrow(/No plugin.json/);
  });
});
