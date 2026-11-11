import { z } from "@hono/zod-openapi";

export const Uuid = z.uuid();

/** RFC 9457 problem details with a stable machine-readable code. */
export const Problem = z
  .object({
    type: z.string().openapi({ example: "https://casama.ai/problems/not_found" }),
    title: z.string(),
    status: z.number().int(),
    code: z.string().openapi({ description: "Stable error code", example: "not_found" }),
    detail: z.string().optional(),
    instance: z.string().optional(),
    errors: z
      .array(z.object({ path: z.string(), message: z.string() }))
      .optional()
      .openapi({ description: "Field errors for validation_failed" }),
  })
  .openapi("Problem");
export type Problem = z.infer<typeof Problem>;

export const problemResponses = {
  400: {
    description: "Validation failed",
    content: { "application/problem+json": { schema: Problem } },
  },
  401: {
    description: "Not authenticated",
    content: { "application/problem+json": { schema: Problem } },
  },
  403: { description: "Forbidden", content: { "application/problem+json": { schema: Problem } } },
  404: { description: "Not found", content: { "application/problem+json": { schema: Problem } } },
  409: { description: "Conflict", content: { "application/problem+json": { schema: Problem } } },
  429: {
    description: "Rate limited",
    content: { "application/problem+json": { schema: Problem } },
  },
} as const;

export const IdempotencyKeyHeader = z.object({
  "idempotency-key": z
    .string()
    .max(255)
    .optional()
    .openapi({ description: "Retries with the same key return the first result" }),
});

export const jsonBody = <T extends z.ZodType>(schema: T) => ({
  content: { "application/json": { schema } },
  required: true,
});
export const jsonResponse = <T extends z.ZodType>(description: string, schema: T) => ({
  description,
  content: { "application/json": { schema } },
});
