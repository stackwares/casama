import { describe, expect, it, vi } from "vitest";
import { ComputerService } from "../src/computers.ts";

/** Computer limits from the monetization audit (D-248): after a downgrade, a full server, credits. */
describe("checkCanStart (D-248)", () => {
  /** A db that answers the start check's one query, then the capacity count. */
  const svc = (row: Record<string, unknown>, running?: number) => {
    const answers: unknown[][] = [[row], ...(running == null ? [] : [[{ n: String(running) }]])];
    const execute = vi.fn(async () => answers.shift() ?? []);
    return { s: new ComputerService({ execute } as never, {} as never), execute };
  };
  const ok = {
    suspended: false,
    plan: "pro",
    verified: true,
    gate: true,
    credits: "5",
    unbilled: "0",
  };

  it("after a downgrade, only the plan's number of computers (the oldest) start", async () => {
    await expect(
      svc({ ...ok, max_computers: "2", rank: "2" }).s.checkCanStart("org", {
        credits: true,
        computerId: "c3",
      }),
    ).rejects.toThrow("plan_limit");
    await expect(
      svc({ ...ok, max_computers: "2", rank: "1" }).s.checkCanStart("org", {
        credits: true,
        computerId: "c2",
      }),
    ).resolves.toBeUndefined();
  });

  it("a full server says so instead of starting one more", async () => {
    const full = svc({ ...ok, max_computers: null, rank: "0" }, 8);
    full.s.maxRunning = 8;
    await expect(full.s.checkCanStart("org", { credits: true, computerId: "c1" })).rejects.toThrow(
      "capacity_full",
    );
    const room = svc({ ...ok, max_computers: null, rank: "0" }, 7);
    room.s.maxRunning = 8;
    await expect(
      room.s.checkCanStart("org", { credits: true, computerId: "c1" }),
    ).resolves.toBeUndefined();
    // No limit set: the count isn't even read.
    const free = svc({ ...ok, max_computers: null, rank: "0" });
    await free.s.checkCanStart("org", { credits: true, computerId: "c1" });
    expect(free.execute).toHaveBeenCalledTimes(1);
  });

  it("credits left after unsettled usage, not the bare balance, decide", async () => {
    await expect(
      svc({
        ...ok,
        credits: "1",
        unbilled: "1.5",
        max_computers: null,
        rank: null,
      }).s.checkCanStart("org", {
        credits: true,
      }),
    ).rejects.toThrow("out_of_credits");
  });
});

describe("meterRunning (D-248)", () => {
  it("bills a running computer as it runs, and puts one to sleep when its workspace is out of credits", async () => {
    const since = new Date(Date.now() - 10 * 60_000);
    const running = {
      id: "c1",
      org_id: "org",
      owner_bot_id: null,
      kind: "team",
      provider: "docker",
      size: { cpus: 1, memory_mb: 1024 },
      running_since: since,
    };
    const answers: unknown[][] = [
      [running], // running computers past the interval
      [{ id: "c1" }], // the interval claimed
      [], // the usage row
      [{ id: "c1", org_id: "org" }], // running computers of workspaces with no credits
    ];
    const execute = vi.fn(async () => answers.shift() ?? []);
    const s = new ComputerService({ execute } as never, {} as never);
    const sleep = vi.spyOn(s, "sleep").mockResolvedValue(undefined);
    const r = await s.meterRunning();
    expect(r).toEqual({ metered: 1, slept: 1 });
    expect(sleep).toHaveBeenCalledWith("c1");
    // The usage row was written for the ten minutes that ran.
    const usage = (execute.mock.calls[2] as unknown[] | undefined)?.[0];
    expect(JSON.stringify(usage)).toContain("computer_seconds");
  });
});
