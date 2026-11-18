/**
 * System permissions on the person's own devices (D-376): what devices report, the card's buttons
 * (a computer's socket, a phone's notification), "Not now", and the cards runs show by themselves.
 */
import {
  cardForToolError,
  loadPerson,
  personBlock,
  registerDeviceTools,
  ToolRegistry,
} from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const KEY = "perm-phone-0001";
let h: Harness;
let owner: { id: string; token: string };
let mate: { id: string; token: string };
let orgId: string;
let botId: string;
let computerId: string;
let deviceId: string;
let sourceId: string;

/** A connected desktop app, as the device registry sees it: records what it's sent. */
function fakeSocket() {
  const sent: Array<Record<string, unknown>> = [];
  const handlers: Record<string, Array<() => void>> = {};
  const ws = {
    OPEN: 1,
    readyState: 1,
    send: (m: string) => sent.push(JSON.parse(m)),
    on: (ev: string, f: () => void) => {
      (handlers[ev] ??= []).push(f);
    },
    ping: () => {},
    terminate: () => {},
    close: () => {
      for (const f of handlers.close ?? []) f();
    },
  };
  return { ws, sent };
}

type Ev = { type: string; payload: Record<string, unknown> };
function emitter() {
  const evs: Ev[] = [];
  return {
    evs,
    emit: async (type: string, payload: Record<string, unknown>) =>
      void evs.push({ type, payload }),
  };
}
const newRun = async (createdBy: string) =>
  (
    await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, created_by) values (${orgId}, ${botId}, ${createdBy}) returning id`
  )[0]!.id;

beforeAll(async () => {
  h = await startHarness({ local: true });
  owner = await h.user("perm-owner@example.com");
  mate = await h.user("perm-mate@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Perms" } }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${mate.id}, 'member')`;
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Deskhand" },
      }),
    )
  ).id;
  const [c] = await h.tdb.admin<{ id: string }[]>`
    insert into public.computers (org_id, kind, name, provider) values (${orgId}, 'local', 'Ana Mac', 'local') returning id`;
  computerId = c!.id;
  const [d] = await h.tdb.admin<{ id: string }[]>`
    insert into public.local_devices (org_id, user_id, computer_id, platform, token_hash, allowed_roots, capabilities, name)
    values (${orgId}, ${owner.id}, ${computerId}, 'macos', 'perm-x', '{}', '{"shell":true}', 'MacBook Pro') returning id`;
  deviceId = d!.id;
  sourceId = (
    await j(
      await h.request(`/v1/device-sources/${KEY}`, {
        method: "PUT",
        token: owner.token,
        json: { name: "Ana's iPhone", platform: "ios", kinds: { places: {} } },
      }),
    )
  ).id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

