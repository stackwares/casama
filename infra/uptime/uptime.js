// Casama uptime check (D-252) and public status page (D-304). Cron every 5 minutes: fetch each URL
// in CHECKS; after 2 failures in a row email ALERT_TO that it's down (repeated at most hourly while
// down), and once when it's back. Mail goes out over SMTP with implicit TLS (port 465), the same
// mailbox the server uses.
//
// status.casama.ai is served from here too, so it stays up when the server is down: the latest
// result per service, 90 days of daily uptime, and an incident note when one is set
// (scripts/status-incident.sh). KV writes stay inside the free tier: a check's own state is written
// only when it changes, plus one history record per run (288 a day).
import { connect } from "cloudflare:sockets";

const FAILS_TO_ALERT = 2;
const REPEAT_MS = 60 * 60_000;

async function probe(url) {
  const started = Date.now();
  try {
    const r = await fetch(url, {
      method: "GET",
      headers: { "user-agent": "casama-uptime" },
      signal: AbortSignal.timeout(10_000),
      cf: { cacheTtl: 0 },
    });
    return { ok: r.ok, detail: `HTTP ${r.status} in ${Date.now() - started} ms` };
  } catch (err) {
    return { ok: false, detail: `${err?.name ?? "Error"}: ${err?.message ?? err}` };
  }
}

/** A minimal SMTP client: implicit TLS, AUTH LOGIN, one message. */
async function sendMail(env, subject, text) {
  const socket = connect(
    { hostname: env.SMTP_HOST, port: Number(env.SMTP_PORT || 465) },
    { secureTransport: "on" },
  );
  const writer = socket.writable.getWriter();
  const reader = socket.readable.getReader();
  const enc = new TextEncoder();
  const dec = new TextDecoder();
  let buf = "";
  const reply = async () => {
    // Read until a final reply line ("250 ..." rather than "250-...").
    for (;;) {
      const lines = buf.split("\r\n");
      for (let i = 0; i < lines.length - 1; i++) {
        if (/^\d{3} /.test(lines[i])) {
          buf = lines.slice(i + 1).join("\r\n");
          const code = Number(lines[i].slice(0, 3));
          if (code >= 400) throw new Error(`SMTP ${lines[i]}`);
          return code;
        }
      }
      const { value, done } = await reader.read();
      if (done) throw new Error("SMTP connection closed");
      buf += dec.decode(value);
    }
  };
  const cmd = async (line) => {
    await writer.write(enc.encode(`${line}\r\n`));
    return reply();
  };
  const b64 = (s) => btoa(String.fromCharCode(...enc.encode(s)));
  const from = env.MAIL_FROM;
  const fromAddr = (from.match(/<([^>]+)>/) ?? [null, from])[1];
  try {
    await reply();
    await cmd("EHLO casama-uptime");
    await cmd("AUTH LOGIN");
    await cmd(b64(env.SMTP_USER));
    await cmd(b64(env.SMTP_PASS));
    await cmd(`MAIL FROM:<${fromAddr}>`);
    for (const to of env.ALERT_TO.split(",")
      .map((s) => s.trim())
      .filter(Boolean))
      await cmd(`RCPT TO:<${to}>`);
    await cmd("DATA");
    const body = [
      `From: ${from}`,
      `To: ${env.ALERT_TO}`,
      `Subject: ${subject}`,
      `Date: ${new Date().toUTCString()}`,
      "MIME-Version: 1.0",
      "Content-Type: text/plain; charset=utf-8",
      "",
      ...text.split("\n").map((l) => (l.startsWith(".") ? `.${l}` : l)),
      ".",
    ].join("\r\n");
    await cmd(body);
    await cmd("QUIT").catch(() => {});
  } finally {
    await socket.close().catch(() => {});
  }
}

const HISTORY_DAYS = 90;
/** The names people see; a check without one shows its own name. */
const LABELS = { api: "API", app: "Web app", auth: "Sign-in", docs: "Docs", site: "Website" };

