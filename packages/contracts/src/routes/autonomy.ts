import { createRoute, z } from "@hono/zod-openapi";
import {
  Approval,
  ApprovalDecisionRequest,
  AttachIntegrationRequest,
  CreatedRoutine,
  CreateIntegrationRequest,
  CreateRoutineRequest,
  CreateSecretRequest,
  CreateTaskCommentRequest,
  CreateTaskRequest,
  Integration,
  IntegrationTestResult,
  Routine,
  Secret,
  Task,
  TaskComment,
  Template,
  UpdateRoutineRequest,
  UpdateTaskRequest,
} from "../autonomy.ts";
import { IdempotencyKeyHeader, jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;
const list = <T extends z.ZodType>(name: string, item: T) =>
  z.object({ items: z.array(item) }).openapi(name);
const idParam = z.object({ id: Uuid });
const orgQuery = z.object({ org_id: Uuid });

export const listApprovals = createRoute({
  operationId: "listApprovals",
  method: "get",
  path: "/v1/approvals",
  tags: ["approvals"],
  security,
  request: {
    query: orgQuery.extend({
      status: z.enum(["pending", "approved", "denied", "expired"]).optional(),
    }),
  },
  responses: { 200: jsonResponse("Newest first", list("ApprovalList", Approval)), 401: e401 },
});

export const decideApproval = createRoute({
  operationId: "decideApproval",
  method: "post",
  path: "/v1/approvals/{id}/decision",
  tags: ["approvals"],
  security,
  summary: "Approve or deny; denying cancels that step only",
  request: { params: idParam, body: jsonBody(ApprovalDecisionRequest) },
  responses: { 200: jsonResponse("Decided", Approval), 401: e401, 404: e404, 409: e409 },
});

export const listSecrets = createRoute({
  operationId: "listSecrets",
  method: "get",
  path: "/v1/secrets",
  tags: ["secrets"],
  security,
  request: { query: orgQuery },
  responses: { 200: jsonResponse("Secret metadata", list("SecretList", Secret)), 401: e401 },
});

export const createSecret = createRoute({
  operationId: "createSecret",
  method: "post",
  path: "/v1/secrets",
  tags: ["secrets"],
  security,
  summary: "Create a named secret with allowed hosts (value stored in Vault)",
  request: { headers: IdempotencyKeyHeader, body: jsonBody(CreateSecretRequest) },
  responses: { 201: jsonResponse("Created", Secret), 400: e400, 401: e401, 403: e403, 409: e409 },
});

export const deleteSecret = createRoute({
  operationId: "deleteSecret",
  method: "delete",
  path: "/v1/secrets/{id}",
  tags: ["secrets"],
  security,
  request: { params: idParam },
  responses: {
    200: jsonResponse("Deleted", z.object({ deleted: Uuid }).openapi("DeletedId")),
    401: e401,
    403: e403,
    404: e404,
  },
});

export const listIntegrations = createRoute({
  operationId: "listIntegrations",
  method: "get",
  path: "/v1/integrations",
  tags: ["integrations"],
  security,
  request: { query: orgQuery },
  responses: { 200: jsonResponse("Integrations", list("IntegrationList", Integration)), 401: e401 },
});

export const createIntegration = createRoute({
  operationId: "createIntegration",
  method: "post",
  path: "/v1/integrations",
  tags: ["integrations"],
  security,
  summary: "Add an MCP server, OpenAPI source, Composio or Pipedream Connect",
  request: { headers: IdempotencyKeyHeader, body: jsonBody(CreateIntegrationRequest) },
  responses: {
    201: jsonResponse("Created", Integration),
    400: e400,
    401: e401,
    403: e403,
    409: e409,
  },
});

export const testIntegration = createRoute({
  operationId: "testIntegration",
  method: "post",
  path: "/v1/integrations/{id}/test",
  tags: ["integrations"],
  security,
  summary: "List tools to prove the connection works (refreshes the tool cache)",
  request: { params: idParam },
  responses: {
    200: jsonResponse("Result", IntegrationTestResult),
    401: e401,
    403: e403,
    404: e404,
  },
});

export const attachIntegration = createRoute({
  operationId: "attachIntegration",
  method: "post",
  path: "/v1/bots/{id}/integrations",
  tags: ["integrations"],
  security,
  summary: "Let a bot use an integration's tools (optionally only some)",
  request: { params: idParam, body: jsonBody(AttachIntegrationRequest) },
  responses: {
    200: jsonResponse("Attached", z.object({ ok: z.boolean() }).openapi("Ok")),
    400: e400,
    401: e401,
    404: e404,
  },
});

export const listRoutines = createRoute({
  operationId: "listRoutines",
  method: "get",
  path: "/v1/bots/{id}/routines",
  tags: ["routines"],
  security,
  request: { params: idParam },
  responses: { 200: jsonResponse("Routines", list("RoutineList", Routine)), 401: e401, 404: e404 },
});

export const createRoutine = createRoute({
  operationId: "createRoutine",
  method: "post",
  path: "/v1/routines",
  tags: ["routines"],
  security,
  summary: "Schedule a routine (cron in a timezone) or create a GitHub/custom webhook trigger",
  request: { headers: IdempotencyKeyHeader, body: jsonBody(CreateRoutineRequest) },
  responses: { 201: jsonResponse("Created", CreatedRoutine), 400: e400, 401: e401, 404: e404 },
});

export const updateRoutine = createRoute({
  operationId: "updateRoutine",
  method: "patch",
  path: "/v1/routines/{id}",
  tags: ["routines"],
  security,
  request: { params: idParam, body: jsonBody(UpdateRoutineRequest) },
  responses: { 200: jsonResponse("Updated", Routine), 400: e400, 401: e401, 404: e404 },
});

export const deleteRoutine = createRoute({
  operationId: "deleteRoutine",
  method: "delete",
  path: "/v1/routines/{id}",
  tags: ["routines"],
  security,
  summary: "Delete a routine (its past runs and conversation are kept)",
  request: { params: idParam },
  responses: {
    200: jsonResponse("Deleted", z.object({ deleted: Uuid }).openapi("DeletedRoutine")),
    401: e401,
    404: e404,
  },
});

export const runRoutine = createRoute({
  operationId: "runRoutine",
  method: "post",
  path: "/v1/routines/{id}/run",
  tags: ["routines"],
  security,
  summary: "Run a routine now",
  request: { params: idParam },
  responses: {
    202: jsonResponse("Started", z.object({ run_id: Uuid }).openapi("RunStarted")),
    401: e401,
    404: e404,
  },
});

export const listTemplates = createRoute({
  operationId: "listTemplates",
  method: "get",
  path: "/v1/templates",
  tags: ["bots"],
  security,
  responses: { 200: jsonResponse("Starter bots", list("TemplateList", Template)), 401: e401 },
});

export const listTasks = createRoute({
  operationId: "listTasks",
  method: "get",
  path: "/v1/tasks",
  tags: ["tasks"],
  security,
  request: { query: orgQuery },
  responses: { 200: jsonResponse("The shared task board", list("TaskList", Task)), 401: e401 },
});

export const createTask = createRoute({
  operationId: "createTask",
  method: "post",
  path: "/v1/tasks",
  tags: ["tasks"],
  security,
  summary: "Create a ticket; assigning a bot starts its work",
  request: { body: jsonBody(CreateTaskRequest) },
  responses: { 201: jsonResponse("Created", Task), 400: e400, 401: e401, 404: e404 },
});

export const updateTask = createRoute({
  operationId: "updateTask",
  method: "patch",
  path: "/v1/tasks/{id}",
  tags: ["tasks"],
  security,
  summary: "Change a ticket (moving, reassigning, editing); a newly assigned bot starts its work",
  request: { params: idParam, body: jsonBody(UpdateTaskRequest) },
  responses: { 200: jsonResponse("Updated", Task), 400: e400, 401: e401, 404: e404 },
});

export const deleteTask = createRoute({
  operationId: "deleteTask",
  method: "delete",
  path: "/v1/tasks/{id}",
  tags: ["tasks"],
  security,
  request: { params: idParam },
  responses: { 204: { description: "Deleted" }, 401: e401, 404: e404 },
});

export const listTaskComments = createRoute({
  operationId: "listTaskComments",
  method: "get",
  path: "/v1/tasks/{id}/comments",
  tags: ["tasks"],
  security,
  request: { params: idParam },
  responses: {
    200: jsonResponse("Comments, oldest first", list("TaskCommentList", TaskComment)),
    401: e401,
    404: e404,
  },
});

export const createTaskComment = createRoute({
  operationId: "createTaskComment",
  method: "post",
  path: "/v1/tasks/{id}/comments",
  tags: ["tasks"],
  security,
  summary: "Comment on a ticket; a comment on a bot's ticket wakes that bot",
  request: { params: idParam, body: jsonBody(CreateTaskCommentRequest) },
  responses: { 201: jsonResponse("Posted", TaskComment), 400: e400, 401: e401, 404: e404 },
});

const webhook = (kind: "github" | "custom") =>
  createRoute({
    operationId: kind === "github" ? "githubWebhook" : "customWebhook",
    method: "post",
    path: `/hooks/${kind}/{routine_id}`,
    tags: ["webhooks"],
    summary:
      kind === "github"
        ? "GitHub webhook for a routine (X-Hub-Signature-256)"
        : "Custom webhook for a routine (X-Kasama-Signature: sha256=HMAC-SHA256 of the body)",
    request: { params: z.object({ routine_id: Uuid }) },
    responses: {
      202: jsonResponse(
        "Accepted for verification",
        z.object({ accepted: z.boolean() }).openapi("Accepted"),
      ),
      413: { description: "Body too large" },
    },
  });
export const githubWebhook = webhook("github");
export const customWebhook = webhook("custom");
