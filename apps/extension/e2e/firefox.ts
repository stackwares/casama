/**
 * Casama for Firefox in Playwright's Firefox (D-323 Phase 5).
 *
 * Playwright can neither load an extension into Firefox nor open its moz-extension:// pages, so
 * this goes through Firefox's own remote debugging protocol, the one `web-ext run` and about:debugging
 * use: the browser starts with its debugging server on, the built add-on (dist/firefox-e2e) goes in
 * as a temporary add-on, and the tests run code in the add-on's background page. The options page
 * and the panel load there in frames of the add-on's own origin, so a test reads and clicks them as
 * the person would, and sees the same pages Firefox shows.
 *
 * Clicks made this way aren't the person's own, so anything that needs Firefox's permission prompt
 * stays out of these tests (the e2e build has its permissions already).
 */
import { existsSync, mkdtempSync, rmSync } from "node:fs";
import { createServer, type Socket, connect as tcp } from "node:net";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { type BrowserContext, firefox } from "@playwright/test";
import { GECKO_ID } from "../src/manifest.ts";

export const FIREFOX_BUILD = resolve(import.meta.dirname, "../dist/firefox-e2e");

export function firefoxBuilt(): boolean {
  return existsSync(join(FIREFOX_BUILD, "manifest.json"));
}

/** A free port for the debugging server. */
function freePort(): Promise<number> {
  return new Promise((ok, fail) => {
    const s = createServer();
    s.listen(0, "127.0.0.1", () => {
      const port = (s.address() as { port: number }).port;
      s.close(() => ok(port));
    });
    s.on("error", fail);
  });
}

type Packet = Record<string, unknown> & { from?: string; type?: string };

/** Firefox's remote debugging protocol: `<length>:<json>` packets, each from an actor. */
class Rdp {
  private buffer = Buffer.alloc(0);
  private packets: Packet[] = [];
  private wake: (() => void) | null = null;
  private readonly socket: Socket;
  constructor(socket: Socket) {
    this.socket = socket;
    socket.on("data", (chunk: Buffer) => {
      this.buffer = Buffer.concat([this.buffer, chunk]);
      for (;;) {
        const colon = this.buffer.indexOf(":");
        if (colon < 0) break;
        const length = Number(this.buffer.subarray(0, colon).toString());
        if (this.buffer.length < colon + 1 + length) break;
        this.packets.push(
          JSON.parse(this.buffer.subarray(colon + 1, colon + 1 + length).toString()),
        );
        this.buffer = this.buffer.subarray(colon + 1 + length);
      }
      this.wake?.();
    });
  }

  static async connect(port: number): Promise<Rdp> {
    const deadline = Date.now() + 15_000;
    for (;;) {
      const socket = await new Promise<Socket | null>((ok) => {
        const s = tcp(port, "127.0.0.1");
        s.once("connect", () => ok(s));
        s.once("error", () => {
          s.destroy();
          ok(null);
        });
      });
      if (socket) {
        const rdp = new Rdp(socket);
        await rdp.next((p) => p.from === "root"); // the greeting
        return rdp;
      }
      if (Date.now() > deadline) throw new Error(`Firefox's debugger never listened on ${port}`);
      await new Promise((r) => setTimeout(r, 250));
    }
  }

  send(packet: object) {
    const body = Buffer.from(JSON.stringify(packet));
    this.socket.write(`${body.length}:`);
    this.socket.write(body);
  }

  async next(match: (p: Packet) => boolean, timeoutMs = 30_000): Promise<Packet> {
    const deadline = Date.now() + timeoutMs;
    for (;;) {
      const i = this.packets.findIndex(match);
      if (i >= 0) return this.packets.splice(i, 1)[0]!;
      const left = deadline - Date.now();
      if (left <= 0) throw new Error("Firefox's debugger didn't answer in time");
      await new Promise<void>((ok) => {
        const timer = setTimeout(ok, Math.min(left, 1000));
        this.wake = () => {
          clearTimeout(timer);
          ok();
        };
      });
    }
  }

  /** Sends [packet] to [to] and returns its reply (not one of its events). */
  async request(to: string, packet: object): Promise<Packet> {
    this.send({ to, ...packet });
    const reply = await this.next(
      (p) => p.from === to && p.type !== "target-available-form" && p.type !== "evaluationResult",
    );
    if (reply.error) throw new Error(`${to}: ${reply.error} ${reply.message ?? ""}`);
    return reply;
  }

  close() {
    this.socket.destroy();
  }
}

/** The add-on, installed, with a way to run code in its background page. */
export class FirefoxAddon {
  private readonly rdp: Rdp;
  private readonly console: string;
  constructor(rdp: Rdp, consoleActor: string) {
    this.rdp = rdp;
    this.console = consoleActor;
  }

