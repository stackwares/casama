// casama.ai/pair: where a sign-in QR code lands when the app isn't installed, or didn't catch the
// link. The code and the server's address ride after "#", which a browser never sends to a web
// server. They are read only here, to hand them to the app through its own link. Nothing on this
// page stores or sends them.
(function () {
  var open = document.getElementById("open-app");
  if (!open) return;
  var values = location.hash.replace(/^#/, "");
  if (/(^|&)s=/.test(values) && /(^|&)c=/.test(values)) {
    open.setAttribute("href", "casama://app/pair?" + values);
  } else {
    document.documentElement.classList.add("no-code");
  }
})();
