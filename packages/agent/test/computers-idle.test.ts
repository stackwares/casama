import { describe, expect, it, vi } from "vitest";
import { ComputerService } from "../src/computers.ts";

/** Idle sleep (D-178, D-195): an open terminal nobody uses no longer keeps a computer awake. */
describe("sleepIdle", () => {
  it("sleeps a computer with only an idle open terminal, not one running a command", async () => {
    const rows = [
      { id: "idle-terminal", provider: "docker" },
      { id: "running-command", provider: "docker" },
    ];
    const health = {
      "idle-terminal": { runningExecs: 0, openTerminals: 1 },
      "running-command": { runningExecs: 1, openTerminals: 0 },
    } as Record<string, { runningExecs: number; openTerminals: number }>;
    const provider = {
      get: async (id: string) => ({ health: async () => health[id] }),
    };
    const db = { execute: async () => rows };
    const svc = new ComputerService(db as never, provider as never);
    const sleep = vi.spyOn(svc, "sleep").mockResolvedValue(undefined);
    const touch = vi.spyOn(svc, "touch").mockResolvedValue(undefined);

    expect(await svc.sleepIdle()).toEqual(["idle-terminal"]);
    expect(sleep).toHaveBeenCalledWith("idle-terminal");
    expect(sleep).not.toHaveBeenCalledWith("running-command");
    expect(touch).toHaveBeenCalledWith("running-command");
  });
});
