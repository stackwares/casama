/** The analytics catalog is the contract: names, properties and where events are sent from (ANALYTICS-PLAN §6). */
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import {
  clientEventProperties,
  dartCatalog,
  GA4_RECOMMENDED_EVENTS,
  ga4Twins,
  loadAnalyticsCatalog,
} from "../src/analytics.ts";
import {
  ANALYTICS_CLIENT_EVENTS,
  GA4_CLIENT_TWINS,
  GA4_TWINS,
} from "../src/ga4-twins.generated.ts";

const catalog = loadAnalyticsCatalog();
const root = fileURLToPath(new URL("../../../", import.meta.url));
const SKIP = new Set(["node_modules", ".dart_tool", "build", "dist", ".git", "generated", "test"]);

function sources(dir: string, exts: string[]): string[] {
  const out: string[] = [];
  for (const e of readdirSync(join(root, dir), { withFileTypes: true })) {
    if (SKIP.has(e.name)) continue;
    const rel = `${dir}/${e.name}`;
    if (e.isDirectory()) out.push(...sources(rel, exts));
    else if (exts.some((x) => e.name.endsWith(x)) && !e.name.endsWith(".g.dart"))
      out.push(readFileSync(join(root, rel), "utf8"));
  }
  return out;
}

const clientSource = sources("client/lib", [".dart"]).join("\n");
const serverSource = [
  ...sources("apps/server/src", [".ts"]),
  ...sources("packages/agent/src", [".ts"]),
].join("\n");

describe("analytics catalog", () => {
  it("has legal, unique, permanent-looking names", () => {
    const names = catalog.events.map((e) => e.name);
    expect(new Set(names).size).toBe(names.length);
    for (const n of names) {
      expect(n, n).toMatch(/^[a-z][a-z0-9_]{0,39}$/);
      expect(n, n).not.toMatch(/^(firebase_|google_|ga_)/);
    }
  });

  it("fits Google Analytics 4's rules, so every event can also go there (D-397)", () => {
    // Names GA4 (Firebase) reserves for its own automatic events.
    const reserved = new Set([
      "ad_activeview",
      "ad_click",
      "ad_exposure",
      "ad_impression",
      "ad_query",
      "ad_reward",
      "adunit_exposure",
      "app_background",
      "app_clear_data",
      "app_exception",
      "app_remove",
      "app_store_refund",
      "app_store_subscription_cancel",
      "app_store_subscription_convert",
      "app_store_subscription_renew",
      "app_update",
      "app_upgrade",
      "dynamic_link_app_open",
      "dynamic_link_app_update",
      "dynamic_link_first_open",
      "error",
      "first_open",
      "first_visit",
      "in_app_purchase",
      "notification_dismiss",
      "notification_foreground",
      "notification_open",
      "notification_receive",
      "os_update",
      "session_start",
      "session_start_with_rollout",
      "screen_view",
      "user_engagement",
    ]);
    // Super properties the GA4 sinks add on top of an event's own (app, environment, source, platform,
    // server_version, workspace_id) leave 19 of GA4's 25 params per event.
    for (const e of catalog.events) {
      expect(reserved.has(e.name), e.name).toBe(false);
      const keys = Object.keys(e.properties ?? {}).filter((k) => !k.includes("*"));
      if (e.name !== "usage_daily" && e.name !== "workspace_daily")
        expect(keys.length, e.name).toBeLessThanOrEqual(19);
      for (const k of keys) {
        expect(k.length, `${e.name}.${k}`).toBeLessThanOrEqual(40);
        expect(k, `${e.name}.${k}`).not.toMatch(/^(firebase_|google_|ga_)/);
      }
    }
  });

  it("never lets a property carry content, and keeps keys snake_case with closed enums", () => {
    for (const e of catalog.events)
      for (const [key, prop] of Object.entries(e.properties)) {
        const k = key.replace(/_\*$/, "");
        expect(k, `${e.name}.${key}`).toMatch(/^[a-z][a-z0-9_]*$/);
        // A flag or a count can't carry content, so a server-only one may mention a word (email_sent); the app's
        // scrubber would drop such a key, so on the client the words are never allowed.
        const harmless = e.by.length === 1 && e.by[0] === "server" && prop.type !== "string";
        if (!harmless)
          for (const w of catalog.forbidden_property_words)
            expect(k.split("_"), `${e.name}.${key} contains "${w}"`).not.toContain(w);
        if (prop.values) {
          expect(prop.type).toBe("string");
          expect(prop.values.length).toBeGreaterThan(0);
          expect(new Set(prop.values).size).toBe(prop.values.length);
        }
      }
  });

  it("every event the code sends is in the catalog", () => {
    const known = new Set(catalog.events.map((e) => e.name));
    const used = new Set<string>();
    for (const m of serverSource.matchAll(
      /(?:track|capture)\([^{]*\{\s*event:\s*"([a-z][a-z0-9_]*)"/g,
    ))
      used.add(m[1] as string);
    for (const m of clientSource.matchAll(/Analytics\.(?:capture|log)\(\s*'([a-z][a-z0-9_]*)'/g))
      used.add(m[1] as string);
    for (const n of used) expect(known.has(n), `"${n}" is sent but not in the catalog`).toBe(true);
    expect(used.size).toBeGreaterThan(30);
  });

  it("every catalog event is sent from the side it says", () => {
    for (const e of catalog.events) {
      const quoted = new RegExp(`['"]${e.name}['"]`);
      if (e.by.includes("client"))
        expect(quoted.test(clientSource), `${e.name} (client)`).toBe(true);
      if (e.by.includes("server"))
        expect(quoted.test(serverSource), `${e.name} (server)`).toBe(true);
    }
  });

  it("the app's generated allowlist is current", () => {
    const file = readFileSync(join(root, "client/lib/core/analytics_events.g.dart"), "utf8");
    expect(file, "run `pnpm gen` after changing analytics/catalog.json").toBe(dartCatalog(catalog));
  });

  it("GA4 twins are recommended events built from the event's own properties (D-398)", () => {
    const names = new Set(catalog.events.map((e) => e.name));
    for (const [event, twin] of Object.entries(ga4Twins(catalog))) {
      const e = catalog.events.find((x) => x.name === event)!;
      expect(GA4_RECOMMENDED_EVENTS as readonly string[], event).toContain(twin.name);
      // A twin never shadows a catalog event (purchase is mapped in the server sink, not twinned).
      expect(names.has(twin.name), event).toBe(false);
      for (const p of twin.params) expect(Object.keys(e.properties), `${event}.${p}`).toContain(p);
    }
    const server = Object.fromEntries(
      Object.entries(ga4Twins(catalog)).filter(([n]) =>
        catalog.events.find((e) => e.name === n)!.by.includes("server"),
      ),
    );
    expect(GA4_TWINS, "run `pnpm gen` after changing analytics/catalog.json").toEqual(server);
    expect(ANALYTICS_CLIENT_EVENTS, "run `pnpm gen`").toEqual(clientEventProperties(catalog));
    const client = Object.fromEntries(
      Object.entries(ga4Twins(catalog)).filter(([n]) =>
        catalog.events.find((e) => e.name === n)!.by.includes("client"),
      ),
    );
    expect(GA4_CLIENT_TWINS, "run `pnpm gen`").toEqual(client);
  });
});
