/**
 * Casama gallery items (D-184): themes, color schemes, wallpapers and skills that anyone can
 * contribute. Pure checks. The checker script and the server both use these.
 */
import { createHash } from "node:crypto";
import { parseSkillMd, SkillFormatError } from "./skill-format.ts";

export const GALLERY_TYPES = ["theme", "scheme", "wallpaper", "skill"] as const;
export type GalleryType = (typeof GALLERY_TYPES)[number];

export const LOOK_LICENSES = ["CC0-1.0", "CC-BY-4.0"] as const;
export const SKILL_LICENSES = ["MIT", "Apache-2.0"] as const;

/** Fonts the app can draw without an extra download step failing the checker. */
export const GALLERY_FONTS = [
  "Libre Baskerville",
  "Lato",
  "Google Sans",
  "Noto Serif",
  "Fraunces",
  "Figtree",
  "Inter",
  "Plus Jakarta Sans",
  "DM Sans",
  "Manrope",
  "Nunito",
  "Outfit",
  "Poppins",
  "Lexend",
  "Work Sans",
  "Rubik",
  "Sora",
  "Urbanist",
  "Quicksand",
  "Onest",
  "Geist",
  "Atkinson Hyperlegible",
  "IBM Plex Sans",
  "Noto Sans",
  "Source Sans 3",
  "Open Sans",
  "Roboto",
  "Playfair Display",
  "Instrument Serif",
  "DM Serif Display",
  "Young Serif",
  "Lora",
  "Newsreader",
  "Source Serif 4",
  "Merriweather",
  "EB Garamond",
  "Crimson Pro",
  "Bricolage Grotesque",
  "Space Grotesk",
  "Fredoka",
  "Baloo 2",
] as const;

export const WALLPAPER_PATTERNS = [
  "none",
  "clouds",
  "doodles",
  "treats",
  "garden",
  "space",
  "pets",
  "sea",
  "tech",
] as const;

export const WALLPAPER_PALETTES = [
  "theme",
  "casama",
  "lavender",
  "cotton",
  "peach",
  "sunset",
  "mint",
  "ocean",
  "forest",
  "graphite",
] as const;

const HEX = /^#[0-9A-Fa-f]{6}$/;
const ID = /^[a-z0-9][a-z0-9-]{0,62}$/;
const TAG = /^[a-z0-9][a-z0-9-]{0,23}$/;

export interface GalleryAuthor {
  name: string;
  url?: string;
}

export interface GalleryMeta {
  name: string;
  author: GalleryAuthor;
  license: string;
  tags: string[];
  featured: boolean;
  retired: boolean;
  version: number;
  category?: string;
  /** A Lucide icon name for a skill's tile (`notebook-pen`). Unknown names fall back in the app. */
  icon?: string;
}

export interface SeedColors {
  seed: string;
  background: string;
  onBackground: string;
}

/** SHA-256 over sorted path + length + bytes. The index stores this; install checks it. */
export function galleryHash(files: { path: string; bytes: Uint8Array }[]): string {
  const hash = createHash("sha256");
  for (const f of [...files].sort((a, b) => (a.path < b.path ? -1 : a.path > b.path ? 1 : 0))) {
    hash.update(f.path);
    hash.update("\0");
    hash.update(String(f.bytes.byteLength));
    hash.update("\0");
    hash.update(f.bytes);
  }
  return hash.digest("hex");
}

function channel(c: number) {
  const s = c / 255;
  return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
}

