import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { sandboxContract } from "../src/contract.ts";
import { dockerAvailable, type SandboxStack, startSandboxStack } from "../src/testing.ts";
import { collectExec, type SandboxHandle } from "../src/types.ts";

const enabled = (await dockerAvailable()) && process.env.SKIP_DOCKER_TESTS !== "1";

describe.skipIf(!enabled)("docker sandbox", () => {
  let stack: SandboxStack;
  beforeAll(async () => {
    stack = await startSandboxStack();
  }, 120_000);
  afterAll(async () => {
    await stack?.stop();
  }, 120_000);

  sandboxContract("docker", async () => ({ provider: stack.provider }));

  describe("isolation and egress", () => {
    let a: SandboxHandle;
    let b: SandboxHandle;
    const refA = randomUUID();
    const refB = randomUUID();
    beforeAll(async () => {
      a = await stack.provider.create({ ref: refA, profile: "headless" });
      b = await stack.provider.create({ ref: refB, profile: "headless" });
    }, 120_000);
    afterAll(async () => {
      await stack.provider.destroy(refA).catch(() => {});
      await stack.provider.destroy(refB).catch(() => {});
    }, 60_000);

    const curl = (h: SandboxHandle, args: string) =>
      collectExec(
        h.exec(`curl -s -o /dev/null -w '%{http_code}' --max-time 8 ${args}; echo " exit=$?"`),
      );

    it("reaches the internet only through the egress proxy", async () => {
      expect((await curl(a, "https://example.com")).stdout).toMatch(/^200 /);
      const direct = await curl(a, "--noproxy '*' https://example.com");
      expect(direct.stdout).not.toMatch(/^200 /);
    }, 60_000);

    it("blocks cloud metadata and private addresses", async () => {
      for (const target of [
        "http://169.254.169.254/latest/meta-data/",
        "http://10.0.0.1/",
        "http://192.168.1.1/",
        "http://172.17.0.1/",
      ]) {
        const r = await curl(a, target);
        // 403 from the proxy (or a refused local connection for 127.0.0.1), never a real answer
        expect(r.stdout, target).not.toMatch(/^200 /);
      }
      const direct = await curl(a, "--noproxy '*' http://169.254.169.254/latest/meta-data/");
      expect(direct.stdout).toMatch(/^000 /);
    }, 60_000);

    it("cannot reach another computer, the supervisor or the proxy control port", async () => {
      const other = `${stack.prefix}-c-${refB}`;
      expect((await curl(a, `--noproxy '*' http://${other}:7070/health`)).stdout).toMatch(/^000 /);
      expect((await curl(a, `http://${other}:7070/health`)).stdout).not.toMatch(/^200 /);
      expect(
        (await curl(a, `--noproxy '*' http://${stack.egressContainer}:3129/healthz`)).stdout,
      ).toMatch(/^401 |^000 /);
      expect(
        (await curl(a, `--noproxy '*' http://${stack.prefix}-sup:8788/computers`)).stdout,
      ).toMatch(/^401 |^000 /);
      // b is unaffected
      expect((await collectExec(b.exec("echo fine"))).stdout).toBe("fine\n");
    }, 60_000);

    it("keeps browser logins across sleep and restore", async () => {
      const ref = randomUUID();
      let h = await stack.provider.create({ ref, profile: "headless" });
      try {
        const expires = Math.floor(Date.now() / 1000) + 86_400;
        const set = await collectExec(
          h.exec(
            `agent-browser open https://example.com >/dev/null && agent-browser cookies set session abc123 --expires ${expires} && agent-browser close >/dev/null; echo done`,
            { timeoutMs: 90_000 },
          ),
        );
        expect(set.stdout, set.stderr).toContain("done");
        const snap = await stack.provider.sleep(ref);
        h = await stack.provider.resume(ref, snap, { profile: "headless" });
        const got = await collectExec(
          h.exec(
            "agent-browser open https://example.com >/dev/null && agent-browser cookies get --json; agent-browser close >/dev/null",
            {
              timeoutMs: 90_000,
            },
          ),
        );
        expect(got.stdout).toContain("abc123");
      } finally {
        await stack.provider.destroy(ref).catch(() => {});
      }
    }, 240_000);

    it("runs as an unprivileged user on a read-only root filesystem", async () => {
      const r = await collectExec(
        a.exec(
          "id -u; touch /usr/x 2>&1 || echo ro; touch ~/ok && echo home-ok; cat /proc/1/status | grep CapEff",
        ),
      );
      expect(r.stdout).toContain("1000\n");
      expect(r.stdout).toContain("ro\n");
      expect(r.stdout).toContain("home-ok\n");
      expect(r.stdout).toMatch(/CapEff:\s+0000000000000000/);
    });
  });
});
