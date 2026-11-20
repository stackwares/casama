/**
 * Bot pictures (docs/BOT-PICTURES-PLAN.md §6): turning an uploaded, chat or drawn picture into the
 * two sizes the apps show, without its metadata, and finding the two colours the bot is drawn in.
 * Pure image work, no database: the API and the bot's tool both use it.
 */
import { botImageAvatar, botNamePalette } from "@casama/domain";
import sharp from "sharp";

/** Largest upload the API takes (base64 makes the request about a third bigger). */
export const BOT_PICTURE_MAX_BYTES = 4 * 1024 * 1024;
/** Largest original kept for Re-crop. */
export const BOT_PICTURE_ORIGINAL_MAX_BYTES = 3 * 1024 * 1024;
/** Pictures bigger than this many pixels are refused before decoding (a 48 MP photo is fine). */
export const BOT_PICTURE_MAX_PIXELS = 60_000_000;

export type PictureType = "image/jpeg" | "image/png" | "image/webp" | "image/gif" | "image/heic";

/** The picture's real type from its first bytes, or null when it isn't one we read. */
export function sniffPictureType(b: Uint8Array): PictureType | null {
  const at = (i: number, s: string) => {
    for (let k = 0; k < s.length; k++) if (b[i + k] !== s.charCodeAt(k)) return false;
    return true;
  };
  if (b.length >= 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff) return "image/jpeg";
  if (b.length >= 8 && b[0] === 0x89 && at(1, "PNG\r\n\x1a\n")) return "image/png";
  if (b.length >= 12 && at(0, "RIFF") && at(8, "WEBP")) return "image/webp";
  if (b.length >= 6 && (at(0, "GIF87a") || at(0, "GIF89a"))) return "image/gif";
  if (
    b.length >= 12 &&
    at(4, "ftyp") &&
    /^(heic|heix|mif1|msf1|heim|heis)$/.test(String.fromCharCode(...b.slice(8, 12)))
  )
    return "image/heic";
  return null;
}

export class PictureError extends Error {
  readonly code: "picture_unreadable" | "picture_too_big";
  constructor(code: "picture_unreadable" | "picture_too_big", message: string) {
    super(message);
    this.code = code;
  }
}

export interface BotPictureFiles {
  /** 512 × 512 WebP. */
  large: Buffer;
  /** 128 × 128 WebP. */
  small: Buffer;
  /** The bot's two colours, `rrggbbrrggbb`. */
  colors: string;
}

const open = (bytes: Uint8Array) => {
  const type = sniffPictureType(bytes);
  if (!type)
    throw new PictureError("picture_unreadable", "That file isn't a picture Casama can read");
  if (bytes.length > BOT_PICTURE_MAX_BYTES)
    throw new PictureError("picture_too_big", "Pictures can be up to 4 MB");
  // The first frame only (GIFs stay still), turned the way the camera held it, in sRGB.
  return sharp(bytes, {
    limitInputPixels: BOT_PICTURE_MAX_PIXELS,
    failOn: "error",
    animated: false,
  })
    .rotate()
    .toColourspace("srgb");
};

/**
 * The two sizes the apps show. The app sends an already cropped square; anything else (a picture
 * from a chat, a drawn one) is cropped to a square around what's most interesting in it. Sharp
 * drops all metadata (EXIF, GPS, camera details) unless asked to keep it, and we never ask.
 */
export async function makeBotPicture(
  bytes: Uint8Array,
  opts: { botName: string } = { botName: "" },
): Promise<BotPictureFiles> {
  let square: Buffer;
  try {
    const img = open(bytes);
    const meta = await img.metadata();
    if (!meta.width || !meta.height) throw new Error("no size");
    square = await img
      .resize(512, 512, {
        fit: "cover",
        position: meta.width === meta.height ? "centre" : sharp.strategy.attention,
        withoutEnlargement: false,
      })
      .png()
      .toBuffer();
  } catch (e) {
    if (e instanceof PictureError) throw e;
    const big = e instanceof Error && /pixel limit/i.test(e.message);
    throw new PictureError(
      big ? "picture_too_big" : "picture_unreadable",
      big
        ? "That picture is too large. Try a smaller one"
        : "That picture can't be read. Try a JPEG or PNG",
    );
  }
  const [large, small, colors] = await Promise.all([
    sharp(square).webp({ quality: 86, alphaQuality: 90, effort: 4 }).toBuffer(),
    sharp(square).resize(128, 128).webp({ quality: 82, alphaQuality: 90, effort: 4 }).toBuffer(),
    pictureColors(square, opts.botName),
  ]);
  return { large, small, colors };
}

/**
 * The picture as picked, for Re-crop: at most 2,048 px on its long side and 3 MB, without
 * metadata, as JPEG (or PNG/WebP when it has see-through parts).
 */
export async function makeOriginal(
  bytes: Uint8Array,
): Promise<{ bytes: Buffer; type: "image/jpeg" | "image/png" | "image/webp" }> {
  const img = open(bytes).resize(2048, 2048, { fit: "inside", withoutEnlargement: true });
  const meta = await sharp(bytes, { limitInputPixels: BOT_PICTURE_MAX_PIXELS }).metadata();
  if (meta.hasAlpha) {
    for (const quality of [90, 80, 70]) {
      const out = await img.clone().webp({ quality, alphaQuality: 90 }).toBuffer();
      if (out.length <= BOT_PICTURE_ORIGINAL_MAX_BYTES) return { bytes: out, type: "image/webp" };
    }
  } else {
    for (const quality of [90, 82, 72, 60]) {
      const out = await img.clone().jpeg({ quality, mozjpeg: true }).toBuffer();
      if (out.length <= BOT_PICTURE_ORIGINAL_MAX_BYTES) return { bytes: out, type: "image/jpeg" };
    }
  }
  throw new PictureError("picture_too_big", "That picture is too large to keep for re-cropping");
}

