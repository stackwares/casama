/**
 * File work that needs no computer (D-351): crop and convert pictures, read documents, combine and
 * cut PDFs, make and read QR codes. A bot on the person's Mac with no shared folders, or with no
 * computer at all, could only remake a picture when asked to crop it; these run on the server, on
 * files kept in the chat (media: ids).
 */
import jsQRModule from "jsqr";
import { degrees, PDFDocument } from "pdf-lib";
import QRCode from "qrcode";
import sharp from "sharp";
import { parseDocument } from "./knowledge-parse.ts";

// jsqr is CommonJS with a default export: depending on the loader it's the function or holds it.
type JsQr = (data: Uint8ClampedArray, width: number, height: number) => { data: string } | null;
const jsQR = ((jsQRModule as unknown as { default?: JsQr }).default ??
  (jsQRModule as unknown as JsQr)) as JsQr;

/** Largest picture accepted, in pixels (about 50 megapixels), so one file can't eat the server. */
const MAX_PIXELS = 50_000_000;

export class FileOpError extends Error {}

export interface ImageEdit {
  /** A box in pixels of the original (after turning it upright). */
  crop?: { left: number; top: number; width: number; height: number };
  /** Cut to a shape, like "1:1", "16:9", "4:5" or "9:16", keeping as much as fits. */
  aspect?: string;
  /** Which part to keep when cutting to a shape: the middle, an edge, or what looks most interesting. */
  focus?: "center" | "top" | "bottom" | "left" | "right" | "auto";
  /** Fits inside this box, never larger than the original unless asked. */
  resize?: { width?: number; height?: number; enlarge?: boolean };
  /** Turns clockwise by this many degrees. */
  rotate?: number;
  flip?: "horizontal" | "vertical";
  format?: "png" | "jpeg" | "webp";
  /** 1–100, for JPEG and WebP. */
  quality?: number;
}

export interface ImageOut {
  bytes: Uint8Array;
  contentType: string;
  ext: string;
  width: number;
  height: number;
}

const FORMATS = {
  png: { contentType: "image/png", ext: "png" },
  jpeg: { contentType: "image/jpeg", ext: "jpg" },
  webp: { contentType: "image/webp", ext: "webp" },
} as const;

function formatOf(contentType: string): keyof typeof FORMATS {
  if (contentType.includes("png")) return "png";
  if (contentType.includes("webp")) return "webp";
  return "jpeg";
}

function parseAspect(s: string) {
  const m = /^\s*(\d+(?:\.\d+)?)\s*[:x/]\s*(\d+(?:\.\d+)?)\s*$/.exec(s);
  const w = Number(m?.[1]);
  const h = Number(m?.[2]);
  if (!m || !(w > 0) || !(h > 0)) throw new FileOpError(`"${s}" isn't a shape like 1:1 or 16:9.`);
  return w / h;
}

/** Applies the edits in a fixed order: upright, rotate, flip, crop, shape, resize, format. */
export async function editImage(
  input: Uint8Array,
  contentType: string,
  edit: ImageEdit,
): Promise<ImageOut> {
  const open = (b: Uint8Array | Buffer) => sharp(b, { limitInputPixels: MAX_PIXELS });
  let meta: sharp.Metadata;
  try {
    meta = await open(input).metadata();
  } catch {
    throw new FileOpError("That file isn't a picture this can open (PNG, JPEG, WebP, GIF, TIFF).");
  }
  // Upright first (phone photos carry their turn in EXIF), so boxes match what people see.
  let buf = await open(input).rotate().toBuffer();
  if (edit.rotate) {
    const turn = ((Math.round(edit.rotate) % 360) + 360) % 360;
    if (turn) buf = await open(buf).rotate(turn, { background: "#ffffff" }).toBuffer();
  }
  if (edit.flip === "horizontal") buf = await open(buf).flop().toBuffer();
  if (edit.flip === "vertical") buf = await open(buf).flip().toBuffer();
  let { width = 0, height = 0 } = await open(buf).metadata();
  if (edit.crop) {
    const c = edit.crop;
    const left = Math.max(0, Math.round(c.left));
    const top = Math.max(0, Math.round(c.top));
    const w = Math.min(Math.round(c.width), width - left);
    const h = Math.min(Math.round(c.height), height - top);
    if (w < 1 || h < 1)
      throw new FileOpError(`That box is outside the picture, which is ${width}×${height}.`);
    buf = await open(buf).extract({ left, top, width: w, height: h }).toBuffer();
    width = w;
    height = h;
  }
  if (edit.aspect) {
    const ratio = parseAspect(edit.aspect);
    const w = Math.min(width, Math.round(height * ratio));
    const h = Math.min(height, Math.round(width / ratio));
    const focus = edit.focus ?? "center";
    const position =
      focus === "auto" ? sharp.strategy.attention : focus === "center" ? "centre" : focus;
    buf = await open(buf).resize(w, h, { fit: "cover", position }).toBuffer();
    width = w;
    height = h;
  }
  if (edit.resize && (edit.resize.width || edit.resize.height)) {
    buf = await open(buf)
      .resize(edit.resize.width ?? null, edit.resize.height ?? null, {
        fit: "inside",
        withoutEnlargement: !edit.resize.enlarge,
      })
      .toBuffer();
  }
  const format =
    edit.format ??
    (meta.format === "png" || meta.format === "webp" ? meta.format : formatOf(contentType));
  const quality = edit.quality ? Math.min(100, Math.max(1, Math.round(edit.quality))) : undefined;
  // Metadata (location, camera) is left out: sharp drops it unless asked to keep it.
  const img = open(buf);
  const out =
    format === "png"
      ? img.png()
      : format === "webp"
        ? img.webp(quality ? { quality } : {})
        : img.flatten({ background: "#ffffff" }).jpeg({ quality: quality ?? 88, mozjpeg: true });
  const { data, info } = await out.toBuffer({ resolveWithObject: true });
  return {
    bytes: new Uint8Array(data),
    ...FORMATS[format],
    width: info.width,
    height: info.height,
  };
}

