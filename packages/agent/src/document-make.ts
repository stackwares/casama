/**
 * PDF and Word files from Markdown, without a computer (D-351, docs/DOCUMENT-FILES-PLAN.md).
 * Markdown is read once with marked's lexer into a small block model, then written out with
 * pdfmake (PDF) or docx (Word). Plain look: black text, one font family, page numbers.
 * Chinese, Japanese and Korean in PDFs use the server's Noto Sans CJK; Word files leave fonts to
 * the reader's computer.
 */
import { existsSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, join } from "node:path";
import * as docx from "docx";
import { marked, type Token, type Tokens } from "marked";
import { PDFDocument as PdfLibDocument } from "pdf-lib";
import sharp from "sharp";
import { FileOpError } from "./file-ops.ts";

/** Most pages and bytes a made file may have. */
export const MAX_DOC_PAGES = 200;
export const MAX_DOC_BYTES = 10 * 1024 * 1024;
/** Where Debian's fonts-noto-cjk puts the collections (the server image copies them there). */
export const DEFAULT_CJK_FONT_DIR = "/usr/share/fonts/opentype/noto";

export interface DocImage {
  bytes: Uint8Array;
  contentType: string;
}

export interface MakeDocument {
  markdown: string;
  format: "pdf" | "docx";
  title?: string;
  pageSize?: "a4" | "letter";
  /** Pictures the Markdown points at (`![alt](media:<id>)`), by that address. */
  images?: Map<string, DocImage>;
  cjkFontDir?: string;
}

// ------------------------------------------------------------------ the block model

interface Run {
  text: string;
  bold?: boolean;
  italic?: boolean;
  strike?: boolean;
  code?: boolean;
  link?: string;
}
type Block =
  | { kind: "heading"; level: number; runs: Run[] }
  | { kind: "para"; runs: Run[] }
  | { kind: "list"; ordered: boolean; start: number; items: Block[][] }
  | { kind: "table"; header: Run[][]; rows: Run[][][] }
  | { kind: "quote"; blocks: Block[] }
  | { kind: "code"; text: string }
  | { kind: "rule" }
  | { kind: "image"; ref: string; alt: string };

const decode = (s: string) =>
  s
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&");
const stripTags = (s: string) => decode(s.replace(/<br\s*\/?>/gi, "\n").replace(/<[^>]+>/g, ""));
const safeLink = (href: string) => (/^(https?:|mailto:)/i.test(href) ? href : undefined);

type Style = Omit<Run, "text">;
type Inline = Run | { image: string; alt: string };

function inlines(tokens: Token[] | undefined, style: Style = {}): Inline[] {
  const out: Inline[] = [];
  for (const t of tokens ?? []) {
    switch (t.type) {
      case "strong":
        out.push(...inlines((t as Tokens.Strong).tokens, { ...style, bold: true }));
        break;
      case "em":
        out.push(...inlines((t as Tokens.Em).tokens, { ...style, italic: true }));
        break;
      case "del":
        out.push(...inlines((t as Tokens.Del).tokens, { ...style, strike: true }));
        break;
      case "codespan":
        out.push({ ...style, code: true, text: decode((t as Tokens.Codespan).text) });
        break;
      case "link": {
        const l = t as Tokens.Link;
        out.push(...inlines(l.tokens, { ...style, link: safeLink(l.href) ?? style.link }));
        break;
      }
      case "image": {
        const i = t as Tokens.Image;
        out.push({ image: i.href, alt: i.text });
        break;
      }
      case "br":
        out.push({ ...style, text: "\n" });
        break;
      case "html":
        out.push({ ...style, text: stripTags((t as Tokens.HTML).text) });
        break;
      case "text": {
        const x = t as Tokens.Text;
        if (x.tokens?.length) out.push(...inlines(x.tokens, style));
        else out.push({ ...style, text: decode(x.text) });
        break;
      }
      default:
        if ("text" in t && typeof t.text === "string") out.push({ ...style, text: decode(t.text) });
    }
  }
  return out;
}

