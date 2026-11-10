import { deflateSync } from "node:zlib";
import { strToU8, zipSync } from "fflate";
import { describe, expect, it } from "vitest";
import { robotsRules } from "../src/knowledge.ts";
import { chunkSections, csvRows, parseDocument } from "../src/knowledge-parse.ts";

const enc = (s: string) => new TextEncoder().encode(s);

describe("knowledge parsing", () => {
  it("splits Markdown and HTML by heading", () => {
    const md = parseDocument(
      "guide.md",
      enc("# Handbook\n\nIntro.\n\n## Leave\n\nTwenty days a year."),
    );
    expect(md.title).toBe("Handbook");
    expect(md.sections).toEqual([
      { location: "Handbook", text: "Intro." },
      { location: "Leave", text: "Twenty days a year." },
    ]);
    const html = parseDocument(
      "p.html",
      enc(
        "<html><head><title>Pricing &amp; plans</title><script>var x=1</script></head><body><nav>Home</nav><h2>Pro</h2><p>$12 a month</p></body></html>",
      ),
    );
    expect(html.title).toBe("Pricing & plans");
    expect(html.sections).toEqual([{ location: "Pro", text: "$12 a month" }]);
  });

  it("reads CSV with quotes and keeps the header with each row", () => {
    expect(csvRows('a,b\n"x, y","say ""hi"""\n')).toEqual([
      ["a", "b"],
      ["x, y", 'say "hi"'],
    ]);
    const doc = parseDocument("people.csv", enc("name,team\nAna,Ops\nBen,Sales\n"));
    expect(doc.sections[0]?.text).toBe("name: Ana; team: Ops\nname: Ben; team: Sales");
  });

  it("reads a Word document with headings", () => {
    const xml = `<w:document><w:body><w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>Refunds</w:t></w:r></w:p><w:p><w:r><w:t>Within 30 </w:t></w:r><w:r><w:t>days.</w:t></w:r></w:p></w:body></w:document>`;
    const doc = parseDocument("policy.docx", zipSync({ "word/document.xml": strToU8(xml) }));
    expect(doc.sections).toEqual([{ location: "Refunds", text: "Within 30 days." }]);
  });

  it("reads text from a PDF's compressed content streams, page by page", () => {
    const page = (t: string) => {
      const stream = deflateSync(
        Buffer.from(`BT /F1 12 Tf 72 720 Td (${t}) Tj 0 -14 Td [(Sec) 20 (ond) -300 (line)] TJ ET`),
      );
      return Buffer.concat([
        Buffer.from(`<< /Length ${stream.length} /Filter /FlateDecode >>\nstream\n`),
        stream,
        Buffer.from("\nendstream\n"),
      ]);
    };
    const pdf = Buffer.concat([
      Buffer.from("%PDF-1.4\n1 0 obj\n"),
      page("Hello \\(world\\)"),
      Buffer.from("endobj\n2 0 obj\n"),
      page("Page two"),
      Buffer.from("endobj\n%%EOF"),
    ]);
    const doc = parseDocument("report.pdf", pdf);
    expect(doc.sections.map((s) => s.location)).toEqual(["page 1", "page 2"]);
    expect(doc.sections[0]?.text).toBe("Hello (world)\nSecond line");
    expect(() => parseDocument("x.exe", enc("x"))).toThrow(/Unsupported/);
  });

  it("chunks long sections and follows robots.txt", () => {
    const long = Array.from({ length: 40 }, (_, i) => `Sentence number ${i} is here.`).join(" ");
    const chunks = chunkSections([{ location: "A", text: long }], 300);
    expect(chunks.length).toBeGreaterThan(3);
    expect(chunks.every((c) => c.text.length <= 340 && c.location === "A")).toBe(true);
    const allowed = robotsRules(
      "User-agent: *\nDisallow: /private\nAllow: /private/open\n\nUser-agent: other\nDisallow: /",
    );
    expect(allowed("/docs")).toBe(true);
    expect(allowed("/private/x")).toBe(false);
    expect(allowed("/private/open/y")).toBe(true);
  });
});
