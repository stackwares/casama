/**
 * The model catalog as an admin setting (D-373, docs/REMOTE-CONTENT-PLAN.md #1): default, small and
 * test models per provider, the picker's featured list, price and capability rows, and image
 * prices. The server owner edits it in Admin → Models (`instance_settings` key `model_catalog`);
 * every process loads it every minute. Whatever the setting leaves out, or gets wrong, falls back
 * to the values in code (`models.ts`, the gateway's regex table, the media price list), so an empty
 * setting behaves exactly as before.
 */
import { DEFAULT_MODELS, FEATURED_MODELS, type ModelOption, SMALL_MODELS } from "./models.ts";

/** A price and capability row. `id` matches one model exactly; `pattern` is a regular expression. */
export interface ModelPriceRow {
  id?: string;
  pattern?: string;
  context_window?: number;
  tools?: boolean;
  vision?: boolean;
  caching?: boolean;
  /** USD per million tokens. */
  input_price: number;
  output_price: number;
  cache_read_price?: number;
  cache_write_price?: number;
}

export interface ModelCatalog {
  default_models?: Record<string, string>;
  small_models?: Record<string, string>;
  test_models?: Record<string, string>;
  featured_models?: Record<string, ModelOption[]>;
  models?: ModelPriceRow[];
  /** USD per image, by model id (OpenRouter ids). */
  image_prices?: Record<string, number>;
}

const CATALOG_KEYS = [
  "default_models",
  "small_models",
  "test_models",
  "featured_models",
  "models",
  "image_prices",
] as const;
const ROW_KEYS = [
  "id",
  "pattern",
  "context_window",
  "tools",
  "vision",
  "caching",
  "input_price",
  "output_price",
  "cache_read_price",
  "cache_write_price",
];
const PROVIDER = /^[a-z][a-z0-9_]{0,39}$/;
const MODEL_ID = /^[^\s]{1,200}$/;
/** Highest token price accepted, USD per million: a typo (15000 for 15) is refused on save. */
export const MAX_TOKEN_PRICE = 1000;
export const MAX_IMAGE_PRICE = 5;
const MAX_ROWS = 200;
const MAX_FEATURED = 40;

const isRecord = (v: unknown): v is Record<string, unknown> =>
  typeof v === "object" && v !== null && !Array.isArray(v);
const price = (v: unknown, max: number) =>
  typeof v === "number" && Number.isFinite(v) && v >= 0 && v <= max;

/** Compiles a row's pattern, or null when it isn't a usable regular expression. */
export function catalogPattern(source: string): RegExp | null {
  if (!source || source.length > 200) return null;
  try {
    return new RegExp(source);
  } catch {
    return null;
  }
}

/**
 * Checks a catalog. `catalog` holds every part that passed, so a stored value with one bad entry
 * still applies the rest (and the code fallback covers the bad one); a save is refused when
 * `errors` isn't empty.
 */
