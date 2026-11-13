// Runs in <head>, before first paint: turns on the script-only styles and restores the
// visitor's light/dark choice and any look they kept, so the page never flashes another look.
(function () {
  var root = document.documentElement;
  root.classList.add("js");
  try {
    var mode = localStorage.getItem("casama-site-theme");
    if (mode === "dark" || mode === "light") root.setAttribute("data-theme", mode);
    var kept = JSON.parse(localStorage.getItem("casama-site-look") || "null");
    if (kept && kept.light && kept.dark) {
      var dark = mode ? mode === "dark" : !!(window.matchMedia && matchMedia("(prefers-color-scheme: dark)").matches);
      var tokens = dark ? kept.dark : kept.light;
      for (var k in tokens) root.style.setProperty(k, tokens[k]);
    }
  } catch (e) {}
})();
