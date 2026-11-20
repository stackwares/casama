// The web app's loading screen: what happens between the page opening and Flutter's first frame.
//
// A plain script (no inline code: the self-host image's CSP allows scripts from 'self' only), run
// before flutter_bootstrap.js. It shows:
//   - real download progress: the app's large files are counted byte by byte as they arrive,
//     against sizes scripts/build-web.sh writes into flutter_bootstrap.js (casamaBoot.files);
//   - named steps for what can't be measured (compiling, starting the engine);
//   - honest trouble: slow connection, offline, no progress for a long time, or a real failure,
//     with a Reload button and a short code for support.
// Nothing is shown on a fast load. Without the sizes file (flutter run, a hand-made build) the bar
// moves without a percentage. Flutter's own StartupGate takes over at the first frame.
(function () {
  'use strict';

  // Links to a screen (…/settings/billing, …/open/join/…, D-326) open it. The app reads its route
  // from the part after #, so a path is moved there before the app starts.
  (function () {
    var base = new URL(document.baseURI).pathname;
    var l = window.location;
    if (l.hash || l.pathname.indexOf(base) !== 0) return;
    var route = l.pathname.slice(base.length);
    if (!route || route === 'index.html') return;
    history.replaceState(null, '', base + '#/' + route + l.search);
  })();

  var SHOW_AFTER_MS = 800; // a quicker load never shows the bar
  var SLOW_AFTER_MS = 15000; // still downloading after this long: say the connection is slow
  var QUIET_AFTER_MS = 10000; // no progress for this long: say so
  var STUCK_AFTER_MS = 30000; // no progress for this long: offer Reload (loading keeps going)
  var RETRIES = [1000, 3000]; // waits before trying a failed download again
  var BUST_KEY = 'casama-boot-nocache';

  // The files Flutter picks between. One of each group loads; sizes come from the build.
  var GROUPS = {
    app: {
      wasm: ['main.dart.mjs', 'main.dart.wasm'],
      js: ['main.dart.js'],
    },
    renderer: {
      skwasm: ['canvaskit/skwasm.js', 'canvaskit/skwasm.wasm'],
      skwasm_heavy: ['canvaskit/skwasm_heavy.js', 'canvaskit/skwasm_heavy.wasm'],
      canvaskit_chromium: ['canvaskit/chromium/canvaskit.js', 'canvaskit/chromium/canvaskit.wasm'],
      canvaskit: ['canvaskit/canvaskit.js', 'canvaskit/canvaskit.wasm'],
    },
  };
  // A failure in one of these means the app can't start. A missing font only looks wrong.
  var CORE = {};
  Object.keys(GROUPS).forEach(function (g) {
    Object.keys(GROUPS[g]).forEach(function (v) {
      GROUPS[g][v].forEach(function (f) { CORE[f] = g + ':' + v; });
    });
  });

  var start = now();
  var state = {
    sizes: null, // path -> bytes, from the build
    always: [], // paths every start loads (fonts, font manifest)
    got: {}, // path -> bytes received so far
    done: {}, // path -> true once complete
    streamed: {}, // path -> true when counted through fetch
    variant: { app: null, renderer: null },
    step: 'download', // download, engine, app
    lastProgress: start,
    shown: false,
    finished: false,
    failed: null,
    lastError: null,
    shownPct: 0,
  };
  var bust = false;
  try {
    bust = sessionStorage.getItem(BUST_KEY) === '1';
    if (bust) sessionStorage.removeItem(BUST_KEY);
  } catch (_) {}

  function now() { return (window.performance && performance.now) ? performance.now() : Date.now(); }
  function $(id) { return document.getElementById(id); }

  // ---- Which file is this? -------------------------------------------------------------------

  var basePath = new URL(document.baseURI).pathname;
  function keyOf(url) {
    if (!url) return null;
    var u;
    try { u = new URL(String(url), document.baseURI); } catch (_) { return null; }
    if (u.origin !== location.origin || u.pathname.indexOf(basePath) !== 0) return null;
    var rel;
    try { rel = decodeURIComponent(u.pathname.slice(basePath.length)); } catch (_) { return null; }
    if (CORE[rel] || (state.sizes && state.sizes[rel] != null)) return rel;
    return null;
  }

  function noteVariant(key) {
    var tag = CORE[key];
    if (!tag) return;
    var parts = tag.split(':');
    if (!state.variant[parts[0]]) state.variant[parts[0]] = parts[1];
  }

  // What Flutter will most likely pick before it has asked for anything (flutter_js's own checks).
  function guessRenderer(app) {
    var blink = navigator.vendor === 'Google Inc.' || navigator.userAgent.indexOf('Edg/') >= 0;
    var codecs = typeof window.ImageDecoder !== 'undefined' && blink;
    var breaks = typeof Intl !== 'undefined' && typeof Intl.v8BreakIterator !== 'undefined' &&
      typeof Intl.Segmenter !== 'undefined';
    var light = codecs && breaks;
    if (app === 'js') return light ? 'canvaskit_chromium' : 'canvaskit';
    return light ? 'skwasm' : 'skwasm_heavy';
  }

  function expectedFiles() {
    var app = state.variant.app || 'wasm';
    var renderer = state.variant.renderer || guessRenderer(app);
    return GROUPS.app[app].concat(GROUPS.renderer[renderer], state.always);
  }

  // 0..1, or null when it can't be measured (no sizes, or the JavaScript build's main script,
  // which loads through a script tag and reports nothing until it's done).
  function fraction() {
    if (!state.sizes) return null;
    if (state.variant.app === 'js' && !state.done['main.dart.js']) return null;
    var total = 0, got = 0;
    expectedFiles().forEach(function (f) {
      var size = state.sizes[f] || 0;
      total += size;
      got += state.done[f] ? size : Math.min(state.got[f] || 0, size);
    });
    return total > 0 ? got / total : null;
  }

  // ---- Counting bytes ------------------------------------------------------------------------

  function progressed() { state.lastProgress = now(); schedule(); }

  function received(key, bytes) {
    state.got[key] = (state.got[key] || 0) + bytes;
    progressed();
  }

  function complete(key) {
    if (state.done[key]) return;
    state.done[key] = true;
    progressed();
  }

  var origFetch = window.fetch;
  function sleep(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }
  function whenOnline() {
    if (navigator.onLine !== false) return Promise.resolve();
    return new Promise(function (r) { window.addEventListener('online', function () { r(); }, { once: true }); });
  }

  // Fetches one of the app's files, trying again after a dropped connection or a server error.
  function fetchFile(key, input, init, attempt) {
    return origFetch.call(window, input, init).then(function (res) {
      if (res.status >= 500 && attempt < RETRIES.length) {
        return sleep(RETRIES[attempt]).then(function () { return fetchFile(key, input, init, attempt + 1); });
      }
      return res;
    }, function (err) {
      if (init && init.signal && init.signal.aborted) throw err;
      if (navigator.onLine === false) {
        // Offline: wait for the connection instead of failing, however long that takes.
        render();
        return whenOnline().then(function () { return fetchFile(key, input, init, attempt); });
      }
      if (attempt < RETRIES.length) {
        return sleep(RETRIES[attempt]).then(function () { return fetchFile(key, input, init, attempt + 1); });
      }
      throw err;
    });
  }

  // The same response, with its body counted as it's read.
  function counted(key, res) {
    if (res.status !== 200 || !res.body || typeof ReadableStream === 'undefined') return res;
    var reader = res.body.getReader();
    state.streamed[key] = true;
    state.got[key] = 0;
    var body = new ReadableStream({
      pull: function (ctl) {
        return reader.read().then(function (r) {
          if (r.done) { complete(key); ctl.close(); return; }
          received(key, r.value.byteLength);
          ctl.enqueue(r.value);
        }, function (err) {
          if (CORE[key]) fail('network', key);
          ctl.error(err);
        });
      },
      cancel: function (reason) { return reader.cancel(reason); },
    });
    var out = new Response(body, { status: res.status, statusText: res.statusText, headers: res.headers });
    try {
      Object.defineProperty(out, 'url', { value: res.url });
      Object.defineProperty(out, 'redirected', { value: res.redirected });
      Object.defineProperty(out, 'type', { value: res.type });
    } catch (_) {}
    return out;
  }

  if (typeof origFetch === 'function') {
    window.fetch = function (input, init) {
      var key = null;
      if (!state.finished) {
        var method = (init && init.method) || (input && typeof input === 'object' && input.method) || 'GET';
        if (String(method).toUpperCase() === 'GET') {
          key = keyOf(typeof input === 'string' || input instanceof URL ? input : input && input.url);
        }
      }
      if (!key) return origFetch.apply(window, arguments);
      noteVariant(key);
      // After "Reload without cache", the large files skip the browser's HTTP cache once.
      if (bust) init = Object.assign({}, init, { cache: 'reload' });
      return fetchFile(key, input, init, 0).then(function (res) {
        if (!res.ok && CORE[key]) fail(res.status === 404 ? 'missing' : 'network', key, res.status);
        return counted(key, res);
      }, function (err) {
        if (CORE[key]) fail('network', key);
        throw err;
      });
    };
  }

  // Files that don't go through fetch (the JavaScript runtime and renderer scripts load with
  // import() or a script tag) are seen when they finish.
  if (typeof PerformanceObserver !== 'undefined') {
    try {
      new PerformanceObserver(function (list) {
        list.getEntries().forEach(function (e) {
          var key = keyOf(e.name);
          if (!key || state.streamed[key]) return;
          noteVariant(key);
          if (e.responseStatus >= 400) return; // the error listener below reports it
          complete(key);
        });
      }).observe({ type: 'resource', buffered: true });
    } catch (_) {}
  }

  // The JavaScript build's main script is a script tag: note the choice when it's added.
  if (typeof MutationObserver !== 'undefined') {
    new MutationObserver(function (records) {
      records.forEach(function (r) {
        r.addedNodes.forEach(function (n) {
          if (n.tagName !== 'SCRIPT' || !n.src) return;
          var key = keyOf(n.src);
          if (key) { noteVariant(key); progressed(); }
        });
      });
    }).observe(document.head, { childList: true });
  }

  // A script that fails to load (flutter_bootstrap.js, the JavaScript build's main script).
  window.addEventListener('error', function (e) {
    if (state.finished) return;
    var t = e.target;
    if (t && t !== window && t.tagName === 'SCRIPT') {
      var src = t.src || '';
      var key = keyOf(src);
      if (key && CORE[key]) return fail('network', key);
      if (/flutter_bootstrap\.js|flutter\.js/.test(src)) return fail('network', 'flutter_bootstrap.js');
      return;
    }
    if (e.message) state.lastError = String(e.message).slice(0, 120);
  }, true);
  window.addEventListener('unhandledrejection', function (e) {
    if (state.finished) return;
    var r = e.reason;
    state.lastError = String((r && (r.message || r)) || 'unknown').slice(0, 120);
  });

  // ---- What the screen says ------------------------------------------------------------------

  var renderTimer = null;
  function schedule() {
    if (renderTimer || state.finished) return;
    renderTimer = setTimeout(function () { renderTimer = null; render(); }, 100);
  }

  function setText(el, text) { if (el && el.textContent !== text) el.textContent = text; }
  function toggle(el, cls, on) { if (el) el.classList.toggle(cls, !!on); }

  function render() {
    if (state.finished) return;
    var splash = $('splash');
    if (!splash) return;
    var t = now();
    if (!state.shown) {
      if (t - start < SHOW_AFTER_MS && !state.failed) return;
      state.shown = true;
      splash.classList.add('is-loading');
    }

    var bar = $('boot-bar'), fill = $('boot-fill'), text = $('boot-text'), hint = $('boot-hint');
    var help = $('boot-help');

    if (state.failed) {
      splash.classList.add('is-failed');
      toggle(help, 'is-on', true);
      return;
    }

    var f = fraction();
    var downloading = f == null ? state.step === 'download' : f < 0.999;
    var pct = f == null ? null : Math.max(state.shownPct, Math.floor(f * 100));
    if (pct != null) state.shownPct = pct;

    // The bar: real progress while downloading, a moving stripe when it can't be measured.
    var indeterminate = pct == null || !downloading;
    toggle(bar, 'is-indeterminate', indeterminate);
    if (!indeterminate) {
      fill.style.transform = 'scaleX(' + Math.max(0.02, pct / 100) + ')';
      bar.setAttribute('aria-valuenow', String(pct));
      bar.setAttribute('aria-valuetext', pct + '%');
    } else {
      fill.style.transform = '';
      bar.removeAttribute('aria-valuenow');
      bar.setAttribute('aria-valuetext', downloading ? 'Loading' : 'Starting');
    }

    if (downloading) {
      setText(text, pct == null ? 'Loading Casama…' : 'Loading Casama… ' + pct + '%');
    } else {
      setText(text, state.step === 'app' ? 'Opening Casama…' : 'Starting Casama…');
    }

    var visible = !document.hidden;
    var quiet = visible ? t - state.lastProgress : 0;
    var hintText = '';
    if (navigator.onLine === false) {
      hintText = 'You’re offline. Loading continues when you’re back online.';
    } else if (quiet >= QUIET_AFTER_MS) {
      hintText = downloading ? 'Waiting for the network…' : 'Still starting. Slower devices take a little longer.';
    } else if (downloading && t - start >= SLOW_AFTER_MS) {
      hintText = 'Your connection seems slow. Still loading.';
    }
    setText(hint, hintText);
    toggle(hint, 'is-on', !!hintText);

    var stuck = quiet >= STUCK_AFTER_MS && navigator.onLine !== false;
    if (stuck) {
      setText($('boot-title'), 'This is taking longer than it should');
      setText($('boot-body'), state.lastError
        ? 'Casama hit a problem while starting. Reloading usually fixes it.'
        : 'Casama is still trying. Reloading usually fixes it.');
      setCode('stuck', state.step + (state.lastError ? ' · ' + state.lastError : ''));
    }
    toggle(splash, 'is-help', stuck);
    toggle(help, 'is-on', stuck);
  }

  function setCode(kind, detail) {
    setText($('boot-code'), 'Code: ' + kind + (detail ? ' · ' + detail : ''));
  }

  function fail(kind, detail, status) {
    if (state.failed || state.finished) return;
    if (kind === 'network' && navigator.onLine === false) kind = 'offline';
    state.failed = kind;
    var title = 'Casama couldn’t load', body;
    switch (kind) {
      case 'browser':
        title = 'This browser can’t run Casama';
        body = 'Update your browser, or open Casama in a recent Chrome, Edge, Safari or Firefox.';
        break;
      case 'missing':
        body = 'A new version may be rolling out. Reload to get it.';
        break;
      case 'offline':
        body = 'You’re offline. Casama will reload when you’re back online.';
        window.addEventListener('online', function () { location.reload(); }, { once: true });
        break;
      case 'network':
        body = 'The connection dropped while loading. Check your internet, then reload.';
        break;
      default:
        title = 'Casama couldn’t start';
        body = 'Something went wrong while starting. Reloading usually fixes it.';
    }
    setText($('boot-title'), title);
    setText($('boot-body'), body);
    setCode(kind, String(detail || state.step) + (status ? ' ' + status : ''));
    var clear = $('boot-clear');
    if (clear) clear.hidden = kind === 'browser' || kind === 'offline';
    render();
    try { console.error('[casama] startup failed:', kind, detail || '', status || ''); } catch (_) {}
  }

  function finish() {
    if (state.finished) return;
    state.finished = true;
    clearInterval(ticker);
    var s = $('splash');
    if (s) s.remove();
  }

  // Reload: the browser revalidates the page. Reload without cache also removes Flutter's old
  // service worker and its caches, and makes the next start fetch the large files fresh. Sign-in
  // (local storage, IndexedDB) and the push-notification worker are left alone.
  function reload(clean) {
    if (!clean) return location.reload();
    try { sessionStorage.setItem(BUST_KEY, '1'); } catch (_) {}
    var jobs = [];
    if (navigator.serviceWorker && navigator.serviceWorker.getRegistrations) {
      jobs.push(navigator.serviceWorker.getRegistrations().then(function (regs) {
        return Promise.all(regs.filter(function (r) {
          var w = r.active || r.waiting || r.installing;
          return w && /flutter_service_worker\.js/.test(w.scriptURL);
        }).map(function (r) { return r.unregister(); }));
      }));
    }
    if (window.caches && caches.keys) {
      jobs.push(caches.keys().then(function (keys) {
        return Promise.all(keys.filter(function (k) { return /^flutter/.test(k); })
          .map(function (k) { return caches.delete(k); }));
      }));
    }
    Promise.race([Promise.all(jobs), sleep(3000)]).catch(function () {}).then(function () { location.reload(); });
  }

  var ticker = setInterval(render, 1000);
  window.addEventListener('flutter-first-frame', finish);
  window.addEventListener('online', schedule);
  window.addEventListener('offline', schedule);
  document.addEventListener('visibilitychange', function () {
    if (!document.hidden) state.lastProgress = Math.max(state.lastProgress, now() - 1000);
    schedule();
  });
  function wire() {
    var r = $('boot-reload'), c = $('boot-clear');
    if (r) r.addEventListener('click', function () { reload(false); });
    if (c) c.addEventListener('click', function () { reload(true); });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', wire);
  else wire();

  // ---- The painted scene behind the launch screen ----------------------------------------------
  // After the first paint, at low priority, so the bar and the mascot always come first. The
  // Flutter splash and welcome screen draw the same file, so it's already cached when they need it.
  function loadScene() {
    var splash = $('splash');
    if (!splash || state.finished) return;
    var dark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    var url = 'splash/scene-' + (dark ? 'night' : 'day') + '-wide.webp';
    var img = new Image();
    try { img.fetchPriority = 'low'; } catch (_) {}
    img.decoding = 'async';
    img.onload = function () {
      if (state.finished) return;
      splash.style.setProperty('--boot-scene', 'url("' + url + '")');
      // Start the zoom at the point it would be at since the page began, like Flutter's will.
      splash.style.setProperty('--boot-scene-delay', -Math.round(performance.now()) + 'ms');
      splash.classList.add('has-scene');
    };
    img.src = url;
  }
  requestAnimationFrame(function () { requestAnimationFrame(function () { setTimeout(loadScene, 0); }); });

  // ---- For flutter_bootstrap.js ----------------------------------------------------------------

  window.casamaBoot = {
    // From scripts/build-web.sh: every candidate file's size, and the files every start loads.
    files: function (manifest) {
      if (!manifest || !manifest.sizes) return;
      state.sizes = manifest.sizes;
      state.always = (manifest.always || []).filter(function (f) { return manifest.sizes[f] != null; });
      schedule();
    },
    step: function (name) {
      if (state.step === name) return;
      state.step = name;
      // Each step proves files arrived, even ones read from somewhere this script can't see
      // (the browser's cross-origin storage): the engine starts once the app's code has
      // compiled, and the app runs once the renderer is up.
      var app = state.variant.app || 'wasm';
      GROUPS.app[app].forEach(function (f) { state.done[f] = true; });
      if (name === 'app') {
        GROUPS.renderer[state.variant.renderer || guessRenderer(app)].forEach(function (f) { state.done[f] = true; });
      }
      progressed();
    },
    fail: function (err) {
      var msg = String((err && (err.message || err)) || 'unknown');
      if (/compatible/i.test(msg)) return fail('browser');
      fail('crash', msg.slice(0, 120));
    },
  };
})();
