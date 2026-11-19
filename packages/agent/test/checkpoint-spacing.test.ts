import { describe, expect, it } from "vitest";
import {
  ComputerService,
  SAFETY_CHECKPOINT_COST_FACTOR,
  SAFETY_CHECKPOINT_GAP_S,
} from "../src/computers.ts";
import { registerComputerTools, runStreaming } from "../src/tools/computer.ts";
import { type ToolContext, ToolRegistry } from "../src/tools/registry.ts";

/**
 * The automatic checkpoint before a command that deletes (D-413). It archives the whole home
 * folder, so with a large home every `rm -rf` waited minutes; now a recent one stands in.
 */
const service = (last?: { age_s: number; took_ms: number | null }) =>
  new ComputerService({ execute: async () => (last ? [last] : []) } as never, {} as never);

describe("automatic checkpoints are spaced by what they cost", () => {
  it("takes one when the computer has none", async () => {
    expect(await service().hasFreshCheckpoint("c1")).toBe(false);
  });

  it("skips while a quick one is under ten minutes old", async () => {
    expect(await service({ age_s: 60, took_ms: 3000 }).hasFreshCheckpoint("c1")).toBe(true);
    expect(
      await service({ age_s: SAFETY_CHECKPOINT_GAP_S + 1, took_ms: 3000 }).hasFreshCheckpoint("c1"),
    ).toBe(false);
  });

  it("waits longer after a slow one: a 4 minute archive isn't repeated within the hour", async () => {
    const took = 250_000;
    expect(await service({ age_s: 3600, took_ms: took }).hasFreshCheckpoint("c1")).toBe(true);
    const gap = (took / 1000) * SAFETY_CHECKPOINT_COST_FACTOR;
    expect(await service({ age_s: gap + 1, took_ms: took }).hasFreshCheckpoint("c1")).toBe(false);
  });

  it("treats a checkpoint from before durations were kept as a quick one", async () => {
    expect(await service({ age_s: 300, took_ms: null }).hasFreshCheckpoint("c1")).toBe(true);
    expect(await service({ age_s: 700, took_ms: null }).hasFreshCheckpoint("c1")).toBe(false);
  });
});

describe("shell.exec", () => {
  const run = async (command: string, ctx: Partial<ToolContext>) => {
    const registry = new ToolRegistry();
    registerComputerTools(registry);
    const ran: string[] = [];
    const computer = {
      async *exec(cmd: string) {
        ran.push(cmd);
        yield { type: "exit", code: 0, timedOut: false, killed: false, truncated: false };
      },
    };
    const def = registry.get("shell.exec");
    await def?.execute(
      { command } as never,
      {
        output: async () => {},
        computer: async () => computer,
        ...ctx,
      } as never,
    );
    return ran;
  };

  it("asks for the spaced checkpoint before a command that deletes, and runs the command", async () => {
    const asked: string[] = [];
    const named: string[] = [];
    const ran = await run("rm -rf build", {
      checkpointBefore: async (label) => void asked.push(label),
      checkpoint: async (label) => {
        named.push(label);
        return { checkpointId: "x", label };
      },
    });
    expect(asked).toEqual(["Before: rm -rf build"]);
    expect(named).toEqual([]);
    expect(ran).toEqual(["rm -rf build"]);
  });

  it("takes no checkpoint for a command that deletes nothing", async () => {
    const asked: string[] = [];
    await run("ls -la", { checkpointBefore: async (label) => void asked.push(label) });
    expect(asked).toEqual([]);
  });
});

describe("a command whose exit never arrives", () => {
  const registry = new ToolRegistry();
  registerComputerTools(registry);
  const exec = (computer: unknown, timeout_s: number) =>
    registry.get("shell.exec")?.execute(
      { command: "make", timeout_s } as never,
      {
        output: async () => {},
        computer: async () => computer,
      } as never,
    ) as Promise<{ content: string }>;

  it("says the connection dropped when the stream ends without an exit", async () => {
    const computer = {
      async *exec() {
        yield { type: "stdout", data: "compiling\n" };
      },
    };
    const r = await exec(computer, 60);
    expect(r.content).toContain("connection to your computer dropped");
    expect(r.content).toContain("compiling");
    expect(r.content).not.toContain("exit code -1");
  });

  it("stops waiting shortly after the command's own timeout", async () => {
    let aborted = false;
    const computer = {
      async *exec(_cmd: string, opts: { signal?: AbortSignal }) {
        yield { type: "stdout", data: "starting\n" };
        // The computer never reports the exit; only the caller's signal ends the wait.
        await new Promise((_, reject) =>
          opts.signal?.addEventListener("abort", () => {
            aborted = true;
            reject(opts.signal?.reason);
          }),
        );
      },
    };
    const r = await runStreaming({ output: async () => {} }, computer as never, "make", {
      timeoutMs: 40,
      exitGraceMs: 40,
    });
    expect(aborted).toBe(true);
    expect(r).toMatchObject({ timedOut: true, lost: false, out: "starting\n" });
  });

  it("still stops at once when the run is cancelled", async () => {
    const stop = new AbortController();
    const computer = {
      async *exec(_cmd: string, opts: { signal?: AbortSignal }) {
        yield { type: "stdout", data: "starting\n" };
        await new Promise((_, reject) => {
          if (opts.signal?.aborted) reject(new Error("aborted"));
          opts.signal?.addEventListener("abort", () => reject(new Error("aborted")));
        });
      },
    };
    const running = runStreaming({ output: async () => {} }, computer as never, "make", {
      timeoutMs: 60_000,
      signal: stop.signal,
    });
    stop.abort();
    await expect(running).rejects.toThrow("aborted");
  });
});
