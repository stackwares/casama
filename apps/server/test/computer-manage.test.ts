import { ComputerService, resetScript } from "@casama/agent";
import type { ExecChunk, SandboxHandle, SandboxProvider } from "@casama/sandbox";
import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import {
  ARCHIVE_SCRIPT,
  CLEAN_SCRIPT,
  PROCESSES_SCRIPT,
  parseProcesses,
  parseStorage,
  parseVitals,
  STORAGE_SCRIPT,
  VITALS_SCRIPT,
} from "../src/api/routes/computers.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

/**
 * Managing a computer (D-240): vitals, storage, programs, reset, sleep timer, usage, history,
 * the bots that use it and downloading every file. Looking never wakes a computer.
 */

let h: Harness;
let owner: { id: string; token: string };
let member: { id: string; token: string };
let stranger: { id: string; token: string };
let orgId: string;
let computerId: string;
let svc: ComputerService;
const background: Promise<unknown>[] = [];

/** What each script prints on the fake computer. */
const replies = new Map<string, { stdout: string; code?: number }>();
const execs: string[] = [];
const exec = vi.fn(async function* (cmd: string): AsyncIterable<ExecChunk> {
  execs.push(cmd);
  const r = [...replies].find(([k]) => cmd === k || cmd.startsWith(k))?.[1] ?? { stdout: "" };
  yield { type: "start", execId: "e1" } as ExecChunk;
  if (r.stdout) yield { type: "stdout", data: r.stdout } as ExecChunk;
  yield { type: "exit", code: r.code ?? 0, timedOut: false, truncated: false } as ExecChunk;
});
const readFile = vi.fn(async () => new Uint8Array([0x50, 0x4b, 3, 4]));
const checkpoint = vi.fn(async () => ({ key: "cp/1.tar.gz", size: 10 }));
const handle = {
  ref: "fake",
  exec,
  readFile,
  checkpoint,
  health: async () => ({ ok: true, runningExecs: 0 }),
} as unknown as SandboxHandle;
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
} as unknown as SandboxProvider & {
  get: ReturnType<typeof vi.fn>;
  resume: ReturnType<typeof vi.fn>;
  sleep: ReturnType<typeof vi.fn>;
};

const setState = (state: string) =>
  h.tdb
    .admin`update public.computers set state = ${state}, running_since = null, last_active_at = '2026-01-01T00:00:00Z' where id = ${computerId}`;
const api = (path: string, init: { method?: string; json?: unknown; token?: string } = {}) =>
  h.request(`/v1/computers/${computerId}${path}`, { token: owner.token, ...init });

beforeAll(async () => {
  h = await startHarness();
  svc = new ComputerService(h.handle.db, provider);
  (h.deps as { computers?: unknown }).computers = svc;
  (h.deps as { onBackgroundTask?: unknown }).onBackgroundTask = (p: Promise<unknown>) =>
    background.push(p);
  owner = await h.user("manage-owner@example.com");
  member = await h.user("manage-member@example.com");
  stranger = await h.user("manage-stranger@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Manage" } }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
  const [c] = await h.tdb.admin<{ id: string }[]>`
    select id from public.computers where org_id = ${orgId} and kind = 'team'`;
  computerId = c?.id as string;
}, 60_000);
afterAll(async () => {
  await h?.stop();
});
beforeEach(() => {
  vi.clearAllMocks();
  execs.length = 0;
  replies.clear();
});

