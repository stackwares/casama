import { sql } from "drizzle-orm";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import {
  scrubGap,
  sessionSigner,
  trimWebHistory,
  WebLimits,
} from "../src/api/routes/support-web.ts";
import { readSiteDir, SupportDocs, splitFaq } from "../src/services/support-docs.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

/** A fake OpenRouter and Turnstile: model calls get the next scripted message. */
function fakeUpstream() {
  const script: Record<string, unknown>[] = [];
  const calls: {
    messages: { role: string; content: string }[];
    tools?: { function: { name: string } }[];
    max_tokens: number;
    user?: string;
  }[] = [];
  const verifies: string[] = [];
  let verifyOk = true;
  const impl = (async (url: string, init: RequestInit) => {
    if (String(url).includes("turnstile")) {
      verifies.push(String(init.body));
      return new Response(JSON.stringify({ success: verifyOk, hostname: "casama.ai" }), {
        headers: { "content-type": "application/json" },
      });
    }
    calls.push(JSON.parse(String(init.body)));
    const message = script.shift() ?? { content: "Fallback answer." };
    return new Response(JSON.stringify({ choices: [{ message }], usage: { cost: 0.001 } }), {
      headers: { "content-type": "application/json" },
    });
  }) as unknown as typeof fetch;
  return {
    script,
    calls,
    verifies,
    impl,
    setVerify(ok: boolean) {
      verifyOk = ok;
    },
  };
}

const tool = (name: string, args: Record<string, unknown> = {}) => ({
  content: "",
  tool_calls: [{ id: `call-${name}`, function: { name, arguments: JSON.stringify(args) } }],
});

const SITE = "https://casama.ai";