export function checkModelCatalog(raw: unknown): { catalog: ModelCatalog; errors: string[] } {
  const errors: string[] = [];
  const catalog: ModelCatalog = {};
  if (raw === undefined || raw === null) return { catalog, errors };
  if (!isRecord(raw)) return { catalog, errors: ["the catalog must be an object"] };
  for (const key of Object.keys(raw))
    if (!(CATALOG_KEYS as readonly string[]).includes(key))
      errors.push(`unknown part ${key} (expected ${CATALOG_KEYS.join(", ")})`);

  const perProvider = (name: "default_models" | "small_models" | "test_models") => {
    const value = raw[name];
    if (value === undefined) return;
    if (!isRecord(value)) {
      errors.push(`${name} must map providers to model ids`);
      return;
    }
    const out: Record<string, string> = {};
    for (const [p, id] of Object.entries(value)) {
      if (!PROVIDER.test(p)) errors.push(`${name}: ${p} isn't a provider id`);
      else if (typeof id !== "string" || !MODEL_ID.test(id))
        errors.push(`${name}.${p} must be a model id`);
      else out[p] = id;
    }
    catalog[name] = out;
  };
  perProvider("default_models");
  perProvider("small_models");
  perProvider("test_models");

  const featured = raw.featured_models;
  if (featured !== undefined) {
    if (!isRecord(featured)) errors.push("featured_models must map providers to lists");
    else {
      const out: Record<string, ModelOption[]> = {};
      for (const [p, list] of Object.entries(featured)) {
        if (!PROVIDER.test(p)) {
          errors.push(`featured_models: ${p} isn't a provider id`);
          continue;
        }
        if (!Array.isArray(list)) {
          errors.push(`featured_models.${p} must be a list of { id, name }`);
          continue;
        }
        if (list.length > MAX_FEATURED)
          errors.push(`featured_models.${p} has more than ${MAX_FEATURED} models`);
        const items: ModelOption[] = [];
        list.slice(0, MAX_FEATURED).forEach((m, i) => {
          const at = `featured_models.${p}[${i}]`;
          if (!isRecord(m) || typeof m.id !== "string" || !MODEL_ID.test(m.id)) {
            errors.push(`${at} needs an id`);
            return;
          }
          const name = typeof m.name === "string" && m.name.trim() ? m.name.trim() : m.id;
          if (name.length > 120) {
            errors.push(`${at}.name is too long`);
            return;
          }
          if (items.some((x) => x.id === m.id)) {
            errors.push(`${at} repeats ${m.id}`);
            return;
          }
          items.push({ id: m.id, name });
        });
        out[p] = items;
      }
      catalog.featured_models = out;
    }
  }

  const rows = raw.models;
  if (rows !== undefined) {
    if (!Array.isArray(rows)) errors.push("models must be a list of price rows");
    else {
      if (rows.length > MAX_ROWS) errors.push(`models has more than ${MAX_ROWS} rows`);
      const out: ModelPriceRow[] = [];
      rows.slice(0, MAX_ROWS).forEach((r, i) => {
        const at = `models[${i}]`;
        if (!isRecord(r)) {
          errors.push(`${at} must be an object`);
          return;
        }
        const before = errors.length;
        for (const k of Object.keys(r))
          if (!ROW_KEYS.includes(k)) errors.push(`${at}: unknown ${k}`);
        const hasId = r.id !== undefined;
        const hasPattern = r.pattern !== undefined;
        if (hasId === hasPattern) errors.push(`${at} needs either id or pattern`);
        if (hasId && (typeof r.id !== "string" || !MODEL_ID.test(r.id)))
          errors.push(`${at}.id must be a model id`);
        if (hasPattern && (typeof r.pattern !== "string" || !catalogPattern(r.pattern)))
          errors.push(`${at}.pattern isn't a regular expression of up to 200 characters`);
        for (const k of ["input_price", "output_price"])
          if (!price(r[k], MAX_TOKEN_PRICE))
            errors.push(`${at}.${k} must be USD per million tokens, 0 to ${MAX_TOKEN_PRICE}`);
        for (const k of ["cache_read_price", "cache_write_price"])
          if (r[k] !== undefined && !price(r[k], MAX_TOKEN_PRICE))
            errors.push(`${at}.${k} must be USD per million tokens, 0 to ${MAX_TOKEN_PRICE}`);
        if (
          r.context_window !== undefined &&
          !(
            Number.isInteger(r.context_window) &&
            (r.context_window as number) >= 1000 &&
            (r.context_window as number) <= 20_000_000
          )
        )
          errors.push(`${at}.context_window must be a whole number of tokens`);
        for (const k of ["tools", "vision", "caching"])
          if (r[k] !== undefined && typeof r[k] !== "boolean")
            errors.push(`${at}.${k} must be true or false`);
        if (errors.length !== before) return;
        const row: ModelPriceRow = {
          input_price: r.input_price as number,
          output_price: r.output_price as number,
        };
        if (hasId) row.id = (r.id as string).toLowerCase();
        if (hasPattern) row.pattern = r.pattern as string;
        for (const k of ["context_window", "cache_read_price", "cache_write_price"] as const)
          if (r[k] !== undefined) row[k] = r[k] as number;
        for (const k of ["tools", "vision", "caching"] as const)
          if (r[k] !== undefined) row[k] = r[k] as boolean;
        out.push(row);
      });
      catalog.models = out;
    }
  }

  const images = raw.image_prices;
  if (images !== undefined) {
    if (!isRecord(images)) errors.push("image_prices must map model ids to USD per image");
    else {
      const out: Record<string, number> = {};
      for (const [id, v] of Object.entries(images)) {
        if (!MODEL_ID.test(id)) errors.push(`image_prices: ${id} isn't a model id`);
        else if (!price(v, MAX_IMAGE_PRICE))
          errors.push(`image_prices.${id} must be USD per image, 0 to ${MAX_IMAGE_PRICE}`);
        else out[id] = v as number;
      }
      catalog.image_prices = out;
    }
  }
  return { catalog, errors };
}

