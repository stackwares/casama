import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { computerdBinary, type FakeDevice, startFakeDevice } from "./fake-device.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/local.json", import.meta.url));

describe("local computer companion (Phase 6)", () => {
  let h: Harness;
  let owner: { id: string; token: string };
  let orgId: string;
  let botId: string;
  let otherBotId: string;
  let device: { id: string; computer_id: string; token: string };
  let fake: FakeDevice;
  let home: string;

  const chat = async (bot: string, text: string) => {
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: bot },
      }),
    );
    const sent = await j(
      await h.request(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token: owner.token,
        json: { text },
      }),
    );
    return sent.run_id as string;
  };
  const settle = async (runId: string, until = ["completed", "failed", "waiting_approval"]) => {
    for (let i = 0; i < 300; i++) {
      const r = await j(await h.request(`/v1/runs/${runId}`, { token: owner.token }));
      if (until.includes(r.status)) return r;
      await new Promise((res) => setTimeout(res, 200));
    }
    throw new Error("run did not settle");
  };
  const events = async (runId: string) =>
    (await j(await h.request(`/v1/runs/${runId}/events?limit=500`, { token: owner.token })))
      .items as Array<{
      type: string;
      payload: Record<string, unknown>;
    }>;

  beforeAll(async () => {
    computerdBinary();
    home = mkdtempSync(join(tmpdir(), "casama-companion-"));
    mkdirSync(join(home, "Shared"));
    mkdirSync(join(home, "Private"));
    writeFileSync(join(home, "Shared", "report-draft.md"), "# Draft\n");
    writeFileSync(join(home, "Private", "passwords.txt"), "hunter2\n");
    h = await startHarness({ worker: { fixtures: FIXTURES }, local: true });
    owner = await h.user("companion-owner@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Companion" },
        }),
      )
    ).id;
    const cred = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-companion-key" },
      }),
    );
    const mk = async (name: string) =>
      (
        await j(
          await h.request("/v1/bots", {
            method: "POST",
            token: owner.token,
            json: {
              org_id: orgId,
              name,
              autonomy: "autonomous",
              model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
            },
          }),
        )
      ).id as string;
    botId = await mk("Ada");
    otherBotId = await mk("Rex");
  }, 180_000);
  afterAll(async () => {
    await fake?.close();
    await h?.stop();
    rmSync(home, { recursive: true, force: true });
  });

  it("pairs a device, which connects and shows online", async () => {
    const res = await h.request("/v1/local-devices", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, name: "Work laptop", platform: "macos" },
    });
    expect(res.status).toBe(201);
    device = await j(res);
    expect(device.token).toMatch(/^kdev_/);
    const patched = await j(
      await h.request(`/v1/local-devices/${device.id}`, {
        method: "PATCH",
        token: owner.token,
        json: {
          capabilities: { shell: true, files: true },
          allowed_roots: [join(home, "Shared")],
          allowed_bot_ids: [botId],
        },
      }),
    );
    expect(patched.capabilities).toEqual({ shell: true, files: true });
    fake = await startFakeDevice({
      serverUrl: h.serverUrl as string,
      token: device.token,
      roots: [join(home, "Shared")],
      capabilities: ["shell", "files"],
    });
    const list = await j(
      await h.request(`/v1/local-devices?org_id=${orgId}`, { token: owner.token }),
    );
    expect(list.items[0]).toMatchObject({ name: "Work laptop", online: true });
    // Bots use it once it is their computer.
    for (const b of [botId, otherBotId])
      await h.handle.db.execute(
        (await import("drizzle-orm"))
          .sql`update public.bots set default_computer_id = ${device.computer_id}::uuid where id = ${b}::uuid`,
      );
  }, 60_000);

  it("a bot runs a command in the shared folder on the user's machine, and the device sees who acts", async () => {
    const runId = await chat(botId, "Please list my shared folder.");
    expect((await settle(runId)).status).toBe("completed");
    const out = (await events(runId))
      .filter((e) => e.type === "tool.output")
      .map((e) => e.payload.chunk)
      .join("");
    expect(out).toContain("report-draft.md");
    expect(
      fake.activities.some((a) => a.bot === "Ada" && a.tool === "shell.exec" && a.run_id === runId),
    ).toBe(true);
  }, 60_000);

  it("refuses paths outside the shared folders", async () => {
    const runId = await chat(botId, "Please read my passwords.");
    await settle(runId);
    const failed = (await events(runId)).find((e) => e.type === "tool.failed");
    expect(JSON.stringify(failed?.payload)).toContain("outside the folders shared");
    expect(JSON.stringify(await events(runId))).not.toContain("hunter2");
  }, 60_000);

  it("refuses bots the user did not allow", async () => {
    const runId = await chat(otherBotId, "Please list my shared folder.");
    await settle(runId);
    const failed = (await events(runId)).find((e) => e.type === "tool.failed");
    expect(JSON.stringify(failed?.payload)).toContain("not allowed");
  }, 60_000);

  it("high-risk actions ask for approval on a personal computer even for autonomous bots", async () => {
    const runId = await chat(botId, "Please clean up old files.");
    expect((await settle(runId)).status).toBe("waiting_approval");
  }, 60_000);

  it("has no live view: the session is refused, and a takeover asks in chat instead (D-218)", async () => {
    const res = await h.request(`/v1/computers/${device.computer_id}/stream-session`, {
      method: "POST",
      token: owner.token,
      json: { mode: "view" },
    });
    expect(res.status).toBe(409);
    expect((await j(res)).code).toBe("not_on_companion");

    const runId = await chat(botId, "Please sign in to my bank.");
    expect((await settle(runId)).status).toBe("completed");
    expect(JSON.stringify(await events(runId))).toContain("can't take over from the app");
    const [row] = await h.handle.db.execute<{ n: number }>(
      (await import("drizzle-orm"))
        .sql`select count(*)::int as n from public.takeover_requests where run_id = ${runId}::uuid`,
    );
    expect(row?.n).toBe(0);
  }, 60_000);

  it("thumbnails: only the device's owner, only inside the shared folders, with no bot (D-226)", async () => {
    const thumb = (path: string, token: string) =>
      h.request(
        `/v1/computers/${device.computer_id}/files/thumbnail?path=${encodeURIComponent(path)}`,
        { token },
      );
    // The tunnel lets the owner through: computerd itself answers that a text file has none.
    const none = await thumb(join(home, "Shared", "report-draft.md"), owner.token);
    expect(none.status).toBe(404);
    expect((await j(none)).code).toBe("no_thumbnail");
    // Outside the shared folders computerd refuses, and the app just keeps its plain tile.
    const outside = await thumb(join(home, "Private", "passwords.txt"), owner.token);
    expect(outside.status).toBe(409);
    // Another member of the workspace can't look at the owner's computer this way.
    const member = await h.user("companion-member@example.com");
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
    const other = await thumb(join(home, "Shared", "report-draft.md"), member.token);
    expect(other.status).toBe(409);
    expect((await j(other)).code).toBe("thumbnail_unavailable");
  }, 60_000);

  it("the owner opens and lists files in the shared folders from the app, read-only (D-226)", async () => {
    const file = (path: string, token: string) =>
      h.request(`/v1/computers/${device.computer_id}/files?path=${encodeURIComponent(path)}`, {
        token,
      });
    const ok = await file(join(home, "Shared", "report-draft.md"), owner.token);
    expect(ok.status).toBe(200);
    expect((await ok.text()).length).toBeGreaterThan(0);
    const list = await h.request(
      `/v1/computers/${device.computer_id}/files/list?path=${encodeURIComponent(join(home, "Shared"))}`,
      { token: owner.token },
    );
    expect(list.status).toBe(200);
    expect(JSON.stringify(await j(list))).toContain("report-draft.md");
    // Still only inside the shared folders.
    const outside = await file(join(home, "Private", "passwords.txt"), owner.token);
    expect(outside.status).not.toBe(200);
    expect(await outside.text()).not.toContain("hunter2");
    // Another member is refused plainly, not told to try again.
    const member = await h.user("companion-reader@example.com");
    await h.tdb
      .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
    const other = await file(join(home, "Shared", "report-draft.md"), member.token);
    expect(other.status).toBe(403);
    expect((await j(other)).code).toBe("computer_forbidden");
    // Writing still needs a bot the owner allowed.
    const put = await h.request(
      `/v1/computers/${device.computer_id}/files?path=${encodeURIComponent(join(home, "Shared", "x.txt"))}`,
      { method: "PUT", token: owner.token, body: "hi" },
    );
    expect(put.status).toBe(403);
  }, 60_000);

  it("fails fast when the device is offline", async () => {
    await fake.close();
    await new Promise((r) => setTimeout(r, 300));
    const t0 = Date.now();
    const runId = await chat(botId, "Please list my shared folder.");
    await settle(runId);
    expect(Date.now() - t0).toBeLessThan(15_000);
    const failed = (await events(runId)).find((e) => e.type === "tool.failed");
    expect(JSON.stringify(failed?.payload)).toMatch(/offline|could not be reached|unavailable/i);
    // Opening a file says the computer is offline and what to do, not "try again shortly".
    const open = await h.request(
      `/v1/computers/${device.computer_id}/files?path=${encodeURIComponent(join(home, "Shared", "report-draft.md"))}`,
      { token: owner.token },
    );
    expect(open.status).toBe(409);
    const problem = await j(open);
    expect(problem.code).toBe("device_offline");
    expect(problem.detail).toContain("Use this computer for bots");
  }, 60_000);
});
