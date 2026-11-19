/* casama.ai "See it at work": plays the three scenes in showcase.css (docs/SHOWCASE-PLAN.md).
   Each scene starts on the finished frame the HTML shows, then loops its own short story. A scene plays only
   while it's on screen, the tab is visible and nobody pressed its pause button. With reduced motion or
   Save-Data nothing here runs, and the finished frames stay. */
(function () {
  "use strict";

  var still = window.matchMedia("(prefers-reduced-motion: reduce)").matches || !!(navigator.connection && navigator.connection.saveData);
  if (still || !("IntersectionObserver" in window) || !window.Promise) return;

  var EASE = "cubic-bezier(.16,1,.3,1)";
  var $ = function (root, sel) { return root.querySelector(sel); };
  var $$ = function (root, sel) { return Array.prototype.slice.call(root.querySelectorAll(sel)); };

  // One scene: pausing, waiting, messages arriving in its chat, and the loop.
  function scene(fig, build) {
    var paused = true, inView = false, userPaused = false;
    var update = function () {
      paused = document.hidden || !inView || userPaused;
      fig.classList.toggle("is-paused", paused);
    };
    document.addEventListener("visibilitychange", update);
    new IntersectionObserver(function (e) { inView = e[e.length - 1].isIntersecting; update(); }, { threshold: 0.25 }).observe(fig);

    var toggle = $(fig, "[data-scene-toggle]");
    if (toggle) {
      var label = $(toggle, "[data-scene-toggle-label]");
      toggle.hidden = false;
      toggle.addEventListener("click", function () {
        userPaused = !userPaused;
        toggle.setAttribute("aria-pressed", String(userPaused));
        label.textContent = userPaused ? "Play animation" : "Pause animation";
        update();
      });
    }

    // Waits that count real time, and stop counting while the scene can't be seen or is paused.
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

    var list = $(fig, "[data-msgs]");
    var typingEl = $(list, "[data-typing]");
    var steps = {};
    $$(list, "[data-step]").forEach(function (el) { steps[el.dataset.step] = el; });

    // Messages sit at the bottom of the chat. When one arrives or leaves, the others glide to their new place.
    var flip = function (change) {
      var kids = Array.prototype.filter.call(list.children, function (k) { return !k.hidden; });
      var tops = kids.map(function (k) { return k.offsetTop; });
      change();
      kids.forEach(function (k, i) {
        if (k.hidden) return;
        var d = tops[i] - k.offsetTop;
        if (!d) return;
        k.style.transition = "none";
        k.style.transform = "translateY(" + d + "px)";
      });
      void list.offsetHeight;
      kids.forEach(function (k) {
        if (!k.style.transform) return;
        k.style.transition = "transform .45s " + EASE;
        k.style.transform = "";
        setTimeout(function () { k.style.transition = ""; }, 500);
      });
    };
    var enter = function (el) {
      el.hidden = false;
      el.classList.remove("arrive");
      void el.offsetWidth;
      el.classList.add("arrive");
    };
    list.addEventListener("animationend", function (e) { if (e.target.parentNode === list) e.target.classList.remove("arrive"); });
    var api = {
      wait: wait,
      steps: steps,
      arrive: function (name) {
        flip(function () { if (typingEl) typingEl.hidden = true; enter(steps[name]); });
      },
      typing: function (who, name) {
        var img = $(typingEl, "img");
        img.src = "/assets/bots/casama-" + who + ".svg";
        $(typingEl, ".m-name").textContent = name;
        if (typingEl.hidden) flip(function () { enter(typingEl); });
      },
      clear: function () {
        Object.keys(steps).forEach(function (k) { steps[k].hidden = true; steps[k].classList.remove("arrive"); });
        if (typingEl) typingEl.hidden = true;
      }
    };

    var story = build(api, fig);
    (async function loop() {
      await wait(1400);
      for (;;) {
        list.classList.add("fading");
        if (story.fadeAlso) story.fadeAlso.forEach(function (el) { el.classList.add("fading"); });
        await wait(500);
        api.clear();
        story.reset();
        list.classList.remove("fading");
        if (story.fadeAlso) story.fadeAlso.forEach(function (el) { el.classList.remove("fading"); });
        await wait(500);
        await story.play();
      }
    })();
    fig.classList.add("is-live");
  }

  // ------------------------------------------------------------ A. group chat on a desktop
  var group = document.querySelector('[data-scene="group"]');
  if (group) scene(group, function (s, fig) {
    var bots = {};
    ["ada", "milo", "nova", "juno"].forEach(function (b) {
      bots[b] = { side: $(fig, '.side-bot[data-bot="' + b + '"]'), ring: $(fig, '.ava-ring[data-bot="' + b + '"]') };
    });
    var rsvp = $(fig, "[data-rsvp]");
    var rsvpSide = $(fig, "[data-rsvp-side]");
    var setBot = function (b, text, working) {
      bots[b].side.classList.toggle("working", working);
      bots[b].ring.classList.toggle("working", working);
      $(bots[b].side, "[data-bot-status]").textContent = text;
    };
    var setRsvp = function (n, bump) {
      rsvp.textContent = n + " of 8 going";
      rsvpSide.textContent = n + " of 8 going";
      if (bump) { rsvp.classList.remove("bump"); void rsvp.offsetWidth; rsvp.classList.add("bump"); }
    };
    return {
      reset: function () {
        ["ada", "milo", "nova"].forEach(function (b) { setBot(b, "Idle", false); });
        setBot("juno", "Idle", false);
        rsvpSide.textContent = "New chat";
        setRsvp(1);
        rsvpSide.textContent = "New chat";
      },
      play: async function () {
        await s.wait(300);
        s.arrive("you");
        await s.wait(800);
        s.typing("starry", "Nova");
        await s.wait(1000);
        s.arrive("split");
        await s.wait(250);
        setBot("ada", "Writing the invite…", true);
        setBot("milo", "Building the RSVP page…", true);
        setBot("nova", "Shortlisting places…", true);
        rsvpSide.textContent = "3 bots working";
        await s.wait(900);
        s.typing("cool", "Milo");
        await s.wait(800);
        s.arrive("milo1");
        await s.wait(900);
        s.typing("lovey", "Ada");
        await s.wait(1300);
        s.arrive("ada");
        setBot("ada", "Invite ready", false);
        await s.wait(1100);
        s.typing("starry", "Nova");
        await s.wait(1200);
        s.arrive("nova2");
        setBot("nova", "Shortlist ready", false);
        await s.wait(1100);
        s.typing("cool", "Milo");
        await s.wait(1200);
        setRsvp(1);
        s.arrive("milo2");
        setBot("milo", "RSVP page live", false);
        for (var n = 2; n <= 5; n++) { await s.wait(n === 2 ? 1300 : 750); setRsvp(n, true); }
        await s.wait(3800);
      }
    };
  });

  // ------------------------------------------------------------ B. a map in the chat, on a phone
  var map = document.querySelector('[data-scene="map"]');
  if (map) scene(map, function (s, fig) {
    var days = $$(fig, ".map-day");
    var tabs = $$(fig, "[data-tab]");
    var pics = $$(fig, "[data-daypic]");
    var showDay = function (d) {
      days.forEach(function (g, i) { g.classList.toggle("on", i === d); });
      pics.forEach(function (p, i) { p.classList.toggle("on", i === Math.max(d, 0)); });
      tabs.forEach(function (t, i) { t.classList.toggle("on", i === d); });
    };
    return {
      reset: function () { showDay(-1); tabs[0].classList.add("on"); },
      play: async function () {
        await s.wait(300);
        s.arrive("you");
        await s.wait(900);
        s.typing("starry", "Nova");
        await s.wait(900);
        s.arrive("ack");
        await s.wait(800);
        s.typing("starry", "Nova");
        await s.wait(1200);
        s.arrive("map");
        await s.wait(600);
        for (var d = 0; d < 3; d++) { showDay(d); await s.wait(3000); }
        s.typing("starry", "Nova");
        await s.wait(900);
        s.arrive("saved");
        await s.wait(4200);
      }
    };
  });

  // ------------------------------------------------------------ C. watch and take over, on a tablet
  var take = document.querySelector('[data-scene="takeover"]');
  if (take) scene(take, function (s, fig) {
    var vm = $(fig, "[data-vm]");
    var view = $(fig, "[data-vm-view]");
    var page = $(fig, "[data-vm-page]");
    var vmBtn = $(fig, "[data-vm-btn]");
    var vmWho = $(fig, "[data-vm-who]");
    var check = $(fig, "[data-vm-check]");
    var status = $(fig, "[data-vm-status]");
    var plate = $(fig, "[data-plate]");
    var zone = $(fig, "[data-zone]");
    var len12 = $(fig, '[data-len="12"]');
    var len6 = $(fig, '[data-len="6"]');
    var pay = $(fig, "[data-pay]");
    var done = $(fig, "[data-done]");
    var ask = $(fig, "[data-ask]");
    var takeBtn = $(fig, "[data-take-btn]");
    var cur = { kai: $(fig, '[data-cur="kai"]'), you: $(fig, '[data-cur="you"]') };

    // The bot's screen is laid out for at least 460×380 and scaled to fill the view, like a live view of a
    // real screen: a wider or taller view just shows more page.
    var fit = function () {
      var w = view.clientWidth, h = view.clientHeight;
      if (!w || !h) return;
      var sc = Math.min(w / 460, h / 380);
      page.style.setProperty("--vm-s", sc.toFixed(4));
      page.style.width = (w / sc) + "px";
      page.style.height = (h / sc) + "px";
    };
    if ("ResizeObserver" in window) new ResizeObserver(fit).observe(view);
    fit();

    var at = function (el, dx, dy) {
      var x = el.offsetLeft + (dx == null ? el.offsetWidth / 2 : dx);
      var y = el.offsetTop + (dy == null ? el.offsetHeight / 2 : dy);
      for (var p = el.offsetParent; p && p !== page; p = p.offsetParent) { x += p.offsetLeft; y += p.offsetTop; }
      return [x, y];
    };
    var place = function (who, xy, instant) {
      var c = cur[who];
      if (instant) c.style.transition = "none";
      c.style.transform = "translate(" + xy[0] + "px," + xy[1] + "px)";
      if (instant) { void c.offsetWidth; c.style.transition = ""; }
    };
    var press = async function (who, el) {
      cur[who].classList.add("press");
      if (el) el.classList.add("press");
      await s.wait(160);
      cur[who].classList.remove("press");
      if (el) el.classList.remove("press");
    };
    var tap = async function (btn) {
      btn.classList.add("tapped");
      await s.wait(220);
      btn.classList.remove("tapped");
    };
    var setLen = function (six) {
      len6.classList.toggle("on", six);
      len12.classList.toggle("on", !six);
      pay.textContent = six ? "Pay $26" : "Pay $48";
    };
    var control = function (you) {
      vm.classList.toggle("taken", you);
      vmBtn.textContent = you ? "Hand back" : "Take over";
      vmWho.textContent = you ? "You're in control" : "Live";
    };

    return {
      fadeAlso: [view],
      reset: function () {
        control(false);
        ask.classList.remove("asking", "answered");
        plate.textContent = "";
        zone.textContent = "Choose a zone";
        zone.style.color = "#9a97a0";
        setLen(false);
        done.classList.remove("on");
        check.textContent = "Checkpoint 0";
        status.textContent = "Idle";
        cur.you.classList.remove("show");
        cur.kai.classList.remove("show");
        place("kai", [page.offsetWidth - 70, page.offsetHeight - 60], true);
      },
      play: async function () {
        await s.wait(300);
        s.arrive("you");
        await s.wait(800);
        s.typing("thinker", "Kai");
        await s.wait(900);
        s.arrive("ack");
        status.textContent = "Working";
        cur.kai.classList.add("show");
        await s.wait(400);
        place("kai", at(plate, 60));
        await s.wait(900);
        await press("kai");
        plate.classList.add("focus");
        var text = "7KDM214";
        for (var i = 1; i <= text.length; i++) { plate.textContent = text.slice(0, i); await s.wait(90); }
        plate.classList.remove("focus");
        check.textContent = "Checkpoint 1 saved";
        place("kai", at(zone, 80));
        await s.wait(900);
        await press("kai");
        zone.classList.add("focus");
        await s.wait(350);
        zone.textContent = "Zone 4 · Riverside";
        zone.style.color = "";
        await s.wait(300);
        zone.classList.remove("focus");
        check.textContent = "Checkpoint 2 saved";
        place("kai", at(len12, 40));
        await s.wait(900);
        await press("kai");
        check.textContent = "Checkpoint 3 saved";
        place("kai", at(pay));
        await s.wait(900);
        status.textContent = "Waiting for your OK";
        s.typing("thinker", "Kai");
        await s.wait(800);
        s.arrive("ask");
        ask.classList.add("asking");
        await s.wait(2400);

        await tap(takeBtn);
        ask.classList.remove("asking");
        ask.classList.add("answered");
        control(true);
        cur.kai.classList.remove("show");
        s.arrive("took");
        status.textContent = "You're in control";
        place("you", [page.offsetWidth - 120, page.offsetHeight - 40], true);
        cur.you.classList.add("show");
        await s.wait(200);
        place("you", at(len6, 50));
        await s.wait(950);
        await press("you");
        setLen(true);
        await s.wait(1000);
        await tap(vmBtn);
        control(false);
        cur.you.classList.remove("show");
        s.arrive("back");
        status.textContent = "Working";
        cur.kai.classList.add("show");
        await s.wait(300);
        place("kai", at(pay));
        await s.wait(900);
        await press("kai", pay);
        await s.wait(400);
        done.classList.add("on");
        cur.kai.classList.remove("show");
        check.textContent = "Checkpoint 4 saved";
        status.textContent = "Done";
        s.typing("thinker", "Kai");
        await s.wait(900);
        s.arrive("done");
        await s.wait(4500);
      }
    };
  });
})();
