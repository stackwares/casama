/**
 * Coding agents as data (D-370, docs/REMOTE-CONTENT-PLAN.md §2): the catalog entries that
 * `coding.delegate` runs, the people's own agents (D-371), and the checks every entry passes
 * before a command is ever built from it. No I/O.
 *
 * A command is a template with three placeholders, `{task}`, `{folder}` and `{result_file}`, each a
 * whole unquoted word that the server fills with a shell-quoted value. Every command in a template
 * (split at `;`, `&&`, `||`, `|`) starts with the agent's own `bin`. No `$`, backticks, parentheses,
 * braces, backslashes, globs, background `&` or newlines outside single quotes. What can't be said
 * this way is a named behaviour in code (`result`, `browser`, `commits_for_agent`), not a template.
 */

export type CodingWhere = "my_computer" | "bot_computer";
export const CODING_WHERE: readonly CodingWhere[] = ["my_computer", "bot_computer"];

/** How the agent's final answer is read from its output. `json_field:<name>` names the field. */
export const CODING_RESULT_MODES = ["json_result", "marker", "stream_json", "tail"] as const;
export type CodingResultMode = (typeof CODING_RESULT_MODES)[number] | `json_field:${string}`;

/** The person's browser as an MCP server, in the flags each agent family takes (D-323 C16). */
export type CodingBrowserFlags = "claude" | "codex";

/** What a template may contain as placeholders. */
export const CODING_PLACEHOLDERS = ["task", "folder", "result_file"] as const;

/** Printed before an agent's final message when it writes that message to a file (`marker`). */
export const AGENT_RESULT_MARKER = "<<<casama-agent-result>>>";

/** The task the desktop app's Test button runs (D-371). */
export const CODING_TEST_TASK = "Reply with just the word pong. Do not use tools.";

/** Ids that start with this are people's own agents (D-371); catalog ids never do. */
export const OWN_AGENT_PREFIX = "own_";

export interface CodingExitMessage {
  /** Replaces "failed (exit N)" in the result's first line, e.g. "is waiting for an answer". */
  status: string;
  /** Added to the end of the result. */
  note?: string;
}

/** One coding agent, as `coding.delegate` uses it. */
export interface CodingAgentSpec {
  id: string;
  label: string;
  bin: string;
  where: CodingWhere[];
  /** Installs the CLI on the bot's computer (bot_computer only). */
  install: string | null;
  /** The bot's named secret passed to the CLI on the bot's computer. */
  keyName: string | null;
  command: Partial<Record<CodingWhere, string>>;
  result: CodingResultMode;
  browser: CodingBrowserFlags | null;
  /** Codex's sandbox can't write .git: Casama commits its changes on the branch for it. */
  commitsForAgent: boolean;
  needsFolder: boolean;
  exitMessages: Record<string, CodingExitMessage>;
  /** A short note for the model, e.g. "needs the T3 Code app running". */
  hint: string | null;
  /** A person's own agent on their computer (D-371). */
  own?: boolean;
  /** Own agents: the default time limit in minutes. */
  timeoutMin?: number;
}

/** The catalog file's entry, as gallery/coding-agents.json writes it. */
export interface CodingAgentEntry {
  id: string;
  label: string;
  bin: string;
  where: CodingWhere[];
  install?: string | null;
  key_name?: string | null;
  command: Partial<Record<CodingWhere, string>>;
  result: string;
  browser?: CodingBrowserFlags | null;
  commits_for_agent?: boolean;
  needs_folder?: boolean;
  exit_messages?: Record<string, CodingExitMessage>;
  hint?: string | null;
  min_server?: string;
}

/**
 * Today's agents, the fallback when the gallery's list can't be read or an entry fails its check.
 * gallery/coding-agents.json carries the same entries (a test keeps them in step).
 */
