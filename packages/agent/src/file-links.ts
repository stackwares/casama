/**
 * Checks that the computer files a reply links to exist (D-231). A model can say "Done, open it
 * here: [index.html](workspace/...)" without having made anything; the person then taps a link to
 * a file that isn't there. Before a final reply is kept, its file links are looked up on the bot's
 * computer, and a missing one sends the model back once to make it or to correct the reply.
 */
import type { SandboxHandle } from "@casama/sandbox";
import type { ComputerService } from "./computers.ts";

/**
 * The computer path a chat link opens, or null when it isn't a file link. The same rule as the
 * app's `computerPathFromLink` (client/lib/features/files/file_preview.dart), so this checks what
 * a tap would open: absolute paths stay absolute, `~/x` is in the home folder, and everything else
 * is relative to ~/workspace.
 */
export function computerPathFromLink(link: string): string | null {
  let s: string;
  try {
    s = decodeURI(link.trim());
  } catch {
    s = link.trim();
  }
  if (!s || s.startsWith("#")) return null;
  const lower = s.toLowerCase();
  if (/^(https?:|mailto:|tel:)/.test(lower)) return null;
  for (const prefix of ["sandbox:", "file://"]) {
    if (lower.startsWith(prefix)) s = s.slice(prefix.length);
  }
  if (/^[a-z][a-z0-9+.-]*:/i.test(s)) return null;
  const home = "/home/casama/";
  if (s.startsWith(home)) s = s.slice(home.length);
  else if (s.startsWith("~/")) s = s.slice(2);
  else if (s.startsWith("/")) return s;
  else if (s.startsWith("./")) s = s.slice(2);
  else if (!s.startsWith("workspace/")) return s.includes(".") || s.includes("/") ? s : null;
  if (s.startsWith("workspace/")) return s.slice("workspace/".length);
  return `~/${s}`;
}

/** The file paths a reply links to with Markdown links or images, at most `max`, in order. */
export function linkedFilePaths(text: string, max = 5): string[] {
  const out: string[] = [];
  // [label](target) and ![alt](target), with an optional "title"; code spans are skipped.
  const prose = text.replace(/```[\s\S]*?```/g, "").replace(/`[^`\n]*`/g, "");
  for (const m of prose.matchAll(/!?\[[^\]\n]*\]\(\s*<?([^)\s>]+)>?(?:\s+"[^"]*")?\s*\)/g)) {
    const path = computerPathFromLink(m[1] ?? "");
    if (path && !out.includes(path)) out.push(path);
    if (out.length >= max) break;
  }
  return out;
}

/** Whether a file exists, by listing its folder. Null when the computer couldn't say. */
async function exists(h: SandboxHandle, path: string): Promise<boolean | null> {
  const clean = path.replace(/\/+$/, "");
  const cut = clean.lastIndexOf("/");
  const dir = cut < 0 ? "" : cut === 0 ? "/" : clean.slice(0, cut);
  const name = clean.slice(cut + 1);
  if (!name) return null;
  try {
    const entries = await h.listDir(dir);
    return entries.some((e) => e.name === name);
  } catch (err) {
    const e = err as { code?: string; status?: number; message?: string };
    if (
      e.code === "not_found" ||
      e.status === 404 ||
      /no such|not found|ENOENT/i.test(e.message ?? "")
    )
      return false;
    return null;
  }
}

/**
 * The linked files that aren't on the bot's computer. Fails open: no computer, an offline or
 * unreachable one, or one the run may not use returns [], so a reply is never held back because
 * the check itself couldn't run.
 */
export async function missingLinkedFiles(
  computers: ComputerService | undefined,
  run: {
    runId: string;
    botId: string;
    botName: string;
    actingUserId?: string | null;
    localOwner?: (computerId: string) => Promise<string | null>;
  },
  text: string,
  timeoutMs = 15_000,
): Promise<string[]> {
  const paths = linkedFilePaths(text);
  if (!computers || paths.length === 0) return [];
  const check = async () => {
    const row = await computers.forBot(run.botId);
    // A personal computer only works for its owner's own runs (D-131); don't check others'.
    if (row.kind === "local" && run.localOwner) {
      const owner = await run.localOwner(row.id);
      if (owner && owner !== run.actingUserId) return [];
    }
    const raw = await computers.ensureRunning(row.id);
    const h =
      raw.withActivity?.({
        run_id: run.runId,
        bot: run.botName,
        tool: "files.list",
        summary: "Checking the files in its reply",
      }) ?? raw;
    const missing: string[] = [];
    for (const p of paths) if ((await exists(h, p)) === false) missing.push(p);
    return missing;
  };
  let timer: ReturnType<typeof setTimeout> | undefined;
  const timeout = new Promise<string[]>((r) => {
    timer = setTimeout(() => r([]), timeoutMs);
  });
  try {
    return await Promise.race([check().catch(() => []), timeout]);
  } finally {
    clearTimeout(timer);
  }
}

/** The note that sends the model back after a reply linked to files that aren't there. */
export function missingFilesNote(missing: string[]): string {
  const list = missing.map((p) => `"${p}"`).join(", ");
  return `[Casama: your reply links to ${list}, but there's no file there on your computer, so the link won't open. Don't say you made or saved something you didn't. Either make it now with your tools and then reply, or reply again without that link and say plainly what you did and didn't do.]`;
}
