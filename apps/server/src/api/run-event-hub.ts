import type postgres from "postgres";

/** Fans out Postgres NOTIFY messages ("run_id:seq") from the run_events trigger to SSE subscribers. */
export interface RunEventHub {
  subscribe(runId: string, onEvent: () => void): () => void;
  close(): Promise<void>;
}

export async function pgRunEventHub(client: postgres.Sql): Promise<RunEventHub> {
  const subs = new Map<string, Set<() => void>>();
  const listener = await client.listen("kasama_run_events", (payload) => {
    const runId = payload.split(":")[0] ?? "";
    for (const cb of subs.get(runId) ?? []) cb();
  });
  return {
    subscribe(runId, onEvent) {
      let set = subs.get(runId);
      if (!set) {
        set = new Set();
        subs.set(runId, set);
      }
      set.add(onEvent);
      return () => {
        set.delete(onEvent);
        if (set.size === 0) subs.delete(runId);
      };
    },
    close: () => listener.unlisten(),
  };
}
