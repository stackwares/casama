import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  CreateGalleryRequest,
  CreateGallerySubmission,
  GalleryAnyKind,
  GalleryApproval,
  GalleryApprovalDecision,
  GalleryApprovalList,
  GalleryAuthorItemList,
  GalleryAuthorList,
  GalleryDetail,
  GalleryInstalledList,
  GalleryInstallRequest,
  GalleryInstallResult,
  GalleryList,
  GalleryPolicy,
  GalleryRequest,
  GalleryRequestList,
  GallerySetInstallRequest,
  GallerySetInstallResult,
  GallerySetList,
  GalleryStatsList,
  GallerySubmission,
  GallerySubmissionList,
  GalleryUpdateRequest,
  GalleryUpdateResult,
  GalleryWorkspaceKind,
  UpdateGalleryRequest,
} from "../gallery.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 409: e409, 429: e429 } = problemResponses;
const e503 = { ...e404, description: "Not available on this server" };

/** Ids may carry an extra catalog's name: `source:id` (D-315). */
const ItemId = z.string().min(1).max(100);

export const listGallery = createRoute({
  operationId: "listGallery",
  method: "get",
  path: "/v1/gallery",
  tags: ["gallery"],
  security,
  summary: "Themes, color schemes, wallpapers and skills from the open gallery (D-184)",
  request: {
    query: z.object({
      type: GalleryAnyKind.optional(),
      kinds: z.enum(["all"]).optional().openapi({
        description: "all: every kind in one list (apps, bots, routines, plugins, sets too, D-315)",
      }),
      q: z.string().max(80).optional(),
      tag: z.string().max(24).optional(),
      featured: z.enum(["true", "false"]).optional(),
    }),
  },
  responses: {
    200: { description: "Gallery", content: { "application/json": { schema: GalleryList } } },
    401: e401,
    404: e404,
  },
});

export const getGalleryItem = createRoute({
  operationId: "getGalleryItem",
  method: "get",
  path: "/v1/gallery/{type}/{id}",
  tags: ["gallery"],
  security,
  summary: "One gallery item, including the document the app applies",
  request: {
    params: z.object({
      type: GalleryAnyKind,
      id: ItemId,
    }),
  },
  responses: {
    200: { description: "Item", content: { "application/json": { schema: GalleryDetail } } },
    401: e401,
    404: e404,
  },
});

// ---------------------------------------------------------------- stats (D-315)

export const getGalleryStats = createRoute({
  operationId: "getGalleryStats",
  method: "get",
  path: "/v1/gallery/stats",
  tags: ["gallery"],
  summary: "How many people use each gallery item, aggregate only (no sign-in)",
  responses: { 200: jsonResponse("Stats", GalleryStatsList) },
});

export const markGalleryItemUsed = createRoute({
  operationId: "markGalleryItemUsed",
  method: "post",
  path: "/v1/gallery/{type}/{id}/used",
  tags: ["gallery"],
  security,
  summary: "Count a look as used on this device (counted once per person, aggregate only)",
  request: {
    params: z.object({ type: z.enum(["theme", "scheme", "wallpaper"]), id: ItemId }),
  },
  responses: { 204: { description: "Counted" }, 400: e400, 401: e401, 429: e429 },
});

export const listGallerySets = createRoute({
  operationId: "listGallerySets",
  method: "get",
  path: "/v1/gallery/sets",
  tags: ["gallery"],
  security,
  summary: "Starter sets: a few gallery items that go well together",
  responses: { 200: jsonResponse("Sets", GallerySetList), 401: e401 },
});

export const listGalleryAuthors = createRoute({
  operationId: "listGalleryAuthors",
  method: "get",
  path: "/v1/gallery/authors",
  tags: ["gallery"],
  security,
  summary: "The gallery's authors and what each made",
  responses: { 200: jsonResponse("Authors", GalleryAuthorList), 401: e401 },
});

// ---------------------------------------------------------------- installed and updates

export const listGalleryInstalled = createRoute({
  operationId: "listGalleryInstalled",
  method: "get",
  path: "/v1/gallery/installed",
  tags: ["gallery"],
  security,
  summary: "What this workspace added from the gallery, with updates and retired items",
  request: { query: z.object({ org_id: Uuid }) },
  responses: {
    200: jsonResponse("Installed", GalleryInstalledList),
    401: e401,
    404: e404,
  },
});

