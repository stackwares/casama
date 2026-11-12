import { describe, expect, it } from "vitest";
import {
  catalogAppFromGallery,
  checkAppDocument,
  checkAppLogo,
  publicHttpsUrl,
} from "../src/gallery-apps.ts";

const base = {
  description: "Search and edit designs.",
  category: "design",
  color: "00c4cc",
  homepage: "https://www.canva.com",
  url: "https://mcp.canva.com/mcp",
  auth: ["oauth"],
  oauthClient: "dcr",
  capabilities: ["Search designs"],
};

describe("gallery apps", () => {
  it("accepts a vendor's OAuth server and cleans it", () => {
    const { doc, errors } = checkAppDocument(base);
    expect(errors).toEqual([]);
    expect(doc?.color).toBe("00C4CC");
    expect(catalogAppFromGallery("canva", "Canva", base)).toMatchObject({
      id: "canva",
      name: "Canva",
      auth: ["oauth"],
      oauthClient: "dcr",
    });
  });

  it("refuses what only built-in apps may do", () => {
    for (const bad of [
      { ...base, category: "google" },
      { ...base, oauthClient: "preregistered" },
      { ...base, auth: ["managed"] },
      { ...base, composio: "canva" },
      { ...base, inbox: true },
      { ...base, popular: true },
    ])
      expect(checkAppDocument(bad).errors.length).toBeGreaterThan(0);
  });

  it("only connects to public https hosts", () => {
    expect(publicHttpsUrl("https://mcp.vendor.com/mcp")).toBeDefined();
    for (const u of [
      "http://mcp.vendor.com/mcp",
      "https://localhost/mcp",
      "https://127.0.0.1/mcp",
      "https://[::1]/mcp",
      "https://intranet/mcp",
      "https://mcp.corp/mcp",
      "https://box.internal/mcp",
      "https://mcp.vendor.com:8443/mcp",
      "https://user:pw@mcp.vendor.com/mcp",
    ])
      expect(publicHttpsUrl(u)).toBeUndefined();
  });

  it("needs help text for a key and refuses headers that would redirect the request", () => {
    const key = {
      ...base,
      auth: ["api_key"],
      oauthClient: undefined,
      apiKey: { label: "API key", url: "https://vendor.com/keys", steps: ["Create a key."] },
    };
    delete (key as Record<string, unknown>).oauthClient;
    expect(checkAppDocument(key).errors).toEqual([]);
    expect(checkAppDocument({ ...key, apiKey: undefined }).errors.length).toBeGreaterThan(0);
    expect(
      checkAppDocument({ ...key, apiKey: { ...key.apiKey, header: "Host" } }).errors.length,
    ).toBeGreaterThan(0);
    expect(
      checkAppDocument({ ...key, apiKey: { ...key.apiKey, header: "X-Api-Key" } }).errors,
    ).toEqual([]);
  });

  it("allows a plain SVG mark and nothing that runs or loads", () => {
    const ok =
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M0 0h24v24H0z"/></svg>';
    expect(checkAppLogo(ok, ok.length)).toEqual([]);
    for (const bad of [
      '<svg viewBox="0 0 24 24"><script>alert(1)</script></svg>',
      '<svg viewBox="0 0 24 24" onload="x()"><path d="M0 0"/></svg>',
      '<svg viewBox="0 0 24 24"><image href="https://x.com/a.png"/></svg>',
      '<svg viewBox="0 0 24 24"><path style="fill:url(#a)" d="M0 0"/></svg>',
      '<!DOCTYPE svg [<!ENTITY x "y">]><svg viewBox="0 0 24 24"></svg>',
      '<svg><path d="M0 0"/></svg>',
    ])
      expect(checkAppLogo(bad, bad.length).length).toBeGreaterThan(0);
    expect(checkAppLogo(ok, 30 * 1024).length).toBeGreaterThan(0);
  });
});
