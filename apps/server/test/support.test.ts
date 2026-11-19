import { sql } from "drizzle-orm";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { Limits, meaningfulSupportMessage, trimHistory } from "../src/api/routes/support.ts";
import { DocIndex, parseLlmsFull, readDocsDir, SupportDocs } from "../src/services/support-docs.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

/** A fake OpenRouter: answers each call with the next scripted message and records the requests. */
function fakeModel() {
  const script: Record<string, unknown>[] = [];
  const calls: {
    messages: { role: string; content: string }[];
    tools?: unknown[];
    max_tokens: number;
    provider?: Record<string, unknown>;
  }[] = [];
  const impl = (async (_url: string, init: RequestInit) => {
    calls.push(JSON.parse(String(init.body)));
    const message = script.shift() ?? { content: "Fallback answer." };
    return new Response(JSON.stringify({ choices: [{ message }], usage: { cost: 0.001 } }), {
      headers: { "content-type": "application/json" },
    });
  }) as unknown as typeof fetch;
  return { script, calls, impl };
}

const tool = (name: string, args: Record<string, unknown> = {}) => ({
  content: "",
  tool_calls: [{ id: `call-${name}`, function: { name, arguments: JSON.stringify(args) } }],
});

describe("support assistant and tickets (D-298)", () => {
  let h: Harness;
  const model = fakeModel();
  let person: { id: string; token: string };
  let stranger: { id: string; token: string };
  let orgId: string;
  const ask = (token: string, content: string, extra: Record<string, unknown> = {}) =>
    h.request("/v1/support/chat", {
      method: "POST",
      token,
      json: {
        org_id: orgId,
        messages: [{ role: "user", content }],
        app_version: "0.1.0 (18)",
        platform: "iOS",
        ...extra,
      },
    });

  beforeAll(async () => {
    h = await startHarness({
      email: true,
      supportFetch: model.impl,
      env: {
        CLOUD_MODEL_UPSTREAM_KEY: "sk-test",
        SUPPORT_MESSAGES_PER_DAY: "8",
        SUPPORT_TICKETS_PER_DAY: "6",
        DOCS_URL: "http://docs.invalid",
      },
    });
    person = await h.user("help-me@example.com");
    stranger = await h.user("stranger@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: person.token,
          json: { name: "Help Co" },
        }),
      )
    ).id;
  });
  afterAll(() => h?.stop());
  beforeEach(async () => {
    // Each test starts with a fresh minute; the per-minute cap has its own test.
    Limits.perMinute = 1000;
    model.script.length = 0;
    model.calls.length = 0;
    await h.handle.db.execute(sql`delete from public.support_usage`);
  });

  it("says what it offers", async () => {
    const r = await j(await h.request("/v1/support", { token: person.token }));
    expect(r).toMatchObject({ assistant: true, tickets: true, email: "support@casama.ai" });
  });

  it("answers from the docs and the person's own workspace, with sources", async () => {
    model.script.push(
      tool("search_docs", { query: "restore purchases payments" }),
      tool("get_account"),
      {
        content:
          "Tap **Restore Purchases** on the Billing page.\n\nSources: __URL__, https://made.up/page",
      },
    );
    // Cite a section the search will really return, plus one it never saw.
    const real = (await import("../src/services/support-docs.ts")).readDocsDir(
      new URL("../../../docs-site/", import.meta.url).pathname,
      "http://docs.invalid",
    );
    const hit = new (await import("../src/services/support-docs.ts")).DocIndex(real).search(
      "restore purchases payments",
      5,
    )[0];
    (model.script[2] as { content: string }).content = (
      model.script[2] as { content: string }
    ).content.replace("__URL__", hit?.url ?? "");
    const res = await ask(person.token, "I paid but my plan didn't change");
    expect(res.status).toBe(200);
    const r = await j(res);
    expect(r.reply).toContain("Restore Purchases");
    expect(r.reply).not.toContain("Sources");
    // Only the link the search returned survives.
    expect(r.sources).toEqual([{ url: hit?.url, title: hit?.title }]);
    expect(r.handoff).toBeNull();
    // The account lookup saw this workspace and this person.
    const account = model.calls[2]?.messages.find(
      (m) => m.role === "tool" && m.content.includes("purchase_customer_id"),
    );
    expect(account?.content).toContain(orgId);
    expect(account?.content).toContain("help-me@example.com");
    // The system prompt is fenced to Casama and tells the model about the build.
    expect(model.calls[0]?.messages[0]?.content).toContain("Only Casama");
    expect(model.calls[0]?.messages[0]?.content).toContain("0.1.0 (18) on iOS");
    expect(model.calls[0]?.max_tokens).toBe(Limits.maxTokens);
    // Every round goes to the cheapest provider first, so its prompt cache holds (D-354).
    expect(model.calls.map((c) => c.provider)).toEqual([
      { sort: "price" },
      { sort: "price" },
      { sort: "price" },
    ]);
  });

  it("never looks into a workspace the person isn't in", async () => {
    model.script.push(tool("get_account"), { content: "ok" });
    await ask(stranger.token, "what plan am I on?");
    const account = model.calls[1]?.messages.find((m) => m.role === "tool");
    expect(account?.content).not.toContain(orgId);
    expect(account?.content).toContain('"workspace":null');
  });

  it("hands off to a person with a summary", async () => {
    model.script.push(tool("hand_off", { topic: "billing", summary: "Charged twice for Plus." }), {
      content: "I've written this up for our team.",
    });
    const r = await j(await ask(person.token, "I was charged twice, I want a refund"));
    expect(r.handoff).toEqual({ topic: "billing", summary: "Charged twice for Plus." });
  });

  it("stops after a few tool rounds", async () => {
    for (let i = 0; i < 10; i++) model.script.push(tool("search_docs", { query: "x" }));
    model.script.push({ content: "done" });
    await ask(person.token, "loop please");
    expect(model.calls.length).toBe(Limits.toolRounds + 1);
    // The last round can't call tools.
    expect(model.calls.at(-1)?.tools).toBeUndefined();
  });

  it("pauses for a day after repeated off-topic requests", async () => {
    for (let i = 0; i < Limits.strikesBeforePause; i++) {
      model.script.push(tool("decline_off_topic"), { content: "I can only help with Casama." });
      expect((await ask(person.token, "write my essay")).status).toBe(200);
    }
    const res = await ask(person.token, "how do I make a bot?");
    expect(res.status).toBe(429);
    expect((await j(res)).code).toBe("support_paused");
  });

  it("caps messages a day per person and spending for everyone", async () => {
    await h.handle.db.execute(
      sql`insert into public.support_usage (key, messages) values (${`u:${person.id}`}, 8)`,
    );
    expect((await j(await ask(person.token, "hi"))).code).toBe("support_limit");
    await h.handle.db.execute(sql`delete from public.support_usage`);
    await h.handle.db.execute(sql`insert into public.support_usage (key, usd) values ('all', 10)`);
    expect((await j(await ask(person.token, "hi"))).code).toBe("support_busy_global");
    expect(model.calls.length).toBe(0);
  });

  it("caps a person's spending and counts what each answer cost", async () => {
    model.script.push({ content: "hello" });
    await ask(person.token, "hi");
    const [row] = await h.handle.db.execute<{ messages: number; usd: string }>(
      sql`select messages, usd from public.support_usage where key = ${`u:${person.id}`}`,
    );
    expect(row).toMatchObject({ messages: 1 });
    expect(Number(row?.usd)).toBeCloseTo(0.001);
    await h.handle.db.execute(
      sql`update public.support_usage set usd = ${Limits.personDailyUsd} where key = ${`u:${person.id}`}`,
    );
    expect((await ask(person.token, "hi")).status).toBe(429);
  });

  it("allows only a few messages a minute", async () => {
    Limits.perMinute = 2;
    const other = await h.user("quick@example.com");
    model.script.push({ content: "a" }, { content: "b" });
    expect((await ask(other.token, "1")).status).toBe(200);
    expect((await ask(other.token, "2")).status).toBe(200);
    expect((await j(await ask(other.token, "3"))).code).toBe("rate_limited");
  });

  it("turns guests away", async () => {
    const guest = await h.user("guest@example.com", { is_anonymous: true });
    expect((await ask(guest.token, "hi")).status).toBe(403);
  });

  it("emails the support inbox with reply-to, ids and the transcript, and caps tickets", async () => {
    h.outbox.length = 0;
    const send = (more = "Please help.", token = person.token) =>
      h.request("/v1/support/tickets", {
        method: "POST",
        token,
        json: {
          org_id: orgId,
          topic: "billing",
          message: `Charged twice for Plus.\n${more}`,
          transcript: [
            { role: "user", content: "I was charged twice" },
            { role: "assistant", content: "Let me pass this on." },
          ],
          app_version: "0.1.0 (18)",
          platform: "Android",
        },
      });
    // Gibberish never reaches the inbox, and doesn't count against the person's limits.
    const junk = await h.request("/v1/support/tickets", {
      method: "POST",
      token: person.token,
      json: { org_id: orgId, topic: "other", message: "asdf sdfkj lkjh qwrt" },
    });
    expect(junk.status).toBe(400);
    expect((await j(junk)).code).toBe("ticket_too_short");
    expect(h.outbox).toHaveLength(0);
    const r = await j(await send());
    expect(r.reference).toMatch(/^C-[2-9A-Z]{6}$/);
    expect(r.reply_to).toBe("help-me@example.com");
    const mail = h.outbox.find((m) => m.to === "support@casama.ai");
    expect(mail?.replyTo).toBe("help-me@example.com");
    expect(mail?.subject).toBe(`[billing] Charged twice for Plus. (${r.reference})`);
    expect(mail?.text).toContain(`RevenueCat customer: ${orgId}`);
    expect(mail?.text).toContain(`Account ID: ${person.id}`);
    expect(mail?.text).toContain("Person: I was charged twice");
    expect(mail?.text).toContain("0.1.0 (18) on Android");
    // The same message again, or another one straight away, doesn't go out.
    const again = await send("Please  HELP.");
    expect(again.status).toBe(409);
    expect((await j(again)).code).toBe("ticket_duplicate");
    const soon = await send("Still waiting.");
    expect(soon.status).toBe(429);
    expect((await j(soon)).code).toBe("ticket_cooldown");
    // Without the gap, the daily cap per person stops them.
    const gap = Limits.ticketGapMs;
    Limits.ticketGapMs = 0;
    try {
      for (let i = 1; i < Limits.ticketsPerDay; i++)
        expect((await send(`Try ${i}.`)).status).toBe(200);
      const capped = await send("One more.");
      expect(capped.status).toBe(429);
      expect((await j(capped)).code).toBe("ticket_limit");
      // And the cap for everyone together (6 here) stops other accounts too.
      expect((await send("Mine too.", stranger.token)).status).toBe(200);
      const full = await send("Me again.", stranger.token);
      expect(full.status).toBe(429);
      expect((await j(full)).code).toBe("ticket_limit_global");
    } finally {
      Limits.ticketGapMs = gap;
    }
  });

  it("keeps a log of tickets: the owners list and close them, and Casama Help finds them (D-303)", async () => {
    // The first account is the instance owner here.
    const list = await j(await h.request("/v1/admin/support-tickets", { token: person.token }));
    expect(list.items.length).toBeGreaterThan(0);
    const t = list.items.find(
      (i: { user_email: string }) => i.user_email === "help-me@example.com",
    );
    expect(t).toMatchObject({
      topic: "billing",
      subject: "Charged twice for Plus.",
      status: "open",
      user_email: "help-me@example.com",
    });
    expect((await h.request("/v1/admin/support-tickets", { token: stranger.token })).status).toBe(
      403,
    );
    const closed = await j(
      await h.request(`/v1/admin/support-tickets/${t.reference}`, {
        method: "POST",
        token: person.token,
        json: { status: "closed" },
      }),
    );
    expect(closed.status).toBe("closed");
    model.script.push(tool("get_my_tickets"), { content: "Yes, we got it." });
    await ask(person.token, "did you get my message?");
    const result = model.calls[1]?.messages.find((m) => m.role === "tool");
    expect(result?.content).toContain(t.reference);
  });

  it("looks up usage, connections, a bot and invites, never someone else's private things", async () => {
    const db = h.handle.db;
    const mate = await h.user("teammate@example.com");
    await db.execute(
      sql`insert into public.memberships (org_id, user_id, role) values (${orgId}::uuid, ${mate.id}::uuid, 'member')`,
    );
    const [team] = await db.execute<{ id: string }>(sql`
      insert into public.bots (org_id, name, created_by, visibility) values (${orgId}::uuid, 'Ledger Bot', ${person.id}::uuid, 'team') returning id`);
    const [secret] = await db.execute<{ id: string }>(sql`
      insert into public.bots (org_id, name, created_by, visibility) values (${orgId}::uuid, 'Secret Bot', ${mate.id}::uuid, 'private') returning id`);
    await db.execute(sql`
      insert into public.usage_ledger (org_id, bot_id, kind, quantity, cost_usd, billable) values
        (${orgId}::uuid, ${team!.id}::uuid, 'tokens_in', 1000, 0.40, true),
        (${orgId}::uuid, ${secret!.id}::uuid, 'tokens_in', 500, 0.25, true),
        (${orgId}::uuid, ${team!.id}::uuid, 'computer_seconds', 5400, 0.10, true)`);
    await db.execute(sql`
      insert into public.runs (org_id, bot_id, status, error, created_by) values
        (${orgId}::uuid, ${team!.id}::uuid, 'failed', '{"code":"credits_exhausted","message":"Out of credits."}', ${person.id}::uuid),
        (${orgId}::uuid, ${secret!.id}::uuid, 'failed', '{"code":"secret_failure","message":"Private bot broke."}', ${mate.id}::uuid)`);
    await db.execute(sql`
      insert into public.routines (org_id, bot_id, name, instructions_md, schedule_cron, timezone, next_run_at)
      values (${orgId}::uuid, ${team!.id}::uuid, 'Morning digest', 'Summarize', '0 8 * * *', 'Asia/Manila', now() + interval '1 day')`);
    const [app] = await db.execute<{ id: string }>(sql`
      insert into public.integrations (org_id, kind, name, status, error, config)
      values (${orgId}::uuid, 'mcp', 'gmail', 'error', 'token expired', '{"api_key":"must-not-leak"}') returning id`);
    await db.execute(
      sql`insert into public.bot_integrations (org_id, bot_id, integration_id) values (${orgId}::uuid, ${team!.id}::uuid, ${app!.id}::uuid)`,
    );
    await db.execute(sql`
      insert into public.channels (org_id, bot_id, kind, name, last_error) values
        (${orgId}::uuid, ${team!.id}::uuid, 'telegram', 'Team chat', 'bot was blocked'),
        (${orgId}::uuid, ${secret!.id}::uuid, 'telegram', 'Hidden chat', null)`);
    await db.execute(sql`
      insert into public.model_credentials (org_id, provider, label, owner_user_id) values
        (${orgId}::uuid, 'openai', 'Team key', null),
        (${orgId}::uuid, 'anthropic', 'Mate personal key', ${mate.id}::uuid)`);
    const [other] = await db.execute<{ id: string }>(
      sql`insert into public.organizations (name, slug) values ('Other Co', 'other-co') returning id`,
    );
    await db.execute(sql`
      insert into public.invites (org_id, email, role, token_hash, expires_at) values
        (${other!.id}::uuid, 'teammate@example.com', 'member', 'h1', now() + interval '3 days'),
        (${orgId}::uuid, 'newbie@example.com', 'member', 'h2', now() + interval '3 days')`);
    await db.execute(
      sql`insert into public.join_requests (org_id, user_id) values (${other!.id}::uuid, ${mate.id}::uuid)`,
    );

    const results = async (token: string, calls: [string, Record<string, unknown>?][]) => {
      model.script.length = 0;
      model.calls.length = 0;
      model.script.push(
        {
          content: "",
          tool_calls: calls.map(([name, args], i) => ({
            id: `c${i}`,
            function: { name, arguments: JSON.stringify(args ?? {}) },
          })),
        },
        { content: "ok" },
      );
      expect((await ask(token, "my bot stopped and I'm out of credits?")).status).toBe(200);
      const msgs = model.calls[1]?.messages as {
        role: string;
        content: string;
        tool_call_id?: string;
      }[];
      return calls.map((_, i) => msgs.find((m) => m.tool_call_id === `c${i}`)?.content ?? "");
    };

    // The owner.
    const [usage, conns, bot, invites, problems, hidden, account] = await results(person.token, [
      ["get_usage"],
      ["get_connections"],
      ["get_bot", { name: "ledger" }],
      ["get_invites"],
      ["get_recent_problems"],
      ["get_bot", { name: "Secret" }],
      ["get_account"],
    ]);
    // Past the per-round cap, calls are dropped from the assistant message too, so every call
    // the model sees has its reply.
    expect(account).toBe("");
    const sent = model.calls[1]?.messages.find((m) => m.role === "assistant") as unknown as {
      tool_calls: unknown[];
    };
    expect(sent.tool_calls).toHaveLength(Limits.callsPerRound);
    const u = JSON.parse(usage ?? "");
    expect(u.spent_usd).toBe(0.75);
    expect(u.by_bot).toEqual(
      expect.arrayContaining([
        { bot: "Ledger Bot", usd: 0.5 },
        { bot: "a private bot", usd: 0.25 },
      ]),
    );
    expect(u.bots.used).toBe(2);
    expect(u.seats.used).toBe(2);
    expect(u.computer_hours.used).toBe(1.5);
    expect(u.stopped_runs_last_7_days).toEqual([
      expect.objectContaining({ reason: "credits_exhausted", runs: 1 }),
    ]);
    expect(usage).not.toContain("Secret Bot");
    expect(usage).not.toContain("secret_failure");

    expect(conns).toContain("token expired");
    expect(conns).toContain("bot was blocked");
    expect(conns).toContain("Team key");
    expect(conns).not.toContain("must-not-leak");
    expect(conns).not.toContain("Hidden chat");
    expect(conns).not.toContain("Mate personal key");

    expect(bot).toContain("Morning digest");
    expect(bot).toContain("Asia/Manila");
    expect(bot).toContain("gmail");
    expect(bot).toContain("credits_exhausted");
    expect(hidden).toContain("No bot by that name");
    expect(problems).not.toContain("Secret Bot");

    const inv = JSON.parse(invites ?? "");
    expect(inv.open_workspace.invites_not_accepted).toEqual([
      expect.objectContaining({ email: "newbie@example.com", state: "waiting" }),
    ]);
    const [account2] = await results(person.token, [["get_account"]]);
    const acct = JSON.parse(account2 ?? "{}");
    expect(acct.account.sign_in_methods).toBeInstanceOf(Array);
    expect(acct.workspace).toHaveProperty("limits");

    // A member sees their own private bot and key, and their own invites, but no admin lists.
    const [mineBot, mineConns, mineInvites] = await results(mate.token, [
      ["get_bot", { name: "Secret Bot" }],
      ["get_connections"],
      ["get_invites"],
    ]);
    expect(mineBot).toContain("secret_failure");
    expect(mineConns).toContain("Mate personal key");
    const mi = JSON.parse(mineInvites ?? "");
    expect(mi.invites_to_me).toEqual([
      expect.objectContaining({ workspace: "Other Co", state: "waiting" }),
    ]);
    expect(mi.my_join_requests).toEqual([
      expect.objectContaining({ workspace: "Other Co", status: "pending" }),
    ]);
    expect(mi.open_workspace).toBeUndefined();
  });

  it("links places only when requested, gates roles/botIds, and keeps legacy clients safe", async () => {
    // Without features: ["places"], places aren't in the prompt and stray place links are stripped.
    model.script.push({
      content:
        "Open [Privacy](place:privacy?highlight=export) or [Raw](casama://app/settings/privacy).",
    });
    const legacy = await j(await ask(person.token, "where do I export my data?"));
    expect(model.calls[0]?.messages[0]?.content).not.toContain("Clickable places");
    expect(legacy.reply).toBe("Open Privacy or Raw.");
    expect(legacy.places).toEqual([]);

    // With features: ["places"], owner gets privacy + domains + verified bot from get_bot,
    // while unverified botIds and raw casama:// links are stripped.
    model.script.length = 0;
    model.calls.length = 0;
    // First find Ledger Bot's id from DB so scripted reply can cite it.
    const [ledger] = await h.handle.db.execute<{ id: string }>(
      sql`select id from public.bots where org_id = ${orgId}::uuid and name = 'Ledger Bot' limit 1`,
    );
    const botId = ledger?.id ?? "";
    const forgedId = "99999999-9999-4999-8999-999999999999";
    // Self-hosted (billing disabled) omits cloudOnly places like domains, while allowing bot_settings & privacy.
    model.script.length = 0;
    model.calls.length = 0;
    model.script.push(tool("get_bot", { name: "Ledger Bot" }), {
      content:
        `Check [Bot Settings](place:bot_settings?botId=${botId}), [Domains](place:domains), ` +
        `[Secret](place:bot_settings?botId=${forgedId}), and [Privacy](place:privacy?highlight=export).`,
    });
    const selfHosted = await j(
      await ask(person.token, "where do I rename Ledger Bot?", { features: ["places"] }),
    );
    expect(model.calls[0]?.messages[0]?.content).toContain("Clickable places");
    expect(selfHosted.reply).toBe(
      `Check [Bot Settings](casama://app/bots/${botId}/settings), Domains, Secret, and [Privacy](casama://app/settings/privacy?highlight=export).`,
    );
    expect(selfHosted.places).toEqual([
      {
        id: "bot_settings",
        label: "Bot settings",
        route: `/bots/${botId}/settings`,
        url: `casama://app/bots/${botId}/settings`,
      },
      {
        id: "privacy",
        label: "Privacy & data",
        route: "/settings/privacy?highlight=export",
        url: "casama://app/settings/privacy?highlight=export",
      },
    ]);

    // On Casama Cloud, owners/admins see cloudOnly + admin-only places like domains, while members don't.
    const billingMut = h.deps.billing as { enabled: boolean };
    const prevBilling = billingMut.enabled;
    billingMut.enabled = true;
    try {
      model.script.length = 0;
      model.calls.length = 0;
      model.script.push({ content: "Open [Domains](place:domains)." });
      const ownerCloud = await j(
        await ask(person.token, "how do I verify a domain?", { features: ["places"] }),
      );
      expect(ownerCloud.reply).toBe("Open [Domains](casama://app/settings/domains).");
      expect(ownerCloud.places).toEqual([
        {
          id: "domains",
          label: "Domains",
          route: "/settings/domains",
          url: "casama://app/settings/domains",
        },
      ]);

      const mate2 = await h.user("teammate2@example.com");
      await h.handle.db.execute(
        sql`insert into public.memberships (org_id, user_id, role) values (${orgId}::uuid, ${mate2.id}::uuid, 'member')`,
      );
      model.script.length = 0;
      model.calls.length = 0;
      model.script.push({ content: "See [Domains](place:domains) or [Privacy](place:privacy)." });
      const memberRes = await j(
        await ask(mate2.token, "how do I verify a domain?", { features: ["places"] }),
      );
      expect(model.calls[0]?.messages[0]?.content).not.toContain("`domains`");
      expect(memberRes.reply).toBe("See Domains or [Privacy](casama://app/settings/privacy).");
      expect(memberRes.places).toEqual([
        {
          id: "privacy",
          label: "Privacy & data",
          route: "/settings/privacy",
          url: "casama://app/settings/privacy",
        },
      ]);
    } finally {
      billingMut.enabled = prevBilling;
    }
  });
});

