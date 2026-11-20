/** Workspace pictures (docs/WORKSPACE-PICTURES-PLAN.md): upload, serve, recent, undo, re-crop, icon fallback, auth. */
import { parseBotAvatar } from "@casama/domain";
import sharp from "sharp";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let me: { id: string; token: string };
let other: { id: string; token: string };
let orgId = "";

const square = (rgb: [number, number, number], side = 512) =>
  sharp({
    create: {
      width: side,
      height: side,
      channels: 3,
      background: { r: rgb[0], g: rgb[1], b: rgb[2] },
    },
  })
    .png()
    .toBuffer();

beforeAll(async () => {
  h = await startHarness();
  me = await h.user("ws-pictures@example.com");
  other = await h.user("ws-stranger@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: me.token, json: { name: "Acme" } }),
    )
  ).id;
}, 60_000);
afterAll(async () => h?.stop());

const call = (path: string, init: { method?: string; json?: unknown; token?: string } = {}) =>
  h.request(path, { token: me.token, ...init });

const upload = async (rgb: [number, number, number], extra: Record<string, unknown> = {}) =>
  call(`/v1/orgs/${orgId}/image`, {
    method: "PUT",
    json: { data: (await square(rgb)).toString("base64"), ...extra },
  });

describe("workspace pictures", () => {
  it("sets a picture, serves it without a token, supports original/recent/use/remove, and clears on icon pick", async () => {
    const original = await sharp({
      create: { width: 1200, height: 900, channels: 3, background: "#3366cc" },
    })
      .jpeg()
      .toBuffer();
    const res = await upload([40, 120, 220], {
      original: original.toString("base64"),
      crop: { x: 0.5, y: 0.4, scale: 0.8, rotation: 0, mirror: false, background: "none" },
    });
    expect(res.status).toBe(200);
    const org = await j(res);
    const a = parseBotAvatar(org.avatar_url);
    expect(a.kind).toBe("image");
    if (a.kind !== "image") return;

    // Public immutable serving
    const big = await h.request(`/v1/workspace-images/${a.id}`);
    expect(big.status).toBe(200);
    expect(big.headers.get("content-type")).toBe("image/webp");
    expect(big.headers.get("cache-control")).toContain("immutable");
    const small = await h.request(`/v1/workspace-images/${a.id}?size=128&format=png`);
    expect(small.headers.get("content-type")).toBe("image/png");
    expect((await sharp(Buffer.from(await small.arrayBuffer())).metadata()).width).toBe(128);
    expect((await h.request("/v1/workspace-images/not-an-id")).status).toBe(404);

    // Original for Re-crop
    const origRes = await call(`/v1/orgs/${orgId}/images/${a.id}/original`);
    expect(origRes.status).toBe(200);

    // Second picture, then switch back to the first via /use
    const res2 = await upload([220, 80, 60]);
    expect(res2.status).toBe(200);
    const org2 = await j(res2);
    expect(org2.avatar_url).not.toBe(org.avatar_url);

    const list = await j(await call(`/v1/orgs/${orgId}/images`));
    expect(list.items.length).toBe(2);
    expect(list.items[0].in_use).toBe(true);

    const switched = await j(
      await call(`/v1/orgs/${orgId}/images/${a.id}/use`, { method: "POST" }),
    );
    expect(switched.avatar_url).toBe(org.avatar_url);

    // Picking an icon clears avatar_url so the icon shows again
    const iconed = await j(
      await call(`/v1/orgs/${orgId}`, { method: "PATCH", json: { icon: "rocket" } }),
    );
    expect(iconed.icon).toBe("rocket");
    expect(iconed.avatar_url).toBeNull();

    // Re-apply and remove explicitly
    await call(`/v1/orgs/${orgId}/images/${a.id}/use`, { method: "POST" });
    const removed = await j(await call(`/v1/orgs/${orgId}/image`, { method: "DELETE" }));
    expect(removed.avatar_url).toBeNull();
    expect(removed.icon).toBe("rocket");

    // Non-members cannot view or change workspace pictures
    expect((await call(`/v1/orgs/${orgId}/images`, { token: other.token })).status).toBe(404);
    expect(
      (
        await call(`/v1/orgs/${orgId}/image`, {
          method: "PUT",
          token: other.token,
          json: { data: (await square([10, 20, 30])).toString("base64") },
        })
      ).status,
    ).toBe(404);
  });
});
