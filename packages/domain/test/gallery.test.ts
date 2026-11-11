import { describe, expect, it } from "vitest";
import {
  checkSchemeDocument,
  checkThemeDocument,
  checkWallpaperDocument,
  contrastRatio,
  galleryHash,
  LOOK_LICENSES,
  parseGalleryMeta,
} from "../src/gallery.ts";

describe("gallery", () => {
  it("measures WCAG contrast", () => {
    expect(contrastRatio("#000000", "#FFFFFF")).toBeGreaterThan(20);
    expect(contrastRatio("#777777", "#888888")).toBeLessThan(4.5);
  });

  it("rejects a scheme whose text is too faint", () => {
    const errors = checkSchemeDocument({
      light: { seed: "#888888", background: "#888888", onBackground: "#999999" },
      dark: { seed: "#8FE8E2", background: "#0C2428", onBackground: "#E7F6F5" },
    });
    expect(errors.some((e) => e.includes("WCAG"))).toBe(true);
  });

  it("accepts the lagoon theme and hashes files in path order", () => {
    expect(
      checkThemeDocument({
        v: 2,
        scheme: {
          light: { seed: "#0E6E78", background: "#F4FBFC", onBackground: "#102226" },
          dark: { seed: "#8FE8E2", background: "#0C2428", onBackground: "#E7F6F5" },
        },
        headingFont: "Fraunces",
        bodyFont: "Figtree",
        wallpaper: { pattern: "sea", palette: "ocean", intensity: 0.5 },
      }),
    ).toEqual([]);
    const a = new TextEncoder().encode("a");
    const b = new TextEncoder().encode("b");
    expect(
      galleryHash([
        { path: "b", bytes: b },
        { path: "a", bytes: a },
      ]),
    ).toBe(
      galleryHash([
        { path: "a", bytes: a },
        { path: "b", bytes: b },
      ]),
    );
  });

  it("requires an author and a look license", () => {
    const parsed = parseGalleryMeta({ name: "Lagoon", license: "MIT", tags: [] }, LOOK_LICENSES);
    expect(parsed.errors.join(" ")).toMatch(/license|author/);
  });

  it("checks an image wallpaper's small copy for cards", () => {
    const doc = { kind: "image", file: "dusk.jpg", thumb: "thumb.jpg" };
    expect(checkWallpaperDocument(doc, [{ path: "dusk.jpg", bytes: 180_000 }, { path: "thumb.jpg", bytes: 12_000 }])).toEqual([]);
    expect(checkWallpaperDocument(doc, [{ path: "dusk.jpg", bytes: 180_000 }, { path: "thumb.jpg", bytes: 300_000 }])).toEqual([
      "thumb.jpg is over 200 KB",
    ]);
    expect(checkWallpaperDocument(doc, [{ path: "dusk.jpg", bytes: 180_000 }])).toEqual(["missing thumb.jpg"]);
  });

  it("keeps a skill's icon only when it is a Lucide name", () => {
    const meta = { name: "Notes", author: { name: "Casama" }, license: "MIT", tags: [], category: "work" };
    expect(parseGalleryMeta({ ...meta, icon: "notebook-pen" }, ["MIT"]).meta?.icon).toBe("notebook-pen");
    expect(parseGalleryMeta({ ...meta, icon: "<svg>" }, ["MIT"]).errors).toEqual([
      "icon must be a Lucide icon name such as notebook-pen",
    ]);
  });
});
