import { describe, expect, it } from "vitest";
import { PAGE_CSP, renderPage, scriptJson } from "../src/pages.ts";

describe("pages", () => {
  it("keeps data inside its script block", () => {
    const s = scriptJson({ a: "</script><script>alert(1)</script>", b: " " });
    expect(s).not.toContain("<");
    expect(JSON.parse(s)).toEqual({ a: "</script><script>alert(1)</script>", b: " " });
  });

  it("adds the head, data and updated line to a full document once", () => {
    const html = renderPage({
      title: "T",
      html: "<html><head><title>X</title></head><body><p>a</p></body></html>",
      data: { n: 1 },
      updatedAt: new Date("2026-11-10T09:30:00Z"),
    });
    expect(html.match(/kasama-data/g)).toHaveLength(1);
    expect(html).toContain('<meta name="robots" content="noindex,nofollow">');
    expect(html).toContain(
      'Updated <time datetime="2026-11-10T09:30:00.000Z">2026-11-10 09:30 UTC</time></div></body>',
    );
  });

  it("wraps a fragment and escapes the title", () => {
    const html = renderPage({ title: "<b>", html: "<p>x</p>", data: {}, updatedAt: new Date(0) });
    expect(html).toContain("<title>&#60;b&#62;</title>");
    expect(html).toContain("<p>x</p>");
  });

  it("blocks network requests and outside forms", () => {
    expect(PAGE_CSP).toContain("connect-src 'none'");
    expect(PAGE_CSP).toContain("form-action 'none'");
    expect(PAGE_CSP).toContain("default-src 'none'");
  });
});
