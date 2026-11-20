import { describe, expect, it } from "vitest";
import {
  apiAuthResults,
  cloudflareAuthResults,
  isAutomaticMail,
  senderCheckFrom,
  senderCheckFromResend,
} from "../src/index.ts";

const h = (key: string, value: string) => ({ key, value });

describe("sender check", () => {
  it("reads Cloudflare's prepended results", () => {
    const r = cloudflareAuthResults([
      h("authentication-results", "mx.cloudflare.net; spf=pass; dkim=pass; dmarc=pass"),
    ]);
    expect(r).toMatchObject({ spf: "pass", dkim: "pass", dmarc: "pass" });
    expect(senderCheckFrom(r)).toBe("pass");
  });

  it("ignores a sender's faked header on top of nothing", () => {
    expect(cloudflareAuthResults([h("authentication-results", "evil.com; dmarc=pass")])).toBeNull();
    expect(senderCheckFrom(null)).toBe("none");
  });

  it("ignores everything below the first header", () => {
    const r = cloudflareAuthResults([
      h("authentication-results", "mx.cloudflare.net; spf=fail; dkim=fail; dmarc=fail"),
      h("authentication-results", "mx.cloudflare.net; spf=pass; dkim=pass; dmarc=pass"),
    ]);
    expect(senderCheckFrom(r)).toBe("fail");
  });

  it("confirms SPF or DKIM for the From domain when it has no DMARC", () => {
    const spf = cloudflareAuthResults([
      h(
        "authentication-results",
        "mx.cloudflare.net; spf=pass smtp.mailfrom=bounce.example.com; dmarc=none",
      ),
    ]);
    expect(senderCheckFrom(spf, "example.com")).toBe("pass");
    // The attack: SPF passes for the attacker's domain, not the From domain.
    expect(senderCheckFrom(spf, "owner.com")).toBe("fail");
    const dkim = cloudflareAuthResults([
      h(
        "authentication-results",
        "mx.cloudflare.net; dkim=pass header.d=example.com header.i=@example.com; dmarc=none",
      ),
    ]);
    expect(senderCheckFrom(dkim, "example.com")).toBe("pass");
    expect(senderCheckFrom(dkim, "owner.com")).toBe("fail");
    // A bare pass with no domain to check it against fails.
    expect(senderCheckFrom({ spf: "pass", dmarc: "none" }, "example.com")).toBe("fail");
    expect(senderCheckFrom({ dkim: "pass", dmarc: "none" }, "example.com")).toBe("fail");
    expect(senderCheckFrom({ spf: "none", dkim: "none", dmarc: "none" }, "example.com")).toBe(
      "fail",
    );
    expect(senderCheckFrom({ spf: "pass", dmarc: "reject" }, "example.com")).toBe("fail");
  });

  it("reads any prepended results for the self-hosted app", () => {
    expect(apiAuthResults([h("subject", "hi")])).toBeNull();
    const r = apiAuthResults([h("Authentication-Results", "router.example; dmarc=pass")]);
    expect(senderCheckFrom(r)).toBe("pass");
  });

  it("reads Resend's authentication object", () => {
    expect(senderCheckFromResend({ spf: "pass", dkim: "pass", dmarc: "pass" })).toBe("pass");
    // Gray is Resend's word for "no DMARC policy": DKIM passing confirms (its verdict is
    // From-aware), SPF passing alone doesn't (it checks the envelope, not From).
    expect(senderCheckFromResend({ spf: "gray", dkim: "pass", dmarc: "gray" })).toBe("pass");
    expect(senderCheckFromResend({ spf: "pass", dkim: "gray", dmarc: "gray" })).toBe("fail");
    expect(senderCheckFromResend({ spf: "fail", dkim: "fail", dmarc: "fail" })).toBe("fail");
  });

  it("matches DMARC header.from to the From domain and ignores planted dmarc=pass in other clauses", () => {
    const mismatch = cloudflareAuthResults([
      h("authentication-results", "mx.cloudflare.net; dmarc=pass header.from=evil.com"),
    ]);
    expect(senderCheckFrom(mismatch, "owner.com")).toBe("fail");
    expect(senderCheckFrom(mismatch, "evil.com")).toBe("pass");
    // Planted inside DKIM or a comment must never count as a DMARC pass.
    const plantedDkim = cloudflareAuthResults([
      h(
        "authentication-results",
        "mx.cloudflare.net; dkim=pass header.s=dmarc=pass header.d=evil.com; dmarc=fail",
      ),
    ]);
    expect(plantedDkim?.dmarc).toBe("fail");
    expect(senderCheckFrom(plantedDkim, "owner.com")).toBe("fail");
    const plantedComment = cloudflareAuthResults([
      h("authentication-results", "mx.cloudflare.net; dkim=fail (dmarc=pass); dmarc=fail"),
    ]);
    expect(plantedComment?.dmarc).toBe("fail");
    expect(senderCheckFrom(plantedComment, "owner.com")).toBe("fail");
    const semiInComment = cloudflareAuthResults([
      h("authentication-results", "mx.cloudflare.net; dkim=fail (foo; dmarc=pass); dmarc=fail"),
    ]);
    expect(semiInComment?.dmarc).toBe("fail");
    expect(senderCheckFrom(semiInComment, "owner.com")).toBe("fail");
  });
});

describe("automatic mail", () => {
  it("recognizes bounces, out-of-office and lists", () => {
    expect(isAutomaticMail([h("auto-submitted", "auto-replied")], "a@b.c")).toBe(true);
    expect(isAutomaticMail([h("auto-submitted", "no")], "a@b.c")).toBe(false);
    expect(isAutomaticMail([h("x-autoreply", "yes")], "a@b.c")).toBe(true);
    expect(isAutomaticMail([h("x-autoreply", "no")], "a@b.c")).toBe(false);
    expect(isAutomaticMail([h("x-auto-response-suppress", "All")], "a@b.c")).toBe(true);
    expect(isAutomaticMail([], "")).toBe(true);
    expect(isAutomaticMail([], "<>")).toBe(true);
    expect(isAutomaticMail([], "a@b.c", "")).toBe(true);
    expect(isAutomaticMail([h("precedence", "bulk")], "a@b.c")).toBe(true);
    expect(isAutomaticMail([h("precedence", "list")], "a@b.c")).toBe(true);
    expect(isAutomaticMail([h("list-id", "<x.y>")], "a@b.c")).toBe(true);
    expect(isAutomaticMail([], "mailer-daemon@example.com")).toBe(true);
    expect(isAutomaticMail([], "postmaster@example.com")).toBe(true);
    expect(isAutomaticMail([], "oliver@example.com")).toBe(false);
  });
});
