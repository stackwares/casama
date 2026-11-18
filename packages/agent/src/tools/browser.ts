/**
 * Browser tools (D-323 Phase 3, plan §9.5). One set of tools, two backends:
 *
 *   browser.* tool ─> BrowserBackend ─┬─ computer: agent-browser on the bot's computer
 *                                      └─ mine: the person's own Chrome, through the device tunnel
 *
 * Both give the same snapshot format and `@e1` refs, so skills and replays work on either. Which one a
 * run uses: the person's browser when the conversation started in it, a routine asks for it, or the
 * bot says `where: "mine"`, and the browser is online with this bot allowed; otherwise the bot's own
 * computer. A run keeps the browser it started with, since refs only mean something in one browser.
 */
import { type BrowserAction, type BrowserResult, EXTRACT_TABLES_JS } from "@casama/contracts";
import { browsable, CASAMA_DOMAINS, isCasamaAddress } from "@casama/domain";
import { collectExec, type SandboxHandle } from "@casama/sandbox";
import { z } from "zod";
import { wrapUntrusted } from "../context.ts";
import { type ToolContext, ToolError, type ToolRegistry, toolImage } from "./registry.ts";

/** The person's browser, as a run reaches it. */
export interface UserBrowser {
  deviceId: string;
  call(action: BrowserAction, args: Record<string, unknown>): Promise<BrowserResult>;
}

/** What a run knows about browsers (set by the worker). */
export interface BrowserChoice {
  /** The person's browser when it's online and lets this bot in; null otherwise. */
  mine(): Promise<UserBrowser | null>;
  /** Waits up to [ms] for the person's browser to come online (routines that need it). */
  waitMine(ms: number): Promise<UserBrowser | null>;
  /**
   * The run's default: "mine" (a routine that must use the person's browser), "mine_or_computer"
   * (the conversation started in the browser, or a routine that prefers it) or "computer".
   */
  preferred: "mine" | "mine_or_computer" | "computer";
  /** The browser this run settled on. */
  picked: "mine" | "computer" | null;
  pick(where: "mine" | "computer"): void;
  /** This server's own addresses (API, web app, sign-in), never opened by a bot. */
  ownUrls: string[];
  /** Keeps a file in the Library (downloads); null when this server has no Library storage. */
  keep?: (
    name: string,
    bytes: Uint8Array,
  ) => Promise<{ creation_id: string; title: string } | null>;
  /** A Library file's bytes (uploads). */
  libraryFile?: (creationId: string) => Promise<{ name: string; mime: string; bytes: Uint8Array }>;
}

/** How long a routine that needs the person's browser waits for it to come online. */
export const WAIT_FOR_BROWSER_MS = 30 * 60 * 1000;
/** Largest file a bot moves through the person's browser (downloads and uploads). */
export const BROWSER_FILE_MAX = 20 * 1024 * 1024;

