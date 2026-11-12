import { createRoute, z } from "@hono/zod-openapi";
import {
  AboutYou,
  ImportProfilePhotoRequest,
  SetProfilePhotoRequest,
  UpdateAboutYouRequest,
  UserFact,
} from "../about-you.ts";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";

/**
 * About you (D-169): one profile per person that every bot reads. It goes through the API, not
 * straight to Supabase, because its text is sealed with the person's own key when they belong to a
 * workspace that encrypts (D-136).
 */
const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 404: e404 } = problemResponses;

const FactList = z.object({ items: z.array(UserFact) }).openapi("UserFactList");

export const getAboutYou = createRoute({
  operationId: "getAboutYou",
  method: "get",
  path: "/v1/me/about",
  tags: ["about-you"],
  security,
  summary: "What bots call you and what you shared about yourself",
  responses: { 200: jsonResponse("About you", AboutYou), 401: e401 },
});

export const updateAboutYou = createRoute({
  operationId: "updateAboutYou",
  method: "patch",
  path: "/v1/me/about",
  tags: ["about-you"],
  security,
  request: { body: jsonBody(UpdateAboutYouRequest) },
  responses: { 200: jsonResponse("About you", AboutYou), 400: e400, 401: e401 },
});

export const listUserFacts = createRoute({
  operationId: "listUserFacts",
  method: "get",
  path: "/v1/me/facts",
  tags: ["about-you"],
  security,
  summary: "Facts bots learned about you, pinned and newest first",
  responses: { 200: jsonResponse("Facts", FactList), 401: e401 },
});

export const addUserFacts = createRoute({
  operationId: "addUserFacts",
  method: "post",
  path: "/v1/me/facts",
  tags: ["about-you"],
  security,
  request: {
    body: jsonBody(
      z
        .object({
          items: z
            .array(
              z.object({
                kind: z.enum(["fact", "preference"]).optional(),
                content: z.string().min(1).max(500),
              }),
            )
            .min(1)
            .max(200),
        })
        .openapi("AddUserFactsRequest"),
    ),
  },
  responses: { 200: jsonResponse("Added", FactList), 400: e400, 401: e401 },
});

export const updateUserFact = createRoute({
  operationId: "updateUserFact",
  method: "patch",
  path: "/v1/me/facts/{id}",
  tags: ["about-you"],
  security,
  request: {
    params: z.object({ id: Uuid }),
    body: jsonBody(
      z
        .object({ content: z.string().min(1).max(500).optional(), pinned: z.boolean().optional() })
        .openapi("UpdateUserFactRequest"),
    ),
  },
  responses: { 200: jsonResponse("Fact", UserFact), 400: e400, 401: e401, 404: e404 },
});

export const deleteUserFact = createRoute({
  operationId: "deleteUserFact",
  method: "delete",
  path: "/v1/me/facts/{id}",
  tags: ["about-you"],
  security,
  request: { params: z.object({ id: Uuid }) },
  responses: {
    200: jsonResponse("Deleted", z.object({ deleted: Uuid }).openapi("DeletedUserFact")),
    401: e401,
    404: e404,
  },
});

const ProfileSpace = z.object({ org_id: Uuid, shared: z.boolean() }).openapi("ProfileSpace");

export const getProfileSpace = createRoute({
  operationId: "getProfileSpace",
  method: "get",
  path: "/v1/me/profile-spaces/{org_id}",
  tags: ["about-you"],
  security,
  summary: "Whether bots in this workspace use About me and learned facts",
  request: { params: z.object({ org_id: Uuid }) },
  responses: { 200: jsonResponse("Sharing", ProfileSpace), 401: e401, 404: e404 },
});

export const setProfileSpace = createRoute({
  operationId: "setProfileSpace",
  method: "put",
  path: "/v1/me/profile-spaces/{org_id}",
  tags: ["about-you"],
  security,
  request: {
    params: z.object({ org_id: Uuid }),
    body: jsonBody(z.object({ shared: z.boolean() }).openapi("SetProfileSpaceRequest")),
  },
  responses: { 200: jsonResponse("Sharing", ProfileSpace), 400: e400, 401: e401, 404: e404 },
});

// Profile photo (D-202). Each change returns About you with the new photo_id. The picture itself
// is served at GET /v1/photos/{id} (no token, cached for good: a new photo gets a new id).
export const setProfilePhoto = createRoute({
  operationId: "setProfilePhoto",
  method: "put",
  path: "/v1/me/photo",
  tags: ["about-you"],
  security,
  summary: "Set your profile photo",
  request: { body: jsonBody(SetProfilePhotoRequest) },
  responses: { 200: jsonResponse("About you", AboutYou), 400: e400, 401: e401 },
});

export const deleteProfilePhoto = createRoute({
  operationId: "deleteProfilePhoto",
  method: "delete",
  path: "/v1/me/photo",
  tags: ["about-you"],
  security,
  summary: "Remove your profile photo",
  responses: { 200: jsonResponse("About you", AboutYou), 401: e401 },
});

export const importProfilePhoto = createRoute({
  operationId: "importProfilePhoto",
  method: "post",
  path: "/v1/me/photo/import",
  tags: ["about-you"],
  security,
  summary: "Copy the photo your sign-in provider shares (Google) as your profile photo",
  description:
    "Without replace it only copies once, and only while you have no photo. It finishes quietly when there's nothing to copy or the provider can't be reached.",
  request: { body: jsonBody(ImportProfilePhotoRequest) },
  responses: { 200: jsonResponse("About you", AboutYou), 400: e400, 401: e401 },
});
