// Casama uptime check (D-252). Cron every 5 minutes: fetch each URL in CHECKS; after 2 failures in
// a row email ALERT_TO that it's down (repeated at most hourly while down), and once when it's back.
// Mail goes out over SMTP with implicit TLS (port 465), the same mailbox the server uses.
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

async function run(env) {
  const checks = env.CHECKS.split(",").map((pair) => {
    const [name, url] = pair.split("=");
    return { name: name.trim(), url: url.trim() };
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
    await env.STATE.put(key, JSON.stringify(state));
    results.push({ ...c, ...res, fails });
  }
  return results;
}

export default {
  async scheduled(_event, env, ctx) {
    ctx.waitUntil(run(env));
  },
  // workers_dev is off and there's no route, so this only answers `wrangler dev` checks.
  async fetch(req, env) {
    if (new URL(req.url).searchParams.get("test") === "mail") {
      await sendMail(
        env,
        "Casama uptime check is on",
        "This is a test from the casama-uptime Worker. You'll get mail like this if api.casama.ai or app.casama.ai stops answering.",
      );
      return new Response("sent");
    }
    return Response.json(await run(env));
  },
};
