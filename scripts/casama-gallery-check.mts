/**
 * Checks gallery/ and writes gallery/index.json.
 *   node scripts/casama-gallery-check.mts
 * Exit 1 when an item is wrong. Pass --check to verify the committed index matches.
 */
import { createHash } from "node:crypto";
import { readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import {
  checkGalleryId,
  checkSchemeDocument,
  checkSkillDocument,
  checkThemeDocument,
  checkWallpaperDocument,
  type GalleryType,
  galleryHash,
  LOOK_LICENSES,
  parseGalleryMeta,
  SKILL_LICENSES,
} from "../packages/domain/src/gallery.ts";
import { parseSkillMd } from "../packages/domain/src/skill-format.ts";

const root = fileURLToPath(new URL("../gallery", import.meta.url));
const checkOnly = process.argv.includes("--check");

const folders: { dir: string; type: GalleryType }[] = [
  { dir: "themes", type: "theme" },
  { dir: "schemes", type: "scheme" },
  { dir: "wallpapers", type: "wallpaper" },
  { dir: "skills", type: "skill" },
];

function walk(dir: string): string[] {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    return statSync(path).isDirectory() ? walk(path) : [path];
  });
}

const errors: string[] = [];
const items: unknown[] = [];

for (const { dir, type } of folders) {
  const parent = join(root, dir);
  let ids: string[] = [];
  try {
    ids = readdirSync(parent).filter((name) => statSync(join(parent, name)).isDirectory());
  } catch {
    errors.push(`missing ${dir}/`);
    continue;
  }
  for (const id of ids) {
    const where = `${dir}/${id}`;
    const badId = checkGalleryId(id);
    if (badId) errors.push(`${where}: ${badId}`);
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
    let metaJson: unknown;
    try {
      metaJson = JSON.parse(metaFile.bytes.toString("utf8"));
    } catch {
      errors.push(`${where}: item.json is not JSON`);
      continue;
    }
    const licenses = type === "skill" ? SKILL_LICENSES : LOOK_LICENSES;
    const parsed = parseGalleryMeta(metaJson, licenses);
    for (const e of parsed.errors) errors.push(`${where}: ${e}`);
    if (!parsed.meta) continue;
    if (type === "skill" && !parsed.meta.category)
      errors.push(`${where}: a skill needs a category`);

    // What a gallery card needs to draw its preview, so a list needs no request per item.
    let document: unknown;
    let description: string | undefined;
    if (type === "theme" || type === "scheme" || type === "wallpaper") {
      const name =
        type === "theme" ? "theme.json" : type === "scheme" ? "scheme.json" : "wallpaper.json";
      const doc = files.find((f) => f.relative === name);
      if (!doc) {
        errors.push(`${where}: missing ${name}`);
        continue;
      }
      let json: unknown;
      try {
        json = JSON.parse(doc.bytes.toString("utf8"));
      } catch {
        errors.push(`${where}: ${name} is not JSON`);
        continue;
      }
      const found =
        type === "theme"
          ? checkThemeDocument(json)
          : type === "scheme"
            ? checkSchemeDocument(json)
            : checkWallpaperDocument(
                json,
                files.map((f) => ({ path: f.relative, bytes: f.bytes.byteLength })),
              );
      for (const e of found) errors.push(`${where}: ${e}`);
      document = json;
    } else {
      const skill = files.find((f) => f.relative === "SKILL.md");
      if (!skill) errors.push(`${where}: missing SKILL.md`);
      else
        for (const e of checkSkillDocument(id, skill.bytes.toString("utf8")))
          errors.push(`${where}: ${e}`);
      try {
        if (skill) description = parseSkillMd(skill.bytes.toString("utf8")).description;
      } catch {
        // Reported above.
      }
    }

    const sha256 = galleryHash(files.map((f) => ({ path: f.relative, bytes: f.bytes })));
    const size = files.reduce((n, f) => n + f.bytes.byteLength, 0);
    items.push({
      id,
      type,
      name: parsed.meta.name,
      author: parsed.meta.author,
      license: parsed.meta.license,
      tags: parsed.meta.tags,
      featured: parsed.meta.featured,
      retired: parsed.meta.retired,
      version: parsed.meta.version,
      sha256,
      size,
      ...(parsed.meta.category ? { category: parsed.meta.category } : {}),
      ...(parsed.meta.icon ? { icon: parsed.meta.icon } : {}),
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

items.sort((a, b) => {
  const left = a as { type: string; id: string };
  const right = b as { type: string; id: string };
  return left.type === right.type
    ? left.id.localeCompare(right.id)
    : left.type.localeCompare(right.type);
});

const body = `${JSON.stringify({ schema: 1, items }, null, 2)}\n`;
const indexPath = join(root, "index.json");
if (checkOnly) {
  const current = readFileSync(indexPath, "utf8");
  const same =
    createHash("sha256").update(current).digest("hex") ===
    createHash("sha256").update(body).digest("hex");
  if (!same) {
    console.error("gallery/index.json is stale. Run scripts/casama-gallery-check.ts");
    process.exit(1);
  }
  console.log(`gallery ok, ${items.length} items`);
} else {
  writeFileSync(indexPath, body);
  console.log(`wrote gallery/index.json (${items.length} items)`);
}
