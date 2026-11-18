import { describe, expect, it, vi } from "vitest";
import { ComputerService, RunningLimitError } from "../src/computers.ts";

/** Plan limits on hosted computers (D-249): how many run at once, and how big each one is. */
describe("fitPlan", () => {
  const computer = {
    id: "new",
    org_id: "org",
    kind: "team",
    size: { cpus: 1, memory_mb: 1024 },
  };
  /** A db whose execute() answers the entitlement, then the running computers, then updates. */
  const setup = (
    limits: Record<string, unknown>,
    running: Array<{ id: string; idle: boolean }>,
  ) => {
    const answers: unknown[][] = [
      [{ running: limits.max_running_computers, size: limits.computer_size }],
      running,
    ];
    const execute = vi.fn(async () => answers.shift() ?? []);
    const svc = new ComputerService({ execute } as never, {} as never);
    const sleep = vi.spyOn(svc, "sleep").mockResolvedValue(undefined);
    const fit = (c = computer) =>
      (svc as unknown as { fitPlan(c: unknown): Promise<unknown> }).fitPlan(c);
    return { svc, sleep, execute, fit };
  };

  it("puts the computer nobody is using to sleep to make room", async () => {
    const { sleep, fit } = setup({ max_running_computers: 2 }, [
      { id: "old", idle: true },
      { id: "busy", idle: false },
    ]);
    expect(await fit()).toBeNull();
    expect(sleep).toHaveBeenCalledWith("old");
    expect(sleep).not.toHaveBeenCalledWith("busy");
  });

  it("refuses when every running computer is in use", async () => {
    const { sleep, fit } = setup({ max_running_computers: 1 }, [{ id: "busy", idle: false }]);
    await expect(fit()).rejects.toBeInstanceOf(RunningLimitError);
    await expect(
      setup({ max_running_computers: 1 }, [{ id: "busy", idle: false }]).fit(),
    ).rejects.toMatchObject({ message: "running_limit", limit: 1 });
    expect(sleep).not.toHaveBeenCalled();
  });

  it("starts freely under the limit or with no limit", async () => {
    expect(await setup({ max_running_computers: 3 }, [{ id: "a", idle: false }]).fit()).toBeNull();
    const { fit, execute } = setup({}, []);
    expect(await fit()).toBeNull();
    // No limit: only the entitlement is read.
    expect(execute).toHaveBeenCalledTimes(1);
  });

  it("sizes the computer by plan and saves it, so usage is billed at that size", async () => {
    const { fit, execute } = setup({ computer_size: 4 }, []);
    expect(await fit()).toEqual({ cpus: 4, memory_mb: 4096 });
    expect(execute).toHaveBeenCalledTimes(2);
    // Already that size: nothing to change.
    expect(
      await setup({ computer_size: 2 }, []).fit({
        ...computer,
        size: { cpus: 2, memory_mb: 2048 },
      }),
    ).toBeNull();
  });
});
