import { describe, expect, it } from "vitest";
import type { DockerApi } from "../src/docker/api.ts";
import { DockerProvider, peerIps } from "../src/docker/provider.ts";
import type { ObjectStore } from "../src/object-store.ts";

/**
 * Under gVisor, Docker's DNS doesn't reach into the computer, so its peers (egress proxy,
 * supervisor, TURN relay) sit on fixed addresses named in its hosts file, and keep them when a
 * deploy recreates them. Docker is faked.
 */
describe("fixed peer addresses on a computer's network", () => {
  it("reserves the 2nd to 4th addresses and leaves the upper half to Docker", () => {
    expect(peerIps("172.22.0.0/16")).toEqual({
      subnet: "172.22.0.0/16",
      gateway: "172.22.0.1",
      egress: "172.22.0.2",
      supervisor: "172.22.0.3",
      turn: "172.22.0.4",
      ipRange: "172.22.128.0/17",
    });
    expect(peerIps("192.168.48.0/20")?.ipRange).toBe("192.168.56.0/21");
    expect(peerIps("")).toBeNull();
    expect(peerIps("fd00::/64")).toBeNull();
  });

  const setup = (networks: Record<string, { Labels?: Record<string, string>; Subnet: string }>) => {
    const calls: Array<{ method: string; path: string; body?: Record<string, unknown> }> = [];
    const docker = {
      call: async (method: string, path: string, body?: Record<string, unknown>) => {
        calls.push({ method, path, body });
        if (method === "GET" && path.startsWith("/containers/json"))
          return [
            {
              Names: ["/t-c-abc"],
              Labels: { "dev.casama.computer": "abc", "dev.casama.profile": "desktop" },
            },
          ];
        if (method === "POST" && path === "/networks/create") {
          const b = body as { Name: string; Labels: Record<string, string>; IPAM?: unknown };
          networks[b.Name] = { Labels: b.Labels, Subnet: "172.30.0.0/16" };
        }
        if (method === "DELETE" && path.startsWith("/networks/"))
          delete networks[path.split("/")[2] as string];
        if (method === "POST" && path.endsWith("/start")) throw new Error("stop here");
        if (method === "GET" && path.startsWith("/containers/") && path.endsWith("/json"))
          return { State: { Running: true }, Config: { Labels: {} } };
        return {};
      },
      inspectOrNull: async (path: string) => {
        const m = /^\/networks\/(.+)$/.exec(path);
        const net = m ? networks[m[1] as string] : undefined;
        return net ? { Labels: net.Labels, IPAM: { Config: [{ Subnet: net.Subnet }] } } : null;
      },
    } as unknown as DockerApi;
    const provider = new DockerProvider({
      docker,
      store: {} as ObjectStore,
      images: { headless: "h", desktop: "d" },
      tokenSecret: "s",
      egress: {
        containerName: "egress",
        proxyPort: 3128,
        control: { register: async () => {}, unregister: async () => {} },
      },
      supervisorContainer: "supervisor",
      turn: { containerName: "turn", secret: "x" },
      namePrefix: "t",
    });
    const joins = () =>
      calls
        .filter((c) => c.path.endsWith("/connect"))
        .map((c) => {
          const b = c.body as {
            Container: string;
            EndpointConfig?: { IPAMConfig?: { IPv4Address?: string } };
          };
          return `${b.Container} ${b.EndpointConfig?.IPAMConfig?.IPv4Address ?? "-"}`;
        });
    return { provider, calls, joins };
  };

  it("rejoins peers on their fixed addresses, and older networks without them", async () => {
    const fixed = setup({
      "t-n-abc": { Labels: { "dev.casama.fixed-peers": "1" }, Subnet: "172.25.0.0/16" },
    });
    expect(await fixed.provider.reconnect()).toEqual([]);
    expect(fixed.joins()).toEqual([
      "egress 172.25.0.2",
      "supervisor 172.25.0.3",
      "turn 172.25.0.4",
    ]);

    const older = setup({ "t-n-abc": { Subnet: "172.25.0.0/16" } });
    expect(await older.provider.reconnect()).toEqual([]);
    expect(older.joins()).toEqual(["egress -", "supervisor -", "turn -"]);
  });

  it("a new computer gets its subnet, peers on fixed addresses before it exists, and a hosts file naming them", async () => {
    const networks: Record<string, { Labels?: Record<string, string>; Subnet: string }> = {};
    const { provider, calls, joins } = setup(networks);
    // The fake stops at the container start; computerd isn't there.
    await expect(provider.create({ ref: "new", profile: "desktop" })).rejects.toThrow("stop here");
    const made = calls.filter((c) => c.path === "/networks/create").map((c) => c.body);
    expect(made).toHaveLength(2);
    expect(made[1]).toMatchObject({
      Internal: true,
      Labels: { "dev.casama.fixed-peers": "1" },
      IPAM: {
        Config: [{ Subnet: "172.30.0.0/16", Gateway: "172.30.0.1", IPRange: "172.30.128.0/17" }],
      },
    });
    expect(joins()).toEqual(["egress 172.30.0.2", "supervisor 172.30.0.3", "turn 172.30.0.4"]);
    const order = calls.map((c) => c.path);
    const create = order.findIndex((p) => p.startsWith("/containers/create"));
    expect(order.findIndex((p) => p.endsWith("/connect"))).toBeLessThan(create);
    // ExtraHosts is a HostConfig field; at the top level Docker ignores it.
    const body = calls[create]?.body as {
      ExtraHosts?: unknown;
      HostConfig: { ExtraHosts: string[] };
    };
    expect(body.ExtraHosts).toBeUndefined();
    expect(body.HostConfig.ExtraHosts).toEqual([
      "egress:172.30.0.2",
      "supervisor:172.30.0.3",
      "turn:172.30.0.4",
    ]);
  });
});
