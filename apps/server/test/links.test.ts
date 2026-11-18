/** Linked agents (D-143): invites, both approve, structured requests, both timelines, revoke; across servers over A2A. */
import { fileURLToPath } from "node:url";
import { registerLinkTools, ToolRegistry } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/links.json", import.meta.url));
let one: Harness;
let two: Harness;

beforeAll(async () => {
  const worker = { fixtures: FIXTURES, egressExemptCidrs: ["127.0.0.1/32"] };
  one = await startHarness({ serve: true, worker });
  // DBOS runs one worker per process: the second server has none, and its bot's tool is called directly.
  two = await startHarness({ serve: true });
}, 120_000);
afterAll(async () => {
  await one?.stop();
  await two?.stop();
});

const waitFor = async <T>(
  fn: () => Promise<T | undefined | null | false>,
  what: string,
  ms = 60_000,
): Promise<T> => {
  const until = Date.now() + ms;
  for (;;) {
    const v = await fn();
    if (v) return v;
    if (Date.now() > until) throw new Error(`timed out waiting for ${what}`);
    await new Promise((r) => setTimeout(r, 100));
  }
};

async function person(h: Harness, email: string, botName: string) {
  const u = await h.user(email);
  const orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: u.token, json: { name: botName } }),
    )
  ).id;
  const cred = (
    await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: u.token,
        json: { org_id: orgId, provider: "openrouter", label: "m", api_key: "sk-or-links" },
      }),
    )
  ).id;
  const bot = await j(
    await h.request("/v1/bots", {
      method: "POST",
      token: u.token,
      json: {
        org_id: orgId,
        name: botName,
        model_policy: { primary: { credential_id: cred, model: "fixture-main" } },
      },
    }),
  );
  return { u, orgId, bot };
}
async function ask(h: Harness, p: Awaited<ReturnType<typeof person>>) {
  const conv = await j(
    await h.request("/v1/conversations", {
      method: "POST",
      token: p.u.token,
      json: { bot_id: p.bot.id },
    }),
  );
  const runId = (
    await j(
      await h.request(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token: p.u.token,
        json: { text: "Ask Sam's assistant about dinner" },
      }),
    )
  ).run_id;
  await waitFor(
    async () =>
      ["completed", "failed"].includes(
        (await j(await h.request(`/v1/runs/${runId}`, { token: p.u.token }))).status,
      ),
    "asker run",
  );
  const evs = (await j(await h.request(`/v1/runs/${runId}/events?limit=200`, { token: p.u.token })))
    .items as Array<{ type: string; payload: Record<string, unknown> }>;
  return evs.find((e) => e.type === "tool.completed" || e.type === "tool.failed")?.payload;
}

