/* Casama — casama.ai
   1. Looks: the eight looks that ship in the app. The page wears one at a time and morphs to the
      next every few seconds: every colour token blends in OKLab, the app pictures switch fonts.
   2. Field: the hero's pattern. The Casama cloud is eight circles and an ellipse; for each look
      those same shapes regroup into that look's picture (clouds, waves, hills, blossoms, a sun,
      planets, a halftone, a cairn). One small canvas, drawn only while it is on screen.
   3. The page's controls: approval card, switches, the run slider, plans, copy, reveals. */
(function () {
  "use strict";

  var root = document.documentElement;
  var reduceMQ = window.matchMedia("(prefers-reduced-motion: reduce)");
  var darkMQ = window.matchMedia("(prefers-color-scheme: dark)");
  var HOLD = 4200;
  var MORPH = 1900;
  var STORE_MODE = "casama-site-theme";
  var STORE_LOOK = "casama-site-look";

  function store(key, value) {
    try { if (value == null) localStorage.removeItem(key); else localStorage.setItem(key, value); } catch (e) {}
  }
  function read(key) {
    try { return localStorage.getItem(key); } catch (e) { return null; }
  }
  function $all(sel, el) { return Array.prototype.slice.call((el || document).querySelectorAll(sel)); }

  // ------------------------------------------------------------------ colour (sRGB <-> OKLab)
  function lin(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); }
  function delin(c) { return c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055; }
  var labCache = {};
  function toLab(hex) {
    if (labCache[hex]) return labCache[hex];
    var n = parseInt(hex.slice(1), 16);
    var r = lin((n >> 16 & 255) / 255), g = lin((n >> 8 & 255) / 255), b = lin((n & 255) / 255);
    var l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    var m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    var s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    return (labCache[hex] = [
      0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s,
      1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s,
      0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s
    ]);
  }
  function fromLab(L) {
    var l = L[0] + 0.3963377774 * L[1] + 0.2158037573 * L[2];
    var m = L[0] - 0.1055613458 * L[1] - 0.0638541728 * L[2];
    var s = L[0] - 0.0894841775 * L[1] - 1.291485548 * L[2];
    l = l * l * l; m = m * m * m; s = s * s * s;
    var rgb = [
      4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
      -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
      -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s
    ];
    var out = "#";
    for (var i = 0; i < 3; i++) {
      var v = Math.round(Math.min(1, Math.max(0, delin(rgb[i]))) * 255);
      out += (v < 16 ? "0" : "") + v.toString(16);
    }
    return out;
  }
  function mix(a, b, t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    var A = toLab(a), B = toLab(b);
    return fromLab([A[0] + (B[0] - A[0]) * t, A[1] + (B[1] - A[1]) * t, A[2] + (B[2] - A[2]) * t]);
  }
  // A light tint, carried into the dark: same hue, low lightness, gentle chroma.
  function nightTint(hex, lightness) {
    var L = toLab(hex), c = Math.sqrt(L[1] * L[1] + L[2] * L[2]), h = Math.atan2(L[2], L[1]);
    var c2 = Math.min(c * 1.25, 0.075);
    return fromLab([lightness, c2 * Math.cos(h), c2 * Math.sin(h)]);
  }

  // ------------------------------------------------------------------ the looks
  var LB = '"Libre Baskerville", Georgia, serif';
  var LATO = '"Lato", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif';
  var FRAUNCES = '"Fraunces", Georgia, serif';
  var FIGTREE = '"Figtree", -apple-system, BlinkMacSystemFont, sans-serif';
  var GSANS = '"Google Sans", -apple-system, BlinkMacSystemFont, sans-serif';

  var LOOKS = [
    { id: "casama", name: "Casama", head: LB, body: LATO, headName: "Libre Baskerville", bodyName: "Lato", field: "clouds",
      desc: "Plum and lilac with a bookish serif. The look every new workspace opens in.",
      light: { bg: "#fcf3fb", card: "#fffbfe", ink: "#1e1a20", accent: "#7a3fa8", onAccent: "#ffffff", pc: "#f1e2fc", onPc: "#2e004e", t1: "#e7cff8", t2: "#f8d3e5", t3: "#d6e0fb" },
      dark: { bg: "#1c1720", ink: "#f1e8f0", accent: "#d9b6f7", onAccent: "#25102f", pc: "#4a2361", onPc: "#f2daff" } },
    { id: "editorial", name: "Editorial", head: FRAUNCES, body: FIGTREE, headName: "Fraunces", bodyName: "Figtree", field: "cairn",
      desc: "Sepia and peach set in Fraunces and Figtree, like a well-kept magazine.",
      light: { bg: "#fdf6f0", card: "#fffcf9", ink: "#241b16", accent: "#7c4a2d", onAccent: "#ffffff", pc: "#f9e3d4", onPc: "#381c0a", t1: "#efcdb4", t2: "#f6dccd", t3: "#e8d6c3" },
      dark: { bg: "#1e1815", ink: "#eee4de", accent: "#e8b698", onAccent: "#2b160a", pc: "#56321d", onPc: "#f9e3d4" } },
    { id: "ocean", name: "Ocean", head: LB, body: LATO, headName: "Libre Baskerville", bodyName: "Lato", field: "waves",
      desc: "Deep blue and sea glass, for long and calm working sessions.",
      light: { bg: "#f2f8ff", card: "#fafdff", ink: "#14202b", accent: "#175e96", onAccent: "#ffffff", pc: "#d5e8ff", onPc: "#062745", t1: "#b9dbf7", t2: "#c6ecf3", t3: "#d3dcfb" },
      dark: { bg: "#111b24", ink: "#e0ebf5", accent: "#91c8ff", onAccent: "#072742", pc: "#124670", onPc: "#d5e8ff" } },
    { id: "forest", name: "Forest", head: LB, body: LATO, headName: "Libre Baskerville", bodyName: "Lato", field: "hills",
      desc: "Moss and fern greens that stay easy on the eyes from morning to night.",
      light: { bg: "#f3faf5", card: "#fbfefc", ink: "#16221b", accent: "#1d6b42", onAccent: "#ffffff", pc: "#d2f2df", onPc: "#062e18", t1: "#b6e2c5", t2: "#dcecbc", t3: "#c7e6dc" },
      dark: { bg: "#121d16", ink: "#e1efe6", accent: "#82d9a8", onAccent: "#072916", pc: "#154f30", onPc: "#d2f2df" } },
    { id: "sakura", name: "Sakura", head: LB, body: LATO, headName: "Libre Baskerville", bodyName: "Lato", field: "blossoms",
      desc: "Blossom pink with soft lilac and sky. Cheerful without shouting.",
      light: { bg: "#fff5f9", card: "#fffbfd", ink: "#24161c", accent: "#b33668", onAccent: "#ffffff", pc: "#ffdbe8", onPc: "#450922", t1: "#f8c0d5", t2: "#e0dafb", t3: "#cfe6fa" },
      dark: { bg: "#21151a", ink: "#f2e2e8", accent: "#f9a8c7", onAccent: "#3d0a1f", pc: "#6e1f40", onPc: "#ffdbe8" } },
    { id: "sunset", name: "Sunset", head: FRAUNCES, body: LATO, headName: "Fraunces", bodyName: "Lato", field: "sun",
      desc: "Tangerine and rose with Fraunces headings, for warm evenings of work.",
      light: { bg: "#fff7f2", card: "#fffcfa", ink: "#241914", accent: "#bf5215", onAccent: "#ffffff", pc: "#ffe1cf", onPc: "#421700", t1: "#f9c6a4", t2: "#f7cbd4", t3: "#f8e0b0" },
      dark: { bg: "#211814", ink: "#f2e5df", accent: "#f9b389", onAccent: "#3b1502", pc: "#6e2e0b", onPc: "#ffe1cf" } },
    { id: "cosmos", name: "Cosmos", head: LB, body: LATO, headName: "Libre Baskerville", bodyName: "Lato", field: "orbits",
      desc: "Indigo and lavender, a little starry, with a quiet serif.",
      light: { bg: "#f6f3ff", card: "#fcfaff", ink: "#1b1826", accent: "#5138a8", onAccent: "#ffffff", pc: "#e5deff", onPc: "#190752", t1: "#d2c6fb", t2: "#e8d3f7", t3: "#c6d0f7" },
      dark: { bg: "#171424", ink: "#e6e2f5", accent: "#c4b5fd", onAccent: "#1b0e4f", pc: "#39257a", onPc: "#e5deff" } },
    { id: "graphite", name: "Graphite", head: GSANS, body: LATO, headName: "Google Sans", bodyName: "Lato", field: "halftone",
      desc: "Cool greys and Google Sans. Nothing between you and the work.",
      light: { bg: "#f4f6f8", card: "#fcfdfe", ink: "#181b20", accent: "#363b44", onAccent: "#ffffff", pc: "#e3e6ec", onPc: "#14171c", t1: "#d3d7de", t2: "#e0e3e8", t3: "#c5cad3" },
      dark: { bg: "#15171b", ink: "#e4e7ec", accent: "#c8cdd6", onAccent: "#171a20", pc: "#343942", onPc: "#e3e6ec" } }
  ];
  var byId = {};
  LOOKS.forEach(function (l, i) { l.index = i; byId[l.id] = l; });

  // Every token the page reads, for one look in one mode.
  function tokensFor(look, dark) {
    var L = look.light;
    if (!dark) {
      return {
        "--bg": L.bg, "--bg-2": mix(L.bg, L.ink, 0.055), "--card": L.card, "--ink": L.ink, "--ink-2": mix(L.ink, L.bg, 0.3),
        "--accent": L.accent, "--on-accent": L.onAccent, "--pc": L.pc, "--on-pc": L.onPc,
        "--t1": L.t1, "--t2": L.t2, "--t3": L.t3, "--code-bg": mix(L.ink, L.accent, 0.08), "--code-ink": "#f4f0f5"
      };
    }
    var D = look.dark;
    return {
      "--bg": D.bg, "--bg-2": mix(D.bg, D.ink, 0.06), "--card": mix(D.bg, D.ink, 0.1), "--ink": D.ink, "--ink-2": mix(D.ink, D.bg, 0.3),
      "--accent": D.accent, "--on-accent": D.onAccent, "--pc": D.pc, "--on-pc": D.onPc,
      "--t1": nightTint(L.t1, 0.34), "--t2": nightTint(L.t2, 0.37), "--t3": nightTint(L.t3, 0.31),
      "--code-bg": mix(D.bg, "#000000", 0.4), "--code-ink": "#f4f0f5"
    };
  }

  function isDark() {
    var t = root.getAttribute("data-theme");
    if (t === "dark") return true;
    if (t === "light") return false;
    return darkMQ.matches;
  }

  // ------------------------------------------------------------------ state
  var current = byId.casama;
  var shown = {};          // tokens on screen now
  var morph = null;        // { from, to, fromTokens, toTokens, start, dur, swapped }
  var paused = false;
  var kept = null;
  var holdTimer = 0;
  var cycling = root.hasAttribute("data-cycle");

  try { kept = JSON.parse(read(STORE_LOOK) || "null"); } catch (e) { kept = null; }
  if (kept && byId[kept.id]) { current = byId[kept.id]; paused = true; } else { kept = null; }
  if (reduceMQ.matches) paused = true;

  function setTokens(tokens) {
    for (var k in tokens) {
      if (shown[k] !== tokens[k]) { root.style.setProperty(k, tokens[k]); shown[k] = tokens[k]; }
    }
  }

  var nameEls = $all("[data-look-name]");
  var descEl = document.querySelector("[data-look-desc]");
  var headEl = document.querySelector("[data-look-head]");
  var bodyEl = document.querySelector("[data-look-body]");
  var galleryLink = document.getElementById("gallery-look");
  var keepBtn = document.getElementById("keep-look");
  var chip = document.getElementById("look-chip");
  var chipLabel = chip && chip.querySelector("[data-chip-label]");
  var themeMeta = document.querySelector('meta[name="theme-color"]');
  var pickers = $all(".swatch[data-look], .look-tab[data-look], .ap-tile[data-look]");

  // Names, fonts and pressed states for the look now being worn.
  function showLook(look) {
    root.style.setProperty("--look-head", look.head);
    root.style.setProperty("--look-body", look.body);
    nameEls.forEach(function (el) { el.textContent = look.name; });
    if (descEl) descEl.textContent = look.desc;
    if (headEl) headEl.textContent = look.headName;
    if (bodyEl) bodyEl.textContent = look.bodyName;
    if (galleryLink) galleryLink.href = "https://gallery.casama.ai/#theme/" + look.id;
    pickers.forEach(function (b) { b.setAttribute("aria-pressed", String(b.dataset.look === look.id)); });
  }

  // Each picker shows its own look's colours in the current mode.
  function paintPickers() {
    var dark = isDark();
    pickers.forEach(function (b) {
      var look = byId[b.dataset.look];
      if (!look) return;
      var t = tokensFor(look, dark);
      if (b.classList.contains("swatch")) b.style.setProperty("--sw", t["--accent"]);
      if (b.classList.contains("ap-tile")) {
        b.style.setProperty("--tile-bg", t["--bg"]);
        b.style.setProperty("--tile-ink", t["--ink"]);
        b.style.setProperty("--tile-accent", t["--accent"]);
        b.style.setProperty("--tile-font", look.head);
      }
    });
  }

  function updateChrome() {
    if (chip) {
      chip.setAttribute("aria-pressed", String(paused));
      if (chipLabel) chipLabel.textContent = paused ? "Play the changing looks" : "Pause the changing looks";
      chip.title = paused ? "Play the looks" : "Pause on this look";
    }
    if (keepBtn) {
      var isKept = !!(kept && kept.id === current.id);
      keepBtn.setAttribute("aria-pressed", String(isKept));
      keepBtn.textContent = isKept ? "Kept on this device" : "Keep this look";
    }
  }

  // Ease in and out, gently.
  function ease(t) { return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2; }

  function goTo(look, dur) {
    clearTimeout(holdTimer);
    var dark = isDark();
    var toTokens = tokensFor(look, dark);
    if (dur <= 0 || reduceMQ.matches) {
      morph = null;
      setTokens(toTokens);
      current = look;
      showLook(look);
      field.jump(look);
      afterMorph();
      return;
    }
    var fromTokens = {};
    for (var k in toTokens) fromTokens[k] = shown[k] || toTokens[k];
    morph = { from: current, to: look, fromTokens: fromTokens, toTokens: toTokens, start: 0, dur: dur, swapped: false };
    field.morphTo(look);
    current = look;
    kick();
  }

  function afterMorph() {
    if (themeMeta) themeMeta.setAttribute("content", shown["--bg"]);
    updateChrome();
    scheduleNext();
  }

  function scheduleNext() {
    clearTimeout(holdTimer);
    if (!cycling || paused || document.hidden) return;
    holdTimer = setTimeout(function () {
      goTo(LOOKS[(current.index + 1) % LOOKS.length], MORPH);
    }, HOLD);
  }

  function pick(id, persist) {
    var look = byId[id];
    if (!look) return;
    paused = true;
    clearTimeout(holdTimer);
    if (persist) keepLook(look);
    if (look !== current || morph) goTo(look, 900);
    updateChrome();
  }

  function keepLook(look) {
    kept = { id: look.id, light: tokensFor(look, false), dark: tokensFor(look, true) };
    store(STORE_LOOK, JSON.stringify(kept));
  }

  // ------------------------------------------------------------------ the field
  var field = (function () {
    var canvas = document.getElementById("hero-field");
    var hero = canvas && canvas.parentElement;
    var stageEl = document.querySelector(".hero-stage");
    var chatEl = document.querySelector(".hero-stage .chat");
    var api = { jump: function () {}, morphTo: function () {}, draw: function () { return false; }, start: function () {}, redraw: function () {}, visible: false };
    if (!canvas || !canvas.getContext) return api;
    var ctx = canvas.getContext("2d");
    var W = 0, H = 0, dpr = 1, N = 48;
    var layouts = {};
    var from = null, to = null, morphStart = 0, morphDur = 0, layoutsFor = "";
    var lastDraw = 0;

    // The Casama cloud: centre x, centre y, x radius, y radius, in its own 256 box.
    var CLOUD = [[68, 130, 23, 23], [50, 158, 28, 28], [110, 112, 50, 50], [176, 130, 36, 36], [205, 163, 27, 27],
      [80, 189, 29, 29], [128, 197, 28, 28], [178, 190, 29, 29], [128, 158, 84, 44]];

    function rng(seed) {
      return function () {
        seed |= 0; seed = (seed + 0x6d2b79f5) | 0;
        var t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
        t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
      };
    }

    // A shape: position, radii, colour slot, layer, and how it idles.
    function shape(x, y, rx, ry, c, z, idle) {
      return { x: x, y: y, rx: rx, ry: ry == null ? rx : ry, c: c, z: z, ax: idle && idle.ax || 0, ay: idle && idle.ay || 0,
        tw: idle && idle.tw || 0, sp: idle && idle.sp || 0.5, ph: idle && idle.ph || 0 };
    }

    function cloud(out, cx, cy, w, c, z, idle) {
      var s = w / 210;
      for (var i = 0; i < CLOUD.length; i++) {
        var p = CLOUD[i];
        out.push(shape(cx + (p[0] - 127) * s, cy + (p[1] - 144) * s, p[2] * s, p[3] * s, c, z, idle));
      }
    }

    // Each look's picture, laid out around the chat. F is where the big shape gathers (beside the
    // chat on a wide screen, above it on a phone), TR the free corner up top, BL the stage's foot.
    var BUILD = {
      clouds: function (o, g) {
        var k = g.k, F = g.F;
        cloud(o, F.x, F.y, k * (g.small ? 1.5 : 1.45), "accent", 6, { ax: 5, sp: 0.18 });
        cloud(o, g.TR.x, g.TR.y, k * 0.6, "pc", 4, { ax: 9, sp: 0.22, ph: 1 });
        cloud(o, g.C.x + k * (g.small ? 0.1 : 0.16), g.C.y - k * 0.04, k * 0.26, "t2", 5, { ax: 10, sp: 0.3, ph: 2 });
        if (!g.small) {
          cloud(o, g.C.x + g.C.w + k * 0.16, g.S.y + k * 0.1, k * 0.2, "t3", 3, { ax: 14, sp: 0.26, ph: 3 });
          cloud(o, g.BL.x, g.BL.y, k * 0.22, "t1", 3, { ax: 10, sp: 0.24, ph: 4 });
        }
        for (var i = 0; i < 6; i++) o.push(shape(g.rx(), g.ry(), 3 + g.r() * 4, null, i % 2 ? "t1" : "t3", 1, { tw: 0.5, sp: 1 + g.r(), ph: g.r() * 6 }));
      },
      cairn: function (o, g) {
        var k = g.k, x = g.F.x, top = g.H + k * (g.small ? -0.05 : 0.08);
        if (g.small) top = g.C.y + k * 0.9;
        var sizes = [0.5, 0.37, 0.27, 0.19, 0.13], cols = ["accent", "pc", "t1", "accent", "t3"];
        for (var i = 0; i < sizes.length; i++) {
          var rx = k * sizes[i], ry = rx * 0.44, cy = top - ry * (i === 0 ? 0.6 : 0.78);
          o.push(shape(x + (i % 2 ? 1 : -1) * k * 0.025, cy, rx, ry, cols[i], 5 + i, { ay: 2, sp: 0.2, ph: i }));
          top = cy - ry;
        }
        var n = g.small ? 14 : 26;
        for (var j = 0; j < n; j++) {
          var r = k * (0.018 + g.r() * 0.04);
          o.push(shape(g.rx(), g.ry(), r, r * (0.55 + g.r() * 0.2), ["t1", "t2", "t3", "pc"][j % 4], 1 + (j % 3), { ay: 3, sp: 0.3, ph: g.r() * 6 }));
        }
      },
      waves: function (o, g) {
        var k = g.k, s = g.S, rows = g.small ? 3 : 4, colors = g.small ? ["t2", "pc", "accent"] : ["t3", "t2", "pc", "accent"];
        var y0 = g.small ? g.C.y - k * 0.02 : s.y + k * 0.02;
        for (var r = 0; r < rows; r++) {
          var R = k * (0.11 + 0.045 * r), y = y0 + (g.H - y0) * (r / rows) * 1.05, step = R * 1.45;
          var x0 = (g.small ? -R * 0.4 : s.x + R + 8) + (r % 2) * step * 0.5, count = Math.min(10, Math.ceil((g.W - x0 + R) / step) + 1);
          for (var i = 0; i < count; i++) o.push(shape(x0 + i * step, y, R, R, colors[r], 2 + r, { ax: 12, sp: 0.35, ph: r * 1.3 }));
        }
        var n = g.small ? 6 : 12;
        for (var j = 0; j < n; j++) {
          var b = 4 + g.r() * 9;
          o.push(shape(g.rx(), s.y - k * 0.1 + g.r() * k * 0.3, b, b, j % 2 ? "t1" : "t3", 1, { ay: 10, sp: 0.4 + g.r() * 0.4, ph: g.r() * 6 }));
        }
      },
      hills: function (o, g) {
        var k = g.k, s = g.S, H = g.H, W = g.W;
        o.push(shape(g.TR.x, g.TR.y, k * 0.11, k * 0.11, "t3", 1, { tw: 0.03, sp: 0.4 }));
        var hills = g.small
          ? [[W * 0.1, g.C.y + k * 1.0, k * 0.95, "t2", 2], [W * 0.95, g.C.y + k * 0.95, k * 0.9, "pc", 3], [W * 0.55, g.C.y + k * 1.15, k * 1.05, "accent", 6]]
          : [[s.x + k * 0.4, H + k * 0.62, k * 0.92, "t2", 2], [g.C.x + g.C.w * 0.45, H + k * 0.7, k * 0.98, "pc", 3], [W + k * 0.12, H + k * 0.52, k * 1.0, "accent", 6]];
        hills.forEach(function (h, i) { o.push(shape(h[0], h[1], h[2], h[2], h[3], h[4], { ay: 2, sp: 0.15, ph: i })); });
        // Round trees standing on the front hill.
        var front = hills[2], trees = g.small ? 4 : 6;
        for (var t = 0; t < trees; t++) {
          var tx = g.small ? W * (0.12 + t * 0.26) : g.C.x + g.C.w + (W - g.C.x - g.C.w) * (0.08 + t * 0.19);
          var dx = tx - front[0];
          var ground = front[1] - Math.sqrt(Math.max(0, front[2] * front[2] - dx * dx));
          var tr = k * (0.05 + 0.018 * ((t * 7) % 3)), ty = ground - tr * 0.9;
          var col = t % 2 ? "t1" : "pc", z = 7;
          o.push(shape(tx, ty, tr, tr * 1.15, col, z, { ax: 3, sp: 0.5, ph: t }));
          o.push(shape(tx - tr * 0.68, ty + tr * 0.55, tr * 0.72, tr * 0.72, col, z, { ax: 3, sp: 0.5, ph: t }));
          o.push(shape(tx + tr * 0.68, ty + tr * 0.55, tr * 0.72, tr * 0.72, col, z, { ax: 3, sp: 0.5, ph: t }));
        }
        var n = g.small ? 4 : 10;
        for (var j = 0; j < n; j++) o.push(shape(g.rx(), s.y - k * 0.05 + g.r() * k * 0.35, 7, 4, j % 2 ? "t1" : "t2", 1, { ax: 14, ay: 6, sp: 0.4, ph: g.r() * 6 }));
      },
      blossoms: function (o, g) {
        var k = g.k;
        function flower(cx, cy, pr, col, mid, z, ph) {
          for (var i = 0; i < 5; i++) {
            var a = -Math.PI / 2 + i * Math.PI * 2 / 5;
            o.push(shape(cx + Math.cos(a) * pr * 1.05, cy + Math.sin(a) * pr * 1.05, pr, pr, col, z, { ax: 3, ay: 3, sp: 0.3, ph: ph + i }));
          }
          o.push(shape(cx, cy, pr * 0.55, pr * 0.55, mid, z + 0.5, { tw: 0.04, sp: 0.5, ph: ph }));
        }
        flower(g.F.x, g.F.y - k * 0.06, k * 0.22, "accent", "t3", 6, 0);
        flower(g.TR.x, g.TR.y, k * 0.1, "pc", "accent", 4, 2);
        if (!g.small) {
          flower(g.BL.x, g.BL.y, k * 0.08, "t1", "t3", 3, 3);
          flower(g.C.x + g.C.w + k * 0.12, g.S.y + k * 0.1, k * 0.05, "t2", "pc", 2, 4);
        }
        var n = g.small ? 8 : 16;
        for (var j = 0; j < n; j++) {
          var pr = k * (0.012 + g.r() * 0.016);
          o.push(shape(g.rx(), g.ry(), pr * 1.3, pr, ["t1", "t2", "pc"][j % 3], 1, { ax: 10, ay: 12, sp: 0.35 + g.r() * 0.3, ph: g.r() * 6 }));
        }
      },
      sun: function (o, g) {
        var k = g.k, cx = g.F.x, cy = g.small ? g.C.y + k * 0.5 : g.H - k * 0.02;
        var rings = [[0.95, "t3"], [0.78, "t2"], [0.62, "t1"], [0.47, "pc"], [0.34, "accent"]];
        for (var i = 0; i < rings.length; i++) o.push(shape(cx, cy, k * rings[i][0], k * rings[i][0], rings[i][1], 2 + i, { tw: 0.012, sp: 0.25, ph: i * 0.6 }));
        var arcs = g.small ? 2 : 3, per = g.small ? 9 : 12;
        for (var a = 0; a < arcs; a++) {
          var R = k * (1.06 + a * 0.13);
          for (var j = 0; j < per; j++) {
            var ang = Math.PI * (1.04 + 0.92 * (j + (a % 2) * 0.5) / per);
            var x = cx + Math.cos(ang) * R, y = cy + Math.sin(ang) * R, d = 3 + a * 1.6;
            if (x < g.S.x - 10) { x = g.S.x + g.r() * 40; d = 0; }
            o.push(shape(x, y, d, d, a === 1 ? "accent" : "t1", 1, { tw: 0.45, sp: 0.8, ph: j * 0.7 + a }));
          }
        }
      },
      orbits: function (o, g) {
        var k = g.k, px = g.F.x, py = g.F.y;
        o.push(shape(px, py, k * 0.62, k * 0.13, "t2", 4, { ay: 3, sp: 0.2 }));
        o.push(shape(px, py, k * 0.36, k * 0.36, "accent", 5, { ay: 3, sp: 0.2 }));
        o.push(shape(px - k * 0.34, py - k * 0.44, k * 0.07, k * 0.07, "pc", 6, { ax: 8, ay: 5, sp: 0.3 }));
        o.push(shape(px + k * 0.08, py - k * 0.52, k * 0.045, k * 0.045, "t1", 6, { ax: 6, ay: 6, sp: 0.35, ph: 2 }));
        o.push(shape(g.TR.x, g.TR.y + k * 0.06, k * 0.15, k * 0.15, "t3", 2, { ay: 6, sp: 0.2, ph: 1 }));
        o.push(shape(g.TR.x - k * 0.06, g.TR.y + k * 0.04, k * 0.15, k * 0.15, "bg", 2.5, { ay: 6, sp: 0.2, ph: 1 }));
        var n = g.small ? 18 : 32;
        for (var j = 0; j < n; j++) {
          var d = 2 + g.r() * 4;
          o.push(shape(g.rx(), g.ry(), d, d, ["t1", "t3", "accent", "pc"][j % 4], 1, { tw: 0.75, sp: 0.6 + g.r() * 1.2, ph: g.r() * 6 }));
        }
      },
      halftone: function (o, g) {
        var s = g.S, cols = g.small ? 6 : 8, rows = g.small ? 5 : 6;
        var x0 = g.small ? 0 : s.x, y0 = g.small ? s.y + 14 : s.y - 10;
        var step = Math.max((g.W - x0) / (cols - 0.6), (g.H - y0) / (rows - 0.4));
        for (var r = 0; r < rows; r++) {
          for (var c = 0; c < cols; c++) {
            var f = g.small
              ? Math.min(1.12, Math.max(0.1, (c / (cols - 1)) * 0.75 + (1 - r / (rows - 1)) * 0.55 - 0.15))
              : Math.min(1.12, Math.max(0.1, (c / (cols - 1)) * 0.6 + (r / (rows - 1)) * 0.7 - 0.2));
            var rad = step * 0.5 * f;
            o.push(shape(x0 + step * (c + 0.2), y0 + step * (r + 0.2), rad, rad, f > 0.55 ? "accent" : (f > 0.3 ? "t3" : "t1"), 2 + f, { tw: 0.06, sp: 0.6, ph: (c + r) * 0.45 }));
          }
        }
      }
    };

    function rectIn(el, h) {
      if (!el) return null;
      var r = el.getBoundingClientRect();
      return { x: r.left - h.left, y: r.top - h.top, w: r.width, h: r.height };
    }

    // Line boxes of the hero's words, so small shapes keep off them.
    var textEls = $all(".hero h1, .hero-lede, .hero-actions, .hero-note");
    function textBoxes(h) {
      var out = [];
      textEls.forEach(function (el) {
        var rects = el.tagName === "H1" && document.createRange ? (function () { var r = document.createRange(); r.selectNodeContents(el); return r.getClientRects(); })() : [el.getBoundingClientRect()];
        for (var i = 0; i < rects.length; i++) {
          var r = rects[i];
          if (r.width && r.height) out.push({ x0: r.left - h.left - 10, x1: r.right - h.left + 10, y0: r.top - h.top - 6, y1: r.bottom - h.top + 6 });
        }
      });
      return out;
    }
    function hitsText(sh, boxes) {
      for (var i = 0; i < boxes.length; i++) {
        var b = boxes[i];
        if (sh.x + sh.rx > b.x0 && sh.x - sh.rx < b.x1 && sh.y + sh.ry > b.y0 && sh.y - sh.ry < b.y1) return true;
      }
      return false;
    }

    function geometry() {
      var h = hero.getBoundingClientRect();
      var st = rectIn(stageEl, h) || { x: W * 0.4, y: H * 0.4, w: W * 0.6, h: H * 0.6 };
      var C = rectIn(chatEl, h) || { x: st.x + 40, y: st.y + 40, w: st.w * 0.6, h: st.h };
      var S = { x: st.x, y: st.y, w: Math.max(80, W - st.x), h: Math.max(80, H - st.y) };
      var small = W < 700;
      var k = small ? Math.min(W, 520) * 0.95 : Math.min(S.w * 0.78, H * 0.9);
      var right = C.x + C.w;
      return {
        W: W, H: H, S: S, C: C, k: k, small: small,
        F: small ? { x: W * 0.62, y: C.y + k * 0.46 } : { x: right - Math.min(60, (W - right) * 0.2) + k * 0.12, y: H - k * 0.1 },
        TR: small ? { x: W - k * 0.06, y: S.y + k * 0.2 } : { x: W - k * 0.1, y: S.y + k * 0.03 },
        BL: { x: S.x + k * 0.16, y: H - k * 0.06 },
        // Free spots for the small pieces: beside and above the chat, never under the words.
        zones: small
          ? [{ x0: 0, x1: W, y0: S.y + 8, y1: C.y - 8 }]
          : [{ x0: C.x + C.w + 8, x1: W, y0: S.y - k * 0.1, y1: H }, { x0: C.x, x1: W, y0: S.y - k * 0.04, y1: C.y - 6 }],
        text: textBoxes(h)
      };
    }

    function build(look) {
      if (layouts[look.id]) return layouts[look.id];
      var g = geometry(), out = [];
      g.r = rng(look.index * 7919 + 11);
      // Small pieces land in a free zone: pick the zone with rx, then a height inside it with ry.
      var zone = g.zones[0];
      g.rx = function () { zone = g.zones[g.r() < 0.72 || g.zones.length < 2 ? 0 : 1]; return zone.x0 + g.r() * (zone.x1 - zone.x0); };
      g.ry = function () { return zone.y0 + g.r() * (zone.y1 - zone.y0); };
      BUILD[look.field](out, g);
      // On a phone the stage sits close under the note, so the picture moves down until no big shape
      // climbs above the stage and behind the words.
      if (g.small) {
        var top = Infinity;
        out.forEach(function (sh) { if (Math.max(sh.rx, sh.ry) >= g.k * 0.09) top = Math.min(top, sh.y - sh.ry - sh.ay); });
        var drop = g.S.y - top;
        if (drop > 0) out.forEach(function (sh) { sh.y += drop; });
      }
      // Nothing small sits on the words; big soft shapes may pass behind them.
      out.forEach(function (sh) {
        if (Math.max(sh.rx, sh.ry) < g.k * 0.09 && hitsText(sh, g.text)) { sh.rx = 0; sh.ry = 0; }
      });
      out.sort(function (a, b) { return a.z - b.z; });
      // Same number of shapes in every look, so each one has somewhere to go.
      while (out.length < N) {
        var src = out[(out.length * 7) % out.length];
        out.splice((out.length * 5) % out.length, 0, shape(src.x, src.y, 0, 0, src.c, src.z, null));
      }
      if (out.length > N) out.length = N;
      return (layouts[look.id] = out);
    }

    function resize() {
      var r = hero.getBoundingClientRect();
      W = Math.round(r.width); H = Math.round(r.height);
      dpr = Math.min(window.devicePixelRatio || 1, 2);
      canvas.width = Math.round(W * dpr); canvas.height = Math.round(H * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      N = W < 700 ? 40 : 56;
      layouts = {};
      var key = W + "x" + H;
      if (layoutsFor !== key) { layoutsFor = key; }
      if (to) {
        var look = byId[to.id];
        to = { id: look.id, shapes: build(look) };
        from = null;
      }
      draw(performance.now(), true);
    }

    function colorOf(slot) { return shown["--" + slot] || "#000000"; }

    var last = { fromColors: null };
    function draw(now, force) {
      if (!to || !api.visible) return false;
      var still = reduceMQ.matches;
      if (!force && !morphStart && !still && now - lastDraw < (W < 700 ? 50 : 33)) return true;
      lastDraw = now;
      var p = 1;
      if (morphStart) {
        p = Math.min(1, (now - morphStart) / morphDur);
        if (p >= 1) { morphStart = 0; from = null; }
      }
      var time = now / 1000;
      ctx.clearRect(0, 0, W, H);
      var A = from && from.shapes, B = to.shapes;
      for (var i = 0; i < B.length; i++) {
        var b = B[i], x, y, rx, ry, col;
        if (A && p < 1) {
          var a = A[i];
          // A sweep: shapes on the left set off first.
          var delay = 0.32 * Math.min(1, Math.max(0, (b.x + a.x) / (2 * W)));
          var q = ease(Math.min(1, Math.max(0, (p - delay) / 0.66)));
          x = a.x + (b.x - a.x) * q; y = a.y + (b.y - a.y) * q;
          rx = a.rx + (b.rx - a.rx) * q; ry = a.ry + (b.ry - a.ry) * q;
          col = mix(from.colors[a.c] || colorOf(a.c), colorOf(b.c), q);
        } else {
          x = b.x; y = b.y; rx = b.rx; ry = b.ry; col = colorOf(b.c);
        }
        if (rx < 0.4 || ry < 0.4) continue;
        if (!still) {
          var w = Math.sin(time * b.sp + b.ph);
          x += b.ax * w; y += b.ay * Math.cos(time * b.sp * 0.8 + b.ph);
          if (b.tw) { var sc = 1 - b.tw * (0.5 + 0.5 * w); rx *= sc; ry *= sc; }
        }
        ctx.fillStyle = col;
        ctx.beginPath();
        ctx.ellipse(x, y, rx, ry, 0, 0, 6.283185307);
        ctx.fill();
      }
      return !still || !!morphStart;
    }

    // Colours of the outgoing look stay fixed while its shapes leave.
    function snapshotColors() {
      var c = {};
      ["accent", "pc", "t1", "t2", "t3", "bg"].forEach(function (k) { c[k] = colorOf(k); });
      return c;
    }

    api.jump = function (look) {
      to = { id: look.id, shapes: build(look) };
      from = null; morphStart = 0;
      draw(performance.now(), true);
    };
    api.morphTo = function (look) {
      var now = performance.now();
      if (to) {
        // Mid-morph: start from where the shapes are heading, which is close enough.
        from = { id: to.id, shapes: to.shapes, colors: snapshotColors() };
      }
      to = { id: look.id, shapes: build(look) };
      morphStart = now; morphDur = MORPH * 0.95;
      if (reduceMQ.matches) { from = null; morphStart = 0; }
    };
    api.draw = draw;
    api.redraw = function () { draw(performance.now(), true); };

    var ro = window.ResizeObserver ? new ResizeObserver(function () { resize(); kick(); }) : null;
    if (ro) ro.observe(hero); else window.addEventListener("resize", function () { resize(); kick(); });
    if ("IntersectionObserver" in window) {
      new IntersectionObserver(function (entries) {
        api.visible = entries[0].isIntersecting;
        if (api.visible) kick();
      }).observe(hero);
    } else {
      api.visible = true;
    }
    api.start = function (look) { api.visible = api.visible || !("IntersectionObserver" in window); resize(); api.jump(look); };
    return api;
  })();

  // ------------------------------------------------------------------ one frame loop
  var raf = 0;
  function kick() { if (!raf && !document.hidden) raf = requestAnimationFrame(frame); }
  function frame(now) {
    raf = 0;
    var again = false;
    if (morph) {
      if (!morph.start) morph.start = now;
      var p = Math.min(1, (now - morph.start) / morph.dur);
      if (p >= 1 || !morph.last || now - morph.last >= 30) {
        morph.last = now;
        var e = ease(p), out = {};
        for (var k in morph.toTokens) out[k] = mix(morph.fromTokens[k], morph.toTokens[k], e);
        setTokens(out);
      }
      if (!morph.swapped && p >= 0.45) { morph.swapped = true; showLook(morph.to); }
      if (p >= 1) { morph = null; afterMorph(); } else again = true;
    }
    if (field.draw(now, !!morph)) again = true;
    if (again) raf = requestAnimationFrame(frame);
  }

  document.addEventListener("visibilitychange", function () {
    if (document.hidden) { clearTimeout(holdTimer); if (raf) { cancelAnimationFrame(raf); raf = 0; } }
    else { kick(); if (!morph) scheduleNext(); }
  });

  // ------------------------------------------------------------------ start
  setTokens(tokensFor(current, isDark()));
  showLook(current);
  paintPickers();
  field.start(current);
  updateChrome();
  if (chip && cycling) chip.hidden = false;
  if (themeMeta) themeMeta.setAttribute("content", shown["--bg"]);

  // Warm the faces other looks use, once the page has settled.
  var idle = window.requestIdleCallback || function (fn) { return setTimeout(fn, 1200); };
  window.addEventListener("load", function () {
    idle(function () {
      if (document.fonts && document.fonts.load) {
        ["600 1em Fraunces", "400 1em Figtree", "600 1em Figtree", "500 1em 'Google Sans'", "700 1em 'Google Sans'"].forEach(function (f) {
          document.fonts.load(f).catch(function () {});
        });
      }
    });
  });

  // First change comes a little sooner than the rest, once the hero has opened.
  if (cycling && !paused) {
    holdTimer = setTimeout(function () { goTo(LOOKS[(current.index + 1) % LOOKS.length], MORPH); }, 3600);
  }

  // ------------------------------------------------------------------ look controls
  pickers.forEach(function (b) {
    b.addEventListener("click", function () { pick(b.dataset.look, false); });
  });
  if (chip) {
    chip.addEventListener("click", function () {
      paused = !paused;
      if (!paused) {
        kept = null;
        store(STORE_LOOK, null);
        goTo(LOOKS[(current.index + 1) % LOOKS.length], MORPH);
      } else {
        clearTimeout(holdTimer);
      }
      updateChrome();
    });
  }
  if (keepBtn) {
    keepBtn.addEventListener("click", function () {
      if (kept && kept.id === current.id) {
        kept = null;
        store(STORE_LOOK, null);
      } else {
        paused = true;
        clearTimeout(holdTimer);
        keepLook(current);
      }
      updateChrome();
    });
  }

  function applyMode() {
    paintPickers();
    var t = tokensFor(current, isDark());
    if (morph) { morph.toTokens = t; } else { goTo(current, 450); }
  }
  $all("[data-theme-toggle]").forEach(function (toggle) {
    toggle.addEventListener("click", function () {
      var next = isDark() ? "light" : "dark";
      root.setAttribute("data-theme", next);
      store(STORE_MODE, next);
      applyMode();
    });
  });
  if (darkMQ.addEventListener) darkMQ.addEventListener("change", function () { if (!root.getAttribute("data-theme")) applyMode(); });

  // ------------------------------------------------------------------ header over the hero
  var header = document.querySelector(".site-header");
  var heroEl = document.querySelector(".hero");
  if (header && heroEl && "IntersectionObserver" in window) {
    var sentinel = document.createElement("div");
    sentinel.style.cssText = "position:absolute;top:0;left:0;width:1px;height:1px;pointer-events:none"; // taste-skill-ignore: invisible scroll sentinel
    heroEl.appendChild(sentinel);
    new IntersectionObserver(function (entries) {
      header.classList.toggle("over-hero", entries[0].isIntersecting);
    }, { rootMargin: "-8px 0px 0px 0px" }).observe(sentinel);
  }

  // ------------------------------------------------------------------ reveals
  // The hero (its chat and its copy) opens right away; everything else rises as it scrolls in.
  // The hero's note sits low enough that the scroll trigger below could miss it.
  var shutters = $all(".shutter, .hero [data-reveal]");
  requestAnimationFrame(function () { setTimeout(function () { shutters.forEach(function (el) { el.classList.add("is-in"); }); }, 120); });
  var revealEls = $all("[data-reveal]").filter(function (el) { return !el.closest(".hero"); });
  if ("IntersectionObserver" in window && !reduceMQ.matches) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (!en.isIntersecting) return;
        en.target.classList.add("is-in");
        io.unobserve(en.target);
      });
    }, { rootMargin: "0px 0px -10% 0px", threshold: 0.08 });
    revealEls.forEach(function (el) { io.observe(el); });
    window.addEventListener("load", function () {
      setTimeout(function () {
        revealEls.forEach(function (el) {
          var r = el.getBoundingClientRect();
          if (r.top < innerHeight && r.bottom > 0) el.classList.add("is-in");
        });
      }, 2400);
    });
  } else {
    revealEls.forEach(function (el) { el.classList.add("is-in"); });
  }

  // ------------------------------------------------------------------ the approval card
  var ask = document.getElementById("ask-card");
  if (ask) {
    var askText = ask.querySelector("[data-ask-text]");
    var askReply = document.querySelector("[data-ask-reply]");
    var original = askText.innerHTML;
    var resetTimer = 0;
    $all("[data-ask]", ask).forEach(function (b) {
      b.addEventListener("click", function () {
        var yes = b.dataset.ask === "yes";
        ask.dataset.state = "done";
        askText.textContent = yes ? "Approved. Booking flights and hotel." : "Denied. Checkpoint 7 restored.";
        askReply.textContent = yes
          ? "Booked. The confirmations are in your inbox and on your calendar. That task cost $0.019."
          : "Okay, nothing was booked. I rolled my computer back to checkpoint 7.";
        askReply.hidden = false;
        clearTimeout(resetTimer);
        resetTimer = setTimeout(function () {
          ask.dataset.state = "ask";
          askText.innerHTML = original;
          askReply.hidden = true;
        }, 7000);
      });
    });
  }

  // ------------------------------------------------------------------ switches
  $all(".toggle[role='switch']").forEach(function (t) {
    t.addEventListener("click", function () {
      var on = t.getAttribute("aria-checked") !== "true";
      t.setAttribute("aria-checked", String(on));
      var band = t.closest(".band");
      if (band) band.classList.toggle("is-on", on);
    });
  });

  // ------------------------------------------------------------------ how a run works
  var range = document.getElementById("how-range");
  var split = document.querySelector(".how-split");
  if (range && split) {
    var STAGES = [
      null,
      { clause: "First, you ask in plain words.", note: "Type it, say it, or forward an email. Put it on the board if it can wait.", state: "Reading", stop: "Ask" },
      { clause: "Then it works on its own computer.", note: "It browses, compares prices, fills in forms and writes files, without touching your own devices.", state: "Working", stop: "Work" },
      { clause: "It stops before anything risky.", note: "Sending, booking, paying or deleting waits for your OK, on your phone or here.", state: "Waiting for you", stop: "Check" },
      { clause: "Last, it reports back with the cost.", note: "Every step it took, and what it cost, down to a tenth of a cent.", state: "Done", stop: "Report" }
    ];
    var clause = split.querySelector("[data-how-clause]");
    var note = split.querySelector("[data-how-note]");
    var hfState = split.querySelector("[data-hf-state]");
    var stops = $all(".how-stops li");
    var swapT = 0;
    var setStage = function (n, instant) {
      var st = STAGES[n];
      range.style.setProperty("--fill", ((n - 1) / 3 * 100) + "%");
      range.setAttribute("aria-valuetext", st.stop);
      stops.forEach(function (li) { li.classList.toggle("is-on", Number(li.dataset.stop) === n); });
      split.dataset.stage = String(n);
      hfState.textContent = st.state;
      clearTimeout(swapT);
      if (instant || reduceMQ.matches) { clause.textContent = st.clause; note.textContent = st.note; return; }
      split.classList.add("swapping");
      swapT = setTimeout(function () {
        clause.textContent = st.clause; note.textContent = st.note;
        split.classList.remove("swapping");
      }, 200);
    };
    range.addEventListener("input", function () { setStage(Number(range.value)); });
    setStage(Number(range.value) || 1, true);
  }

  // ------------------------------------------------------------------ plans
  var PLANS = {
    self: { price: "$0", period: "forever, on your own server", cta: "Read the self-hosting guide", href: "https://docs.casama.ai/self-hosting/", meter: null,
      what: "The whole stack in Docker on a VPS, a home server or your laptop, or from the Mac and Linux app. Unlimited users and bots, any model or your own keys, and nothing phones home." },
    free: { price: "$0", period: "a month", cta: "Start on Free", href: "https://app.casama.ai", meter: ["$0.58", "About 30 more runs", 42, "$0.42 of $1.00 used this month"],
      what: "$1 of credits every month, 2 bots, 1 cloud computer with 5 hours of computer time, and 1 seat. Continue with Google or Apple and start in seconds." },
    plus: { price: "$15", period: "a month, or $150 a year", cta: "Get Plus", href: "https://app.casama.ai", meter: ["$3.10", "About 160 more runs", 38, "$1.90 of $5.00 used this month"],
      what: "$5 of credits every month, 5 bots, 2 cloud computers with 30 hours of computer time, and 2 seats. Buy credit packs when a busy month needs more." },
    pro: { price: "$39", period: "a month, or $390 a year", cta: "Get Pro", href: "https://app.casama.ai", meter: ["$5.80", "About 300 more runs", 42, "$4.20 of $10.00 used this month"],
      what: "$10 of credits every month, 20 bots, 5 cloud computers with 100 hours of computer time, and 5 seats for your team." },
    max: { price: "$149", period: "a month, or $1,490 a year", cta: "Get Max", href: "https://app.casama.ai", meter: ["$31.40", "About 1,650 more runs", 37, "$18.60 of $50.00 used this month"],
      what: "$50 of credits every month, 50 bots, 10 cloud computers with 400 hours of computer time, and 10 seats." }
  };
  var planTabs = $all(".plan-name");
  var planStage = document.getElementById("plan-stage");
  if (planTabs.length && planStage) {
    var priceEl = planStage.querySelector("[data-plan-price]");
    var periodEl = planStage.querySelector("[data-plan-period]");
    var whatEl = planStage.querySelector("[data-plan-what]");
    var ctaEl = planStage.querySelector("[data-plan-cta]");
    var meterEl = planStage.querySelector("[data-plan-meter]");
    var planT = 0;
    var choose = function (tab, focus) {
      var plan = PLANS[tab.dataset.plan];
      if (!plan || tab.getAttribute("aria-selected") === "true") { if (focus) tab.focus(); return; }
      planTabs.forEach(function (t) {
        var on = t === tab;
        t.setAttribute("aria-selected", String(on));
        t.tabIndex = on ? 0 : -1;
      });
      planStage.setAttribute("aria-labelledby", tab.id);
      if (focus) tab.focus();
      var fill = function () {
        priceEl.textContent = plan.price; periodEl.textContent = plan.period;
        whatEl.textContent = plan.what; ctaEl.textContent = plan.cta; ctaEl.href = plan.href;
        if (meterEl) {
          meterEl.hidden = !plan.meter;
          if (plan.meter) {
            meterEl.querySelector("[data-meter-left]").textContent = plan.meter[0];
            meterEl.querySelector("[data-meter-runs]").textContent = plan.meter[1];
            meterEl.querySelector("[data-meter-fill]").style.width = plan.meter[2] + "%";
            meterEl.querySelector("[data-meter-used]").textContent = plan.meter[3];
          }
        }
      };
      clearTimeout(planT);
      if (reduceMQ.matches) { fill(); return; }
      planStage.classList.add("swapping");
      planT = setTimeout(function () { fill(); planStage.classList.remove("swapping"); }, 200);
    };
    planTabs.forEach(function (tab, i) {
      tab.addEventListener("click", function () { choose(tab, false); });
      tab.addEventListener("keydown", function (e) {
        var to = null;
        if (e.key === "ArrowDown" || e.key === "ArrowRight") to = planTabs[(i + 1) % planTabs.length];
        if (e.key === "ArrowUp" || e.key === "ArrowLeft") to = planTabs[(i - 1 + planTabs.length) % planTabs.length];
        if (e.key === "Home") to = planTabs[0];
        if (e.key === "End") to = planTabs[planTabs.length - 1];
        if (to) { e.preventDefault(); choose(to, true); }
      });
    });
  }

  // ------------------------------------------------------------------ copy the install command
  var copyBtn = document.getElementById("copy-install");
  var code = document.getElementById("install-code");
  if (copyBtn && code) {
    copyBtn.addEventListener("click", function () {
      var done = function (ok) {
        copyBtn.textContent = ok ? "Copied" : "Select it";
        setTimeout(function () { copyBtn.textContent = "Copy"; }, 1800);
      };
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(code.textContent.trim()).then(function () { done(true); }, function () { done(false); });
      } else {
        done(false);
      }
    });
  }

  // Close the menu after a jump.
  var menu = document.querySelector(".menu");
  if (menu) $all("a", menu).forEach(function (a) { a.addEventListener("click", function () { menu.removeAttribute("open"); }); });
})();
