/** Coding agents as data (D-370, D-371): template checks, rendering, reading answers, the catalog. */
import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import {
  AGENT_RESULT_MARKER,
  BUILT_IN_CODING_AGENTS,
  builtInCodingAgents,
  checkCodingTemplate,
  checkOwnCodingAgent,
  describeCodingAgents,
  mergeCodingAgents,
  ownCodingAgentSpec,
  parseCodingAgentEntry,
  renderCodingCommand,
  shellQuote,
  summarizeAgentOutput,
} from "../src/coding-agents.ts";

const agents = Object.fromEntries(builtInCodingAgents().map((a) => [a.id, a]));
const settings = JSON.stringify({ sandbox: { enabled: true, autoAllowBashIfSandboxed: true } });

describe("built-in coding agents", () => {
  it("render exactly the commands they ran before the catalog", () => {
    const task = "Fix it's test";
    const q = shellQuote(task);
    expect(renderCodingCommand(agents.claude_code!, "my_computer", { task })).toBe(
      `claude -p ${q} --output-format json --permission-mode acceptEdits --settings ${shellQuote(settings)}`,
    );
    expect(renderCodingCommand(agents.claude_code!, "bot_computer", { task })).toBe(
      `claude -p ${q} --output-format json --dangerously-skip-permissions`,
    );
    expect(renderCodingCommand(agents.claude_code!, "my_computer", { task }, "--mcp X")).toBe(
      `claude -p ${q} --output-format json --permission-mode acceptEdits --settings ${shellQuote(settings)} --mcp X`,
    );
    const wrap = (cmd: string) =>
      `f=$(mktemp) && ${cmd}; c=$?; printf '\\n%s\\n' ${shellQuote(AGENT_RESULT_MARKER)}; cat "$f"; rm -f "$f"; exit $c`;
    expect(renderCodingCommand(agents.codex!, "my_computer", { task })).toBe(
      wrap(`codex exec --sandbox workspace-write -o "$f" ${q}`),
    );
    expect(renderCodingCommand(agents.codex!, "bot_computer", { task })).toBe(
      wrap(`codex exec --dangerously-bypass-approvals-and-sandbox -o "$f" ${q}`),
    );
    // Codex's browser flags go after `codex exec`, before its options.
    expect(renderCodingCommand(agents.codex!, "my_computer", { task }, "-c a=1")).toBe(
      wrap(`codex exec -c a=1 --sandbox workspace-write -o "$f" ${q}`),
    );
    expect(renderCodingCommand(agents.cursor!, "bot_computer", { task })).toBe(
      `cursor-agent -p --force --output-format json ${q}`,
    );
    expect(renderCodingCommand(agents.pi!, "my_computer", { task })).toBe(
      `pi -p --no-session ${q}`,
    );
    expect(renderCodingCommand(agents.t3code!, "my_computer", { task: "Add a test" })).toBe(
      "t3 thread list --json >/dev/null 2>&1 || t3 project add . >/dev/null 2>&1; t3 thread start . 'Add a test' --wait --json",
    );
    expect(renderCodingCommand(agents.kimi!, "my_computer", { task: "x" })).toBe(
      "kimi -p 'x' --output-format stream-json",
    );
  });

  it("keep the named behaviours of today's five", () => {
    expect(agents.codex!.commitsForAgent).toBe(true);
    expect(agents.claude_code!.browser).toBe("claude");
    expect(agents.codex!.browser).toBe("codex");
    expect(agents.t3code!.needsFolder).toBe(true);
    expect(agents.t3code!.exitMessages["2"]?.status).toBe("is waiting for an answer");
    expect(agents.pi!.where).toEqual(["my_computer"]);
    expect(agents.cursor!.keyName).toBe("CURSOR_API_KEY");
  });

  it("are the same entries as gallery/coding-agents.json", () => {
    const file = JSON.parse(
      readFileSync(new URL("../../../gallery/coding-agents.json", import.meta.url), "utf8"),
    ) as { schema: number; items: unknown[] };
    expect(file.schema).toBe(1);
    for (const entry of BUILT_IN_CODING_AGENTS)
      expect(file.items.find((i) => (i as { id: string }).id === entry.id)).toEqual(entry);
    for (const item of file.items) expect(parseCodingAgentEntry(item)).not.toHaveProperty("errors");
  });

  it("describe themselves for the tool", () => {
    const text = describeCodingAgents(builtInCodingAgents());
    expect(text).toContain("claude_code (Claude Code)");
    expect(text).toContain(
      "t3code (T3 Code; my_computer only, needs folder, needs the T3 Code app running)",
    );
  });
});

