import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { z } from "zod";

/**
 * The catalog of screens and store pages Casama Help is allowed to link to.
 * Keep routes in sync with `client/lib/core/router.dart` (verified by Flutter route tests).
 */
export const PlacePlatform = z.enum(["ios", "android", "macos", "windows", "linux", "web"]);
export type PlacePlatform = z.infer<typeof PlacePlatform>;

export const PlaceRole = z.enum(["owner", "admin", "member"]);
export type PlaceRole = z.infer<typeof PlaceRole>;

export const SupportPlaceDefinition = z
  .object({
    id: z.string().regex(/^[a-z][a-z0-9_]{1,40}$/),
    label: z.string().min(1).max(80),
    route: z.string().startsWith("/").optional(),
    url: z.url().startsWith("https://").optional(),
    params: z.array(z.string().regex(/^[a-zA-Z][a-zA-Z0-9_]*$/)).optional(),
    highlights: z.array(z.string().regex(/^[a-z][a-z0-9_]{1,40}$/)).optional(),
    public: z.boolean(),
    platforms: z.array(PlacePlatform).optional(),
    minBuild: z.number().int().min(1).optional(),
    cloudOnly: z.boolean().optional(),
    roles: z.array(PlaceRole).optional(),
    description: z.string().min(1).max(200),
  })
  .refine((p) => Boolean(p.route) !== Boolean(p.url), {
    message: "Each place must specify exactly one of route or url",
  })
  .refine(
    (p) => {
      if (!p.route) return !p.params?.length && !p.highlights?.length;
      const placeholders = [...p.route.matchAll(/\{([a-zA-Z][a-zA-Z0-9_]*)\}/g)]
        .map((m) => m[1])
        .filter((name): name is string => Boolean(name));
      const declared = p.params ?? [];
      return (
        placeholders.length === declared.length &&
        placeholders.every((name) => declared.includes(name))
      );
    },
    { message: "route placeholders must match declared params" },
  );

export type SupportPlaceDefinition = z.infer<typeof SupportPlaceDefinition>;

export const SupportPlacesCatalog = z.object({
  version: z.literal(1),
  places: z.array(SupportPlaceDefinition).min(1),
});

export type SupportPlacesCatalog = z.infer<typeof SupportPlacesCatalog>;

const PLACES_PATH = fileURLToPath(new URL("../support/places.json", import.meta.url));

let cached: SupportPlaceDefinition[] | null = null;

export function loadSupportPlaces(): SupportPlaceDefinition[] {
  if (cached) return cached;
  const raw = JSON.parse(readFileSync(PLACES_PATH, "utf8")) as unknown;
  const parsed = SupportPlacesCatalog.parse(raw);
  cached = parsed.places;
  return cached;
}

export function resetSupportPlacesCache(): void {
  cached = null;
}
