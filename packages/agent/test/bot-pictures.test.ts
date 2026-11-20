import { parseBotAvatar } from "@casama/domain";
import sharp from "sharp";
import { describe, expect, it } from "vitest";
import {
  luminance,
  makeBotPicture,
  makeOriginal,
  PictureError,
  pictureAsPng,
  pictureAvatar,
  readableOnBoth,
  sniffPictureType,
} from "../src/bot-pictures.ts";

const solid = (w: number, h: number, rgb: [number, number, number], alpha = 1) =>
  sharp({
    create: {
      width: w,
      height: h,
      channels: 4,
      background: { r: rgb[0], g: rgb[1], b: rgb[2], alpha },
    },
  });

describe("bot pictures", () => {
  it("knows pictures by their first bytes", async () => {
    expect(sniffPictureType(await solid(4, 4, [1, 2, 3]).png().toBuffer())).toBe("image/png");
    expect(sniffPictureType(await solid(4, 4, [1, 2, 3]).jpeg().toBuffer())).toBe("image/jpeg");
    expect(sniffPictureType(await solid(4, 4, [1, 2, 3]).webp().toBuffer())).toBe("image/webp");
    expect(sniffPictureType(await solid(4, 4, [1, 2, 3]).gif().toBuffer())).toBe("image/gif");
    expect(
      sniffPictureType(new TextEncoder().encode("<svg xmlns='http://www.w3.org/2000/svg'/>")),
    ).toBeNull();
  });

  it("makes a 512 and a 128 WebP and drops the camera's metadata", async () => {
    const photo = await solid(1200, 900, [40, 120, 220])
      .jpeg()
      .withExif({ IFD0: { Make: "Casama Test Camera", Copyright: "secret place" } })
      .toBuffer();
    expect(photo.includes(Buffer.from("Casama Test Camera"))).toBe(true);
    const out = await makeBotPicture(photo, { botName: "Ada" });
    const [large, small] = await Promise.all([
      sharp(out.large).metadata(),
      sharp(out.small).metadata(),
    ]);
    expect([large.format, large.width, large.height]).toEqual(["webp", 512, 512]);
    expect([small.format, small.width, small.height]).toEqual(["webp", 128, 128]);
    expect(large.exif).toBeUndefined();
    expect(out.large.includes(Buffer.from("Casama Test Camera"))).toBe(false);
    expect(out.small.length).toBeLessThan(65536);
  });

  it("keeps see-through parts, for logos", async () => {
    const logo = await sharp({
      create: { width: 300, height: 300, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } },
    })
      .composite([
        { input: await solid(100, 100, [230, 60, 60]).png().toBuffer(), top: 100, left: 100 },
      ])
      .png()
      .toBuffer();
    const out = await makeBotPicture(logo, { botName: "Logo" });
    const m = await sharp(out.large).metadata();
    expect(m.hasAlpha).toBe(true);
    const { data } = await sharp(out.large)
      .ensureAlpha()
      .raw()
      .toBuffer({ resolveWithObject: true });
    expect(data[3]).toBeLessThan(10); // the top-left corner stays see-through
  });

  it("refuses things that aren't pictures", async () => {
    await expect(makeBotPicture(new TextEncoder().encode("hello"))).rejects.toBeInstanceOf(
      PictureError,
    );
    const broken = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.alloc(200, 7)]);
    await expect(makeBotPicture(broken)).rejects.toMatchObject({ code: "picture_unreadable" });
  });

  it("takes the colours from the picture, readable on light and dark", async () => {
    const two = await sharp({
      create: { width: 200, height: 200, channels: 3, background: { r: 255, g: 210, b: 40 } },
    })
      .composite([
        { input: await solid(200, 70, [30, 80, 230]).png().toBuffer(), top: 130, left: 0 },
      ])
      .png()
      .toBuffer();
    const out = await makeBotPicture(two, { botName: "Sunny" });
    expect(out.colors).toMatch(/^[0-9a-f]{12}$/);
    const rgb = (h: string) =>
      [0, 2, 4].map((i) => Number.parseInt(h.slice(i, i + 2), 16)) as [number, number, number];
    const [a, b] = [rgb(out.colors.slice(0, 6)), rgb(out.colors.slice(6))];
    // The yellow leads (it covers more of the picture), the blue comes second.
    expect(a[0]).toBeGreaterThan(a[2]);
    expect(b[2]).toBeGreaterThan(b[0]);
    for (const c of [a, b]) {
      expect(luminance(c)).toBeGreaterThanOrEqual(0.13);
      expect(luminance(c)).toBeLessThanOrEqual(0.31);
    }
  });

  it("uses the name's gradient for a grey picture", async () => {
    const grey = await solid(64, 64, [128, 128, 128]).png().toBuffer();
    const out = await makeBotPicture(grey, { botName: "Ada" });
    // botNamePalette("Ada"), the same gradient the app draws her initials on.
    const { botNamePalette } = await import("@casama/domain");
    const [x, y] = botNamePalette("Ada");
    expect(out.colors).toBe(`${x.slice(1)}${y.slice(1)}`);
  });

  it("nudges colours that are too light or too dark", () => {
    expect(luminance(readableOnBoth([250, 250, 120]))).toBeLessThanOrEqual(0.3);
    expect(luminance(readableOnBoth([10, 10, 60]))).toBeGreaterThanOrEqual(0.14);
  });

  it("keeps a shrunk original without metadata for Re-crop", async () => {
    const photo = await solid(3000, 2000, [200, 90, 90])
      .jpeg()
      .withExif({ IFD0: { Make: "Casama Test Camera" } })
      .toBuffer();
    const o = await makeOriginal(photo);
    const m = await sharp(o.bytes).metadata();
    expect(o.type).toBe("image/jpeg");
    expect(Math.max(m.width ?? 0, m.height ?? 0)).toBe(2048);
    expect(m.exif).toBeUndefined();
  });

  it("serves PNG copies for widgets and builds the stored value", async () => {
    const out = await makeBotPicture(await solid(64, 64, [20, 160, 120]).png().toBuffer());
    const png = await pictureAsPng(out.small);
    expect(sniffPictureType(png)).toBe("image/png");
    const v = pictureAvatar("6f1c2e9a-3b4d-4c5e-8f70-1a2b3c4d5e6f", out.colors);
    expect(parseBotAvatar(v).kind).toBe("image");
  });
});