async function run(env) {
  const checks = env.CHECKS.split(",").map((pair) => {
    // Split at the first "=" only: a URL can have its own (a query string).
    const at = pair.indexOf("=");
    const name = pair.slice(0, at);
    const url = pair.slice(at + 1);
    // The auth check's public sign-in key comes from AUTH_ANON_KEY (see wrangler.jsonc).
    return { name: name.trim(), url: url.trim().replace("AUTH_ANON_KEY", env.AUTH_ANON_KEY ?? "") };
  });
  const now = Date.now();
  const results = [];
  for (const c of checks) {
    const res = await probe(c.url);
    const key = `check:${c.name}`;
    const prev = JSON.parse((await env.STATE.get(key)) ?? "{}");
    const fails = res.ok ? 0 : (prev.fails ?? 0) + 1;
    const state = {
      fails,
      since: res.ok ? null : (prev.since ?? now),
      alertedAt: prev.alertedAt ?? null,
    };
    if (
      !res.ok &&
      fails >= FAILS_TO_ALERT &&
      (!state.alertedAt || now - state.alertedAt > REPEAT_MS)
    ) {
      await sendMail(
        env,
        `Casama is DOWN: ${c.name}`,
        `${c.url} has failed ${fails} checks in a row since ${new Date(state.since).toISOString()}.\nLast result: ${res.detail}\n\nServer: ssh casama-vps, then docker compose ps in /opt/casama/infra/compose.`,
      );
      state.alertedAt = now;
    }
    if (res.ok && prev.alertedAt) {
      await sendMail(
        env,
        `Casama is back up: ${c.name}`,
        `${c.url} answers again (${res.detail}). It was down since ${new Date(prev.since ?? now).toISOString()}.`,
      );
      state.alertedAt = null;
    }
    if (
      JSON.stringify(state) !==
      JSON.stringify({
        fails: prev.fails ?? 0,
        since: prev.since ?? null,
        alertedAt: prev.alertedAt ?? null,
      })
    )
      await env.STATE.put(key, JSON.stringify(state));
    results.push({ ...c, ...res, fails });
  }
  await recordHistory(env, results, now);
  return results;
}

/** One record for the status page: the latest results and a per-day count of good checks. */
async function recordHistory(env, results, now) {
  const h = JSON.parse((await env.STATE.get("history")) ?? "{}");
  const today = new Date(now).toISOString().slice(0, 10);
  const days = h.days ?? {};
  const counts = days[today] ?? {};
  for (const r of results) {
    const [good, total] = counts[r.name] ?? [0, 0];
    counts[r.name] = [good + (r.ok ? 1 : 0), total + 1];
  }
  days[today] = counts;
  for (const d of Object.keys(days).sort().slice(0, -HISTORY_DAYS)) delete days[d];
  const latest = {};
  for (const r of results)
    latest[r.name] = {
      ok: r.ok,
      fails: r.fails,
      since: r.ok ? null : (h.latest?.[r.name]?.since ?? now),
    };
  await env.STATE.put("history", JSON.stringify({ updated: now, latest, days }));
}

/** What the page and /status.json show: no URLs or error text, just names and states. */
async function statusData(env) {
  const h = JSON.parse((await env.STATE.get("history")) ?? "{}");
  const incident = JSON.parse((await env.STATE.get("incident")) ?? "null");
  const names = env.CHECKS.split(",").map((p) => p.split("=")[0].trim());
  const dayKeys = [];
  for (let i = HISTORY_DAYS - 1; i >= 0; i--)
    dayKeys.push(new Date(Date.now() - i * 86_400_000).toISOString().slice(0, 10));
  const services = names.map((name) => {
    const l = h.latest?.[name];
    // Down only after two failed checks in a row, like the alert: one blip isn't an outage.
    const state = !l ? "unknown" : l.ok ? "up" : l.fails >= FAILS_TO_ALERT ? "down" : "up";
    const days = dayKeys.map((d) => {
      const c = h.days?.[d]?.[name];
      return { day: d, uptime: c && c[1] ? c[0] / c[1] : null };
    });
    const known = days.filter((d) => d.uptime !== null);
    const uptime = known.length ? known.reduce((a, d) => a + d.uptime, 0) / known.length : null;
    return {
      name,
      label: LABELS[name] ?? name,
      state,
      since: state === "down" ? l.since : null,
      uptime,
      days,
    };
  });
  const overall =
    incident?.severity === "major" || services.some((s) => s.state === "down")
      ? "down"
      : incident
        ? "degraded"
        : services.every((s) => s.state === "up")
          ? "up"
          : "unknown";
  return { overall, updated: h.updated ?? null, incident, services };
}