function luminance(hex: string) {
  const n = Number.parseInt(hex.slice(1), 16);
  const r = channel((n >> 16) & 255);
  const g = channel((n >> 8) & 255);
  const b = channel(n & 255);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/** WCAG contrast. AA text is 4.5. */
export function contrastRatio(a: string, b: string): number {
  const l1 = luminance(a);
  const l2 = luminance(b);
  const [hi, lo] = l1 >= l2 ? [l1, l2] : [l2, l1];
  return (hi + 0.05) / (lo + 0.05);
}

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

export function parseGalleryMeta(
  raw: unknown,
  licenses: readonly string[],
): { meta?: GalleryMeta; errors: string[] } {
  const errors: string[] = [];
  if (!isRecord(raw)) return { errors: ["item.json must be an object"] };
  const name = typeof raw.name === "string" ? raw.name.trim() : "";
  if (name.length < 1 || name.length > 60) errors.push("name must be 1 to 60 characters");
  const author = isRecord(raw.author) ? raw.author : null;
  const authorName = author && typeof author.name === "string" ? author.name.trim() : "";
  if (authorName.length < 1 || authorName.length > 80) errors.push("author.name is required");
  let url: string | undefined;
  if (author && author.url != null) {
    if (typeof author.url !== "string" || !/^https:\/\/[^\s]+$/.test(author.url))
      errors.push("author.url must be an https link");
    else url = author.url;
  }
  const license = typeof raw.license === "string" ? raw.license : "";
  if (!licenses.includes(license)) errors.push(`license must be one of ${licenses.join(", ")}`);
  const tags = Array.isArray(raw.tags) ? raw.tags : [];
  if (tags.length > 8) errors.push("at most 8 tags");
  const cleanTags: string[] = [];
  for (const t of tags) {
    if (typeof t !== "string" || !TAG.test(t)) errors.push(`bad tag ${String(t)}`);
    else cleanTags.push(t);
  }
  const version = raw.version == null ? 1 : raw.version;
  if (typeof version !== "number" || !Number.isInteger(version) || version < 1)
    errors.push("version must be a positive integer");
  const category = raw.category == null ? undefined : raw.category;
  if (category != null && (typeof category !== "string" || category.length > 40))
    errors.push("category must be a short string");
  const icon = raw.icon == null ? undefined : raw.icon;
  if (icon != null && (typeof icon !== "string" || !/^[a-z0-9][a-z0-9-]{0,39}$/.test(icon)))
    errors.push("icon must be a Lucide icon name such as notebook-pen");
  if (errors.length) return { errors };
  return {
    errors,
    meta: {
      name,
      author: { name: authorName, ...(url ? { url } : {}) },
      license,
      tags: cleanTags,
      featured: raw.featured === true,
      retired: raw.retired === true,
      version: version as number,
      ...(typeof category === "string" ? { category } : {}),
      ...(typeof icon === "string" ? { icon } : {}),
    },
  };
}

function checkSeeds(label: string, raw: unknown, errors: string[]): SeedColors | undefined {
  if (!isRecord(raw)) {
    errors.push(`${label} must be an object with seed, background and onBackground`);
    return;
  }
  const seed = raw.seed;
  const background = raw.background;
  const onBackground = raw.onBackground;
  for (const [key, value] of [
    ["seed", seed],
    ["background", background],
    ["onBackground", onBackground],
  ] as const) {
    if (typeof value !== "string" || !HEX.test(value))
      errors.push(`${label}.${key} must be a #RRGGBB color`);
  }
  if (
    typeof background === "string" &&
    typeof onBackground === "string" &&
    HEX.test(background) &&
    HEX.test(onBackground) &&
    contrastRatio(background, onBackground) < 4.5
  )
    errors.push(`${label} text on background is below WCAG AA (4.5:1)`);
  if (
    typeof seed === "string" &&
    typeof background === "string" &&
    typeof onBackground === "string"
  )
    return { seed, background, onBackground };
  return;
}

export function checkSchemeDocument(raw: unknown): string[] {
  const errors: string[] = [];
  if (!isRecord(raw)) return ["scheme.json must be an object"];
  checkSeeds("light", raw.light, errors);
  checkSeeds("dark", raw.dark, errors);
  return errors;
}

function checkWallpaperFields(raw: unknown, errors: string[]) {
  if (!isRecord(raw)) {
    errors.push("wallpaper must be an object");
    return;
  }
  if (typeof raw.pattern !== "string" || !WALLPAPER_PATTERNS.includes(raw.pattern as never))
    errors.push(`wallpaper.pattern must be one of ${WALLPAPER_PATTERNS.join(", ")}`);
  if (typeof raw.palette !== "string" || !WALLPAPER_PALETTES.includes(raw.palette as never))
    errors.push(`wallpaper.palette must be one of ${WALLPAPER_PALETTES.join(", ")}`);
  if (typeof raw.intensity !== "number" || raw.intensity < 0 || raw.intensity > 1)
    errors.push("wallpaper.intensity must be between 0 and 1");
}

export function checkThemeDocument(raw: unknown): string[] {
  const errors: string[] = [];
  if (!isRecord(raw)) return ["theme.json must be an object"];
  if (raw.v !== 2) errors.push("theme.json v must be 2");
  if (typeof raw.scheme === "string") {
    if (!ID.test(raw.scheme)) errors.push("scheme id must be lowercase letters, digits and dashes");
  } else {
    if (!isRecord(raw.scheme)) errors.push("scheme must be an id or light and dark seeds");
    else {
      checkSeeds("scheme.light", raw.scheme.light, errors);
      checkSeeds("scheme.dark", raw.scheme.dark, errors);
    }
  }
  for (const key of ["headingFont", "bodyFont"] as const) {
    const font = raw[key];
    if (typeof font !== "string" || !GALLERY_FONTS.includes(font as never))
      errors.push(`${key} must be one of the app's fonts`);
  }
  checkWallpaperFields(raw.wallpaper, errors);
  return errors;
}

export function checkWallpaperDocument(
  raw: unknown,
  files: { path: string; bytes: number }[],
): string[] {
  const errors: string[] = [];
  if (!isRecord(raw)) return ["wallpaper.json must be an object"];
  if (raw.kind === "pattern") {
    checkWallpaperFields(raw, errors);
    return errors;
  }
  if (raw.kind === "image") {
    const file = raw.file;
    if (typeof file !== "string" || !/^[A-Za-z0-9._-]+\.(webp|jpe?g)$/.test(file)) {
      errors.push("image file must be a webp or jpeg in this folder");
      return errors;
    }
    const found = files.find((f) => f.path === file);
    if (!found) errors.push(`missing ${file}`);
    else if (found.bytes > 2 * 1024 * 1024) errors.push(`${file} is over 2 MB`);
    // A small copy for gallery cards, so a grid doesn't download every full-size image.
    const thumb = raw.thumb;
    if (thumb !== undefined) {
      if (typeof thumb !== "string" || !/^[A-Za-z0-9._-]+\.(webp|jpe?g)$/.test(thumb))
        errors.push("thumb must be a webp or jpeg in this folder");
      else {
        const small = files.find((f) => f.path === thumb);
        if (!small) errors.push(`missing ${thumb}`);
        else if (small.bytes > 200 * 1024) errors.push(`${thumb} is over 200 KB`);
      }
    }
    return errors;
  }
  errors.push('wallpaper kind must be "pattern" or "image"');
  return errors;
}

export function checkSkillDocument(id: string, skillMd: string): string[] {
  try {
    const parsed = parseSkillMd(skillMd);
    if (parsed.name !== id) return [`SKILL.md name is ${parsed.name}; the folder is ${id}`];
    return [];
  } catch (err) {
    return [err instanceof SkillFormatError ? err.message : "SKILL.md is not a skill"];
  }
}

export function checkGalleryId(id: string): string | undefined {
  return ID.test(id) ? undefined : "folder name must be lowercase letters, digits and dashes";
}