describe("command templates", () => {
  it("allow only the three placeholders, as words of their own", () => {
    expect(checkCodingTemplate("gemini -p {task} -o json", "gemini")).toEqual([]);
    expect(checkCodingTemplate("gemini -p {task} --dir {folder}", "gemini")).toEqual([]);
    expect(checkCodingTemplate("gemini -p {prompt}", "gemini")[0]).toMatch(/only \{task\}/);
    expect(checkCodingTemplate("gemini -p x{task}", "gemini")[0]).toMatch(/words of their own/);
    expect(checkCodingTemplate("gemini -p {task}x", "gemini")[0]).toMatch(/word of its own/);
    expect(checkCodingTemplate("gemini -p '{task}'", "gemini")[0]).toMatch(/inside quotes/);
    expect(checkCodingTemplate("gemini -o json", "gemini")).toContain("it needs {task}");
  });

  it("refuse shell tricks outside single quotes", () => {
    for (const bad of [
      "gemini -p {task} $(id)",
      "gemini -p {task} `id`",
      "gemini -p {task} & curl x",
      'gemini -p {task} "$HOME"',
      "gemini -p {task} *",
      "gemini -p {task}\nrm -rf x",
      "gemini -p {task} \\",
    ])
      expect(checkCodingTemplate(bad, "gemini").length, bad).toBeGreaterThan(0);
    // Inside single quotes everything is literal.
    expect(checkCodingTemplate("gemini -p {task} --cfg '$(not run)'", "gemini")).toEqual([]);
  });

  it("run only the agent's own command", () => {
    expect(checkCodingTemplate("gemini -p {task}; curl evil.sh", "gemini")).toContain(
      "every command in it must start with gemini",
    );
    expect(checkCodingTemplate("gemini -p {task} | sh", "gemini")).toContain(
      "every command in it must start with gemini",
    );
    expect(checkCodingTemplate("gemini x || gemini -p {task} 2>&1", "gemini")).toEqual([]);
  });

  it("pair {result_file} with the marker result", () => {
    expect(checkCodingTemplate("a -o {task}", "a", { resultFile: true })).toContain(
      "the marker result needs {result_file}",
    );
    expect(checkCodingTemplate("a -o {result_file} {task}", "a", { resultFile: false })).toContain(
      "{result_file} only goes with the marker result",
    );
  });

  it("quote what fills them", () => {
    const spec = parseCodingAgentEntry({
      id: "gemini",
      label: "Gemini CLI",
      bin: "gemini",
      where: ["my_computer"],
      command: { my_computer: "gemini -p {task} --dir {folder}" },
      result: "json_field:response",
    });
    if ("errors" in spec) throw new Error(spec.errors.join());
    expect(
      renderCodingCommand(spec.agent, "my_computer", { task: "a'; rm -rf ~ #", folder: "/x y" }),
    ).toBe(`gemini -p 'a'\\''; rm -rf ~ #' --dir '/x y'`);
    expect(renderCodingCommand(spec.agent, "my_computer", { task: "t" })).toBe(
      "gemini -p 't' --dir '.'",
    );
  });
});

