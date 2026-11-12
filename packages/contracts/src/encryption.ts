import { z } from "@hono/zod-openapi";

const ts = z.iso.datetime({ offset: true });

export const EncryptionStatus = z
  .object({
    /** off, encrypting (sealing existing rows), on, or decrypting (turning off). */
    mode: z.enum(["off", "encrypting", "on", "decrypting"]),
    /** Whether this server has a key to encrypt with (CONTENT_ENCRYPTION_KEY or AWS KMS). */
    available: z.boolean(),
    key: z.enum(["server_key", "aws_kms"]).nullable(),
    since: ts.nullable(),
    rotated_at: ts.nullable(),
    /** A replaced data key's rows are still being moved onto the new key (D-238). Optional for older servers. */
    rekeying: z.boolean().optional(),
  })
  .openapi("EncryptionStatus");

export const ReplacedDataKeys = z
  .object({
    /** Workspaces whose data key was replaced. */
    workspaces: z.number().int(),
    /** People whose About you key was replaced. */
    people: z.number().int(),
  })
  .openapi("ReplacedDataKeys");

export const SetEncryptionRequest = z
  .object({ enabled: z.boolean() })
  .openapi("SetEncryptionRequest");
