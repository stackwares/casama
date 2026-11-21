/**
 * How many runs work at once (D-413): RUN_CONCURRENCY on this worker, RUN_WORKSPACE_CONCURRENCY
 * of them for one workspace.
 *
 * These used to be the queue's own limits, and the queue counts a run from the moment it starts
 * until it ends. A run that waits for a person (an approval, a secret, the screen, for up to 24
 * hours) kept its place the whole time. Five runs waiting for an OK in one workspace, say routines
 * that asked overnight, and every new message there stayed "queued" with the bot looking stuck;
 * twenty across the server did that to everyone.
 *
 * Now the queue admits more runs than may work, and a run holds one of these slots only while it
 * works: it takes one before its first step, gives it back when it starts waiting for a person,
 * and takes one again when the wait is over. The slots are kept in this process: a restarted
 * worker starts empty, and its recovered runs take theirs again.
 */
export class RunSlots {
  private working = 0;
  private readonly byWorkspace = new Map<string, number>();
  private readonly waiting: Array<{ workspace: string; start: () => void }> = [];

  /** The error an aborted [acquire] rejects with. */
  static readonly ABORTED = "run_slot_wait_aborted";

  private readonly total: number;
  private readonly perWorkspace: number;

  /** [perWorkspace] 0: no limit per workspace. */
  constructor(total: number, perWorkspace: number) {
    this.total = total;
    this.perWorkspace = perWorkspace;
  }

  private free(workspace: string) {
    return (
      this.working < this.total &&
      (this.perWorkspace <= 0 || (this.byWorkspace.get(workspace) ?? 0) < this.perWorkspace)
    );
  }

  private take(workspace: string) {
    this.working++;
    this.byWorkspace.set(workspace, (this.byWorkspace.get(workspace) ?? 0) + 1);
  }

  /**
   * Resolves once a slot is free for [workspace]; first come, first served. [signal] takes a
   * waiting caller out of the line (Stop on a queued run): the promise rejects with
   * [RunSlots.ABORTED] and no slot is held.
   */
  acquire(workspace: string, signal?: AbortSignal): Promise<void> {
    if (signal?.aborted) return Promise.reject(new Error(RunSlots.ABORTED));
    // Nobody ahead who could also start: otherwise a newcomer would jump the line.
    if (this.free(workspace) && !this.waiting.some((w) => this.free(w.workspace))) {
      this.take(workspace);
      return Promise.resolve();
    }
    return new Promise((resolve, reject) => {
      const entry = {
        workspace,
        start: () => {
          signal?.removeEventListener("abort", onAbort);
          resolve();
        },
      };
      const onAbort = () => {
        const i = this.waiting.indexOf(entry);
        if (i < 0) return; // Already started.
        this.waiting.splice(i, 1);
        reject(new Error(RunSlots.ABORTED));
      };
      signal?.addEventListener("abort", onAbort, { once: true });
      this.waiting.push(entry);
    });
  }

  release(workspace: string) {
    this.working = Math.max(0, this.working - 1);
    const left = (this.byWorkspace.get(workspace) ?? 1) - 1;
    if (left > 0) this.byWorkspace.set(workspace, left);
    else this.byWorkspace.delete(workspace);
    // The longest waiting run whose workspace has room goes next, and so on while slots last.
    for (let i = 0; i < this.waiting.length && this.working < this.total; ) {
      const next = this.waiting[i] as { workspace: string; start: () => void };
      if (!this.free(next.workspace)) {
        i++;
        continue;
      }
      this.waiting.splice(i, 1);
      this.take(next.workspace);
      next.start();
    }
  }

  /** Runs [wait] without a slot (the run is waiting for a person), then takes one again. */
  async idle<T>(workspace: string, wait: () => Promise<T>): Promise<T> {
    this.release(workspace);
    try {
      return await wait();
    } finally {
      await this.acquire(workspace);
    }
  }

  /** For tests and logs. */
  get counts() {
    return { working: this.working, waiting: this.waiting.length };
  }
}

/**
 * How many started runs the queue admits for each one that may work. The rest of the started ones
 * are waiting for a person, or for a slot.
 */
export const STARTED_PER_WORKING = 10;
