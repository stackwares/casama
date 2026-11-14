{{flutter_js}}
{{flutter_build_config}}

// Phones (Safari, and Chrome and Firefox on iOS) are WebKit. Android Firefox is
// Gecko. Flutter leaves Wasm off for both, so they load main.dart.js instead.
// That file is past Cloudflare's 25 MiB asset limit, so it is never published
// and the single-page fallback serves index.html as the script. The page then
// stays on the launch splash. Browsers that lack WasmGC still take the
// JavaScript build; feature detection is unchanged.
_flutter.loader.load({
  config: {
    wasmAllowList: { blink: true, gecko: true, webkit: true },
  },
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
});