describe("linked agents", () => {
  it("on one server: invite, accept, ask, both timelines, revoke", async () => {
    const ana = await person(one, "ana@example.com", "Ava");
    const sam = await person(one, "sam@example.com", "Ben");
    const inv = await j(
      await one.request(`/v1/bots/${ana.bot.id}/links`, {
        method: "POST",
        token: ana.u.token,
        json: { name: "Sam" },
      }),
    );
    expect(inv.status).toBe("pending");
    expect(inv.invite).toMatch(/^casama-link:/);
    // Sam accepts with his bot; both sides are active.
    const accepted = await j(
      await one.request("/v1/links/accept", {
        method: "POST",
        token: sam.u.token,
        json: { invite: inv.invite, bot_id: sam.bot.id, name: "Ana" },
      }),
    );
    expect(accepted).toMatchObject({ status: "active", peer_bot_name: "Ava" });
    expect(
      (
        await one.request("/v1/links/accept", {
          method: "POST",
          token: sam.u.token,
          json: { invite: inv.invite, bot_id: sam.bot.id, name: "Ana again" },
        })
      ).status,
    ).toBe(409);
    const anaLinks = (
      await j(await one.request(`/v1/bots/${ana.bot.id}/links`, { token: ana.u.token }))
    ).items;
    expect(anaLinks[0]).toMatchObject({ status: "active", peer_bot_name: "Ben" });

    // Ana's bot asks; Sam's bot answers under Sam (its run is Sam's).
    const r = await ask(one, ana);
    expect(r?.result_preview).toContain("Thursday at 7pm works for Sam.");
    const [peerRun] = await one.tdb.admin<
      { created_by: string; trigger: string; bot_id: string }[]
    >`select created_by, trigger, bot_id from public.runs where trigger = 'link'`;
    expect(peerRun).toMatchObject({ created_by: sam.u.id, trigger: "link", bot_id: sam.bot.id });
    const anaEx = (
      await j(await one.request(`/v1/links/${anaLinks[0].id}/exchanges`, { token: ana.u.token }))
    ).items;
    const samEx = (
      await j(await one.request(`/v1/links/${accepted.id}/exchanges`, { token: sam.u.token }))
    ).items;
    expect(anaEx[0]).toMatchObject({
      direction: "out",
      request: "Find a dinner slot for 4 next week",
      status: "answered",
      response: "Thursday at 7pm works for Sam.",
    });
    expect(samEx[0]).toMatchObject({ direction: "in", status: "answered" });
    expect(
      await one.tdb
        .admin`select 1 from public.notifications where user_id = ${sam.u.id} and kind = 'link_exchange'`,
    ).toHaveLength(1);
    // Ana can't read Sam's side.
    expect(
      (await j(await one.request(`/v1/links/${accepted.id}/exchanges`, { token: ana.u.token })))
        .items,
    ).toHaveLength(0);

    // Either side revokes for both.
    expect(
      (
        await j(
          await one.request(`/v1/links/${accepted.id}`, { method: "DELETE", token: sam.u.token }),
        )
      ).status,
    ).toBe("revoked");
    expect(
      (await j(await one.request(`/v1/bots/${ana.bot.id}/links`, { token: ana.u.token }))).items[0]
        .status,
    ).toBe("revoked");
  }, 120_000);

  it("across Casama servers: the accept handshake swaps link tokens, and requests go over A2A", async () => {
    const sam = await person(one, "sam2@example.com", "Ben");
    const ana = await person(two, "ana2@example.com", "Ava");
    // Sam (server one) invites; Ana (server two) accepts with her bot.
    // Over real HTTP, so each server puts its own address in what it sends.
    const http = (h: Harness, path: string, token: string, json?: unknown) =>
      fetch(`${h.serverUrl}${path}`, {
        method: json ? "POST" : "GET",
        headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
        body: json ? JSON.stringify(json) : undefined,
      });
    const inv = await j(
      await http(one, `/v1/bots/${sam.bot.id}/links`, sam.u.token, { name: "Ana" }),
    );
    const accepted = await j(
      await http(two, "/v1/links/accept", ana.u.token, {
        invite: inv.invite,
        bot_id: ana.bot.id,
        name: "Sam",
      }),
    );
    expect(accepted).toMatchObject({
      status: "active",
      peer_bot_name: "Ben",
      remote_url: one.serverUrl,
    });
    const [samSide] = await one.tdb.admin<
      { status: string; remote_url: string }[]
    >`select status, remote_url from public.bot_links where id = ${inv.id}`;
    expect(samSide).toMatchObject({ status: "active", remote_url: two.serverUrl });

    // Ana's bot asks over A2A; Sam's bot answers on server one, as Sam.
    const reg = new ToolRegistry();
    registerLinkTools(reg, { db: two.handle.db });
    const [run2] = await two.tdb.admin<
      { id: string }[]
    >`insert into public.runs (org_id, bot_id, created_by) values (${ana.orgId}, ${ana.bot.id}, ${ana.u.id}) returning id`;
    const ctx = {
      runId: run2!.id,
      botId: ana.bot.id,
      orgId: ana.orgId,
      output: async () => {},
      emit: async () => {},
    } as never;
    const askTool = () =>
      reg
        .get("links.ask")!
        .execute({ contact: "Sam", request: "Find a dinner slot for 4 next week" } as never, ctx);
    const r = await askTool();
    expect(r.content).toContain("Thursday at 7pm works for Sam.");
    const [outEx] = await two.tdb.admin<
      { direction: string; status: string }[]
    >`select direction, status from public.link_exchanges where link_id = ${accepted.id}`;
    expect(outEx).toMatchObject({ direction: "out", status: "answered" });
    const [run] = await one.tdb.admin<
      { created_by: string; trigger: string }[]
    >`select r.created_by, r.trigger from public.a2a_tasks t join public.runs r on r.id = t.run_id`;
    expect(run).toMatchObject({ created_by: sam.u.id, trigger: "a2a" });
    const [inEx] = await one.tdb.admin<
      { direction: string; response: string }[]
    >`select direction, response from public.link_exchanges where link_id = ${inv.id}`;
    expect(inEx).toMatchObject({ direction: "in", response: "Thursday at 7pm works for Sam." });

    // Revoking on server two revokes on server one; the token stops working.
    await fetch(`${two.serverUrl}/v1/links/${accepted.id}`, {
      method: "DELETE",
      headers: { authorization: `Bearer ${ana.u.token}` },
    });
    await waitFor(
      async () =>
        (
          await one.tdb.admin<
            { status: string }[]
          >`select status from public.bot_links where id = ${inv.id}`
        )[0]?.status === "revoked",
      "remote revoke",
      10_000,
    );
    await expect(askTool()).rejects.toThrow(/no linked contacts/);
  }, 120_000);
});
