{{flutter_js}}
{{flutter_build_config}}

// File sizes for the loading screen's progress bar (web/boot.js). scripts/build-web.sh replaces
// the next line with casamaBoot.files({...}); a build made any other way shows the bar without a
// percentage.
/* casama-boot-files */

(function () {
  var boot = window.casamaBoot || { step: function () {}, fail: function (e) { console.error(e); } };

  // Phones (Safari, and Chrome and Firefox on iOS) are WebKit. Android Firefox is
  // Gecko. Flutter leaves Wasm off for both and would load main.dart.js; we keep
  // them on the faster Wasm build. Browsers that lack WasmGC still take the
  // JavaScript build (feature detection is unchanged), which app.casama.ai now
  // serves from R2 when it is past Cloudflare's 25 MiB asset limit (D-316).
  var config = {
    wasmAllowList: { blink: true, gecko: true, webkit: true },
    // The renderer (skwasm, or CanvasKit for the JavaScript build) from this site's own canvaskit/
    // folder, which every build ships, rather than www.gstatic.com: no extra connection before the
    // first frame, and a self-hosted server doesn't depend on Google's CDN.
    canvasKitBaseUrl: "canvaskit/",
  };

  try {
    _flutter.loader.load({
      config: config,
      serviceWorkerSettings: {
        serviceWorkerVersion: {{flutter_service_worker_version}},
      },
      // Flutter's default steps, reported to the loading screen. Errors here never reach load()'s
      // promise (Flutter calls this from inside the app's code), so they're caught here.
      onEntrypointLoaded: function (engineInitializer) {
        boot.step('engine');
        return Promise.resolve()
          .then(function () { return engineInitializer.initializeEngine(config); })
          .then(function (appRunner) {
            boot.step('app');
            return appRunner.runApp();
          })
          .catch(function (e) { boot.fail(e); });
      },
    }).catch(function (e) { boot.fail(e); });
  } catch (e) {
    boot.fail(e);
  }
})();