/** A paragraph's inline content; pictures in it become their own blocks, in place. */
function paragraphBlocks(tokens: Token[] | undefined): Block[] {
  const out: Block[] = [];
  let runs: Run[] = [];
  const flush = () => {
    if (runs.some((r) => r.text.trim())) out.push({ kind: "para", runs });
    runs = [];
  };
  for (const x of inlines(tokens)) {
    if ("image" in x) {
      flush();
      out.push({ kind: "image", ref: x.image, alt: x.alt });
    } else runs.push(x);
  }
  flush();
  return out;
}

const cellRuns = (tokens: Token[] | undefined) =>
  inlines(tokens).flatMap((x) => ("image" in x ? [{ text: x.alt }] : [x]));

function blocks(tokens: Token[]): Block[] {
  const out: Block[] = [];
  for (const t of tokens) {
    switch (t.type) {
      case "heading": {
        const h = t as Tokens.Heading;
        out.push({ kind: "heading", level: h.depth, runs: cellRuns(h.tokens) });
        break;
      }
      case "paragraph":
      case "text":
        out.push(
          ...paragraphBlocks((t as Tokens.Paragraph).tokens ?? [{ ...t, tokens: undefined }]),
        );
        break;
      case "list": {
        const l = t as Tokens.List;
        out.push({
          kind: "list",
          ordered: l.ordered,
          start: typeof l.start === "number" ? l.start : 1,
          items: l.items.map((i) => blocks(i.tokens)),
        });
        break;
      }
      case "table": {
        const tb = t as Tokens.Table;
        out.push({
          kind: "table",
          header: tb.header.map((c) => cellRuns(c.tokens)),
          rows: tb.rows.map((r) => r.map((c) => cellRuns(c.tokens))),
        });
        break;
      }
      case "blockquote":
        out.push({ kind: "quote", blocks: blocks((t as Tokens.Blockquote).tokens) });
        break;
      case "code":
        out.push({ kind: "code", text: (t as Tokens.Code).text });
        break;
      case "hr":
        out.push({ kind: "rule" });
        break;
      case "html": {
        const text = stripTags((t as Tokens.HTML).text).trim();
        if (text) out.push({ kind: "para", runs: [{ text }] });
        break;
      }
      default:
        break;
    }
  }
  return out;
}

const parse = (markdown: string) => blocks(marked.lexer(markdown, { gfm: true }));

/** The picture addresses a Markdown text points at that aren't web links (media: ids, paths). */
export function imageRefs(markdown: string): string[] {
  const refs = new Set<string>();
  marked.walkTokens(marked.lexer(markdown, { gfm: true }), (t) => {
    if (t.type === "image" && !/^(https?:|data:)/i.test((t as Tokens.Image).href))
      refs.add((t as Tokens.Image).href);
  });
  return [...refs];
}

// ------------------------------------------------------------------ pictures

interface Prepared {
  bytes: Buffer;
  type: "png" | "jpg";
  width: number;
  height: number;
}

/** Pictures turned upright, at most 1,600 px, as PNG (transparent) or JPEG. */
async function preparePictures(images: Map<string, DocImage> | undefined) {
  const out = new Map<string, Prepared>();
  for (const [ref, img] of images ?? []) {
    const png = img.contentType.includes("png") || img.contentType.includes("gif");
    const pipe = sharp(img.bytes, { limitInputPixels: 50_000_000 })
      .rotate()
      .resize(1600, 1600, { fit: "inside", withoutEnlargement: true });
    const r = await (png
      ? pipe.png()
      : pipe.flatten({ background: "#ffffff" }).jpeg({ quality: 85 })
    )
      .toBuffer({ resolveWithObject: true })
      .catch(() => null);
    if (r) out.set(ref, { bytes: r.data, type: png ? "png" : "jpg", ...r.info });
  }
  return out;
}

// ------------------------------------------------------------------ scripts and fonts