export const updateGalleryInstalled = createRoute({
  operationId: "updateGalleryInstalled",
  method: "post",
  path: "/v1/gallery/installed/update",
  tags: ["gallery"],
  security,
  summary:
    "Update an installed item to the gallery's latest (409 access_changed when it can touch more or is breaking)",
  description:
    '409 access_changed: the Problem\'s `errors` list what\'s new, one entry each: `{path: "reads"|"writes", message: <the added thing>}`, `{path: "runs_code"|"computer"|"breaking", message: "true"}`. Send accept_access: true after the person agrees. The Installed list\'s access_added and breaking say the same up front.',
  request: { body: jsonBody(GalleryUpdateRequest) },
  responses: {
    200: jsonResponse("Updated", GalleryUpdateResult),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

export const removeGalleryInstalled = createRoute({
  operationId: "removeGalleryInstalled",
  method: "delete",
  path: "/v1/gallery/installed/{type}/{id}",
  tags: ["gallery"],
  security,
  summary: "Remove what this workspace added from a gallery item",
  request: {
    params: z.object({ type: GalleryWorkspaceKind, id: ItemId }),
    query: z.object({ org_id: Uuid }),
  },
  responses: { 204: { description: "Removed" }, 401: e401, 403: e403, 404: e404 },
});

// ---------------------------------------------------------------- install with needs and inputs

export const installGalleryItem = createRoute({
  operationId: "installGalleryItem",
  method: "post",
  path: "/v1/gallery/install",
  tags: ["gallery"],
  security,
  summary:
    "Add a gallery item with its install questions; needed skills come along, needed apps come back in missing",
  description:
    "201 installed, or 202 approval_pending (an admin was asked; approval_id set). 400 inputs_invalid: the Problem's `errors` are `{path: <input key>, message}`, one per bad answer. 400 bot_required: a routine or plugin needs bot_id. 403 gallery_blocked: the workspace's rules don't allow it.",
  request: { body: jsonBody(GalleryInstallRequest) },
  responses: {
    201: jsonResponse("Installed", GalleryInstallResult),
    202: jsonResponse("Waiting for an admin to approve", GalleryInstallResult),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const installGallerySet = createRoute({
  operationId: "installGallerySet",
  method: "post",
  path: "/v1/gallery/sets/{id}/install",
  tags: ["gallery"],
  security,
  summary: "Add every workspace item of a starter set",
  request: { params: z.object({ id: ItemId }), body: jsonBody(GallerySetInstallRequest) },
  responses: {
    200: jsonResponse("Per-item results", GallerySetInstallResult),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

// ---------------------------------------------------------------- workspace controls

export const getGalleryPolicy = createRoute({
  operationId: "getGalleryPolicy",
  method: "get",
  path: "/v1/orgs/{id}/gallery-policy",
  tags: ["gallery"],
  security,
  summary: "What members may add from the gallery",
  request: { params: z.object({ id: Uuid }) },
  responses: { 200: jsonResponse("Policy", GalleryPolicy), 401: e401, 404: e404 },
});

export const setGalleryPolicy = createRoute({
  operationId: "setGalleryPolicy",
  method: "put",
  path: "/v1/orgs/{id}/gallery-policy",
  tags: ["gallery"],
  security,
  summary: "Change what members may add from the gallery (owners and admins)",
  request: { params: z.object({ id: Uuid }), body: jsonBody(GalleryPolicy) },
  responses: {
    200: jsonResponse("Policy", GalleryPolicy),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const listGalleryApprovals = createRoute({
  operationId: "listGalleryApprovals",
  method: "get",
  path: "/v1/orgs/{id}/gallery-approvals",
  tags: ["gallery"],
  security,
  summary: "Gallery items members asked to add (admins see all, members their own)",
  request: {
    params: z.object({ id: Uuid }),
    query: z.object({ status: z.enum(["pending", "approved", "denied", "failed"]).optional() }),
  },
  responses: { 200: jsonResponse("Approvals", GalleryApprovalList), 401: e401, 404: e404 },
});

export const decideGalleryApproval = createRoute({
  operationId: "decideGalleryApproval",
  method: "post",
  path: "/v1/gallery-approvals/{id}/decision",
  tags: ["gallery"],
  security,
  summary: "Approve (which adds the item) or deny a gallery request (owners and admins)",
  request: { params: z.object({ id: Uuid }), body: jsonBody(GalleryApprovalDecision) },
  responses: {
    200: jsonResponse("Decided", GalleryApproval),
    401: e401,
    403: e403,
    404: e404,
    409: e409,
  },
});

// ---------------------------------------------------------------- requests board

export const listGalleryRequests = createRoute({
  operationId: "listGalleryRequests",
  method: "get",
  path: "/v1/gallery/requests",
  tags: ["gallery"],
  security,
  summary: "What people asked the gallery to have",
  request: {
    query: z.object({
      sort: z.enum(["top", "new"]).optional(),
      status: z.enum(["open", "planned", "done", "declined"]).optional(),
    }),
  },
  responses: { 200: jsonResponse("Requests", GalleryRequestList), 401: e401 },
});

export const createGalleryRequest = createRoute({
  operationId: "createGalleryRequest",
  method: "post",
  path: "/v1/gallery/requests",
  tags: ["gallery"],
  security,
  summary: "Ask for something the gallery doesn't have (a similar request is returned instead)",
  request: { body: jsonBody(CreateGalleryRequest) },
  responses: {
    200: jsonResponse("A similar request that already exists", GalleryRequest),
    201: jsonResponse("Created", GalleryRequest),
    400: e400,
    401: e401,
    429: e429,
  },
});

export const updateGalleryRequest = createRoute({
  operationId: "updateGalleryRequest",
  method: "patch",
  path: "/v1/gallery/requests/{id}",
  tags: ["gallery"],
  security,
  summary: "Set a request's status (instance owners)",
  request: { params: z.object({ id: Uuid }), body: jsonBody(UpdateGalleryRequest) },
  responses: {
    200: jsonResponse("Request", GalleryRequest),
    401: e401,
    403: e403,
    404: e404,
  },
});

export const voteGalleryRequest = createRoute({
  operationId: "voteGalleryRequest",
  method: "post",
  path: "/v1/gallery/requests/{id}/vote",
  tags: ["gallery"],
  security,
  summary: "Vote for a request",
  request: { params: z.object({ id: Uuid }) },
  responses: { 200: jsonResponse("Request", GalleryRequest), 401: e401, 404: e404 },
});

export const unvoteGalleryRequest = createRoute({
  operationId: "unvoteGalleryRequest",
  method: "delete",
  path: "/v1/gallery/requests/{id}/vote",
  tags: ["gallery"],
  security,
  summary: "Take back a vote",
  request: { params: z.object({ id: Uuid }) },
  responses: { 200: jsonResponse("Request", GalleryRequest), 401: e401, 404: e404 },
});

// ---------------------------------------------------------------- submissions and author stats

export const createGallerySubmission = createRoute({
  operationId: "createGallerySubmission",
  method: "post",
  path: "/v1/gallery/submissions",
  tags: ["gallery"],
  security,
  summary: "Submit a look, skill, routine or bot to the gallery (opens a pull request for review)",
  request: { body: jsonBody(CreateGallerySubmission) },
  responses: {
    201: jsonResponse("Submitted", GallerySubmission),
    400: e400,
    401: e401,
    429: e429,
    503: e503,
  },
});

export const listGallerySubmissions = createRoute({
  operationId: "listGallerySubmissions",
  method: "get",
  path: "/v1/gallery/submissions",
  tags: ["gallery"],
  security,
  summary: "My gallery submissions and their review status",
  responses: { 200: jsonResponse("Submissions", GallerySubmissionList), 401: e401 },
});

export const listMyGalleryItems = createRoute({
  operationId: "listMyGalleryItems",
  method: "get",
  path: "/v1/gallery/me/items",
  tags: ["gallery"],
  security,
  summary: "Gallery items I made (from merged submissions), with their full stats",
  responses: { 200: jsonResponse("My items", GalleryAuthorItemList), 401: e401 },
});
