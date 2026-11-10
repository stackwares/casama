import { createRoute, z } from "@hono/zod-openapi";
import { jsonResponse } from "../common.ts";
import { PublicConfig, SignupChallenge } from "../workspaces.ts";

const Health = z
  .object({
    status: z.enum(["ok", "degraded"]),
    checks: z.record(z.string(), z.string()).optional(),
  })
  .openapi("Health");

export const healthz = createRoute({
  operationId: "healthz",
  method: "get",
  path: "/healthz",
  tags: ["system"],
  responses: { 200: jsonResponse("Process is up", Health) },
});

export const readyz = createRoute({
  operationId: "readyz",
  method: "get",
  path: "/readyz",
  tags: ["system"],
  responses: {
    200: jsonResponse("Dependencies reachable", Health),
    503: jsonResponse("Not ready", Health),
  },
});

export const getConfig = createRoute({
  operationId: "getConfig",
  method: "get",
  path: "/v1/config",
  tags: ["system"],
  summary: "Public client configuration (no auth)",
  responses: { 200: jsonResponse("Client configuration", PublicConfig) },
});

export const getSignupChallenge = createRoute({
  operationId: "getSignupChallenge",
  method: "get",
  path: "/v1/signup/challenge",
  tags: ["system"],
  summary: "A proof-of-work puzzle for signing up when the server asks for one (no auth)",
  responses: { 200: jsonResponse("Challenge", SignupChallenge) },
});