describe("device permissions API", () => {
  it("lists the person's devices with Casama's own settings filled in", async () => {
    const list = await j(await h.request("/v1/device-permissions", { token: owner.token }));
    const mac = list.items.find((d: { type: string }) => d.type === "computer");
    expect(mac).toMatchObject({
      device_ref: `computer:${deviceId}`,
      id: deviceId,
      name: "MacBook Pro",
      platform: "macos",
      reported_at: null,
      online: false,
      permissions: { shared_folders: "denied", local_tools: "denied" },
    });
    const phone = list.items.find((d: { type: string }) => d.type === "source");
    expect(phone).toMatchObject({
      device_ref: `source:${sourceId}`,
      online: true,
      permissions: {},
    });
    // Nobody else sees them.
    expect(
      (await j(await h.request("/v1/device-permissions", { token: mate.token }))).items,
    ).toEqual([]);
    expect((await h.request("/v1/device-permissions")).status).toBe(401);
  });

  it("a device reports what the system allows; only its owner can", async () => {
    const put = (token: string, type: string, id: string, permissions: Record<string, string>) =>
      h.request(`/v1/device-permissions/${type}/${id}`, {
        method: "PUT",
        token,
        json: { permissions },
      });
    const r = await j(
      await put(owner.token, "computer", deviceId, {
        accessibility: "denied",
        screen_recording: "not_asked",
        automation: "granted",
      }),
    );
    expect(r.permissions).toMatchObject({
      accessibility: "denied",
      screen_recording: "not_asked",
      automation: "granted",
      shared_folders: "denied",
    });
    expect(r.reported_at).toEqual(expect.any(String));
    expect((await put(mate.token, "computer", deviceId, { accessibility: "granted" })).status).toBe(
      404,
    );
    expect((await put(owner.token, "computer", deviceId, { accessibility: "maybe" })).status).toBe(
      400,
    );
    const phone = await j(
      await put(owner.token, "source", sourceId, { location_always: "denied", camera: "granted" }),
    );
    expect(phone.permissions).toEqual({ location_always: "denied", camera: "granted" });
  });

  it("a card's button reaches the computer over its socket, or says it's offline", async () => {
    const ask = (json: Record<string, unknown>) =>
      h.request(`/v1/device-permissions/computer/${deviceId}/ask`, {
        method: "POST",
        token: owner.token,
        json,
      });
    const offline = await ask({ permission: "screen_recording", do: "open_settings" });
    expect(offline.status).toBe(409);
    expect((await j(offline)).code).toBe("device_offline");

    const { ws, sent } = fakeSocket();
    h.deps.devices!.attach(computerId, deviceId, ws as never);
    try {
      const ok = await j(
        await ask({ permission: "screen_recording", do: "request", bot_id: botId }),
      );
      expect(ok).toEqual({ via: "socket" });
      expect(sent).toEqual([
        { type: "permission", permission: "screen_recording", do: "request", bot_id: botId },
      ]);
      // A permission a Mac doesn't have, or one nobody knows.
      expect((await ask({ permission: "location_always", do: "request" })).status).toBe(400);
      const unknown = await ask({ permission: "telepathy", do: "request" });
      expect(unknown.status).toBe(400);
      expect((await j(unknown)).code).toBe("unknown_permission");
      // Someone else's device doesn't exist for them.
      expect(
        (
          await h.request(`/v1/device-permissions/computer/${deviceId}/ask`, {
            method: "POST",
            token: mate.token,
            json: { permission: "screen_recording", do: "request" },
          })
        ).status,
      ).toBe(404);
    } finally {
      ws.close();
    }
  });

  it("on a phone it becomes a notification to tap, opening Casama into the prompt", async () => {
    const r = await j(
      await h.request(`/v1/device-permissions/source/${sourceId}/ask`, {
        method: "POST",
        token: owner.token,
        json: { permission: "location_always", do: "request", bot_id: botId },
      }),
    );
    expect(r).toEqual({ via: "notification" });
    const [n] = await h.tdb.admin<
      { kind: string; payload: Record<string, string>; push_status: string }[]
    >`select kind, payload, push_status from public.notifications where user_id = ${owner.id} and kind = 'permission'`;
    expect(n).toMatchObject({
      kind: "permission",
      push_status: "deferred",
      payload: {
        title: "Turn on Location in the background",
        body: "Deskhand asked for Location in the background on Ana's iPhone. Tap to turn it on.",
        link: `/permissions?device=source%3A${sourceId}&ask=location_always&do=request`,
        bot_id: botId,
      },
    });
    // Screen Recording isn't something an iPhone has.
    expect(
      (
        await h.request(`/v1/device-permissions/source/${sourceId}/ask`, {
          method: "POST",
          token: owner.token,
          json: { permission: "screen_recording", do: "request" },
        })
      ).status,
    ).toBe(400);
  });

  it("Not now quiets that bot for a day, and old entries go", async () => {
    await h.tdb.admin`update public.local_devices set permission_snoozes = ${JSON.stringify({
      "old:accessibility": new Date(Date.now() - 1000).toISOString(),
    })}::text::jsonb where id = ${deviceId}`;
    const r = await j(
      await h.request(`/v1/device-permissions/computer/${deviceId}/snooze`, {
        method: "POST",
        token: owner.token,
        json: { bot_id: botId, permissions: ["accessibility", "screen_recording"] },
      }),
    );
    expect(new Date(r.until).getTime()).toBeGreaterThan(Date.now() + 23 * 3600_000);
    const [row] = await h.tdb.admin<{ s: Record<string, string> }[]>`
      select permission_snoozes as s from public.local_devices where id = ${deviceId}`;
    expect(Object.keys(row!.s).sort()).toEqual([
      `${botId}:accessibility`,
      `${botId}:screen_recording`,
    ]);
    await h.tdb
      .admin`update public.local_devices set permission_snoozes = '{}' where id = ${deviceId}`;
  });
});

