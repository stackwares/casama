import { describe, expect, it } from "vitest";
import {
  balanceFences,
  parseInline,
  toAdf,
  toEmailHtml,
  toPlain,
  toSlack,
  toTelegramHtml,
  toWhatsApp,
} from "../src/channels/format.ts";

// The reply from the first live Telegram test (2026-11-17), shortened.
const REPLY = `Here's the short version:

**Daily**
- Morning brief at 8am — meetings, emails needing a reply. I can change the *time* or content.

## Email & calendar
- Read Gmail and Calendar, flag what matters (CI failures, PRs)
  - Draft emails for you to send yourself — I never send anything
1. See [the docs](https://casama.ai/docs) or \`casama help\`

What's on your mind?`;

describe("chat app formats (D-340)", () => {
  it("Telegram gets HTML with escaping", () => {
    expect(toTelegramHtml(REPLY)).toBe(
      [
        "Here's the short version:",
        "",
        "<b>Daily</b>",
        "• Morning brief at 8am — meetings, emails needing a reply. I can change the <i>time</i> or content.",
        "",
        "<b>Email &amp; calendar</b>",
        "• Read Gmail and Calendar, flag what matters (CI failures, PRs)",
        "  • Draft emails for you to send yourself — I never send anything",
        '1. See <a href="https://casama.ai/docs">the docs</a> or <code>casama help</code>',
        "",
        "What's on your mind?",
      ].join("\n"),
    );
    expect(toTelegramHtml("if a < b && c > d")).toBe("if a &lt; b &amp;&amp; c &gt; d");
    expect(toTelegramHtml("```ts\nconst x = a<b;\n```")).toBe(
      '<pre><code class="language-ts">const x = a&lt;b;</code></pre>',
    );
    expect(toTelegramHtml("> quoted **bit**")).toBe("<blockquote>quoted <b>bit</b></blockquote>");
    expect(toTelegramHtml("[x](javascript:alert(1))")).not.toContain("<a");
  });

  it("plain text drops the marks and keeps links readable", () => {
    expect(toPlain(REPLY)).toContain("Daily\n• Morning brief");
    expect(toPlain(REPLY)).toContain("Email & calendar");
    expect(toPlain(REPLY)).toContain("1. See the docs (https://casama.ai/docs) or casama help");
    expect(toPlain(REPLY)).not.toMatch(/\*\*|##|`/);
    expect(toPlain("<https://a.io>")).toBe("https://a.io");
    expect(toPlain("[https://a.io](https://a.io)")).toBe("https://a.io");
  });

  it("Slack gets mrkdwn", () => {
    const out = toSlack(REPLY);
    expect(out).toContain("*Daily*");
    expect(out).toContain("_time_");
    expect(out).toContain("*Email &amp; calendar*");
    expect(out).toContain("<https://casama.ai/docs|the docs>");
    expect(toSlack("~~gone~~ and **bold **")).toBe("~gone~ and **bold **");
    expect(toSlack("**a** <b>")).toBe("*a* &lt;b&gt;");
  });

  it("WhatsApp gets its own marks", () => {
    const out = toWhatsApp(REPLY);
    expect(out).toContain("*Daily*\n- Morning brief");
    expect(out).toContain("*Email & calendar*");
    expect(out).toContain("the docs (https://casama.ai/docs)");
    expect(toWhatsApp("```\ncode\n```")).toBe("```code```");
  });

  it("leaves snake_case, lone stars and maths alone", () => {
    expect(toPlain("set max_run_count to 2 * 3 * 4")).toBe("set max_run_count to 2 * 3 * 4");
    expect(toTelegramHtml("price: 5 * 2")).toBe("price: 5 * 2");
    expect(toPlain("\\*not italic\\*")).toBe("*not italic*");
    expect(parseInline("**bold *and italic***")).toEqual([
      {
        t: "b",
        c: [
          { t: "text", v: "bold " },
          { t: "i", c: [{ t: "text", v: "and italic" }] },
        ],
      },
    ]);
  });

  it("tables become aligned text, or real tables where the app has them", () => {
    const md = "| Plan | Price |\n|---|---:|\n| Plus | $15 |\n| Max | $99 |";
    expect(toTelegramHtml(md)).toBe("<pre>Plan  Price\n----  -----\nPlus  $15\nMax   $99</pre>");
    expect(toEmailHtml(md)).toContain("<table");
    const adf = toAdf(md) as { content: Array<{ type: string }> };
    expect(adf.content[0]?.type).toBe("table");
  });

  it("email gets an HTML body", () => {
    const html = toEmailHtml(REPLY);
    expect(html).toContain("<strong>Daily</strong>");
    expect(html).toContain('<a href="https://casama.ai/docs">the docs</a>');
    expect(html).toMatch(/<ul><li>Read Gmail[\s\S]*<ul><li>Draft emails/);
    expect(html).toContain("<h3>Email &amp; calendar</h3>");
  });

  it("Jira gets document nodes with marks", () => {
    const doc = toAdf("Hi **Ana**, see [docs](https://x.io)\n\n- one\n- two") as {
      content: Array<Record<string, unknown>>;
    };
    expect(doc.content[0]).toEqual({
      type: "paragraph",
      content: [
        { type: "text", text: "Hi " },
        { type: "text", text: "Ana", marks: [{ type: "strong" }] },
        { type: "text", text: ", see " },
        { type: "text", text: "docs", marks: [{ type: "link", attrs: { href: "https://x.io" } }] },
      ],
    });
    expect(doc.content[1]?.type).toBe("bulletList");
  });

  it("a code block split across parts is closed and reopened", () => {
    expect(balanceFences(["Intro\n```py\nline 1", "line 2\n```\nDone"])).toEqual([
      "Intro\n```py\nline 1\n```",
      "```py\nline 2\n```\nDone",
    ]);
    expect(balanceFences(["a", "b"])).toEqual(["a", "b"]);
  });

  it("never throws on odd input", () => {
    for (const s of ["", "**", "[", "[a](", "```", "|a|\n|-|", "> ", "1.", "* ", "\\", "<", "~~~"])
      for (const fn of [toPlain, toTelegramHtml, toSlack, toWhatsApp, toEmailHtml, toAdf])
        expect(() => fn(s)).not.toThrow();
  });
});
