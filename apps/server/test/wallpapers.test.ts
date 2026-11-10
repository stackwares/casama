import { describe, expect, it } from "vitest";
import { unsplashSource } from "../src/services/wallpapers.ts";

const photo = {
  id: "abc",
  color: "#aabbcc",
  width: 4000,
  height: 3000,
  urls: {
    raw: "https://images.unsplash.com/photo-1?ixid=x",
    small: "https://s",
    regular: "https://r",
  },
  links: {
    html: "https://unsplash.com/photos/abc",
    download_location: "https://api.unsplash.test/photos/abc/download?ixid=x",
  },
  user: { name: "Ana", links: { html: "https://unsplash.com/@ana" } },
};

function fakeFetch(calls: string[]) {
  return (async (url: string | URL, init?: RequestInit) => {
    calls.push(String(url));
    expect((init?.headers as Record<string, string> | undefined)?.Authorization).toBe(
      "Client-ID key",
    );
    const body = String(url).includes("/search/") ? { results: [photo] } : [photo];
    return new Response(JSON.stringify(body), { status: 200 });
  }) as typeof fetch;
}

describe("unsplash wallpapers", () => {
  it("searches, maps photos with attribution, and lists wallpapers without a query", async () => {
    const calls: string[] = [];
    const src = unsplashSource({
      accessKey: "key",
      apiUrl: "https://api.unsplash.test",
      fetch: fakeFetch(calls),
    });
    const [p] = await src.search("sea cliffs", 2);
    expect(calls[0]).toContain("/search/photos?query=sea%20cliffs&page=2");
    expect(p).toMatchObject({
      id: "abc",
      thumb_url: "https://s",
      author: "Ana",
      author_url: "https://unsplash.com/@ana?utm_source=kasama&utm_medium=referral",
      source_url: "https://unsplash.com/photos/abc?utm_source=kasama&utm_medium=referral",
    });
    expect(p!.url).toContain("w=2400");
    await src.search(undefined, 1);
    expect(calls[1]).toContain("/topics/wallpapers/photos");
  });

  it("tracks downloads only on the API host", async () => {
    const calls: string[] = [];
    const src = unsplashSource({
      accessKey: "key",
      apiUrl: "https://api.unsplash.test",
      fetch: fakeFetch(calls),
    });
    await src.trackDownload(photo.links.download_location);
    expect(calls).toEqual([photo.links.download_location]);
    await expect(src.trackDownload("https://evil.example/x")).rejects.toThrow();
  });
});