describe("cards a run shows by itself", () => {
  it("a failed desktop tool on the person's own Mac shows one card per run, in their own runs only", async () => {
    // The bot works on a cloud computer: nothing to show.
    const runId = await newRun(owner.id);
    const e = emitter();
    const t = { runId, botId, actingUserId: owner.id, emit: e.emit };
    const err = ["perm_denied", "Screen Recording permission not granted"] as const;
    expect(await cardForToolError(h.deps.db, t, ...err)).toBeNull();

    await h.tdb
      .admin`update public.bots set default_computer_id = ${computerId} where id = ${botId}`;
    const text = await cardForToolError(h.deps.db, t, ...err);
    expect(text).toContain("card to turn on Screen Recording on MacBook Pro");
    expect(e.evs).toEqual([
      {
        type: "device.permission_needed",
        payload: {
          device_ref: `computer:${deviceId}`,
          device_name: "MacBook Pro",
          platform: "macos",
          permissions: ["screen_recording"],
          reason: "So I can take screenshots of your screen",
          bot_id: botId,
        },
      },
    ]);
    // Again in the same run: the model is told again, the card isn't posted twice.
    expect(await cardForToolError(h.deps.db, t, ...err)).toContain("card");
    expect(e.evs).toHaveLength(1);
    // Accessibility is new in this run; folders come from the device's settings.
    await cardForToolError(h.deps.db, t, "perm_denied", "Accessibility permission not granted");
    await cardForToolError(h.deps.db, t, "no_folders", "No folders");
    expect(e.evs.map((x) => x.payload.permissions)).toEqual([
      ["screen_recording"],
      ["accessibility"],
      ["shared_folders"],
    ]);
    // Errors that aren't about a permission, and someone else's run, show nothing.
    expect(await cardForToolError(h.deps.db, t, "timeout", "took too long")).toBeNull();
    const other = emitter();
    expect(
      await cardForToolError(
        h.deps.db,
        { runId: await newRun(mate.id), botId, actingUserId: mate.id, emit: other.emit },
        ...err,
      ),
    ).toBeNull();
    expect(other.evs).toEqual([]);
  });

  it("after Not now the bot is told to carry on, and no card comes", async () => {
    await h.tdb.admin`update public.local_devices set permission_snoozes = ${JSON.stringify({
      [`${botId}:screen_recording`]: new Date(Date.now() + 3600_000).toISOString(),
    })}::text::jsonb where id = ${deviceId}`;
    const e = emitter();
    const text = await cardForToolError(
      h.deps.db,
      { runId: await newRun(owner.id), botId, actingUserId: owner.id, emit: e.emit },
      "screen_recording_denied",
      "Screen Recording is off for Casama on this Mac",
    );
    expect(text).toContain("They said not now to Screen Recording on MacBook Pro recently");
    expect(e.evs).toEqual([]);
    await h.tdb
      .admin`update public.local_devices set permission_snoozes = '{}' where id = ${deviceId}`;
  });

  it("device.read stops with a card when the phone's system permission is off", async () => {
    await h.request("/v1/device-grants", {
      method: "PUT",
      token: owner.token,
      json: { bot_id: botId, kind: "places", allowed: true },
    });
    const registry = new ToolRegistry();
    registerDeviceTools(registry, { db: h.deps.db, waitMs: { read: 50, write: 50 } });
    const e = emitter();
    const ctx = {
      runId: await newRun(owner.id),
      botId,
      orgId,
      output: async () => {},
      emit: e.emit,
    };
    // The phone reported Location in the background as off (see above).
    await expect(
      registry.get("device.read")!.execute({ kind: "places" }, ctx),
    ).rejects.toMatchObject({
      code: "permission_off",
      message: expect.stringContaining("Location in the background on Ana's iPhone"),
    });
    expect(e.evs).toMatchObject([
      {
        type: "device.permission_needed",
        payload: { device_ref: `source:${sourceId}`, permissions: ["location_always"] },
      },
    ]);
    // Once it's on, the read goes ahead (nothing stored yet: no items).
    await h.tdb
      .admin`update public.device_sources set permissions = '{"location_always":"granted"}' where id = ${sourceId}`;
    const res = await registry.get("device.read")!.execute({ kind: "places" }, ctx);
    expect(res.content).toContain("No places");
  });

  it("device.request_permission picks the device that fits and skips what's on", async () => {
    const registry = new ToolRegistry();
    registerDeviceTools(registry, { db: h.deps.db });
    const tool = registry.get("device.request_permission")!;
    const e = emitter();
    const ctx = {
      runId: await newRun(owner.id),
      botId,
      orgId,
      output: async () => {},
      emit: e.emit,
    };
    // Screen Recording: the bot's own computer, the person's Mac.
    const mac = await tool.execute(
      { permissions: ["screen_recording"], reason: "To check the page" },
      ctx,
    );
    expect(mac.content).toBe(
      "Showed them a card to turn on Screen Recording on MacBook Pro. Wait for them; don't repeat the steps in text.",
    );
    expect(e.evs.at(-1)?.payload).toMatchObject({
      device_ref: `computer:${deviceId}`,
      reason: "To check the page",
    });
    // Camera: only the phone has it; it's on there already.
    await h.tdb
      .admin`update public.device_sources set permissions = '{"camera":"granted"}' where id = ${sourceId}`;
    expect((await tool.execute({ permissions: ["camera"], reason: "x" }, ctx)).content).toBe(
      "Already on: Camera.",
    );
    // By name; a name they don't have; a permission that device can't have.
    const phone = await tool.execute(
      { permissions: ["photos"], device: "iphone", reason: "To find the receipt" },
      ctx,
    );
    expect(phone.content).toContain("Photos on Ana's iPhone");
    await expect(
      tool.execute({ permissions: ["photos"], device: "Pixel", reason: "x" }, ctx),
    ).rejects.toMatchObject({ code: "device_not_found" });
    await expect(
      tool.execute({ permissions: ["photos"], device: "MacBook", reason: "x" }, ctx),
    ).rejects.toMatchObject({ code: "permission_not_here" });
    await expect(
      tool.execute({ permissions: ["notification_access"], reason: "x" }, ctx),
    ).rejects.toMatchObject({ code: "no_device" });
  });

  it("the bot's prompt names what's off on the person's devices", async () => {
    await h.tdb
      .admin`update public.local_devices set permissions = '{"accessibility":"denied","screen_recording":"granted"}' where id = ${deviceId}`;
    await h.tdb
      .admin`update public.device_sources set permissions = '{"location_always":"denied"}' where id = ${sourceId}`;
    const p = await loadPerson(h.deps.db, owner.id, orgId, botId);
    expect(p?.permissions).toEqual([
      "MacBook Pro: Accessibility is off; no shared folders.",
      "Ana's iPhone: Location in the background is off.",
    ]);
    expect(personBlock(p)).toContain(
      "Off on their devices: MacBook Pro: Accessibility is off; no shared folders. Ana's iPhone: Location in the background is off. If you need one, device.request_permission shows them a card to turn it on.",
    );
    // Everything on: no line at all.
    await h.tdb
      .admin`update public.local_devices set permissions = '{"accessibility":"granted"}', allowed_roots = '{/Users/ana}' where id = ${deviceId}`;
    await h.tdb
      .admin`update public.device_sources set permissions = '{"location_always":"granted"}' where id = ${sourceId}`;
    const q = await loadPerson(h.deps.db, owner.id, orgId, botId);
    expect(q?.permissions).toBeUndefined();
    expect(personBlock(q)).not.toContain("Off on their devices");
  });
});
