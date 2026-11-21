import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

export const McpKey = z
  .object({
    id: Uuid,
    name: z.string(),
    hint: z.string(),
    last_used_at: ts.nullable(),
    created_at: ts,
  })
  .openapi("McpKey");

/** An AI app connected with OAuth (D-117): one person's grant to one app in one workspace. */
export const McpConnection = z
  .object({
    client_id: z.string(),
    client_name: z.string().openapi({ description: "The name the app registered with" }),
    user_id: Uuid,
    user_name: z
      .string()
      .openapi({ description: "Who connected it: their name, else their email" }),
    mine: z.boolean(),
    connected_at: ts,
    last_used_at: ts.nullable(),
  })
  .openapi("McpConnection");

export const CreatedMcpKey = McpKey.extend({
  key: z
    .string()
    .openapi({ description: "Shown once; paste it into the AI app as a bearer token" }),
  mcp_url: z.string(),
}).openapi("CreatedMcpKey");

export const CreateMcpKeyRequest = z
  .object({ name: z.string().trim().min(1).max(80) })
  .openapi("CreateMcpKeyRequest");

export const McpAuthRequestInfo = z
  .object({
    id: Uuid,
    client_name: z.string(),
    redirect_host: z.string(),
    // False when the app sends people somewhere other than a well-known AI app or their own device:
    // the consent screen warns.
    known_app: z.boolean(),
    expires_at: ts,
  })
  .openapi("McpAuthRequestInfo");

export const McpConsentRequest = z
  .object({ org_id: Uuid, approve: z.boolean() })
  .openapi("McpConsentRequest");

export const McpConsentResult = z.object({ redirect_url: z.string() }).openapi("McpConsentResult");