/** What the code ships, in the setting's shape: what Admin shows as the defaults. */
export function builtInModelCatalog(): ModelCatalog {
  return {
    default_models: { ...DEFAULT_MODELS },
    small_models: { ...SMALL_MODELS },
    test_models: builtInTestModels(),
    featured_models: Object.fromEntries(
      Object.entries(FEATURED_MODELS).map(([p, list]) => [p, list.map((m) => ({ ...m }))]),
    ),
  };
}

// ---------------------------------------------------------------- the loaded catalog

let current: ModelCatalog = {};
let compiled: Array<{ row: ModelPriceRow; re: RegExp | null }> = [];

/** Replaces the loaded catalog (the server calls it every minute); bad parts are left out. */
export function setModelCatalog(raw: unknown) {
  current = checkModelCatalog(raw).catalog;
  compiled = (current.models ?? []).map((row) => ({
    row,
    re: row.pattern ? catalogPattern(row.pattern) : null,
  }));
}

export function modelCatalog(): ModelCatalog {
  return current;
}

/** Default model ids per provider: the setting's on top of the code's. */
export function defaultModels(): Readonly<Record<string, string>> {
  return current.default_models ? { ...DEFAULT_MODELS, ...current.default_models } : DEFAULT_MODELS;
}

/**
 * The default model for a provider, if Casama has one (others need the user to pick): an env
 * override (DEFAULT_MODEL_OPENROUTER, DEFAULT_MODEL_OPENAI) first, then the setting, then the code.
 */
export function defaultModelFor(
  provider: string,
  overrides: Partial<Record<string, string | undefined>> = {},
): string | undefined {
  return overrides[provider] || current.default_models?.[provider] || DEFAULT_MODELS[provider];
}

/** A provider's small model for background work (D-187). */
export function smallModelFor(provider: string): string | undefined {
  return current.small_models?.[provider] ?? SMALL_MODELS[provider];
}

/** The picker's featured list for a provider: the setting's list replaces the code's. */
export function featuredModelsFor(provider: string): readonly ModelOption[] {
  return current.featured_models?.[provider] ?? FEATURED_MODELS[provider] ?? [];
}

/**
 * The model a key check calls: the provider's small model (the cheapest that answers), else its
 * default, else the first featured model. Derived, so it can't go stale the way a list did.
 */
function builtInTestModels(): Record<string, string> {
  const out: Record<string, string> = {};
  for (const p of new Set([
    ...Object.keys(DEFAULT_MODELS),
    ...Object.keys(SMALL_MODELS),
    ...Object.keys(FEATURED_MODELS),
  ])) {
    if (p === "chatgpt") continue;
    const id = SMALL_MODELS[p] ?? DEFAULT_MODELS[p] ?? FEATURED_MODELS[p]?.[0]?.id;
    if (id) out[p] = id;
  }
  return out;
}

export function testModelFor(provider: string): string | undefined {
  if (current.test_models?.[provider]) return current.test_models[provider];
  if (provider === "chatgpt") return undefined;
  return smallModelFor(provider) ?? defaultModels()[provider] ?? featuredModelsFor(provider)[0]?.id;
}

/** The catalog's price row for a model id (lower case): an exact id first, then patterns in order. */
export function catalogPriceRow(id: string): ModelPriceRow | undefined {
  if (!compiled.length) return undefined;
  const exact = compiled.find((c) => c.row.id === id);
  if (exact) return exact.row;
  return compiled.find((c) => c.re?.test(id))?.row;
}

/** An image model's price from the setting, if it has one. */
export function catalogImagePrice(model: string): number | undefined {
  return current.image_prices?.[model];
}
