import { collectExec, type SandboxHandle } from "@kasama/sandbox";
import { z } from "zod";
import { wrapUntrusted } from "../context.ts";
import { TAKEOVER_TOOL } from "../takeover.ts";
import { shq } from "./computer.ts";
import { type ToolContext, ToolError, type ToolRegistry } from "./registry.ts";

const need = async (ctx: ToolContext): Promise<SandboxHandle> => {
  if (!ctx.computer) throw new ToolError("no_computer", "This bot has no computer available.");
  return ctx.computer();
};

/** Runs agent-desktop in the computer's desktop session; returns its JSON envelope's data or error. */
async function agentDesktop(ctx: ToolContext, args: string, timeoutMs = 60_000) {
  const h = await need(ctx);
  const r = await collectExec(h.exec(`agent-desktop ${args}`, { timeoutMs }));
  const text = r.stdout.trim();
  let env: { ok?: boolean; data?: unknown; error?: { code?: string; message?: string } } = {};
  try {
    env = JSON.parse(text);
  } catch {
    if (r.code !== 0) throw new ToolError("desktop_failed", (r.stderr || text).slice(0, 2000));
    return { text, data: null };
  }
  if (env.ok === false)
    throw new ToolError(
      env.error?.code?.toLowerCase() ?? "desktop_failed",
      env.error?.message ?? text.slice(0, 2000),
    );
  return { text, data: env.data };
}

const REF = z.string().regex(/^@[\w-]+:e\d+$/, "a ref from desktop.snapshot, like @s1:e4");

/** Phase 5 desktop tools (agent-desktop on X11, with xdotool and screenshots as the fallback). */
export function registerDesktopTools(registry: ToolRegistry) {
  const requires = { computer: true, desktop: true };

  registry.register({
    name: "desktop.snapshot",
    untrustedOutput: true,
    readOnly: true,
    screen: true,
    description:
      "Accessibility tree of desktop apps (or one app) with refs like @s1:e4 for click and type. Start here before acting on the desktop.",
    risk: "low",
    requires,
    schema: z.object({ app: z.string().max(100).optional() }),
    async execute(args, ctx) {
      const { text } = await agentDesktop(
        ctx,
        `snapshot -i --compact${args.app ? ` --app ${shq(args.app)}` : ""}`,
      );
      return { content: wrapUntrusted("desktop", text), preview: `${text.length} characters` };
    },
  });

  registry.register({
    name: "desktop.launch",
    screen: true,
    description: "Start a desktop app (for example mousepad, xterm) and wait for its window.",
    risk: "low",
    requires,
    schema: z.object({
      app: z.string().min(1).max(100),
      args: z.array(z.string().max(1000)).max(20).optional(),
    }),
    async execute(args, ctx) {
      const extra = (args.args ?? []).map((a) => ` --arg=${shq(a)}`).join("");
      await agentDesktop(ctx, `launch ${shq(args.app)}${extra} --activate`, 45_000);
      return { content: `Launched ${args.app}.`, preview: `launched ${args.app}` };
    },
  });

  registry.register({
    name: "desktop.click",
    screen: true,
    description:
      "Click an element by ref from desktop.snapshot, or at screen coordinates when the app exposes no accessibility tree.",
    risk: "low",
    requires,
    schema: z.object({
      ref: REF.optional(),
      x: z.number().int().min(0).max(10_000).optional(),
      y: z.number().int().min(0).max(10_000).optional(),
    }),
    async execute(args, ctx) {
      if (args.ref) {
        await agentDesktop(ctx, `click ${shq(args.ref)}`);
        return { content: `Clicked ${args.ref}.`, preview: `clicked ${args.ref}` };
      }
      if (args.x === undefined || args.y === undefined)
        throw new ToolError("invalid_arguments", "Give a ref, or both x and y.");
      await (await need(ctx)).input({ type: "click", x: args.x, y: args.y });
      return { content: `Clicked at ${args.x},${args.y}.`, preview: `clicked ${args.x},${args.y}` };
    },
  });

  registry.register({
    name: "desktop.type",
    screen: true,
    description:
      "Type text into an element by ref, or into whatever has keyboard focus when no ref is given.",
    risk: "low",
    requires,
    schema: z.object({ text: z.string().min(1).max(10_000), ref: REF.optional() }),
    async execute(args, ctx) {
      if (args.ref) await agentDesktop(ctx, `type ${shq(args.ref)} ${shq(args.text)}`);
      else await (await need(ctx)).input({ type: "type", text: args.text });
      return {
        content: `Typed ${args.text.length} characters.`,
        preview: `typed ${args.text.length} chars`,
      };
    },
  });

  registry.register({
    name: "desktop.press",
    screen: true,
    description:
      "Press a key or combo in the focused app: return, escape, ctrl+s, alt+f4, shift+tab.",
    risk: "low",
    requires,
    schema: z.object({ keys: z.string().min(1).max(50), app: z.string().max(100).optional() }),
    async execute(args, ctx) {
      try {
        await agentDesktop(
          ctx,
          `press ${shq(args.keys)}${args.app ? ` --app ${shq(args.app)}` : ""}`,
        );
      } catch (err) {
        // Fall back to X input (xdotool names: ctrl+s, Return, Escape).
        if (!(err instanceof ToolError)) throw err;
        await (await need(ctx)).input({ type: "key", key: args.keys });
      }
      return { content: `Pressed ${args.keys}.`, preview: `pressed ${args.keys}` };
    },
  });

  registry.register({
    name: "desktop.screenshot",
    screen: true,
    readOnly: true,
    description:
      "Save a screenshot of the whole desktop to a file in your computer and return its path (for the user, or when the accessibility tree is empty).",
    risk: "low",
    requires,
    schema: z.object({ path: z.string().max(500).optional() }),
    async execute(args, ctx) {
      const h = await need(ctx);
      const asked =
        args.path ?? `screenshots/desktop-${new Date().toISOString().replace(/[:.]/g, "-")}.png`;
      const path = h.resolvePath?.(asked) ?? asked;
      const png = await h.screenshot();
      await h.writeFile(path.startsWith("/") ? path : `/home/kasama/workspace/${path}`, png);
      return {
        content: `Saved a desktop screenshot to ${path}.`,
        preview: `saved ${path}`,
        artifactPath: path,
      };
    },
  });

  registry.register({
    name: TAKEOVER_TOOL,
    description:
      "Ask a person to take over your computer's screen (for example to sign in, solve a CAPTCHA or approve something only they can). The page you have open in the browser opens on a visible desktop for them. You wait until they hand back control or decline.",
    risk: "low",
    // Offered on headless computers too: the run switches the computer to a desktop first.
    requires: { computer: true },
    schema: z.object({ reason: z.string().min(1).max(1000) }),
    async execute() {
      // Handled by the run loop so the wait is durable.
      throw new ToolError("internal", "request_takeover runs in the run loop");
    },
  });

  return registry;
}
