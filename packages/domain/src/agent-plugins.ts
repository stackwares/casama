/**
 * Agent Plugins 1.0 (D-121): reading and checking a plugin package (`plugin.json`, `mcp.json`,
 * `skills/<name>/SKILL.md`) the way the published specification describes, including the rules
 * its JSON Schemas can't express. Written from the specification text, not from another client.
 */

export const PLUGIN_SCHEMA_1_0 = "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json";
export const MCP_SCHEMA_1_0 = "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json";
/** Kasama's own extension namespace inside `extensions` (allowed by the specification). */
export const KASAMA_EXTENSION = "com.kasama";

const NAME = /^(?!.*(?:--|\.\.))[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$/;
const MANIFEST_FIELDS = new Set([
  "$schema",
  "name",
  "version",
  "description",
  "author",
  "homepage",
  "repository",
  "license",
  "keywords",
  "extensions",
]);
const HEADER_NAME = /^[!#$%&'*+.^_`|~0-9A-Za-z-]+$/;
const ENV_KEY = /^[A-Za-z_][A-Za-z0-9_]*$/;
const SECRET_NAME = /^[A-Z][A-Z0-9_]{0,63}$/;

export interface PluginManifest {
  name: string;
  version?: string;
  description?: string;
  author?: { name?: string; email?: string; url?: string };
  homepage?: string;
  repository?: string;
  license?: string;
  keywords?: string[];
}

export type PluginServer =
  | {
      key: string;
      type: "stdio";
      command: string;
      args: string[];
      env: Record<string, string>;
      cwd?: string;
    }
  | { key: string; type: "streamable-http" | "sse"; url: string; headers: Record<string, string> };

/** A secret the plugin needs, from Kasama's extension: where it goes and why. */
export interface PluginSecret {
  name: string;
  description: string;
  server: string;
  /** stdio: an environment variable; http: a header (the value may use {{value}}). */
  env?: string;
  header?: string;
  format?: string;
}

export interface PluginSkillFile {
  name: string;
  path: string;
}

export interface CheckedPlugin {
  manifest: PluginManifest;
  skills: PluginSkillFile[];
  servers: PluginServer[];
  secrets: PluginSecret[];
  /** Hosts the plugin's remote servers talk to. */
  hosts: string[];
  /** Non-fatal problems (skipped servers or skills, ignored fields). */
  warnings: string[];
}

export class PluginError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "PluginError";
  }
}

const isObj = (v: unknown): v is Record<string, unknown> =>
  typeof v === "object" && v !== null && !Array.isArray(v);
const strMap = (v: unknown) =>
  isObj(v) && Object.values(v).every((x) => typeof x === "string")
    ? (v as Record<string, string>)
    : null;

/** Checks plugin.json. Throws PluginError when the plugin must be rejected. */
export function checkManifest(raw: unknown, warnings: string[] = []): PluginManifest {
  if (!isObj(raw)) throw new PluginError("plugin.json must be a JSON object");
  if (typeof raw.$schema !== "string" || !raw.$schema)
    throw new PluginError("plugin.json needs $schema");
  if (raw.$schema !== PLUGIN_SCHEMA_1_0)
    throw new PluginError(`Unsupported Agent Plugins version (${raw.$schema}); Kasama reads 1.0.0`);
  if (typeof raw.name !== "string" || !raw.name) throw new PluginError("plugin.json needs a name");
  if (raw.name.length > 64 || !NAME.test(raw.name))
    throw new PluginError(
      `"${raw.name}" isn't a valid plugin name (lowercase letters, digits, dots and dashes)`,
    );
  for (const k of ["version", "description", "homepage", "repository", "license"] as const)
    if (raw[k] !== undefined && typeof raw[k] !== "string")
      throw new PluginError(`plugin.json ${k} must be a string`);
  if (
    raw.keywords !== undefined &&
    !(Array.isArray(raw.keywords) && raw.keywords.every((k) => typeof k === "string"))
  )
    throw new PluginError("plugin.json keywords must be a list of strings");
  if (raw.author !== undefined) {
    if (!isObj(raw.author)) throw new PluginError("plugin.json author must be an object");
    for (const [k, v] of Object.entries(raw.author))
      if (!["name", "email", "url"].includes(k) || typeof v !== "string")
        throw new PluginError(`plugin.json author.${k} isn't allowed`);
  }
  if (raw.extensions !== undefined && !isObj(raw.extensions))
    warnings.push("Ignored extensions: not an object");
  for (const k of Object.keys(raw))
    if (!MANIFEST_FIELDS.has(k)) warnings.push(`Ignored unknown field ${k}`);
  const { name, version, description, author, homepage, repository, license, keywords } =
    raw as PluginManifest & Record<string, unknown>;
  return { name, version, description, author, homepage, repository, license, keywords };
}

