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

// The shapes are kept unregistered for their nullable uses: zod-openapi resolves a registered
// schema that is also used `.nullable()` differently depending on module load order.
const cardUnitsShape = z.object({
  temp: z.enum(["C", "F"]).optional(),
  wind: z.enum(["kph", "mph", "ms", "kn"]).optional(),
  precip: z.enum(["mm", "in"]).optional(),
  distance: z.enum(["km", "mi"]).optional(),
});
export const CardUnits = cardUnitsShape.openapi("CardUnits");

const placeShape = z.object({
  name: z.string(),
  region: z.string().nullable().optional(),
  country: z.string().nullable().optional(),
  country_name: z.string().nullable().optional(),
  lat: z.number(),
  lng: z.number(),
  tz: z.string().nullable().optional(),
});
export const PlaceOut = placeShape.openapi("Place");

export const CardPrefs = z
  .object({
    home_place: placeShape.nullable(),
    units: cardUnitsShape.nullable(),
  })
  .openapi("CardPrefs");

export const UpdateCardPrefs = z
  .object({
    /** A city the person picked from `GET /v1/places`; null clears it. */
    home_place: placeShape.nullable().optional(),
    units: cardUnitsShape.nullable().optional(),
  })
  .openapi("UpdateCardPrefs");

export const PlaceList = z.object({ items: z.array(PlaceOut) }).openapi("PlaceList");

export const PinLiveCard = z.object({ units: CardUnits.optional() }).openapi("PinLiveCard");

/** A price watch on a Fares card (docs/FLIGHT-SEARCH-PLAN.md §9): the person's own. */
export const FareWatch = z
  .object({
    id: Uuid,
    card_id: Uuid,
    bot_id: Uuid.nullable(),
    /** "Manila → Tokyo · Mar 12–19". */
    route: z.string(),
    /** The price that sends a push when the fare is at or under it; null means "any good drop". */
    below: z.number().nullable(),
    currency: z.string(),
    first_price: z.number().nullable(),
    last_price: z.number().nullable(),
    last_checked_at: ts.nullable(),
    ends_at: ts,
    created_at: ts,
  })
  .openapi("FareWatch");

export const FareWatchList = z.object({ items: z.array(FareWatch) }).openapi("FareWatchList");

export const WatchFares = z
  .object({ below: z.number().positive().max(10_000_000).nullable().optional() })
  .openapi("WatchFares");
