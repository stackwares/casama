/* Plays the Casama brand mascot, the app's own Lottie (client/assets/mascots/brand.json), in every
   element marked data-casama-mark, and in any element passed to window.casamaMark(el).
   Shared by casama.ai, docs.casama.ai and gallery.casama.ai: scripts/web-brand-lottie.py copies this
   file, the player and the animation next to each other on all three sites.
   - The player (lottie-web's SVG-only build, no eval) and the animation load once, after the page.
   - Each mark plays only while it is on screen; the player itself stops when the tab is hidden.
   - Reduced motion shows one still frame. */
(function () {
  "use strict";
  var script = document.currentScript;
  var base = script && script.src ? script.src.replace(/[^/]*$/, "") : "/assets/brand/";
  var still = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)");
  var ready = null;
  var observer = null;

  function load() {
    if (ready) return ready;
    var player = window.lottie ? Promise.resolve() : new Promise(function (resolve, reject) {
      var s = document.createElement("script");
      s.src = base + "lottie_light.min.js";
      s.onload = resolve;
      s.onerror = reject;
      document.head.appendChild(s);
    });
    var data = fetch(base + "casama-brand.json").then(function (r) {
      if (!r.ok) throw new Error("casama-brand.json " + r.status);
      return r.text();
    });
    ready = Promise.all([player, data]).then(function (got) { return got[1]; });
    return ready;
  }

  function watch(el, anim) {
    if (!("IntersectionObserver" in window)) { anim.play(); return; }
    if (!observer) {
      observer = new IntersectionObserver(function (entries) {
        entries.forEach(function (e) {
          var a = e.target.casamaAnim;
          if (!a || (still && still.matches)) return;
          if (e.isIntersecting) a.play(); else a.pause();
        });
      });
    }
    observer.observe(el);
  }

  function mount(el) {
    if (!el || el.casamaAnim || el.casamaLoading) return;
    el.casamaLoading = true;
    el.setAttribute("aria-hidden", "true");
    load().then(function (json) {
      // lottie changes the data it is given, so every mark gets its own copy.
      var anim = window.lottie.loadAnimation({
        container: el,
        renderer: "svg",
        loop: true,
        autoplay: false,
        animationData: JSON.parse(json),
        rendererSettings: { preserveAspectRatio: "xMidYMid meet", progressiveLoad: false }
      });
      el.casamaAnim = anim;
      anim.addEventListener("DOMLoaded", function () {
        el.classList.add("is-ready");
        if (still && still.matches) anim.goToAndStop(0, true);
        else watch(el, anim);
      });
    }).catch(function () {
      el.casamaLoading = false;
    });
  }

  if (still && still.addEventListener) {
    still.addEventListener("change", function () {
      document.querySelectorAll("[data-casama-mark]").forEach(function (el) {
        var a = el.casamaAnim;
        if (!a) return;
        if (still.matches) a.goToAndStop(0, true);
        else watch(el, a);
      });
    });
  }

  window.casamaMark = mount;
  document.querySelectorAll("[data-casama-mark]").forEach(mount);
})();
