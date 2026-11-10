import { z } from "@hono/zod-openapi";
import { Integration } from "./autonomy.ts";
import { Uuid } from "./common.ts";

/** A built-in app: a vendor's hosted MCP server Kasama connects to (D-089). */
export const CatalogApp = z
  .object({
    id: z.string(),
    name: z.string(),
    description: z.string(),
    category: z.enum([
      "developer",
      "productivity",
      "google",
      "payments",
      "design",
      "sales",
      "data",
      "automation",
    ]),
    color: z.string().openapi({ description: "Brand color, hex without #" }),
    homepage: z.string(),
    url: z.string(),
    auth: z.array(z.enum(["oauth", "api_key", "none", "managed"])),
    api_key: z
      .object({
        label: z.string(),
        placeholder: z.string().optional(),
        url: z.string(),
        steps: z.array(z.string()),
      })
      .optional(),
    capabilities: z.array(z.string()),
    popular: z.boolean(),
    note: z.string().optional(),
    /** Whether one-click sign-in works on this server (some vendors need a client the admin sets up). */
    oauth_available: z.boolean(),
  })
  .openapi("CatalogApp");

export const AppCatalog = z
  .object({
    apps: z.array(CatalogApp),
    /** The OAuth redirect address vendors must allow, for admins registering a client. */
    redirect_uri: z.string(),
  })
  .openapi("AppCatalog");

export const ConnectAppRequest = z
  .object({
    org_id: Uuid,
    app_id: z.string().max(64),
    method: z.enum(["oauth", "api_key", "none", "managed"]),
    api_key: z.string().min(1).max(10_000).optional(),
    /** Reconnect this integration instead of adding a new one. */
    integration_id: Uuid.optional(),
  })
  .openapi("ConnectAppRequest");

export const ConnectAppResponse = z
  .object({
    status: z.enum(["connected", "authorize", "error"]),
    integration: Integration.optional(),
    /** Open in a browser; the vendor redirects back to the API when done. */
    authorize_url: z.string().optional(),
    flow_id: Uuid.optional(),
    error: z.string().optional(),
  })
  .openapi("ConnectAppResponse");

export const ConnectFlowStatus = z
  .object({
    status: z.enum(["pending", "connected", "error", "expired"]),
    integration: Integration.optional(),
    error: z.string().optional(),
  })
  .openapi("ConnectFlowStatus");

export const UpdateIntegrationRequest = z
  .object({ risk_overrides: z.record(z.string(), z.enum(["low", "medium", "high"])).optional() })
  .openapi("UpdateIntegrationRequest");

export const ProviderApp = z
  .object({
    slug: z.string(),
    name: z.string(),
    description: z.string(),
    logo: z.string().nullable(),
  })
  .openapi("ProviderApp");

export const ProviderAccount = z
  .object({ app: z.string(), status: z.enum(["connected", "pending", "error"]) })
  .openapi("ProviderAccount");

export const ProviderConnectRequest = z
  .object({ app: z.string().min(1).max(100) })
  .openapi("ProviderConnectRequest");
