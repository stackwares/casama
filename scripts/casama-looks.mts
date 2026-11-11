/**
 * Built-in looks are data (D-201): client/looks holds the Casama scheme, the mesh palettes and the
 * doodle patterns in the gallery's formats. This checks them and writes client/lib/theme/looks.g.dart.
 *   node scripts/casama-looks.mts          write looks.g.dart
 *   node scripts/casama-looks.mts --check  fail if looks.g.dart is stale
 */
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const repo = join(import.meta.dirname, "..");
const looks = join(repo, "client", "looks");
const out = join(repo, "client", "lib", "theme", "looks.g.dart");
const lucide = JSON.parse(
  readFileSync(join(repo, "gallery", "assets", "lucide", "icon-nodes.json"), "utf8"),
) as Record<string, [string, Record<string, string | number>][]>;

const HEX = /^#[0-9A-Fa-f]{6}$/;
const errors: string[] = [];
const read = (path: string) => JSON.parse(readFileSync(join(looks, path), "utf8"));

function channel(c: number) {
  const s = c / 255;
  return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
}
function luminance(hex: string) {
  const n = Number.parseInt(hex.slice(1), 16);
  return (
    0.2126 * channel((n >> 16) & 255) + 0.7152 * channel((n >> 8) & 255) + 0.0722 * channel(n & 255)
  );
}
function contrast(a: string, b: string) {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
}
const color = (hex: string) => `Color(0xFF${hex.slice(1).toUpperCase()})`;
const num = (v: number) => `${v}`;
const dartString = (s: string) =>
  `'${s.replace(/\\/g, "\\\\").replace(/'/g, "\\'").replace(/\$/g, "\\$")}'`;
const number = (v: unknown) => (typeof v === "number" ? v : Number.parseFloat(String(v)));
const dartDouble = (v: unknown) => `${number(v)}`;

// ------------------------------------------------------------------ meshes
function meshDart(id: string, raw: Record<string, unknown>) {
  const where = `meshes/${id}.json`;
  for (const key of ["light", "dark"] as const) {
    const list = raw[key];
    if (
      !Array.isArray(list) ||
      list.length !== 9 ||
      !list.every((c) => typeof c === "string" && HEX.test(c))
    ) {
      errors.push(`${where}: ${key} must be nine #RRGGBB colors`);
      return "";
    }
    for (const c of list as string[]) {
      if (key === "light" && luminance(c) < 0.55) errors.push(`${where}: light ${c} is too dark`);
      if (key === "dark" && luminance(c) > 0.05) errors.push(`${where}: dark ${c} is too light`);
    }
  }
  const points = raw.points as [number, number][];
  if (!Array.isArray(points) || points.length !== 9)
    errors.push(`${where}: points must be nine [x, y]`);
  else
    points.forEach(([x, y], i) => {
      const col = i % 3;
      const row = Math.floor(i / 3);
      if ((col !== 1 && x !== col / 2) || (row !== 1 && y !== row / 2))
        errors.push(`${where}: point ${i} must stay on its corner or edge`);
      if ((col === 1 && (x < 0.2 || x > 0.8)) || (row === 1 && (y < 0.2 || y > 0.8)))
        errors.push(`${where}: point ${i} must stay between 0.2 and 0.8`);
    });
  const offsets = points.map(([x, y]) =>
    x === 0 && y === 0 ? "Offset.zero" : `Offset(${num(x)}, ${num(y)})`,
  );
  return `  ${id}(
    ${dartString(raw.name as string)},
    [${(raw.light as string[]).map(color).join(", ")}],
    dark: [${(raw.dark as string[]).map(color).join(", ")}],
    points: [${offsets.join(", ")}],
  )`;
}

// ------------------------------------------------------------------ doodles
function shapeDart(where: string, node: [string, Record<string, string | number>]): string {
  const [tag, a] = node;
  switch (tag) {
    case "path":
      if (typeof a.d !== "string" || a.d.length > 1500) errors.push(`${where}: bad path`);
      return `DoodlePath(${dartString(String(a.d))})`;
    case "circle":
      return `DoodleCircle(${dartDouble(a.cx)}, ${dartDouble(a.cy)}, ${dartDouble(a.r)})`;
    case "ellipse":
      return `DoodleEllipse(${dartDouble(a.cx)}, ${dartDouble(a.cy)}, ${dartDouble(a.rx)}, ${dartDouble(a.ry)})`;
    case "rect": {
      const rx = a.rx ?? a.ry;
      const ry = a.ry ?? a.rx;
      const radius = rx === undefined ? "" : `, rx: ${dartDouble(rx)}, ry: ${dartDouble(ry)}`;
      return `DoodleRect(${dartDouble(a.x ?? 0)}, ${dartDouble(a.y ?? 0)}, ${dartDouble(a.width)}, ${dartDouble(a.height)}${radius})`;
    }
    case "line":
      return `DoodleLine(${dartDouble(a.x1)}, ${dartDouble(a.y1)}, ${dartDouble(a.x2)}, ${dartDouble(a.y2)})`;
    case "polyline":
    case "polygon": {
      const values = String(a.points)
        .trim()
        .split(/[\s,]+/)
        .map(dartDouble);
      return `DoodlePoly([${values.join(", ")}], closed: ${tag === "polygon"})`;
    }
  }
  errors.push(`${where}: ${tag} is not a doodle shape`);
  return "";
}

