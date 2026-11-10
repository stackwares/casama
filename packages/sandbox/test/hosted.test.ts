import { randomUUID } from "node:crypto";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { sandboxContract } from "../src/contract.ts";
import { daytonaProvider, e2bProvider, type HostedProvider } from "../src/hosted.ts";
import { boatProvider, incusProvider, kubernetesProvider, novitaProvider, railwayProvider } from "../src/hosted-more.ts";
import { FsObjectStore } from "../src/object-store.ts";
import {
  dockerAvailable,
  type SandboxStack,
  startSandboxStack,
  TEST_IMAGES,
} from "../src/testing.ts";
import { type MockControlPlane, startMockControlPlane } from "../src/testing-hosted.ts";
import { connectLive } from "../src/testing-stream.ts";
import { turnCredentials, turnIceServer } from "../src/turn.ts";
import { collectExec } from "../src/types.ts";

const enabled = (await dockerAvailable()) && process.env.SKIP_DOCKER_TESTS !== "1";
const images = { headless: TEST_IMAGES.headless, desktop: TEST_IMAGES.desktop };

describe.skipIf(!enabled)("hosted providers against local control planes", () => {
  let stack: SandboxStack;
  let dir: string;
  const planes: MockControlPlane[] = [];
  beforeAll(async () => {
    stack = await startSandboxStack();
    dir = await mkdtemp(join(tmpdir(), "kasama-hosted-"));
  }, 120_000);
  afterAll(async () => {
    for (const p of planes) await p.stop().catch(() => {});
    await stack?.stop();
    await rm(dir, { recursive: true, force: true });
  }, 120_000);

  const hostedOpts = () => ({
    store: new FsObjectStore(dir),
    tokenSecret: "hosted-test-token-secret",
    // Sandboxes join the stack's network, so they reach the relay by its container name.
    turn: { host: stack.turn.container, port: 3478, secret: stack.turn.secret },
  });

  const e2b = async () => {
    const plane = await startMockControlPlane({
      kind: "e2b",
      images,
      network: `${stack.prefix}-control`,
    });
    planes.push(plane);
    const provider = e2bProvider(
      {
        apiKey: plane.apiKey,
        apiUrl: plane.url,
        templates: { headless: "kasama-headless", desktop: "kasama-desktop" },
        portUrl: (id, port) => plane.portUrl(id, port),
      },
      hostedOpts(),
    );
    return { provider, plane };
  };

  sandboxContract("e2b", async () => ({ provider: (await e2b()).provider }));

  sandboxContract("daytona", async () => {
    const plane = await startMockControlPlane({
      kind: "daytona",
      images,
      network: `${stack.prefix}-control`,
    });
    planes.push(plane);
    const provider = daytonaProvider(
      {
        apiKey: plane.apiKey,
        apiUrl: plane.url,
        snapshots: { headless: "kasama-headless", desktop: "kasama-desktop" },
      },
      hostedOpts(),
    );
    return {
      provider,
      cleanup: async () => {
        // Every computerd call carried the preview token from the control plane.
        expect(plane.requests.some((r) => r.path.endsWith("/preview-url"))).toBe(true);
      },
    };
  });

  // More providers (D-139), each against a stand-in that speaks its API.
  sandboxContract("novita", async () => {
    const plane = await startMockControlPlane({ kind: "e2b", images, network: `${stack.prefix}-control` });
    planes.push(plane);
    const provider = novitaProvider(
      { apiKey: plane.apiKey, apiUrl: plane.url, templates: { headless: "kasama-headless", desktop: "kasama-desktop" }, portUrl: (id, port) => plane.portUrl(id, port) },
      hostedOpts(),
    );
    return { provider };
  });

  sandboxContract("kubernetes", async () => {
    const plane = await startMockControlPlane({ kind: "kubernetes", images, network: `${stack.prefix}-control` });
    planes.push(plane);
    const provider = kubernetesProvider(
      { apiUrl: plane.url, token: plane.apiKey, namespace: "kasama", images: { headless: "kasama-headless", desktop: "kasama-desktop" } },
      hostedOpts(),
    );
    return {
      provider,
      cleanup: async () => {
        // computerd was reached through the API server's pod proxy, with the service account token.
        expect(plane.requests.some((r) => /\/pods\/[^/]+:7070\/proxy\//.test(r.path))).toBe(true);
      },
    };
  });

  sandboxContract("incus", async () => {
    const plane = await startMockControlPlane({ kind: "incus", images, network: `${stack.prefix}-control` });
    planes.push(plane);
    const provider = incusProvider(
      {
        apiUrl: plane.url,
        token: plane.apiKey,
        registry: "https://ghcr.io",
        images: { headless: "kasama-headless", desktop: "kasama-desktop" },
        portUrl: (id, port) => plane.portUrl(id, port),
      },
      hostedOpts(),
    );
    return { provider };
  });

  sandboxContract("boat", async () => {
    const plane = await startMockControlPlane({ kind: "boat", images, network: `${stack.prefix}-control` });
    planes.push(plane);
    const provider = boatProvider({ apiKey: plane.apiKey, apiUrl: plane.url, images: { headless: "kasama-headless", desktop: "kasama-desktop" } }, hostedOpts());
    return { provider };
  });

  sandboxContract("railway", async () => {
    const plane = await startMockControlPlane({ kind: "railway", images, network: `${stack.prefix}-control` });
    planes.push(plane);
    const provider = railwayProvider(
      { token: plane.apiKey, projectId: "proj_1", environmentId: "env_1", apiUrl: plane.url, images: { headless: "kasama-headless", desktop: "kasama-desktop" }, domainScheme: "http" },
      hostedOpts(),
    );
    return { provider };
  });

  describe("live view and take control on E2B", () => {
    let provider: HostedProvider;
    let plane: MockControlPlane;
    const ref = randomUUID();
    beforeAll(async () => {
      ({ provider, plane } = await e2b());
      await provider.create({ ref, profile: "desktop" });
    }, 180_000);
    afterAll(async () => {
      await provider?.destroy(ref).catch(() => {});
    }, 60_000);

    it("streams, accepts control input and keeps the API key on the control plane only", async () => {
      const h = (await provider.get(ref))!;
      const ice = [
        turnIceServer(
          stack.turn.host,
          stack.turn.udpPort,
          turnCredentials(stack.turn.secret, "u", 300),
        ),
      ];
      const ep = await h.streamEndpoint({ mode: "control" });
      const c = await connectLive({ url: ep.url, headers: ep.headers, iceServers: ice });
      try {
        await c.firstFrameMs;
        const rtts: number[] = [];
        for (let i = 0; i < 5; i++) rtts.push(await c.ping());
        expect(rtts.sort((a, b) => a - b)[2]).toBeLessThan(500);
        c.send("control/request");
        expect((await c.waitFor("control/host")).payload?.has_host).toBe(true);
        c.move(222, 111);
        await new Promise((r) => setTimeout(r, 500));
        expect((await collectExec(h.exec("xdotool getmouselocation"))).stdout).toContain(
          "x:222 y:111",
        );
      } finally {
        await c.close();
      }
      expect(plane.requests.every((r) => r.headers["x-api-key"] === plane.apiKey)).toBe(true);
    }, 120_000);
  });
});
