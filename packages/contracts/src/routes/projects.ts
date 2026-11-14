import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import { CreateProjectRequest, Project, ProjectDetail, UpdateProjectRequest } from "../projects.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;
const idParam = z.object({ id: Uuid });

export const listProjects = createRoute({
  operationId: "listProjects",
  method: "get",
  path: "/v1/projects",
  tags: ["projects"],
  security,
  request: { query: z.object({ org_id: Uuid }) },
  responses: {
    200: jsonResponse("Projects", z.object({ items: z.array(Project) }).openapi("ProjectList")),
    401: e401,
  },
});

export const createProject = createRoute({
  operationId: "createProject",
  method: "post",
  path: "/v1/projects",
  tags: ["projects"],
  security,
  summary:
    "Start a project: one you work on together in its chat, or one its lead bot plans for your approval and then works on by itself",
  request: { body: jsonBody(CreateProjectRequest) },
  responses: { 201: jsonResponse("Created", Project), 400: e400, 401: e401, 403: e403 },
});

export const getProject = createRoute({
  operationId: "getProject",
  method: "get",
  path: "/v1/projects/{id}",
  tags: ["projects"],
  security,
  request: { params: idParam },
  responses: { 200: jsonResponse("Project", ProjectDetail), 401: e401, 404: e404 },
});

export const updateProject = createRoute({
  operationId: "updateProject",
  method: "patch",
  path: "/v1/projects/{id}",
  tags: ["projects"],
  security,
  summary:
    "Pause, resume, cancel or finish a project, change its goal, budget, deadline or plan, or switch working by itself on or off",
  request: { params: idParam, body: jsonBody(UpdateProjectRequest) },
  responses: {
    200: jsonResponse("Project", Project),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const approveProjectPlan = createRoute({
  operationId: "approveProjectPlan",
  method: "post",
  path: "/v1/projects/{id}/plan/approve",
  tags: ["projects"],
  security,
  summary: "Approve the proposed plan; sessions start",
  request: { params: idParam },
  responses: { 200: jsonResponse("Project", Project), 401: e401, 403: e403, 404: e404, 409: e409 },
});

export const signOffMilestone = createRoute({
  operationId: "signOffMilestone",
  method: "post",
  path: "/v1/projects/{id}/milestones/{milestone_id}/signoff",
  tags: ["projects"],
  security,
  summary: "Sign off a finished milestone so the next one begins",
  request: { params: z.object({ id: Uuid, milestone_id: Uuid }) },
  responses: { 200: jsonResponse("Project", Project), 401: e401, 403: e403, 404: e404, 409: e409 },
});
