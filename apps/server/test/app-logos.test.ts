import { readFileSync } from "node:fs";
import { APP_CATALOG } from "@casama/domain";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

// Built-in apps' marks served by the API, for apps built before a mark was bundled.
let h: Harness;
let token: string;
beforeAll(async () => {
  h = await startHarness();
  token = (await h.user("logos@example.com")).token;
});
afterAll(async () => {
  await h?.stop();
});

describe("built-in app logos", () => {
  it("every built-in app has a mark, and the catalog links to it", async () => {
    const cat = await j(await h.request("/v1/apps", { token }));
    const byId = new Map<string, { logo_url?: string }>(
      cat.apps.map((a: { id: string }) => [a.id, a]),
    );
    for (const a of APP_CATALOG) {
      const listed = byId.get(a.id);
      if (!listed) continue; // hidden on this server (needs a client or Composio)
      expect(listed.logo_url, a.id).toMatch(
        new RegExp(`/v1/apps/logos/${a.id}\\.svg\\?v=[0-9a-f]{10}$`),
      );
    }
    expect(byId.get("revenuecat")?.logo_url).toBeTruthy();
  });

  it("serves the mark as a locked-down SVG", async () => {
    const res = await h.request("/v1/apps/logos/adapty.svg");
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toMatch(/^image\/svg\+xml/);
    expect(res.headers.get("content-security-policy")).toContain("default-src 'none'");
    expect(res.headers.get("x-content-type-options")).toBe("nosniff");
    const file = new URL("../../../client/assets/apps/adapty.svg", import.meta.url);
    expect(await res.text()).toBe(readFileSync(file, "utf8"));
  });

  it("anything that isn't a known mark is not found", async () => {
    for (const p of [
      "nope.svg",
      "adapty.png",
      "..%2F..%2Fpackage.json",
      "NOTICE.txt",
      "ADAPTY.svg",
    ])
      expect((await h.request(`/v1/apps/logos/${p}`)).status, p).toBe(404);
  });
});
