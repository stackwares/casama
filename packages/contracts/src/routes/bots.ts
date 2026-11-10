import { createRoute, z } from "@hono/zod-openapi";
import {
  Bot,
  ChatGptSignInCompleteRequest,
  ChatGptSignInStart,
  ChatGptSignInStartRequest,
  Conversation,
  CreateBotRequest,
  CreateConversationRequest,
  CreateCredentialRequest,
  Credential,
  CredentialTestResult,
  Memory,
  ModelOptionList,
  Run,
  RunEventsPage,
  SendMessageRequest,
  SendMessageResponse,
  EditMessageRequest,
  SwitchBranchRequest,
  SwitchBranchResponse,
  StartSetupResponse,
  StartWelcomeRequest,
  WelcomeChat,
  TestCredentialRequest,
  UpdateCredentialRequest,
  UsageReport,
} from "../bots.ts";
import { IdempotencyKeyHeader, jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;
const list = <T extends z.ZodType>(name: string, item: T) =>
  z.object({ items: z.array(item) }).openapi(name);
const idParam = z.object({ id: Uuid });

export const createBot = createRoute({
  operationId: "createBot",
  method: "post",
  path: "/v1/bots",
  tags: ["bots"],
  security,
  request: { headers: IdempotencyKeyHeader, body: jsonBody(CreateBotRequest) },
  responses: { 201: jsonResponse("Created", Bot), 400: e400, 401: e401, 403: e403, 404: e404 },
});

export const listBots = createRoute({
  operationId: "listBots",
  method: "get",
  path: "/v1/bots",
  tags: ["bots"],
  security,
  request: {
    query: z.object({
      org_id: Uuid,
      archived: z
        .enum(["true", "false"])
        .optional()
        .openapi({ description: "true lists only archived bots (default: active bots)" }),
    }),
  },
  responses: { 200: jsonResponse("Bots you can access", list("BotList", Bot)), 401: e401 },
});

export const createConversation = createRoute({
  operationId: "createConversation",
  method: "post",
  path: "/v1/conversations",
  tags: ["chat"],
  security,
  request: { headers: IdempotencyKeyHeader, body: jsonBody(CreateConversationRequest) },
  responses: { 201: jsonResponse("Created", Conversation), 400: e400, 401: e401, 404: e404 },
});

export const listConversations = createRoute({
  operationId: "listConversations",
  method: "get",
  path: "/v1/bots/{id}/conversations",
  tags: ["chat"],
  security,
  request: { params: idParam },
  responses: {
    200: jsonResponse("Newest first", list("ConversationList", Conversation)),
    401: e401,
    404: e404,
  },
});

export const sendMessage = createRoute({
  operationId: "sendMessage",
  method: "post",
  path: "/v1/conversations/{id}/messages",
  tags: ["chat"],
  security,
  summary: "Send a message; starts a run",
  request: { params: idParam, headers: IdempotencyKeyHeader, body: jsonBody(SendMessageRequest) },
  responses: {
    202: jsonResponse("Run started", SendMessageResponse),
    400: e400,
    401: e401,
    404: e404,
  },
});

export const getRun = createRoute({
  operationId: "getRun",
  method: "get",
  path: "/v1/runs/{id}",
  tags: ["runs"],
  security,
  request: { params: idParam },
  responses: { 200: jsonResponse("Run", Run), 401: e401, 404: e404 },
});

export const listRunEvents = createRoute({
  operationId: "listRunEvents",
  method: "get",
  path: "/v1/runs/{id}/events",
  tags: ["runs"],
  security,
  summary:
    "Events after a seq. Send Accept: text/event-stream to keep streaming live events (SSE).",
  request: {
    params: idParam,
    query: z.object({
      after_seq: z.coerce.number().int().min(0).optional(),
      limit: z.coerce.number().int().min(1).max(1000).optional(),
    }),
  },
  responses: {
    200: {
      description: "Events in seq order (JSON), or a server-sent event stream",
      content: {
        "application/json": { schema: RunEventsPage },
        "text/event-stream": {
          schema: z.string().openapi({ description: "event: run_event, data: RunEventEnvelope" }),
        },
      },
    },
    401: e401,
    404: e404,
  },
});

export const cancelRun = createRoute({
  operationId: "cancelRun",
  method: "post",
  path: "/v1/runs/{id}/cancel",
  tags: ["runs"],
  security,
  summary: "Cancel a run and its subruns",
  request: { params: idParam },
  responses: { 202: jsonResponse("Cancellation requested", Run), 401: e401, 404: e404, 409: e409 },
});

export const createCredential = createRoute({
  operationId: "createCredential",
  method: "post",
  path: "/v1/credentials",
  tags: ["credentials"],
  security,
  summary: "Store a model key in Vault; returns metadata only",
  request: { headers: IdempotencyKeyHeader, body: jsonBody(CreateCredentialRequest) },
  responses: {
    201: jsonResponse("Created", Credential),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const listCredentials = createRoute({
  operationId: "listCredentials",
  method: "get",
  path: "/v1/credentials",
  tags: ["credentials"],
  security,
  request: { query: z.object({ org_id: Uuid }) },
  responses: {
    200: jsonResponse("Credential metadata", list("CredentialList", Credential)),
    401: e401,
  },
});

export const testCredential = createRoute({
  operationId: "testCredential",
  method: "post",
  path: "/v1/credentials/{id}/test",
  tags: ["credentials"],
  security,
  summary: "Validate a key with a 1-token call",
  request: { params: idParam, body: { ...jsonBody(TestCredentialRequest), required: false } },
  responses: {
    200: jsonResponse("Result", CredentialTestResult),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const listCredentialModels = createRoute({
  operationId: "listCredentialModels",
  method: "get",
  path: "/v1/credentials/{id}/models",
  tags: ["credentials"],
  security,
  summary: "Models this key can use, recommended ones first",
  request: { params: idParam },
  responses: {
    200: jsonResponse("Models", ModelOptionList),
    401: e401,
    404: e404,
  },
});

export const updateCredential = createRoute({
  operationId: "updateCredential",
  method: "patch",
  path: "/v1/credentials/{id}",
  tags: ["credentials"],
  security,
  summary: "Rename a credential or change its settings",
  request: { params: idParam, body: jsonBody(UpdateCredentialRequest) },
  responses: {
    200: jsonResponse("Updated", Credential),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const deleteCredential = createRoute({
  operationId: "deleteCredential",
  method: "delete",
  path: "/v1/credentials/{id}",
  tags: ["credentials"],
  security,
  summary: "Delete a credential and its Vault secret (a ChatGPT sign-in is revoked first)",
  request: { params: idParam },
  responses: {
    204: { description: "Deleted" },
    401: e401,
    403: e403,
    404: e404,
  },
});

export const startChatGptSignIn = createRoute({
  operationId: "startChatGptSignIn",
  method: "post",
  path: "/v1/credentials/chatgpt/start",
  tags: ["credentials"],
  security,
  summary: "Begin ChatGPT sign-in; returns the authorize URL for a loopback callback",
  request: { body: jsonBody(ChatGptSignInStartRequest) },
  responses: {
    200: jsonResponse("Sign-in started", ChatGptSignInStart),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const completeChatGptSignIn = createRoute({
  operationId: "completeChatGptSignIn",
  method: "post",
  path: "/v1/credentials/chatgpt/complete",
  tags: ["credentials"],
  security,
  summary: "Finish ChatGPT sign-in; the server exchanges the code and keeps the tokens in Vault",
  request: { body: jsonBody(ChatGptSignInCompleteRequest) },
  responses: {
    200: jsonResponse("Connected", Credential),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const listMemories = createRoute({
  operationId: "listMemories",
  method: "get",
  path: "/v1/bots/{id}/memories",
  tags: ["memory"],
  security,
  request: { params: idParam, query: z.object({ q: z.string().max(500).optional() }) },
  responses: {
    200: jsonResponse("Memories, pinned first", list("MemoryList", Memory)),
    401: e401,
    404: e404,
  },
});

export const getUsage = createRoute({
  operationId: "getUsage",
  method: "get",
  path: "/v1/usage",
  tags: ["usage"],
  security,
  request: {
    query: z.object({ org_id: Uuid, period: z.enum(["day", "week", "month", "year"]).optional() }),
  },
  responses: { 200: jsonResponse("Usage and cost by bot", UsageReport), 401: e401, 404: e404 },
});

export const startBotSetup = createRoute({
  operationId: "startBotSetup",
  method: "post",
  path: "/v1/bots/{id}/setup",
  tags: ["bots"],
  security,
  summary: "Start (or rerun) the bot's setup interview in a new conversation",
  request: { params: idParam },
  responses: { 201: jsonResponse("Started", StartSetupResponse), 401: e401, 403: e403, 404: e404 },
});

export const editMessage = createRoute({
  operationId: "editMessage",
  method: "post",
  path: "/v1/conversations/{id}/messages/{message_id}/edit",
  tags: ["chat"],
  security,
  summary: "Edit a sent message: forks the conversation there and reruns it (the old branch stays)",
  request: {
    params: z.object({ id: Uuid, message_id: Uuid }),
    body: jsonBody(EditMessageRequest),
  },
  responses: {
    202: jsonResponse("Run started", SendMessageResponse),
    400: e400,
    401: e401,
    404: e404,
    409: e409,
  },
});

export const switchBranch = createRoute({
  operationId: "switchBranch",
  method: "post",
  path: "/v1/conversations/{id}/branch",
  tags: ["chat"],
  security,
  summary: "Show another branch of the conversation (its newest message under the given one)",
  request: { params: idParam, body: jsonBody(SwitchBranchRequest) },
  responses: { 200: jsonResponse("Head", SwitchBranchResponse), 401: e401, 404: e404 },
});

export const listGroupChats = createRoute({
  operationId: "listGroupChats",
  method: "get",
  path: "/v1/group-chats",
  tags: ["chat"],
  security,
  summary: "Group chats in a workspace that you can see (D-118)",
  request: { query: z.object({ org_id: Uuid }) },
  responses: { 200: jsonResponse("Group chats", list("GroupChatList", Conversation)), 401: e401 },
});

export const startWelcome = createRoute({
  operationId: "startWelcome",
  method: "post",
  path: "/v1/welcome",
  tags: ["bots"],
  security: [{ bearerAuth: [] }],
  summary: "A new person's personal workspace, bot and welcome chat (D-129); the same chat again if it exists",
  request: { body: jsonBody(StartWelcomeRequest) },
  responses: {
    200: jsonResponse("Welcome chat", WelcomeChat),
    401: problemResponses[401],
    409: problemResponses[409],
  },
});
