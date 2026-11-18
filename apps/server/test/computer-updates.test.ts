import { ComputerService } from "@casama/agent";
import type { SandboxHandle, SandboxProvider } from "@casama/sandbox";
import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

/**
 * Computer updates on the person's terms (D-360): the worker marks running computers that are
 * behind the current image, any start clears the mark, and the person applies it when they like.
 */

let h: Harness;
let owner: { id: string; token: string };
let stranger: { id: string; token: string };
let orgId: string;
let computerId: string;
let svc: ComputerService;

let runningExecs = 0;
const handle = {
  ref: "fake",
  health: async () => ({ ok: true, runningExecs }),
} as unknown as SandboxHandle;
let status: Array<{ ref: string; current: boolean }> | null = [];
const provider = {
  id: "docker",
  capabilities: { desktop: false, snapshots: true, liveStream: false },
  get: vi.fn(async () => handle),
  create: vi.fn(async () => handle),
  resume: vi.fn(async () => handle),
  sleep: vi.fn(async () => ({
    key: "snap/1.tar.gz",
    size: 5,
    createdAt: new Date().toISOString(),
  })),
  destroy: vi.fn(),
  imageStatus: async () => status,
} as unknown as SandboxProvider & {
  resume: ReturnType<typeof vi.fn>;
  sleep: ReturnType<typeof vi.fn>;
};

const since = async () =>
  (
    await h.tdb.admin<{ s: string | null }[]>`
      select update_available_since::text as s from public.computers where id = ${computerId}`
  )[0]?.s ?? null;
const api = (init: { json?: unknown; token?: string } = {}) =>
  h.request(`/v1/computers/${computerId}/apply-update`, {
    method: "POST",
    token: owner.token,
    json: {},
    ...init,
  });

beforeAll(async () => {
  h = await startHarness();
  svc = new ComputerService(h.handle.db, provider);
  (h.deps as { computers?: unknown }).computers = svc;
  owner = await h.user("updates-owner@example.com");
  stranger = await h.user("updates-stranger@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", {
        method: "POST",
        token: owner.token,
        json: { name: "Updates" },
      }),
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
  runningExecs = 0;
  await h.tdb.admin`update public.computers set state = 'running', running_since = now(),
    update_available_since = null where id = ${computerId}`;
});

describe("checkUpdates", () => {
  it("marks a computer behind the image once, and clears it when current or gone", async () => {
    status = [{ ref: computerId, current: false }];
    expect(await svc.checkUpdates()).toBe(1);
    const first = await since();
    expect(first).not.toBeNull();
    // The first minute it was seen stays: the app can say how long an update has waited.
    await svc.checkUpdates();
    expect(await since()).toBe(first);

    status = [{ ref: computerId, current: true }];
    await svc.checkUpdates();
    expect(await since()).toBeNull();

    status = [{ ref: computerId, current: false }];
    await svc.checkUpdates();
    status = []; // asleep: not running any more
    await svc.checkUpdates();
    expect(await since()).toBeNull();
  });

  it("changes nothing when the supervisor can't tell", async () => {
    await h.tdb
      .admin`update public.computers set update_available_since = now() where id = ${computerId}`;
    status = null;
    expect(await svc.checkUpdates()).toBe(0);
    expect(await since()).not.toBeNull();
  });

  it("is cleared by any start, which always uses the current image", async () => {
    await h.tdb.admin`update public.computers set update_available_since = now(), state = 'sleeping'
      where id = ${computerId}`;
    provider.get = vi.fn(async () => null) as never;
    try {
      await svc.ensureRunning(computerId);
    } finally {
      provider.get = vi.fn(async () => handle) as never;
    }
    expect(provider.resume).toHaveBeenCalled();
    expect(await since()).toBeNull();
  });
});

describe("POST /v1/computers/{id}/apply-update", () => {
  it("says so when there is nothing to update", async () => {
    const res = await api();
    expect(res.status).toBe(409);
    expect((await j(res)).code).toBe("no_update");
    expect(provider.sleep).not.toHaveBeenCalled();
  });

  it("restarts the computer, keeps its files, clears the mark and records it", async () => {
    await h.tdb
      .admin`update public.computers set update_available_since = now() where id = ${computerId}`;
    const res = await api();
    expect(res.status).toBe(200);
    const body = await j(res);
    expect(body.update_available_since).toBeNull();
    expect(body.state).toBe("running");
    // Sleep archives the home folder; the start restores it into a new container.
    expect(provider.sleep).toHaveBeenCalledWith(computerId);
    expect(provider.resume.mock.calls[0]?.[1]).toMatchObject({ key: "snap/1.tar.gz" });
    const [a] = await h.tdb.admin<{ actor_id: string; metadata: { force: boolean } }[]>`
      select actor_id, metadata from public.audit_log
      where target_id = ${computerId} and action = 'computer.updated'`;
    expect(a?.actor_id).toBe(owner.id);
    expect(a?.metadata.force).toBe(false);
  });

  it("waits while a command runs, unless asked to update anyway", async () => {
    await h.tdb
      .admin`update public.computers set update_available_since = now() where id = ${computerId}`;
    runningExecs = 1;
    const busy = await api();
    expect(busy.status).toBe(409);
    expect((await j(busy)).code).toBe("computer_busy");
    expect(provider.sleep).not.toHaveBeenCalled();
    const forced = await api({ json: { force: true } });
    expect(forced.status).toBe(200);
    expect(provider.sleep).toHaveBeenCalled();
  });

  it("shows the mark on the computer and hides the computer from strangers", async () => {
    await h.tdb
      .admin`update public.computers set update_available_since = now() where id = ${computerId}`;
    const list = await j(await h.request(`/v1/computers?org_id=${orgId}`, { token: owner.token }));
    const mine = list.items.find((c: { id: string }) => c.id === computerId);
    expect(mine.update_available_since).toMatch(/^\d{4}-/);
    expect((await api({ token: stranger.token })).status).toBe(404);
  });
});
