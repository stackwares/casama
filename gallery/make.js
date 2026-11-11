/*!
 * Casama gallery: make a look. Builds a theme, color scheme or wallpaper, previews it with
 * gallery.js the way the app draws it, checks it with the gallery's rules (README.md) and hands
 * over the files. Nothing is sent anywhere; GitHub links carry the file in the URL.
 */
(function () {
  "use strict";
  var G = window.CasamaGallery;
  var REPO = "https://github.com/stackwares/casama-gallery";
  var ID = /^[a-z0-9][a-z0-9-]{0,62}$/;
  var TAG = /^[a-z0-9][a-z0-9-]{0,23}$/;
  var HEX = /^#[0-9A-Fa-f]{6}$/;
  // The app's font list (gallery/check.mjs).
  var FONTS = [
    "Libre Baskerville", "Lato", "Google Sans", "Noto Serif", "Fraunces", "Figtree", "Inter",
    "Plus Jakarta Sans", "DM Sans", "Manrope", "Nunito", "Outfit", "Poppins", "Lexend", "Work Sans",
    "Rubik", "Sora", "Urbanist", "Quicksand", "Onest", "Geist", "Atkinson Hyperlegible", "IBM Plex Sans",
    "Noto Sans", "Source Sans 3", "Open Sans", "Roboto", "Playfair Display", "Instrument Serif",
    "DM Serif Display", "Young Serif", "Lora", "Newsreader", "Source Serif 4", "Merriweather",
    "EB Garamond", "Crimson Pro", "Bricolage Grotesque", "Space Grotesk", "Fredoka", "Baloo 2",
  ];
  var COLOR_LABELS = {
    seed: "Seed", background: "Background", onBackground: "Text",
    primary: "Primary", primaryContainer: "Primary container", secondary: "Secondary",
    secondaryContainer: "Secondary container", tertiary: "Tertiary", tertiaryContainer: "Tertiary container",
    appBar: "App bar",
  };
  var MIN_LIGHT = 0.55;
  var MAX_DARK = 0.05;

  function $(id) { return document.getElementById(id); }
  function el(tag, cls, text) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text != null) n.textContent = text;
    return n;
  }
  function copyMesh(name) {
    var p = G.PALETTES[name];
    return { light: p.light.slice(), dark: p.dark.slice(), points: p.points.map(function (x) { return x.slice(); }) };
  }

  var state = {
    kind: "theme",
    exact: false,
    scheme: {
      light: { seed: "#9C3A9E", background: "#FDF3F8", onBackground: "#201A1E", primary: "#9C3A9E", primaryContainer: "#FFD6F8", secondary: "#B8407F", secondaryContainer: "#FFD9EA", tertiary: "#5562CF", tertiaryContainer: "#E0E2FF", appBar: "#FCF3FB" },
      dark: { seed: "#F2B0EC", background: "#211920", onBackground: "#EBDFE6", primary: "#F2B0EC", primaryContainer: "#6B1F69", secondary: "#FFB1D4", secondaryContainer: "#7A2152", tertiary: "#BDC2FF", tertiaryContainer: "#323C8A", appBar: "#25102F" },
    },
    headingFont: "Fraunces",
    bodyFont: "Figtree",
    bg: "palette",
    palette: "casama",
    mesh: copyMesh("casama"),
    fallbackPalette: "casama",
    pat: "builtin",
    pattern: "clouds",
    fallbackPattern: "clouds",
    glyphs: [],
    intensity: 0.5,
    previewDark: false,
  };
  var lucide = null;       // name → nodes, once fetched
  var lucideLoading = false;

  // ------------------------------------------------------------ form setup
  function fillSelect(select, values, labels, value) {
    select.textContent = "";
    values.forEach(function (v) {
      var o = el("option", null, labels ? labels[v] || v : v);
      o.value = v;
      select.appendChild(o);
    });
    select.value = value;
  }

  function colorField(label, value, onInput) {
    var wrap = el("label", "mk-color");
    var input = el("input");
    input.type = "color";
    input.value = value.toLowerCase();
    var text = el("input", "mk-hex");
    text.value = value.toUpperCase();
    text.maxLength = 7;
    text.spellcheck = false;
    text.setAttribute("aria-label", label + " hex");
    input.addEventListener("input", function () { text.value = input.value.toUpperCase(); onInput(text.value); });
    text.addEventListener("input", function () {
      var v = text.value.trim();
      if (v && v[0] !== "#") v = "#" + v;
      if (HEX.test(v)) { input.value = v.toLowerCase(); onInput(v.toUpperCase()); }
    });
    var name = el("span", "mk-color-name", label);
    var badge = el("span", "mk-badge");
    wrap.appendChild(input);
    wrap.appendChild(name);
    wrap.appendChild(text);
    wrap.appendChild(badge);
    wrap.badge = badge;
    return wrap;
  }

  var schemeBadges = { light: {}, dark: {} };
  function buildScheme() {
    var host = $("scheme-modes");
    host.textContent = "";
    ["light", "dark"].forEach(function (mode) {
      var box = el("div", "mk-mode");
      box.appendChild(el("h3", null, mode === "light" ? "Light" : "Dark"));
      var keys = ["seed", "background", "onBackground"];
      if (state.exact) keys = keys.concat(G.SCHEME_COLORS, ["appBar"]);
      keys.forEach(function (k) {
        var f = colorField(COLOR_LABELS[k], state.scheme[mode][k], function (v) {
          state.scheme[mode][k] = v;
          if (k === "primary") state.scheme[mode].seed = v;
          update();
        });
        schemeBadges[mode][k] = f.badge;
        box.appendChild(f);
      });
      host.appendChild(box);
    });
  }

  var meshInputs = { light: [], dark: [] };
  function buildMeshGrid() {
    ["light", "dark"].forEach(function (mode) {
      var host = $("mesh-" + mode);
      host.textContent = "";
      meshInputs[mode] = state.mesh[mode].map(function (c, i) {
        var input = el("input");
        input.type = "color";
        input.value = c.toLowerCase();
        input.setAttribute("aria-label", (mode === "light" ? "Light" : "Dark") + " color " + (i + 1));
        input.addEventListener("input", function () { state.mesh[mode][i] = input.value.toUpperCase(); update(); });
        host.appendChild(input);
        return input;
      });
    });
  }

  function setPressed(groupId, attr, value) {
    $(groupId).querySelectorAll("button").forEach(function (b) { b.setAttribute("aria-pressed", String(b.getAttribute(attr) === value)); });
  }

  // ------------------------------------------------------------ lucide doodles
  function loadLucide() {
    if (lucide || lucideLoading) return;
    lucideLoading = true;
    $("glyph-count").textContent = "Loading icons…";
    fetch("assets/lucide/icon-nodes.json")
      .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
      .then(function (data) { lucide = data; lucideLoading = false; renderGlyphResults(); update(); })
      .catch(function () { lucideLoading = false; $("glyph-count").textContent = "Couldn't load the icons. Try again in a moment."; });
  }

  function iconSvg(nodes, size) {
    var span = el("span", "mk-ico");
    span.innerHTML = "<svg viewBox='0 0 24 24' width='" + size + "' height='" + size + "' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' aria-hidden='true'>" + G.nodesMarkup(nodes) + "</svg>";
    return span;
  }

  function renderGlyphResults() {
    var host = $("glyph-results");
    host.textContent = "";
    if (!lucide) return;
    var q = $("f-glyph-q").value.trim().toLowerCase();
    var names = Object.keys(lucide);
    var found = q ? names.filter(function (n) { return n.indexOf(q) !== -1; }) : names.slice(0, 0);
    if (q && !found.length) host.appendChild(el("p", "mk-hint", "No icons match."));
    found.slice(0, 60).forEach(function (name) {
      var b = el("button", "mk-icon");
      b.type = "button";
      b.title = name;
      b.setAttribute("role", "option");
      b.setAttribute("aria-label", name);
      b.setAttribute("aria-selected", String(state.glyphs.indexOf(name) !== -1));
      b.appendChild(iconSvg(lucide[name], 22));
      b.addEventListener("click", function () { toggleGlyph(name); });
      host.appendChild(b);
    });
    renderPicked();
  }

  function toggleGlyph(name) {
    var at = state.glyphs.indexOf(name);
    if (at !== -1) state.glyphs.splice(at, 1);
    else if (state.glyphs.length < 24) state.glyphs.push(name);
    renderGlyphResults();
    update();
  }

  function renderPicked() {
    var host = $("glyph-picked");
    host.textContent = "";
    state.glyphs.forEach(function (name) {
      var chip = el("button", "mk-chip");
      chip.type = "button";
      chip.setAttribute("aria-label", "Remove " + name);
      if (lucide && lucide[name]) chip.appendChild(iconSvg(lucide[name], 16));
      chip.appendChild(el("span", null, name));
      chip.appendChild(el("span", "mk-x", "×"));
      chip.addEventListener("click", function () { toggleGlyph(name); });
      host.appendChild(chip);
    });
    $("glyph-count").textContent = lucide ? state.glyphs.length + " of 24 picked" + (state.glyphs.length ? "" : ". Search above and tap icons to add them.") : "";
  }

  // ------------------------------------------------------------ documents
  function itemDoc() {
    var tags = $("f-tags").value.split(",").map(function (t) { return t.trim().toLowerCase(); }).filter(Boolean);
    var author = { name: $("f-author").value.trim() };
    var url = $("f-url").value.trim();
    if (url) author.url = url;
    return { name: $("f-name").value.trim(), author: author, license: $("f-license").value, tags: tags, featured: false, version: 1 };
  }

  function schemeDoc() {
    var out = {};
    ["light", "dark"].forEach(function (mode) {
      var m = state.scheme[mode];
      var o = { seed: m.seed, background: m.background, onBackground: m.onBackground };
      if (state.exact) {
        G.SCHEME_COLORS.forEach(function (k) { o[k] = m[k]; });
        if (m.appBar) o.appBar = m.appBar;
      }
      out[mode] = o;
    });
    return out;
  }

  /** The wallpaper fields shared by wallpaper.json and a theme's wallpaper (no kind). */
  function wallFields() {
    var w = {};
    if (state.pat === "glyphs") w.pattern = state.fallbackPattern;
    else w.pattern = state.pat === "none" ? "none" : state.pattern;
    w.palette = state.bg === "mesh" ? state.fallbackPalette : state.palette;
    w.intensity = Math.round(state.intensity * 100) / 100;
    if (state.bg === "mesh") w.mesh = { light: state.mesh.light.slice(), dark: state.mesh.dark.slice(), points: state.mesh.points.map(function (p) { return [round(p[0]), round(p[1])]; }) };
    if (state.pat === "glyphs") w.glyphs = state.glyphs.slice();
    return w;
  }
  function round(v) { return Math.round(v * 100) / 100; }

  function wallpaperDoc() {
    var w = wallFields();
    var out = { kind: w.mesh ? "mesh" : "pattern" };
    Object.keys(w).forEach(function (k) { out[k] = w[k]; });
    return out;
  }

  function themeDoc() {
    return { v: 2, scheme: schemeDoc(), headingFont: state.headingFont, bodyFont: state.bodyFont, wallpaper: wallFields() };
  }

  /** The same wallpaper with glyphs drawn from the fetched Lucide data, for previews only. */
  function previewWall(w) {
    var copy = {};
    Object.keys(w).forEach(function (k) { copy[k] = w[k]; });
    if (w.glyphs && lucide) {
      copy.doodles = w.glyphs.map(function (g) { return lucide[g]; }).filter(Boolean);
      if (!copy.doodles.length) delete copy.doodles;
    }
    return copy;
  }

  // ------------------------------------------------------------ checks (README.md rules)
  function check() {
    var errors = [];
    var item = itemDoc();
    var id = $("f-id").value.trim();
    if (!ID.test(id)) errors.push("Folder id: lowercase letters, digits and dashes, starting with a letter or digit.");
    if (item.name.length < 1) errors.push("Give it a name.");
    if (item.author.name.length < 1) errors.push("Add your name as the author.");
    if (item.author.url && !/^https:\/\/\S+$/.test(item.author.url)) errors.push("Your link must start with https://.");
    if (item.tags.length > 8) errors.push("At most 8 tags.");
    item.tags.forEach(function (t) { if (!TAG.test(t)) errors.push("Tag “" + t + "”: lowercase letters, digits and dashes, up to 24."); });

    var badges = [];
    if (state.kind !== "wallpaper") {
      ["light", "dark"].forEach(function (mode) {
        var m = state.scheme[mode], label = mode === "light" ? "Light" : "Dark";
        var ratio = G.contrast(m.background, m.onBackground);
        badges.push([mode, "onBackground", ratio, ratio >= 4.5]);
        if (ratio < 4.5) errors.push(label + ": text on the background is " + ratio.toFixed(2) + ":1; it needs 4.5:1.");
        if (state.exact) {
          ["primary", "secondary", "tertiary"].forEach(function (k) {
            var r = G.contrast(m[k], m.background);
            badges.push([mode, k, r, r >= 4.5]);
            if (r < 4.5) errors.push(label + ": " + COLOR_LABELS[k].toLowerCase() + " on the background is " + r.toFixed(2) + ":1; it needs 4.5:1.");
          });
          ["primaryContainer", "secondaryContainer", "tertiaryContainer"].forEach(function (k) {
            var r = G.contrast(m.onBackground, m[k]);
            badges.push([mode, k, r, r >= 4.5]);
            if (r < 4.5) errors.push(label + ": text on the " + COLOR_LABELS[k].toLowerCase() + " is " + r.toFixed(2) + ":1; it needs 4.5:1.");
          });
        }
      });
    }
    if (state.kind !== "scheme") {
      if (state.bg === "mesh") {
        ["light", "dark"].forEach(function (mode) {
          state.mesh[mode].forEach(function (c, i) {
            var l = G.luminance(c);
            var bad = mode === "light" ? l < MIN_LIGHT : l > MAX_DARK;
            meshInputs[mode][i].classList.toggle("is-bad", bad);
            meshInputs[mode][i].title = bad ? (mode === "light" ? "Too dark for text on top" : "Too light for text on top") : c;
            if (bad) errors.push((mode === "light" ? "Light" : "Dark") + " mesh color " + (i + 1) + " (" + c + ") is too " + (mode === "light" ? "dark" : "light") + " for text on top.");
          });
        });
      }
      if (state.pat === "glyphs" && (state.glyphs.length < 1 || state.glyphs.length > 24)) errors.push("Pick 1 to 24 icons for your doodles.");
      if (state.pat === "glyphs" && lucide) state.glyphs.forEach(function (g) { if (!lucide[g]) errors.push("“" + g + "” isn't a Lucide icon."); });
    }
    return { errors: errors, badges: badges, id: id, item: item };
  }

  // ------------------------------------------------------------ render
  function renderBadges(badges) {
    ["light", "dark"].forEach(function (mode) {
      Object.keys(schemeBadges[mode]).forEach(function (k) { schemeBadges[mode][k].textContent = ""; schemeBadges[mode][k].className = "mk-badge"; });
    });
    badges.forEach(function (b) {
      var badge = schemeBadges[b[0]][b[1]];
      if (!badge) return;
      badge.textContent = b[2].toFixed(1) + ":1";
      badge.className = "mk-badge " + (b[3] ? "is-ok" : "is-bad");
      badge.title = b[3] ? "Readable (4.5:1 or more)" : "Below 4.5:1";
    });
  }

  function previewLook() {
    var look = { scheme: null, headingFont: "Libre Baskerville", bodyFont: "Lato", wallpaper: { kind: "pattern", pattern: "clouds", palette: "theme", intensity: 0.5 } };
    if (state.kind !== "wallpaper") look.scheme = schemeDoc();
    if (state.kind === "theme") { look.headingFont = state.headingFont; look.bodyFont = state.bodyFont; }
    if (state.kind !== "scheme") look.wallpaper = previewWall(state.kind === "theme" ? wallFields() : wallpaperDoc());
    return look;
  }

  function renderPreview() {
    var host = $("preview");
    host.textContent = "";
    var look = previewLook();
    if (state.kind === "wallpaper") {
      var row = el("div", "mk-phones");
      [false, true].forEach(function (dark) {
        var fig = el("figure", "mk-fig");
        var item = { id: "preview", type: "wallpaper", name: "Preview", document: look.wallpaper };
        var frame = G.wallpaper(item, { dark: dark, label: (dark ? "Dark" : "Light") + " preview" });
        var holder = el("div", "mk-phone");
        holder.appendChild(frame);
        if (state.bg === "mesh") holder.appendChild(pointsLayer(dark));
        fig.appendChild(holder);
        fig.appendChild(el("figcaption", null, dark ? "Dark" : "Light"));
        row.appendChild(fig);
      });
      host.appendChild(row);
    }
    [false, true].forEach(function (dark) {
      var fig = el("figure", "mk-fig");
      var frame = G.chat(look, { dark: dark, aspect: "4 / 3" });
      var holder = el("div", "mk-chat");
      holder.appendChild(frame);
      if (state.kind === "theme" && state.bg === "mesh" && !dark) holder.appendChild(pointsLayer(false));
      fig.appendChild(holder);
      fig.appendChild(el("figcaption", null, (dark ? "Dark" : "Light") + (state.kind === "wallpaper" ? ", behind a chat" : "")));
      host.appendChild(fig);
    });
  }

  /** Draggable mesh points over a preview: corners fixed, edge points along their edge, inner 0.2–0.8. */
  function pointsLayer(dark) {
    var layer = el("div", "mk-points");
    layer.setAttribute("aria-hidden", "true");
    state.mesh.points.forEach(function (p, i) {
      var col = i % 3, row = Math.floor(i / 3);
      if (col !== 1 && row !== 1) return; // corners stay put
      var dot = el("span", "mk-dot");
      dot.style.left = p[0] * 100 + "%";
      dot.style.top = p[1] * 100 + "%";
      dot.style.background = state.mesh[dark ? "dark" : "light"][i];
      dot.addEventListener("pointerdown", function (e) {
        e.preventDefault();
        dot.setPointerCapture(e.pointerId);
        var rect = layer.getBoundingClientRect();
        function move(ev) {
          var x = (ev.clientX - rect.left) / rect.width, y = (ev.clientY - rect.top) / rect.height;
          var pt = state.mesh.points[i];
          if (col === 1) pt[0] = Math.max(0.2, Math.min(0.8, x));
          if (row === 1) pt[1] = Math.max(0.2, Math.min(0.8, y));
          dot.style.left = pt[0] * 100 + "%";
          dot.style.top = pt[1] * 100 + "%";
        }
        function up() {
          dot.removeEventListener("pointermove", move);
          dot.removeEventListener("pointerup", up);
          dot.removeEventListener("pointercancel", up);
          update();
        }
        dot.addEventListener("pointermove", move);
        dot.addEventListener("pointerup", up);
        dot.addEventListener("pointercancel", up);
      });
      layer.appendChild(dot);
    });
    return layer;
  }

  function fileBlock(path, content, enabled) {
    var box = el("div", "mk-file");
    var head = el("div", "mk-file-head");
    head.appendChild(el("code", null, path));
    var actions = el("div", "mk-file-actions");
    var copy = el("button", "btn quiet", "Copy");
    copy.type = "button";
    copy.disabled = !enabled;
    copy.addEventListener("click", function () {
      navigator.clipboard.writeText(content).then(function () { copy.textContent = "Copied"; setTimeout(function () { copy.textContent = "Copy"; }, 1400); });
    });
    var download = el("button", "btn quiet", "Download");
    download.type = "button";
    download.disabled = !enabled;
    download.addEventListener("click", function () {
      var a = document.createElement("a");
      a.href = URL.createObjectURL(new Blob([content], { type: "application/json" }));
      a.download = path.split("/").pop();
      document.body.appendChild(a);
      a.click();
      setTimeout(function () { URL.revokeObjectURL(a.href); a.remove(); }, 0);
    });
    var propose = el("a", "btn" + (enabled ? " primary" : ""), "Propose on GitHub");
    if (enabled) {
      propose.href = REPO + "/new/main?filename=" + encodeURIComponent(path) + "&value=" + encodeURIComponent(content);
      propose.target = "_blank";
      propose.rel = "noopener";
    } else {
      propose.setAttribute("aria-disabled", "true");
      propose.tabIndex = -1;
    }
    actions.appendChild(copy);
    actions.appendChild(download);
    actions.appendChild(propose);
    head.appendChild(actions);
    box.appendChild(head);
    var pre = el("pre", "sample mk-code");
    pre.appendChild(el("code", null, content));
    box.appendChild(pre);
    return box;
  }

  function renderFiles(result) {
    var ul = $("errors");
    ul.textContent = "";
    result.errors.forEach(function (e) { ul.appendChild(el("li", null, e)); });
    var ok = !result.errors.length;
    var id = result.id || "your-id";
    var dir = state.kind + "s/" + id + "/";
    var docName = state.kind + ".json";
    var doc = state.kind === "theme" ? themeDoc() : state.kind === "scheme" ? schemeDoc() : wallpaperDoc();
    var host = $("files");
    host.textContent = "";
    host.appendChild(fileBlock(dir + "item.json", JSON.stringify(result.item, null, 2) + "\n", ok));
    host.appendChild(fileBlock(dir + docName, JSON.stringify(doc, null, 2) + "\n", ok));
    host.classList.toggle("is-disabled", !ok);
  }

  function update() {
    $("sec-scheme").hidden = state.kind === "wallpaper";
    $("sec-fonts").hidden = state.kind !== "theme";
    $("sec-wall").hidden = state.kind === "scheme";
    $("bg-palette").hidden = state.bg !== "palette";
    $("bg-mesh").hidden = state.bg !== "mesh";
    $("pat-builtin").hidden = state.pat !== "builtin";
    $("pat-glyphs").hidden = state.pat !== "glyphs";
    $("intensity-row").hidden = state.pat === "none";
    $("o-intensity").textContent = Math.round(state.intensity * 100) + "%";
    if (state.pat === "glyphs") loadLucide();
    var result = check();
    renderBadges(result.badges);
    renderPreview();
    renderFiles(result);
  }

  // ------------------------------------------------------------ wire up
  function init() {
    if (!G) return;
    var paletteNames = Object.keys(G.PALETTE_LABELS);
    var patternNames = Object.keys(G.PATTERN_LABELS).filter(function (p) { return p !== "none"; });
    fillSelect($("f-palette"), paletteNames, G.PALETTE_LABELS, state.palette);
    fillSelect($("f-mesh-start"), Object.keys(G.PALETTES), G.PALETTE_LABELS, "casama");
    fillSelect($("f-fallback-palette"), G.FALLBACK_PALETTES, G.PALETTE_LABELS, state.fallbackPalette);
    fillSelect($("f-pattern"), patternNames, G.PATTERN_LABELS, state.pattern);
    fillSelect($("f-fallback-pattern"), Object.keys(G.PATTERN_LABELS), G.PATTERN_LABELS, state.fallbackPattern);
    fillSelect($("f-heading"), FONTS, null, state.headingFont);
    fillSelect($("f-body"), FONTS, null, state.bodyFont);

    $("kind").addEventListener("click", function (e) {
      var b = e.target.closest("button[data-kind]");
      if (!b) return;
      state.kind = b.getAttribute("data-kind");
      setPressed("kind", "data-kind", state.kind);
      update();
    });
    $("bg-mode").addEventListener("click", function (e) {
      var b = e.target.closest("button[data-bg]");
      if (!b) return;
      state.bg = b.getAttribute("data-bg");
      setPressed("bg-mode", "data-bg", state.bg);
      update();
    });
    $("pat-mode").addEventListener("click", function (e) {
      var b = e.target.closest("button[data-pat]");
      if (!b) return;
      state.pat = b.getAttribute("data-pat");
      setPressed("pat-mode", "data-pat", state.pat);
      update();
    });
    $("f-exact").addEventListener("change", function () { state.exact = this.checked; buildScheme(); update(); });
    $("f-palette").addEventListener("change", function () { state.palette = this.value; update(); });
    $("f-mesh-start").addEventListener("change", function () { state.mesh = copyMesh(this.value); buildMeshGrid(); update(); });
    $("f-fallback-palette").addEventListener("change", function () { state.fallbackPalette = this.value; update(); });
    $("f-pattern").addEventListener("change", function () { state.pattern = this.value; update(); });
    $("f-fallback-pattern").addEventListener("change", function () { state.fallbackPattern = this.value; update(); });
    $("f-heading").addEventListener("change", function () { state.headingFont = this.value; update(); });
    $("f-body").addEventListener("change", function () { state.bodyFont = this.value; update(); });
    $("f-intensity").addEventListener("input", function () { state.intensity = Number(this.value); update(); });
    $("f-glyph-q").addEventListener("input", renderGlyphResults);
    // Suggest the folder id from the name until the id is edited by hand.
    var idTouched = false;
    $("f-id").addEventListener("input", function () { idTouched = true; update(); });
    $("f-name").addEventListener("input", function () {
      if (!idTouched) $("f-id").value = this.value.toLowerCase().normalize("NFKD").replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 63);
      update();
    });
    ["f-author", "f-url", "f-license", "f-tags"].forEach(function (id) { $(id).addEventListener("input", update); });
    $("form").addEventListener("submit", function (e) { e.preventDefault(); });

    buildScheme();
    buildMeshGrid();
    update();
  }

  init();
})();
