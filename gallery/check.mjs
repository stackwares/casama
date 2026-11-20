/**
 * Checks this gallery and writes index.json, the other kinds' files, authors.json and manifest.json.
 * No app toolchain: pull requests run `node check.mjs`.
 *   node check.mjs          write the derived files
 *   node check.mjs --check  fail if a derived file is stale or an item is wrong
 * manifest.sig is written by `node sign.mjs` in CI, never here.
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
// Starter bots, routine ideas and reviewed plugins (D-241).
const WRITING = ["MIT", "Apache-2.0", "CC0-1.0", "CC-BY-4.0"];
const TEMPLATE_CATEGORIES = ["work", "research", "build", "create", "life"];
const MASCOTS = ["cool", "focused", "giggly", "lovey", "shy", "sleepy", "starry", "thinker", "winky", "wow"];
const BOT_AUTONOMY = ["ask_always", "ask_risky"];
const DOCUMENTS = { bot: "bot.json", routine: "routine.json", plugin: "plugin.json" };
const INDEX_TYPES = ["theme", "scheme", "wallpaper", "skill"];
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

/** A gallery image wallpaper's document (`wallpapers/<id>/wallpaper.json`), or null when there is none. */
function imageWallpaper(id) {
  if (typeof id !== "string" || !ID.test(id)) return null;
  try {
    const doc = JSON.parse(readFileSync(join(root, "wallpapers", id, "wallpaper.json"), "utf8"));
    return isRecord(doc) && doc.kind === "image" && typeof doc.file === "string" ? doc : null;
  } catch {
    return null;
  }
}

/**
 * A theme's wallpaper can name a gallery image wallpaper: `"image": "<wallpaper id>"`. The index
 * carries it resolved, as the image wallpaper's own fields with paths that start at the theme's
 * folder (`../<id>/<file>`), because apps build an image address as `wallpapers/<item id>/<file>`.
 * That way apps from before this field draw the picture too. `pattern` and `palette` stay as the
 * fallback for anything that can't show a picture. `dark` and `darkThumb`, the painting's night
 * version, come along the same way (D-388).
 */
function withImage(w) {
  const doc = imageWallpaper(w.image);
  if (!doc) return w;
  const at = (key) => (typeof doc[key] === "string" ? { [key]: `../${w.image}/${doc[key]}` } : {});
  return { ...w, kind: "image", ...at("file"), ...at("thumb"), ...at("dark"), ...at("darkThumb") };
}

