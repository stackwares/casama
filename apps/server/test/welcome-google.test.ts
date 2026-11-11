/** Welcome chat, Google first (D-204): the Google card after the name, the catch-up once it's really connected. */
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/welcome-google.json", import.meta.url));
let h: Harness;
let composio: Server;
/** What Composio says about the Google Calendar account: none yet, still signing in, or active. */
let calendar: "none" | "INITIATED" | "ACTIVE" = "none";
let gail: { id: string; token: string };
let w: { org_id: string; bot_id: string; conversation_id: string };

type Part = { type: string; text?: string; surface_id?: string; messages?: unknown[] };
const settle = async () => {
  let quiet = 0;
  for (let i = 0; i < 600 && quiet < 3; i++) {
    const [r] = await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.runs where status in ('queued', 'running')`;
    quiet = r?.n ? 0 : quiet + 1;
    await new Promise((res) => setTimeout(res, 100));
  }
};
const last = async () => {
  const [m] = await h.tdb.admin<
    { content: Part[] }[]
  >`select content from public.messages where conversation_id = ${w.conversation_id} and role = 'assistant' order by created_at desc limit 1`;
  return m?.content ?? [];
};
type Component = Record<string, unknown> & {
  action?: { event?: { name: string; context?: Record<string, unknown> } };
};
const components = (parts: Part[]) =>
  parts.flatMap((p) =>
    ((p.messages ?? []) as Array<{ updateComponents?: { components?: Component[] } }>).flatMap(
      (m) => m.updateComponents?.components ?? [],
    ),
  );
const actions = (parts: Part[]) => components(parts).flatMap((c) => c.action?.event ?? []);
const surface = (parts: Part[]) => parts.find((p) => p.type === "ui")?.surface_id as string;
const act = async (parts: Part[], name: string, context: Record<string, unknown>, text = name) =>
  j(
    await h.request(`/v1/conversations/${w.conversation_id}/messages`, {
      method: "POST",
      token: gail.token,
      json: { text, ui_action: { surface_id: surface(parts), name, context } },
    }),
  );
/** A model key, so the cards that wait for a model don't come first. */
const addKey = async (token: string, orgId: string) => {
  await h.request("/v1/credentials", {
    method: "POST",
    token,
    json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
  });
};
const step = async () => {
  const [c] = await h.tdb.admin<
    { step: string }[]
  >`select welcome ->> 'step' as step from public.conversations where id = ${w.conversation_id}`;
  return c?.step;
};

beforeAll(async () => {
  composio = createServer(async (req, res) => {
    for await (const _ of req) {
      // drain
    }
    res.setHeader("content-type", "application/json");
    if (req.url?.startsWith("/api/v3/auth_configs?")) return res.end(JSON.stringify({ items: [] }));
    if (req.url === "/api/v3/auth_configs")
      return res.end(JSON.stringify({ auth_config: { id: "ac_1" } }));
    if (req.url === "/api/v3/connected_accounts/link")
      return res.end(JSON.stringify({ redirect_url: "https://composio.example/signin/1" }));
    if (req.url?.startsWith("/api/v3/connected_accounts?"))
      return res.end(
        JSON.stringify({
          items:
            calendar === "none" ? [] : [{ toolkit: { slug: "googlecalendar" }, status: calendar }],
        }),
      );
    res.writeHead(404).end("{}");
  }).listen(0, "127.0.0.1");
  await once(composio, "listening");
  h = await startHarness({
    worker: { fixtures: FIXTURES },
    env: {
      COMPOSIO_API_KEY: "cmp-key",
      COMPOSIO_API_URL: `http://127.0.0.1:${(composio.address() as AddressInfo).port}`,
    },
  });
  gail = await h.user("gail@example.com");
}, 60_000);
afterAll(async () => {
  await h?.stop();
  composio?.close();
});

