/**
 * Lists that change without an app build (docs/REMOTE-CONTENT-PLAN.md): the model catalog and cost
 * tables (D-373), and the browser guard's added sites (D-374). The stored values are free-form JSON
 * here; the server checks them (packages/domain model-catalog.ts, cost-tables.ts, browser-guard.ts)
 * and refuses a save that doesn't pass.
 */
import { z } from "@hono/zod-openapi";

const Json = z.record(z.string(), z.unknown());

export const AdminModelCatalog = z
  .object({
    catalog: Json.openapi({
      description:
        "What's saved: default_models, small_models, test_models, featured_models, models (price rows), image_prices. Anything left out uses the value in code; {} is all code.",
    }),
    built_in: Json.openapi({ description: "The values in code, in the same shape" }),
  })
  .openapi("AdminModelCatalog");

export const SaveModelCatalogRequest = z
  .object({ catalog: Json })
  .openapi("SaveModelCatalogRequest", {
    description: "Replaces the saved catalog after it's checked",
  });

export const AdminPriceTables = z
  .object({
    cost_tables: Json.openapi({
      description:
        "What's saved: voice, gemini_live, computers, media. A price left out uses the one in code.",
    }),
    built_in: Json.openapi({ description: "The prices in code, in the same shape" }),
    domain_tlds: z.array(z.string()).openapi({
      description: "The endings on sale now (saved, else CASAMA_DOMAINS_TLDS, else code)",
    }),
    domain_tlds_saved: z
      .boolean()
      .openapi({ description: "Whether domain_tlds is the saved list" }),
    domain_cap_first_month: z.number().int(),
    domain_cap_per_month: z.number().int(),
  })
  .openapi("AdminPriceTables");

export const SavePriceTablesRequest = z
  .object({
    cost_tables: Json.optional(),
    domain_tlds: z.array(z.string().max(80)).max(100).nullable().optional().openapi({
      description: "null goes back to CASAMA_DOMAINS_TLDS or the list in code",
    }),
    domain_cap_first_month: z.number().int().min(0).max(1000).optional(),
    domain_cap_per_month: z.number().int().min(0).max(1000).optional(),
  })
  .openapi("SavePriceTablesRequest");

/** Sites the browser guard keeps out on top of its built-in lists (D-374). Never fewer. */
export const BrowserGuardSites = z
  .object({
    hosts: z.record(z.string(), z.array(z.string())).openapi({
      description:
        "Added hosts by kind (banking, health, passwords, government). Kinds this version doesn't know are skipped.",
    }),
  })
  .openapi("BrowserGuardSites");

export const AdminBrowserGuard = z
  .object({
    hosts: z.record(z.string(), z.array(z.string())),
    built_in: z.record(z.string(), z.array(z.string())),
  })
  .openapi("AdminBrowserGuard");

const CallLimitsShape = z.record(z.string(), z.number().int());

export const AdminCallLimits = z
  .object({
    limits: CallLimitsShape.openapi({
      description: "The values the owner saved; any left out use the default",
    }),
    built_in: CallLimitsShape.openapi({ description: "The defaults in code" }),
    in_use: CallLimitsShape.openapi({
      description:
        "What every process uses now: saved values over the defaults, made to fit together",
    }),
    ranges: z.record(z.string(), z.tuple([z.number().int(), z.number().int()])).openapi({
      description: "The lowest and highest value each limit may take",
    }),
  })
  .openapi("AdminCallLimits");

export const SaveCallLimitsRequest = z
  .object({
    limits: z.record(z.string(), z.number().int().nullable()).openapi({
      description:
        "silence_seconds, heartbeat_seconds, abandoned_seconds, max_call_minutes, warning_seconds, ring_daily_cap, ring_cooldown_minutes. Replaces the saved values; a name left out or null uses the default",
    }),
  })
  .openapi("SaveCallLimitsRequest");