/** Single-quotes a value for bash. */
const shq = (s: string) => `'${s.replaceAll("'", `'\\''`)}'`;

type Out = {
  text: string;
  image?: { data: string; media_type: string };
  url?: string;
  file?: { name: string; media_type: string; data: string };
};

/** One backend's way of doing each action. */
interface Backend {
  kind: "mine" | "computer";
  run(action: BrowserAction, args: Record<string, unknown>): Promise<Out>;
}

const OFFLINE =
  "Your browser isn't available: Casama for Chrome is closed, offline, or doesn't let this bot in (Device connections). Ask the person to open Chrome, or use the bot's own computer (where: \"computer\").";

function mineBackend(b: UserBrowser): Backend {
  return {
    kind: "mine",
    async run(action, args) {
      const r = await b.call(action, args);
      if (!r.ok) {
        // A step the person finishes themselves (purchases, password changes, a hand-off rule).
        if (r.code === "handed_off") throw new ToolError("handed_off", r.message);
        if (r.code === "offline") throw new ToolError("browser_offline", OFFLINE);
        throw new ToolError(r.code === "asked_denied" ? "denied" : "browser_error", r.message);
      }
      return { text: r.text, image: r.image, url: r.url, file: r.file };
    },
  };
}

function computerBackend(ctx: ToolContext): Backend {
  const need = async (): Promise<SandboxHandle> => {
    if (!ctx.computer) throw new ToolError("no_computer", "This bot has no computer available.");
    return ctx.computer();
  };
  const ab = async (args: string, timeoutMs = 90_000) => {
    const h = await need();
    const r = await collectExec(h.exec(`agent-browser ${args}`, { timeoutMs }));
    const out = `${r.stdout}${r.stderr ? `\n${r.stderr}` : ""}`.trim();
    if (r.code !== 0)
      throw new ToolError(
        "browser_error",
        out.slice(0, 2000) || `agent-browser exited with ${r.code}`,
      );
    return out;
  };
  const ref = (r: unknown) => {
    const s = String(r ?? "");
    return s.startsWith("@") ? s : `@${s}`;
  };
  return {
    kind: "computer",
    async run(action, a) {
      switch (action) {
        case "open":
          return { text: (await ab(`open ${shq(String(a.url))}`)) || `Opened ${a.url}` };
        case "snapshot":
          return { text: await ab(`snapshot${a.interactive_only === false ? "" : " -i"}`) };
        case "read":
          return { text: await ab("read") };
        case "click":
          return { text: (await ab(`click ${ref(a.ref)}`)) || `Clicked ${ref(a.ref)}` };
        case "fill":
          return {
            text: (await ab(`fill ${ref(a.ref)} ${shq(String(a.text))}`)) || `Filled ${ref(a.ref)}`,
          };
        case "type":
          return { text: (await ab(`keyboard type ${shq(String(a.text))}`)) || "Typed" };
        case "press":
          return { text: (await ab(`press ${shq(String(a.key))}`)) || `Pressed ${a.key}` };
        case "scroll":
          return {
            text:
              (await ab(`scroll ${a.direction}${a.amount ? ` ${a.amount}` : ""}`)) || "Scrolled",
          };
        case "url":
          return { text: await ab("get url", 20_000) };
        case "tabs":
          return { text: (await ab("tab")) || "No tabs" };
        case "switch_tab":
          return {
            text: a.url
              ? (await ab(`tab new ${shq(String(a.url))}`)) || `Opened ${a.url} in a new tab`
              : (await ab(`tab ${shq(String(a.tab))}`)) || `Switched to ${a.tab}`,
          };
        case "wait":
          return {
            text:
              (await ab(
                a.text
                  ? `wait --text ${shq(String(a.text))}`
                  : `wait ${Math.min(Number(a.ms ?? 1000), 30_000)}`,
                60_000,
              )) || "Done waiting",
          };
        case "dialog":
          return {
            text:
              (await ab(
                a.accept === false
                  ? "dialog dismiss"
                  : `dialog accept${a.text ? ` ${shq(String(a.text))}` : ""}`,
              )) || "Answered the dialog",
          };
        case "console":
          return {
            text: `Console:\n${(await ab("console")) || "(empty)"}\n\nErrors:\n${(await ab("errors")) || "(none)"}`,
          };
        case "network":
          return {
            text:
              (await ab(
                `network requests${a.filter ? ` --filter ${shq(String(a.filter))}` : ""}`,
              )) || "No requests recorded",
          };
        case "extract":
          return {
            text: await ab(`eval -b ${Buffer.from(EXTRACT_TABLES_JS).toString("base64")}`),
          };
        case "upload": {
          if (typeof a.path !== "string")
            throw new ToolError(
              "bad_arguments",
              "On the bot's computer, upload takes a file path on that computer.",
            );
          return {
            text: (await ab(`upload ${ref(a.ref)} ${shq(a.path)}`)) || `Uploaded ${a.path}`,
          };
        }
        case "download": {
          if (typeof a.url !== "string")
            throw new ToolError(
              "bad_arguments",
              "On the bot's computer, download takes the file's address (url).",
            );
          const h = await need();
          const name =
            decodeURIComponent(new URL(a.url).pathname.split("/").pop() || "download").replace(
              /[^\w.-]/g,
              "_",
            ) || "download";
          const path = `/home/casama/workspace/Downloads/${name}`;
          const r = await collectExec(
            h.exec(
              `mkdir -p /home/casama/workspace/Downloads && curl -fsSL --max-filesize ${BROWSER_FILE_MAX} -o ${shq(path)} ${shq(a.url)}`,
              { timeoutMs: 120_000 },
            ),
          );
          if (r.code !== 0)
            throw new ToolError(
              "download_failed",
              r.stderr.slice(0, 500) || "The download failed.",
            );
          return { text: `Downloaded to ~/workspace/Downloads/${name}.` };
        }
        case "screenshot":
        case "page_text":
        case "stop":
          throw new ToolError("unsupported", `${action} is handled by the tool itself.`);
      }
    },
  };
}

/** Picks the backend for one call; remembers it for the rest of the run. */
export async function backendFor(ctx: ToolContext, where?: "mine" | "computer"): Promise<Backend> {
  const b = ctx.browser;
  const computer = () => {
    b?.pick("computer");
    return computerBackend(ctx);
  };
  if (!b) {
    if (where === "mine") throw new ToolError("browser_offline", OFFLINE);
    return computerBackend(ctx);
  }
  const want = where ?? b.picked;
  if (want === "computer") return computer();
  if (want === "mine") {
    const m = await b.mine();
    if (!m) throw new ToolError("browser_offline", OFFLINE);
    b.pick("mine");
    return mineBackend(m);
  }
  if (b.preferred === "mine") {
    const m = (await b.mine()) ?? (await b.waitMine(WAIT_FOR_BROWSER_MS));
    if (!m) throw new ToolError("browser_offline", OFFLINE);
    b.pick("mine");
    return mineBackend(m);
  }
  if (b.preferred === "mine_or_computer" || !ctx.computer) {
    const m = await b.mine();
    if (m) {
      b.pick("mine");
      return mineBackend(m);
    }
  }
  return computer();
}

/** Refuses pages a bot must never open: browser pages, the store, Casama's own addresses. */
/**
 * Casama's own pages are refused in both browsers. The person's browser opens only web pages; the
 * bot's own computer may still open its local files (file://), as before.
 */
function checkUrl(url: string, ctx: ToolContext, kind: Backend["kind"]) {
  if (kind === "mine" && !browsable(url))
    throw new ToolError(
      "refused",
      "Only web pages (http and https) can be opened in the person's browser.",
    );
  if (isCasamaAddress(url, ctx.browser?.ownUrls ?? []))
    throw new ToolError(
      "refused",
      `Casama's own pages (${CASAMA_DOMAINS.join(", ")} and this server) can't be opened by a bot.`,
    );
}

const Where = z
  .enum(["mine", "computer"])
  .optional()
  .describe(
    'Which browser: "mine" is the person\'s own Chrome (signed in to their sites), "computer" your own computer\'s. Leave it out to keep using the one this conversation uses.',
  );
const Ref = z.string().regex(/^@?e\d+$/);

const web = (out: string, preview: string) => ({ content: wrapUntrusted("web", out), preview });

export function registerBrowserTools(registry: ToolRegistry) {
  const requires = { computer: true };
  const act = async (
    ctx: ToolContext,
    where: "mine" | "computer" | undefined,
    action: BrowserAction,
    args: Record<string, unknown>,
  ) => (await backendFor(ctx, where)).run(action, args);

  registry.register({
    name: "browser.open",
    screen: true,
    untrustedOutput: true,
    description:
      'Open a URL in a browser. Then use browser.snapshot to see interactive elements with refs like @e1. In the person\'s own browser (where: "mine") you work in your own tab group, already signed in to their sites.',
    risk: "low",
    requires,
    schema: z.object({ url: z.string().min(1).max(4000), where: Where }),
    async execute(args, ctx) {
      const be = await backendFor(ctx, args.where);
      checkUrl(args.url, ctx, be.kind);
      const out = await be.run("open", { url: args.url });
      // A redirect may land on one of Casama's own pages: leave it at once.
      if (be.kind === "computer") {
        const at = (await be.run("url", {}).catch(() => ({ text: "" }))).text.trim();
        if (at && isCasamaAddress(at, ctx.browser?.ownUrls ?? [])) {
          await be.run("open", { url: "about:blank" }).catch(() => {});
          throw new ToolError(
            "refused",
            "That page led to Casama's own pages, which a bot can't use.",
          );
        }
      }
      return web(out.text || `Opened ${args.url}`, `opened ${args.url.slice(0, 100)}`);
    },
  });

  registry.register({
    name: "browser.snapshot",
    screen: true,
    untrustedOutput: true,
    readOnly: true,
    description:
      "Accessibility snapshot of the current page. Interactive elements get refs (@e1, @e2) to use with click and fill.",
    risk: "low",
    requires,
    schema: z.object({ interactive_only: z.boolean().optional(), where: Where }),
    async execute(args, ctx) {
      const out = await act(ctx, args.where, "snapshot", {
        interactive_only: args.interactive_only,
      });
      return web(out.text, `${out.text.split("\n").length} lines`);
    },
  });

  registry.register({
    name: "browser.read",
    screen: true,
    untrustedOutput: true,
    readOnly: true,
    description: "Read the current page's main text content.",
    risk: "low",
    requires,
    schema: z.object({ where: Where }),
    async execute(args, ctx) {
      const out = await act(ctx, args.where, "read", {});
      return web(out.text, `${out.text.length} characters`);
    },
  });

  registry.register({
    name: "browser.click",
    screen: true,
    untrustedOutput: true,
    description:
      "Click an element by its ref from the last snapshot (for example @e3). In the person's browser, buttons that send, buy, delete, publish, share or sign in ask the person first; purchases and password changes are handed to them.",
    risk: "low",
    requires,
    schema: z.object({ ref: Ref, where: Where }),
    async execute(args, ctx) {
      const ref = args.ref.startsWith("@") ? args.ref : `@${args.ref}`;
      return web(
        (await act(ctx, args.where, "click", { ref })).text || `Clicked ${ref}`,
        `clicked ${ref}`,
      );
    },
  });

  registry.register({
    name: "browser.fill",
    screen: true,
    untrustedOutput: true,
    description: "Clear a form field by ref and type text into it.",
    risk: "low",
    requires,
    acceptsSecrets: true,
    // Secrets may only be typed into pages on the secret's allowed hosts.
    destinationHost: async (args: { where?: "mine" | "computer" }, ctx: ToolContext) => {
      try {
        const be = await backendFor(ctx, args.where);
        return new URL((await be.run("url", {})).text.trim()).hostname;
      } catch {
        return null;
      }
    },
    schema: z.object({ ref: Ref, text: z.string().max(20_000), where: Where }),
    async execute(args, ctx) {
      const ref = args.ref.startsWith("@") ? args.ref : `@${args.ref}`;
      return web(
        (await act(ctx, args.where, "fill", { ref, text: args.text })).text || `Filled ${ref}`,
        `filled ${ref}`,
      );
    },
  });

  registry.register({
    name: "browser.type",
    screen: true,
    untrustedOutput: true,
    description: "Type text into the focused element.",
    risk: "low",
    requires,
    schema: z.object({ text: z.string().max(20_000), where: Where }),
    async execute(args, ctx) {
      return web(
        (await act(ctx, args.where, "type", { text: args.text })).text || "Typed",
        "typed",
      );
    },
  });

  registry.register({
    name: "browser.press",
    screen: true,
    untrustedOutput: true,
    description: "Press a key, for example Enter, Tab, Escape or Control+a.",
    risk: "low",
    requires,
    schema: z.object({ key: z.string().min(1).max(50), where: Where }),
    async execute(args, ctx) {
      return web(
        (await act(ctx, args.where, "press", { key: args.key })).text || `Pressed ${args.key}`,
        `pressed ${args.key}`,
      );
    },
  });

  registry.register({
    name: "browser.scroll",
    screen: true,
    untrustedOutput: true,
    description: "Scroll the page up or down.",
    risk: "low",
    requires,
    schema: z.object({
      direction: z.enum(["up", "down"]),
      amount: z.number().int().min(1).max(10_000).optional(),
      where: Where,
    }),
    async execute(args, ctx) {
      return web(
        (await act(ctx, args.where, "scroll", { direction: args.direction, amount: args.amount }))
          .text || "Scrolled",
        `scrolled ${args.direction}`,
      );
    },
  });

  registry.register({
    name: "browser.screenshot",
    screen: true,
    description:
      "Take a screenshot of the current page, attached so you can see it when your model reads images. On your computer it's also saved to a file.",
    risk: "low",
    requires,
    schema: z.object({ path: z.string().max(500).optional(), where: Where }),
    async execute(args, ctx) {
      const be = await backendFor(ctx, args.where);
      if (be.kind === "mine") {
        const out = await be.run("screenshot", {});
        const image = out.image
          ? toolImage(Buffer.from(out.image.data, "base64"), out.image.media_type)
          : undefined;
        return {
          content: `Took a screenshot of the person's tab.${image ? " It's attached so you can see it." : ""}`,
          preview: "screenshot of your tab",
          ...(image ? { image } : {}),
        };
      }
      const asked =
        args.path ?? `screenshots/${new Date().toISOString().replace(/[:.]/g, "-")}.png`;
      // On a team computer relative paths are in the bot's folder (D-148).
      if (!ctx.computer) throw new ToolError("no_computer", "This bot has no computer available.");
      const h = await ctx.computer();
      const path = h.resolvePath?.(asked) ?? asked;
      const full = path.startsWith("/") ? path : `/home/casama/workspace/${path}`;
      // agent-browser doesn't create folders, and the bot's screenshots folder may not exist yet.
      await collectExec(
        h.exec(`mkdir -p ${shq(full.slice(0, full.lastIndexOf("/")) || "/")}`, {
          timeoutMs: 10_000,
        }),
      );
      const r = await collectExec(
        h.exec(`agent-browser screenshot ${shq(full)}`, { timeoutMs: 90_000 }),
      );
      if (r.code !== 0)
        throw new ToolError(
          "browser_error",
          (r.stdout + r.stderr).slice(0, 2000) || "screenshot failed",
        );
      const image = toolImage(await h.readFile(full).catch(() => new Uint8Array()), "image/png");
      return {
        content: `Saved screenshot to ${path}.${image ? " It's attached so you can see it." : ""}`,
        preview: `saved ${path}`,
        artifactPath: path,
        ...(image ? { image } : {}),
      };
    },
  });

  // --- New in Phase 3: tabs, waiting, files, dialogs, developer views, tables ---

  registry.register({
    name: "browser.tabs",
    screen: true,
    readOnly: true,
    untrustedOutput: true,
    description:
      "List the browser's tabs you can use (in the person's browser: only the tabs in your own tab group).",
    risk: "low",
    requires,
    schema: z.object({ where: Where }),
    async execute(args, ctx) {
      const out = await act(ctx, args.where, "tabs", {});
      return web(out.text, `${out.text.split("\n").filter(Boolean).length} tabs`);
    },
  });

  registry.register({
    name: "browser.switch_tab",
    screen: true,
    untrustedOutput: true,
    description:
      "Switch to one of your tabs (an id from browser.tabs), or open an address in a new tab (url).",
    risk: "low",
    requires,
    schema: z
      .object({
        tab: z.string().max(40).optional(),
        url: z.string().max(4000).optional(),
        where: Where,
      })
      .refine((a) => !!a.tab !== !!a.url, "Give a tab or a url"),
    async execute(args, ctx) {
      const be = await backendFor(ctx, args.where);
      if (args.url) checkUrl(args.url, ctx, be.kind);
      const out = await be.run("switch_tab", { tab: args.tab, url: args.url });
      return web(out.text, args.url ? `new tab ${args.url.slice(0, 80)}` : `tab ${args.tab}`);
    },
  });

  registry.register({
    name: "browser.wait",
    screen: true,
    readOnly: true,
    description:
      "Wait for some text to appear on the page, or for a number of milliseconds (at most 30 s).",
    risk: "low",
    requires,
    schema: z.object({
      text: z.string().min(1).max(200).optional(),
      ms: z.number().int().min(100).max(30_000).optional(),
      where: Where,
    }),
    async execute(args, ctx) {
      const out = await act(ctx, args.where, "wait", { text: args.text, ms: args.ms });
      return {
        content: out.text || "Done waiting",
        preview: args.text ? `waited for "${args.text}"` : "waited",
      };
    },
  });

  registry.register({
    name: "browser.dialog",
    screen: true,
    description:
      "Answer a page's pop-up dialog (alert, confirm or prompt): accept (with text for a prompt) or dismiss.",
    risk: "low",
    requires,
    schema: z.object({ accept: z.boolean(), text: z.string().max(2000).optional(), where: Where }),
    async execute(args, ctx) {
      const out = await act(ctx, args.where, "dialog", { accept: args.accept, text: args.text });
      return {
        content: out.text || "Answered",
        preview: args.accept ? "accepted dialog" : "dismissed dialog",
      };
    },
  });

  registry.register({
    name: "browser.console",
    screen: true,
    readOnly: true,
    untrustedOutput: true,
    description: "For developers: the page's console messages and errors, to debug a site.",
    risk: "low",
    requires,
    schema: z.object({ where: Where }),
    async execute(args, ctx) {
      const out = await act(ctx, args.where, "console", {});
      return web(out.text, "console");
    },
  });

  registry.register({
    name: "browser.network",
    screen: true,
    readOnly: true,
    untrustedOutput: true,
    description:
      "For developers: the page's recent network requests (method, status, address), optionally filtered by text in the address.",
    risk: "low",
    requires,
    schema: z.object({ filter: z.string().max(200).optional(), where: Where }),
    async execute(args, ctx) {
      const out = await act(ctx, args.where, "network", { filter: args.filter });
      return web(out.text, "network requests");
    },
  });

  registry.register({
    name: "browser.extract",
    screen: true,
    readOnly: true,
    untrustedOutput: true,
    description:
      "Get the data out: the visible tables (or lists) on the page as CSV, to save to a file, a sheet or the Library.",
    risk: "low",
    requires,
    schema: z.object({ where: Where }),
    async execute(args, ctx) {
      const out = await act(ctx, args.where, "extract", {});
      return web(out.text, `${out.text.split("\n").length} lines of data`);
    },
  });

  registry.register({
    name: "browser.upload",
    screen: true,
    description:
      "Put a file into a page's upload field (by ref): a file on your computer (path) or a Library file (creation_id).",
    risk: "low",
    requires,
    schema: z
      .object({
        ref: Ref,
        path: z.string().min(1).max(1000).optional(),
        creation_id: z.uuid().optional(),
        where: Where,
      })
      .refine((a) => !!a.path !== !!a.creation_id, "Give a path or a creation_id"),
    async execute(args, ctx) {
      const be = await backendFor(ctx, args.where);
      const ref = args.ref.startsWith("@") ? args.ref : `@${args.ref}`;
      if (be.kind === "computer") {
        if (!args.path)
          throw new ToolError("bad_arguments", "On your computer, upload a file by its path.");
        return {
          content: (await be.run("upload", { ref, path: args.path })).text,
          preview: `uploaded ${args.path}`,
        };
      }
      // The person's browser: the file's bytes go with the call.
      let file: { name: string; mime: string; bytes: Uint8Array };
      if (args.creation_id) {
        if (!ctx.browser?.libraryFile)
          throw new ToolError("no_library", "Library files can't be read on this server.");
        file = await ctx.browser.libraryFile(args.creation_id);
      } else {
        if (!ctx.computer)
          throw new ToolError("no_computer", "This bot has no computer for that file.");
        const bytes = await (await ctx.computer()).readFile(args.path as string);
        const name = (args.path as string).split("/").pop() ?? "file";
        file = { name, mime: "application/octet-stream", bytes };
      }
      if (file.bytes.length > BROWSER_FILE_MAX)
        throw new ToolError(
          "too_big",
          "Files over 20 MB can't be uploaded through the person's browser.",
        );
      const out = await be.run("upload", {
        ref,
        file: {
          name: file.name,
          media_type: file.mime,
          data: Buffer.from(file.bytes).toString("base64"),
        },
      });
      return {
        content: out.text || `Put ${file.name} in the upload field.`,
        preview: `uploaded ${file.name}`,
      };
    },
  });

  registry.register({
    name: "browser.download",
    screen: true,
    description:
      "Download a file: by its address (url) or a link's ref. From the person's browser it uses their sign-in and goes to the Library (or your computer's Downloads folder with save_to: \"computer\").",
    risk: "low",
    requires,
    schema: z
      .object({
        url: z.string().max(4000).optional(),
        ref: Ref.optional(),
        save_to: z.enum(["library", "computer"]).optional(),
        where: Where,
      })
      .refine((a) => !!a.url || !!a.ref, "Give a url or a ref"),
    async execute(args, ctx) {
      const be = await backendFor(ctx, args.where);
      if (args.url) checkUrl(args.url, ctx, be.kind);
      if (be.kind === "computer") {
        const out = await be.run("download", { url: args.url, ref: args.ref });
        return { content: out.text, preview: "downloaded" };
      }
      const out = await be.run("download", { url: args.url, ref: args.ref });
      if (!out.file) throw new ToolError("download_failed", out.text || "Nothing was downloaded.");
      const bytes = Buffer.from(out.file.data, "base64");
      const name = out.file.name.replace(/[^\w.-]/g, "_") || "download";
      if (args.save_to === "computer" || !ctx.browser?.keep) {
        if (!ctx.computer)
          throw new ToolError("no_computer", "This bot has nowhere to keep the file.");
        const h = await ctx.computer();
        await h.writeFile(`Downloads/${name}`, bytes);
        return {
          content: `Downloaded ${name} (${bytes.length} bytes) to Downloads/${name} on your computer.`,
          preview: `downloaded ${name}`,
          artifactPath: h.resolvePath?.(`Downloads/${name}`) ?? `Downloads/${name}`,
        };
      }
      const kept = await ctx.browser.keep(name, bytes);
      if (!kept)
        throw new ToolError("download_failed", "The file couldn't be kept (empty or too big).");
      return {
        content: `Downloaded ${name} (${bytes.length} bytes) into the Library as "${kept.title}" (creation ${kept.creation_id}).`,
        preview: `downloaded ${name} to the Library`,
      };
    },
  });
}