export const BUILT_IN_CODING_AGENTS: readonly CodingAgentEntry[] = [
  {
    id: "claude_code",
    label: "Claude Code",
    bin: "claude",
    where: ["my_computer", "bot_computer"],
    install: "npm install -g @anthropic-ai/claude-code",
    key_name: "ANTHROPIC_API_KEY",
    command: {
      // Its own sandbox lets it run tests and git without asking, writes kept to the project.
      my_computer: `claude -p {task} --output-format json --permission-mode acceptEdits --settings '{"sandbox":{"enabled":true,"autoAllowBashIfSandboxed":true}}'`,
      bot_computer: "claude -p {task} --output-format json --dangerously-skip-permissions",
    },
    result: "json_result",
    browser: "claude",
  },
  {
    id: "codex",
    label: "Codex",
    bin: "codex",
    where: ["my_computer", "bot_computer"],
    install: "npm install -g @openai/codex",
    key_name: "OPENAI_API_KEY",
    command: {
      my_computer: "codex exec --sandbox workspace-write -o {result_file} {task}",
      bot_computer: "codex exec --dangerously-bypass-approvals-and-sandbox -o {result_file} {task}",
    },
    result: "marker",
    browser: "codex",
    commits_for_agent: true,
  },
  {
    id: "cursor",
    label: "Cursor",
    bin: "cursor-agent",
    where: ["my_computer", "bot_computer"],
    install: "curl -fsS https://cursor.com/install | bash",
    key_name: "CURSOR_API_KEY",
    command: {
      my_computer: "cursor-agent -p --force --output-format json {task}",
      bot_computer: "cursor-agent -p --force --output-format json {task}",
    },
    result: "json_result",
  },
  {
    id: "pi",
    label: "Pi",
    bin: "pi",
    where: ["my_computer"],
    command: { my_computer: "pi -p --no-session {task}" },
    result: "tail",
  },
  {
    id: "t3code",
    label: "T3 Code",
    bin: "t3",
    where: ["my_computer"],
    command: {
      my_computer:
        "t3 thread list --json >/dev/null 2>&1 || t3 project add . >/dev/null 2>&1; t3 thread start . {task} --wait --json",
    },
    result: "json_field:reply",
    needs_folder: true,
    hint: "needs the T3 Code app running",
    exit_messages: {
      "2": {
        status: "is waiting for an answer",
        note: "T3 Code stopped to ask a question: answer it in its thread in T3 Code.",
      },
    },
  },
  {
    id: "kimi",
    label: "Kimi Code",
    bin: "kimi",
    where: ["my_computer"],
    command: { my_computer: "kimi -p {task} --output-format stream-json" },
    result: "stream_json",
  },
];

/** The agents shipped apps (0.1.0+34 and older) already knew: allowed whenever commands are on. */
export const PREALLOWED_CODING_AGENTS: readonly string[] = [
  "claude_code",
  "codex",
  "cursor",
  "pi",
  "t3code",
];

const ID = /^[a-z][a-z0-9_]{1,31}$/;
const OWN_KEY = /^[a-z][a-z0-9_]{0,23}$/;
const BIN = /^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/;
const KEY_NAME = /^[A-Z][A-Z0-9_]{1,63}$/;
const FIELD = /^[A-Za-z_][A-Za-z0-9_]{0,31}$/;
const SEMVER = /^\d{1,4}\.\d{1,4}\.\d{1,4}$/;
const ENTRY_KEYS = new Set([
  "id",
  "label",
  "bin",
  "where",
  "install",
  "key_name",
  "command",
  "result",
  "browser",
  "commits_for_agent",
  "needs_folder",
  "exit_messages",
  "hint",
  "min_server",
]);
/** Characters a bare word may hold. */
const WORD_CHAR = /[A-Za-z0-9_\-./=:,@+%^~]/;

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

/** One line of text, no control characters. */
const plainText = (v: unknown, max: number) =>
  typeof v === "string" &&
  v.trim().length > 0 &&
  v.length <= max &&
  ![...v].some((ch) => ch.charCodeAt(0) < 0x20);

export function isCodingResultMode(v: unknown): v is CodingResultMode {
  if (typeof v !== "string") return false;
  if ((CODING_RESULT_MODES as readonly string[]).includes(v)) return true;
  return v.startsWith("json_field:") && FIELD.test(v.slice("json_field:".length));
}