describe("support docs index", () => {
  it("reads the bundled docs and finds the right section", () => {
    const pages = readDocsDir(
      new URL("../../../docs-site/", import.meta.url).pathname,
      "https://docs.casama.ai",
    );
    expect(pages.length).toBeGreaterThan(20);
    expect(pages.some((p) => p.url === "https://docs.casama.ai/guide/bots")).toBe(true);
    const index = new DocIndex(pages);
    const hits = index.search("cancel subscription refund");
    expect(hits.length).toBeGreaterThan(0);
    expect(index.outline()).toContain("https://docs.casama.ai/faq");
  });

  it("parses llms-full.txt and swaps it in, but never for a broken copy", async () => {
    const text = Array.from(
      { length: 6 },
      (_, i) =>
        `<!-- page: https://docs.example/p${i} -->\n# Page ${i}\n\n## Billing ${i}\n\nThe zebra plan renews monthly in workspace ${i}.`,
    ).join("\n");
    expect(parseLlmsFull(text)).toHaveLength(6);
    let body = text;
    let t = 0;
    const docs = new SupportDocs({
      siteDir: "",
      docsUrl: "https://docs.example",
      dir: "/nonexistent",
      now: () => t,
      refreshMs: 10,
      fetchImpl: (async () => new Response(body)) as unknown as typeof fetch,
    });
    t = 100;
    expect((await docs.current()).search("zebra").length).toBeGreaterThan(0);
    body = "<!-- page: https://docs.example/x -->\n# Broken";
    t = 200;
    await docs.current();
    await new Promise((r) => setTimeout(r, 10));
    expect((await docs.current()).pages).toHaveLength(6);
  });

  it("keeps the newest messages that fit, starting with the person's", () => {
    const msgs = Array.from(
      { length: 30 },
      (_, i) => ({ role: i % 2 ? "assistant" : "user", content: `m${i}` }) as const,
    );
    const kept = trimHistory([...msgs, { role: "user", content: "last" }]);
    expect(kept.length).toBeLessThanOrEqual(Limits.historyMessages);
    expect(kept[0]?.role).toBe("user");
    expect(kept.at(-1)?.content).toBe("last");
  });
});

describe("what counts as a message to support", () => {
  it("takes a sentence or two and turns away gibberish", () => {
    expect(meaningfulSupportMessage("My bot stopped answering after I connected Gmail.")).toBe(
      true,
    );
    expect(meaningfulSupportMessage("I was charged twice for Plus this month")).toBe(true);
    expect(meaningfulSupportMessage("Charged twice for Plus.\nPlease help.")).toBe(true);
    expect(meaningfulSupportMessage("help")).toBe(false);
    expect(meaningfulSupportMessage("it doesn't work")).toBe(false);
    expect(meaningfulSupportMessage("asdfghjkl qwertyuiop")).toBe(false);
    expect(meaningfulSupportMessage("asdf sdfkj lkjh qwrt zxcv")).toBe(false);
    expect(meaningfulSupportMessage("test test test test test test")).toBe(false);
    expect(meaningfulSupportMessage("1234567890 !!!! ???? ....")).toBe(false);
    // Scripts without spaces or Latin vowels need only a few words' worth of letters.
    expect(meaningfulSupportMessage("請幫我看看為什麼我的機器人沒有回覆")).toBe(true);
    expect(meaningfulSupportMessage("請幫我")).toBe(false);
  });
});