/** A plugin-relative path: starts with ./ and stays inside (symlinks are resolved by the caller). */
export function insidePlugin(p: string) {
  if (!p.startsWith("./")) return false;
  const parts: string[] = [];
  for (const seg of p.slice(2).split("/")) {
    if (seg === "" || seg === ".") continue;
    if (seg === "..") {
      if (!parts.length) return false;
      parts.pop();
    } else parts.push(seg);
  }
  return true;
}

function checkCwd(cwd: string) {
  if (cwd.startsWith("./")) return insidePlugin(cwd);
  for (const root of ["${PLUGIN_ROOT}", "${PLUGIN_DATA}"])
    if (cwd === root || cwd.startsWith(`${root}/`))
      return insidePlugin(`.${cwd.slice(root.length) || "/"}`);
  return false;
}

function checkUrl(u: string) {
  let url: URL;
  try {
    url = new URL(u);
  } catch {
    return "isn't an absolute URL";
  }
  if (url.protocol !== "https:" && url.protocol !== "http:") return "must be http or https";
  if (url.username || url.password) return "can't contain a user name or password";
  if (u.includes("#")) return "can't contain a fragment";
  const host = url.hostname.replace(/^\[|\]$/g, "");
  const loopback = host === "localhost" || /^127\./.test(host) || host === "::1";
  if (url.protocol === "http:" && !loopback) return "must use https";
  return null;
}

/** Checks one mcp.json server entry; returns null (with a warning) when it must be skipped. */
function checkServer(key: string, v: unknown, warnings: string[]): PluginServer | null {
  const skip = (why: string) => (warnings.push(`Skipped MCP server ${key}: ${why}`), null);
  if (!isObj(v)) return skip("not an object");
  if (v.type === "stdio") {
    for (const k of Object.keys(v))
      if (!["type", "command", "args", "env", "cwd"].includes(k)) return skip(`unknown field ${k}`);
    if (typeof v.command !== "string" || !v.command) return skip("needs a command");
    if (/\s/.test(v.command)) return skip("command must be one program, not a shell line");
    if (v.command.includes("/") && !insidePlugin(v.command))
      return skip("command path must start with ./ and stay inside the plugin");
    if (
      v.args !== undefined &&
      !(Array.isArray(v.args) && v.args.every((a) => typeof a === "string"))
    )
      return skip("args must be strings");
    const env = v.env === undefined ? {} : strMap(v.env);
    if (!env) return skip("env values must be strings");
    for (const k of Object.keys(env)) {
      if (k === "PLUGIN_ROOT" || k === "PLUGIN_DATA") return skip(`env can't set ${k}`);
      if (!ENV_KEY.test(k)) return skip(`bad env name ${k}`);
    }
    if (v.cwd !== undefined && (typeof v.cwd !== "string" || !checkCwd(v.cwd)))
      return skip("cwd must stay inside the plugin or its data folder");
    return {
      key,
      type: "stdio",
      command: v.command,
      args: (v.args as string[]) ?? [],
      env,
      cwd: v.cwd as string | undefined,
    };
  }
  if (v.type === "streamable-http" || v.type === "sse") {
    for (const k of Object.keys(v))
      if (!["type", "url", "headers"].includes(k)) return skip(`unknown field ${k}`);
    if (typeof v.url !== "string") return skip("needs a url");
    const bad = checkUrl(v.url);
    if (bad) return skip(`url ${bad}`);
    const headers = v.headers === undefined ? {} : strMap(v.headers);
    if (!headers) return skip("header values must be strings");
    const seen = new Set<string>();
    for (const [k, val] of Object.entries(headers)) {
      if (!HEADER_NAME.test(k) || /[\r\n\0]/.test(val)) return skip(`bad header ${k}`);
      if (seen.has(k.toLowerCase())) return skip(`duplicate header ${k}`);
      seen.add(k.toLowerCase());
    }
    return { key, type: v.type, url: v.url, headers };
  }
  return skip(`unsupported type ${String(v.type)}`);
}

