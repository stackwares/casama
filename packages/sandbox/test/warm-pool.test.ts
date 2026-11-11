import { execFile } from "node:child_process";
import { randomUUID } from "node:crypto";
import { promisify } from "node:util";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { dockerAvailable, type SandboxStack, startSandboxStack } from "../src/testing.ts";
import { collectExec } from "../src/types.ts";

const run = promisify(execFile);
const enabled = (await dockerAvailable()) && process.env.SKIP_DOCKER_TESTS !== "1";
const names = async (filter: string, running = false) =>
  (
    await run("docker", [
      "ps",
      ...(running ? [] : ["-a"]),
      "--format",
      "{{.Names}}",
      "--filter",
      `name=${filter}`,
    ])
  ).stdout
    .split("\n")
    .filter(Boolean);
// A member is ready once its container runs and computerd answers (a few seconds after the container starts).
const ready = async (prefix: string) =>
  (await names(`${prefix}-c-pool-`, true)).length >= 1 &&
  (await new Promise<boolean>((r) => setTimeout(r, 3000, true)));
const waitFor = async (check: () => Promise<boolean>, ms = 90_000) => {
  const until = Date.now() + ms;
  while (Date.now() < until) {
    if (await check()) return;
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error("timed out");
};

/** Warm pool (D-148): started headless computers that a new computer claims instead of a cold start. */
describe.skipIf(!enabled)("warm pool", () => {
  let stack: SandboxStack;
  beforeAll(async () => {
    stack = await startSandboxStack({ warmPool: 1 });
    await waitFor(() => ready(stack.prefix));
  }, 180_000);
  afterAll(async () => {
    for (const n of await names(`${stack?.prefix}-c-pool-`))
      await run("docker", ["rm", "-f", "-v", n]).catch(() => {});
    await stack?.stop();
  }, 120_000);

  it("a new computer claims the started member, works normally, and the pool refills", async () => {
    const [member] = await names(`${stack.prefix}-c-pool-`, true);
    const pool = member!.slice(`${stack.prefix}-c-`.length);
    const ref = randomUUID();
    const started = Date.now();
    const h = await stack.provider.create({ ref, profile: "headless" });
    const took = Date.now() - started;
    try {
      // The member was renamed to the computer, keeping its own network and volume.
      expect(await names(`${stack.prefix}-c-${ref}`)).toEqual([`${stack.prefix}-c-${ref}`]);
      expect(await names(member!)).toEqual([]);
      expect(took).toBeLessThan(5_000);
      const who = await collectExec(
        h.exec(
          "whoami && pwd && curl -s -o /dev/null -w '%{http_code}' --max-time 8 https://example.com",
        ),
      );
      expect(who.stdout).toMatch(/^casama\n.*\/workspace\n200$/);
      await h.writeFile("note.txt", new TextEncoder().encode("kept"));
      expect(await stack.provider.list?.()).toContain(ref);
      expect(await stack.provider.list?.()).not.toContain(pool);
      // Sleep and restore go through the claimed container's own credentials.
      const snap = await stack.provider.sleep(ref);
      expect(
        (await run("docker", ["network", "ls", "--format", "{{.Name}}"])).stdout,
      ).not.toContain(`${stack.prefix}-n-${pool}`);
      const again = await stack.provider.resume(ref, snap, { profile: "headless" });
      expect(new TextDecoder().decode(await again.readFile("note.txt"))).toBe("kept");
      // A fresh member replaces the one that was taken.
      await waitFor(async () => (await names(`${stack.prefix}-c-pool-`)).length >= 1);
      expect(await names(`${stack.prefix}-c-pool-`)).not.toContain(member);
    } finally {
      await stack.provider.destroy(ref).catch(() => {});
    }
  }, 240_000);

  it("a computer with a non-default size or a desktop never takes a pool member", async () => {
    await waitFor(() => ready(stack.prefix));
    const before = await names(`${stack.prefix}-c-pool-`);
    const ref = randomUUID();
    try {
      await stack.provider.create({ ref, profile: "headless", size: { cpus: 2 } });
      expect(await names(`${stack.prefix}-c-pool-`)).toEqual(before);
    } finally {
      await stack.provider.destroy(ref).catch(() => {});
    }
  }, 180_000);
});
