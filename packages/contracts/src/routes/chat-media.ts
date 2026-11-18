import { createRoute, z } from "@hono/zod-openapi";
import { problemResponses } from "../common.ts";

/**
 * Files sent in chats (pictures, videos, sound, documents): the bytes behind a message's media_id.
 * Served by apps/server/src/api/routes/chat-media.ts to members of the file's workspace; anyone else
 * gets a 404. The id is checked by the handler, so a malformed one is a 404 too, not a 400.
 */
const security = [{ bearerAuth: [] }];
const { 401: e401, 404: e404 } = problemResponses;
const idParam = z.object({ id: z.string().openapi({ format: "uuid" }) });
const binary = (types: string[]) =>
  Object.fromEntries(types.map((t) => [t, { schema: z.string().openapi({ format: "binary" }) }]));

export const getChatMedia = createRoute({
  operationId: "getChatMedia",
  method: "get",
  path: "/v1/media/{id}",
  tags: ["chat"],
  security,
  summary:
    "A chat file's bytes, in its own content type; one byte range honoured (cached for good)",
  request: {
    params: idParam,
    headers: z.object({
      range: z.string().optional().openapi({ description: "One byte range, e.g. bytes=0-1023" }),
    }),
  },
  responses: {
    200: { description: "The file", content: binary(["application/octet-stream"]) },
    206: { description: "A byte range", content: binary(["application/octet-stream"]) },
    401: e401,
    404: e404,
    416: { description: "The range is outside the file" },
  },
});

export const getChatMediaPoster = createRoute({
  operationId: "getChatMediaPoster",
  method: "get",
  path: "/v1/media/{id}/poster",
  tags: ["chat"],
  security,
  summary:
    "A video's poster (a JPEG still) for its chat card; 404 for other files (cached for good)",
  request: { params: idParam },
  responses: {
    200: { description: "Poster", content: binary(["image/jpeg"]) },
    401: e401,
    404: e404,
  },
});

const UploadedMedia = z
  .object({
    id: z.string().openapi({ format: "uuid" }),
    path: z.string().openapi({
      description: "Put this in a message attachment's path: media:<id>. No computer is needed",
      example: "media:2f6c…",
    }),
    name: z.string(),
    mime_type: z.string(),
    size: z.number().int(),
    creation_id: z
      .string()
      .openapi({ format: "uuid", description: "The Library item, when saved to the Library" })
      .nullable(),
  })
  .openapi("UploadedMedia");

/**
 * Casama for Chrome (D-323): a picture or file sent from the browser, kept with the chat instead
 * of on the bot's computer, so asking about a screenshot never wakes a computer. `library`
 * saves it to the Library instead (Save to Library); `convert=pdf` prints an HTML body as PDF
 * first where the server can.
 */
export const uploadMedia = createRoute({
  operationId: "uploadMedia",
  method: "post",
  path: "/v1/media",
  tags: ["chat"],
  security,
  summary:
    "Upload a picture or file for a message (media:<id>), or save one to the Library; the body is the raw bytes",
  request: {
    query: z.object({
      org_id: z.uuid(),
      name: z.string().min(1).max(200),
      purpose: z.enum(["attachment", "library"]).default("attachment"),
      convert: z.enum(["pdf"]).optional().openapi({ description: "Print an HTML body as PDF" }),
      project_id: z
        .uuid()
        .optional()
        .openapi({ format: "uuid", description: "File the Library item under this project" }),
    }),
    body: {
      content: binary(["application/octet-stream", "image/png", "image/jpeg", "text/html"]),
      required: true,
    },
  },
  responses: {
    201: {
      description: "Stored",
      content: { "application/json": { schema: UploadedMedia } },
    },
    400: problemResponses[400],
    401: e401,
    404: e404,
    409: problemResponses[409],
    429: problemResponses[429],
  },
});
