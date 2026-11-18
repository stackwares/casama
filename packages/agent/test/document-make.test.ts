/** PDF and Word files from Markdown (D-351), read back through the knowledge parsers. */
import { existsSync } from "node:fs";
import { join } from "node:path";
import { PDFDocument } from "pdf-lib";
import sharp from "sharp";
import { describe, expect, it } from "vitest";
import {
  DEFAULT_CJK_FONT_DIR,
  imageRefs,
  MAX_DOC_PAGES,
  makeDocument,
} from "../src/document-make.ts";
import { FileOpError } from "../src/file-ops.ts";
import { parseDocx, parsePdf } from "../src/knowledge-parse.ts";

const SAMPLE = `# Trip plan

Leave **Friday** at *9 am*, with ~~two~~ three bags. See [the map](https://example.com/map).

## Packing

- Passport
- Charger
  - USB-C cable
- Snacks

1. Book the hotel
2. Rent a car

| Day | Place | Cost |
| --- | --- | --- |
| Fri | Baguio | 2,500 |
| Sat | Sagada | 1,800 |

> Bring a jacket: it gets cold at night.

\`\`\`
total = 2500 + 1800
\`\`\`

---

Use \`code\` inline & keep <b>HTML</b> text.
`;

const textOfPdf = async (bytes: Uint8Array) =>
  (await parsePdf(bytes, "x")).sections.map((s) => s.text).join("\n");
const textOfDocx = (bytes: Uint8Array) =>
  parseDocx(bytes, "x")
    .sections.map((s) => `${s.location ?? ""}\n${s.text}`)
    .join("\n");

const cjkDir = process.env.CJK_FONT_DIR || DEFAULT_CJK_FONT_DIR;
const haveCjk = existsSync(join(cjkDir, "NotoSansCJK-Regular.ttc"));

describe("PDF", () => {
  it("writes every Markdown element with page numbers", async () => {
    const r = await makeDocument({ markdown: SAMPLE, format: "pdf", title: "Trip" });
    expect(r.contentType).toBe("application/pdf");
    expect(r.pages).toBe(1);
    const text = await textOfPdf(r.bytes);
    for (const s of [
      "Trip plan",
      "Friday",
      "the map",
      "Passport",
      "USB-C cable",
      "Book the hotel",
      "Sagada",
      "1,800",
      "Bring a jacket",
      "total = 2500 + 1800",
      "HTML text",
      "1 / 1",
    ])
      expect(text).toContain(s);
    expect(text).not.toContain("<b>");
    expect((await PDFDocument.load(r.bytes)).getTitle()).toBe("Trip");
  });

  it("uses the page size asked for", async () => {
    const a4 = await makeDocument({ markdown: "Hi", format: "pdf" });
    const letter = await makeDocument({ markdown: "Hi", format: "pdf", pageSize: "letter" });
    const size = async (b: Uint8Array) =>
      (await PDFDocument.load(b)).getPage(0).getSize().width.toFixed(0);
    expect(await size(a4.bytes)).toBe("595");
    expect(await size(letter.bytes)).toBe("612");
  });

  it("puts in pictures by their address, and shows the caption for missing ones", async () => {
    const png = new Uint8Array(
      await sharp({ create: { width: 400, height: 300, channels: 3, background: "#2a6" } })
        .png()
        .toBuffer(),
    );
    const md = "Before\n\n![Receipt](media:aaaa)\n\n![Lost one](media:bbbb)\n\nAfter";
    expect(imageRefs(`${md}\n\n![web](https://x.test/a.png)`)).toEqual([
      "media:aaaa",
      "media:bbbb",
    ]);
    const r = await makeDocument({
      markdown: md,
      format: "pdf",
      images: new Map([["media:aaaa", { bytes: png, contentType: "image/png" }]]),
    });
    const text = await textOfPdf(r.bytes);
    expect(text).toContain("Lost one");
    expect(text).not.toContain("Receipt");
    expect(Buffer.from(r.bytes).toString("latin1")).toContain("/Subtype /Image");
  });

  it("refuses an empty document and one over the page limit", async () => {
    await expect(makeDocument({ markdown: "  ", format: "pdf" })).rejects.toBeInstanceOf(
      FileOpError,
    );
    const long = Array.from(
      { length: MAX_DOC_PAGES + 5 },
      (_, i) => `# Page ${i}\n\n${"Line\n\n".repeat(40)}`,
    ).join("\n");
    await expect(makeDocument({ markdown: long, format: "pdf" })).rejects.toThrow(/limit is 200/);
  }, 60_000);

  it("says so when the server has no CJK fonts", async () => {
    await expect(
      makeDocument({ markdown: "你好", format: "pdf", cjkFontDir: "/nowhere" }),
    ).rejects.toThrow(/no Chinese, Japanese or Korean fonts/);
  });

  it.skipIf(!haveCjk)(
    "writes Chinese, Japanese and Korean with Noto Sans CJK",
    async () => {
      const md =
        "# 旅行の計画\n\n東京で**寿司**を食べる。\n\n한국어 문장입니다.\n\n中文：你好，世界。 Mixed with English.";
      const r = await makeDocument({ markdown: md, format: "pdf", cjkFontDir: cjkDir });
      const text = await textOfPdf(r.bytes);
      for (const s of ["旅行の計画", "寿司", "한국어", "你好", "Mixed with English"])
        expect(text.replace(/\s+/g, "")).toContain(s.replace(/\s+/g, ""));
      const raw = Buffer.from(r.bytes).toString("latin1");
      expect(raw).toContain("NotoSansCJKjp");
      expect(raw).toContain("NotoSansCJKkr");
    },
    60_000,
  );
});

describe("Word", () => {
  it("writes every Markdown element", async () => {
    const r = await makeDocument({ markdown: SAMPLE, format: "docx", title: "Trip" });
    expect(r.ext).toBe("docx");
    expect(r.pages).toBeNull();
    const text = textOfDocx(r.bytes);
    for (const s of [
      "Trip plan",
      "Friday",
      "the map",
      "Passport",
      "USB-C cable",
      "Book the hotel",
      "Sagada",
      "Bring a jacket",
      "total = 2500 + 1800",
      "HTML text",
    ])
      expect(text).toContain(s);
  });

  it("keeps Chinese, Japanese and Korean text without server fonts", async () => {
    const r = await makeDocument({
      markdown: "你好 こんにちは 안녕하세요",
      format: "docx",
      cjkFontDir: "/nowhere",
    });
    expect(textOfDocx(r.bytes)).toContain("こんにちは");
  });

  it("puts in pictures", async () => {
    const jpg = new Uint8Array(
      await sharp({ create: { width: 2400, height: 1200, channels: 3, background: "#a62" } })
        .jpeg()
        .toBuffer(),
    );
    const r = await makeDocument({
      markdown: "![Photo](media:cccc)",
      format: "docx",
      images: new Map([["media:cccc", { bytes: jpg, contentType: "image/jpeg" }]]),
    });
    const { unzipSync } = await import("fflate");
    const files = Object.keys(unzipSync(r.bytes));
    expect(files.some((f) => f.startsWith("word/media/"))).toBe(true);
  });
});
