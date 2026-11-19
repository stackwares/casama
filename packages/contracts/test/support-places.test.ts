import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { loadSupportPlaces } from "../src/support-places.ts";

const root = fileURLToPath(new URL("../../../", import.meta.url));

describe("support places catalog", () => {
  const places = loadSupportPlaces();

  it("has unique ids and valid routes or https urls", () => {
    const ids = places.map((p) => p.id);
    expect(new Set(ids).size).toBe(ids.length);
    for (const p of places) {
      if (p.route) {
        expect(p.route.startsWith("/"), p.id).toBe(true);
        expect(p.url, p.id).toBeUndefined();
      } else {
        expect(p.url?.startsWith("https://"), p.id).toBe(true);
      }
      if (p.highlights) {
        expect(new Set(p.highlights).size, p.id).toBe(p.highlights.length);
      }
    }
  });

  it("keeps public places free of required params and role gates", () => {
    for (const p of places.filter((x) => x.public)) {
      expect(p.params ?? [], p.id).toEqual([]);
      expect(p.roles ?? [], p.id).toEqual([]);
    }
  });

  it("matches every route prefix against router.dart", () => {
    const router = readFileSync(`${root}client/lib/core/router.dart`, "utf8");
    for (const p of places) {
      if (!p.route) continue;
      const segments = p.route
        .split("/")
        .filter(Boolean)
        .map((seg) => (seg.startsWith("{") ? `:${seg.slice(1, -1)}` : seg));
      for (const seg of segments) {
        if (seg.startsWith(":")) {
          expect(router, `${p.id} param ${seg}`).toContain(seg);
        } else {
          const singleQuoted = `'${seg}'`;
          const slashQuoted = `'/${seg}'`;
          const subQuoted = `/${seg}'`;
          expect(
            router.includes(singleQuoted) ||
              router.includes(slashQuoted) ||
              router.includes(subQuoted),
            `${p.id} segment ${seg} in router.dart`,
          ).toBe(true);
        }
      }
    }
  });

  it("ships in the server image, which reads it at runtime", () => {
    const dockerfile = readFileSync(`${root}apps/server/Dockerfile`, "utf8");
    expect(dockerfile).toMatch(/^COPY packages\/contracts\/support packages\/contracts\/support$/m);
  });
});