describe("Casama Help on the websites (D-401)", () => {
  let h: Harness;
  const up = fakeUpstream();
  let owner: { id: string; token: string };
  let ip = 1;
  const headers = (extra: Record<string, string> = {}) => ({
    origin: SITE,
    "x-forwarded-for": `203.0.113.${ip}`,
    ...extra,
  });
  const session = async () => {
    const r = await h.request("/v1/support/web/session", {
      method: "POST",
      headers: headers(),
      json: { turnstile_token: "tok" },
    });
    expect(r.status).toBe(200);
    return (await j(r)).session as string;
  };
  const ask = (s: string, content: string, more: { role: string; content: string }[] = []) =>
    h.request("/v1/support/web/chat", {
      method: "POST",
      headers: headers(),
      json: { session: s, messages: [...more, { role: "user", content }], page: "/pricing" },
    });

  beforeAll(async () => {
    h = await startHarness({
      supportFetch: up.impl,
      env: {
        CLOUD_MODEL_UPSTREAM_KEY: "sk-test",
        SUPPORT_WEB_UPSTREAM_KEY: "sk-web",
        TURNSTILE_SITE_KEY: "site-key",
        TURNSTILE_SECRET_KEY: "secret-key",
        SUPPORT_WEB_MESSAGES_PER_DAY: "6",
        SUPPORT_WEB_DAILY_USD: "1",
        DOCS_URL: "http://docs.invalid",
      },
    });
    owner = await h.user("owner-web@example.com");
  });
  afterAll(() => h?.stop());
  beforeEach(async () => {
    ip++;
    WebLimits.perMinute = 1000;
    WebLimits.perSession = 8;
    up.script.length = 0;
    up.calls.length = 0;
    up.verifies.length = 0;
    up.setVerify(true);
    await h.handle.db.execute(sql`delete from public.support_usage`);
    await h.handle.db.execute(sql`delete from public.support_web_gaps`);
  });

  it("tells the widget it answers, with the Turnstile site key, signed out", async () => {
    const r = await h.request("/v1/support/web/config", { headers: headers() });
    expect(r.status).toBe(200);
    expect(await j(r)).toMatchObject({ assistant: true, turnstile_site_key: "site-key" });
  });

  it("answers from the docs with its own key, three account-free tools, and real sources only", async () => {
    const s = await session();
    expect(up.verifies[0]).toContain("secret=secret-key");
    up.script.push(tool("search_docs", { query: "credits plan" }), {
      content: "Credits pay for models.\n\nSources: https://made.up/page",
    });
    const r = await ask(s, "What do credits pay for?");
    expect(r.status).toBe(200);
    const body = await j(r);
    expect(body.reply).toBe("Credits pay for models.");
    expect(body.sources).toEqual([]);
    const first = up.calls[0];
    expect(first?.tools?.map((t) => t.function.name).sort()).toEqual([
      "decline_off_topic",
      "get_plans",
      "note_gap",
      "search_docs",
    ]);
    expect(first?.max_tokens).toBe(WebLimits.maxTokens);
    expect(first?.messages[0]?.content).toContain("can't see any account");
    expect(first?.messages[0]?.content).toContain("on /pricing");
    // casama.ai's own pages are in what it searches.
    const tool1 = up.calls[1]?.messages.find((m) => m.role === "tool");
    expect(tool1?.content).toBeTruthy();
  });

  it("refuses without a passed check, from other sites, and with a forged or moved session", async () => {
    up.setVerify(false);
    const bad = await h.request("/v1/support/web/session", {
      method: "POST",
      headers: headers(),
      json: { turnstile_token: "tok" },
    });
    expect(bad.status).toBe(403);
    expect((await j(bad)).code).toBe("turnstile_failed");
    up.setVerify(true);

    const other = await h.request("/v1/support/web/session", {
      method: "POST",
      headers: headers({ origin: "https://evil.example" }),
      json: { turnstile_token: "tok" },
    });
    expect(other.status).toBe(403);
    expect((await j(other)).code).toBe("origin_not_allowed");

    const s = await session();
    const forged = `${s.slice(0, -3)}abc`;
    expect((await ask(forged, "hi")).status).toBe(401);
    ip++;
    const moved = await ask(s, "hi");
    expect(moved.status).toBe(401);
    expect((await j(moved)).code).toBe("web_session_invalid");
    expect(up.calls.length).toBe(0);
  });

  it("keeps questions it couldn't answer without anything personal", async () => {
    const s = await session();
    up.script.push(
      tool("note_gap", {
        question: "Do you support Klingon? mail me at a@b.co or +1 555 123 4567",
      }),
      { content: "I'm not sure." },
    );
    expect((await ask(s, "Do you support Klingon?")).status).toBe(200);
    const rows = await h.handle.db.execute<{ question: string; page: string }>(
      sql`select question, page from public.support_web_gaps`,
    );
    expect(rows[0]?.question).toBe("Do you support Klingon? mail me at [email] or [number]");
    expect(rows[0]?.page).toBe("/pricing");

    const stats = await j(await h.request("/v1/admin/support-web", { token: owner.token }));
    expect(stats.on).toBe(true);
    expect(stats.messages_today).toBe(1);
    expect(stats.gaps[0].question).toContain("Klingon");
    expect((await h.request("/v1/admin/support-web")).status).toBe(401);
  });

  it("pauses an address after three off-topic requests", async () => {
    const s = await session();
    for (let i = 0; i < 3; i++) {
      up.script.push(tool("decline_off_topic"), { content: "I can only help with Casama." });
      expect((await ask(s, "write my essay")).status).toBe(200);
    }
    const r = await ask(s, "and now?");
    expect(r.status).toBe(429);
    expect((await j(r)).code).toBe("support_paused");
    const again = await h.request("/v1/support/web/session", {
      method: "POST",
      headers: headers(),
      json: { turnstile_token: "tok" },
    });
    expect(again.status).toBe(429);
  });

  it("caps a session, an address's day and everyone's budget", async () => {
    WebLimits.perSession = 2;
    let s = await session();
    expect((await ask(s, "one")).status).toBe(200);
    expect((await ask(s, "two")).status).toBe(200);
    expect((await ask(s, "three")).status).toBe(429);

    WebLimits.perSession = 100;
    s = await session();
    for (let i = 0; i < 4; i++) expect((await ask(s, `q${i}`)).status).toBe(200);
    const capped = await ask(s, "seventh");
    expect(capped.status).toBe(429);
    expect((await j(capped)).code).toBe("support_limit");

    ip++;
    await h.handle.db.execute(sql`
      insert into public.support_usage (key, usd) values ('web:all', 1)
      on conflict (key, day) do update set usd = 1`);
    const busy = await ask(await session(), "hello");
    expect(busy.status).toBe(429);
    expect((await j(busy)).code).toBe("support_busy_global");
  });

  it("rejects a long message and a conversation that ends with its own answer", async () => {
    const s = await session();
    expect((await ask(s, "x".repeat(WebLimits.messageChars + 1))).status).toBe(400);
    const r = await h.request("/v1/support/web/chat", {
      method: "POST",
      headers: headers(),
      json: {
        session: s,
        messages: [
          { role: "user", content: "hi" },
          { role: "assistant", content: "hello" },
        ],
      },
    });
    expect(r.status).toBe(400);
  });

  it("links only public places using https://casama.ai/open and strips private ones", async () => {
    const s = await session();
    up.script.push({
      content:
        "Open [Privacy & data](place:privacy?highlight=export), check [Apple](place:store_subscriptions_apple), or [Bot](place:bot_settings?botId=11111111-1111-4111-8111-111111111111).",
    });
    const r = await ask(s, "how do I export my data or cancel?");
    expect(r.status).toBe(200);
    const body = await j(r);
    expect(up.calls[0]?.messages[0]?.content).toContain("Clickable places");
    expect(up.calls[0]?.messages[0]?.content).not.toContain("`bot_settings`");
    expect(body.reply).toBe(
      "Open [Privacy & data](https://casama.ai/open/settings/privacy?highlight=export), check [Apple](https://apps.apple.com/account/subscriptions), or Bot.",
    );
    expect(body.places).toEqual([
      {
        id: "privacy",
        label: "Privacy & data",
        url: "https://casama.ai/open/settings/privacy?highlight=export",
      },
      {
        id: "store_subscriptions_apple",
        label: "Apple subscriptions",
        url: "https://apps.apple.com/account/subscriptions",
      },
    ]);
  });
});