const HANGUL = /[ᄀ-ᇿ㄰-㆏ꥠ-꥿가-힯ힰ-퟿]/u;
const KANA = /[぀-ヿㇰ-ㇿｦ-ﾟ]/u;
const CJK = /[ᄀ-ᇿ⺀-⿟⿰-〿぀-ㇿ㈀-䶿一-鿿ꥠ-꥿가-퟿豈-﫿︰-﹏＀-￯\u{20000}-\u{3134F}]/u;
const CJK_RUNS = new RegExp(`(${CJK.source}+)`, "gu");

type CjkFamily = "CJK_SC" | "CJK_JP" | "CJK_KR";

/** Han characters are drawn the way the document's language writes them. */
function hanFamily(text: string): CjkFamily {
  if (KANA.test(text)) return "CJK_JP";
  if (HANGUL.test(text)) return "CJK_KR";
  return "CJK_SC";
}

const req = createRequire(import.meta.url);
const ROBOTO = dirname(req.resolve("pdfmake/fonts/Roboto.js"));

function pdfFonts(cjkDir: string | null) {
  const fonts: Record<string, Record<string, string | [string, string]>> = {
    Roboto: {
      normal: join(ROBOTO, "Roboto", "Roboto-Regular.ttf"),
      bold: join(ROBOTO, "Roboto", "Roboto-Medium.ttf"),
      italics: join(ROBOTO, "Roboto", "Roboto-Italic.ttf"),
      bolditalics: join(ROBOTO, "Roboto", "Roboto-MediumItalic.ttf"),
    },
    Courier: {
      normal: "Courier",
      bold: "Courier-Bold",
      italics: "Courier-Oblique",
      bolditalics: "Courier-BoldOblique",
    },
  };
  if (cjkDir) {
    const regular = join(cjkDir, "NotoSansCJK-Regular.ttc");
    const bold = join(cjkDir, "NotoSansCJK-Bold.ttc");
    for (const [family, tag] of [
      ["CJK_SC", "sc"],
      ["CJK_JP", "jp"],
      ["CJK_KR", "kr"],
    ] as const) {
      // pdfkit can't slant or thicken a font, so italics use the upright faces.
      const r: [string, string] = [regular, `NotoSansCJK${tag}-Regular`];
      const b: [string, string] = [bold, `NotoSansCJK${tag}-Bold`];
      fonts[family] = { normal: r, bold: b, italics: r, bolditalics: b };
    }
  }
  return fonts;
}

function findCjkDir(dir: string | undefined) {
  const d = dir || DEFAULT_CJK_FONT_DIR;
  return existsSync(join(d, "NotoSansCJK-Regular.ttc")) &&
    existsSync(join(d, "NotoSansCJK-Bold.ttc"))
    ? d
    : null;
}

// ------------------------------------------------------------------ PDF

const PAGE = {
  a4: { pdf: "A4", width: 595.28, docx: { width: 11906, height: 16838 } },
  letter: { pdf: "LETTER", width: 612, docx: { width: 12240, height: 15840 } },
} as const;
const MARGIN = 56;
const HEADING_SIZES = [22, 18, 15, 13, 12, 11];

type PdfNode = Record<string, unknown> | string;

