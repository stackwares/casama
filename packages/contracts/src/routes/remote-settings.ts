import { createRoute } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses } from "../common.ts";
import {
  AdminBrowserGuard,
  AdminModelCatalog,
  AdminPriceTables,
  BrowserGuardSites,
  SaveModelCatalogRequest,
  SavePriceTablesRequest,
} from "../remote-settings.ts";

const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403 } = problemResponses;

export const adminModelCatalog = createRoute({
  operationId: "adminModelCatalog",
  method: "get",
  path: "/v1/admin/model-catalog",
  tags: ["admin"],
  security,
  summary: "The model catalog: saved values and the ones in code (owner only; D-373)",
  responses: { 200: jsonResponse("Catalog", AdminModelCatalog), 401: e401, 403: e403 },
});

export const saveModelCatalog = createRoute({
  operationId: "saveModelCatalog",
  method: "put",
  path: "/v1/admin/model-catalog",
  tags: ["admin"],
  security,
  summary: "Replace the model catalog; refused when any part fails its check (owner only)",
  request: { body: jsonBody(SaveModelCatalogRequest) },
  responses: { 200: jsonResponse("Saved", AdminModelCatalog), 400: e400, 401: e401, 403: e403 },
});

export const adminPriceTables = createRoute({
  operationId: "adminPriceTables",
  method: "get",
  path: "/v1/admin/price-tables",
  tags: ["admin"],
  security,
  summary: "Cost tables and domain sale settings (owner only; D-373)",
  responses: { 200: jsonResponse("Price tables", AdminPriceTables), 401: e401, 403: e403 },
});

export const savePriceTables = createRoute({
  operationId: "savePriceTables",
  method: "put",
  path: "/v1/admin/price-tables",
  tags: ["admin"],
  security,
  summary: "Change cost tables or domain sale settings; fields left out keep their value",
  request: { body: jsonBody(SavePriceTablesRequest) },
  responses: { 200: jsonResponse("Saved", AdminPriceTables), 400: e400, 401: e401, 403: e403 },
});

export const getBrowserGuardSites = createRoute({
  operationId: "getBrowserGuardSites",
  method: "get",
  path: "/v1/browser-guard",
  tags: ["system"],
  summary: "Sites the browser guard keeps out on top of its own lists (no auth; D-374)",
  responses: { 200: jsonResponse("Added sites", BrowserGuardSites) },
});

export const adminBrowserGuard = createRoute({
  operationId: "adminBrowserGuard",
  method: "get",
  path: "/v1/admin/browser-guard",
  tags: ["admin"],
  security,
  summary: "The browser guard's added sites and its built-in ones (owner only; D-374)",
  responses: { 200: jsonResponse("Guard sites", AdminBrowserGuard), 401: e401, 403: e403 },
});

export const saveBrowserGuard = createRoute({
  operationId: "saveBrowserGuard",
  method: "put",
  path: "/v1/admin/browser-guard",
  tags: ["admin"],
  security,
  summary: "Replace the added sites; the built-in lists can't be shortened (owner only)",
  request: { body: jsonBody(BrowserGuardSites) },
  responses: { 200: jsonResponse("Saved", AdminBrowserGuard), 400: e400, 401: e401, 403: e403 },
});
