/* Plays the Casama brand mascot, the app's own Lottie (client/assets/mascots/brand.json), in every
   element marked data-casama-mark, and in any element passed to window.casamaMark(el).
   Shared by casama.ai, docs.casama.ai and gallery.casama.ai: scripts/web-brand-lottie.py copies this
   file, the player and the animation next to each other on all three sites.
   - The player (lottie-web's SVG-only build, no eval) and the animation load once, after the page.
     A mark further down the page (a footer) is only built when it scrolls near.
   - Each mark plays only while it is on screen, and nothing runs while the tab is hidden.
   - One shared loop steps every visible mark: 60 fps on desktop, 30 fps on touch screens, where
     fewer redraws keep phones smooth while the page changes looks.
   - Reduced motion shows one still frame. */
(function () {
  "use strict";
  var script = document.currentScript;
  var base = script && script.src ? script.src.replace(/[^/]*$/, "") : "/assets/brand/";
  var still = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)");
  var ready = null;
  var observer = null;
  var coarse = window.matchMedia && window.matchMedia("(pointer: coarse)").matches;
  var STEP = coarse ? 1000 / 30 : 1000 / 60;
  var playing = [];
  var raf = 0;
  var last = 0;

  function tick(now) {
    raf = 0;
    if (!playing.length) return;
    if (!last) last = now - STEP;
    var dt = now - last;
    if (dt >= STEP - 2) {
      last = now;
      dt = Math.min(dt, 100);
      playing.forEach(function (a) {
        a.goToAndStop((a.currentFrame + dt * a.frameRate / 1000) % a.totalFrames, true);
      });
    }
    raf = requestAnimationFrame(tick);
  }

  function play(a) {
    if (playing.indexOf(a) === -1) playing.push(a);
    if (!raf) { last = 0; raf = requestAnimationFrame(tick); }
  }

  function pause(a) {
    var i = playing.indexOf(a);
    if (i !== -1) playing.splice(i, 1);
  }

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
    if (!("IntersectionObserver" in window)) { play(anim); return; }
    if (!observer) {
      observer = new IntersectionObserver(function (entries) {
        entries.forEach(function (e) {
          var a = e.target.casamaAnim;
          if (!a || (still && still.matches)) return;
          if (e.isIntersecting) play(a); else pause(a);
        });
      });
    }
    observer.unobserve(el); // observing again reports the current visibility right away
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
      anim.addEventListener("destroy", function () { pause(anim); });
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
        if (still.matches) { pause(a); a.goToAndStop(0, true); }
        else watch(el, a);
      });
    });
  }

  // Builds a mark now if it is near the screen, otherwise when it scrolls near.
  var near = "IntersectionObserver" in window ? new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (!e.isIntersecting) return;
      near.unobserve(e.target);
      mount(e.target);
    });
  }, { rootMargin: "400px 0px" }) : null;

  window.casamaMark = function (el) { if (near) near.observe(el); else mount(el); };
  document.querySelectorAll("[data-casama-mark]").forEach(window.casamaMark);
})();
