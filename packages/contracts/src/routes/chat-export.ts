import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";

const security = [{ bearerAuth: [] }];
const { 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;
const idParam = z.object({ id: Uuid });

export const exportConversation = createRoute({
  operationId: "exportConversation",
  method: "get",
  path: "/v1/conversations/{id}/export",
  tags: ["chat"],
  security,
  summary: "Download a chat as Markdown or JSON (D-282)",
  request: {
    params: idParam,
    query: z.object({ format: z.enum(["markdown", "json"]).optional() }),
  },
  responses: {
    200: {
      description: "The chat",
      content: {
        "text/markdown": { schema: z.string() },
        "application/json": { schema: z.object({}).passthrough() },
      },
    },
    401: e401,
    404: e404,
  },
});

export const shareConversation = createRoute({
  operationId: "shareConversation",
  method: "post",
  path: "/v1/conversations/{id}/share",
  tags: ["chat"],
  security,
  summary: "Make or stop a public read-only link to a chat (D-282)",
  description:
    "Only the person who started it or someone who manages its bot. Making it public again gives a new link. A private chat (personal device data) can't be shared: 409.",
  request: {
    params: idParam,
    body: jsonBody(z.object({ public: z.boolean() }).openapi("ShareConversationRequest")),
  },
  responses: {
    200: jsonResponse(
      "Shared",
      z.object({ url: z.string().nullable() }).openapi("ShareConversationResponse"),
    ),
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});
