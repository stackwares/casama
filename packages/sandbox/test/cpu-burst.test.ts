import { describe, expect, it } from "vitest";
import type { DockerApi } from "../src/docker/api.ts";
import { DockerProvider } from "../src/docker/provider.ts";
import type { ObjectStore } from "../src/object-store.ts";

/** D-472: a computer may burst above its size while the machine is free; its share stays its size. */
describe("computer CPU limits", () => {
  const created = async (defaults?: { cpus?: number; burstCpus?: number }, cpus?: number) => {
    let host: Record<string, unknown> = {};
    const docker = {
      call: async (method: string, path: string, body?: Record<string, unknown>) => {
        if (method === "POST" && path.startsWith("/containers/create"))
          host = (body as { HostConfig: Record<string, unknown> }).HostConfig;
        if (method === "POST" && path.endsWith("/start")) throw new Error("stop here");
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
        control: { register: async () => {}, unregister: async () => {} },
      },
      namePrefix: "t",
      defaults,
    });
    await expect(
      provider.create({ ref: "c1", profile: "headless", ...(cpus ? { size: { cpus } } : {}) }),
    ).rejects.toThrow("stop here");
    return { cap: Number(host.NanoCpus) / 1e9, shares: host.CpuShares };
  };

  it("caps at the burst while weighting by the size", async () => {
    expect(await created({ burstCpus: 2 })).toEqual({ cap: 2, shares: 1024 });
  });

  it("keeps the old cap when no burst is set", async () => {
    expect(await created()).toEqual({ cap: 1, shares: 1024 });
  });

  it("never caps a bigger computer below its size", async () => {
    expect(await created({ burstCpus: 2 }, 4)).toEqual({ cap: 4, shares: 4096 });
  });
});