type Token =
  | { kind: "word"; text: string; start: number; end: number }
  | { kind: "placeholder"; name: string; start: number; end: number }
  | { kind: "op"; text: string; start: number; end: number };

/**
 * Splits a template into words, placeholders and operators, or returns what's wrong with it.
 * Words may mix bare characters, 'single-quoted' and "double-quoted" parts (no `$`, backticks or
 * backslashes in double quotes). Redirections (`>file`, `2>&1`) count as words.
 */
export function tokenizeCodingTemplate(template: string): { tokens: Token[] } | { error: string } {
  const tokens: Token[] = [];
  let i = 0;
  const n = template.length;
  while (i < n) {
    const ch = template[i] as string;
    if (ch === " " || ch === "\t") {
      i++;
      continue;
    }
    if (ch === "\n" || ch === "\r") return { error: "a command is one line" };
    // Operators that separate commands.
    const two = template.slice(i, i + 2);
    if (two === "&&" || two === "||") {
      tokens.push({ kind: "op", text: two, start: i, end: i + 2 });
      i += 2;
      continue;
    }
    if (ch === ";" || ch === "|") {
      tokens.push({ kind: "op", text: ch, start: i, end: i + 1 });
      i++;
      continue;
    }
    // A placeholder: a whole word of its own.
    if (ch === "{") {
      const close = template.indexOf("}", i);
      const name = close > i ? template.slice(i + 1, close) : "";
      if (!(CODING_PLACEHOLDERS as readonly string[]).includes(name))
        return {
          error: `only {task}, {folder} and {result_file} may be used (found ${template.slice(i, close > i ? close + 1 : i + 12)})`,
        };
      const after = template[close + 1];
      if (after !== undefined && !/[\s;|&]/.test(after))
        return { error: `{${name}} must be a word of its own` };
      tokens.push({ kind: "placeholder", name, start: i, end: close + 1 });
      i = close + 1;
      continue;
    }
    // A word.
    const start = i;
    let text = "";
    while (i < n) {
      const c = template[i] as string;
      if (c === " " || c === "\t" || c === ";" || c === "|") break;
      if (c === "&") {
        // `2>&1` and `>&2` are redirections; `&&` ends the word; a lone `&` would background it.
        if (template[i + 1] === "&") break;
        if (template[i - 1] === ">" && /[0-9]/.test(template[i + 1] ?? "")) {
          text += c;
          i++;
          continue;
        }
        return { error: "a command can't run in the background (&)" };
      }
      if (c === "'") {
        const close = template.indexOf("'", i + 1);
        if (close < 0) return { error: "a quote isn't closed" };
        const inner = template.slice(i + 1, close);
        if (/\{(task|folder|result_file)\}/.test(inner))
          return { error: "placeholders can't be inside quotes: the server quotes them" };
        if (/[\n\r]/.test(inner)) return { error: "a command is one line" };
        text += inner;
        i = close + 1;
        continue;
      }
      if (c === '"') {
        const close = template.indexOf('"', i + 1);
        if (close < 0) return { error: "a quote isn't closed" };
        const inner = template.slice(i + 1, close);
        if (/[$`\\\n\r]/.test(inner))
          return { error: "double quotes can't hold $, backticks or backslashes" };
        if (/\{(task|folder|result_file)\}/.test(inner))
          return { error: "placeholders can't be inside quotes: the server quotes them" };
        text += inner;
        i = close + 1;
        continue;
      }
      if (c === ">" || c === "<") {
        text += c;
        i++;
        continue;
      }
      if (c === "{") return { error: "placeholders must be words of their own" };
      if (!WORD_CHAR.test(c))
        return {
          error: `"${c}" isn't allowed outside quotes (no $, backticks, parentheses, braces, backslashes or globs)`,
        };
      text += c;
      i++;
    }
    tokens.push({ kind: "word", text, start, end: i });
  }
  return { tokens };
}

/** What's wrong with a command template for an agent whose CLI is `bin`; empty when it's fine. */
export function checkCodingTemplate(
  template: unknown,
  bin: string,
  opts: { resultFile?: boolean } = {},
): string[] {
  if (typeof template !== "string" || !template.trim()) return ["the command is empty"];
  if (template.length > 1000) return ["the command is longer than 1000 characters"];
  const parsed = tokenizeCodingTemplate(template);
  if ("error" in parsed) return [parsed.error];
  const errors: string[] = [];
  const { tokens } = parsed;
  // Every command starts with the agent's own bin.
  let atStart = true;
  for (const t of tokens) {
    if (t.kind === "op") {
      if (atStart) errors.push(`"${t.text}" needs a command before it`);
      atStart = true;
      continue;
    }
    if (atStart) {
      if (t.kind !== "word" || t.text !== bin)
        errors.push(`every command in it must start with ${bin}`);
      atStart = false;
    }
  }
  if (atStart && tokens.length) errors.push("it can't end with an operator");
  const names = tokens.filter((t) => t.kind === "placeholder").map((t) => t.name);
  if (!names.includes("task")) errors.push("it needs {task}");
  if (names.filter((x) => x === "task").length > 1) errors.push("{task} may appear once");
  if (opts.resultFile === true && !names.includes("result_file"))
    errors.push("the marker result needs {result_file}");
  if (opts.resultFile === false && names.includes("result_file"))
    errors.push("{result_file} only goes with the marker result");
  return [...new Set(errors)];
}

/**
 * Checks one catalog entry. A bad entry is refused whole; callers keep the built-in agent of that id
 * (if any) instead.
 */
export function parseCodingAgentEntry(
  raw: unknown,
): { agent: CodingAgentSpec; entry: CodingAgentEntry } | { errors: string[] } {
  if (!isRecord(raw)) return { errors: ["an entry must be an object"] };
  const errors: string[] = [];
  for (const k of Object.keys(raw)) if (!ENTRY_KEYS.has(k)) errors.push(`unknown field ${k}`);
  const id = raw.id;
  if (typeof id !== "string" || !ID.test(id))
    errors.push("id must be 2 to 32 lower-case letters, digits or _");
  else if (id.startsWith(OWN_AGENT_PREFIX)) errors.push(`id can't start with ${OWN_AGENT_PREFIX}`);
  if (!plainText(raw.label, 40)) errors.push("label must be 1 to 40 characters");
  const bin = raw.bin;
  if (typeof bin !== "string" || !BIN.test(bin))
    errors.push("bin must be a command name (letters, digits, . _ -)");
  const where = raw.where;
  const whereOk =
    Array.isArray(where) &&
    where.length > 0 &&
    where.every((w) => (CODING_WHERE as readonly unknown[]).includes(w)) &&
    new Set(where).size === where.length;
  if (!whereOk) errors.push("where must list my_computer and/or bot_computer");
  const install = raw.install ?? null;
  const keyName = raw.key_name ?? null;
  if (install !== null && !plainText(install, 300))
    errors.push("install must be one line of at most 300 characters");
  if (keyName !== null && (typeof keyName !== "string" || !KEY_NAME.test(keyName)))
    errors.push("key_name must be UPPER_SNAKE_CASE");
  if (whereOk && (where as string[]).includes("bot_computer") && (!install || !keyName))
    errors.push("bot_computer needs install and key_name");
  const result = raw.result;
  if (!isCodingResultMode(result))
    errors.push("result must be json_result, marker, json_field:<name>, stream_json or tail");
  const command = raw.command;
  if (!isRecord(command)) errors.push("command must be an object by where");
  else if (whereOk && typeof bin === "string" && BIN.test(bin)) {
    for (const k of Object.keys(command))
      if (!(where as string[]).includes(k)) errors.push(`command.${k} isn't in where`);
    for (const w of where as CodingWhere[]) {
      const errs = checkCodingTemplate(command[w], bin, { resultFile: result === "marker" });
      for (const e of errs) errors.push(`command.${w}: ${e}`);
    }
  }
  const browser = raw.browser ?? null;
  if (browser !== null && browser !== "claude" && browser !== "codex")
    errors.push("browser must be claude, codex or left out");
  for (const k of ["commits_for_agent", "needs_folder"] as const)
    if (raw[k] !== undefined && typeof raw[k] !== "boolean")
      errors.push(`${k} must be true or false`);
  const exits = raw.exit_messages ?? {};
  const exitMessages: Record<string, CodingExitMessage> = {};
  if (!isRecord(exits)) errors.push("exit_messages must be an object");
  else
    for (const [code, m] of Object.entries(exits)) {
      if (!/^[1-9][0-9]{0,2}$/.test(code)) errors.push(`exit_messages.${code}: not an exit code`);
      else if (
        !isRecord(m) ||
        !plainText(m.status, 80) ||
        (m.note !== undefined && !plainText(m.note, 300))
      )
        errors.push(`exit_messages.${code} needs a status (and an optional note)`);
      else
        exitMessages[code] = {
          status: m.status as string,
          ...(m.note ? { note: m.note as string } : {}),
        };
    }
  const hint = raw.hint ?? null;
  if (hint !== null && !plainText(hint, 160)) errors.push("hint must be at most 160 characters");
  if (
    raw.min_server !== undefined &&
    (typeof raw.min_server !== "string" || !SEMVER.test(raw.min_server))
  )
    errors.push("min_server must be a version like 0.2.0");
  if (errors.length) return { errors };
  const agent: CodingAgentSpec = {
    id: id as string,
    label: (raw.label as string).trim(),
    bin: bin as string,
    where: [...(where as CodingWhere[])],
    install: install as string | null,
    keyName: keyName as string | null,
    command: Object.fromEntries(
      (where as CodingWhere[]).map((w) => [w, (command as Record<string, string>)[w]]),
    ),
    result: result as CodingResultMode,
    browser: browser as CodingBrowserFlags | null,
    commitsForAgent: raw.commits_for_agent === true,
    needsFolder: raw.needs_folder === true,
    exitMessages,
    hint: hint as string | null,
  };
  return { agent, entry: raw as unknown as CodingAgentEntry };
}

/** The built-in agents as specs. */
export function builtInCodingAgents(): CodingAgentSpec[] {
  return BUILT_IN_CODING_AGENTS.map((e) => {
    const r = parseCodingAgentEntry(e);
    if ("errors" in r) throw new Error(`built-in coding agent ${e.id}: ${r.errors.join("; ")}`);
    return r.agent;
  });
}

/**
 * The catalog this server uses: the gallery's entries that pass their check (in its order), then
 * the built-in agents it doesn't name. An entry that fails keeps the built-in one of that id.
 * `tooNew` drops entries for a newer server (min_server).
 */
export function mergeCodingAgents(
  items: unknown,
  opts: { tooNew?: (entry: Record<string, unknown>) => boolean } = {},
): { agents: CodingAgentSpec[]; refused: { id: string; errors: string[] }[] } {
  const builtIn = builtInCodingAgents();
  const out: CodingAgentSpec[] = [];
  const refused: { id: string; errors: string[] }[] = [];
  const seen = new Set<string>();
  for (const raw of Array.isArray(items) ? items : []) {
    const rid = isRecord(raw) && typeof raw.id === "string" ? raw.id : "?";
    if (isRecord(raw) && opts.tooNew?.(raw)) continue;
    const r = parseCodingAgentEntry(raw);
    if ("errors" in r) {
      refused.push({ id: rid.slice(0, 40), errors: r.errors });
      continue;
    }
    if (seen.has(r.agent.id)) {
      refused.push({ id: r.agent.id, errors: ["named twice"] });
      continue;
    }
    seen.add(r.agent.id);
    out.push(r.agent);
  }
  for (const b of builtIn) if (!seen.has(b.id)) out.push(b);
  return { agents: out, refused };
}

/** A person's own agent as stored (D-371). */
export interface OwnCodingAgent {
  key: string;
  label: string;
  bin: string;
  command: string;
  result: string;
  timeout_min?: number;
}

/** Checks a person's own agent: the same rules as a catalog entry, on my_computer only. */
export function checkOwnCodingAgent(raw: OwnCodingAgent): string[] {
  const errors: string[] = [];
  if (typeof raw.key !== "string" || !OWN_KEY.test(raw.key))
    errors.push("key must be 1 to 24 lower-case letters, digits or _");
  if (!plainText(raw.label, 40)) errors.push("label must be 1 to 40 characters");
  if (typeof raw.bin !== "string" || !BIN.test(raw.bin))
    errors.push("the command name must be letters, digits, . _ or -");
  else
    errors.push(
      ...checkCodingTemplate(raw.command, raw.bin, { resultFile: raw.result === "marker" }),
    );
  if (!isCodingResultMode(raw.result)) errors.push("pick how the answer is read");
  if (
    raw.timeout_min !== undefined &&
    (!Number.isInteger(raw.timeout_min) || raw.timeout_min < 1 || raw.timeout_min > 120)
  )
    errors.push("the time limit is 1 to 120 minutes");
  return errors;
}

/** A person's own agent as a spec `coding.delegate` can run (my_computer only). */
export function ownCodingAgentSpec(raw: OwnCodingAgent): CodingAgentSpec {
  return {
    id: `${OWN_AGENT_PREFIX}${raw.key}`,
    label: raw.label,
    bin: raw.bin,
    where: ["my_computer"],
    install: null,
    keyName: null,
    command: { my_computer: raw.command },
    result: raw.result as CodingResultMode,
    browser: null,
    commitsForAgent: false,
    needsFolder: false,
    exitMessages: {},
    hint: null,
    own: true,
    timeoutMin: raw.timeout_min ?? 30,
  };
}

/** Single-quotes a value for the shell. */
export const shellQuote = (s: string) => `'${s.replaceAll("'", `'\\''`)}'`;

/**
 * The command to run. Placeholders get shell-quoted values; `marker` wraps the command so the file
 * the agent wrote its answer to is printed after the marker; `browserFlags` go where the agent's
 * family takes them (Claude: at the end, its --allowedTools takes several values; Codex: right
 * after its leading words, `codex exec`).
 */
export function renderCodingCommand(
  spec: Pick<CodingAgentSpec, "command" | "result" | "browser">,
  where: CodingWhere,
  values: { task: string; folder?: string | null },
  browserFlags?: string | null,
): string {
  const template = spec.command[where];
  if (!template) throw new Error(`no command for ${where}`);
  const parsed = tokenizeCodingTemplate(template);
  if ("error" in parsed) throw new Error(parsed.error);
  const marker = spec.result === "marker";
  const fill = (name: string) =>
    name === "task"
      ? shellQuote(values.task)
      : name === "folder"
        ? shellQuote(values.folder || ".")
        : '"$f"';
  // Where the Codex flags go: after the first run of plain words (the bin and its subcommand).
  let codexAt = -1;
  if (browserFlags && spec.browser === "codex") {
    for (const t of parsed.tokens) {
      if (t.kind !== "word" || t.text.startsWith("-") || /[<>]/.test(t.text)) break;
      codexAt = t.end;
    }
  }
  let out = "";
  let at = 0;
  for (const t of parsed.tokens) {
    if (t.kind === "placeholder") {
      out += template.slice(at, t.start) + fill(t.name);
      at = t.end;
    }
    if (codexAt >= 0 && t.end === codexAt) {
      out += `${template.slice(at, t.end)} ${browserFlags}`;
      at = t.end;
    }
  }
  out += template.slice(at);
  if (browserFlags && spec.browser === "claude") out += ` ${browserFlags}`;
  if (marker)
    out = `f=$(mktemp) && ${out}; c=$?; printf '\\n%s\\n' ${shellQuote(AGENT_RESULT_MARKER)}; cat "$f"; rm -f "$f"; exit $c`;
  return out;
}

const cap = (text: string) => (text.length > 3000 ? `${text.slice(0, 3000)}…` : text);

function jsonLines(out: string): Record<string, unknown>[] {
  const lines: Record<string, unknown>[] = [];
  for (const line of out.trim().split("\n").reverse()) {
    const t = line.trim();
    if (!t.startsWith("{")) continue;
    try {
      const j = JSON.parse(t) as unknown;
      if (isRecord(j)) lines.push(j);
    } catch {
      // not JSON
    }
  }
  return lines; // newest first
}

const errText = (e: unknown) => (e == null ? "" : typeof e === "string" ? e : JSON.stringify(e));

/** A message's text: a string, or the text parts of a list of content blocks. */
function contentText(c: unknown): string {
  if (typeof c === "string") return c;
  if (Array.isArray(c))
    return c
      .map((p) => (isRecord(p) && p.type === "text" && typeof p.text === "string" ? p.text : ""))
      .filter(Boolean)
      .join("\n");
  return "";
}

/** Reads the answer the way `mode` says; null when the output doesn't have it. */
function byMode(out: string, mode: CodingResultMode): { text: string; error: boolean } | null {
  if (mode === "marker") {
    const at = out.lastIndexOf(AGENT_RESULT_MARKER);
    if (at < 0) return null;
    const text = out.slice(at + AGENT_RESULT_MARKER.length).trim();
    return text ? { text: cap(text), error: false } : null;
  }
  if (mode === "json_result") {
    for (const j of jsonLines(out))
      if (typeof j.result === "string") return { text: j.result, error: j.is_error === true };
    return null;
  }
  if (mode.startsWith("json_field:")) {
    const field = mode.slice("json_field:".length);
    for (const j of jsonLines(out)) {
      if (typeof j[field] === "string" || (j.error != null && field in j)) {
        const err = errText(j.error);
        return {
          text: [j[field], err].filter((x) => typeof x === "string" && x).join("\n\n"),
          error: !!err,
        };
      }
    }
    return null;
  }
  if (mode === "stream_json") {
    for (const j of jsonLines(out)) {
      // Claude-style streams end with a result event.
      if (j.type === "result" && typeof j.result === "string")
        return { text: j.result, error: j.is_error === true };
      if (j.type === "error" && (typeof j.message === "string" || j.error != null))
        return { text: errText(j.message ?? j.error), error: true };
      // Message streams (Kimi): the last assistant message with text.
      if (j.role === "assistant") {
        const text = contentText(j.content);
        if (text) return { text: cap(text), error: false };
      }
      if (j.type === "assistant" && isRecord(j.message)) {
        const text = contentText(j.message.content);
        if (text) return { text: cap(text), error: false };
      }
    }
    return null;
  }
  return null;
}

/**
 * The text an agent's output ends with. With a mode, what that mode reads; otherwise (or when it
 * finds nothing) what follows the result marker, a JSON `result`, T3 Code's `reply`, else the tail.
 */
export function summarizeAgentOutput(
  out: string,
  mode?: CodingResultMode,
): { text: string; error: boolean } {
  if (mode && mode !== "tail") {
    const got = byMode(out, mode);
    if (got) return got;
  }
  const marked = byMode(out, "marker");
  if (marked) return marked;
  for (const j of jsonLines(out)) {
    if (typeof j.result === "string") return { text: j.result, error: j.is_error === true };
    // T3 Code's `thread start --json`.
    if (typeof j.reply === "string" || (j.error != null && "threadId" in j)) {
      const err = errText(j.error);
      return {
        text: [j.reply, err].filter((x) => typeof x === "string" && x).join("\n\n"),
        error: !!err,
      };
    }
  }
  const tail = out.trim();
  return { text: tail.length > 3000 ? `…${tail.slice(-3000)}` : tail, error: false };
}

/** The tool description's list of agents, e.g. "claude_code (Claude Code), pi (Pi; my_computer only)". */
export function describeCodingAgents(agents: CodingAgentSpec[]): string {
  return agents
    .filter((a) => !a.own)
    .map((a) => {
      const notes = [
        a.where.length === 1 ? `${a.where[0]} only` : "",
        a.needsFolder ? "needs folder" : "",
        a.hint ?? "",
      ].filter(Boolean);
      return `${a.id} (${a.label}${notes.length ? `; ${notes.join(", ")}` : ""})`;
    })
    .join(", ");
}