/** A PNG of a stored WebP, for widgets that read PNG files (`?format=png`). */
export function pictureAsPng(webp: Uint8Array): Promise<Buffer> {
  return sharp(webp).png({ compressionLevel: 9 }).toBuffer();
}

// ---------------------------------------------------------------------------------------------
// Colours
// ---------------------------------------------------------------------------------------------

type Rgb = [number, number, number];

const hex = (c: Rgb) => c.map((v) => Math.round(v).toString(16).padStart(2, "0")).join("");

function toHsl([r, g, b]: Rgb): [number, number, number] {
  const [R, G, B] = [r / 255, g / 255, b / 255];
  const max = Math.max(R, G, B);
  const min = Math.min(R, G, B);
  const l = (max + min) / 2;
  if (max === min) return [0, 0, l];
  const d = max - min;
  const s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  const h =
    max === R ? (G - B) / d + (G < B ? 6 : 0) : max === G ? (B - R) / d + 2 : (R - G) / d + 4;
  return [h * 60, s, l];
}

function fromHsl([h, s, l]: [number, number, number]): Rgb {
  const c = (1 - Math.abs(2 * l - 1)) * s;
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  const m = l - c / 2;
  const [r, g, b] =
    h < 60
      ? [c, x, 0]
      : h < 120
        ? [x, c, 0]
        : h < 180
          ? [0, c, x]
          : h < 240
            ? [0, x, c]
            : h < 300
              ? [x, 0, c]
              : [c, 0, x];
  return [(r + m) * 255, (g + m) * 255, (b + m) * 255];
}

/** WCAG relative luminance. */
export function luminance([r, g, b]: Rgb): number {
  const ch = (v: number) => {
    const s = v / 255;
    return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
  };
  return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b);
}

/**
 * Moves a colour's lightness until it reads at 3:1 on both the app's light surface (white) and
 * its dark one (#1c1c1e), and keeps white initials legible on it: luminance between 0.14 and 0.30.
 */
export function readableOnBoth(c: Rgb): Rgb {
  const [h, s] = toHsl(c);
  let l = toHsl(c)[2];
  let out = c;
  for (let i = 0; i < 40; i++) {
    const y = luminance(out);
    if (y > 0.3) l -= 0.02;
    else if (y < 0.14) l += 0.02;
    else break;
    out = fromHsl([h, s, Math.min(1, Math.max(0, l))]);
  }
  return out;
}

/**
 * The bot's two colours from its picture: the most common colour, then the most vivid colour that
 * looks clearly different (or a darker shade of the first). See-through pixels don't count. A
 * picture that is nearly grey uses the gradient its name would give it instead.
 */
export async function pictureColors(png: Buffer, botName: string): Promise<string> {
  const { data, info } = await sharp(png)
    .resize(48, 48, { fit: "fill" })
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });
  const bins = new Map<number, { n: number; r: number; g: number; b: number }>();
  for (let i = 0; i < data.length; i += info.channels) {
    if (data[i + 3]! < 128) continue;
    const [r, g, b] = [data[i]!, data[i + 1]!, data[i + 2]!];
    const key = ((r >> 4) << 8) | ((g >> 4) << 4) | (b >> 4);
    const bin = bins.get(key) ?? { n: 0, r: 0, g: 0, b: 0 };
    bin.n++;
    bin.r += r;
    bin.g += g;
    bin.b += b;
    bins.set(key, bin);
  }
  const total = [...bins.values()].reduce((a, x) => a + x.n, 0);
  const clusters = [...bins.values()]
    .map((x) => ({ n: x.n, c: [x.r / x.n, x.g / x.n, x.b / x.n] as Rgb }))
    .map((x) => ({ ...x, hsl: toHsl(x.c) }))
    .sort((a, b) => b.n - a.n);
  const vivid = clusters.filter(
    (x) => x.hsl[1] > 0.22 && x.hsl[2] > 0.12 && x.hsl[2] < 0.9 && x.n >= total * 0.01,
  );
  if (!total || vivid.length === 0) {
    const [a, b] = botNamePalette(botName);
    return `${a.slice(1)}${b.slice(1)}`;
  }
  // The most common colourful colour leads; the second is the most vivid that differs in hue.
  const first = vivid[0]!;
  const hueGap = (a: number, b: number) => Math.min(Math.abs(a - b), 360 - Math.abs(a - b));
  const second =
    vivid
      .filter((x) => hueGap(x.hsl[0], first.hsl[0]) > 28)
      .sort((a, b) => b.hsl[1] * Math.sqrt(b.n) - a.hsl[1] * Math.sqrt(a.n))[0]?.c ??
    fromHsl([first.hsl[0], first.hsl[1], Math.max(0, first.hsl[2] - 0.14)]);
  return `${hex(readableOnBoth(first.c))}${hex(readableOnBoth(second))}`;
}

/** The value `bots.avatar_url` gets for a stored picture. */
export const pictureAvatar = (id: string, colors: string) =>
  botImageAvatar(id, [colors.slice(0, 6), colors.slice(6)]);