describe("parsers", () => {
  it("vitals: CPU of the cores it has, memory without page cache, disk against its size", () => {
    const v = parseVitals(
      "cpu_usec=150000\ncpu_max=200000 100000\nmem=600000000\nmem_inactive=100000000\nmem_max=max\ndisk=8000000000",
      { cpus: 2, memory_mb: 4096, disk_gb: 10 },
    );
    expect(v.cpu_percent).toBe(25); // 0.15 s of 0.3 s × 2 cores
    expect(v.memory_used_bytes).toBe(500_000_000);
    expect(v.memory_limit_bytes).toBe(4096 * 1024 ** 2);
    expect(v.disk_used_bytes).toBe(8_000_000_000);
    expect(v.disk_limit_bytes).toBe(10 * 1024 ** 3);
    // Garbage never goes negative or over 100.
    const bad = parseVitals("cpu_usec=-5\nmem=abc", {});
    expect(bad.cpu_percent).toBe(0);
    expect(bad.memory_used_bytes).toBe(0);
  });

  it("storage: the rest of the home folder is 'other'; caches and browser caches are cleanable", () => {
    const s = parseStorage(
      "total=1000\nfiles=400\napps=100\ncaches=150\nbrowser=200\nbrowser_cache=50",
      { disk_gb: 10 },
    );
    expect(s.used_bytes).toBe(1000);
    expect(s.categories.find((c) => c.id === "other")?.bytes).toBe(150);
    expect(s.cleanable_bytes).toBe(200);
  });

  it("processes: helpers fold into their parent, and the computer's own parts are system", () => {
    const items = parseProcesses(
      [
        "uid=1000",
        "  1     0  900  0.0  1600  1000 tini       /usr/bin/tini -- computerd",
        "  7     1  900  0.5 20000     0 computerd  computerd",
        " 40     7  300 10.0 100000 1000 chrome     /usr/local/bin/chrome --headless",
        " 41    40  300 20.0 200000 1000 chrome     /usr/local/bin/chrome --type=renderer",
        " 42    40  300  5.0  50000 1000 chrome     /usr/local/bin/chrome --type=gpu",
        " 90     7   60 30.0  30000 1000 python3    python3 scrape.py",
      ].join("\n"),
    );
    const chrome = items.find((p) => p.name === "chrome");
    expect(chrome).toMatchObject({ pid: 40, cpu_percent: 35, memory_bytes: 350000 * 1024 });
    expect(items.filter((p) => p.name === "chrome")).toHaveLength(1);
    expect(items[0]?.name).toBe("chrome");
    expect(items.find((p) => p.name === "python3")).toMatchObject({
      system: false,
      elapsed_seconds: 60,
      command: "python3 scrape.py",
    });
    expect(items.find((p) => p.pid === 1)?.system).toBe(true);
    expect(items.find((p) => p.name === "computerd")?.system).toBe(true);
  });

  it("reset keeps ~/workspace unless it erases", () => {
    expect(resetScript("system")).toContain("! -name workspace");
    expect(resetScript("erase")).not.toContain("! -name workspace");
    for (const s of [resetScript("system"), resetScript("erase")])
      expect(s).toContain('mkdir -p "$HOME/workspace"');
  });
});

describe("looking never wakes the computer", () => {
  it("vitals, storage and programs answer 409 while it sleeps, without starting it", async () => {
    await setState("sleeping");
    for (const path of ["/vitals", "/storage", "/processes"]) {
      const res = await api(path);
      expect(res.status, path).toBe(409);
      expect((await j(res)).code).toBe("computer_not_running");
    }
    expect(provider.resume).not.toHaveBeenCalled();
    expect(exec).not.toHaveBeenCalled();
  });

  it("reads vitals, storage and programs from a running computer without touching it", async () => {
    await setState("running");
    replies.set(VITALS_SCRIPT, {
      stdout: "cpu_usec=30000\ncpu_max=max 100000\nmem=200\nmem_inactive=0\nmem_max=max\ndisk=5",
    });
    replies.set(STORAGE_SCRIPT, { stdout: "total=10\nfiles=6\ncaches=4" });
    replies.set(PROCESSES_SCRIPT, {
      stdout: "uid=1000\n 90 7 60 3.0 3000 1000 python3 python3 job.py",
    });
    const vitals = await j(await api("/vitals"));
    expect(vitals.cpu_percent).toBe(10);
    expect(vitals.disk_limit_bytes).toBe(10 * 1024 ** 3);
    const storage = await j(await api("/storage"));
    expect(storage).toMatchObject({ used_bytes: 10, cleanable_bytes: 4 });
    const procs = await j(await api("/processes"));
    expect(procs.items).toEqual([expect.objectContaining({ pid: 90, name: "python3" })]);
    const [row] = await h.tdb.admin<{ t: Date }[]>`
      select last_active_at as t from public.computers where id = ${computerId}`;
    expect(row?.t.toISOString()).toBe("2026-01-01T00:00:00.000Z");
    expect(provider.resume).not.toHaveBeenCalled();
  });

  it("people outside the workspace can't look", async () => {
    expect((await api("/vitals", { token: stranger.token })).status).toBe(404);
    expect((await api("/usage", { token: stranger.token })).status).toBe(404);
    expect((await api("/history", { token: stranger.token })).status).toBe(404);
  });
});

