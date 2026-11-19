/* Casama web error reports (D-416). The same file ships with casama.ai (site/), the docs
 * (docs-site/public/), the gallery (gallery/) and the web app (client/web/); keep the copies equal
 * (scripts/check-web-errors.sh).
 *
 * Nothing loads until a page actually breaks: this listens for uncaught errors, unhandled promise
 * rejections and scripts that fail to load, and only then fetches Sentry's browser bundle (about
 * 32 KB gzipped, pinned with an integrity hash) to send them. No cookie, no local storage, no
 * visitor ID, no session tracking, no breadcrumbs of what was typed or clicked.
 *
 * Off when: the script tag has no data-dsn (self-hosted web app builds), on localhost, when the
 * browser sends Do Not Track or Global Privacy Control, and in the web app when its "Share usage
 * data and crash reports" switch is off. At most 10 reports per page load.
 *
 *   <script src="/errors.js" data-dsn="https://…@….ingest.sentry.io/…" data-surface="site"></script>
 */
(function () {
  "use strict";
  var SDK = "https://browser.sentry-cdn.com/11.9.0/bundle.min.js";
  var SRI = "sha384-xE/bmsH+mppbFLN9Cj+Lyc7rR9sTBh9p6GEswhQcoZPRAZbv5k6MRfdRIGnB+azV";
  var MAX = 10;
  try {
    var tag = document.currentScript;
    var dsn = tag && tag.getAttribute("data-dsn");
    if (!dsn) return;
    var surface = (tag && tag.getAttribute("data-surface")) || "site";
    var release = (tag && tag.getAttribute("data-release")) || undefined;
    var host = location.hostname;
    if (!host || /^(localhost|127\.|\[::1\]|0\.0\.0\.0)/.test(host) || /\.local$/.test(host)) return;
    if (navigator.doNotTrack === "1" || window.doNotTrack === "1" || navigator.globalPrivacyControl === true) return;
    // The web app's switch, as shared_preferences stores it on the web.
    try {
      if (window.localStorage && localStorage.getItem("flutter.casama.analytics_enabled") === "false") return;
    } catch (e) { /* storage blocked: the app's own Dart reporter still follows the switch */ }
  } catch (e) {
    return;
  }

  var queue = [];
  var sent = 0;
  var state = "idle"; // idle | loading | ready | failed

  var secrets = [
    /\b(sk|pk|rk)-[A-Za-z0-9_-]{12,}/g,
    /\bBearer\s+[A-Za-z0-9._~+\/=-]{8,}/gi,
    /\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{5,}/g,
    /\b(gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16})\b/g,
    /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g,
  ];
  function scrub(s) {
    if (typeof s !== "string") return s;
    for (var i = 0; i < secrets.length; i++) s = s.replace(secrets[i], "[redacted]");
    return s.length > 500 ? s.slice(0, 500) + "…" : s;
  }
  // Addresses without their query or fragment (sign-in codes and tokens live there).
  function bare(u) {
    return typeof u === "string" ? u.split(/[?#]/)[0] : u;
  }

  function report(item) {
    if (sent >= MAX) return;
    if (state === "ready") return send(item);
    if (state === "failed") return;
    queue.push(item);
    if (state === "idle") load();
  }

  function send(item) {
    var S = window.Sentry;
    if (!S || sent >= MAX) return;
    if (item.error) S.captureException(item.error, { mechanism: { handled: false } });
    else S.captureMessage(item.message, "error");
  }

  function load() {
    state = "loading";
    var s = document.createElement("script");
    s.src = SDK;
    s.integrity = SRI;
    s.crossOrigin = "anonymous";
    s.async = true;
    s.onload = function () {
      try {
        window.Sentry.init({
          dsn: dsn,
          release: release,
          environment: "production",
          sendDefaultPii: false,
          maxBreadcrumbs: 0,
          // Only the error handlers and the stack trace helpers: no sessions, no fetch or console
          // breadcrumbs. GlobalHandlers takes over uncaught errors from here on.
          integrations: function (all) {
            return all.filter(function (i) {
              return /^(GlobalHandlers|LinkedErrors|Dedupe|EventFilters|InboundFilters|FunctionToString|HttpContext)$/.test(i.name);
            });
          },
          initialScope: { tags: { surface: surface } },
          beforeSend: function (event) {
            if (++sent > MAX) return null;
            if (event.request) {
              event.request.url = bare(event.request.url);
              delete event.request.cookies;
              delete event.request.query_string;
            }
            event.user = undefined;
            if (event.message) event.message = scrub(event.message);
            var ex = (event.exception && event.exception.values) || [];
            for (var i = 0; i < ex.length; i++) {
              ex[i].value = scrub(ex[i].value);
              var frames = (ex[i].stacktrace && ex[i].stacktrace.frames) || [];
              for (var j = 0; j < frames.length; j++) frames[j].filename = bare(frames[j].filename);
            }
            return event;
          },
        });
        state = "ready";
        var pending = queue;
        queue = [];
        for (var i = 0; i < pending.length; i++) send(pending[i]);
      } catch (e) {
        state = "failed";
      }
    };
    s.onerror = function () {
      state = "failed";
      queue = [];
    };
    (document.head || document.documentElement).appendChild(s);
  }

  // Scripts and stylesheets that fail to load (capture phase: these events don't bubble).
  window.addEventListener(
    "error",
    function (e) {
      var t = e.target;
      if (t && t !== window && (t.tagName === "SCRIPT" || t.tagName === "LINK")) {
        var src = bare(t.src || t.href || "");
        if (src && src.indexOf("sentry-cdn.com") < 0) report({ message: "Failed to load " + src });
        return;
      }
      if (state === "ready") return; // Sentry's own handler has it
      report({ error: e.error || new Error(scrub(String(e.message || "Script error"))) });
    },
    true
  );
  window.addEventListener("unhandledrejection", function (e) {
    if (state === "ready") return;
    var r = e.reason;
    report({ error: r instanceof Error ? r : new Error("Unhandled rejection: " + scrub(String(r))) });
  });
})();
