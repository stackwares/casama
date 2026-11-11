import { spawn } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createInterface } from "node:readline";
import { describe, expect, it } from "vitest";
import { checkFiles, checkPluginFolder, type PluginFile } from "../src/check.ts";

const example = new URL("../../../examples/hello-plugin/", import.meta.url).pathname;
const SCHEMA = "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json";
const MCP = "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json";

const file = (path: string, text: string | Buffer, executable = false): PluginFile => ({
  path,
  content: Buffer.isBuffer(text) ? text : Buffer.from(text),
  executable,
});
const manifest = (extra: object = {}) =>
  file("plugin.json", JSON.stringify({ $schema: SCHEMA, name: "demo", ...extra }));
const mcp = (servers: object) =>
  file("mcp.json", JSON.stringify({ $schema: MCP, mcpServers: servers }));
const skill = (name: string, md = `---\nname: ${name}\ndescription: Does ${name}\n---\n\nSteps.`) =>
  file(`skills/${name}/SKILL.md`, md);

describe("the example plugin", () => {
  it("is ready to install, with no warnings or tips", () => {
    const r = checkPluginFolder(example);
    expect(r.errors).toEqual([]);
    expect(r.warnings).toEqual([]);
    expect(r.tips.filter((t) => !t.includes("committed"))).toEqual([]);
    expect(r.skills.map((s) => s.name)).toEqual(["team-standup"]);
    expect(r.plugin?.servers.map((s) => s.key)).toEqual(["notes"]);
    expect(r.plugin?.secrets).toEqual([
      expect.objectContaining({ name: "NOTES_SIGNATURE", server: "notes", env: "NOTES_SIGNATURE" }),
    ]);
  });

  it("runs: its server answers MCP and saves signed notes in its data folder", async () => {
    const data = mkdtempSync(join(tmpdir(), "hello-plugin-"));
    const proc = spawn("node", [join(example, "server/notes.mjs")], {
      env: { ...process.env, NOTES_DIR: join(data, "notes"), NOTES_SIGNATURE: "Team Rocket" },
      stdio: ["pipe", "pipe", "inherit"],
    });
    const replies = createInterface({ input: proc.stdout! });
    const pending = new Map<number, (v: any) => void>();
    replies.on("line", (l) => {
      const m = JSON.parse(l);
      pending.get(m.id)?.(m);
    });
    let id = 0;
    const rpc = (method: string, params?: object) =>
      new Promise<any>((done) => {
        pending.set(++id, done);
        proc.stdin!.write(`${JSON.stringify({ jsonrpc: "2.0", id, method, params })}\n`);
      });
    try {
      const init = await rpc("initialize", {
        protocolVersion: "2025-06-18",
        capabilities: {},
        clientInfo: { name: "t", version: "1" },
      });
      expect(init.result.capabilities.tools).toBeDefined();
      proc.stdin!.write(
        `${JSON.stringify({ jsonrpc: "2.0", method: "notifications/initialized" })}\n`,
      );
      const list = await rpc("tools/list");
      const byName = Object.fromEntries(list.result.tools.map((t: any) => [t.name, t]));
      expect(Object.keys(byName).sort()).toEqual(["list_notes", "read_note", "save_note"]);
      // Risk in Kasama comes from these: read-only is low, the rest medium.
      expect(byName.list_notes.annotations.readOnlyHint).toBe(true);
      expect(byName.save_note.annotations.destructiveHint).toBe(false);
      await rpc("tools/call", {
        name: "save_note",
        arguments: { title: "Stand-up 2026-11-11", body: "All good." },
      });
      const read = await rpc("tools/call", {
        name: "read_note",
        arguments: { title: "Stand-up 2026-11-11" },
      });
      expect(read.result.content[0].text).toBe("All good.\n\n— Team Rocket\n");
      expect(readFileSync(join(data, "notes", "Stand-up 2026-11-11.md"), "utf8")).toContain(
        "Team Rocket",
      );
      const missing = await rpc("tools/call", { name: "read_note", arguments: { title: "nope" } });
      expect(missing.result.isError).toBe(true);
      const unknown = await rpc("no/such");
      expect(unknown.error.code).toBe(-32601);
    } finally {
      proc.kill();
      rmSync(data, { recursive: true, force: true });
    }
  });
});

