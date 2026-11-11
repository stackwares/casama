/**
 * Teach a task by showing it (SPEC: Post-v1 roadmap → Teach a task; D-120): capturing each step's
 * context from the computer, and the drafting run's teach.save_draft tool.
 */
import type { Database } from "@casama/db";
import { SKILL_NAME } from "@casama/domain";
import { collectExec, type SandboxHandle } from "@casama/sandbox";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { ToolError, type ToolRegistry } from "./tools/registry.ts";

const quiet = async (h: SandboxHandle, cmd: string) => {
  try {
    const r = await collectExec(h.exec(cmd, { timeoutMs: 8_000 }));
    return r.code === 0 ? r.stdout.trim() : "";
  } catch {
    return "";
  }
};

/**
 * What the screen looks like after a step: the accessibility snapshot (desktop, else the bot's
 * browser), the browser's address and a screenshot. Missing pieces are left out, never fatal.
 */
export async function captureTeachContext(h: SandboxHandle) {
  const [desktop, url, screenshot] = await Promise.all([
    quiet(h, "agent-desktop snapshot -i --compact 2>/dev/null"),
    quiet(h, "agent-browser get url 2>/dev/null"),
    h.screenshot().catch(() => null),
  ]);
  const snapshot = desktop || (await quiet(h, "agent-browser snapshot -i 2>/dev/null"));
  return {
    snapshot: snapshot ? snapshot.slice(0, 20_000) : null,
    url: /^https?:\/\//.test(url) ? url.slice(0, 2000) : null,
    screenshot: screenshot && screenshot.byteLength <= 3_000_000 ? screenshot : null,
  };
}

export function registerTeachTools(registry: ToolRegistry, deps: { db: Database }) {
  const { db } = deps;
  registry.register({
    name: "teach.save_draft",
    description:
      "Only when turning a recording into a skill (a teach recording): save the draft skill for the person to review. Not for anything else.",
    risk: "low",
    keepsPlaceholders: true,
    schema: z.object({
      name: z.string().regex(SKILL_NAME),
      description: z.string().min(1).max(300),
      instructions: z.string().min(1).max(50_000),
      inputs: z
        .array(
          z.object({
            name: z.string().min(1).max(64),
            description: z.string().max(300).optional(),
            secret: z.boolean().optional(),
          }),
        )
        .max(30)
        .optional(),
      checks: z.array(z.string().min(1).max(500)).max(20).optional(),
    }),
    async execute(args, ctx) {
      const inputs = args.inputs ?? [];
      const checks = args.checks ?? [];
      const body = [
        args.instructions.trim(),
        inputs.length
          ? `## Inputs\n\n${inputs.map((i) => `- \`${i.secret ? `{{secret:${i.name}}}` : i.name}\`${i.description ? `: ${i.description}` : ""}`).join("\n")}`
          : "",
        checks.length ? `## Success checks\n\n${checks.map((c) => `- ${c}`).join("\n")}` : "",
      ]
        .filter(Boolean)
        .join("\n\n");
      const draft = { name: args.name, description: args.description, body, inputs, checks };
      const [s] = await db.execute<{ id: string }>(sql`
        update public.teach_sessions set draft = ${JSON.stringify(draft)}::jsonb, status = 'drafted'
        where run_id = ${ctx.runId}::uuid and status = 'drafting' returning id`);
      if (!s)
        throw new ToolError(
          "not_teaching",
          "There's no recording to draft a skill from in this chat.",
        );
      return {
        content: `Saved the draft skill ${args.name} for review.`,
        preview: `draft ${args.name}`,
      };
    },
  });
}