// The document as index.json carries it: `glyphs` resolved into `doodles`, a theme's `image` into a file.
function indexDocument(type, raw) {
  if (!isRecord(raw)) return raw;
  const withDoodles = (w) => (Array.isArray(w.glyphs) && w.doodles === undefined ? { ...w, doodles: resolveGlyphs(w.glyphs) } : w);
  if (type === "wallpaper") return withDoodles(raw);
  if (type === "theme" && isRecord(raw.wallpaper)) return { ...raw, wallpaper: withImage(withDoodles(raw.wallpaper)) };
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
  if (raw.image !== undefined && !imageWallpaper(raw.image))
    errors.push("wallpaper.image must be the id of an image wallpaper in the gallery");
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

// A painted cover (cover.webp) for sets, bots, routines, skills and plugins: presentation only, so it
// stays out of the item's files, sha256 and size and adding one never shows as an update.
const COVER_TYPES = ["set", "bot", "routine", "skill", "plugin"];
const COVER_FILE = "cover.webp";
const COVER_MAX = 80 * 1024;
const COVER_MIN_PX = 256;
const COVER_MAX_PX = 1024;

// Width and height from a WebP's first chunk (VP8 lossy, VP8L lossless or VP8X extended), or null.
function webpSize(b) {
  if (b.length < 30 || b.toString("latin1", 0, 4) !== "RIFF" || b.toString("latin1", 8, 12) !== "WEBP") return null;
  const chunk = b.toString("latin1", 12, 16);
  if (chunk === "VP8 ") {
    if (b[23] !== 0x9d || b[24] !== 0x01 || b[25] !== 0x2a) return null;
    return { width: b.readUInt16LE(26) & 0x3fff, height: b.readUInt16LE(28) & 0x3fff };
  }
  if (chunk === "VP8L") {
    if (b[20] !== 0x2f) return null;
    const bits = b.readUInt32LE(21);
    return { width: (bits & 0x3fff) + 1, height: ((bits >>> 14) & 0x3fff) + 1 };
  }
  if (chunk === "VP8X") return { width: b.readUIntLE(24, 3) + 1, height: b.readUIntLE(27, 3) + 1 };
  return null;
}

function coverImage(bytes, errors) {
  if (bytes.byteLength > COVER_MAX) errors.push(`${COVER_FILE} is over ${COVER_MAX / 1024} KB`);
  const size = webpSize(bytes);
  if (!size) return errors.push(`${COVER_FILE} isn't a WebP image`);
  if (size.width !== size.height) errors.push(`${COVER_FILE} must be square (it is ${size.width}x${size.height})`);
  else if (size.width < COVER_MIN_PX || size.width > COVER_MAX_PX) errors.push(`${COVER_FILE} must be ${COVER_MIN_PX} to ${COVER_MAX_PX} px (it is ${size.width})`);
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

// ---------------------------------------------------------------- bots, routines, plugins (D-241)
// Mirrors packages/domain/src/gallery-content.ts; the server runs the same checks again (with a
// full cron parser; this one checks the shape).
const ICON_NAME = /^[a-z0-9][a-z0-9-]{0,39}$/;
const CRON_FIELD = /^(\*|\d{1,2}(-\d{1,2})?)(\/\d{1,2})?(,(\*|\d{1,2}(-\d{1,2})?)(\/\d{1,2})?)*$/;
const cronOk = (v) => typeof v === "string" && v.trim().split(/\s+/).length === 5 && v.trim().split(/\s+/).every((f) => CRON_FIELD.test(f) || /^[A-Za-z]{3}(-[A-Za-z]{3})?$/.test(f));
const longText = (v, max, min) => {
  if (typeof v !== "string") return undefined;
  const t = v.trim();
  return t.length >= min && t.length <= max ? t : undefined;
};
const onlyKeys = (raw, allowed, label, errors) => {
  for (const key of Object.keys(raw)) if (!allowed.includes(key)) errors.push(`${label} can't have ${key}`);
};

function botDocument(raw, errors) {
  if (!isRecord(raw)) return errors.push("bot.json must be an object"), undefined;
  const start = errors.length;
  onlyKeys(raw, ["description", "category", "icon", "mascot", "persona", "starters", "autonomy", "skills", "routines"], "bot.json", errors);
  const description = text(raw.description, 300);
  if (!description) errors.push("description must be 1 to 300 characters");
  const category = TEMPLATE_CATEGORIES.find((c) => c === raw.category);
  if (!category) errors.push(`category must be one of ${TEMPLATE_CATEGORIES.join(", ")}`);
  const icon = typeof raw.icon === "string" && ICON_NAME.test(raw.icon) ? raw.icon : undefined;
  if (!icon) errors.push("icon must be a Lucide icon name such as notebook-pen");
  const mascot = MASCOTS.find((m) => m === raw.mascot);
  if (!mascot) errors.push(`mascot must be one of ${MASCOTS.join(", ")}`);
  const persona = longText(raw.persona, 20000, 20);
  if (!persona) errors.push("persona must be 20 to 20,000 characters of standing instructions");
  const starters = Array.isArray(raw.starters) ? raw.starters.map((x) => text(x, 160)) : [];
  if (!Array.isArray(raw.starters) || starters.length < 1 || starters.length > 6 || starters.some((x) => !x))
    errors.push("starters must be 1 to 6 first messages of at most 160 characters");
  const autonomy = BOT_AUTONOMY.find((a) => a === raw.autonomy);
  if (!autonomy) errors.push(`autonomy must be ${BOT_AUTONOMY.join(" or ")}`);
  const skills = [];
  if (raw.skills !== undefined) {
    if (!Array.isArray(raw.skills) || raw.skills.length > 10) errors.push("skills must be at most 10");
    else
      raw.skills.forEach((k, i) => {
        const at = `skills[${i}]`;
        if (!isRecord(k)) return errors.push(`${at} must be an object`);
        onlyKeys(k, ["name", "description", "body_md"], at, errors);
        const name = typeof k.name === "string" && /^[a-z0-9][a-z0-9_-]{0,62}$/.test(k.name) ? k.name : undefined;
        const desc = text(k.description, 300);
        const body = longText(k.body_md, 50000, 1);
        if (!name) errors.push(`${at}.name must be lowercase letters, digits, dashes or underscores`);
        if (!desc) errors.push(`${at}.description must be 1 to 300 characters`);
        if (!body) errors.push(`${at}.body_md must be 1 to 50,000 characters`);
        if (name && skills.some((x) => x.name === name)) errors.push(`${at}.name ${name} is used twice`);
        if (name && desc && body) skills.push({ name, description: desc, body_md: body });
      });
  }
  const routines = [];
  if (raw.routines !== undefined) {
    if (!Array.isArray(raw.routines) || raw.routines.length > 5) errors.push("routines must be at most 5");
    else
      raw.routines.forEach((r, i) => {
        const at = `routines[${i}]`;
        if (!isRecord(r)) return errors.push(`${at} must be an object`);
        onlyKeys(r, ["name", "instructions_md", "schedule_cron"], at, errors);
        const name = text(r.name, 120);
        const instructions = longText(r.instructions_md, 20000, 1);
        const cron = cronOk(r.schedule_cron) ? r.schedule_cron : undefined;
        if (!name) errors.push(`${at}.name must be 1 to 120 characters`);
        if (!instructions) errors.push(`${at}.instructions_md must be 1 to 20,000 characters`);
        if (!cron) errors.push(`${at}.schedule_cron must be a 5-field cron expression`);
        if (name && instructions && cron) routines.push({ name, instructions_md: instructions, schedule_cron: cron });
      });
  }
  if (errors.length > start) return undefined;
  return { description, category, icon, mascot, persona, starters, autonomy, skills, ...(routines.length ? { routines } : {}) };
}

function routineDocument(raw, errors) {
  if (!isRecord(raw)) return errors.push("routine.json must be an object"), undefined;
  const start = errors.length;
  onlyKeys(raw, ["description", "category", "icon", "instructions_md", "schedule_cron"], "routine.json", errors);
  const description = text(raw.description, 200);
  if (!description) errors.push("description must be 1 to 200 characters");
  const category = TEMPLATE_CATEGORIES.find((c) => c === raw.category);
  if (!category) errors.push(`category must be one of ${TEMPLATE_CATEGORIES.join(", ")}`);
  const icon = typeof raw.icon === "string" && ICON_NAME.test(raw.icon) ? raw.icon : undefined;
  if (!icon) errors.push("icon must be a Lucide icon name such as calendar-check");
  const instructions = longText(raw.instructions_md, 20000, 10);
  if (!instructions) errors.push("instructions_md must be 10 to 20,000 characters");
  const cron = cronOk(raw.schedule_cron) ? raw.schedule_cron : undefined;
  if (!cron) errors.push("schedule_cron must be a 5-field cron expression such as 0 9 * * 1-5");
  if (errors.length > start) return undefined;
  return { description, category, icon, instructions_md: instructions, schedule_cron: cron };
}

function pluginDocument(raw, errors) {
  if (!isRecord(raw)) return errors.push("plugin.json must be an object"), undefined;
  const start = errors.length;
  onlyKeys(raw, ["description", "url", "commit", "icon", "adds"], "plugin.json", errors);
  const description = text(raw.description, 300);
  if (!description) errors.push("description must be 1 to 300 characters");
  const url = typeof raw.url === "string" && /^https:\/\/github\.com\/[A-Za-z0-9_.-]{1,100}\/[A-Za-z0-9_.-]{1,100}(\/tree\/[^/\s]{1,200}(\/[^\s]{1,300})?)?\/?$/.test(raw.url) ? raw.url : undefined;
  if (!url) errors.push("url must be a github.com repository or folder link");
  const commit = typeof raw.commit === "string" && /^[0-9a-f]{40}$/.test(raw.commit) ? raw.commit : undefined;
  if (!commit) errors.push("commit must be the full 40-character commit that was reviewed");
  let icon;
  if (raw.icon !== undefined) {
    icon = typeof raw.icon === "string" && ICON_NAME.test(raw.icon) ? raw.icon : undefined;
    if (!icon) errors.push("icon must be a Lucide icon name such as puzzle");
  }
  const adds = Array.isArray(raw.adds) ? raw.adds.map((a) => text(a, 80)) : [];
  if (adds.length < 1 || adds.length > 6 || adds.some((a) => !a)) errors.push("adds must be 1 to 6 short phrases of at most 80 characters");
  if (errors.length > start) return undefined;
  return { description, url, commit, ...(icon ? { icon } : {}), adds };
}


// ---------------------------------------------------------------- gallery v2 (D-315)
// Mirrors packages/domain/src/gallery.ts (parseGalleryMeta) and gallery-catalog.ts.
const KINDS = ["theme", "scheme", "wallpaper", "skill", "app", "bot", "routine", "plugin", "set"];
const SET_ITEM_TYPES = ["app", "skill", "routine", "bot", "theme", "scheme", "wallpaper", "plugin"];
const CREDIT_LEVELS = ["none", "low", "medium", "high"];
const EXAMPLE_KINDS = ["skill", "app", "bot"];
const ACCESS_KINDS = ["skill", "app", "routine", "bot", "plugin"];
const NEEDS_KINDS = ["routine", "bot"];
const INPUT_KINDS = ["routine", "bot"];
const INPUT_TYPES = ["text", "choice", "time", "timezone"];
const TEMPLATE_FIELDS = { routine: ["instructions_md", "schedule_cron"], bot: ["persona", "starters"] };
// Built-in app ids (packages/domain/src/apps.ts APP_CATALOG), so `needs.apps` can name them.
// packages/domain/test/gallery-catalog.test.ts keeps this list in step.
const BUILT_IN_APPS = [
  "gmail", "google_calendar", "google_drive", "google_docs", "google_sheets", "google_contacts", "google_slides",
  "notion", "slack", "asana", "monday", "box", "atlassian", "exa", "airtable", "trustmrr", "zapier", "composio", "pipedream", "zoho", "zoho_mail", "zoho_crm", "zoho_desk", "zoho_books", "zoho_apps",
  "figma", "webflow", "hubspot", "intercom", "stripe", "revenuecat", "superwall", "adapty", "github", "linear", "sentry", "vercel", "supabase", "neon",
  "cloudflare", "context7", "posthog", "huggingface",
];
const MANIFEST_FILES = ["index.json", "apps.json", "bots.json", "routines.json", "plugins.json", "sets.json", "authors.json",
  // Content lists (D-372).
  "lists.json",
  "coding-agents.json",
  "prompts.json",
];
const DATE = /^(\d{4})-(\d{2})-(\d{2})$/;
const SEMVER = /^\d{1,4}\.\d{1,4}\.\d{1,4}$/;
const HANDLE = /^[a-z0-9][a-z0-9-]{0,38}$/;
const INPUT_KEY = /^[a-z][a-z0-9_]{0,31}$/;
const TIME = /^([01]\d|2[0-3]):[0-5]\d$/;
const TIMEZONE = /^(UTC|[A-Za-z]+(\/[A-Za-z0-9_+-]+){1,2})$/;
const DAYS_IN_MONTH = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
const PLACEHOLDER = /\{\{\s*([a-z][a-z0-9_]{0,31}(?:\.(?:hour|minute))?)\s*\}\}/g;

function isDate(v) {
  if (typeof v !== "string") return false;
  const m = DATE.exec(v);
  if (!m) return false;
  const [y, mo, d] = [Number(m[1]), Number(m[2]), Number(m[3])];
  const date = new Date(Date.UTC(y, mo - 1, d));
  return date.getUTCFullYear() === y && date.getUTCMonth() === mo - 1 && date.getUTCDate() === d;
}
function isMonthDay(v) {
  const m = typeof v === "string" ? /^(\d{2})-(\d{2})$/.exec(v) : null;
  if (!m) return false;
  const mo = Number(m[1]);
  const d = Number(m[2]);
  return mo >= 1 && mo <= 12 && d >= 1 && d <= DAYS_IN_MONTH[mo - 1];
}
const hasScripts = (paths) => paths.some((p) => /\.(py|sh|bash|zsh|js|mjs|cjs|ts|mts|rb|pl|ps1|php|go)$/i.test(p));

function shortList(raw, label, max, minItems, maxItems, errors) {
  if (!Array.isArray(raw) || raw.length < minItems || raw.length > maxItems || !raw.every((x) => typeof x === "string" && x.trim().length >= 1 && x.trim().length <= max)) {
    errors.push(`${label} must be ${minItems} to ${maxItems} lines of at most ${max} characters`);
    return undefined;
  }
  return raw.map((x) => x.trim());
}
function itemRef(raw, label, errors) {
  if (!isRecord(raw) || !KINDS.includes(raw.type) || typeof raw.id !== "string" || !ID.test(raw.id) || Object.keys(raw).some((k) => k !== "type" && k !== "id")) {
    errors.push(`${label} must be { "type": kind, "id": gallery id }`);
    return undefined;
  }
  return { type: raw.type, id: raw.id };
}
function inputValueError(type, value, options) {
  if (value.length < 1 || value.length > 120) return "must be 1 to 120 characters";
  if (type === "time" && !TIME.test(value)) return "must be a time such as 07:30";
  if (type === "timezone" && !TIMEZONE.test(value)) return "must be a time zone such as Europe/Berlin";
  if (type === "choice" && !(options ?? []).includes(value)) return "must be one of the options";
  if (/[{}]/.test(value)) return "can't contain { or }";
  return undefined;
}

function parseChangelog(raw, version, errors) {
  if (!Array.isArray(raw) || raw.length < 1 || raw.length > 50) return errors.push("changelog must be 1 to 50 entries, newest first"), undefined;
  const out = [];
  raw.forEach((e, i) => {
    const at = `changelog[${i}]`;
    if (!isRecord(e)) return errors.push(`${at} must be an object`);
    for (const k of Object.keys(e)) if (!["version", "date", "note", "breaking"].includes(k)) errors.push(`${at} can't have ${k}`);
    if (!Number.isInteger(e.version) || e.version < 1) errors.push(`${at}.version must be a positive integer`);
    if (!isDate(e.date)) errors.push(`${at}.date must be YYYY-MM-DD`);
    const note = typeof e.note === "string" ? e.note.trim() : "";
    if (note.length < 1 || note.length > 160) errors.push(`${at}.note must be 1 to 160 characters`);
    if (e.breaking !== undefined && typeof e.breaking !== "boolean") errors.push(`${at}.breaking must be true or false`);
    out.push({ version: e.version, date: e.date, note, ...(e.breaking === true ? { breaking: true } : {}) });
  });
  for (let i = 1; i < out.length; i++) {
    if (!(out[i].version < out[i - 1].version)) errors.push("changelog versions must go strictly down, newest first");
    if (out[i].date > out[i - 1].date) errors.push("changelog dates must not go up, newest first");
  }
  if (out[0] && out[0].version !== version) errors.push(`changelog's top entry must be version ${version}`);
  return out;
}
function parseAccess(raw, errors) {
  if (!isRecord(raw)) return errors.push("access must be an object"), undefined;
  for (const k of Object.keys(raw)) if (!["reads", "writes", "runs_code", "computer", "credits"].includes(k)) errors.push(`access can't have ${k}`);
  const out = {};
  for (const key of ["reads", "writes"]) {
    if (raw[key] === undefined) continue;
    const list = shortList(raw[key], `access.${key}`, 40, 1, 8, errors);
    if (list) out[key] = list;
  }
  for (const key of ["runs_code", "computer"]) {
    if (raw[key] === undefined) continue;
    if (typeof raw[key] !== "boolean") errors.push(`access.${key} must be true or false`);
    else out[key] = raw[key];
  }
  if (raw.credits !== undefined) {
    if (!CREDIT_LEVELS.includes(raw.credits)) errors.push(`access.credits must be one of ${CREDIT_LEVELS.join(", ")}`);
    else out.credits = raw.credits;
  }
  return out;
}
function parseNeeds(raw, errors) {
  if (!isRecord(raw)) return errors.push("needs must be an object"), undefined;
  const out = {};
  for (const k of Object.keys(raw)) if (k !== "apps" && k !== "skills") errors.push(`needs can't have ${k}`);
  for (const key of ["apps", "skills"]) {
    const list = raw[key];
    if (list === undefined) continue;
    if (!Array.isArray(list) || list.length < 1 || list.length > 10 || !list.every((x) => typeof x === "string" && /^[a-z0-9][a-z0-9_-]{0,62}$/.test(x)) || new Set(list).size !== list.length)
      errors.push(`needs.${key} must be 1 to 10 different ids`);
    else out[key] = list;
  }
  return out;
}
function parseInputs(raw, errors) {
  if (!Array.isArray(raw) || raw.length < 1 || raw.length > 6) return errors.push("inputs must be 1 to 6 questions"), undefined;
  const out = [];
  raw.forEach((q, i) => {
    const at = `inputs[${i}]`;
    if (!isRecord(q)) return errors.push(`${at} must be an object`);
    const start = errors.length;
    for (const k of Object.keys(q)) if (!["key", "label", "type", "default", "options", "help"].includes(k)) errors.push(`${at} can't have ${k}`);
    const key = typeof q.key === "string" && INPUT_KEY.test(q.key) ? q.key : undefined;
    if (!key) errors.push(`${at}.key must be lowercase letters, digits or _ (up to 32)`);
    else if (out.some((x) => x.key === key)) errors.push(`${at}.key ${key} is used twice`);
    const label = typeof q.label === "string" ? q.label.trim() : "";
    if (label.length < 1 || label.length > 60) errors.push(`${at}.label must be 1 to 60 characters`);
    const type = INPUT_TYPES.find((t) => t === q.type);
    if (!type) errors.push(`${at}.type must be one of ${INPUT_TYPES.join(", ")}`);
    let options;
    if (type === "choice") options = shortList(q.options, `${at}.options`, 60, 2, 8, errors);
    else if (q.options !== undefined) errors.push(`${at}.options are only for choice`);
    const help = q.help === undefined ? undefined : typeof q.help === "string" ? q.help.trim() : "";
    if (help !== undefined && (help.length < 1 || help.length > 120)) errors.push(`${at}.help must be 1 to 120 characters`);
    const def = typeof q.default === "string" ? q.default.trim() : undefined;
    if (def === undefined || def.length < 1 || def.length > 120) errors.push(`${at}.default must be 1 to 120 characters (what older servers use)`);
    else if (type) {
      const why = inputValueError(type, def, options);
      if (why) errors.push(`${at}.default ${why}`);
    }
    if (errors.length === start) out.push({ key, label, type, default: def, ...(options ? { options } : {}), ...(help ? { help } : {}) });
  });
  return out;
}

// The newer item.json fields; `kind` gates the kind-only ones.
function metaV2(meta, kind, errors) {
  const version = meta.version == null ? 1 : meta.version;
  const out = {};
  if (meta.author && meta.author.handle !== undefined) {
    if (typeof meta.author.handle !== "string" || !HANDLE.test(meta.author.handle)) errors.push("author.handle must be lowercase letters, digits and dashes (up to 39)");
    else out.handle = meta.author.handle;
  }
  if (meta.added === undefined) errors.push("added must be the YYYY-MM-DD it was added");
  else if (!isDate(meta.added)) errors.push("added must be a YYYY-MM-DD date");
  else out.added = meta.added;
  if (meta.changelog !== undefined && Number.isInteger(version)) out.changelog = parseChangelog(meta.changelog, version, errors);
  else if (Number.isInteger(version) && version > 1) errors.push("changelog is required once version is above 1");
  let updated;
  if (meta.updated !== undefined) {
    if (!isDate(meta.updated)) errors.push("updated must be a YYYY-MM-DD date");
    else updated = meta.updated;
  }
  updated = updated ?? out.changelog?.[0]?.date ?? out.added;
  if (updated && out.added && updated < out.added) errors.push("updated can't be before added");
  if (updated && out.changelog?.[0] && updated < out.changelog[0].date) errors.push("updated can't be before the latest changelog entry");
  if (updated) out.updated = updated;
  if (meta.pick !== undefined) {
    const pick = typeof meta.pick === "string" ? meta.pick.trim() : "";
    if (meta.featured !== true) errors.push("pick is only for featured items");
    if (pick.length < 1 || pick.length > 140) errors.push("pick must be 1 to 140 characters");
    out.pick = pick;
  }
  if (meta.examples !== undefined) {
    if (!EXAMPLE_KINDS.includes(kind)) errors.push(`examples aren't for a ${kind}`);
    out.examples = shortList(meta.examples, "examples", 160, 1, 3, errors);
  }
  if (meta.access !== undefined) {
    if (!ACCESS_KINDS.includes(kind)) errors.push(`access isn't for a ${kind}`);
    out.access = parseAccess(meta.access, errors);
  }
  if (meta.needs !== undefined) {
    if (!NEEDS_KINDS.includes(kind)) errors.push(`needs aren't for a ${kind}`);
    out.needs = parseNeeds(meta.needs, errors);
  }
  if (meta.inputs !== undefined) {
    if (!INPUT_KINDS.includes(kind)) errors.push(`inputs aren't for a ${kind}`);
    out.inputs = parseInputs(meta.inputs, errors);
  }
  if (meta.remix_of !== undefined) out.remix_of = itemRef(meta.remix_of, "remix_of", errors);
  if (meta.replaced_by !== undefined) out.replaced_by = itemRef(meta.replaced_by, "replaced_by", errors);
  for (const key of ["min_app", "min_server"]) {
    if (meta[key] === undefined) continue;
    if (typeof meta[key] !== "string" || !SEMVER.test(meta[key])) errors.push(`${key} must be a version such as 0.2.0`);
    else out[key] = meta[key];
  }
  if (meta.season !== undefined) {
    const s = meta.season;
    if (!isRecord(s) || !isMonthDay(s.from) || !isMonthDay(s.to) || s.from === s.to || Object.keys(s).some((k) => k !== "from" && k !== "to"))
      errors.push('season must be { "from": "MM-DD", "to": "MM-DD" }');
    else out.season = { from: s.from, to: s.to };
  }
  return out;
}

const placeholders = (text) => [...text.matchAll(PLACEHOLDER)].map((m) => m[1]);
function fillText(text, values) {
  return text.replace(PLACEHOLDER, (whole, name) => {
    const [key, part] = name.split(".");
    const value = values[key];
    if (value === undefined) return whole;
    if (!part) return value;
    const [hh, mm] = value.split(":");
    return String(Number(part === "hour" ? hh : mm));
  });
}
function templateTexts(kind, doc) {
  const out = [];
  for (const field of TEMPLATE_FIELDS[kind]) {
    const v = doc[field];
    if (typeof v === "string") out.push({ field, text: v });
    else if (Array.isArray(v)) for (const x of v) if (typeof x === "string") out.push({ field, text: x });
  }
  return out;
}
function inputsUsage(kind, inputs, raw) {
  if (!TEMPLATE_FIELDS[kind] || !isRecord(raw)) return [];
  const errors = [];
  const byKey = new Map((inputs ?? []).map((i) => [i.key, i]));
  const used = new Set();
  for (const { field, text } of templateTexts(kind, raw)) {
    for (const name of placeholders(text)) {
      const [key, part] = name.split(".");
      used.add(key);
      const input = byKey.get(key);
      if (!input) errors.push(`{{${name}}} in ${field} has no input`);
      else if (part && (key !== "time" || input.type !== "time")) errors.push(`{{${name}}} needs a time input named time`);
      else if (field === "schedule_cron" && !part) errors.push("schedule_cron can only use {{time.minute}} and {{time.hour}}");
    }
  }
  for (const key of byKey.keys()) if (!used.has(key)) errors.push(`input ${key} isn't used`);
  return errors;
}
function fillDocument(kind, raw, values) {
  if (!TEMPLATE_FIELDS[kind] || !isRecord(raw)) return raw;
  const out = { ...raw };
  for (const field of TEMPLATE_FIELDS[kind]) {
    const v = out[field];
    if (typeof v === "string") out[field] = fillText(v, values);
    else if (Array.isArray(v)) out[field] = v.map((x) => (typeof x === "string" ? fillText(x, values) : x));
  }
  return out;
}
function templateOf(kind, raw) {
  if (!TEMPLATE_FIELDS[kind] || !isRecord(raw)) return undefined;
  const out = {};
  for (const field of TEMPLATE_FIELDS[kind]) if (raw[field] !== undefined) out[field] = raw[field];
  return out;
}

function testsFile(raw, errors) {
  if (!isRecord(raw) || !Array.isArray(raw.cases)) return errors.push('tests.json must be { "cases": [{ "prompt", "expect" }] }');
  for (const k of Object.keys(raw)) if (k !== "cases") errors.push(`tests.json can't have ${k}`);
  if (raw.cases.length < 1 || raw.cases.length > 5) errors.push("tests.json needs 1 to 5 cases");
  raw.cases.forEach((c, i) => {
    const at = `tests.json cases[${i}]`;
    if (!isRecord(c)) return errors.push(`${at} must be an object`);
    for (const k of Object.keys(c)) if (k !== "prompt" && k !== "expect") errors.push(`${at} can't have ${k}`);
    const prompt = typeof c.prompt === "string" ? c.prompt.trim() : "";
    const expect = typeof c.expect === "string" ? c.expect.trim() : "";
    if (prompt.length < 1 || prompt.length > 500) errors.push(`${at}.prompt must be 1 to 500 characters`);
    if (expect.length < 1 || expect.length > 300) errors.push(`${at}.expect must be 1 to 300 characters`);
  });
}

function setDocument(raw, errors) {
  if (!isRecord(raw)) return errors.push("set.json must be an object"), undefined;
  const start = errors.length;
  for (const k of Object.keys(raw)) if (!["description", "icon", "items"].includes(k)) errors.push(`set.json can't have ${k}`);
  const description = typeof raw.description === "string" ? raw.description.trim() : "";
  if (description.length < 1 || description.length > 200) errors.push("description must be 1 to 200 characters");
  const icon = typeof raw.icon === "string" && ICON_NAME.test(raw.icon) ? raw.icon : "";
  if (!icon) errors.push("icon must be a Lucide icon name such as rocket");
  const items = [];
  if (!Array.isArray(raw.items) || raw.items.length < 2 || raw.items.length > 12) errors.push("items must be 2 to 12 gallery items");
  else
    raw.items.forEach((x, i) => {
      if (!isRecord(x) || !SET_ITEM_TYPES.includes(x.type) || typeof x.id !== "string" || !ID.test(x.id) || Object.keys(x).some((k) => k !== "type" && k !== "id"))
        return errors.push(`items[${i}] must be { "type": ${SET_ITEM_TYPES.join("|")}, "id" }`);
      if (items.some((y) => y.type === x.type && y.id === x.id)) errors.push(`items[${i}] ${x.type}/${x.id} is listed twice`);
      items.push({ type: x.type, id: x.id });
    });
  if (errors.length > start) return undefined;
  return { description, icon, items };
}

function authorSlug(name) {
  const slug = name.normalize("NFKD").replace(/[̀-ͯ]/g, "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 39).replace(/-+$/, "");
  return slug || "unknown";
}
const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
function buildAuthors(all) {
  const sorted = all.filter((i) => !i.retired).sort((a, b) => (a.type === b.type ? cmp(a.id, b.id) : cmp(a.type, b.type)));
  const byHandle = new Map();
  for (const i of sorted) {
    const handle = i.author.handle ?? authorSlug(i.author.name);
    let entry = byHandle.get(handle);
    if (!entry) byHandle.set(handle, (entry = { handle, name: i.author.name, items: [] }));
    if (!entry.url && i.author.url) entry.url = i.author.url;
    entry.items.push({ type: i.type, id: i.id });
  }
  const authors = [...byHandle.values()].sort((a, b) => cmp(a.handle, b.handle)).map((a) => ({ handle: a.handle, name: a.name, ...(a.url ? { url: a.url } : {}), items: a.items }));
  return { schema: 1, authors };
}

let tested = {};
try {
  const raw = JSON.parse(readFileSync(join(root, "tested.json"), "utf8"));
  if (!isRecord(raw)) throw new Error();
  for (const [id, e] of Object.entries(raw)) {
    if (!isRecord(e) || !Number.isInteger(e.version) || e.version < 1 || typeof e.passed !== "boolean" || !isDate(e.date)) {
      console.error(`tested.json ${id} must be { version, passed, date }`);
      process.exit(1);
    }
    tested[id] = e;
  }
} catch (err) {
  if (err?.code !== "ENOENT") {
    console.error("tested.json must be an object of { version, passed, date }");
    process.exit(1);
  }
  tested = {};
}
const testedFor = (id, version) => {
  const e = Object.hasOwn(tested, id) ? tested[id] : undefined;
  return e?.passed && e.version === version ? { version: e.version, date: e.date } : undefined;
};

const errors = [];
const items = [];
const refs = [];
for (const [dir, type] of [["themes", "theme"], ["schemes", "scheme"], ["wallpapers", "wallpaper"], ["skills", "skill"], ["apps", "app"], ["bots", "bot"], ["routines", "routine"], ["plugins", "plugin"], ["sets", "set"]]) {
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
    const walked = walk(folder).map((path) => ({
      path,
      relative: relative(folder, path).split("\\").join("/"),
      bytes: readFileSync(path),
    }));
    // The cover is taken out before anything else sees the files (allowed lists, hash, size, files).
    const coverFile = COVER_TYPES.includes(type) ? walked.find((f) => f.relative === COVER_FILE) : undefined;
    const files = walked.filter((f) => f !== coverFile);
    if (coverFile) {
      const local = [];
      coverImage(coverFile.bytes, local);
      for (const e of local) errors.push(`${where}: ${e}`);
    }
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
    const licenses = type === "skill" ? SKILL : type === "app" ? APP : type === "plugin" ? APP : type === "bot" || type === "routine" ? WRITING : LOOK;
    const v2 = [];
    const extra = metaV2(meta, type, v2);
    for (const e of v2) errors.push(`${where}: ${e}`);
    let template;
    let setItems;
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
    if (DOCUMENTS[type]) {
      const docName = DOCUMENTS[type];
      for (const f of files)
        if (f.relative !== "item.json" && f.relative !== docName) errors.push(`${where}: ${f.relative} isn't allowed (only item.json, ${docName} and cover.webp)`);
      const raw = readJson(docName);
      if (raw) {
        const local = [...inputsUsage(type, extra.inputs, raw)];
        const filled = fillDocument(type, raw, Object.fromEntries((extra.inputs ?? []).map((i) => [i.key, i.default])));
        if (extra.inputs) template = templateOf(type, raw);
        document = type === "bot" ? botDocument(filled, local) : type === "routine" ? routineDocument(filled, local) : pluginDocument(filled, local);
        description = document?.description;
        for (const e of local) errors.push(`${where}: ${e}`);
      }
    } else if (type === "app") {
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
    } else if (type === "set") {
      for (const f of files) if (f.relative !== "item.json" && f.relative !== "set.json") errors.push(`${where}: ${f.relative} isn't allowed (only item.json, set.json and cover.webp)`);
      const raw = readJson("set.json");
      if (raw) {
        const local = [];
        document = setDocument(raw, local);
        description = document?.description;
        setItems = document?.items;
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
        if (doc.image !== undefined) local.push("only a theme's wallpaper can name an image wallpaper");
        wallpaperFields(doc, local);
        for (const e of local) errors.push(`${where}: ${e}`);
      } else if (doc?.kind === "image") {
        image("file", 2 * 1024 * 1024);
        if (doc.thumb !== undefined) image("thumb", 200 * 1024);
        // The same painting for dark mode (D-388). Apps without it draw `file` in both modes.
        if (doc.dark !== undefined) image("dark", 2 * 1024 * 1024);
        if (doc.darkThumb !== undefined) {
          if (doc.dark === undefined) errors.push(`${where}: darkThumb needs dark`);
          image("darkThumb", 200 * 1024);
        }
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
      if (files.some((f) => f.relative === "tests.json")) {
        const raw = readJson("tests.json");
        const local = [];
        if (raw) testsFile(raw, local);
        for (const e of local) errors.push(`${where}: ${e}`);
      }
    }

    let access = extra.access;
    if (type === "skill" && hasScripts(files.map((f) => f.relative))) {
      if (access?.runs_code === false || access?.computer === false) errors.push(`${where}: access says no code or computer, but the skill brings scripts`);
      access = { ...access, runs_code: true, computer: true };
    }
    const version = Number.isInteger(meta.version) ? meta.version : 1;
    const testedNow = type === "skill" ? testedFor(id, version) : undefined;
    refs.push({ type, id, retired: meta.retired === true, needs: extra.needs, remix_of: extra.remix_of, replaced_by: extra.replaced_by, setItems });

    items.push({
      id,
      type,
      name,
      author: { name: authorName, ...(url ? { url } : {}), ...(extra.handle ? { handle: extra.handle } : {}) },
      license: meta.license,
      tags,
      featured: meta.featured === true,
      retired: meta.retired === true,
      version,
      added: extra.added,
      updated: extra.updated,
      sha256: hash(files.map((f) => ({ path: f.relative, bytes: f.bytes }))),
      size: files.reduce((n, f) => n + f.bytes.byteLength, 0),
      ...(typeof meta.category === "string" ? { category: meta.category } : {}),
      ...(typeof meta.icon === "string" ? { icon: meta.icon } : {}),
      ...(description ? { description } : {}),
      ...(document !== undefined && requiresOf(type, document).length ? { requires: requiresOf(type, document) } : {}),
      ...(extra.changelog ? { changelog: extra.changelog } : {}),
      ...(extra.pick ? { pick: extra.pick } : {}),
      ...(extra.examples ? { examples: extra.examples } : {}),
      ...(access ? { access } : {}),
      ...(extra.needs ? { needs: extra.needs } : {}),
      ...(extra.inputs ? { inputs: extra.inputs } : {}),
      ...(extra.remix_of ? { remix_of: extra.remix_of } : {}),
      ...(extra.replaced_by ? { replaced_by: extra.replaced_by } : {}),
      ...(extra.min_app ? { min_app: extra.min_app } : {}),
      ...(extra.min_server ? { min_server: extra.min_server } : {}),
      ...(extra.season ? { season: extra.season } : {}),
      ...(testedNow ? { tested: testedNow } : {}),
      ...(document !== undefined ? { document: indexDocument(type, document) } : {}),
      ...(template ? { template } : {}),
      ...(coverFile ? { cover: `${dir}/${id}/${COVER_FILE}` } : {}),
      files: files.map((f) => `${dir}/${id}/${f.relative}`).sort(),
    });
  }
}

// Check-in and setup prompts (D-374): prompts/<id>.md, versioned in prompts/versions.json (a new
// version whenever a text changes). Main catalog only; packages/agent/src/prompts.ts holds the ids,
// the fallback text and the same reserved words (its test keeps them in step).
const PROMPT_IDS = ["checkin.brief", "checkin.scan", "checkin.setup_scan", "checkin.reason.connection", "checkin.reason.event", "setup.guide"];
const PROMPT_RESERVED = [[/NOTHING_NEW/, "NOTHING_NEW"], [/quiet day/i, '"Quiet day"'], [/write my morning brief for today/i, "the brief's opening line"], [/check-in scan\./i, "the scan's opening line"], [/you(?:'|’)re all set/i, '"You\'re all set"']];
const prompts = (() => {
  const dir = join(root, "prompts");
  let versions = {};
  try {
    versions = JSON.parse(readFileSync(join(dir, "versions.json"), "utf8"));
  } catch {
    // A first run starts every prompt at version 1.
  }
  const out = [];
  const nextVersions = {};
  for (const file of readdirSync(dir).filter((f) => f.endsWith(".md")).sort()) {
    const id = file.slice(0, -3);
    if (!PROMPT_IDS.includes(id)) {
      errors.push(`prompts/${file}: ${id} isn't a prompt id`);
      continue;
    }
    const text = readFileSync(join(dir, file), "utf8").trim();
    if (text.length < 20 || text.length > 8000) errors.push(`prompts/${file}: the text must be 20 to 8000 characters`);
    for (const [re, what] of PROMPT_RESERVED) if (re.test(text)) errors.push(`prompts/${file}: ${what} is added by code; leave it out of the text`);
    const sha256 = createHash("sha256").update(text).digest("hex");
    const was = versions[id];
    const version = !was ? 1 : was.sha256 === sha256 ? was.version : was.version + 1;
    nextVersions[id] = { version, sha256 };
    out.push({ id, version, text });
  }
  return { items: out, versions: nextVersions };
})();

// References that need the whole catalog: needs, remix_of, replaced_by and sets' items.
const known = new Map(refs.map((r) => [`${r.type}/${r.id}`, r]));
const builtInApps = new Set(BUILT_IN_APPS);
for (const r of refs) {
  const where = `${r.type}/${r.id}`;
  for (const id of r.needs?.skills ?? []) if (!known.has(`skill/${id}`)) errors.push(`${where}: needs skill ${id}, which isn't in the gallery`);
  for (const id of r.needs?.apps ?? [])
    if (!builtInApps.has(id) && !builtInApps.has(id.replaceAll("-", "_")) && !known.has(`app/${id}`)) errors.push(`${where}: needs app ${id}, which isn't a gallery or built-in app`);
  for (const field of ["remix_of", "replaced_by"]) {
    const ref = r[field];
    if (!ref) continue;
    if (ref.type === r.type && ref.id === r.id) errors.push(`${where}: ${field} can't be itself`);
    else if (!known.has(`${ref.type}/${ref.id}`)) errors.push(`${where}: ${field} ${ref.type}/${ref.id} isn't in the gallery`);
  }
  if (r.replaced_by && !r.retired) errors.push(`${where}: replaced_by is only for retired items`);
  for (const ref of r.setItems ?? []) {
    const found = known.get(`${ref.type}/${ref.id}`);
    if (!found) errors.push(`${where}: ${ref.type}/${ref.id} isn't in the gallery`);
    else if (found.retired) errors.push(`${where}: ${ref.type}/${ref.id} is retired`);
  }
}

// Coding agents (D-370): first-party, hand-written, signed with the rest. Their commands run on
// people's computers, so pull requests from outside Casama can't change this file (gallery.yml).
// Mirrors packages/domain/src/coding-agents.ts (parseCodingAgentEntry, checkCodingTemplate).
const CODING_AGENTS_FILE = "coding-agents.json";
let codingAgentsBody = "";
try {
  codingAgentsBody = readFileSync(join(root, CODING_AGENTS_FILE), "utf8");
} catch {
  errors.push(`${CODING_AGENTS_FILE} is missing`);
}
if (codingAgentsBody) {
  let parsed;
  try {
    parsed = JSON.parse(codingAgentsBody);
  } catch {
    errors.push(`${CODING_AGENTS_FILE} is not JSON`);
  }
  if (parsed && (parsed.schema !== 1 || !Array.isArray(parsed.items))) errors.push(`${CODING_AGENTS_FILE} must be { "schema": 1, "items": [...] }`);
  else if (parsed) {
    const ids = new Set();
    for (const [n, e] of parsed.items.entries()) for (const err of checkCodingAgent(e, ids)) errors.push(`${CODING_AGENTS_FILE} items[${n}]: ${err}`);
  }
}

function checkCodingTemplate(t, bin, marker) {
  if (typeof t !== "string" || !t.trim()) return ["the command is empty"];
  if (t.length > 1000) return ["the command is longer than 1000 characters"];
  const tokens = [];
  let i = 0;
  while (i < t.length) {
    const ch = t[i];
    if (ch === " " || ch === "\t") { i++; continue; }
    if (ch === "\n" || ch === "\r") return ["a command is one line"];
    const two = t.slice(i, i + 2);
    if (two === "&&" || two === "||") { tokens.push({ op: two }); i += 2; continue; }
    if (ch === ";" || ch === "|") { tokens.push({ op: ch }); i++; continue; }
    if (ch === "{") {
      const close = t.indexOf("}", i);
      const name = close > i ? t.slice(i + 1, close) : "";
      if (!["task", "folder", "result_file"].includes(name)) return ["only {task}, {folder} and {result_file} may be used"];
      if (t[close + 1] !== undefined && !/[\s;|&]/.test(t[close + 1])) return [`{${name}} must be a word of its own`];
      tokens.push({ placeholder: name });
      i = close + 1;
      continue;
    }
    let text = "";
    while (i < t.length) {
      const c = t[i];
      if (c === " " || c === "\t" || c === ";" || c === "|") break;
      if (c === "&") {
        if (t[i + 1] === "&") break;
        if (t[i - 1] === ">" && /[0-9]/.test(t[i + 1] ?? "")) { text += c; i++; continue; }
        return ["a command can't run in the background (&)"];
      }
      if (c === "'" || c === '"') {
        const close = t.indexOf(c, i + 1);
        if (close < 0) return ["a quote isn't closed"];
        const inner = t.slice(i + 1, close);
        if (c === '"' && /[$`\\\n\r]/.test(inner)) return ["double quotes can't hold $, backticks or backslashes"];
        if (/[\n\r]/.test(inner)) return ["a command is one line"];
        if (/\{(task|folder|result_file)\}/.test(inner)) return ["placeholders can't be inside quotes"];
        text += inner;
        i = close + 1;
        continue;
      }
      if (c === ">" || c === "<") { text += c; i++; continue; }
      if (!/[A-Za-z0-9_\-./=:,@+%^~]/.test(c)) return [`"${c}" isn't allowed outside quotes`];
      text += c;
      i++;
    }
    tokens.push({ word: text });
  }
  const errs = [];
  let atStart = true;
  for (const tok of tokens) {
    if (tok.op) { if (atStart) errs.push(`"${tok.op}" needs a command before it`); atStart = true; continue; }
    if (atStart && tok.word !== bin) errs.push(`every command must start with ${bin}`);
    atStart = false;
  }
  if (atStart && tokens.length) errs.push("it can't end with an operator");
  const names = tokens.filter((x) => x.placeholder).map((x) => x.placeholder);
  if (names.filter((x) => x === "task").length !== 1) errs.push("it needs {task}, once");
  if (marker !== names.includes("result_file")) errs.push("{result_file} goes with the marker result, and only with it");
  return [...new Set(errs)];
}

function checkCodingAgent(e, ids) {
  if (!isRecord(e)) return ["must be an object"];
  const errs = [];
  const KEYS = ["id", "label", "bin", "where", "install", "key_name", "command", "result", "browser", "commits_for_agent", "needs_folder", "exit_messages", "hint", "min_server"];
  for (const k of Object.keys(e)) if (!KEYS.includes(k)) errs.push(`unknown field ${k}`);
  if (typeof e.id !== "string" || !/^[a-z][a-z0-9_]{1,31}$/.test(e.id) || e.id.startsWith("own_")) errs.push("id must be 2 to 32 lower-case letters, digits or _, not starting with own_");
  else if (ids.has(e.id)) errs.push(`${e.id} is listed twice`);
  else ids.add(e.id);
  const text = (v, max) => typeof v === "string" && v.trim().length > 0 && v.length <= max && !/[\u0000-\u001f]/.test(v);
  if (!text(e.label, 40)) errs.push("label must be 1 to 40 characters");
  const binOk = typeof e.bin === "string" && /^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/.test(e.bin);
  if (!binOk) errs.push("bin must be a command name");
  const whereOk = Array.isArray(e.where) && e.where.length > 0 && e.where.every((w) => ["my_computer", "bot_computer"].includes(w)) && new Set(e.where).size === e.where.length;
  if (!whereOk) errs.push("where must list my_computer and/or bot_computer");
  if (e.install != null && !text(e.install, 300)) errs.push("install must be one line of at most 300 characters");
  if (e.key_name != null && (typeof e.key_name !== "string" || !/^[A-Z][A-Z0-9_]{1,63}$/.test(e.key_name))) errs.push("key_name must be UPPER_SNAKE_CASE");
  if (whereOk && e.where.includes("bot_computer") && (!e.install || !e.key_name)) errs.push("bot_computer needs install and key_name");
  const resultOk = ["json_result", "marker", "stream_json", "tail"].includes(e.result) || (typeof e.result === "string" && /^json_field:[A-Za-z_][A-Za-z0-9_]{0,31}$/.test(e.result));
  if (!resultOk) errs.push("result must be json_result, marker, json_field:<name>, stream_json or tail");
  if (!isRecord(e.command)) errs.push("command must be an object by where");
  else if (whereOk && binOk) {
    for (const k of Object.keys(e.command)) if (!e.where.includes(k)) errs.push(`command.${k} isn't in where`);
    for (const w of e.where) for (const err of checkCodingTemplate(e.command[w], e.bin, e.result === "marker")) errs.push(`command.${w}: ${err}`);
  }
  if (e.browser != null && !["claude", "codex"].includes(e.browser)) errs.push("browser must be claude, codex or left out");
  for (const k of ["commits_for_agent", "needs_folder"]) if (e[k] !== undefined && typeof e[k] !== "boolean") errs.push(`${k} must be true or false`);
  if (e.exit_messages !== undefined) {
    if (!isRecord(e.exit_messages)) errs.push("exit_messages must be an object");
    else for (const [code, m] of Object.entries(e.exit_messages)) {
      if (!/^[1-9][0-9]{0,2}$/.test(code)) errs.push(`exit_messages.${code}: not an exit code`);
      else if (!isRecord(m) || !text(m.status, 80) || (m.note !== undefined && !text(m.note, 300))) errs.push(`exit_messages.${code} needs a status (and an optional note)`);
    }
  }
  if (e.hint != null && !text(e.hint, 160)) errs.push("hint must be at most 160 characters");
  if (e.min_server !== undefined && !(typeof e.min_server === "string" && SEMVER.test(e.min_server))) errs.push("min_server must be a version like 0.2.0");
  return errs;
}

// Content lists (D-372): first-party lists the apps and servers read instead of their built-in
// copies (search words, welcome chat words, empty-state starters, app catalog curation). One file
// each in lists/, published together as lists.json. Readers skip what they don't know, so a list
// here can only add or reword; packages/domain/src/gallery-lists.ts is the reader.
const LISTS = ["search-words", "welcome", "starters", "app-curation"];
// The welcome chat's focus ids (packages/agent/src/welcome.ts WELCOME_FOCUS): fixed for analytics.
const WELCOME_FOCUS_IDS = ["email_calendar", "work_projects", "coding", "research", "sales", "errands", "health", "other"];
const LIST_WORD = /^[a-z0-9][a-z0-9' -]{0,30}$/;
const LIST_ID = /^[a-z0-9][a-z0-9_-]{0,62}$/;
const lists = [];
function listDocument(id, raw, errs) {
  const textOk = (v, max) => typeof v === "string" && v.trim().length >= 1 && v.trim().length <= max;
  const ids = (v, max, label, known) => {
    if (v === undefined) return;
    if (!Array.isArray(v) || v.length > max || v.some((x) => typeof x !== "string" || !LIST_ID.test(x)) || new Set(v).size !== v.length)
      return errs.push(`${label} must be at most ${max} different ids`);
    if (known) for (const x of v) if (!known.includes(x)) errs.push(`${label}: ${x} isn't a built-in app`);
  };
  const entries = (v, label, max, fields) => {
    if (v === undefined) return;
    if (!Array.isArray(v) || v.length < 1 || v.length > max) return errs.push(`${label} must list 1 to ${max} entries`);
    const seen = new Set();
    v.forEach((e, i) => {
      if (!isRecord(e) || typeof e.id !== "string" || !LIST_ID.test(e.id)) return errs.push(`${label}[${i}].id must be lowercase letters, digits, - or _`);
      if (seen.has(e.id)) errs.push(`${label}[${i}].id ${e.id} is used twice`);
      seen.add(e.id);
      for (const [k, max] of Object.entries(fields)) if (!textOk(e[k], max)) errs.push(`${label}[${i}].${k} must be 1 to ${max} characters`);
    });
  };
  if (id === "search-words") {
    if (!isRecord(raw.words) || Object.keys(raw.words).length < 1 || Object.keys(raw.words).length > 500) return errs.push("words must map 1 to 500 words to lists");
    for (const [k, v] of Object.entries(raw.words)) {
      if (!LIST_WORD.test(k)) errs.push(`words.${k}: lowercase words only`);
      if (!Array.isArray(v) || v.length < 1 || v.length > 12 || v.some((x) => typeof x !== "string" || !LIST_WORD.test(x) || x === k) || new Set(v).size !== v.length)
        errs.push(`words.${k} must be 1 to 12 different lowercase words, not itself`);
    }
  } else if (id === "welcome") {
    if (!Array.isArray(raw.focus) || raw.focus.length < 1) return errs.push("focus must list the choices");
    const seen = new Set();
    raw.focus.forEach((f, i) => {
      const at = `focus[${i}]`;
      if (!isRecord(f) || !WELCOME_FOCUS_IDS.includes(f.id)) return errs.push(`${at}.id must be one of ${WELCOME_FOCUS_IDS.join(", ")}`);
      if (seen.has(f.id)) errs.push(`${at}.id ${f.id} is used twice`);
      seen.add(f.id);
      for (const k of Object.keys(f)) if (!["id", "label", "intro", "first_task", "starters", "apps"].includes(k)) errs.push(`${at}.${k} isn't a field`);
      if (f.label !== undefined && !textOk(f.label, 40)) errs.push(`${at}.label must be 1 to 40 characters`);
      if (f.intro !== undefined && !textOk(f.intro, 400)) errs.push(`${at}.intro must be 1 to 400 characters`);
      if (f.first_task !== undefined) {
        const t = f.first_task;
        if (!isRecord(t) || !textOk(t.label, 120) || !textOk(t.placeholder, 120) || typeof t.prefix !== "string" || t.prefix.length > 200)
          errs.push(`${at}.first_task needs label and placeholder (1 to 120 characters) and a prefix (up to 200)`);
      }
      ids(f.starters, 4, `${at}.starters`);
      ids(f.apps, 4, `${at}.apps`, BUILT_IN_APPS);
    });
  } else if (id === "starters") {
    entries(raw.library, "library", 9, { label: 40, prompt: 300 });
    for (const [i, e] of (Array.isArray(raw.library) ? raw.library : []).entries()) {
      if (!isRecord(e)) continue;
      if (typeof e.icon !== "string" || !LUCIDE[e.icon]) errs.push(`library[${i}].icon must be a Lucide icon name`);
      if (typeof e.hue !== "number" || e.hue < 0 || e.hue > 360) errs.push(`library[${i}].hue must be 0 to 360`);
    }
    entries(raw.tasks, "tasks", 6, { text: 160 });
    entries(raw.support, "support", 6, { text: 120 });
  } else if (id === "app-curation") {
    const allowed = ["id", "name", "description", "color", "featured"];
    if (!Array.isArray(raw.apps) || raw.apps.length > 200) errs.push("apps must be a list");
    else
      raw.apps.forEach((a, i) => {
        const at = `apps[${i}]`;
        if (!isRecord(a) || !BUILT_IN_APPS.includes(a.id)) return errs.push(`${at}.id must be a built-in app (gallery apps are curated in their own entry)`);
        for (const k of Object.keys(a)) if (!allowed.includes(k)) errs.push(`${at}.${k}: only display fields (${allowed.join(", ")}); sign-in details stay in code`);
        if (a.name !== undefined && !textOk(a.name, 60)) errs.push(`${at}.name must be 1 to 60 characters`);
        if (a.description !== undefined && !textOk(a.description, 300)) errs.push(`${at}.description must be 1 to 300 characters`);
        if (a.color !== undefined && !(typeof a.color === "string" && /^[0-9A-Fa-f]{6}$/.test(a.color))) errs.push(`${at}.color must be six hex digits without #`);
        if (a.featured !== undefined && typeof a.featured !== "boolean") errs.push(`${at}.featured must be true or false`);
      });
    ids(raw.order, 200, "order", BUILT_IN_APPS);
    ids(raw.starter_apps, 8, "starter_apps", BUILT_IN_APPS);
  }
}
{
  const parent = join(root, "lists");
  let names = [];
  try {
    names = readdirSync(parent).filter((n) => n.endsWith(".json"));
  } catch {
    // No lists: every reader keeps its built-in copy.
  }
  for (const file of names.sort()) {
    const id = file.replace(/\.json$/, "");
    const where = `lists/${file}`;
    if (!LISTS.includes(id)) {
      errors.push(`${where}: unknown list (${LISTS.join(", ")})`);
      continue;
    }
    let raw;
    try {
      raw = JSON.parse(readFileSync(join(parent, file), "utf8"));
    } catch {
      errors.push(`${where}: not JSON`);
      continue;
    }
    if (!isRecord(raw)) {
      errors.push(`${where}: must be an object`);
      continue;
    }
    const { name, version, updated, ...document } = raw;
    const local = [];
    if (typeof name !== "string" || name.trim().length < 1 || name.trim().length > 60) local.push("name must be 1 to 60 characters");
    if (!Number.isInteger(version) || version < 1) local.push("version must be a whole number from 1");
    if (!isDate(updated)) local.push("updated must be a YYYY-MM-DD date");
    listDocument(id, document, local);
    for (const e of local) errors.push(`${where}: ${e}`);
    lists.push({ type: "list", id, name: typeof name === "string" ? name.trim() : id, version, updated, document });
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
  { file: "index.json", items: items.filter((i) => INDEX_TYPES.includes(i.type)) },
  { file: "apps.json", items: items.filter((i) => i.type === "app") },
  { file: "bots.json", items: items.filter((i) => i.type === "bot") },
  { file: "routines.json", items: items.filter((i) => i.type === "routine") },
  { file: "plugins.json", items: items.filter((i) => i.type === "plugin") },
  // Starter sets (D-315): a new kind, so its own file.
  { file: "sets.json", items: items.filter((i) => i.type === "set") },
  // Content lists (D-372): their own file, so no older reader sees them.
  { file: "lists.json", items: lists },
];
const bodies = outputs.map((out) => ({ file: out.file, body: `${JSON.stringify({ schema: 1, items: out.items }, null, 2)}\n`, count: `${out.items.length} items` }));
const authors = buildAuthors(items);
bodies.push({ file: "authors.json", body: `${JSON.stringify(authors, null, 2)}\n`, count: `${authors.authors.length} authors` });
// Hand-written: read as it is, never rewritten; only its hash goes in the manifest.
bodies.push({ file: CODING_AGENTS_FILE, body: codingAgentsBody, source: true });
bodies.push({ file: "prompts.json", body: `${JSON.stringify({ schema: 1, items: prompts.items }, null, 2)}\n`, count: `${prompts.items.length} prompts` });
bodies.push({ file: "prompts/versions.json", body: `${JSON.stringify(prompts.versions, null, 2)}\n`, count: `${prompts.items.length} versions` });
// The manifest's date is the newest change in the catalog, so it only moves when the catalog does.
const created = [...items, ...lists].reduce((max, i) => (i.updated > max ? i.updated : max), "");
const manifest = {
  schema: 1,
  created,
  files: Object.fromEntries(MANIFEST_FILES.map((file) => [file, createHash("sha256").update(bodies.find((b) => b.file === file).body).digest("hex")])),
};
bodies.push({ file: "manifest.json", body: `${JSON.stringify(manifest, null, 2)}\n`, count: `${MANIFEST_FILES.length} files` });
let stale = false;
for (const out of bodies) {
  if (out.source) continue;
  const body = out.body;
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
    console.log(`wrote ${out.file} (${out.count})`);
  }
}
if (stale) process.exit(1);
if (checkOnly) console.log(`gallery ok, ${items.length} items`);
