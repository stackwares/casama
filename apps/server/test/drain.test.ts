import { afterEach, describe, expect, it } from "vitest";
import { drainApi, OpenSockets, RESTART_CODE, requestCounter } from "../src/api/drain.ts";
import {
  drainSteps,
  gatedStep,
  isDraining,
  resetDrain,
  stepsInFlight,
} from "../src/worker/drain.ts";

// Stopping without dropping people (D-402).

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

describe("OpenSockets", () => {
  it("closes every socket with the restart code and waits for their last writes", async () => {
    const open = new OpenSockets();
    const closed: Array<[number, string]> = [];
    let saved = false;
    open.add((code, reason) => {
      closed.push([code, reason]);
    });
    const untrack = open.add(async (code, reason) => {
      closed.push([code, reason]);
      await sleep(20);
      saved = true;
    });
    const gone = open.add(() => {
      throw new Error("must not be closed: it was untracked");
    });
    gone();
    expect(open.size).toBe(2);
    await open.closeAll();
    expect(saved).toBe(true);
    expect(closed).toEqual([
      [RESTART_CODE, "server restarting"],
      [RESTART_CODE, "server restarting"],
    ]);
    expect(open.size).toBe(0);
    untrack(); // closing after closeAll is harmless
  });
});

describe("requestCounter", () => {
  it("counts requests until their handler returns", async () => {
    const counter = requestCounter();
    let release = () => {};
    const handler = counter.wrap(
      (n: number) =>
        new Promise<number>((r) => {
          release = () => r(n * 2);
        }),
    );
    const pending = handler(21);
    expect(counter.inFlight).toBe(1);
    release();
    expect(await pending).toBe(42);
    expect(counter.inFlight).toBe(0);
    await expect(counter.wrap(() => Promise.reject(new Error("x")))()).rejects.toThrow("x");
    expect(counter.inFlight).toBe(0);
  });
});

/** A fake API: what drainApi did, in order. */
function fakeApi(opts: { inFlight?: number; calls?: number } = {}) {
  const log: string[] = [];
  let inFlight = opts.inFlight ?? 0;
  const calls = { size: opts.calls ?? 0 };
  return {
    log,
    finishRequests: () => {
      inFlight = 0;
    },
    endCalls: () => {
      calls.size = 0;
    },
    options: {
      stopListening: () => log.push("stop listening"),
      redialing: [() => void log.push("redial: live views"), () => void log.push("redial: apps")],
      inFlight: () => inFlight,
      calls: [
        {
          get size() {
            return calls.size;
          },
          closeAll: async () => {
            log.push(`close calls (${calls.size})`);
            calls.size = 0;
          },
        },
      ],
      closeConnections: () => log.push("close connections"),
      requestMs: 1000,
      callMs: 1000,
      pollMs: 5,
    },
  };
}

describe("drainApi", () => {
  it("restart: stops listening, tells redialing sockets, lets requests finish, then closes calls", async () => {
    const api = fakeApi({ inFlight: 2, calls: 1 });
    setTimeout(() => {
      api.log.push("requests done");
      api.finishRequests();
    }, 30);
    await drainApi({ mode: "restart", ...api.options });
    expect(api.log).toEqual([
      "stop listening",
      "redial: live views",
      "redial: apps",
      "requests done",
      "close calls (1)",
      "close connections",
    ]);
  });

  it("restart: gives up on requests after requestMs", async () => {
    const api = fakeApi({ inFlight: 1 });
    const started = Date.now();
    await drainApi({ mode: "restart", ...api.options, requestMs: 50 });
    expect(Date.now() - started).toBeGreaterThanOrEqual(45);
    expect(api.log.at(-1)).toBe("close connections");
  });

  it("handover: carries calls until they end", async () => {
    const api = fakeApi({ calls: 2 });
    setTimeout(() => {
      api.log.push("calls ended");
      api.endCalls();
    }, 40);
    await drainApi({ mode: "handover", ...api.options });
    expect(api.log).toEqual([
      "stop listening",
      "redial: live views",
      "redial: apps",
      "calls ended",
      "close calls (0)",
      "close connections",
    ]);
  });

  it("handover: closes calls when the time runs out, or sooner when cut short", async () => {
    const timedOut = fakeApi({ calls: 1 });
    await drainApi({ mode: "handover", ...timedOut.options, callMs: 30 });
    expect(timedOut.log).toContain("close calls (1)");

    const cut = fakeApi({ calls: 1 });
    let cutShort = false;
    setTimeout(() => {
      cutShort = true;
    }, 20);
    const started = Date.now();
    await drainApi({ mode: "handover", ...cut.options, callMs: 5000, cutShort: () => cutShort });
    expect(Date.now() - started).toBeLessThan(1000);
    expect(cut.log).toContain("close calls (1)");
  });

  it("crash: waits for nothing", async () => {
    const api = fakeApi({ inFlight: 3, calls: 1 });
    const started = Date.now();
    await drainApi({ mode: "crash", ...api.options, requestMs: 5000, callMs: 5000 });
    expect(Date.now() - started).toBeLessThan(500);
    expect(api.log).toEqual([
      "stop listening",
      "redial: live views",
      "redial: apps",
      "close calls (1)",
      "close connections",
    ]);
  });
});

describe("worker drain", () => {
  afterEach(() => resetDrain());

  it("lets steps in flight finish and holds new ones", async () => {
    let finish = () => {};
    const inFlight = gatedStep(
      () =>
        new Promise<string>((r) => {
          finish = () => r("saved");
        }),
    );
    expect(stepsInFlight()).toBe(1);
    const draining = drainSteps(1000);
    expect(isDraining()).toBe(true);

    // A step asked for while draining never starts.
    let started = false;
    const held = gatedStep(async () => {
      started = true;
      return "never";
    });
    let heldSettled = false;
    void held.then(
      () => {
        heldSettled = true;
      },
      () => {
        heldSettled = true;
      },
    );

    finish();
    expect(await inFlight).toBe("saved");
    expect(await draining).toBe(0);
    await sleep(10);
    expect(started).toBe(false);
    expect(heldSettled).toBe(false);
  });

  it("gives up after the drain time and says how many steps were cut", async () => {
    void gatedStep(() => new Promise(() => {}));
    expect(await drainSteps(30)).toBe(1);
  });

  it("returns at once when nothing is running", async () => {
    expect(await drainSteps(10_000)).toBe(0);
  });
});
