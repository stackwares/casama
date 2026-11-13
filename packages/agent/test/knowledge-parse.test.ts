import { deflateSync } from "node:zlib";
import { strToU8, zipSync } from "fflate";
import { describe, expect, it } from "vitest";
import { robotsRules } from "../src/knowledge.ts";
import {
  chunkSections,
  csvRows,
  parseDocument,
  parsePdfStreams,
  SCANNED_PDF,
} from "../src/knowledge-parse.ts";

const enc = (s: string) => new TextEncoder().encode(s);

describe("knowledge parsing", () => {
  it("splits Markdown and HTML by heading", async () => {
    const md = await parseDocument(
      "guide.md",
      enc("# Handbook\n\nIntro.\n\n## Leave\n\nTwenty days a year."),
    );
    expect(md.title).toBe("Handbook");
    expect(md.sections).toEqual([
      { location: "Handbook", text: "Intro." },
      { location: "Leave", text: "Twenty days a year." },
    ]);
    const html = await parseDocument(
      "p.html",
      enc(
        "<html><head><title>Pricing &amp; plans</title><script>var x=1</script></head><body><nav>Home</nav><h2>Pro</h2><p>$12 a month</p></body></html>",
      ),
    );
    expect(html.title).toBe("Pricing & plans");
    expect(html.sections).toEqual([{ location: "Pro", text: "$12 a month" }]);
  });

  it("reads CSV with quotes and keeps the header with each row", async () => {
    expect(csvRows('a,b\n"x, y","say ""hi"""\n')).toEqual([
      ["a", "b"],
      ["x, y", 'say "hi"'],
    ]);
    const doc = await parseDocument("people.csv", enc("name,team\nAna,Ops\nBen,Sales\n"));
    expect(doc.sections[0]?.text).toBe("name: Ana; team: Ops\nname: Ben; team: Sales");
  });

  it("reads a Word document with headings", async () => {
    const xml = `<w:document><w:body><w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>Refunds</w:t></w:r></w:p><w:p><w:r><w:t>Within 30 </w:t></w:r><w:r><w:t>days.</w:t></w:r></w:p></w:body></w:document>`;
    const doc = await parseDocument("policy.docx", zipSync({ "word/document.xml": strToU8(xml) }));
    expect(doc.sections).toEqual([{ location: "Refunds", text: "Within 30 days." }]);
  });

  it("reads text from a PDF's compressed content streams, page by page", async () => {
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
    const doc = await parseDocument("report.pdf", pdf);
    expect(doc.sections.map((s) => s.location)).toEqual(["page 1", "page 2"]);
    expect(doc.sections[0]?.text).toBe("Hello (world)\nSecond line");
    await expect(parseDocument("x.exe", enc("x"))).rejects.toThrow(/Unsupported/);
  });

  it("chunks long sections and follows robots.txt", async () => {
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

  it("reads a well-formed PDF whose text is hex-encoded, which the old reader returned empty (D-273)", async () => {
    // A real PDF with an xref table; its text is written as <hex> strings, as most exporters do.
    const hex = (t: string) => Buffer.from(t, "latin1").toString("hex");
    const content = `BT /F1 12 Tf 72 720 Td <${hex("Quarterly revenue rose 12%")}> Tj ET`;
    const objs = [
      "<< /Type /Catalog /Pages 2 0 R >>",
      "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
      "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>",
      `<< /Length ${content.length} >>\nstream\n${content}\nendstream`,
      "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>",
    ];
    let body = "%PDF-1.4\n";
    const offsets: number[] = [];
    objs.forEach((o, i) => {
      offsets.push(body.length);
      body += `${i + 1} 0 obj\n${o}\nendobj\n`;
    });
    const xref = body.length;
    body += `xref\n0 ${objs.length + 1}\n0000000000 65535 f \n`;
    for (const off of offsets) body += `${String(off).padStart(10, "0")} 00000 n \n`;
    body += `trailer\n<< /Size ${objs.length + 1} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF`;
    const pdf = Buffer.from(body, "latin1");
    expect(parsePdfStreams(pdf, "q").sections).toEqual([]);
    const doc = await parseDocument("q3.pdf", pdf);
    expect(doc.sections).toEqual([{ location: "page 1", text: "Quarterly revenue rose 12%" }]);
  });

  it("a PDF with no text layer says so instead of indexing nothing", async () => {
    await expect(parseDocument("scan.pdf", Buffer.from("%PDF-1.4\n%%EOF"))).rejects.toThrow(
      SCANNED_PDF,
    );
  });
});