async function makePdf(input: MakeDocument): Promise<Uint8Array> {
  const page = PAGE[input.pageSize ?? "a4"];
  const width = page.width - MARGIN * 2;
  const doc = parse(input.markdown);
  const hasCjk = CJK.test(input.markdown);
  const cjkDir = hasCjk ? findCjkDir(input.cjkFontDir) : null;
  if (hasCjk && !cjkDir)
    throw new FileOpError(
      "This server has no Chinese, Japanese or Korean fonts, so it can't make this PDF. A Word file works, or the computer's tools.",
    );
  const han = hanFamily(input.markdown);
  const pictures = await preparePictures(input.images);

  const texts = (runs: Run[]): PdfNode[] =>
    runs.flatMap((r) => {
      const base: Record<string, unknown> = {
        ...(r.bold ? { bold: true } : {}),
        ...(r.italic ? { italics: true } : {}),
        ...(r.strike ? { decoration: "lineThrough" } : {}),
        ...(r.link ? { link: r.link, color: "#1a4fb5", decoration: "underline" } : {}),
        // Courier has Latin-1 only; other code text stays in the body font.
        ...(r.code && /^[\x20-\xff\n]*$/.test(r.text) ? { font: "Courier" } : {}),
        ...(r.code ? { background: "#f1f1f1" } : {}),
      };
      if (!hasCjk) return [{ ...base, text: r.text }];
      return r.text
        .split(CJK_RUNS)
        .filter(Boolean)
        .map((part) =>
          CJK.test(part)
            ? { ...base, font: HANGUL.test(part) && !KANA.test(part) ? "CJK_KR" : han, text: part }
            : { ...base, text: part },
        );
    });

  const node = (b: Block): PdfNode => {
    switch (b.kind) {
      case "heading":
        return {
          text: texts(b.runs),
          bold: true,
          fontSize: HEADING_SIZES[b.level - 1] ?? 11,
          margin: [0, b.level <= 2 ? 14 : 10, 0, 6],
        };
      case "para":
        return { text: texts(b.runs), margin: [0, 0, 0, 8] };
      case "list": {
        const items = b.items.map((item) =>
          item.length === 1 && item[0]?.kind === "para"
            ? { text: texts(item[0].runs) }
            : { stack: item.map(node) },
        );
        return b.ordered
          ? { ol: items, start: b.start, margin: [0, 0, 0, 8] }
          : { ul: items, margin: [0, 0, 0, 8] };
      }
      case "table":
        return {
          table: {
            headerRows: 1,
            widths: b.header.map(() => "*"),
            body: [
              b.header.map((c) => ({ text: texts(c), bold: true })),
              ...b.rows.map((r) => b.header.map((_, i) => ({ text: texts(r[i] ?? []) }))),
            ],
          },
          layout: {
            hLineWidth: () => 0.5,
            vLineWidth: () => 0.5,
            hLineColor: () => "#bbbbbb",
            vLineColor: () => "#bbbbbb",
            paddingTop: () => 3,
            paddingBottom: () => 3,
          },
          fontSize: 10,
          margin: [0, 0, 0, 10],
        };
      case "quote":
        return { stack: b.blocks.map(node), margin: [18, 0, 0, 8], color: "#444444" };
      case "code":
        return {
          table: {
            widths: ["*"],
            body: [
              [
                {
                  text: texts([{ text: b.text, code: true }]).map((t) =>
                    typeof t === "string" ? t : { ...t, background: undefined },
                  ),
                  fontSize: 9.5,
                  preserveLeadingSpaces: true,
                },
              ],
            ],
          },
          layout: {
            hLineWidth: () => 0,
            vLineWidth: () => 0,
            fillColor: () => "#f4f4f4",
            paddingLeft: () => 8,
            paddingRight: () => 8,
            paddingTop: () => 6,
            paddingBottom: () => 6,
          },
          margin: [0, 0, 0, 10],
        };
      case "rule":
        return {
          canvas: [
            { type: "line", x1: 0, y1: 0, x2: width, y2: 0, lineWidth: 0.5, lineColor: "#bbbbbb" },
          ],
          margin: [0, 6, 0, 12],
        };
      case "image": {
        const p = pictures.get(b.ref);
        if (!p) return { text: b.alt || b.ref, italics: true, margin: [0, 0, 0, 8] };
        return {
          image: `data:image/${p.type === "png" ? "png" : "jpeg"};base64,${p.bytes.toString("base64")}`,
          fit: [width, 560],
          margin: [0, 4, 0, 10],
        };
      }
    }
  };

  const fonts = pdfFonts(cjkDir);
  const allowed = new Set(
    Object.values(fonts).flatMap((f) => Object.values(f).map((v) => (Array.isArray(v) ? v[0] : v))),
  );
  const pdfmake = req("pdfmake") as {
    setFonts(f: unknown): void;
    setUrlAccessPolicy(cb: (url: string) => boolean): void;
    setLocalAccessPolicy(cb: (path: string) => boolean): void;
    createPdf(d: unknown): { getBuffer(): Promise<Buffer> };
  };
  pdfmake.setFonts(fonts);
  // Nothing is fetched, and only the fonts above are read from disk.
  pdfmake.setUrlAccessPolicy(() => false);
  pdfmake.setLocalAccessPolicy((path) => allowed.has(path));
  const definition = {
    pageSize: page.pdf,
    pageMargins: [MARGIN, MARGIN, MARGIN, MARGIN + 8],
    info: { title: input.title ?? "", creator: "Casama", producer: "Casama" },
    defaultStyle: { font: "Roboto", fontSize: 11, lineHeight: 1.25 },
    footer: (current: number, total: number) => ({
      text: `${current} / ${total}`,
      alignment: "center",
      fontSize: 9,
      color: "#777777",
      margin: [0, 20, 0, 0],
    }),
    content: doc.length ? doc.map(node) : [{ text: "" }],
  };
  try {
    return new Uint8Array(await pdfmake.createPdf(definition).getBuffer());
  } catch (err) {
    throw new FileOpError(`The PDF couldn't be made: ${(err as Error).message}`);
  }
}

