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
// Apps (D-239): the entry is CC0; its logo stays the vendor's trademark.
const APP = ["CC0-1.0"];
const APP_CATEGORIES = ["developer", "productivity", "payments", "design", "sales", "data", "automation"];
const APP_AUTH = ["oauth", "api_key", "none"];
const APP_KEYS = ["description", "category", "color", "homepage", "url", "auth", "oauthClient", "scopes", "apiKey", "note", "capabilities"];
const RESERVED_HEADERS = new Set(["host", "cookie", "connection", "content-length", "content-type", "transfer-encoding", "accept", "mcp-session-id", "mcp-protocol-version"]);
const LOGO_MAX = 24 * 1024;
const FONTS = new Set([
  "Libre Baskerville", "Lato", "Google Sans", "Noto Serif", "Fraunces", "Figtree", "Inter",
  "Plus Jakarta Sans", "DM Sans", "Manrope", "Nunito", "Outfit", "Poppins", "Lexend", "Work Sans",
  "Rubik", "Sora", "Urbanist", "Quicksand", "Onest", "Geist", "Atkinson Hyperlegible", "IBM Plex Sans",
  "Noto Sans", "Source Sans 3", "Open Sans", "Roboto", "Playfair Display", "Instrument Serif",
  "DM Serif Display", "Young Serif", "Lora", "Newsreader", "Source Serif 4", "Merriweather",
  "EB Garamond", "Crimson Pro", "Bricolage Grotesque", "Space Grotesk", "Fredoka", "Baloo 2",
]);
const PATTERNS = new Set(["none", "clouds", "doodles", "treats", "garden", "space", "pets", "sea", "tech"]);
// Palettes every app version draws; a mesh names one of these as the fallback older apps show.
const FALLBACK_PALETTES = ["theme", "casama", "lavender", "cotton", "peach", "sunset", "mint", "ocean", "forest", "graphite"];
// The last five came with mesh gradients, so apps from before then skip items that name them.
const PALETTES = new Set([...FALLBACK_PALETTES, "northern", "twilight", "berry", "citrus", "reef"]);
// Mesh colors stay this light (light) or dark (night), so text on the app's headers reads.
const MESH_MIN_LIGHT = 0.55;
const MESH_MAX_DARK = 0.05;
const HEX = /^#[0-9A-Fa-f]{6}$/;
// Lucide's icons, so wallpapers can name them as `glyphs` (resolved into doodles in index.json).
const LUCIDE = JSON.parse(readFileSync(join(root, "assets/lucide/icon-nodes.json"), "utf8"));
const SCHEME_COLOR_KEYS = ["primary", "primaryContainer", "secondary", "secondaryContainer", "tertiary", "tertiaryContainer"];
const REQUIREMENTS = ["doodles", "mesh", "scheme-colors"];
// Each doodle tag's attributes: required, optional, and which are sizes (0 to 26) rather than positions (-2 to 26).
const DOODLE_TAGS = {
  path: { required: ["d"], optional: [], sizes: [] },
  circle: { required: ["cx", "cy", "r"], optional: [], sizes: ["r"] },
  ellipse: { required: ["cx", "cy", "rx", "ry"], optional: [], sizes: ["rx", "ry"] },
  rect: { required: ["x", "y", "width", "height"], optional: ["rx", "ry"], sizes: ["width", "height", "rx", "ry"] },
  line: { required: ["x1", "y1", "x2", "y2"], optional: [], sizes: [] },
  polyline: { required: ["points"], optional: [], sizes: [] },
  polygon: { required: ["points"], optional: [], sizes: [] },
};
const PATH_DATA = /^[MmLlHhVvCcSsQqTtAaZz0-9eE.,+\-\s]+$/;
const NUMBER = /^\s*[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?\s*$/;
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
function lum(hex) {
  const n = Number.parseInt(hex.slice(1), 16);
  const r = channel((n >> 16) & 255);
  const g = channel((n >> 8) & 255);
  const bl = channel(n & 255);
  return 0.2126 * r + 0.7152 * g + 0.0722 * bl;
}
function contrast(a, b) {
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

// A mesh: nine light and nine night #RRGGBB colors, row by row from the top left, and optionally
// nine [x, y] points as fractions of the window (corners on corners, edge points on their edge).
function meshFields(raw, errors) {
  if (!raw || typeof raw !== "object") return errors.push("mesh must be an object with light, dark and optional points");
  for (const key of ["light", "dark"]) {
    const colors = raw[key];
    if (!Array.isArray(colors) || colors.length !== 9) {
      errors.push(`mesh.${key} must be nine #RRGGBB colors`);
      continue;
    }
    colors.forEach((c, i) => {
      if (typeof c !== "string" || !HEX.test(c)) return errors.push(`mesh.${key}[${i}] must be a #RRGGBB color`);
      if (key === "light" && lum(c) < MESH_MIN_LIGHT) errors.push(`mesh.light[${i}] ${c} is too dark for text on top`);
      if (key === "dark" && lum(c) > MESH_MAX_DARK) errors.push(`mesh.dark[${i}] ${c} is too light for text on top`);
    });
  }
  if (raw.points === undefined) return;
  if (!Array.isArray(raw.points) || raw.points.length !== 9) return errors.push("mesh.points must be nine [x, y] pairs");
  raw.points.forEach((p, i) => {
    if (!Array.isArray(p) || p.length !== 2 || !p.every((v) => typeof v === "number" && v >= 0 && v <= 1))
      return errors.push(`mesh.points[${i}] must be [x, y] between 0 and 1`);
    const [x, y] = p;
    const col = i % 3;
    const row = Math.floor(i / 3);
    if ((col !== 1 && x !== col / 2) || (row !== 1 && y !== row / 2)) errors.push(`mesh.points[${i}] must stay on its corner or edge`);
    if ((col === 1 && (x < 0.2 || x > 0.8)) || (row === 1 && (y < 0.2 || y > 0.8)))
      errors.push(`mesh.points[${i}] must stay between 0.2 and 0.8 inside the window`);
  });
}

const isRecord = (v) => typeof v === "object" && v !== null && !Array.isArray(v);
const hasSchemeColors = (raw) => isRecord(raw) && (SCHEME_COLOR_KEYS.some((k) => raw[k] !== undefined) || raw.appBar !== undefined);

// A full scheme's exact colors on one side: all six or none, appBar optional, AA on background and containers.
function schemeColors(label, raw, errors) {
  if (!hasSchemeColors(raw)) return;
  if (SCHEME_COLOR_KEYS.filter((k) => raw[k] !== undefined).length !== SCHEME_COLOR_KEYS.length)
    return errors.push(`${label} must give all of ${SCHEME_COLOR_KEYS.join(", ")} or none`);
  let valid = true;
  for (const key of [...SCHEME_COLOR_KEYS, ...(raw.appBar !== undefined ? ["appBar"] : [])]) {
    if (typeof raw[key] !== "string" || !HEX.test(raw[key])) {
      errors.push(`${label}.${key} must be a #RRGGBB color`);
      valid = false;
    }
  }
  if (!valid || !HEX.test(raw.background ?? "") || !HEX.test(raw.onBackground ?? "")) return;
  for (const key of ["primary", "secondary", "tertiary"])
    if (contrast(raw[key], raw.background) < 4.5) errors.push(`${label}.${key} on background is below WCAG AA (4.5:1)`);
  for (const key of ["primaryContainer", "secondaryContainer", "tertiaryContainer"])
    if (contrast(raw.onBackground, raw[key]) < 4.5) errors.push(`${label} text on ${key} is below WCAG AA (4.5:1)`);
}

function numberOf(v) {
  if (typeof v === "number") return Number.isFinite(v) ? v : undefined;
  if (typeof v === "string" && NUMBER.test(v)) return Number(v);
  return undefined;
}

// A wallpaper's own doodles: 1 to 24, each 1 to 24 Lucide-style elements on a 24 × 24 grid.
function doodleFields(raw, errors) {
  if (!Array.isArray(raw) || raw.length < 1 || raw.length > 24) return errors.push("doodles must be 1 to 24 drawings");
  raw.forEach((doodle, i) => {
    const at = `doodles[${i}]`;
    if (!Array.isArray(doodle) || doodle.length < 1 || doodle.length > 24) return errors.push(`${at} must be 1 to 24 elements`);
    doodle.forEach((element, j) => {
      const where = `${at}[${j}]`;
      if (!Array.isArray(element) || element.length !== 2 || !isRecord(element[1])) return errors.push(`${where} must be [tag, attributes]`);
      const [tag, attrs] = element;
      const spec = typeof tag === "string" ? DOODLE_TAGS[tag] : undefined;
      if (!spec) return errors.push(`${where} tag must be one of ${Object.keys(DOODLE_TAGS).join(", ")}`);
      for (const key of Object.keys(attrs))
        if (!spec.required.includes(key) && !spec.optional.includes(key)) errors.push(`${where} ${tag} can't have ${key}`);
      for (const key of spec.required) if (attrs[key] === undefined) errors.push(`${where} ${tag} needs ${key}`);
      for (const key of [...spec.required, ...spec.optional]) {
        const value = attrs[key];
        if (value === undefined) continue;
        if (key === "d") {
          if (typeof value !== "string" || value.length > 1500 || !PATH_DATA.test(value))
            errors.push(`${where} d must be at most 1500 characters of path commands and numbers`);
          continue;
        }
        if (key === "points") {
          const numbers = typeof value === "string" && /^[0-9eE.,+\-\s]+$/.test(value) ? value.trim().split(/[\s,]+/).map(numberOf) : [];
          if (numbers.length < 2 || numbers.length % 2 !== 0 || numbers.some((n) => n === undefined || n < -2 || n > 26))
            errors.push(`${where} points must be an even count of numbers between -2 and 26`);
          continue;
        }
        const n = numberOf(value);
        const [lo, hi] = spec.sizes.includes(key) ? [0, 26] : [-2, 26];
        if (n === undefined || n < lo || n > hi) errors.push(`${where} ${key} must be a number between ${lo} and ${hi}`);
      }
    });
  });
}

function glyphFields(raw, errors) {
  if (!Array.isArray(raw) || raw.length < 1 || raw.length > 24) return errors.push("glyphs must be 1 to 24 Lucide icon names");
  raw.forEach((name, i) => {
    if (typeof name !== "string" || !/^[a-z0-9][a-z0-9-]*$/.test(name)) errors.push(`glyphs[${i}] must be a Lucide icon name`);
    else if (!Object.hasOwn(LUCIDE, name)) errors.push(`glyphs[${i}] ${name} isn't a Lucide icon`);
  });
}

// Lucide icons by name as doodles, without Lucide's `key` attributes.
const resolveGlyphs = (names) =>
  names.map((name) => (LUCIDE[name] ?? []).map(([tag, attrs]) => {
    const { key: _key, ...rest } = attrs;
    return [tag, rest];
  }));

// The document as index.json carries it: `glyphs` resolved into `doodles`.
function indexDocument(type, raw) {
  if (!isRecord(raw)) return raw;
  const withDoodles = (w) => (Array.isArray(w.glyphs) && w.doodles === undefined ? { ...w, doodles: resolveGlyphs(w.glyphs) } : w);
  if (type === "wallpaper") return withDoodles(raw);
  if (type === "theme" && isRecord(raw.wallpaper)) return { ...raw, wallpaper: withDoodles(raw.wallpaper) };
  return raw;
}

// What a look needs from the app, so newer apps hide items they can't draw.
function requiresOf(type, raw) {
  if (!isRecord(raw)) return [];
  const found = new Set();
  const wallpaper = (w) => {
    if (!isRecord(w)) return;
    if (w.mesh !== undefined) found.add("mesh");
    if (w.doodles !== undefined || w.glyphs !== undefined) found.add("doodles");
  };
  const scheme = (sc) => {
    if (isRecord(sc) && (hasSchemeColors(sc.light) || hasSchemeColors(sc.dark))) found.add("scheme-colors");
  };
  if (type === "wallpaper") wallpaper(raw);
  if (type === "scheme") scheme(raw);
  if (type === "theme") {
    wallpaper(raw.wallpaper);
    scheme(raw.scheme);
  }
  return REQUIREMENTS.filter((r) => found.has(r));
}

function wallpaperFields(raw, errors) {
  if (!raw || typeof raw !== "object") return errors.push("wallpaper must be an object");
  if (raw.glyphs !== undefined && raw.doodles !== undefined) errors.push("wallpaper has glyphs and doodles; give one");
  else if (raw.glyphs !== undefined) glyphFields(raw.glyphs, errors);
  else if (raw.doodles !== undefined) doodleFields(raw.doodles, errors);
  if (raw.mesh !== undefined) {
    meshFields(raw.mesh, errors);
    if (typeof raw.palette === "string" && !FALLBACK_PALETTES.includes(raw.palette))
      errors.push(`with a mesh, wallpaper.palette is the fallback and must be one of ${FALLBACK_PALETTES.join(", ")}`);
  }
  if (!PATTERNS.has(raw.pattern)) errors.push("wallpaper.pattern is not one the app draws");
  if (!PALETTES.has(raw.palette)) errors.push("wallpaper.palette is not one the app draws");
  if (typeof raw.intensity !== "number" || raw.intensity < 0 || raw.intensity > 1)
    errors.push("wallpaper.intensity must be between 0 and 1");
}

// ---------------------------------------------------------------- apps (D-239)
// Mirrors packages/domain/src/gallery-apps.ts: the server runs the same checks again.
const text = (v, max) => {
  if (typeof v !== "string") return undefined;
  const t = v.trim();
  return t.length >= 1 && t.length <= max ? t : undefined;
};

function publicHttpsUrl(raw) {
  if (typeof raw !== "string" || raw.length > 500) return undefined;
  let u;
  try {
    u = new URL(raw);
  } catch {
    return undefined;
  }
  if (u.protocol !== "https:" || u.username || u.password || u.port) return undefined;
  const host = u.hostname.toLowerCase();
  if (!host.includes(".") || host.startsWith("[") || /^[\d.]+$/.test(host)) return undefined;
  if (host === "localhost" || /\.(localhost|local|internal|lan|home|corp|test|invalid|example)$/.test(host)) return undefined;
  return raw;
}

function appDocument(raw, errors) {
  if (!isRecord(raw)) return errors.push("app.json must be an object"), undefined;
  const start = errors.length;
  for (const key of Object.keys(raw)) if (!APP_KEYS.includes(key)) errors.push(`app.json can't have ${key}`);
  const description = text(raw.description, 140);
  if (!description) errors.push("description must be 1 to 140 characters");
  const category = APP_CATEGORIES.find((c) => c === raw.category);
  if (!category) errors.push(`category must be one of ${APP_CATEGORIES.join(", ")}`);
  const color = typeof raw.color === "string" && /^[0-9A-Fa-f]{6}$/.test(raw.color) ? raw.color : undefined;
  if (!color) errors.push("color must be a hex color without # (for example 00C4CC)");
  const homepage = publicHttpsUrl(raw.homepage);
  if (!homepage) errors.push("homepage must be an https link on a public host");
  const url = publicHttpsUrl(raw.url);
  if (!url) errors.push("url must be the vendor's https MCP endpoint on a public host");
  const auth = [];
  if (!Array.isArray(raw.auth) || raw.auth.length < 1) errors.push("auth must list how it connects");
  else
    for (const m of raw.auth) {
      const found = APP_AUTH.find((a) => a === m);
      if (!found) errors.push(`auth can only use ${APP_AUTH.join(", ")}`);
      else if (auth.includes(found)) errors.push(`auth lists ${found} twice`);
      else auth.push(found);
    }
  if (auth.includes("none") && auth.length > 1) errors.push('auth "none" can\'t be combined');
  let oauthClient;
  if (auth.includes("oauth")) {
    if (raw.oauthClient === "dcr" || raw.oauthClient === "cimd") oauthClient = raw.oauthClient;
    else errors.push('with oauth, oauthClient must be "dcr" or "cimd"');
  } else if (raw.oauthClient !== undefined) errors.push("oauthClient is only for oauth");
  let scopes;
  if (raw.scopes !== undefined) {
    if (!auth.includes("oauth")) errors.push("scopes are only for oauth");
    else if (!Array.isArray(raw.scopes) || raw.scopes.length > 30 || !raw.scopes.every((s) => typeof s === "string" && /^[\x21-\x7E]{1,200}$/.test(s)))
      errors.push("scopes must be at most 30 scope names");
    else scopes = raw.scopes;
  }
  let apiKey;
  if (auth.includes("api_key")) {
    const k = isRecord(raw.apiKey) ? raw.apiKey : null;
    const label = k ? text(k.label, 40) : undefined;
    const keyUrl = k ? publicHttpsUrl(k.url) : undefined;
    const placeholder = k && k.placeholder !== undefined ? text(k.placeholder, 60) : undefined;
    const steps = k && Array.isArray(k.steps) && k.steps.length >= 1 && k.steps.length <= 6 ? k.steps.map((s) => text(s, 160)) : [];
    const header = k && k.header !== undefined ? k.header : undefined;
    if (!k) errors.push("with api_key, apiKey must say where to get one");
    else {
      for (const key of Object.keys(k)) if (!["label", "placeholder", "url", "steps", "header"].includes(key)) errors.push(`apiKey can't have ${key}`);
      if (!label) errors.push("apiKey.label must be 1 to 40 characters");
      if (!keyUrl) errors.push("apiKey.url must be an https link on a public host");
      if (k.placeholder !== undefined && !placeholder) errors.push("apiKey.placeholder must be 1 to 60 characters");
      if (!steps.length || steps.some((s) => !s)) errors.push("apiKey.steps must be 1 to 6 lines of at most 160 characters");
      if (header !== undefined && (typeof header !== "string" || !/^[A-Za-z0-9-]{1,40}$/.test(header) || RESERVED_HEADERS.has(header.toLowerCase())))
        errors.push("apiKey.header must be a header name such as X-Api-Key");
    }
    if (label && keyUrl && steps.length && steps.every(Boolean))
      apiKey = { label, url: keyUrl, steps, ...(placeholder ? { placeholder } : {}), ...(typeof header === "string" ? { header } : {}) };
  } else if (raw.apiKey !== undefined) errors.push("apiKey is only for api_key");
  const note = raw.note === undefined ? undefined : text(raw.note, 200);
  if (raw.note !== undefined && !note) errors.push("note must be 1 to 200 characters");
  const capabilities = Array.isArray(raw.capabilities) ? raw.capabilities.map((c) => text(c, 60)) : [];
  if (capabilities.length < 1 || capabilities.length > 6 || capabilities.some((c) => !c))
    errors.push("capabilities must be 1 to 6 short phrases of at most 60 characters");
  if (errors.length > start) return undefined;
  return {
    description, category, color: color.toUpperCase(), homepage, url, auth,
    ...(oauthClient ? { oauthClient } : {}),
    ...(scopes ? { scopes } : {}),
    ...(apiKey ? { apiKey } : {}),
    ...(note ? { note } : {}),
    capabilities,
  };
}

function appLogo(svg, bytes, errors) {
  if (bytes > LOGO_MAX) errors.push(`logo.svg is over ${LOGO_MAX / 1024} KB`);
  if (!/^\s*(<\?xml[^>]*\?>\s*)?<svg[\s>]/.test(svg) || !/<\/svg>\s*$/.test(svg)) errors.push("logo.svg must be one <svg> element");
  if (!/viewBox\s*=\s*"[\d.\s-]+"/.test(svg)) errors.push("logo.svg needs a viewBox");
  if (/<(script|style|foreignObject|image|use|a|iframe|object|embed)[\s>/]/i.test(svg)) errors.push("logo.svg can't have scripts, styles, links, images or <use>");
  if (/\son[a-z]+\s*=/i.test(svg)) errors.push("logo.svg can't have event handlers");
  if (/(xlink:)?href\s*=|url\s*\(|javascript:|data:/i.test(svg)) errors.push("logo.svg can't point at other files or URLs");
  if (/<!(DOCTYPE|ENTITY)/i.test(svg)) errors.push("logo.svg can't declare entities");
}

const errors = [];
const items = [];
for (const [dir, type] of [["themes", "theme"], ["schemes", "scheme"], ["wallpapers", "wallpaper"], ["skills", "skill"], ["apps", "app"]]) {
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
    const licenses = type === "skill" ? SKILL : type === "app" ? APP : LOOK;
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
    if (type === "app") {
      for (const f of files)
        if (!["item.json", "app.json", "logo.svg"].includes(f.relative)) errors.push(`${where}: ${f.relative} isn't allowed (only item.json, app.json, logo.svg)`);
      const raw = readJson("app.json");
      if (raw) {
        const local = [];
        document = appDocument(raw, local);
        description = document?.description;
        for (const e of local) errors.push(`${where}: ${e}`);
      }
      const logo = files.find((f) => f.relative === "logo.svg");
      if (logo) {
        const local = [];
        appLogo(logo.bytes.toString("utf8"), logo.bytes.byteLength, local);
        for (const e of local) errors.push(`${where}: ${e}`);
      }
    } else if (type === "theme") {
      const doc = readJson("theme.json");
      document = doc ?? undefined;
      if (doc) {
        if (doc.v !== 2) errors.push(`${where}: theme.json v must be 2`);
        if (typeof doc.scheme === "string") {
          if (!ID.test(doc.scheme)) errors.push(`${where}: scheme id is not a gallery id`);
        } else {
          seeds(`${where} scheme.light`, doc.scheme?.light, errors);
          seeds(`${where} scheme.dark`, doc.scheme?.dark, errors);
          schemeColors(`${where} scheme.light`, doc.scheme?.light, errors);
          schemeColors(`${where} scheme.dark`, doc.scheme?.dark, errors);
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
        schemeColors(`${where} light`, doc.light, errors);
        schemeColors(`${where} dark`, doc.dark, errors);
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
      if (doc?.kind === "pattern" || doc?.kind === "mesh") {
        const local = [];
        if (doc.kind === "pattern" && doc.mesh !== undefined) local.push('a wallpaper with a mesh is kind "mesh"');
        if (doc.kind === "mesh" && doc.mesh === undefined) local.push("a mesh wallpaper needs a mesh");
        wallpaperFields(doc, local);
        for (const e of local) errors.push(`${where}: ${e}`);
      } else if (doc?.kind === "image") {
        image("file", 2 * 1024 * 1024);
        if (doc.thumb !== undefined) image("thumb", 200 * 1024);
      } else if (doc) errors.push(`${where}: wallpaper kind must be "pattern", "mesh" or "image"`);
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
      ...(document !== undefined && requiresOf(type, document).length ? { requires: requiresOf(type, document) } : {}),
      ...(document !== undefined ? { document: indexDocument(type, document) } : {}),
      files: files.map((f) => `${dir}/${id}/${f.relative}`).sort(),
    });
  }
}

if (errors.length) {
  for (const e of errors) console.error(e);
  process.exit(1);
}
items.sort((a, b) => (a.type === b.type ? a.id.localeCompare(b.id) : a.type.localeCompare(b.type)));
// Apps get their own file (D-239): servers and apps from before apps only read index.json, and
// their parsers know just the four look and skill types.
const outputs = [
  { file: "index.json", items: items.filter((i) => i.type !== "app") },
  { file: "apps.json", items: items.filter((i) => i.type === "app") },
];
let stale = false;
for (const out of outputs) {
  const body = `${JSON.stringify({ schema: 1, items: out.items }, null, 2)}\n`;
  const path = join(root, out.file);
  if (checkOnly) {
    let current = "";
    try {
      current = readFileSync(path, "utf8");
    } catch {
      // Missing counts as stale.
    }
    if (createHash("sha256").update(current).digest("hex") !== createHash("sha256").update(body).digest("hex")) {
      console.error(`${out.file} is stale. Run: node check.mjs`);
      stale = true;
    }
  } else {
    writeFileSync(path, body);
    console.log(`wrote ${out.file} (${out.items.length} items)`);
  }
}
if (stale) process.exit(1);
if (checkOnly) console.log(`gallery ok, ${items.length} items`);