describe("doing things", () => {
  it("stops a program, refuses the computer's own parts, and logs it", async () => {
    await setState("running");
    replies.set("p=90\n", { stdout: "python3\n" });
    replies.set("p=7\n", { stdout: "", code: 45 });
    replies.set("p=55\n", { stdout: "", code: 44 });
    const ok = await api("/processes/90/stop", { method: "POST" });
    expect(ok.status).toBe(200);
    expect(await j(ok)).toEqual({ stopped: 90 });
    expect((await api("/processes/7/stop", { method: "POST" })).status).toBe(400);
    expect((await api("/processes/55/stop", { method: "POST" })).status).toBe(404);
    expect((await api("/processes/1/stop", { method: "POST" })).status).toBe(400);
    const history = await j(await api("/history"));
    expect(history.items[0]).toMatchObject({
      action: "computer.process_stopped",
      actor_type: "user",
      actor_id: owner.id,
      metadata: { pid: 90, name: "python3" },
    });
  });

  it("frees up space and says how much", async () => {
    await setState("running");
    let calls = 0;
    exec.mockImplementation(async function* (cmd: string): AsyncIterable<ExecChunk> {
      execs.push(cmd);
      const stdout =
        cmd === STORAGE_SCRIPT ? (calls++ === 0 ? "total=1000\ncaches=300" : "total=700") : "";
      yield { type: "start", execId: "e" } as ExecChunk;
      if (stdout) yield { type: "stdout", data: stdout } as ExecChunk;
      yield { type: "exit", code: 0, timedOut: false, truncated: false } as ExecChunk;
    });
    const res = await j(await api("/storage/clean", { method: "POST" }));
    expect(res.freed_bytes).toBe(300);
    expect(res.storage.used_bytes).toBe(700);
    expect(execs).toContain(CLEAN_SCRIPT);
    exec.mockReset();
    exec.mockImplementation(async function* (cmd: string): AsyncIterable<ExecChunk> {
      execs.push(cmd);
      const r = [...replies].find(([k]) => cmd === k || cmd.startsWith(k))?.[1] ?? { stdout: "" };
      yield { type: "start", execId: "e1" } as ExecChunk;
      if (r.stdout) yield { type: "stdout", data: r.stdout } as ExecChunk;
      yield { type: "exit", code: r.code ?? 0, timedOut: false, truncated: false } as ExecChunk;
    });
  });

  it("downloads every file as a zip, or says there are none", async () => {
    await setState("running");
    replies.set(ARCHIVE_SCRIPT, { stdout: "4\n" });
    const res = await api("/files/archive");
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toBe("application/zip");
    expect(res.headers.get("content-disposition")).toContain("-files.zip");
    expect(new Uint8Array(await res.arrayBuffer())).toEqual(new Uint8Array([0x50, 0x4b, 3, 4]));
    replies.set(ARCHIVE_SCRIPT, { stdout: "", code: 44 });
    const empty = await api("/files/archive");
    expect(empty.status).toBe(422);
    expect((await j(empty)).code).toBe("nothing_to_download");
    replies.set(ARCHIVE_SCRIPT, { stdout: String(2 * 1024 ** 3) });
    expect((await api("/files/archive")).status).toBe(413);
  });

  it("resets in the background: restore point, clear the home folder, fresh system", async () => {
    await setState("running");
    const res = await api("/reset", { method: "POST", json: { mode: "system" } });
    expect(res.status).toBe(202);
    const started = await j(res);
    expect(started.operation).toMatchObject({ kind: "reset_system", step: "saving" });
    // A second reset while this one runs is refused.
    expect((await api("/reset", { method: "POST", json: { mode: "erase" } })).status).toBe(409);
    await Promise.all(background.splice(0));
    const after = await j(await api(""));
    expect(after.operation).toMatchObject({ kind: "reset_system", step: "done", error: null });
    expect(after.operation.checkpoint_id).toBeTruthy();
    const [cp] = await h.tdb.admin<{ label: string }[]>`
      select label from public.checkpoints where id = ${after.operation.checkpoint_id}`;
    expect(cp?.label).toBe("Before reset");
    expect(execs).toContain(resetScript("system"));
    expect(provider.sleep).toHaveBeenCalled();
    expect(provider.resume).toHaveBeenCalled();
    const history = await j(await api("/history"));
    expect(history.items.map((i: { action: string }) => i.action)).toContain("computer.reset");
  });

  it("erases without a restore point when asked, and reports a failure on the computer", async () => {
    await setState("running");
    replies.set(resetScript("erase"), { stdout: "", code: 3 });
    const res = await api("/reset", {
      method: "POST",
      json: { mode: "erase", checkpoint: false },
    });
    expect(res.status).toBe(202);
    expect((await j(res)).operation).toMatchObject({ kind: "erase", step: "wiping" });
    await Promise.all(background.splice(0));
    const after = await j(await api(""));
    expect(after.operation).toMatchObject({ step: "failed", checkpoint_id: null });
    expect(after.operation.error).toContain("home folder");
    expect(checkpoint).not.toHaveBeenCalled();
  });

  it("only admins reset a team computer; members can still look", async () => {
    await setState("running");
    const res = await api("/reset", {
      method: "POST",
      json: { mode: "system" },
      token: member.token,
    });
    expect(res.status).toBe(403);
    expect((await api("/usage", { token: member.token })).status).toBe(200);
  });
});

