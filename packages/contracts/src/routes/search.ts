import { createRoute, z } from "@hono/zod-openapi";
import { jsonResponse, problemResponses, Uuid } from "../common.ts";
import { SearchResponse } from "../search.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401 } = problemResponses;

export const search = createRoute({
  operationId: "search",
  method: "get",
  path: "/v1/search",
  tags: ["search"],
  security,
  summary: "Search messages, chats, memories, skills, routines, tickets and files in a workspace",
  request: {
    query: z.object({
      org_id: Uuid,
      q: z.string().min(2).max(200),
      files: z.enum(["true", "false"]).optional().openapi({
        description: "Also search file names and contents on awake computers (default true)",
      }),
      kinds: z
        .string()
        .regex(
          /^(message|chat|memory|skill|routine|ticket|file)(,(message|chat|memory|skill|routine|ticket|file))*$/,
        )
        .optional()
        .openapi({
          description:
            "Only these kinds, comma-separated (message, chat, memory, skill, routine, ticket, file). A scoped search returns up to 25 of each kind instead of 8; files are searched only when `file` is listed.",
        }),
    }),
  },
  responses: { 200: jsonResponse("Results grouped by kind", SearchResponse), 400: e400, 401: e401 },
});
