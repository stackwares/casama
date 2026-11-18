/**
 * How the worker stops without cutting runs (D-402, docs/SMOOTH-DEPLOYS-PLAN.md).
 *
 * Runs are durable workflows: every model and tool call is a saved step, and the next worker picks
 * up every unfinished run where its saved steps end. So a stopping worker lets the steps in flight
 * finish and be saved, and holds every run at its next step, which then never starts here. The
 * next worker runs it. Nothing runs twice and nothing is cut, unless a step outlasts the drain.
 */

/** A promise that never settles: a run held here is left for the next worker. */
export const never = () => new Promise<never>(() => {});

let draining = false;
let inFlight = 0;
const idle = new Set<() => void>();

/** Whether the worker is stopping: runs must not start new steps or record anything. */
export function isDraining() {
  return draining;
}

/** Steps running now. */
export function stepsInFlight() {
  return inFlight;
}

/**
 * Runs one step unless the worker is stopping, in which case the run waits here for good and the
 * next worker runs the step. Wraps the whole engine call, so the step's saved result is included.
 */
export async function gatedStep<T>(run: () => Promise<T>): Promise<T> {
  if (draining) return never();
  inFlight++;
  try {
    return await run();
  } finally {
    inFlight--;
    if (inFlight === 0) for (const done of idle) done();
  }
}

/**
 * Stops new steps and waits up to `ms` for the steps in flight. Returns how many were still
 * running when it gave up (0: all finished and were saved).
 */
export async function drainSteps(ms: number): Promise<number> {
  draining = true;
  if (inFlight === 0) return 0;
  await new Promise<void>((resolve) => {
    const done = () => {
      clearTimeout(timer);
      idle.delete(done);
      resolve();
    };
    const timer = setTimeout(done, ms);
    idle.add(done);
  });
  return inFlight;
}

/** For tests. */
export function resetDrain() {
  draining = false;
  inFlight = 0;
  idle.clear();
}
