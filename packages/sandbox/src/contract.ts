/**
 * The SandboxProvider contract: every adapter (Docker, E2B, Daytona, local) must pass this suite.
 * Usage: sandboxContract("docker", async () => ({ provider, cleanup }));
 */
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { collectExec, type SandboxHandle, type SandboxProvider } from "./types.ts";

const text = (b: Uint8Array) => new TextDecoder().decode(b);
const bytes = (s: string) => new TextEncoder().encode(s);

export function sandboxContract(name: string, setup: () => Promise<{ provider: SandboxProvider; cleanup?: () => Promise<void> }>) {
  describe(`SandboxProvider contract: ${name}`, () => {
    let provider: SandboxProvider;
    let cleanup: (() => Promise<void>) | undefined;
    let h: SandboxHandle;
    const ref = randomUUID();

    beforeAll(async () => {
      ({ provider, cleanup } = await setup());
      h = await provider.create({ ref, profile: "headless" });
    }, 120_000);
    afterAll(async () => {
      await provider?.destroy(ref).catch(() => {});
      await cleanup?.();
    }, 120_000);

    it("runs commands with output and exit codes", async () => {
      const r = await collectExec(h.exec("echo out; echo err >&2; exit 7"));
      expect(r).toMatchObject({ stdout: "out\n", stderr: "err\n", code: 7 });
      const who = await collectExec(h.exec("whoami; pwd"));
      expect(who.stdout).toMatch(/^kasama\n.*\/workspace\n$/);
    });

    it("streams output as it is produced", async () => {
      const seen: string[] = [];
      for await (const c of h.exec("for i in 1 2 3; do echo $i; sleep 0.2; done")) if (c.type === "stdout") seen.push(c.data);
      expect(seen.join("")).toBe("1\n2\n3\n");
      expect(seen.length).toBeGreaterThan(1);
    });

    it("enforces timeouts and can kill a command", async () => {
      expect((await collectExec(h.exec("sleep 10", { timeoutMs: 500 }))).timedOut).toBe(true);
      const stream = h.exec("echo go; sleep 30");
      let killed = false;
      for await (const c of stream) {
        if (c.type === "start") setTimeout(() => void h.kill(c.execId), 300);
        if (c.type === "exit") killed = c.killed;
      }
      expect(killed).toBe(true);
    });

    it("reads, writes, lists, searches and deletes files", async () => {
      await h.writeFile("notes/today.md", bytes("# Today\nFind the teal widget\n"));
      expect(text(await h.readFile("notes/today.md"))).toContain("teal widget");
      expect((await h.listDir("notes")).map((e) => e.name)).toEqual(["today.md"]);
      expect((await h.search("TEAL"))[0]).toMatchObject({ line: 2 });
      await h.deleteFile("notes");
      await expect(h.readFile("notes/today.md")).rejects.toThrow();
    });

    it("restores a checkpoint", async () => {
      await h.writeFile("doc.txt", bytes("version 1"));
      const cp = await h.checkpoint("before edit");
      await h.writeFile("doc.txt", bytes("version 2"));
      await h.writeFile("new.txt", bytes("added later"));
      await h.restore(cp);
      expect(text(await h.readFile("doc.txt"))).toBe("version 1");
      await expect(h.readFile("new.txt")).rejects.toThrow();
    });

    it("reports health", async () => {
      expect(await h.health()).toMatchObject({ ok: true });
    });

    it("sleeps to storage and resumes with the home directory intact", async () => {
      await h.writeFile("keep/me.txt", bytes("still here"));
      await collectExec(h.exec("mkdir -p ~/.config/app && echo token=xyz > ~/.config/app/state"));
      const snap = await provider.sleep(ref);
      expect(snap.size).toBeGreaterThan(0);
      expect(await provider.get(ref)).toBeNull();
      h = await provider.resume(ref, snap, { profile: "headless" });
      expect(text(await h.readFile("keep/me.txt"))).toBe("still here");
      expect((await collectExec(h.exec("cat ~/.config/app/state"))).stdout).toBe("token=xyz\n");
    }, 120_000);
  });
}