// ------------------------------------------------------------------ Word

async function makeDocx(input: MakeDocument): Promise<Uint8Array> {
  const page = PAGE[input.pageSize ?? "a4"];
  const doc = parse(input.markdown);
  const pictures = await preparePictures(input.images);
  // 1-inch margins; pictures fit the text width at 96 pixels per inch.
  const maxPx = Math.round(((page.docx.width - 2 * 1440) / 1440) * 96);
  let lists = 0;

  const runs = (rs: Run[]): docx.ParagraphChild[] =>
    rs.flatMap((r): docx.ParagraphChild[] => {
      const pieces = r.text.split("\n");
      const make = (text: string, i: number) =>
        new docx.TextRun({
          text,
          ...(i > 0 ? { break: 1 } : {}),
          ...(r.bold ? { bold: true } : {}),
          ...(r.italic ? { italics: true } : {}),
          ...(r.strike ? { strike: true } : {}),
          ...(r.code
            ? {
                font: "Consolas",
                shading: { type: docx.ShadingType.CLEAR, fill: "F1F1F1", color: "auto" },
              }
            : {}),
          ...(r.link ? { style: "Hyperlink" } : {}),
        });
      const made = pieces.map(make);
      return r.link ? [new docx.ExternalHyperlink({ link: r.link, children: made })] : made;
    });

  const HEADINGS = [
    docx.HeadingLevel.HEADING_1,
    docx.HeadingLevel.HEADING_2,
    docx.HeadingLevel.HEADING_3,
    docx.HeadingLevel.HEADING_4,
    docx.HeadingLevel.HEADING_5,
    docx.HeadingLevel.HEADING_6,
  ];

  const out = (b: Block, depth = 0, quote = false): Array<docx.Paragraph | docx.Table> => {
    const indent = quote
      ? {
          indent: { left: 567 },
          border: { left: { style: docx.BorderStyle.SINGLE, size: 12, color: "BBBBBB", space: 8 } },
        }
      : {};
    switch (b.kind) {
      case "heading":
        return [new docx.Paragraph({ heading: HEADINGS[b.level - 1], children: runs(b.runs) })];
      case "para":
        return [new docx.Paragraph({ children: runs(b.runs), spacing: { after: 160 }, ...indent })];
      case "list": {
        const instance = ++lists;
        return b.items.flatMap((item) =>
          item.flatMap((child, k) => {
            if (child.kind !== "para" || k > 0) return out(child, depth + 1, quote);
            return [
              new docx.Paragraph({
                children: runs(child.runs),
                ...(b.ordered
                  ? { numbering: { reference: "numbered", level: Math.min(depth, 8), instance } }
                  : { bullet: { level: Math.min(depth, 8) } }),
              }),
            ];
          }),
        );
      }
      case "table":
        return [
          new docx.Table({
            width: { size: 100, type: docx.WidthType.PERCENTAGE },
            rows: [
              new docx.TableRow({
                tableHeader: true,
                children: b.header.map(
                  (c) =>
                    new docx.TableCell({
                      children: [
                        new docx.Paragraph({
                          children: runs(c.map((r) => ({ ...r, bold: true }))),
                        }),
                      ],
                    }),
                ),
              }),
              ...b.rows.map(
                (r) =>
                  new docx.TableRow({
                    children: b.header.map(
                      (_, i) =>
                        new docx.TableCell({
                          children: [new docx.Paragraph({ children: runs(r[i] ?? []) })],
                        }),
                    ),
                  }),
              ),
            ],
          }),
          new docx.Paragraph({ children: [] }),
        ];
      case "quote":
        return b.blocks.flatMap((x) => out(x, depth, true));
      case "code":
        return b.text.split("\n").map(
          (line, i, all) =>
            new docx.Paragraph({
              children: [new docx.TextRun({ text: line, font: "Consolas", size: 19 })],
              shading: { type: docx.ShadingType.CLEAR, fill: "F4F4F4", color: "auto" },
              spacing: { after: i === all.length - 1 ? 160 : 0 },
            }),
        );
      case "rule":
        return [
          new docx.Paragraph({
            children: [],
            border: {
              bottom: { style: docx.BorderStyle.SINGLE, size: 6, color: "BBBBBB", space: 1 },
            },
          }),
        ];
      case "image": {
        const p = pictures.get(b.ref);
        if (!p)
          return [
            new docx.Paragraph({
              children: [new docx.TextRun({ text: b.alt || b.ref, italics: true })],
            }),
          ];
        const scale = Math.min(1, maxPx / p.width, (maxPx * 1.3) / p.height);
        return [
          new docx.Paragraph({
            children: [
              new docx.ImageRun({
                type: p.type,
                data: p.bytes,
                transformation: {
                  width: Math.round(p.width * scale),
                  height: Math.round(p.height * scale),
                },
                altText: { name: b.alt || "picture", description: b.alt || "", title: b.alt || "" },
              }),
            ],
            spacing: { after: 160 },
          }),
        ];
      }
    }
  };

  const children = doc.flatMap((b) => out(b));
  const file = new docx.Document({
    creator: "Casama",
    title: input.title ?? "",
    styles: { default: { document: { run: { font: "Calibri", size: 22 } } } },
    numbering: {
      config: [
        {
          reference: "numbered",
          levels: Array.from({ length: 9 }, (_, level) => ({
            level,
            format: docx.LevelFormat.DECIMAL,
            text: `%${level + 1}.`,
            alignment: docx.AlignmentType.START,
            style: { paragraph: { indent: { left: 720 * (level + 1), hanging: 360 } } },
          })),
        },
      ],
    },
    sections: [
      {
        properties: {
          page: {
            size: page.docx,
            margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 },
          },
        },
        footers: {
          default: new docx.Footer({
            children: [
              new docx.Paragraph({
                alignment: docx.AlignmentType.CENTER,
                children: [
                  new docx.TextRun({
                    children: [docx.PageNumber.CURRENT],
                    size: 18,
                    color: "777777",
                  }),
                ],
              }),
            ],
          }),
        },
        children: children.length ? children : [new docx.Paragraph({ children: [] })],
      },
    ],
  });
  return new Uint8Array(await docx.Packer.toBuffer(file));
}

// ------------------------------------------------------------------ entry

export const DOC_TYPES = {
  pdf: { contentType: "application/pdf", ext: "pdf" },
  docx: {
    contentType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ext: "docx",
  },
} as const;

/** Makes the file; refuses one over the page or size limit. */
export async function makeDocument(input: MakeDocument) {
  if (!input.markdown.trim()) throw new FileOpError("There's nothing to put in the document.");
  const bytes = input.format === "pdf" ? await makePdf(input) : await makeDocx(input);
  if (bytes.length > MAX_DOC_BYTES)
    throw new FileOpError("That document came out over 10 MB. Use fewer or smaller pictures.");
  let pages: number | null = null;
  if (input.format === "pdf") {
    pages = (await PdfLibDocument.load(bytes)).getPageCount();
    if (pages > MAX_DOC_PAGES)
      throw new FileOpError(`That came out at ${pages} pages; the limit is ${MAX_DOC_PAGES}.`);
  }
  return { bytes, pages, ...DOC_TYPES[input.format] };
}
