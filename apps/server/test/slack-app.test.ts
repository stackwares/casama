/**
 * Slack as a first-class place to work (D-277): @mentions in channels, a reaction on arrival,
 * approvals with buttons in the thread, and Casama's own app installed in one click.
 */
import { createHmac } from "node:crypto";
import { once } from "node:events";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { postApprovalToChannel } from "@casama/agent";
import { afterAll, beforeAll, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const SIGNING = "slack-app-signing-secret";
let h: Harness;
let slack: Server;
let api = "";
const calls: Array<{ path: string; body: string }> = [];

beforeAll(async () => {
  slack = createServer(async (req, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    const body = Buffer.concat(chunks).toString();
    calls.push({ path: req.url ?? "", body });
    const out =
      req.url === "/api/oauth.v2.access"
        ? {
            ok: true,
            access_token: "xoxb-installed",
            bot_user_id: "UBOT",
            team: { id: "T42", name: "Acme" },
            authed_user: { id: "UANA" },
          }
        : { ok: true };
    res.writeHead(200, { "content-type": "application/json" }).end(JSON.stringify(out));
  }).listen(0, "127.0.0.1");
  await once(slack, "listening");
  api = `http://127.0.0.1:${(slack.address() as AddressInfo).port}`;
  h = await startHarness({
    env: {
      SLACK_CLIENT_ID: "cid",
      SLACK_CLIENT_SECRET: "csecret",
      SLACK_SIGNING_SECRET: SIGNING,
      SLACK_API_BASE: api,
      INTERNAL_TOKEN: "internal-token-for-tests-0123456789abcdef",
    },
  });
}, 60_000);
afterAll(async () => {
  await h?.stop();
  slack?.close();
});

const signed = (body: string, secret = SIGNING) => {
  const ts = String(Math.floor(Date.now() / 1000));
  return {
    "x-slack-request-timestamp": ts,
    "x-slack-signature": `v0=${createHmac("sha256", secret).update(`v0:${ts}:${body}`).digest("hex")}`,
  };
};

it("installs Casama's Slack app in one click, then answers @mentions with a reaction on arrival", async () => {
  const u = await h.user("slack-owner@example.com");
  const org = (
    await j(await h.request("/v1/orgs", { method: "POST", token: u.token, json: { name: "S" } }))
  ).id;
  const bot = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: u.token,
        json: { org_id: org, name: "Helper" },
      }),
    )
  ).id;
  const start = await j(
    await h.request(`/v1/channels/slack/install?bot_id=${bot}`, { token: u.token }),
  );
  const authorize = new URL(start.url);
  expect(authorize.pathname).toBe("/oauth/v2/authorize");
  expect(authorize.searchParams.get("scope")).toContain("app_mentions:read");
  const back = await h.request(
    `/hooks/slack/oauth?code=abc&state=${encodeURIComponent(authorize.searchParams.get("state")!)}`,
  );
  expect(back.status).toBe(200);
  expect(await back.text()).toContain("Slack is connected");
  const [ch] = await h.tdb.admin<
    { id: string; allowed_senders: string[]; config: Record<string, unknown> }[]
  >`
    select id, allowed_senders, config from public.channels where bot_id = ${bot}`;
  expect(ch).toMatchObject({
    allowed_senders: ["UANA"],
    config: { team_id: "T42", app: "casama" },
  });
  // A forged state is refused.
  expect((await h.request("/hooks/slack/oauth?code=abc&state=x.y")).status).toBe(400);

  const event = JSON.stringify({
    type: "event_callback",
    team_id: "T42",
    event_id: "Ev1",
    event: {
      type: "app_mention",
      text: "<@UBOT> what's on today?",
      user: "UANA",
      channel: "C1",
      ts: "100.1",
    },
  });
  expect(
    (
      await h.request("/hooks/slack/events", {
        method: "POST",
        headers: signed(event, "wrong"),
        body: event,
      })
    ).status,
  ).toBe(401);
  const ok = await h.request("/hooks/slack/events", {
    method: "POST",
    headers: signed(event),
    body: event,
  });
  expect(ok.status).toBe(200);
  // The same message as a plain "message" event doesn't start a second run.
  const dup = JSON.stringify({
    type: "event_callback",
    team_id: "T42",
    event_id: "Ev2",
    event: {
      type: "message",
      text: "<@UBOT> what's on today?",
      user: "UANA",
      channel: "C1",
      ts: "100.1",
    },
  });
  await h.request("/hooks/slack/events", { method: "POST", headers: signed(dup), body: dup });
  const runs = await h.tdb.admin<
    { id: string }[]
  >`select id from public.runs where bot_id = ${bot}`;
  expect(runs).toHaveLength(1);
  const [m] = await h.tdb.admin<{ content: Array<{ text?: string }> }[]>`
    select content from public.messages where run_id = ${runs[0]!.id}`;
  expect(m!.content[0]!.text).toContain("what's on today?");
  expect(m!.content[0]!.text).not.toContain("<@UBOT>");
  expect(
    calls.some((c) => c.path === "/api/reactions.add" && c.body.includes('"name":"eyes"')),
  ).toBe(true);
});

