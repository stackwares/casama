import { describe, expect, it } from "vitest";
import {
  normalizeServer,
  originPattern,
  parseSignInLink,
  serverLabel,
} from "../src/lib/servers.ts";

const CODE = `ksc_${"b".repeat(43)}`;

describe("server addresses", () => {
  it("adds https, drops slashes, query and fragment", () => {
    expect(normalizeServer("casama.example.com/")).toBe("https://casama.example.com");
    expect(normalizeServer(" https://x.example.com/api/?a=1#b ")).toBe("https://x.example.com/api");
    expect(normalizeServer("http://localhost:8787")).toBe("http://localhost:8787");
    expect(normalizeServer("http://192.168.1.20:8787")).toBe("http://192.168.1.20:8787");
  });

  it("refuses plain http on the internet, other schemes and user names", () => {
    expect(() => normalizeServer("http://casama.example.com")).toThrow(/https/);
    expect(() => normalizeServer("ftp://x.example.com")).toThrow();
    expect(() => normalizeServer("https://me:pw@x.example.com")).toThrow();
    expect(() => normalizeServer("")).toThrow();
  });

  it("labels Casama Cloud by name and others by host", () => {
    expect(serverLabel("https://api.casama.ai")).toBe("Casama Cloud");
    expect(serverLabel("https://casama.example.com:8443")).toBe("casama.example.com:8443");
    expect(originPattern("https://casama.example.com:8443/api")).toBe(
      "https://casama.example.com/*",
    );
  });
});

describe("sign-in links", () => {
  it("reads the server and code from the link's fragment", () => {
    const link = `https://casama.ai/pair#v=1&s=${encodeURIComponent("https://api.casama.ai")}&c=${CODE}`;
    expect(parseSignInLink(link)).toEqual({ server: "https://api.casama.ai", code: CODE });
  });

  it("takes a bare code without a server", () => {
    expect(parseSignInLink(` ${CODE} `)).toEqual({ code: CODE });
  });

  it("explains what's wrong with anything else", () => {
    expect(() => parseSignInLink("hello")).toThrow(/whole sign-in link/);
    expect(() => parseSignInLink("https://casama.ai/pair#v=1&s=x")).toThrow(
      /isn't a Casama sign-in link/,
    );
    expect(() =>
      parseSignInLink(
        `https://casama.ai/pair#v=1&s=${encodeURIComponent("http://evil.example")}&c=${CODE}`,
      ),
    ).toThrow(/https/);
  });
});
