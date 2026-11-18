import { collectExec, type ExecChunk, type ExecOptions, type SandboxHandle } from "@casama/sandbox";
import { ToolError } from "./tools/registry.ts";

/**
 * A cloud computer's home folder limit (D-348). `computers.size.disk_gb` was shown on the Storage
 * card but nothing held a bot to it, and every byte of the home folder is archived on each sleep
 * (D-251). Docker's local volumes can't take a size, so the limit is kept here instead: over it,
 * files.write is refused and shell commands still run (the bot needs them to delete things) but
 * end with a note saying the folder is full. It's a soft limit: one command can still go past it.
 */
export const DEFAULT_DISK_GB = 10;
const GIB = 1024 ** 3;

/**
 * Prints the home folder's size in bytes. Shares the cache the Storage and vitals reads keep in
 * /tmp/.casama-du ("bytes epoch"): measured right away the first time, then answered from the
 * cache and refreshed in the background once it's over a minute old, so a check costs one quick
 * exec.
 */
export const DISK_USAGE_SCRIPT = [
  'f=/tmp/.casama-du; now=$(date +%s); disk=""; t=0',
  "[ -f $f ] && read disk t < $f",
  'if [ -z "$disk" ]; then disk=$(timeout 8 du -sb "$HOME" 2>/dev/null | cut -f1); echo "$disk $now" > $f',
  `elif [ $((now - \${t:-0})) -gt 60 ]; then (nohup sh -c 'd=$(du -sb "$HOME" 2>/dev/null | cut -f1); echo "$d $(date +%s)" > /tmp/.casama-du.n && mv /tmp/.casama-du.n /tmp/.casama-du' >/dev/null 2>&1 &); fi`,
  'echo "${disk:-}"',
].join("\n");

const gb = (bytes: number) => (bytes / GIB).toFixed(1).replace(/\.0$/, "");

export const diskFullMessage = (used: number, limit: number) =>
  `Your home folder is full: it uses ${gb(used)} GB of its ${gb(limit)} GB. Delete files you no longer need (caches in ~/.cache first; du -sh ~/* ~/.[!.]* shows what's big) before saving more, or ask the person to free up space from the computer's Storage card.`;

/** The home folder's size in bytes, or null when it can't be read (the check then lets it be). */
export async function homeUsage(h: SandboxHandle): Promise<number | null> {
  try {
    const r = await collectExec(h.exec(DISK_USAGE_SCRIPT, { timeoutMs: 15_000 }));
    const n = Number(r.stdout.trim());
    return r.code === 0 && r.stdout.trim() && Number.isFinite(n) && n >= 0 ? n : null;
  } catch {
    return null;
  }
}

/** A computer row's home folder limit in GB (`size.disk_gb`, else the column's default). */
export const diskGbOf = (row: { size?: { disk_gb?: unknown } | null }) => {
  const v = row.size?.disk_gb;
  return typeof v === "number" && v > 0 ? v : DEFAULT_DISK_GB;
};

/** A handle held to a home folder of `diskGb` GB (see the module comment). */
export function withDiskLimit(h: SandboxHandle, diskGb: number = DEFAULT_DISK_GB): SandboxHandle {
  const limit = Math.max(1, diskGb) * GIB;
  // One look per 30 s at most: a tool like the browser runs several commands per call.
  let seen: { at: number; used: number | null } | null = null;
  const over = async () => {
    if (!seen || Date.now() - seen.at > 30_000) seen = { at: Date.now(), used: await homeUsage(h) };
    const used = seen.used;
    return used !== null && used >= limit ? used : null;
  };
  return {
    ...h,
    exec: (cmd: string, opts?: ExecOptions) =>
      (async function* () {
        let exit: Extract<ExecChunk, { type: "exit" }> | undefined;
        for await (const c of h.exec(cmd, opts)) {
          if (c.type === "exit") exit = c;
          else yield c;
        }
        const used = await over();
        if (used !== null)
          yield { type: "stderr" as const, data: `\n${diskFullMessage(used, limit)}\n` };
        if (exit) yield exit;
      })(),
    writeFile: async (p, data) => {
      const used = await over();
      if (used !== null) throw new ToolError("disk_full", diskFullMessage(used, limit));
      return h.writeFile(p, data);
    },
  };
}
