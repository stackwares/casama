/**
 * Cards from a page's own structured data (RICH-CARDS-PLAN §4.7): schema.org JSON-LD that recipe,
 * shop, film, book, event and news sites publish. A recipe card from a recipe site then has the
 * site's real ingredients, not a model's retelling. Page text is untrusted: everything is cut short
 * and only known fields are read.
 */
import { LiveDataError, type LiveHttp } from "./core.ts";

type Json = Record<string, unknown>;

const cut = (v: unknown, n = 300): string | undefined => {
  if (typeof v === "number") return String(v);
  if (typeof v !== "string") return undefined;
  const t = v
    .replace(/<[^>]*>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/\s+/g, " ")
    .trim();
  return t ? t.slice(0, n) : undefined;
};
const https = (v: unknown): string | undefined => {
  const u = typeof v === "string" ? v : Array.isArray(v) ? v[0] : (v as Json | undefined)?.url;
  return typeof u === "string" && /^https:\/\/\S+$/.test(u) ? u.slice(0, 1000) : undefined;
};
const types = (o: Json) => (Array.isArray(o["@type"]) ? o["@type"] : [o["@type"]]).map(String);

/** Every JSON-LD object on a page, flattening @graph and lists. */
export function jsonLd(html: string): Json[] {
  const out: Json[] = [];
  const re = /<script[^>]+type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
  for (const m of html.matchAll(re)) {
    try {
      const walk = (v: unknown) => {
        if (Array.isArray(v)) v.forEach(walk);
        else if (v && typeof v === "object") {
          const o = v as Json;
          if (Array.isArray(o["@graph"])) walk(o["@graph"]);
          if (o["@type"]) out.push(o);
        }
      };
      walk(JSON.parse((m[1] ?? "").trim()));
    } catch {
      // A broken block is skipped.
    }
  }
  return out;
}

/** "PT1H15M" → "1 h 15 min". */
export function isoDuration(v: unknown): string | undefined {
  if (typeof v !== "string") return undefined;
  const m = /^P(?:(\d+)D)?T?(?:(\d+)H)?(?:(\d+)M)?/.exec(v);
  if (!m) return undefined;
  const total = (Number(m[1] ?? 0) * 24 + Number(m[2] ?? 0)) * 60 + Number(m[3] ?? 0);
  if (!total) return undefined;
  const h = Math.floor(total / 60);
  const min = total % 60;
  return [h ? `${h} h` : "", min ? `${min} min` : ""].filter(Boolean).join(" ");
}

const FRACTIONS: Record<string, number> = {
  "½": 0.5,
  "¼": 0.25,
  "¾": 0.75,
  "⅓": 0.33,
  "⅔": 0.67,
  "⅛": 0.125,
};
const UNITS =
  /^(kg|g|mg|lb|lbs|oz|l|ml|cups?|tbsp|tablespoons?|tsp|teaspoons?|cloves?|pieces?|cans?|slices?|pinch|bunch)\b\.?/i;

/** "1 ½ cups flour" → {qty: 1.5, unit: "cups", text: "flour"}. */
export function ingredient(line: string): { text: string; qty?: number; unit?: string } {
  const s = line.trim();
  let qty: number | undefined;
  let rest = s;
  // "1 1/2", "1/2", "1.5", "1 ½", "½".
  const frac = /^(?:(\d+)\s+)?(\d+)\/(\d+)\s*/.exec(s);
  const dec = frac ? null : /^(\d+(?:[.,]\d+)?)?\s*([½¼¾⅓⅔⅛])?\s*/.exec(s);
  if (frac && Number(frac[3]) > 0) {
    qty = Number(frac[1] ?? 0) + Number(frac[2]) / Number(frac[3]);
    rest = s.slice(frac[0].length);
  } else if (dec && (dec[1] || dec[2])) {
    qty = (dec[1] ? Number(dec[1].replace(",", ".")) : 0) + (dec[2] ? (FRACTIONS[dec[2]] ?? 0) : 0);
    rest = s.slice(dec[0].length);
  }
  let unit: string | undefined;
  const u = qty !== undefined ? UNITS.exec(rest) : null;
  if (u) {
    unit = u[1]?.toLowerCase();
    rest = rest.slice(u[0].length).trim();
  }
  if (qty === undefined || !rest) return { text: s.slice(0, 200) };
  return { text: rest.slice(0, 200), qty: Math.round(qty * 100) / 100, ...(unit ? { unit } : {}) };
}

