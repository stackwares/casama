import { z } from "@hono/zod-openapi";
import { Integration } from "./autonomy.ts";
import { Uuid } from "./common.ts";
import { galleryExtras } from "./gallery.ts";

/** A built-in app: a vendor's hosted MCP server Casama connects to (D-089). */
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
    /** Composio's toolkit slug for this app, so apps connected through a Composio hub can be matched to it. */
    composio: z.string().optional(),
    /**
     * A single-color SVG mark for apps from the open gallery (D-239), tinted by the app like its
     * bundled logos. Built-in apps have none: the app ships their marks.
     */
    logo_url: z.string().optional(),
    /** Gallery v2 (D-315), gallery apps only. */
    added: galleryExtras.added,
    pick: galleryExtras.pick,
    examples: galleryExtras.examples,
    access: galleryExtras.access,
    min_app: galleryExtras.min_app,
    source: galleryExtras.source,
    version: z.number().int().optional(),
    stats: galleryExtras.stats,
  })
  .openapi("CatalogApp");

export const AppCatalog = z
  .object({
    apps: z.array(CatalogApp),
    /** The OAuth redirect address vendors must allow, for admins registering a client. */
    redirect_uri: z.string(),
    /** The apps an empty chat offers to connect first, in order (D-372); the app's own list when absent. */
    starter_apps: z.array(z.string()).optional(),
  })
  .openapi("AppCatalog");

export const ConnectAppRequest = z
  .object({
    org_id: Uuid,
    app_id: z.string().max(100),
    method: z.enum(["oauth", "api_key", "none", "managed"]),
    api_key: z.string().min(1).max(10_000).optional(),
    /** Reconnect this integration instead of adding a new one. */
    integration_id: Uuid.optional(),
    /**
     * Signing in from the app's sign-in sheet: when it finishes, send the browser to
     * casama-auth://done so the sheet closes, instead of showing a "go back to Casama" page.
     */
    return_to_app: z.boolean().optional(),
  })
  .openapi("ConnectAppRequest");

/** An MCP server that isn't in the catalog, offered by a bot in a chat or typed by the person (D-473). */
export const ProbeServerRequest = z
  .object({ org_id: Uuid, url: z.string().min(1).max(2000) })
  .openapi("ProbeServerRequest");

export const ProbeServerResponse = z
  .object({
    /** How the server lets people in: nothing, a browser sign-in, or a key. */
    auth: z.enum(["none", "oauth", "key"]),
    host: z.string(),
    /** Where the browser sign-in happens, when it isn't the server's own host. */
    sign_in_host: z.string().optional(),
    /** False when this API can't take a browser sign-in back (plain http, or no way to register). */
    oauth_available: z.boolean().optional(),
    /** The catalog app at this address, if any: connect that instead. */
    app_id: z.string().optional(),
  })
  .openapi("ProbeServerResponse");

export const ConnectServerRequest = z
  .object({
    org_id: Uuid,
    url: z.string().min(1).max(2000),
    /** Shown to people; the connection's own name is made from it. */
    name: z.string().min(1).max(60),
    method: z.enum(["oauth", "api_key", "none"]),
    api_key: z.string().min(1).max(10_000).optional(),
    /** The header the key goes in (default Authorization, sent as Bearer). */
    auth_header: z
      .string()
      .regex(/^[A-Za-z0-9-]{1,60}$/)
      .optional(),
    /** The person typed an address that holds its own key: keep it in Vault, not in the config. */
    private_url: z.boolean().optional(),
    /** The bot whose card this came from; it gets the connection. */
    bot_id: Uuid.optional(),
    return_to_app: z.boolean().optional(),
  })
  .openapi("ConnectServerRequest");

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
  .object({
    app: z.string().min(1).max(100),
    /** As in ConnectAppRequest: finish on casama-auth://done so the app's sign-in sheet closes. */
    return_to_app: z.boolean().optional(),
  })
  .openapi("ProviderConnectRequest");
