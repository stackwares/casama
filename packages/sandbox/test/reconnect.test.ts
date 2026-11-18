import { createHmac } from "node:crypto";
import { describe, expect, it } from "vitest";
import type { DockerApi } from "../src/docker/api.ts";
import { DockerProvider } from "../src/docker/provider.ts";
import type { ObjectStore } from "../src/object-store.ts";

/**
 * A deploy recreates the egress proxy and the supervisor: computers already running must rejoin
 * both, and the proxy (registrations in memory) must learn them again. Docker is faked.
 */
describe("reconnecting running computers", () => {
  const setup = (containers: Array<{ name: string; labels: Record<string, string> }>) => {
    const calls: Array<{ path: string; body?: { Container?: string } }> = [];
    const registered: Array<[string, string]> = [];
    const docker = {
      call: async (method: string, path: string, body?: { Container?: string }) => {
        calls.push({ path: `${method} ${path}`, body });
        if (method === "GET" && path.startsWith("/containers/json"))
          return containers.map((c) => ({ Names: [`/t-c-${c.name}`], Labels: c.labels }));
        if (path.endsWith("/connect") && body?.Container === "egress" && path.includes("already"))
          throw new Error("endpoint with name egress already exists in network");
        return {};
      },
      inspectOrNull: async () => null,
    } as unknown as DockerApi;
    const provider = new DockerProvider({
      docker,
      store: {} as ObjectStore,
      images: { headless: "h", desktop: "d" },
      tokenSecret: "s",
      egress: {
        containerName: "egress",
        proxyPort: 3128,
        control: {
          register: async (ref, token) => void registered.push([ref, token]),
          unregister: async () => {},
        },
      },
      supervisorContainer: "supervisor",
      turn: { containerName: "turn", secret: "x" },
      namePrefix: "t",
    });
    const joins = () =>
      calls
        .filter((c) => c.path.endsWith("/connect"))
        .map((c) => `${c.path.split("/")[2]} ${c.body?.Container}`);
    return { provider, joins, registered };
  };
  const token = (key: string) =>
    createHmac("sha256", "s").update(`egress:${key}`).digest("base64url");

  it("rejoins the proxy and supervisor to each computer's network and registers it again", async () => {
    const { provider, joins, registered } = setup([
      { name: "abc", labels: { "dev.casama.computer": "abc", "dev.casama.profile": "headless" } },
      {
        name: "desk",
        labels: { "dev.casama.computer": "desk", "dev.casama.profile": "desktop" },
      },
    ]);
    expect(await provider.reconnect()).toEqual([]);
    expect(joins()).toEqual([
      "t-n-abc egress",
      "t-n-abc supervisor",
      "t-n-desk egress",
      "t-n-desk supervisor",
      "t-n-desk turn",
    ]);
    expect(registered).toEqual([
      ["abc", token("abc")],
      ["desk", token("desk")],
    ]);
  });

  it("uses a claimed pool member's own network and egress identity", async () => {
    const { provider, joins, registered } = setup([
      {
        name: "mine",
        labels: { "dev.casama.computer": "pool-1", "dev.casama.pool": "pool-1" },
      },
    ]);
    await provider.reconnect();
    expect(joins()).toEqual(["t-n-pool-1 egress", "t-n-pool-1 supervisor"]);
    expect(registered).toEqual([["pool-1", token("pool-1")]]);
  });

  it("is a no-op for computers already connected", async () => {
    const { provider, registered } = setup([
      { name: "already", labels: { "dev.casama.computer": "already" } },
    ]);
    expect(await provider.reconnect()).toEqual([]);
    expect(registered).toHaveLength(1);
  });
});
