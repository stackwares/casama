import { execFileSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { ExecChunk, ExecOptions, SandboxHandle } from "@casama/sandbox";
import { describe, expect, it } from "vitest";
import { buildContext } from "../src/context.ts";
import {
  DEFAULT_DISK_GB,
  DISK_USAGE_SCRIPT,
  diskGbOf,
  homeUsage,
  withDiskLimit,
} from "../src/disk-limit.ts";

const GIB = 1024 ** 3;
const exit = { type: "exit", code: 0, timedOut: false, killed: false, truncated: false } as const;

/** A computer whose home folder holds `used` bytes; counts usage checks and writes. */
function fakeComputer(used: () => number | "fail") {
  const calls = { usage: 0, writes: [] as string[], commands: [] as string[] };
  const h = {
    ref: "c1",
    async *exec(cmd: string, _opts?: ExecOptions): AsyncIterable<ExecChunk> {
      if (cmd === DISK_USAGE_SCRIPT) {
        calls.usage++;
        const u = used();
        if (u === "fail") {
          yield { ...exit, code: 1 };
          return;
        }
        yield { type: "stdout", data: `${u}\n` };
        yield exit;
        return;
      }
      calls.commands.push(cmd);
      yield { type: "stdout", data: "ok\n" };
      yield { ...exit, code: 3 };
    },
    writeFile: async (p: string) => {
      calls.writes.push(p);
    },
  } as unknown as SandboxHandle;
  return { h, calls };
}

async function run(h: SandboxHandle, cmd: string) {
  const out: ExecChunk[] = [];
  for await (const c of h.exec(cmd)) out.push(c);
  return out;
}

/** Home folder limit (D-348). */
describe("home folder limit", () => {
  it("under the limit: writes go through and commands are unchanged", async () => {
    const { h, calls } = fakeComputer(() => 2 * GIB);
    const limited = withDiskLimit(h, 10);
    await limited.writeFile("a.txt", new Uint8Array());
    const out = await run(limited, "ls");
    expect(calls.writes).toEqual(["a.txt"]);
    expect(out).toEqual([
      { type: "stdout", data: "ok\n" },
      { ...exit, code: 3 },
    ]);
  });

  it("over the limit: files.write is refused with disk_full, commands still run and end with a note", async () => {
    const { h, calls } = fakeComputer(() => 10.4 * GIB);
    const limited = withDiskLimit(h, 10);
    await expect(limited.writeFile("a.txt", new Uint8Array())).rejects.toMatchObject({
      code: "disk_full",
      message: expect.stringContaining("10.4 GB of its 10 GB"),
    });
    expect(calls.writes).toEqual([]);
    const out = await run(limited, "rm -rf ~/.cache/big");
    expect(calls.commands).toEqual(["rm -rf ~/.cache/big"]);
    expect(out[0]).toEqual({ type: "stdout", data: "ok\n" });
    expect(out[1]).toMatchObject({
      type: "stderr",
      data: expect.stringContaining("home folder is full"),
    });
    // The exit code stays the command's own, and comes last.
    expect(out[2]).toEqual({ ...exit, code: 3 });
  });

  it("looks at most every 30 seconds per handle", async () => {
    const { h, calls } = fakeComputer(() => GIB);
    const limited = withDiskLimit(h, 10);
    await run(limited, "a");
    await run(limited, "b");
    await limited.writeFile("x", new Uint8Array());
    expect(calls.usage).toBe(1);
  });

  it("lets it be when the size can't be read", async () => {
    const { h, calls } = fakeComputer(() => "fail");
    expect(await homeUsage(h)).toBeNull();
    await withDiskLimit(h, 1).writeFile("a.txt", new Uint8Array());
    expect(calls.writes).toEqual(["a.txt"]);
  });

  it("the limit comes from size.disk_gb, else 10 GB", () => {
    expect(diskGbOf({ size: { disk_gb: 20 } })).toBe(20);
    expect(diskGbOf({ size: {} })).toBe(DEFAULT_DISK_GB);
    expect(diskGbOf({ size: { disk_gb: 0 } })).toBe(DEFAULT_DISK_GB);
    expect(diskGbOf({ size: null })).toBe(DEFAULT_DISK_GB);
  });

  it("the usage script measures the home folder and then answers from its cache", () => {
    if (process.platform !== "linux") return; // du -b is GNU; computers run Linux
    const home = mkdtempSync(join(tmpdir(), "casama-home-"));
    const cache = "/tmp/.casama-du";
    rmSync(cache, { force: true });
    try {
      writeFileSync(join(home, "f"), Buffer.alloc(100_000));
      const first = Number(
        execFileSync("sh", ["-c", DISK_USAGE_SCRIPT], {
          env: { HOME: home, PATH: process.env.PATH },
        }),
      );
      expect(first).toBeGreaterThanOrEqual(100_000);
      writeFileSync(join(home, "g"), Buffer.alloc(500_000));
      const cached = Number(
        execFileSync("sh", ["-c", DISK_USAGE_SCRIPT], {
          env: { HOME: home, PATH: process.env.PATH },
        }),
      );
      expect(cached).toBe(first);
    } finally {
      rmSync(home, { recursive: true, force: true });
      rmSync(cache, { force: true });
    }
  });
});

describe("home folder in the system prompt", () => {
  const base = {
    botName: "B",
    persona: "",
    autonomy: "ask_risky" as const,
    now: new Date("2026-11-17T00:00:00Z"),
    timezone: "UTC",
    skills: [],
    memories: [],
    summary: "",
    history: [],
    contextWindow: 200_000,
    computer: true,
  };

  it("cloud computers learn the limit and that system updates can break their own installs", () => {
    const text = buildContext({ ...base, diskGb: 20 }).system.join("\n");
    expect(text).toContain("Your home folder holds up to 20 GB");
    expect(text).toContain("reinstall it");
    expect(buildContext(base).system.join("\n")).toContain(`up to ${DEFAULT_DISK_GB} GB`);
    expect(buildContext({ ...base, teamFolder: "b" }).system.join("\n")).toContain(
      "Your home folder holds up to",
    );
  });
});
