// SPDX-License-Identifier: Apache-2.0
// A shared format, also used by the Apache-2.0 SDKs and tools (LICENSING.md).
/**
 * Gallery v2 (D-315): the catalog-wide parts of the gallery format. Install questions and their
 * `{{key}}` placeholders, skill tests, starter sets, references between items, authors, and the
 * signed manifest. Pure functions: both checkers and the server use them.
 */
import {
  createHash,
  createPrivateKey,
  createPublicKey,
  generateKeyPairSync,
  type KeyObject,
  sign,
  verify,
} from "node:crypto";
import {
  checkInputValue,
  type GalleryInput,
  type GalleryItemRef,
  type GalleryKind,
  type GalleryMeta,
  isGalleryDate,
} from "./gallery.ts";

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

// ---------------------------------------------------------------- install questions

const PLACEHOLDER = /\{\{\s*([a-z][a-z0-9_]{0,31}(?:\.(?:hour|minute))?)\s*\}\}/g;

/** The placeholder names a text uses: `city`, `time.hour`. */
export function galleryPlaceholders(text: string): string[] {
  return [...text.matchAll(PLACEHOLDER)].map((m) => m[1] as string);
}

/** Fills `{{key}}`, `{{time.hour}}` and `{{time.minute}}` from answers; unknown keys stay. */
export function fillGalleryText(text: string, values: Record<string, string>): string {
  return text.replace(PLACEHOLDER, (whole, name: string) => {
    const [key, part] = name.split(".") as [string, string | undefined];
    const value = values[key];
    if (value === undefined) return whole;
    if (!part) return value;
    const [hh, mm] = value.split(":");
    return String(Number(part === "hour" ? hh : mm));
  });
}

/** The document fields placeholders may appear in, by kind. Cron may only use `time.*`. */
export const GALLERY_TEMPLATE_FIELDS = {
  routine: ["instructions_md", "schedule_cron"],
  bot: ["persona", "starters"],
} as const;

function templateTexts(kind: "routine" | "bot", doc: Record<string, unknown>) {
  const out: { field: string; text: string }[] = [];
  for (const field of GALLERY_TEMPLATE_FIELDS[kind]) {
    const v = doc[field];
    if (typeof v === "string") out.push({ field, text: v });
    else if (Array.isArray(v))
      for (const x of v) if (typeof x === "string") out.push({ field, text: x });
  }
  return out;
}

/** Whether placeholders in a raw document and its inputs match: every one used is asked, every one asked is used. */
export function checkGalleryInputsUsage(
  kind: GalleryKind,
  inputs: GalleryInput[] | undefined,
  rawDocument: unknown,
): string[] {
  if ((kind !== "routine" && kind !== "bot") || !isRecord(rawDocument)) return [];
  const errors: string[] = [];
  const byKey = new Map((inputs ?? []).map((i) => [i.key, i]));
  const used = new Set<string>();
  for (const { field, text } of templateTexts(kind, rawDocument)) {
    for (const name of galleryPlaceholders(text)) {
      const [key, part] = name.split(".") as [string, string | undefined];
      used.add(key);
      const input = byKey.get(key);
      if (!input) errors.push(`{{${name}}} in ${field} has no input`);
      else if (part && (key !== "time" || input.type !== "time"))
        errors.push(`{{${name}}} needs a time input named time`);
      else if (field === "schedule_cron" && !part)
        errors.push(`schedule_cron can only use {{time.minute}} and {{time.hour}}`);
    }
  }
  for (const key of byKey.keys()) if (!used.has(key)) errors.push(`input ${key} isn't used`);
  return errors;
}

/** Each input's default, the answers older servers (and skipped forms) use. */
export function galleryInputDefaults(inputs: GalleryInput[] | undefined): Record<string, string> {
  return Object.fromEntries((inputs ?? []).map((i) => [i.key, i.default]));
}