/** The best card for a page's structured data, or null when it has none Casama draws. */
export function cardFromLd(items: Json[], pageUrl: string): Record<string, unknown> | null {
  const host = new URL(pageUrl).host.replace(/^www\./, "");
  const source = { name: host, url: pageUrl };
  const pick = (...want: string[]) => items.find((o) => types(o).some((t) => want.includes(t)));
  const rating = (o: Json) => {
    const r = o.aggregateRating as Json | undefined;
    const v = Number(r?.ratingValue);
    return Number.isFinite(v) && v > 0
      ? {
          value: v,
          max: Number(r?.bestRating) || 5,
          count: Number(r?.ratingCount ?? r?.reviewCount) || undefined,
        }
      : undefined;
  };

  const recipe = pick("Recipe");
  if (recipe) {
    const ing = (Array.isArray(recipe.recipeIngredient) ? recipe.recipeIngredient : [])
      .map((x) => cut(x, 200))
      .filter((x): x is string => !!x)
      .slice(0, 60)
      .map(ingredient);
    const steps: string[] = [];
    const walk = (v: unknown) => {
      if (typeof v === "string")
        steps.push(
          ...v
            .split(/\n+/)
            .map((x) => cut(x, 500))
            .filter((x): x is string => !!x),
        );
      else if (Array.isArray(v)) v.forEach(walk);
      else if (v && typeof v === "object") {
        const o = v as Json;
        if (o.itemListElement) walk(o.itemListElement);
        else if (o.text) walk(o.text);
      }
    };
    walk(recipe.recipeInstructions);
    const yieldN = Number(
      String(
        Array.isArray(recipe.recipeYield) ? recipe.recipeYield[0] : (recipe.recipeYield ?? ""),
      ).match(/\d+/)?.[0],
    );
    const kcal = Number(
      String((recipe.nutrition as Json | undefined)?.calories ?? "").match(/\d+/)?.[0],
    );
    if (ing.length && steps.length)
      return {
        component: "Recipe",
        title: cut(recipe.name, 120) ?? "Recipe",
        ...(https(recipe.image) ? { imageUrl: https(recipe.image) } : {}),
        ...(isoDuration(recipe.totalTime ?? recipe.cookTime)
          ? { time: isoDuration(recipe.totalTime ?? recipe.cookTime) }
          : {}),
        ...(yieldN > 0 && yieldN < 100 ? { servings: yieldN } : {}),
        ...(kcal > 0 ? { calories: kcal } : {}),
        ingredients: ing,
        steps: steps.slice(0, 40),
        url: pageUrl,
        source,
      };
  }

  const media = pick(
    "Movie",
    "TVSeries",
    "Book",
    "MusicAlbum",
    "VideoGame",
    "PodcastSeries",
    "SoftwareApplication",
    "MobileApplication",
  );
  if (media) {
    const t = types(media);
    const kind = t.includes("Movie")
      ? "movie"
      : t.includes("TVSeries")
        ? "show"
        : t.includes("Book")
          ? "book"
          : t.includes("MusicAlbum")
            ? "album"
            : t.includes("VideoGame")
              ? "game"
              : t.includes("PodcastSeries")
                ? "podcast"
                : "app";
    const r = rating(media);
    const who = (media.author ?? media.director ?? media.byArtist) as Json | Json[] | undefined;
    const names = (Array.isArray(who) ? who : who ? [who] : [])
      .map((x) => cut(x.name, 60))
      .filter(Boolean)
      .slice(0, 3)
      .join(", ");
    return {
      component: "Media",
      kind,
      title: cut(media.name, 120) ?? host,
      ...(names ? { subtitle: names } : {}),
      ...(https(media.image) ? { imageUrl: https(media.image) } : {}),
      ...(cut(media.datePublished ?? media.dateCreated, 10)?.slice(0, 4)
        ? { year: cut(media.datePublished ?? media.dateCreated, 10)?.slice(0, 4) }
        : {}),
      ...(r ? { rating: Math.min(r.value, r.max), ratingMax: r.max } : {}),
      ...(cut(media.description, 600) ? { text: cut(media.description, 600) } : {}),
      url: pageUrl,
      source,
    };
  }

  const product = pick("Product");
  if (product) {
    const offers = (Array.isArray(product.offers) ? product.offers[0] : product.offers) as
      | Json
      | undefined;
    const r = rating(product);
    const price = offers?.price ?? (offers as Json | undefined)?.lowPrice;
    return {
      component: "Results",
      layout: "list",
      items: [
        {
          title: cut(product.name, 120) ?? host,
          ...(cut((product.brand as Json | undefined)?.name ?? product.brand, 60)
            ? { subtitle: cut((product.brand as Json | undefined)?.name ?? product.brand, 60) }
            : {}),
          ...(https(product.image) ? { imageUrl: https(product.image) } : {}),
          ...(price !== undefined
            ? { price: `${cut(offers?.priceCurrency, 5) ?? ""} ${cut(price, 20)}`.trim() }
            : {}),
          ...(r ? { rating: Math.min(5, (r.value / r.max) * 5) } : {}),
          ...(r?.count ? { reviews: r.count } : {}),
          url: pageUrl,
          badge: cut(
            String(offers?.availability ?? "")
              .split("/")
              .pop(),
            20,
          ),
        },
      ],
    };
  }

  const event = pick("Event", "MusicEvent", "SportsEvent", "TheaterEvent", "Festival");
  if (event && typeof event.startDate === "string") {
    const loc = event.location as Json | undefined;
    return {
      component: "Event",
      title: cut(event.name, 120) ?? host,
      start: event.startDate.slice(0, 25),
      ...(typeof event.endDate === "string" ? { end: event.endDate.slice(0, 25) } : {}),
      ...(cut(loc?.name ?? loc, 200) ? { location: cut(loc?.name ?? loc, 200) } : {}),
      ...(cut(event.description, 600) ? { description: cut(event.description, 600) } : {}),
      actions: false,
    };
  }

  const thing = pick(
    "NewsArticle",
    "Article",
    "BlogPosting",
    "Person",
    "Organization",
    "LocalBusiness",
    "Restaurant",
    "Place",
    "TouristAttraction",
  );
  if (thing) {
    const addr = thing.address as Json | string | undefined;
    const address =
      typeof addr === "string"
        ? cut(addr, 200)
        : cut(
            [addr?.streetAddress, addr?.addressLocality, addr?.addressCountry]
              .filter((x) => typeof x === "string")
              .join(", "),
            200,
          );
    const facts = [
      address && { label: "Address", value: address },
      cut(thing.telephone, 40) && { label: "Phone", value: cut(thing.telephone, 40) },
      cut(
        Array.isArray(thing.openingHours) ? thing.openingHours.join(", ") : thing.openingHours,
        120,
      ) && {
        label: "Hours",
        value: cut(
          Array.isArray(thing.openingHours) ? thing.openingHours.join(", ") : thing.openingHours,
          120,
        ),
      },
      cut(thing.priceRange, 20) && { label: "Price", value: cut(thing.priceRange, 20) },
      cut(thing.datePublished, 10) && { label: "Published", value: cut(thing.datePublished, 10) },
      rating(thing) && {
        label: "Rating",
        value: `${rating(thing)?.value} / ${rating(thing)?.max}`,
      },
    ].filter(Boolean);
    const text = cut(thing.description ?? thing.abstract ?? thing.headline, 900);
    if (!text && !facts.length) return null;
    return {
      component: "Summary",
      title: cut(thing.headline ?? thing.name, 160) ?? host,
      ...(https(thing.image ?? thing.logo) ? { imageUrl: https(thing.image ?? thing.logo) } : {}),
      text: text ?? "",
      ...(facts.length ? { facts } : {}),
      url: pageUrl,
      source,
    };
  }
  return null;
}

export async function pageCard(http: LiveHttp, url: string) {
  let u: URL;
  try {
    u = new URL(url);
  } catch {
    throw new LiveDataError("bad_url", "That isn't a web address.");
  }
  if (u.protocol !== "https:" && u.protocol !== "http:")
    throw new LiveDataError("bad_url", "Only web pages can be read.");
  const html = await http.text(u.toString(), {
    headers: { accept: "text/html,application/xhtml+xml" },
  });
  const card = cardFromLd(jsonLd(html.slice(0, 3_000_000)), u.toString());
  if (!card)
    throw new LiveDataError(
      "no_structured_data",
      "That page has no recipe, product, film, book, event or article data to make a card from; read it with web.fetch instead.",
    );
  return card;
}
