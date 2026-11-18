/* Casama Help's loader, on casama.ai (site.js adds it) and docs.casama.ai (the docs theme adds it).
   It only draws the small "? Questions" button; the chat (support-widget.js and .css, next to this
   file) is fetched on the first click, or straight away where a page holds the chat inline
   ([data-casama-help-inline], casama.ai/help).

   window.CasamaHelp.open({ text, inline }) opens the chat, sends `text` as a first message, and with
   `inline` (an element) draws the chat inside it instead of a panel.
   The API is https://api.casama.ai, or window.CASAMA_API, or this script's data-api; on localhost it
   is the local stack's http://localhost:8787. */
(function () {
  "use strict";

  if (window.CasamaHelp) return;
  var me = document.currentScript;
  var base = me && me.src ? me.src.replace(/[^/]*(\?.*)?$/, "") : "/assets/support/";
  var local = /^(localhost|127\.0\.0\.1|\[::1\])$/.test(location.hostname);
  var api = String(window.CASAMA_API || (me && me.getAttribute("data-api")) || (local ? "http://localhost:8787" : "https://api.casama.ai")).replace(/\/+$/, "");
  var surface = (me && me.getAttribute("data-surface")) || "site";
  var loading = null;
  var queue = [];

  function load() {
    if (loading) return loading;
    loading = new Promise(function (resolve, reject) {
      var css = document.createElement("link");
      css.rel = "stylesheet";
      css.href = base + "support-widget.css";
      document.head.appendChild(css);
      var js = document.createElement("script");
      js.src = base + "support-widget.js";
      js.async = true;
      js.onload = function () { window.__casamaHelpWidget ? resolve(window.__casamaHelpWidget) : reject(new Error("no widget")); };
      js.onerror = function () { loading = null; reject(new Error("widget failed to load")); };
      document.head.appendChild(js);
    });
    return loading;
  }

  function open(options) {
    options = options || {};
    return load().then(function (widget) {
      widget.open({ api: api, surface: surface, text: options.text || "", inline: options.inline || null, opener: options.opener || document.activeElement });
    }, function () {
      // The chat couldn't load: the help page still answers, and a person still reads email.
      if (!options.inline) location.href = surface === "docs" ? "https://casama.ai/help" : "/help";
    });
  }

  window.CasamaHelp = { open: open };

  // The button. Not where a page holds the chat inline, and on the home page only after the hero.
  var inline = document.querySelector("[data-casama-help-inline]");
  if (!inline && !(me && me.getAttribute("data-button") === "off")) {
    var style = document.createElement("style");
    style.textContent =
      ".cmh-launch{position:fixed;right:max(16px,env(safe-area-inset-right));bottom:max(16px,env(safe-area-inset-bottom));z-index:2147483000;" +
      "display:inline-flex;align-items:center;gap:8px;min-height:44px;padding:0 18px 0 8px;border:1px solid var(--cmh-line,#e3e2e7);border-radius:999px;" +
      "background:#fff;color:#1d1b20;font:600 15px/1 'Google Sans',-apple-system,BlinkMacSystemFont,'Segoe UI',system-ui,sans-serif;cursor:pointer;" +
      "box-shadow:0 6px 24px rgba(20,10,30,.14);transition:opacity .2s ease,transform .2s ease,visibility .2s}" +
      ".cmh-launch-q{display:grid;place-items:center;width:28px;height:28px;border-radius:50%;background:#7a3fa8;color:#fff;font-weight:700}" +
      ".cmh-launch[data-away]{opacity:0;visibility:hidden;transform:translateY(12px);pointer-events:none}" +
      ".cmh-launch:focus-visible{outline:3px solid #7a3fa8;outline-offset:3px}" +
      "@media (prefers-color-scheme:dark){html:not(.dark):not([data-theme=light]) .cmh-launch:not([data-surface=docs]){background:#242427;color:#f2f1f4;border-color:#38383c}" +
      "html:not([data-theme=light]) .cmh-launch:not([data-surface=docs]) .cmh-launch-q{background:#d9b6f7;color:#25102f}}" +
      "html.dark .cmh-launch,:root[data-theme=dark] .cmh-launch{background:#242427;color:#f2f1f4;border-color:#38383c}" +
      "html.dark .cmh-launch .cmh-launch-q,:root[data-theme=dark] .cmh-launch .cmh-launch-q{background:#d9b6f7;color:#25102f}" +
      "@media (prefers-reduced-motion:reduce){.cmh-launch{transition:none}}" +
      "@media print{.cmh-launch{display:none}}";
    document.head.appendChild(style);

    var button = document.createElement("button");
    button.type = "button";
    button.className = "cmh-launch";
    button.setAttribute("aria-label", "Ask Casama Help");
    button.setAttribute("aria-haspopup", "dialog");
    button.setAttribute("data-surface", surface);
    button.innerHTML = '<span class="cmh-launch-q" aria-hidden="true">?</span><span aria-hidden="true">Questions</span>';
    button.addEventListener("click", function () { open({ opener: button }); });
    window.addEventListener("casama-help-panel", function (e) { button.hidden = !!(e.detail && e.detail.open); });

    var hero = surface === "site" && (location.pathname === "/" || location.pathname === "/index.html") ? document.querySelector(".hero") : null;
    if (hero && "IntersectionObserver" in window) {
      button.setAttribute("data-away", "");
      new IntersectionObserver(function (entries) {
        if (entries[0].isIntersecting) button.setAttribute("data-away", "");
        else button.removeAttribute("data-away");
      }).observe(hero);
    }
    document.body.appendChild(button);
  }

  try { document.dispatchEvent(new CustomEvent("casama-help-ready")); } catch (e) { /* old browsers: the help page shows email */ }
})();
