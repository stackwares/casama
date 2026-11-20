import { z } from "@hono/zod-openapi";
import { Uuid } from "./common.ts";

/**
 * Live data cards (docs/RICH-CARDS-PLAN.md §4.3–4.6). A card is an A2UI component the server
 * filled from a named provider; its `live` block says where from and when. The app refreshes it
 * by id; the call it repeats stays on the server.
 */
const ts = z.iso.datetime({ offset: true });

export const LiveCardData = z
  .record(z.string(), z.unknown())
  .openapi("LiveCardData", { description: "The card's component, with its `live` block" });

export const LiveCardOut = z
  .object({
    id: Uuid,
    card: LiveCardData,
    fetched_at: ts,
    /** Why it couldn't be updated; the card is the last good one, marked stale. */
    error: z.string().nullable(),
    pinned: z.boolean(),
  })
  .openapi("LiveCard");

export const LiveCardList = z.object({ items: z.array(LiveCardOut) }).openapi("LiveCardList");

export const RefreshLiveCard = z
  .object({
    /** Another of the card's views (a day, a chart range); not saved as the card's data. */
    view: z.string().max(20).optional(),
    /** The person tapped ↻: call the provider again unless the answer is very recent. */
    force: z.boolean().optional(),
  })
  .openapi("RefreshLiveCard");

export const CardUnits = z
  .object({
    temp: z.enum(["C", "F"]).optional(),
    wind: z.enum(["kph", "mph", "ms", "kn"]).optional(),
    precip: z.enum(["mm", "in"]).optional(),
    distance: z.enum(["km", "mi"]).optional(),
  })
  .openapi("CardUnits");

export const PlaceOut = z
  .object({
    name: z.string(),
    region: z.string().nullable().optional(),
    country: z.string().nullable().optional(),
    country_name: z.string().nullable().optional(),
    lat: z.number(),
    lng: z.number(),
    tz: z.string().nullable().optional(),
  })
  .openapi("Place");

export const CardPrefs = z
  .object({
    home_place: PlaceOut.nullable(),
    units: CardUnits.nullable(),
  })
  .openapi("CardPrefs");

export const UpdateCardPrefs = z
  .object({
    /** A city the person picked from `GET /v1/places`; null clears it. */
    home_place: PlaceOut.nullable().optional(),
    units: CardUnits.nullable().optional(),
  })
  .openapi("UpdateCardPrefs");

export const PlaceList = z.object({ items: z.array(PlaceOut) }).openapi("PlaceList");

export const PinLiveCard = z.object({ units: CardUnits.optional() }).openapi("PinLiveCard");
