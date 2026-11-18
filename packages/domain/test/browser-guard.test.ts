import { describe, expect, it } from "vitest";
import { browsable, cleanSitePattern, isCasamaAddress, siteMatches } from "../src/browser-guard.ts";

describe("isCasamaAddress", () => {
  it("knows Casama's domains and this server's own addresses", () => {
    for (const u of [
      "https://app.casama.ai/approvals",
      "https://casama.ai",
      "https://CASAMA.AI./x",
      "https://abc.casama.link/",
      "https://api-dev.kasama.ai/v1",
      "http://localhost:8797/v1/approvals",
    ])
      expect(isCasamaAddress(u, ["http://localhost:8797", null]), u).toBe(true);
    for (const u of ["https://casama.ai.evil.com", "https://notcasama.ai", "http://localhost:3000"])
      expect(isCasamaAddress(u, ["http://localhost:8797"]), u).toBe(false);
  });
});

describe("site lists", () => {
  it("matches hosts and subdomains, and cleans entries", () => {
    expect(siteMatches("mail.google.com", "google.com")).toBe(true);
    expect(siteMatches("google.com", "*.google.com")).toBe(false);
    expect(siteMatches("evilgoogle.com", "google.com")).toBe(false);
    expect(cleanSitePattern(" https://www.Example.com/path?q ")).toBe("example.com");
    expect(cleanSitePattern("*.wiki.acme.org")).toBe("*.wiki.acme.org");
    expect(cleanSitePattern("not a site")).toBeNull();
    expect(browsable("chrome://settings")).toBe(false);
    expect(browsable("https://chromewebstore.google.com/detail/x")).toBe(false);
    expect(browsable("file:///etc/passwd")).toBe(false);
    expect(browsable("https://example.com")).toBe(true);
  });
});
