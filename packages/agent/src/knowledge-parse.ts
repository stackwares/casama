/**
 * Knowledge sources (D-125): turning documents into titled sections and chunks. Small parsers
 * with no extra libraries: Markdown and plain text by heading, HTML by heading (scripts and styles
 * dropped), CSV by rows with their header, DOCX from its document XML, and PDF through pdf.js
 * (Mozilla), with the old content-stream reader as a fallback. Scanned PDFs have no text to find.
 */
import { inflateSync } from "node:zlib";
import { unzipSync } from "fflate";

export interface Section {
  /** A heading or "page 3". */
  location: string | null;
  text: string;
}
export interface ParsedDoc {
  title: string;
  sections: Section[];
}

const decodeEntities = (s: string) =>
  s
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/&#(\d+);/g, (_, n) => String.fromCodePoint(Number(n)))
    .replace(/&#x([0-9a-f]+);/gi, (_, n) => String.fromCodePoint(Number.parseInt(n, 16)));

export function parseMarkdown(text: string, fallbackTitle: string): ParsedDoc {
  const sections: Section[] = [];
  let title = fallbackTitle;
  let heading: string | null = null;
  let buf: string[] = [];
  const flush = () => {
    const t = buf.join("\n").trim();
    if (t) sections.push({ location: heading, text: t });
    buf = [];
  };
  for (const line of text.split(/\r?\n/)) {
    const m = /^(#{1,6})\s+(.+?)\s*#*\s*$/.exec(line);
    if (m) {
      flush();
      heading = (m[2] as string).trim();
      if (m[1] === "#" && title === fallbackTitle) title = heading;
    } else buf.push(line);
  }
  flush();
  return { title, sections };
}

export function parseHtml(html: string, fallbackTitle: string): ParsedDoc {
  const title =
    decodeEntities(/<title[^>]*>([\s\S]*?)<\/title>/i.exec(html)?.[1]?.trim() ?? "") ||
    fallbackTitle;
  const body = html
    .replace(/<head[\s\S]*?<\/head>/gi, " ")
    .replace(/<(script|style|noscript|template|svg)[\s\S]*?<\/\1>/gi, " ")
    .replace(/<!--[\s\S]*?-->/g, " ")
    .replace(/<(nav|footer)[\s\S]*?<\/\1>/gi, " ");
  // Headings become Markdown headings; block ends become new lines.
  const md = body
    .replace(
      /<h([1-6])[^>]*>([\s\S]*?)<\/h\1>/gi,
      (_, n, t) => `\n${"#".repeat(Number(n))} ${t.replace(/<[^>]+>/g, "").trim()}\n`,
    )
    .replace(/<(br|\/p|\/div|\/li|\/tr|\/section|\/article)[^>]*>/gi, "\n")
    .replace(/<li[^>]*>/gi, "- ")
    .replace(/<[^>]+>/g, " ");
  const doc = parseMarkdown(
    decodeEntities(md)
      .replace(/[ \t]+/g, " ")
      .replace(/\n\s*\n+/g, "\n\n"),
    title,
  );
  return { title, sections: doc.sections };
}

/** CSV rows, quoted fields included. */
export function csvRows(text: string): string[][] {
  const rows: string[][] = [];
  let row: string[] = [];
  let field = "";
  let quoted = false;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (quoted) {
      if (ch === '"' && text[i + 1] === '"') {
        field += '"';
        i++;
      } else if (ch === '"') quoted = false;
      else field += ch;
    } else if (ch === '"') quoted = true;
    else if (ch === ",") {
      row.push(field);
      field = "";
    } else if (ch === "\n" || ch === "\r") {
      if (ch === "\r" && text[i + 1] === "\n") i++;
      row.push(field);
      if (row.some((f) => f !== "")) rows.push(row);
      row = [];
      field = "";
    } else field += ch;
  }
  row.push(field);
  if (row.some((f) => f !== "")) rows.push(row);
  return rows;
}

export function parseCsv(text: string, title: string): ParsedDoc {
  const [header, ...rows] = csvRows(text);
  if (!header) return { title, sections: [] };
  const sections: Section[] = [];
  for (let i = 0; i < rows.length; i += 20) {
    const part = rows
      .slice(i, i + 20)
      .map((r) => header.map((h, j) => `${h}: ${r[j] ?? ""}`).join("; "));
    sections.push({
      location: `rows ${i + 2}–${Math.min(i + 21, rows.length + 1)}`,
      text: part.join("\n"),
    });
  }
  return { title, sections };
}

export function parseDocx(bytes: Uint8Array, title: string): ParsedDoc {
  const files = unzipSync(bytes, { filter: (f) => f.name === "word/document.xml" });
  const xml = new TextDecoder().decode(files["word/document.xml"] ?? new Uint8Array());
  if (!xml) throw new Error("Not a Word document (no word/document.xml)");
  const lines: string[] = [];
  for (const p of xml.match(/<w:p[ >][\s\S]*?<\/w:p>/g) ?? []) {
    const text = decodeEntities(
      (p.match(/<w:t[^>]*>([\s\S]*?)<\/w:t>/g) ?? [])
        .map((t) => t.replace(/<[^>]+>/g, ""))
        .join(""),
    );
    const style = /<w:pStyle w:val="(Heading|Title)(\d?)"/i.exec(p);
    lines.push(style && text ? `${"#".repeat(Math.min(Number(style[2] || 1), 6))} ${text}` : text);
  }
  return parseMarkdown(lines.join("\n"), title);
}

/** A PDF literal string's bytes, with its escapes. */
function pdfString(s: string) {
  return s.replace(/\\([nrtbf()\\]|[0-7]{1,3})/g, (_, e: string) => {
    const map: Record<string, string> = {
      n: "\n",
      r: "\r",
      t: "\t",
      b: "\b",
      f: "\f",
      "(": "(",
      ")": ")",
      "\\": "\\",
    };
    return map[e] ?? String.fromCharCode(Number.parseInt(e, 8));
  });
}

/** Thrown for a PDF with no text layer, so the person learns why it found nothing (D-273). */
export const SCANNED_PDF =
  "This PDF has no text to read, probably because it's a scan. Upload a version with selectable text.";

/**
 * A PDF's text, page by page (D-273). pdf.js reads hex strings, font encodings and ToUnicode maps,
 * which most exported PDFs use and the old reader couldn't, so those files indexed as empty.
 */
export async function parsePdf(bytes: Uint8Array, title: string): Promise<ParsedDoc> {
  let doc: ParsedDoc | null = null;
  try {
    doc = await parsePdfText(bytes, title);
  } catch {
    doc = null;
  }
  if (!doc?.sections.length) doc = parsePdfStreams(bytes, title);
  if (!doc.sections.length) throw new Error(SCANNED_PDF);
  return doc;
}

async function parsePdfText(bytes: Uint8Array, title: string): Promise<ParsedDoc> {
  const { getDocument } = await import("pdfjs-dist/legacy/build/pdf.mjs");
  const task = getDocument({
    // pdf.js takes ownership of the buffer it's given.
    data: new Uint8Array(bytes),
    disableFontFace: true,
    useSystemFonts: false,
    verbosity: 0,
  });
  const pdf = await task.promise;
  try {
    const meta = await pdf.getMetadata().catch(() => null);
    const docTitle = String((meta?.info as { Title?: unknown } | undefined)?.Title ?? "").trim();
    const sections: Section[] = [];
    for (let n = 1; n <= Math.min(pdf.numPages, 2000); n++) {
      const page = await pdf.getPage(n);
      const content = await page.getTextContent();
      let text = "";
      for (const item of content.items as Array<{ str?: string; hasEOL?: boolean }>) {
        if (typeof item.str !== "string") continue;
        text += item.str + (item.hasEOL ? "\n" : "");
      }
      page.cleanup();
      const clean = text
        .replace(/[ \t]+/g, " ")
        .replace(/ *\n */g, "\n")
        .replace(/\n{3,}/g, "\n\n")
        .trim();
      if (clean) sections.push({ location: `page ${n}`, text: clean });
    }
    return { title: docTitle || title, sections };
  } finally {
    await task.destroy().catch(() => {});
  }
}

/** The old reader: literal strings in Flate or plain content streams (kept as a fallback). */
export function parsePdfStreams(bytes: Uint8Array, title: string): ParsedDoc {
  const raw = Buffer.from(bytes).toString("latin1");
  if (!raw.startsWith("%PDF")) throw new Error("Not a PDF");
  const pages: string[] = [];
  const re = /<<([\s\S]*?)>>\s*stream\r?\n([\s\S]*?)\r?\nendstream/g;
  for (let m = re.exec(raw); m; m = re.exec(raw)) {
    const dict = m[1] as string;
    let data = Buffer.from(m[2] as string, "latin1");
    if (/\/FlateDecode/.test(dict)) {
      try {
        data = inflateSync(data);
      } catch {
        continue;
      }
    } else if (/\/Filter/.test(dict)) continue;
    const content = data.toString("latin1");
    if (!/\b(Tj|TJ)\b/.test(content)) continue;
    const out: string[] = [];
    // Text show operators: (..) Tj, [(..) n (..)] TJ, and line moves as spaces or new lines.
    const tok =
      /\((?:\\.|[^\\)])*\)\s*Tj|\[((?:\((?:\\.|[^\\)])*\)|[^\]])*)\]\s*TJ|T\*|-?[\d.]+\s+-?[\d.]+\s+T[dD]|ET/g;
    for (let t = tok.exec(content); t; t = tok.exec(content)) {
      const s = t[0];
      if (s.endsWith("Tj")) out.push(pdfString(s.slice(1, s.lastIndexOf(")"))));
      else if (s.endsWith("TJ"))
        out.push(
          [...(t[1] ?? "").matchAll(/\((?:\\.|[^\\)])*\)|-?\d+(\.\d+)?/g)]
            .map(([x]) =>
              x.startsWith("(") ? pdfString(x.slice(1, -1)) : Number(x) < -200 ? " " : "",
            )
            .join(""),
        );
      else out.push("\n");
    }
    const text = out
      .join("")
      .replace(/[ \t]+/g, " ")
      .replace(/\n\s*\n+/g, "\n")
      .trim();
    if (text) pages.push(text);
  }
  return { title, sections: pages.map((text, i) => ({ location: `page ${i + 1}`, text })) };
}

