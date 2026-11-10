/**
 * Plugins on the bot's computer (D-121): a plugin's stdio MCP servers run inside the computer,
 * started by computerd and bridged to the worker, so plugin code never runs on Kasama's servers.
 * Before the first call on a computer, the package files are written to
 * ~/.kasama/plugins/<plugin>/ (PLUGIN_ROOT) and computerd gets the server list.
 */
import { createHash } from "node:crypto";
import type { Database } from "@kasama/db";
import { expandPluginVars } from "@kasama/domain";
import { collectExec, type McpServerSpec, type SandboxHandle } from "@kasama/sandbox";
import { sql } from "drizzle-orm";

export interface ComputerMcpConfig {
  plugin_id: string;
  plugin: string;
  server: string;
  command: string;
  args: string[];
  env: Record<string, string>;
  cwd?: string;
}

const synced = new Map<string, string>();

/** Where a plugin lives on the computer. */
export const pluginRoot = (home: string, plugin: string) => `${home}/.kasama/plugins/${plugin}`;
export const pluginData = (home: string, plugin: string) => `${home}/.kasama/plugin-data/${plugin}`;

const homeOf = async (h: SandboxHandle) => {
  const r = await collectExec(h.exec('printf %s "$HOME"', { timeoutMs: 10_000 }));
  return r.stdout.trim() || "/home/kasama";
};

/**
 * The stdio plugin servers for a computer: those attached to bots that use it (their private
 * computer or default computer), keyed by integration name. Secret env values come from Vault.
 */
export async function computerPluginServers(db: Database, computerId: string) {
  return db.execute<{
    name: string;
    config: ComputerMcpConfig;
    secret: string | null;
    commit_sha: string;
  }>(sql`
    select distinct on (i.id) i.name, i.config, v.decrypted_secret as secret, p.commit_sha
    from public.integrations i
    join public.plugins p on p.id = i.plugin_id
    join public.bot_integrations bi on bi.integration_id = i.id
    join public.bots b on b.id = bi.bot_id
    left join public.computers k on k.id = ${computerId}::uuid
    left join vault.decrypted_secrets v on v.id = i.vault_secret_id
    where i.kind = 'computer_mcp' and (b.default_computer_id = ${computerId}::uuid or k.owner_bot_id = b.id)`);
}

/** Writes changed plugin packages and hands computerd its server list (skipped when unchanged). */
export async function syncPluginComputer(db: Database, h: SandboxHandle, computerId: string) {
  if (!h.setMcpServers) throw new Error("This computer can't run plugin servers");
  const rows = await computerPluginServers(db, computerId);
  const hash = createHash("sha256").update(JSON.stringify(rows)).digest("hex");
  if (synced.get(h.ref) === hash) return;
  const home = await homeOf(h);
  const plugins = new Map(
    rows.map((r) => [r.config.plugin_id, { name: r.config.plugin, commit: r.commit_sha }]),
  );
  for (const [id, p] of plugins) {
    const root = pluginRoot(home, p.name);
    const marker = await h
      .readFile(`${root}/.kasama-commit`)
      .then((b) => new TextDecoder().decode(b))
      .catch(() => "");
    if (marker.trim() === p.commit) continue;
    const files = await db.execute<{ path: string; content: Buffer; executable: boolean }>(
      sql`select path, content, executable from public.plugin_files where plugin_id = ${id}::uuid`,
    );
    await collectExec(
      h.exec(`rm -rf "${root}" && mkdir -p "${root}" "${pluginData(home, p.name)}"`, {
        timeoutMs: 30_000,
      }),
    );
    for (const f of files) await h.writeFile(`${root}/${f.path}`, new Uint8Array(f.content));
    const exe = files
      .filter((f) => f.executable)
      .map((f) => `"${root}/${f.path.replaceAll('"', "")}"`);
    if (exe.length) await collectExec(h.exec(`chmod +x ${exe.join(" ")}`, { timeoutMs: 30_000 }));
    await h.writeFile(`${root}/.kasama-commit`, new TextEncoder().encode(p.commit));
  }
  const servers: Record<string, McpServerSpec> = {};
  for (const r of rows) {
    const c = r.config;
    const roots = { root: pluginRoot(home, c.plugin), data: pluginData(home, c.plugin) };
    const x = (s: string) => expandPluginVars(s, roots);
    let secretEnv: Record<string, string> = {};
    try {
      secretEnv = r.secret ? (JSON.parse(r.secret) as Record<string, string>) : {};
    } catch {}
    servers[r.name] = {
      kind: "stdio",
      command: c.command.startsWith("./") ? `${roots.root}/${c.command.slice(2)}` : c.command,
      args: c.args.map(x),
      cwd: c.cwd
        ? c.cwd.startsWith("./")
          ? `${roots.root}/${c.cwd.slice(2)}`
          : x(c.cwd)
        : roots.root,
      env: {
        ...Object.fromEntries(Object.entries(c.env).map(([k, v]) => [k, x(v)])),
        ...secretEnv,
        PLUGIN_ROOT: roots.root,
        PLUGIN_DATA: roots.data,
      },
    };
  }
  await h.setMcpServers(servers);
  synced.set(h.ref, hash);
}

/** A fetch that sends MCP requests to one of computerd's bridged servers. */
export function computerMcpFetch(h: SandboxHandle, key: string): typeof fetch {
  if (!h.mcpFetch) throw new Error("This computer can't run plugin servers");
  const send = h.mcpFetch.bind(h);
  return (async (_url: string | URL | Request, init?: RequestInit) =>
    send(key, init ?? {})) as typeof fetch;
}

/** Forget what was synced (tests, and after uninstalling). */
export const forgetPluginSync = (ref?: string) => (ref ? synced.delete(ref) : synced.clear());

/** The computer a bot's plugin servers run on: its private computer, else its default one. */
export async function botComputerId(db: Database, botId: string) {
  const [r] = await db.execute<{ id: string | null }>(sql`
    select coalesce((select k.id from public.computers k where k.owner_bot_id = b.id limit 1), b.default_computer_id) as id
    from public.bots b where b.id = ${botId}::uuid`);
  return r?.id ?? null;
}

/** Everything a computer_mcp adapter needs, given a way to reach the bot's computer. */
export function computerMcpFor(
  db: Database,
  botId: string,
  computer: () => Promise<SandboxHandle>,
) {
  return async (rec: { name: string }) => {
    const id = await botComputerId(db, botId);
    if (!id) throw new Error("This bot has no computer for its plugin servers");
    const h = await computer();
    await syncPluginComputer(db, h, id);
    return computerMcpFetch(h, rec.name);
  };
}
