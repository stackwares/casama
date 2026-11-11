/**
 * Checks this gallery and writes index.json. No app toolchain: pull requests run `node check.mjs`.
 *   node check.mjs          write index.json
 *   node check.mjs --check  fail if index.json is stale or an item is wrong
 */
import { createHash } from "node:crypto";
import { readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join, relative } from "node:path";

const root = process.argv[2] && !process.argv[2].startsWith("--") ? process.argv[2] : import.meta.dirname;
const checkOnly = process.argv.includes("--check");

const LOOK = ["CC0-1.0", "CC-BY-4.0"];
const SKILL = ["MIT", "Apache-2.0"];
const FONTS = new Set([
  "Libre Baskerville", "Lato", "Google Sans", "Noto Serif", "Fraunces", "Figtree", "Inter",
  "Plus Jakarta Sans", "DM Sans", "Manrope", "Nunito", "Outfit", "Poppins", "Lexend", "Work Sans",
  "Rubik", "Sora", "Urbanist", "Quicksand", "Onest", "Geist", "Atkinson Hyperlegible", "IBM Plex Sans",
  "Noto Sans", "Source Sans 3", "Open Sans", "Roboto", "Playfair Display", "Instrument Serif",
  "DM Serif Display", "Young Serif", "Lora", "Newsreader", "Source Serif 4", "Merriweather",
  "EB Garamond", "Crimson Pro", "Bricolage Grotesque", "Space Grotesk", "Fredoka", "Baloo 2",
]);
const PATTERNS = new Set(["none", "clouds", "doodles", "treats", "garden", "space", "pets", "sea", "tech"]);
const PALETTES = new Set(["theme", "casama", "lavender", "cotton", "peach", "sunset", "mint", "ocean", "forest", "graphite"]);
const HEX = /^#[0-9A-Fa-f]{6}$/;
const ID = /^[a-z0-9][a-z0-9-]{0,62}$/;
const TAG = /^[a-z0-9][a-z0-9-]{0,23}$/;

function hash(files) {
  const h = createHash("sha256");
  for (const f of [...files].sort((a, b) => (a.path < b.path ? -1 : a.path > b.path ? 1 : 0))) {
    h.update(f.path);
    h.update("\0");
    h.update(String(f.bytes.byteLength));
    h.update("\0");
    h.update(f.bytes);
  }
  return h.digest("hex");
}

function channel(c) {
  const s = c / 255;
  return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
}
function contrast(a, b) {
  const lum = (hex) => {
    const n = Number.parseInt(hex.slice(1), 16);
    const r = channel((n >> 16) & 255);
    const g = channel((n >> 8) & 255);
    const bl = channel(n & 255);
    return 0.2126 * r + 0.7152 * g + 0.0722 * bl;
  };
  const [hi, lo] = [lum(a), lum(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
}

function walk(dir) {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    return statSync(path).isDirectory() ? walk(path) : [path];
  });
}

function seeds(label, raw, errors) {
  if (!raw || typeof raw !== "object") {
    errors.push(`${label} must be an object with seed, background and onBackground`);
    return;
  }
  for (const key of ["seed", "background", "onBackground"]) {
    if (typeof raw[key] !== "string" || !HEX.test(raw[key])) errors.push(`${label}.${key} must be a #RRGGBB color`);
  }
  if (HEX.test(raw.background ?? "") && HEX.test(raw.onBackground ?? "") && contrast(raw.background, raw.onBackground) < 4.5)
    errors.push(`${label} text on background is below WCAG AA (4.5:1)`);
}

function wallpaperFields(raw, errors) {
  if (!raw || typeof raw !== "object") return errors.push("wallpaper must be an object");
  if (!PATTERNS.has(raw.pattern)) errors.push("wallpaper.pattern is not one the app draws");
  if (!PALETTES.has(raw.palette)) errors.push("wallpaper.palette is not one the app draws");
  if (typeof raw.intensity !== "number" || raw.intensity < 0 || raw.intensity > 1)
    errors.push("wallpaper.intensity must be between 0 and 1");
}