const esc = (s) =>
  String(s ?? "").replace(
    /[&<>"']/g,
    (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c],
  );

function statusPage(d) {
  const headline = {
    up: "All systems working",
    degraded: "Some things aren't working right",
    down: "Casama is having problems",
    unknown: "Checking...",
  }[d.overall];
  const dot = (state) =>
    ({ up: "var(--good)", down: "var(--bad)", degraded: "var(--warn)", unknown: "var(--muted)" })[
      state
    ];
  const bar = (u) =>
    u === null
      ? "var(--empty)"
      : u >= 0.999
        ? "var(--good)"
        : u >= 0.98
          ? "var(--warn)"
          : "var(--bad)";
  const pct = (u) =>
    u === null ? "No data yet" : `${(u * 100).toFixed(u >= 0.9995 ? 0 : 2)}% uptime`;
  const rows = d.services
    .map(
      (s) => `<section class="svc">
  <div class="row"><span class="name"><i style="background:${dot(s.state)}"></i>${esc(s.label)}</span><span class="state">${s.state === "up" ? "Working" : s.state === "down" ? "Down" : "Checking"}</span></div>
  <div class="bars" role="img" aria-label="${esc(s.label)}: ${pct(s.uptime)} over 90 days">${s.days.map((x) => `<b style="background:${bar(x.uptime)}" title="${x.day}: ${x.uptime === null ? "no data" : `${(x.uptime * 100).toFixed(2)}%`}"></b>`).join("")}</div>
  <div class="row small"><span>90 days ago</span><span>${pct(s.uptime)}</span><span>Today</span></div>
</section>`,
    )
    .join("\n");
  const incident = d.incident
    ? `<section class="incident ${d.incident.severity === "major" ? "major" : ""}"><strong>${esc(d.incident.title)}</strong>${d.incident.body ? `<p>${esc(d.incident.body)}</p>` : ""}<p class="small">Since ${esc(new Date(d.incident.started ?? Date.now()).toUTCString())}</p></section>`
    : "";
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Casama status</title><link rel="icon" type="image/svg+xml" href="https://casama.ai/assets/bots/casama-winky-animated.svg"><meta name="description" content="Whether Casama's services are working right now.">
<meta http-equiv="refresh" content="120">
<meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)"><meta name="theme-color" content="#1c1c1e" media="(prefers-color-scheme: dark)">
<link rel="preload" href="https://casama.ai/assets/fonts/GoogleSans-Bold.woff2" as="font" type="font/woff2" crossorigin>
<style>
/* The casama.link look: plain white in light mode, plain dark grey in dark mode, no tints. Fonts come from casama.ai. */
@font-face{font-family:"Google Sans";src:url("https://casama.ai/assets/fonts/GoogleSans-Regular.woff2") format("woff2");font-weight:400;font-display:swap}
@font-face{font-family:"Google Sans";src:url("https://casama.ai/assets/fonts/GoogleSans-Medium.woff2") format("woff2");font-weight:500 600;font-display:swap}
@font-face{font-family:"Google Sans";src:url("https://casama.ai/assets/fonts/GoogleSans-Bold.woff2") format("woff2");font-weight:700;font-display:swap}
@font-face{font-family:"Libre Baskerville";src:url("https://casama.ai/assets/fonts/LibreBaskerville-Bold.woff2") format("woff2");font-weight:700;font-display:swap}
:root{color-scheme:light;--bg:#ffffff;--bg-2:#f4f4f6;--card:#f7f7f9;--ink:#1d1b20;--ink-2:#5d5a63;--muted:#5d5a63;--line:#e3e2e7;--accent:#7a3fa8;--accent-soft:#f1e2fc;--good:#1f7a4d;--warn:#b7791f;--bad:#a2361f;--empty:#e3e2e7;
--sans:"Google Sans",-apple-system,BlinkMacSystemFont,"Segoe UI",system-ui,sans-serif;--serif:"Libre Baskerville",Georgia,"Times New Roman",serif}
@media (prefers-color-scheme:dark){:root{color-scheme:dark;--bg:#1c1c1e;--bg-2:#2a2a2d;--card:#242427;--ink:#f2f1f4;--ink-2:#b4b1b9;--muted:#b4b1b9;--line:#38383c;--accent:#d9b6f7;--accent-soft:#3a2a47;--good:#7fd6a6;--warn:#f2c46d;--bad:#ffab96;--empty:#38383c}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink-2);font:400 17px/1.55 var(--sans);-webkit-font-smoothing:antialiased}
main{max-width:760px;margin:0 auto;padding:20px 16px 64px}
.brand{display:inline-flex;align-items:center;gap:10px;text-decoration:none;color:var(--ink)}
.brand-word{font:700 22px/1 var(--serif);letter-spacing:-0.03em}
.brand-tag{font:700 13px/1 var(--sans);letter-spacing:.04em;text-transform:uppercase;color:var(--accent);background:var(--accent-soft);padding:5px 9px;border-radius:999px;margin-left:-2px}
h1{color:var(--ink);font:700 clamp(32px,5vw,48px)/1.05 var(--sans);letter-spacing:-0.05em;margin:48px 0 12px}.sub{color:var(--ink-2);margin:0 0 32px;font-size:15px}
.card{background:var(--card);border:1px solid var(--line);border-radius:22px;padding:8px 24px}
.svc{padding:18px 0;border-bottom:1px solid var(--line)}.svc:last-child{border-bottom:0}
.row{display:flex;justify-content:space-between;align-items:center;gap:8px}.small{font-size:13px;color:var(--muted);margin-top:8px}
.name{font-weight:700;color:var(--ink);display:flex;align-items:center;gap:10px}.name i{width:10px;height:10px;border-radius:50%;display:inline-block}
.state{font-size:15px;font-weight:500;color:var(--ink-2)}
.bars{display:grid;grid-template-columns:repeat(90,1fr);gap:2px;margin-top:12px;height:28px}.bars b{border-radius:3px;display:block}
.incident{background:var(--card);border:1px solid color-mix(in oklab,var(--warn) 45%,var(--line));border-radius:22px;padding:18px 24px;margin:0 0 20px;color:var(--ink)}
.incident.major{border-color:color-mix(in oklab,var(--bad) 45%,var(--line))}.incident strong{font-weight:700}.incident p{margin:6px 0 0;color:var(--ink-2)}
footer{margin-top:28px;font-size:15px;color:var(--ink-2)}footer a{color:var(--ink);font-weight:700}
:focus-visible{outline:3px solid var(--accent);outline-offset:3px;border-radius:6px}
::selection{background:var(--accent);color:var(--bg)}
@media (max-width:480px){.bars{grid-template-columns:repeat(45,1fr)}.bars b:nth-child(-n+45){display:none}}
</style></head>
<body><main>
<a class="brand" href="https://casama.ai"><span class="brand-word">Casama</span><span class="brand-tag">Status</span></a>
<h1>${headline}</h1>
<p class="sub">${d.updated ? `Checked every 5 minutes · last check ${esc(new Date(d.updated).toUTCString())}` : "Waiting for the first check"}</p>
${incident}
<div class="card">${rows}</div>
<footer>Something wrong that isn't shown here? Write to <a href="mailto:support@casama.ai">support@casama.ai</a>, or use Settings &gt; Help &amp; support in the app.</footer>
</main></body></html>`;
}

export default {
  async scheduled(_event, env, ctx) {
    ctx.waitUntil(run(env));
  },
  // status.casama.ai: the page and /status.json. The test mail needs TEST_TOKEN, so nobody else
  // can make it send email.
  async fetch(req, env) {
    const url = new URL(req.url);
    if (url.searchParams.get("test") === "mail") {
      if (!env.TEST_TOKEN || url.searchParams.get("token") !== env.TEST_TOKEN)
        return new Response("Not found", { status: 404 });
      await sendMail(
        env,
        "Casama uptime check is on",
        "This is a test from the casama-uptime Worker. You'll get mail like this if a Casama service stops answering.",
      );
      return new Response("sent");
    }
    const data = await statusData(env);
    const headers = { "cache-control": "public, max-age=60", "access-control-allow-origin": "*" };
    if (url.pathname === "/status.json") return Response.json(data, { headers });
    if (url.pathname !== "/") return new Response("Not found", { status: 404 });
    return new Response(statusPage(data), {
      headers: { ...headers, "content-type": "text/html; charset=utf-8" },
    });
  },
};
