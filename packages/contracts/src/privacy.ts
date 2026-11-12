import { z } from "@hono/zod-openapi";

export const DeleteAccountRequest = z
  .object({
    confirm_email: z.email().openapi({ description: "The account's email, to confirm" }),
  })
  .openapi("DeleteAccountRequest");

export const AccountDeletion = z
  .object({
    purge_after: z.iso.datetime({ offset: true }),
    workspaces_deleted: z
      .array(z.string())
      .openapi({ description: "Workspaces you are the only owner of; they are deleted with you" }),
  })
  .openapi("AccountDeletion");

export const OrgSettings = z
  .object({
    run_event_retention_days: z.number().int().min(7).max(3650),
    require_mfa: z.boolean().openapi({
      description:
        "Owners and admins must use two-step sign-in (turning it on needs an aal2 session)",
    }),
    mcp_decide_approvals: z.boolean().openapi({
      description: "Allow approving or denying actions from AI apps connected over MCP",
    }),
    allow_bot_to_bot: z.boolean().openapi({
      description: "Bots may @mention, message and delegate to each other; subagents always work",
    }),
    a2a_enabled: z.boolean().openapi({
      description:
        "Bots the workspace chooses can be published as A2A agents, reachable with workspace API keys",
    }),
    llm_tracing: z.boolean().openapi({
      description:
        "Send model calls to the server's Langfuse, secrets redacted; no effect without Langfuse",
    }),
    analytics_opt_out: z.boolean().optional().openapi({
      description: "Disable usage analytics collection and rollups for this workspace",
    }),
  })
  .openapi("OrgSettings");

export const UpdateOrgSettingsRequest = OrgSettings.partial().openapi("UpdateOrgSettingsRequest");

export const SetAnalyticsOptOutRequest = z
  .object({
    opt_out: z.boolean().openapi({ description: "True to opt out of usage analytics" }),
  })
  .openapi("SetAnalyticsOptOutRequest");
