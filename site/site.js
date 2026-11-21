/* Casama — casama.ai: the header's line on scroll, the film (in the
   hero and its dialog), the download button for this device and the install command's Copy button.
   Everything else is plain HTML and CSS. */
(function () {
  "use strict";

  var header = document.querySelector(".site-header");
  if (header) {
    var onScroll = function () { header.classList.toggle("scrolled", window.scrollY > 8); };
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
  }

  // The film in the hero (D-390): it plays muted while it's on screen, unless the
  // visitor asked for less motion or less data (then it waits for the player's own button).
  // "Sound on" starts it over with the voice and music.
  var reel = document.querySelector(".reel-video");
  var reelInView = false;
  var playQuietly = function (v) { var p = v.play(); if (p && p.catch) p.catch(function () { /* the player's own button starts it */ }); };
  var film = document.getElementById("film");
  if (reel) {
    // In the hero (D-390) wide screens and upright phones play the 9:16 film the HTML names; tablets and
    // phones on their side get 16:9. The query matches the one in site.css that shapes the frame.
    if (reel.hasAttribute("data-src-wide") && !window.matchMedia("(min-width: 961px), (max-width: 600px) and (orientation: portrait)").matches) {
      reel.setAttribute("poster", reel.getAttribute("data-poster-wide"));
      reel.setAttribute("src", reel.getAttribute("data-src-wide"));
      reel.setAttribute("width", "1920"); reel.setAttribute("height", "1080");
    }
    var soundBtn = document.querySelector("[data-reel-sound]");
    var calm = window.matchMedia("(prefers-reduced-motion: reduce)").matches || !!(navigator.connection && navigator.connection.saveData);
    if (calm || !("IntersectionObserver" in window) || !soundBtn) {
      reel.controls = true;
      if (soundBtn) soundBtn.hidden = true;
    } else {
      // It starts only after the page has loaded, so the film never slows the first paint.
      var watchReel = function () {
        new IntersectionObserver(function (entries) {
          reelInView = entries[0].isIntersecting;
          if (reelInView && !(film && film.open)) playQuietly(reel);
          else reel.pause();
        }, { threshold: 0.35 }).observe(reel);
      };
      if (document.readyState === "complete") watchReel(); else window.addEventListener("load", watchReel);
      var soundLabel = soundBtn.querySelector("[data-reel-sound-label]");
      soundBtn.addEventListener("click", function () {
        var on = reel.muted;
        reel.muted = !on;
        if (on) { reel.currentTime = 0; playQuietly(reel); }
        soundBtn.setAttribute("aria-pressed", String(on));
        soundLabel.textContent = on ? "Sound off" : "Sound on";
      });
    }
  }

  // The film (D-390): "Watch the film" opens the YouTube film in a dialog. A phone held upright
  // gets the 9:16 Short; everything else gets 16:9. casama.ai/#film opens it straight away. Without
  // JavaScript the links open the YouTube URL.
  var filmVideo = film && film.querySelector(".film-video");
  if (film && filmVideo && typeof film.showModal === "function") {
    var wideSrc = filmVideo.getAttribute("data-src") || filmVideo.getAttribute("src");
    var tallSrc = filmVideo.getAttribute("data-src-tall");
    var upright = window.matchMedia ? window.matchMedia("(orientation: portrait) and (max-width: 600px)") : null;
    var counted = false;
    var openFilm = function () {
      if (reel) reel.pause();
      var useTall = !!(tallSrc && upright && upright.matches);
      var pickSrc = useTall ? tallSrc : wideSrc;
      film.classList.toggle("film--tall", useTall);
      if (pickSrc && filmVideo.getAttribute("src") !== pickSrc) {
        filmVideo.setAttribute("src", pickSrc);
      }
      film.showModal();
      if (!counted) { counted = true; countEvent("film_play"); }
    };
    Array.prototype.forEach.call(document.querySelectorAll("[data-film-open]"), function (a) {
      a.addEventListener("click", function (e) { e.preventDefault(); openFilm(); });
    });
    film.querySelector("[data-film-close]").addEventListener("click", function () { film.close(); });
    film.addEventListener("click", function (e) { if (e.target === film) film.close(); });
    film.addEventListener("close", function () {
      if (filmVideo.tagName === "IFRAME") filmVideo.removeAttribute("src");
      else filmVideo.pause();
      if (location.hash === "#film") history.replaceState(null, "", location.pathname + location.search);
      if (reel && reelInView && !reel.controls) playQuietly(reel);
    });
    if (location.hash === "#film") openFilm();
    window.addEventListener("hashchange", function () { if (location.hash === "#film" && !film.open) openFilm(); });
  }

  // The download page and section (D-377): the button for this device first, and its card marked.
  var platform = (function () {
    var ua = navigator.userAgent || "";
    if (/iPhone|iPod/.test(ua)) return "iphone";
    // iPads ask for desktop pages and say Macintosh; a touch screen gives them away.
    if (/iPad/.test(ua) || (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1)) return "ipad";
    if (/Android/.test(ua)) return "android";
    if (/CrOS/.test(ua)) return "";
    if (/Macintosh|Mac OS X/.test(ua)) return "mac";
    if (/Windows/.test(ua)) return "windows";
    if (/Linux|X11/.test(ua)) return "linux";
    return "";
  })();
  var picks = {
    iphone: ["/get/ios", "Get it on TestFlight"],
    ipad: ["/get/ios", "Get it on TestFlight"],
    android: ["/get/android", "Get it on Google Play"],
    mac: ["/get/mac-dmg", "Download for Mac"],
    windows: ["/get/windows", "Download for Windows"],
    linux: ["/get/linux", "Download for Linux"]
  };
  var pick = document.querySelector("[data-get-pick]");
  if (pick && picks[platform]) {
    pick.href = picks[platform][0];
    pick.textContent = picks[platform][1];
    var alt = document.querySelector("[data-get-alt]");
    if (alt) { alt.href = "https://app.casama.ai"; alt.textContent = "Or use the web app"; }
  }
  var yours = platform && document.querySelector('.dl[data-platform="' + platform + '"]');
  if (yours) {
    yours.classList.add("is-yours");
    var tag = document.createElement("span");
    tag.className = "brand-tag";
    tag.textContent = "This device";
    yours.querySelector("h3").appendChild(tag);
  }

  var copyBtn = document.getElementById("copy-install");
  var code = document.getElementById("install-code");
  if (copyBtn && code) {
    copyBtn.addEventListener("click", function () {
      var done = function (ok) {
        copyBtn.textContent = ok ? "Copied" : "Select it";
        if (ok) countEvent("copy_install");
        setTimeout(function () { copyBtn.textContent = "Copy"; }, 1800);
      };
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(code.textContent.trim()).then(function () { done(true); }, function () { done(false); });
      } else {
        done(false);
      }
    });
  }
  // One anonymous count per page view (the page, and which kind of site sent the visitor), so we
  // can tell whether search engines and AI assistants send anyone. No cookie and no visitor ID.
  try {
    var from = "";
    try { from = document.referrer ? new URL(document.referrer).hostname : ""; } catch (e) { from = ""; }
    var utm = new URLSearchParams(location.search).get("utm_source") || "";
    if (navigator.sendBeacon && !/^(localhost|127\.)/.test(location.hostname)) {
      navigator.sendBeacon("/b", JSON.stringify({ p: location.pathname, r: from, u: utm }));
    }
  } catch (e) { /* counting is never worth breaking the page for */ }

  // Funnel steps (D-398). A link straight to the web app counts as "start" like /get/start does, and
  // carries where it came from, so the web app credits this page. A [data-plan] button names its plan.
  document.addEventListener("click", function (e) {
    var a = e.target && e.target.closest ? e.target.closest("a[href], [data-plan]") : null;
    if (!a) return;
    var plan = a.getAttribute("data-plan");
    if (plan) countEvent("plan_click", { plan: plan });
    var href = a.getAttribute("href") || "";
    if (/^https:\/\/app\.casama\.ai(\/|$|\?)/.test(href)) {
      try {
        var u = new URL(href);
        if (!u.searchParams.has("utm_source")) {
          var slug = location.pathname.replace(/^\/+|\/+$/g, "").replace(/\.html$/, "").replace(/[^a-z0-9]+/gi, "-").toLowerCase();
          u.searchParams.set("utm_source", "casama.ai");
          u.searchParams.set("utm_medium", "website");
          u.searchParams.set("utm_campaign", slug || "home");
          a.setAttribute("href", u.toString());
        }
      } catch (err) { /* keep the link as it is */ }
      countEvent("start_click", { via: "link" });
    }
  });

  // The monthly email (D-404): sends the form without leaving the page. Without JavaScript the form
  // posts normally and the Worker answers with a page.
  Array.prototype.forEach.call(document.querySelectorAll("form[data-newsletter]"), function (form) {
    if (!window.fetch) return;
    form.addEventListener("submit", function (e) {
      e.preventDefault();
      var note = form.querySelector(".footer-news-note");
      var btn = form.querySelector("button[type=submit]");
      var say = function (text, good) {
        if (!note) return;
        note.textContent = text;
        note.className = "footer-news-note " + (good ? "is-good" : "is-bad");
      };
      btn.disabled = true;
      fetch(form.action, { method: "POST", body: new FormData(form), headers: { Accept: "application/json" } })
        .then(function (r) { return r.json().catch(function () { return { ok: false }; }); })
        .then(function (res) {
          say(res.message || (res.ok ? "Check your inbox." : "That didn't work. Try again in a minute."), !!res.ok);
          if (res.ok) form.reset();
        })
        .catch(function () { say("That didn't work. Check your connection and try again.", false); })
        .then(function () { btn.disabled = false; });
    });
  });

  // On /download, a desktop download starting shows "While it downloads" (D-404) once.
  var dlNews = document.getElementById("dl-news");
  if (dlNews) {
    document.addEventListener("click", function (e) {
      var a = e.target && e.target.closest ? e.target.closest('a[href^="/get/mac-dmg"], a[href^="/get/windows"], a[href^="/get/linux"]') : null;
      if (!a || !dlNews.hidden) return;
      dlNews.hidden = false;
      setTimeout(function () {
        try { dlNews.scrollIntoView({ behavior: "smooth", block: "center" }); } catch (err) { /* old browsers */ }
      }, 400);
    });
  }

  // Casama Help, the support chat that answers from the docs: a tiny loader draws its button, and the
  // chat itself is fetched on the first click (site/assets/support/).
  var help = document.createElement("script");
  help.src = "/assets/support/loader.js";
  help.async = true;
  document.body.appendChild(help);

  /** One named event through the same anonymous count; casama.ai's Worker keeps only known ones. */
  function countEvent(name, data) {
    try {
      if (navigator.sendBeacon && !/^(localhost|127\.)/.test(location.hostname)) {
        navigator.sendBeacon("/b", JSON.stringify({ p: location.pathname, e: name, d: data || {} }));
      }
    } catch (e) { /* counting is never worth breaking the page for */ }
  }
})();