/** A raw routine or bot document with its placeholders filled. Other kinds come back unchanged. */
export function fillGalleryDocument(
  kind: GalleryKind,
  rawDocument: unknown,
  values: Record<string, string>,
): unknown {
  if ((kind !== "routine" && kind !== "bot") || !isRecord(rawDocument)) return rawDocument;
  const out: Record<string, unknown> = { ...rawDocument };
  for (const field of GALLERY_TEMPLATE_FIELDS[kind]) {
    const v = out[field];
    if (typeof v === "string") out[field] = fillGalleryText(v, values);
    else if (Array.isArray(v))
      out[field] = v.map((x) => (typeof x === "string" ? fillGalleryText(x, values) : x));
  }
  return out;
}

/**
 * Someone's answers checked against the questions: unknown keys and wrong values are errors by key,
 * and unanswered questions take their default.
 */
export function checkGalleryInputValues(
  inputs: GalleryInput[] | undefined,
  given: Record<string, unknown> | undefined,
): { values: Record<string, string>; errors: Record<string, string> } {
  const values: Record<string, string> = {};
  const errors: Record<string, string> = {};
  const list = inputs ?? [];
  for (const key of Object.keys(given ?? {}))
    if (!list.some((i) => i.key === key)) errors[key] = "isn't a question this item asks";
  for (const input of list) {
    const raw = given?.[input.key];
    if (raw === undefined || raw === null || (typeof raw === "string" && raw.trim() === "")) {
      values[input.key] = input.default;
      continue;
    }
    if (typeof raw !== "string") {
      errors[input.key] = "must be text";
      continue;
    }
    const why = checkInputValue(input.type, raw.trim(), input.options);
    if (why) errors[input.key] = why;
    else values[input.key] = raw.trim();
  }
  return { values, errors };
}

// ---------------------------------------------------------------- skill tests

export const GALLERY_TESTS_FILE = "tests.json";

export interface GalleryTestCase {
  prompt: string;
  expect: string;
}

/** A skill's tests.json: 1 to 5 prompts, each with a plain-words rubric a judge model checks. */
export function checkGalleryTests(raw: unknown): { cases?: GalleryTestCase[]; errors: string[] } {
  if (!isRecord(raw) || !Array.isArray(raw.cases))
    return { errors: ['tests.json must be { "cases": [{ "prompt", "expect" }] }'] };
  const errors: string[] = [];
  for (const k of Object.keys(raw)) if (k !== "cases") errors.push(`tests.json can't have ${k}`);
  if (raw.cases.length < 1 || raw.cases.length > 5) errors.push("tests.json needs 1 to 5 cases");
  const cases: GalleryTestCase[] = [];
  raw.cases.forEach((c, i) => {
    const at = `tests.json cases[${i}]`;
    if (!isRecord(c)) {
      errors.push(`${at} must be an object`);
      return;
    }
    for (const k of Object.keys(c))
      if (k !== "prompt" && k !== "expect") errors.push(`${at} can't have ${k}`);
    const prompt = typeof c.prompt === "string" ? c.prompt.trim() : "";
    const expect = typeof c.expect === "string" ? c.expect.trim() : "";
    if (prompt.length < 1 || prompt.length > 500)
      errors.push(`${at}.prompt must be 1 to 500 characters`);
    if (expect.length < 1 || expect.length > 300)
      errors.push(`${at}.expect must be 1 to 300 characters`);
    cases.push({ prompt, expect });
  });
  return errors.length ? { errors } : { cases, errors };
}

export interface GalleryTestedEntry {
  version: number;
  passed: boolean;
  date: string;
}

/** gallery/tested.json, as the test runner writes it. Bad entries are errors. */
export function parseGalleryTested(raw: unknown): {
  tested: Record<string, GalleryTestedEntry>;
  errors: string[];
} {
  const tested: Record<string, GalleryTestedEntry> = {};
  const errors: string[] = [];
  if (!isRecord(raw)) return { tested, errors: ["tested.json must be an object"] };
  for (const [id, e] of Object.entries(raw)) {
    if (
      !isRecord(e) ||
      typeof e.version !== "number" ||
      !Number.isInteger(e.version) ||
      e.version < 1 ||
      typeof e.passed !== "boolean" ||
      !isGalleryDate(e.date)
    ) {
      errors.push(`tested.json ${id} must be { version, passed, date }`);
      continue;
    }
    tested[id] = { version: e.version, passed: e.passed, date: e.date };
  }
  return { tested, errors };
}

