/** The analytics catalog is the contract: names, properties and where events are sent from (ANALYTICS-PLAN §6). */
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { dartCatalog, loadAnalyticsCatalog } from "../src/analytics.ts";

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
});
