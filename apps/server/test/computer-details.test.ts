/**
 * Computer details on the card (D-227): the operating system and, for a personal computer, its
 * device (platform, connection, what bots may use). The desktop app reports its OS on connect.
 */
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { WebSocket } from "ws";
import { computerOs, DOCKER_COMPUTER_OS } from "../src/api/routes/computers.ts";
import { deviceOsVersion } from "../src/api/routes/local.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

describe("computer details (D-227)", () => {
  let h: Harness;
  let owner: { id: string; token: string };
  let orgId: string;
  let device: { id: string; computer_id: string; token: string };
  const sockets: WebSocket[] = [];

  beforeAll(async () => {
    h = await startHarness({ local: true });
    owner = await h.user("details-owner@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Details" },
        }),
      )
    ).id;
    device = await j(
      await h.request("/v1/local-devices", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, name: "Work laptop", platform: "macos" },
      }),
    );
    await h.request(`/v1/local-devices/${device.id}`, {
      method: "PATCH",
      token: owner.token,
      json: { capabilities: { files: true, shell: true } },
    });
  }, 120_000);
  afterAll(async () => {
    for (const s of sockets) s.close();
    await h?.stop();
  });

  const localComputer = async () => {
    const list = await j(await h.request(`/v1/computers?org_id=${orgId}`, { token: owner.token }));
    return list.items.find((c: { id: string }) => c.id === device.computer_id);
  };

  it("a personal computer shows its platform and access before the app reports more", async () => {
    const c = await localComputer();
    expect(c).toMatchObject({
      kind: "local",
      os: "macOS",
      device: {
        platform: "macos",
        online: false,
        last_seen_at: null,
        capabilities: { files: true, shell: true },
      },
    });
  });

  it("the OS the app reports on connect is kept, cleaned, and shown with the connection", async () => {
    const ws = new WebSocket(
      `${(h.serverUrl as string).replace("http", "ws")}/v1/local-computer/connect`,
      {
        headers: { authorization: `Device ${device.token}`, "x-casama-os": "  macOS\t26.2  " },
      },
    );
    sockets.push(ws);
    await new Promise<void>((resolve, reject) => {
      ws.once("message", () => resolve());
      ws.once("error", reject);
    });
    let c: Record<string, unknown> | undefined;
    for (let i = 0; i < 50; i++) {
      c = await localComputer();
      if (c?.os === "macOS 26.2" && (c.device as { online: boolean }).online) break;
      await new Promise((r) => setTimeout(r, 100));
    }
    expect(c?.os).toBe("macOS 26.2");
    expect(c?.device).toMatchObject({ online: true });
    expect((c?.device as { last_seen_at: string | null } | undefined)?.last_seen_at).toBeTruthy();
    const devices = await j(
      await h.request(`/v1/local-devices?org_id=${orgId}`, { token: owner.token }),
    );
    expect(devices.items[0].os_version).toBe("macOS 26.2");
    // The single-computer read carries the same details.
    const one = await j(
      await h.request(`/v1/computers/${device.computer_id}`, { token: owner.token }),
    );
    expect(one).toMatchObject({ os: "macOS 26.2", device: { platform: "macos" } });
  });

  it("someone outside the workspace learns nothing", async () => {
    const stranger = await h.user("details-stranger@example.com");
    const res = await h.request(`/v1/computers/${device.computer_id}`, { token: stranger.token });
    expect(res.status).toBe(404);
  });

  it("cloud computers name the image's OS; others stay unknown", () => {
    expect(computerOs({ kind: "team", provider: "docker" })).toBe(DOCKER_COMPUTER_OS);
    expect(computerOs({ kind: "private", provider: "e2b" })).toBeNull();
    expect(computerOs({ kind: "local", provider: "local" })).toBeNull();
  });

  it("a reported OS is printable text of at most 80 characters", () => {
    expect(deviceOsVersion("Windows 11 Pro")).toBe("Windows 11 Pro");
    expect(deviceOsVersion(["Ubuntu 24.04.1 LTS", "x"])).toBe("Ubuntu 24.04.1 LTS");
    expect(deviceOsVersion("a\u0000b\nc")).toBe("a b c");
    expect(deviceOsVersion("   ")).toBeNull();
    expect(deviceOsVersion(undefined)).toBeNull();
    expect(deviceOsVersion("x".repeat(200))).toHaveLength(80);
  });
});
