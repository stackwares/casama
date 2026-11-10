import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  ApplySkillUpdateRequest,
  GitHubSkillPreview,
  GitHubSkillPreviewRequest,
  InstallCatalogSkillRequest,
  InstalledSkill,
  InstallGitHubSkillRequest,
  SkillCatalog,
  SkillUpdateCheck,
} from "../skills.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409 } = problemResponses;
const idParam = z.object({ id: Uuid });

export const getSkillCatalog = createRoute({
  operationId: "getSkillCatalog",
  method: "get",
  path: "/v1/skills/catalog",
  tags: ["skills"],
  security,
  summary: "The curated skills that ship with this server",
  responses: { 200: jsonResponse("Catalog", SkillCatalog), 401: e401 },
});

export const installCatalogSkill = createRoute({
  operationId: "installCatalogSkill",
  method: "post",
  path: "/v1/skills/install",
  tags: ["skills"],
  security,
  summary: "Install a catalog skill to the workspace (admins) or one bot (its managers)",
  request: { body: jsonBody(InstallCatalogSkillRequest) },
  responses: {
    201: jsonResponse("Installed", InstalledSkill),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const previewGitHubSkill = createRoute({
  operationId: "previewGitHubSkill",
  method: "post",
  path: "/v1/skills/github/preview",
  tags: ["skills"],
  security,
  summary:
    "Read a skill folder from GitHub at its latest commit and show its files before installing",
  request: { body: jsonBody(GitHubSkillPreviewRequest) },
  responses: { 200: jsonResponse("Preview", GitHubSkillPreview), 400: e400, 401: e401, 404: e404 },
});

export const installGitHubSkill = createRoute({
  operationId: "installGitHubSkill",
  method: "post",
  path: "/v1/skills/github/install",
  tags: ["skills"],
  security,
  summary: "Install a GitHub skill pinned to the previewed commit",
  request: { body: jsonBody(InstallGitHubSkillRequest) },
  responses: {
    201: jsonResponse("Installed", InstalledSkill),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const checkSkillUpdate = createRoute({
  operationId: "checkSkillUpdate",
  method: "get",
  path: "/v1/skills/{id}/update",
  tags: ["skills"],
  security,
  summary: "Compare a GitHub skill with its source's latest commit (diff before updating)",
  request: { params: idParam },
  responses: {
    200: jsonResponse("Update check", SkillUpdateCheck),
    400: e400,
    401: e401,
    404: e404,
  },
});

export const applySkillUpdate = createRoute({
  operationId: "applySkillUpdate",
  method: "post",
  path: "/v1/skills/{id}/update",
  tags: ["skills"],
  security,
  summary: "Update a GitHub skill to a newer commit (after reviewing the diff)",
  request: { params: idParam, body: jsonBody(ApplySkillUpdateRequest) },
  responses: {
    200: jsonResponse("Updated", InstalledSkill),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});
