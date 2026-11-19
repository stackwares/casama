/* Casama Help: the website's support chat, answering from Casama's docs. Loaded by loader.js on the
   first click (or straight away where a page holds it inline). No framework and no chat service:
   it talks to Casama's API only (GET /v1/support/web/config, POST /v1/support/web/session after a
   Cloudflare Turnstile check, POST /v1/support/web/chat).

   The conversation lives in sessionStorage only. Answers are plain text with a small, escaped
   markdown subset: paragraphs, **bold**, lists, `code` and http(s) links. */
(function () {
  "use strict";

  var MAX_CHARS = 1000;
  var MAX_SENT = 8; // messages sent to the API with each question
  var MAX_KEPT = 40; // messages kept in sessionStorage
  var CHAT_KEY = "casama-help-chat";
  var SESSION_KEY = "casama-help-session";
  var EMAIL = "support@casama.ai";
  var DOCS = "https://docs.casama.ai";
  var HELP_URL = "https://casama.ai/help";

  var api = "https://api.casama.ai";
  var surface = "site";
  var configPromise = null;
  var config = null;
  var messages = load(CHAT_KEY) || [];
  var busy = false;
  var ui = null; // the one chat on the page: { root, log, form, input, send, counter, live, mode, opener }
  var turnstile = { id: null, waiting: null };

  // ---------------------------------------------------------------- storage

  function load(key) {
    try {
      var raw = sessionStorage.getItem(key);
      return raw ? JSON.parse(raw) : null;
    } catch (e) {
      return null;
    }
  }
  function save(key, value) {
    try {
      if (value == null) sessionStorage.removeItem(key);
      else sessionStorage.setItem(key, JSON.stringify(value));
    } catch (e) { /* private windows: the chat still works for this page */ }
  }
  function saveChat() { save(CHAT_KEY, messages.slice(-MAX_KEPT)); }

  // ---------------------------------------------------------------- the API

  function request(method, path, body, timeoutMs) {
    var ctrl = "AbortController" in window ? new AbortController() : null;
    var timer = ctrl ? setTimeout(function () { ctrl.abort(); }, timeoutMs || 20000) : 0;
    var init = { method: method, credentials: "omit", headers: { "content-type": "application/json" } };
    if (body !== undefined) init.body = JSON.stringify(body);
    if (ctrl) init.signal = ctrl.signal;
    return fetch(api + path, init).then(function (res) {
      clearTimeout(timer);
      return res.text().then(function (text) {
        var data = null;
        try { data = text ? JSON.parse(text) : null; } catch (e) { data = null; }
        if (!res.ok) {
          var err = new Error((data && data.error) || "Request failed");
          err.status = res.status;
          err.code = data && data.code;
          err.apiMessage = data && typeof data.error === "string" ? data.error : "";
          throw err;
        }
        return data || {};
      });
    }, function (e) {
      clearTimeout(timer);
      var err = new Error("network");
      err.status = 0;
      err.cause = e;
      throw err;
    });
  }

  function getConfig() {
    if (!configPromise) {
      configPromise = request("GET", "/v1/support/web/config", undefined, 8000).then(function (c) {
        config = c;
        return c;
      }, function () {
        config = { assistant: false, turnstile_site_key: null, email: EMAIL, docs_url: DOCS, failed: true };
        configPromise = null; // try again next time the chat opens
        return config;
      });
    }
    return configPromise;
  }

  function validSession() {
    var s = load(SESSION_KEY);
    if (!s || !s.session) return null;
    var t = Date.parse(s.expires_at);
    if (t && t - Date.now() < 30000) return null;
    return s.session;
  }

  function newSession() {
    return turnstileToken().then(function (token) {
      return request("POST", "/v1/support/web/session", { turnstile_token: token || "" }, 20000);
    }).then(function (s) {
      if (!s || !s.session) throw Object.assign(new Error("no session"), { status: 0 });
      save(SESSION_KEY, { session: s.session, expires_at: s.expires_at || "" });
      return s.session;
    });
  }

  function session() {
    var s = validSession();
    return s ? Promise.resolve(s) : newSession();
  }

  // ---------------------------------------------------------------- Turnstile

  function loadTurnstile() {
    if (window.turnstile) return Promise.resolve(window.turnstile);
    if (loadTurnstile.p) return loadTurnstile.p;
    loadTurnstile.p = new Promise(function (resolve, reject) {
      var s = document.createElement("script");
      s.src = "https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit";
      s.async = true;
      s.onload = function () { window.turnstile ? resolve(window.turnstile) : reject(new Error("turnstile")); };
      s.onerror = function () { loadTurnstile.p = null; reject(new Error("turnstile")); };
      document.head.appendChild(s);
    });
    return loadTurnstile.p;
  }

  function turnstileToken() {
    var key = config && config.turnstile_site_key;
    if (!key) return Promise.resolve("");
    return loadTurnstile().then(function (ts) {
      return new Promise(function (resolve, reject) {
        var done = setTimeout(function () { reject(Object.assign(new Error("turnstile timeout"), { status: 0 })); }, 90000);
        turnstile.waiting = {
          resolve: function (t) { clearTimeout(done); resolve(t); },
          reject: function (e) { clearTimeout(done); reject(e); }
        };
        var holder = ui && ui.root.querySelector(".cmh-check");
        if (turnstile.id == null || !holder || !holder.firstChild) {
          if (holder) holder.textContent = "";
          turnstile.id = ts.render(holder || document.body, {
            sitekey: key,
            execution: "execute",
            appearance: "interaction-only",
            callback: function (t) { if (turnstile.waiting) turnstile.waiting.resolve(t); turnstile.waiting = null; },
            "error-callback": function () { if (turnstile.waiting) turnstile.waiting.reject(Object.assign(new Error("turnstile"), { status: 0 })); turnstile.waiting = null; },
            "expired-callback": function () { /* a new one is asked for when needed */ }
          });
        } else {
          ts.reset(turnstile.id);
        }
        ts.execute(turnstile.id);
      });
    });
  }

  // ---------------------------------------------------------------- markdown (escaped, small)

  function esc(s) {
    return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#39;");
  }

  function safeUrl(url) {
    var u = url.replace(/&amp;/g, "&");
    if (/^\/(?!\/)/.test(u)) u = DOCS + u;
    return /^https?:\/\/[^\s]+$/i.test(u) ? esc(u) : null;
  }

  function link(url, label) {
    return '<a href="' + url + '" target="_blank" rel="noopener noreferrer">' + label + "</a>";
  }

  /** Inline markdown on escaped text: `code`, [label](url), bare https links, **bold**. */
  function inline(text) {
    var keep = [];
    var hold = function (html) { keep.push(html); return "\u0000" + (keep.length - 1) + "\u0000"; };
    var out = esc(text)
      .replace(/`([^`\n]+)`/g, function (_m, code) { return hold("<code>" + code + "</code>"); })
      .replace(/\[([^\]\n]+)\]\(([^)\s]+)\)/g, function (m, label, url) {
        var safe = safeUrl(url);
        return safe ? hold(link(safe, label)) : label;
      })
      .replace(/https?:\/\/[^\s<\u0000]+/g, function (m) {
        var trail = m.match(/[.,;:!?)\]]+$/);
        var url = trail ? m.slice(0, -trail[0].length) : m;
        var safe = safeUrl(url);
        return (safe ? hold(link(safe, url)) : url) + (trail ? trail[0] : "");
      })
      .replace(/\*\*([^*\n]+)\*\*/g, "<strong>$1</strong>");
    return out.replace(/\u0000(\d+)\u0000/g, function (_m, i) { return keep[Number(i)]; });
  }

  function markdown(source) {
    var lines = String(source).replace(/\r/g, "").split("\n");
    var html = [];
    var para = [];
    var list = null;
    function flushPara() { if (para.length) { html.push("<p>" + inline(para.join(" ")) + "</p>"); para = []; } }
    function flushList() { if (list) { html.push("<" + list.tag + ">" + list.items.map(function (t) { return "<li>" + inline(t) + "</li>"; }).join("") + "</" + list.tag + ">"); list = null; } }
    lines.forEach(function (line) {
      var m = line.match(/^\s*([-*•]|\d{1,3}[.)])\s+(.*)$/);
      if (m) {
        flushPara();
        var tag = /\d/.test(m[1]) ? "ol" : "ul";
        if (list && list.tag !== tag) flushList();
        if (!list) list = { tag: tag, items: [] };
        list.items.push(m[2]);
      } else if (!line.trim()) {
        flushPara();
        flushList();
      } else if (list && /^\s+\S/.test(line)) {
        list.items[list.items.length - 1] += " " + line.trim();
      } else {
        flushList();
        para.push(line.trim().replace(/^#{1,6}\s+/, ""));
      }
    });
    flushPara();
    flushList();
    return html.join("");
  }

  // ---------------------------------------------------------------- the view

  function el(tag, cls, html) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (html != null) e.innerHTML = html;
    return e;
  }

  function starters() {
    var path = location.pathname;
    var docs = surface === "docs";
    if (/^\/pricing/.test(path) || (docs && /^\/guide\/usage/.test(path))) {
      return ["What do credits pay for?", "How do I cancel?", "Is there a free trial?"];
    }
    if (/^\/self-host/.test(path) || (docs && /^\/(self-hosting|guide\/casama-link)/.test(path))) {
      return ["What do I need to self-host?", "Can I use my own models or local models?", "How do I reach my server from my phone?"];
    }
    if (docs && /^\/develop/.test(path)) {
      return ["How do I call the Casama API?", "How do I write a plugin?", "Can my coding agent build on Casama?"];
    }
    return ["What can a Casama bot do?", "Is Casama free?", "Is my data used to train AI?"];
  }

  function helpLinks() {
    return '<p class="cmh-help-links">' + link(HELP_URL, "Search the FAQ") + ' · <a href="mailto:' + EMAIL + '">Email ' + EMAIL + "</a></p>";
  }

  function build(mode) {
    var root = el("div", "cmh cmh-" + mode);
    root.setAttribute("data-surface", surface);
    var titleId = "cmh-title-" + Math.random().toString(36).slice(2, 8);
    if (mode === "panel") {
      root.setAttribute("role", "dialog");
      root.setAttribute("aria-modal", "true");
      root.setAttribute("aria-labelledby", titleId);
    } else {
      root.setAttribute("role", "region");
      root.setAttribute("aria-labelledby", titleId);
    }
    root.innerHTML =
      '<div class="cmh-head"><h2 class="cmh-title" id="' + titleId + '">Casama Help <span>· answers from our docs</span></h2>' +
      (mode === "panel" ? '<button type="button" class="cmh-close" aria-label="Close Casama Help"><svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/></svg></button>' : "") +
      "</div>" +
      '<div class="cmh-log" tabindex="-1"></div>' +
      '<div class="cmh-live visually-hidden cmh-sr" aria-live="polite" aria-atomic="true"></div>' +
      '<div class="cmh-check"></div>' +
      '<form class="cmh-form" novalidate hidden>' +
      '<label class="cmh-sr" for="' + titleId + '-in">Your question</label>' +
      '<textarea id="' + titleId + '-in" class="cmh-input" rows="1" maxlength="' + MAX_CHARS + '" placeholder="Ask a question" autocomplete="off"></textarea>' +
      '<span class="cmh-count" aria-live="polite" hidden></span>' +
      '<button type="submit" class="cmh-send" aria-label="Send"><svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><path d="M12 19V5M5 12l7-7 7 7" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg></button>' +
      "</form>" +
      '<div class="cmh-foot"><a href="mailto:' + EMAIL + '">Email a person</a><span>Account help: open <strong>Help &amp; support</strong> in the app</span></div>';
    var view = {
      root: root,
      mode: mode,
      log: root.querySelector(".cmh-log"),
      live: root.querySelector(".cmh-live"),
      form: root.querySelector(".cmh-form"),
      input: root.querySelector(".cmh-input"),
      send: root.querySelector(".cmh-send"),
      counter: root.querySelector(".cmh-count"),
      opener: null
    };
    view.form.addEventListener("submit", function (e) {
      e.preventDefault();
      ask(view.input.value);
    });
    view.input.addEventListener("keydown", function (e) {
      if (e.key === "Enter" && !e.shiftKey && !e.isComposing) {
        e.preventDefault();
        ask(view.input.value);
      }
    });
    view.input.addEventListener("input", function () {
      grow(view.input);
      updateCounter(view);
    });
    var close = root.querySelector(".cmh-close");
    if (close) close.addEventListener("click", closePanel);
    if (mode === "panel") root.addEventListener("keydown", trapKeys);
    return view;
  }

  function grow(input) {
    input.style.height = "auto";
    input.style.height = Math.min(input.scrollHeight, 160) + "px";
  }

  function updateCounter(view) {
    var n = view.input.value.length;
    view.counter.hidden = n < MAX_CHARS - 200;
    view.counter.textContent = n + "/" + MAX_CHARS;
    view.counter.classList.toggle("cmh-count-full", n >= MAX_CHARS);
    view.send.disabled = busy || !view.input.value.trim();
  }

  function render() {
    if (!ui) return;
    var log = ui.log;
    log.textContent = "";
    if (!config) {
      log.appendChild(el("p", "cmh-note", "One moment…"));
      return;
    }
    if (!config.assistant) {
      ui.form.hidden = true;
      var off = el("div", "cmh-off");
      off.innerHTML =
        "<p>" + (config.failed ? "Casama Help can't be reached right now." : "Casama Help isn't answering questions right now.") + "</p>" +
        "<p>Most questions have an answer on the help page, and a person reads every email.</p>" +
        helpLinks();
      log.appendChild(off);
      return;
    }
    ui.form.hidden = false;
    if (!messages.length) {
      var empty = el("div", "cmh-empty");
      empty.appendChild(el("p", "cmh-note", "Ask anything about Casama. Answers come from our docs, with links to the pages."));
      var list = el("div", "cmh-starters");
      starters().forEach(function (q) {
        var b = el("button", "cmh-starter");
        b.type = "button";
        b.textContent = q;
        b.addEventListener("click", function () { ask(q); });
        list.appendChild(b);
      });
      empty.appendChild(list);
      log.appendChild(empty);
    }
    messages.forEach(function (m) { log.appendChild(bubble(m)); });
    if (busy) {
      var wait = el("div", "cmh-msg cmh-bot cmh-wait");
      wait.innerHTML = '<span class="cmh-sr">Casama Help is writing</span><span class="cmh-dots" aria-hidden="true"><i></i><i></i><i></i></span>';
      log.appendChild(wait);
    }
    log.scrollTop = log.scrollHeight;
    updateCounter(ui);
  }

  function bubble(m) {
    if (m.role === "user") {
      var u = el("div", "cmh-msg cmh-you");
      u.textContent = m.content;
      return u;
    }
    if (m.role === "error") {
      return el("div", "cmh-msg cmh-bot cmh-error", "<p>" + esc(m.content) + "</p>" + helpLinks());
    }
    var b = el("div", "cmh-msg cmh-bot", markdown(m.content));
    var sources = (m.sources || []).filter(function (s) { return s && typeof s.url === "string" && safeUrl(s.url); });
    if (sources.length) {
      var box = el("div", "cmh-sources");
      box.appendChild(el("p", "cmh-sources-title", "Sources"));
      var ul = el("ul");
      sources.slice(0, 6).forEach(function (s) {
        var li = el("li");
        li.innerHTML = link(safeUrl(s.url), esc(s.title || s.url));
        ul.appendChild(li);
      });
      box.appendChild(ul);
      b.appendChild(box);
    }
    return b;
  }

  function announce(text) {
    if (!ui) return;
    ui.live.textContent = "";
    setTimeout(function () { if (ui) ui.live.textContent = text; }, 60);
  }

  // ---------------------------------------------------------------- asking

  function history() {
    var turns = messages.filter(function (m) { return m.role === "user" || m.role === "assistant"; }).slice(-MAX_SENT);
    while (turns.length && turns[0].role !== "user") turns.shift();
    return turns.map(function (m) { return { role: m.role, content: String(m.content).slice(0, 4000) }; });
  }

  function calmMessage(err) {
    if (err.apiMessage && (err.status === 429 || err.status === 503 || err.status === 403)) return err.apiMessage;
    if (err.status === 429) return "Lots of questions right now. Please try again in a little while.";
    if (err.status === 403) return "Casama Help isn't answering questions right now.";
    if (err.status === 503) return "Casama Help is unavailable for a moment. Please try again soon.";
    if (err.apiMessage) return err.apiMessage;
    return "Casama Help couldn't be reached. Please try again in a moment.";
  }

  function ask(raw) {
    var text = String(raw || "").trim().slice(0, MAX_CHARS);
    if (!text || busy || !ui) return;
    busy = true;
    messages.push({ role: "user", content: text });
    saveChat();
    ui.input.value = "";
    grow(ui.input);
    render();

    var retried = false;
    var send = function () {
      return session().then(function (s) {
        return request("POST", "/v1/support/web/chat", { session: s, messages: history(), page: location.pathname.slice(0, 200) }, 90000);
      }).catch(function (err) {
        if (err.status === 401 && !retried) {
          retried = true;
          save(SESSION_KEY, null);
          return send();
        }
        throw err;
      });
    };

    getConfig().then(send).then(function (res) {
      var reply = typeof res.reply === "string" && res.reply.trim() ? res.reply : "I couldn't find an answer to that in our docs.";
      messages.push({ role: "assistant", content: reply, sources: Array.isArray(res.sources) ? res.sources : [] });
      announce("Casama Help answered: " + reply.slice(0, 400));
    }, function (err) {
      if (err.status === 403 && err.code === "assistant_off" && config) config.assistant = false;
      var msg = calmMessage(err);
      messages.push({ role: "error", content: msg });
      announce(msg);
    }).then(function () {
      busy = false;
      saveChat();
      render();
      if (ui && ui.mode === "panel" && document.activeElement === document.body) ui.input.focus();
    });
  }

  // ---------------------------------------------------------------- the panel

  var panelOpen = false;

  /* Phones: the panel fills the screen, but an open keyboard only shrinks the visual viewport
     (Chrome on Android and Safari on iOS), and focusing the box pans the page up, which pushed the
     header and the conversation off the top. While the panel is open on a phone, pin it to the
     visual viewport so it always sits between the top of the screen and the keyboard. */
  var phone = window.matchMedia("(max-width: 639px)");
  var fitting = false;

  function fitPanel() {
    if (!ui || ui.mode !== "panel" || !panelOpen) return;
    var vv = window.visualViewport;
    var s = ui.root.style;
    if (!vv || !phone.matches) {
      s.top = s.height = s.bottom = "";
      return;
    }
    var log = ui.log;
    var atEnd = log.scrollHeight - log.scrollTop - log.clientHeight < 40;
    s.top = Math.max(0, vv.offsetTop) + "px";
    s.height = vv.height + "px";
    s.bottom = "auto";
    if (atEnd) log.scrollTop = log.scrollHeight;
  }

  function startFitting() {
    if (fitting || !window.visualViewport) return;
    fitting = true;
    window.visualViewport.addEventListener("resize", fitPanel);
    window.visualViewport.addEventListener("scroll", fitPanel);
    fitPanel();
  }

  function stopFitting() {
    if (!fitting) return;
    fitting = false;
    window.visualViewport.removeEventListener("resize", fitPanel);
    window.visualViewport.removeEventListener("scroll", fitPanel);
    if (ui) ui.root.style.top = ui.root.style.height = ui.root.style.bottom = "";
  }

  function focusables(root) {
    return Array.prototype.filter.call(
      root.querySelectorAll('a[href], button:not([disabled]), textarea:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex="-1"])'),
      function (e) { return e.offsetParent !== null || e === document.activeElement; }
    );
  }

  function trapKeys(e) {
    if (e.key === "Escape") {
      e.stopPropagation();
      closePanel();
      return;
    }
    if (e.key !== "Tab") return;
    var list = focusables(ui.root);
    if (!list.length) return;
    var first = list[0];
    var last = list[list.length - 1];
    if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
    else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
  }

  function closePanel() {
    if (!ui || ui.mode !== "panel" || !panelOpen) return;
    panelOpen = false;
    ui.root.hidden = true;
    stopFitting();
    document.documentElement.classList.remove("cmh-locked");
    try { window.dispatchEvent(new CustomEvent("casama-help-panel", { detail: { open: false } })); } catch (e) { /* fine */ }
    var back = ui.opener;
    if (back && typeof back.focus === "function" && document.contains(back)) back.focus();
  }

  function open(options) {
    api = options.api || api;
    surface = options.surface || surface;
    if (options.inline) {
      if (!ui || ui.mode !== "inline") {
        if (ui && ui.mode === "panel") ui.root.remove();
        ui = build("inline");
        options.inline.textContent = "";
        options.inline.appendChild(ui.root);
      }
    } else {
      if (!ui) {
        ui = build("panel");
        document.body.appendChild(ui.root);
      }
      if (ui.mode === "panel") {
        ui.opener = options.opener && options.opener !== document.body ? options.opener : ui.opener;
        ui.root.hidden = false;
        panelOpen = true;
        if (phone.matches) document.documentElement.classList.add("cmh-locked");
        startFitting();
        try { window.dispatchEvent(new CustomEvent("casama-help-panel", { detail: { open: true } })); } catch (e) { /* fine */ }
      }
    }
    render();
    getConfig().then(function () {
      render();
      if (ui.mode === "panel" && panelOpen) {
        (ui.form.hidden ? (ui.root.querySelector(".cmh-close") || ui.log) : ui.input).focus();
      }
      if (options.text && config.assistant) ask(options.text);
      else if (options.text) render();
    });
    if (ui.mode === "panel") (ui.root.querySelector(".cmh-close") || ui.log).focus();
  }

  window.__casamaHelpWidget = { open: open };
})();
