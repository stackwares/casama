/** File work without a computer (D-351): pictures, documents, PDFs and QR codes. */
import { PDFDocument } from "pdf-lib";
import sharp from "sharp";
import { describe, expect, it } from "vitest";
import {
  combinePdf,
  editImage,
  FileOpError,
  imageInfo,
  makeQr,
  parsePages,
  pickPdfPages,
  READ_CHUNK,
  readDocument,
  readQr,
  rotatePdf,
  splitPdf,
} from "../src/file-ops.ts";

const picture = async (width: number, height: number, format: "png" | "jpeg" = "png") =>
  new Uint8Array(
    await sharp({ create: { width, height, channels: 3, background: "#c33" } })
      [format]()
      .toBuffer(),
  );

const pdfOf = async (pages: number) => {
  const doc = await PDFDocument.create();
  for (let i = 0; i < pages; i++) doc.addPage([200 + i, 300]);
  return doc.save();
};
const pageWidths = async (bytes: Uint8Array) =>
  (await PDFDocument.load(bytes)).getPages().map((p) => Math.round(p.getWidth()));

describe("pictures", () => {
  it("crops to a shape from the middle, keeping as much as fits", async () => {
    const out = await editImage(await picture(300, 200), "image/png", { aspect: "1:1" });
    expect([out.width, out.height, out.contentType]).toEqual([200, 200, "image/png"]);
    const wide = await editImage(await picture(300, 300), "image/png", { aspect: "16:9" });
    expect([wide.width, wide.height]).toEqual([300, 169]);
  });

  it("crops to a box, and says so when the box is outside the picture", async () => {
    const out = await editImage(await picture(300, 200), "image/png", {
      crop: { left: 50, top: 20, width: 100, height: 400 },
    });
    expect([out.width, out.height]).toEqual([100, 180]);
    await expect(
      editImage(await picture(300, 200), "image/png", {
        crop: { left: 400, top: 0, width: 10, height: 10 },
      }),
    ).rejects.toThrow(/outside the picture, which is 300×200/);
  });

  it("rotates, resizes without enlarging, and converts", async () => {
    const turned = await editImage(await picture(300, 200), "image/png", { rotate: 90 });
    expect([turned.width, turned.height]).toEqual([200, 300]);
    const small = await editImage(await picture(800, 400), "image/png", {
      resize: { width: 200 },
      format: "webp",
    });
    expect([small.width, small.height, small.contentType, small.ext]).toEqual([
      200,
      100,
      "image/webp",
      "webp",
    ]);
    const same = await editImage(await picture(100, 50), "image/png", { resize: { width: 400 } });
    expect(same.width).toBe(100);
  });

  it("keeps JPEG as JPEG and leaves out location and camera details", async () => {
    const withGps = new Uint8Array(
      await sharp(await picture(120, 80, "jpeg"))
        .withExif({ IFD0: { Make: "Phone" }, IFD3: { GPSLatitudeRef: "N" } })
        .jpeg()
        .toBuffer(),
    );
    expect((await sharp(withGps).metadata()).exif).toBeDefined();
    const out = await editImage(withGps, "image/jpeg", { aspect: "1:1" });
    expect(out.contentType).toBe("image/jpeg");
    expect((await sharp(out.bytes).metadata()).exif).toBeUndefined();
  });

  it("refuses files that aren't pictures, and bad shapes", async () => {
    await expect(editImage(new Uint8Array([1, 2, 3]), "image/png", {})).rejects.toBeInstanceOf(
      FileOpError,
    );
    await expect(
      editImage(await picture(10, 10), "image/png", { aspect: "square" }),
    ).rejects.toThrow(/isn't a shape/);
  });

  it("reports a picture's size", async () => {
    expect(await imageInfo(await picture(64, 32))).toMatchObject({ width: 64, height: 32 });
    expect(await imageInfo(new Uint8Array([0]))).toBeNull();
  });
});

describe("documents", () => {
  it("reads CSV and text, a piece at a time", async () => {
    const csv = new TextEncoder().encode("name,qty\nApples,3\nPears,5\n");
    const r = await readDocument("order.csv", csv, "text/csv");
    expect(r.text).toContain("Apples");
    expect(r.next).toBeNull();
    const long = new TextEncoder().encode("word ".repeat(12_000));
    const first = await readDocument("notes.txt", long, "text/plain");
    expect(first.text.length).toBe(READ_CHUNK);
    expect(first.next).toBe(READ_CHUNK);
    const rest = await readDocument("notes.txt", long, "text/plain", first.next ?? 0);
    expect(rest.next).toBeNull();
    expect(first.text.length + rest.text.length).toBe(first.total);
  });

  it("says plainly which types it reads", async () => {
    await expect(readDocument("song.mp3", new Uint8Array([1]), "audio/mpeg")).rejects.toThrow(
      /Unsupported file type/,
    );
  });
});

describe("PDFs", () => {
  it("reads page lists", () => {
    expect(parsePages("1-3, 5", 6)).toEqual([0, 1, 2, 4]);
    expect(parsePages("5-", 6)).toEqual([4, 5]);
    expect(parsePages(undefined, 3)).toEqual([0, 1, 2]);
    expect(() => parsePages("9", 6)).toThrow(/has 6 pages/);
    expect(() => parsePages("4-2", 6)).toThrow(/isn't a page/);
  });

  it("combines PDFs and pictures in order", async () => {
    const r = await combinePdf([
      { bytes: await pdfOf(2), contentType: "application/pdf", name: "a.pdf" },
      { bytes: await picture(640, 480, "jpeg"), contentType: "image/jpeg", name: "receipt.jpg" },
      { bytes: await picture(50, 70), contentType: "image/png", name: "stamp.png" },
    ]);
    expect(r.pages).toBe(4);
    expect(await pageWidths(r.bytes)).toEqual([200, 201, 640, 50]);
    await expect(
      combinePdf([{ bytes: new Uint8Array([1]), contentType: "audio/mpeg", name: "x.mp3" }]),
    ).rejects.toThrow(/isn't a PDF or a picture/);
  });

  it("keeps, reorders and drops pages", async () => {
    const src = await pdfOf(5);
    const picked = await pickPdfPages(src, "5, 1-2");
    expect(await pageWidths(picked.bytes)).toEqual([204, 200, 201]);
    const dropped = await pickPdfPages(src, undefined, "2-4");
    expect(await pageWidths(dropped.bytes)).toEqual([200, 204]);
    await expect(pickPdfPages(src, undefined, "1-5")).rejects.toThrow(/no pages/);
  });

  it("rotates pages and splits into pieces", async () => {
    const turned = await rotatePdf(await pdfOf(3), 90, "2");
    const doc = await PDFDocument.load(turned.bytes);
    expect(doc.getPages().map((p) => p.getRotation().angle)).toEqual([0, 90, 0]);
    const parts = await splitPdf(await pdfOf(5), 2);
    expect(parts.map((p) => [p.from, p.to])).toEqual([
      [1, 2],
      [3, 4],
      [5, 5],
    ]);
  });

  it("says when a file isn't a PDF", async () => {
    await expect(pickPdfPages(new Uint8Array([1, 2]), "1")).rejects.toThrow(/isn't a PDF/);
  });
});

describe("QR codes", () => {
  it("makes one that reads back, and finds none in a plain picture", async () => {
    const qr = await makeQr("https://casama.ai/open?x=1", 400);
    expect((await imageInfo(qr.bytes))?.width).toBe(400);
    expect(await readQr(qr.bytes)).toBe("https://casama.ai/open?x=1");
    expect(await readQr(await picture(200, 200))).toBeNull();
  });
});
