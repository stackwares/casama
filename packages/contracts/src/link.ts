import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

const ts = z.iso.datetime({ offset: true });

/**
 * Casama Link (D-296): a self-hosted server linked to a Casama Cloud workspace gets a public
 * address. These are the parts people use from the app; the server-to-cloud calls
 * (/link/v1/link and /link/v1/remote) authenticate with a key and aren't in this document.
 */

export const LinkSignInRequest = z
  .object({
    user_code: z.string().openapi({ description: "The code the server shows, like K7QM-2XFD" }),
    instance_name: z.string(),
    platform: z.string().nullable(),
    version: z.string().nullable(),
    approved: z.boolean(),
    expires_at: ts,
  })
  .openapi("LinkSignInRequest");

export const ApproveLinkSignInRequest = z
  .object({ user_code: z.string().min(8).max(16) })
  .openapi("ApproveLinkSignInRequest");

export const ApprovedLinkSignIn = z
  .object({ instance_name: z.string() })
  .openapi("ApprovedLinkSignIn");

// Statuses here are plain strings, not enums: the generated Dart client refuses a value it doesn't
// know, so an enum could never gain a member without breaking apps already installed.
export const LinkServerStatus = z.string().openapi({
  description:
    "active: it has a tunnel. parked: not seen for a while, the tunnel returns when the server does. released: remote access was turned off, the address is kept for a time. suspended: taken down. Treat an unknown value as not active.",
  example: "active",
});

export const LinkServer = z
  .object({
    id: Uuid,
    instance_name: z.string(),
    address: z.string().openapi({ description: "https://<label>.<zone>" }),
    pages_address: z.string(),
    status: LinkServerStatus,
    status_reason: z.string().nullable(),
    platform: z.string().nullable(),
    version: z.string().nullable(),
    last_seen_at: ts.nullable(),
    created_at: ts,
  })
  .openapi("LinkServer");

export const LinkServerList = z
  .object({
    items: z.array(LinkServer),
    limit: z.number().int().openapi({ description: "Servers this workspace's plan connects" }),
  })
  .openapi("LinkServerList");

export const AdminLinkServer = LinkServer.extend({
  org_id: Uuid,
  org_name: z.string(),
}).openapi("AdminLinkServer");

export const AdminLinkServerList = z
  .object({
    items: z.array(AdminLinkServer),
    tunnels: z
      .number()
      .int()
      .nullable()
      .openapi({ description: "Tunnels held at the provider, or null when it didn't answer" }),
    zone: z.string(),
  })
  .openapi("AdminLinkServerList");

export const SuspendLinkServerRequest = z
  .object({ reason: z.string().min(1).max(200) })
  .openapi("SuspendLinkServerRequest");

// ---------------------------------------------------------------------------
// On the self-hosted server: its own address
// ---------------------------------------------------------------------------

export const RemoteAccessState = z.string().openapi({
  description:
    "off, starting, online, offline or needs_attention. Treat an unknown value as needs_attention.",
  example: "online",
});

export const RemoteAccessProblem = z.string().openapi({
  description:
    "Where it stops: not_linked, cloud_unreachable, key_rejected, suspended, removed, plan_limit, unknown_server, address_changed, connector_missing, connector_blocked (the connector runs but its network blocks the tunnel, outbound port 7844) or address_unanswered (everything looks connected, yet the address doesn't answer from outside). More may be added.",
  example: "connector_blocked",
});

export const RemoteAccessStatus = z
  .object({
    state: RemoteAccessState,
    address: z.string().nullable().openapi({ description: "The public address, when it is on" }),
    pages_address: z.string().nullable(),
    local_address: z
      .string()
      .nullable()
      .openapi({ description: "The address on the server's own machine" }),
    linked: z.boolean().openapi({ description: "Whether the server has a link to Casama Cloud" }),
    problem: RemoteAccessProblem.nullable(),
    connections: z
      .number()
      .int()
      .nullable()
      .openapi({ description: "Connections the connector holds; null when it couldn't be asked" }),
    checked_at: ts.nullable(),
    push: z.string().optional().openapi({
      description:
        "How notifications reach the store apps: own (this server's own Firebase key), relay (through Casama Cloud) or off.",
      example: "relay",
    }),
    private_notifications: z.boolean().optional().openapi({
      description:
        "On: the relay is given no text (the phone shows New activity) and the app loads it from this server.",
    }),
    invites: z.boolean().optional().openapi({
      description:
        "Whether invited people can make an account while remote access is on. Off: sign-ups are closed.",
    }),
    live_view: z.string().optional().openapi({
      description:
        "Live video for people away from the server's machine, which goes through a relay at Casama Cloud: included (the linked workspace's plan has it) or plan (it comes with a higher plan; they see screenshots). Absent when it isn't known. More values may be added.",
      example: "included",
    }),
  })
  .openapi("RemoteAccessStatus");

export const SetRemoteAccessSettingsRequest = z
  .object({ private_notifications: z.boolean() })
  .openapi("SetRemoteAccessSettingsRequest");

// ---------------------------------------------------------------------------
// Scan to sign in (any server)
// ---------------------------------------------------------------------------

export const SignInCode = z
  .object({
    code: z
      .string()
      .openapi({ description: "Shown once, inside the QR code; valid a few minutes" }),
    expires_at: ts,
    server_url: z.string().openapi({ description: "The address a phone uses for this server" }),
    reachable: z.boolean().openapi({
      description:
        "false when that address only works on this machine or network; a phone elsewhere needs remote access turned on first",
    }),
    pair_url: z
      .string()
      .openapi({ description: "What the QR code holds: a link that opens the app with the code" }),
  })
  .openapi("SignInCode");

export const RedeemSignInCodeRequest = z
  .object({
    code: z.string().min(20).max(200),
    device_name: z.string().max(80).optional(),
  })
  .openapi("RedeemSignInCodeRequest");

export const RedeemedSignInCode = z
  .object({
    token_hash: z.string().openapi({
      description: "Finish with Auth's verify (type magiclink) to get this device its own session",
    }),
    email: z.string(),
  })
  .openapi("RedeemedSignInCode");