describe("checkFiles", () => {
  it("refuses what Kasama refuses", () => {
    expect(checkFiles([]).errors).toEqual(["No plugin.json at the plugin's root"]);
    expect(checkFiles([file("plugin.json", "{")]).errors).toEqual(["plugin.json isn't valid JSON"]);
    expect(checkFiles([manifest({ name: "Bad Name" })]).ok).toBe(false);
    expect(
      checkFiles([
        file(
          "plugin.json",
          JSON.stringify({
            $schema: "https://agent-plugins.org/schemas/2.0.0/plugin.schema.json",
            name: "x",
          }),
        ),
      ]).errors[0],
    ).toMatch(/Kasama reads 1.0.0/);
  });

  it("refuses plugins over the size limits", () => {
    const many = Array.from({ length: 400 }, (_, i) => file(`f${i}.txt`, "x"));
    expect(checkFiles([manifest(), ...many]).errors[0]).toMatch(/up to 400/);
    expect(
      checkFiles([manifest(), file("big.bin", Buffer.alloc(11 * 1024 * 1024, 1))]).errors[0],
    ).toMatch(/up to 10 MB/);
  });

  it("reports what Kasama would skip", () => {
    const r = checkFiles([
      manifest({
        extensions: { "com.kasama": { secrets: [{ name: "lower", server: "x" }] } },
        colour: "red",
      }),
      mcp({
        shell: { type: "stdio", command: "node server.js" },
        plain: { type: "streamable-http", url: "http://example.com/mcp" },
        ok: { type: "streamable-http", url: "https://example.com/mcp" },
      }),
      skill("good"),
      skill("broken", "no front matter"),
      file("skills/big/SKILL.md", "---\nname: big\ndescription: d\n---\n"),
      file("skills/big/data.bin", Buffer.alloc(1024 * 1024 + 1, 1)),
    ]);
    expect(r.ok).toBe(true);
    expect(r.warnings).toEqual(
      expect.arrayContaining([
        "Ignored unknown field colour",
        "Skipped MCP server shell: command must be one program, not a shell line",
        "Skipped MCP server plain: url must use https",
        "Ignored a secret: needs an uppercase name and a server",
        expect.stringMatching(/^Skipped skill broken:/),
        "Skipped skill big: data.bin is over 1 MB",
      ]),
    );
    expect(r.skills.map((s) => s.name)).toEqual(["good"]);
    expect(r.plugin?.hosts).toEqual(["example.com"]);
  });

  it("gives run-time tips for servers on the bot's computer", () => {
    const r = checkFiles(
      [
        manifest(),
        mcp({
          missing: { type: "stdio", command: "./bin/server" },
          notExec: { type: "stdio", command: "./bin/run" },
          deno: { type: "stdio", command: "deno", args: ["run", "x.ts"] },
          gone: { type: "stdio", command: "node", args: ["${PLUGIN_ROOT}/dist/index.js"] },
          fetched: { type: "stdio", command: "npx", args: ["-y", "some-mcp"] },
        }),
        file("bin/run", "#!/bin/sh\n"),
        skill("renamed", "---\nname: other\ndescription: d\n---\n"),
      ],
      { untracked: ["skills/new/SKILL.md"] },
    );
    const tips = r.tips.join("\n");
    expect(tips).toMatch(/missing: \.\/bin\/server isn't in the plugin/);
    expect(tips).toMatch(/notExec: \.\/bin\/run isn't executable/);
    expect(tips).toMatch(/"deno" isn't in Kasama's default computer image/);
    expect(tips).toMatch(/gone: \$\{PLUGIN_ROOT\}\/dist\/index.js isn't in the plugin/);
    expect(tips).toMatch(/fetched: npx downloads packages/);
    expect(tips).toMatch(/Skill folder renamed is named "other"/);
    expect(tips).toMatch(/1 file isn't committed/);
  });

  it("warns about a plugin that adds nothing", () => {
    expect(checkFiles([manifest()]).warnings).toContain(
      "The plugin has no working skills or MCP servers, so it adds nothing",
    );
  });
});
