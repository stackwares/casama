/**
 * Checks gallery/ and writes gallery/index.json.
 *   node scripts/casama-gallery-check.mts
 * Exit 1 when an item is wrong. Pass --check to verify the committed index matches.
 */
import { createHash } from "node:crypto";
import { readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { APP_CATALOG } from "../packages/domain/src/apps.ts";
import {
  checkGalleryId,
  checkSchemeDocument,
  checkSkillDocument,
  checkThemeDocument,
  checkWallpaperDocument,
  type GalleryType,
  galleryHash,
  galleryIndexDocument,
  galleryRequires,
  LOOK_LICENSES,
  type LucideNodes,
  parseGalleryMeta,
  SKILL_LICENSES,
} from "../packages/domain/src/gallery.ts";
import {
  APP_LICENSES,
  checkAppDocument,
  checkAppLogo,
  GALLERY_APP_TYPE,
} from "../packages/domain/src/gallery-apps.ts";
import {
  BOT_LICENSES,
  checkBotDocument,
  checkPluginDocument,
  checkRoutineDocument,
  GALLERY_BOT_TYPE,
  GALLERY_PLUGIN_TYPE,
  GALLERY_ROUTINE_TYPE,
  PLUGIN_ENTRY_LICENSES,
  ROUTINE_LICENSES,
} from "../packages/domain/src/gallery-content.ts";
import { parseSkillMd } from "../packages/domain/src/skill-format.ts";
import { BOT_TEMPLATES } from "../packages/domain/src/templates.ts";

const root = fileURLToPath(new URL("../gallery", import.meta.url));
const checkOnly = process.argv.includes("--check");
// Lucide's icons, so wallpapers can name them as `glyphs` (resolved into doodles in the index).
const lucide = JSON.parse(
  readFileSync(join(root, "assets/lucide/icon-nodes.json"), "utf8"),
) as LucideNodes;

type FolderType =
  | GalleryType
  | typeof GALLERY_APP_TYPE
  | typeof GALLERY_BOT_TYPE
  | typeof GALLERY_ROUTINE_TYPE
  | typeof GALLERY_PLUGIN_TYPE;
/** The look and skill types that index.json carries; every other type has its own file. */
const INDEX_TYPES = new Set<string>(["theme", "scheme", "wallpaper", "skill"]);
/** The one document each newer type's folder holds next to item.json. */
const DOCUMENTS: Record<string, string> = {
  bot: "bot.json",
  routine: "routine.json",
  plugin: "plugin.json",
};
const folders: { dir: string; type: FolderType }[] = [
  { dir: "themes", type: "theme" },
  { dir: "schemes", type: "scheme" },
  { dir: "wallpapers", type: "wallpaper" },
  { dir: "skills", type: "skill" },
  // Vendors' MCP servers (D-239). Built-in apps (packages/domain/src/apps.ts) keep their ids.
  { dir: "apps", type: GALLERY_APP_TYPE },
  // Starter bots, routine ideas and reviewed plugins (D-241).
  { dir: "bots", type: GALLERY_BOT_TYPE },
  { dir: "routines", type: GALLERY_ROUTINE_TYPE },
  { dir: "plugins", type: GALLERY_PLUGIN_TYPE },
];
const builtInBots = new Set(BOT_TEMPLATES.map((t) => t.id));
const builtInApps = new Set(APP_CATALOG.map((a) => a.id));

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
    const licenses =
      type === "skill"
        ? SKILL_LICENSES
        : type === GALLERY_APP_TYPE
          ? APP_LICENSES
          : type === GALLERY_BOT_TYPE
            ? BOT_LICENSES
            : type === GALLERY_ROUTINE_TYPE
              ? ROUTINE_LICENSES
              : type === GALLERY_PLUGIN_TYPE
                ? PLUGIN_ENTRY_LICENSES
                : LOOK_LICENSES;
    const parsed = parseGalleryMeta(metaJson, licenses);
    for (const e of parsed.errors) errors.push(`${where}: ${e}`);
    if (!parsed.meta) continue;
    if (type === "skill" && !parsed.meta.category)
      errors.push(`${where}: a skill needs a category`);

    // What a gallery card needs to draw its preview, so a list needs no request per item.
    let document: unknown;
    let description: string | undefined;
    let requires: string[] = [];
    const docName = DOCUMENTS[type];
    if (docName) {
      if (type === GALLERY_BOT_TYPE && builtInBots.has(id))
        errors.push(
          `${where}: ${id} is a built-in starter bot; change it in packages/domain/src/templates.ts`,
        );
      for (const f of files)
        if (f.relative !== "item.json" && f.relative !== docName)
          errors.push(`${where}: ${f.relative} isn't allowed (only item.json and ${docName})`);
      const doc = files.find((f) => f.relative === docName);
      if (!doc) {
        errors.push(`${where}: missing ${docName}`);
        continue;
      }
      let json: unknown;
      try {
        json = JSON.parse(doc.bytes.toString("utf8"));
      } catch {
        errors.push(`${where}: ${docName} is not JSON`);
        continue;
      }
      const checked =
        type === GALLERY_BOT_TYPE
          ? checkBotDocument(json)
          : type === GALLERY_ROUTINE_TYPE
            ? checkRoutineDocument(json)
            : checkPluginDocument(json);
      for (const e of checked.errors) errors.push(`${where}: ${e}`);
      document = checked.doc;
      description = checked.doc?.description;
    } else if (type === GALLERY_APP_TYPE) {
      if (builtInApps.has(id) || builtInApps.has(id.replaceAll("-", "_")))
        errors.push(`${where}: ${id} is a built-in app; change it in packages/domain/src/apps.ts`);
      for (const f of files)
        if (f.relative !== "item.json" && f.relative !== "app.json" && f.relative !== "logo.svg")
          errors.push(`${where}: ${f.relative} isn't allowed (only item.json, app.json, logo.svg)`);
      const doc = files.find((f) => f.relative === "app.json");
      if (!doc) {
        errors.push(`${where}: missing app.json`);
        continue;
      }
      let json: unknown;
      try {
        json = JSON.parse(doc.bytes.toString("utf8"));
      } catch {
        errors.push(`${where}: app.json is not JSON`);
        continue;
      }
      const checked = checkAppDocument(json);
      for (const e of checked.errors) errors.push(`${where}: ${e}`);
      document = checked.doc;
      description = checked.doc?.description;
      const logo = files.find((f) => f.relative === "logo.svg");
      if (logo)
        for (const e of checkAppLogo(logo.bytes.toString("utf8"), logo.bytes.byteLength))
          errors.push(`${where}: ${e}`);
    } else if (type === "theme" || type === "scheme" || type === "wallpaper") {
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
          ? checkThemeDocument(json, { lucide })
          : type === "scheme"
            ? checkSchemeDocument(json)
            : checkWallpaperDocument(
                json,
                files.map((f) => ({ path: f.relative, bytes: f.bytes.byteLength })),
                { lucide },
              );
      for (const e of found) errors.push(`${where}: ${e}`);
      document = galleryIndexDocument(type, json, lucide);
      requires = galleryRequires(type, json);
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
      ...(requires.length ? { requires } : {}),
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

// Apps get their own file (D-239): servers and apps from before apps only read index.json, and
// their parsers know just the four look and skill types.
const typeOf = (i: unknown) => (i as { type: string }).type;
const outputs = [
  { file: "index.json", items: items.filter((i) => INDEX_TYPES.has(typeOf(i))) },
  { file: "apps.json", items: items.filter((i) => typeOf(i) === GALLERY_APP_TYPE) },
  { file: "bots.json", items: items.filter((i) => typeOf(i) === GALLERY_BOT_TYPE) },
  { file: "routines.json", items: items.filter((i) => typeOf(i) === GALLERY_ROUTINE_TYPE) },
  { file: "plugins.json", items: items.filter((i) => typeOf(i) === GALLERY_PLUGIN_TYPE) },
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
    const same =
      createHash("sha256").update(current).digest("hex") ===
      createHash("sha256").update(body).digest("hex");
    if (!same) {
      console.error(`gallery/${out.file} is stale. Run: node scripts/casama-gallery-check.mts`);
      stale = true;
    }
  } else {
    writeFileSync(path, body);
    console.log(`wrote gallery/${out.file} (${out.items.length} items)`);
  }
}
if (stale) process.exit(1);
if (checkOnly) console.log(`gallery ok, ${items.length} items`);
