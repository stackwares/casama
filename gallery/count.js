/* One anonymous page-view count for gallery.casama.ai (D-398), posted to casama.ai's counter, which
 * forwards it to Google Analytics from the server: no cookie and no Google script here. */
(function () {
  try {
    if (!navigator.sendBeacon || location.hostname !== "gallery.casama.ai") return;
    var from = "";
    try { from = document.referrer ? new URL(document.referrer).hostname : ""; } catch (e) { from = ""; }
    var utm = new URLSearchParams(location.search).get("utm_source") || "";
    navigator.sendBeacon("https://casama.ai/b", JSON.stringify({ h: "gallery", p: location.pathname, r: from, u: utm }));
  } catch (e) { /* counting is never worth breaking the page for */ }
})();
