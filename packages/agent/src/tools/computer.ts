import { collectExec, type SandboxHandle } from "@kasama/sandbox";
import { z } from "zod";
import { wrapUntrusted } from "../context.ts";
import { type ToolContext, ToolError, type ToolRegistry } from "./registry.ts";

/** Commands that destroy data get a checkpoint first. */
export const DESTRUCTIVE_PATTERNS: RegExp[] = [
  /\brm\s+(-[a-zA-Z]*[rf][a-zA-Z]*\s+)+/,
  /\bgit\s+(reset\s+--hard|clean\s+-[a-zA-Z]*f|checkout\s+--\s|push\s+.*--force)/,
  /\b(apt|apt-get)\s+(remove|purge|autoremove)\b/,
  /\b(npm|pnpm|yarn)\s+(uninstall|remove|rm)\b/,
  /\bpip3?\s+uninstall\b/,
  /\bdd\s+if=/,
  /\bmkfs\b/,
  /\btruncate\s+-s\s*0\b/,
  />\s*\/dev\/sd[a-z]/,
];

export const isDestructive = (cmd: string) => DESTRUCTIVE_PATTERNS.some((re) => re.test(cmd));

/** Single-quotes a value for bash. */
export const shq = (s: string) => `'${s.replaceAll("'", `'\\''`)}'`;

const needComputer = async (ctx: ToolContext): Promise<SandboxHandle> => {
  if (!ctx.computer) throw new ToolError("no_computer", "This bot has no computer available.");
  return ctx.computer();
};

/** Streams exec output to tool.output events, at most every 250 ms. */
export async function runStreaming(
  ctx: Pick<ToolContext, "output">,
  h: SandboxHandle,
  cmd: string,
  opts: { cwd?: string; timeoutMs?: number; env?: Record<string, string>; signal?: AbortSignal },
) {
  let pending = "";
  let out = "";
  let code = -1;
  let timedOut = false;
  let truncated = false;
  let last = 0;
  for await (const c of h.exec(cmd, opts)) {
    if (c.type === "stdout" || c.type === "stderr") {
      out += c.data;
      pending += c.data;
      if (Date.now() - last > 250) {
        await ctx.output(pending);
        pending = "";
        last = Date.now();
      }
    } else if (c.type === "exit") {
      code = c.code;
      timedOut = c.timedOut;
      truncated = c.truncated;
    }
  }
  if (pending) await ctx.output(pending);
  return { out, code, timedOut, truncated };
}

/** Phase 2 tools: shell, files, browser (agent-browser) and checkpoints. All require a computer. */
export function registerComputerTools(registry: ToolRegistry) {
  const requires = { computer: true };

  registry.register({
    name: "shell.exec",
    // Destructive commands that reach outside the workspace are high risk.
    riskFor: (args: { command: string }) =>
      isDestructive(args.command) &&
      /(^|[\s'"=])(\/(?!home\/kasama\/workspace)|~\/(?!workspace)|\.\.\/)/.test(args.command)
        ? "high"
        : "low",
    description:
      "Run a bash command in your computer (Ubuntu, home /home/kasama, working directory ~/workspace by default). Output streams to the user. Use for code, files, git, package installs and CLIs.",
    risk: "low",
    requires,
    schema: z.object({
      command: z.string().min(1).max(20_000),
      cwd: z.string().max(1000).optional(),
      timeout_s: z.number().int().min(1).max(3600).optional(),
    }),
    async execute(args, ctx) {
      const h = await needComputer(ctx);
      if (isDestructive(args.command) && ctx.checkpoint) {
        await ctx.checkpoint(`Before: ${args.command.slice(0, 120)}`);
      }
      const r = await runStreaming(ctx, h, args.command, {
        cwd: args.cwd,
        timeoutMs: (args.timeout_s ?? 600) * 1000,
      });
      const status = r.timedOut
        ? `timed out after ${args.timeout_s ?? 600}s`
        : `exit code ${r.code}`;
      return {
        content: `${status}${r.truncated ? " (output truncated)" : ""}\n${r.out}`,
        preview: `${status}${r.out ? `: ${r.out.trim().split("\n").slice(-1)[0]?.slice(0, 200)}` : ""}`,
      };
    },
  });

  registry.register({
    name: "files.read",
    // Outside content (audit 2026-11): later risky calls ask first.
    untrustedOutput: true,
    readOnly: true,
    description: "Read a text file from your computer. Relative paths are inside ~/workspace.",
    risk: "low",
    requires,
    schema: z.object({
      path: z.string().min(1).max(1000),
      max_bytes: z.number().int().min(1).max(2_000_000).optional(),
    }),
    async execute(args, ctx) {
      const data = await (await needComputer(ctx)).readFile(args.path);
      const slice = data.subarray(0, args.max_bytes ?? 200_000);
      if (slice.includes(0))
        throw new ToolError("binary_file", `${args.path} is a binary file (${data.length} bytes).`);
      const text = new TextDecoder().decode(slice);
      return {
        content:
          data.length > slice.length
            ? `${text}\n[... ${data.length - slice.length} more bytes]`
            : text,
        preview: `${data.length} bytes`,
      };
    },
  });

  registry.register({
    name: "files.write",
    description:
      "Create or overwrite a text file in your computer. Relative paths are inside ~/workspace. Parent folders are created.",
    risk: "low",
    requires,
    schema: z.object({ path: z.string().min(1).max(1000), content: z.string().max(5_000_000) }),
    async execute(args, ctx) {
      const h = await needComputer(ctx);
      await h.writeFile(args.path, new TextEncoder().encode(args.content));
      return {
        content: `Wrote ${args.content.length} characters to ${args.path}.`,
        preview: `wrote ${args.path}`,
        artifactPath: h.resolvePath?.(args.path) ?? args.path,
      };
    },
  });

  registry.register({
    name: "files.list",
    readOnly: true,
    description: "List a directory in your computer (default ~/workspace).",
    risk: "low",
    requires,
    schema: z.object({ path: z.string().max(1000).optional() }),
    async execute(args, ctx) {
      const entries = await (await needComputer(ctx)).listDir(args.path ?? "");
      if (!entries.length) return { content: "(empty)", preview: "0 entries" };
      return {
        content: entries
          .map(
            (e) =>
              `${e.type === "dir" ? "d" : "-"} ${String(e.size).padStart(10)}  ${e.name}${e.type === "dir" ? "/" : ""}`,
          )
          .join("\n"),
        preview: `${entries.length} entries`,
      };
    },
  });

  registry.register({
    name: "files.search",
    readOnly: true,
    description:
      "Search text files in your computer for a phrase (case-insensitive). Returns path, line and text.",
    risk: "low",
    requires,
    schema: z.object({ query: z.string().min(1).max(500), path: z.string().max(1000).optional() }),
    async execute(args, ctx) {
      const matches = await (await needComputer(ctx)).search(args.query, args.path);
      if (!matches.length) return { content: "No matches.", preview: "0 matches" };
      return {
        content: matches.map((m) => `${m.path}:${m.line}: ${m.text}`).join("\n"),
        preview: `${matches.length} matches`,
      };
    },
  });

  // --- browser (agent-browser inside the computer; profile in the home directory) ---

  const browser = async (ctx: ToolContext, args: string, timeoutMs = 90_000) => {
    const h = await needComputer(ctx);
    const r = await collectExec(h.exec(`agent-browser ${args}`, { timeoutMs }));
    const out = `${r.stdout}${r.stderr ? `\n${r.stderr}` : ""}`.trim();
    if (r.code !== 0)
      throw new ToolError(
        "browser_error",
        out.slice(0, 2000) || `agent-browser exited with ${r.code}`,
      );
    return out;
  };
  const web = (out: string, preview: string) => ({ content: wrapUntrusted("web", out), preview });

  registry.register({
    name: "browser.open",
    screen: true,
    untrustedOutput: true,
    description:
      "Open a URL in your computer's browser. Then use browser.snapshot to see interactive elements with refs like @e1.",
    risk: "low",
    requires,
    schema: z.object({ url: z.string().min(1).max(4000) }),
    async execute(args, ctx) {
      const out = await browser(ctx, `open ${shq(args.url)}`);
      return web(out || `Opened ${args.url}`, `opened ${args.url.slice(0, 100)}`);
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
    schema: z.object({ interactive_only: z.boolean().optional() }),
    async execute(args, ctx) {
      const out = await browser(ctx, `snapshot${args.interactive_only === false ? "" : " -i"}`);
      return web(out, `${out.split("\n").length} lines`);
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
    schema: z.object({}),
    async execute(_args, ctx) {
      const out = await browser(ctx, "read");
      return web(out, `${out.length} characters`);
    },
  });

  registry.register({
    name: "browser.click",
    screen: true,
    untrustedOutput: true,
    description: "Click an element by its ref from the last snapshot (for example @e3).",
    risk: "low",
    requires,
    schema: z.object({ ref: z.string().regex(/^@?e\d+$/) }),
    async execute(args, ctx) {
      const ref = args.ref.startsWith("@") ? args.ref : `@${args.ref}`;
      return web((await browser(ctx, `click ${ref}`)) || `Clicked ${ref}`, `clicked ${ref}`);
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
    destinationHost: async (_args: unknown, ctx: ToolContext) => {
      if (!ctx.computer) return null;
      const r = await collectExec(
        (await ctx.computer()).exec("agent-browser get url", { timeoutMs: 20_000 }),
      );
      try {
        return new URL(r.stdout.trim()).hostname;
      } catch {
        return null;
      }
    },
    schema: z.object({ ref: z.string().regex(/^@?e\d+$/), text: z.string().max(20_000) }),
    async execute(args, ctx) {
      const ref = args.ref.startsWith("@") ? args.ref : `@${args.ref}`;
      return web(
        (await browser(ctx, `fill ${ref} ${shq(args.text)}`)) || `Filled ${ref}`,
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
    schema: z.object({ text: z.string().max(20_000) }),
    async execute(args, ctx) {
      return web((await browser(ctx, `keyboard type ${shq(args.text)}`)) || "Typed", "typed");
    },
  });

  registry.register({
    name: "browser.press",
    screen: true,
    untrustedOutput: true,
    description: "Press a key, for example Enter, Tab, Escape or Control+a.",
    risk: "low",
    requires,
    schema: z.object({ key: z.string().min(1).max(50) }),
    async execute(args, ctx) {
      return web(
        (await browser(ctx, `press ${shq(args.key)}`)) || `Pressed ${args.key}`,
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
    }),
    async execute(args, ctx) {
      return web(
        (await browser(ctx, `scroll ${args.direction}${args.amount ? ` ${args.amount}` : ""}`)) ||
          "Scrolled",
        `scrolled ${args.direction}`,
      );
    },
  });

  registry.register({
    name: "browser.screenshot",
    screen: true,
    description:
      "Save a screenshot of the current page to a file in your computer and return its path.",
    risk: "low",
    requires,
    schema: z.object({ path: z.string().max(500).optional() }),
    async execute(args, ctx) {
      const asked =
        args.path ?? `screenshots/${new Date().toISOString().replace(/[:.]/g, "-")}.png`;
      // On a team computer relative paths are in the bot's folder (D-148).
      const path = (await needComputer(ctx)).resolvePath?.(asked) ?? asked;
      await browser(
        ctx,
        `screenshot ${shq(path.startsWith("/") ? path : `/home/kasama/workspace/${path}`)}`,
      );
      return {
        content: `Saved screenshot to ${path}.`,
        preview: `saved ${path}`,
        artifactPath: path,
      };
    },
  });

  registry.register({
    name: "checkpoint.create",
    description:
      "Save an undo point of your computer's files before risky changes. The user can restore it from the timeline.",
    risk: "low",
    requires,
    schema: z.object({ label: z.string().min(1).max(200) }),
    async execute(args, ctx) {
      if (!ctx.checkpoint)
        throw new ToolError("no_computer", "This bot has no computer available.");
      const cp = await ctx.checkpoint(args.label);
      return {
        content: `Saved checkpoint ${cp.checkpointId} (${cp.label}).`,
        preview: `checkpoint ${cp.label}`,
      };
    },
  });

  return registry;
}