function patternDart(id: string, raw: Record<string, unknown>) {
  const where = `patterns/${id}.json`;
  let doodles: [string, Record<string, string | number>][][] = [];
  if (Array.isArray(raw.glyphs) && raw.doodles === undefined) {
    for (const name of raw.glyphs as string[]) {
      const found = lucide[name];
      if (!found) errors.push(`${where}: ${name} is not a Lucide icon`);
      else doodles.push(found);
    }
  } else if (Array.isArray(raw.doodles) && raw.glyphs === undefined) {
    doodles = raw.doodles as typeof doodles;
  } else errors.push(`${where}: give glyphs or doodles`);
  if (doodles.length < 1 || doodles.length > 24) errors.push(`${where}: 1 to 24 doodles`);
  const items = doodles.map((d, i) => {
    if (d.length < 1 || d.length > 24) errors.push(`${where}: doodle ${i} needs 1 to 24 shapes`);
    return `Doodle([${d.map((n) => shapeDart(where, n)).join(", ")}])`;
  });
  return `  ${id}(${dartString(raw.name as string)}, [${items.join(", ")}])`;
}

// ------------------------------------------------------------------ schemes
const SIX = [
  "primary",
  "primaryContainer",
  "secondary",
  "secondaryContainer",
  "tertiary",
  "tertiaryContainer",
];
function schemeDart(id: string, raw: Record<string, Record<string, string>>) {
  const where = `schemes/${id}.json`;
  const mode = (m: "light" | "dark") => {
    const c = raw[m];
    for (const key of ["seed", "background", "onBackground", ...SIX])
      if (!HEX.test(c?.[key] ?? "")) errors.push(`${where}: ${m}.${key} must be a #RRGGBB color`);
    if (errors.length) return "";
    for (const key of ["primary", "secondary", "tertiary"])
      if (contrast(c[key], c.background) < 4.5)
        errors.push(`${where}: ${m}.${key} is below 4.5:1 on the background`);
    for (const key of ["primaryContainer", "secondaryContainer", "tertiaryContainer"])
      if (contrast(c.onBackground, c[key]) < 4.5)
        errors.push(`${where}: ${m} text is below 4.5:1 on ${key}`);
    return `FlexSchemeColor(
    primary: ${color(c.primary)},
    primaryContainer: ${color(c.primaryContainer)},
    secondary: ${color(c.secondary)},
    secondaryContainer: ${color(c.secondaryContainer)},
    tertiary: ${color(c.tertiary)},
    tertiaryContainer: ${color(c.tertiaryContainer)},
    appBarColor: ${color(c.appBar ?? c.primaryContainer)},
    error: ${m === "light" ? "Color(0xFFBA1A1A)" : "Color(0xFFFFB4AB)"},
  )`;
  };
  const camel = id.replace(/-([a-z])/g, (_, ch: string) => ch.toUpperCase());
  return `/// ${raw.name as unknown as string}: ${raw.description as unknown as string}
const ${camel}Scheme = FlexSchemeData(
  name: ${dartString(raw.name as unknown as string)},
  description: ${dartString(raw.description as unknown as string)},
  light: ${mode("light")},
  dark: ${mode("dark")},
);`;
}

// ------------------------------------------------------------------ write
const index = read("index.json") as { schemes: string[]; meshes: string[]; patterns: string[] };
const meshes = index.meshes.map((id) => meshDart(id, read(`meshes/${id}.json`)));
const patterns = index.patterns.map((id) => patternDart(id, read(`patterns/${id}.json`)));
const schemes = index.schemes.map((id) => schemeDart(id, read(`schemes/${id}.json`)));

if (errors.length) {
  for (const e of errors) console.error(e);
  process.exit(1);
}

const source = `// Made by scripts/casama-looks.mts from client/looks; do not edit.

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import 'doodles.dart';
import 'mesh_gradient.dart';

/// A mesh gradient behind the pattern: nine colors on a gently warped 3×3 grid, with hand-picked
/// night versions. \`theme\` follows the chosen color scheme; \`flat\` is its plain surface.
enum WallpaperPalette {
  theme('Theme', []),

  /// No gradient at all: the theme's own surface color, flat.
  flat('Flat', []),
${meshes.join(",\n")};

  const WallpaperPalette(
    this.label,
    this.light, {
    this.dark,
    this.points = MeshGradient.evenPoints,
  });
  final String label;
  final List<Color> light;
  final List<Color>? dark;

  /// Where the nine colors sit, as fractions of the window, row by row from the top left.
  final List<Offset> points;
}

/// Doodle patterns drawn over the wallpaper gradient, Telegram style, from Lucide drawings.
enum WallpaperPattern {
  none('Plain', []),
${patterns.join(",\n")};

  const WallpaperPattern(this.label, this.drawings);
  final String label;

  /// The drawings scattered over the tile. (Not \`doodles\`: that is a pattern's name.)
  final List<Doodle> drawings;
}

${schemes.join("\n\n")}
`;

// Formatted with dart format, so the file reads like the rest and the output is stable.
const tmp = join(mkdtempSync(join(tmpdir(), "casama-looks-")), "looks.g.dart");
writeFileSync(tmp, source);
execFileSync("dart", ["format", "--output=write", tmp], { stdio: "ignore" });
const formatted = readFileSync(tmp, "utf8");

if (process.argv.includes("--check")) {
  const current = readFileSync(out, "utf8");
  if (current !== formatted) {
    console.error("client/lib/theme/looks.g.dart is stale: run node scripts/casama-looks.mts");
    process.exit(1);
  }
  console.log("looks ok");
} else {
  writeFileSync(out, formatted);
  console.log(
    `wrote client/lib/theme/looks.g.dart (${index.schemes.length} schemes, ${index.meshes.length} meshes, ${index.patterns.length} patterns)`,
  );
}