/** What an index record carries as `tested`: only a pass on the item's current version. */
export function galleryTestedFor(
  tested: Record<string, GalleryTestedEntry>,
  id: string,
  version: number,
): { version: number; date: string } | undefined {
  const e = Object.hasOwn(tested, id) ? tested[id] : undefined;
  return e?.passed && e.version === version ? { version: e.version, date: e.date } : undefined;
}

// ---------------------------------------------------------------- starter sets

export const GALLERY_SET_TYPE = "set" as const;
export const SET_LICENSES = ["CC0-1.0", "CC-BY-4.0"] as const;
/** What a set can hold: every kind but another set. */
export const GALLERY_SET_ITEM_TYPES = [
  "app",
  "skill",
  "routine",
  "bot",
  "theme",
  "scheme",
  "wallpaper",
  "plugin",
] as const;

export interface GallerySetDocument {
  description: string;
  icon: string;
  items: GalleryItemRef[];
}

/** A starter set's set.json: a description, a Lucide icon and 2 to 12 other gallery items. */
export function checkSetDocument(raw: unknown): { doc?: GallerySetDocument; errors: string[] } {
  if (!isRecord(raw)) return { errors: ["set.json must be an object"] };
  const errors: string[] = [];
  for (const k of Object.keys(raw))
    if (!["description", "icon", "items"].includes(k)) errors.push(`set.json can't have ${k}`);
  const description = typeof raw.description === "string" ? raw.description.trim() : "";
  if (description.length < 1 || description.length > 200)
    errors.push("description must be 1 to 200 characters");
  const icon =
    typeof raw.icon === "string" && /^[a-z0-9][a-z0-9-]{0,39}$/.test(raw.icon) ? raw.icon : "";
  if (!icon) errors.push("icon must be a Lucide icon name such as rocket");
  const items: GalleryItemRef[] = [];
  if (!Array.isArray(raw.items) || raw.items.length < 2 || raw.items.length > 12)
    errors.push("items must be 2 to 12 gallery items");
  else
    raw.items.forEach((x, i) => {
      if (
        !isRecord(x) ||
        !GALLERY_SET_ITEM_TYPES.includes(x.type as never) ||
        typeof x.id !== "string" ||
        !/^[a-z0-9][a-z0-9-]{0,62}$/.test(x.id) ||
        Object.keys(x).some((k) => k !== "type" && k !== "id")
      ) {
        errors.push(`items[${i}] must be { "type": ${GALLERY_SET_ITEM_TYPES.join("|")}, "id" }`);
        return;
      }
      if (items.some((y) => y.type === x.type && y.id === x.id))
        errors.push(`items[${i}] ${x.type}/${x.id} is listed twice`);
      items.push({ type: x.type as GalleryKind, id: x.id });
    });
  return errors.length ? { errors } : { doc: { description, icon, items }, errors };
}

// ---------------------------------------------------------------- references between items

export interface GalleryCatalogEntry {
  type: GalleryKind;
  id: string;
  meta: GalleryMeta;
  /** A set's items. */
  setItems?: GalleryItemRef[];
}

/**
 * References that need the whole catalog: `needs` (skills in the gallery; apps in the gallery or
 * built in), `remix_of`, `replaced_by` and a set's items. Errors are prefixed `kind/id: `.
 */
