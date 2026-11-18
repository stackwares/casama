{{flutter_js}}
{{flutter_build_config}}

// Phones (Safari, and Chrome and Firefox on iOS) are WebKit. Android Firefox is
// Gecko. Flutter leaves Wasm off for both and would load main.dart.js; we keep
// them on the faster Wasm build. Browsers that lack WasmGC still take the
// JavaScript build (feature detection is unchanged), which app.casama.ai now
// serves from R2 when it is past Cloudflare's 25 MiB asset limit (D-316).
_flutter.loader.load({
  config: {
    wasmAllowList: { blink: true, gecko: true, webkit: true },
    // The renderer (skwasm, or CanvasKit for the JavaScript build) from this site's own canvaskit/
    // folder, which every build ships, rather than www.gstatic.com: no extra connection before the
    // first frame, and a self-hosted server doesn't depend on Google's CDN.
    canvasKitBaseUrl: "canvaskit/",
  },
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
});
