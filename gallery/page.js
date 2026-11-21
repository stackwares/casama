/* The gallery's static pages (/i/<type>/<id>/, /by/<handle>/, built by build-pages.mjs): draws
   look previews with gallery.js, a light/dark switch, the public usage line and copy buttons. */
(function () {
  "use strict";
  var G = window.CasamaGallery;
  var node = document.getElementById("page-data");
  var data = {};
  try { data = node ? JSON.parse(node.textContent) : {}; } catch (e) { data = {}; }
  var dark = document.documentElement.getAttribute("data-theme") === "dark";
  var looks = {};
  (data.looks || []).forEach(function (i) { looks[i.type + "/" + i.id] = i; });

  function seg(onPick) {
    var box = document.createElement("div");
    box.className = "seg";
    box.setAttribute("role", "group");
    box.setAttribute("aria-label", "Preview in");
    ["light", "dark"].forEach(function (mode) {
      var b = document.createElement("button");
      b.type = "button";
      b.textContent = mode === "dark" ? "Dark" : "Light";
      b.setAttribute("aria-pressed", String((mode === "dark") === dark));
      b.addEventListener("click", function () {
        dark = mode === "dark";
        box.querySelectorAll("button").forEach(function (x) { x.setAttribute("aria-pressed", String(x === b)); });
        onPick();
      });
      box.appendChild(b);
    });
    return box;
  }

  // The item's own preview, as on the gallery.
  var pic = document.getElementById("pic");
  var item = pic && looks[pic.getAttribute("data-key")];
  if (G && pic && item) {
    var holder = document.createElement("div");
    holder.className = "pics";
    var draw = function () {
      holder.textContent = "";
      var look = G.lookOf(item, { alone: false });
      if (item.type === "wallpaper") {
        var portrait = G.wallpaper(item, { dark: dark, label: item.name });
        portrait.style.flex = "0 0 34%";
        holder.appendChild(portrait);
        var behind = G.chat(look, { dark: dark, label: "Behind a Casama chat" });
        behind.style.flex = "1";
        holder.appendChild(behind);
      } else {
        holder.appendChild(G.chat(look, { dark: dark, aspect: "16 / 10", label: item.name + " in a Casama chat" }));
      }
      drawMinis();
    };
    pic.textContent = "";
    pic.appendChild(holder);
    pic.appendChild(seg(draw));
    if (item.type === "theme" && item.document && item.document.headingFont) {
      G.ensureFonts([item.document.headingFont]);
      var h1 = document.getElementById("name");
      if (h1) h1.style.fontFamily = "'" + item.document.headingFont + "', var(--display)";
    }
    draw();
  } else {
    drawMinis();
  }

  // Small previews next to looks in lists (related items, author pages).
  function drawMinis() {
    if (!G) return;
    document.querySelectorAll(".mini-pic[data-key]").forEach(function (box) {
      var it = looks[box.getAttribute("data-key")];
      if (!it) return;
      box.textContent = "";
      box.appendChild(G.preview(it, { dark: dark, thumb: true, aspect: "4 / 3", label: "" }));
    });
  }

  // Public usage numbers, when the stats endpoint answers (hidden otherwise).
  var statsBox = document.getElementById("stats");
  if (statsBox && data.stats && window.fetch) {
    var meta = document.querySelector('meta[name="casama-stats"]');
    var url = new URLSearchParams(location.search).get("stats") || (meta && meta.content) || "https://api.casama.ai/v1/gallery/stats";
    if (url !== "off")
      fetch(url, { credentials: "omit" }).then(function (r) { return r.ok ? r.json() : null; }).then(function (res) {
        var s = res && res.items && res.items[data.stats];
        if (!s) return;
        var parts = [];
        if (s.installers) parts.push("Used by " + Number(s.installers).toLocaleString("en-US") + " people");
        if (typeof s.success === "number") parts.push(Math.round(s.success * (s.success <= 1 ? 100 : 1)) + "% of runs finish");
        if (!parts.length) return;
        statsBox.textContent = parts.join(" · ");
        statsBox.hidden = false;
      }).catch(function () {});
  }

  // Copy buttons: data-copy holds the text.
  document.querySelectorAll("[data-copy]").forEach(function (b) {
    var label = b.querySelector("span");
    var was = label ? label.textContent : "";
    b.addEventListener("click", function () {
      var done = function () { if (label) { label.textContent = "Copied"; setTimeout(function () { label.textContent = was; }, 1600); } };
      if (navigator.clipboard) navigator.clipboard.writeText(b.getAttribute("data-copy")).then(done, done); else done();
    });
  });
})();