export function checkGalleryRefs(
  entries: GalleryCatalogEntry[],
  builtInAppIds: Iterable<string>,
): string[] {
  const errors: string[] = [];
  const key = (type: string, id: string) => `${type}/${id}`;
  const all = new Map(entries.map((e) => [key(e.type, e.id), e]));
  const builtIn = new Set(builtInAppIds);
  const appOk = (id: string) =>
    builtIn.has(id) || builtIn.has(id.replaceAll("-", "_")) || all.has(key("app", id));
  for (const e of entries) {
    const where = `${e.type}/${e.id}`;
    for (const id of e.meta.needs?.skills ?? [])
      if (!all.has(key("skill", id)))
        errors.push(`${where}: needs skill ${id}, which isn't in the gallery`);
    for (const id of e.meta.needs?.apps ?? [])
      if (!appOk(id))
        errors.push(`${where}: needs app ${id}, which isn't a gallery or built-in app`);
    for (const field of ["remix_of", "replaced_by"] as const) {
      const ref = e.meta[field];
      if (!ref) continue;
      if (ref.type === e.type && ref.id === e.id) errors.push(`${where}: ${field} can't be itself`);
      else if (!all.has(key(ref.type, ref.id)))
        errors.push(`${where}: ${field} ${ref.type}/${ref.id} isn't in the gallery`);
    }
    if (e.meta.replaced_by && !e.meta.retired)
      errors.push(`${where}: replaced_by is only for retired items`);
    for (const ref of e.setItems ?? []) {
      const found = all.get(key(ref.type, ref.id));
      if (!found) errors.push(`${where}: ${ref.type}/${ref.id} isn't in the gallery`);
      else if (found.meta.retired) errors.push(`${where}: ${ref.type}/${ref.id} is retired`);
    }
  }
  return errors;
}

// ---------------------------------------------------------------- authors

export interface GalleryAuthorEntry {
  handle: string;
  name: string;
  url?: string;
  items: { type: GalleryKind; id: string }[];
}

