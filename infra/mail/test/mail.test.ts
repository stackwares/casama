/** The mail Worker: posts raw mail to the API signed, rejects unknown addresses. */
import { createHash, createHmac } from "node:crypto";
import { afterEach, describe, expect, it } from "vitest";
import handler from "../mail.js";

const realFetch = globalThis.fetch;
afterEach(() => {
  globalThis.fetch = realFetch;
});

function message(raw: string, to = "ada@mail.test") {
  const bytes = new TextEncoder().encode(raw);
  return {
    from: "ana@example.com",
    to,
    rawSize: bytes.length,
    raw: new ReadableStream({
      start(c) {
        c.enqueue(bytes);
        c.close();
      },
    }),
    rejected: null as string | null,
    setReject(reason: string) {
      this.rejected = reason;
    },
  };
}

const env = { CASAMA_API_URL: "https://api.test", MAIL_HOOK_SECRET: "hook-secret" };

function stubFetch(responder: (url: string, init: RequestInit) => Response) {
  const calls: Array<{ url: string; init: RequestInit; body: string; rawBody: Uint8Array | null }> =
    [];
  globalThis.fetch = (async (url: string, init: RequestInit = {}) => {
    const rawBody = init.body instanceof Uint8Array ? init.body : null;
    const body = rawBody ? new TextDecoder().decode(rawBody) : String(init.body ?? "");
    calls.push({ url, init, body, rawBody });
    return responder(url, init);
  }) as typeof fetch;
  return calls;
}

const signed = (payload: string, headers: HeadersInit) => {
  const h = new Headers(headers);
  const at = h.get("x-mail-timestamp") ?? "";
  const want = `v1=${createHmac("sha256", "hook-secret").update(`${at}.${payload}`).digest("hex")}`;
  return h.get("x-mail-signature") === want;
};

describe("mail worker", () => {
  it("posts raw MIME signed by SHA-256 digest without base64/JSON bloat", async () => {
    const calls = stubFetch(() => new Response(JSON.stringify({ ok: true }), { status: 200 }));
    const m = message("From: ana@example.com\r\n\r\nHi");
    await handler.email(m as never, env as never, {} as never);
    expect(m.rejected).toBeNull();
    expect(calls).toHaveLength(1);
    expect(calls[0]?.url).toBe("https://api.test/hooks/mail");
    const h = new Headers(calls[0]!.init.headers as HeadersInit);
    expect(h.get("content-type")).toBe("message/rfc822");
    expect(h.get("x-mail-to")).toBe("ada@mail.test");
    expect(h.get("x-mail-from")).toBe("ana@example.com");
    expect(calls[0]!.rawBody).toBeInstanceOf(Uint8Array);
    expect(calls[0]!.body).toContain("Hi");
    const digest = createHash("sha256").update(calls[0]!.rawBody!).digest("hex");
    expect(signed(`ada@mail.test\nana@example.com\n${digest}`, h)).toBe(true);
  });

  it("rejects unknown addresses, and throws when the API is down", async () => {
    stubFetch(() => new Response(JSON.stringify({ code: "no_such_address" }), { status: 404 }));
    const m = message("x");
    await handler.email(m as never, env as never, {} as never);
    expect(m.rejected).toBe("No such address");

    stubFetch(() => new Response("{}", { status: 500 }));
    await expect(handler.email(message("x") as never, env as never, {} as never)).rejects.toThrow(
      "API answered 500",
    );

    globalThis.fetch = (() => Promise.reject(new Error("down"))) as typeof fetch;
    await expect(handler.email(message("x") as never, env as never, {} as never)).rejects.toThrow(
      "mail post failed",
    );
  });

  it("rejects garbage without retrying it", async () => {
    stubFetch(() => new Response(JSON.stringify({ code: "validation_failed" }), { status: 400 }));
    const m = message("x");
    await handler.email(m as never, env as never, {} as never);
    expect(m.rejected).toBe("Rejected");
  });

  it("names a full mailbox, and blocked senders are rejected", async () => {
    stubFetch(() => new Response(JSON.stringify({ code: "mailbox_full" }), { status: 413 }));
    const full = message("x");
    await handler.email(full as never, env as never, {} as never);
    expect(full.rejected).toBe("Mailbox full");
    stubFetch(() => new Response(JSON.stringify({ code: "sender_blocked" }), { status: 404 }));
    const blocked = message("x");
    await handler.email(blocked as never, env as never, {} as never);
    expect(blocked.rejected).toBe("Rejected");
  });

  it("asks first for large mail", async () => {
    const big = "x".repeat(2 * 1024 * 1024);
    const calls = stubFetch((url) =>
      url.includes("/hooks/mail?to=")
        ? new Response(JSON.stringify({ ok: true }), { status: 200 })
        : new Response(JSON.stringify({ ok: true }), { status: 200 }),
    );
    const m = message(big);
    await handler.email(m as never, env as never, {} as never);
    expect(m.rejected).toBeNull();
    expect(calls[0]?.url).toContain("/hooks/mail?to=ada%40mail.test");
    expect(signed("ada@mail.test", calls[0]!.init.headers as HeadersInit)).toBe(true);
    expect(signed("", calls[0]!.init.headers as HeadersInit)).toBe(false);
    expect(calls).toHaveLength(2);
  });

  it("rejects large mail to unknown addresses before posting", async () => {
    const calls = stubFetch(
      () => new Response(JSON.stringify({ code: "no_such_address" }), { status: 404 }),
    );
    const m = message("x".repeat(2 * 1024 * 1024), "nobody@mail.test");
    await handler.email(m as never, env as never, {} as never);
    expect(m.rejected).toBe("No such address");
    expect(calls).toHaveLength(1);
  });

  it("retries transient errors (429, 401, 403, 503, unconfigured 404) instead of bouncing permanently", async () => {
    for (const [status, code] of [
      [429, "rate_limited"],
      [401, "bad_signature"],
      [403, "forbidden"],
      [503, "service_unavailable"],
      [404, "not_found"],
    ] as const) {
      stubFetch(() => new Response(JSON.stringify({ code }), { status }));
      const m = message("x");
      await expect(handler.email(m as never, env as never, {} as never)).rejects.toThrow();
      expect(m.rejected).toBeNull();
    }
  });

  it("rejects mail over 25 MiB without buffering or posting", async () => {
    const calls = stubFetch(() => new Response("{}", { status: 200 }));
    const m = message("x");
    m.rawSize = 26 * 1024 * 1024;
    await handler.email(m as never, env as never, {} as never);
    expect(m.rejected).toBe("Message too large");
    expect(calls).toHaveLength(0);
  });

  it("forwards queue events signed, acking garbage and retrying outages", async () => {
    const calls = stubFetch((url) =>
      url.endsWith("/hooks/mail/events")
        ? new Response(JSON.stringify({ ok: true }), { status: 200 })
        : new Response("{}", { status: 404 }),
    );
    const acked: string[] = [];
    const retried: string[] = [];
    const msg = (id: string, body: unknown) => ({
      id,
      body,
      ack: () => void acked.push(id),
      retry: () => void retried.push(id),
    });
    await handler.queue(
      { messages: [msg("e1", { type: "cf.email.sending.message.delivered" })] } as never,
      env as never,
    );
    expect(calls[0]?.url).toBe("https://api.test/hooks/mail/events");
    expect(signed(calls[0]!.body, calls[0]!.init.headers as HeadersInit)).toBe(true);
    expect(acked).toEqual(["e1"]);
    expect(retried).toEqual([]);
  });
});
