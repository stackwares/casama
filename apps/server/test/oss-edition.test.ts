import { Hono } from "hono";
import { describe, expect, it } from "vitest";
import { ENTERPRISE_PATHS, edition, loadEe, registerEnterpriseFallback } from "../src/ee.ts";

/** The open-source edition: the server runs without ee/ (D-339). */
describe("open-source edition", () => {
  // CI runs this file again in a copy without ee/ (scripts/oss-edition.sh) with CASAMA_EDITION=oss.
  const expected = process.env.CASAMA_EDITION === "oss" ? "oss" : "enterprise";

  it(`runs as the ${expected} edition`, async () => {
    expect(edition).toBe(expected);
    expect((await loadEe()) === null).toBe(expected === "oss");
  });

  it("treats a missing ee/ as the open-source edition", async () => {
    const missing = Object.assign(new Error("Cannot find package '@casama/ee' imported from x"), {
      code: "ERR_MODULE_NOT_FOUND",
    });
    expect(await loadEe(() => Promise.reject(missing))).toBeNull();
  });

  it("doesn't hide a broken ee/", async () => {
    const broken = Object.assign(new Error("Cannot find package 'jose' imported from ee"), {
      code: "ERR_MODULE_NOT_FOUND",
    });
    await expect(loadEe(() => Promise.reject(broken))).rejects.toThrow("jose");
    await expect(loadEe(() => Promise.reject(new SyntaxError("bad")))).rejects.toThrow("bad");
  });

  it("answers the enterprise routes with 402 license_required", async () => {
    const app = new Hono();
    registerEnterpriseFallback(app);
    const orgId = "00000000-0000-0000-0000-000000000001";
    for (const [path, method] of [
      [`/v1/orgs/${orgId}/sso`, "POST"],
      [`/v1/orgs/${orgId}/sso/verification`, "GET"],
      [`/v1/orgs/${orgId}/audit-log/export`, "GET"],
      [`/v1/orgs/${orgId}/audit-forwarders`, "GET"],
      [`/v1/orgs/${orgId}/audit-forwarders/f1`, "DELETE"],
    ] as const) {
      const res = await app.request(path, { method });
      expect(res.status, path).toBe(402);
      expect(((await res.json()) as { code: string }).code).toBe("license_required");
    }
    expect(ENTERPRISE_PATHS).toHaveLength(5);
  });
});
