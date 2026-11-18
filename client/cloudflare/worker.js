// The casama-app Worker in front of app.casama.ai (D-316).
//
// Everything is served from static assets except build files of 25 MiB or more (Cloudflare's
// per-asset limit), which live in the R2 bucket bound as LARGE. cloudflare/prepare.mjs lists them in
// large-files.json and uploads a plain, a Brotli and a gzip copy of each under a content-named key.
// Only paths in wrangler.jsonc's assets.run_worker_first reach this code at all.
import large from "../build/web-host/large-files.json";

// What _headers gives static assets; it doesn't apply to responses made here.
const HEADERS = {
  "Cache-Control": "public, max-age=0, must-revalidate",
  "Cross-Origin-Opener-Policy": "same-origin",
  "Cross-Origin-Embedder-Policy": "credentialless",
  "Cross-Origin-Resource-Policy": "same-origin",
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
  Vary: "Accept-Encoding",
};

export default {
  async fetch(request, env, ctx) {
    const entry = large[new URL(request.url).pathname];
    if (!entry) return env.ASSETS.fetch(request);
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response(null, { status: 405, headers: { Allow: "GET, HEAD" } });
    }

    const etag = `"${entry.hash}"`;
    const headers = new Headers({ ...HEADERS, "Content-Type": entry.type, ETag: etag });
    const seen = (request.headers.get("If-None-Match") ?? "").split(",").map((t) => t.trim().replace(/^W\//, ""));
    if (seen.includes(etag) || seen.includes("*")) return new Response(null, { status: 304, headers });

    const accept = request.headers.get("Accept-Encoding") ?? "";
    const [suffix, encoding] = /\bbr\b/.test(accept) ? [".br", "br"] : /\bgzip\b/.test(accept) ? [".gz", "gzip"] : ["", null];
    const key = entry.key + suffix;

    // Keys never change content, so each data centre keeps its copy; R2 is read once per place.
    // Cached without Content-Encoding so the cache stores the bytes exactly as uploaded.
    const cache = caches.default;
    const cacheKey = new Request(`https://casama-app-large.internal/${key}`);
    let body = null;
    let length = null;
    const hit = await cache.match(cacheKey);
    if (hit) {
      body = hit.body;
      length = hit.headers.get("Content-Length");
    } else {
      const object = await env.LARGE.get(key);
      if (!object) return new Response("Not found", { status: 404 });
      const [toClient, toCache] = object.body.tee();
      body = toClient;
      length = String(object.size);
      ctx.waitUntil(
        cache.put(
          cacheKey,
          new Response(toCache, {
            headers: { "Content-Type": "application/octet-stream", "Content-Length": length, "Cache-Control": "public, max-age=31536000, immutable" },
          }),
        ),
      );
    }

    if (encoding) headers.set("Content-Encoding", encoding);
    if (length) headers.set("Content-Length", length);
    if (request.method === "HEAD") {
      body?.cancel();
      body = null;
    }
    return new Response(body, { headers, encodeBody: encoding ? "manual" : "automatic" });
  },
};
