import { describe, expect, it } from "vitest";
import type { BrowserChoice, PhoneBrowser } from "../src/tools/browser.ts";
import { registerBrowserTools } from "../src/tools/browser.ts";
import { ToolRegistry } from "../src/tools/registry.ts";

type Reasons = PhoneBrowser["reasons"];
let seq = 0;

/** A run with a scripted computer browser and, maybe, the person's phone browser. */
function world(opts: {
  phone?: { reasons: Partial<Reasons>; sites?: string[] } | null;
  /** What the computer's `snapshot` returns. */
  page?: string;
  computerUrl?: string;
}) {
  const ran: string[] = [];
  const phoneCalls: string[] = [];
  const noted: unknown[] = [];
  let picked: BrowserChoice["picked"] = null;
  let phone = opts.phone ?? null;
  const browser: BrowserChoice = {
    preferred: "computer",
    get picked() {
      return picked;
    },
    pick(w) {
      picked = w;
    },
    ownUrls: [],
    mine: async () => null,
    waitMine: async () => null,
    phone: async () =>
      phone
        ? {
            deviceId: "d",
            sites: phone.sites ?? [],
            reasons: { asked: false, blocked: false, signed_in: false, ...phone.reasons },
            call: async (action) => {
              phoneCalls.push(action);
              return { ok: true, text: `${action} on the phone`, url: "https://shop.example/" };
            },
          }
        : null,
    noteComputer: async (b) => {
      noted.push(b ?? "run");
    },
  };
  const ctx = {
    runId: `run-${++seq}`,
    botId: "b",
    orgId: "o",
    output: async () => {},
    emit: async () => {},
    browser,
    computer: async () => ({
      async *exec(cmd: string) {
        ran.push(cmd);
        const out = cmd.includes(" snapshot")
          ? (opts.page ?? '- button "Go" [ref=e1]')
          : cmd.includes("get url")
            ? (opts.computerUrl ?? "https://shop.example/")
            : "ok";
        yield { type: "stdout" as const, data: out };
        yield { type: "exit" as const, code: 0, timedOut: false, killed: false, truncated: false };
      },
    }),
  } as never;
  const reg = new ToolRegistry();
  registerBrowserTools(reg);
  const tool = (name: string, args: Record<string, unknown>) =>
    (reg.get(name) as { execute: (a: unknown, c: unknown) => Promise<unknown> }).execute(args, ctx);
  return {
    ran,
    phoneCalls,
    noted,
    tool,
    picked: () => picked,
    phoneLeaves: () => {
      phone = null;
    },
  };
}

describe("the browser inside the person's phone app", () => {
  it("stays on the computer by default, and counts the run", async () => {
    const w = world({ phone: { reasons: { asked: true } } });
    await w.tool("browser.open", { url: "https://shop.example/" });
    expect(w.picked()).toBe("computer");
    expect(w.phoneCalls).toEqual([]);
    expect(w.noted).toEqual(["run"]);
  });

  it("is used when the bot names it, and the run then stays there", async () => {
    const w = world({ phone: { reasons: { asked: true } } });
    await w.tool("browser.open", { url: "https://shop.example/", where: "phone" });
    await w.tool("browser.snapshot", {});
    expect(w.picked()).toBe("phone");
    expect(w.phoneCalls).toEqual(["open", "snapshot"]);
    expect(w.ran).toEqual([]);
  });

  it("says so plainly when the phone isn't there, or leaves mid-task", async () => {
    const none = world({ phone: null });
    await expect(
      none.tool("browser.open", { url: "https://shop.example/", where: "phone" }),
    ).rejects.toMatchObject({ code: "browser_offline" });
    const w = world({ phone: { reasons: { asked: true } } });
    await w.tool("browser.open", { url: "https://shop.example/", where: "phone" });
    w.phoneLeaves();
    await expect(w.tool("browser.snapshot", {})).rejects.toThrow(
      /start again on your own computer/,
    );
    // Starting again on the computer works.
    await w.tool("browser.open", { url: "https://shop.example/", where: "computer" });
    expect(w.picked()).toBe("computer");
  });

  it("refuses the phone when no reason for it is switched on", async () => {
    const w = world({ phone: { reasons: {} } });
    await expect(
      w.tool("browser.open", { url: "https://shop.example/", where: "phone" }),
    ).rejects.toMatchObject({ code: "refused" });
    expect(w.phoneCalls).toEqual([]);
  });

  it("opens a site the person signed in to on the phone there, without being told", async () => {
    const w = world({ phone: { reasons: { signed_in: true }, sites: ["shop.example"] } });
    await w.tool("browser.open", { url: "https://www.shop.example/orders" });
    expect(w.picked()).toBe("phone");
    // Another site still goes to the computer.
    const other = world({ phone: { reasons: { signed_in: true }, sites: ["shop.example"] } });
    await other.tool("browser.open", { url: "https://news.example/" });
    expect(other.picked()).toBe("computer");
    // With the reason off, the list alone changes nothing.
    const off = world({ phone: { reasons: { asked: true }, sites: ["shop.example"] } });
    await off.tool("browser.open", { url: "https://shop.example/" });
    expect(off.picked()).toBe("computer");
  });

  it("notices a block on the computer, and offers the phone only when that reason is on", async () => {
    const block = "Just a moment...\nVerify you are human by completing the action below.";
    const w = world({ phone: { reasons: { blocked: true } }, page: block });
    await w.tool("browser.open", { url: "https://shop.example/" });
    // Before the block, "blocked" alone doesn't allow the phone.
    const early = world({ phone: { reasons: { blocked: true } }, page: block });
    await expect(
      early.tool("browser.open", { url: "https://shop.example/", where: "phone" }),
    ).rejects.toMatchObject({ code: "refused" });

    const out = JSON.stringify(await w.tool("browser.snapshot", {}));
    expect(out).toContain('where: \\"phone\\"');
    expect(w.noted).toContainEqual({
      host: "shop.example",
      block: { kind: "challenge", sign: "Just a moment..." },
    });
    await w.tool("browser.open", { url: "https://shop.example/", where: "phone" });
    expect(w.picked()).toBe("phone");

    // Counted either way, but not offered when the reason is off or the phone isn't there.
    const quiet = world({ phone: { reasons: { asked: true } }, page: block });
    await quiet.tool("browser.open", { url: "https://shop.example/" });
    expect(JSON.stringify(await quiet.tool("browser.snapshot", {}))).not.toContain("phone");
    expect(quiet.noted).toHaveLength(2);
    const alone = world({ phone: null, page: block });
    await alone.tool("browser.open", { url: "https://shop.example/" });
    expect(JSON.stringify(await alone.tool("browser.snapshot", {}))).not.toContain("phone");
  });
});
