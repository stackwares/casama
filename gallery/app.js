/* gallery.casama.ai: browse the catalog in index.json with previews drawn by gallery.js. */
(function () {
  "use strict";
  var G = window.CasamaGallery;
  var TYPES = ["theme", "scheme", "wallpaper", "skill"];
  var PLURAL = { theme: "Themes", scheme: "Colors", wallpaper: "Wallpapers", skill: "Skills" };
  var NOUN = { theme: ["theme", "themes"], scheme: ["color scheme", "color schemes"], wallpaper: ["wallpaper", "wallpapers"], skill: ["skill", "skills"] };
  var SINGULAR = { theme: "Theme", scheme: "Color scheme", wallpaper: "Wallpaper", skill: "Skill" };
  var CATEGORY_ICON = { work: "briefcase", writing: "pen-line", research: "telescope", data: "table-2", money: "coins", build: "code", life: "compass" };
  var CATEGORY = { work: "Work", writing: "Writing", research: "Research", data: "Data", money: "Money", build: "Build", life: "Life" };

  var state = { items: null, failed: false, type: null, q: "", dark: matchMedia("(prefers-color-scheme: dark)").matches, open: null };
  var $ = function (id) { return document.getElementById(id); };
  var content = $("content");
  var dialog = $("detail");

  function el(tag, attrs, kids) {
    var e = document.createElement(tag);
    Object.keys(attrs || {}).forEach(function (k) {
      if (k === "text") e.textContent = attrs[k];
      else if (k === "class") e.className = attrs[k];
      else if (k.slice(0, 2) === "on") e.addEventListener(k.slice(2), attrs[k]);
      else if (attrs[k] != null) e.setAttribute(k, attrs[k]);
    });
    (kids || []).forEach(function (kid) { if (kid) e.appendChild(typeof kid === "string" ? document.createTextNode(kid) : kid); });
    return e;
  }
  function count(n, type) { return n + " " + NOUN[type][n === 1 ? 0 : 1]; }
  function community(item) { return item.author && item.author.name && item.author.name !== "Casama"; }

  // ---------------------------------------------------------------- data
  function load() {
    state.failed = false;
    render();
    fetch("index.json", { cache: "no-cache" })
      .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
      .then(function (data) {
        state.items = (data.items || []).filter(function (i) { return !i.retired; });
        summary();
        route();
      })
      .catch(function () { state.failed = true; render(); });
  }

  function matches() {
    var q = state.q.trim().toLowerCase();
    var list = (state.items || []).filter(function (i) {
      if (!q) return true;
      return [i.name, i.id, i.description || "", i.category || "", (i.author || {}).name || ""].concat(i.tags || [])
        .some(function (s) { return String(s).toLowerCase().indexOf(q) !== -1; });
    });
    return list.sort(function (a, b) {
      if (!!a.featured !== !!b.featured) return a.featured ? -1 : 1;
      return a.name.localeCompare(b.name);
    });
  }

  function summary() {
    var n = {};
    TYPES.forEach(function (t) { n[t] = state.items.filter(function (i) { return i.type === t; }).length; });
    var parts = TYPES.filter(function (t) { return n[t]; }).map(function (t) { return count(n[t], t); });
    var list = parts.length > 1 ? parts.slice(0, -1).join(", ") + " and " + parts[parts.length - 1] : parts[0] || "Nothing yet";
    $("summary").textContent = list + ", free and open source. See each one as it looks in the app, then open it in Casama.";
  }

  // ---------------------------------------------------------------- layout
  function width() { return content.clientWidth || document.querySelector("main").clientWidth; }
  function phone() { return window.innerWidth < 640; }
  function columns(type) {
    var w = width();
    var min = type === "wallpaper" ? 150 : 230, lo = type === "wallpaper" ? 3 : 2, hi = type === "wallpaper" ? 7 : 5;
    return Math.max(lo, Math.min(hi, Math.floor((w + 16) / (min + 16))));
  }

  // ---------------------------------------------------------------- cards
  function dots(item) {
    if (item.type !== "theme" && item.type !== "scheme") return null;
    var seeds = item.type === "theme" ? (item.document || {}).scheme : item.document;
    if (!seeds || typeof seeds !== "object") return null;
    var c = G.scheme(seeds, state.dark);
    return el("span", { class: "dots", "aria-hidden": "true" }, [c.t, c.s, c.p].map(function (color) {
      var i = el("i"); i.style.background = color; return i;
    }));
  }

  function headingFont(item) {
    return item.type === "theme" && item.document && item.document.headingFont ? item.document.headingFont : null;
  }

  function line(item) {
    if (community(item)) return "By " + item.author.name;
    var doc = item.document || {};
    if (item.type === "theme") return doc.headingFont === doc.bodyFont ? doc.headingFont : doc.headingFont + " · " + doc.bodyFont;
    if (item.type === "scheme") return "Light and dark";
    if (item.type === "wallpaper") return G.describeWallpaper(doc);
    return CATEGORY[item.category] || item.category || "";
  }

  function caption(item, opts) {
    var name = el("span", { class: "name", text: item.name });
    var font = headingFont(item);
    if (font) name.style.fontFamily = "'" + font + "', var(--font)";
    return el("span", { class: "cap" }, [
      el("span", { class: "cap-text" }, [name, el("span", { class: "line", text: opts && opts.line ? opts.line : line(item) })]),
      opts && opts.trailing ? opts.trailing : dots(item),
    ]);
  }

  function card(item) {
    var pic = G.preview(item, { dark: state.dark, thumb: true, label: item.name });
    return el("a", { class: "card", href: "#" + item.type + "/" + item.id, "aria-label": item.name + ", " + SINGULAR[item.type] }, [pic, caption(item)]);
  }

  function featuredCard(item) {
    var pic = G.chat(G.lookOf(item, { alone: false }), { dark: state.dark, thumb: true, aspect: phone() ? "16 / 10" : "2 / 1", label: item.name });
    var go = el("span", { class: "skill-go" }, [G.icon("chevron-right", { size: 18 })]);
    return el("a", { class: "card", href: "#" + item.type + "/" + item.id, "aria-label": item.name + ", " + SINGULAR[item.type] }, [pic, caption(item, { line: SINGULAR[item.type], trailing: go })]);
  }

  function skillRow(item) {
    var cat = CATEGORY[item.category] || item.category || "";
    return el("li", null, [el("a", { class: "skill", href: "#skill/" + item.id }, [
      G.icon(item.icon || CATEGORY_ICON[item.category] || "book-open"),
      el("span", null, [
        el("span", { class: "skill-name", text: item.name }),
        el("span", { class: "skill-desc", text: item.description || "" }),
        el("span", { class: "skill-meta-line", text: [cat, item.license].filter(Boolean).join(" · ") }),
      ]),
      el("span", { class: "skill-meta", text: community(item) ? "By " + item.author.name : cat }),
      el("span", { class: "skill-meta", text: item.license }),
      el("span", { class: "skill-go" }, [G.icon("chevron-right", { size: 18 })]),
    ])]);
  }

  function cardsFor(type, list) {
    if (type === "skill") return el("ul", { class: "skills" }, list.map(skillRow));
    var cards = list.map(card);
    var grid = el("div", { class: "grid" }, cards);
    grid.style.setProperty("--cols", columns(type));
    return grid;
  }

  function section(title, n, body, seeAll) {
    var h = el("h2", null, [title, n == null ? null : el("span", { class: "n", text: String(n) })]);
    var head = el("div", { class: "section-head" }, [h, seeAll ? el("button", { class: "see-all", type: "button", onclick: seeAll, text: "See all" }) : null]);
    return el("section", { class: "section" }, [head, body]);
  }

  // ---------------------------------------------------------------- render
  function tabs(found) {
    var box = $("tabs");
    box.textContent = "";
    [null].concat(TYPES).forEach(function (type) {
      var n = found ? (type ? found.filter(function (i) { return i.type === type; }).length : found.length) : null;
      box.appendChild(el("button", {
        class: "tab", type: "button", role: "tab", "aria-selected": String(state.type === type),
        onclick: function () { setType(type); },
      }, [type ? PLURAL[type] : "All", n == null ? null : el("span", { class: "n", text: String(n) })]));
    });
  }

  function skeleton() {
    var cols = phone() ? 2 : columns("theme");
    return [0, 1].map(function () {
      var cards = [];
      for (var i = 0; i < cols; i++) {
        var frame = el("div", { class: "cg-frame" });
        cards.push(el("div", { class: "card skeleton", "aria-hidden": "true" }, [frame, el("span", { class: "cap" }, [el("span", { class: "cap-text" }, [el("span", { class: "bar-line", style: "width:60%" }), el("span", { class: "bar-line", style: "width:38%" })])])]));
      }
      var grid = el("div", { class: "grid" }, cards);
      grid.style.setProperty("--cols", cols);
      return el("section", { class: "section" }, [el("div", { class: "section-head" }, [el("span", { class: "bar-line", style: "width:96px;height:14px" })]), grid]);
    });
  }

  function render() {
    content.textContent = "";
    if (state.failed) {
      tabs(null);
      $("count").textContent = "";
      content.appendChild(el("div", { class: "empty" }, [
        el("p", { text: "The gallery couldn't be loaded." }),
        el("p", { class: "small", text: "Check the connection and try again. Every item is also listed in index.json." }),
        el("button", { class: "btn", type: "button", onclick: load, text: "Try again" }),
      ]));
      return;
    }
    if (!state.items) {
      tabs(null);
      skeleton().forEach(function (s) { content.appendChild(s); });
      return;
    }
    var found = matches();
    tabs(found);
    var shown = state.type ? found.filter(function (i) { return i.type === state.type; }) : found;
    var q = state.q.trim();
    $("count").textContent = q
      ? (shown.length === 1 ? "1 match" : shown.length + " matches") + " for “" + q + "”"
      : state.type ? count(shown.length, state.type) : shown.length + " items";
    if (!shown.length) {
      content.appendChild(el("div", { class: "empty" }, [
        el("p", { text: q ? "Nothing matches “" + q + "”." : "Nothing here yet." }),
        q ? el("button", { class: "btn", type: "button", onclick: function () { setQuery(""); }, text: "Clear search" }) : null,
      ]));
      return;
    }
    if (state.type) {
      content.appendChild(el("section", { class: "section" }, [cardsFor(state.type, shown)]));
      return;
    }
    if (!q) {
      var byType = ["theme", "wallpaper", "scheme"].map(function (t) { return found.filter(function (i) { return i.type === t && i.featured; }); });
      var featured = [];
      for (var i = 0; i < 6; i++) byType.forEach(function (list) { if (list[i]) featured.push(list[i]); });
      var limit = phone() ? 1 : width() >= 900 ? 3 : 2;
      featured = featured.slice(0, limit);
      if (featured.length) {
        var body = el("div", { class: "grid featured" }, featured.map(featuredCard));
        body.style.setProperty("--cols", featured.length);
        content.appendChild(section("Featured", null, body));
      }
    }
    TYPES.forEach(function (type) {
      var list = found.filter(function (i) { return i.type === type; });
      if (!list.length) return;
      // A phone shows two rows of each kind; wider screens one.
      var visible = type === "skill" ? list.slice(0, 4) : list.slice(0, columns(type) * (phone() ? 2 : 1));
      content.appendChild(section(PLURAL[type], list.length, cardsFor(type, visible), function () { setType(type); }));
    });
  }

  // ---------------------------------------------------------------- detail
  function swatchChips(seeds, dark) {
    var c = G.scheme(seeds, dark);
    return el("span", { class: "chips", "aria-hidden": "true" }, [c.p, c.pc, c.s, c.t, c.surf].map(function (color) {
      var i = el("i"); i.style.background = color; return i;
    }));
  }

  function facts(item) {
    var doc = item.document || {};
    var rows = [];
    var row = function (label, value) { rows.push(el("tr", null, [el("th", { scope: "row", text: label }), el("td", null, [value])])); };
    if (item.type === "theme") {
      if (typeof doc.scheme === "object") {
        row("Colors", el("span", { class: "pair" }, [
          el("span", null, [el("span", { class: "pair-label", text: "Light" }), swatchChips(doc.scheme, false)]),
          el("span", null, [el("span", { class: "pair-label", text: "Dark" }), swatchChips(doc.scheme, true)]),
        ]));
      }
      var fonts = el("span");
      [doc.headingFont, doc.bodyFont].filter(function (f, i, all) { return f && all.indexOf(f) === i; }).forEach(function (f, i) {
        if (i) fonts.appendChild(document.createTextNode(" · "));
        var s = el("span", { text: f }); s.style.fontFamily = "'" + f + "', var(--font)"; fonts.appendChild(s);
      });
      row("Fonts", fonts);
      row("Background", document.createTextNode(G.describeWallpaper(doc.wallpaper)));
    } else if (item.type === "scheme") {
      row("Light", swatchChips(doc, false));
      row("Dark", swatchChips(doc, true));
    } else if (item.type === "wallpaper") {
      row("Kind", document.createTextNode(G.describeWallpaper(doc)));
    } else {
      row("Category", document.createTextNode(CATEGORY[item.category] || item.category || "-"));
    }
    var author = item.author || {};
    row("Made by", author.url ? el("a", { href: author.url, rel: "noopener", text: author.name }) : document.createTextNode(author.name || "-"));
    row("License", document.createTextNode(item.license));
    row("Source", el("a", { href: G.sourceLink(item), rel: "noopener", text: "On GitHub" }));
    return el("table", { class: "facts" }, [el("tbody", null, rows)]);
  }

  function openDetail(item) {
    state.open = item;
    var dark = state.dark;
    dialog.textContent = "";
    var font = headingFont(item);
    var title = el("h2", { id: "detail-title", text: item.name });
    if (font) title.style.fontFamily = "'" + font + "', var(--font)";
    var author = (item.author || {}).name || "";
    var meta = el("p", { class: "meta", text: SINGULAR[item.type] + " · By " + author + " · " + item.license });

    var pic = el("div", { class: "detail-pic" });
    function drawPic() {
      pic.textContent = "";
      if (item.type === "skill") {
        var pre = el("pre", { class: "instructions", "aria-label": "Instructions", text: "Loading the instructions…" });
        pre.style.maxHeight = "none";
        pre.style.width = "100%";
        pre.style.margin = "0";
        pic.appendChild(pre);
        var path = (item.files || []).filter(function (f) { return /\/SKILL\.md$/.test(f); })[0];
        if (path) fetch(path).then(function (r) { return r.text(); }).then(function (md) {
          pre.textContent = md.replace(/^---\n[\s\S]*?\n---\n?/, "").trim();
        }).catch(function () { pre.textContent = "The instructions couldn't be loaded."; });
        return;
      }
      var look = G.lookOf(item, { alone: false });
      if (item.type === "wallpaper") {
        var pics = el("div", { style: "display:flex;gap:12px;width:100%;align-items:center" });
        var portrait = G.wallpaper(item, { dark: dark, label: item.name });
        portrait.style.flex = "0 0 34%";
        var behind = G.chat(look, { dark: dark, label: "Behind a Casama chat" });
        behind.style.flex = "1";
        pics.appendChild(portrait);
        pics.appendChild(behind);
        pic.appendChild(pics);
      } else {
        pic.appendChild(G.chat(look, { dark: dark, aspect: "16 / 10", label: item.name + " in a Casama chat" }));
      }
      var seg = el("div", { class: "seg", role: "group", "aria-label": "Preview in" }, ["light", "dark"].map(function (mode) {
        return el("button", { type: "button", "aria-pressed": String((mode === "dark") === dark), onclick: function () { dark = mode === "dark"; drawPic(); }, text: mode === "dark" ? "Dark" : "Light" });
      }));
      pic.appendChild(seg);
    }
    drawPic();

    var copy = el("button", { class: "btn", type: "button" }, [G.icon("link"), "Copy link"]);
    copy.addEventListener("click", function () {
      var done = function () { copy.lastChild.textContent = "Copied"; setTimeout(function () { copy.lastChild.textContent = "Copy link"; }, 1600); };
      if (navigator.clipboard) navigator.clipboard.writeText(G.appLink(item)).then(done, done); else done();
    });
    var info = el("div", { class: "detail-info" }, [
      title,
      meta,
      item.description ? el("p", { class: "desc", text: item.description }) : null,
      facts(item),
      (item.tags || []).length ? el("div", { class: "tags" }, item.tags.map(function (tag) {
        return el("button", { class: "tag", type: "button", onclick: function () { dialog.close(); setQuery(tag); setType(null); }, text: tag });
      })) : null,
      el("div", { class: "actions" }, [
        el("a", { class: "btn primary", href: G.appLink(item) }, [G.icon("external-link"), item.type === "skill" ? "Install in Casama" : "Open in Casama"]),
        copy,
      ]),
    ]);
    var close = el("button", { class: "detail-close", type: "button", "aria-label": "Close", autofocus: "", onclick: function () { dialog.close(); } }, [G.icon("x")]);
    dialog.appendChild(el("div", { class: "detail-inner" }, [pic, info]));
    dialog.appendChild(close);
    if (!dialog.open) dialog.showModal();
  }

  dialog.addEventListener("close", function () {
    state.open = null;
    var want = state.type ? "#" + state.type : " ";
    if (location.hash !== want) history.replaceState(null, "", want === " " ? location.pathname : want);
  });
  dialog.addEventListener("click", function (e) { if (e.target === dialog) dialog.close(); });

  // ---------------------------------------------------------------- routing and controls
  function route() {
    var parts = location.hash.replace(/^#/, "").split("/");
    var type = TYPES.indexOf(parts[0]) !== -1 ? parts[0] : null;
    if (parts[0] && !type) { render(); return; }
    if (parts[1]) {
      var item = (state.items || []).filter(function (i) { return i.type === type && i.id === parts[1]; })[0];
      render();
      if (item) openDetail(item);
      return;
    }
    state.type = type;
    if (dialog.open) dialog.close();
    render();
  }

  function setType(type) {
    state.type = type;
    history.replaceState(null, "", type ? "#" + type : location.pathname);
    render();
  }
  function setQuery(q) {
    state.q = q;
    $("q").value = q;
    render();
  }

  $("search-icon").appendChild(G.icon("search"));
  $("q").addEventListener("input", function (e) { state.q = e.target.value; render(); });
  document.querySelectorAll(".toolbar .seg button").forEach(function (b) {
    b.setAttribute("aria-pressed", String((b.dataset.mode === "dark") === state.dark));
    b.addEventListener("click", function () {
      state.dark = b.dataset.mode === "dark";
      document.querySelectorAll(".toolbar .seg button").forEach(function (x) { x.setAttribute("aria-pressed", String(x === b)); });
      render();
    });
  });
  window.addEventListener("hashchange", route);
  var lastWidth = window.innerWidth, timer;
  window.addEventListener("resize", function () {
    clearTimeout(timer);
    timer = setTimeout(function () { if (window.innerWidth !== lastWidth) { lastWidth = window.innerWidth; render(); } }, 120);
  });
  load();
})();
