import { ComputerService } from "@casama/agent";
import {
  type FileThumbnail,
  SandboxError,
  type SandboxHandle,
  type SandboxProvider,
} from "@casama/sandbox";
import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

/**
 * Thumbnails of files on a bot's computer (D-226): relayed from a running computer, and never a
 * reason to start, wake or restore one.
 */
const JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3, 0xff, 0xd9]);

let h: Harness;
let owner: { id: string; token: string };
let stranger: { id: string; token: string };
let orgId: string;
let computerId: string;
let svc: ComputerService;

const thumbnail = vi.fn<(path: string, size: number) => Promise<FileThumbnail | null>>();
const screenshot = vi.fn<() => Promise<Uint8Array>>();
const handle = { ref: "fake", thumbnail, screenshot } as unknown as SandboxHandle;
const provider = {
  id: "docker",
  capabilities: { desktop: false, snapshots: true, liveStream: false },
  get: vi.fn(async () => handle),
  create: vi.fn(async () => handle),
  resume: vi.fn(async () => handle),
  sleep: vi.fn(),
  destroy: vi.fn(),
} as unknown as SandboxProvider & {
  get: ReturnType<typeof vi.fn>;
  create: ReturnType<typeof vi.fn>;
  resume: ReturnType<typeof vi.fn>;
};

const url = (path: string, size?: number) =>
  `/v1/computers/${computerId}/files/thumbnail?path=${encodeURIComponent(path)}${size ? `&size=${size}` : ""}`;

const setState = (state: string) =>
  h.tdb
    .admin`update public.computers set state = ${state}, last_active_at = '2026-01-01T00:00:00Z' where id = ${computerId}`;
const lastActive = async () =>
  (
    await h.tdb.admin<
      { t: Date }[]
    >`select last_active_at as t from public.computers where id = ${computerId}`
  )[0]?.t.toISOString();

beforeAll(async () => {
  h = await startHarness();
  svc = new ComputerService(h.handle.db, provider);
  (h.deps as { computers?: unknown }).computers = svc;
  owner = await h.user("thumbs-owner@example.com");
  stranger = await h.user("thumbs-stranger@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Thumbs" } }),
    )
  ).id;
  // Every workspace starts with its team computer.
  const [c] = await h.tdb.admin<{ id: string }[]>`
    select id from public.computers where org_id = ${orgId} and kind = 'team'`;
  computerId = c?.id as string;
}, 60_000);
afterAll(async () => {
  await h?.stop();
});
beforeEach(() => {
  vi.clearAllMocks();
});

describe("computer file thumbnails", () => {
  it("relays the bytes from a running computer, privately cacheable, without touching it", async () => {
    await setState("running");
    thumbnail.mockResolvedValueOnce({
      data: JPEG,
      contentType: "image/jpeg",
      mtimeMs: 1_700_000_000_000,
      durationMs: 12_345,
    });
    const ensure = vi.spyOn(svc, "ensureRunning");
    const res = await h.request(url("Passports/clip.mp4", 9999), { token: owner.token });
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toBe("image/jpeg");
    expect(res.headers.get("cache-control")).toBe("private, max-age=86400");
    expect(res.headers.get("x-duration-ms")).toBe("12345");
    expect(res.headers.get("x-file-mtime")).toBe("1700000000000");
    expect(new Uint8Array(await res.arrayBuffer())).toEqual(JPEG);
    // The size is clamped to 640.
    expect(thumbnail).toHaveBeenCalledWith("Passports/clip.mp4", 640);
    expect(ensure).not.toHaveBeenCalled();
    expect(provider.resume).not.toHaveBeenCalled();
    // A thumbnail is not activity: it never keeps a computer awake.
    expect(await lastActive()).toBe("2026-01-01T00:00:00.000Z");
    ensure.mockRestore();
  });

  it("never wakes a sleeping or stopped computer: answers 409 at once", async () => {
    const ensure = vi.spyOn(svc, "ensureRunning");
    for (const state of ["sleeping", "stopped", "error"]) {
      await setState(state);
      const res = await h.request(url("clip.mp4"), { token: owner.token });
      expect(res.status).toBe(409);
      expect((await j(res)).code).toBe("thumbnail_unavailable");
    }
    expect(ensure).not.toHaveBeenCalled();
    expect(provider.resume).not.toHaveBeenCalled();
    expect(provider.create).not.toHaveBeenCalled();
    // The stored state alone decides: the sandbox isn't even looked up.
    expect(provider.get).not.toHaveBeenCalled();
    expect(thumbnail).not.toHaveBeenCalled();
    ensure.mockRestore();
  });

  it("a row that says running but whose sandbox is gone is unavailable, not restarted", async () => {
    await setState("running");
    provider.get.mockResolvedValueOnce(null);
    const res = await h.request(url("clip.mp4"), { token: owner.token });
    expect(res.status).toBe(409);
    expect(provider.resume).not.toHaveBeenCalled();
  });

  it("404 when the computer has no thumbnail for the file; 409 when it can't be reached", async () => {
    await setState("running");
    thumbnail.mockResolvedValueOnce(null);
    const none = await h.request(url("notes.txt"), { token: owner.token });
    expect(none.status).toBe(404);
    expect((await j(none)).code).toBe("no_thumbnail");
    thumbnail.mockRejectedValueOnce(new Error("timed out"));
    const slow = await h.request(url("big.mov"), { token: owner.token });
    expect(slow.status).toBe(409);
  });

  it("refuses people outside the workspace before reaching the computer", async () => {
    await setState("running");
    const res = await h.request(url("clip.mp4"), { token: stranger.token });
    expect(res.status).toBe(404);
    const anon = await h.request(url("clip.mp4"));
    expect(anon.status).toBe(401);
    expect(provider.get).not.toHaveBeenCalled();
    expect(thumbnail).not.toHaveBeenCalled();
  });

  it("answers 503 computer_unavailable, not a 500, when the computer can't be reached", async () => {
    await setState("running");
    screenshot.mockRejectedValueOnce(
      new SandboxError("computer_unreachable", "computerd unreachable: fetch failed"),
    );
    const res = await h.request(`/v1/computers/${computerId}/screenshot`, { token: owner.token });
    expect(res.status).toBe(503);
    expect((await j(res)).code).toBe("computer_unavailable");
  });
});
