/* Casama — casama.ai: the header's line on scroll, the example approval card, the film (in the
   hero's dialog and in "See it at work"), the download button for this device and the install command's Copy button.
   Everything else is plain HTML and CSS. */
(function () {
  "use strict";

  var header = document.querySelector(".site-header");
  if (header) {
    var onScroll = function () { header.classList.toggle("scrolled", window.scrollY > 8); };
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
  }

  // The hero chat. It plays itself in a loop of about 25 seconds: you ask, Anna works through flights and
  // hotels on her computer (with checkpoints and the cost ticking up), asks for your OK, a tap approves it,
  // and it starts over. Visitors can tap Approve or Deny themselves while it asks. It begins on the finished
  // card the HTML shows, so first paint is complete. With reduced motion or Save-Data it stays that still,
  // and the buttons just show what would happen. It pauses while off screen or in a hidden tab.
  var ask = document.getElementById("ask-card");
  var chat = ask && ask.closest(".chat");
  if (ask && chat) {
    var askText = ask.querySelector("[data-ask-text]");
    var askReply = chat.querySelector("[data-ask-reply]");
    var original = askText.textContent;
    var replyYes = "Booked. The confirmations are in your inbox and on your calendar. That task cost $0.019.";
    var replyNo = "Okay, nothing was booked. I rolled my computer back to checkpoint 7.";
    var answer = function (yes) {
      ask.dataset.state = "done";
      askText.textContent = yes ? "Approved. Booking flights and hotel." : "Denied. Checkpoint 7 restored.";
      askReply.textContent = yes ? replyYes : replyNo;
    };
    var still = window.matchMedia("(prefers-reduced-motion: reduce)").matches || !!(navigator.connection && navigator.connection.saveData);
    var buttons = ask.querySelectorAll("[data-ask]");

    if (still || !("IntersectionObserver" in window)) {
      var resetTimer = 0;
      Array.prototype.forEach.call(buttons, function (b) {
        b.addEventListener("click", function () {
          answer(b.dataset.ask === "yes");
          askReply.hidden = false;
          clearTimeout(resetTimer);
          resetTimer = setTimeout(function () { ask.dataset.state = "ask"; askText.textContent = original; askReply.hidden = true; }, 7000);
        });
      });
    } else {
      var body = chat.querySelector(".chat-body");
      var you = body.querySelector(".bubble.you");
      var result = body.querySelector(".bubble.bot:not([data-ask-reply])");
      var run = body.querySelector(".run-card");
      var statusEl = chat.querySelector("[data-chat-status]");
      var dot = chat.querySelector(".live-dot");
      var costEl = chat.querySelector("[data-chat-cost]");
      var urlEl = run.querySelector("[data-run-url]");
      var rowsEl = run.querySelector("[data-run-rows]");
      var barEl = run.querySelector("[data-run-progress]");
      var okEl = run.querySelector("[data-run-ok]");
      var metaEl = run.querySelector("[data-run-meta]");
      var steps = [you, result, run, ask, askReply];

      // The airlines, hotels and prices are made up, like the film's.
      var FLIGHTS = [["1 stop · Madrid", "$541"], ["Direct · 2h 35m", "$612"], ["1 stop · Paris", "$577"], ["Direct · late", "$655"], ["1 stop · London", "$598"],
        ["2 stops", "$489"], ["Direct · early", "$634"], ["1 stop · Zurich", "$603"], ["1 stop · Frankfurt", "$622"], ["Direct · morning", "$612"]];
      var HOTELS = [["Rua Nova Suites · Baixa", "$530"], ["Miradouro Inn · Alfama", "$468"], ["Tejo Loft · Chiado", "$575"], ["Casa Azul · Graça", "$455"],
        ["Pátio Hotel · Alfama", "$519"], ["Sé Rooms · Alfama", "$441"], ["Largo House · Mouraria", "$498"], ["Casa Lumen · Alfama", "$492"]];
      var PICK = [["TAP · direct · May 8–12", "$612", true], ["Casa Lumen · Alfama · 4 nights", "$492", true], ["Total", "$1,104"]];

      var paused = false, inView = true, userPaused = false;
      var setPaused = function () {
        paused = document.hidden || !inView || userPaused;
        chat.classList.toggle("is-paused", paused);
      };
      // Anything that moves for more than five seconds gets a pause button (WCAG 2.2.2); showcase.css styles it.
      var toggle = document.createElement("button");
      toggle.type = "button";
      toggle.className = "scene-toggle";
      toggle.setAttribute("aria-pressed", "false");
      toggle.setAttribute("aria-label", "Pause animation");
      toggle.innerHTML = '<span class="scene-toggle-icon" aria-hidden="true"></span>';
      toggle.addEventListener("click", function () {
        userPaused = !userPaused;
        toggle.setAttribute("aria-pressed", String(userPaused));
        toggle.setAttribute("aria-label", userPaused ? "Play animation" : "Pause animation");
        setPaused();
      });
      chat.appendChild(toggle);
      document.addEventListener("visibilitychange", setPaused);
      new IntersectionObserver(function (e) { inView = e[e.length - 1].isIntersecting; setPaused(); }, { threshold: 0.2 }).observe(chat);
      // A wait that stops counting while the chat can't be seen.
      var wait = function (ms) {
        return new Promise(function (done) {
          var left = ms, last = Date.now();
          (function tick() {
            var now = Date.now();
            if (!paused) left -= now - last;
            last = now;
            if (left <= 0) done(); else setTimeout(tick, Math.min(left, 100));
          })();
        });
      };

      var cost = 0;
      var setCost = function (c) { cost = c; costEl.textContent = "$" + c.toFixed(3) + " today"; };
      var setStatus = function (t, idle) { statusEl.textContent = t; dot.classList.toggle("idle", !!idle); };
      var show = function (el) { el.classList.remove("off"); };
      var hide = function (el) { el.classList.add("off"); };

      var ROW = 30;
      var rows = [];
      var place = function () {
        var n = rows.length;
        rows.forEach(function (r, i) {
          var slot = i - Math.max(0, n - 3);
          r.style.transform = "translateY(" + (slot * ROW) + "px)";
          r.style.opacity = slot < 0 ? "0" : "1";
        });
        while (rows.length > 4) rowsEl.removeChild(rows.shift());
      };
      var pushRow = function (d) {
        var r = document.createElement("div");
        r.className = "run-row" + (d[2] ? " best" : "");
        r.innerHTML = "<span></span><b></b>";
        r.firstChild.textContent = d[0];
        r.lastChild.textContent = d[1];
        r.style.transform = "translateY(" + (3 * ROW) + "px)";
        r.style.opacity = "0";
        rowsEl.appendChild(r);
        rows.push(r);
        void r.offsetWidth;
        place();
      };
      var clearRows = function () { rows = []; rowsEl.textContent = ""; };

      // Dots in the spot where the bot's next card will appear.
      var typing = document.createElement("div");
      typing.className = "bubble bot typing";
      typing.innerHTML = "<i></i><i></i><i></i>";
      typing.style.cssText = "position:absolute;left:0;";
      var showTyping = function (at) { typing.style.top = at.offsetTop + "px"; body.appendChild(typing); };
      var hideTyping = function () { if (typing.parentNode) body.removeChild(typing); };

      var cursor = document.createElement("span");
      cursor.className = "tap-cursor";
      cursor.setAttribute("aria-hidden", "true");

      var choose = null;
      Array.prototype.forEach.call(buttons, function (b) {
        b.addEventListener("click", function () { if (choose) choose({ yes: b.dataset.ask === "yes", byYou: true }); });
      });

      chat.classList.add("is-live");
      steps.forEach(function (el) { el.setAttribute("data-step", ""); });
      askReply.hidden = false;
      askReply.textContent = replyYes;  // the longer reply holds its space, so the card never changes height
      hide(askReply);
      PICK.forEach(pushRow);
      barEl.style.width = "100%";
      setCost(0.017);
      setStatus("Waiting for your OK");

      var askPhase = async function () {
        ask.dataset.state = "ask";
        askText.textContent = original;
        // Every card still takes its space while hidden, so this is the tallest the chat gets; holding it
        // keeps the page from moving when the buttons go away.
        body.style.minHeight = "";
        body.style.minHeight = body.offsetHeight + "px";
        ask.classList.add("asking");
        setStatus("Waiting for your OK");
        var picked = await new Promise(function (resolve) {
          choose = resolve;
          (async function () {
            await wait(3200);
            if (choose !== resolve) return;
            var yesBtn = ask.querySelector('[data-ask="yes"]');
            cursor.style.transition = "none";
            cursor.style.left = (body.clientWidth - 24) + "px";
            cursor.style.top = (body.clientHeight - 10) + "px";
            cursor.style.opacity = "0";
            body.appendChild(cursor);
            void cursor.offsetWidth;
            cursor.style.transition = "";
            cursor.style.opacity = "1";
            cursor.style.left = (yesBtn.offsetLeft + yesBtn.offsetWidth / 2) + "px";
            cursor.style.top = (yesBtn.offsetTop + yesBtn.offsetHeight / 2) + "px";
            await wait(1000);
            if (choose !== resolve) { cursor.remove(); return; }
            cursor.classList.add("press");
            yesBtn.classList.add("tapped");
            await wait(180);
            cursor.classList.remove("press");
            yesBtn.classList.remove("tapped");
            resolve({ yes: true, byYou: false });
          })();
        });
        choose = null;
        ask.classList.remove("asking");
        answer(picked.yes);
        await wait(300);
        cursor.style.opacity = "0";
        if (picked.yes) {
          setStatus("Booking flights and hotel");
          await wait(1300);
          setCost(0.019);
          setStatus("Done · booked", true);
        } else {
          setStatus("Rolling back to checkpoint 7");
          await wait(1000);
          setStatus("Online", true);
        }
        show(askReply);
        cursor.remove();
        await wait(picked.byYou ? 8000 : 4500);
      };

      var buildPhase = async function () {
        body.classList.add("fading");
        await wait(550);
        steps.forEach(hide);
        hideTyping();
        clearRows();
        barEl.style.width = "0";
        okEl.textContent = "Starting up";
        metaEl.textContent = "Checkpoint 0";
        urlEl.textContent = "Lisbon · May 8–12";
        setCost(0);
        setStatus("Online", true);
        askReply.textContent = replyYes;
        body.classList.remove("fading");
        await wait(700);

        show(you);
        await wait(700);
        setStatus("Reading your message");
        showTyping(result);
        await wait(1100);
        hideTyping();
        setStatus("Working on her computer");
        show(run);
        await wait(500);

        var cp = 0;
        urlEl.textContent = "Flights · LIS · May 8–12";
        for (var i = 0; i < FLIGHTS.length; i++) {
          pushRow(FLIGHTS[i]);
          okEl.textContent = Math.round((i + 1) * 41 / FLIGHTS.length) + " flights checked";
          barEl.style.width = ((i + 1) * 45 / FLIGHTS.length) + "%";
          setCost(cost + 0.0008);
          if (i % 3 === 2) metaEl.textContent = "Checkpoint " + (++cp) + " saved";
          await wait(320);
        }
        urlEl.textContent = "Hotels · Alfama · 4 nights";
        for (var j = 0; j < HOTELS.length; j++) {
          pushRow(HOTELS[j]);
          okEl.textContent = "41 flights and " + Math.round((j + 1) * 18 / HOTELS.length) + " hotels checked";
          barEl.style.width = (45 + (j + 1) * 45 / HOTELS.length) + "%";
          setCost(cost + 0.0008);
          if (j % 3 === 2) metaEl.textContent = "Checkpoint " + (++cp) + " saved";
          await wait(320);
        }
        urlEl.textContent = "Best fit · under $1,200";
        await wait(300);
        clearRows();
        for (var k = 0; k < PICK.length; k++) { pushRow(PICK[k]); await wait(260); }
        barEl.style.width = "100%";
        metaEl.textContent = "Checkpoint 7 saved";
        setCost(0.017);
        await wait(700);
        showTyping(result);
        await wait(900);
        hideTyping();
        show(result);
        await wait(900);
        show(ask);
        await wait(400);
      };

      (async function loop() {
        await wait(1500);
        for (;;) {
          await askPhase();
          await buildPhase();
        }
      })();
    }
  }

  // The film in "See it at work" (D-390): it plays muted while it's on screen, unless the
  // visitor asked for less motion or less data (then it waits for the player's own button).
  // "Sound on" starts it over with the voice and music.
  var reel = document.querySelector(".reel-video");
  var reelInView = false;
  var playQuietly = function (v) { var p = v.play(); if (p && p.catch) p.catch(function () { /* the player's own button starts it */ }); };
  var film = document.getElementById("film");
  if (reel) {
    var soundBtn = document.querySelector("[data-reel-sound]");
    var calm = window.matchMedia("(prefers-reduced-motion: reduce)").matches || !!(navigator.connection && navigator.connection.saveData);
    if (calm || !("IntersectionObserver" in window) || !soundBtn) {
      reel.controls = true;
      if (soundBtn) soundBtn.hidden = true;
    } else {
      new IntersectionObserver(function (entries) {
        reelInView = entries[0].isIntersecting;
        if (reelInView && !(film && film.open)) playQuietly(reel);
        else reel.pause();
      }, { threshold: 0.35 }).observe(reel);
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

  // The film (D-390): "Watch the film" opens the 86-second film with sound in a dialog. A phone held
  // upright gets the 9:16 film, which fills its screen; everything else gets 16:9. The choice is made
  // each time the dialog opens. casama.ai/#film opens it straight away. Without JavaScript the links
  // open the 16:9 file.
  var filmVideo = film && film.querySelector(".film-video");
  if (film && filmVideo && typeof film.showModal === "function") {
    var wide = {src: filmVideo.getAttribute("src"), poster: filmVideo.getAttribute("poster")};
    var tall = {src: filmVideo.getAttribute("data-src-tall"), poster: filmVideo.getAttribute("data-poster-tall")};
    var upright = window.matchMedia ? window.matchMedia("(orientation: portrait) and (max-width: 600px)") : null;
    var openFilm = function () {
      if (reel) reel.pause();
      var useTall = !!(tall.src && upright && upright.matches);
      var pick = useTall ? tall : wide;
      film.classList.toggle("film--tall", useTall);
      if (filmVideo.getAttribute("src") !== pick.src) {
        filmVideo.setAttribute("poster", pick.poster);
        filmVideo.setAttribute("src", pick.src);
        filmVideo.load();
      }
      film.showModal();
      playQuietly(filmVideo);
    };
    Array.prototype.forEach.call(document.querySelectorAll("[data-film-open]"), function (a) {
      a.addEventListener("click", function (e) { e.preventDefault(); openFilm(); });
    });
    film.querySelector("[data-film-close]").addEventListener("click", function () { film.close(); });
    film.addEventListener("click", function (e) { if (e.target === film) film.close(); });
    film.addEventListener("close", function () {
      filmVideo.pause();
      if (location.hash === "#film") history.replaceState(null, "", location.pathname + location.search);
      if (reel && reelInView && !reel.controls) playQuietly(reel);
    });
    // Funnel (D-398): the first time the film plays with sound on this page.
    filmVideo.addEventListener("play", function once() {
      filmVideo.removeEventListener("play", once);
      countEvent("film_play");
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
    iphone: ["/get/ios", "Download on the App Store"],
    ipad: ["/get/ios", "Download on the App Store"],
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