describe("sleep timer, usage and bots", () => {
  it("sets the sleep timer; five minutes is the default", async () => {
    const res = await j(
      await h.request(`/v1/computers/${computerId}`, {
        method: "PATCH",
        token: owner.token,
        json: { idle_sleep_minutes: 30 },
      }),
    );
    expect(res.idle_sleep_minutes).toBe(30);
    expect(
      (
        await h.request(`/v1/computers/${computerId}`, {
          method: "PATCH",
          token: owner.token,
          json: { idle_sleep_minutes: 7 },
        })
      ).status,
    ).toBe(400);
    // Idle for 10 minutes: under its 30-minute timer, so it stays up.
    await h.tdb.admin`update public.computers set state = 'running', operation = null,
      last_active_at = now() - interval '10 minutes' where id = ${computerId}`;
    expect(await svc.sleepIdle()).not.toContain(computerId);
    await h.tdb
      .admin`update public.computers set last_active_at = now() - interval '31 minutes' where id = ${computerId}`;
    expect(await svc.sleepIdle()).toContain(computerId);
    const history = await j(await api("/history"));
    expect(history.items[0]).toMatchObject({
      action: "computer.slept",
      actor_type: "system",
      metadata: { reason: "idle" },
    });
    const back = await j(
      await h.request(`/v1/computers/${computerId}`, {
        method: "PATCH",
        token: owner.token,
        json: { idle_sleep_minutes: 5 },
      }),
    );
    expect(back.idle_sleep_minutes).toBe(5);
  });

  it("adds up this month's time and cost per computer, including the time it's on now", async () => {
    await h.tdb
      .admin`insert into public.usage_ledger (org_id, computer_id, kind, quantity, cost_usd, billable)
      values (${orgId}, ${computerId}, 'computer_seconds', 3600, 0.01, true),
             (${orgId}, null, 'computer_seconds', 999, 5, true)`;
    await h.tdb.admin`update public.computers set state = 'running',
      running_since = now() - interval '10 minutes' where id = ${computerId}`;
    const u = await j(await api("/usage"));
    expect(u.seconds).toBeGreaterThanOrEqual(3600 + 600);
    expect(u.seconds).toBeLessThan(3600 + 700);
    expect(u.cost_usd).toBeGreaterThan(0.01);
    expect(u.cost_usd).toBeLessThan(1);
    const today = new Date().toISOString().slice(0, 10);
    expect(u.days.at(-1)).toMatchObject({ date: today });
    expect(u.days[0].date).toBe(u.month_start);
  });

  it("lists the bots that use the computer", async () => {
    const bot = await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Helper" },
      }),
    );
    const res = await j(await api("/bots"));
    expect(res.items).toEqual(
      expect.arrayContaining([expect.objectContaining({ bot_id: bot.id, name: "Helper" })]),
    );
  });
});
