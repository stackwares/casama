/**
 * Travel time for leave-now triggers (D-151), on the workspace's own maps key: Google Maps
 * (Distance Matrix, with traffic) or Mapbox (geocoding, then driving-traffic directions).
 */
export type MapsProvider = "google_maps" | "mapbox";

export interface TravelDeps {
  fetch: typeof fetch;
  /** Overrides for tests. */
  bases?: { google_maps?: string; mapbox?: string };
}

/** Minutes from [origin] to [destination] (an address), or null when the provider can't say. */
export async function travelMinutes(
  provider: MapsProvider,
  key: string,
  origin: { lat: number; lng: number },
  destination: string,
  deps: TravelDeps,
): Promise<number | null> {
  if (provider === "google_maps") {
    const base = deps.bases?.google_maps ?? "https://maps.googleapis.com";
    const u = new URL("/maps/api/distancematrix/json", base);
    u.search = new URLSearchParams({
      origins: `${origin.lat},${origin.lng}`,
      destinations: destination,
      departure_time: "now",
      key,
    }).toString();
    const r = await deps.fetch(u);
    if (!r.ok) return null;
    const j = (await r.json()) as {
      rows?: Array<{
        elements?: Array<{
          status?: string;
          duration?: { value: number };
          duration_in_traffic?: { value: number };
        }>;
      }>;
    };
    const e = j.rows?.[0]?.elements?.[0];
    if (e?.status !== "OK") return null;
    return Math.ceil((e.duration_in_traffic?.value ?? e.duration?.value ?? 0) / 60);
  }
  const base = deps.bases?.mapbox ?? "https://api.mapbox.com";
  const g = new URL("/search/geocode/v6/forward", base);
  g.search = new URLSearchParams({
    q: destination,
    limit: "1",
    proximity: `${origin.lng},${origin.lat}`,
    access_token: key,
  }).toString();
  const gr = await deps.fetch(g);
  if (!gr.ok) return null;
  const coords = (
    (await gr.json()) as { features?: Array<{ geometry?: { coordinates?: [number, number] } }> }
  ).features?.[0]?.geometry?.coordinates;
  if (!coords) return null;
  const d = new URL(
    `/directions/v5/mapbox/driving-traffic/${origin.lng},${origin.lat};${coords[0]},${coords[1]}`,
    base,
  );
  d.search = new URLSearchParams({ access_token: key, overview: "false" }).toString();
  const dr = await deps.fetch(d);
  if (!dr.ok) return null;
  const sec = ((await dr.json()) as { routes?: Array<{ duration?: number }> }).routes?.[0]
    ?.duration;
  return typeof sec === "number" ? Math.ceil(sec / 60) : null;
}