/** A picture's size and type, for telling the model what it's working with. */
export async function imageInfo(input: Uint8Array) {
  const m = await sharp(input, { limitInputPixels: MAX_PIXELS })
    .metadata()
    .catch(() => null);
  if (!m?.width || !m.height) return null;
  // Width and height as people see them (EXIF orientations 5–8 swap them).
  const swap = (m.orientation ?? 1) >= 5;
  return { width: swap ? m.height : m.width, height: swap ? m.width : m.height, format: m.format };
}

/** Largest piece of a document's text returned at once. */
export const READ_CHUNK = 40_000;

/** A document's text (PDF, Word, CSV, Markdown, HTML, text), a piece at a time. */
export async function readDocument(
  name: string,
  bytes: Uint8Array,
  contentType: string,
  offset = 0,
) {
  let doc: Awaited<ReturnType<typeof parseDocument>>;
  try {
    doc = await parseDocument(name, bytes, contentType);
  } catch (err) {
    throw new FileOpError((err as Error).message);
  }
  const full = doc.sections
    .map((s) => (s.location ? `[${s.location}]\n${s.text}` : s.text))
    .join("\n\n")
    .trim();
  const start = Math.max(0, Math.min(offset, full.length));
  const text = full.slice(start, start + READ_CHUNK);
  const next = start + text.length < full.length ? start + text.length : null;
  return { title: doc.title, text, total: full.length, next };
}

/** "1-3, 5, 8-" → zero-based page numbers, in the order given; null means every page. */
export function parsePages(spec: string | undefined, count: number): number[] {
  if (!spec?.trim() || spec.trim() === "all") return [...Array(count).keys()];
  const out: number[] = [];
  for (const part of spec.split(",")) {
    const p = part.trim();
    if (!p) continue;
    const m = /^(\d+)?\s*-\s*(\d+)?$/.exec(p);
    const one = /^\d+$/.test(p) ? Number(p) : null;
    const from = one ?? (m ? Number(m[1] ?? 1) : Number.NaN);
    const to = one ?? (m ? Number(m[2] ?? count) : Number.NaN);
    if (!Number.isInteger(from) || !Number.isInteger(to) || from < 1 || to < from)
      throw new FileOpError(`"${p}" isn't a page or range like 3 or 2-5.`);
    if (to > count) throw new FileOpError(`The PDF has ${count} pages; there's no page ${to}.`);
    for (let i = from; i <= to; i++) out.push(i - 1);
  }
  if (!out.length) throw new FileOpError("No pages were given.");
  return out;
}

async function loadPdf(bytes: Uint8Array) {
  try {
    return await PDFDocument.load(bytes, { ignoreEncryption: false });
  } catch (err) {
    const msg = (err as Error).message;
    throw new FileOpError(
      /encrypt/i.test(msg)
        ? "That PDF is password-protected, so it can't be changed."
        : "That file isn't a PDF this can open.",
    );
  }
}

export type PdfInput = { bytes: Uint8Array; contentType: string; name: string };