  /**
   * Runs [body] (an async function body that returns something JSON can carry) in the add-on's
   * background page and returns what it returned. A thrown error comes back as one here.
   */
  async run<T = unknown>(body: string, timeoutMs = 30_000): Promise<T> {
    const text = `(async () => { try { return JSON.stringify({ ok: await (async () => { ${body} })() }); } catch (e) { return JSON.stringify({ error: String((e && e.message) || e) }); } })()`;
    const ack = await this.rdp.request(this.console, {
      type: "evaluateJSAsync",
      text,
      mapped: { await: true },
    });
    const done = await this.rdp.next(
      (p) =>
        p.from === this.console && p.type === "evaluationResult" && p.resultID === ack.resultID,
      timeoutMs,
    );
    let result = done.result as string | { type?: string; actor?: string; length?: number };
    if (typeof result === "object" && result?.type === "longString") {
      const full = await this.rdp.request(result.actor!, {
        type: "substring",
        start: 0,
        end: result.length,
      });
      result = full.substring as string;
    }
    if (typeof result !== "string")
      throw new Error(`no result from the add-on: ${JSON.stringify(done).slice(0, 500)}`);
    const parsed = JSON.parse(result) as { ok?: T; error?: string };
    if (parsed.error !== undefined) throw new Error(parsed.error);
    return parsed.ok as T;
  }

  close() {
    this.rdp.close();
  }
}

/**
 * Helpers for the tests' code inside the add-on: `page(path)` loads one of its pages in a frame
 * and returns the frame's document; `el(doc, testId)` waits for an element; `none(doc, testId)`
 * says it isn't there; `text(doc, s)` waits for some text; `fill(input, value)` types into a field.
 */
export const IN_ADDON = `
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const until = async (what, fn, ms = 20000) => {
    const end = Date.now() + ms;
    for (;;) {
      const v = await fn();
      if (v) return v;
      if (Date.now() > end) throw new Error("waited too long for " + what);
      await sleep(100);
    }
  };
  const page = async (path) => {
    for (const old of document.querySelectorAll("iframe[data-casama-test]")) old.remove();
    const f = document.createElement("iframe");
    f.dataset.casamaTest = "1";
    f.style.width = "420px";
    f.style.height = "900px";
    f.src = "/" + path;
    document.body.append(f);
    await new Promise((r) => f.addEventListener("load", r, { once: true }));
    return f.contentDocument;
  };
  const el = (doc, id, ms) => until(id, () => doc.querySelector('[data-testid="' + id + '"]'), ms);
  const none = (doc, id) => !doc.querySelector('[data-testid="' + id + '"]');
  const text = (doc, s, ms) => until(s, () => doc.body.innerText.includes(s), ms);
  const fill = (input, value) => {
    input.focus();
    input.value = value;
    input.dispatchEvent(new Event("input", { bubbles: true }));
    input.dispatchEvent(new Event("change", { bubbles: true }));
  };
`;

/** A fresh Firefox profile with Casama for Firefox installed as a temporary add-on. */
export async function launchFirefoxWithCasama(): Promise<{
  context: BrowserContext;
  addon: FirefoxAddon;
  close: () => Promise<void>;
}> {
  const dir = mkdtempSync(join(tmpdir(), "casama-ff-"));
  const port = await freePort();
  const context = await firefox.launchPersistentContext(dir, {
    args: ["-start-debugger-server", String(port)],
    firefoxUserPrefs: {
      "devtools.debugger.remote-enabled": true,
      "devtools.debugger.prompt-connection": false,
    },
  });
  const rdp = await Rdp.connect(port).catch(async (e) => {
    await context.close();
    throw e;
  });
  try {
    const root = await rdp.request("root", { type: "getRoot" });
    const installed = await rdp.request(root.addonsActor as string, {
      type: "installTemporaryAddon",
      addonPath: FIREFOX_BUILD,
      openDevTools: false,
    });
    const id = (installed.addon as { id?: string } | undefined)?.id;
    if (id !== GECKO_ID) throw new Error(`installed ${id}, expected ${GECKO_ID}`);
    const list = await rdp.request("root", { type: "listAddons" });
    const descriptor = (list.addons as Array<{ id: string; actor: string }>).find(
      (a) => a.id === GECKO_ID,
    )!;
    const watcher = await rdp.request(descriptor.actor, { type: "getWatcher" });
    rdp.send({ to: watcher.actor, type: "watchTargets", targetType: "frame" });
    const target = await rdp.next(
      (p) =>
        p.from === watcher.actor &&
        p.type === "target-available-form" &&
        String((p.target as { url?: string })?.url).endsWith("/_generated_background_page.html"),
    );
    const addon = new FirefoxAddon(rdp, (target.target as { consoleActor: string }).consoleActor);
    return {
      context,
      addon,
      close: async () => {
        addon.close();
        await context.close();
        rmSync(dir, { recursive: true, force: true });
      },
    };
  } catch (e) {
    rdp.close();
    await context.close();
    throw e;
  }
}
