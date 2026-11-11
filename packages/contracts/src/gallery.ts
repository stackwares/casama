import { z } from "@hono/zod-openapi";

const Author = z
  .object({
    name: z.string(),
    url: z.string().optional(),
  })
  .openapi("GalleryAuthor");

export const GalleryItem = z
  .object({
    id: z.string(),
    type: z.enum(["theme", "scheme", "wallpaper", "skill"]),
    name: z.string(),
    author: Author,
    license: z.string(),
    tags: z.array(z.string()),
    featured: z.boolean(),
    retired: z.boolean(),
    version: z.number().int(),
    sha256: z.string(),
    category: z.string().optional(),
    icon: z.string().optional().openapi({ description: "A skill's Lucide icon name." }),
    description: z.string().optional().openapi({ description: "A skill's one-line description." }),
    requires: z.array(z.string()).optional().openapi({
      description:
        "Features the look needs from the app (doodles, mesh, scheme-colors). Apps hide items that need something they can't draw.",
    }),
    document: z.record(z.string(), z.unknown()).optional().openapi({
      description:
        "A theme, scheme or wallpaper document, so a list can draw previews without fetching each item.",
    }),
    files: z.array(z.string()),
  })
  .openapi("GalleryItem");

export const GalleryList = z
  .object({
    available: z.boolean().openapi({
      description: "False when the gallery host could not be read. Built-in looks still apply.",
    }),
    items: z.array(GalleryItem),
  })
  .openapi("GalleryList");

export const GalleryDetail = GalleryItem.extend({
  document: z.record(z.string(), z.unknown()).nullable(),
  skill_md: z.string().nullable(),
}).openapi("GalleryDetail");
