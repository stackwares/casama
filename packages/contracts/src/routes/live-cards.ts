import { createRoute, z } from "@hono/zod-openapi";
import { jsonBody, jsonResponse, problemResponses, Uuid } from "../common.ts";
import {
  CardPrefs,
  FareWatch,
  FareWatchList,
  LiveCardList,
  LiveCardOut,
  PinLiveCard,
  PlaceList,
  RefreshLiveCard,
  UpdateCardPrefs,
  WatchFares,
} from "../live-cards.ts";

/** Live data cards (docs/RICH-CARDS-PLAN.md §4.4–4.6). */
const security = [{ bearerAuth: [] }];
const { 400: e400, 401: e401, 403: e403, 404: e404, 429: e429 } = problemResponses;
const idParam = z.object({ id: Uuid });

export const getLiveCards = createRoute({
  operationId: "getLiveCards",
  method: "get",
  path: "/v1/live-cards",
  tags: ["cards"],
  security,
  summary: "The latest data of the live cards on screen (up to 20 ids, comma separated)",
  request: { query: z.object({ ids: z.string().max(800) }) },
  responses: { 200: jsonResponse("The cards", LiveCardList), 400: e400, 401: e401 },
});

export const refreshLiveCard = createRoute({
  operationId: "refreshLiveCard",
  method: "post",
  path: "/v1/live-cards/{id}/refresh",
  tags: ["cards"],
  security,
  summary:
    "Fetch a card's data again (through the shared cache), or another of its views. No model call; a failed fetch returns the last card marked stale with the reason",
  request: { params: idParam, body: jsonBody(RefreshLiveCard) },
  responses: {
    200: jsonResponse("The card", LiveCardOut),
    400: e400,
    401: e401,
    404: e404,
    429: e429,
  },
});

export const reportLiveCard = createRoute({
  operationId: "reportLiveCard",
  method: "post",
  path: "/v1/live-cards/{id}/report",
  tags: ["cards"],
  security,
  summary: "Report wrong data on a card (its provider and data are kept, no words)",
  request: { params: idParam },
  responses: { 200: jsonResponse("Reported", z.object({ ok: z.boolean() })), 401: e401, 404: e404 },
});

export const pinLiveCard = createRoute({
  operationId: "pinLiveCard",
  method: "post",
  path: "/v1/live-cards/{id}/pin",
  tags: ["cards"],
  security,
  summary:
    "Pin a card to the person's widgets: a Canvas the server keeps fresh without the bot (the bot's widget permission applies)",
  request: { params: idParam, body: jsonBody(PinLiveCard) },
  responses: {
    200: jsonResponse(
      "Pinned",
      z
        .object({ canvas_id: Uuid, status: z.enum(["waiting", "shown", "paused"]) })
        .openapi("PinnedLiveCard"),
    ),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const unpinLiveCard = createRoute({
  operationId: "unpinLiveCard",
  method: "delete",
  path: "/v1/live-cards/{id}/pin",
  tags: ["cards"],
  security,
  summary: "Take a pinned card off the widgets",
  request: { params: idParam },
  responses: { 200: jsonResponse("Unpinned", z.object({ ok: z.boolean() })), 401: e401, 404: e404 },
});

export const getCardPrefs = createRoute({
  operationId: "getCardPrefs",
  method: "get",
  path: "/v1/me/card-prefs",
  tags: ["cards"],
  security,
  summary: "The person's home city and units for cards",
  responses: { 200: jsonResponse("Preferences", CardPrefs), 401: e401 },
});

export const updateCardPrefs = createRoute({
  operationId: "updateCardPrefs",
  method: "put",
  path: "/v1/me/card-prefs",
  tags: ["cards"],
  security,
  summary: "Set the person's home city (a city, never a street) and units for cards",
  request: { body: jsonBody(UpdateCardPrefs) },
  responses: { 200: jsonResponse("Saved", CardPrefs), 400: e400, 401: e401 },
});

export const searchPlaces = createRoute({
  operationId: "searchPlaces",
  method: "get",
  path: "/v1/places",
  tags: ["cards"],
  security,
  summary: "Cities matching a name, for picking a home city",
  request: { query: z.object({ q: z.string().min(2).max(120) }) },
  responses: { 200: jsonResponse("Places", PlaceList), 400: e400, 401: e401, 429: e429 },
});

export const watchLiveCard = createRoute({
  operationId: "watchLiveCard",
  method: "post",
  path: "/v1/live-cards/{id}/watch",
  tags: ["cards"],
  security,
  summary:
    "Watch a Fares card's price: the server checks it every few hours (free providers only) and pushes when it drops. Up to 5 watches per workspace",
  request: { params: idParam, body: jsonBody(WatchFares) },
  responses: {
    200: jsonResponse("Watching", FareWatch),
    400: e400,
    401: e401,
    403: e403,
    404: e404,
  },
});

export const unwatchLiveCard = createRoute({
  operationId: "unwatchLiveCard",
  method: "delete",
  path: "/v1/live-cards/{id}/watch",
  tags: ["cards"],
  security,
  summary: "Stop watching a Fares card's price",
  request: { params: idParam },
  responses: { 200: jsonResponse("Stopped", z.object({ ok: z.boolean() })), 401: e401, 404: e404 },
});

export const listFareWatches = createRoute({
  operationId: "listFareWatches",
  method: "get",
  path: "/v1/me/fare-watches",
  tags: ["cards"],
  security,
  summary: "The person's active price watches",
  responses: { 200: jsonResponse("Watches", FareWatchList), 401: e401 },
});
