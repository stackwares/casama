/**
 * Lists the owner changes in Admin without a release (docs/REMOTE-CONTENT-PLAN.md): the model
 * catalog and cost tables (D-373), and the browser guard's added sites (D-374). Every save is
 * checked in full and refused with the list of problems; nothing half-valid is stored.
 */
import {
  COMPUTER_RATES,
  GEMINI_LIVE_PRICES,
  MEDIA_PRICES,
  OPENROUTER_IMAGE_PRICES,
  OPENROUTER_VIDEO_PER_SECOND,
  VOICE_PRICES,
} from "@casama/agent";
import { routes } from "@casama/contracts";
import {
  builtInModelCatalog,
  type CostTables,
  checkCostTables,
  checkGuardAdditions,
  checkModelCatalog,
  SENSITIVE_SITE_HOSTS,
} from "@casama/domain";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import {
  domainSaleSettings,
  saveCostTables,
  saveGuardSites,
  saveModelCatalog,
  storedCostTables,
  storedGuardSites,
  storedModelCatalog,
  TLD,
} from "../../services/remote-settings.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { instanceOwnerCheck } from "./admin.ts";
import { requireClaims } from "./autonomy.ts";

/** The prices in code, in the setting's shape: what Admin shows next to the saved values. */
export function builtInCostTables(): CostTables {
  return {
    voice: {
      stt_per_minute: VOICE_PRICES.sttPerMinute,
      gemini_tts_per_thousand_chars: VOICE_PRICES.geminiTtsPerThousandChars,
      gemini_live_per_minute: VOICE_PRICES.geminiLivePerMinute,
    },
    gemini_live: {
      input_audio: GEMINI_LIVE_PRICES.inputAudio,
      input_text: GEMINI_LIVE_PRICES.inputText,
      input_image: GEMINI_LIVE_PRICES.inputImage,
      output_audio: GEMINI_LIVE_PRICES.outputAudio,
      output_text: GEMINI_LIVE_PRICES.outputText,
    },
    computers: Object.fromEntries(Object.entries(COMPUTER_RATES).map(([k, r]) => [k, { ...r }])),
    media: {
      image: MEDIA_PRICES.image,
      video_per_second: MEDIA_PRICES.videoPerSecond,
      openrouter_video_per_second: OPENROUTER_VIDEO_PER_SECOND,
    },
  };
}

/** A refused save names its first problems. */
function refuse(errors: string[]): never {
  const shown = errors.slice(0, 8).join("; ");
  throw new ApiError(
    400,
    "validation_failed",
    errors.length > 8 ? `${shown}; and ${errors.length - 8} more` : shown,
  );
}

export function registerRemoteSettingsRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db, env } = deps;
  const requireOwner = instanceOwnerCheck(deps);

  // ------------------------------------------------------------- model catalog (#1)

  const catalogOut = async () => ({
    catalog: (await storedModelCatalog(db)) as Record<string, unknown>,
    built_in: {
      ...builtInModelCatalog(),
      image_prices: { ...OPENROUTER_IMAGE_PRICES },
    } as Record<string, unknown>,
  });

  app.openapi(routes.adminModelCatalog, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    return c.json(await catalogOut(), 200);
  });

  app.openapi(routes.saveModelCatalog, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const { catalog, errors } = checkModelCatalog(c.req.valid("json").catalog);
    if (errors.length) refuse(errors);
    await saveModelCatalog(db, catalog);
    deps.logger.info("model catalog changed", { by: claims.sub, parts: Object.keys(catalog) });
    return c.json(await catalogOut(), 200);
  });

  // ------------------------------------------------------------- cost tables and domains (#11, #12)

  const pricesOut = async () => {
    const sale = await domainSaleSettings(db, env.CASAMA_DOMAINS_TLDS);
    return {
      cost_tables: (await storedCostTables(db)) as Record<string, unknown>,
      built_in: builtInCostTables() as Record<string, unknown>,
      domain_tlds: sale.tlds,
      domain_tlds_saved: sale.tlds_saved,
      domain_cap_first_month: sale.cap_first_month,
      domain_cap_per_month: sale.cap_per_month,
    };
  };

  app.openapi(routes.adminPriceTables, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    return c.json(await pricesOut(), 200);
  });

  app.openapi(routes.savePriceTables, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const b = c.req.valid("json");
    const errors: string[] = [];
    let tables: CostTables | undefined;
    if (b.cost_tables !== undefined) {
      const checked = checkCostTables(b.cost_tables);
      errors.push(...checked.errors);
      tables = checked.tables;
    }
    let tlds: string[] | null | undefined;
    if (b.domain_tlds !== undefined && b.domain_tlds !== null) {
      tlds = [];
      for (const raw of b.domain_tlds) {
        const t = raw.trim().toLowerCase().replace(/^\./, "");
        if (!TLD.test(t)) errors.push(`${raw} isn't a domain ending like com or co.uk`);
        else if (!tlds.includes(t)) tlds.push(t);
      }
      if (!tlds.length)
        errors.push("domain_tlds needs at least one ending (null goes back to the default)");
    } else if (b.domain_tlds === null) tlds = null;
    if (errors.length) refuse(errors);
    if (tables) await saveCostTables(db, tables, claims.sub);
    if (
      tlds !== undefined ||
      b.domain_cap_first_month !== undefined ||
      b.domain_cap_per_month !== undefined
    )
      await db.execute(sql`
        update public.billing_settings set
          domain_tlds = case when ${tlds !== undefined}::boolean then ${tlds === undefined || tlds === null ? null : `{${tlds.join(",")}}`}::text[] else domain_tlds end,
          domain_cap_first_month = coalesce(${b.domain_cap_first_month ?? null}::int, domain_cap_first_month),
          domain_cap_per_month = coalesce(${b.domain_cap_per_month ?? null}::int, domain_cap_per_month),
          updated_at = now(), updated_by = ${claims.sub}::uuid
        where id`);
    deps.logger.info("price tables changed", {
      by: claims.sub,
      cost_tables: tables ? Object.keys(tables) : undefined,
      domains: tlds !== undefined || b.domain_cap_first_month !== undefined,
    });
    return c.json(await pricesOut(), 200);
  });

  // ------------------------------------------------------------- browser guard (#7)

  // Public: the Chrome extension reads it before anyone signs in, like /v1/app-config.
  app.openapi(routes.getBrowserGuardSites, async (c) => {
    const hosts = await storedGuardSites(db).catch(() => ({}));
    return c.json({ hosts }, 200);
  });

  const guardOut = async () => ({
    hosts: await storedGuardSites(db),
    built_in: Object.fromEntries(
      Object.entries(SENSITIVE_SITE_HOSTS).map(([k, v]) => [k, [...v]]),
    ) as Record<string, string[]>,
  });

  app.openapi(routes.adminBrowserGuard, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    return c.json(await guardOut(), 200);
  });

  app.openapi(routes.saveBrowserGuard, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const { hosts, errors } = checkGuardAdditions(c.req.valid("json").hosts);
    if (errors.length) refuse(errors);
    await saveGuardSites(db, hosts);
    deps.logger.info("browser guard sites changed", {
      by: claims.sub,
      added: Object.values(hosts).reduce((n, l) => n + l.length, 0),
    });
    return c.json(await guardOut(), 200);
  });
}
