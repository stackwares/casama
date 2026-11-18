/**
 * Plugin tools on a person's own computer (D-344): a plugin's stdio servers placed on the
 * installer's desktop companion. They're `local_mcp` connections (D-096) with the plugin's
 * command in their config; the API pushes the package and the server list to the companion's
 * computerd over the device tunnel (`PUT /plugins/<name>`, `PUT /plugin-servers`), and the worker
 * calls them on `/mcp/<bridge_key>` like any local server. Pushed after install, update, settings
 * changes and removal, and again whenever the companion connects (computerd keeps them in memory).
 */

import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import type { AppDeps } from "../api/types.ts";

type Registry = NonNullable<AppDeps["devices"]>;

export interface CompanionPluginConfig {
  plugin_id: string;
  plugin: string;
  server: string;
  command: string;
  args: string[];
  env: Record<string, string>;
  cwd?: string;
  device_id: string;
  computer_id: string;
  owner_user_id: string;
  /** The key computerd bridges it on: the connection's name, unique in the workspace. */
  bridge_key: string;
}

/** One request to a device's computerd through the tunnel, read whole. */
export function deviceCall(
  registry: Registry,
  computerId: string,
  method: string,
  path: string,
  body?: unknown,
): Promise<{ status: number; json: unknown }> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    let status = 502;
    const data = body === undefined ? undefined : Buffer.from(JSON.stringify(body));
    try {
      registry.request(
        computerId,
        {
          method,
          path,
          headers: data
            ? { "content-type": "application/json", "content-length": String(data.length) }
            : {},
          body: data,
        },
        {
          onResponse: (s) => {
            status = s;
          },
          onChunk: (d) => chunks.push(d),
          onEnd: () => {
            const text = Buffer.concat(chunks).toString();
            let json: unknown = null;
            try {
              json = text ? JSON.parse(text) : null;
            } catch {}
            resolve({ status, json });
          },
          onError: (m) => reject(new Error(m)),
        },
      );
    } catch (err) {
      reject(err);
    }
  });
}

/** The plugin servers placed on one companion computer, with their secret env values. */
export function companionPluginRows(db: Database, computerId: string) {
  return db.execute<{
    name: string;
    config: CompanionPluginConfig;
    secret: string | null;
    commit_sha: string;
  }>(sql`
    select i.name, i.config, v.decrypted_secret as secret, p.commit_sha
    from public.integrations i
    join public.plugins p on p.id = i.plugin_id
    left join vault.decrypted_secrets v on v.id = i.vault_secret_id
    where i.kind = 'local_mcp' and i.config ->> 'computer_id' = ${computerId}
    order by i.name`);
}

/**
 * Hands a companion its plugin packages (only those whose commit changed) and the full server
 * list. Returns false when the computer is offline; it gets them when it connects again.
 */
export async function syncCompanionPlugins(
  deps: Pick<AppDeps, "db" | "devices">,
  computerId: string,
): Promise<boolean> {
  const registry = deps.devices;
  if (!registry?.online(computerId)) return false;
  const rows = await companionPluginRows(deps.db, computerId);
  const have = await deviceCall(registry, computerId, "GET", "/plugins");
  if (have.status !== 200) throw new Error(errorText(have.json, "The computer refused plugins"));
  const commits = ((have.json as { commits?: Record<string, string> })?.commits ?? {}) as Record<
    string,
    string
  >;
  const packages = new Map(rows.map((r) => [r.config.plugin, r]));
  for (const [name, r] of packages) {
    if (commits[name] === r.commit_sha) continue;
    const files = await deps.db.execute<{ path: string; content: Buffer; executable: boolean }>(
      sql`select path, content, executable from public.plugin_files where plugin_id = ${r.config.plugin_id}::uuid`,
    );
    const put = await deviceCall(registry, computerId, "PUT", `/plugins/${name}`, {
      commit: r.commit_sha,
      files: files.map((f) => ({
        path: f.path,
        base64: Buffer.from(f.content).toString("base64"),
        executable: f.executable,
      })),
    });
    if (put.status !== 200)
      throw new Error(errorText(put.json, `The computer didn't take the ${name} plugin`));
  }
  const servers: Record<string, unknown> = {};
  for (const r of rows) {
    let secretEnv: Record<string, string> = {};
    try {
      secretEnv = r.secret ? (JSON.parse(r.secret) as Record<string, string>) : {};
    } catch {}
    const c = r.config;
    servers[c.bridge_key] = {
      plugin: c.plugin,
      command: c.command,
      args: c.args ?? [],
      ...(c.cwd ? { cwd: c.cwd } : {}),
      env: { ...(c.env ?? {}), ...secretEnv },
    };
  }
  const put = await deviceCall(registry, computerId, "PUT", "/plugin-servers", { servers });
  if (put.status !== 200)
    throw new Error(errorText(put.json, "The computer didn't take the plugin servers"));
  return true;
}

/** Syncs quietly: a failure leaves the tools saying what's wrong when they're called. */
export function syncCompanionPluginsQuietly(
  deps: Pick<AppDeps, "db" | "devices">,
  computerId: string,
) {
  return syncCompanionPlugins(deps, computerId).catch(() => false);
}

const errorText = (json: unknown, fallback: string) => {
  const m = (json as { message?: unknown } | null)?.message;
  return typeof m === "string" && m ? m : fallback;
};
