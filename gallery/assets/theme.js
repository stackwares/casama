/* Light, dark or system theme for Casama's websites (casama.ai, gallery, casama.link, casama.page).
   One copy of this file lives in site/assets/, gallery/assets/ and link-site/assets/; keep them the same.

   Load it in <head>, before the stylesheets paint, as a plain (blocking) script:
     <script src="/assets/theme.js"></script>
   It sets <html data-theme="light|dark"> straight away, so a saved choice never flashes the other theme.
   The default is the system setting, and it follows the system live while no choice is saved.

   Once the page has loaded it adds a button to the header that cycles System -> Light -> Dark. It goes
   in [data-theme-toggle] if the page has one, else just before the header's main button, else at the
   end of the header. Styles: .theme-toggle in each site's stylesheet.

   The choice is kept in a casama-theme cookie on .casama.ai (so casama.ai and the gallery share it;
   localhost shares it across ports) and in localStorage. Other scripts can read window.CasamaTheme
   and listen for the "casama-theme" event on document. */
(function () {
  "use strict";
  var KEY = "casama-theme";
  var root = document.documentElement;
  var mq = window.matchMedia ? matchMedia("(prefers-color-scheme: dark)") : { matches: false };
  var COLORS = { light: "#ffffff", dark: "#1c1c1e" };

  function valid(v) { return v === "light" || v === "dark" ? v : null; }
  function read() {
    var m = /(?:^|;\s*)casama-theme=(light|dark)/.exec(document.cookie || "");
    if (m) return m[1];
    try { return valid(localStorage.getItem(KEY)) || "system"; } catch (e) { return "system"; }
  }
  function save(pref) {
    var shared = /(^|\.)casama\.ai$/.test(location.hostname) ? "; domain=.casama.ai" : "";
    var secure = location.protocol === "https:" ? "; Secure" : "";
    document.cookie = KEY + "=" + (pref === "system" ? "; max-age=0" : pref + "; max-age=31536000") + "; path=/; SameSite=Lax" + shared + secure;
    try { pref === "system" ? localStorage.removeItem(KEY) : localStorage.setItem(KEY, pref); } catch (e) { /* storage off */ }
  }

  var pref = read();
  function effective() { return pref === "system" ? (mq.matches ? "dark" : "light") : pref; }

  function apply() {
    var mode = effective();
    root.setAttribute("data-theme", mode);
    var metas = document.querySelectorAll('meta[name="theme-color"]');
    for (var i = 0; i < metas.length; i++) {
      if (pref === "system") {
        var m = metas[i].getAttribute("data-media");
        if (m) { metas[i].setAttribute("media", m); metas[i].removeAttribute("data-media"); }
        metas[i].setAttribute("content", /dark/.test(metas[i].getAttribute("media") || "") ? COLORS.dark : COLORS.light);
      } else {
        if (metas[i].hasAttribute("media")) { metas[i].setAttribute("data-media", metas[i].getAttribute("media")); metas[i].removeAttribute("media"); }
        metas[i].setAttribute("content", COLORS[mode]);
      }
    }
    syncButtons();
    try { document.dispatchEvent(new CustomEvent("casama-theme", { detail: { pref: pref, mode: mode } })); } catch (e) { /* old browser */ }
  }

  var LABELS = { system: "System", light: "Light", dark: "Dark" };
  var NEXT = { system: "light", light: "dark", dark: "system" };
  var ICONS = {
    system: '<rect x="3" y="4" width="18" height="12" rx="2"/><path d="M8 20h8M12 16v4"/>',
    light: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
    dark: '<path d="M20.5 14.5A8.5 8.5 0 0 1 9.5 3.5a8.5 8.5 0 1 0 11 11z"/>'
  };
  var buttons = [];
  function syncButtons() {
    for (var i = 0; i < buttons.length; i++) {
      var b = buttons[i];
      b.innerHTML = '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true" focusable="false">' + ICONS[pref] + "</svg>";
      var label = "Theme: " + LABELS[pref] + ". Switch to " + LABELS[NEXT[pref]];
      b.setAttribute("aria-label", label);
      b.title = label;
      b.setAttribute("data-pref", pref);
    }
  }
  function makeButton() {
    var b = document.createElement("button");
    b.type = "button";
    b.className = "theme-toggle";
    b.addEventListener("click", function () { set(NEXT[pref]); });
    buttons.push(b);
    return b;
  }
  function mount() {
    var spot = document.querySelector("[data-theme-toggle]");
    if (spot) { spot.appendChild(makeButton()); syncButtons(); return; }
    var header = document.querySelector("header.site-header, header.bar");
    if (!header) return;
    var cta = header.querySelector(".header-cta");
    if (cta) { cta.insertBefore(makeButton(), cta.firstChild); syncButtons(); return; }
    var btn = header.querySelector(".btn.primary");
    if (btn) { btn.parentNode.insertBefore(makeButton(), btn); syncButtons(); return; }
    var inner = header.querySelector(".header-inner, .bar-inner") || header;
    var b = makeButton();
    b.classList.add("theme-toggle--end");
    inner.appendChild(b);
    syncButtons();
  }

  function set(next) {
    pref = next === "light" || next === "dark" ? next : "system";
    save(pref);
    apply();
  }

  var onSystem = function () { if (pref === "system") apply(); };
  if (mq.addEventListener) mq.addEventListener("change", onSystem); else if (mq.addListener) mq.addListener(onSystem);
  // Another tab changed it.
  window.addEventListener("storage", function (e) { if (e.key === KEY) { pref = read(); apply(); } });

  window.CasamaTheme = {
    get pref() { return pref; },
    get mode() { return effective(); },
    set: set
  };

  root.setAttribute("data-theme", effective());
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", function () { mount(); apply(); });
  else { mount(); apply(); }
})();
