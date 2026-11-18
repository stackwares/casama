import { describe, expect, it } from "vitest";
import { authorizeUrl, enabledProviders, exchangeCode, pkcePair } from "../src/lib/auth.ts";

const svc = { authUrl: "https://auth.example.test/", anonKey: "anon" };

describe("Google and Apple sign-in (route 4)", () => {
  it("makes a PKCE pair whose challenge is the verifier's SHA-256", async () => {
    const { verifier, challenge } = await pkcePair();
    expect(verifier).toMatch(/^[A-Za-z0-9_-]{43}$/);
    const digest = new Uint8Array(
      await crypto.subtle.digest("SHA-256", new TextEncoder().encode(verifier)),
    );
    const b64 = btoa(String.fromCharCode(...digest))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");
    expect(challenge).toBe(b64);
    expect((await pkcePair()).verifier).not.toBe(verifier);
  });

  it("sends the browser to Auth's authorize with the redirect and challenge", () => {
    const url = new URL(
      authorizeUrl(svc, "google", "https://abc.chromiumapp.org/auth", "challenge123"),
    );
    expect(url.origin + url.pathname).toBe("https://auth.example.test/auth/v1/authorize");
    expect(Object.fromEntries(url.searchParams)).toEqual({
      provider: "google",
      redirect_to: "https://abc.chromiumapp.org/auth",
      code_challenge: "challenge123",
      code_challenge_method: "s256",
    });
  });

  it("lists only the turned-on providers, not email or phone", async () => {
    const f = (async (url: string, init: RequestInit) => {
      expect(url).toBe("https://auth.example.test/auth/v1/settings");
      expect(init.method).toBe("GET");
      return new Response(
        JSON.stringify({
          external: { email: true, phone: false, google: true, apple: true, github: false },
        }),
      );
    }) as unknown as typeof fetch;
    expect(await enabledProviders(svc, f)).toEqual(["google", "apple"]);
  });

  it("trades the code and verifier for a session", async () => {
    const f = (async (url: string, init: RequestInit) => {
      expect(url).toBe("https://auth.example.test/auth/v1/token?grant_type=pkce");
      expect(JSON.parse(String(init.body))).toEqual({ auth_code: "c0de", code_verifier: "v" });
      return new Response(
        JSON.stringify({
          access_token: "at",
          refresh_token: "rt",
          expires_in: 3600,
          user: { id: "u1", email: "a@example.test" },
        }),
      );
    }) as unknown as typeof fetch;
    const s = await exchangeCode(svc, "c0de", "v", f);
    expect(s.refresh_token).toBe("rt");
    expect(s.user.id).toBe("u1");
  });
});
