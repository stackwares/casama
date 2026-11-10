import { describe, expect, it } from "vitest";
import { z } from "zod";
import { checkReplaySteps, describeOutcome, executeReplay, fillParams, findRef, REPLAY_STOPPED, replayFromTeach } from "../src/replays.ts";
import { ToolRegistry } from "../src/tools/registry.ts";

const SNAP = `- heading "Expenses" [level=1]
- textbox "Amount" [ref=e3]
- button "Submit expense" [ref=e7]
- link "Submit" [ref=e9]`;

describe("step replay", () => {
  it("fills parameters and finds elements by role and label", () => {
    expect(fillParams({ text: "Pay {{param:amount}} now", n: 1 }, { amount: "42" })).toEqual({ text: "Pay 42 now", n: 1 });
    expect(() => fillParams({ t: "{{param:x}}" }, {})).toThrow(/needs x/);
    expect(findRef(SNAP, { role: "button", name: "Submit expense" })).toBe("e7");
    expect(findRef(SNAP, { role: "link", name: "Submit" })).toBe("e9");
    expect(findRef(SNAP, { name: "Delete" })).toBeNull();
  });

  it("refuses undeclared parameters and passwords typed in clear text", () => {
    expect(() => checkReplaySteps([{ tool: "browser.fill", args: { text: "{{param:who}}" } }], [])).toThrow(/isn't declared/);
    expect(() => checkReplaySteps([{ tool: "browser.fill", args: { text: "hunter2" }, target: { name: "Password" } }], [])).toThrow(/clear text/);
    expect(() => checkReplaySteps([{ tool: "browser.fill", args: { text: "{{secret:PORTAL_PASSWORD}}" }, target: { name: "Password" } }], [])).not.toThrow();
  });

  it("turns a teach recording into steps with parameters and secrets", () => {
    const r = replayFromTeach([
      { seq: 1, kind: "click", x: 10, y: 20, button: 1, text: null, key: null, secret_name: null, url: "https://portal.example.com/new" },
      { seq: 2, kind: "type", x: null, y: null, button: null, text: "42.50", key: null, secret_name: null, url: null },
      { seq: 3, kind: "type", x: null, y: null, button: null, text: null, key: null, secret_name: "PASSWORD", url: "https://portal.example.com/login" },
      { seq: 4, kind: "key", x: null, y: null, button: null, text: null, key: "Enter", url: null, secret_name: null },
    ]);
    expect(r.params).toEqual([{ name: "text_1", default: "42.50", description: "Typed at step 2" }]);
    expect(r.steps.map((s) => [s.tool, s.args])).toEqual([
      ["desktop.click", { x: 10, y: 20 }],
      ["desktop.type", { text: "{{param:text_1}}" }],
      ["desktop.type", { text: "{{secret:PASSWORD}}" }],
      ["desktop.press", { keys: "Enter" }],
    ]);
    expect(r.steps[0]?.check).toEqual({ url_contains: "portal.example.com/new" });
    expect(r.steps[2]?.host).toBe("portal.example.com");
  });

  it("runs steps without a model, resolves refs, and stops at a missing element", async () => {
    const calls: string[] = [];
    const reg = new ToolRegistry();
    for (const name of ["browser.open", "browser.click", "browser.fill"])
      reg.register({
        name,
        description: name,
        risk: "low",
        schema: z.object({ url: z.string().optional(), ref: z.string().optional(), text: z.string().optional() }),
        async execute(args) {
          calls.push(`${name} ${JSON.stringify(args)}`);
          return { content: "ok" };
        },
      });
    let url = "https://portal.example.com/expenses";
    const ctx = {
      runId: "r",
      botId: "b",
      orgId: "o",
      output: async () => {},
      emit: async () => {},
      computer: async () => ({
        async *exec(cmd: string) {
          yield { type: "stdout" as const, data: cmd.includes("get url") ? url : SNAP };
          yield { type: "exit" as const, code: 0, timedOut: false, killed: false, truncated: false };
        },
      }),
    } as never;
    const db = { execute: async () => [] } as never;
    const replay = {
      name: "file-expense",
      params: [{ name: "amount" }],
      steps: [
        { tool: "browser.open", args: { url: "https://portal.example.com/expenses" }, check: { url_contains: "/expenses" } },
        { tool: "browser.fill", args: { text: "{{param:amount}}" }, target: { role: "textbox", name: "Amount" } },
        { tool: "browser.click", args: {}, target: { role: "button", name: "Submit expense" }, check: { text_contains: "Expenses" } },
      ],
    };
    const ok = await executeReplay({ db, registry: () => reg }, replay, { amount: "42" }, ctx);
    expect(ok).toMatchObject({ ok: true, done: 3, total: 3 });
    expect(calls).toEqual(['browser.open {"url":"https://portal.example.com/expenses"}', 'browser.fill {"ref":"e3","text":"42"}', 'browser.click {"ref":"e7"}']);

    url = "https://portal.example.com/login";
    const stopped = await executeReplay({ db, registry: () => reg }, replay, { amount: "42" }, ctx);
    expect(stopped).toMatchObject({ ok: false, stoppedAt: 1, done: 0 });
    expect(describeOutcome("file-expense", stopped)).toMatch(new RegExp(`^${REPLAY_STOPPED}: replay "file-expense" stopped at step 1 of 3: expected the address to contain "/expenses"`));
    const missing = await executeReplay({ db, registry: () => reg }, { ...replay, steps: [{ tool: "browser.click", args: {}, target: { name: "Approve" } }] }, { amount: "1" }, ctx);
    expect(missing.reason).toBe('couldn\'t find element "Approve" on the screen');
  });
});
