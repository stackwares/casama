/* The waitlist and invite pages' script (docs/WAITLIST-PLAN.md §5, §7). One file for /waitlist, the
   invite pages (/invite/<code>, /i/<code>) and /waitlist/leave.

   Joining, claiming an invite and leaving talk to the API. The first two need a solved sign-up
   puzzle (a proof of work, D-094): sha256("<challenge>:<nonce>") must start with `difficulty` zero
   bits. WebCrypto's digest is async and far too slow for ~260,000 tries, so this file carries a small
   synchronous SHA-256 and searches in chunks, so the page stays responsive.

   The API is https://api.casama.ai, or window.CASAMA_API; on localhost it is the local stack's
   http://localhost:8787. window.CasamaWaitlist holds the pure parts (for tests). */
(function (root) {
  "use strict";

  // ------------------------------------------------------------------ SHA-256

  var K = new Int32Array([
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ]);
  var INIT = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];

  /** Runs one 64-byte block (m[o..o+63]) through the compression function, updating h in place. */
  function block(h, w, m, o) {
    var i, x, y;
    for (i = 0; i < 16; i++) {
      var j = o + i * 4;
      w[i] = (m[j] << 24) | (m[j + 1] << 16) | (m[j + 2] << 8) | m[j + 3];
    }
    for (i = 16; i < 64; i++) {
      x = w[i - 15];
      y = w[i - 2];
      var s0 = ((x >>> 7) | (x << 25)) ^ ((x >>> 18) | (x << 14)) ^ (x >>> 3);
      var s1 = ((y >>> 17) | (y << 15)) ^ ((y >>> 19) | (y << 13)) ^ (y >>> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) | 0;
    }
    var a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7];
    for (i = 0; i < 64; i++) {
      var S1 = ((e >>> 6) | (e << 26)) ^ ((e >>> 11) | (e << 21)) ^ ((e >>> 25) | (e << 7));
      var ch = (e & f) ^ (~e & g);
      var t1 = (hh + S1 + ch + K[i] + w[i]) | 0;
      var S0 = ((a >>> 2) | (a << 30)) ^ ((a >>> 13) | (a << 19)) ^ ((a >>> 22) | (a << 10));
      var maj = (a & b) ^ (a & c) ^ (b & c);
      var t2 = (S0 + maj) | 0;
      hh = g; g = f; f = e; e = (d + t1) | 0; d = c; c = b; b = a; a = (t1 + t2) | 0;
    }
    h[0] = (h[0] + a) | 0; h[1] = (h[1] + b) | 0; h[2] = (h[2] + c) | 0; h[3] = (h[3] + d) | 0;
    h[4] = (h[4] + e) | 0; h[5] = (h[5] + f) | 0; h[6] = (h[6] + g) | 0; h[7] = (h[7] + hh) | 0;
  }

  /** A string as UTF-8 bytes. */
  function utf8(s) {
    var out = [];
    for (var i = 0; i < s.length; i++) {
      var c = s.charCodeAt(i);
      if (c >= 0xd800 && c < 0xdc00 && i + 1 < s.length) {
        var d = s.charCodeAt(i + 1);
        if (d >= 0xdc00 && d < 0xe000) {
          c = 0x10000 + ((c - 0xd800) << 10) + (d - 0xdc00);
          i++;
        }
      }
      if (c < 0x80) out.push(c);
      else if (c < 0x800) out.push(0xc0 | (c >> 6), 0x80 | (c & 63));
      else if (c < 0x10000) out.push(0xe0 | (c >> 12), 0x80 | ((c >> 6) & 63), 0x80 | (c & 63));
      else out.push(0xf0 | (c >> 18), 0x80 | ((c >> 12) & 63), 0x80 | ((c >> 6) & 63), 0x80 | (c & 63));
    }
    return new Uint8Array(out);
  }

  /** SHA-256 of a byte array, as eight 32-bit words. */
  function digestWords(bytes) {
    var h = new Int32Array(INIT);
    var w = new Int32Array(64);
    var n = bytes.length;
    var full = n >> 6;
    for (var i = 0; i < full; i++) block(h, w, bytes, i * 64);
    var rest = n - full * 64;
    var tail = new Uint8Array(rest + 9 > 64 ? 128 : 64);
    for (i = 0; i < rest; i++) tail[i] = bytes[full * 64 + i];
    tail[rest] = 0x80;
    var bits = n * 8;
    var end = tail.length;
    tail[end - 4] = bits >>> 24;
    tail[end - 3] = bits >>> 16;
    tail[end - 2] = bits >>> 8;
    tail[end - 1] = bits;
    tail[end - 5] = Math.floor(n / 0x20000000) & 255; // the high word, for inputs over 512 MB
    block(h, w, tail, 0);
    if (end === 128) block(h, w, tail, 64);
    return h;
  }

  /** SHA-256 of a string (as UTF-8), in lowercase hex. */
  function sha256Hex(text) {
    var h = digestWords(utf8(String(text)));
    var out = "";
    for (var i = 0; i < 8; i++) out += ("00000000" + (h[i] >>> 0).toString(16)).slice(-8);
    return out;
  }

  // ------------------------------------------------------------------ the puzzle

  /** True when the digest words start with at least `bits` zero bits. */
  function leadingZeros(h, bits) {
    var whole = bits >> 5;
    for (var i = 0; i < whole; i++) if (h[i] !== 0) return false;
    var rem = bits & 31;
    return rem === 0 || h[whole] >>> (32 - rem) === 0;
  }

  /** Returns search(from, count): the first nonce in [from, from + count) that solves the puzzle, or null. */
  function searcher(challenge, difficulty) {
    var prefix = utf8(challenge + ":");
    var full = prefix.length >> 6;
    var w = new Int32Array(64);
    var base = new Int32Array(INIT);
    for (var i = 0; i < full; i++) block(base, w, prefix, i * 64);
    var r = prefix.length - full * 64;
    var buf = new Uint8Array(128);
    for (i = 0; i < r; i++) buf[i] = prefix[full * 64 + i];
    var h = new Int32Array(8);
    return function (from, count) {
      for (var n = from; n < from + count; n++) {
        var s = String(n);
        var len = s.length;
        for (var k = 0; k < len; k++) buf[r + k] = s.charCodeAt(k);
        var total = r + len;
        buf[total] = 0x80;
        var end = total + 9 <= 64 ? 64 : 128;
        for (k = total + 1; k < end - 8; k++) buf[k] = 0;
        var bits = (prefix.length + len) * 8;
        buf[end - 8] = 0; buf[end - 7] = 0; buf[end - 6] = 0; buf[end - 5] = 0;
        buf[end - 4] = bits >>> 24; buf[end - 3] = bits >>> 16; buf[end - 2] = bits >>> 8; buf[end - 1] = bits;
        h.set(base);
        block(h, w, buf, 0);
        if (end === 128) block(h, w, buf, 64);
        if (leadingZeros(h, difficulty)) return s;
      }
      return null;
    };
  }

  function checkDifficulty(difficulty) {
    if (typeof difficulty !== "number" || difficulty < 0 || difficulty > 30 || Math.floor(difficulty) !== difficulty) {
      throw new Error("Unexpected puzzle");
    }
  }

  /** Finds a nonce in one go (tests, small difficulties). Pass `limit` to give up after that many tries. */
  function findNonce(challenge, difficulty, limit) {
    checkDifficulty(difficulty);
    var search = searcher(challenge, difficulty);
    var max = limit || 4294967296;
    for (var from = 0; from < max; from += 50000) {
      var hit = search(from, Math.min(50000, max - from));
      if (hit !== null) return hit;
    }
    return null;
  }

  /** Finds a nonce in chunks, letting the page breathe between them. Resolves with the nonce string. */
  function solve(challenge, difficulty, options) {
    var chunk = (options && options.chunk) || 20000;
    var wait = (options && options.wait) || root.setTimeout;
    return new Promise(function (resolve, reject) {
      var search;
      try {
        checkDifficulty(difficulty);
        search = searcher(challenge, difficulty);
      } catch (err) {
        reject(err);
        return;
      }
      var from = 0;
      (function step() {
        try {
          var hit = search(from, chunk);
          if (hit !== null) return resolve(hit);
          from += chunk;
          wait(step, 0);
        } catch (err) {
          reject(err);
        }
      })();
    });
  }

  root.CasamaWaitlist = { sha256Hex: sha256Hex, leadingZeros: leadingZeros, findNonce: findNonce, solve: solve, embeddedBrowser: embeddedBrowser };

  if (typeof document === "undefined") return;

  // ------------------------------------------------------------------ talking to the API

  var local = /^(localhost|127\.0\.0\.1|\[::1\])$/.test(location.hostname);
  var API = String(root.CASAMA_API || (local ? "http://localhost:8787" : "https://api.casama.ai")).replace(/\/+$/, "");
  var SIGN_IN = "https://app.casama.ai";
  var NETWORK = "Couldn't reach Casama. Try again in a moment.";
  var GENERIC = "Something went wrong. Try again in a moment.";
  var params = new URLSearchParams(location.search);

  /**
   * One funnel step through casama.ai's anonymous count (D-398), as site.js sends them; the Worker
   * keeps only names on its closed list. Never the address or a code.
   */
  function countEvent(name, data) {
    try {
      if (navigator.sendBeacon && !local) {
        navigator.sendBeacon("/b", JSON.stringify({ p: location.pathname, e: name, d: data || {} }));
      }
    } catch (e) { /* counting is never worth breaking the page for */ }
  }

  function fail(message, code, status) {
    var err = new Error(message);
    err.code = code;
    err.status = status;
    return err;
  }

  function call(method, path, body) {
    return fetch(API + path, {
      method: method,
      headers: { "content-type": "application/json", accept: "application/json" },
      body: body === undefined ? undefined : JSON.stringify(body),
    }).then(
      function (res) {
        return res.text().then(
          function (text) {
            var data = null;
            try { data = JSON.parse(text); } catch (e) { data = null; }
            if (res.ok) return data || {};
            throw fail((data && data.detail) || GENERIC, data && data.code, res.status);
          },
          function () { throw fail(NETWORK, "network"); }
        );
      },
      function () { throw fail(NETWORK, "network"); }
    );
  }

  function getProof() {
    return call("GET", "/v1/signup/challenge").then(function (c) {
      if (!c || typeof c.challenge !== "string") throw fail(GENERIC, "bad_challenge");
      return solve(c.challenge, c.difficulty).then(function (nonce) {
        return { challenge: c.challenge, nonce: nonce };
      });
    });
  }

  // A proof is good once. Solving starts when someone first clicks into a form, so it is often done
  // by the time they press the button.
  var warmed = null;
  function warm() {
    if (warmed) return;
    warmed = getProof();
    warmed.catch(function () { warmed = null; });
  }
  function takeProof(fresh) {
    var ready = warmed;
    warmed = null;
    return !fresh && ready ? ready.catch(getProof) : getProof();
  }

  /** POST with a solved puzzle; a rejected proof is replaced and tried once more. */
  function postWithProof(path, payload) {
    function attempt(retry) {
      return takeProof(retry).then(function (proof) {
        var body = {};
        for (var k in payload) body[k] = payload[k];
        body.proof = proof;
        return call("POST", path, body).catch(function (err) {
          if (err.code === "proof_required" && !retry) return attempt(true);
          throw err;
        });
      });
    }
    return attempt(false);
  }

  // ------------------------------------------------------------------ the page

  function clip(value, max) {
    return String(value || "").trim().slice(0, max);
  }
  function sourceFor(el) {
    return clip(params.get("from") || el.getAttribute("data-source") || "waitlist", 64);
  }
  function refValue() {
    return clip(params.get("ref") || params.get("utm_campaign"), 64);
  }
  function say(el, text, bad) {
    if (!el) return;
    el.textContent = text;
    el.className = el.className.replace(/\s*\bis-bad\b/, "") + (bad ? " is-bad" : "");
  }
  function busy(form, on) {
    var btn = form.querySelector("button[type=submit]");
    if (btn) btn.disabled = on;
    form._busy = on;
  }

  function node(tag, className, text) {
    var el = document.createElement(tag);
    if (className) el.className = className;
    if (text !== undefined) el.textContent = text;
    return el;
  }
  function link(href, text, className) {
    var a = node("a", className, text);
    a.href = href;
    return a;
  }

  /**
   * The app whose built-in browser this is (a link tapped inside Instagram, Facebook, Threads, TikTok,
   * X, LinkedIn, Snapchat or Line), or "" in a real browser. Pure, for tests.
   */
  function embeddedBrowser(ua) {
    ua = String(ua || "");
    if (/Barcelona/i.test(ua)) return "Threads";
    if (/Instagram/i.test(ua)) return "Instagram";
    if (/FBAN|FBAV|FB_IAB|FBIOS/i.test(ua)) return "Facebook";
    if (/musical_ly|BytedanceWebview|TikTok/i.test(ua)) return "TikTok";
    if (/Twitter/i.test(ua)) return "X";
    if (/LinkedInApp/i.test(ua)) return "LinkedIn";
    if (/Snapchat/i.test(ua)) return "Snapchat";
    if (/\bLine\//i.test(ua)) return "Line";
    return "";
  }

  /** A button that copies `text`, and says so. Falls back to showing the text to copy by hand. */
  function copyButton(text, label) {
    var btn = node("button", "btn", label);
    btn.type = "button";
    btn.addEventListener("click", function () {
      function done() { btn.textContent = "Copied"; }
      function byHand() { btn.textContent = text.replace(/^https:\/\//, ""); }
      try {
        if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(text).then(done, byHand);
        else byHand();
      } catch (e) { byHand(); }
    });
    return btn;
  }

  /** What a redeemed code says (docs/WAITLIST-PLAN.md §12). Everything typed by a person goes in as text. */
  function showRedeemed(target, outcome, email) {
    target.textContent = "";
    if (outcome === "admitted") {
      var p = node("p", "wl-lead");
      p.appendChild(node("strong", "", "You're in."));
      p.appendChild(document.createTextNode(" Sign in with " + email + ": Google, Apple and the email link all work, as long as it's this address."));
      target.appendChild(p);
      var row = node("div", "wl-actions");
      var inside = embeddedBrowser(navigator.userAgent);
      if (inside) {
        // Google's sign-in refuses to run inside another app's browser, and the web app is heavy
        // there. The apps come first, and the address to open in a real browser can be copied.
        target.appendChild(node("p", "wl-note", "You're in " + inside + "'s browser, where Google sign-in doesn't work. Get the app, or open app.casama.ai in Safari or Chrome."));
        row.appendChild(link("/download", "Get the apps", "btn primary"));
        row.appendChild(copyButton(SIGN_IN, "Copy app.casama.ai"));
      } else {
        row.appendChild(link(SIGN_IN, "Open Casama", "btn primary"));
        row.appendChild(link("/download", "Get the apps", "btn"));
      }
      target.appendChild(row);
    } else {
      target.appendChild(node("p", "wl-lead", "That invite has been used up. You're on the waitlist, near the front."));
    }
    target.hidden = false;
  }

  /**
   * Wires a join form. `body(f, email)` adds the form's own fields to the request; `done()` runs after
   * the join. The full /waitlist form and the small inline forms share this: one solver, one POST.
   */
  function wireJoin(form, body, done) {
    var status = form.querySelector("[data-wl-status]");
    form.addEventListener("focusin", warm, { once: true });
    form.addEventListener("submit", function (e) {
      e.preventDefault();
      if (form._busy) return;
      var email = clip(form.elements.email.value, 254);
      if (!email) return;
      var payload = { email: email, source: sourceFor(form) };
      var ref = refValue();
      if (ref) payload.ref = ref;
      body(form.elements, payload);
      busy(form, true);
      say(status, "One moment…", false);
      postWithProof("/v1/waitlist", payload).then(
        function () { done(form); },
        function (err) {
          say(status, err.message || GENERIC, true);
          busy(form, false);
        }
      );
    });
  }

  function bindJoin(form) {
    var joined = document.querySelector("[data-wl-joined]");
    form.hidden = false;
    var prefill = clip(params.get("email"), 254); // from the small forms' no-JavaScript fallback
    if (prefill && form.elements.email && !form.elements.email.value) form.elements.email.value = prefill;
    wireJoin(
      form,
      function (f, payload) {
        payload.newsletter = !!f.newsletter.checked;
        payload.self_hosting = !!f.self_hosting.checked;
        var note = clip(f.note.value, 280);
        if (note) payload.note = note;
      },
      function () {
        countEvent("waitlist_join", { form: "page" });
        form.hidden = true;
        if (joined) {
          joined.hidden = false;
          joined.setAttribute("tabindex", "-1");
          joined.focus();
        }
      }
    );
  }

  // waitlist copy: docs/WAITLIST-PLAN.md §12 (the /waitlist page's joined message, less the newsletter clause: these forms don't ask)
  var JOINED = "You're on the list. We're letting people in every day. You'll get one email when it's your turn, and nothing else.";

  /** The small email-only form (home page, blog posts, changelog, download). Joining swaps it for the joined message. */
  function bindInline(form) {
    wireJoin(
      form,
      function (f, payload) {
        payload.newsletter = false;
        payload.self_hosting = false;
      },
      function () {
        countEvent("waitlist_join", { form: "inline" });
        var msg = node("p", "wl-inline-done");
        msg.setAttribute("role", "status");
        msg.setAttribute("tabindex", "-1");
        var strong = node("strong", "", "You're on the list.");
        msg.appendChild(strong);
        msg.appendChild(document.createTextNode(JOINED.slice("You're on the list.".length)));
        form.parentNode.replaceChild(msg, form);
        msg.focus();
      }
    );
  }

  function bindRedeem(form) {
    var status = form.querySelector("[data-wl-status]");
    var result = (form.parentNode && form.parentNode.querySelector("[data-wl-result]")) || document.querySelector("[data-wl-result]");
    var fixed = form.getAttribute("data-code");
    form.hidden = false;
    form.addEventListener("focusin", warm, { once: true });
    form.addEventListener("submit", function (e) {
      e.preventDefault();
      if (form._busy) return;
      var f = form.elements;
      var email = clip(f.email.value, 254);
      // A code or the whole invite link: the server reads either, however it is written.
      var code = clip(fixed || f.code.value, 200);
      if (!email || !code) return;
      busy(form, true);
      say(status, "One moment…", false);
      var payload = { email: email, code: code, source: sourceFor(form) };
      if (f.newsletter && f.newsletter.checked) payload.newsletter = true;
      postWithProof("/v1/waitlist/redeem", payload).then(
        function (res) {
          form.hidden = true;
          if (result) showRedeemed(result, res && res.outcome, email);
        },
        function (err) {
          say(status, err.message || GENERIC, true);
          busy(form, false);
        }
      );
    });
  }

  // /waitlist/leave?t=<token>: the link in the email only asks. Nothing is removed until the button is pressed.
  function bindLeave(box) {
    var ask = box.querySelector("[data-wl-leave-ask]");
    var done = box.querySelector("[data-wl-leave-done]");
    var bad = box.querySelector("[data-wl-leave-bad]");
    var button = box.querySelector("[data-wl-leave-button]");
    var status = box.querySelector("[data-wl-status]");
    var token = params.get("t") || "";
    function show(which) {
      ask.hidden = which !== ask;
      done.hidden = which !== done;
      bad.hidden = which !== bad;
    }
    if (!token) return show(bad);
    show(ask);
    button.addEventListener("click", function () {
      if (button.disabled) return;
      button.disabled = true;
      say(status, "One moment…", false);
      call("POST", "/v1/waitlist/leave", { token: token }).then(
        function () { show(done); },
        function (err) {
          if (err.code === "bad_token") return show(bad);
          say(status, err.message || GENERIC, true);
          button.disabled = false;
        }
      );
    });
  }

  function init() {
    if (document.querySelector("form[data-wl-join]")) countEvent("waitlist_view");
    Array.prototype.forEach.call(document.querySelectorAll("form[data-wl-join]"), bindJoin);
    Array.prototype.forEach.call(document.querySelectorAll("form[data-wl-inline]"), bindInline);
    Array.prototype.forEach.call(document.querySelectorAll("form[data-wl-redeem]"), bindRedeem);
    Array.prototype.forEach.call(document.querySelectorAll("[data-wl-leave]"), bindLeave);
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})(typeof window !== "undefined" ? window : this);