/** An author's page id when they give no handle: their name as lowercase words joined by dashes. */
export function galleryAuthorSlug(name: string): string {
  const slug = name
    .normalize("NFKD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 39)
    .replace(/-+$/, "");
  return slug || "unknown";
}

/**
 * authors.json: items grouped by `author.handle`, else by name slug. Name and link come from the
 * author's first item in kind/id order. Retired items are left out.
 */
export function buildGalleryAuthors(
  items: {
    type: GalleryKind;
    id: string;
    retired?: boolean;
    author: { name: string; url?: string; handle?: string };
  }[],
): { schema: 1; authors: GalleryAuthorEntry[] } {
  const sorted = [...items]
    .filter((i) => !i.retired)
    .sort((a, b) => (a.type === b.type ? cmp(a.id, b.id) : cmp(a.type, b.type)));
  const byHandle = new Map<string, GalleryAuthorEntry>();
  for (const i of sorted) {
    const handle = i.author.handle ?? galleryAuthorSlug(i.author.name);
    let entry = byHandle.get(handle);
    if (!entry) {
      entry = { handle, name: i.author.name, items: [] };
      byHandle.set(handle, entry);
    }
    if (!entry.url && i.author.url) entry.url = i.author.url;
    entry.items.push({ type: i.type, id: i.id });
  }
  const authors = [...byHandle.values()]
    .sort((a, b) => cmp(a.handle, b.handle))
    .map((a) => ({
      handle: a.handle,
      name: a.name,
      ...(a.url ? { url: a.url } : {}),
      items: a.items,
    }));
  return { schema: 1, authors };
}

function cmp(a: string, b: string) {
  return a < b ? -1 : a > b ? 1 : 0;
}

// ---------------------------------------------------------------- the signed manifest

/** The derived files the manifest covers, in order. */
export const GALLERY_MANIFEST_FILES = [
  "index.json",
  "apps.json",
  "bots.json",
  "routines.json",
  "plugins.json",
  "sets.json",
  "authors.json",
  // Hand-written and first-party (D-370): hashed as it is.
  "coding-agents.json",
  // Content lists (D-372).
  "lists.json",
] as const;

export interface GalleryManifest {
  schema: 1;
  created: string;
  files: Record<string, string>;
}

export function sha256Hex(bytes: Uint8Array | string): string {
  return createHash("sha256").update(bytes).digest("hex");
}

/**
 * manifest.json's exact text. `created` is the newest `updated` date in the catalog, so the file
 * only changes when the catalog does and `--check` stays stable.
 */
export function galleryManifestJson(
  files: { name: string; bytes: Uint8Array | string }[],
  created: string,
): string {
  const manifest: GalleryManifest = {
    schema: 1,
    created,
    files: Object.fromEntries(files.map((f) => [f.name, sha256Hex(f.bytes)])),
  };
  return `${JSON.stringify(manifest, null, 2)}\n`;
}

export function parseGalleryManifest(raw: unknown): GalleryManifest | undefined {
  if (!isRecord(raw) || raw.schema !== 1 || typeof raw.created !== "string" || !isRecord(raw.files))
    return;
  const files: Record<string, string> = {};
  for (const [name, hash] of Object.entries(raw.files)) {
    if (typeof hash !== "string" || !/^[0-9a-f]{64}$/.test(hash)) return;
    files[name] = hash;
  }
  return { schema: 1, created: raw.created, files };
}

/** Whether a fetched file matches the manifest. A file the manifest doesn't list fails. */
export function galleryManifestCovers(
  manifest: GalleryManifest,
  name: string,
  bytes: Uint8Array | string,
): boolean {
  const want = Object.hasOwn(manifest.files, name) ? manifest.files[name] : undefined;
  return want !== undefined && want === sha256Hex(bytes);
}

const SPKI_ED25519 = Buffer.from("302a300506032b6570032100", "hex");
const PKCS8_ED25519 = Buffer.from("302e020100300506032b657004220420", "hex");

/** An Ed25519 public key from its base64 raw 32 bytes. */
export function galleryPublicKey(base64: string): KeyObject {
  const raw = Buffer.from(base64.trim(), "base64");
  if (raw.length !== 32) throw new Error("gallery public key must be 32 bytes in base64");
  return createPublicKey({ key: Buffer.concat([SPKI_ED25519, raw]), format: "der", type: "spki" });
}

/** An Ed25519 private key from a PKCS8 PEM or a base64 raw 32-byte seed (GALLERY_SIGNING_KEY). */
export function galleryPrivateKey(value: string): KeyObject {
  const v = value.trim();
  if (v.includes("-----BEGIN")) return createPrivateKey(v);
  const seed = Buffer.from(v, "base64");
  if (seed.length !== 32)
    throw new Error("gallery signing key must be a PKCS8 PEM or a 32-byte seed in base64");
  return createPrivateKey({
    key: Buffer.concat([PKCS8_ED25519, seed]),
    format: "der",
    type: "pkcs8",
  });
}

/** manifest.sig: base64 Ed25519 signature over the exact bytes of manifest.json. */
export function signGalleryManifest(
  manifestBytes: Uint8Array | string,
  privateKey: string,
): string {
  return sign(null, Buffer.from(manifestBytes), galleryPrivateKey(privateKey)).toString("base64");
}

/** Whether manifest.sig is a valid signature of manifest.json by that public key. Never throws. */
export function verifyGalleryManifest(
  manifestBytes: Uint8Array | string,
  signatureBase64: string,
  publicKeyBase64: string,
): boolean {
  try {
    const sig = Buffer.from(signatureBase64.trim(), "base64");
    if (sig.length !== 64) return false;
    return verify(null, Buffer.from(manifestBytes), galleryPublicKey(publicKeyBase64), sig);
  } catch {
    return false;
  }
}

/** A new signing key pair: the private key as PKCS8 PEM and the public key as base64 raw bytes. */
export function generateGalleryKeyPair(): { privateKeyPem: string; publicKeyBase64: string } {
  const { privateKey, publicKey } = generateKeyPairSync("ed25519");
  const spki = publicKey.export({ format: "der", type: "spki" });
  return {
    privateKeyPem: privateKey.export({ format: "pem", type: "pkcs8" }).toString(),
    publicKeyBase64: spki.subarray(spki.length - 32).toString("base64"),
  };
}

/**
 * The raw template fields of a routine or bot with install questions, as index records carry them
 * next to `document` (which has the defaults filled in, for servers from before inputs).
 */
export function galleryTemplateOf(
  kind: GalleryKind,
  rawDocument: unknown,
): Record<string, unknown> | undefined {
  if ((kind !== "routine" && kind !== "bot") || !isRecord(rawDocument)) return;
  const out: Record<string, unknown> = {};
  for (const field of GALLERY_TEMPLATE_FIELDS[kind])
    if (rawDocument[field] !== undefined) out[field] = rawDocument[field];
  return out;
}
