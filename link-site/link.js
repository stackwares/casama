/* casama.link (D-317): the address check and the report form. Everything happens on this page:
   the check reads only the address's shape (it never contacts the server, so this page can't be
   used to find out which addresses exist), and the report opens the visitor's email app. */
(function () {
  "use strict";

  // apps/server/src/link/servers.ts newLabel(): one of LABEL_FIRST, then 11 of LABEL_REST
  // (no i, l, o, 0 or 1). tunnels.ts: the server at <label>, its bots' pages at <label>-p.
  var LABEL = /^[a-hjkmnp-z][a-hjkmnp-z2-9]{11}$/;
  var ZONE = "casama.link";
  var DOCS = "https://docs.casama.ai/self-hosting/remote-access";

  /** What a pasted address is: { kind: "server" | "pages" | "home" | "bad" | "other", host }. */
  function read(raw) {
    var s = String(raw || "")
      .trim()
      .toLowerCase();
    if (!s) return null;
    var host = s
      .replace(/^[a-z][a-z0-9+.-]*:\/\//, "")
      .replace(/^[^@/]*@/, "")
      .split(/[/?#:\s]/)[0]
      .replace(/\.$/, "");
    if (!host) return { kind: "bad", host: s };
    if (LABEL.test(host)) host += "." + ZONE; // just the label
    if (host === ZONE || host === "www." + ZONE) return { kind: "home", host: host };
    if (host.slice(-(ZONE.length + 1)) !== "." + ZONE) return { kind: "other", host: host };
    var sub = host.slice(0, -(ZONE.length + 1));
    var pages = /-p$/.test(sub);
    var label = pages ? sub.slice(0, -2) : sub;
    if (!LABEL.test(label)) return { kind: "bad", host: host };
    return { kind: pages ? "pages" : "server", host: host };
  }

  function el(tag, attrs, text) {
    var n = document.createElement(tag);
    for (var k in attrs || {}) n.setAttribute(k, attrs[k]);
    if (text != null) n.textContent = text;
    return n;
  }

  var check = document.getElementById("check");
  var input = document.getElementById("check-input");
  var out = document.getElementById("check-result");
  var reportAddress = document.getElementById("r-address");

  function show(r) {
    out.replaceChildren();
    out.className = "check-result " + (r.kind === "server" || r.kind === "pages" ? "ok" : "no");
    var title,
      row,
      lines = [],
      actions = [];
    if (r.kind === "server" || r.kind === "pages") {
      title = "A Casama server's address";
      lines.push(
        r.kind === "pages"
          ? "The -p ending means it shows pages that bots on that server made: reports, sites, files they shared."
          : "It leads to the sign-in screen of a Casama server.",
      );
      lines.push(
        "Someone runs that server on their own computer. Casama gave it the address, but doesn't run it and can't see what's on it.",
      );
      actions.push(["report", "Report this address"]);
      actions.push(["mine", "It's my server"]);
    } else if (r.kind === "home") {
      title = "That's this page";
      lines.push("Addresses have a part before .casama.link, like k7qm2xfd9abc.casama.link.");
    } else if (r.kind === "other") {
      title = "Not a casama.link address";
      lines.push(
        r.host +
          " isn't one of ours, so Casama can't say anything about it. Be careful with links you weren't expecting.",
      );
    } else {
      title = "Casama Link doesn't give out addresses like this";
      lines.push(
        "Real ones have 12 letters and digits before .casama.link (or -p.casama.link). If someone sent you this, it may be pretending to be one.",
      );
      actions.push(["report", "Report it anyway"]);
    }
    out.appendChild(el("h3", null, title));
    lines.forEach(function (t) {
      out.appendChild(el("p", null, t));
    });
    if (actions.length) {
      row = el("div", { class: "check-actions" });
      actions.forEach(function (a) {
        var b;
        if (a[0] === "mine") {
          row.appendChild(el("a", { class: "text-link", href: DOCS }, a[1]));
        } else {
          b = el("button", { class: "text-link", type: "button" }, a[1]);
          b.addEventListener("click", function () {
            reportAddress.value = "https://" + r.host;
            document.getElementById("report").scrollIntoView();
            document.getElementById("r-details").focus({ preventScroll: true });
          });
          row.appendChild(b);
        }
      });
      out.appendChild(row);
    }
    out.hidden = false;
  }

  check.addEventListener("submit", function (e) {
    e.preventDefault();
    var r = read(input.value);
    if (r) show(r);
    else {
      out.hidden = true;
      input.focus();
    }
  });

  // The report: the visitor's own email app, so this page never holds or sends what they wrote.
  var form = document.getElementById("report-form");
  var error = document.getElementById("r-error");
  form.addEventListener("submit", function (e) {
    e.preventDefault();
    var address = reportAddress.value.trim();
    if (!address) {
      error.textContent = "Add the address you're reporting.";
      error.hidden = false;
      reportAddress.focus();
      return;
    }
    error.hidden = true;
    var kind = (form.querySelector("input[name=kind]:checked") || {}).value || "Something else";
    var details = document.getElementById("r-details").value.trim().slice(0, 1500);
    var r = read(address);
    var subject =
      "casama.link report: " + (r && r.host ? r.host : address).slice(0, 120) + " (" + kind + ")";
    var body = [
      "Address: " + address,
      "What's wrong: " + kind,
      "",
      details || "(no details)",
      "",
      "Seen: " + new Date().toUTCString(),
      "Sent from https://casama.link/#report",
    ].join("\n");
    location.href =
      "mailto:security@casama.ai?subject=" +
      encodeURIComponent(subject) +
      "&body=" +
      encodeURIComponent(body);
  });

  // A pasted link to this page with an address in it (casama.link/#report=<address>) fills the form.
  var m = /^#report=(.+)$/.exec(location.hash);
  if (m) {
    try {
      reportAddress.value = decodeURIComponent(m[1]).slice(0, 300);
    } catch (err) {}
    document.getElementById("report").scrollIntoView();
  }

  var header = document.querySelector(".site-header");
  var onScroll = function () {
    header.classList.toggle("scrolled", window.scrollY > 8);
  };
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();
})();

// One anonymous page-view count (D-398), posted to casama.ai's counter, which forwards it to Google
// Analytics from the server: no cookie and no Google script on casama.link.
(function () {
  try {
    if (!navigator.sendBeacon || !/(^|\.)casama\.link$/.test(location.hostname)) return;
    let from = "";
    try {
      from = document.referrer ? new URL(document.referrer).hostname : "";
    } catch (e) {
      from = "";
    }
    let utm = new URLSearchParams(location.search).get("utm_source") || "";
    navigator.sendBeacon(
      "https://casama.ai/b",
      JSON.stringify({ h: "link", p: location.pathname, r: from, u: utm }),
    );
  } catch (e) {
    /* counting is never worth breaking the page for */
  }
})();
