import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

export const PasswordManager = z
  .object({
    id: Uuid,
    scope: z.enum(["workspace", "personal"]),
    provider: z.enum(["1password", "bitwarden"]),
    name: z.string(),
    url: z.string(),
    allowed_vaults: z.array(z.string()),
    allowed_bot_ids: z.array(Uuid).nullable(),
    status: z.enum(["ok", "error"]),
    last_error: z.string().nullable(),
    created_at: ts,
  })
  .openapi("PasswordManager");

export const CreatePasswordManagerRequest = z
  .object({
    org_id: Uuid,
    scope: z.enum(["workspace", "personal"]),
    provider: z.enum(["1password", "bitwarden"]),
    name: z.string().min(1).max(100),
    /** 1Password Connect server, or Bitwarden's `bw serve` address. */
    url: z.url(),
    token: z.string().max(5000),
  })
  .openapi("CreatePasswordManagerRequest");

export const UpdatePasswordManagerRequest = z
  .object({ allowed_vaults: z.array(z.string().max(200)).max(100), allowed_bot_ids: z.array(Uuid).max(200).nullable().optional() })
  .openapi("UpdatePasswordManagerRequest");

export const PasswordManagerVault = z
  .object({ id: z.string(), name: z.string(), allowed: z.boolean(), logins: z.number().int().nullable() })
  .openapi("PasswordManagerVault");
