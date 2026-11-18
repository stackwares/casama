/**
 * Wallpaper photo search (D-087). Optional: only on when UNSPLASH_ACCESS_KEY is set. The key
 * stays on the server; the app gets photo URLs and attribution, and reports which photo was
 * chosen so the source's download count stays right (an Unsplash API requirement).
 */
import type { WallpaperPhoto } from "@casama/contracts";
import type { z } from "zod";

type Photo = z.infer<typeof WallpaperPhoto>;

export interface WallpaperSource {
  readonly name: "unsplash";
  search(query: string | undefined, page: number): Promise<Photo[]>;
  trackDownload(downloadLocation: string): Promise<void>;
}

type UnsplashPhoto = {
  id: string;
  color: string | null;
  width: number;
  height: number;
  urls: { raw: string; small: string; regular: string };
  links: { html: string; download_location: string };
  user: { name: string; links: { html: string } };
};

const UTM = "utm_source=casama&utm_medium=referral";
const withUtm = (url: string) => `${url}${url.includes("?") ? "&" : "?"}${UTM}`;

export function unsplashSource(opts: {
  accessKey: string;
  apiUrl: string;
  fetch?: typeof fetch;
}): WallpaperSource {
  const doFetch = opts.fetch ?? fetch;
  const api = opts.apiUrl.replace(/\/$/, "");
  const headers = { Authorization: `Client-ID ${opts.accessKey}`, "Accept-Version": "v1" };
  const toPhoto = (p: UnsplashPhoto): Photo => ({
    id: p.id,
    thumb_url: p.urls.small,
    // Screen-sized: long edge 2400 px, good enough for a blurred, dimmed background.
    url: `${p.urls.raw}${p.urls.raw.includes("?") ? "&" : "?"}w=2400&q=80&fm=jpg&fit=max`,
    color: p.color,
    width: p.width,
    height: p.height,
    author: p.user.name,
    author_url: withUtm(p.user.links.html),
    source_url: withUtm(p.links.html),
    download_location: p.links.download_location,
  });
  return {
    name: "unsplash",
    async search(query, page) {
      const q = query?.trim();
      const url = q
        ? `${api}/search/photos?query=${encodeURIComponent(q)}&page=${page}&per_page=24&content_filter=high`
        : `${api}/topics/wallpapers/photos?page=${page}&per_page=24`;
      const res = await doFetch(url, { headers, signal: AbortSignal.timeout(10_000) });
      if (!res.ok) throw new Error(`unsplash ${res.status}`);
      const body = (await res.json()) as UnsplashPhoto[] | { results: UnsplashPhoto[] };
      return (Array.isArray(body) ? body : body.results).map(toPhoto);
    },
    async trackDownload(downloadLocation) {
      // Only the source's own API host, so this can't be pointed elsewhere.
      if (new URL(downloadLocation).origin !== new URL(api).origin) {
        throw new Error("download_location is not an Unsplash API URL");
      }
      const res = await doFetch(downloadLocation, { headers, signal: AbortSignal.timeout(10_000) });
      if (!res.ok) throw new Error(`unsplash ${res.status}`);
    },
  };
}
