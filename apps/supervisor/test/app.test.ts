import { SandboxError } from "@kasama/sandbox";
import { describe, expect, it } from "vitest";
import { createSupervisorApp } from "../src/app.ts";

const fakeProvider = {
  opts: { docker: { ping: async () => true }, store: { delete: async () => {} } },
  list: async () => ["a"],
  get: async () => null,
  create: async () => {
    throw new SandboxError("docker_error", "boom", 500);
  },
} as never;

describe("supervisor API", () => {
  const app = createSupervisorApp(fakeProvider, "supervisor-token-0123456789");
  const auth = { authorization: "Bearer supervisor-token-0123456789" };

  it("serves health without a token", async () => {
    expect(await (await app.request("/healthz")).json()).toEqual({ ok: true });
  });

  it("rejects requests without the supervisor token", async () => {
    expect((await app.request("/computers")).status).toBe(401);
    expect((await app.request("/computers/a/exec", { method: "POST", body: "{}" })).status).toBe(
      401,
    );
    expect(
      (await app.request("/objects/delete", { method: "POST", body: '{"keys":[]}' })).status,
    ).toBe(401);
  });

  it("lists computers and maps sandbox errors", async () => {
    expect(await (await app.request("/computers", { headers: auth })).json()).toEqual({
      running: ["a"],
    });
    const notRunning = await app.request("/computers/a/files/list", { headers: auth });
    expect(notRunning.status).toBe(409);
    expect(((await notRunning.json()) as { code: string }).code).toBe("not_running");
    const failed = await app.request("/computers", {
      method: "POST",
      headers: auth,
      body: JSON.stringify({ ref: "x", profile: "headless" }),
    });
    expect(failed.status).toBe(500);
  });
});
