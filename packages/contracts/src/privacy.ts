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
  })
  .openapi("OrgSettings");

export const UpdateOrgSettingsRequest = OrgSettings.partial().openapi("UpdateOrgSettingsRequest");