/** Joins PDFs and pictures, in order, into one PDF (pictures each get a page their size). */
export async function combinePdf(files: PdfInput[]) {
  const out = await PDFDocument.create();
  for (const f of files) {
    if (f.contentType.includes("pdf") || f.name.toLowerCase().endsWith(".pdf")) {
      const src = await loadPdf(f.bytes);
      for (const p of await out.copyPages(src, src.getPageIndices())) out.addPage(p);
      continue;
    }
    if (!f.contentType.startsWith("image/"))
      throw new FileOpError(`${f.name} isn't a PDF or a picture.`);
    // PNG stays PNG (sharp, transparent edges); everything else becomes JPEG, turned upright.
    const png = f.contentType.includes("png");
    const upright = await sharp(f.bytes, { limitInputPixels: MAX_PIXELS })
      .rotate()
      [png ? "png" : "jpeg"]()
      .toBuffer()
      .catch(() => {
        throw new FileOpError(`${f.name} isn't a picture this can open.`);
      });
    const img = await embed(out, upright, png);
    const page = out.addPage([img.width, img.height]);
    page.drawImage(img, { x: 0, y: 0, width: img.width, height: img.height });
  }
  if (!out.getPageCount()) throw new FileOpError("Nothing to put in the PDF.");
  return { bytes: await out.save(), pages: out.getPageCount() };
}

const embed = (doc: PDFDocument, bytes: Buffer, png: boolean) =>
  png ? doc.embedPng(bytes) : doc.embedJpg(bytes);

/** A new PDF with only these pages, in this order (pull out, reorder or drop pages). */
export async function pickPdfPages(bytes: Uint8Array, pages: string | undefined, drop?: string) {
  const src = await loadPdf(bytes);
  const count = src.getPageCount();
  let keep = parsePages(pages, count);
  if (drop) {
    const gone = new Set(parsePages(drop, count));
    keep = keep.filter((i) => !gone.has(i));
  }
  if (!keep.length) throw new FileOpError("That would leave no pages.");
  const out = await PDFDocument.create();
  for (const p of await out.copyPages(src, keep)) out.addPage(p);
  return { bytes: await out.save(), pages: keep.length, of: count };
}

/** Turns pages clockwise by 90, 180 or 270 degrees (every page unless some are named). */
export async function rotatePdf(bytes: Uint8Array, by: number, pages?: string) {
  const doc = await loadPdf(bytes);
  const turn = (((Math.round(by / 90) * 90) % 360) + 360) % 360;
  if (!turn) throw new FileOpError("Turn by 90, 180 or 270 degrees.");
  for (const i of parsePages(pages, doc.getPageCount())) {
    const p = doc.getPage(i);
    p.setRotation(degrees((p.getRotation().angle + turn) % 360));
  }
  return { bytes: await doc.save(), pages: doc.getPageCount() };
}

/** Splits into pieces of `every` pages (a 10-page PDF in 3s: 1-3, 4-6, 7-9, 10). */
export async function splitPdf(bytes: Uint8Array, every: number) {
  const src = await loadPdf(bytes);
  const count = src.getPageCount();
  const size = Math.max(1, Math.round(every));
  if (count / size > 50) throw new FileOpError("That would make more than 50 files.");
  const parts: Array<{ bytes: Uint8Array; from: number; to: number }> = [];
  for (let start = 0; start < count; start += size) {
    const idx = [...Array(Math.min(size, count - start)).keys()].map((k) => start + k);
    const out = await PDFDocument.create();
    for (const p of await out.copyPages(src, idx)) out.addPage(p);
    parts.push({ bytes: await out.save(), from: start + 1, to: start + idx.length });
  }
  return parts;
}

/** A QR code as a PNG: a link, text, Wi-Fi details (WIFI:T:WPA;S:name;P:pass;;) and so on. */
export async function makeQr(text: string, size = 512) {
  if (!text) throw new FileOpError("Nothing to put in the QR code.");
  const width = Math.min(2048, Math.max(128, Math.round(size)));
  const bytes = await QRCode.toBuffer(text, {
    type: "png",
    width,
    margin: 2,
    errorCorrectionLevel: "M",
  }).catch((err: Error) => {
    throw new FileOpError(
      /too big|amount of data/i.test(err.message)
        ? "That's too much text for one QR code."
        : err.message,
    );
  });
  return { bytes: new Uint8Array(bytes), width };
}

/** What a QR code in a picture says; null when there's none to read. */
export async function readQr(input: Uint8Array): Promise<string | null> {
  const tryAt = async (max: number) => {
    const { data, info } = await sharp(input, { limitInputPixels: MAX_PIXELS })
      .rotate()
      .resize(max, max, { fit: "inside", withoutEnlargement: true })
      .ensureAlpha()
      .raw()
      .toBuffer({ resolveWithObject: true });
    return (
      jsQR(
        new Uint8ClampedArray(data.buffer, data.byteOffset, data.length),
        info.width,
        info.height,
      )?.data ?? null
    );
  };
  try {
    // Small codes in big photos read better at full size; most read fine smaller and faster.
    return (await tryAt(1200)) ?? (await tryAt(3000));
  } catch {
    throw new FileOpError("That file isn't a picture this can open.");
  }
}
