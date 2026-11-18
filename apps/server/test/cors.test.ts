import { describe, expect, it } from "vitest";
import { corsOrigins } from "../src/api/cors.ts";

const EXT = "ppbkfncjfhfhkgbkdleajcpacfljphpl";
const env = (over: Partial<Parameters<typeof corsOrigins>[0]> = {}) => ({
  PUBLIC_APP_URL: "https://app.casama.ai",
  CORS_ORIGINS: "https://app.example.com, ",
  CHROME_EXTENSION_IDS: EXT,
  NODE_ENV: "production",
  ...over,
});

describe("CORS origins", () => {
  it("allows the web app, extra origins and Casama for Chrome in production", () => {
    const allow = corsOrigins(env());
    expect(allow("https://app.casama.ai")).toBe("https://app.casama.ai");
    expect(allow("https://app.example.com")).toBe("https://app.example.com");
    expect(allow(`chrome-extension://${EXT}`)).toBe(`chrome-extension://${EXT}`);
  });

  it("refuses other sites and other extensions in production", () => {
    const allow = corsOrigins(env());
    expect(allow(undefined)).toBeNull();
    expect(allow("https://evil.example")).toBeNull();
    expect(allow("http://localhost:3000")).toBeNull();
    expect(allow(`chrome-extension://${"a".repeat(32)}`)).toBeNull();
  });

  it("allows Casama for Firefox's per-install origins unless turned off", () => {
    const ff = "moz-extension://0b5e1c2a-9d3f-4c7e-8a1b-2f6d4e8c0a9b";
    expect(corsOrigins(env())(ff)).toBe(ff);
    expect(corsOrigins(env({ FIREFOX_EXTENSIONS: false }))(ff)).toBeNull();
    expect(corsOrigins(env())("moz-extension://not-a-uuid")).toBeNull();
    expect(corsOrigins(env())(`${ff}.evil.example`)).toBeNull();
  });

  it("takes extension ids from the setting and ignores malformed ones", () => {
    const other = "b".repeat(32);
    const allow = corsOrigins(env({ CHROME_EXTENSION_IDS: `${other}, not-an-id` }));
    expect(allow(`chrome-extension://${other}`)).toBe(`chrome-extension://${other}`);
    expect(allow(`chrome-extension://${EXT}`)).toBeNull();
    expect(allow("chrome-extension://not-an-id")).toBeNull();
  });

  it("allows localhost and any extension outside production", () => {
    const allow = corsOrigins(env({ NODE_ENV: "development", CHROME_EXTENSION_IDS: "" }));
    expect(allow("http://localhost:8098")).toBe("http://localhost:8098");
    expect(allow(`chrome-extension://${"c".repeat(32)}`)).toBe(
      `chrome-extension://${"c".repeat(32)}`,
    );
    expect(allow("chrome-extension://short")).toBeNull();
  });
});
