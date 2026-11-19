import { collectExec, type SandboxHandle } from "@casama/sandbox";
import { z } from "zod";
import { wrapUntrusted } from "../context.ts";
import { registerBrowserTools } from "./browser.ts";
import { type ToolContext, ToolError, type ToolRegistry, toolImage } from "./registry.ts";

/** File endings read as pictures (files.read; D-269). */
const IMAGE_TYPES: Record<string, string> = {
  png: "image/png",
  jpg: "image/jpeg",
  jpeg: "image/jpeg",
  webp: "image/webp",
  gif: "image/gif",
};

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
  opts: {
    cwd?: string;
    timeoutMs?: number;
    env?: Record<string, string>;
    signal?: AbortSignal;
    /** How long after the command's own timeout its exit is still waited for. */
    exitGraceMs?: number;
  },
) {
  let pending = "";
  let out = "";
  let code = -1;
  let timedOut = false;
  let truncated = false;
  let exited = false;
  let last = 0;
  // The computer stops the command at its timeout and says so. When that word never comes (a
  // background process kept the output open, the computer froze), waiting ends a minute later
  // instead of holding the run until its own time limit (D-413). Hanging up stops the command.
  const limit = opts.timeoutMs
    ? AbortSignal.timeout(opts.timeoutMs + (opts.exitGraceMs ?? EXIT_GRACE_MS))
    : null;
  const signal = limit
    ? opts.signal
      ? AbortSignal.any([opts.signal, limit])
      : limit
    : opts.signal;
  try {
    const { exitGraceMs: _grace, ...execOpts } = opts;
    for await (const c of h.exec(cmd, { ...execOpts, signal })) {
      if (c.type === "stdout" || c.type === "stderr") {
        out += c.data;
        pending += c.data;
        if (Date.now() - last > 250) {
          await ctx.output(pending);
          pending = "";
          last = Date.now();
        }
      } else if (c.type === "exit") {
        exited = true;
        code = c.code;
        timedOut = c.timedOut;
        truncated = c.truncated;
      }
    }
  } catch (err) {
    if (!limit?.aborted || opts.signal?.aborted) throw err;
    timedOut = true;
  }
  if (pending) await ctx.output(pending);
  // The stream ended without the command's exit: the computer restarted or the link dropped.
  return { out, code, timedOut, truncated, lost: !exited && !timedOut };
}

/** How long after a command's own timeout its exit is still waited for. */
export const EXIT_GRACE_MS = 60_000;

/** Phase 2 tools: shell, files, browser (agent-browser) and checkpoints. All require a computer. */
export function registerComputerTools(registry: ToolRegistry) {
  const requires = { computer: true };

  registry.register({
    name: "shell.exec",
    // Destructive commands that reach outside the workspace are high risk.
    riskFor: (args: { command: string }) =>
      isDestructive(args.command) &&
      /(^|[\s'"=])(\/(?!home\/casama\/workspace)|~\/(?!workspace)|\.\.\/)/.test(args.command)
        ? "high"
        : "low",
    description:
      "Run a bash command in your computer (Ubuntu, home /home/casama, working directory ~/workspace by default). Output streams to the user. Use for code, files, git, package installs and CLIs.",
    risk: "low",
    requires,
    schema: z.object({
      command: z.string().min(1).max(20_000),
      cwd: z.string().max(1000).optional(),
      timeout_s: z.number().int().min(1).max(3600).optional(),
    }),
    async execute(args, ctx) {
      const h = await needComputer(ctx);
      if (isDestructive(args.command)) {
        const label = `Before: ${args.command.slice(0, 120)}`;
        if (ctx.checkpointBefore) await ctx.checkpointBefore(label);
        else if (ctx.checkpoint) await ctx.checkpoint(label);
      }
      const r = await runStreaming(ctx, h, args.command, {
        cwd: args.cwd,
        timeoutMs: (args.timeout_s ?? 600) * 1000,
        signal: ctx.signal,
      });
      const status = r.timedOut
        ? `timed out after ${args.timeout_s ?? 600}s`
        : r.lost
          ? "the connection to your computer dropped before this finished, and the command was stopped (it may have done part of its work; check before running it again)"
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
    description:
      "Read a text file from your computer, or look at an image (png, jpg, webp, gif). Relative paths are inside ~/workspace.",
    risk: "low",
    requires,
    schema: z.object({
      path: z.string().min(1).max(1000),
      max_bytes: z.number().int().min(1).max(2_000_000).optional(),
    }),
    async execute(args, ctx) {
      const data = await (await needComputer(ctx)).readFile(args.path);
      // A picture: attached for models that can see it (D-269).
      const kind = IMAGE_TYPES[args.path.toLowerCase().split(".").pop() ?? ""];
      if (kind) {
        const image = toolImage(data, kind);
        if (image)
          return {
            content: `${args.path} is an image (${data.length} bytes). It's attached so you can see it.`,
            preview: `image, ${data.length} bytes`,
            image,
          };
      }
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
    name: "files.edit",
    description:
      "Change part of a text file in your computer without rewriting it: replaces old_text with new_text. old_text must match the file exactly (spaces and line breaks too) and appear once, unless replace_all is set. Use files.write for new files or full rewrites.",
    risk: "low",
    requires,
    schema: z.object({
      path: z.string().min(1).max(1000),
      old_text: z.string().min(1).max(200_000),
      new_text: z.string().max(2_000_000),
      replace_all: z.boolean().optional(),
    }),
    async execute(args, ctx) {
      const h = await needComputer(ctx);
      const data = await h.readFile(args.path);
      if (data.includes(0))
        throw new ToolError(
          "binary_file",
          `${args.path} is a binary file; files.edit changes text.`,
        );
      const text = new TextDecoder().decode(data);
      const count = text.split(args.old_text).length - 1;
      if (count === 0)
        throw new ToolError(
          "not_found",
          `old_text isn't in ${args.path}. Read the file again and copy the text exactly.`,
        );
      if (count > 1 && !args.replace_all)
        throw new ToolError(
          "not_unique",
          `old_text appears ${count} times in ${args.path}. Add surrounding lines so it's unique, or set replace_all.`,
        );
      const next = args.replace_all
        ? text.split(args.old_text).join(args.new_text)
        : text.replace(args.old_text, () => args.new_text);
      await h.writeFile(args.path, new TextEncoder().encode(next));
      return {
        content: `Replaced ${args.replace_all ? count : 1} place${count > 1 && args.replace_all ? "s" : ""} in ${args.path}.`,
        preview: `edited ${args.path}`,
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

  // Browser tools: the bot's computer or the person's own browser (D-323 Phase 3).
  registerBrowserTools(registry);

  registry.register({
    name: "checkpoint.create",
    description:
      "Save an undo point of your computer's files before risky changes. The user can restore it from the timeline.",
    risk: "low",
    // Only the bot's own state inside Casama: never asks (D-155).
    selfOnly: true,
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

  registry.register({
    name: "computer.restart",
    description:
      "Restart your computer when it is stuck: a program won't respond, the browser hangs or commands time out for no reason. Files in the home folder are kept; running programs stop. Takes about 20 seconds. Tell the user you restarted it.",
    risk: "low",
    requires,
    schema: z.object({
      reason: z.string().min(1).max(300).describe("What was wrong, in a few words"),
    }),
    async execute(_args, ctx) {
      if (!ctx.restartComputer)
        throw new ToolError("no_computer", "This bot has no computer available.");
      await ctx.restartComputer();
      return {
        content:
          "Restarted the computer. Files are kept; programs that were running have stopped, so start again anything you still need.",
        preview: "restarted the computer",
      };
    },
  });

  return registry;
}
