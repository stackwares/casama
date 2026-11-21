import { describe, expect, it } from "vitest";
import {
  requireFreshAdminAuthentication as check,
  hasFreshAuthentication,
} from "../src/api/admin-security.ts";
import { ApiError } from "../src/api/errors.ts";

const now = 10_000;
const claims = (timestamp: unknown, method = "password") => ({
  sub: "owner",
  amr: [{ method, timestamp }],
});
const denied = (run: () => void, code: string) => {
  try {
    run();
    throw new Error("Expected rejection");
  } catch (error) {
    expect(error).toBeInstanceOf(ApiError);
    expect(error).toMatchObject({ code });
  }
};

describe("admin authentication freshness", () => {
  it("allows recent proof and bounds reads and writes independently", () => {
    expect(() => check("GET", "/v1/admin/users", claims(now - 300), now)).not.toThrow();
    expect(() => check("PATCH", "/v1/admin/orgs/id/limits", claims(now - 60), now)).not.toThrow();
    denied(
      () => check("GET", "/v1/admin/users", claims(now - 301), now),
      "admin_reauthentication_required",
    );
    for (const method of ["POST", "PATCH", "PUT", "DELETE"]) {
      denied(
        () => check(method, "/v1/admin/vendor", claims(now - 61), now),
        "admin_confirmation_required",
      );
    }
  });
  it("does not let token issuance or refresh renew authentication", () => {
    for (const proof of [
      { sub: "owner", iat: now },
      { ...claims(now - 301), iat: now },
      {
        sub: "owner",
        amr: [
          { method: "password", timestamp: now - 301 },
          { method: "token_refresh", timestamp: now },
        ],
      },
    ])
      denied(() => check("GET", "/v1/admin/users", proof, now), "admin_reauthentication_required");
  });
  it("rejects future, malformed and non-interactive authentication", () => {
    for (const timestamp of [now + 1, "10000", null, NaN, Infinity, -1, 0]) {
      denied(
        () => check("GET", "/v1/admin/users", claims(timestamp), now),
        "admin_reauthentication_required",
      );
    }
    for (const method of ["token_refresh", "anonymous", "recovery", "invite", "unknown"]) {
      denied(
        () => check("POST", "/v1/admin/action", claims(now, method), now),
        "admin_confirmation_required",
      );
    }
    for (const amr of [null, {}, [null], ["password"], [{}]]) {
      denied(
        () => check("GET", "/v1/admin/users", { sub: "owner", amr }, now),
        "admin_reauthentication_required",
      );
    }
  });
  it("accepts the latest real step even alongside stale or refresh entries", () => {
    for (const method of ["password", "otp", "totp", "oauth", "sso/saml", "magiclink", "passkey"]) {
      expect(() => check("POST", "/v1/admin/action", claims(now, method), now)).not.toThrow();
    }
  });
  it("exempts only exact GET owner discovery and requires a login elsewhere", () => {
    expect(() => check("GET", "/v1/admin/overview", { sub: "owner" }, now)).not.toThrow();
    denied(
      () => check("POST", "/v1/admin/overview", { sub: "owner" }, now),
      "admin_confirmation_required",
    );
    denied(() => check("GET", "/v1/admin/users", undefined, now), "unauthorized");
  });
  it("reading Casama Link's status needs no fresh sign-in; changing it does (D-463)", () => {
    expect(() => check("GET", "/v1/admin/remote-access", { sub: "owner" }, now)).not.toThrow();
    expect(() =>
      check("POST", "/v1/admin/remote-access/check", { sub: "owner" }, now),
    ).not.toThrow();
    denied(
      () => check("PUT", "/v1/admin/remote-access/settings", { sub: "owner" }, now),
      "admin_confirmation_required",
    );
    denied(
      () => check("POST", "/v1/admin/remote-access", { sub: "owner" }, now),
      "admin_confirmation_required",
    );
  });
  it("owner actions outside the console use the one-minute window", () => {
    expect(hasFreshAuthentication(claims(now - 60), true, now)).toBe(true);
    expect(hasFreshAuthentication(claims(now - 61), true, now)).toBe(false);
    expect(hasFreshAuthentication(claims(now - 61), false, now)).toBe(true);
  });
});
