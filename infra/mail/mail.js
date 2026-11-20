/**
 * Hosted bot mail's door (BOT-EMAIL-PLAN §5.1). Cloudflare Email Routing sends every mail to the
 * mail domain here (one catch-all rule); the Worker posts the raw message to POST /hooks/mail on
 * the API, signed with the shared secret. It parses nothing.
 *
 * The API's answer decides what the sender sees: 404 (no such address) and other 4xx reject the
 * mail; anything else failing throws, so the sending server tries again later. The retry behavior
 * is confirmed in Phase 0, which also wires the catch-all rule to this Worker.
 */

const LARGE_MAIL_BYTES = 1024 * 1024;
const MAX_MAIL_BYTES = 25 * 1024 * 1024;

const toHex = (buf) =>
  [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");

const sign = async (secret, timestamp, body) => {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(`${timestamp}.${body}`),
  );
  return `v1=${toHex(sig)}`;
};

const readCode = (res) =>
  res.json().then(
    (b) => (b && typeof b.code === "string" ? b.code : ""),
    () => "",
  );

export default {
  async email(message, env, _ctx) {
    if (message.rawSize > MAX_MAIL_BYTES) {
      message.setReject("Message too large");
      return;
    }
    const api = env.CASAMA_API_URL.replace(/\/$/, "");
    const secret = env.MAIL_HOOK_SECRET;
    const to = message.to;
    if (message.rawSize > LARGE_MAIL_BYTES) {
      // Ask first: unknown addresses reject before the bytes cross.
      const at = String(Date.now());
      let res;
      try {
        res = await fetch(`${api}/hooks/mail?to=${encodeURIComponent(to)}`, {
          headers: {
            "x-mail-timestamp": at,
            "x-mail-signature": await sign(secret, at, to),
          },
        });
      } catch (e) {
        throw new Error(`exists check failed: ${e.message}`);
      }
      if (res.status === 404) {
        const code = await readCode(res);
        if (code === "no_such_address") {
          message.setReject("No such address");
          return;
        }
        throw new Error(`exists check answered 404 (${code || "unknown"})`);
      }
      if (!res.ok) throw new Error(`exists check answered ${res.status}`);
    }
    // Read raw MIME bytes once and post as raw binary (message/rfc822) signed by its SHA-256
    // digest, avoiding base64 + JSON copies that blow past the Worker's 128 MB memory limit.
    const buf = new Uint8Array(await new Response(message.raw).arrayBuffer());
    const from = message.from ?? "";
    const digest = toHex(await crypto.subtle.digest("SHA-256", buf));
    const at = String(Date.now());
    let res;
    try {
      res = await fetch(`${api}/hooks/mail`, {
        method: "POST",
        headers: {
          "content-type": "message/rfc822",
          "x-mail-to": to,
          "x-mail-from": from,
          "x-mail-timestamp": at,
          "x-mail-signature": await sign(secret, at, `${to}\n${from}\n${digest}`),
        },
        body: buf,
      });
    } catch (e) {
      throw new Error(`mail post failed: ${e.message}`);
    }
    if (res.status === 404) {
      const code = await readCode(res);
      if (code === "no_such_address" || code === "sender_blocked") {
        message.setReject(code === "no_such_address" ? "No such address" : "Rejected");
        return;
      }
      // Missing server config or route mismatch: retry, never bounce permanently.
      throw new Error(`API answered 404 (${code || "unknown"})`);
    }
    if (res.status === 413) {
      const code = await readCode(res);
      message.setReject(code === "mailbox_full" ? "Mailbox full" : "Message too large");
      return;
    }
    // Only an unparseable message (400) is permanently rejected; rate limits (429), auth/clock
    // drift (401/403), timeouts (408) and 5xx throw so the sending server tries again later.
    if (res.status === 400) {
      message.setReject("Rejected");
      return;
    }
    if (!res.ok) throw new Error(`API answered ${res.status}`);
  },

  // Delivery events (BOT-EMAIL-PLAN §6.5): the Email Sending event subscription drops one
  // message per event on the queue; each is posted to the API, signed like inbound mail.
  async queue(batch, env) {
    const api = env.CASAMA_API_URL.replace(/\/$/, "");
    const secret = env.MAIL_HOOK_SECRET;
    for (const msg of batch.messages) {
      const body = JSON.stringify(msg.body ?? {});
      const at = String(Date.now());
      try {
        const res = await fetch(`${api}/hooks/mail/events`, {
          method: "POST",
          headers: {
            "content-type": "application/json",
            "x-mail-timestamp": at,
            "x-mail-signature": await sign(secret, at, body),
          },
          body,
        });
        // Only valid deliveries and malformed payloads (400) are acknowledged; 401/403/404/429/5xx retry.
        if (res.ok || res.status === 400) msg.ack();
        else msg.retry();
      } catch {
        msg.retry();
      }
    }
  },
};