const errors = [];
const items = [];
for (const [dir, type] of [["themes", "theme"], ["schemes", "scheme"], ["wallpapers", "wallpaper"], ["skills", "skill"]]) {
  const parent = join(root, dir);
  let ids = [];
  try {
    ids = readdirSync(parent).filter((name) => statSync(join(parent, name)).isDirectory());
  } catch {
    errors.push(`missing ${dir}/`);
    continue;
  }
  for (const id of ids) {
    const where = `${dir}/${id}`;
    if (!ID.test(id)) errors.push(`${where}: folder name must be lowercase letters, digits and dashes`);
    const folder = join(parent, id);
    const files = walk(folder).map((path) => ({
      path,
      relative: relative(folder, path).split("\\").join("/"),
      bytes: readFileSync(path),
    }));
    const metaFile = files.find((f) => f.relative === "item.json");
    if (!metaFile) {
      errors.push(`${where}: missing item.json`);
      continue;
    }
    let meta;
    try {
      meta = JSON.parse(metaFile.bytes.toString("utf8"));
    } catch {
      errors.push(`${where}: item.json is not JSON`);
      continue;
    }
    const licenses = type === "skill" ? SKILL : LOOK;
    const name = typeof meta.name === "string" ? meta.name.trim() : "";
    if (name.length < 1 || name.length > 60) errors.push(`${where}: name must be 1 to 60 characters`);
    const authorName = meta.author && typeof meta.author.name === "string" ? meta.author.name.trim() : "";
    if (authorName.length < 1 || authorName.length > 80) errors.push(`${where}: author.name is required`);
    let url;
    if (meta.author && meta.author.url != null) {
      if (typeof meta.author.url !== "string" || !/^https:\/\/\S+$/.test(meta.author.url))
        errors.push(`${where}: author.url must be an https link`);
      else url = meta.author.url;
    }
    if (!licenses.includes(meta.license)) errors.push(`${where}: license must be one of ${licenses.join(", ")}`);
    const tags = Array.isArray(meta.tags) ? meta.tags : [];
    if (tags.length > 8) errors.push(`${where}: at most 8 tags`);
    for (const t of tags) if (typeof t !== "string" || !TAG.test(t)) errors.push(`${where}: bad tag ${t}`);
    if (type === "skill" && (typeof meta.category !== "string" || meta.category.length > 40))
      errors.push(`${where}: a skill needs a category`);
    if (meta.icon != null && (typeof meta.icon !== "string" || !/^[a-z0-9][a-z0-9-]{0,39}$/.test(meta.icon)))
      errors.push(`${where}: icon must be a Lucide icon name such as notebook-pen`);
    // What a gallery card needs to draw its preview, so a list needs no request per item.
    let document;
    let description;

    const readJson = (file) => {
      const found = files.find((f) => f.relative === file);
      if (!found) {
        errors.push(`${where}: missing ${file}`);
        return null;
      }
      try {
        return JSON.parse(found.bytes.toString("utf8"));
      } catch {
        errors.push(`${where}: ${file} is not JSON`);
        return null;
      }
    };
    if (type === "theme") {
      const doc = readJson("theme.json");
      document = doc ?? undefined;
      if (doc) {
        if (doc.v !== 2) errors.push(`${where}: theme.json v must be 2`);
        if (typeof doc.scheme === "string") {
          if (!ID.test(doc.scheme)) errors.push(`${where}: scheme id is not a gallery id`);
        } else {
          seeds(`${where} scheme.light`, doc.scheme?.light, errors);
          seeds(`${where} scheme.dark`, doc.scheme?.dark, errors);
        }
        for (const key of ["headingFont", "bodyFont"]) {
          if (!FONTS.has(doc[key])) errors.push(`${where}: ${key} must be one of the app's fonts`);
        }
        const local = [];
        wallpaperFields(doc.wallpaper, local);
        for (const e of local) errors.push(`${where}: ${e}`);
      }
    } else if (type === "scheme") {
      const doc = readJson("scheme.json");
      document = doc ?? undefined;
      if (doc) {
        seeds(`${where} light`, doc.light, errors);
        seeds(`${where} dark`, doc.dark, errors);
      }
    } else if (type === "wallpaper") {
      const doc = readJson("wallpaper.json");
      document = doc ?? undefined;
      const image = (key, limit) => {
        const file = doc[key];
        if (typeof file !== "string" || !/^[A-Za-z0-9._-]+\.(webp|jpe?g)$/.test(file))
          return errors.push(`${where}: ${key} must be a webp or jpeg in this folder`);
        const found = files.find((f) => f.relative === file);
        if (!found) errors.push(`${where}: missing ${file}`);
        else if (found.bytes.byteLength > limit) errors.push(`${where}: ${file} is over ${limit / 1024} KB`);
      };
      if (doc?.kind === "pattern") {
        const local = [];
        wallpaperFields(doc, local);
        for (const e of local) errors.push(`${where}: ${e}`);
      } else if (doc?.kind === "image") {
        image("file", 2 * 1024 * 1024);
        if (doc.thumb !== undefined) image("thumb", 200 * 1024);
      } else if (doc) errors.push(`${where}: wallpaper kind must be "pattern" or "image"`);
    } else {
      const skill = files.find((f) => f.relative === "SKILL.md");
      if (!skill) errors.push(`${where}: missing SKILL.md`);
      else {
        const text = skill.bytes.toString("utf8");
        const fm = /^---\n([\s\S]*?)\n---/.exec(text);
        const named = fm && /^name:\s*(\S+)\s*$/m.exec(fm[1]);
        if (!fm) errors.push(`${where}: SKILL.md must start with front matter`);
        else if (!named || named[1] !== id) errors.push(`${where}: SKILL.md name must be ${id}`);
        const said = fm && /^description:\s*(.+?)\s*$/m.exec(fm[1]);
        if (said) description = said[1].replace(/^(["'])(.*)\1$/, "$2");
      }
    }

    items.push({
      id,
      type,
      name,
      author: { name: authorName, ...(url ? { url } : {}) },
      license: meta.license,
      tags,
      featured: meta.featured === true,
      retired: meta.retired === true,
      version: Number.isInteger(meta.version) ? meta.version : 1,
      sha256: hash(files.map((f) => ({ path: f.relative, bytes: f.bytes }))),
      size: files.reduce((n, f) => n + f.bytes.byteLength, 0),
      ...(typeof meta.category === "string" ? { category: meta.category } : {}),
      ...(typeof meta.icon === "string" ? { icon: meta.icon } : {}),
      ...(description ? { description } : {}),
      ...(document !== undefined ? { document } : {}),
      files: files.map((f) => `${dir}/${id}/${f.relative}`).sort(),
    });
  }
}

if (errors.length) {
  for (const e of errors) console.error(e);
  process.exit(1);
}
items.sort((a, b) => (a.type === b.type ? a.id.localeCompare(b.id) : a.type.localeCompare(b.type)));
const body = `${JSON.stringify({ schema: 1, items }, null, 2)}\n`;
const indexPath = join(root, "index.json");
if (checkOnly) {
  const current = readFileSync(indexPath, "utf8");
  if (createHash("sha256").update(current).digest("hex") !== createHash("sha256").update(body).digest("hex")) {
    console.error("index.json is stale. Run: node check.mjs");
    process.exit(1);
  }
  console.log(`gallery ok, ${items.length} items`);
} else {
  writeFileSync(indexPath, body);
  console.log(`wrote index.json (${items.length} items)`);
}
