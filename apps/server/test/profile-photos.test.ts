/** Profile photos (D-202): upload, serve, remove, and copying the Google sign-in photo once. */
import { afterAll, afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import {
  fetchProviderPhoto,
  providerPhotoUrl,
  sniffPhotoType,
} from "../src/services/profile-photos.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

// The smallest real PNG: one transparent pixel.
const PNG = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=",
  "base64",
);
const JPEG = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 0x10, 0x4a, 0x46, 0x49, 0x46, 0]);

describe("profile photo helpers", () => {
  it("knows a picture by its bytes", () => {
    expect(sniffPhotoType(PNG)).toBe("image/png");
    expect(sniffPhotoType(JPEG)).toBe("image/jpeg");
    expect(sniffPhotoType(Buffer.from("RIFF0000WEBPVP8 "))).toBe("image/webp");
    expect(sniffPhotoType(Buffer.from("<svg onload=alert(1)>"))).toBeNull();
  });

  it("only fetches Google's photo host, at 512 px", () => {
    expect(
      providerPhotoUrl({ avatar_url: "https://lh3.googleusercontent.com/a/ACg8oc=s96-c" }),
    ).toBe("https://lh3.googleusercontent.com/a/ACg8oc=s512-c");
    expect(providerPhotoUrl({ picture: "https://lh3.googleusercontent.com/a/ACg8oc" })).toBe(
      "https://lh3.googleusercontent.com/a/ACg8oc=s512-c",
    );
    expect(providerPhotoUrl({ avatar_url: "http://lh3.googleusercontent.com/a/x" })).toBeNull();
    expect(
      providerPhotoUrl({ avatar_url: "https://evil.example/googleusercontent.com" }),
    ).toBeNull();
    expect(providerPhotoUrl({ avatar_url: "https://169.254.169.254/latest" })).toBeNull();
    expect(providerPhotoUrl({ full_name: "No photo" })).toBeNull();
    expect(providerPhotoUrl(null)).toBeNull();
  });

  it("gives up quietly on anything that isn't a picture", async () => {
    const reply = (body: ConstructorParameters<typeof Response>[0], status = 200) =>
      (async () => new Response(body, { status })) as unknown as typeof fetch;
    expect(await fetchProviderPhoto("https://x", reply(PNG))).toMatchObject({ type: "image/png" });
    expect(await fetchProviderPhoto("https://x", reply("<html>"))).toBeNull();
    expect(await fetchProviderPhoto("https://x", reply(PNG, 404))).toBeNull();
    const offline = (async () => {
      throw new Error("offline");
    }) as unknown as typeof fetch;
    expect(await fetchProviderPhoto("https://x", offline)).toBeNull();
  });
});

let h: Harness;
let me: { id: string; token: string };
let orgId = "";

beforeAll(async () => {
  h = await startHarness();
  me = await h.user("photo@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: me.token, json: { name: "Mine" } }),
    )
  ).id;
}, 60_000);
afterAll(async () => h?.stop());
afterEach(() => vi.restoreAllMocks());

const call = (path: string, init: { method?: string; json?: unknown } = {}) =>
  h.request(path, { ...init, token: me.token });

describe("profile photo API", () => {
  it("uploads, serves without a token, shows in the member list and removes", async () => {
    expect(await j(await call("/v1/me/about"))).toMatchObject({
      photo_id: null,
      provider_photo: false,
    });

    // A file that says it's a picture but isn't is turned away.
    const fake = await call("/v1/me/photo", {
      method: "PUT",
      json: { content_type: "image/png", data: Buffer.from("<svg/>").toString("base64") },
    });
    expect(fake.status).toBe(400);

    const set = await j(
      await call("/v1/me/photo", {
        method: "PUT",
        json: { content_type: "image/png", data: PNG.toString("base64") },
      }),
    );
    expect(set.photo_id).toMatch(/^[0-9a-f-]{36}$/);

    const pic = await h.request(`/v1/photos/${set.photo_id}`);
    expect(pic.status).toBe(200);
    expect(pic.headers.get("content-type")).toBe("image/png");
    expect(pic.headers.get("cache-control")).toContain("immutable");
    expect(Buffer.from(await pic.arrayBuffer()).equals(PNG)).toBe(true);

    const members = await j(await call(`/v1/orgs/${orgId}/members`));
    expect(members.items[0]).toMatchObject({ user_id: me.id, photo_id: set.photo_id });

    // A new photo gets a new address; the old one stops working.
    const again = await j(
      await call("/v1/me/photo", {
        method: "PUT",
        json: { content_type: "image/png", data: PNG.toString("base64") },
      }),
    );
    expect(again.photo_id).not.toBe(set.photo_id);
    expect((await h.request(`/v1/photos/${set.photo_id}`)).status).toBe(404);

    const removed = await j(await call("/v1/me/photo", { method: "DELETE" }));
    expect(removed.photo_id).toBeNull();
    expect((await h.request(`/v1/photos/${again.photo_id}`)).status).toBe(404);
    expect((await h.request("/v1/photos/not-an-id")).status).toBe(404);
  });

  it("copies the Google photo once, never after it was removed, and again on request", async () => {
    const google = await h.user("google@example.com");
    await h.tdb.admin.unsafe(
      `update auth.users set raw_user_meta_data = raw_user_meta_data || '{"avatar_url":"https://lh3.googleusercontent.com/a/me=s96-c"}' where id = $1`,
      [google.id],
    );
    const asked: string[] = [];
    const real = globalThis.fetch;
    vi.spyOn(globalThis, "fetch").mockImplementation(async (input, init) => {
      const url = String(input instanceof Request ? input.url : input);
      if (!url.includes("googleusercontent.com")) return real(input, init);
      asked.push(url);
      return new Response(JPEG);
    });
    const g = (path: string, init: { method?: string; json?: unknown } = {}) =>
      h.request(path, { ...init, token: google.token });

    expect(await j(await g("/v1/me/about"))).toMatchObject({
      photo_id: null,
      provider_photo: true,
      photo_import_tried: false,
    });
    const first = await j(await g("/v1/me/photo/import", { method: "POST", json: {} }));
    expect(first.photo_id).toMatch(/^[0-9a-f-]{36}$/);
    expect(asked).toEqual(["https://lh3.googleusercontent.com/a/me=s512-c"]);

    // Removed on purpose: asking again without replace leaves it removed.
    await g("/v1/me/photo", { method: "DELETE" });
    const quiet = await j(await g("/v1/me/photo/import", { method: "POST", json: {} }));
    expect(quiet.photo_id).toBeNull();
    expect(asked).toHaveLength(1);

    // "Use my Google photo" brings it back.
    const back = await j(
      await g("/v1/me/photo/import", { method: "POST", json: { replace: true } }),
    );
    expect(back.photo_id).toMatch(/^[0-9a-f-]{36}$/);
    expect(asked).toHaveLength(2);
  });
});
