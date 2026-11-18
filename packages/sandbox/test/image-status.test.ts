import { describe, expect, it } from "vitest";
import type { DockerApi } from "../src/docker/api.ts";
import { DockerProvider } from "../src/docker/provider.ts";
import type { ObjectStore } from "../src/object-store.ts";

/**
 * Which running computers are behind the current image (D-360): each container's image against
 * what its profile's tag names now. Docker is faked.
 */
describe("computer image status", () => {
  const setup = (
    containers: Array<{ name: string; profile?: string; image?: string }>,
    tags: Record<string, string | undefined>,
  ) => {
    const docker = {
      call: async (method: string, path: string) => {
        if (method === "GET" && path.startsWith("/containers/json"))
          return containers.map((c) => ({
            Names: [`/t-c-${c.name}`],
            Labels: {
              "dev.casama.computer": c.name,
              "dev.casama.profile": c.profile ?? "headless",
            },
            ImageID: c.image,
          }));
        return {};
      },
      inspectOrNull: async (path: string) => {
        const tag = decodeURIComponent(path.slice("/images/".length, -"/json".length));
        const id = tags[tag];
        return id ? { Id: id } : null;
      },
    } as unknown as DockerApi;
    return new DockerProvider({
      docker,
      store: {} as ObjectStore,
      images: { headless: "x/headless:1", desktop: "x/desktop:1" },
      tokenSecret: "s",
      egress: {
        containerName: "egress",
        proxyPort: 3128,
        control: { register: async () => {}, unregister: async () => {} },
      },
      namePrefix: "t",
    });
  };

  it("compares each computer with its own profile's image", async () => {
    const p = setup(
      [
        { name: "a", image: "sha256:h2" },
        { name: "b", image: "sha256:h1" },
        { name: "c", profile: "desktop", image: "sha256:d1" },
        { name: "d", profile: "desktop", image: "sha256:h2" },
      ],
      { "x/headless:1": "sha256:h2", "x/desktop:1": "sha256:d1" },
    );
    expect(await p.imageStatus()).toEqual([
      { ref: "a", current: true },
      { ref: "b", current: false },
      { ref: "c", current: true },
      { ref: "d", current: false },
    ]);
  });

  it("counts unknown images as current and leaves pool members out", async () => {
    const p = setup(
      [
        { name: "a", image: "sha256:old" },
        { name: "b" },
        { name: "pool-abc", image: "sha256:old" },
        { name: "c", profile: "desktop", image: "sha256:old" },
      ],
      { "x/headless:1": "sha256:new" },
    );
    expect(await p.imageStatus()).toEqual([
      { ref: "a", current: false },
      { ref: "b", current: true },
      { ref: "c", current: true },
    ]);
  });
});