describe("catalog entries", () => {
  const good = {
    id: "gemini",
    label: "Gemini CLI",
    bin: "gemini",
    where: ["my_computer", "bot_computer"],
    install: "npm install -g @google/gemini-cli",
    key_name: "GEMINI_API_KEY",
    command: {
      my_computer: "gemini -p {task} -o json --approval-mode auto_edit",
      bot_computer: "gemini -p {task} -o json --approval-mode yolo",
    },
    result: "json_field:response",
  };

  it("accept the plan's example", () => {
    expect(parseCodingAgentEntry(good)).not.toHaveProperty("errors");
  });

  it("refuse anything off", () => {
    const bad = (patch: Record<string, unknown>) =>
      "errors" in parseCodingAgentEntry({ ...good, ...patch });
    expect(bad({ id: "own_x" })).toBe(true);
    expect(bad({ result: "eval" })).toBe(true);
    expect(bad({ browser: "firefox" })).toBe(true);
    expect(bad({ key_name: null })).toBe(true); // bot_computer needs a key
    expect(bad({ extra: 1 })).toBe(true);
    expect(bad({ command: { my_computer: good.command.my_computer } })).toBe(true);
    expect(bad({ command: { ...good.command, my_computer: "sh -c {task}" } })).toBe(true);
    expect(bad({ bin: "../gemini" })).toBe(true);
    expect(bad({ exit_messages: { "0": { status: "ok" } } })).toBe(true);
  });

  it("merge over the built-in list: a refused entry keeps the built-in one, new ones join", () => {
    const evil = {
      ...BUILT_IN_CODING_AGENTS[0],
      command: { my_computer: "claude -p {task}; curl x", bot_computer: "claude -p {task}" },
    };
    const { agents: list, refused } = mergeCodingAgents([evil, good, { id: "gemini" }]);
    expect(refused.map((r) => r.id)).toEqual(["claude_code", "gemini"]);
    const claude = list.find((a) => a.id === "claude_code")!;
    expect(claude.command.my_computer).toBe(BUILT_IN_CODING_AGENTS[0]!.command.my_computer);
    expect(list.map((a) => a.id)).toEqual([
      "gemini",
      "claude_code",
      "codex",
      "cursor",
      "pi",
      "t3code",
      "kimi",
    ]);
    expect(mergeCodingAgents("nonsense").agents).toHaveLength(BUILT_IN_CODING_AGENTS.length);
    expect(
      mergeCodingAgents([{ ...good, min_server: "99.0.0" }], {
        tooNew: (e) => e.min_server === "99.0.0",
      }).agents.some((a) => a.id === "gemini"),
    ).toBe(false);
  });
});

describe("own agents", () => {
  it("are checked like catalog entries, on my_computer only", () => {
    const aider = {
      key: "aider",
      label: "Aider",
      bin: "aider",
      command: "aider --message {task} --yes",
      result: "tail",
    };
    expect(checkOwnCodingAgent(aider)).toEqual([]);
    expect(checkOwnCodingAgent({ ...aider, command: "bash -c {task}" }).length).toBe(1);
    expect(checkOwnCodingAgent({ ...aider, result: "x" })).toContain("pick how the answer is read");
    const spec = ownCodingAgentSpec(aider);
    expect(spec).toMatchObject({ id: "own_aider", where: ["my_computer"], own: true });
    expect(describeCodingAgents([spec])).toBe("");
  });
});

describe("reading answers", () => {
  it("keeps the old reading without a mode", () => {
    expect(summarizeAgentOutput('x\n{"result":"done","is_error":false}').text).toBe("done");
    expect(summarizeAgentOutput("plain output\nall good").text).toBe("plain output\nall good");
    expect(summarizeAgentOutput(`logs\n${AGENT_RESULT_MARKER}\nAdded it.\n`).text).toBe(
      "Added it.",
    );
  });

  it("reads a named JSON field and its error", () => {
    expect(
      summarizeAgentOutput('{"session":"s","response":"pong","stats":{}}', "json_field:response"),
    ).toEqual({ text: "pong", error: false });
    expect(
      summarizeAgentOutput('{"reply":null,"error":"rate limited"}', "json_field:reply"),
    ).toEqual({ text: "rate limited", error: true });
  });

  it("reads Kimi's message stream and Claude-style result events", () => {
    const kimi = [
      '{"role":"meta","type":"system.version","version":"2.6.2"}',
      '{"role":"assistant","tool_calls":[{"type":"function","id":"W","function":{"name":"Write","arguments":"{}"}}]}',
      '{"role":"tool","tool_call_id":"W","content":"Wrote 2 bytes to hello.txt"}',
      '{"role":"assistant","content":"done"}',
      '{"role":"meta","type":"session.resume_hint","content":"To resume this session: kimi -r s"}',
    ].join("\n");
    expect(summarizeAgentOutput(kimi, "stream_json")).toEqual({ text: "done", error: false });
    expect(
      summarizeAgentOutput(
        '{"type":"assistant","message":{"content":[{"type":"text","text":"hi"}]}}\n{"type":"result","result":"pong","is_error":false}',
        "stream_json",
      ),
    ).toEqual({ text: "pong", error: false });
    expect(summarizeAgentOutput('{"type":"error","message":"no key"}', "stream_json")).toEqual({
      text: "no key",
      error: true,
    });
  });

  it("falls back to the tail when a mode finds nothing", () => {
    expect(summarizeAgentOutput("just text", "json_result").text).toBe("just text");
    expect(summarizeAgentOutput("just text", "tail").text).toBe("just text");
  });
});