describe("welcome chat: Google first", () => {
  it("asks for Google right after the name, saying it goes through Composio", async () => {
    w = await j(
      await h.request("/v1/welcome", {
        method: "POST",
        token: gail.token,
        json: { first_name: "gail" },
      }),
    );
    await addKey(gail.token, w.org_id);
    await act(await last(), "welcome.name", { name: "Gail" }, "Gail");
    const card = await last();
    expect(card[0]?.text).toBe("Nice to meet you, Gail!");
    expect(actions(card)).toEqual([
      { name: "app:connect", context: { app: "google_calendar", after: "welcome.connected" } },
      { name: "app:connect", context: { app: "gmail", after: "welcome.connected" } },
      { name: "welcome.nogoogle", context: {} },
    ]);
    expect(components(card).find((c) => c.id === "via")?.text).toMatch(/Composio/);
    expect(await step()).toBe("google");
  });

  it("doesn't start a catch-up before anything is connected", async () => {
    await act(await last(), "welcome.connected", { app: "google_calendar" }, "Connected");
    const again = await last();
    expect(again[0]?.text).toMatch(/don't see Google connected yet/);
    expect(actions(again).some((a) => a.name === "welcome.nogoogle")).toBe(true);
    expect(await step()).toBe("google");
  });

  it("waits while the Composio sign-in is still open, then catches up once it's active", async () => {
    const connected = await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: gail.token,
        json: { org_id: w.org_id, app_id: "google_calendar", method: "managed" },
      }),
    );
    expect(connected.status).toBe("authorize");
    calendar = "INITIATED";
    await act(await last(), "welcome.connected", { app: "google_calendar" }, "Connected");
    const wait = await last();
    expect(wait[0]?.text).toMatch(/Finish signing in to Google/);
    expect(actions(wait).map((a) => a.name)).toEqual(["welcome.catchup", "welcome.nocatchup"]);
    // Tapped too early: still nothing to read, so no run.
    await act(wait, "welcome.catchup", {}, "Catch me up");
    expect((await last())[0]?.text).toMatch(/isn't connected yet/);
    const [none] = await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.runs where conversation_id = ${w.conversation_id} and trigger <> 'welcome'`;
    expect(none?.n).toBe(0);

    calendar = "ACTIVE";
    await act(await last(), "welcome.catchup", {}, "Catch me up");
    await settle();
    const [run] = await h.tdb.admin<
      { status: string }[]
    >`select status from public.runs where conversation_id = ${w.conversation_id} and trigger = 'chat'`;
    expect(run?.status).toBe("completed");
    const [asked] = await h.tdb.admin<
      { content: Part[] }[]
    >`select content from public.messages where conversation_id = ${w.conversation_id} and role = 'user' order by created_at desc limit 1`;
    // Only the calendar is connected, so only the calendar is read.
    expect(asked?.content[0]?.text).toMatch(/14 days of calendar and tell me/);
    // The first value leads on to the setup offer, as in the rest of the welcome chat.
    expect((await last())[0]?.text).toContain("a few quick questions");
  });

  it("connected from the card, the catch-up starts at once and the picks are skipped", async () => {
    const hal = await h.user("hal@example.com");
    const hw = await j(
      await h.request("/v1/welcome", {
        method: "POST",
        token: hal.token,
        json: { first_name: "hal" },
      }),
    );
    w = hw;
    gail = hal;
    await addKey(hal.token, hw.org_id);
    await act(await last(), "welcome.name", { name: "Hal" }, "Hal");
    await j(
      await h.request("/v1/apps/connect", {
        method: "POST",
        token: hal.token,
        json: { org_id: hw.org_id, app_id: "google_calendar", method: "managed" },
      }),
    );
    // The fake Composio account list is shared, and still says ACTIVE.
    await act(await last(), "welcome.connected", { app: "google_calendar" }, "Connected");
    await settle();
    const [mem] = await h.tdb.admin<
      { content: string }[]
    >`select content from public.memories where bot_id = ${hw.bot_id} and content like 'Connected Google%'`;
    expect(mem?.content).toBe("Connected Google Calendar in the welcome chat.");
    const msgs = await h.tdb.admin<
      { role: string; content: Part[] }[]
    >`select role, content from public.messages where conversation_id = ${hw.conversation_id} order by created_at`;
    const texts = msgs.flatMap((m) => m.content.map((p) => p.text ?? "")).join("\n");
    expect(texts).toContain("Here's what I noticed");
    expect(texts).not.toContain("What should I help with first?");
  });

  it("'Not now' goes on to the picks, and the later connection card leaves Google out", async () => {
    const ivy = await h.user("ivy@example.com");
    w = await j(
      await h.request("/v1/welcome", {
        method: "POST",
        token: ivy.token,
        json: { first_name: "ivy" },
      }),
    );
    gail = ivy;
    await addKey(ivy.token, w.org_id);
    await act(await last(), "welcome.name", { name: "Ivy" }, "Ivy");
    await act(await last(), "welcome.nogoogle", {}, "Not now");
    const focus = await last();
    expect(focus[0]?.text).toMatch(/connect it any time/);
    expect(components(focus).find((c) => c.component === "ChoicePicker")).toBeTruthy();
    await act(focus, "welcome.focus", { focus: ["email_calendar", "coding"] }, "Picks");
    await act(await last(), "welcome.scope", { scope: "just_me" }, "Just me");
    const connect = await last();
    expect(
      actions(connect)
        .filter((a) => a.name === "app:connect")
        .map((a) => a.context?.app),
    ).toEqual(["github"]);
  });
});