/** Picks a parser by file name (or content type). */
export async function parseDocument(
  name: string,
  bytes: Uint8Array,
  contentType = "",
): Promise<ParsedDoc> {
  const ext = name.toLowerCase().split(".").pop() ?? "";
  const base = name.replace(/\.[^.]+$/, "");
  const text = () => new TextDecoder().decode(bytes);
  if (ext === "pdf" || contentType.includes("pdf")) return parsePdf(bytes, base);
  if (ext === "docx") return parseDocx(bytes, base);
  if (ext === "csv" || contentType.includes("csv")) return parseCsv(text(), base);
  if (ext === "html" || ext === "htm" || contentType.includes("html"))
    return parseHtml(text(), base);
  if (
    ["md", "markdown", "txt", "text", "mdx", "rst"].includes(ext) ||
    contentType.startsWith("text/")
  )
    return parseMarkdown(text(), base);
  throw new Error(`Unsupported file type: .${ext} (PDF, DOCX, Markdown, HTML, CSV or text)`);
}

/** Splits sections into chunks of about `size` characters, on paragraph and sentence ends. */
export function chunkSections(
  sections: Section[],
  size = 1500,
): Array<Section & { position: number }> {
  const out: Array<Section & { position: number }> = [];
  for (const s of sections) {
    const paras = s.text.split(/\n{2,}/);
    let cur = "";
    const push = () => {
      const t = cur.trim();
      if (t) out.push({ location: s.location, text: t.slice(0, 8000), position: out.length });
      cur = "";
    };
    for (const p of paras) {
      if (cur && cur.length + p.length > size) push();
      if (p.length > size) {
        for (const sentence of p.split(/(?<=[.!?])\s+/)) {
          if (cur && cur.length + sentence.length > size) push();
          cur += `${sentence} `;
        }
      } else cur += `${p}\n\n`;
    }
    push();
  }
  return out;
}