it("an approval shows buttons in the thread, and a press from an allowed person decides it", async () => {
  const [ch] = await h.tdb.admin<{ id: string; bot_id: string; org_id: string }[]>`
    select id, bot_id, org_id from public.channels where config ->> 'team_id' = 'T42'`;
  const [run] = await h.tdb.admin<{ id: string; conversation_id: string }[]>`
    select id, conversation_id from public.runs where bot_id = ${ch!.bot_id}`;
  const [a] = await h.tdb.admin<{ id: string }[]>`
    insert into public.approvals (org_id, bot_id, run_id, call_id, tool_name, args_redacted, summary, risk, expires_at)
    values (${ch!.org_id}, ${ch!.bot_id}, ${run!.id}, 'c1', 'email.send', '{}', 'Helper wants to send an email to the board', 'high', now() + interval '1 day')
    returning id`;
  expect(
    await postApprovalToChannel(
      h.handle.db,
      run!.conversation_id,
      { id: a!.id, summary: "Send an email to the board" },
      fetch,
    ),
  ).toBe(true);
  const posted = calls.filter((c) => c.path === "/api/chat.postMessage").at(-1);
  expect(JSON.parse(posted!.body)).toMatchObject({ channel: "C1", thread_ts: "100.1" });
  expect(posted!.body).toContain(`approve:${a!.id}`);

  const press = (user: string, value: string) =>
    `payload=${encodeURIComponent(
      JSON.stringify({
        type: "block_actions",
        team: { id: "T42" },
        user: { id: user },
        actions: [{ value }],
        response_url: `${api}/respond`,
      }),
    )}`;
  // Someone not on the allowed list can't decide.
  const stranger = press("UEVE", `approve:${a!.id}`);
  await h.request("/hooks/slack/interact", {
    method: "POST",
    headers: signed(stranger),
    body: stranger,
  });
  const [still] = await h.tdb.admin<
    { status: string }[]
  >`select status from public.approvals where id = ${a!.id}`;
  expect(still!.status).toBe("pending");
  const yes = press("UANA", `approve:${a!.id}`);
  expect(
    (await h.request("/hooks/slack/interact", { method: "POST", headers: signed(yes), body: yes }))
      .status,
  ).toBe(200);
  const [done] = await h.tdb.admin<{ status: string; decided_by: string }[]>`
    select status, decided_by from public.approvals where id = ${a!.id}`;
  expect(done!.status).toBe("approved");
  expect(calls.some((c) => c.path === "/respond" && c.body.includes("Approved by <@UANA>"))).toBe(
    true,
  );
});

it("a server without a Slack app says so", async () => {
  const plain = await startHarness();
  try {
    const u = await plain.user("no-slack@example.com");
    const org = (
      await j(
        await plain.request("/v1/orgs", { method: "POST", token: u.token, json: { name: "N" } }),
      )
    ).id;
    const bot = (
      await j(
        await plain.request("/v1/bots", {
          method: "POST",
          token: u.token,
          json: { org_id: org, name: "B" },
        }),
      )
    ).id;
    expect(
      (await plain.request(`/v1/channels/slack/install?bot_id=${bot}`, { token: u.token })).status,
    ).toBe(409);
  } finally {
    await plain.stop();
  }
});