describe("website assistant helpers (D-401)", () => {
  it("signs sessions to one address and expiry", () => {
    const signer = sessionSigner(Buffer.alloc(32, 1));
    const { session } = signer.issue("abc", 1_000);
    expect(signer.check(session, "abc", 2_000)).toBeTruthy();
    expect(signer.check(session, "abd", 2_000)).toBeNull();
    expect(signer.check(session, "abc", 1_000 + WebLimits.sessionMs + 1)).toBeNull();
    expect(sessionSigner(Buffer.alloc(32, 2)).check(session, "abc", 2_000)).toBeNull();
    expect(signer.check("nonsense", "abc")).toBeNull();
  });

  it("keeps the newest messages, cut to size, starting with the visitor's", () => {
    const msgs = Array.from({ length: 12 }, (_, i) => ({
      role: (i % 2 ? "assistant" : "user") as "user" | "assistant",
      content: `m${i}`,
    }));
    const out = trimWebHistory(msgs);
    expect(out.length).toBeLessThanOrEqual(WebLimits.historyMessages);
    expect(out[0]?.role).toBe("user");
    expect(out.at(-1)?.content).toBe("m11");
    expect(trimWebHistory([{ role: "user", content: "y".repeat(5000) }])[0]?.content.length).toBe(
      WebLimits.messageChars,
    );
  });

  it("takes emails, links and phone numbers out of saved questions", () => {
    expect(scrubGap("ping x.y+z@mail.example.com about https://a.b/c, tel (02) 8123-4567")).toBe(
      "ping [email] about [link] tel [number]",
    );
  });

  it("knows casama.ai's explainers and finds a single FAQ answer", async () => {
    const site = readSiteDir(new URL("../../../site/content/", import.meta.url).pathname);
    expect(site.some((p) => p.url === "https://casama.ai/pricing")).toBe(true);
    expect(site.some((p) => p.url.startsWith("https://casama.ai/learn/"))).toBe(true);
    expect(site.every((p) => !p.body.includes("\nupdated:"))).toBe(true);
    const faq = splitFaq([
      {
        url: "https://docs.x/faq",
        title: "FAQ",
        body: "# FAQ\n\n## Billing\n\n### How do I cancel?\n\nIn the store you bought it in, from its subscriptions page settings.\n",
      },
    ]);
    expect(faq[0]?.body).toContain("## How do I cancel?");
    const docs = new SupportDocs({
      docsUrl: "http://docs.invalid",
      refreshMs: Number.POSITIVE_INFINITY,
    });
    const idx = await docs.current();
    expect(idx.pages.some((p) => p.url === "https://casama.ai/pricing")).toBe(true);
    expect(idx.search("cancel refund", 3).length).toBeGreaterThan(0);
  });
});
