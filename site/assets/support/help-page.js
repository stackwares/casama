/* casama.ai/help: the search box over the questions (every word must match the question or its
   answer), and Casama Help inline under them. Without JavaScript every question is simply shown. */
(function () {
  "use strict";

  var root = document.querySelector("[data-help]");
  if (!root) return;
  var box = root.querySelector("[data-help-search]");
  var input = document.getElementById("help-q");
  var status = root.querySelector("[data-help-status]");
  var none = root.querySelector("[data-help-none]");
  var ask = root.querySelector("[data-help-ask]");
  var askText = root.querySelector("[data-help-ask-text]");
  var askBtn = root.querySelector("[data-help-ask-btn]");
  var chat = root.querySelector("[data-casama-help-inline]");
  var groups = Array.prototype.slice.call(root.querySelectorAll("[data-help-group]"));
  var items = Array.prototype.slice.call(root.querySelectorAll("[data-help-q]")).map(function (el) {
    return { el: el, text: el.textContent.toLowerCase().replace(/\s+/g, " ") };
  });
  if (!box || !input) return;
  box.hidden = false;

  var timer = 0;
  function apply() {
    var query = input.value.trim();
    var words = query.toLowerCase().split(/\s+/).filter(Boolean);
    var shown = 0;
    items.forEach(function (item) {
      var hit = words.every(function (w) { return item.text.indexOf(w) !== -1; });
      item.el.hidden = !hit;
      if (hit) shown++;
    });
    groups.forEach(function (g) {
      g.hidden = !g.querySelector("[data-help-q]:not([hidden])");
    });
    none.hidden = !(words.length && shown === 0);
    ask.hidden = !words.length;
    askText.textContent = query.length > 80 ? query.slice(0, 80) + "…" : query;
    clearTimeout(timer);
    timer = setTimeout(function () {
      status.textContent = words.length ? (shown === 1 ? "1 matching question" : shown + " matching questions") : "";
    }, 400);
  }
  input.addEventListener("input", apply);

  // casama.ai/help?q=… starts with that search.
  try {
    var q = new URLSearchParams(location.search).get("q");
    if (q) { input.value = q.slice(0, 200); apply(); }
  } catch (e) { /* no search then */ }

  askBtn.addEventListener("click", function () {
    var text = input.value.trim().slice(0, 1000);
    if (!text || !window.CasamaHelp) return;
    window.CasamaHelp.open({ inline: chat, text: text });
    chat.scrollIntoView({ block: "start", behavior: window.matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth" });
  });

  // Casama Help itself lives under the questions; it loads once the loader (site.js) is there.
  function start() {
    if (window.CasamaHelp && chat) window.CasamaHelp.open({ inline: chat });
  }
  if (window.CasamaHelp) start();
  else document.addEventListener("casama-help-ready", start, { once: true });
})();