/** Checks mcp.json; a broken file disables MCP for this plugin only (a warning, no servers). */
export function checkMcp(raw: unknown, warnings: string[] = []): PluginServer[] {
  if (!isObj(raw)) return (warnings.push("MCP disabled: mcp.json isn't a JSON object"), []);
  if (raw.$schema !== MCP_SCHEMA_1_0)
    return (warnings.push("MCP disabled: mcp.json $schema isn't 1.0.0"), []);
  if (!isObj(raw.mcpServers))
    return (warnings.push("MCP disabled: mcp.json needs an mcpServers object"), []);
  for (const k of Object.keys(raw))
    if (k !== "$schema" && k !== "mcpServers")
      return (warnings.push(`MCP disabled: unknown field ${k}`), []);
  return Object.entries(raw.mcpServers)
    .map(([k, v]) => checkServer(k, v, warnings))
    .filter((s): s is PluginServer => s !== null);
}

/** Secrets from `extensions["com.kasama"].secrets`, kept only when they point at a real server. */
export function pluginSecrets(
  rawManifest: unknown,
  servers: PluginServer[],
  warnings: string[] = [],
): PluginSecret[] {
  const ext =
    isObj(rawManifest) && isObj(rawManifest.extensions)
      ? rawManifest.extensions[KASAMA_EXTENSION]
      : undefined;
  if (!isObj(ext) || !Array.isArray(ext.secrets)) return [];
  const out: PluginSecret[] = [];
  for (const s of ext.secrets) {
    if (
      !isObj(s) ||
      typeof s.name !== "string" ||
      !SECRET_NAME.test(s.name) ||
      typeof s.server !== "string"
    ) {
      warnings.push("Ignored a secret: needs an uppercase name and a server");
      continue;
    }
    const server = servers.find((x) => x.key === s.server);
    if (!server) {
      warnings.push(`Ignored secret ${s.name}: no server ${s.server}`);
      continue;
    }
    const env = typeof s.env === "string" && ENV_KEY.test(s.env) ? s.env : undefined;
    const header =
      typeof s.header === "string" && HEADER_NAME.test(s.header) ? s.header : undefined;
    if ((server.type === "stdio" && !env) || (server.type !== "stdio" && !header)) {
      warnings.push(
        `Ignored secret ${s.name}: needs ${server.type === "stdio" ? "env" : "header"}`,
      );
      continue;
    }
    out.push({
      name: s.name,
      description: typeof s.description === "string" ? s.description.slice(0, 300) : "",
      server: s.server,
      env,
      header,
      format: typeof s.format === "string" && s.format.includes("{{value}}") ? s.format : undefined,
    });
  }
  return out;
}

/** Expands ${PLUGIN_ROOT} and ${PLUGIN_DATA} once (args, env values, cwd only). */
export function expandPluginVars(s: string, roots: { root: string; data: string }) {
  return s.replaceAll("${PLUGIN_ROOT}", roots.root).replaceAll("${PLUGIN_DATA}", roots.data);
}

/**
 * Checks a whole package from its files (path → text, paths relative to the plugin root without
 * "./"). Skills are the immediate folders of skills/ that hold a SKILL.md.
 */
export function checkPlugin(files: Map<string, string>): CheckedPlugin {
  const warnings: string[] = [];
  const text = files.get("plugin.json");
  if (text === undefined) throw new PluginError("No plugin.json at the plugin's root");
  let raw: unknown;
  try {
    raw = JSON.parse(text);
  } catch {
    throw new PluginError("plugin.json isn't valid JSON");
  }
  const manifest = checkManifest(raw, warnings);
  let servers: PluginServer[] = [];
  const mcpText = files.get("mcp.json");
  if (mcpText !== undefined) {
    try {
      servers = checkMcp(JSON.parse(mcpText), warnings);
    } catch {
      warnings.push("MCP disabled: mcp.json isn't valid JSON");
    }
  }
  const skills: PluginSkillFile[] = [];
  for (const p of files.keys()) {
    const m = /^skills\/([^/]+)\/SKILL\.md$/.exec(p);
    if (m) skills.push({ name: m[1] as string, path: `skills/${m[1]}` });
  }
  skills.sort((a, b) => a.name.localeCompare(b.name));
  const hosts = [
    ...new Set(servers.flatMap((s) => (s.type === "stdio" ? [] : [new URL(s.url).hostname]))),
  ];
  return {
    manifest,
    skills,
    servers,
    secrets: pluginSecrets(raw, servers, warnings),
    hosts,
    warnings,
  };
}
