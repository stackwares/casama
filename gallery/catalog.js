/*!
 * Casama gallery catalog helpers (D-315): kinds, labels, what an item can access, search with
 * synonyms, rows (picks, new, seasonal) and the links into the app. Shared by the gallery page
 * (app.js) and the page generator (build-pages.mjs), so both say the same thing. No DOM here.
 */
(function (root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory();
  else root.CasamaCatalog = factory();
})(typeof self !== "undefined" ? self : this, function () {
  "use strict";

  var SITE = "https://gallery.casama.ai";
  var REPO = "stackwares/casama-gallery";
  var TYPES = ["theme", "scheme", "wallpaper", "skill", "app", "bot", "routine", "plugin"];
  var LOOKS = ["theme", "scheme", "wallpaper"];
  var PLURAL = { theme: "Themes", scheme: "Colors", wallpaper: "Wallpapers", skill: "Skills", app: "Apps", bot: "Bots", routine: "Routines", plugin: "Plugins", set: "Starter sets" };
  var NOUN = { theme: ["theme", "themes"], scheme: ["color scheme", "color schemes"], wallpaper: ["wallpaper", "wallpapers"], skill: ["skill", "skills"], app: ["app", "apps"], bot: ["starter bot", "starter bots"], routine: ["routine idea", "routine ideas"], plugin: ["plugin", "plugins"], set: ["starter set", "starter sets"] };
  var SINGULAR = { theme: "Theme", scheme: "Color scheme", wallpaper: "Wallpaper", skill: "Skill", app: "App", bot: "Starter bot", routine: "Routine idea", plugin: "Plugin", set: "Starter set" };
  var DAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
  // Categories across kinds, merged into one list of topics for the filter.
  var CATEGORY = {
    work: "Work", writing: "Writing", research: "Research", data: "Data", money: "Money", build: "Build", life: "Life", create: "Create",
    developer: "Developer", productivity: "Productivity", payments: "Payments", design: "Design", sales: "Sales", automation: "Automation",
  };
  var CREDITS = { none: "Free to run", low: "Uses a few credits", medium: "Uses some credits", high: "Uses a lot of credits" };
  // Small synonym map for search: a word also finds these.
  var SYNONYMS = {
    mail: ["email", "gmail", "outlook", "inbox"], email: ["mail", "gmail", "outlook", "inbox"], inbox: ["email", "mail"],
    cal: ["calendar"], calendar: ["cal", "schedule", "meeting", "events"], meeting: ["calendar", "meet", "zoom", "call"], schedule: ["calendar", "routine"],
    doc: ["docs", "document", "notion"], docs: ["doc", "document", "notion"], notes: ["note", "notion", "obsidian", "journal"], note: ["notes", "notion"],
    code: ["github", "developer", "build", "programming", "dev"], dev: ["developer", "code", "github"], git: ["github", "gitlab"],
    pay: ["payments", "stripe", "invoice", "billing"], money: ["finance", "payments", "budget", "invoice"], finance: ["money", "budget", "accounting"],
    chat: ["slack", "discord", "messages", "telegram"], message: ["slack", "chat", "messages"],
    task: ["todo", "tasks", "linear", "asana", "jira", "project"], todo: ["task", "tasks"], tasks: ["task", "todo", "project"],
    write: ["writing", "blog", "article", "draft"], writing: ["write", "blog", "article"], blog: ["writing", "article", "post"],
    crm: ["sales", "hubspot", "salesforce", "customers"], sales: ["crm", "leads"], analytics: ["data", "metrics", "stats"], metrics: ["analytics", "data"],
    sheet: ["spreadsheet", "excel", "sheets", "table"], spreadsheet: ["sheet", "excel", "table"], design: ["figma", "canva"],
    dark: ["night"], night: ["dark"], color: ["colour", "scheme", "colors"], colour: ["color", "scheme"], colors: ["color", "scheme"],
    wallpaper: ["background"], background: ["wallpaper"], look: ["theme"], photo: ["image", "picture"], image: ["photo", "picture"],
    news: ["newsletter", "digest", "briefing"], morning: ["daily", "briefing", "digest"], summary: ["summarize", "digest", "brief"], summarize: ["summary", "digest"],
    study: ["student", "learn", "school"], student: ["study", "learn", "school"], travel: ["trip", "flight", "hotel"], health: ["fitness", "workout"],
  };

  function str(v) { return v == null ? "" : String(v); }
  function doc(item) { return (item && item.document) || {}; }
  function isLook(item) { return LOOKS.indexOf(item.type) !== -1; }
  function count(n, type) { var w = NOUN[type] || [type, type + "s"]; return n + " " + w[n === 1 ? 0 : 1]; }

  /** An item's category, from the record or its document. */
  function category(item) { return item.category || doc(item).category || ""; }
  function categoryLabel(item) { var c = category(item); return CATEGORY[c] || (c ? c.charAt(0).toUpperCase() + c.slice(1) : ""); }

  /** A cron schedule in words, for the common shapes; the expression itself otherwise. */
  function when(cron) {
    var f = str(cron).trim().split(/\s+/);
    if (f.length !== 5) return str(cron);
    var m = +f[0], h = +f[1];
    if (isNaN(m) || isNaN(h)) return str(cron);
    var t = (h % 12 || 12) + (m ? ":" + (m < 10 ? "0" + m : m) : "") + (h < 12 ? " am" : " pm");
    if (f[2] === "*" && f[3] === "*" && f[4] === "*") return "Every day at " + t;
    if (f[2] === "*" && f[3] === "*" && f[4] === "1-5") return "Weekdays at " + t;
    if (f[2] === "*" && f[3] === "*" && /^[0-6]$/.test(f[4])) return "Every " + DAYS[+f[4]] + " at " + t;
    if (/^\d+$/.test(f[2]) && f[3] === "*" && f[4] === "*") return "Monthly on day " + f[2] + " at " + t;
    return str(cron);
  }
  /** A routine's schedule; `{{time.hour}}` placeholders read as "at a time you pick". */
  function schedule(cron) {
    if (/\{\{/.test(str(cron))) return "At a time you pick";
    return when(cron);
  }

  // ---------------------------------------------------------------- people
  function slug(s) { return str(s).toLowerCase().normalize("NFKD").replace(/[^\w\s-]/g, "").replace(/[\s_]+/g, "-").replace(/-+/g, "-").replace(/^-|-$/g, "").slice(0, 39) || "unknown"; }
  /** Author page id: author.handle, else a slug of the name. */
  function authorKey(item) { var a = item.author || {}; return a.handle || slug(a.name); }
  function community(item) { return !!(item.author && item.author.name && item.author.name !== "Casama"); }
  /** "Casama", "Community", plus "Reviewed" when its tests passed for this version. */
  function madeBy(item) {
    var parts = [community(item) ? "Community" : "Casama"];
    if (item.tested && (item.tested.version == null || item.tested.version === item.version)) parts.push("Reviewed");
    return parts;
  }

  // ---------------------------------------------------------------- what it can do
  /** What an item can access, as plain lines: [{ icon, label, text }]. Empty when not stated. */
  function access(item) {
    var a = item.access;
    if (!a || typeof a !== "object") return [];
    var out = [];
    if (Array.isArray(a.reads) && a.reads.length) out.push({ icon: "eye", label: "Reads", text: a.reads.join(", ") });
    if (Array.isArray(a.writes) && a.writes.length) out.push({ icon: "pencil", label: "Can", text: a.writes.join(", ") });
    if (a.runs_code) out.push({ icon: "terminal", label: "Runs code", text: "Runs scripts while it works" });
    if (a.computer) out.push({ icon: "monitor", label: "Computer", text: "Needs the bot's own computer" });
    if (a.credits && CREDITS[a.credits]) out.push({ icon: "coins", label: "Cost", text: CREDITS[a.credits] });
    return out;
  }
  function needsComputer(item) { return !!(item.access && item.access.computer); }
  /** Free to run: looks, and items that say they use no credits. */
  function isFree(item) { return isLook(item) || !!(item.access && item.access.credits === "none"); }
  /** Works on a self-hosted server: not marked cloud-only, and not an app whose sign-in needs Casama's
   *  public client document (cimd), which only works on a server with a public https address. */
  function selfHosted(item) {
    if (item.self_hosted === false || item.cloud_only === true) return false;
    if (item.type === "app" && doc(item).oauthClient === "cimd") return false;
    return true;
  }
  function examples(item) { return Array.isArray(item.examples) ? item.examples.filter(Boolean).slice(0, 3) : []; }
  function changelog(item) { return Array.isArray(item.changelog) ? item.changelog : []; }
  function needs(item) {
    var n = item.needs || {};
    return { apps: Array.isArray(n.apps) ? n.apps : [], skills: Array.isArray(n.skills) ? n.skills : [] };
  }
  function inputs(item) { return Array.isArray(item.inputs) ? item.inputs : []; }
  /** A set's items: [{ type, id }], from the record or its document. */
  function setItems(set) { var list = set.items || doc(set).items; return Array.isArray(list) ? list : []; }

  // ---------------------------------------------------------------- dates
  function day(s) { var m = /^(\d{4})-(\d{2})-(\d{2})/.exec(str(s)); return m ? Date.UTC(+m[1], +m[2] - 1, +m[3]) : NaN; }
  /** Added within the last 30 days. */
  function isNew(item, now) {
    var t = day(item.added);
    if (isNaN(t)) return false;
    var age = ((now || Date.now()) - t) / 86400000;
    return age >= -1 && age <= 30;
  }
  /** In season today: between season.from and season.to ("MM-DD"), wrapping the year end. */
  function inSeason(item, now) {
    var s = item.season;
    if (!s || !/^\d{2}-\d{2}$/.test(str(s.from)) || !/^\d{2}-\d{2}$/.test(str(s.to))) return false;
    var d = new Date(now || Date.now());
    var today = ("0" + (d.getUTCMonth() + 1)).slice(-2) + "-" + ("0" + d.getUTCDate()).slice(-2);
    return s.from <= s.to ? today >= s.from && today <= s.to : today >= s.from || today <= s.to;
  }
  var MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
  function longDate(s) { var t = day(s); if (isNaN(t)) return ""; var d = new Date(t); return MONTHS[d.getUTCMonth()] + " " + d.getUTCDate() + ", " + d.getUTCFullYear(); }

  // ---------------------------------------------------------------- stats
  /** "Used by 120 people · 96% of runs finish", or "" when the stats say nothing. */
  function statsLine(stats) {
    if (!stats) return "";
    var parts = [];
    if (stats.installers) parts.push("Used by " + Number(stats.installers).toLocaleString("en-US") + " people");
    if (typeof stats.success === "number") parts.push(Math.round(stats.success * (stats.success <= 1 ? 100 : 1)) + "% of runs finish");
    return parts.join(" · ");
  }

  // ---------------------------------------------------------------- search
  function words(q) { return str(q).toLowerCase().replace(/[^\p{L}\p{N}\s-]/gu, " ").split(/\s+/).filter(Boolean); }
  /** The words a query word also matches. */
  function expand(word) {
    var out = [word];
    var add = function (list) { (list || []).forEach(function (w) { if (out.indexOf(w) === -1) out.push(w); }); };
    add(SYNONYMS[word]);
    if (word.length > 3 && /s$/.test(word)) { out.push(word.slice(0, -1)); add(SYNONYMS[word.slice(0, -1)]); }
    return out;
  }
  /** Search fields of an item, weighted: name 6, tags 4, kind/category 3, id 3, the rest 1. */
  function fields(item) {
    var d = doc(item), a = item.access || {};
    return [
      [6, str(item.name).toLowerCase()],
      [4, (item.tags || []).join(" ").toLowerCase()],
      [3, (str(item.type) + " " + (NOUN[item.type] || []).join(" ") + " " + category(item) + " " + categoryLabel(item)).toLowerCase()],
      [3, str(item.id).replace(/-/g, " ")],
      [1, [item.description, d.description, (item.author || {}).name, (item.author || {}).handle, item.pick]
        .concat(examples(item), a.reads || [], a.writes || [], d.capabilities || [], d.adds || [], d.starters || [])
        .map(str).join(" ").toLowerCase()],
    ];
  }
  /** Score of an item for a query: every word (or one of its synonyms) must match; 0 when not. */
  function score(item, q) {
    var ws = words(q);
    if (!ws.length) return 1;
    var fs = item._fields || fields(item), total = 0;
    for (var i = 0; i < ws.length; i++) {
      var best = 0, alts = expand(ws[i]);
      for (var j = 0; j < fs.length; j++) {
        for (var k = 0; k < alts.length; k++) {
          if (fs[j][1].indexOf(alts[k]) !== -1) { var s = fs[j][0] * (k === 0 ? 1 : 0.6); if (s > best) best = s; }
        }
      }
      if (!best) return 0;
      total += best;
    }
    return total;
  }
  /** Items matching q, best first (picks break ties, then names). */
  function search(items, q) {
    return items.map(function (i) { return { i: i, s: score(i, q) }; }).filter(function (x) { return x.s > 0; })
      .sort(function (a, b) { return b.s - a.s || (b.i.featured ? 1 : 0) - (a.i.featured ? 1 : 0) || str(a.i.name).localeCompare(str(b.i.name)); })
      .map(function (x) { return x.i; });
  }

  // ---------------------------------------------------------------- links
  function pagePath(item) { return "/i/" + item.type + "/" + item.id + "/"; }
  function pageUrl(item) { return SITE + pagePath(item); }
  function authorPath(key) { return "/by/" + key + "/"; }
  /** Opens the item in the app (casama://app/gallery/<type>/<id>). */
  function openLink(item) { return "casama://app/gallery/" + item.type + "/" + item.id; }
  /** The share link: casama.ai opens the app on phones that have it, else this page. */
  function shareLink(item) { return "https://casama.ai/gallery/" + item.type + "/" + item.id; }
  function sourceLink(item) { return "https://github.com/" + REPO + "/tree/main/" + item.type + "s/" + item.id; }
  /** A chat with this prompt in the app (Quick ask). */
  function askLink(prompt) { return "casama://app/quick-ask?text=" + encodeURIComponent(str(prompt)); }
  /** The app's requests board with a new request, and a GitHub issue for people without the app. */
  function requestLinks(q) {
    var title = str(q).trim().slice(0, 80);
    return {
      app: "casama://app/gallery/requests/new?title=" + encodeURIComponent(title),
      github: "https://github.com/" + REPO + "/issues/new?labels=request&title=" + encodeURIComponent("Request: " + title) +
        "&body=" + encodeURIComponent("What should it do?\n\n"),
    };
  }
  function askToMake(q) { return askLink("Make me a Casama " + (str(q).trim() || "skill") + " and help me add it to the gallery."); }

  return {
    SITE: SITE, REPO: REPO, TYPES: TYPES, LOOKS: LOOKS, PLURAL: PLURAL, NOUN: NOUN, SINGULAR: SINGULAR, CATEGORY: CATEGORY,
    CREDITS: CREDITS, SYNONYMS: SYNONYMS,
    doc: doc, isLook: isLook, count: count, category: category, categoryLabel: categoryLabel, when: when, schedule: schedule,
    slug: slug, authorKey: authorKey, community: community, madeBy: madeBy,
    access: access, needsComputer: needsComputer, isFree: isFree, selfHosted: selfHosted, examples: examples, changelog: changelog,
    needs: needs, inputs: inputs, setItems: setItems,
    day: day, isNew: isNew, inSeason: inSeason, longDate: longDate, statsLine: statsLine,
    words: words, expand: expand, fields: fields, score: score, search: search,
    pagePath: pagePath, pageUrl: pageUrl, authorPath: authorPath, openLink: openLink, shareLink: shareLink, sourceLink: sourceLink,
    askLink: askLink, askToMake: askToMake, requestLinks: requestLinks,
  };
});
