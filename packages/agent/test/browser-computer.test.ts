import { describe, expect, it } from "vitest";
import { CLOSE_PLAIN_BROWSER, plainBrowserCommand } from "../src/run.ts";
import { registerBrowserTools } from "../src/tools/browser.ts";
import { ToolRegistry } from "../src/tools/registry.ts";

/** A computer whose agent-browser answers each command with the next scripted result. */
function computerWith(results: Array<{ code: number; out: string }>) {
  const ran: string[] = [];
  const ctx = {
    runId: "r",
    botId: "b",
    orgId: "o",
    output: async () => {},
    emit: async () => {},
    computer: async () => ({
      async *exec(cmd: string) {
        ran.push(cmd);
        const r = results.shift() ?? { code: 0, out: "" };
        yield { type: r.code === 0 ? ("stdout" as const) : ("stderr" as const), data: r.out };
        yield {
          type: "exit" as const,
          code: r.code,
          timedOut: false,
          killed: false,
          truncated: false,
        };
      },
    }),
  } as never;
  const reg = new ToolRegistry();
  registerBrowserTools(reg);
  const open = (url: string) =>
    (reg.get("browser.open") as { execute: (a: unknown, c: unknown) => Promise<unknown> }).execute(
      { url },
      ctx,
    );
  return { ran, open };
}

const NO_ANSWER =
  "✗ Failed to read: Resource temporarily unavailable (os error 11) (the command reached the daemon but no response came back)";

describe("browser on the bot's computer", () => {
  it("tries an open once more when the browser daemon doesn't answer after a wake", async () => {
    const c = computerWith([
      { code: 1, out: NO_ANSWER },
      { code: 0, out: "✓ Example" },
    ]);
    await c.open("https://example.com");
    expect(c.ran.filter((r) => r.startsWith("agent-browser open"))).toHaveLength(2);
  });

  it("still fails after a second unanswered try", async () => {
    const c = computerWith([
      { code: 1, out: NO_ANSWER },
      { code: 1, out: NO_ANSWER },
    ]);
    await expect(c.open("https://example.com")).rejects.toThrow(/os error 11/);
  });

  it("treats a page that never finished loading as open", async () => {
    const c = computerWith([
      { code: 1, out: "✗ Timed out after 25000ms waiting for load state 'load'" },
    ]);
    const out = JSON.stringify(await c.open("https://accounts.google.com"));
    expect(out).toContain("still loading");
  });

  it("doesn't repeat a command that failed for another reason", async () => {
    const c = computerWith([{ code: 1, out: "✗ net::ERR_NAME_NOT_RESOLVED" }]);
    await expect(c.open("https://nowhere.invalid")).rejects.toThrow(/ERR_NAME_NOT_RESOLVED/);
    expect(c.ran.filter((r) => r.startsWith("agent-browser open"))).toHaveLength(1);
  });
});

describe("takeover browser", () => {
  it("opens the page in the plain desktop browser after closing the bot's own", () => {
    const cmd = plainBrowserCommand("https://accounts.google.com/?q=it's");
    expect(cmd.indexOf("agent-browser close")).toBeLessThan(cmd.indexOf("casama-open-browser"));
    expect(cmd).toContain("setsid -f casama-open-browser --class=casama-takeover");
    expect(cmd).toContain("'https://accounts.google.com/?q=it'\\''s'");
    expect(cmd).not.toContain("agent-browser open");
  });

  it("closes only that browser on hand-back, not the shell running the command", () => {
    expect(CLOSE_PLAIN_BROWSER).toContain('pkill -TERM -f -- "--class=[c]asama-takeover"');
  });
});
