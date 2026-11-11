import { describe, expect, it } from "vitest";
import {
  checkDoodles,
  checkSchemeColors,
  checkSchemeDocument,
  checkThemeDocument,
  checkWallpaperDocument,
  contrastRatio,
  galleryHash,
  galleryIndexDocument,
  galleryRequires,
  LOOK_LICENSES,
  type LucideNodes,
  parseGalleryMeta,
  resolveGlyphs,
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
    expect(
      checkWallpaperDocument(doc, [
        { path: "dusk.jpg", bytes: 180_000 },
        { path: "thumb.jpg", bytes: 12_000 },
      ]),
    ).toEqual([]);
    expect(
      checkWallpaperDocument(doc, [
        { path: "dusk.jpg", bytes: 180_000 },
        { path: "thumb.jpg", bytes: 300_000 },
      ]),
    ).toEqual(["thumb.jpg is over 200 KB"]);
    expect(checkWallpaperDocument(doc, [{ path: "dusk.jpg", bytes: 180_000 }])).toEqual([
      "missing thumb.jpg",
    ]);
  });

  it("checks a mesh wallpaper's colors, points and fallback palette", () => {
    const mesh = {
      light: [
        "#F1DBFF",
        "#FED3EA",
        "#F9E3F7",
        "#E5D1FE",
        "#F8E1F9",
        "#FFCFE0",
        "#DDDEFF",
        "#F5CAF6",
        "#EAE3FF",
      ],
      dark: [
        "#351C43",
        "#3F102E",
        "#3F253D",
        "#28103E",
        "#3D223F",
        "#3E0A24",
        "#221E47",
        "#310B34",
        "#31234A",
      ],
      points: [
        [0, 0],
        [0.62, 0],
        [1, 0],
        [0, 0.38],
        [0.4, 0.58],
        [1, 0.46],
        [0, 1],
        [0.55, 1],
        [1, 1],
      ],
    };
    const doc = { kind: "mesh", pattern: "none", palette: "casama", intensity: 0.5, mesh };
    expect(checkWallpaperDocument(doc, [])).toEqual([]);
    expect(
      checkWallpaperDocument({ ...doc, mesh: { light: mesh.light, dark: mesh.dark } }, []),
    ).toEqual([]);
    expect(checkWallpaperDocument({ ...doc, palette: "berry" }, [])).toEqual([
      "with a mesh, wallpaper.palette is the fallback and must be one of theme, casama, lavender, cotton, peach, sunset, mint, ocean, forest, graphite",
    ]);
    const tooDark = { ...mesh, light: ["#444444", ...mesh.light.slice(1)] };
    expect(checkWallpaperDocument({ ...doc, mesh: tooDark }, []).join(" ")).toMatch(
      /mesh.light\[0\] #444444 is too dark/,
    );
    const offEdge = { ...mesh, points: [[0.1, 0], ...mesh.points.slice(1)] };
    expect(checkWallpaperDocument({ ...doc, mesh: offEdge }, [])).toEqual([
      "mesh.points[0] must stay on its corner or edge",
    ]);
    expect(
      checkWallpaperDocument({ ...doc, mesh: { ...mesh, dark: mesh.dark.slice(1) } }, []),
    ).toEqual(["mesh.dark must be nine #RRGGBB colors"]);
    expect(checkWallpaperDocument({ ...doc, kind: "pattern" }, [])).toEqual([
      'a wallpaper with a mesh is kind "mesh"',
    ]);
    expect(
      checkThemeDocument({
        v: 2,
        scheme: "plum",
        headingFont: "Fraunces",
        bodyFont: "Figtree",
        wallpaper: { pattern: "clouds", palette: "casama", intensity: 0.4, mesh },
      }),
    ).toEqual([]);
  });

  it("keeps a skill's icon only when it is a Lucide name", () => {
    const meta = {
      name: "Notes",
      author: { name: "Casama" },
      license: "MIT",
      tags: [],
      category: "work",
    };
    expect(parseGalleryMeta({ ...meta, icon: "notebook-pen" }, ["MIT"]).meta?.icon).toBe(
      "notebook-pen",
    );
    expect(parseGalleryMeta({ ...meta, icon: "<svg>" }, ["MIT"]).errors).toEqual([
      "icon must be a Lucide icon name such as notebook-pen",
    ]);
  });

  describe("doodles", () => {
    const lucide: LucideNodes = {
      cloud: [
        ["path", { d: "M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z", key: "p7xjir" }],
      ],
      star: [["polygon", { points: "12 2 15 9 22 9 16 14 18 21 12 17 6 21 8 14 2 9 9 9" }]],
    };
    const base = { kind: "pattern", pattern: "clouds", palette: "casama", intensity: 0.5 };
    const errorsOf = (raw: unknown) => {
      const errors: string[] = [];
      checkDoodles(raw, errors);
      return errors;
    };

    it("accepts every tag, with numbers or numeric strings", () => {
      expect(
        errorsOf([
          [["path", { d: "M3 14c2-4 4-4 6 0s4 4 6 0" }]],
          [
            ["circle", { cx: 12, cy: "9", r: 3 }],
            ["line", { x1: 12, y1: 15.5, x2: "12", y2: 22 }],
          ],
          [["ellipse", { cx: 12, cy: 12, rx: 8, ry: 4 }]],
          [["rect", { x: 5, y: 5, width: 14, height: 14, rx: 4 }]],
          [["polyline", { points: "3 6 9 12 15 6" }]],
          [["polygon", { points: "12,3 21,20 3,20" }]],
        ]),
      ).toEqual([]);
    });

    it("rejects each kind of malformed doodle", () => {
      expect(errorsOf([])).toEqual(["doodles must be 1 to 24 drawings"]);
      expect(errorsOf(Array(25).fill([["circle", { cx: 1, cy: 1, r: 1 }]]))).toEqual([
        "doodles must be 1 to 24 drawings",
      ]);
      expect(errorsOf([Array(17).fill(["circle", { cx: 1, cy: 1, r: 1 }])])).toEqual([
        "doodles[0] must be 1 to 16 elements",
      ]);
      expect(errorsOf([[["image", { href: "x" }]]])[0]).toMatch(/tag must be one of/);
      expect(errorsOf([[["circle", { cx: 1, cy: 1, r: 1, fill: "red" }]]])).toEqual([
        "doodles[0][0] circle can't have fill",
      ]);
      expect(errorsOf([[["circle", { cx: 1, cy: 1 }]]])).toEqual(["doodles[0][0] circle needs r"]);
      expect(errorsOf([[["circle", { cx: 40, cy: 1, r: 1 }]]])).toEqual([
        "doodles[0][0] cx must be a number between -2 and 26",
      ]);
      expect(errorsOf([[["circle", { cx: 1, cy: 1, r: -1 }]]])).toEqual([
        "doodles[0][0] r must be a number between 0 and 26",
      ]);
      expect(errorsOf([[["path", { d: "M0 0<script>" }]]])[0]).toMatch(/d must be/);
      expect(errorsOf([[["path", { d: `M${"1 ".repeat(800)}` }]]])[0]).toMatch(/d must be/);
      expect(errorsOf([[["polyline", { points: "1 2 3" }]]])[0]).toMatch(/even count/);
      expect(errorsOf([["circle"]])).toEqual(["doodles[0][0] must be [tag, attributes]"]);
    });

    it("checks glyph names against Lucide and refuses glyphs with doodles", () => {
      expect(
        checkWallpaperDocument({ ...base, glyphs: ["cloud", "star"] }, [], { lucide }),
      ).toEqual([]);
      expect(
        checkWallpaperDocument({ ...base, glyphs: ["cloud", "unicorn"] }, [], { lucide }),
      ).toEqual(["glyphs[1] unicorn isn't a Lucide icon"]);
      expect(checkWallpaperDocument({ ...base, glyphs: [] }, [], { lucide })).toEqual([
        "glyphs must be 1 to 24 Lucide icon names",
      ]);
      expect(
        checkWallpaperDocument(
          { ...base, glyphs: ["cloud"], doodles: [[["circle", { cx: 1, cy: 1, r: 1 }]]] },
          [],
          {
            lucide,
          },
        ),
      ).toEqual(["wallpaper has glyphs and doodles; give one"]);
      expect(
        checkWallpaperDocument({ ...base, doodles: [[["circle", { cx: 1, cy: 1, r: 1 }]]] }, []),
      ).toEqual([]);
    });

    it("resolves glyphs into doodles for the index, without Lucide's keys", () => {
      expect(resolveGlyphs(["cloud"], lucide)).toEqual([
        [["path", { d: "M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z" }]],
      ]);
      const doc = galleryIndexDocument("wallpaper", { ...base, glyphs: ["star"] }, lucide) as {
        glyphs: string[];
        doodles: unknown[];
      };
      expect(doc.glyphs).toEqual(["star"]);
      expect(doc.doodles).toEqual(resolveGlyphs(["star"], lucide));
      const theme = galleryIndexDocument(
        "theme",
        { v: 2, wallpaper: { ...base, glyphs: ["cloud"] } },
        lucide,
      ) as {
        wallpaper: { doodles: unknown[] };
      };
      expect(theme.wallpaper.doodles).toHaveLength(1);
      const own = { ...base, doodles: [[["circle", { cx: 1, cy: 1, r: 1 }]]] };
      expect(galleryIndexDocument("wallpaper", own, lucide)).toBe(own);
    });
  });

  describe("full color schemes", () => {
    const light = {
      seed: "#9C3A9E",
      background: "#FCF3FB",
      onBackground: "#201A1E",
      primary: "#9C3A9E",
      primaryContainer: "#FADDF5",
      secondary: "#B8407F",
      secondaryContainer: "#FFD9EA",
      tertiary: "#5562CF",
      tertiaryContainer: "#E0E2FF",
      appBar: "#FCF3FB",
    };
    const dark = {
      seed: "#F2B0EC",
      background: "#211920",
      onBackground: "#EBDFE6",
      primary: "#F2B0EC",
      primaryContainer: "#6B1F69",
      secondary: "#FFB1D4",
      secondaryContainer: "#7A2152",
      tertiary: "#BDC2FF",
      tertiaryContainer: "#323C8A",
    };

    it("accepts the Casama colors with and without an app bar", () => {
      expect(checkSchemeDocument({ light, dark })).toEqual([]);
    });

    it("needs all six colors, valid hex and readable pairs", () => {
      const errorsOf = (raw: unknown) => {
        const errors: string[] = [];
        checkSchemeColors("light", raw, errors);
        return errors;
      };
      const { tertiaryContainer: _t, ...missing } = light;
      expect(errorsOf(missing)[0]).toMatch(/must give all of/);
      expect(errorsOf({ ...light, appBar: "plum" })).toEqual([
        "light.appBar must be a #RRGGBB color",
      ]);
      expect(errorsOf({ ...light, primary: "#F0D0F0" })).toEqual([
        "light.primary on background is below WCAG AA (4.5:1)",
      ]);
      expect(errorsOf({ ...light, secondaryContainer: "#6B1F69" })).toEqual([
        "light text on secondaryContainer is below WCAG AA (4.5:1)",
      ]);
      expect(errorsOf({ seed: "#9C3A9E", background: "#FCF3FB", onBackground: "#201A1E" })).toEqual(
        [],
      );
    });

    it("checks a theme's inline scheme colors too", () => {
      const theme = {
        v: 2,
        scheme: { light: { ...light, primary: "#F0D0F0" }, dark },
        headingFont: "Fraunces",
        bodyFont: "Figtree",
        wallpaper: { pattern: "clouds", palette: "casama", intensity: 0.5 },
      };
      expect(checkThemeDocument(theme)).toEqual([
        "scheme.light.primary on background is below WCAG AA (4.5:1)",
      ]);
    });

    it("lists what each look needs", () => {
      expect(galleryRequires("scheme", { light, dark })).toEqual(["scheme-colors"]);
      expect(
        galleryRequires("scheme", { light: { seed: "#9C3A9E" }, dark: { seed: "#F2B0EC" } }),
      ).toEqual([]);
      expect(galleryRequires("wallpaper", { kind: "mesh", mesh: {}, glyphs: ["cloud"] })).toEqual([
        "doodles",
        "mesh",
      ]);
      expect(
        galleryRequires("theme", {
          scheme: { light, dark },
          wallpaper: { doodles: [] },
        }),
      ).toEqual(["doodles", "scheme-colors"]);
      expect(
        galleryRequires("theme", { scheme: "plum", wallpaper: { pattern: "clouds" } }),
      ).toEqual([]);
    });
  });
});
