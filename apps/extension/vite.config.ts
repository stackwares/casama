/**
 * Builds Casama for Chrome into dist/<mode> (D-323): `vite build --mode dev`, `--mode store` or
 * `--mode e2e`; Phase 5 adds `--mode firefox` (Firefox's store build, plan §13) and
 * `--mode firefox-e2e` (its end-to-end build). Edge takes the store build as it is.
 * The manifest is written from src/manifest.ts with the version from package.json.
 */
import { readFileSync, rmSync } from "node:fs";
import { resolve } from "node:path";
import { build, defineConfig, type Plugin } from "vite";
import { type Browser, buildManifest, type Target } from "./src/manifest.ts";

const pkg = JSON.parse(readFileSync(new URL("./package.json", import.meta.url), "utf8")) as {
  version: string;
};

function manifest(target: Target, browser: Browser): Plugin {
  return {
    name: "casama-manifest",
    generateBundle() {
      this.emitFile({
        type: "asset",
        fileName: "manifest.json",
        source: `${JSON.stringify(buildManifest(target, pkg.version, browser), null, 2)}\n`,
      });
    },
  };
}

/**
 * The page kit (src/content/kit.ts) is a content script, which Chrome runs as a classic script: it
 * is built on its own, as one self-contained IIFE, into content.js next to the rest.
 */
function contentScript(target: Target, browser: Browser, outDir: string): Plugin {
  return {
    name: "casama-content-script",
    apply: "build",
    async closeBundle() {
      await build({
        configFile: false,
        logLevel: "warn",
        define: {
          __CASAMA_TARGET__: JSON.stringify(target === "e2e" ? "dev" : target),
          __CASAMA_BROWSER__: JSON.stringify(browser),
        },
        build: {
          outDir,
          emptyOutDir: false,
          target: esTarget(browser),
          minify: target === "store" && browser === "chromium",
          sourcemap: false,
          lib: {
            entry: resolve(import.meta.dirname, "src/content/kit.ts"),
            formats: ["iife"],
            name: "casamaKit",
            fileName: () => "content.js",
          },
        },
      });
    },
  };
}

/**
 * Firefox reads administrators' settings from its own policies file, not a managed schema, and
 * the settings are Act's (G9) apart from the server address and the off switch, which only Chrome's
 * managed storage carries today; so Firefox's build leaves the schema out.
 */
function withoutManaged(outDir: string): Plugin {
  return {
    name: "casama-firefox-no-managed",
    apply: "build",
    closeBundle: () => rmSync(resolve(outDir, "managed_schema.json"), { force: true }),
  };
}

const esTarget = (browser: Browser) => (browser === "firefox" ? "firefox140" : "chrome116");

export default defineConfig(({ mode }) => {
  const browser: Browser = mode.startsWith("firefox") ? "firefox" : "chromium";
  const base = browser === "firefox" ? mode.slice("firefox".length).replace(/^-/, "") : mode;
  const target: Target = base === "e2e" ? "e2e" : base === "dev" ? "dev" : "store";
  if (!["store", "e2e", "dev", "firefox", "firefox-e2e", "firefox-dev"].includes(mode))
    throw new Error(`unknown build mode ${mode}`);
  const outDir = resolve(import.meta.dirname, "dist", mode);
  return {
    root: resolve(import.meta.dirname, "src"),
    publicDir: resolve(import.meta.dirname, "public"),
    base: "",
    define: {
      // The e2e build behaves as the dev build; only its manifest differs.
      __CASAMA_TARGET__: JSON.stringify(target === "e2e" ? "dev" : target),
      __CASAMA_VERSION__: JSON.stringify(pkg.version),
      __CASAMA_BROWSER__: JSON.stringify(browser),
    },
    plugins: [
      manifest(target, browser),
      contentScript(target, browser, outDir),
      ...(browser === "firefox" ? [withoutManaged(outDir)] : []),
    ],
    build: {
      outDir,
      emptyOutDir: true,
      target: esTarget(browser),
      // Minified code is allowed in the Chrome Web Store; obfuscated code isn't (plan §2). Mozilla
      // reviewers read the code, so the Firefox build stays readable (and comes with its source).
      minify: target === "store" && browser === "chromium",
      sourcemap: target !== "store",
      modulePreload: false,
      rollupOptions: {
        input: {
          options: resolve(import.meta.dirname, "src/options/options.html"),
          panel: resolve(import.meta.dirname, "src/panel/panel.html"),
          // Act's ask page and the offscreen audio page: Chrome and Edge only.
          ...(browser === "firefox"
            ? {}
            : {
                offscreen: resolve(import.meta.dirname, "src/offscreen/offscreen.html"),
                ask: resolve(import.meta.dirname, "src/act/ask.html"),
              }),
          live: resolve(import.meta.dirname, "src/live/live.html"),
          background: resolve(import.meta.dirname, "src/background/index.ts"),
        },
        output: {
          entryFileNames: (chunk) =>
            chunk.name === "background" ? "background.js" : "assets/[name]-[hash].js",
          chunkFileNames: "assets/[name]-[hash].js",
          assetFileNames: "assets/[name]-[hash][extname]",
        },
      },
    },
  };
});
