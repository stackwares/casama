import { describe, expect, it } from "vitest";
import { guardUrl, scriptable } from "../src/lib/guard.ts";
import { guardAdditions, refreshGuardSites } from "../src/lib/guard-sites.ts";
import { setFetch } from "../src/lib/session.ts";
import { updateLocal } from "../src/lib/store.ts";
import { installFakeChrome } from "./fake-chrome.ts";

describe("the guard (G2, §11)", () => {
  it("always refuses Casama's own addresses", () => {
    expect(guardUrl("https://app.casama.ai/inbox")).toBe("casama");
    expect(guardUrl("https://casama.link/x")).toBe("casama");
    expect(guardUrl("https://app.casama.ai/x", { allowed: ["casama"] })).toBe("casama");
    expect(guardUrl("https://app.casama.ai./inbox")).toBe("casama");
  });

  it("treats the signed-in servers' own addresses as Casama's", () => {
    const ownHosts = ["casama.home.example:8443", "localhost:8797"];
    expect(guardUrl("https://casama.home.example:8443/pair", { ownHosts })).toBe("casama");
    expect(guardUrl("http://localhost:8797/v1/config", { ownHosts })).toBe("casama");
    // Another service on the same machine is an ordinary site.
    expect(guardUrl("http://localhost:5999/news", { ownHosts })).toBeNull();
  });

  it("keeps banking, health, password managers and government ID off by default", () => {
    expect(guardUrl("https://www.paypal.com/myaccount")).toBe("banking");
    expect(guardUrl("https://secure.chase.com/")).toBe("banking");
    expect(guardUrl("https://onlinebanking.example.com/")).toBe("banking");
    expect(guardUrl("https://mychart.hospital.org/")).toBe("health");
    expect(guardUrl("https://vault.bitwarden.com/")).toBe("passwords");
    expect(guardUrl("https://www.irs.gov/")).toBe("government");
    expect(guardUrl("https://www.gov.uk/")).toBe("government");
    expect(guardUrl("https://www.paypal.com/", { allowed: ["banking"] })).toBeNull();
  });

  it("leaves ordinary sites alone and honours the never-list", () => {
    expect(guardUrl("https://news.ycombinator.com/")).toBeNull();
    expect(guardUrl("https://www.youtube.com/watch?v=x")).toBeNull();
    expect(guardUrl("https://mail.example.com/", { neverList: ["example.com"] })).toBe("never");
    expect(guardUrl("https://notexample.com/", { neverList: ["example.com"] })).toBeNull();
    expect(guardUrl(undefined)).toBeNull();
    expect(guardUrl("not a url")).toBeNull();
  });

  it("knows the pages Chrome won't let it script", () => {
    expect(scriptable("https://example.com")).toBe(true);
    expect(scriptable("chrome://settings")).toBe(false);
    expect(scriptable("https://chromewebstore.google.com/detail/x")).toBe(false);
    expect(scriptable(undefined)).toBe(false);
  });
});

describe("sites the servers add to the guard (D-374)", () => {
  it("adds hosts to a kind, and never takes a built-in one off", () => {
    const extraHosts = { banking: ["mybank.example"] };
    expect(guardUrl("https://login.mybank.example/", { extraHosts })).toBe("banking");
    expect(guardUrl("https://login.mybank.example/")).toBeNull();
    // Nothing a server sends shortens the lists in code.
    expect(guardUrl("https://www.paypal.com/", { extraHosts: { banking: [] } })).toBe("banking");
    // The person can still switch the kind back on.
    expect(guardUrl("https://mybank.example/", { extraHosts, allowed: ["banking"] })).toBeNull();
  });

  it("fetches each signed-in server's list, drops bad entries, and keeps it when offline", async () => {
    installFakeChrome();
    await updateLocal((s) => {
      s.accounts = [
        {
          id: "https://a.example u1",
          server: "https://a.example",
          authUrl: "https://a.example/auth/v1",
          anonKey: "k",
          userId: "u1",
          email: "a@example.com",
          refreshToken: "r",
          addedAt: "2026-11-18T00:00:00Z",
        },
      ];
    });
    let up = true;
    setFetch((async () => {
      if (!up) throw new TypeError("offline");
      return Response.json({
        hosts: { banking: ["mybank.example", "not a host"], crypto: ["coin.example"] },
      });
    }) as unknown as typeof fetch);
    expect(await refreshGuardSites("https://a.example")).toMatchObject({
      banking: ["mybank.example"],
    });
    up = false;
    expect((await refreshGuardSites("https://a.example")).banking).toEqual(["mybank.example"]);
    const merged = await guardAdditions(0);
    expect(merged.banking).toEqual(["mybank.example"]);
    expect(Object.keys(merged)).not.toContain("crypto");
  });
});
