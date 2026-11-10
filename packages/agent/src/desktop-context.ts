/**
 * Desktop context (SPEC: Desktop context; D-152): searching the person's own computer through the
 * desktop app (Spotlight on macOS, Windows Search on Windows, locate or find on Linux), only inside
 * the folders they allowed.
 */
import type { Database } from "@kasama/db";
import { collectExec } from "@kasama/sandbox";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { wrapUntrusted } from "./context.ts";
import { shq } from "./tools/computer.ts";
import { ToolError, type ToolRegistry } from "./tools/registry.ts";

/** The search command for a platform: names (and contents where the index has them) under the roots. */
export function fileSearchCommand(platform: "macos" | "windows" | "linux", roots: string[], query: string, limit: number): string {
  if (platform === "macos")
    return `{ ${roots.map((r) => `mdfind -onlyin ${shq(r)} ${shq(query)}`).join("; ")}; } 2>/dev/null | head -n ${limit}`;
  if (platform === "linux") {
    const safe = query.replace(/[*?[\]]/g, "");
    return `{ ${roots
      .map((r) => `(command -v locate >/dev/null && locate -i -l ${limit} ${shq(`${r.replace(/\/$/, "")}/*${safe}*`)}) || find ${shq(r)} -iname ${shq(`*${safe}*`)} -not -path '*/.*' 2>/dev/null`)
      .join("; ")}; } | head -n ${limit}`;
  }
  // Windows Search's index (SystemIndex), scoped to each allowed folder.
  const q = query.replace(/'/g, "''");
  const scopes = roots.map((r) => `SCOPE='file:${r.replace(/'/g, "''").replace(/\\/g, "/")}'`).join(" OR ");
  const ps = `$c=New-Object -ComObject ADODB.Connection;$r=New-Object -ComObject ADODB.Recordset;$c.Open('Provider=Search.CollatorDSO;Extended Properties=''Application=Windows'';');$r.Open("SELECT TOP ${limit} System.ItemPathDisplay FROM SystemIndex WHERE (${scopes.replace(/"/g, '`"')}) AND (CONTAINS(System.FileName, '\\"${q}*\\"') OR FREETEXT('${q}'))",$c);while(-not $r.EOF){$r.Fields.Item('System.ItemPathDisplay').Value;$r.MoveNext()}`;
  return `powershell -NoProfile -Command ${shq(ps)}`;
}

export function registerDesktopContextTools(registry: ToolRegistry, deps: { db: Database }) {
  registry.register({
    name: "desktop.files.search",
    readOnly: true,
    untrustedOutput: true,
    description:
      "Search files on the person's own computer (the Kasama desktop app), only inside the folders they allowed: Spotlight on a Mac, Windows Search on Windows, locate on Linux. Returns paths; read one with files.read.",
    risk: "low",
    requires: { computer: true },
    schema: z.object({ query: z.string().trim().min(1).max(200), limit: z.number().int().min(1).max(100).optional() }),
    async execute(args, ctx) {
      // The bot's computer must be the person's own (D-066); runs for others are refused before this.
      const [dev] = await deps.db.execute<{ platform: "macos" | "windows" | "linux"; allowed_roots: string[] }>(sql`
        select d.platform, d.allowed_roots from public.bots b
        join public.computers c on c.id = b.default_computer_id and c.kind = 'local'
        join public.local_devices d on d.computer_id = c.id
        where b.id = ${ctx.botId}::uuid limit 1`);
      if (!dev) throw new ToolError("no_desktop", "This works on the person's own computer: they connect it in Settings → Use this computer and pick it as this bot's computer.");
      if (!dev.allowed_roots.length) throw new ToolError("no_folders", "The person hasn't allowed any folders on their computer yet (Settings → Use this computer).");
      const h = await ctx.computer?.();
      if (!h) throw new ToolError("no_computer", "Their computer isn't reachable right now.");
      const limit = args.limit ?? 30;
      const r = await collectExec(h.exec(fileSearchCommand(dev.platform, dev.allowed_roots, args.query, limit), { timeoutMs: 30_000 }));
      const paths = r.stdout.split(/\r?\n/).map((l) => l.trim()).filter(Boolean);
      // Belt and braces: nothing outside the allowed folders.
      const norm = (p: string) => p.replace(/\\/g, "/").toLowerCase();
      const inside = paths.filter((p) => dev.allowed_roots.some((root) => norm(p).startsWith(norm(root).replace(/\/?$/, "/")) || norm(p) === norm(root))).slice(0, limit);
      if (!inside.length) return { content: `No files match "${args.query}" in the allowed folders.`, preview: "0 files" };
      return { content: wrapUntrusted("file search", inside.join("\n")), preview: `${inside.length} files` };
    },
  });
}
