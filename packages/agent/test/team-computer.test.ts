import type { ExecChunk, ExecOptions, SandboxHandle } from "@kasama/sandbox";
import { describe, expect, it } from "vitest";
import { folderSlug, inTeamFolder } from "../src/team-computer.ts";

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
      "exec mkdir -p /home/kasama/workspace/bots/researcher /home/kasama/workspace/shared @",
      "write bots/researcher/notes.md",
      "write shared/plan.md",
      "read /etc/hostname",
      "read ~/.bashrc",
      "list bots/researcher",
      "list bots/designer",
      "search (all)",
      "search bots/researcher/src",
      "exec ls @/home/kasama/workspace/bots/researcher",
      "exec ls @/home/kasama/workspace/bots/researcher/src",
      "exec ls @/tmp",
    ]);
    expect(h.resolvePath?.("report.md")).toBe("bots/researcher/report.md");
    expect(h.resolvePath?.("bots/researcher/report.md")).toBe("bots/researcher/report.md");
  });
});
