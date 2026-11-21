/**
 * The phone browser's stage through the admin bot (docs/PHONE-BROWSER-PLAN.md §6).
 *
 * The same rule as every admin tool (D-435): the read runs in the owner's own admin chat; a change
 * waits for the owner's fresh approval, checked again from the database by [guard]. The bot can
 * say whether a stage's numbers are met; it can't confirm a safety review or a store approval, so
 * it lists those for the owner instead of assuming them.
 */

import { type ToolContext, ToolError, type ToolRegistry } from "@casama/agent";
import { appBrowserNextSteps, checkAppBrowserSettings } from "@casama/domain";
import { z } from "zod";
import type { AdminBotDeps } from "./admin-bot.ts";
import { appBrowserNumbers, getAppBrowserSettings, setAppBrowserSettings } from "./app-browser.ts";

type Guard = (
  deps: AdminBotDeps,
  ctx: ToolContext,
  tool: string,
  write: boolean,
) => Promise<string | null>;
type Audit = (
  deps: AdminBotDeps,
  ctx: ToolContext,
  tool: string,
  by: string,
  metadata: Record<string, unknown>,
) => Promise<void>;

export function registerAdminAppBrowserTools(
  registry: ToolRegistry,
  deps: AdminBotDeps,
  guard: Guard,
  audit: Audit,
) {
  const base = { instanceAdmin: true, risk: "high" as const };

  registry.register({
    ...base,
    name: "admin.phone_browser.status",
    readOnly: true,
    description:
      "Instance admin: the browser inside the phone app. Returns its stage (off, testers, on), who the testers are, which reasons and systems are on, the last 14 days' numbers, and for each next switch whether its numbers are met and what only the owner can confirm (a safety review, store approvals, days in a stage). Never treat those as done unless the owner says so.",
    schema: z.object({}),
    async execute(_args, ctx) {
      await guard(deps, ctx, "admin.phone_browser.status", false);
      const settings = await getAppBrowserSettings(deps.db);
      const numbers = await appBrowserNumbers(deps.db, 14);
      const next = appBrowserNextSteps(settings, numbers);
      return {
        content: JSON.stringify({ settings, numbers, next }),
        preview: `${settings.stage}, ${numbers.phone_runs} phone runs`,
      };
    },
  });

  registry.register({
    ...base,
    name: "admin.phone_browser.set",
    description:
      'Instance admin: change the phone browser\'s stage. stage "off" turns it off for everyone at once. "testers" gives it to the listed user ids. "on" gives it to everyone on the listed systems (ios, android). reasons say when a bot may use it: asked (the person asks), blocked (a site blocks the bot\'s computer), signed_in (a site the person signed in to on the phone). Only the given fields change. Call admin.phone_browser.status first and tell the owner what is and isn\'t met. The owner approves first.',
    schema: z.object({
      stage: z.enum(["off", "testers", "on"]).optional(),
      testers: z.array(z.uuid()).max(200).optional(),
      reasons: z
        .object({
          asked: z.boolean().optional(),
          blocked: z.boolean().optional(),
          signed_in: z.boolean().optional(),
        })
        .optional(),
      systems: z
        .array(z.enum(["ios", "android"]))
        .max(2)
        .optional(),
    }),
    async execute(args, ctx) {
      const by = (await guard(deps, ctx, "admin.phone_browser.set", true)) as string;
      const before = await getAppBrowserSettings(deps.db);
      const { settings, errors } = checkAppBrowserSettings({
        stage: args.stage ?? before.stage,
        testers: args.testers ?? before.testers,
        reasons: { ...before.reasons, ...(args.reasons ?? {}) },
        systems: args.systems ?? before.systems,
      });
      if (!settings) throw new ToolError("admin_refused", errors.join("; "));
      const after = await setAppBrowserSettings(deps.db, settings);
      await audit(deps, ctx, "admin.phone_browser.set", by, { before, after });
      return {
        content: `The phone browser is ${after.stage}. ${JSON.stringify(after)}`,
        preview: `stage ${after.stage}`,
      };
    },
  });
}
