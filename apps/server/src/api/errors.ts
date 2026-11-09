import type { Problem } from "@kasama/contracts";
import type { Context } from "hono";
import type { ContentfulStatusCode } from "hono/utils/http-status";

const titles: Record<number, string> = {
  400: "Bad Request",
  401: "Unauthorized",
  402: "Payment Required",
  403: "Forbidden",
  404: "Not Found",
  409: "Conflict",
  422: "Unprocessable Content",
  429: "Too Many Requests",
  500: "Internal Server Error",
  503: "Service Unavailable",
};

/** Error with a stable code, rendered as RFC 9457 problem JSON. */
export class ApiError extends Error {
  readonly status: ContentfulStatusCode;
  readonly code: string;
  readonly errors?: Problem["errors"];
  readonly headers?: Record<string, string>;
  constructor(
    status: ContentfulStatusCode,
    code: string,
    detail?: string,
    extra?: { errors?: Problem["errors"]; headers?: Record<string, string> },
  ) {
    super(detail ?? code);
    this.status = status;
    this.code = code;
    this.errors = extra?.errors;
    this.headers = extra?.headers;
  }
}

export function problemBody(
  status: number,
  code: string,
  detail?: string,
  instance?: string,
  errors?: Problem["errors"],
): Problem {
  return {
    type: `https://kasama.dev/problems/${code}`,
    title: titles[status] ?? "Error",
    status,
    code,
    ...(detail ? { detail } : {}),
    ...(instance ? { instance } : {}),
    ...(errors ? { errors } : {}),
  };
}

export function problem(c: Context, err: ApiError) {
  for (const [k, v] of Object.entries(err.headers ?? {})) c.header(k, v);
  c.header("content-type", "application/problem+json");
  return c.body(
    JSON.stringify(
      problemBody(
        err.status,
        err.code,
        err.message === err.code ? undefined : err.message,
        c.req.path,
        err.errors,
      ),
    ),
    err.status,
  );
}
