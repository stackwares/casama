/* gallery.casama.ai: browse the catalog (index.json and the other lists) with previews drawn by
   gallery.js and labels, search and links from catalog.js (D-184, D-189, D-315). */
(function () {
  "use strict";
  var G = window.CasamaGallery;
  var C = window.CasamaCatalog;
  var TYPES = C.TYPES;
  var PLURAL = C.PLURAL;
  var SINGULAR = C.SINGULAR;
  // Starter bots, routine ideas, reviewed plugins and apps read as lists, like skills.
  var LISTED = ["skill", "app", "bot", "routine", "plugin"];
  var AUTH = { oauth: "Sign in with the vendor", api_key: "An API key", none: "Nothing, it's public" };
  var CATEGORY_ICON = { work: "briefcase", writing: "pen-line", research: "telescope", data: "table-2", money: "coins", build: "code", life: "compass" };
  var TYPE_ICON = { skill: "book-open", app: "app-window", bot: "bot", routine: "repeat", plugin: "puzzle", set: "package" };
  var MOST_USED_TYPES = ["app", "skill", "wallpaper", "theme"];

  var params = new URLSearchParams(location.search);
  var state = {
    items: null, sets: [], stats: {}, failed: false, type: null, q: params.get("q") || "",
    filter: { topic: "", free: false, self: false, computer: false },
    dark: matchMedia("(prefers-color-scheme: dark)").matches, open: null,
  };
  function applyChrome() { document.documentElement.setAttribute("data-theme", state.dark ? "dark" : "light"); }
  applyChrome();
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
  function key(item) { return item.type + "/" + item.id; }
  function statsOf(item) { return state.stats[key(item)] || item.stats || null; }
  function find(type, id) { return (type === "set" ? state.sets : state.items || []).filter(function (i) { return i.type === type && i.id === id; })[0]; }

  // ---------------------------------------------------------------- data
  /** The public stats endpoint: ?stats=<url> or ?stats=off, else the page's casama-stats meta. */
  function statsUrl() {
    var p = params.get("stats");
    if (p) return p === "off" ? null : p;
    var meta = document.querySelector('meta[name="casama-stats"]');
    var v = meta ? meta.getAttribute("content") : "";
    return v && v !== "off" ? v : null;
  }
  function loadStats() {
    var url = statsUrl();
    if (!url || !window.fetch) return;
    var ctrl = window.AbortController ? new AbortController() : null;
    var timer = setTimeout(function () { if (ctrl) ctrl.abort(); }, 5000);
    fetch(url, { signal: ctrl ? ctrl.signal : undefined, credentials: "omit" })
      .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
      .then(function (data) {
        clearTimeout(timer);
        if (data && data.items && typeof data.items === "object") { state.stats = data.items; render(); }
      })
      .catch(function () { clearTimeout(timer); });
  }

  function load() {
    state.failed = false;
    render();
    var get = function (file) {
      return fetch(file, { cache: "no-cache" }).then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); });
    };
    // Every list but index.json is optional: the rest still shows if one can't be read.
    var optional = function (file) { return get(file).catch(function () { return { items: [] }; }); };
    Promise.all([get("index.json"), optional("apps.json"), optional("bots.json"), optional("routines.json"), optional("plugins.json"), optional("sets.json")])
      .then(function (files) {
        var sets = files.pop();
        var all = files.reduce(function (list, f) { return list.concat(f.items || []); }, []);
        state.items = all.filter(function (i) { return !i.retired && TYPES.indexOf(i.type) !== -1; });
        state.items.forEach(function (i) { i._fields = C.fields(i); });
        var fresh = state.items.filter(function (i) { return C.isNew(i); }).length;
        state.newOk = fresh > 0 && fresh <= state.items.length / 2;
        state.sets = (sets.items || sets.sets || []).filter(function (s) { return !s.retired; }).map(function (s) {
          s.type = "set";
          s._fields = C.fields(s);
          return s;
        });
        // Icons a listed item names that the page doesn't embed load once, then the list redraws.
        var missing = state.items.concat(state.sets).some(function (i) {
          var name = C.doc(i).icon || i.icon;
          return name && !G.hasIcon(name);
        });
        if (missing)
          fetch("assets/lucide/icon-nodes.json").then(function (r) { return r.json(); }).then(function (nodes) {
            G.addIcons(nodes);
            render();
          }).catch(function () {});
        summary();
        topics();
        route();
      })
      .catch(function () { state.failed = true; render(); });
    loadStats();
  }

  function filtered() {
    var f = state.filter;
    return (state.items || []).filter(function (i) {
      if (f.topic) {
        var t = f.topic.split(":");
        if (t[0] === "cat" && C.category(i) !== t[1]) return false;
        if (t[0] === "tag" && (i.tags || []).indexOf(t[1]) === -1) return false;
      }
      if (f.free && !C.isFree(i)) return false;
      if (f.self && !C.selfHosted(i)) return false;
      if (f.computer && !C.needsComputer(i)) return false;
      return true;
    });
  }
  function filtering() { var f = state.filter; return !!(f.topic || f.free || f.self || f.computer); }

  function matches() {
    var list = filtered();
    if (state.q.trim()) return C.search(list, state.q);
    return list.sort(function (a, b) {
      if (!!a.featured !== !!b.featured) return a.featured ? -1 : 1;
      return a.name.localeCompare(b.name);
    });
  }

  function summary() {
    var n = {};
    TYPES.forEach(function (t) { n[t] = state.items.filter(function (i) { return i.type === t; }).length; });
    var parts = TYPES.filter(function (t) { return n[t]; }).map(function (t) { return C.count(n[t], t); });
    var list = parts.length > 1 ? parts.slice(0, -1).join(", ") + " and " + parts[parts.length - 1] : parts[0] || "Nothing yet";
    $("summary").textContent = list + ", free and open source. See each one as it looks in the app, then open it in Casama.";
  }

  // The topic filter: categories first, then the tags several items share.
  function topics() {
    var select = $("topic");
    if (!select) return;
    select.textContent = "";
    select.appendChild(el("option", { value: "", text: "Any topic" }));
    var cats = {}, tags = {};
    state.items.forEach(function (i) {
      var c = C.category(i);
      if (c) cats[c] = (cats[c] || 0) + 1;
      (i.tags || []).forEach(function (t) { tags[t] = (tags[t] || 0) + 1; });
    });
    var catGroup = el("optgroup", { label: "Categories" });
    Object.keys(cats).sort(function (a, b) { return C.categoryLabel({ category: a }).localeCompare(C.categoryLabel({ category: b })); }).forEach(function (c) {
      catGroup.appendChild(el("option", { value: "cat:" + c, text: C.categoryLabel({ category: c }) }));
    });
    select.appendChild(catGroup);
    var top = Object.keys(tags).filter(function (t) { return tags[t] > 1 && !cats[t]; }).sort(function (a, b) { return tags[b] - tags[a] || a.localeCompare(b); }).slice(0, 24);
    if (top.length) {
      var tagGroup = el("optgroup", { label: "Tags" });
      top.sort().forEach(function (t) { tagGroup.appendChild(el("option", { value: "tag:" + t, text: t })); });
      select.appendChild(tagGroup);
    }
    select.value = state.filter.topic;
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
    var seeds = item.type === "theme" ? C.doc(item).scheme : item.document;
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
    if (C.community(item)) return "By " + item.author.name;
    var doc = C.doc(item);
    if (item.type === "theme") return doc.headingFont === doc.bodyFont ? doc.headingFont : doc.headingFont + " · " + doc.bodyFont;
    if (item.type === "scheme") return "Light and dark";
    if (item.type === "wallpaper") return G.describeWallpaper(doc);
    return C.categoryLabel(item);
  }
  // "New" means something only while most of the catalog isn't: a young catalog (every item
  // backfilled within 30 days) shows no badges and no New row.
  function newShown(item) { return state.newOk && C.isNew(item); }
  function newBadge(item) { return newShown(item) ? el("span", { class: "badge-new", text: "New" }) : null; }

  function caption(item, opts) {
    var name = el("span", { class: "name", text: item.name });
    var font = headingFont(item);
    if (font) name.style.fontFamily = "'" + font + "', var(--font)";
    return el("span", { class: "cap" }, [
      el("span", { class: "cap-text" }, [name, el("span", { class: "line", text: opts && opts.line ? opts.line : line(item) })]),
      opts && opts.trailing ? opts.trailing : dots(item),
    ]);
  }

  /** A link to an item's page that opens the detail here on a plain click. */
  function itemLink(item, cls, label, kids) {
    var a = el("a", { class: cls, href: C.pagePath(item), "aria-label": label }, kids);
    a.addEventListener("click", function (e) {
      if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey || e.button) return;
      e.preventDefault();
      if (item.type === "set") openSet(item); else openDetail(item);
    });
    return a;
  }

  function card(item, opts) {
    opts = opts || {};
    var pic = G.preview(item, { dark: state.dark, thumb: true, label: item.name, aspect: opts.aspect });
    var holder = el("span", { class: "card-pic" }, [pic, newBadge(item)]);
    return itemLink(item, "card", item.name + ", " + SINGULAR[item.type], [holder, caption(item, { line: opts.note })]);
  }

  function featuredCard(item) {
    var pic = G.chat(G.lookOf(item, { alone: false }), { dark: state.dark, thumb: true, aspect: phone() ? "16 / 10" : "2 / 1", label: item.name });
    var go = el("span", { class: "skill-go" }, [G.icon("chevron-right", { size: 18 })]);
    return itemLink(item, "card", item.name + ", " + SINGULAR[item.type], [el("span", { class: "card-pic" }, [pic, newBadge(item)]), caption(item, { line: item.pick || SINGULAR[item.type], trailing: go })]);
  }

  // An app's mark, tinted on its brand color like the app draws it; its initial without one.
  function appLogo(item, size) {
    var doc = C.doc(item);
    var hex = /^[0-9A-Fa-f]{6}$/.test(doc.color || "") ? doc.color : "6B7280";
    var n = parseInt(hex, 16);
    var light = (0.299 * (n >> 16) + 0.587 * ((n >> 8) & 255) + 0.114 * (n & 255)) / 255 > 0.6;
    var ink = light ? "#1B1B1F" : "#FFFFFF";
    var tile = el("span", { class: "app-logo", "aria-hidden": "true" });
    tile.style.cssText = "width:" + size + "px;height:" + size + "px;border-radius:" + Math.round(size * 0.28) + "px;background:#" + hex;
    var logo = "apps/" + item.id + "/logo.svg";
    if ((item.files || []).indexOf(logo) !== -1) {
      var mark = el("i");
      var url = "/" + logo;
      mark.style.cssText = "background:" + ink + ";-webkit-mask:url(" + url + ") center/contain no-repeat;mask:url(" + url + ") center/contain no-repeat";
      tile.appendChild(mark);
    } else {
      var letter = el("b", { text: (item.name || "?").charAt(0).toUpperCase() });
      letter.style.cssText = "color:" + ink + ";font-size:" + Math.round(size * 0.44) + "px";
      tile.appendChild(letter);
    }
    return tile;
  }
  function itemIcon(item, size) {
    if (item.type === "app") return appLogo(item, size || 32);
    if (C.isLook(item)) return G.icon(item.type === "wallpaper" ? "image" : "palette", size ? { size: size } : undefined);
    var doc = C.doc(item);
    return G.icon(doc.icon || item.icon || CATEGORY_ICON[C.category(item)] || TYPE_ICON[item.type] || "book-open", size ? { size: size } : undefined);
  }

  /** A card for a skill, app, bot, routine, plugin or set in a row: its mark, name and what it does. */
  function tile(item, note) {
    var meta = item.type === "set" ? C.setItems(item).length + " items" : SINGULAR[item.type] + (C.categoryLabel(item) ? " · " + C.categoryLabel(item) : "");
    return itemLink(item, "card tile", item.name + ", " + SINGULAR[item.type], [
      el("span", { class: "tile-top" }, [el("span", { class: "tile-mark" }, [itemIcon(item, item.type === "app" ? 40 : 22)]), newBadge(item)]),
      el("span", { class: "tile-name", text: item.name }),
      el("span", { class: "tile-desc", text: note || item.description || C.doc(item).description || "" }),
      el("span", { class: "tile-meta", text: meta }),
    ]);
  }

  function rowCard(item, note) {
    if (C.isLook(item)) return card(item, { aspect: "4 / 3", note: note });
    return tile(item, note);
  }

  function listRow(item) {
    var doc = C.doc(item);
    var cat = C.categoryLabel(item);
    var meta = item.type === "routine" ? C.schedule(doc.schedule_cron) : item.type === "plugin" ? (doc.adds || []).length + " things" : cat;
    var name = el("span", { class: "skill-name" }, [item.name, newBadge(item)]);
    return el("li", null, [itemLink(item, "skill" + (item.type === "app" ? " app-row" : ""), item.name + ", " + SINGULAR[item.type], [
      itemIcon(item, item.type === "app" ? 32 : null),
      el("span", null, [
        name,
        el("span", { class: "skill-desc", text: item.description || "" }),
        el("span", { class: "skill-meta-line", text: [meta, item.type === "skill" ? item.license : null].filter(Boolean).join(" · ") }),
      ]),
      el("span", { class: "skill-meta", text: C.community(item) ? "By " + item.author.name : meta }),
      el("span", { class: "skill-meta", text: item.license }),
      el("span", { class: "skill-go" }, [G.icon("chevron-right", { size: 18 })]),
    ])]);
  }

  function cardsFor(type, list) {
    if (LISTED.indexOf(type) !== -1) return el("ul", { class: "skills" }, list.map(listRow));
    var grid = el("div", { class: "grid" }, list.map(function (i) { return card(i); }));
    grid.style.setProperty("--cols", columns(type));
    return grid;
  }

  function section(title, n, body, seeAll, note) {
    var h = el("h2", null, [title, n == null ? null : el("span", { class: "n", text: String(n) })]);
    var head = el("div", { class: "section-head" }, [
      el("div", null, [h, note ? el("p", { class: "section-note", text: note }) : null]),
      seeAll ? el("button", { class: "see-all", type: "button", onclick: seeAll, text: "See all" }) : null,
    ]);
    return el("section", { class: "section" }, [head, body]);
  }
  /** A sideways-scrolling row of mixed cards. */
  function shelf(title, list, noteOf, note) {
    if (!list.length) return null;
    var row = el("div", { class: "shelf row" }, list.map(function (i) { return rowCard(i, noteOf ? noteOf(i) : null); }));
    return section(title, null, row, null, note);
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

  /** Nothing matched: ask for it on the requests board, or ask Casama to make it. */
  function emptySearch(q) {
    var links = C.requestLinks(q);
    return el("div", { class: "empty" }, [
      el("p", { class: "empty-title", text: "Nothing matches “" + q + "” yet." }),
      el("p", { class: "small", text: "Ask for it and people can vote it up, or have Casama make one for you now." }),
      el("div", { class: "empty-actions" }, [
        el("a", { class: "btn primary", href: links.app }, [G.icon("message-square-plus"), "Request this"]),
        el("a", { class: "btn", href: C.askToMake(q) }, [G.icon("sparkles"), "Ask Casama to make it"]),
      ]),
      el("p", { class: "small" }, ["No app on this device? ", el("a", { href: links.github, rel: "noopener", text: "Request it on GitHub" }), " · ",
        el("button", { class: "linkish", type: "button", onclick: function () { setQuery(""); }, text: "Clear search" })]),
    ]);
  }

  function homeRows(found) {
    var out = [];
    // Picks: featured items, the ones with a note first, mixing kinds.
    var picks = found.filter(function (i) { return i.featured; });
    var byType = {};
    picks.forEach(function (i) { (byType[i.type] = byType[i.type] || []).push(i); });
    Object.keys(byType).forEach(function (t) { byType[t].sort(function (a, b) { return (b.pick ? 1 : 0) - (a.pick ? 1 : 0); }); });
    var mixed = [];
    for (var n = 0; mixed.length < picks.length; n++) TYPES.forEach(function (t) { if (byType[t] && byType[t][n]) mixed.push(byType[t][n]); });
    mixed.sort(function (a, b) { return (b.pick ? 1 : 0) - (a.pick ? 1 : 0); });
    out.push(shelf("Picks", mixed.slice(0, 12), function (i) { return i.pick || null; }, "Chosen by the Casama team."));

    var fresh = found.filter(newShown).sort(function (a, b) { return C.day(b.added) - C.day(a.added); });
    out.push(shelf("New", fresh.slice(0, 12), null, "Added in the last 30 days."));

    var trending = found.filter(function (i) { var s = statsOf(i); return s && s.trending > 0; })
      .sort(function (a, b) { return statsOf(b).trending - statsOf(a).trending; });
    out.push(shelf("Trending this week", trending.slice(0, 12), function (i) { return C.statsLine(statsOf(i)) || null; }));

    var used = found.filter(function (i) { var s = statsOf(i); return MOST_USED_TYPES.indexOf(i.type) !== -1 && s && s.installers > 0; })
      .sort(function (a, b) { return statsOf(b).installers - statsOf(a).installers; });
    out.push(shelf("Most used", used.slice(0, 12), function (i) { return C.statsLine(statsOf(i)) || null; }));

    out.push(shelf("Starter sets", state.sets, null, "A few things that work well together, added in one go."));

    var season = found.filter(function (i) { return C.inSeason(i); });
    out.push(shelf("In season", season.slice(0, 12)));
    return out.filter(Boolean);
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
    var sets = q ? C.search(state.sets, q) : [];
    $("count").textContent = q
      ? (shown.length === 1 ? "1 match" : shown.length + " matches") + " for “" + q + "”"
      : state.type ? C.count(shown.length, state.type) : shown.length + " items";
    document.querySelectorAll(".chip[data-filter]").forEach(function (b) { b.setAttribute("aria-pressed", String(!!state.filter[b.dataset.filter])); });
    var clear = $("clear-filters");
    if (clear) clear.hidden = !filtering();
    if (!shown.length && !sets.length) {
      if (q) { content.appendChild(emptySearch(q)); return; }
      content.appendChild(el("div", { class: "empty" }, [
        el("p", { text: filtering() ? "Nothing here with these filters." : "Nothing here yet." }),
        filtering() ? el("button", { class: "btn", type: "button", onclick: clearFilters, text: "Clear filters" }) : null,
      ]));
      return;
    }
    if (state.type) {
      content.appendChild(el("section", { class: "section" }, [cardsFor(state.type, shown)]));
      return;
    }
    if (q) {
      // Best matches first, across every kind; then each kind.
      var best = shown.slice(0, 8);
      if (shown.length > 3) content.appendChild(shelf("Best matches", best));
      if (sets.length) content.appendChild(shelf("Starter sets", sets));
    } else if (!filtering()) {
      homeRows(found).forEach(function (s) { content.appendChild(s); });
    }
    TYPES.forEach(function (type) {
      var list = shown.filter(function (i) { return i.type === type; });
      if (!list.length) return;
      // A phone shows two rows of each kind; wider screens one.
      var visible = LISTED.indexOf(type) !== -1 ? list.slice(0, 4) : list.slice(0, columns(type) * (phone() ? 2 : 1));
      content.appendChild(section(PLURAL[type], list.length, cardsFor(type, visible), list.length > visible.length ? function () { setType(type); } : null));
    });
  }

  // ---------------------------------------------------------------- detail
  function swatchChips(seeds, dark) {
    var c = G.scheme(seeds, dark);
    return el("span", { class: "chips", "aria-hidden": "true" }, [c.p, c.pc, c.s, c.t, c.surf].map(function (color) {
      var i = el("i"); i.style.background = color; return i;
    }));
  }
  function nameOf(type, id) { var i = find(type, id); return i ? i.name : id; }

  function facts(item) {
    var doc = C.doc(item);
    var rows = [];
    var row = function (label, value) { rows.push(el("tr", null, [el("th", { scope: "row", text: label }), el("td", null, [typeof value === "string" ? document.createTextNode(value) : value])])); };
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
      row("Background", G.describeWallpaper(doc.wallpaper));
    } else if (item.type === "scheme") {
      row("Light", swatchChips(doc, false));
      row("Dark", swatchChips(doc, true));
    } else if (item.type === "wallpaper") {
      row("Kind", G.describeWallpaper(doc));
    } else if (item.type === "bot") {
      row("Category", C.categoryLabel(item) || "-");
      row("Asks first", doc.autonomy === "ask_always" ? "Before every action" : "Before risky actions");
      var comes = (doc.skills || []).map(function (k) { return "Skill: " + k.name; }).concat((doc.routines || []).map(function (r) { return "Routine: " + r.name + " (" + C.schedule(r.schedule_cron) + ")"; }));
      if (comes.length) row("Comes with", comes.join(" · "));
    } else if (item.type === "routine") {
      row("When", C.schedule(doc.schedule_cron));
      row("Category", C.categoryLabel(item) || "-");
    } else if (item.type === "plugin") {
      row("Adds", (doc.adds || []).join(" · "));
      var at = String(doc.url || "").replace(/\/tree\/[^/]+/, "/tree/" + doc.commit);
      row("Reviewed code", el("a", { href: at, rel: "noopener", text: String(doc.commit || "").slice(0, 7) + " on GitHub" }));
    } else if (item.type === "app") {
      row("Category", C.categoryLabel(item) || "-");
      row("Connects to", el("code", { text: doc.url || "-" }));
      row("Needs", (doc.auth || []).map(function (a) { return AUTH[a] || a; }).join(" or "));
      if (doc.homepage) row("Website", el("a", { href: doc.homepage, rel: "noopener", text: doc.homepage.replace(/^https:\/\//, "") }));
    } else {
      row("Category", C.categoryLabel(item) || "-");
    }
    var author = item.author || {};
    var by = el("span", null, [
      el("a", { href: C.authorPath(C.authorKey(item)), text: author.name || "-" }),
      C.madeBy(item).filter(function (m) { return m !== author.name; }).map(function (m) { return " · " + m; }).join(""),
    ]);
    row("Made by", by);
    if (item.remix_of && item.remix_of.type && item.remix_of.id)
      row("Remix of", el("a", { href: C.pagePath(item.remix_of), text: nameOf(item.remix_of.type, item.remix_of.id) }));
    var version = "Version " + (item.version || 1);
    if (item.updated) version += " · updated " + C.longDate(item.updated);
    row("Version", version);
    row("License", item.license || "-");
    row("Source", el("a", { href: C.sourceLink(item), rel: "noopener", text: "On GitHub" }));
    return el("table", { class: "facts" }, [el("tbody", null, rows)]);
  }

  /** What it can access, its examples, what it needs and asks, and its changelog. */
  function extras(item) {
    var out = [];
    var acc = C.access(item);
    if (acc.length)
      out.push(el("div", { class: "block" }, [el("h3", { text: "What it can access" }), el("ul", { class: "access" }, acc.map(function (a) {
        return el("li", null, [G.icon(a.icon, { size: 16 }), el("span", null, [el("b", { text: a.label + " " }), a.text])]);
      }))]));
    var ex = C.examples(item);
    if (ex.length)
      out.push(el("div", { class: "block" }, [el("h3", { text: "Try it" }), el("ul", { class: "examples" }, ex.map(function (p) {
        return el("li", null, [el("a", { href: C.askLink(p), title: "Ask Casama" }, [G.icon("message-circle", { size: 16 }), el("span", { text: p })])]);
      }))]));
    var needs = C.needs(item);
    if (needs.apps.length || needs.skills.length) {
      var list = needs.apps.map(function (id) { return { type: "app", id: id }; }).concat(needs.skills.map(function (id) { return { type: "skill", id: id }; }));
      out.push(el("div", { class: "block" }, [el("h3", { text: "Works with" }), el("p", { class: "inline-list" }, list.map(function (n, i) {
        var known = find(n.type, n.id);
        return el("span", null, [i ? ", " : "", known ? el("a", { href: C.pagePath(n), text: known.name }) : el("span", { text: n.id })]);
      }))]));
    }
    var inp = C.inputs(item);
    if (inp.length)
      out.push(el("div", { class: "block" }, [el("h3", { text: "Asks you when you add it" }), el("p", { class: "small", text: inp.map(function (x) { return x.label; }).join(" · ") })]));
    var log = C.changelog(item);
    if (log.length)
      out.push(el("details", { class: "block changelog" }, [el("summary", { text: "What's new" }), el("ul", null, log.map(function (c) {
        return el("li", null, [el("b", { text: "Version " + c.version }), " · " + C.longDate(c.date) + (c.breaking ? " · changes how it works" : ""), el("br"), c.note]);
      }))]));
    return out;
  }

  function copyButton(text, label) {
    var copy = el("button", { class: "btn", type: "button" }, [G.icon("link"), label]);
    copy.addEventListener("click", function () {
      var done = function () { copy.lastChild.textContent = "Copied"; setTimeout(function () { copy.lastChild.textContent = label; }, 1600); };
      if (navigator.clipboard) navigator.clipboard.writeText(text).then(done, done); else done();
    });
    return copy;
  }

  function openDetail(item) {
    state.open = item;
    var dark = state.dark;
    dialog.textContent = "";
    var font = headingFont(item);
    var title = el("h2", { id: "detail-title", text: item.name });
    if (font) title.style.fontFamily = "'" + font + "', var(--font)";
    var meta = el("p", { class: "meta", text: SINGULAR[item.type] + " · By " + ((item.author || {}).name || "") + " · " + item.license });
    var stats = C.statsLine(statsOf(item));

    var pic = el("div", { class: "detail-pic" });
    function drawPic() {
      pic.textContent = "";
      var d = C.doc(item);
      if (item.type === "bot" || item.type === "routine") {
        pic.appendChild(el("pre", { class: "instructions full", "aria-label": "Instructions", text: item.type === "bot" ? d.persona : d.instructions_md }));
        if (item.type === "bot" && (d.starters || []).length)
          pic.appendChild(el("ul", { class: "app-can" }, d.starters.map(function (s) { return el("li", null, [G.icon("message-circle", { size: 16 }), s]); })));
        return;
      }
      if (item.type === "plugin") {
        pic.appendChild(el("div", { class: "app-hero" }, [
          G.icon(d.icon || "puzzle", { size: 72 }),
          el("ul", { class: "app-can" }, (d.adds || []).map(function (c) { return el("li", null, [G.icon("check", { size: 16 }), c]); })),
        ]));
        return;
      }
      if (item.type === "app") {
        pic.appendChild(el("div", { class: "app-hero" }, [
          appLogo(item, 88),
          el("ul", { class: "app-can" }, (d.capabilities || []).map(function (c) { return el("li", null, [G.icon("check", { size: 16 }), c]); })),
          d.note ? el("p", { class: "small", text: d.note }) : null,
        ]));
        return;
      }
      if (item.type === "skill") {
        var pre = el("pre", { class: "instructions full", "aria-label": "Instructions", text: "Loading the instructions…" });
        pic.appendChild(pre);
        var path = (item.files || []).filter(function (f) { return /\/SKILL\.md$/.test(f); })[0];
        if (path) fetch("/" + path).then(function (r) { return r.text(); }).then(function (md) {
          pre.textContent = md.replace(/^---\n[\s\S]*?\n---\n?/, "").trim();
        }).catch(function () { pre.textContent = "The instructions couldn't be loaded."; });
        return;
      }
      var look = G.lookOf(item, { alone: false });
      if (item.type === "wallpaper") {
        var pics = el("div", { class: "pics" });
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
      pic.appendChild(el("div", { class: "seg", role: "group", "aria-label": "Preview in" }, ["light", "dark"].map(function (mode) {
        return el("button", { type: "button", "aria-pressed": String((mode === "dark") === dark), onclick: function () { dark = mode === "dark"; drawPic(); }, text: mode === "dark" ? "Dark" : "Light" });
      })));
    }
    drawPic();

    var hint = {
      app: "Connect it in Casama from Settings → Connections.",
      bot: "Pick it in Casama when you make a new bot.",
      routine: "Find it under Ideas when you add a routine to a bot.",
      plugin: "Add it in Casama from a bot's Plugins page, at the reviewed version.",
    }[item.type];
    var info = el("div", { class: "detail-info" }, [
      title,
      meta,
      stats ? el("p", { class: "stats-line", text: stats }) : null,
      item.pick ? el("p", { class: "pick-note" }, [G.icon("sparkles", { size: 16 }), item.pick]) : null,
      item.description ? el("p", { class: "desc", text: item.description }) : null,
    ].concat(extras(item), [
      facts(item),
      (item.tags || []).length ? el("div", { class: "tags" }, item.tags.map(function (tag) {
        return el("button", { class: "tag", type: "button", onclick: function () { dialog.close(); setType(null); setQuery(tag); }, text: tag });
      })) : null,
      hint ? el("p", { class: "small", text: hint }) : null,
      el("div", { class: "actions" }, [
        el("a", { class: "btn primary", href: C.openLink(item) }, [G.icon("external-link"), item.type === "skill" ? "Install in Casama" : "Open in Casama"]),
        copyButton(C.shareLink(item), "Copy link"),
        el("a", { class: "btn quiet", href: C.pagePath(item), text: "Full page" }),
      ]),
    ]));
    var close = el("button", { class: "detail-close", type: "button", "aria-label": "Close", autofocus: "", onclick: function () { dialog.close(); } }, [G.icon("x")]);
    dialog.appendChild(el("div", { class: "detail-inner" }, [pic, info]));
    dialog.appendChild(close);
    if (!dialog.open) dialog.showModal();
  }

  /** A starter set: what's in it, and one button to add it all. */
  function openSet(set) {
    state.open = set;
    dialog.textContent = "";
    var members = C.setItems(set).map(function (m) { return find(m.type, m.id) || { type: m.type, id: m.id, name: m.id }; });
    var list = el("ul", { class: "skills set-list" }, members.map(function (m) {
      return el("li", null, [el("a", { class: "skill", href: C.pagePath(m) }, [
        C.isLook(m) ? G.icon(m.type === "wallpaper" ? "image" : "palette") : itemIcon(m, m.type === "app" ? 32 : null),
        el("span", null, [el("span", { class: "skill-name", text: m.name }), el("span", { class: "skill-desc", text: SINGULAR[m.type] + (m.description ? " · " + m.description : "") })]),
        el("span", { class: "skill-go" }, [G.icon("chevron-right", { size: 18 })]),
      ])]);
    }));
    var info = el("div", { class: "detail-info wide" }, [
      el("h2", { id: "detail-title", text: set.name }),
      el("p", { class: "meta", text: "Starter set · " + members.length + " items" }),
      set.description || C.doc(set).description ? el("p", { class: "desc", text: set.description || C.doc(set).description }) : null,
      list,
      el("div", { class: "actions" }, [
        el("a", { class: "btn primary", href: C.openLink(set) }, [G.icon("external-link"), "Add all in Casama"]),
        copyButton(C.pageUrl(set), "Copy link"),
      ]),
    ]);
    var close = el("button", { class: "detail-close", type: "button", "aria-label": "Close", autofocus: "", onclick: function () { dialog.close(); } }, [G.icon("x")]);
    dialog.appendChild(el("div", { class: "detail-inner single" }, [info]));
    dialog.appendChild(close);
    if (!dialog.open) dialog.showModal();
  }

  dialog.addEventListener("close", function () { state.open = null; });
  dialog.addEventListener("click", function (e) { if (e.target === dialog) dialog.close(); });

  // ---------------------------------------------------------------- routing and controls
  function route() {
    var parts = location.hash.replace(/^#/, "").split("/");
    var type = TYPES.indexOf(parts[0]) !== -1 || parts[0] === "set" ? parts[0] : null;
    // Old item links (#theme/lagoon) now have their own page.
    if (type && parts[1] && /^[a-z0-9][a-z0-9-]{0,62}$/.test(parts[1])) { location.replace(C.pagePath({ type: type, id: parts[1] })); return; }
    if (type === "set") type = null;
    if (parts[0] && !type) { render(); return; }
    state.type = type;
    if (dialog.open) dialog.close();
    render();
  }

  function syncUrl() {
    var p = new URLSearchParams(location.search);
    if (state.q.trim()) p.set("q", state.q.trim()); else p.delete("q");
    var qs = p.toString();
    history.replaceState(null, "", location.pathname + (qs ? "?" + qs : "") + (state.type ? "#" + state.type : ""));
  }
  function setType(type) { state.type = type; syncUrl(); render(); }
  function setQuery(q) { state.q = q; $("q").value = q; syncUrl(); render(); }
  function clearFilters() {
    state.filter = { topic: "", free: false, self: false, computer: false };
    if ($("topic")) $("topic").value = "";
    render();
  }

  $("search-icon").appendChild(G.icon("search"));
  $("q").value = state.q;
  var typing;
  $("q").addEventListener("input", function (e) {
    state.q = e.target.value;
    render();
    clearTimeout(typing);
    typing = setTimeout(syncUrl, 400);
  });
  if ($("topic")) $("topic").addEventListener("change", function (e) { state.filter.topic = e.target.value; render(); });
  document.querySelectorAll(".chip[data-filter]").forEach(function (b) {
    b.addEventListener("click", function () { state.filter[b.dataset.filter] = !state.filter[b.dataset.filter]; render(); });
  });
  if ($("clear-filters")) $("clear-filters").addEventListener("click", clearFilters);
  document.querySelectorAll(".toolbar .seg button").forEach(function (b) {
    b.setAttribute("aria-pressed", String((b.dataset.mode === "dark") === state.dark));
    b.addEventListener("click", function () {
      state.dark = b.dataset.mode === "dark";
      applyChrome();
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
