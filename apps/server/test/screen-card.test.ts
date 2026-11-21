import { ComputerService } from "@casama/agent";
import type { SandboxHandle, SandboxProvider } from "@casama/sandbox";
import sharp from "sharp";
import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { ScreenCaptures } from "../src/api/screen-captures.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

/**
 * The lighter screenshot for the screen card (SCREEN-CARD-PLAN §8): a small JPEG, 304 for an
 * unchanged screen, one capture a second shared by every viewer, and wake=false never waking or
 * touching a computer. Old apps (no query) still get the full PNG.
 */
let h: Harness;
let owner: { id: string; token: string };
let stranger: { id: string; token: string };
let computerId: string;
let svc: ComputerService;
let screen: Uint8Array;

const screenshot = vi.fn<() => Promise<Uint8Array>>();
const handle = { ref: "fake", screenshot } as unknown as SandboxHandle;
const provider = {
  id: "docker",
  capabilities: { desktop: true, snapshots: true, liveStream: false },
  get: vi.fn(async () => handle),
  create: vi.fn(async () => handle),
  resume: vi.fn(async () => handle),
  sleep: vi.fn(),
  destroy: vi.fn(),
} as unknown as SandboxProvider & { resume: ReturnType<typeof vi.fn> };

const url = (q = "") => `/v1/computers/${computerId}/screenshot${q}`;
const setState = (state: string) =>
  h.tdb
    .admin`update public.computers set state = ${state}, last_active_at = '2026-01-01T00:00:00Z' where id = ${computerId}`;
const lastActive = async () =>
  (
    await h.tdb.admin<
      { t: Date }[]
    >`select last_active_at as t from public.computers where id = ${computerId}`
  )[0]?.t.toISOString();
/** Waits out the shared one-second capture window, so the next ask captures again. */
const nextSecond = () => new Promise((r) => setTimeout(r, 1050));

beforeAll(async () => {
  screen = new Uint8Array(
    await sharp({
      create: { width: 1280, height: 800, channels: 3, background: { r: 40, g: 90, b: 200 } },
    })
      .png()
      .toBuffer(),
  );
  h = await startHarness();
  svc = new ComputerService(h.handle.db, provider);
  (h.deps as { computers?: unknown }).computers = svc;
  owner = await h.user("screencard-owner@example.com");
  stranger = await h.user("screencard-stranger@example.com");
  const orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Card" } }),
    )
  ).id;
  const [c] = await h.tdb.admin<{ id: string }[]>`
    select id from public.computers where org_id = ${orgId} and kind = 'team'`;
  computerId = c?.id as string;
}, 60_000);
afterAll(async () => {
  await h?.stop();
});
beforeEach(async () => {
  vi.clearAllMocks();
  screenshot.mockImplementation(async () => screen);
  await nextSecond();
});

describe("screenshot for the screen card", () => {
  it("wake=false on a sleeping computer: 409 computer_asleep, nothing started or touched", async () => {
    await setState("sleeping");
    const before = await lastActive();
    const res = await h.request(url("?format=jpeg&width=480&wake=false"), { token: owner.token });
    expect(res.status).toBe(409);
    expect((await j(res)).code).toBe("computer_asleep");
    expect(provider.resume).not.toHaveBeenCalled();
    expect(screenshot).not.toHaveBeenCalled();
    expect(await lastActive()).toBe(before);
  });

  it("wake=false on a running computer: a small JPEG with an ETag, without touching it", async () => {
    await setState("running");
    const before = await lastActive();
    const res = await h.request(url("?format=jpeg&width=480&wake=false"), { token: owner.token });
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toBe("image/jpeg");
    expect(res.headers.get("etag")).toMatch(/^"s-[0-9a-f]{20}"$/);
    const body = new Uint8Array(await res.arrayBuffer());
    const meta = await sharp(body).metadata();
    expect(meta.format).toBe("jpeg");
    expect(meta.width).toBe(480);
    expect(body.length).toBeLessThan(screen.length);
    expect(await lastActive()).toBe(before);
  });

  it("an unchanged screen answers 304; a changed one sends the new picture", async () => {
    await setState("running");
    const first = await h.request(url("?format=jpeg&wake=false"), { token: owner.token });
    const etag = first.headers.get("etag") as string;
    await nextSecond();
    const same = await h.request(url("?format=jpeg&wake=false"), {
      token: owner.token,
      headers: { "if-none-match": etag },
    });
    expect(same.status).toBe(304);
    expect(same.headers.get("etag")).toBe(etag);
    await nextSecond();
    const changed = new Uint8Array(
      await sharp({
        create: { width: 1280, height: 800, channels: 3, background: { r: 200, g: 40, b: 40 } },
      })
        .png()
        .toBuffer(),
    );
    screenshot.mockImplementation(async () => changed);
    const moved = await h.request(url("?format=jpeg&wake=false"), {
      token: owner.token,
      headers: { "if-none-match": etag },
    });
    expect(moved.status).toBe(200);
    expect(moved.headers.get("etag")).not.toBe(etag);
  });

  it("asks within the same second share one capture", async () => {
    await setState("running");
    const asks = await Promise.all(
      [1, 2, 3, 4].map(() =>
        h.request(url("?format=jpeg&width=320&wake=false"), { token: owner.token }),
      ),
    );
    expect(asks.map((r) => r.status)).toEqual([200, 200, 200, 200]);
    expect(screenshot).toHaveBeenCalledTimes(1);
  });

  it("someone outside the workspace gets 404 and no picture is taken", async () => {
    await setState("running");
    const res = await h.request(url("?format=jpeg&wake=false"), { token: stranger.token });
    expect(res.status).toBe(404);
    expect(screenshot).not.toHaveBeenCalled();
  });

  it("old apps (no query) still get the full-size PNG", async () => {
    await setState("running");
    const res = await h.request(url(), { token: owner.token });
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toBe("image/png");
    expect(new Uint8Array(await res.arrayBuffer())).toEqual(screen);
  });

  it("rejects sizes outside 160–1280", async () => {
    await setState("running");
    const res = await h.request(url("?format=jpeg&width=4000"), { token: owner.token });
    expect(res.status).toBe(400);
  });
});

describe("ScreenCaptures", () => {
  it("captures again only after the window, and keeps the same ETag for the same picture", async () => {
    let t = 0;
    const caps = new ScreenCaptures(1000, () => t);
    const png = new Uint8Array([1, 2, 3]);
    const capture = vi.fn(async () => png);
    const a = await caps.get("c", capture);
    t = 500;
    await caps.get("c", capture);
    expect(capture).toHaveBeenCalledTimes(1);
    t = 1500;
    const b = await caps.get("c", capture);
    expect(capture).toHaveBeenCalledTimes(2);
    expect(b.etag).toBe(a.etag);
  });

  it("a failed capture isn't kept, so the next ask tries again", async () => {
    const caps = new ScreenCaptures(1000, () => 0);
    const capture = vi
      .fn<() => Promise<Uint8Array>>()
      .mockRejectedValueOnce(new Error("down"))
      .mockResolvedValueOnce(new Uint8Array([9]));
    await expect(caps.get("c", capture)).rejects.toThrow("down");
    expect((await caps.get("c", capture)).png).toEqual(new Uint8Array([9]));
  });
});
