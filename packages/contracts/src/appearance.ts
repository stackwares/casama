import { z } from "@hono/zod-openapi";

/** A wallpaper photo from the server's optional photo source (Unsplash today, D-087). */
export const WallpaperPhoto = z
  .object({
    id: z.string(),
    /** Small, for the picker grid. */
    thumb_url: z.string(),
    /** Screen-sized, for the wallpaper itself. */
    url: z.string(),
    color: z.string().nullable(),
    width: z.number().int(),
    height: z.number().int(),
    author: z.string(),
    author_url: z.string(),
    /** The photo's page on the source, for attribution. */
    source_url: z.string(),
    /** Opaque; send back to `trackWallpaperDownload` when the photo is chosen. */
    download_location: z.string(),
  })
  .openapi("WallpaperPhoto");

export const WallpaperPhotoList = z
  .object({ items: z.array(WallpaperPhoto), source: z.enum(["unsplash"]) })
  .openapi("WallpaperPhotoList");

export const WallpaperDownloadRequest = z
  .object({ download_location: z.url().max(2000) })
  .openapi("WallpaperDownloadRequest");
