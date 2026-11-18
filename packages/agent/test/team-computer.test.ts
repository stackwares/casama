import type { ExecChunk, ExecOptions, SandboxHandle } from "@casama/sandbox";
import { describe, expect, it } from "vitest";
import { folderSlug, homeRelative, inTeamFolder, withHomePaths } from "../src/team-computer.ts";

/** Team computer layout (D-148): folder names and paths that start in the bot's folder. */
describe("team computer folders", () => {
  it("folder names from bot names", () => {
    expect(folderSlug("Research Bot!")).toBe("research-bot");
    expect(folderSlug("Café  Ops")).toBe("cafe-ops");
    expect(folderSlug("🤖")).toBe("bot");
    expect(folderSlug("a".repeat(80))).toHaveLength(40);
  });

  it("relative paths and commands start in the bot's folder; shared/, bots/ and absolute paths don't", async () => {
    const calls: string[] = [];
    const base = {
      ref: "c1",
      async *exec(cmd: string, opts?: ExecOptions): AsyncIterable<ExecChunk> {
        calls.push(`exec ${cmd} @${opts?.cwd ?? ""}`);
        yield { type: "exit", code: 0, timedOut: false, killed: false, truncated: false };
      },
      readFile: async (p: string) => {
        calls.push(`read ${p}`);
        return new Uint8Array();
      },
      writeFile: async (p: string) => {
        calls.push(`write ${p}`);
      },
      listDir: async (p: string) => {
        calls.push(`list ${p}`);
        return [];
      },
      search: async (_q: string, p?: string) => {
        calls.push(`search ${p ?? "(all)"}`);
        return [];
      },
      deleteFile: async (p: string) => {
        calls.push(`delete ${p}`);
      },
    } as unknown as SandboxHandle;
    const h = inTeamFolder(base, "researcher");
    await h.writeFile("notes.md", new Uint8Array());
    await h.writeFile("shared/plan.md", new Uint8Array());
    await h.readFile("/etc/hostname");
    await h.readFile("~/.bashrc");
    await h.listDir("");
    await h.listDir("bots/designer");
    await h.search("x");
    await h.search("x", "src");
    for await (const _ of h.exec("ls")) {
    }
    for await (const _ of h.exec("ls", { cwd: "src" })) {
    }
    for await (const _ of h.exec("ls", { cwd: "/tmp" })) {
    }
    expect(calls).toEqual([
      "exec mkdir -p /home/casama/workspace/bots/researcher /home/casama/workspace/shared @",
      "write bots/researcher/notes.md",
      "write shared/plan.md",
      "read /etc/hostname",
      "read ~/.bashrc",
      "list bots/researcher",
      "list bots/designer",
      "search (all)",
      "search bots/researcher/src",
      "exec ls @/home/casama/workspace/bots/researcher",
      "exec ls @/home/casama/workspace/bots/researcher/src",
      "exec ls @/tmp",
    ]);
    expect(h.resolvePath?.("report.md")).toBe("bots/researcher/report.md");
    expect(h.resolvePath?.("bots/researcher/report.md")).toBe("bots/researcher/report.md");
  });
});

describe("home-folder paths (the form bots link files with)", () => {
  it("reads workspace/... as under ~/workspace, so a written file is where its link points", async () => {
    expect(homeRelative("workspace/bots/casama/report.md")).toBe("bots/casama/report.md");
    expect(homeRelative("./workspace/report.md")).toBe("report.md");
    expect(homeRelative("workspace")).toBe("");
    expect(homeRelative("notes/workspace/a.md")).toBe("notes/workspace/a.md");
    expect(homeRelative("/home/casama/workspace/a.md")).toBe("/home/casama/workspace/a.md");

    const writes: string[] = [];
    const base = {
      ref: "c1",
      async *exec() {},
      writeFile: async (p: string) => {
        writes.push(p);
      },
    } as unknown as SandboxHandle;
    // A team computer: the link form doesn't nest inside the bot's folder.
    const team = withHomePaths(inTeamFolder(base, "casama"));
    await team.writeFile("workspace/bots/casama/report.md", new Uint8Array());
    expect(team.resolvePath?.("workspace/bots/casama/report.md")).toBe("bots/casama/report.md");
    // A bot's own computer: no ~/workspace/workspace.
    const own = withHomePaths(base);
    await own.writeFile("workspace/report.md", new Uint8Array());
    expect(writes.slice(-2)).toEqual(["bots/casama/report.md", "report.md"]);
  });
});
