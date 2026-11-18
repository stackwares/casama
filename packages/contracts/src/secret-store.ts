import { z } from "@hono/zod-openapi";

export const SecretStoreSettings = z
  .object({
    provider: z.enum(["vault", "infisical"]),
    site_url: z.string().nullable(),
    project_id: z.string().nullable(),
    environment: z.string().nullable(),
    secret_path: z.string().nullable(),
  })
  .openapi("SecretStoreSettings");

export const SetSecretStoreRequest = z
  .object({
    site_url: z.url(),
    project_id: z.string().min(1).max(100),
    environment: z.string().min(1).max(64).optional(),
    secret_path: z.string().regex(/^\//).max(300).optional(),
    client_id: z.string().min(1).max(200),
    client_secret: z.string().min(1).max(500),
    /** Move the workspace's current secrets from Vault into Infisical. */
    move_existing: z.boolean().optional(),
  })
  .openapi("SetSecretStoreRequest");
