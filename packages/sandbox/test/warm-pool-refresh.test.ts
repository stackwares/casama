import { describe, expect, it } from "vitest";
import type { DockerApi } from "../src/docker/api.ts";
import { DockerProvider } from "../src/docker/provider.ts";
import type { ObjectStore } from "../src/object-store.ts";

/**
 * After an image update (the headless tag pulled again), warm-pool members started from the old
 * image are replaced instead of handed out. Docker is faked: only the calls matter here.
 */
describe("warm pool after an image update", () => {
  const setup = (
    containers: Array<{ pool: string; state: string; image?: string }>,
    current?: string,
  ) => {
    const calls: string[] = [];
    const docker = {
      call: async (method: string, path: string) => {
        calls.push(`${method} ${path}`);
        if (method === "GET" && path.startsWith("/containers/json"))
          return containers.map((c) => ({
            Names: [`/t-c-${c.pool}`],
            State: c.state,
            Labels: { "dev.casama.pool": c.pool },
            ImageID: c.image,
          }));
        if (method === "POST" && path.includes("/rename")) return {};
        return {};
      },
      inspectOrNull: async (path: string) => {
        calls.push(`INSPECT ${path}`);
        if (path.startsWith("/images/")) return current ? { Id: current } : null;
        return null;
      },
    } as unknown as DockerApi;
    const provider = new DockerProvider({
      docker,
      store: {} as ObjectStore,
      images: { headless: "ghcr.io/x/computer-headless:latest", desktop: "d" },
      tokenSecret: "s",
      egress: {
        containerName: "egress",
        proxyPort: 3128,
        control: { register: async () => {}, unregister: async () => {} },
      },
      namePrefix: "t",
      warmPool: 1,
    });
    const removed = () =>
      calls
        .filter((c) => c.startsWith("DELETE /containers/"))
        .map((c) => c.slice("DELETE /containers/".length).split("?")[0]);
    return { provider, calls, removed };
  };

  it("replaces members on an older image and keeps current ones", async () => {
    const { provider, removed, calls } = setup(
      [
        { pool: "pool-new", state: "running", image: "sha256:new" },
        { pool: "pool-old", state: "running", image: "sha256:old" },
      ],
      "sha256:new",
    );
    await provider.fillPool();
    expect(removed()).toEqual(["t-c-pool-old"]);
    // The current member fills the pool of one: nothing new is started.
    expect(calls.some((c) => c.startsWith("POST /containers/create"))).toBe(false);
    expect(calls).toContain("INSPECT /images/ghcr.io%2Fx%2Fcomputer-headless%3Alatest/json");
  });

  it("keeps members when the image can't be read, rather than churning the pool", async () => {
    const { provider, removed } = setup([{ pool: "pool-a", state: "running", image: "sha256:a" }]);
    await provider.fillPool();
    expect(removed()).toEqual([]);
  });

  it("never hands out a member on an older image", async () => {
    const { provider, calls } = setup(
      [{ pool: "pool-old", state: "running", image: "sha256:old" }],
      "sha256:new",
    );
    // A claim is the private step create() takes first; the stale member must not be renamed.
    const claimed = await (provider as unknown as { claim(ref: string): Promise<boolean> }).claim(
      "abc",
    );
    expect(claimed).toBe(false);
    expect(calls.some((c) => c.includes("/rename"))).toBe(false);
  });
});
